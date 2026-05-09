local FishManager = {} -- ★1: モジュール用のテーブル定義が必要
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local riverPart = game.Workspace:FindFirstChild("FishColliderBox")
local FishingAction = require(script.Parent.FishingAction)

-- FishBoxAnimationモジュールを読み込む

local MAX_FISH_COUNT = 20 -- 最大数
local SPAWN_INTERVAL = 3 -- 何秒ごとに増やすか
-- 内部関数：プロンプトの設定
local function setUpFishBoxAction(fishBox)
    -- ProceduralModelの場合、Generated内のModelを探す
    local targetModel = fishBox
    local generated = fishBox:FindFirstChild("Generated")
    
    if generated then
        -- Generatedフォルダ内の実際のModelを取得
        for _, child in ipairs(generated:GetChildren()) do
            if child:IsA("Model") then
                targetModel = child
                break
            end
        end
    end
    
    -- 既存のプロンプトを確認
    local existingPrompt = targetModel:FindFirstChildOfClass("ProximityPrompt")
    
    if not existingPrompt then
        print("[FishBox]: プロンプト設定開始")
        local prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = "川"
        prompt.ActionText = "釣りをする"
        prompt.MaxActivationDistance = 20
        prompt.Parent = targetModel
        
        prompt.Triggered:Connect(function(player)
            print(player.Name .. "が川で釣りしました: " .. fishBox.Name)
            
            -- キャラクターゲット処理
            local success = FishingAction.ProcessFishing(player, fishBox)
            if success then
                -- 釣りが終わったら魚影を消す
                fishBox:Destroy()
            end
        end)
        
        print("[FishBox]: プロンプト設定完了")
    end
end

local function spawnFishRandomly(areaPart, fishTemplate)
    -- 1. 範囲パーツのサイズと座標を取得
    local areaSize = areaPart.Size
    local areaPos = areaPart.Position
    
    -- 2. 範囲内のランダムなオフセットを計算
    local randomX = math.random(-areaSize.X / 2, areaSize.X / 2)
    local randomZ = math.random(-areaSize.Z / 2, areaSize.Z / 2)
    
    -- 3. 最終的な出現座標を決定（高さYはパーツの中心に合わせる）
    local spawnCFrame = CFrame.new(areaPos.X + randomX, areaPos.Y, areaPos.Z + randomZ)
    local templateRotation = fishTemplate.WorldPivot.Rotation -- 回転情報を取得
    -- 4. 魚影を生成して配置
    local newFish = fishTemplate:Clone()
    newFish.Parent = riverPart
    newFish:PivotTo(spawnCFrame * templateRotation)
    setUpFishBoxAction(newFish)
    
    return newFish
end

-- 外部から呼び出す初期化関数
function FishManager.Initialize() -- ★3: local は不要（モジュール関数にするため）
    -- ★ 一定時間ごとに自動で増やすループ処理
    local fishBoxTemplate = ReplicatedStorage:FindFirstChild('FishBox')
        
    task.spawn(function()
        while true do
            task.wait(SPAWN_INTERVAL)
            -- GetChildren() で取得したリストの数を # で数える
            local currentFishCount = #riverPart:GetChildren()
            
            if currentFishCount < MAX_FISH_COUNT then
                -- 第1引数に範囲パーツ、第2引数にテンプレートを渡す
                local spawnedFish = spawnFishRandomly(riverPart, fishBoxTemplate)
                
                -- 生成された魚を riverPart の中に入れる（これでカウント対象になる）
                if spawnedFish then
                    spawnedFish.Parent = riverPart
                end
            end
        end
    end)
end

return FishManager -- ★4: 最後にモジュールを返す（余計な end は消去）