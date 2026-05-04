--[[
    ProfileTemplate
    プレイヤーデータの初期テンプレート定義
    ブレインロット収集・育成システム対応
]]

export type Monster = {
    MonsterId: string,
    MonsterName: string,
    ModelName: string,
    Rarity: string,  -- "Common", "Rare", "Epic", "Legendary", "Rainbow"
    Money: number,    -- 1秒あたりの収入
    Bonus: number,    -- ボーナス値
    Level: number,    -- 育成レベル
}

export type ProfileData = {
    -- 通貨
    Money: number,

    -- 高度（Brainrot Launch Simulator用）
    Height: number,

    -- キャラクターボーナス
    CharacterBonus: number,
    BasePower: number,

    -- ブレインロット収集
    TotalCharactersCollected: number,  -- 総収集数

    -- スロット配置
    SlotData: {[number]: Monster?},  -- スロット番号 → MonsterId（空ならnil）

    -- アンロック済みオブジェクトID
    UnlockedObjects: {[string]: boolean},

    -- 放置報酬用
    LastOnlineTime: number,
    OfflineEarningsRate: number,  -- 1秒あたりのオフライン収益

    -- 統計
    TotalMoneyEarned: number,
    TotalPlayTime: number,
    SessionCount: number,
    TotalLaunches: number,  -- 発射回数
    RainbowCharactersFound: number,  -- レインボーキャラ発見数
}

local ProfileTemplate: ProfileData = {
    -- 通貨
    Money = 0,

    -- 高度（Brainrot Launch Simulator用）
    Height = 0,

    -- キャラクターボーナス
    CharacterBonus = 10,  -- 初期キャラクターボーナス
    BasePower = 100,  -- 基本発射パワー

    -- ブレインロット収集
    TotalCharactersCollected = 0,

    -- スロット配置
    SlotData = {},

    -- アンロック済みオブジェクトID
    UnlockedObjects = {},

    -- 放置報酬用
    LastOnlineTime = 0,
    OfflineEarningsRate = 1,  -- 初期は1秒あたり1コイン

    -- 統計
    TotalMoneyEarned = 0,
    TotalPlayTime = 0,
    SessionCount = 0,
    TotalLaunches = 0,
    RainbowCharactersFound = 0,
}

return {
    ProfileTemplate = ProfileTemplate,
}
