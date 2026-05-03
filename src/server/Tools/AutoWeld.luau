-- Pluginのツールバーとボタンを作成
local toolbar = plugin:CreateToolbar("MyCustomTools")
local weldButton = toolbar:CreateButton("WeldToPrimary", "選択したモデルをPrimaryPartに溶接", "rbxassetid://4458901886")

-- ボタンがクリックされた時の処理
weldButton.Click:Connect(function()
    local selection = game:GetService("Selection"):Get()
    
    for _, model in ipairs(selection) do
        if model:IsA("Model") and model.PrimaryPart then
            local primary = model.PrimaryPart
            local count = 0

            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and part ~= primary then
                    -- 古いWeldを掃除
                    for _, c in ipairs(part:GetChildren()) do
                        if c:IsA("WeldConstraint") then c:Destroy() end
                    end
                    
                    -- 新規Weld作成
                    local w = Instance.new("WeldConstraint")
                    w.Part0 = part
                    w.Part1 = primary
                    w.Parent = part
                    w.Name = "AutoWeld"
                    part.Anchored = false
                    count += 1
                end
            end
            print(model.Name .. ": " .. count .. "個のパーツを溶接しました！")
        else
            warn(model.Name .. ": PrimaryPartが設定されていません")
        end
    end
end)