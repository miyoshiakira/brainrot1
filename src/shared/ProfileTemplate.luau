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

    -- 釣りパワー
    FishingPower: number,

    -- 装備
    EquippedRodName: string?,  -- 釣り竿名（例: "FishingRod1"）

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
    RainbowCharactersFound: number,  -- レインボーキャラ発見数
}

local ProfileTemplate: ProfileData = {
    -- 通貨
    Money = 0,

    -- 釣りパワー
    FishingPower = 1,

    -- 装備
    EquippedRodName = nil,

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
    RainbowCharactersFound = 0,
}

return {
    ProfileTemplate = ProfileTemplate,
}
