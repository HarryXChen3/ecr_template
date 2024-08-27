local RunService = game:GetService("RunService")

local gorp = require("packages/gorp")
local zap = require("shared/zap/client")

local ffl = require("shared/ffl")
local world = require("client/world")

local loop = require("client/gameloop")

local gorp_client = gorp.get_client()
gorp.names(ffl)
gorp.hook_world(world)
gorp_client.enabled(true)
gorp_client.gorp_selector()

zap.client_ready.fire()
RunService:BindToRenderStep("loop", 201, function(dt)
    loop(dt)
end)
