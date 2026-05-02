local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local constants = require("../Constants")
-- モジュール読み込み待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")

local DataManager = require(script.Parent.DataManager)
-- LaunchManagerなどは既存のまま
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
-- 配置時の高さオフセット（浮いている場合はここを下げる）
local Y_OFFSET = 3.0 -- 2.0から1.0に調整。モデルのPivot位置に合わせて微調整してください
-- モデルに関わる物理的な結合をすべて解除し、静止状態にする
local function clearAllWelds(model: Instance)
    if not model then return end

    -- 1. モデル内の全オブジェクトを走査（子要素としてのWeldを破壊）
    for _, descendant in ipairs(model:GetDescendants()) do
        -- すべての溶接・制約系をターゲットにする
        if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") or descendant:IsA("CharacterWeld") then
            descendant:Destroy()
        end
    end
    
    -- 念のため、親をWorkspaceまたはSlotに変更して物理的な親子関係をリセット
    -- (この関数を呼んだ直後に Parent = slot するのがベスト)
end
-- モデルの物理設定
local function setModelPhysics(model, anchored, canCollide)
    if model:IsA("BasePart") then
        model.Anchored = anchored
        model.CanCollide = canCollide
        model.Massless = not anchored
    else
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = anchored
                part.CanCollide = canCollide
                part.Massless = not anchored
            end
        end
    end
end
-- キャラクターをスロットに配置（RemoteFunction）
RemoteFunctions.CharacterPlaceTry.OnServerInvoke = function(player, heldModel, slot)
    -- 1. バリデーション
    local profile = DataManager.GetProfile(player)
    local playerCharacter = player.Character
    if not profile or not heldModel or not slot then
        return { success = false, error = "Invalid Request" }
    end

    if slot:GetAttribute("Occupied") then
        return { success = false, error = "Slot already occupied" }
    end

    local characterId = heldModel:GetAttribute("CharacterId")
    if not characterId or not profile.Characters[characterId] then
        return { success = false, error = "Character data missing" }
    end
    -------------------------------------------------------
    -- 物理的な配置処理
    -------------------------------------------------------
    -- 結合解除（親リセット）
    heldModel.Parent = game.Workspace
    -- スロットの位置へ移動
    local targetCFrame = slot.CFrame * CFrame.new(0, Y_OFFSET, 0)
    heldModel:PivotTo(targetCFrame)
    -- プレイヤーのHumanoidRootPartからWeldを解除
    local humanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    clearAllWelds(humanoidRootPart)
    -- スロットへ固定処理
    setModelPhysics(heldModel, true, false)
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
RemoteFunctions.CharacterPickupTry.OnServerInvoke = function(player, slot)
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
    -- PrimaryPartを取得（Weld用）
    local primaryPart = charModel.PrimaryPart or charModel:FindFirstChild("Body") or (charModel:IsA("BasePart") and charModel)

    -- 初期化（固定解除）
    charModel.Parent = game.Workspace
    -- プレイヤーの前に配置
    charModel:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 2, -3))
    charModel.Parent = character
    -- 全パーツの物理設定（スロットから解除）
    setModelPhysics(charModel, false, false)
    
    -- Weldでプレイヤーに持たせる
    local weld = Instance.new("WeldConstraint")
    weld.Name = "CharacterWeld"
    weld.Part0 = humanoidRootPart
    weld.Part1 = primaryPart
    weld.Parent = humanoidRootPart

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
        weld = weld,
    }
end

return {
    RemoteFunctions = RemoteFunctions
}
