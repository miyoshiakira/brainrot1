--[[
    Brainrot Launch Simulator サーバーメインスクリプト
    - DataManager: プレイヤーデータ管理
    - LaunchManager: 発射システム & グローバルイベント
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- モジュール読み込み待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")

local DataManager = require(script.Modules.DataManager)
local LaunchModule = require(script.Modules.LaunchManager)
local LaunchManager = LaunchModule.LaunchManager
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
-- CharacterController を読み込む
-- これにより、CharacterController.luau 内の OnServerInvoke が登録される
local _CharacterController = require(script.Modules.CharacterController)
local MonsterManager = require(script.Modules.MonsterManager)

print("CharacterController has been initialized.")
print("=================================")
print("Brainrot Launch Simulator サーバー起動")
print("=================================")

-- プレイヤーデータ取得（RemoteFunction）
RemoteEvents.GetPlayerData.OnServerInvoke = function(player)
    local profile = DataManager.GetProfile(player)
    if profile then
        return {
            Money = profile.Money,
            Height = profile.Height,
            TotalHeight = profile.TotalHeight,
            CharacterBonus = profile.CharacterBonus,
            BasePower = profile.BasePower,
            Characters = profile.Characters or {},
            ActiveCharacter = profile.ActiveCharacter,
            TotalCharactersCollected = profile.TotalCharactersCollected or 0,
            RainbowCharactersFound = profile.RainbowCharactersFound or 0,
        }
    end
    return nil
end

-- MoneyBoxの参照取得
local CommonFunctions = require(script.Modules.CommonFunctions)
local moneyBox = CommonFunctions.findModelById(game.workspace, "MoneyBox")
function setUpMoneyBox(player)
    if moneyBox then
        -- UI要素の取得
        local floatingPanel = moneyBox:FindFirstChild("FloatingTextPanel")
        local amountLabel = floatingPanel and floatingPanel:FindFirstChild("Amount", true) -- trueで子孫まで探す

        -- テキストを更新する関数
        local function updateDisplay()
            local currentMoney = moneyBox:GetAttribute("Money" .. player.UserId) or 0
            if amountLabel then
                -- string.format でカンマ区切りや単位をつけると見栄えが良くなります
                amountLabel.Text = string.format("$%d", currentMoney)
            end
        end

        -- 1. Attributeが変更されたら実行されるように紐付け (イベント駆動)
        moneyBox:GetAttributeChangedSignal("Money" .. player.UserId):Connect(updateDisplay)

        -- 2. 初回起動時にも一度更新しておく
        updateDisplay()
    end
end
local CollectionService = game:GetService("CollectionService")

-- プレイヤー入室処理
Players.PlayerAdded:Connect(function(player)
    print("[Server] プレイヤー入室:", player.Name)

    -- Leaderstatsを作成
    LaunchManager.CreateLeaderstats(player)

    -- データ読み込み待機
    task.wait(1)

    local profile = DataManager.GetProfile(player)
    if profile then
        -- Leaderstatsを更新
        LaunchManager.UpdateLeaderstats(player)

        -- パッシブコイン生成を開始
        setUpMoneyBox(player)

        -- 初期お金を通知
        RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        RemoteEvents.HeightChanged:FireClient(player, profile.Height)

        -- 放置報酬があれば通知
        if profile.SessionCount > 1 then
            RemoteEvents.NotifyPlayer:FireClient(player, "おかえりなさい！", "セッション #" .. profile.SessionCount)
        end
    end


end)

-- お金が変わったときの通知（DataManagerから呼び出し可能にする）
local originalAddMoney = DataManager.AddMoney
DataManager.AddMoney = function(player: Player, amount: number): boolean
    local result = originalAddMoney(player, amount)
    if result then
        local profile = DataManager.GetProfile(player)
        if profile then
            RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        end
    end
    return result
end

local originalSpendMoney = DataManager.SpendMoney
DataManager.SpendMoney = function(player: Player, amount: number): boolean
    local result = originalSpendMoney(player, amount)
    if result then
        local profile = DataManager.GetProfile(player)
        if profile then
            RemoteEvents.MoneyChanged:FireClient(player, profile.Money)
        end
    end
    return result
end

-- LaunchManagerを初期化
LaunchManager.Initialize()

-- スロットの挙動を初期化する関数
local function setupSlot(slot)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = slot
    prompt.ObjectText = "スロット"
    prompt.ActionText = "配置する"    
    prompt.Triggered:Connect(function(player)
        -- ここに「持っているものを置く」共通ロジック
        -- クライアントに通知
        local success = RemoteFunctions.SlotActionTrigger:InvokeClient(player, {
            Slot = slot,
        })
        local monsterId = slot:GetAttribute("MonsterId")
        print(string.format("monsterId: %s", tostring(monsterId)))
        if monsterId then
            prompt.ActionText = "ひろう"
        else
            prompt.ActionText = "配置する"
        end
    end)
end

-- 既存の全スロットに適用
for _, slot in ipairs(CollectionService:GetTagged("SlotPart")) do
    setupSlot(slot)
end

-- 後から生成されたスロットにも自動適用（エンジニアらしい設計）
CollectionService:GetInstanceAddedSignal("SlotPart"):Connect(setupSlot)


-- JumpPadの挙動を初期化する関数
local function setupJumpPad(jumpPad)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = jumpPad
    prompt.ObjectText = "発射台"
    prompt.ActionText = "発射する"
    prompt.Triggered:Connect(function(player)
        -- クライアントにUI表示を依頼
        local _success = RemoteFunctions.JumpPadAction:InvokeClient(player, {
            JumpPad = jumpPad,
        })
    end)
end

-- 既存の全JumpPadに適用
for _, jumpPad in ipairs(CollectionService:GetTagged("JumpPad")) do
    setupJumpPad(jumpPad)
end

-- 後から生成されたJumpPadにも自動適用
CollectionService:GetInstanceAddedSignal("JumpPad"):Connect(setupJumpPad)

-- MoneyBoxの挙動を初期化する関数
local function setUpMoneyBoxAction(moneyBox)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = moneyBox
    prompt.ObjectText = "貯金箱"
    prompt.ActionText = "集金する"
    prompt.Triggered:Connect(function(player)
        local money = moneyBox:GetAttribute("Money" .. player.UserId) or 0
        if money > 0 then
            DataManager.AddMoney(player, money)
            moneyBox:SetAttribute("Money" .. player.UserId, 0)
        end
    end)
end

-- 既存の全JumpPadに適用
for _, box in ipairs(CollectionService:GetTagged("MoneyBox")) do
    setUpMoneyBoxAction(box)
end

-- 後から生成されたMoneyBoxにも自動適用
CollectionService:GetInstanceAddedSignal("MoneyBox"):Connect(setUpMoneyBoxAction)

-- 既存の加算ループ処理
task.spawn(function()
    while true do
        task.wait(1)
        for _, player in ipairs(game.Players:GetPlayers()) do
            local income = MonsterManager.GetSlotIncomePerSecond(player)
            print("Income:".. income)
            if income > 0 then
                -- ここで属性を更新するだけで、上のConnectした関数が自動で動く！
                if moneyBox then
                    local current = moneyBox:GetAttribute("Money" .. player.UserId) or 0
                    moneyBox:SetAttribute("Money" .. player.UserId, current + income)
                end
            end
        end
    end
end)

print("[Server] 初期化完了")
