--[[
    Brainrot クライアントスクリプト
    - 所持金・釣りパワーUI表示
    - 通知表示
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local _UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
print("=================================")
print("Brainrot クライアント起動")
print("=================================")

-- 現在の所持金と釣りパワー
local currentMoney = 0
local currentFishingPower = 0
local currentRodRank = 1

-- パステルカラー定義
local COLORS = {
    Pink = Color3.fromRGB(255, 182, 193),
    Mint = Color3.fromRGB(152, 251, 152),
    Lavender = Color3.fromRGB(230, 190, 255),
    Sky = Color3.fromRGB(135, 206, 250),
    Peach = Color3.fromRGB(255, 218, 185),
    Yellow = Color3.fromRGB(255, 255, 186),
    White = Color3.fromRGB(255, 255, 255),
    Dark = Color3.fromRGB(60, 60, 80),
    Perfect = Color3.fromRGB(255, 215, 0),
    Good = Color3.fromRGB(100, 255, 100),
}


-- レアリティカラー
local RARITY_COLORS = {
    Common = Color3.fromRGB(150, 150, 150),
    Rare = Color3.fromRGB(0, 150, 255),
    Epic = Color3.fromRGB(180, 0, 255),
    Legendary = Color3.fromRGB(255, 200, 0),
    Rainbow = Color3.fromRGB(255, 100, 255),
}

-- メインUI作成
local function createMainUI(): ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BrainrotUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- 上部ステータスバー (右上に配置)
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(0, 150, 0, 130) -- 釣り竿ランク表示追加で拡張
    topBar.Position = UDim2.new(1, -160, 0, 10) -- 右上に配置
    topBar.BackgroundColor3 = COLORS.Dark
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui

    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 8)
    topBarCorner.Parent = topBar

    -- コイン表示
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsFrame"
    coinsFrame.Size = UDim2.new(1, -10, 0, 35)
    coinsFrame.Position = UDim2.new(0, 5, 0, 5)
    coinsFrame.BackgroundColor3 = COLORS.Yellow
    coinsFrame.BackgroundTransparency = 0.2
    coinsFrame.BorderSizePixel = 0
    coinsFrame.Parent = topBar

    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 8)
    coinsCorner.Parent = coinsFrame

    local coinsIcon = Instance.new("TextLabel")
    coinsIcon.Name = "Icon"
    coinsIcon.Size = UDim2.new(0, 30, 1, 0)
    coinsIcon.Position = UDim2.new(0, 5, 0, 0)
    coinsIcon.BackgroundTransparency = 1
    coinsIcon.Text = "＄"
    coinsIcon.TextSize = 20
    coinsIcon.Parent = coinsFrame

    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -40, 1, 0)
    coinsLabel.Position = UDim2.new(0, 35, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.TextColor3 = COLORS.Dark
    coinsLabel.Text = "0"
    coinsLabel.TextSize = 18
    coinsLabel.Font = Enum.Font.GothamBold
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.Parent = coinsFrame

    -- 釣りパワー表示
    local fishingPowerFrame = Instance.new("Frame")
    fishingPowerFrame.Name = "FishingPowerFrame"
    fishingPowerFrame.Size = UDim2.new(1, -10, 0, 35)
    fishingPowerFrame.Position = UDim2.new(0, 5, 0, 45)
    fishingPowerFrame.BackgroundColor3 = COLORS.Mint
    fishingPowerFrame.BackgroundTransparency = 0.2
    fishingPowerFrame.BorderSizePixel = 0
    fishingPowerFrame.Parent = topBar

    local fishingPowerCorner = Instance.new("UICorner")
    fishingPowerCorner.CornerRadius = UDim.new(0, 8)
    fishingPowerCorner.Parent = fishingPowerFrame

    local fishingPowerIcon = Instance.new("TextLabel")
    fishingPowerIcon.Name = "Icon"
    fishingPowerIcon.Size = UDim2.new(0, 30, 1, 0)
    fishingPowerIcon.Position = UDim2.new(0, 5, 0, 0)
    fishingPowerIcon.BackgroundTransparency = 1
    fishingPowerIcon.Text = "🎣"
    fishingPowerIcon.TextSize = 20
    fishingPowerIcon.Parent = fishingPowerFrame

    local fishingPowerLabel = Instance.new("TextLabel")
    fishingPowerLabel.Name = "FishingPowerLabel"
    fishingPowerLabel.Size = UDim2.new(1, -40, 1, 0)
    fishingPowerLabel.Position = UDim2.new(0, 35, 0, 0)
    fishingPowerLabel.BackgroundTransparency = 1
    fishingPowerLabel.TextColor3 = COLORS.Dark
    fishingPowerLabel.Text = "0"
    fishingPowerLabel.TextSize = 18
    fishingPowerLabel.Font = Enum.Font.GothamBold
    fishingPowerLabel.TextXAlignment = Enum.TextXAlignment.Left
    fishingPowerLabel.Parent = fishingPowerFrame

    -- 釣り竿ランク表示
    local rodRankFrame = Instance.new("Frame")
    rodRankFrame.Name = "RodRankFrame"
    rodRankFrame.Size = UDim2.new(1, -10, 0, 35)
    rodRankFrame.Position = UDim2.new(0, 5, 0, 85)
    rodRankFrame.BackgroundColor3 = COLORS.Sky
    rodRankFrame.BackgroundTransparency = 0.2
    rodRankFrame.BorderSizePixel = 0
    rodRankFrame.Parent = topBar

    local rodRankCorner = Instance.new("UICorner")
    rodRankCorner.CornerRadius = UDim.new(0, 8)
    rodRankCorner.Parent = rodRankFrame

    local rodRankIcon = Instance.new("TextLabel")
    rodRankIcon.Name = "Icon"
    rodRankIcon.Size = UDim2.new(0, 30, 1, 0)
    rodRankIcon.Position = UDim2.new(0, 5, 0, 0)
    rodRankIcon.BackgroundTransparency = 1
    rodRankIcon.Text = "🎣"
    rodRankIcon.TextSize = 20
    rodRankIcon.Parent = rodRankFrame

    local rodRankLabel = Instance.new("TextLabel")
    rodRankLabel.Name = "RodRankLabel"
    rodRankLabel.Size = UDim2.new(1, -40, 1, 0)
    rodRankLabel.Position = UDim2.new(0, 35, 0, 0)
    rodRankLabel.BackgroundTransparency = 1
    rodRankLabel.TextColor3 = COLORS.Dark
    rodRankLabel.Text = "Lv.1"
    rodRankLabel.TextSize = 18
    rodRankLabel.Font = Enum.Font.GothamBold
    rodRankLabel.TextXAlignment = Enum.TextXAlignment.Left
    rodRankLabel.Parent = rodRankFrame

    -- ========================================
    -- 通知コンテナ
    local notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "NotificationContainer"
    notificationContainer.Size = UDim2.new(0, 350, 0, 300)
    notificationContainer.Position = UDim2.new(0.5, -175, 0, 80)
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.Parent = screenGui

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = notificationContainer

    -- ========================================
    -- キャラクター収集UI
    -- ========================================
    local characterButton = Instance.new("TextButton")
    characterButton.Name = "CharacterButton"
    characterButton.Size = UDim2.new(0, 60, 0, 60)
    characterButton.Position = UDim2.new(0, 20, 0.5, -30)
    characterButton.BackgroundColor3 = COLORS.Lavender
    characterButton.BorderSizePixel = 0
    characterButton.Text = "🎁"
    characterButton.TextSize = 32
    characterButton.Font = Enum.Font.GothamBold
    characterButton.Parent = screenGui

    local charButtonCorner = Instance.new("UICorner")
    charButtonCorner.CornerRadius = UDim.new(0, 12)
    charButtonCorner.Parent = characterButton

    -- キャラクターパネル（非表示）
    local characterPanel = Instance.new("Frame")
    characterPanel.Name = "CharacterPanel"
    characterPanel.Size = UDim2.new(0, 400, 0, 500)
    characterPanel.Position = UDim2.new(0.5, -200, 0.5, -250)
    characterPanel.BackgroundColor3 = COLORS.Dark
    characterPanel.BackgroundTransparency = 0.1
    characterPanel.BorderSizePixel = 0
    characterPanel.Visible = false
    characterPanel.ZIndex = 10
    characterPanel.Parent = screenGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 16)
    panelCorner.Parent = characterPanel

    -- パネルタイトル
    local panelTitle = Instance.new("TextLabel")
    panelTitle.Name = "Title"
    panelTitle.Size = UDim2.new(1, 0, 0, 40)
    panelTitle.Position = UDim2.new(0, 0, 0, 10)
    panelTitle.BackgroundTransparency = 1
    panelTitle.TextColor3 = COLORS.Pink
    panelTitle.Text = "🎁 Brainrot Collection 🎁"
    panelTitle.TextSize = 24
    panelTitle.Font = Enum.Font.GothamBold
    panelTitle.Parent = characterPanel

    -- 閉じるボタン
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = COLORS.White
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = characterPanel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    -- キャラクターリストコンテナ
    local characterList = Instance.new("ScrollingFrame")
    characterList.Name = "CharacterList"
    characterList.Size = UDim2.new(1, -20, 1, -120)
    characterList.Position = UDim2.new(0, 10, 0, 60)
    characterList.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    characterList.BackgroundTransparency = 0.5
    characterList.BorderSizePixel = 0
    characterList.ScrollBarThickness = 8
    characterList.Parent = characterPanel

    local listCorner2 = Instance.new("UICorner")
    listCorner2.CornerRadius = UDim.new(0, 8)
    listCorner2.Parent = characterList

    local listLayout2 = Instance.new("UIGridLayout")
    listLayout2.CellSize = UDim2.new(0, 85, 0, 100)
    listLayout2.CellPadding = UDim2.new(0, 5, 0, 5)
    listLayout2.Parent = characterList

    -- 統計表示
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, 0, 0, 30)
    statsLabel.Position = UDim2.new(0, 0, 1, -40)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = COLORS.White
    statsLabel.Text = "収集数: 0 | Rainbow: 0"
    statsLabel.TextSize = 16
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.Parent = characterPanel

    return screenGui
