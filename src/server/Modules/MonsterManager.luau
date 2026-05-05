local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters)

-- タグ名の定義
local MONSTER_TAG = "Monster"

local MonsterManager = {}

-- 数値をフォーマット（1000 → 1K, 1000000 → 1M）
local function formatNumber(num: number): string
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

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
            statsFrame.Money.Text = string.format("%s $/s", formatNumber(AllMoney))
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
function MonsterManager.SetupCharModel(charModel, rarity: string)
    -- レアリティに応じて色を変更
    local modelStr = rarity .. "Effect"
    local effect = ReplicatedStorage:FindFirstChild("RarityEffects"):FindFirstChild(modelStr)
    if effect then
        local clonedEffect = effect:Clone()
        clonedEffect.Parent = charModel.PrimaryPart
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

    -- 式: 基本収益 * (レベルの2.1乗) * レアリティ倍率
    local yield = baseMoney * math.pow(level, 2.1) * rarityMul
    
    return math.floor(yield)
end

-- キャラクターモデルの強化コスト
function MonsterManager.GetUpgradeCost(charModel: Instance): number
    if not charModel then return 0 end

    local baseMoney = charModel:GetAttribute("Money") or 0
    local level = charModel:GetAttribute("Level") or 1
    local rarity = charModel:GetAttribute("Rarity") or "Common"
    local rarityMul = RARITY_MULTIPLIER[rarity] or 1.0

    -- 式: (基本) + (レベルによる加算) + (レベルの2乗による急上昇)
    local cost = baseMoney + (level * 200) + (math.pow(level, 2.5) * 50)
    return math.floor(cost * rarityMul)
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
    FormatNumber = formatNumber,
}