local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters)
local constants = require("../Constants")

-- タグ名の定義
local MONSTER_TAG = "Monster"
local SLOT_TAG = "SlotPart"

local MonsterManager = {}

-- モンスターが追加された時の処理
local function UpdateMonsterUI(monsterModel)
    if not monsterModel then return end
    print("UpdateMonsterUI: " .. monsterModel.Name)
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
        local monsterMoney = monsterModel:GetAttribute("Money")
        local monsterRarity = monsterModel:GetAttribute("Rarity")

        -- 属性が未設定の場合はスキップ（SetInitStatus呼び出し前にタグが付いた場合）
        if not monsterName then return end

        monsterNameLabel.Text = monsterName
        
        if statsFrame:FindFirstChild("Level") then
            statsFrame.Level.Text = string.format("Lv.%d", monsterLevel or 1)
        end
        
        if statsFrame:FindFirstChild("Money") then
            statsFrame.Money.Text = string.format("%d $/s", monsterMoney or 0)
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

-- すでに存在しているモンスターを処理
for _, monsterModel in ipairs(CollectionService:GetTagged(MONSTER_TAG)) do
    UpdateMonsterUI(monsterModel)
end

-- 新しく生成されたモンスターを監視
CollectionService:GetInstanceAddedSignal(MONSTER_TAG):Connect(UpdateMonsterUI)

-- プレイヤーが所有するスロットのMoney合算を取得
function MonsterManager.GetSlotIncomePerSecond(player: Player): number
    local totalMoney = 0
    for _, slot in ipairs(CollectionService:GetTagged(SLOT_TAG)) do
        if slot:GetAttribute("Owner") == player.UserId then
            local monster = slot:FindFirstChild(constants.CHARACTER_MODEL_NAME)
            if monster then
                totalMoney = totalMoney + (monster:GetAttribute("Money") or 0)
            end
        end
    end
    return totalMoney
end

return {
    SetInitStatus = SetInitStatus,
    SetupCharModel = MonsterManager.SetupCharModel,
    UpdateMonsterUI = UpdateMonsterUI,
    GetSlotIncomePerSecond = MonsterManager.GetSlotIncomePerSecond,
}