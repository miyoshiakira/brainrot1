local TweenService = game:GetService("TweenService")

local FishingSplashEffect = {}

-- ========================================
-- 釣り上げ 水しぶきエフェクト
-- ========================================

-- 水しぶきの色設定
local COLORS = {
	Water     = Color3.fromRGB(100, 180, 255),
	WaterDark = Color3.fromRGB(60, 130, 220),
	White     = Color3.fromRGB(220, 240, 255),
	Foam      = Color3.fromRGB(200, 230, 255),
	Sparkle   = Color3.fromRGB(180, 230, 255),
}

-- 単一の水滴を飛ばす
local function spawnDroplet(origin, direction, speed, size, color, duration)
	local part = Instance.new("Part")
	part.Name = "Droplet"
	part.Size = size
	part.CFrame = CFrame.new(origin)
	part.Color = color
	part.Material = Enum.Material.Glass
	part.Transparency = 0.2
	part.Reflectance = 0.5
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Shape = Enum.PartType.Ball
	part.Parent = workspace.Terrain

	-- 放物線運動
	local velocity = direction * speed
	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	local startTime = os.clock()

	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not part.Parent then
			if connection then connection:Disconnect() end
			return
		end
		local t = os.clock() - startTime
		if t > duration then
			connection:Disconnect()
			-- フェードアウト
			local fadeTween = TweenService:Create(part,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1, Size = size * 0.3}
			)
			fadeTween.Completed:Connect(function()
				if part.Parent then part:Destroy() end
			end)
			fadeTween:Play()
			return
		end
		local pos = origin + velocity * t + 0.5 * gravity * t * t
		part.CFrame = CFrame.new(pos)
	end)

	return part
end

-- 水柱（メインの上昇水流）
local function spawnWaterColumn(origin, duration)
	local column = Instance.new("Part")
	column.Name = "WaterColumn"
	column.Size = Vector3.new(1, 1, 1)
	column.CFrame = CFrame.new(origin)
	column.Color = COLORS.Water
	column.Material = Enum.Material.Glass
	column.Transparency = 0.3
	column.Reflectance = 0.4
	column.Anchored = true
	column.CanCollide = false
	column.CastShadow = false
	column.Parent = workspace.Terrain

	-- 上昇
	local riseHeight = 18
	local riseDuration = duration * 0.3
	local riseTween = TweenService:Create(column,
		TweenInfo.new(riseDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = Vector3.new(2.5, riseHeight, 2.5), CFrame = CFrame.new(origin + Vector3.new(0, riseHeight / 2, 0)), Transparency = 0.5}
	)

	-- 拡散＋フェード
	local fadeTween = TweenService:Create(column,
		TweenInfo.new(duration * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Size = Vector3.new(5, riseHeight * 1.3, 5), Transparency = 1}
	)

	riseTween.Completed:Connect(function()
		if column.Parent then fadeTween:Play() end
	end)

	fadeTween.Completed:Connect(function()
		if column.Parent then column:Destroy() end
	end)

	riseTween:Play()
	return column
end

-- 波紋リング
local function spawnRingWave(origin, delay, color, maxRadius)
	local ring = Instance.new("Part")
	ring.Name = "RingWave"
	ring.Size = Vector3.new(0.5, 0.2, 0.5)
	ring.CFrame = CFrame.new(origin)
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.2
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Parent = workspace.Terrain

	-- Y軸を水平にするため90度回転
	ring.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))

	local radius = maxRadius or 12
	local expandTween = TweenService:Create(ring,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 0.8}
	)
	local fadeTween = TweenService:Create(ring,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Size = Vector3.new(0.1, radius * 2.5, radius * 2.5), Transparency = 1}
	)

	expandTween.Completed:Connect(function()
		if ring.Parent then fadeTween:Play() end
	end)
	fadeTween.Completed:Connect(function()
		if ring.Parent then ring:Destroy() end
	end)

	task.delay(delay, function()
		if ring.Parent then expandTween:Play() end
	end)

	return ring
end

