local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonFunctions = require(script.Parent.CommonFunctions)
local DataManager = require(script.Parent.DataManager)
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters).BrainrotMonsters
local MonsterManager = require(script.Parent.MonsterManager)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

-- 釣り設定
local FISHING_CONFIG = {
    CharacterDropRate = 1.0, -- 釣りの時のキャラクタドロップ率
}

local function ProcessFishing(player, fishBox)
    
    if CommonFunctions.isCarrying(player) then
        print(string.format("[FishingAction] %s は既にキャラクターを運んでいます！", player.Name))
        return false
    end

    local profile = DataManager.GetProfile(player)
    if not profile then return false end

    -- ドロップ判定
    if math.random() > FISHING_CONFIG.CharacterDropRate then
        return false
    end

    -- レアリティ決定 (釣り用の特別確率にするか、Launchと同じにするか)
    -- ここではLaunchと同じRollCharacterを使用
    local rarity = BrainrotMonsters.RollCharacter(false)
    if not rarity then return false end

    -- キャラクター選択
    local characters = BrainrotMonsters.GetCharactersByRarity(rarity, profile.Height or 0)
    if #characters == 0 then return false end

    local selectedChar = characters[math.random(1, #characters)]
    profile.TotalCharactersCollected = (profile.TotalCharactersCollected or 0) + 1

    if rarity == "Rainbow" then
        profile.RainbowCharactersFound = (profile.RainbowCharactersFound or 0) + 1
    end

    -- キャラクターをプレイヤーに持たせる
    MonsterManager.SpawnCharacterModel(player, selectedChar.MonsterId)

    -- クライアントに獲得通知 (Launchと同じ)
    RemoteEvents.CharacterCollected:FireClient(player, selectedChar.MonsterId)

    print(string.format("[FishingAction] %s が釣りで %s (%s) を獲得！", player.Name, selectedChar.MonsterId, rarity))
    
    return true
end

return {
    ProcessFishing = ProcessFishing,
}