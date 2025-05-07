local RunService = game:GetService("RunService")

local zap = require("@shared/zap/client")

local pc = require("@shared/pc")
local world = require("@client/world")

local loop = require("@client/gameloop")

zap.client_ready.fire()
RunService:BindToRenderStep("loop", 201, function(dt)
    loop(dt)
end)
