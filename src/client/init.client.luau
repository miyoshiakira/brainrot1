--[[
    Brainrot Launch Simulator クライアントスクリプト
    - 所持金・高度UI表示
    - クリティカル・ローンチUI（パワーゲージ）
    - Rainbow Rainエフェクト
    - 通知表示
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
print("=================================")
print("Brainrot Launch Simulator クライアント起動")
print("=================================")

-- 現在の所持金と高度
local currentMoney = 0
local currentHeight = 0

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
    Rainbow1 = Color3.fromRGB(255, 107, 107),
    Rainbow2 = Color3.fromRGB(255, 217, 61),
    Rainbow3 = Color3.fromRGB(107, 255, 107),
    Rainbow4 = Color3.fromRGB(107, 107, 255),
}

-- ゲージ状態
local gaugeState = {
    isActive = false,
    position = 0,  -- 0-1の値
    direction = 1, -- 1 = 右へ, -1 = 左へ
    speed = 2.0,
}

-- Rainbow Rain状態
local rainbowRainActive = false

-- ========================================
-- キャラクター運搬システム（一元管理）
-- ========================================
local CarrySystem = {
    heldModel = nil,      -- 現在持っているモデル
    isCarrying = false,   -- 運搬中フラグ
    weld = nil,           -- 現在のWeld参照
}

-- キャラクター収集状態
local characterCollection = {}
local activeCharacterId = nil

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

    -- 上部ステータスバー
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = COLORS.Dark
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui

    -- 高度表示
    local heightFrame = Instance.new("Frame")
    heightFrame.Name = "HeightFrame"
    heightFrame.Size = UDim2.new(0, 200, 0, 50)
    heightFrame.Position = UDim2.new(0, 20, 0, 5)
    heightFrame.BackgroundColor3 = COLORS.Sky
    heightFrame.BackgroundTransparency = 0.2
    heightFrame.BorderSizePixel = 0
    heightFrame.Parent = topBar

    local heightCorner = Instance.new("UICorner")
    heightCorner.CornerRadius = UDim.new(0, 12)
    heightCorner.Parent = heightFrame

    local heightIcon = Instance.new("TextLabel")
    heightIcon.Name = "Icon"
    heightIcon.Size = UDim2.new(0, 40, 1, 0)
    heightIcon.Position = UDim2.new(0, 5, 0, 0)
    heightIcon.BackgroundTransparency = 1
    heightIcon.Text = "🚀"
    heightIcon.TextSize = 28
    heightIcon.Parent = heightFrame

    local heightLabel = Instance.new("TextLabel")
    heightLabel.Name = "HeightLabel"
    heightLabel.Size = UDim2.new(1, -50, 1, 0)
    heightLabel.Position = UDim2.new(0, 45, 0, 0)
    heightLabel.BackgroundTransparency = 1
    heightLabel.TextColor3 = COLORS.White
    heightLabel.Text = "0m"
    heightLabel.TextSize = 24
    heightLabel.Font = Enum.Font.GothamBold
    heightLabel.TextXAlignment = Enum.TextXAlignment.Left
    heightLabel.Parent = heightFrame

    -- コイン表示
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsFrame"
    coinsFrame.Size = UDim2.new(0, 180, 0, 50)
    coinsFrame.Position = UDim2.new(0, 240, 0, 5)
    coinsFrame.BackgroundColor3 = COLORS.Yellow
    coinsFrame.BackgroundTransparency = 0.2
    coinsFrame.BorderSizePixel = 0
    coinsFrame.Parent = topBar

    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 12)
    coinsCorner.Parent = coinsFrame

    local coinsIcon = Instance.new("TextLabel")
    coinsIcon.Name = "Icon"
    coinsIcon.Size = UDim2.new(0, 40, 1, 0)
    coinsIcon.Position = UDim2.new(0, 5, 0, 0)
    coinsIcon.BackgroundTransparency = 1
    coinsIcon.Text = "🪙"
    coinsIcon.TextSize = 28
    coinsIcon.Parent = coinsFrame

    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(1, -50, 1, 0)
    coinsLabel.Position = UDim2.new(0, 45, 0, 0)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.TextColor3 = COLORS.Dark
    coinsLabel.Text = "0"
    coinsLabel.TextSize = 24
    coinsLabel.Font = Enum.Font.GothamBold
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.Parent = coinsFrame

    -- グローバル高度表示
    local globalFrame = Instance.new("Frame")
    globalFrame.Name = "GlobalFrame"
    globalFrame.Size = UDim2.new(0, 250, 0, 50)
    globalFrame.Position = UDim2.new(1, -270, 0, 5)
    globalFrame.BackgroundColor3 = COLORS.Lavender
    globalFrame.BackgroundTransparency = 0.2
    globalFrame.BorderSizePixel = 0
    globalFrame.Parent = topBar

    local globalCorner = Instance.new("UICorner")
    globalCorner.CornerRadius = UDim.new(0, 12)
    globalCorner.Parent = globalFrame

    local globalIcon = Instance.new("TextLabel")
    globalIcon.Name = "Icon"
    globalIcon.Size = UDim2.new(0, 40, 1, 0)
    globalIcon.Position = UDim2.new(0, 5, 0, 0)
    globalIcon.BackgroundTransparency = 1
    globalIcon.Text = "🌍"
    globalIcon.TextSize = 28
    globalIcon.Parent = globalFrame

    local globalLabel = Instance.new("TextLabel")
    globalLabel.Name = "GlobalLabel"
    globalLabel.Size = UDim2.new(1, -50, 1, 0)
    globalLabel.Position = UDim2.new(0, 45, 0, 0)
    globalLabel.BackgroundTransparency = 1
    globalLabel.TextColor3 = COLORS.Dark
    globalLabel.Text = "全体: 0m"
    globalLabel.TextSize = 20
    globalLabel.Font = Enum.Font.GothamBold
    globalLabel.TextXAlignment = Enum.TextXAlignment.Left
    globalLabel.Parent = globalFrame

    -- ========================================
    -- クリティカル・ローンチUI（パワーゲージ）
    -- ========================================
    local launchContainer = Instance.new("Frame")
    launchContainer.Name = "LaunchContainer"
    launchContainer.Size = UDim2.new(0, 400, 0, 180)
    launchContainer.Position = UDim2.new(0.5, -200, 1, -200)
    launchContainer.BackgroundColor3 = COLORS.Dark
    launchContainer.BackgroundTransparency = 0.2
    launchContainer.BorderSizePixel = 0
    launchContainer.Parent = screenGui

    local launchCorner = Instance.new("UICorner")
    launchCorner.CornerRadius = UDim.new(0, 16)
    launchCorner.Parent = launchContainer

    -- タイトル
    local launchTitle = Instance.new("TextLabel")
    launchTitle.Name = "Title"
    launchTitle.Size = UDim2.new(1, 0, 0, 30)
    launchTitle.Position = UDim2.new(0, 0, 0, 10)
    launchTitle.BackgroundTransparency = 1
    launchTitle.TextColor3 = COLORS.Pink
    launchTitle.Text = "🚀 LAUNCH POWER 🚀"
    launchTitle.TextSize = 22
    launchTitle.Font = Enum.Font.GothamBold
    launchTitle.Parent = launchContainer

    -- ゲージ背景
    local gaugeBackground = Instance.new("Frame")
    gaugeBackground.Name = "GaugeBackground"
    gaugeBackground.Size = UDim2.new(0, 360, 0, 40)
    gaugeBackground.Position = UDim2.new(0.5, -180, 0, 50)
    gaugeBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    gaugeBackground.BorderSizePixel = 0
    gaugeBackground.Parent = launchContainer

    local gaugeCorner = Instance.new("UICorner")
    gaugeCorner.CornerRadius = UDim.new(0, 8)
    gaugeCorner.Parent = gaugeBackground

    -- Perfect領域（中央 45%-55%）
    local perfectZone = Instance.new("Frame")
    perfectZone.Name = "PerfectZone"
    perfectZone.Size = UDim2.new(0.1, 0, 1, 0)
    perfectZone.Position = UDim2.new(0.45, 0, 0, 0)
    perfectZone.BackgroundColor3 = COLORS.Perfect
    perfectZone.BackgroundTransparency = 0.3
    perfectZone.BorderSizePixel = 0
    perfectZone.ZIndex = 2
    perfectZone.Parent = gaugeBackground

    -- Good領域（左 35%-45%）
    local goodZoneLeft = Instance.new("Frame")
    goodZoneLeft.Name = "GoodZoneLeft"
    goodZoneLeft.Size = UDim2.new(0.1, 0, 1, 0)
    goodZoneLeft.Position = UDim2.new(0.35, 0, 0, 0)
    goodZoneLeft.BackgroundColor3 = COLORS.Good
    goodZoneLeft.BackgroundTransparency = 0.5
    goodZoneLeft.BorderSizePixel = 0
    goodZoneLeft.ZIndex = 1
    goodZoneLeft.Parent = gaugeBackground

    -- Good領域（右 55%-65%）
    local goodZoneRight = Instance.new("Frame")
    goodZoneRight.Name = "GoodZoneRight"
    goodZoneRight.Size = UDim2.new(0.1, 0, 1, 0)
    goodZoneRight.Position = UDim2.new(0.55, 0, 0, 0)
    goodZoneRight.BackgroundColor3 = COLORS.Good
    goodZoneRight.BackgroundTransparency = 0.5
    goodZoneRight.BorderSizePixel = 0
    goodZoneRight.ZIndex = 1
    goodZoneRight.Parent = gaugeBackground

    -- ゲージインジケーター（動くバー）
    local gaugeIndicator = Instance.new("Frame")
    gaugeIndicator.Name = "GaugeIndicator"
    gaugeIndicator.Size = UDim2.new(0, 8, 1, 4)
    gaugeIndicator.Position = UDim2.new(0, -4, 0, -2)
    gaugeIndicator.BackgroundColor3 = COLORS.White
    gaugeIndicator.BorderSizePixel = 0
    gaugeIndicator.ZIndex = 3
    gaugeIndicator.Parent = gaugeBackground

    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 4)
    indicatorCorner.Parent = gaugeIndicator

    -- 発射ボタン
    local launchButton = Instance.new("TextButton")
    launchButton.Name = "LaunchButton"
    launchButton.Size = UDim2.new(0, 200, 0, 50)
    launchButton.Position = UDim2.new(0.5, -100, 0, 110)
    launchButton.BackgroundColor3 = COLORS.Pink
    launchButton.BorderSizePixel = 0
    launchButton.Text = "🚀 LAUNCH! 🚀"
    launchButton.TextColor3 = COLORS.White
    launchButton.TextSize = 24
    launchButton.Font = Enum.Font.GothamBold
    launchButton.Parent = launchContainer

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = launchButton

    -- 発射結果表示
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Name = "ResultLabel"
    resultLabel.Size = UDim2.new(1, 0, 0, 30)
    resultLabel.Position = UDim2.new(0, 0, 0, 165)
    resultLabel.BackgroundTransparency = 1
    resultLabel.TextColor3 = COLORS.White
    resultLabel.Text = ""
    resultLabel.TextSize = 18
    resultLabel.Font = Enum.Font.GothamBold
    resultLabel.Parent = launchContainer

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

    -- Rainbow Rainオーバーレイ
    local rainbowOverlay = Instance.new("Frame")
    rainbowOverlay.Name = "RainbowOverlay"
    rainbowOverlay.Size = UDim2.new(1, 0, 1, 0)
    rainbowOverlay.Position = UDim2.new(0, 0, 0, 0)
    rainbowOverlay.BackgroundColor3 = COLORS.Rainbow1
    rainbowOverlay.BackgroundTransparency = 1
    rainbowOverlay.BorderSizePixel = 0
    rainbowOverlay.ZIndex = 0
    rainbowOverlay.Parent = screenGui

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

