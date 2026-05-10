local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommonFunctions = require(script.Parent.CommonFunctions)

local EquipmentSystem = {}

-- 装備オブジェクト名
local FISHING_ROD_FOLDER = "FishingRod"
local FISHING_ROD_WELD = "FishingRodWeld"

EquipmentSystem.FISHING_ROD_FOLDER = FISHING_ROD_FOLDER

-- ========================================
-- 釣り竿レベル別パラメータ
-- ========================================
local ROD_LEVELS = {
	FishingRod1 = {
		Size = Vector3.new(1, 10, 1),
		Attributes = {
			ColorHandleBase = Color3.fromRGB(60, 40, 25),
			ColorHandle = Color3.fromRGB(100, 65, 40),
			ColorShaft = Color3.fromRGB(120, 80, 50),
			ColorReelBlue = Color3.fromRGB(70, 110, 160),
			ColorReelGrey = Color3.fromRGB(200, 200, 200),
			ColorGuide = Color3.fromRGB(150, 150, 150),
			ColorLine = Color3.fromRGB(240, 240, 240),
			ColorLure = Color3.fromRGB(60, 180, 80),
			ColorHook = Color3.fromRGB(120, 120, 120),
			ColorCrank = Color3.fromRGB(80, 80, 80),
		},
	},
	FishingRod2 = {
		Size = Vector3.new(1, 13, 1),
		Attributes = {
			ColorHandleBase = Color3.fromRGB(80, 50, 30),
			ColorHandle = Color3.fromRGB(130, 85, 50),
			ColorShaft = Color3.fromRGB(160, 100, 60),
			ColorReelBlue = Color3.fromRGB(90, 130, 180),
			ColorReelGrey = Color3.fromRGB(210, 210, 210),
			ColorGuide = Color3.fromRGB(170, 170, 170),
			ColorLine = Color3.fromRGB(245, 245, 245),
			ColorLure = Color3.fromRGB(80, 200, 100),
			ColorHook = Color3.fromRGB(140, 140, 140),
			ColorCrank = Color3.fromRGB(100, 100, 100),
		},
	},
	FishingRod3 = {
		Size = Vector3.new(1, 16, 1),
		Attributes = {
			ColorHandleBase = Color3.fromRGB(100, 60, 35),
			ColorHandle = Color3.fromRGB(160, 110, 65),
			ColorShaft = Color3.fromRGB(200, 130, 80),
			ColorReelBlue = Color3.fromRGB(110, 150, 200),
			ColorReelGrey = Color3.fromRGB(220, 220, 220),
			ColorGuide = Color3.fromRGB(190, 190, 190),
			ColorLine = Color3.fromRGB(250, 250, 250),
			ColorLure = Color3.fromRGB(100, 220, 120),
			ColorHook = Color3.fromRGB(160, 160, 160),
			ColorCrank = Color3.fromRGB(120, 120, 120),
		},
	},
	FishingRod4 = {
		Size = Vector3.new(1, 19, 1),
		Attributes = {
			ColorHandleBase = Color3.fromRGB(40, 40, 50),
			ColorHandle = Color3.fromRGB(70, 70, 90),
			ColorShaft = Color3.fromRGB(90, 90, 120),
			ColorReelBlue = Color3.fromRGB(50, 80, 180),
			ColorReelGrey = Color3.fromRGB(230, 230, 230),
			ColorGuide = Color3.fromRGB(200, 200, 200),
			ColorLine = Color3.fromRGB(255, 255, 255),
			ColorLure = Color3.fromRGB(255, 215, 0),
			ColorHook = Color3.fromRGB(180, 180, 180),
			ColorCrank = Color3.fromRGB(140, 140, 140),
		},
	},
	FishingRod5 = {
		Size = Vector3.new(1, 22, 1),
		Attributes = {
			ColorHandleBase = Color3.fromRGB(120, 20, 20),
			ColorHandle = Color3.fromRGB(180, 40, 40),
			ColorShaft = Color3.fromRGB(220, 60, 60),
			ColorReelBlue = Color3.fromRGB(255, 215, 0),
			ColorReelGrey = Color3.fromRGB(240, 240, 240),
			ColorGuide = Color3.fromRGB(255, 215, 0),
			ColorLine = Color3.fromRGB(255, 255, 255),
			ColorLure = Color3.fromRGB(255, 100, 100),
			ColorHook = Color3.fromRGB(255, 215, 0),
			ColorCrank = Color3.fromRGB(200, 200, 200),
		},
	},
}

