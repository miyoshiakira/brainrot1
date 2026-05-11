local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonFunctions = require(script.Parent.CommonFunctions)
local CommonAnimationFunctions = require(script.Parent.CommonAnimationFunctions)
local EquipmentSystem = require(script.Parent.EquipmentSystem)
local DataManager = require(script.Parent.DataManager)
local MonsterManager = require(script.Parent.MonsterManager)
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local AreaMaster = require(ReplicatedStorage.Shared.AreaMaster)
local constants = require("../Constants")

-- スロットの挙動を初期化する関数
local function setupSlot(slot)
    -- 既にProximityPromptがある場合は重複作成を防止
    if slot:FindFirstChildOfClass("ProximityPrompt") then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = slot.PrimaryPart
    prompt.ObjectText = "スロット"
    prompt.ActionText = "配置する"    
    prompt.Triggered:Connect(function(player)
        -- ここに「持っているものを置く」共通ロジック
        -- クライアントに通知
        local _success = RemoteFunctions.SlotActionTrigger:InvokeClient(player, {
            Slot = slot,
        })
        local monsterId = slot:GetAttribute("MonsterId")
        local isCarrying = player.Character and player.Character:FindFirstChild(constants.CHARACTER_MODEL_NAME) ~= nil
        print(string.format("monsterId: %s", tostring(monsterId)))
        if monsterId and isCarrying then
            prompt.ActionText = "ひろう"
        else
            prompt.ActionText = "配置する"
        end
    end)
end

-- MoneyBoxの挙動を初期化する関数
local MoneyEffect = require(script.Parent.MoneyEffect)

local function setUpMoneyBoxAction(moneyBox)
    -- 既にProximityPromptがある場合は重複作成を防止
    if moneyBox:FindFirstChildOfClass("ProximityPrompt") then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = moneyBox
    prompt.ObjectText = "貯金箱"
    prompt.ActionText = "集金する"
    prompt.MaxActivationDistance = 10
    prompt.Triggered:Connect(function(player)
        local money = moneyBox:GetAttribute("Money" .. player.UserId) or 0
        if money > 0 then
            DataManager.AddMoney(player, money)
            moneyBox:SetAttribute("Money" .. player.UserId, 0)

            -- お金取得効果音
            CommonFunctions.PlayAudioByNameAt("GetMoney", moneyBox)
            -- お金取得エフェクト
            MoneyEffect.Play(moneyBox:GetPivot())
        end
    end)
end

-- TrashBoxの挙動を初期化する関数
local function setUpTrashBoxAction(trashBox)
    -- 既にProximityPromptがある場合は重複作成を防止
    local body = trashBox.PrimaryPart
    if not body then return end
    if body:FindFirstChildOfClass("ProximityPrompt") then return end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = body
    prompt.ObjectText = "モンスターゴミ箱"
    prompt.ActionText = "捨てる"
    prompt.MaxActivationDistance = 10
    prompt.Triggered:Connect(function(player)
        local target = player.Character:FindFirstChild(constants.CHARACTER_MODEL_NAME)
        if target then
            -- プレイヤーのHumanoidRootPartからWeldを解除
            CommonFunctions.dettachCharacter(player)
            target:Destroy()
            -- Client側にも通知する
            RemoteFunctions.TrashBoxAction:InvokeClient(player)
        end
    end)
end

-- 釣り竿アップグレードの挙動を初期化する関数
local ROD_UPGRADE_COSTS = {
    100,    -- FishingRod1 → 2
    500,    -- FishingRod2 → 3
    2000,   -- FishingRod3 → 4
    10000,  -- FishingRod4 → 5
}

-- エリア解放の挙動を初期化する関数
-- AreaBlockタグからエリア名に対応するコストを検索
local function getAreaCost(areaName: string): number?
    return AreaMaster.GetCost(areaName)
end

-- AreaBlockにProximityPromptを設定
local AREA_BLOCK_TAG = "AreaBlock"

