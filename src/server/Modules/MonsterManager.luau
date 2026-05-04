local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters)

-- タグ名の定義
local MONSTER_TAG = "Monster"

local MonsterManager = {}

-- モンスターが追加された時の処理
local function UpdateMonsterUI(monsterModel: Instance)
    if not monsterModel then return end
    print("UpdateMonsterUI: " , monsterModel)
    -- UIコンポーネントの取得
    -- ※画像に基づき、StatsDisplay > Container > StatsFrame > 各項目 と辿る
    local statsDisplay = monsterModel:FindFirstChild("StatsDisplay")
    if not statsDisplay then return end

    local container = statsDisplay:FindFirstChild("Container")
    local statsFrame = container and container:FindFirstChild("StatsFrame")
    local monsterNameLabel = container and container:FindFirstChild("MonsterName")

    if statsFrame and monsterNameLabel then
        -- 本来はここでモンスターの固有ステータス（Attributesなど）を取得します
        local monsterName = monsterModel:GetAttribute("MonsterName")
        local monsterLevel = monsterModel:GetAttribute("Level")
        local monsterRarity = monsterModel:GetAttribute("Rarity")

        -- 属性が未設定の場合はスキップ（SetInitStatus呼び出し前にタグが付いた場合）
        if not monsterName then return end

        monsterNameLabel.Text = monsterName
        
        if statsFrame:FindFirstChild("Level") then
            statsFrame.Level.Text = string.format("Lv.%d", monsterLevel or 1)
        end
        
        if statsFrame:FindFirstChild("Money") then
            local AllMoney = MonsterManager.CalcIncomePerSecond(monsterModel)
            statsFrame.Money.Text = string.format("%d $/s", AllMoney)
        end

        if statsFrame:FindFirstChild("Rarity") then
            statsFrame.Rarity.Text = tostring(monsterRarity or "?")
        end

        print(monsterModel.Name .. " のUIを初期化しました。")
    end
end

-- モンスターが追加された時の処理
local function SetInitStatus(monsterModel, monsterId, modelName)
    local monsterStatusModel = BrainrotMonsters.GetCharacterById(monsterId)
    monsterModel:SetAttribute("MonsterId", monsterId)
    monsterModel:SetAttribute("ModelName", modelName)
    monsterModel:SetAttribute("MonsterName", monsterStatusModel.MonsterName)
    monsterModel:SetAttribute("Level", monsterStatusModel.Level or 1)
    monsterModel:SetAttribute("Money", monsterStatusModel.Money)
    monsterModel:SetAttribute("Rarity", monsterStatusModel.Rarity)
    UpdateMonsterUI(monsterModel)
end

-- モンスターのステータスをマッピング
function MonsterManager.MappingStatus(monsterInfo, monsterModel)
    if not monsterInfo or not monsterModel then
        return
    end
    monsterModel:SetAttribute("MonsterId", monsterInfo.MonsterId)
    monsterModel:SetAttribute("ModelName", monsterInfo.ModelName)
    monsterModel:SetAttribute("MonsterName", monsterInfo.MonsterName)
    monsterModel:SetAttribute("Level", monsterInfo.Level)
    monsterModel:SetAttribute("Money", monsterInfo.Money)
    monsterModel:SetAttribute("Rarity", monsterInfo.Rarity)
    UpdateMonsterUI(monsterModel)
end

-- キャラクターモデルの共通セットアップ（色変更＋物理設定）
function MonsterManager.SetupCharModel(charModel: Instance, rarity: string)
    -- レアリティに応じて色を変更
    local rarityConfig = BrainrotMonsters.GetRarityConfig(rarity)
    local charColor = rarityConfig and rarityConfig.Color or Color3.fromRGB(255, 255, 255)

    for _, part in ipairs(charModel:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Body" then
            part.Color = charColor
            local light = part:FindFirstChild("SlimeLight")
            if light then
                light.Color = charColor
            end
        end
    end

    -- 全パーツの物理設定
    for _, part in ipairs(charModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = false
            part.Massless = true
        end
    end
end

-- レアリティ倍率
local RARITY_MULTIPLIER: {[string]: number} = {
    Common = 1.0,
    Rare = 1.5,
    Epic = 2.0,
    Legendary = 3.5,
    Rainbow = 5.0,
}

-- キャラクターモデルの1秒あたり総合収入を算出
-- 総合収入 = 基本収入(Money) × レベル × レアリティ倍率
function MonsterManager.CalcIncomePerSecond(charModel: Instance): number
    if not charModel then return 0 end

    local baseMoney = charModel:GetAttribute("Money") or 0
    local level = charModel:GetAttribute("Level") or 1
    local rarity = charModel:GetAttribute("Rarity") or "Common"
    local rarityMul = RARITY_MULTIPLIER[rarity] or 1.0

    return baseMoney * level * rarityMul
end

-- キャラクターモデルの強化コスト
function MonsterManager.GetUpgradeCost(charModel: Instance): number
    if not charModel then return 0 end

    local baseMoney = charModel:GetAttribute("Money") or 0
    local level = charModel:GetAttribute("Level") or 1
    local rarity = charModel:GetAttribute("Rarity") or "Common"
    local rarityMul = RARITY_MULTIPLIER[rarity] or 1.0

    return baseMoney * level * rarityMul * 10
end

-- 新しく生成されたモンスターを監視
CollectionService:GetInstanceAddedSignal(MONSTER_TAG):Connect(UpdateMonsterUI)

-- キャラクターモデルのStatusPanelを更新（外部から呼び出し用）
function MonsterManager.UpdateStatusPanel(charModel: Instance)
    UpdateMonsterUI(charModel)
end

-- プレイヤーが所有するスロットのMoney合算を取得
-- ※この関数はPlayerBaseControllerに移動しました（循環依存回避のため）
-- PlayerBaseController.GetSlotIncomePerSecond を使用してください

return {
    SetInitStatus = SetInitStatus,
    SetupCharModel = MonsterManager.SetupCharModel,
    UpdateStatusPanel = MonsterManager.UpdateStatusPanel,
    UpdateMonsterUI = UpdateMonsterUI,
    CalcIncomePerSecond = MonsterManager.CalcIncomePerSecond,
    MappingStatus = MonsterManager.MappingStatus,
    GetUpgradeCost = MonsterManager.GetUpgradeCost,
}