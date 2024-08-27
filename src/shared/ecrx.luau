local ecr = require "packages/ecr"

type entity = ecr.entity
type Handle = ecr.Handle
type Queue<T...> = ecr.Queue<T...>
type Registry = ecr.Registry

local function queue_old_values<T>(reg: Registry, ctype: T, filter: ((Handle) -> boolean)?): Queue<T>
    local q = ecr.queue()

    local function listener(id)
        if filter and not filter(reg:handle(id)) then
            return
        end

        q:add(reg:get(id, ctype))
    end


    reg:on_change(ctype):connect(listener)
    reg:on_remove(ctype):connect(listener)

    return q
end

local function queue_old_entities_and_values<T>(reg: Registry, ctype: T, filter: ((Handle) -> boolean)?): Queue<entity, T>
    local q = ecr.queue()

    local function listener(id)
        if filter and not filter(reg:handle(id)) then
            return
        end

        q:add(id, reg:get(id, ctype))
    end

    reg:on_change(ctype):connect(listener)
    reg:on_remove(ctype):connect(listener)

    return q
end

local function gameloop(
    scheduler: any,
    systems: {Map<string, number> | ModuleScript}
)
    local runs: Map<number, number> = {}
    local names: Array<string> = {}
    local frame = 0
    local interval

    -- pre-compute names
    for i, v in systems do
        if type(v) == "table" then continue end

        local name = v.Name

        local parent = v.Parent :: Instance
        if parent.Name ~= "systems" then
            name = `{parent.Name}/{name}`
        end

        names[i] = name
    end

    return function(dt: number)
        for i, v in ipairs(systems) do
            if type(v) == "table" then
                interval = v.i
                continue
            end

            local name = names[i]

            if not runs[i] or runs[i] + interval == frame then
                runs[i] = frame

                local required = (require)(v)
                scheduler:system(name, required, dt)
            else
                scheduler:skip(name)
            end
        end

        frame += 1
        scheduler:finish()
    end
end

return {
    queue_old_values = queue_old_values,
    queue_old_entities_and_values = queue_old_entities_and_values,
    gameloop = gameloop
}