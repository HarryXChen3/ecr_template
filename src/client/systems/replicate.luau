local ecr = require("packages/ecr")

local ffl = require("shared/ffl")
local zap = require("shared/zap/client")
local zapqueue = require("shared/zap/queue")
local serde = require("shared/serde")

local world = require("client/world")

local function diff_load(diff: ffl.WorldDiff)
    -- process destroyed entities first
    for _, id in diff.destroyed do
        if not world:contains(id) then continue end
        world:destroy(id)
    end

    for cname, changes in diff.changes do
        local ctype = ffl[cname]
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

return function(dt: number)
    for diff in incoming_diff do
        diff_load(diff)
    end

    for diff in udp_incoming_diff do
        diff_load(diff)
    end
end