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

-- RemoteEvents待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local BrainrotCharacters = require(ReplicatedStorage.Shared.BrainrotCharacters).BrainrotCharacters

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

    if heightValue then
        heightValue.Value = math.floor(profile.Height)
    end

    if coinsValue then
        coinsValue.Value = math.floor(profile.Money)
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
function LaunchManager.CalculateLaunchHeight(player: Player, gaugePosition: number): (number, string, number)
    local profile = DataManager.GetProfile(player)
    if not profile then
        return 0, "ERROR", 1.0
    end

    local criticalMultiplier, criticalType = LaunchManager.CalculateCriticalMultiplier(gaugePosition)

    -- Rainbow Rain中はさらにボーナス
    if GlobalState.IsRainbowRain then
        criticalMultiplier = criticalMultiplier * LAUNCH_CONFIG.RainbowRainMultiplier
    end

    -- Height = (BasePower + CharacterBonus) × CriticalMultiplier
    local baseHeight = profile.BasePower + profile.CharacterBonus
    local height = baseHeight * criticalMultiplier

    return height, criticalType, criticalMultiplier
end

-- キャラクター3Dモデルを生成してプレイヤーに持たせる
function LaunchManager.SpawnCharacterModel(player: Player, characterId: string)
    local character = player.Character
    if not character then return nil end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end

    -- キャラクター定義を取得
    local charDef = BrainrotCharacters.GetCharacterById(characterId)
    if not charDef then return nil end

    -- レアリティカラーを取得
    local rarityConfig = BrainrotCharacters.GetRarityConfig(charDef.Rarity)
    local charColor = rarityConfig and rarityConfig.Color or Color3.fromRGB(255, 255, 255)

    -- スライムテンプレートを取得
    local templatesFolder = ReplicatedStorage:FindFirstChild("CharacterTemplates")
    local slimeTemplate = templatesFolder and templatesFolder:FindFirstChild("CuteSlimeTemplate")

    local charModel

    if slimeTemplate then
        -- テンプレートからクローン
        charModel = slimeTemplate:Clone()
        -- Weld自動生成
        CommonFunctions.autoWeldModel(charModel)
        charModel.Name = constants.CHARACTER_MODEL_NAME

        -- レアリティに応じて色を変更
        for _, part in ipairs(charModel:GetDescendants()) do
            if part:IsA("BasePart") and part.Name == "Body" then
                part.Color = charColor
                -- ライトも更新
                local light = part:FindFirstChild("SlimeLight")
                if light then
                    light.Color = charColor
                end
            end
        end

        -- 全パーツの物理設定
        for _, part in ipairs(charModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Anchored = false
                part.Massless = true
            end
        end
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
    charModel:SetAttribute("CharacterId", characterId)
    charModel:SetAttribute("CharacterName", charDef.Name)
    charModel:SetAttribute("Rarity", charDef.Rarity)
    charModel:SetAttribute("OwnerId", player.UserId)

    -- PrimaryPartを取得（Weld用）
    local primaryPart = charModel.PrimaryPart or charModel:FindFirstChild("Body") or (charModel:IsA("BasePart") and charModel)
    -- Weldでプレイヤーに持たせる
    local weld = Instance.new("WeldConstraint")
    weld.Name = "CharacterWeld"
    weld.Part0 = humanoidRootPart
    weld.Part1 = primaryPart
    weld.Parent = humanoidRootPart

    -- プレイヤーの前に配置
    charModel:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 2, -3))
    charModel.Parent = character

    -- クライアントに通知
    RemoteEvents.CharacterSpawned:FireClient(player, {
        ModelName = charModel.Name,
        Model = charModel,
        CharacterId = characterId,
        CharacterName = charDef.Name,
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
    local rarity = BrainrotCharacters.RollCharacter(GlobalState.IsRainbowRain)
    if not rarity then return nil end

    -- そのレアリティのキャラクターからランダム選択
    local characters = BrainrotCharacters.GetCharactersByRarity(rarity)
    if #characters == 0 then return nil end

    local selectedChar = characters[math.random(1, #characters)]
    local bonus = BrainrotCharacters.GenerateBonus(rarity)

    -- プロファイルに追加
    if not profile.Characters then
        profile.Characters = {}
    end

    local existingChar = profile.Characters[selectedChar.Id]
    if existingChar then
        -- 既に所持している場合はカウント増加
        existingChar.Count = existingChar.Count + 1
        existingChar.Bonus = math.max(existingChar.Bonus, bonus)  -- より高いボーナスを保持
    else
        -- 新規キャラクター
        profile.Characters[selectedChar.Id] = {
            Id = selectedChar.Id,
            Name = selectedChar.Name,
            Rarity = rarity,
            Bonus = bonus,
            Level = 1,
            Count = 1,
        }
        profile.TotalCharactersCollected = (profile.TotalCharactersCollected or 0) + 1

        -- Rainbow キャラクターの場合は統計更新
        if rarity == "Rainbow" then
            profile.RainbowCharactersFound = (profile.RainbowCharactersFound or 0) + 1
        end
    end

    -- アクティブキャラクターが未設定の場合は最初のキャラを設定
    if not profile.ActiveCharacter then
        profile.ActiveCharacter = selectedChar.Id
    end

    -- キャラクターボーナスを再計算
    LaunchManager.RecalculateCharacterBonus(player)

    -- 3Dモデルを生成してプレイヤーに持たせる
    LaunchManager.SpawnCharacterModel(player, selectedChar.Id)

    return selectedChar.Id
end

-- キャラクターボーナス再計算
function LaunchManager.RecalculateCharacterBonus(player: Player)
    local profile = DataManager.GetProfile(player)
    if not profile or not profile.Characters then return end

    local totalBonus = 10  -- 基本値

    -- アクティブキャラクターのボーナス
    if profile.ActiveCharacter and profile.Characters[profile.ActiveCharacter] then
        local activeChar = profile.Characters[profile.ActiveCharacter]
        totalBonus = totalBonus + activeChar.Bonus * activeChar.Level
    end

    -- 全キャラクターのパッシブボーナス（収集数に応じて）
    local collectionBonus = 0
    for _, char in pairs(profile.Characters) do
        collectionBonus = collectionBonus + char.Bonus * 0.1  -- 他キャラの10%を追加
    end
    totalBonus = totalBonus + collectionBonus

    profile.CharacterBonus = math.floor(totalBonus)
end

-- 発射処理
function LaunchManager.ProcessLaunch(player: Player, gaugePosition: number): boolean
    -- クールダウンチェック
    local now = tick()
    local lastLaunch = PlayerCooldowns[player] or 0
    if now - lastLaunch < LAUNCH_CONFIG.LaunchCooldown then
        return false
    end
    PlayerCooldowns[player] = now

    -- ゲージ位置の検証（0-1の範囲内か）
    if gaugePosition < 0 or gaugePosition > 1 then
        warn("[LaunchManager] 不正なゲージ位置:", player.Name, gaugePosition)
        return false
    end

    local profile = DataManager.GetProfile(player)
    if not profile then
        return false
    end

    -- 発射高度を計算
    local height, criticalType, multiplier = LaunchManager.CalculateLaunchHeight(player, gaugePosition)

    -- プロファイルを更新
    profile.Height = profile.Height + height
    profile.TotalHeight = profile.TotalHeight + height
    profile.TotalLaunches = profile.TotalLaunches + 1

    -- コインを獲得
    local coinsEarned = math.floor(height * LAUNCH_CONFIG.CoinsPerHeight)
    DataManager.AddMoney(player, coinsEarned)

    -- キャラクタードロップ判定
    local droppedCharacterId = LaunchManager.TryCharacterDrop(player, criticalType)

    -- グローバル高度を更新
    GlobalState.TotalHeight = GlobalState.TotalHeight + height

    -- Leaderstatsを更新
    LaunchManager.UpdateLeaderstats(player)

    -- クライアントに結果を送信
    RemoteEvents.LaunchResult:FireClient(player, {
        Height = height,
        CriticalType = criticalType,
        Multiplier = multiplier,
        TotalHeight = profile.Height,
        CoinsEarned = coinsEarned,
        IsRainbowRain = GlobalState.IsRainbowRain,
        DroppedCharacter = droppedCharacterId,
    })

    -- キャラクター獲得通知
    if droppedCharacterId then
        local charData = profile.Characters[droppedCharacterId]
        if charData then
            RemoteEvents.CharacterCollected:FireClient(player, charData)
        end
    end

    -- グローバル高度を全員に通知
    RemoteEvents.GlobalHeightUpdate:FireAllClients(GlobalState.TotalHeight)

    -- Rainbow Rain判定
    LaunchManager.CheckRainbowRain()

    print(string.format("[LaunchManager] %s が発射: +%.0fm (%s x%.1f) 累計: %.0fm",
        player.Name, height, criticalType, multiplier, profile.Height))

    return true
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

-- パッシブコイン生成
function LaunchManager.StartPassiveCoins(player: Player)
    task.spawn(function()
        while player.Parent do
            task.wait(LAUNCH_CONFIG.PassiveCoinsInterval)

            local profile = DataManager.GetProfile(player)
            if profile then
                -- 基本コイン + キャラクターボーナスに応じた追加
                local passiveCoins = LAUNCH_CONFIG.PassiveCoinsBase + math.floor(profile.CharacterBonus / 10)
                DataManager.AddMoney(player, passiveCoins)
                LaunchManager.UpdateLeaderstats(player)
            end
        end
    end)
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

-- キャラクター選択
function LaunchManager.SelectCharacter(player: Player, characterId: string): boolean
    local profile = DataManager.GetProfile(player)
    if not profile then return false end

    if not profile.Characters or not profile.Characters[characterId] then
        return false
    end

    profile.ActiveCharacter = characterId
    LaunchManager.RecalculateCharacterBonus(player)

    -- クライアントに通知
    RemoteEvents.CharacterSelected:FireClient(player, characterId, profile.CharacterBonus)

    return true
end

-- キャラクター育成（レベルアップ）
function LaunchManager.UpgradeCharacter(player: Player, characterId: string): boolean
    local profile = DataManager.GetProfile(player)
    if not profile then return false end

    local char = profile.Characters and profile.Characters[characterId]
    if not char then return false end

    -- レベルアップコスト計算
    local upgradeCost = char.Level * 100

    if profile.Money < upgradeCost then
        return false
    end

    -- コイン消費
    DataManager.SpendMoney(player, upgradeCost)

    -- レベルアップ
    char.Level = char.Level + 1
    LaunchManager.RecalculateCharacterBonus(player)

    -- クライアントに通知
    RemoteEvents.CharacterUpgraded:FireClient(player, characterId, char.Level, profile.CharacterBonus)

    return true
end

-- キャラクターコレクション取得
function LaunchManager.GetCharacterCollection(player: Player)
    local profile = DataManager.GetProfile(player)
    if not profile then return nil end

    return {
        Characters = profile.Characters or {},
        ActiveCharacter = profile.ActiveCharacter,
        TotalCollected = profile.TotalCharactersCollected or 0,
        RainbowFound = profile.RainbowCharactersFound or 0,
    }
end

function LaunchManager.CharacterPickedUp(player: Player, characterId: string)
    print(string.format("[LaunchManager] %s が %s を所有", player.Name, characterId))
end

-- 初期化
function LaunchManager.Initialize()
    -- 発射リクエスト受信
    RemoteEvents.LaunchRequest.OnServerEvent:Connect(function(player, gaugePosition)
        LaunchManager.ProcessLaunch(player, gaugePosition)
    end)

    -- グローバル統計取得
    RemoteEvents.GetGlobalStats.OnServerInvoke = function(player)
        return LaunchManager.GetGlobalStats()
    end

    -- キャラクターコレクション取得
    RemoteEvents.GetCharacterCollection.OnServerInvoke = function(player)
        return LaunchManager.GetCharacterCollection(player)
    end

    -- キャラクター選択
    RemoteEvents.CharacterSelected.OnServerEvent:Connect(function(player, characterId)
        LaunchManager.SelectCharacter(player, characterId)
    end)
    
    -- キャラクターを手元に拾う
    RemoteEvents.CharacterPickedUp.OnServerEvent:Connect(function(player, characterId)
        LaunchManager.CharacterPickedUp(player, characterId)
    end)
    -- キャラクター育成
    RemoteEvents.CharacterUpgraded.OnServerEvent:Connect(function(player, characterId)
        LaunchManager.UpgradeCharacter(player, characterId)
    end)

    -- キャラクター取り外し
    RemoteEvents.CharacterRemoved.OnServerEvent:Connect(function(player, characterId, slotName)
        print(string.format("[LaunchManager] %s が %s を %s から取り外し", player.Name, characterId, slotName))
    end)

    print("[LaunchManager] 初期化完了")
end

return {
    LaunchManager = LaunchManager,
    LAUNCH_CONFIG = LAUNCH_CONFIG,
    GlobalState = GlobalState,
}
