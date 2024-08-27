local ServerScriptService = game:GetService("ServerScriptService")

local gorp = require("packages/gorp")
local ecrx = require("shared/ecrx")

local server = ServerScriptService.Server
local systems = server.systems

local scheduler = gorp.scheduler("server")
local loop = ecrx.gameloop(scheduler, {
    {i = 1},
    systems.player,
    systems.replicate
})

return function(dt)
    loop(dt)
end
