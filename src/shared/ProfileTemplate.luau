--[[
    ProfileTemplate
    プレイヤーデータの初期テンプレート定義
    ブレインロット収集・育成システム対応
]]

export type BrainrotCharacter = {
    Id: string,
    Name: string,
    Rarity: string,  -- "Common", "Rare", "Epic", "Legendary", "Rainbow"
    Bonus: number,    -- キャラクターボーナス値
    Level: number,   -- 育成レベル
    Count: number,    -- 所持数（重複取得用）
}

export type ProfileData = {
    -- 通貨
    Money: number,

    -- 高度（Brainrot Launch Simulator用）
    Height: number,
    TotalHeight: number,  -- 累計高度

    -- キャラクターボーナス
    CharacterBonus: number,
    BasePower: number,

    -- ブレインロット収集
    Characters: {[string]: BrainrotCharacter},  -- キャラクターID → キャラクターデータ
    ActiveCharacter: string?,  -- 現在選択中のキャラクターID
    TotalCharactersCollected: number,  -- 総収集数

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
    TotalHeight = 0,

    -- キャラクターボーナス
    CharacterBonus = 10,  -- 初期キャラクターボーナス
    BasePower = 100,  -- 基本発射パワー

    -- ブレインロット収集
    Characters = {},
    ActiveCharacter = nil,
    TotalCharactersCollected = 0,

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

return ProfileTemplate
