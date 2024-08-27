local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gorp = require("packages/gorp")
local ecrx = require("shared/ecrx")

local client = ReplicatedStorage.Client
local systems = client.systems

local scheduler = gorp.scheduler("client")
local loop = ecrx.gameloop(scheduler, {
    {i = 1},
    systems.replicate
})

return function(dt)
    loop(dt)
end