-- 高度表示を更新
local function updateHeightDisplay(newHeight: number)
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local heightFrame = ui:FindFirstChild("TopBar"):FindFirstChild("HeightFrame")
    if not heightFrame then return end

    local label = heightFrame:FindFirstChild("HeightLabel")
    if not label then return end

    label.Text = formatNumber(newHeight) .. "m"
    currentHeight = newHeight
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

-- グローバル高度を更新
local function updateGlobalHeight(totalHeight: number)
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local globalFrame = ui:FindFirstChild("TopBar"):FindFirstChild("GlobalFrame")
    if not globalFrame then return end

    local label = globalFrame:FindFirstChild("GlobalLabel")
    if not label then return end

    label.Text = "全体: " .. formatNumber(totalHeight) .. "m"
end

-- 発射結果を表示
local function showLaunchResult(result)
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local container = ui:FindFirstChild("LaunchContainer")
    if not container then return end

    local resultLabel = container:FindFirstChild("ResultLabel")
    if not resultLabel then return end

    local criticalColor = COLORS.White
    if result.CriticalType == "PERFECT" then
        criticalColor = COLORS.Perfect
    elseif result.CriticalType == "GOOD" then
        criticalColor = COLORS.Good
    end

    resultLabel.TextColor3 = criticalColor
    resultLabel.Text = string.format("%s! +%sm (+%d🪙)",
        result.CriticalType,
        formatNumber(result.Height),
        result.CoinsEarned
    )

    -- 高度を更新
    updateHeightDisplay(result.TotalHeight)

    -- フェードアウト
    task.delay(2, function()
        if resultLabel.Text:find(result.CriticalType) then
            resultLabel.Text = ""
        end
    end)
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

