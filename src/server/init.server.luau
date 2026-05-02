--[[
    Brainrot Launch Simulator サーバーメインスクリプト
    - DataManager: プレイヤーデータ管理
    - LaunchManager: 発射システム & グローバルイベント
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- モジュール読み込み待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")

local DataManager = require(script.Modules.DataManager)
local LaunchModule = require(script.Modules.LaunchManager)
local LaunchManager = LaunchModule.LaunchManager
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
-- CharacterController を読み込む
-- これにより、CharacterController.luau 内の OnServerInvoke が登録される
local _CharacterController = require(script.Modules.CharacterController)

print("CharacterController has been initialized.")
print("=================================")
print("Brainrot Launch Simulator サーバー起動")
print("=================================")

-- プレイヤーデータ取得（RemoteFunction）
RemoteEvents.GetPlayerData.OnServerInvoke = function(player)
    local profile = DataManager.GetProfile(player)
    if profile then
        return {
            Money = profile.Money,
            Height = profile.Height,
            TotalHeight = profile.TotalHeight,
            CharacterBonus = profile.CharacterBonus,
            BasePower = profile.BasePower,
            Characters = profile.Characters or {},
            ActiveCharacter = profile.ActiveCharacter,
            TotalCharactersCollected = profile.TotalCharactersCollected or 0,
            RainbowCharactersFound = profile.RainbowCharactersFound or 0,
        }
    end
    return nil
end

-- プレイヤー入室処理
Players.PlayerAdded:Connect(function(player)
    print("[Server] プレイヤー入室:", player.Name)

    -- Leaderstatsを作成
    LaunchManager.CreateLeaderstats(player)

    -- データ読み込み待機
    task.wait(1)

    local profile = DataManager.GetProfile(player)
    if profile then
        -- Leaderstatsを更新
        LaunchManager.UpdateLeaderstats(player)

        -- パッシブコイン生成を開始
        LaunchManager.StartPassiveCoins(player)

        -- 初期お金を通知
        RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        RemoteEvents.HeightChanged:FireClient(player, profile.Height)

        -- 放置報酬があれば通知
        if profile.SessionCount > 1 then
            RemoteEvents.NotifyPlayer:FireClient(player, "おかえりなさい！", "セッション #" .. profile.SessionCount)
        end
    end


end)

-- お金が変わったときの通知（DataManagerから呼び出し可能にする）
local originalAddMoney = DataManager.AddMoney
DataManager.AddMoney = function(player: Player, amount: number): boolean
    local result = originalAddMoney(player, amount)
    if result then
        local profile = DataManager.GetProfile(player)
        if profile then
            RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        end
    end
    return result
end

local originalSpendMoney = DataManager.SpendMoney
DataManager.SpendMoney = function(player: Player, amount: number): boolean
    local result = originalSpendMoney(player, amount)
    if result then
        local profile = DataManager.GetProfile(player)
        if profile then
            RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        end
    end
    return result
end

-- LaunchManagerを初期化
LaunchManager.Initialize()

local CollectionService = game:GetService("CollectionService")

-- スロットの挙動を初期化する関数
local function setupSlot(slot)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = slot
    prompt.ObjectText = "スロット"
    prompt.ActionText = "配置する"    
    prompt.Triggered:Connect(function(player)
        -- ここに「持っているものを置く」共通ロジック
        -- クライアントに通知
        local success = RemoteFunctions.SlotActionTrigger:InvokeClient(player, {
            Slot = slot,
        })
        local characterId = slot:GetAttribute("CharacterId")
        print(string.format("characterId: %s", tostring(characterId)))
        if characterId then
            prompt.ActionText = "ひろう"
        else
            prompt.ActionText = "配置する"
        end
    end)
end

-- 既存の全スロットに適用
for _, slot in ipairs(CollectionService:GetTagged("SlotPart")) do
    setupSlot(slot)
end

-- 後から生成されたスロットにも自動適用（エンジニアらしい設計）
CollectionService:GetInstanceAddedSignal("SlotPart"):Connect(setupSlot)

print("[Server] 初期化完了")