-- ========================================
-- 釣り竿
-- ========================================
function EquipmentSystem.getFishingRod(player)
	local character = player.Character
	if not character then return nil end
	local rightHand = character:FindFirstChild("RightHand")
	if not rightHand then return nil end

	local fishingRod = rightHand:FindFirstChild(FISHING_ROD_FOLDER)
	return fishingRod
end

-- ========================================
-- 釣り竿 名前取得
-- ========================================
function EquipmentSystem.getFishingRodName(player)
	local fishingRod = EquipmentSystem.getFishingRod(player)
	if not fishingRod then return nil end
	return fishingRod:GetAttribute("RodName")
end

-- 釣り竿ランクを取得（FishingRod1=1, FishingRod2=2, ...）
function EquipmentSystem.getRodRank(player)
	local rodName = EquipmentSystem.getFishingRodName(player)
	if not rodName then return 1 end
	local rank = tonumber(string.match(rodName, "%d+"))
	return rank or 1
end

-- 釣り竿レベル一覧を取得
function EquipmentSystem.getRodLevelNames()
	local names = {}
	for name, _ in pairs(ROD_LEVELS) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- 釣り竿をプロシージャル生成して装備する
-- player: Player
-- rodName: string -- "FishingRod1", "FishingRod2" など
function EquipmentSystem.equipFishingRod(player, rodName)
	local character = player.Character
	if not character then return nil end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local rightHand = character:FindFirstChild("RightHand")
	if not humanoidRootPart or not rightHand then return nil end

	-- 既に装備している場合は外してから装備し直す
	local existingRod = character:FindFirstChild(FISHING_ROD_FOLDER)
	if existingRod then
		existingRod:Destroy()
	end

	-- レベル別パラメータを取得（未定義ならFishingRod1を使用）
	local levelConfig = ROD_LEVELS[rodName] or ROD_LEVELS["FishingRod1"]

	-- ReplicatedStorage/FishingRod/[rodName]/ProceduralGeneration を取得
	local rodFolder = ReplicatedStorage:FindFirstChild(FISHING_ROD_FOLDER)
	if not rodFolder then
		warn("[EquipmentSystem] 釣り竿フォルダが見つかりません:", FISHING_ROD_FOLDER)
		return nil
	end

	local rodModuleFolder = rodFolder:FindFirstChild(rodName)
	if not rodModuleFolder then
		warn("[EquipmentSystem] 釣り竿モジュールフォルダが見つかりません:", rodName)
		return nil
	end

	local procGen = rodModuleFolder:FindFirstChild("ProceduralGeneration")
	if not procGen then
		warn("[EquipmentSystem] ProceduralGenerationが見つかりません:", rodName)
		return nil
	end

	local generateModule = require(procGen)

	-- 生成先コンテナ（Model）を作成
	local rod = Instance.new("Model")
	rod.Name = FISHING_ROD_FOLDER
	rod:SetAttribute("RodName", rodName)

	-- プロシージャル生成を実行
	generateModule.OnGenerate({
		Size = levelConfig.Size,
		Attributes = levelConfig.Attributes,
	}, rod)

	-- PrimaryPartがなければ最初のBasePartを設定
	if not rod.PrimaryPart then
		for _, desc in rod:GetDescendants() do
			if desc:IsA("BasePart") then
				rod.PrimaryPart = desc
				break
			end
		end
	end

	-- 全パーツをWeldで接続（ばらけ防止）
	CommonFunctions.autoWeldModel(rod)

	-- 右手に45度前方に傾けて配置
	local tiltCFrame = CFrame.Angles(math.rad(-45), 0, 0)
	rod:PivotTo(rightHand.CFrame * tiltCFrame)
	rod.Parent = rightHand

	-- Weldで接続
	if rod.PrimaryPart then
		local weld = Instance.new("WeldConstraint")
		weld.Name = FISHING_ROD_WELD
		weld.Part0 = rightHand
		weld.Part1 = rod.PrimaryPart
		weld.Parent = rod.PrimaryPart

		-- 物理を無効化
		rod.PrimaryPart.Anchored = false
		for _, part in rod:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
			end
		end
	end

	return rod