local function setupAreaBlocks()
    local areaBlocks = CollectionService:GetTagged(AREA_BLOCK_TAG)
    for _, areaBlock in ipairs(areaBlocks) do
        local areaName = areaBlock:GetAttribute("AreaName")
        if not areaName then
            warn(string.format("[AreaBlock] AreaName属性が未設定: %s", areaBlock.Name))
            continue
        end

        local cost = getAreaCost(areaName)
        if not cost then
            warn(string.format("[AreaBlock] 不明なエリア名: %s", areaName))
            continue
        end

        local body = areaBlock.PrimaryPart or areaBlock:FindFirstChildWhichIsA("BasePart")
        if not body then continue end

        -- 既存プロンプトがあればスキップ
        if body:FindFirstChildOfClass("ProximityPrompt") then continue end

        local prompt = Instance.new("ProximityPrompt")
        prompt.Parent = body
        prompt.ObjectText = areaName
        prompt.ActionText = string.format("解放する(%s)", MonsterManager.FormatNumber(cost))
        prompt.MaxActivationDistance = 15

        prompt.Triggered:Connect(function(player)
            -- クライアントにエリア解放要求を送る（クライアント側で最終判定）
            RemoteEvents.AreaUnlockRequest:FireClient(player, areaName, cost)
        end)
    end

    -- 実行中に追加されたAreaBlockにも対応
    CollectionService:GetInstanceAddedSignal(AREA_BLOCK_TAG):Connect(function(areaBlock)
        task.wait(0.5)
        local areaName = areaBlock:GetAttribute("AreaName")
        if not areaName then return end
        local cost = getAreaCost(areaName)
        if not cost then return end

        local body = areaBlock.PrimaryPart or areaBlock:FindFirstChildWhichIsA("BasePart")
        if not body then return end
        if body:FindFirstChildOfClass("ProximityPrompt") then return end

        local prompt = Instance.new("ProximityPrompt")
        prompt.Parent = body
        prompt.ObjectText = areaName
        prompt.ActionText = string.format("解放する(%s)", MonsterManager.FormatNumber(cost))
        prompt.MaxActivationDistance = 15

        prompt.Triggered:Connect(function(player)
            RemoteEvents.AreaUnlockRequest:FireClient(player, areaName, cost)
        end)
    end)
end

-- 釣り竿アップグレードの挙動を初期化する関数
local function setUpVoxelBaitShopAction(_player: Player)
    local VoxelBaitShop = game.workspace:FindFirstChild("VoxelBaitShop")
    if not VoxelBaitShop then return end
    -- 既にProximityPromptがある場合は重複作成を防止
    local body = VoxelBaitShop.PrimaryPart
    if not body then return end
    if body:FindFirstChildOfClass("ProximityPrompt") then return end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Parent = body
    prompt.ObjectText = "釣り竿ショップ"
    prompt.ActionText = "アップグレード"
    prompt.MaxActivationDistance = 10
    prompt.Triggered:Connect(function(player)
        local currentRank = EquipmentSystem.getRodRank(player)
        local maxRank = #EquipmentSystem.getRodLevelNames()

        -- 既に最大ランク
        if currentRank >= maxRank then
            RemoteEvents.NotifyPlayer:FireClient(player, "🎣 釣り竿", "これ以上アップグレードできません！")
            return
        end

        -- コスト取得
        local upgradeCost = ROD_UPGRADE_COSTS[currentRank]
        if not upgradeCost then
            RemoteEvents.NotifyPlayer:FireClient(player, "⚠️ エラー", "アップグレードコストが未定義です")
            return
        end

        -- 所持金チェック
        local success = DataManager.SpendMoney(player, upgradeCost)
        if not success then
            RemoteEvents.NotifyPlayer:FireClient(player, "⚠️ 所持金不足",
                string.format("アップグレードには %s 必要です", MonsterManager.FormatNumber(upgradeCost)))
            return
        end

        -- 次ランクの釣り竿を装備
        local nextRank = currentRank + 1
        local nextRodName = "FishingRod" .. nextRank
        EquipmentSystem.equipFishingRod(player, nextRodName)

        -- プロファイルに保存
        local profile = DataManager.GetProfile(player)
        if profile then
            profile.EquippedRodName = nextRodName
        end

        -- クライアントに釣り竿ランク変更を通知
        RemoteEvents.RodRankChanged:FireClient(player, nextRank)

        -- プロンプトのテキスト更新
        if nextRank < maxRank then
            local nextCost = ROD_UPGRADE_COSTS[nextRank]
            prompt.ActionText = string.format("アップグレード(%s)", MonsterManager.FormatNumber(nextCost or 0))
        else
            prompt.ActionText = "MAX"
        end

        RemoteEvents.NotifyPlayer:FireClient(player, "🎣 釣り竿アップグレード!",
            string.format("FishingRod%d → FishingRod%d", currentRank, nextRank))

        -- レベルアップ音再生
        CommonFunctions.PlayAudioByNameAt("LevelUp", player.Character)

        print(string.format("[BaitShop] %s: FishingRod%d → FishingRod%d (cost: %d)", player.Name, currentRank, nextRank, upgradeCost))
    end)

    -- 初期表示: 現在のランクに応じたコストを表示
    local function updatePromptText()
        -- 全プレイヤー共通のショップなので、近くにいるプレイヤーのランクを反映できない
        -- 既定としてFishingRod1→2のコストを表示
        prompt.ActionText = string.format("アップグレード(%s)", MonsterManager.FormatNumber(ROD_UPGRADE_COSTS[1]))
    end
    updatePromptText()
