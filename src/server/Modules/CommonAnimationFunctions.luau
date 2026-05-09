--[[
    CommonAnimationFunctions
    TweenServiceを使ったモデルアニメーションの共通処理
    BaseModelのPrimaryPartを操作して動きを表現する
]]

local TweenService = game:GetService("TweenService")

local CommonAnimationFunctions = {}

-- ========================================
-- 基本Tween操作
-- ========================================

-- PrimaryPartのCFrameをTweenで移動
function CommonAnimationFunctions.tweenCFrame(baseModel, tweenInfo, targetCFrame)
    if not baseModel or not baseModel.PrimaryPart then return nil end
    local tween = TweenService:Create(baseModel.PrimaryPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- PrimaryPartのPositionをTweenで移動
function CommonAnimationFunctions.tweenPosition(baseModel, tweenInfo, targetPosition)
    if not baseModel or not baseModel.PrimaryPart then return nil end
    local tween = TweenService:Create(baseModel.PrimaryPart, tweenInfo, {Position = targetPosition})
    tween:Play()
    return tween
end

-- モデル全体をPivotToでLerp移動（CFrame補間）
-- NumberValueを用いてalpha=0→1をTweenし、ChangedでPivotToする
function CommonAnimationFunctions.tweenPivotTo(baseModel, tweenInfo, targetCFrame)
    if not baseModel then return nil end

    local startCFrame = baseModel:GetPivot()
    local tweenValue = Instance.new("NumberValue")
    tweenValue.Value = 0

    local tween = TweenService:Create(tweenValue, tweenInfo, {Value = 1})

    tweenValue.Changed:Connect(function(alpha)
        if not baseModel.Parent then return end
        baseModel:PivotTo(startCFrame:Lerp(targetCFrame, alpha))
    end)

    tween.Completed:Connect(function()
        tweenValue:Destroy()
    end)

    tween:Play()
    return tween
end

-- ========================================
-- スケールアニメーション
-- ========================================

-- モデルをスケールしながら移動（吸い込まれる演出等）
function CommonAnimationFunctions.tweenScaleAndMove(baseModel, tweenInfo, targetCFrame, targetScale)
    if not baseModel then return nil end

    local startCFrame = baseModel:GetPivot()
    local initialScale = baseModel:GetScale()
    local tweenValue = Instance.new("NumberValue")
    tweenValue.Value = 0

    local tween = TweenService:Create(tweenValue, tweenInfo, {Value = 1})

    tweenValue.Changed:Connect(function(alpha)
        if not baseModel.Parent then return end
        local currentCFrame = startCFrame:Lerp(targetCFrame, alpha)
        local currentScale = math.max(targetScale, initialScale + (targetScale - initialScale) * alpha)
        baseModel:PivotTo(currentCFrame)
        baseModel:ScaleTo(currentScale)
    end)

    tween.Completed:Connect(function()
        tweenValue:Destroy()
    end)

    tween:Play()
    return tween
end

-- ========================================
-- 揺れ・振動アニメーション
-- ========================================

-- モデルを揺らす（振動演出）
-- offsets: CFrameオフセットの配列 (例: {CFrame.new(0,0,0.5), CFrame.new(0,0,-0.5), ...})
-- shakeInfo: 各揺れのTweenInfo
function CommonAnimationFunctions.shakeModel(baseModel, offsets, shakeInfo, onComplete)
    if not baseModel or not baseModel.PrimaryPart then return end

    local originalCFrame = baseModel:GetPivot()
    local tweens = {}

    for i, offset in ipairs(offsets) do
        local targetCFrame = originalCFrame * offset
        tweens[i] = TweenService:Create(baseModel.PrimaryPart, shakeInfo, {CFrame = targetCFrame})
    end

    -- 最後に元の位置に戻す
    local resetInfo = TweenInfo.new(shakeInfo.Time * 0.5, shakeInfo.EasingStyle, shakeInfo.EasingDirection)
    local resetTween = TweenService:Create(baseModel.PrimaryPart, resetInfo, {CFrame = originalCFrame})

    -- 順番に再生
    task.spawn(function()
        for _, tween in ipairs(tweens) do
            if not baseModel.Parent then return end
            tween:Play()
            tween.Completed:Wait()
        end
        if baseModel.Parent then
            resetTween:Play()
            resetTween.Completed:Wait()
        end
        if onComplete then
            onComplete()
        end
    end)
end

-- 簡易シェイク（指定回数・振幅で揺らす）
function CommonAnimationFunctions.simpleShake(baseModel, count, amplitude, duration, onComplete)
    if not baseModel or not baseModel.PrimaryPart then return end

    local offsets = {}
    local stepDuration = duration / (count * 2)

    for i = 1, count do
        local sign = (i % 2 == 0) and 1 or -1
        table.insert(offsets, CFrame.new(sign * amplitude, 0, 0))
        table.insert(offsets, CFrame.new(-sign * amplitude * 0.6, 0, 0))
    end

    local shakeInfo = TweenInfo.new(stepDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    CommonAnimationFunctions.shakeModel(baseModel, offsets, shakeInfo, onComplete)
end

-- ========================================
-- 上下揺れ（浮遊）アニメーション
-- ========================================

-- モデルを上下に揺らす（浮遊演出）
function CommonAnimationFunctions.bobModel(baseModel, height, duration, easingStyle)
    if not baseModel or not baseModel.PrimaryPart then return nil end

    local originalPosition = baseModel.PrimaryPart.Position
    local upPosition = originalPosition + Vector3.new(0, height, 0)
    local downPosition = originalPosition + Vector3.new(0, -height, 0)
    local style = easingStyle or Enum.EasingStyle.Sine

    local tweenUp = TweenService:Create(
        baseModel.PrimaryPart,
        TweenInfo.new(duration, style, Enum.EasingDirection.Out),
        {Position = upPosition}
    )
    local tweenDown = TweenService:Create(
        baseModel.PrimaryPart,
        TweenInfo.new(duration, style, Enum.EasingDirection.In),
        {Position = downPosition}
    )

    -- ループ再生
    tweenUp.Completed:Connect(function()
        if baseModel.Parent then
            tweenDown:Play()
        end
    end)
    tweenDown.Completed:Connect(function()
        if baseModel.Parent then
            tweenUp:Play()
        end
    end)

    tweenUp:Play()
    return tweenUp, tweenDown
end

-- ========================================
-- 回転アニメーション
-- ========================================

-- モデルをY軸中心に回転させる（ループ）
-- RunServiceのHeartbeatを使うため、返り値は接続
function CommonAnimationFunctions.spinModel(baseModel, rotationSpeed)
    if not baseModel or not baseModel.PrimaryPart then return nil end

    local RunService = game:GetService("RunService")
    local startTime = os.clock()

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not baseModel.Parent then
            connection:Disconnect()
            return
        end
        local elapsed = os.clock() - startTime
        local angle = elapsed * rotationSpeed
        local originalPosition = baseModel.PrimaryPart.Position
        baseModel.PrimaryPart.CFrame = CFrame.new(originalPosition) * CFrame.Angles(0, angle, 0)
    end)

    return connection
end

-- ========================================
-- レベルアップ演出（回転しながら上昇→下降して元の位置へ）
-- ========================================

function CommonAnimationFunctions.levelUpAnimation(baseModel, riseHeight, duration, finalCFrame)
    if not baseModel or not baseModel.PrimaryPart then return nil end

    local RunService = game:GetService("RunService")
    local primaryPart = baseModel.PrimaryPart
    local originalCFrame = primaryPart.CFrame
    local returnCFrame = finalCFrame or originalCFrame
    local wasAnchored = primaryPart.Anchored
    local halfDuration = duration / 2

    -- Anchoredを一時解除（Tweenとの競合を回避）
    primaryPart.Anchored = false
    baseModel:SetAttribute("IsAnimating", true)

    -- 上昇先のCFrame（Y軸方向にriseHeight分上に）
    local upCFrame = originalCFrame * CFrame.new(0, riseHeight, 0)

    -- 上昇フェーズ
    local riseTween = TweenService:Create(primaryPart,
        TweenInfo.new(halfDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {CFrame = upCFrame}
    )

    -- 下降フェーズ（finalCFrameがあればそこへ、なければ元の位置へ）
    local fallTween = TweenService:Create(primaryPart,
        TweenInfo.new(halfDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {CFrame = returnCFrame}
    )

    -- 回転をHeartbeatで制御
    local spinConnection
    local startTime = os.clock()

    local function startSpin()
        startTime = os.clock()
        spinConnection = RunService.Heartbeat:Connect(function()
            if not baseModel or not baseModel.Parent then
                if spinConnection then spinConnection:Disconnect() end
                return
            end
            local elapsed = os.clock() - startTime
            -- duration秒で2回転
            local angle = (elapsed / duration) * math.pi * 4
            -- 元の回転を保持しつつY軸回転を追加
            primaryPart.CFrame = CFrame.new(primaryPart.Position) * CFrame.Angles(0, angle, 0)
        end)
    end

    local function stopSpin()
        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
    end

    -- 上昇完了 → 下降開始
    riseTween.Completed:Connect(function()
        if baseModel and baseModel.Parent then
            fallTween:Play()
        end
    end)

    -- 下降完了 → 回転停止・指定位置に復帰
    fallTween.Completed:Connect(function()
        stopSpin()
        if baseModel and baseModel.Parent then
            primaryPart.CFrame = returnCFrame
            primaryPart.Anchored = wasAnchored
            baseModel:SetAttribute("IsAnimating", false)
        end
    end)

    startSpin()
    riseTween:Play()

    return riseTween, fallTween
end

-- ========================================
-- フェード・透明度アニメーション
-- ========================================

-- モデル内の全BasePartの透明度をTweenで変更
function CommonAnimationFunctions.tweenTransparency(baseModel, tweenInfo, targetTransparency)
    if not baseModel then return {} end

    local tweens = {}
    for _, part in ipairs(baseModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local tween = TweenService:Create(part, tweenInfo, {Transparency = targetTransparency})
            tween:Play()
            table.insert(tweens, tween)
        end
    end
    return tweens
end

-- ========================================
-- シーケンスアニメーション
-- ========================================

-- 複数のTweenを順番に再生
-- steps: { {tweenInfo, properties}, ... } の配列
-- propertiesはPrimaryPartに対するもの (CFrame, Position等)
function CommonAnimationFunctions.playSequence(baseModel, steps, onComplete)
    if not baseModel or not baseModel.PrimaryPart then return end

    task.spawn(function()
        for _, step in ipairs(steps) do
            if not baseModel.Parent then return end
            local tweenInfo = step[1]
            local properties = step[2]
            local tween = TweenService:Create(baseModel.PrimaryPart, tweenInfo, properties)
            tween:Play()
            tween.Completed:Wait()
        end
        if onComplete then
            onComplete()
        end
    end)
end

-- ========================================
-- 単発エフェクト
-- ========================================

-- ReplicatedStorageからエフェクトテンプレートを取得して再生
-- effectPath: ReplicatedStorage以下のパス（例: "Effects/LevelUpEffect"）
-- cframe: エフェクトの再生位置
-- duration: エフェクトの生存時間（秒）
-- parent: エフェクトの親（省略時はWorkspace）
function CommonAnimationFunctions.playEffect(effectPath, cframe, duration, parent)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local template = ReplicatedStorage:FindFirstChild(effectPath, true)
    if not template then
        warn("[playEffect] エフェクトが見つかりません:", effectPath)
        return nil
    end

    local effect = template:Clone()
    effect:PivotTo(cframe)
    effect.Parent = parent or workspace

    -- 指定時間後に削除
    task.delay(duration, function()
        if effect.Parent then
            effect:Destroy()
        end
    end)

    return effect
end

-- シンプルなバーストエフェクト（拡大→フェードアウトして消滅）
-- cframe: 再生位置
-- color: エフェクトの色
-- options: { size = Vector3, duration = number }
function CommonAnimationFunctions.playBurstEffect(cframe, color, options)
    local opts = options or {}
    local size = opts.size or Vector3.new(3, 3, 3)
    local duration = opts.duration or 0.5

    -- エフェクト用Partを生成
    local part = Instance.new("Part")
    part.Name = "BurstEffect"
    part.Size = size * 0.1
    part.CFrame = cframe
    part.Color = color or Color3.fromRGB(255, 255, 255)
    part.Material = Enum.Material.Neon
    part.Transparency = 0
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Shape = Enum.PartType.Ball
    part.Parent = workspace

    -- 拡大
    local growTween = TweenService:Create(part,
        TweenInfo.new(duration * 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = size, Transparency = 0.3}
    )

    -- フェードアウト
    local fadeTween = TweenService:Create(part,
        TweenInfo.new(duration * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = size * 1.5, Transparency = 1}
    )

    growTween.Completed:Connect(function()
        if part.Parent then
            fadeTween:Play()
        end
    end)

    fadeTween.Completed:Connect(function()
        if part.Parent then
            part:Destroy()
        end
    end)

    growTween:Play()
    return part
end

-- リングエフェクト（Y軸方向に広がる薄いリング）
-- cframe: 再生位置
-- color: リングの色
-- options: { radius = number, duration = number }
function CommonAnimationFunctions.playRingEffect(cframe, color, options)
    local opts = options or {}
    local radius = opts.radius or 5
    local duration = opts.duration or 0.6

    local part = Instance.new("Part")
    part.Name = "RingEffect"
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.CFrame = cframe
    part.Color = color or Color3.fromRGB(255, 255, 255)
    part.Material = Enum.Material.Neon
    part.Transparency = 0
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Shape = Enum.PartType.Cylinder
    part.Parent = workspace

    -- リングをY軸方向に広げる
    local targetSize = Vector3.new(radius * 2, 0.2, radius * 2)
    local growTween = TweenService:Create(part,
        TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = targetSize, Transparency = 0.3}
    )

    local fadeTween = TweenService:Create(part,
        TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = targetSize * 1.3, Transparency = 1}
    )

    growTween.Completed:Connect(function()
        if part.Parent then
            fadeTween:Play()
        end
    end)

    fadeTween.Completed:Connect(function()
        if part.Parent then
            part:Destroy()
        end
    end)

    growTween:Play()
    return part
end

return CommonAnimationFunctions
