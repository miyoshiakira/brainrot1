local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonFunctions = require(script.Parent.CommonFunctions)
local DataManager = require(script.Parent.DataManager)
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters).BrainrotMonsters
local MonsterManager = require(script.Parent.MonsterManager)
local EquipmentSystem = require(script.Parent.EquipmentSystem)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local FishingSplashEffect = require(script.Parent.FishingSplashEffect)

-- 釣り設定
local FISHING_CONFIG = {
    CharacterDropRate = 1.0, -- 釣りの時のキャラクタードロップ率
    AnimationDuration = 2.0, -- エフェクト再生中のロック時間
}

-- プレイヤーごとの釣りロック
local fishingLock: {[number]: boolean} = {}

local function ProcessFishing(player, fishBox)
    
    -- エフェクト再生中は釣り不可
    if fishingLock[player.UserId] then
        return false
    end

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

    -- Biomeに基づいてモンスター抽選 → レアリティ抽選（FishingPower・釣り竿ランクでボーナス）
    local biome = fishBox:GetAttribute("Biome")
    local rodRank = EquipmentSystem.getRodRank(player)
    local selectedChar, rarity = BrainrotMonsters.RollFromAvailablePool(false, biome, profile.FishingPower or 0, rodRank)
    if not selectedChar then return false end
    profile.TotalCharactersCollected = (profile.TotalCharactersCollected or 0) + 1

    if rarity == "Rainbow" then
        profile.RainbowCharactersFound = (profile.RainbowCharactersFound or 0) + 1
    end

    -- 釣りパワー上昇: (1～3のランダム) × レアリティランク × 釣り竿ランク
    local powerGain = math.random(1, 3) * BrainrotMonsters.GetRarityRank(rarity) * rodRank
    profile.FishingPower = (profile.FishingPower or 0) + powerGain

    -- 水しぶきエフェクト（ロック中は他の釣り不可）
    fishingLock[player.UserId] = true
    FishingSplashEffect.Play(fishBox:GetPivot())
    task.delay(FISHING_CONFIG.AnimationDuration, function()
        fishingLock[player.UserId] = nil
    end)

    -- キャラクターをプレイヤーに持たせる（rarityを渡す）
    MonsterManager.SpawnCharacterModel(player, selectedChar.MonsterId, rarity)

    -- クライアントに獲得通知（rarityも送信）
    RemoteEvents.CharacterCollected:FireClient(player, selectedChar.MonsterId, rarity)
    RemoteEvents.FishingPowerChanged:FireClient(player, profile.FishingPower)

    print(string.format("[FishingAction] %s が釣りで %s (%s) を獲得！ FishingPower +%d → %d", player.Name, selectedChar.MonsterId, rarity, powerGain, profile.FishingPower))
    
    return true
end

return {
    ProcessFishing = ProcessFishing,
}