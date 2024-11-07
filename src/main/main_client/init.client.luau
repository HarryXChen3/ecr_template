local RunService = game:GetService("RunService")

local gorp = require("packages/gorp")
local zap = require("shared/zap/client")

local pc = require("shared/pc")
local world = require("client/world")

local loop = require("client/gameloop")

local gorp_client = gorp.get_client()
gorp.names(pc)
gorp.hook_world(world)
gorp_client.enabled(true)
gorp_client.gorp_selector()

zap.client_ready.fire()
RunService:BindToRenderStep("loop", 201, function(dt)
    loop(dt)
end)
