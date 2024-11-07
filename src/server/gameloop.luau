local ServerScriptService = game:GetService("ServerScriptService")

local gorp = require("packages/gorp")
local ecrx = require("shared/ecrx")

local server = ServerScriptService.Server
local systems = server.systems

local scheduler = gorp.scheduler("server")

--[[
    Systems that are part of your gameloop, to be scheduled by the scheduler.

    Systems are added after a block `{i: number}` that describes the frequency they will run at.
    
    i.e.
    ```
    {i = 1},
    systems.bob, -- runs every frame (i=1)
    systems.alice, -- runs every frame (i=1)
    {i = 2},
    systems.steve -- runs every other frame (i=2)
    {i = 3},
    systems.john -- runs every other other frame (i=3)
    ```
]]
local loop = ecrx.gameloop(scheduler, {
    {i = 1},
    systems.player,
    systems.replicate
})

return function(dt)
    loop(dt)
end
