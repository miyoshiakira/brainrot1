--[[
    LaunchManager
    Brainrot Launch Simulatorのコアシステム
    - Leaderstats管理
    - クリティカル・ローンチ判定
    - グローバルイベント（Rainbow Rain）
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CommonFunctions = require(script.Parent.CommonFunctions)
local constants = require("../Constants")
local DataManager = require(script.Parent.DataManager)
local MonsterManager = require(script.Parent.MonsterManager)

-- RemoteEvents待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters).BrainrotMonsters

local LaunchManager = {}
LaunchManager.__index = LaunchManager

-- 設定
local LAUNCH_CONFIG = {
    -- ゲージ設定
    GaugeSpeed = 2.0,           -- 基本ゲージ速度（往復/秒）
    SpeedIncreaseRate = 0.0001, -- 高度1mあたりの速度増加
    MaxGaugeSpeed = 8.0,        -- 最大ゲージ速度

    -- クリティカル判定
    PerfectZoneStart = 0.45,    -- Perfect領域の開始位置（0-1）
    PerfectZoneEnd = 0.55,      -- Perfect領域の終了位置
    GoodZoneStart = 0.35,       -- Good領域の開始位置
    GoodZoneEnd = 0.65,         -- Good領域の終了位置

    -- 倍率
    PerfectMultiplier = 2.0,    -- Perfect時の倍率
    GoodMultiplier = 1.5,       -- Good時の倍率
    NormalMultiplier = 1.0,     -- 通常時の倍率

    -- クールダウン
    LaunchCooldown = 1.0,       -- 発射間隔（秒）

    -- グローバルイベント
    GlobalThreshold = 100000,   -- Rainbow Rain発動閾値（10万m）
    RainbowRainDuration = 180,  -- イベント継続時間（秒）
    RainbowRainMultiplier = 3.0, -- イベント中のボーナス倍率

    -- コイン生成
    CoinsPerHeight = 0.1,       -- 1mあたりのコイン
    PassiveCoinsInterval = 5,   -- パッシブコイン生成間隔（秒）
    PassiveCoinsBase = 1,       -- 基本パッシブコイン

    -- キャラクタードロップ
    CharacterDropRate = 1,   -- 発射ごとのキャラクタードロップ確率（100%）
    PerfectDropBonus = 0.10,    -- Perfect時の追加ドロップ率（+10%）
    GoodDropBonus = 0.05,       -- Good時の追加ドロップ率（+5%）

    -- 脚力（LegPower）
    LegPowerGainNormal = 1,     -- NORMAL時の脚力獲得量
    LegPowerGainGood = 3,       -- GOOD時の脚力獲得量
    LegPowerGainPerfect = 8,    -- PERFECT時の脚力獲得量
    LegPowerHeightBonus = 0.01, -- 脚力1あたりの高度ボーナス倍率（1%）
    MegaJumpLegPowerThreshold = 50,  -- 特大ジャンプ発動に必要な脚力
    MegaJumpMultiplier = 2.0,   -- 特大ジャンプ時の追加倍率

    -- レアリティ脚力ボーナス（キャラクタードロップ時）
    RarityLegPowerBonus = {
        Common = 0,
        Rare = 2,
        Epic = 5,
        Legendary = 10,
        Rainbow = 25,
    },
}

-- グローバル状態
local GlobalState = {
    TotalHeight = 0,            -- サーバー全体の高度合計
    IsRainbowRain = false,      -- Rainbow Rainイベント中か
    RainbowRainEndTime = 0,     -- イベント終了時刻
}

-- プレイヤーごとの発射クールダウン
local PlayerCooldowns: {[Player]: number} = {}

-- Leaderstatsを作成
function LaunchManager.CreateLeaderstats(player: Player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local height = Instance.new("IntValue")
    height.Name = "Height"
    height.Value = 0
    height.Parent = leaderstats

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    local legPower = Instance.new("IntValue")
    legPower.Name = "LegPower"
    legPower.Value = 0
    legPower.Parent = leaderstats

    print("[LaunchManager] Leaderstats作成:", player.Name)
    return leaderstats
end

-- Leaderstatsを更新
function LaunchManager.UpdateLeaderstats(player: Player)
    local profile = DataManager.GetProfile(player)
    if not profile then return end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local heightValue = leaderstats:FindFirstChild("Height")
    local coinsValue = leaderstats:FindFirstChild("Coins")
    local legPowerValue = leaderstats:FindFirstChild("LegPower")

    if heightValue then
        heightValue.Value = math.floor(profile.Height)
    end

    if coinsValue then
        coinsValue.Value = math.floor(profile.Money)
    end

    if legPowerValue then
        legPowerValue.Value = math.floor(profile.LegPower)
    end
end

-- ゲージ速度を計算（高度に応じて上昇）
function LaunchManager.CalculateGaugeSpeed(height: number): number
    local speed = LAUNCH_CONFIG.GaugeSpeed + (height * LAUNCH_CONFIG.SpeedIncreaseRate)
    return math.min(speed, LAUNCH_CONFIG.MaxGaugeSpeed)
end

-- クリティカル判定
function LaunchManager.CalculateCriticalMultiplier(gaugePosition: number): (number, string)
    -- gaugePositionは0-1の値
    if gaugePosition >= LAUNCH_CONFIG.PerfectZoneStart and gaugePosition <= LAUNCH_CONFIG.PerfectZoneEnd then
        return LAUNCH_CONFIG.PerfectMultiplier, "PERFECT"
    elseif gaugePosition >= LAUNCH_CONFIG.GoodZoneStart and gaugePosition <= LAUNCH_CONFIG.GoodZoneEnd then
        return LAUNCH_CONFIG.GoodMultiplier, "GOOD"
    else
        return LAUNCH_CONFIG.NormalMultiplier, "NORMAL"
    end
end

-- 発射高度を計算
function LaunchManager.CalculateLaunchHeight(player: Player, gaugePosition: number): (number, string, number, boolean)
    local profile = DataManager.GetProfile(player)
    if not profile then
        return 0, "ERROR", 1.0, false
    end

    local criticalMultiplier, criticalType = LaunchManager.CalculateCriticalMultiplier(gaugePosition)

    -- Rainbow Rain中はさらにボーナス
    if GlobalState.IsRainbowRain then
        criticalMultiplier = criticalMultiplier * LAUNCH_CONFIG.RainbowRainMultiplier
    end

    -- Height = CriticalMultiplier × LegPowerBonus
    local legPowerBonus = 1 + (profile.LegPower * LAUNCH_CONFIG.LegPowerHeightBonus)
    local height = criticalMultiplier * legPowerBonus * 10

    -- 特大ジャンプ判定: 脚力が閾値以上 + PERFECT
    local isMegaJump = profile.LegPower >= LAUNCH_CONFIG.MegaJumpLegPowerThreshold and criticalType == "PERFECT"
    if isMegaJump then
        height = height * LAUNCH_CONFIG.MegaJumpMultiplier
    end

    return height, criticalType, criticalMultiplier, isMegaJump
end

-- キャラクター3Dモデルを生成してプレイヤーに持たせる
function LaunchManager.SpawnCharacterModel(player: Player, monsterId: string)
    local character = player.Character
    if not character then return nil end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end

    -- キャラクター定義を取得
    local charDef = BrainrotMonsters.GetCharacterById(monsterId)
    if not charDef then return nil end

    -- スライムテンプレートを取得
    local templatesFolder = ReplicatedStorage:FindFirstChild("CharacterTemplates")
    local slimeTemplate = templatesFolder and templatesFolder:FindFirstChild(charDef.ModelName)

    local charModel

    if slimeTemplate then
        -- テンプレートからクローン
        charModel = slimeTemplate:Clone()
        -- Weld自動生成
        CommonFunctions.autoWeldModel(charModel)
        charModel.Name = constants.CHARACTER_MODEL_NAME

        -- レアリティに応じた色変更＋物理設定
        MonsterManager.SetupCharModel(charModel, charDef.Rarity)
    else
        -- フォールバック：シンプルなブロック
        -- charModel = Instance.new("Part")
        -- charModel.Name = "HeldCharacter_" .. player.Name
        -- charModel.Size = Vector3.new(2, 2, 2)
        -- charModel.Color = charColor
        -- charModel.Material = Enum.Material.SmoothPlastic
        -- charModel.CanCollide = false
        -- charModel.Anchored = false
        -- charModel.Massless = true
    end

    -- キャラクター情報を属性として保存
    MonsterManager.SetInitStatus(charModel, monsterId, charDef.ModelName)
    charModel:SetAttribute("Owner", player.UserId)

    -- PrimaryPartを取得（Weld用）
    local primaryPart = charModel.PrimaryPart or charModel:FindFirstChild("Body") or (charModel:IsA("BasePart") and charModel)
    -- Weldでプレイヤーに持たせる
    local weld = Instance.new("WeldConstraint")
    weld.Name = "CharacterWeld"
    weld.Part0 = humanoidRootPart
    weld.Part1 = primaryPart
    weld.Parent = humanoidRootPart
    print("LaunchManager.TryCharacterDrop:",weld)

    -- プレイヤーの前に配置
    charModel:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 2, -3))
    charModel.Parent = character

    -- クライアントに通知
    RemoteEvents.CharacterSpawned:FireClient(player, {
        ModelName = charModel.Name,
        Model = charModel,
        MonsterId = monsterId,
        MonsterName = charDef.Name,
        Rarity = charDef.Rarity,
        Weld = weld,
    })

    return charModel
