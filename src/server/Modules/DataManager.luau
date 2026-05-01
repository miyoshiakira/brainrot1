--[[
    DataManager
    プレイヤーデータの読み込み・保存・セッション管理
    ProfileStore風のセッションロックと自動保存を実装
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local ProfileTemplate = require(game.ReplicatedStorage.Shared.ProfileTemplate)

local DataManager = {}
DataManager.__index = DataManager

-- 設定
local DATA_STORE_NAME = "HybridTycoon_PlayerData_v1"
local AUTO_SAVE_INTERVAL = 60  -- 60秒ごとに自動保存
local SESSION_LOCK_TIMEOUT = 1800  -- 30分でセッションロック解除

-- Studio環境かどうかを判定
local IS_STUDIO = RunService:IsStudio()

-- データストア（本番環境のみ）
local PlayerDataStore = nil
if not IS_STUDIO then
    PlayerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
else
    print("[DataManager] Studio環境: ローカルデータモードで動作")
end

-- プレイヤーデータキャッシュ
local PlayerProfiles: {[Player]: ProfileData} = {}
local SessionLocks: {[Player]: boolean} = {}

export type ProfileData = typeof(ProfileTemplate)

-- データの再帰的マージ（Reconcile）
local function reconcileData(data: any, template: any): any
    if typeof(template) ~= "table" then
        return data ~= nil and data or template
    end

    if typeof(data) ~= "table" then
        data = {}
    end

    local result = {}
    for key, templateValue in pairs(template) do
        result[key] = reconcileData(data[key], templateValue)
    end

    return result
end

-- データ読み込み
function DataManager.LoadProfile(player: Player): ProfileData?
    local userId = player.UserId
    local key = "Player_" .. userId
    local data = nil

    -- Studio環境ではDataStoreをスキップ
    if IS_STUDIO then
        print("[DataManager] Studio環境: 新規プロファイルを作成 (テスト用に$50付与)")
        data = { Money = 50 }  -- テスト用初期資金
    else
        local success, result = pcall(function()
            return PlayerDataStore:GetAsync(key)
        end)

        if not success then
            warn("[DataManager] データ読み込み失敗:", player.Name, result)
            return nil
        end
        data = result
    end

    -- 新規プレイヤーまたはデータマージ
    local profile = reconcileData(data or {}, ProfileTemplate)

    -- 放置報酬の計算
    if profile.LastOnlineTime > 0 then
        local currentTime = os.time()
        local offlineTime = currentTime - profile.LastOnlineTime
        local maxOfflineTime = 8 * 60 * 60  -- 最大8時間
        offlineTime = math.min(offlineTime, maxOfflineTime)

        if offlineTime > 60 then  -- 1分以上オフラインなら報酬
            local offlineEarnings = math.floor(offlineTime * profile.OfflineEarningsRate)
            profile.Money += offlineEarnings
            profile.TotalMoneyEarned += offlineEarnings
            print(string.format("[DataManager] %s に放置報酬 %d コインを付与 (オフライン %d 秒)",
                player.Name, offlineEarnings, offlineTime))
        end
    end

    -- セッション情報更新
    profile.SessionCount += 1
    profile.LastOnlineTime = os.time()

    -- キャッシュに保存
    PlayerProfiles[player] = profile
    SessionLocks[player] = true

    print("[DataManager] プロファイル読み込み完了:", player.Name)
    return profile
end

-- データ保存
function DataManager.SaveProfile(player: Player): boolean
    local profile = PlayerProfiles[player]
    if not profile then
        return false
    end

    local userId = player.UserId
    local key = "Player_" .. userId

    -- 最終オンライン時刻を更新
    profile.LastOnlineTime = os.time()

    -- Studio環境ではDataStoreをスキップ
    if IS_STUDIO then
        print("[DataManager] Studio環境: データ保存スキップ (ローカルのみ)")
        return true
    end

    local success, err = pcall(function()
        PlayerDataStore:SetAsync(key, profile)
    end)

    if not success then
        warn("[DataManager] データ保存失敗:", player.Name, err)
        return false
    end

    print("[DataManager] データ保存完了:", player.Name)
    return true
end

-- プロファイル取得
function DataManager.GetProfile(player: Player): ProfileData?
    return PlayerProfiles[player]
end

-- お金の増減（サーバーサイドで検証）
function DataManager.AddMoney(player: Player, amount: number): boolean
    local profile = PlayerProfiles[player]
    if not profile then
        return false
    end

    profile.Money += amount
    if amount > 0 then
        profile.TotalMoneyEarned += amount
    end

    return true
end

-- お金の消費（残高チェック付き）
function DataManager.SpendMoney(player: Player, amount: number): boolean
    local profile = PlayerProfiles[player]
    if not profile then
        return false
    end

    if profile.Money < amount then
        return false
    end

    profile.Money -= amount
    return true
end

-- オブジェクトのアンロック
function DataManager.UnlockObject(player: Player, objectId: string): boolean
    local profile = PlayerProfiles[player]
    if not profile then
        return false
    end

    profile.UnlockedObjects[objectId] = true
    return true
end

-- オブジェクトがアンロック済みかチェック
function DataManager.IsObjectUnlocked(player: Player, objectId: string): boolean
    local profile = PlayerProfiles[player]
    if not profile then
        return false
    end

    return profile.UnlockedObjects[objectId] == true
end

-- セッションロック解除
function DataManager.ReleaseProfile(player: Player)
    DataManager.SaveProfile(player)
    PlayerProfiles[player] = nil
    SessionLocks[player] = nil
    print("[DataManager] セッション解放:", player.Name)
end

-- プレイヤー入退室のハンドリング
Players.PlayerAdded:Connect(function(player)
    DataManager.LoadProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
    DataManager.ReleaseProfile(player)
end)

-- 自動保存ループ
task.spawn(function()
    while true do
        task.wait(AUTO_SAVE_INTERVAL)
        for player, profile in pairs(PlayerProfiles) do
            if player.Parent then  -- まだゲーム内にいる
                DataManager.SaveProfile(player)
            end
        end
    end
end)

-- ゲーム終了時の緊急保存
game:BindToClose(function()
    for player, _ in pairs(PlayerProfiles) do
        DataManager.ReleaseProfile(player)
    end
end)

return DataManager
