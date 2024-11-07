local RunService = game:GetService("RunService")

local gorp = require("packages/gorp")

local pc = require("shared/pc")
local world = require("server/world")

local loop = require("server/gameloop")

gorp.names(pc)
gorp.hook_world(world)

RunService.Heartbeat:Connect(function(dt)
    loop(dt)
end)