-- 泡パーティクル
local function spawnFoamParticles(origin, duration)
	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain

	-- 一時的なPartをアタッチメントホルダーとして使用
	local holder = Instance.new("Part")
	holder.Name = "FoamHolder"
	holder.Size = Vector3.new(0.1, 0.1, 0.1)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CastShadow = false
	holder.CFrame = CFrame.new(origin)
	holder.Parent = workspace.Terrain
	attachment.Parent = holder

	-- 泡パーティクル
	local foam = Instance.new("ParticleEmitter")
	foam.Name = "Foam"
	foam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.Foam),
		ColorSequenceKeypoint.new(0.5, COLORS.White),
		ColorSequenceKeypoint.new(1, COLORS.Water),
	})
	foam.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	foam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	foam.Lifetime = NumberRange.new(0.5, 1.2)
	foam.Rate = 80
	foam.Speed = NumberRange.new(8, 15)
	foam.SpreadAngle = Vector2.new(40, 40)
	foam.EmissionDirection = Enum.NormalId.Top
	foam.LightEmission = 0.5
	foam.LightInfluence = 0.3
	foam.RotSpeed = NumberRange.new(-180, 180)
	foam.Parent = attachment

	-- スプレーパーティクル（横に飛び散る）
	local spray = Instance.new("ParticleEmitter")
	spray.Name = "Spray"
	spray.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.White),
		ColorSequenceKeypoint.new(1, COLORS.Water),
	})
	spray.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.4, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	spray.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	spray.Lifetime = NumberRange.new(0.4, 0.8)
	spray.Rate = 50
	spray.Speed = NumberRange.new(12, 20)
	spray.SpreadAngle = Vector2.new(60, 60)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.LightEmission = 0.6
	spray.LightInfluence = 0.2
	spray.Parent = attachment

	-- キラキラパーティクル
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "Sparkle"
	sparkle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.Sparkle),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, COLORS.Sparkle),
	})
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkle.Lifetime = NumberRange.new(0.6, 1.5)
	sparkle.Rate = 30
	sparkle.Speed = NumberRange.new(5, 12)
	sparkle.SpreadAngle = Vector2.new(30, 30)
	sparkle.EmissionDirection = Enum.NormalId.Top
	sparkle.LightEmission = 1
	sparkle.LightInfluence = 0
	sparkle.RotSpeed = NumberRange.new(-360, 360)
	sparkle.Parent = attachment

	-- 指定時間後に削除
	task.delay(duration, function()
		foam.Rate = 0
		spray.Rate = 0
		sparkle.Rate = 0
		task.wait(1.5)
		if holder.Parent then holder:Destroy() end
	end)

	return holder
end

-- ========================================
-- メイン：釣り上げ水しぶきエフェクト
-- ========================================

function FishingSplashEffect.Play(cframe, options)
	local opts = options or {}
	local duration = opts.duration or 2.0
	local scale = opts.scale or 1.0

	local origin = cframe.Position

	-- 1. 水柱（中央から上に噴き上がる）
	spawnWaterColumn(origin + Vector3.new(0, 1, 0), duration)

	-- 2. 大量の水滴を放射状に飛ばす
	local dropletCount = 24
	for i = 1, dropletCount do
		local angle = (i / dropletCount) * math.pi * 2
		local direction = Vector3.new(math.cos(angle), 1.2 + math.random() * 0.5, math.sin(angle)).Unit
		local speed = 12 + math.random() * 8
		local size = Vector3.new(0.3, 0.3, 0.3) + Vector3.new(1, 1, 1) * math.random() * 0.4
		local color = math.random() > 0.5 and COLORS.Water or COLORS.White
		local dropletDuration = 0.6 + math.random() * 0.5
		task.wait(math.random() * 0.1)
		spawnDroplet(origin + Vector3.new(0, 2, 0), direction, speed, size * scale, color, dropletDuration)
	end

	-- 3. 大きな水塊（上に飛んで落ちる）
	for i = 1, 5 do
		local angle = math.random() * math.pi * 2
		local direction = Vector3.new(math.cos(angle) * 0.5, 1.5 + math.random() * 0.5, math.sin(angle) * 0.5).Unit
		local speed = 10 + math.random() * 5
		local size = Vector3.new(1.5, 1.5, 1.5) * scale
		task.wait(0.05 * i)
		spawnDroplet(origin + Vector3.new(0, 2, 0), direction, speed, size, COLORS.WaterDark, 1.0 + math.random() * 0.3)
	end

	-- 4. 波紋リング（複数段）
	spawnRingWave(origin, 0.0, COLORS.Water, 10 * scale)
	spawnRingWave(origin, 0.2, COLORS.Foam, 14 * scale)
	spawnRingWave(origin, 0.4, COLORS.White, 18 * scale)

	-- 5. 泡・スプレー・キラキラパーティクル
	spawnFoamParticles(origin + Vector3.new(0, 1, 0), duration * 0.6)

	-- 6. 一時的なPointLightで水面を照らす
	local light = Instance.new("PointLight")
	light.Name = "SplashLight"
	light.Color = COLORS.White
	light.Brightness = 5
	light.Range = 20 * scale
	light.Shadows = false
	light.Parent = workspace.Terrain

	local lightHolder = Instance.new("Part")
	lightHolder.Name = "LightHolder"
	lightHolder.Size = Vector3.new(0.1, 0.1, 0.1)
	lightHolder.Transparency = 1
	lightHolder.Anchored = true
	lightHolder.CanCollide = false
	lightHolder.CFrame = CFrame.new(origin + Vector3.new(0, 5, 0))
	lightHolder.Parent = workspace.Terrain
	light.Parent = lightHolder

	local lightFade = TweenService:Create(light,
		TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Brightness = 0, Range = 0}
	)
	lightFade.Completed:Connect(function()
		if lightHolder.Parent then lightHolder:Destroy() end
	end)
	task.delay(0.3, function()
		if lightHolder.Parent then lightFade:Play() end
	end)
end

return FishingSplashEffect