end

-- 釣り竿を外す
function EquipmentSystem.unequipFishingRod(player)
	local character = player.Character
	if not character then return false end

	-- character直下またはRightHand内を検索
	local rod = character:FindFirstChild(FISHING_ROD_FOLDER)
	if not rod then
		local rightHand = character:FindFirstChild("RightHand")
		if rightHand then
			rod = rightHand:FindFirstChild(FISHING_ROD_FOLDER)
		end
	end
	if not rod then return false end

	-- Weldを削除
	if rod.PrimaryPart then
		local weld = rod.PrimaryPart:FindFirstChild(FISHING_ROD_WELD)
		if weld then weld:Destroy() end
	end

	rod:Destroy()
	return true
end

-- 釣り竿を装備しているか
function EquipmentSystem.isEquippedFishingRod(player)
	local character = player.Character
	if not character then return false end
	return EquipmentSystem.getFishingRod(player) ~= nil
end

-- ========================================
-- 汎用装備関数
-- ========================================

-- 任意のオブジェクトをReplicatedStorageから取得して装備
-- objectName: ReplicatedStorage内のオブジェクト名
-- player: Player
-- options: { offsetCFrame = CFrame?, attachTo = string? }
--   offsetCFrame: 装備位置のオフセット
--   attachTo: 装備先パーツ名（省略時はHumanoidRootPart）
function EquipmentSystem.equipObject(objectName, player, options)
	local character = player.Character
	if not character then return nil end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil end

	-- 既に装備している場合は何もしない
	if character:FindFirstChild(objectName) then
		return character:FindFirstChild(objectName)
	end

	-- ReplicatedStorageからテンプレートを取得
	local template = ReplicatedStorage:FindFirstChild(objectName)
	if not template then
		warn("[EquipmentSystem] オブジェクトが見つかりません:", objectName)
		return nil
	end

	local opts = options or {}
	local offsetCFrame = opts.offsetCFrame or CFrame.new()
	local attachPartName = opts.attachTo
	local attachPart = if attachPartName
		then character:FindFirstChild(attachPartName) or humanoidRootPart
		else humanoidRootPart

	-- クローンして装備
	local obj = template:Clone()
	obj.Name = objectName

	local targetCFrame = attachPart.CFrame * offsetCFrame
	obj:PivotTo(targetCFrame)
	obj.Parent = character

	-- Weldで接続
	if obj.PrimaryPart then
		local weld = Instance.new("WeldConstraint")
		weld.Name = objectName .. "Weld"
		weld.Part0 = attachPart
		weld.Part1 = obj.PrimaryPart
		weld.Parent = obj.PrimaryPart

		-- 物理を無効化
		obj.PrimaryPart.Anchored = false
		for _, part in obj:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
			end
		end
	end

	return obj
end

-- 任意の装備オブジェクトを外す
function EquipmentSystem.unequipObject(objectName, player)
	local character = player.Character
	if not character then return false end

	local obj = character:FindFirstChild(objectName)
	if not obj then return false end

	-- Weldを削除
	if obj.PrimaryPart then
		local weld = obj.PrimaryPart:FindFirstChild(objectName .. "Weld")
		if weld then weld:Destroy() end
	end

	obj:Destroy()
	return true
end

-- 任意のオブジェクトが装備されているか
function EquipmentSystem.isEquipped(objectName, player)
	local character = player.Character
	if not character then return false end
	return character:FindFirstChild(objectName) ~= nil
end

return EquipmentSystem