end

-- キャラクタードロップ処理
function LaunchManager.TryCharacterDrop(player: Player, criticalType: string): string?
    local profile = DataManager.GetProfile(player)
    if not profile then return nil end

    -- ドロップ率計算
    local dropRate = LAUNCH_CONFIG.CharacterDropRate
    if criticalType == "PERFECT" then
        dropRate = dropRate + LAUNCH_CONFIG.PerfectDropBonus
    elseif criticalType == "GOOD" then
        dropRate = dropRate + LAUNCH_CONFIG.GoodDropBonus
    end

    -- Rainbow Rain中はドロップ率2倍
    if GlobalState.IsRainbowRain then
        dropRate = dropRate * 2
    end

    -- ドロップ判定
    if math.random() > dropRate then
        return nil
    end

    -- レアリティ決定
    local rarity = BrainrotMonsters.RollCharacter(GlobalState.IsRainbowRain)
    if not rarity then return nil end

    -- そのレアリティのキャラクターからランダム選択
    local characters = BrainrotMonsters.GetCharactersByRarity(rarity)
    if #characters == 0 then return nil end

    local selectedChar = characters[math.random(1, #characters)]
    profile.TotalCharactersCollected = (profile.TotalCharactersCollected or 0) + 1

    -- Rainbow キャラクターの場合は統計更新
    if rarity == "Rainbow" then
        profile.RainbowCharactersFound = (profile.RainbowCharactersFound or 0) + 1
    end

    -- 3Dモデルを生成してプレイヤーに持たせる
    LaunchManager.SpawnCharacterModel(player, selectedChar.MonsterId)

    return selectedChar.MonsterId
end

-- 発射処理
function LaunchManager.ProcessLaunch(player: Player, gaugePosition: number): {success: boolean, height: number}
    -- クールダウンチェック
    local now = tick()
    local lastLaunch = PlayerCooldowns[player] or 0
    if now - lastLaunch < LAUNCH_CONFIG.LaunchCooldown then
        return {success = false, height = 0}
    end
    PlayerCooldowns[player] = now

    -- ゲージ位置の検証（0-1の範囲内か）
    if gaugePosition < 0 or gaugePosition > 1 then
        warn("[LaunchManager] 不正なゲージ位置:", player.Name, gaugePosition)
        return {success = false, height = 0}
    end

    local profile = DataManager.GetProfile(player)
    if not profile then
        return {success = false, height = 0}
    end

    -- 発射高度を計算
    local height, criticalType, multiplier, isMegaJump = LaunchManager.CalculateLaunchHeight(player, gaugePosition)

    -- プロファイルを更新
    profile.Height = profile.Height + height
    profile.TotalLaunches = profile.TotalLaunches + 1

    -- 脚力獲得
    local legPowerGain = LAUNCH_CONFIG.LegPowerGainNormal
    if criticalType == "PERFECT" then
        legPowerGain = LAUNCH_CONFIG.LegPowerGainPerfect
    elseif criticalType == "GOOD" then
        legPowerGain = LAUNCH_CONFIG.LegPowerGainGood
    end

    -- コインを獲得
    local coinsEarned = math.floor(height * LAUNCH_CONFIG.CoinsPerHeight)
    DataManager.AddMoney(player, coinsEarned)

    -- キャラクタードロップ判定
    local droppedMonsterId = LaunchManager.TryCharacterDrop(player, criticalType)

    -- ドロップしたキャラクターのレアリティに応じた脚力ボーナス
    if droppedMonsterId then
        local droppedCharDef = BrainrotMonsters.GetCharacterById(droppedMonsterId)
        if droppedCharDef then
            legPowerGain = legPowerGain + (LAUNCH_CONFIG.RarityLegPowerBonus[droppedCharDef.Rarity] or 0)
        end
    end

    profile.LegPower = profile.LegPower + legPowerGain

    -- グローバル高度を更新
    GlobalState.TotalHeight = GlobalState.TotalHeight + height

    -- Leaderstatsを更新
    LaunchManager.UpdateLeaderstats(player)

    -- 脚力変更を通知
    RemoteEvents.LegPowerChanged:FireClient(player, profile.LegPower)

    -- クライアントに結果を送信
    RemoteEvents.LaunchResult:FireClient(player, {
        Height = profile.Height,
        CoinsEarned = coinsEarned,
        IsRainbowRain = GlobalState.IsRainbowRain,
        DroppedCharacter = droppedMonsterId,
        CriticalType = criticalType,
        IsMegaJump = isMegaJump,
        LegPowerGain = legPowerGain,
    })

    -- キャラクター獲得通知
    if droppedMonsterId then
        RemoteEvents.CharacterCollected:FireClient(player, droppedMonsterId)
    end

    -- グローバル高度を全員に通知
    RemoteEvents.GlobalHeightUpdate:FireAllClients(GlobalState.TotalHeight)

    -- Rainbow Rain判定
    LaunchManager.CheckRainbowRain()

    print(string.format("[LaunchManager] %s が発射: +%.0fm (%s x%.1f) 累計: %.0fm 脚力: %d%s",
        player.Name, height, criticalType, multiplier, profile.Height, profile.LegPower,
        isMegaJump and " MEGA JUMP!!" or ""))

    return {success = true, height = height}
end

-- Rainbow Rain判定
function LaunchManager.CheckRainbowRain()
    if GlobalState.IsRainbowRain then
        return  -- すでにイベント中
    end

    if GlobalState.TotalHeight >= LAUNCH_CONFIG.GlobalThreshold then
        LaunchManager.StartRainbowRain()
    end
end

-- Rainbow Rain開始
function LaunchManager.StartRainbowRain()
    GlobalState.IsRainbowRain = true
    GlobalState.RainbowRainEndTime = tick() + LAUNCH_CONFIG.RainbowRainDuration

    -- グローバル高度をリセット（次回イベントのため）
    GlobalState.TotalHeight = 0

    -- 全クライアントに通知
    RemoteEvents.RainbowRainStart:FireAllClients({
        Duration = LAUNCH_CONFIG.RainbowRainDuration,
        Multiplier = LAUNCH_CONFIG.RainbowRainMultiplier,
    })

    print("[LaunchManager] Rainbow Rain開始!")

    -- イベント終了タイマー
    task.delay(LAUNCH_CONFIG.RainbowRainDuration, function()
        LaunchManager.EndRainbowRain()
    end)
end

-- Rainbow Rain終了
function LaunchManager.EndRainbowRain()
    GlobalState.IsRainbowRain = false
    GlobalState.RainbowRainEndTime = 0

    -- 全クライアントに通知
    RemoteEvents.RainbowRainEnd:FireAllClients()

    print("[LaunchManager] Rainbow Rain終了")
end

-- グローバル統計取得
function LaunchManager.GetGlobalStats()
    return {
        TotalHeight = GlobalState.TotalHeight,
        Threshold = LAUNCH_CONFIG.GlobalThreshold,
        IsRainbowRain = GlobalState.IsRainbowRain,
        RainbowRainTimeLeft = GlobalState.IsRainbowRain and
            math.max(0, GlobalState.RainbowRainEndTime - tick()) or 0,
    }
end

-- キャラクターコレクション取得
function LaunchManager.GetCharacterCollection(player: Player)
    local profile = DataManager.GetProfile(player)
    if not profile then return nil end

    return {
        TotalCollected = profile.TotalCharactersCollected or 0,
        RainbowFound = profile.RainbowCharactersFound or 0,
    }
end

function LaunchManager.CharacterPickedUp(player: Player, monsterId: string)
    print(string.format("[LaunchManager] %s が %s を所有", player.Name, monsterId))
end

-- 初期化
function LaunchManager.Initialize()
    -- 発射リクエスト受信
    RemoteFunctions.LaunchRequest.OnServerInvoke = function(player, gaugePosition)
        local data = LaunchManager.ProcessLaunch(player, gaugePosition)
        if data.success then
            return data.height
        end
        return nil
    end

    -- グローバル統計取得
    RemoteEvents.GetGlobalStats.OnServerInvoke = function(player)
        return LaunchManager.GetGlobalStats()
    end

    -- キャラクターコレクション取得
    RemoteEvents.GetCharacterCollection.OnServerInvoke = function(player)
        return LaunchManager.GetCharacterCollection(player)
    end
    
    -- キャラクターを手元に拾う
    RemoteEvents.CharacterPickedUp.OnServerEvent:Connect(function(player, monsterId)
        LaunchManager.CharacterPickedUp(player, monsterId)
    end)

    -- キャラクター取り外し
    RemoteEvents.CharacterRemoved.OnServerEvent:Connect(function(player, monsterId, slotName)
        print(string.format("[LaunchManager] %s が %s を %s から取り外し", player.Name, monsterId, slotName))
    end)

    print("[LaunchManager] 初期化完了")
end

return {
    LaunchManager = LaunchManager,
    LAUNCH_CONFIG = LAUNCH_CONFIG,
    GlobalState = GlobalState,
}
