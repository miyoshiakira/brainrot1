--[[
    BrainrotCharacters
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
    {Id = "skibidi", Name = "Skibidi Cat", Rarity = "Common", Emoji = "🐱"},
    {Id = "rizz", Name = "Rizz Hamster", Rarity = "Common", Emoji = "🐹"},
    {Id = "gyatt", Name = "Gyatt Bunny", Rarity = "Common", Emoji = "🐰"},
    {Id = "fanum", Name = "Fanum Fox", Rarity = "Common", Emoji = "🦊"},
    {Id = "sigma", Name = "Sigma Frog", Rarity = "Common", Emoji = "🐸"},

    -- Rare
    {Id = "mewing", Name = "Mewing Owl", Rarity = "Rare", Emoji = "🦉"},
    {Id = "griddy", Name = "Griddy Penguin", Rarity = "Rare", Emoji = "🐧"},
    {Id = "bussin", Name = "Bussin Panda", Rarity = "Rare", Emoji = "🐼"},
    {Id = "cap", Name = "No Cap Koala", Rarity = "Rare", Emoji = "🐨"},

    -- Epic
    {Id = "ohio", Name = "Ohio Dragon", Rarity = "Epic", Emoji = "🐉"},
    {Id = "gooning", Name = "Gooning Unicorn", Rarity = "Epic", Emoji = "🦄"},
    {Id = "npc", Name = "NPC King", Rarity = "Epic", Emoji = "👑"},

    -- Legendary
    {Id = "alpha", Name = "Alpha Titan", Rarity = "Legendary", Emoji = "🦁"},
    {Id = "beta", Name = "Beta Phoenix", Rarity = "Legendary", Emoji = "🔥"},

    -- Rainbow
    {Id = "rainbow_supreme", Name = "Rainbow Supreme", Rarity = "Rainbow", Emoji = "🌈"},
    {Id = "cosmic_brainrot", Name = "Cosmic Brainrot", Rarity = "Rainbow", Emoji = "⭐"},
}

-- ユーティリティ関数
local BrainrotCharacters = {}

function BrainrotCharacters.GetRarityConfig(rarity)
    return RARITY_CONFIG[rarity]
end

function BrainrotCharacters.GetAllCharacters()
    return CHARACTERS
end

function BrainrotCharacters.GetCharacterById(id)
    for _, char in ipairs(CHARACTERS) do
        if char.Id == id then
            return char
        end
    end
    return nil
end

function BrainrotCharacters.GetCharactersByRarity(rarity)
    local result = {}
    for _, char in ipairs(CHARACTERS) do
        if char.Rarity == rarity then
            table.insert(result, char)
        end
    end
    return result
end

function BrainrotCharacters.RollCharacter(isRainbowRain)
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

function BrainrotCharacters.GenerateBonus(rarity)
    local config = RARITY_CONFIG[rarity]
    if not config then return 10 end

    local minBonus, maxBonus = config.BonusRange[1], config.BonusRange[2]
    return math.random(minBonus, maxBonus)
end

return {
    BrainrotCharacters = BrainrotCharacters,
    RARITY_CONFIG = RARITY_CONFIG,
    CHARACTERS = CHARACTERS,
    GetCharacterById = BrainrotCharacters.GetCharacterById,
    GetRarityConfig = BrainrotCharacters.GetRarityConfig,
    GetCharactersByRarity = BrainrotCharacters.GetCharactersByRarity,
    RollCharacter = BrainrotCharacters.RollCharacter,
    GenerateBonus = BrainrotCharacters.GenerateBonus,
}
