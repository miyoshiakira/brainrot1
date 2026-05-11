local TweenService = game:GetService("TweenService")
local MoneyEffect = {}

local COLORS = {
	Gold     = Color3.fromRGB(255, 215, 0),
	GoldDark = Color3.fromRGB(218, 165, 32),
	Yellow   = Color3.fromRGB(255, 255, 100),
	White    = Color3.fromRGB(255, 255, 220),
}

local function spawnCoin(origin, direction, speed, size, color, duration)
	local part = Instance.new("Part")
	part.Name = "Coin"
	part.Size = size
	part.CFrame = CFrame.new(origin)
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = 0.1
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Shape = Enum.PartType.Ball
	part.Parent = workspace.Terrain

	local velocity = direction * speed
	local gravity = Vector3.new(0, workspace.Gravity, 0)
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
			local fadeTween = TweenService:Create(part,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1, Size = size * 0.2}
			)
			fadeTween.Completed:Connect(function()
				if part.Parent then part:Destroy() end
			end)
			fadeTween:Play()
			return
		end
		part.CFrame = CFrame.new(origin + velocity * t + 0.5 * gravity * t * t)
	end)
end

local function spawnGoldRing(origin, delay, color, maxRadius)
	local ring = Instance.new("Part")
	ring.Name = "GoldRing"
	ring.Size = Vector3.new(0.5, 0.2, 0.5)
	ring.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.1
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Parent = workspace.Terrain

	local radius = maxRadius or 10
	local expandTween = TweenService:Create(ring,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 0.7}
	)
	local fadeTween = TweenService:Create(ring,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
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
end

local function spawnMoneyParticles(origin, duration)
	local holder = Instance.new("Part")
	holder.Name = "MoneyParticleHolder"
	holder.Size = Vector3.new(0.1, 0.1, 0.1)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CastShadow = false
	holder.CFrame = CFrame.new(origin)
	holder.Parent = workspace.Terrain

	local attachment = Instance.new("Attachment")
	attachment.Parent = holder

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.Gold),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, COLORS.GoldDark),
	})
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 1.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkle.Lifetime = NumberRange.new(0.8, 1.5)
	sparkle.Rate = 60
	sparkle.Speed = NumberRange.new(6, 14)
	sparkle.SpreadAngle = Vector2.new(45, 45)
	sparkle.EmissionDirection = Enum.NormalId.Top
	sparkle.LightEmission = 1
	sparkle.LightInfluence = 0
	sparkle.RotSpeed = NumberRange.new(-360, 360)
	sparkle.Parent = attachment

	local coins = Instance.new("ParticleEmitter")
	coins.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.Gold),
		ColorSequenceKeypoint.new(0.5, COLORS.Yellow),
		ColorSequenceKeypoint.new(1, COLORS.GoldDark),
	})
	coins.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 2.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	coins.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	coins.Lifetime = NumberRange.new(0.6, 1.2)
	coins.Rate = 40
	coins.Speed = NumberRange.new(4, 8)
	coins.SpreadAngle = Vector2.new(50, 50)
	coins.EmissionDirection = Enum.NormalId.Top
	coins.LightEmission = 0.8
	coins.LightInfluence = 0.2
	coins.RotSpeed = NumberRange.new(-180, 180)
	coins.Parent = attachment

	task.delay(duration, function()
		sparkle.Rate = 0
		coins.Rate = 0
		task.wait(1.5)
		if holder.Parent then holder:Destroy() end
	end)
end

function MoneyEffect.Play(cframe, options)
	local opts = options or {}
	local duration = opts.duration or 1.8
	local scale = opts.scale or 1.0
	local origin = cframe.Position

	-- 1. コイン放射
	for i = 1, 20 do
		local angle = (i / 20) * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0.8 + math.random() * 0.4, math.sin(angle)).Unit
		local speed = 6 + math.random() * 5
		local size = Vector3.new(0.4, 0.4, 0.4) + Vector3.new(1,1,1) * math.random() * 0.3
		local color = math.random() > 0.3 and COLORS.Gold or COLORS.Yellow
		spawnCoin(origin + Vector3.new(0, 2, 0), dir, speed, size * scale, color, 0.7 + math.random() * 0.4)
	end

	-- 2. ゴールドリング
	spawnGoldRing(origin, 0.0, COLORS.Gold, 10 * scale)
	spawnGoldRing(origin, 0.1, COLORS.Yellow, 14 * scale)
	spawnGoldRing(origin, 0.2, COLORS.White, 18 * scale)

	-- 3. パーティクル
	spawnMoneyParticles(origin + Vector3.new(0, 1, 0), duration * 0.6)

	-- 4. PointLight
	local lightHolder = Instance.new("Part")
	lightHolder.Size = Vector3.new(0.1, 0.1, 0.1)
	lightHolder.Transparency = 1
	lightHolder.Anchored = true
	lightHolder.CanCollide = false
	lightHolder.CFrame = CFrame.new(origin + Vector3.new(0, 5, 0))
	lightHolder.Parent = workspace.Terrain
	local light = Instance.new("PointLight")
	light.Color = COLORS.Gold
	light.Brightness = 5
	light.Range = 20 * scale
	light.Shadows = false
	light.Parent = lightHolder

	local lightFade = TweenService:Create(light,
		TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Brightness = 0, Range = 0}
	)
	lightFade.Completed:Connect(function()
		if lightHolder.Parent then lightHolder:Destroy() end
	end)
	task.delay(0.15, function()
		if lightHolder.Parent then lightFade:Play() end
	end)
end

return MoneyEffect