end

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

-- コイン表示を更新
local function updateCoinsDisplay(newMoney: number)
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local coinsFrame = ui:FindFirstChild("TopBar"):FindFirstChild("CoinsFrame")
    if not coinsFrame then return end

    local label = coinsFrame:FindFirstChild("CoinsLabel")
    if not label then return end

    -- アニメーション
    if newMoney > currentMoney then
        label.TextColor3 = COLORS.Good
        task.delay(0.3, function()
            label.TextColor3 = COLORS.Dark
        end)
    end

    label.Text = formatNumber(newMoney)
    currentMoney = newMoney
end

-- 釣りパワー表示を更新
local function updateFishingPowerDisplay(newFishingPower: number)
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local fishingPowerFrame = ui:FindFirstChild("TopBar"):FindFirstChild("FishingPowerFrame")
    if not fishingPowerFrame then return end

    local label = fishingPowerFrame:FindFirstChild("FishingPowerLabel")
    if not label then return end

    -- アニメーション
    if newFishingPower > currentFishingPower then
        label.TextColor3 = COLORS.Perfect
        task.delay(0.5, function()
            label.TextColor3 = COLORS.Dark
        end)
    end

    label.Text = formatNumber(newFishingPower)
    currentFishingPower = newFishingPower
end

-- 釣り竿ランク表示を更新
local function updateRodRankDisplay(newRank: number)
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local rodRankFrame = ui:FindFirstChild("TopBar"):FindFirstChild("RodRankFrame")
    if not rodRankFrame then return end

    local label = rodRankFrame:FindFirstChild("RodRankLabel")
    if not label then return end

    -- アニメーション
    if newRank > currentRodRank then
        label.TextColor3 = COLORS.Perfect
        task.delay(0.5, function()
            label.TextColor3 = COLORS.Dark
        end)
    end

    label.Text = string.format("Lv.%d", newRank)
    currentRodRank = newRank
