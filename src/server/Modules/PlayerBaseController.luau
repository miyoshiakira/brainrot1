local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CommonFunctions = require(script.Parent.CommonFunctions)
local DataManager = require(script.Parent.DataManager)
local MonsterManager = require(script.Parent.MonsterManager)
local BrainrotMonsters = require(ReplicatedStorage.Shared.BrainrotMonsters)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
local constants = require("../Constants")

local PlayerBaseController = {}

-- スロットの挙動を初期化する関数
local function setupSlot(slot)
    -- 既にProximityPromptがある場合は重複作成を防止
    if slot:FindFirstChildOfClass("ProximityPrompt") then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = slot
    prompt.ObjectText = "スロット"
    prompt.ActionText = "配置する"    
    prompt.Triggered:Connect(function(player)
        -- ここに「持っているものを置く」共通ロジック
        -- クライアントに通知
        local _success = RemoteFunctions.SlotActionTrigger:InvokeClient(player, {
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

-- JumpPadの挙動を初期化する関数
local function setupJumpPad(jumpPad)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = jumpPad
    prompt.ObjectText = "発射台"
    prompt.ActionText = "発射する"
    prompt.Triggered:Connect(function(player)
        -- クライアントにUI表示を依頼
        print(string.format("JumpPad triggered by %s", player.Name))
        local _success = RemoteFunctions.JumpPadAction:InvokeClient(player, {
            JumpPad = jumpPad,
        })
    end)
end

-- MoneyBoxの挙動を初期化する関数
local function setUpMoneyBoxAction(moneyBox)
    -- 既にProximityPromptがある場合は重複作成を防止
    if moneyBox:FindFirstChildOfClass("ProximityPrompt") then return end

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

function setUpMoneyBox(player)
    local moneyBox = PlayerBaseController.FindPlayerBase(player):FindFirstChild("MoneyBox")
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

-- プレイヤー入室時にPlayerBaseを初期化
function PlayerBaseController.SetupPlayerBase(player: Player)
    local playerBaseTemplate = ReplicatedStorage:FindFirstChild("PlayerBase")
    if not playerBaseTemplate then
        warn("[PlayerBaseController] PlayerBaseテンプレートがReplicatedStorageに見つかりません")
        return
    end

    local playerBase = playerBaseTemplate:Clone()
    playerBase.Name = "PlayerBase_" .. player.UserId
    playerBase.Parent = game.Workspace

    -- プレイヤー固有の初期化処理
    playerBase:SetAttribute("Owner", player.UserId)

    -- Slot初期化
    local monsterSlotsFolder = playerBase:FindFirstChild("MonsterSlots")
    if monsterSlotsFolder then
        local slotIndex = 1
        for _, slot in ipairs(monsterSlotsFolder:GetChildren()) do
            if slot:IsA("BasePart") then
                print(string.format("スロット %d (%s) を初期化中...", slotIndex, slot.Name))
                slot:SetAttribute("Owner", player.UserId)
                slot.Name = "Slot" .. slotIndex .. "_" .. player.UserId
                slotIndex = slotIndex + 1
                setupSlot(slot)
            end
        end
    end

    -- JumpPad初期化
    local launchPadAreaFolder = playerBase:FindFirstChild("LaunchPadArea")
    if launchPadAreaFolder then
        local launchPad = launchPadAreaFolder:FindFirstChild('LaunchPad')
        if launchPad then
            launchPad:SetAttribute("Owner", player.UserId)
            setupJumpPad(launchPad)
        end
    end

    -- MoneyBox初期化
    local moneyBox = playerBase:FindFirstChild("MoneyBox")
    if moneyBox then
            moneyBox:SetAttribute("Owner", player.UserId)
            setUpMoneyBoxAction(moneyBox)
    end
    -- パッシブコイン生成を開始
    setUpMoneyBox(player)

    -- 既存の加算ループ処理
    task.spawn(function()
        while true do
            task.wait(1)
            local income = MonsterManager.GetSlotIncomePerSecond(player)
            if income > 0 then
                -- ここで属性を更新するだけで、上のConnectした関数が自動で動く！
                if moneyBox then
                    local current = moneyBox:GetAttribute("Money" .. player.UserId) or 0
                    moneyBox:SetAttribute("Money" .. player.UserId, current + income)
                end
            end
        end
    end)
end

function PlayerBaseController.FindPlayerBase(player)
    local playerBase = CommonFunctions.findModelById(game.workspace, PlayerBaseController.CreatePlayerBaseName(player))
    return playerBase
end

function PlayerBaseController.FindPlayerSlots(player)
    local playerBase = PlayerBaseController.FindPlayerBase(player)
    local monsterSlotsFolder = playerBase:FindFirstChild("MonsterSlots")
    return monsterSlotsFolder:GetChildren()
end

function PlayerBaseController.CreatePlayerBaseName(player)
    local targetName = "PlayerBase_" .. player.UserId
    return targetName
end

-- プレイヤー退室時にPlayerBaseを削除
function PlayerBaseController.CleanupPlayerBase(player: Player)
    local playerBase = game.Workspace:FindFirstChild("PlayerBase_" .. player.UserId)
    if playerBase then
        playerBase:Destroy()
    end
end

-- 現在のスロット状態をプロファイルに保存
function PlayerBaseController.SaveSlots(player: Player)

    local slots = PlayerBaseController.FindPlayerSlots(player)
    DataManager.SaveSlotData(player, slots)
end

-- プロファイルからスロット状態を復元（モンスターをスロットに配置）
function PlayerBaseController.RestoreSlots(player: Player)
    local slots = PlayerBaseController.FindPlayerSlots(player)

    local slotData = DataManager.LoadSlotData(player)
    print("[RestoreSlots] slotData count:", #slotData)
    if not slotData or #slotData == 0 then return end

    local slotIndex = 1
    for _, slot in ipairs(slots) do
        if slot:IsA("BasePart") then
            local monsterInfo = slotData[slotIndex]
            if monsterInfo then
                -- slotData[slotIndex] は Monster テーブル
                local monsterId = monsterInfo.MonsterId
                local modelName = monsterInfo.ModelName

                if not monsterId or not modelName then
                    warn(string.format("[RestoreSlots] スロット%d: monsterId/ModelName がnil", slotIndex))
                    slotIndex = slotIndex + 1
                    continue
                end

                -- テンプレートからClone
                local templatesFolder = ReplicatedStorage:FindFirstChild("CharacterTemplates")
                local template = templatesFolder and templatesFolder:FindFirstChild(modelName)
                if template then
                    local charModel = template:Clone()
                    CommonFunctions.autoWeldModel(charModel)
                    charModel.Name = constants.CHARACTER_MODEL_NAME

                    -- レアリティに応じた色変更＋物理設定
                    local rarity = monsterInfo.Rarity
                    MonsterManager.SetupCharModel(charModel, rarity)

                    -- スロットに配置
                    local Y_OFFSET = 3.0
                    local targetCFrame = slot.CFrame * CFrame.new(0, Y_OFFSET, 0)
                    charModel:PivotTo(targetCFrame)
                    CommonFunctions.enableAnchor(charModel, true)
                    charModel.Parent = slot

                    -- 属性設定（保存済みデータから復元）
                    MonsterManager.SetInitStatus(charModel, monsterId, modelName)
                    charModel:SetAttribute("Owner", player.UserId)

                    -- スロット属性更新
                    slot:SetAttribute("MonsterId", monsterId)
                    slot:SetAttribute("Occupied", true)

                    -- ProximityPromptのテキスト更新
                    local prompt = slot:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        prompt.ActionText = "ひろう"
                    end

                    print(string.format("[PlayerBaseController] %s のスロット%d に %s を復元", player.Name, slotIndex, monsterId))
                else
                    warn(string.format("[PlayerBaseController] テンプレート未発見: %s", modelName or "nil"))
                end
            end
            slotIndex = slotIndex + 1
        end
    end
end

return PlayerBaseController
