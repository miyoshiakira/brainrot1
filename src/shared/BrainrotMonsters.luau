--[[
    BrainrotMonsters
    ブレインロットキャラクター定義
    ポップでかわいいキャラクターリスト
]]

-- レアリティ設定
local RARITY_CONFIG = {
    Common = {
        Name = "Common",
        Color = Color3.fromRGB(150, 150, 150),
        DropRate = 0.40,
        BonusRange = {5, 15},
    },
    UnCommon = {
        Name = "UnCommon",
        Color = Color3.fromRGB(100, 200, 100),
        DropRate = 0.25,
        BonusRange = {10, 20},
    },
    Rare = {
        Name = "Rare",
        Color = Color3.fromRGB(0, 150, 255),
        DropRate = 0.20,
        BonusRange = {15, 30},
    },
    Epic = {
        Name = "Epic",
        Color = Color3.fromRGB(180, 0, 255),
        DropRate = 0.12,
        BonusRange = {30, 50},
    },
    Legendary = {
        Name = "Legendary",
        Color = Color3.fromRGB(255, 200, 0),
        DropRate = 0.03,
        BonusRange = {50, 100},
    },
    Rainbow = {
        Name = "Rainbow",
        Color = Color3.fromRGB(255, 100, 255),
        DropRate = 0.001,
        BonusRange = {100, 200},
    },
}

-- キャラクター定義（Rarityは釣り時に確率で決定されるため、定義には含めない）
local CHARACTERS = {
    {MonsterId = "Tamago_Chan", MonsterName = "たまごちゃん", ModelName = "TamagoChan", Money = 1.0, Biome="river"},
    {MonsterId = "Aji_Chan", MonsterName = "あじちゃん", ModelName = "AjiChan", Money = 1.2, Biome="river"},
    {MonsterId = "Ika_Chan", MonsterName = "いかちゃん", ModelName = "IkaChan", Money = 1.1, Biome="river"},
    {MonsterId = "Inari_Chan", MonsterName = "いなりちゃん", ModelName = "InariChan", Money = 1.3, Biome="river"},
    {MonsterId = "Amaebi_Chan", MonsterName = "甘エビちゃん", ModelName = "AmaebiChan", Money = 2.5, Biome="glass"},
    {MonsterId = "Tsubugai_Chan", MonsterName = "つぶがいちゃん", ModelName = "TsubugaiChan", Money = 2.7, Biome="glass"},
    {MonsterId = "Hotate_Chan", MonsterName = "ほたてちゃん", ModelName = "HotateChan", Money = 2.8, Biome="glass"},
    {MonsterId = "Hokkigai_Chan", MonsterName = "ほっきちゃん", ModelName = "HokkigaiChan", Money = 2.9, Biome="glass"},
    {MonsterId = "Salmon_Chan", MonsterName = "サーモンちゃん", ModelName = "SalmonChan", Money = 3.0, Biome="glass"},
    {MonsterId = "Cobalt_Saba", MonsterName = "コバルトしめさば君", ModelName = "CobaltSabaChan", Money = 5.0, Biome="mud"},
    {MonsterId = "Ikura_Chan", MonsterName = "いくらちゃん", ModelName = "IkuraChan", Money = 7.5, Biome="mud"},
    {MonsterId = "Negitoro_Pink", MonsterName = "ねぎとろぴんく", ModelName = "NegitoroChan", Money = 8.8, Biome="mud"},
    {MonsterId = "Golden_Anago", MonsterName = "黄金あなご伯爵", ModelName = "AnagoHakushaku", Money = 9.0, Biome="mud"},
    {MonsterId = "Sushi_Chan", MonsterName = "マグロ先輩", ModelName = "SushiChan", Money = 10.0, Biome="city"},
    {MonsterId = "Crystal_Kajiki", MonsterName = "クリスタルかじき様", ModelName = "CrystalKajikiChan", Money = 12.0, Biome="city"},
    {MonsterId = "Uni_Chan", MonsterName = "うに殿下", ModelName = "UniChan", Money = 25.0, Biome="city"},
    {MonsterId = "Otoro_King", MonsterName = "大トロキング", ModelName = "SushiChan", Money = 100.0, Biome="city"},
}

-- ユーティリティ関数
local BrainrotMonsters = {}

function BrainrotMonsters.GetRarityConfig(rarity)
    return RARITY_CONFIG[rarity]
end

function BrainrotMonsters.GetAllCharacters()
    return CHARACTERS
end

function BrainrotMonsters.GetCharacterById(id)
    for _, char in ipairs(CHARACTERS) do
        if char.MonsterId == id then
            return char
        end
    end
    return nil
end

-- Biomeに基づいて釣り可能なキャラクターを取得
function BrainrotMonsters.GetAvailableCharacters(biome)
    local result = {}
    for _, char in ipairs(CHARACTERS) do
        local biomeMatch = (not biome) or (char.Biome == biome)
        if biomeMatch then
            table.insert(result, char)
        end
    end
    return result
end