-- ゲージを更新
local function updateGauge(dt: number)
    if not gaugeState.isActive then return end

    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local container = ui:FindFirstChild("LaunchContainer")
    if not container then return end

    local background = container:FindFirstChild("GaugeBackground")
    if not background then return end

    local indicator = background:FindFirstChild("GaugeIndicator")
    if not indicator then return end

    -- ゲージ位置を更新
    gaugeState.position = gaugeState.position + (gaugeState.direction * gaugeState.speed * dt)

    -- 端で反転
    if gaugeState.position >= 1 then
        gaugeState.position = 1
        gaugeState.direction = -1
    elseif gaugeState.position <= 0 then
        gaugeState.position = 0
        gaugeState.direction = 1
    end

    -- インジケーターの位置を更新
    indicator.Position = UDim2.new(gaugeState.position, -4, 0, -2)
end

-- 発射処理
local function performLaunch()
    if not gaugeState.isActive then
        -- ゲージを開始
        gaugeState.isActive = true
        gaugeState.position = 0
        gaugeState.direction = 1

        -- 高度に応じてスピードを計算
        gaugeState.speed = 2.0 + (currentHeight * 0.0001)
        gaugeState.speed = math.min(gaugeState.speed, 8.0)
    else
        -- 発射！
        gaugeState.isActive = false
        RemoteEvents.LaunchRequest:FireServer(gaugeState.position)
    end
