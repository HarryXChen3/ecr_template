local ecr = require("packages/ecr")
local world = ecr.registry()

return table.clone(world)