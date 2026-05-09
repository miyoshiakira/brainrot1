local function Initialize()
    local TweenService = game:GetService("TweenService")
    local CollectionService = game:GetService("CollectionService")

    local whaleShark = workspace:WaitForChild("VoxelWhaleShark"):WaitForChild("Generated"):WaitForChild("VoxelWhaleShark")
    local mouth = whaleShark:WaitForChild("Mouth")
    local body = whaleShark:FindFirstChild("Body").PrimaryPart

    -- Create or find Hitbox
    local hitbox = mouth:FindFirstChild("MouthHitbox")
    if not hitbox then
        local cframe, size = mouth:GetBoundingBox()
        hitbox = Instance.new("Part")
        hitbox.Name = "MouthHitbox"
        hitbox.Size = size + Vector3.new(2, 2, 2)
        hitbox.CFrame = cframe
        hitbox.Transparency = 1
        hitbox.CanCollide = false
        hitbox.Anchored = true
        hitbox.Parent = mouth
    end

    -- Store original positions for mouth parts
    local mouthRoof = mouth:FindFirstChild("MouthRoof")
    local mouthFloor = mouth:FindFirstChild("MouthFloor")
    local rightMouthSide = mouth:FindFirstChild("RightMouthSide")
    local leftMouthSide = mouth:FindFirstChild("LeftMouthSide")

    local originalRoofPos = mouthRoof and mouthRoof.Position or nil
    local originalFloorPos = mouthFloor and mouthFloor.Position or nil
    local originalRightSidePos = rightMouthSide and rightMouthSide.Position or nil
    local originalLeftSidePos = leftMouthSide and leftMouthSide.Position or nil

    local eatenMonsters = {}
    local isEating = false

    -- Whale Shark eating animation
    local function playWhaleSharkEatAnimation()
        if isEating then return end
        isEating = true

        -- Close mouth animation (0.3 seconds)
        local mouthCloseDuration = 0.3
        local mouthOpenDuration = 0.4

        -- Calculate target positions for closed mouth
        local roofTargetY = originalRoofPos and (originalRoofPos.Y - 0.5) or 0
        local floorTargetY = originalFloorPos and (originalFloorPos.Y + 0.5) or 0
        local rightSideTargetZ = originalRightSidePos and (originalRightSidePos.Z + 1) or 0
        local leftSideTargetZ = originalLeftSidePos and (originalLeftSidePos.Z - 1) or 0

        -- Close mouth
        if mouthRoof then
            TweenService:Create(mouthRoof, TweenInfo.new(mouthCloseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = Vector3.new(mouthRoof.Position.X, roofTargetY, mouthRoof.Position.Z)}):Play()
        end
        if mouthFloor then
            TweenService:Create(mouthFloor, TweenInfo.new(mouthCloseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = Vector3.new(mouthFloor.Position.X, floorTargetY, mouthFloor.Position.Z)}):Play()
        end
        if rightMouthSide then
            TweenService:Create(rightMouthSide, TweenInfo.new(mouthCloseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = Vector3.new(rightMouthSide.Position.X, rightMouthSide.Position.Y, rightSideTargetZ)}):Play()
        end
        if leftMouthSide then
            TweenService:Create(leftMouthSide, TweenInfo.new(mouthCloseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = Vector3.new(leftMouthSide.Position.X, leftMouthSide.Position.Y, leftSideTargetZ)}):Play()
        end

        -- Body shake animation (swallow effect)
        if body then
            local originalBodyCFrame = body:GetPivot()
            local shakeInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

            -- Shake sequence
            local shake1 = TweenService:Create(body, shakeInfo, {CFrame = originalBodyCFrame * CFrame.new(0, 0, 0.5)})
            local shake2 = TweenService:Create(body, shakeInfo, {CFrame = originalBodyCFrame * CFrame.new(0, 0, -0.5)})
            local shake3 = TweenService:Create(body, shakeInfo, {CFrame = originalBodyCFrame * CFrame.new(0, 0, 0.3)})
            local shake4 = TweenService:Create(body, shakeInfo, {CFrame = originalBodyCFrame * CFrame.new(0, 0, -0.3)})
            local reset = TweenService:Create(body, TweenInfo.new(0.1), {CFrame = originalBodyCFrame})

            task.delay(mouthCloseDuration, function()
                shake1:Play()
                task.wait(0.15)
                shake2:Play()
                task.wait(0.15)
                shake3:Play()
                task.wait(0.15)
                shake4:Play()
                task.wait(0.15)
                reset:Play()
            end)
        end

        -- Open mouth back up (after eating)
        task.delay(mouthCloseDuration + 0.5, function()
            if mouthRoof and originalRoofPos then
                TweenService:Create(mouthRoof, TweenInfo.new(mouthOpenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = originalRoofPos}):Play()
            end
            if mouthFloor and originalFloorPos then
                TweenService:Create(mouthFloor, TweenInfo.new(mouthOpenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = originalFloorPos}):Play()
            end
            if rightMouthSide and originalRightSidePos then
                TweenService:Create(rightMouthSide, TweenInfo.new(mouthOpenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = originalRightSidePos}):Play()
            end
            if leftMouthSide and originalLeftSidePos then
                TweenService:Create(leftMouthSide, TweenInfo.new(mouthOpenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = originalLeftSidePos}):Play()
            end

            task.wait(mouthOpenDuration)
            isEating = false
        end)
    end

    hitbox.Touched:Connect(function(hit)
        local monsterModel = hit:FindFirstAncestorWhichIsA("Model")
        if not monsterModel then return end

        -- プレイヤーが所持中のキャラクターは食べない
        local parentModel = monsterModel.Parent
        if parentModel and parentModel:IsA("Model") and parentModel:FindFirstChild("Humanoid") then
            return
        end

        print("EAT try")
        if CollectionService:HasTag(monsterModel, "Monster") and not eatenMonsters[monsterModel] then
            eatenMonsters[monsterModel] = true

            -- Play whale shark eating animation
            playWhaleSharkEatAnimation()

            -- Stop monster movement
            if monsterModel.PrimaryPart then
                monsterModel.PrimaryPart.Anchored = true
            end
            for _, part in monsterModel:GetDescendants() do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Anchored = true
                end
            end

            -- Animation: Suck into mouth and shrink
            local startCFrame = monsterModel:GetPivot()
            local targetCFrame = hitbox.CFrame

            local tweenValue = Instance.new("NumberValue")
            tweenValue.Value = 0

            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
            local tween = TweenService:Create(tweenValue, tweenInfo, {Value = 1})

            local initialScale = monsterModel:GetScale()

            tweenValue.Changed:Connect(function(alpha)
                if not monsterModel.Parent then return end
                -- Interpolate CFrame
                local currentCFrame = startCFrame:Lerp(targetCFrame, alpha)
                -- Interpolate Scale (from initialScale to 0.01)
                local currentScale = math.max(0.01, initialScale * (1 - alpha))

                monsterModel:PivotTo(currentCFrame)
                monsterModel:ScaleTo(currentScale)
            end)

            tween.Completed:Connect(function()
                if monsterModel.Parent then
                    monsterModel:Destroy()
                end
                tweenValue:Destroy()
                eatenMonsters[monsterModel] = nil
            end)
            print("EAT Start")
            tween:Play()
        end
    end)
end

return {
    Initialize = Initialize
}


