--[[
    RemoteEvents
    クライアント・サーバー間通信用のRemoteEvent定義
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

-- RemoteEventsフォルダを作成（サーバーで実行時）
local function getOrCreateFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "RemoteEvents"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

-- RemoteEventを取得または作成
local function getOrCreateRemoteEvent(name: string): RemoteEvent
    local folder = getOrCreateFolder()
    local remote = folder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
    end
    return remote :: RemoteEvent
end

-- RemoteFunctionを取得または作成
local function getOrCreateRemoteFunction(name: string): RemoteFunction
    local folder = getOrCreateFolder()
    local remote = folder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteFunction")
        remote.Name = name
        remote.Parent = folder
    end
    return remote :: RemoteFunction
end

-- イベント定義
RemoteEvents.MoneyChanged = getOrCreateRemoteEvent("MoneyChanged")
RemoteEvents.ObjectUnlocked = getOrCreateRemoteEvent("ObjectUnlocked")
RemoteEvents.NotifyPlayer = getOrCreateRemoteEvent("NotifyPlayer")

-- Brainrot Launch Simulator用イベント
RemoteEvents.HeightChanged = getOrCreateRemoteEvent("HeightChanged")
RemoteEvents.LaunchRequest = getOrCreateRemoteEvent("LaunchRequest")  -- クライアント→サーバー: ゲージ位置を送信
RemoteEvents.LaunchResult = getOrCreateRemoteEvent("LaunchResult")    -- サーバー→クライアント: 発射結果
RemoteEvents.RainbowRainStart = getOrCreateRemoteEvent("RainbowRainStart")  -- グローバルイベント開始
RemoteEvents.RainbowRainEnd = getOrCreateRemoteEvent("RainbowRainEnd")      -- グローバルイベント終了
RemoteEvents.GlobalHeightUpdate = getOrCreateRemoteEvent("GlobalHeightUpdate")  -- サーバー全体の高度更新

-- ブレインロットキャラクター関連イベント
RemoteEvents.CharacterCollected = getOrCreateRemoteEvent("CharacterCollected")  -- キャラクター獲得通知
RemoteEvents.CharacterSelected = getOrCreateRemoteEvent("CharacterSelected")    -- キャラクター選択
RemoteEvents.CharacterPickedUp = getOrCreateRemoteEvent("CharacterPickedUp")    -- キャラクターを拾う
RemoteEvents.CharacterUpgraded = getOrCreateRemoteEvent("CharacterUpgraded")  -- キャラクター育成
RemoteEvents.CharacterPlaced = getOrCreateRemoteEvent("CharacterPlaced")  -- キャラクターをスロットに配置のイベント
RemoteEvents.CharacterSpawned = getOrCreateRemoteEvent("CharacterSpawned")  -- キャラクター3Dモデル生成
RemoteEvents.CharacterRemoved = getOrCreateRemoteEvent("CharacterRemoved")  -- キャラクター取り外し

-- 関数定義
RemoteEvents.GetPlayerData = getOrCreateRemoteFunction("GetPlayerData")
RemoteEvents.GetGlobalStats = getOrCreateRemoteFunction("GetGlobalStats")  -- グローバル統計取得
RemoteEvents.GetCharacterCollection = getOrCreateRemoteFunction("GetCharacterCollection")  -- キャラクターコレクション取得
RemoteEvents.CharacterPlaced = getOrCreateRemoteFunction("CharacterPlaced")  -- キャラクターをスロットに配置
return RemoteEvents