end

local function FindPlayerBase(player)
    local playerBase = CommonFunctions.findModelById(game.workspace, CreatePlayerBaseName(player))
    return playerBase
end

local function setUpMoneyBox(player)
    local moneyBox = FindPlayerBase(player):FindFirstChild("MoneyBox")
    if moneyBox then
        -- UI要素の取得
        local floatingPanel = moneyBox:FindFirstChild("FloatingTextPanel")
        local amountLabel = floatingPanel and floatingPanel:FindFirstChild("Amount", true) -- trueで子孫まで探す

        -- テキストを更新する関数
        local function updateDisplay()
            local currentMoney = moneyBox:GetAttribute("Money" .. player.UserId) or 0
            if amountLabel then
                -- string.format でカンマ区切りや単位をつけると見栄えが良くなります
                amountLabel.Text = string.format("$%s", MonsterManager.FormatNumber(currentMoney))
            end
        end

        -- 1. Attributeが変更されたら実行されるように紐付け (イベント駆動)
        moneyBox:GetAttributeChangedSignal("Money" .. player.UserId):Connect(updateDisplay)

        -- 2. 初回起動時にも一度更新しておく
        updateDisplay()
    end
end

-- キャラクターのレベルを強化
local function upgradeCharacter(player, UpgradeButton, upgradeCost)
    local character = UpgradeButton.Parent:FindFirstChild(constants.CHARACTER_MODEL_NAME)
    if not character then
        return { success = false, error = "No character on slot" }
    end

    -- アニメーション中は強化不可
    if character:GetAttribute("IsAnimating") then
        return { success = false, error = "アニメーション中です" }
    end

    local currentLevel = character:GetAttribute("Level") or 1

    -- お金の減算（残高不足なら失敗）
    local success = DataManager.SpendMoney(player, upgradeCost)
    if not success then
        return { success = false, error = "Not enough money", cost = upgradeCost }
    end
    print("UpgradeButtonActionTrigger - Money spent")
    -- レベルアップ
    character:SetAttribute("Level", currentLevel + 1)

    -- レベルアップ音再生
    CommonFunctions.PlayAudioByNameAt("LevelUp", character)

    -- レベルに応じたスケール更新
    CommonFunctions.ScaleModelByLevel(character, currentLevel + 1)

    -- 強化演出：回転しながら上昇→下降（終了時にスロットの前方を向く）
    local slot = UpgradeButton.Parent
    local slotPrimary = slot.PrimaryPart or slot:FindFirstChildWhichIsA("BasePart")
    local Y_OFFSET = 5.0
    local slotCFrame = slotPrimary.CFrame
    local targetPosition = slotCFrame.Position + Vector3.new(0, Y_OFFSET, 0)
    local finalCFrame = CFrame.new(targetPosition, slotCFrame.LookVector * 1e6)
    CommonAnimationFunctions.levelUpAnimation(character, 3, 0.5, finalCFrame)

    print(string.format("[Upgrade] %s: Lv.%d → Lv.%d (cost: %d)", character.Name, currentLevel, currentLevel + 1, upgradeCost))

    return { success = true, character = character }