end

-- Rainbow Rainエフェクト開始
local function startRainbowRainEffect(data)
    rainbowRainActive = true

    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local overlay = ui:FindFirstChild("RainbowOverlay")
    if not overlay then return end

    showNotification("🌈 RAINBOW RAIN! 🌈",
        string.format("x%.1f ボーナス! %d秒間有効!", data.Multiplier, data.Duration),
        COLORS.Rainbow1)

    -- レインボーアニメーション
    local colors = {COLORS.Rainbow1, COLORS.Rainbow2, COLORS.Rainbow3, COLORS.Rainbow4}
    local colorIndex = 1

    task.spawn(function()
        while rainbowRainActive do
            overlay.BackgroundTransparency = 0.85
            overlay.BackgroundColor3 = colors[colorIndex]
            colorIndex = (colorIndex % #colors) + 1
            task.wait(0.5)
        end
        overlay.BackgroundTransparency = 1
    end)
end

-- Rainbow Rainエフェクト終了
local function endRainbowRainEffect()
    rainbowRainActive = false
    showNotification("Rainbow Rain終了", "また協力して発動しよう!", COLORS.Lavender)
end

-- キャラクターパネルを表示/非表示
local function toggleCharacterPanel()
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local panel = ui:FindFirstChild("CharacterPanel")
    if not panel then return end

    panel.Visible = not panel.Visible
end

-- キャラクターカードを作成
local function createCharacterCard(parent, charData, isActive)
    local card = Instance.new("Frame")
    card.Name = charData.Id
    card.BackgroundColor3 = RARITY_COLORS[charData.Rarity] or COLORS.White
    card.BackgroundTransparency = isActive and 0.1 or 0.3
    card.BorderSizePixel = isActive and 3 or 0
    card.BorderColor3 = COLORS.Perfect

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    -- 絵文字
    local emoji = Instance.new("TextLabel")
    emoji.Size = UDim2.new(1, 0, 0, 50)
    emoji.Position = UDim2.new(0, 0, 0, 5)
    emoji.BackgroundTransparency = 1
    emoji.Text = charData.Emoji or "❓"
    emoji.TextSize = 36
    emoji.Font = Enum.Font.GothamBold
    emoji.Parent = card

    -- 名前
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0, 20)
    name.Position = UDim2.new(0, 0, 0, 55)
    name.BackgroundTransparency = 1
    name.TextColor3 = COLORS.White
    name.Text = charData.Name
    name.TextSize = 10
    name.Font = Enum.Font.GothamBold
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = card

    -- レベル
    local level = Instance.new("TextLabel")
    level.Size = UDim2.new(1, 0, 0, 15)
    level.Position = UDim2.new(0, 0, 0, 75)
    level.BackgroundTransparency = 1
    level.TextColor3 = COLORS.White
    level.Text = "Lv." .. charData.Level
    level.TextSize = 12
    level.Font = Enum.Font.Gotham
    level.Parent = card

    -- ボーナス
    local bonus = Instance.new("TextLabel")
    bonus.Size = UDim2.new(1, 0, 0, 15)
    bonus.Position = UDim2.new(0, 0, 0, 88)
    bonus.BackgroundTransparency = 1
    bonus.TextColor3 = COLORS.Good
    bonus.Text = "+" .. charData.Bonus
    bonus.TextSize = 11
    bonus.Font = Enum.Font.Gotham
    bonus.Parent = card

    return card
