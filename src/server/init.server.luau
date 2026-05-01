--[[
    Brainrot Launch Simulator サーバーメインスクリプト
    - DataManager: プレイヤーデータ管理
    - LaunchManager: 発射システム & グローバルイベント
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- モジュール読み込み待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")

local DataManager = require(script.Modules.DataManager)
local LaunchModule = require(script.Modules.LaunchManager)
local LaunchManager = LaunchModule.LaunchManager
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

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

print("[Server] 初期化完了")
