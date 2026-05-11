local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)

local UIInit = {}

local ACTION_THROW = "ThrowCharacterAction"
local ACTION_PUTDOWN = "PutDownCharacterAction"

function UIInit.Initialize()

    local function handleAction(actionName, inputState, inputObject)
        if actionName == ACTION_THROW and inputState == Enum.UserInputState.Begin then
            -- サーバーに投げる命令を送り、結果を受け取る
            print("[UIInit] 投げTry")
            local success = RemoteFunctions.ThrowAction:InvokeServer()
            if success then
                print("[UIInit] 投げ成功")
            end
        elseif actionName == ACTION_PUTDOWN and inputState == Enum.UserInputState.Begin then
            -- サーバーに置く命令を送り、結果を受け取る
            print("[UIInit] 置くTry")
            local success = RemoteFunctions.PutDownAction:InvokeServer()
            if success then
                print("[UIInit] 置く成功")
            end
        end
    end

    -- 投げるアクション
    ContextActionService:BindAction(
        ACTION_THROW, 
        handleAction, 
        true, 
        Enum.KeyCode.Q, Enum.KeyCode.ButtonX -- PCはQキー、コントローラーはXボタン
    )
    ContextActionService:SetTitle(ACTION_THROW, "ぶん投げる")
    ContextActionService:SetPosition(ACTION_THROW, UDim2.new(0.5, 0, 0.2, 0))

    -- 置くアクション
    ContextActionService:BindAction(
        ACTION_PUTDOWN,
        handleAction,
        true,
        Enum.KeyCode.E, Enum.KeyCode.ButtonY -- PCはEキー、コントローラーはYボタン
    )
    ContextActionService:SetTitle(ACTION_PUTDOWN, "置く")
    ContextActionService:SetPosition(ACTION_PUTDOWN, UDim2.new(0.5, 0, 0.3, 0))
end

return UIInit