end

local upgradeConnections = {} -- 接続を保存しておくためのテーブル
-- スロットの挙動を初期化する関数
local function setupUpgradeButton(slot)
    -- 強化対象チェック
    local upgradeButton = slot:FindFirstChild("UpgradeButton")
    local targetModel = slot:FindFirstChild(constants.CHARACTER_MODEL_NAME)
    if not targetModel then
        local prompt = upgradeButton:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            prompt:Destroy()
        end
        return
    end
    -- コストは確定
    local upgradeCost = MonsterManager.GetUpgradeCost(targetModel)
    -- 既にProximityPromptがある場合は更新して、無い場合は新規作成
    local prompt = upgradeButton:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
    end

    prompt.Parent = upgradeButton
    prompt.ObjectText = "強化ボタン"
    prompt.ActionText = string.format("強化する(%s)", MonsterManager.FormatNumber(upgradeCost))
-- 1. 以前の接続があれば解除する
    if upgradeConnections[slot.Name] then
        upgradeConnections[slot.Name]:Disconnect()
        upgradeConnections[slot.Name] = nil
    end
    upgradeConnections[slot.Name] = prompt.Triggered:Connect(function(player)
        print("UpgradeButton:Parent Test:", upgradeButton.Parent)
        local result = upgradeCharacter(player, upgradeButton, upgradeCost)
        if result.success == false then
            -- 強化失敗：クライアントに通知
            RemoteEvents.NotifyPlayer:FireClient(player, "⚠️ 強化失敗", result.error or "強化できませんでした")
            return
        end
        MonsterManager.UpdateMonsterUI(result.character)
        -- コスト更新
        setupUpgradeButton(slot)  
    end)
end