end

-- キャラクターリストを更新
local function updateCharacterList()
    local ui = playerGui:FindFirstChild("BrainrotUI")
    if not ui then return end

    local panel = ui:FindFirstChild("CharacterPanel")
    if not panel then return end

    local list = panel:FindFirstChild("CharacterList")
    if not list then return end

    -- 既存のカードを削除
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- キャラクターデータを取得
    local charModule = require(ReplicatedStorage.Shared.BrainrotCharacters)
    local allChars = charModule.CHARACTERS

    -- 各キャラクターのカードを作成
    for _, charDef in ipairs(allChars) do
        local charData = characterCollection[charDef.Id]
        local isActive = activeCharacterId == charDef.Id

        if charData then
            -- 所持しているキャラクター
            charData.Emoji = charDef.Emoji
            createCharacterCard(list, charData, isActive)
        else
            -- 未所持キャラクター（シルエット表示）
            local lockedCard = Instance.new("Frame")
            lockedCard.Name = charDef.Id .. "_Locked"
            lockedCard.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            lockedCard.BackgroundTransparency = 0.5

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = lockedCard

            local question = Instance.new("TextLabel")
            question.Size = UDim2.new(1, 0, 1, 0)
            question.BackgroundTransparency = 1
            question.Text = "?"
            question.TextColor3 = Color3.fromRGB(100, 100, 100)
            question.TextSize = 36
            question.Font = Enum.Font.GothamBold
            question.Parent = lockedCard

            lockedCard.Parent = list
        end
    end

    -- 統計を更新
    local stats = panel:FindFirstChild("StatsLabel")
    if stats then
        local totalCollected = 0
        local rainbowCount = 0
        for _, char in pairs(characterCollection) do
            totalCollected = totalCollected + 1
            if char.Rarity == "Rainbow" then
                rainbowCount = rainbowCount + 1
            end
        end
        stats.Text = string.format("収集数: %d | Rainbow: %d", totalCollected, rainbowCount)
    end
