local Players = game:GetService("Players")

local ecr = require("@packages/ecr")

local zap = require("@shared/zap/server")
local zapqueue = require("@shared/zap/queue")
local pc = require("@shared/pc")

local world = require("@server/world")

local client_ready = zapqueue(zap.client_ready)
local player_removing = ecr.queue(Players.PlayerRemoving)

--[[
    Tracks connected players, adding the Player component to player entities.
    @param dt deltatime
]]
return function(dt: number)
    local context = world:context()
    if not context:has(pc.ConnectedPlayers) then
        context:add(pc.ConnectedPlayers)
    end

    local connected = context:get(pc.ConnectedPlayers)

    -- add player to world and context
    for player in client_ready do
        if table.find(connected, player) then return end
        context:insert(pc.ConnectedPlayers, player)
    end

    for _, player in Players:GetPlayers() do
        if world:find(pc.Player, player) then continue end

        local entity = world:handle()
        entity:set(pc.Player, player)
    end

    -- remove player from world and context
    for player in player_removing do
        context:patch(pc.ConnectedPlayers, function(players)
            local i = table.find(players, player)
            if i then table.remove(players, i) end
            return players
        end)

        local id = world:find(pc.Player, player)
        if id then world:destroy(id) end
    end
end