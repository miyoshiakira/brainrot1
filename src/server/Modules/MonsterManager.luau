local CollectionService = game:GetService("CollectionService")

-- タグ名の定義
local MONSTER_TAG = "Monster"

-- モンスターが追加された時の処理
local function onMonsterAdded(monster)
    -- UIコンポーネントの取得
    -- ※画像に基づき、StatsDisplay > Container > StatsFrame > 各項目 と辿る
    local statsDisplay = monster:FindFirstChild("StatsDisplay")
    if not statsDisplay then return end

    local container = statsDisplay:FindFirstChild("Container")
    local statsFrame = container and container:FindFirstChild("StatsFrame")
    local monsterNameLabel = container and container:FindFirstChild("MonsterName")

    if statsFrame and monsterNameLabel then
        -- 本来はここでモンスターの固有ステータス（Attributesなど）を取得します
        -- 例として、モデル名や属性値を反映
        monsterNameLabel.Text = monster.Name
        
        -- 各ラベルに値を反映（仮の値）
        if statsFrame:FindFirstChild("Level") then
            statsFrame.Level.Text = "Lv. 1" -- monster:GetAttribute("Level") などから取得
        end
        
        if statsFrame:FindFirstChild("Money") then
            statsFrame.Money.Text = "$100"
        end

        print(monster.Name .. " のUIを初期化しました。")
    end
end

-- すでに存在しているモンスターを処理
for _, monster in ipairs(CollectionService:GetTagged(MONSTER_TAG)) do
    onMonsterAdded(monster)
end

-- 新しく生成されたモンスターを監視
CollectionService:GetInstanceAddedSignal(MONSTER_TAG):Connect(onMonsterAdded)