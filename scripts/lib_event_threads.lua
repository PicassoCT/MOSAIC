-- Include once per unit-script environment. Requests from gadgets must enter
-- through CallAsUnit; this helper creates the yieldable coroutine itself.
-- Keys coalesce pending requests only. Running jobs retain their own signals.
local pending = {}
local unpackArgs = unpack or table.unpack

return function(key, action, delayMs, ...)
    assert(type(action) == "function", "event thread requires a function")
    local request = {action = action, args = {...}, count = select("#", ...)}
    local alreadyPending = pending[key] ~= nil
    pending[key] = request
    if alreadyPending then return end

    StartThread(function()
        -- StartThread inherits the caller's signal mask, including when a
        -- gadget calls us from another unit-script coroutine. Detach before
        -- yielding so cancelling that caller cannot strand the pending key.
        SetSignalMask(0)
        Sleep(delayMs or 1)
        local nextRequest = pending[key]
        pending[key] = nil
        -- Child starts with mask zero and may choose its own mask. Clearing
        -- first permits the handler to enqueue a follow-up for the same key.
        StartThread(nextRequest.action,
                    unpackArgs(nextRequest.args, 1, nextRequest.count))
    end)
end
