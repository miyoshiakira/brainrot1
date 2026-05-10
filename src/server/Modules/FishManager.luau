local FishManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local FishingAction = require(script.Parent.FishingAction)

local FISH_POINT_TAG = "FishPoint"
local MAX_FISH_COUNT = 5 -- 最大数
local SPAWN_INTERVAL = 1 -- 何秒ごとに増やすか
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
        local biome = fishBox:GetAttribute("Biome") or "?"
        prompt.ObjectText = biome
        prompt.ActionText = "釣りをする"
        prompt.MaxActivationDistance = 20
        prompt.Parent = targetModel
        
        prompt.Triggered:Connect(function(player)
            local biome = fishBox:GetAttribute("Biome") or "unknown"
            print(player.Name .. "が" .. biome .. "で釣りしました: " .. fishBox.Name)
            
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
    -- FishColliderBoxからBiome属性をコピー
    local biome = areaPart:GetAttribute("Biome")
    if biome then
        newFish:SetAttribute("Biome", biome)
    end
    newFish.Parent = areaPart
    newFish:PivotTo(spawnCFrame * templateRotation)
    setUpFishBoxAction(newFish)
    
    return newFish
end

-- 指定FishPointの現在の魚数を取得
local function getFishCount(fishPoint)
    return #fishPoint:GetChildren()
end

-- 外部から呼び出す初期化関数
function FishManager.Initialize()
    local fishBoxTemplate = ReplicatedStorage:FindFirstChild('FishBox')
    local fishPoints = CollectionService:GetTagged(FISH_POINT_TAG)

    print(string.format("[FishManager] FishPoint数: %d", #fishPoints))
    for _, fp in ipairs(fishPoints) do
        local biome = fp:GetAttribute("Biome") or "unknown"
        print(string.format("[FishManager] FishPoint: %s (Biome: %s)", fp.Name, biome))
    end

    -- 新しいFishPointが追加された場合も対応
    CollectionService:GetInstanceAddedSignal(FISH_POINT_TAG):Connect(function(fishPoint)
        print(string.format("[FishManager] FishPoint追加: %s (Biome: %s)", fishPoint.Name, fishPoint:GetAttribute("Biome") or "unknown"))
    end)

    task.spawn(function()
        while true do
            task.wait(SPAWN_INTERVAL)
            -- 各FishPointごとにMAX_FISH_COUNTまでスポーン
            for _, areaPart in ipairs(fishPoints) do
                if getFishCount(areaPart) < MAX_FISH_COUNT then
                    local spawnedFish = spawnFishRandomly(areaPart, fishBoxTemplate)
                    if spawnedFish then
                        spawnedFish.Parent = areaPart
                    end
                end
            end
        end
    end)
end

return FishManager