end


-- 通知を表示
local function showNotification(title: string, message: string, color: Color3?)
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local container = ui:FindFirstChild("NotificationContainer")
    if not container then return end

    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(1, 0, 0, 70)
    notification.BackgroundColor3 = color or COLORS.Dark
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = COLORS.White
    titleLabel.Text = title
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notification

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 25)
    messageLabel.Position = UDim2.new(0, 10, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.Text = message
    messageLabel.TextSize = 16
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = notification

    notification.Parent = container

    -- フェードイン
    notification.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    messageLabel.TextTransparency = 1

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(notification, tweenInfo, {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(titleLabel, tweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(messageLabel, tweenInfo, {TextTransparency = 0}):Play()

    -- 4秒後にフェードアウト
    task.delay(4, function()
        local fadeOut = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TweenService:Create(notification, fadeOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(titleLabel, fadeOut, {TextTransparency = 1}):Play()
        TweenService:Create(messageLabel, fadeOut, {TextTransparency = 1}):Play()

        task.delay(0.5, function()
            notification:Destroy()
        end)
    end)
end


-- キャラクターパネルを表示/非表示
local function toggleCharacterPanel()
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local panel = ui:FindFirstChild("CharacterPanel")
    if not panel then return end

    panel.Visible = not panel.Visible
end

-- キャラクター獲得通知
local function showCharacterCollected(charData)
    local rarityColor = RARITY_COLORS[charData.Rarity] or COLORS.White
    local title = string.format("🎉 NEW %s!", string.upper(charData.Rarity))
    local message = string.format("%s を入手!", charData.MonsterName)
    showNotification(title, message, rarityColor)
end

-- ========================================
-- キャラクター運搬判定（DisplayMonsterの有無で判定）
-- ========================================
local CHARACTER_MODEL_NAME = "DisplayMonster"

local function getHeldModel()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild(CHARACTER_MODEL_NAME)
end

local function isCarrying()
    return getHeldModel() ~= nil
end

local function placeCharacter(slot)
    local heldModel = getHeldModel()
    if not heldModel then return false end
    local success, errorMessage = RemoteFunctions.CharacterPlaceTry:InvokeServer(heldModel.Name, slot.Name)
    if success then
        showNotification("✅ 配置完了!", "スロットに配置しました", COLORS.Good)
        return true
    else
        showNotification("⚠️ 失敗", errorMessage or "配置できませんでした", COLORS.Yellow)
        return false
    end
end

-- スロットからキャラクターを取り外す
local function removeFromSlot(slot)
    if isCarrying() then return true end
    local data = RemoteFunctions.CharacterPickupTry:InvokeServer(slot.Name)
    if data.success then
        print(string.format("[Client] heldModel: %s", data.heldModel.Name))
        showNotification("✅ 取得完了!", "スロットから取り上げました", COLORS.Good)
        return true
    else
        print(data.errorMessage)
        showNotification("⚠️ 失敗", data.errorMessage or "取り上げできませんでした", COLORS.Yellow)
        return false
    end
end

-- UI初期化
createMainUI()

-- プレイヤー死亡時に運搬状態をリセット
player.CharacterAdded:Connect(function(character)
    
end)


-- ボタンイベント設定
local ui = playerGui:WaitForChild("BrainrotUI")

-- キャラクターボタン
local characterButton = ui:WaitForChild("CharacterButton")
characterButton.MouseButton1Click:Connect(function()
    toggleCharacterPanel()
end)

-- キャラクターパネルの閉じるボタン
local characterPanel = ui:FindFirstChild("CharacterPanel")
if characterPanel then
    local closeButton = characterPanel:FindFirstChild("CloseButton")
    if closeButton then
        closeButton.MouseButton1Click:Connect(function()
            characterPanel.Visible = false
        end)
    end
end

-- サーバーイベント受信
RemoteEvents.MoneyChanged.OnClientEvent:Connect(function(newMoney)
    updateCoinsDisplay(newMoney)
end)

RemoteEvents.FishingPowerChanged.OnClientEvent:Connect(function(newFishingPower)
    updateFishingPowerDisplay(newFishingPower)
end)

RemoteEvents.RodRankChanged.OnClientEvent:Connect(function(newRank)
    updateRodRankDisplay(newRank)
end)

-- エリア解放要求受信（ProximityPromptトリガー → クライアント側で解放実行）
RemoteEvents.AreaUnlockRequest.OnClientEvent:Connect(function(areaName, cost)
    -- クライアントからサーバーへエリア解放を要求
    RemoteEvents.AreaUnlocked:FireServer(areaName)
end)

-- 解放済みエリア一覧受信 → 該当AreaBlockをクライアント側で破壊
local function removeAreaBlockByName(areaName: string)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("AreaName") == areaName then
            obj:Destroy()
            print(string.format("[Area] クライアント側でAreaBlock削除: %s", areaName))
            return
        end
    end
end

RemoteEvents.AreaUnlocked.OnClientEvent:Connect(function(unlockedAreas)
    -- unlockedAreasは配列（ロード時）または単一文字列（解放直後）の両方に対応
    if type(unlockedAreas) == "table" then
        for _, areaName in ipairs(unlockedAreas) do
            removeAreaBlockByName(areaName)
        end
    elseif type(unlockedAreas) == "string" then
        removeAreaBlockByName(unlockedAreas)
    end
end)

RemoteEvents.NotifyPlayer.OnClientEvent:Connect(function(title, message)
    showNotification(title, message)
end)

-- キャラクター関連イベント
RemoteEvents.CharacterCollected.OnClientEvent:Connect(function(droppedMonsterId, rarity)
    local charData = BrainrotMonsters.GetCharacterById(droppedMonsterId)
    if charData then
        charData.Rarity = rarity
        showCharacterCollected(charData)
    end
end)

-- キャラクター3Dモデル生成イベント
RemoteEvents.CharacterSpawned.OnClientEvent:Connect(function(data)
    -- 既に運搬中なら無視
    if isCarrying() then
        print("[CharacterSpawned] 既に運搬中のためスキップ")
        return
    end

    -- 少し待ってからモデルを探す
    task.wait(0.3)

    local modelName = data.Model.Name
    local monsterId = data.MonsterId
    local model = data.Model

    if model then
        print("[CharacterSpawned] モデル生成完了:", monsterId)
    else
        warn("[CharacterSpawned] モデルが見つかりません:", modelName)
    end
end)

RemoteFunctions.SlotActionTrigger.OnClientInvoke = function(data)
    -- TODO: キャラクターをスロットに配置する処理を追加
    local slot = data.Slot
    local monsterId = slot:GetAttribute("MonsterId")
    if monsterId then
        -- とりあげる
        return removeFromSlot(slot)
    else
        -- 設置する
        return placeCharacter(slot)
    end
    
end

-- ゴミ箱アクション
RemoteFunctions.TrashBoxAction.OnClientInvoke = function(player)
    print("[TrashBoxAction] ゴミ箱アクションが呼び出されました")
    local heldModel = getHeldModel()
    if heldModel then
        heldModel:Destroy()
    end
    return true
end

-- 初期データ取得
task.spawn(function()
    task.wait(1)
    local data = RemoteEvents.GetPlayerData:InvokeServer()
    if data then
        updateCoinsDisplay(data.Money)
        updateFishingPowerDisplay(data.FishingPower or 0)
        updateRodRankDisplay(data.RodRank or 1)
        showNotification("🎣 Brainrot", "釣りを始めよう!", COLORS.Pink)
    end
end)

-- UIボタン初期化（投げアクション等）
local UIInit = require(script.UIInit)
UIInit.Initialize()

print("[Client] 初期化完了")