-- プレイヤー入室時にPlayerBaseを初期化
local function SetupPlayerBase(player: Player)
    -- local playerBaseTemplate = ReplicatedStorage:FindFirstChild("PlayerBase")
    -- if not playerBaseTemplate then
    --     warn("[PlayerBaseController] PlayerBaseテンプレートがReplicatedStorageに見つかりません")
    --     return
    -- end
    -- 現在のプレイヤー数を取得
	local playerCount = #Players:GetPlayers()
    local playerBase = game.Workspace:FindFirstChild("PlayerBase" .. playerCount)

    playerBase.Name = CreatePlayerBaseName(player)
    playerBase.Parent = game.Workspace

    -- プレイヤー固有の初期化処理
    playerBase:SetAttribute("Owner", player.UserId)

    -- Slot初期化
    local monsterSlotsFolder = playerBase:FindFirstChild("MonsterSlots")
    if monsterSlotsFolder then
        local slotIndex = 1
        for _, slot in ipairs(monsterSlotsFolder:GetChildren()) do
            print(string.format("スロット %d (%s) を初期化中...", slotIndex, slot.Name))
            slot:SetAttribute("Owner", player.UserId)
            slot.Name = "Slot" .. slotIndex .. "_" .. player.UserId
            slotIndex = slotIndex + 1
            setupSlot(slot)
        end
    end

    -- MoneyBox初期化
    local moneyBox = playerBase:FindFirstChild("MoneyBox")
    if moneyBox then
            moneyBox:SetAttribute("Owner", player.UserId)
            setUpMoneyBoxAction(moneyBox)
    end

    -- TrashBox初期化
    local trashBox = playerBase:FindFirstChild("TrashBox")
    if trashBox then
            trashBox:SetAttribute("Owner", player.UserId)
            setUpTrashBoxAction(trashBox)
    end
    -- パッシブコイン生成を開始
    setUpMoneyBox(player)
    -- 釣り竿屋さん
    setUpVoxelBaitShopAction(player)

    -- 既存の加算ループ処理
    task.spawn(function()
        while true do
            task.wait(1)
            local income = GetSlotIncomePerSecond(player)
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

local function FindPlayerSlots(player)
    local playerBase = FindPlayerBase(player)
    if not playerBase then
        return nil
    end
    local monsterSlotsFolder = playerBase:FindFirstChild("MonsterSlots")
   
    return monsterSlotsFolder:GetChildren()
end

local function FindPlayerSlotsMonsters(player)
    -- プレイヤーの全スロットを取得
    local slots = FindPlayerSlots(player)
    local monsterList = {}

    if slots then
        for _, slot in ipairs(slots) do
            local monster = slot:FindFirstChild(constants.CHARACTER_MODEL_NAME)
            if monster then
                table.insert(monsterList, monster)
            end
        end
    end
    return monsterList
end

-- プレイヤーのスロット配置モンスターの合算収入を取得
function GetSlotIncomePerSecond(player: Player): number
    local totalIncome = 0
    local monsters = FindPlayerSlotsMonsters(player)
    for _, monster in ipairs(monsters) do
        totalIncome += MonsterManager.CalcIncomePerSecond(monster)
    end
    return totalIncome
end

function CreatePlayerBaseName(player)
    local targetName = "PlayerBase_" .. player.UserId
    return targetName
end

-- プレイヤー退室時にPlayerBaseを削除
function CleanupPlayerBase(player: Player)
    local playerBase = game.Workspace:FindFirstChild("PlayerBase_" .. player.UserId)
    if playerBase then
        playerBase:Destroy()
    end
end

local DEFAULT_ROD_NAME = "FishingRod1"

-- 現在のスロット状態をプロファイルに保存
function SaveSlots(player: Player)
    local slots = FindPlayerSlots(player)
    for _, slot in ipairs(slots) do
        setupUpgradeButton(slot)
    end
    DataManager.SaveSlotData(player, slots)

    -- 釣り竿名をプロファイルに保存
    local rodName = EquipmentSystem.getFishingRodName(player)
    local profile = DataManager.GetProfile(player)
    if profile then
        profile.EquippedRodName = rodName
    end
end

-- プロファイルからスロット状態を復元（モンスターをスロットに配置）
function RestoreSlots(player: Player)
    local slots = FindPlayerSlots(player)

    local slotData = DataManager.LoadSlotData(player)
    print("[RestoreSlots] slotData count:", #slotData)
    if not slotData or #slotData == 0 then return end

    local slotIndex = 1
    for _, slot in ipairs(slots) do
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
                local Y_OFFSET = 5.0
                local targetCFrame = slot.PrimaryPart.CFrame * CFrame.new(0, Y_OFFSET, 0)
                charModel:PivotTo(targetCFrame)
                charModel.Parent = slot
                CommonFunctions.enableAnchor(charModel, true)
                CommonFunctions.enableCollider(charModel, false)
                -- 属性設定（保存済みデータから復元）
                MonsterManager.MappingStatus(monsterInfo, charModel)
                charModel:SetAttribute("Owner", player.UserId)

                -- レベルに応じたスケール適用
                CommonFunctions.ScaleModelByLevel(charModel, monsterInfo.Level or 1)

                -- UI更新
                MonsterManager.UpdateMonsterUI(charModel)

                -- スロット属性更新
                slot:SetAttribute("MonsterId", monsterId)
                slot:SetAttribute("Occupied", true)
                -- ProximityPromptのテキスト更新
                -- 強化ボタンのイベント設定
                setupUpgradeButton(slot)
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

-- 釣り竿をプロファイルから復元して装備
function EquipFishingRod(player: Player)
    local profile = DataManager.GetProfile(player)
    if not profile then return end

    -- キャラクターがまだスポーンしていない場合は待機
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end

    local rodName = profile.EquippedRodName or DEFAULT_ROD_NAME
    EquipmentSystem.equipFishingRod(player, rodName)
    print(string.format("[PlayerBaseController] %s に釣り竿 %s を装備", player.Name, rodName))
end

return {
    setupUpgradeButton = setupUpgradeButton,
    setupAreaBlocks = setupAreaBlocks,
    FindPlayerBase = FindPlayerBase,
    FindPlayerSlots = FindPlayerSlots,
    FindPlayerSlotsMonsters = FindPlayerSlotsMonsters,
    GetSlotIncomePerSecond = GetSlotIncomePerSecond,
    CreatePlayerBaseName = CreatePlayerBaseName,
    CleanupPlayerBase = CleanupPlayerBase,
    SaveSlots = SaveSlots,
    RestoreSlots = RestoreSlots,
    EquipFishingRod = EquipFishingRod,
    SetupPlayerBase = SetupPlayerBase,
}
