local ecr = require("packages/ecr")

--[[
    The client world.
]]
local world = ecr.registry()

-- must be cloned for gorp
return table.clone(world)