local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunctions = require(ReplicatedStorage.Shared.RemoteFunctions)

local UIInit = {}

local ACTION_THROW = "ThrowCharacterAction"

function UIInit.Initialize()

    local function handleAction(actionName, inputState, inputObject)
        if actionName == ACTION_THROW and inputState == Enum.UserInputState.Begin then
            -- サーバーに投げる命令を送り、結果を受け取る
            print("[UIInit] 投げTry")
            local success = RemoteFunctions.ThrowAction:InvokeServer()
            if success then
                print("[UIInit] 投げ成功")
            end
        end
    end

    -- アクションの登録
    -- 第1引数: アクション名
    -- 第2引数: 実行する関数
    -- 第3引数: 真の場合、スマホにボタンを表示する
    -- 第4引数以降: 割り当てるキー（PCのキーボードなど）
    ContextActionService:BindAction(
        ACTION_THROW, 
        handleAction, 
        true, 
        Enum.KeyCode.Q, Enum.KeyCode.ButtonX -- PCはQキー、コントローラーはXボタン
    )

    -- スマホ用ボタンの見た目を調整
    ContextActionService:SetTitle(ACTION_THROW, "ぶん投げる")
    ContextActionService:SetPosition(ACTION_THROW, UDim2.new(0.5, 0, 0.2, 0))
end

return UIInit