local RunService = game:GetService("RunService")

local gorp = require("packages/gorp")

local ffl = require("shared/ffl")
local world = require("server/world")

local loop = require("server/gameloop")

gorp.names(ffl)
gorp.hook_world(world)


RunService.Heartbeat:Connect(function(dt)
    loop(dt)
end)
