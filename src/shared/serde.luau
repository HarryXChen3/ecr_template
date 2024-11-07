--[[
    Map of component names to serialization function for that component,
    optional for components.

    ```
    local ser = {
        MyComponent = function(value) return tostring(value) end
    }
    ```
]]
local ser: Map<string, (unknown) -> unknown> = {}


--[[
    Map of component names to deserialization function for that component,
    optional for components.

    ```
    local de = {
        MyComponent = function(value: string) return value end
    }
    ```
]]
local de: Map<string, (unknown) -> unknown> = {}

return {
    ser = ser,
    de = de
}