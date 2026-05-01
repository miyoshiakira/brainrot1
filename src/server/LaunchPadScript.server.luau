--[[
    発射台スクリプト
    プレイヤーが発射台に乗ると物理的に吹っ飛ぶ
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- RemoteEvents待機
repeat task.wait() until ReplicatedStorage:FindFirstChild("Shared")
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)
local LaunchModule = require(script.Parent.Modules.LaunchManager)
local LaunchManager = LaunchModule.LaunchManager
local LAUNCH_CONFIG = LaunchModule.LAUNCH_CONFIG

-- 発射台を取得
local launcher = game.Workspace:FindFirstChild("IceCreamLauncher")
if not launcher then
    warn("[LaunchPad] IceCreamLauncherが見つかりません")
    return
end

local launchPad = launcher:FindFirstChild("LaunchPad")
if not launchPad then
    -- ConeBaseをフォールバック
    launchPad = launcher:FindFirstChild("ConeBase")
end

if not launchPad then
    warn("[LaunchPad] 発射台パーツが見つかりません")
    return
end

print("[LaunchPad] 発射台初期化完了:", launchPad.Name)

-- 発射クールダウン管理
local launchCooldowns = {}
local COOLDOWN = 1.5  -- 発射間隔（秒）

-- 発射エフェクト（発射台のアニメーション）
local function playLaunchEffect()
    -- 発射台を一瞬縮めてから伸びる
    local originalSize = launchPad.Size
    local originalCFrame = launchPad.CFrame

    -- 縮む
    launchPad.Size = Vector3.new(originalSize.X * 0.8, originalSize.Y * 0.5, originalSize.Z * 0.8)
    launchPad.CFrame = originalCFrame

    -- 元に戻す（少し遅れて）
    task.delay(0.1, function()
        launchPad.Size = originalSize
        launchPad.CFrame = originalCFrame
    end)
end

-- プレイヤーを吹っ飛ばす
local function launchPlayer(player, height, criticalType, multiplier)
    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoidRootPart then return end

    -- クールダウンチェック
    local now = tick()
    if launchCooldowns[player] and (now - launchCooldowns[player]) < COOLDOWN then
        return
    end
    launchCooldowns[player] = now

    -- 発射エフェクト
    playLaunchEffect()

    -- 高さに応じた吹っ飛び力を計算
    -- 基本の上方向力 + ランダムな横方向
    local baseForce = 150 + (height * 0.5)  -- 高さに比例
    baseForce = math.min(baseForce, 500)  -- 最大制限

    -- クリティカル時はさらに強く
    if criticalType == "PERFECT" then
        baseForce = baseForce * 1.5
    elseif criticalType == "GOOD" then
        baseForce = baseForce * 1.2
    end

    -- ランダムな横方向（少し乱雑に）
    local randomX = (math.random() - 0.5) * 100
    local randomZ = (math.random() - 0.5) * 100

    -- 速度を設定（物理的に吹っ飛ぶ）
    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
        randomX,
        baseForce,
        randomZ
    )

    -- 回転も少し加える（理不尽さUP）
    humanoidRootPart.AssemblyAngularVelocity = Vector3.new(
        (math.random() - 0.5) * 20,
        (math.random() - 0.5) * 10,
        (math.random() - 0.5) * 20
    )

    -- Humanoidを一時的に無効化（物理挙動を優先）
    if humanoid then
        local originalJumpPower = humanoid.JumpPower
        local originalWalkSpeed = humanoid.WalkSpeed

        humanoid.JumpPower = 0
        humanoid.WalkSpeed = 0

        -- 1.5秒後に元に戻す
        task.delay(1.5, function()
            if humanoid and humanoid.Parent then
                humanoid.JumpPower = originalJumpPower
                humanoid.WalkSpeed = originalWalkSpeed
            end
        end)
    end

    -- クライアントに通知
    RemoteEvents.LaunchResult:FireClient(player, {
        Height = height,
        CriticalType = criticalType,
        Multiplier = multiplier,
        TotalHeight = LaunchManager.GetGlobalStats().TotalHeight,
        CoinsEarned = math.floor(height * LAUNCH_CONFIG.CoinsPerHeight),
        IsRainbowRain = false,
    })

    print(string.format("[LaunchPad] %s が吹っ飛んだ! (%s, %.0fm)",
        player.Name, criticalType, height))
end

-- 発射台に触れた時の処理
local function onTouch(otherPart)
    local character = otherPart.Parent
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end

    -- クールダウンチェック
    local now = tick()
    if launchCooldowns[player] and (now - launchCooldowns[player]) < COOLDOWN then
        return
    end

    -- ランダムなゲージ位置を生成（0-1）
    local gaugePosition = math.random()

    -- クリティカル判定
    local criticalMultiplier, criticalType
    if gaugePosition >= 0.45 and gaugePosition <= 0.55 then
        criticalMultiplier = LAUNCH_CONFIG.PerfectMultiplier
        criticalType = "PERFECT"
    elseif gaugePosition >= 0.35 and gaugePosition <= 0.65 then
        criticalMultiplier = LAUNCH_CONFIG.GoodMultiplier
        criticalType = "GOOD"
    else
        criticalMultiplier = LAUNCH_CONFIG.NormalMultiplier
        criticalType = "NORMAL"
    end

    -- 発射処理を実行（ゲーム進行）
    RemoteEvents.LaunchRequest:FireServer(gaugePosition)

    -- プレイヤーデータから高さを取得
    local profile = require(script.Parent.Modules.DataManager).GetProfile(player)
    if profile then
        local height = (profile.BasePower + profile.CharacterBonus) * criticalMultiplier
        launchPlayer(player, height, criticalType, criticalMultiplier)
    end
end

-- Touchイベント接続
launchPad.Touched:Connect(onTouch)

print("[LaunchPad] 発射台スクリプト起動完了")
