local ecr = require("packages/ecr")

--[[
    The server world.
]]
local world = ecr.registry()

-- must be cloned for gorp
return table.clone(world)