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
        DropRate = 0.60,
        BonusRange = {5, 15},
    },
    Rare = {
        Name = "Rare",
        Color = Color3.fromRGB(0, 150, 255),
        DropRate = 0.25,
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

-- キャラクター定義
local CHARACTERS = {
    -- 【Common】基本のネタ（手に入りやすいが、全ての始まり）
    {MonsterId = "Tamago_Chan", MonsterName = "たまごちゃん", ModelName = "TamagoChan", Rarity = "Common", Money = 1.0, HeightFrom = 0, HeightTo = math.huge},
    {MonsterId = "Aji_Chan", MonsterName = "あじちゃん", ModelName = "AjiChan", Rarity = "Common", Money = 1.2, HeightFrom = 0, HeightTo = math.huge},
    {MonsterId = "Ika_Chan", MonsterName = "いかちゃん", ModelName = "IkaChan", Rarity = "Common", Money = 1.1},
    {MonsterId = "Inari_Chan", MonsterName = "いなりちゃん", ModelName = "InariChan", Rarity = "Common", Money = 1.3, HeightFrom = 0, HeightTo = math.huge},
    -- 【Rare】少し豪華なネタ（ここから収益に差が出始める）
    {MonsterId = "Hokkigai_Chan", MonsterName = "ほっきちゃん", ModelName = "HokkigaiChan", Rarity = "Rare", Money = 2.9},
    {MonsterId = "Amaebi_Chan", MonsterName = "甘エビちゃん", ModelName = "AmaebiChan", Rarity = "Rare", Money = 2.5, HeightFrom = 0, HeightTo = math.huge},
    {MonsterId = "Salmon_Chan", MonsterName = "サーモンちゃん", ModelName = "SalmonChan", Rarity = "Rare", Money = 3.0, HeightFrom = 0, HeightTo = math.huge},
    {MonsterId = "Hotate_Chan", MonsterName = "ほたてちゃん", ModelName = "HotateChan", Rarity = "Rare", Money = 2.8},
    {MonsterId = "Tsubugai_Chan", MonsterName = "つぶがいちゃん", ModelName = "TsubugaiChan", Rarity = "Rare", Money = 2.7},
-- 【Rare】色彩豊かな職人技（装飾はないが、色のコントラストが美しい）
    {
        MonsterId = "Cobalt_Saba", 
        MonsterName = "コバルトしめさば君", 
        ModelName = "CobaltSabaChan", 
        Rarity = "Rare", 
        Money = 5.0,
        HeightFrom = 0, HeightTo = math.huge
    },
    -- 【Epic】高級ネタ（エフェクトが似合うランク）
    {MonsterId = "Ikura_Chan", MonsterName = "いくらちゃん", ModelName = "IkuraChan", Rarity = "Epic", Money = 7.5, HeightFrom = 0, HeightTo = math.huge},
    {MonsterId = "Sushi_Chan", MonsterName = "マグロ先輩", ModelName = "SushiChan", Rarity = "Epic", Money = 10.0, HeightFrom = 0, HeightTo = math.huge},
-- 【Epic】透明感と色彩の調和（シンプルだが高貴な存在）

    {
        MonsterId = "Crystal_Kajiki", 
        MonsterName = "クリスタルかじき様", 
        ModelName = "CrystalKajikiChan", 
        Rarity = "Epic", 
        Money = 12.0,
        HeightFrom = 0, HeightTo = math.huge
    },
-- 【Epic】深い味わいと色味（シンプルだが職人のこだわりを感じる一品）
    {
        MonsterId = "Golden_Anago", 
        MonsterName = "黄金あなご伯爵", 
        ModelName = "AnagoHakushaku", 
        Rarity = "Epic", 
        Money = 9.0,
        HeightFrom = 0, HeightTo = math.huge
    },
    -- 【Epic】高級ネタ（見た目が華やかで収益も高い）
    {MonsterId = "Negitoro_Pink", MonsterName = "ねぎとろぴんく", ModelName = "NegitoroChan", Rarity = "Epic", Money = 8.8},
    
    -- 【Legendary】至高のネタ（なかなか出ない、プレイヤーの憧れ）
    {MonsterId = "Uni_Chan", MonsterName = "うに殿下", ModelName = "UniChan", Rarity = "Legendary", Money = 25.0, HeightFrom = 0, HeightTo = math.huge},
    -- 【Rainbow】幻のネタ（全身が輝く最強の寿司）
    {MonsterId = "Otoro_King", MonsterName = "大トロキング", ModelName = "SushiChan", Rarity = "Rainbow", Money = 100.0, HeightFrom = 0, HeightTo = math.huge},
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

function BrainrotMonsters.GetCharactersByRarity(rarity, height)
    local result = {}
    local h = height or 0
    for _, char in ipairs(CHARACTERS) do
        if char.Rarity == rarity then
            local from = char.HeightFrom or 0
            local to = char.HeightTo or math.huge
            if h >= from and h <= to then
                table.insert(result, char)
            end
        end
    end
    return result
end

function BrainrotMonsters.RollCharacter(isRainbowRain)
    local roll = math.random()

    if isRainbowRain then
        if roll < 0.10 then
            return "Rainbow"
        elseif roll < 0.30 then
            return "Legendary"
        elseif roll < 0.60 then
            return "Epic"
        elseif roll < 0.85 then
            return "Rare"
        else
            return "Common"
        end
    else
        if roll < RARITY_CONFIG.Rainbow.DropRate then
            return "Rainbow"
        elseif roll < RARITY_CONFIG.Rainbow.DropRate + RARITY_CONFIG.Legendary.DropRate then
            return "Legendary"
        elseif roll < RARITY_CONFIG.Rainbow.DropRate + RARITY_CONFIG.Legendary.DropRate + RARITY_CONFIG.Epic.DropRate then
            return "Epic"
        elseif roll < RARITY_CONFIG.Rainbow.DropRate + RARITY_CONFIG.Legendary.DropRate + RARITY_CONFIG.Epic.DropRate + RARITY_CONFIG.Rare.DropRate then
            return "Rare"
        else
            return "Common"
        end
    end
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
    GetCharactersByRarity = BrainrotMonsters.GetCharactersByRarity,
    RollCharacter = BrainrotMonsters.RollCharacter,
    GenerateBonus = BrainrotMonsters.GenerateBonus,
}