end

-- キャラクター獲得通知
local function showCharacterCollected(charData)
    local rarityColor = RARITY_COLORS[charData.Rarity] or COLORS.White
    local title = string.format("🎉 NEW %s!", string.upper(charData.Rarity))
    local message = string.format("%s を入手! (+%d ボーナス)", charData.Name, charData.Bonus)
    showNotification(title, message, rarityColor)
end

-- ========================================
-- キャラクター運搬システム（共通化）
-- ========================================

-- 運搬状態を完全にリセット
local function resetCarryState()
    -- 既存のWeldを削除
    if CarrySystem.weld and CarrySystem.weld.Parent then
        CarrySystem.weld:Destroy()
    end
    CarrySystem.weld = nil
    CarrySystem.heldModel = nil
    CarrySystem.isCarrying = false
end

local function pickupCharacter(targetModel, characterId, weld)
    if CarrySystem.isCarrying then return false end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- 4. 状態更新（複製品を管理対象にする）
    CarrySystem.heldModel = targetModel
    CarrySystem.weld = weld
    CarrySystem.isCarrying = true

    print("[CarrySystem] 複製して拾い上げました:", characterId)
    print(string.format("[CarrySystem] %s", CarrySystem.heldModel.Name))
    return true
end

local function placeCharacter(slot)
    if not CarrySystem.isCarrying or not CarrySystem.heldModel then return false end
    -- サーバーに「このモデルを、このスロットに置きたい」とリクエスト
    -- RemoteFunctionを使って成否を受け取るのがスマートです
    local success, errorMessage = RemoteFunctions.CharacterPlaceTry:InvokeServer(CarrySystem.heldModel.Name, slot.Name)
    if success then
        -- サーバー側で配置・固定・削除が完了したので、手元の管理をクリアするだけ
        CarrySystem.weld = nil
        CarrySystem.heldModel = nil
        CarrySystem.isCarrying = false
        showNotification("✅ 配置完了!", "スロットに配置しました", COLORS.Good)
        return true
    else
        showNotification("⚠️ 失敗", errorMessage or "配置できませんでした", COLORS.Yellow)
        return false
    end
end

-- スロットからキャラクターを取り外す
local function removeFromSlot(slot)
    if CarrySystem.isCarrying and CarrySystem.heldModel then return true end
    -- サーバーに「このモデルを、このスロットに置きたい」とリクエスト
    -- RemoteFunctionを使って成否を受け取るのがスマートです
    local data = RemoteFunctions.CharacterPickupTry:InvokeServer(slot.Name)
    if data.success then
        -- サーバー側で配置・固定・削除が完了したので、手元の管理をクリアするだけ
        print(string.format("[Client] heldModel: %s", data.heldModel.Name))
        CarrySystem.weld = data.weld
        CarrySystem.heldModel = data.heldModel
        CarrySystem.isCarrying = true
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
    -- キャラクターが再スポーンしたら運搬状態をリセット
    if CarrySystem.isCarrying then
        print("[CarrySystem] リスポーンによりリセット")
        resetCarryState()
    end

    -- Humanoidの死亡を監視
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if CarrySystem.isCarrying and CarrySystem.heldModel then
            -- 持っていたモデルを削除
            if CarrySystem.heldModel.Parent then
                CarrySystem.heldModel:Destroy()
            end
        end
        resetCarryState()
    end)
end)

-- ゲージ更新ループ
RunService.Heartbeat:Connect(function(dt)
    updateGauge(dt)
end)

