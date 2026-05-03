local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonFunctions = require(script.Parent.CommonFunctions)
local constants = require("../Constants")
-- モジュール読み込み待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")

local DataManager = require(script.Parent.DataManager)
-- LaunchManagerなどは既存のまま
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
-- 配置時の高さオフセット（浮いている場合はここを下げる）
local Y_OFFSET = 3.0 -- 2.0から1.0に調整。モデルのPivot位置に合わせて微調整してください

-- キャラクターをスロットに配置（RemoteFunction）
RemoteFunctions.CharacterPlaceTry.OnServerInvoke = function(player, heldModelName, slotName)
    -- 1. バリデーション
    local profile = DataManager.GetProfile(player)
    local heldModel = CommonFunctions.findModelById(player.Character, heldModelName)
    local slot = CommonFunctions.findModelById(game.workspace, slotName)
    if not profile or not heldModel or not slot then
        print('パラメータ不足')
        return { success = false, error = "Invalid Request" }
    end

    local characterId = heldModel:GetAttribute("CharacterId")
    if not characterId or not profile.Characters[characterId] then
        print('キャラクターID不正')
        return { success = false, error = "Character data missing" }
    end
    -------------------------------------------------------
    -- 物理的な配置処理
    -------------------------------------------------------
    -- スロットへ固定処理
    CommonFunctions.enableAnchor(heldModel, false)
    -- プレイヤーのHumanoidRootPartからWeldを解除
    CommonFunctions.dettachCharacter(player)
    -- 結合解除（親リセット）
    heldModel.Parent = game.Workspace
    -- スロットの位置へ移動
    local targetCFrame = slot.CFrame * CFrame.new(0, Y_OFFSET, 0)
    heldModel:PivotTo(targetCFrame)
    -- スロットへ固定処理
    CommonFunctions.enableAnchor(heldModel, true)
    heldModel.Parent = slot
    -------------------------------------------------------
    -- データの更新処理
    -------------------------------------------------------
    profile.ActiveCharacter = characterId
    
    -- スロットの状態更新
    print(string.format("[Server] Setting CharacterId to %s", characterId))
    slot:SetAttribute("CharacterId", characterId)
    slot:SetAttribute("Occupied", true)
    slot:SetAttribute("Owner", player.UserId)

    -- ボーナス適用
    local characterData = profile.Characters[characterId]
    if characterData and characterData.Bonus then
        profile.CharacterBonus = characterData.Bonus
    end

    print(string.format("[Server] %s placed %s on %s", player.Name, characterId, slot.Name))

    return {
        success = true,
        activeCharacter = characterId,
        characterBonus = profile.CharacterBonus
    }
end

-- キャラクターをスロットからとりあげる（RemoteFunction）
RemoteFunctions.CharacterPickupTry.OnServerInvoke = function(player, slotName)

    local slot = CommonFunctions.findModelById(game.workspace, slotName)
    -- 1. バリデーション
    local profile = DataManager.GetProfile(player)
    if not profile then
        return { success = false, errorMessage = "Invalid Request" }
    end
    -------------------------------------------------------
    -- 物理的な配置処理
    -------------------------------------------------------
    -- 1. 名前を指定してピンポイント破壊
    local charModel = slot:FindFirstChild(constants.CHARACTER_MODEL_NAME)
    if not charModel then return nil end
    
    local character = player.Character
    if not character then return nil end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end

    -- 初期化（固定解除）
    charModel.Parent = game.Workspace
    -- プレイヤーの前に配置
    charModel:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 2, -3))
    charModel.Parent = character
    -- プレイヤーのHumanoidRootPartにWeldを付与
    CommonFunctions.attachWithWeld(character, charModel, CommonFunctions.CharacterWeld)
    -- スロットから解除
    CommonFunctions.enableAnchor(charModel, false)
    -------------------------------------------------------
    -- データの更新処理
    -------------------------------------------------------
    profile.ActiveCharacter = nil
    
    -- スロットの状態更新
    local characterId = slot:GetAttribute("CharacterId")
    print(string.format("[Server] Getting CharacterId to %s", characterId))
    slot:SetAttribute("CharacterId", nil)
    slot:SetAttribute("Occupied", false)
    slot:SetAttribute("Owner", nil)

    print(string.format("[Server] %s got %s on %s", player.Name, characterId, slot.Name))

    return {
        success = true,
        errorMessage = "",
        heldModel = charModel,
    }
end

return {
    RemoteFunctions = RemoteFunctions
}
