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
    -- Common
    {MonsterId = "Cute_Slime", MonsterName = "キャワスライム", ModelName = "CuteSlimeTemplate", Rarity = "Common", Money = 1.0},
    {MonsterId = "Rare_Slime", MonsterName = "レアスライム", ModelName = "CuteSlimeTemplate", Rarity = "Rare", Money = 1.0},
    {MonsterId = "Epic_Slime", MonsterName = "すごスライム", ModelName = "CuteSlimeTemplate", Rarity = "Epic", Money = 1.0},
    {MonsterId = "Legendary_Slime", MonsterName = "伝説スライム", ModelName = "CuteSlimeTemplate", Rarity = "Legendary", Money = 1.0},
    {MonsterId = "Rainbow_Slime", MonsterName = "七色スライム", ModelName = "CuteSlimeTemplate", Rarity = "Rainbow", Money = 1.0},
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

function BrainrotMonsters.GetCharactersByRarity(rarity)
    local result = {}
    for _, char in ipairs(CHARACTERS) do
        if char.Rarity == rarity then
            table.insert(result, char)
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
