local ecr = require("packages/ecr")

export type WorldDiff = {
    changes: Map<string, {
        added_or_changed: {
            entities: Array<ecr.entity>,
            values: Array<unknown>,
        },
        removed: Array<ecr.entity>,
    }>,
    destroyed: Array<ecr.entity>
}

local component = ecr.component
local tag = ecr.tag

local function primitive<T>(value: T): T
    return component(function() return value end)
end

-- todo: structs with nested tables
local function struct<T>(struct: T & {}): T
    return component(function() return table.clone(struct) :: T & {} end)
end

local components = ecr.name({
    Player = component() :: Player,
    ConnectedPlayers = struct({}) :: Array<Player>
})

return table.freeze(components)