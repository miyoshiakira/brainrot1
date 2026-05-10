--[[
    AreaMaster
    エリア共通マスタ定義
]]

export type AreaEntry = {
    AreaName: string,
    Cost: number,
    Biome: string?,
}

local AREA_OPEN_COSTS: {AreaEntry} = {
    {AreaName = "草原", Cost = 10000, Biome = "glass"},
    {AreaName = "沼地", Cost = 500000, Biome = "mud"},
    {AreaName = "市街地", Cost = 25000000, Biome = "city"},
    {AreaName = "洞窟", Cost = 1250000000, Biome = "cave"},
}

local AreaMaster = {}

function AreaMaster.GetCost(areaName: string): number?
    for _, entry in ipairs(AREA_OPEN_COSTS) do
        if entry.AreaName == areaName then
            return entry.Cost
        end
    end
    return nil
end

function AreaMaster.GetBiome(areaName: string): string?
    for _, entry in ipairs(AREA_OPEN_COSTS) do
        if entry.AreaName == areaName then
            return entry.Biome
        end
    end
    return nil
end

function AreaMaster.GetAllAreas(): {AreaEntry}
    return AREA_OPEN_COSTS
end

return {
    AREA_OPEN_COSTS = AREA_OPEN_COSTS,
    GetCost = AreaMaster.GetCost,
    GetBiome = AreaMaster.GetBiome,
    GetAllAreas = AreaMaster.GetAllAreas,
}
