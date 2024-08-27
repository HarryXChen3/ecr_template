local Players = game:GetService("Players")

local ecr = require("packages/ecr")

local zap = require("shared/zap/server")
local zapqueue = require("shared/zap/queue")
local ffl = require("shared/ffl")

local world = require("server/world")

local client_ready = zapqueue(zap.client_ready)
local player_removing = ecr.queue(Players.PlayerRemoving)

return function(dt: number)
    local context = world:context()
    if not context:has(ffl.ConnectedPlayers) then
        context:add(ffl.ConnectedPlayers)
    end

    local connected = context:get(ffl.ConnectedPlayers)

    -- add player to world and context
    for player in client_ready do
        if table.find(connected, player) then return end
        context:insert(ffl.ConnectedPlayers, player)
    end

    for _, player in Players:GetPlayers() do
        if world:find(ffl.Player, player) then continue end

        local entity = world:handle()
        entity:set(ffl.Player, player)
    end

    -- remove player from world and context
    for player in player_removing do
        context:patch(ffl.ConnectedPlayers, function(players)
            local i = table.find(players, player)
            if i then table.remove(players, i) end
            return players
        end)

        local id = world:find(ffl.Player, player)
        if id then world:destroy(id) end
    end
end