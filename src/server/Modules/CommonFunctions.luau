local ServerScriptService = game:GetService("ServerScriptService")
local Constants = require(ServerScriptService.Server.Constants)
-- ServerScriptService/Server/Modules/CommonFunctions
local CharacterWeld = "CharacterWeld"
local CommonFunctions = { CharacterWeld = CharacterWeld }

-- 物理的な接続（Weld）を安全に行う共通関数
function CommonFunctions.dettachCharacter(player)
    -- プレイヤーのHumanoidRootPartからWeldを解除
    CommonFunctions.dettachWithWeld(player.Character, CharacterWeld)
end

-- 物理的な接続（Weld）を安全に行う共通関数
function CommonFunctions.dettachButton(target)
    -- プレイヤーのHumanoidRootPartからWeldを解除
    local targetButton = target:FindFirstChildOfClass("ProximityPrompt")
    if targetButton then
        targetButton:Destroy()
    end
end

-- 運んでいるかどうか
function CommonFunctions.isCarrying(player)
    return player.Character:FindFirstChild(Constants.CHARACTER_MODEL_NAME)
end

-- 物理的な接続（Weld）を安全に行う共通関数
function CommonFunctions.enableAnchor(BaseModel, enable)
    -- アンカーを有効化/無効化
    BaseModel.PrimaryPart.Anchored = enable
end

-- 物理的な接続（Weld）を安全に行う共通関数
function CommonFunctions.attachWithWeld(BaseModel, parentModel, WeldName)
    local targetPart = BaseModel.PrimaryPart
    local targetParentPart = parentModel.PrimaryPart
    local weld = targetPart:FindFirstChild(WeldName) or Instance.new("WeldConstraint")
    weld.Name = WeldName
    weld.Part0 = targetPart
    weld.Part1 = targetParentPart
    weld.Parent = targetPart
    
    targetParentPart.Anchored = false
end

-- 物理的な接続（Weld）を安全に削除する共通関数
function CommonFunctions.dettachWithWeld(BaseModel, WeldName)
    local targetPart = BaseModel.PrimaryPart
    local weld = targetPart:FindFirstChild(WeldName)
    print("CommonFunctions.dettachWithWeld:",targetPart)
    print("CommonFunctions.dettachWithWeld:",weld)
    weld:Destroy()
end

-- 特定のパスからモデルを安全に取得する関数など
function CommonFunctions.findModelById(parent, id)
    -- サーバー側で管理しているモデル群から検索するロジック
    local target = parent:FindFirstChild(id, true)
    return target
end

-- サーバーサイド: CommonFunctions
function CommonFunctions.autoWeldModel(model)
    local primary = model.PrimaryPart
    if not primary then 
        warn("autoWeldModel: PrimaryPartが設定されていないため実行を中止しました")
        return 
    end

    -- 2. 安全にWeldを作成していく
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= primary then
            -- 既存のAutoWeldがあれば削除してクリーンにする
            local oldWeld = part:FindFirstChild("AutoWeld")
            if oldWeld then oldWeld:Destroy() end

            local weld = Instance.new("WeldConstraint")
            weld.Name = "AutoWeld"
            weld.Part0 = part
            weld.Part1 = primary
            weld.Parent = part
            
            -- Weldが完了してから、アンカーをオフにする
            part.Anchored = false
        end
    end
    
    -- 3. 最後にPrimaryPartだけをAnchorするかは、設置状況に合わせて制御する
    -- ※この時点では、モデル全体はPrimaryPartに繋がっているので、
    -- primary.Anchored = true なら全体が止まり、false なら全体が物理で動きます。
end

return CommonFunctions