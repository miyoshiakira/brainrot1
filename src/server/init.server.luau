local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- モジュール読み込み待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")

local DataManager = require(script.Modules.DataManager)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
local AreaMaster = require(ReplicatedStorage.Shared.AreaMaster)
-- CharacterController を読み込む
-- これにより、CharacterController.luau 内の OnServerInvoke が登録される
local _CharacterController = require(script.Modules.CharacterController)
local MonsterManager = require(script.Modules.MonsterManager)
local PlayerBaseController = require(script.Modules.PlayerBaseController)
local ThrowAction = require(script.Modules.ThrowAction)

print("CharacterController has been initialized.")
print("=================================")
print("Brainrot サーバー起動")
print("=================================")

-- プレイヤーデータ取得（RemoteFunction）
RemoteEvents.GetPlayerData.OnServerInvoke = function(player)
    local profile = DataManager.GetProfile(player)
    if profile then
        return {
            Money = profile.Money,
            FishingPower = profile.FishingPower,
            RodRank = tonumber(string.match(profile.EquippedRodName or "FishingRod1", "%d+")) or 1,
            TotalCharactersCollected = profile.TotalCharactersCollected or 0,
            RainbowCharactersFound = profile.RainbowCharactersFound or 0,
        }
    end
    return nil
end

-- MoneyBoxの参照取得
local CommonFunctions = require(script.Modules.CommonFunctions)
local moneyBox = CommonFunctions.findModelById(game.workspace, "MoneyBox")

local FishManager = require(script.Modules.FishManager)
local WhaleSharkEatLogic = require(script.Modules.WhaleSharkEatLogic)


-- プレイヤー退室処理（スロット同期後にDataManagerが保存）
Players.PlayerRemoving:Connect(function(player)
    local slots = PlayerBaseController.FindPlayerSlots(player)
    if slots then
        DataManager.SaveSlotData(player, slots)
    end

    -- 釣り竿名をプロファイルに保存
    local profile = DataManager.GetProfile(player)
    if profile then
        profile.EquippedRodName = require(script.Modules.EquipmentSystem).getFishingRodName(player)
    end
end)

-- プレイヤー入室処理
Players.PlayerAdded:Connect(function(player)
    print(string.format("[Server] プレイヤー入室: %s (UserId: %d)", player.Name, player.UserId))

    -- PlayerBaseをCloneして配置
    PlayerBaseController.SetupPlayerBase(player)

    -- データ読み込み完了を待機
    local profile = DataManager.WaitForProfile(player)
    if profile then

        -- 保存済みのスロット配置を復元（プロファイル読み込み後であること）
        PlayerBaseController.RestoreSlots(player)

        -- 釣り竿を装備（保存済みがなければFishingRod1）
        PlayerBaseController.EquipFishingRod(player)

        -- 初期お金を通知
        RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        RemoteEvents.FishingPowerChanged:FireClient(player, profile.FishingPower)

        -- 解放済みエリア一覧をクライアントに通知
        local unlockedAreas = {}
        if profile.UnlockedAreas then
            for areaName, _ in pairs(profile.UnlockedAreas) do
                table.insert(unlockedAreas, areaName)
            end
        end
        RemoteEvents.AreaUnlocked:FireClient(player, unlockedAreas)

        -- 放置報酬があれば通知
        if profile.SessionCount > 1 then
            RemoteEvents.NotifyPlayer:FireClient(player, "おかえりなさい！", "セッション #" .. profile.SessionCount)
        end
    end


end)

-- エリア解放処理（クライアントから要求受信）
RemoteEvents.AreaUnlocked.OnServerEvent:Connect(function(player, areaName)
    if type(areaName) ~= "string" then return end

    local profile = DataManager.GetProfile(player)
    if not profile then return end

    -- 既に解放済みならスキップ
    if profile.UnlockedAreas and profile.UnlockedAreas[areaName] then
        RemoteEvents.AreaUnlocked:FireClient(player, areaName)
        return
    end

    -- コスト検索（共通マスタから取得）
    local cost = AreaMaster.GetCost(areaName)
    if not cost then
        RemoteEvents.NotifyPlayer:FireClient(player, "⚠️ エラー", "不明なエリアです")
        return
    end

    -- 課金
    local success = DataManager.SpendMoney(player, cost)
    if not success then
        RemoteEvents.NotifyPlayer:FireClient(player, "⚠️ 所持金不足",
            string.format("エリア解放には %s 必要です", require(script.Modules.MonsterManager).FormatNumber(cost)))
        return
    end

    -- 解放フラグ保存
    if not profile.UnlockedAreas then
        profile.UnlockedAreas = {}
    end
    profile.UnlockedAreas[areaName] = true

    -- クライアントに通知（単一エリア名を送信 → クライアント側でAreaBlock破壊）
    RemoteEvents.AreaUnlocked:FireClient(player, areaName)
    RemoteEvents.NotifyPlayer:FireClient(player, "🗺️ エリア解放!", areaName .. " が解放されました！")

    print(string.format("[AreaUnlock] %s: %s 解放 (cost: %d)", player.Name, areaName, cost))
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

-- 釣りシステムを初期化
print("[Server] 釣りシステムを初期化")
FishManager.Initialize()
-- エリアブロック初期化
PlayerBaseController.setupAreaBlocks()
-- 投げシステムを初期化
print("[Server] 投げシステムを初期化")
ThrowAction.Initialize()
-- 鯨鲨喰らいシステムを初期化
print("[Server] 鯨鲨喰らいシステムを初期化")
WhaleSharkEatLogic.Initialize()
print("[Server] 初期化完了")

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