-- ボタンイベント設定
local ui = playerGui:WaitForChild("BrainrotUI")
local launchButton = ui:WaitForChild("LaunchContainer"):WaitForChild("LaunchButton")

launchButton.MouseButton1Click:Connect(function()
    performLaunch()
end)

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

-- キーボードでも発射可能（スペースキー）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        performLaunch()
    end
end)

-- サーバーイベント受信
RemoteEvents.MoneyChanged.OnClientEvent:Connect(function(newMoney)
    updateCoinsDisplay(newMoney)
end)

RemoteEvents.HeightChanged.OnClientEvent:Connect(function(newHeight)
    updateHeightDisplay(newHeight)
end)

RemoteEvents.LaunchResult.OnClientEvent:Connect(function(result)
    showLaunchResult(result)
end)

RemoteEvents.GlobalHeightUpdate.OnClientEvent:Connect(function(totalHeight)
    updateGlobalHeight(totalHeight)
end)

RemoteEvents.RainbowRainStart.OnClientEvent:Connect(function(data)
    startRainbowRainEffect(data)
end)

RemoteEvents.RainbowRainEnd.OnClientEvent:Connect(function()
    endRainbowRainEffect()
end)

RemoteEvents.NotifyPlayer.OnClientEvent:Connect(function(title, message)
    showNotification(title, message)
end)

-- キャラクター関連イベント
RemoteEvents.CharacterCollected.OnClientEvent:Connect(function(charData)
    characterCollection[charData.Id] = charData
    showCharacterCollected(charData)
end)

-- キャラクター3Dモデル生成イベント
RemoteEvents.CharacterSpawned.OnClientEvent:Connect(function(data)
    -- 既に運搬中なら無視
    if CarrySystem.isCarrying then
        print("[CharacterSpawned] 既に運搬中のためスキップ")
        return
    end

    -- 少し待ってからモデルを探す
    task.wait(0.3)

    local modelName = data.Model.Name
    local weld = data.Weld
    local characterId = data.CharacterId
    local model = data.Model

    if model then
        pickupCharacter(model, characterId, weld)
    else
        warn("[CharacterSpawned] モデルが見つかりません:", modelName)
    end
end)

RemoteFunctions.SlotActionTrigger.OnClientInvoke = function(data)
    -- TODO: キャラクターをスロットに配置する処理を追加
    local slot = data.Slot
    local characterId = slot:GetAttribute("CharacterId")
    if characterId then
        -- とりあげる
        return removeFromSlot(slot)
    else
        -- 設置する
        return placeCharacter(slot)
    end
    
end

RemoteEvents.CharacterSelected.OnClientEvent:Connect(function(charId, newBonus)
    activeCharacterId = charId
    updateCharacterList()
end)

RemoteEvents.CharacterUpgraded.OnClientEvent:Connect(function(charId, newLevel, newBonus)
    if characterCollection[charId] then
        characterCollection[charId].Level = newLevel
    end
    updateCharacterList()
end)

-- 初期データ取得
task.spawn(function()
    task.wait(1)
    local data = RemoteEvents.GetPlayerData:InvokeServer()
    if data then
        updateCoinsDisplay(data.Money)
        updateHeightDisplay(data.Height or 0)
        showNotification("🚀 Brainrot Launch Simulator", "スペースキーまたはボタンで発射!", COLORS.Pink)
    end

    -- グローバル統計取得
    local globalStats = RemoteEvents.GetGlobalStats:InvokeServer()
    if globalStats then
        updateGlobalHeight(globalStats.TotalHeight)
        if globalStats.IsRainbowRain then
            startRainbowRainEffect({
                Duration = globalStats.RainbowRainTimeLeft,
                Multiplier = 3.0
            })
        end
    end

    -- キャラクターコレクション取得
    local collection = RemoteEvents.GetCharacterCollection:InvokeServer()
    if collection then
        characterCollection = collection.Characters or {}
        activeCharacterId = collection.ActiveCharacter
    end
end)

print("[Client] 初期化完了")
