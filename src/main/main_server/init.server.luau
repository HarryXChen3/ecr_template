local RunService = game:GetService("RunService")

local pc = require("@shared/pc")
local world = require("@server/world")

local loop = require("@server/gameloop")

RunService.Heartbeat:Connect(function(dt)
    loop(dt)
end)
