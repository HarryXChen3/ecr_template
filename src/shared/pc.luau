local ecr = require("@packages/ecr")

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

export type CType = unknown

local component = ecr.component
local tag = ecr.tag

--[[
    Convenience function for defining a component with a default primitive value.
    @param value the primitive value
    @return the component with the default value
]]
local function primitive<T>(value: T): T
    return component(function() return value end)
end
--[[
    Convenience function for defining a component with a default struct.
    @param struct the struct
    @return the component with the default struct
    
    *Impl*: the struct provided is cloned on retrieval
]]
-- todo: structs with nested tables
local function struct<T>(struct: T & {}): T
    return component(function() return table.clone(struct) :: T & {} end)
end

--[[
    SSOT for all component types.

    Components are typecasted to their respective value type, e.g.
    ```
    -- not really a Player (in reality its a component id),
    -- but typecasted to one so that we get component types properly
    Player = component() :: Player
    ```

    Typically, this file is named something easy to remember,
    such as an abbrievation of your project name (currently `pc` for project components).
    
    It is recommended that the name be kept to 2 characters length
    to save on keystrokes, as this file is required a lot.
]]
local components = ecr.name({
    Player = component() :: Player,
    ConnectedPlayers = struct({}) :: Array<Player>
})

return table.freeze(components)