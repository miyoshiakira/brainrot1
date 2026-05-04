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
local MonsterManager = require(script.Modules.MonsterManager)
local PlayerBaseController = require(script.Modules.PlayerBaseController)

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
            LegPower = profile.LegPower,
            Height = profile.Height,
            TotalCharactersCollected = profile.TotalCharactersCollected or 0,
            RainbowCharactersFound = profile.RainbowCharactersFound or 0,
        }
    end
    return nil
end

-- MoneyBoxの参照取得
local CommonFunctions = require(script.Modules.CommonFunctions)
local moneyBox = CommonFunctions.findModelById(game.workspace, "MoneyBox")

local CollectionService = game:GetService("CollectionService")


-- プレイヤー退室処理（スロット同期後にDataManagerが保存）
Players.PlayerRemoving:Connect(function(player)
    local slots = PlayerBaseController.FindPlayerSlots(player)
    if slots then
        DataManager.SaveSlotData(player, slots)
    end
end)

-- プレイヤー入室処理
Players.PlayerAdded:Connect(function(player)
    print("[Server] プレイヤー入室:", player.Name)

    -- PlayerBaseをCloneして配置
    PlayerBaseController.SetupPlayerBase(player)

    -- Leaderstatsを作成
    LaunchManager.CreateLeaderstats(player)

    -- データ読み込み完了を待機
    local profile = DataManager.WaitForProfile(player)
    if profile then
        -- Leaderstatsを更新
        LaunchManager.UpdateLeaderstats(player)

        -- 保存済みのスロット配置を復元（プロファイル読み込み後であること）
        PlayerBaseController.RestoreSlots(player)

        -- 初期お金を通知
        RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        RemoteEvents.HeightChanged:FireClient(player, profile.Height)
        RemoteEvents.LegPowerChanged:FireClient(player, profile.LegPower)

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

-- 自動保存（3分ごとにスロット同期＋プロファイル保存）
task.spawn(function()
    while true do
        task.wait(180)
        for _, player in ipairs(Players:GetPlayers()) do
            local profile = DataManager.GetProfile(player)
            if profile then
                -- 保存前にスロットデータをプロファイルに同期
                local slots = PlayerBaseController.FindPlayerSlots(player)
                if slots then
                    DataManager.SaveSlotData(player, slots)
                end
                DataManager.SaveProfile(player)
            end
        end
    end
end)

print("[Server] 初期化完了")
