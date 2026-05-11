local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonFunctions = require(script.Parent.CommonFunctions)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
local constants = require("../Constants")

local Initialize = function()
    RemoteFunctions.ThrowAction.OnServerInvoke = ThrowAction
    RemoteFunctions.PickUpAction.OnServerInvoke = PickUpAction
    RemoteFunctions.PutDownAction.OnServerInvoke = PutDownAction
end

-- 内部関数：プロンプトの設定
local function setUpPickUpAction(monster)
    -- 既存のプロンプトを確認
    local existingPrompt = monster:FindFirstChildOfClass("ProximityPrompt")
    
    if not existingPrompt then
        print("[FishBox]: プロンプト設定開始")
        local prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = "モンスター"
        prompt.ActionText = "ひろう"
        prompt.MaxActivationDistance = 10
        prompt.Parent = monster
        
        prompt.Triggered:Connect(function(player)
            PickUpAction(player, monster)
        end)
        
        print("[FishBox]: プロンプト設定完了")
    end
end

function ThrowAction(player)
    local character = player.Character
    if not character then return false end
    
    local carriedTarget = character:FindFirstChild(constants.CHARACTER_MODEL_NAME)
    print("[ThrowAction] carriedTarget:", carriedTarget)
    if not carriedTarget then return false end

    -- 1. carriedTargetが存在し、かつそれがモデルである場合を想定
    if carriedTarget and carriedTarget:IsA("Model") then 
        local targetRoot = carriedTarget.PrimaryPart -- キャラクターのメインパーツを取得
        
        if targetRoot then
            -- 拘束を解除
            CommonFunctions.dettachCharacter(player)
            
            -- 投げる力を計算
            local direction = character.HumanoidRootPart.CFrame.LookVector
            local force = (direction * 100) + Vector3.new(0, 50, 0) -- 力が足りない場合は数値を調整
            
            -- 2. モデルではなく、パーツに対してApplyImpulseを実行
            targetRoot:ApplyImpulse(force * targetRoot:GetMass())
            -- 3. ネットワークオーナーシップをリセット（物理挙動を滑らかにする）
            targetRoot:SetNetworkOwner(nil) -- サーバー側で実行している場合のみ推奨
            -- 4. ひろうアクションのセット
            setUpPickUpAction(carriedTarget)
            carriedTarget.Parent = game.Workspace
            -- 効果音
            CommonFunctions.PlayAudioByNameAt("UISE", game.Workspace)
            return true
        end
    end
    
    return false
end

function PutDownAction(player)
    local character = player.Character
    if not character then return false end
    
    local carriedTarget = character:FindFirstChild(constants.CHARACTER_MODEL_NAME)
    print("[PutDownAction] carriedTarget:", carriedTarget)
    if not carriedTarget then return false end

    -- 1. carriedTargetが存在し、かつそれがモデルである場合を想定
    if carriedTarget and carriedTarget:IsA("Model") then 
        local targetRoot = carriedTarget.PrimaryPart -- キャラクターのメインパーツを取得
        
        if targetRoot then
            -- 拘束を解除
            CommonFunctions.dettachCharacter(player)
            
            -- 投げる力を計算
            local direction = character.HumanoidRootPart.CFrame.LookVector
            local force = (direction * 1) + Vector3.new(0, 10, 0) -- 力が足りない場合は数値を調整
            
            -- 2. モデルではなく、パーツに対してApplyImpulseを実行
            targetRoot:ApplyImpulse(force * targetRoot:GetMass())
            -- 3. ネットワークオーナーシップをリセット（物理挙動を滑らかにする）
            targetRoot:SetNetworkOwner(nil) -- サーバー側で実行している場合のみ推奨
            -- 4. ひろうアクションのセット
            setUpPickUpAction(carriedTarget)
            carriedTarget.Parent = game.Workspace
            -- 効果音
            CommonFunctions.PlayAudioByNameAt("UISE", game.Workspace)
            return true
        end
    end
    
    return false
end

function PickUpAction(player, monster)

    if CommonFunctions.isCarrying(player) then
        print(string.format("[FishingAction] %s は既にキャラクターを運んでいます！", player.Name))
        return false
    end

    local character = player.Character
    local humanoidRootPart = character.PrimaryPart
    if not character or not humanoidRootPart then return false end
    
    local carriedTarget = monster
    if not carriedTarget then return false end
    
    -- 初期化（固定解除）
    carriedTarget.Parent = game.Workspace
    -- プレイヤーの前に配置
    carriedTarget:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 2, -3))
    carriedTarget.Parent = character
    -- プレイヤーのHumanoidRootPartにWeldを付与
    CommonFunctions.attachWithWeld(character, carriedTarget, CommonFunctions.CharacterWeld)
    -- ひろうボタンの削除
    CommonFunctions.dettachButton(carriedTarget)
    -- 効果音
    CommonFunctions.PlayAudioByNameAt("UISE", game.Workspace)
    return true
end



return {
    Initialize = Initialize,
    PutDownAction = PutDownAction,
}
