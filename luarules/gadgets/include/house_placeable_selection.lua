-- Synced city-wide usage ledger and ordered placement requests. Rules params
-- retain the ledger and applied layouts across reload/save restoration.
local variation = VFS.Include('scripts/lib_house_placeable_variation.lua')
local prefix = 'house_placeable_v1_'
local fields = {'name','typeKey','x','z','moveX','moveY','moveZ','rotation','ground'}
return function(Spring, mapName, state)
    state = state or {}
    state.pending = state.pending or {}
    state.completed = state.completed or {}
    local service = {}
    local function readLayout(id)
        local count = Spring.GetUnitRulesParam(id,prefix..'count')
        if count == nil then return end
        local result = {}
        for i=1,count do
            local p = {}
            for _,key in ipairs(fields) do p[key]=Spring.GetUnitRulesParam(id,prefix..i..'_'..key) end
            result[i]=p
        end
        return result
    end
    local function saveLayout(id, result)
        for i,p in ipairs(result) do
            for _,key in ipairs(fields) do
                if p[key] ~= nil then Spring.SetUnitRulesParam(id,prefix..i..'_'..key,p[key],{private=true}) end
            end
        end
        Spring.SetUnitRulesParam(id,prefix..'count',#result,{private=true})
    end
    function service:GameID(id)
        state.gameID = id
    end
    function service:Request(id, apply)
        if state.completed[id] then return state.completed[id] end
        if state.pending[id] then return state.pending[id] end
        local ticket = {id=id,frame=Spring.GetGameFrame(),apply=apply}
        state.pending[id]=ticket
        return ticket
    end
    function service:UnitDestroyed(id)
        local ticket=state.pending[id]
        if ticket then ticket.done=true;ticket.result={} end
        state.pending[id]=nil
        state.completed[id]=nil
        -- Historical use stays counted. Rebuilt houses draw the next choices.
    end
    function service:GameFrame(frame)
        local ready={}
        for _,ticket in pairs(state.pending) do
            if ticket.frame<frame then ready[#ready+1]=ticket end
        end
        table.sort(ready,function(a,b)
            return a.frame==b.frame and a.id<b.id or a.frame<b.frame
        end)
        -- Bound assembly work; older requests remain ahead of new arrivals.
        for i=1,math.min(8,#ready) do
            local ticket=ready[i]
            local id=ticket.id
            state.pending[id]=nil
            if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then
                ticket.result={}
            else
                local ok,err=pcall(function()
                    Spring.UnitScript.CallAsUnit(id,function()
                        local saved=readLayout(id)
                        local selection
                        local sequence=Spring.GetGameRulesParam(prefix..'sequence') or 0
                        if not saved then
                            local seed=Spring.GetGameRulesParam(prefix..'seed')
                            if not seed then
                                seed=variation.hash(0,(mapName or '')..':'..(state.gameID or ''))
                                Spring.SetGameRulesParam(prefix..'seed',seed,{private=true})
                            end
                            selection={seed=variation.hash(seed,sequence..':'..id),
                                getUses=function(key)
                                    return Spring.GetGameRulesParam(prefix..'used_'..key) or 0
                                end}
                        end
                        local result=assert(ticket.apply(selection,saved),'placement callback returned no layout')
                        if not saved then
                            for _,p in ipairs(result) do
                                local key=prefix..'used_'..assert(p.typeKey)
                                Spring.SetGameRulesParam(key,(Spring.GetGameRulesParam(key) or 0)+1,{private=true})
                            end
                            saveLayout(id,result)
                            Spring.SetGameRulesParam(prefix..'sequence',sequence+1,{private=true})
                        end
                        ticket.result=result
                    end)
                    assert(ticket.result,'placement callback did not complete')
                end)
                if not ok then ticket.error=tostring(err) end
                state.completed[id]=ticket
            end
            ticket.apply=nil
            ticket.done=true
        end
    end
    return service
end
