--[[
    DataManager
    プレイヤーデータの読み込み・保存・セッション管理
    ProfileStore風のセッションロックと自動保存を実装
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local ProfileModule = require(game.ReplicatedStorage.Shared.ProfileTemplate)
local ProfileTemplate = ProfileModule.ProfileTemplate
type Monster = ProfileModule.Monster

local DataManager = {}
DataManager.__index = DataManager

-- 設定
local DATA_STORE_NAME = "HybridTycoon_PlayerData_v1"
local DEV_DATA_STORE_NAME = "HybridTycoon_PlayerData_DEV"  -- Studio用（本番データと分離）
local _SESSION_LOCK_TIMEOUT = 1800  -- 30分でセッションロック解除

-- Studio環境かどうかを判定
local IS_STUDIO = RunService:IsStudio()

-- データストア（Studio環境でもDEVストアを使用）
local storeName = IS_STUDIO and DEV_DATA_STORE_NAME or DATA_STORE_NAME
local PlayerDataStore = DataStoreService:GetDataStore(storeName)
print(string.format("[DataManager] データストア: %s (%s環境)", storeName, IS_STUDIO and "Studio" or "本番"))

-- プレイヤーデータキャッシュ
local PlayerProfiles: {[Player]: ProfileData} = {}
local SessionLocks: {[Player]: boolean} = {}
local DirtyFlags: {[Player]: boolean} = {}
local SaveTimers: {[Player]: thread?} = {}
local DEBOUNCE_SAVE_DELAY = 5  -- 変更後5秒間追加変更がなければ保存

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
    -- テンプレートにあるキーをマージ
    for key, templateValue in pairs(template) do
        result[key] = reconcileData(data[key], templateValue)
    end

    -- テンプレートにないキーもデータからコピー（SlotDataなどの動的配列用）
    for key, dataValue in pairs(data) do
        if result[key] == nil then
            result[key] = dataValue
        end
    end

    return result
end

-- データ読み込み
function DataManager.LoadProfile(player: Player): ProfileData?
    local userId = player.UserId
    local key = "Player_" .. userId
    local data = nil

    -- DataStoreから読み込み（Studio環境でもDEVストアを使用）
    local success, result = pcall(function()
        return PlayerDataStore:GetAsync(key)
    end)

    if not success then
        warn("[DataManager] データ読み込み失敗:", player.Name, result)
        return nil
    end
    data = result

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

    -- DataStoreに保存（Studio環境でもDEVストアに保存）
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

    -- デバウンス保存（即時保存ではなく、5秒後に保存）
    DataManager.MarkDirty(player)

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

    -- デバウンス保存
    DataManager.MarkDirty(player)

    return true
end

-- スロット配置データを保存（PlayerBaseのスロット状態をプロファイルに反映）
function DataManager.SaveSlotData(player: Player, slots): boolean
    local profile: ProfileData? = PlayerProfiles[player]
    if not profile then
        return false
    end
    -- Monsterモデル作成
    local slotData: {[number]:Monster?} = {}

    for i, slot in ipairs(slots) do
        local monster = slot:FindFirstChild("DisplayMonster")
        if monster then
            -- ループの中などで追加する処理
            table.insert(slotData, {
                MonsterId = slot:GetAttribute("MonsterId"),
                MonsterName = monster:GetAttribute("MonsterName"),
                Level = monster:GetAttribute("Level"),
                Money = monster:GetAttribute("Money"),
                Bonus = monster:GetAttribute("Bonus"),
                Rarity = monster:GetAttribute("Rarity"),
                ModelName = monster:GetAttribute("ModelName"),
            })
        end
    end

    profile.SlotData = slotData
    print(string.format("[DataManager] スロットデータ同期完了: %s (%dスロット)", player.Name, #slotData))
    return true
end

-- スロット配置データを読み込み
function DataManager.LoadSlotData(player: Player): {[number]: Monster?}
    local profile = PlayerProfiles[player]
    if not profile then
        return {}
    end

    return profile.SlotData or {}
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

-- プロファイルに変更マークを付ける（デバウンス保存）
function DataManager.MarkDirty(player: Player)
    DirtyFlags[player] = true

    -- 既存のタイマーがあればキャンセル
    local existingTimer = SaveTimers[player]
    if existingTimer then
        task.cancel(existingTimer)
    end

    -- 新しいタイマーを開始
    SaveTimers[player] = task.delay(DEBOUNCE_SAVE_DELAY, function()
        SaveTimers[player] = nil
        if DirtyFlags[player] then
            DirtyFlags[player] = nil
            DataManager.SaveProfile(player)
        end
    end)
end

-- ダーティフラグを即座にフラッシュ（退室時などに使用）
function DataManager.FlushDirty(player: Player)
    local existingTimer = SaveTimers[player]
    if existingTimer then
        task.cancel(existingTimer)
        SaveTimers[player] = nil
    end
    if DirtyFlags[player] then
        DirtyFlags[player] = nil
        DataManager.SaveProfile(player)
    end
end

-- プロファイル読み込み完了を待機
function DataManager.WaitForProfile(player: Player, timeout: number?): ProfileData?
    local maxWait = timeout or 10
    local startTime = tick()
    while tick() - startTime < maxWait do
        local profile = PlayerProfiles[player]
        if profile then
            return profile
        end
        task.wait(0.1)
    end
    warn("[DataManager] プロファイル読み込みタイムアウト:", player.Name)
    return nil
end

-- セッションロック解除
function DataManager.ReleaseProfile(player: Player)
    DataManager.FlushDirty(player)
    DataManager.SaveProfile(player)
    PlayerProfiles[player] = nil
    SessionLocks[player] = nil
    DirtyFlags[player] = nil
    SaveTimers[player] = nil
    print("[DataManager] セッション解放:", player.Name)
end

-- プレイヤー入退室のハンドリング
Players.PlayerAdded:Connect(function(player)
    DataManager.LoadProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
    DataManager.ReleaseProfile(player)
end)

-- ゲーム終了時の緊急保存
game:BindToClose(function()
    for player, _ in pairs(PlayerProfiles) do
        DataManager.ReleaseProfile(player)
    end
end)

return DataManager
