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
RemoteEvents.FishingPowerChanged = getOrCreateRemoteEvent("FishingPowerChanged")
RemoteEvents.RodRankChanged = getOrCreateRemoteEvent("RodRankChanged")
RemoteEvents.AreaUnlockRequest = getOrCreateRemoteEvent("AreaUnlockRequest")
RemoteEvents.AreaUnlocked = getOrCreateRemoteEvent("AreaUnlocked")

-- ブレインロットキャラクター関連イベント
RemoteEvents.CharacterCollected = getOrCreateRemoteEvent("CharacterCollected")  -- キャラクター獲得通知
RemoteEvents.CharacterPickedUp = getOrCreateRemoteEvent("CharacterPickedUp")    -- キャラクターを拾う
RemoteEvents.CharacterSpawned = getOrCreateRemoteEvent("CharacterSpawned")  -- キャラクター3Dモデル生成
RemoteEvents.CharacterRemoved = getOrCreateRemoteEvent("CharacterRemoved")  -- キャラクター取り外し

-- 関数定義
RemoteEvents.GetPlayerData = getOrCreateRemoteFunction("GetPlayerData")
return RemoteEvents
