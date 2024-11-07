local ecr = require("packages/ecr")

local pc = require("shared/pc")
local zap = require("shared/zap/client")
local zapqueue = require("shared/zap/queue")
local serde = require("shared/serde")

local world = require("client/world")

--[[
    Processes the world diff sent by the server, and replicates the changes required.
    @param the diff
]]
local function diff_load(diff: pc.WorldDiff)
    -- process destroyed entities first
    for _, id in diff.destroyed do
        if not world:contains(id) then continue end
        world:destroy(id)
    end

    for cname, changes in diff.changes do
        local ctype = pc[cname]
        local is_tag = ecr.is_tag(ctype)
        local values = changes.added_or_changed.values
        local deserialize = serde.de[cname]

        for i, id in changes.added_or_changed.entities do
            -- create entity because it may not exist yet
            if not world:contains(id) then
                world:create(id)
            end

            if is_tag then
                world:add(id, ctype)
            else
                world:set(id, ctype,
                    if deserialize then deserialize(values[i]) else values[i])
            end
        end

        for _, id in changes.removed do
            world:remove(id, ctype)
        end
    end
end

local incoming_diff = zapqueue(zap.replicate_world)
local udp_incoming_diff = zapqueue(zap.udp_replicate_world)

--[[
    Feeds incoming TCP and UDP diffs to be processed.
    @param dt deltatime
]]
return function(dt: number)
    for diff in incoming_diff do
        diff_load(diff)
    end

    for diff in udp_incoming_diff do
        diff_load(diff)
    end
end