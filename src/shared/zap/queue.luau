local ecr = require("packages/ecr")

type set_callback<T...> = ((T...) -> ()) -> ()
type on<T...> = ((T...) -> ()) -> ()

return function<T...>(event: {set_callback: set_callback<T...>} | {on: on<T...>}): ecr.Queue<T...>
    local queue = ecr.queue()
    if (event :: any).set_callback then
        (event :: any).set_callback(function(...)
            queue:add(...)
        end)
    elseif (event :: any).on then
        (event :: any).on(function(...)
            queue:add(...)
        end)
    end
    return queue
end