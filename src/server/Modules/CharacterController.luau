local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CommonFunctions = require(script.Parent.CommonFunctions)
local constants = require("../Constants")
-- モジュール読み込み待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")

local DataManager = require(script.Parent.DataManager)
local PlayerBaseController = require(script.Parent.PlayerBaseController)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
-- 配置時の高さオフセット（浮いている場合はここを下げる）
local Y_OFFSET = 5.0 -- 2.0から1.0に調整。モデルのPivot位置に合わせて微調整してください

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

    -- アニメーション中は操作不可
    if heldModel:GetAttribute("IsAnimating") then
        return { success = false, error = "アニメーション中です" }
    end

    local monsterId = heldModel:GetAttribute("MonsterId")
    if not monsterId then
        print('キャラクターID不正')
        return { success = false, error = "Character data missing" }
    end
    print(string.format("[Server] Try Place %s", monsterId))
    -- 物理的な配置処理
    -------------------------------------------------------
    -- 1. 結合解除とアンカー解除（物理演算が可能な状態にする）
    heldModel.Parent = game.Workspace
    CommonFunctions.dettachCharacter(player)
    
    -- 2. ネットワーク所有権をサーバーに強制奪還（アンカーがfalseのうちに実行！）
    -- ※これをAnchored=trueの後にやるとエラーになります
    if heldModel.PrimaryPart then
        heldModel.PrimaryPart:SetNetworkOwner(nil)
    end

    -- 3. 位置と回転の調整（スロットの前方を向くよう回転を強制）
    local slotCFrame = slot.PrimaryPart.CFrame
    local targetPosition = slotCFrame.Position + Vector3.new(0, Y_OFFSET, 0)
    local targetCFrame = CFrame.new(targetPosition, slotCFrame.LookVector * 1e6)
    heldModel:PivotTo(targetCFrame)
    -- 物理エンジンに「ここが新しい定位置だよ」と分からせるための短い猶予
    task.wait(0.1)
    CommonFunctions.enableAnchor(heldModel, true)
    heldModel.Parent = slot
    -------------------------------------------------------
    -- データの更新処理
    -------------------------------------------------------
    -- ひろうボタンの削除
    CommonFunctions.dettachButton(heldModel)
    -- スロットの状態更新
    print(string.format("[Server] Setting MonsterId to %s", monsterId))
    slot:SetAttribute("MonsterId", monsterId)
    slot:SetAttribute("Occupied", true)
    -- 強化ボタンの更新
    PlayerBaseController.setupUpgradeButton(slot)
    print(string.format("[Server] %s placed %s on %s", player.Name, monsterId, slot.Name))

    return {
        success = true,
        activeCharacter = monsterId,
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

    -- アニメーション中は操作不可
    if charModel:GetAttribute("IsAnimating") then
        return { success = false, errorMessage = "アニメーション中です" }
    end
    
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
    -------------------------------------------------------
    -- データの更新処理
    -------------------------------------------------------
    
    -- スロットの状態更新
    local monsterId = slot:GetAttribute("MonsterId")
    print(string.format("[Server] Getting MonsterId to %s", monsterId))
    slot:SetAttribute("MonsterId", nil)
    slot:SetAttribute("Occupied", false)
    -- 強化ボタンの更新
    PlayerBaseController.setupUpgradeButton(slot)
    print(string.format("[Server] %s got %s on %s", player.Name, monsterId, slot.Name))

    return {
        success = true,
        errorMessage = "",
        heldModel = charModel,
    }
end

return {
    RemoteFunctions = RemoteFunctions
}