-- レアリティ確率ボーナス計算
-- FishingPowerと釣り竿ランクに応じて高レアリティの確率を加算
-- bonusRateは0～1の範囲で、高レアリティのDropRateに加算される
local function calcRarityBonus(fishingPower: number, rodRank: number): number
    -- FishingPower: 100ごとに+0.01 (最大0.15)
    local powerBonus = math.min(fishingPower / 10000, 0.15)
    -- 釣り竿ランク: ランク1=0, ランク2=0.02, ランク3=0.04, ランク4=0.07, ランク5=0.10
    local rodBonusTable = {0, 0.02, 0.04, 0.07, 0.10}
    local rodBonus = rodBonusTable[rodRank] or 0.10
    return powerBonus + rodBonus
end

-- 釣り抽選: モンスターをBiomeで絞ってランダム選択 → レアリティを確率で抽選
-- 戻り値: char, rarity (2つの値を返す)
function BrainrotMonsters.RollFromAvailablePool(isRainbowRain, biome, fishingPower, rodRank)
    local pool = BrainrotMonsters.GetAvailableCharacters(biome)
    if #pool == 0 then return nil, nil end

    -- 1. モンスターを均等抽選
    local selectedChar = pool[math.random(1, #pool)]

    -- 2. レアリティを確率で抽選（FishingPower・釣り竿ランクでボーナス加算）
    local rarity = BrainrotMonsters.RollCharacter(isRainbowRain, fishingPower or 0, rodRank or 1)

    return selectedChar, rarity
end

function BrainrotMonsters.RollCharacter(isRainbowRain, fishingPower, rodRank)
    local bonus = calcRarityBonus(fishingPower or 0, rodRank or 1)

    -- ボーナスを各レアリティの確率に加算（Commonから減らして高レアリティに分配）
    local rates = {
        Rainbow    = RARITY_CONFIG.Rainbow.DropRate + bonus * 0.1,
        Legendary  = RARITY_CONFIG.Legendary.DropRate + bonus * 0.15,
        Epic       = RARITY_CONFIG.Epic.DropRate + bonus * 0.25,
        Rare       = RARITY_CONFIG.Rare.DropRate + bonus * 0.25,
        UnCommon   = RARITY_CONFIG.UnCommon.DropRate + bonus * 0.15,
        Common     = 1.0, -- 残り全て
    }
    -- Commonは残りを計算
    rates.Common = 1.0 - (rates.Rainbow + rates.Legendary + rates.Epic + rates.Rare + rates.UnCommon)
    if rates.Common < 0.1 then
        rates.Common = 0.1 -- Common最低保障
    end

    -- レインボーレイン時は別テーブル
    if isRainbowRain then
        rates = {
            Rainbow   = 0.10 + bonus * 0.1,
            Legendary = 0.20 + bonus * 0.15,
            Epic      = 0.25 + bonus * 0.25,
            Rare      = 0.20 + bonus * 0.25,
            UnCommon  = 0.15 + bonus * 0.15,
            Common    = 1.0,
        }
        rates.Common = 1.0 - (rates.Rainbow + rates.Legendary + rates.Epic + rates.Rare + rates.UnCommon)
        if rates.Common < 0.05 then
            rates.Common = 0.05
        end
    end

    local roll = math.random()

    if roll < rates.Rainbow then
        return "Rainbow"
    elseif roll < rates.Rainbow + rates.Legendary then
        return "Legendary"
    elseif roll < rates.Rainbow + rates.Legendary + rates.Epic then
        return "Epic"
    elseif roll < rates.Rainbow + rates.Legendary + rates.Epic + rates.Rare then
        return "Rare"
    elseif roll < rates.Rainbow + rates.Legendary + rates.Epic + rates.Rare + rates.UnCommon then
        return "UnCommon"
    else
        return "Common"
    end
end

-- レアリティランクを取得（FishingPower上昇量の倍率用）
-- Common=1, UnCommon=2, Rare=3, Epic=4, Legendary=5, Rainbow=6
function BrainrotMonsters.GetRarityRank(rarity)
    local ranks = {
        Common = 1,
        UnCommon = 2,
        Rare = 3,
        Epic = 4,
        Legendary = 5,
        Rainbow = 6,
    }
    return ranks[rarity] or 1
end

function BrainrotMonsters.GenerateBonus(rarity)
    local config = RARITY_CONFIG[rarity]
    if not config then return 10 end

    local minBonus, maxBonus = config.BonusRange[1], config.BonusRange[2]
    return math.random(minBonus, maxBonus)
end

return {
    BrainrotMonsters = BrainrotMonsters,
    RARITY_CONFIG = RARITY_CONFIG,
    CHARACTERS = CHARACTERS,
    GetCharacterById = BrainrotMonsters.GetCharacterById,
    GetRarityConfig = BrainrotMonsters.GetRarityConfig,
    GetAvailableCharacters = BrainrotMonsters.GetAvailableCharacters,
    RollFromAvailablePool = BrainrotMonsters.RollFromAvailablePool,
    GetRarityRank = BrainrotMonsters.GetRarityRank,
    RollCharacter = BrainrotMonsters.RollCharacter,
    GenerateBonus = BrainrotMonsters.GenerateBonus,
}
