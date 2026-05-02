--[[
    RemoteFunctions
    クライアント・サーバー間通信用のRemoteEvent定義
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteFunctions = {}

-- RemoteFunctionsフォルダを作成（サーバーで実行時）
local function getOrCreateFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "RemoteFunctions"
        folder.Parent = ReplicatedStorage
    end
    return folder
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

RemoteFunctions.CharacterPlaced = getOrCreateRemoteFunction("CharacterPlaced")  -- キャラクターをスロットに配置
return RemoteFunctions
