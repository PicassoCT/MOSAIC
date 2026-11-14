-- Engine-owned GameRulesParams survive a LuaRules reset. Store data only;
-- never evaluate a serialized Lua chunk. Regular ticks do not serialize.
local M={}
local function encode(value)
    local kind=type(value)
    if kind=='boolean' then return value and 'b1' or 'b0' end
    if kind=='string' or kind=='number' then
        local text=kind=='number' and string.format('%.14g',value) or value
        return (kind=='number' and 'n' or 's')..#text..':'..text
    end
    assert(kind=='table','unsupported city snapshot value: '..kind)
    local keys={};for key in pairs(value) do keys[#keys+1]=key end
    table.sort(keys,function(a,b)if type(a)==type(b) then return a<b end;return type(a)<type(b) end)
    local result={'t'..#keys..':'}
    for _,key in ipairs(keys) do result[#result+1]=encode(key);result[#result+1]=encode(value[key]) end
    return table.concat(result)
end
local function decode(text)
    local cursor,items=1,0
    local function read(depth)
        items=items+1;assert(items<100000 and depth<32,'city snapshot exceeds limits')
        local kind=text:sub(cursor,cursor);cursor=cursor+1
        if kind=='b' then
            local v=text:sub(cursor,cursor);cursor=cursor+1;assert(v=='1' or v=='0');return v=='1'
        end
        local stop=assert(text:find(':',cursor,true),'truncated city snapshot')
        local size=assert(tonumber(text:sub(cursor,stop-1)));assert(size>=0 and size==math.floor(size))
        cursor=stop+1
        if kind=='t' then
            local result={};for _=1,size do local key=read(depth+1);result[key]=read(depth+1) end;return result
        end
        assert(kind=='s' or kind=='n');assert(cursor+size-1<=#text)
        local value=text:sub(cursor,cursor+size-1);cursor=cursor+size
        if kind=='n' then return assert(tonumber(value)) end
        return value
    end
    local result=read(0);assert(cursor==#text+1,'trailing city snapshot bytes');return result
end
function M.Save(Spring,controller,shared)
    if not controller then return end
    local wire=encode({version=1,plots=controller.plots,nextID=controller.nextID,completed=controller.completed,
        generation=shared and shared.CityGenerationState,asianState=shared and shared.HouseAsianSplitState,
        plans=shared and shared.HouseAsianUnitPlans,center=shared and shared.innerCityCenter})
    local chunks=math.ceil(#wire/1000)
    for i=1,chunks do Spring.SetGameRulesParam('mosaic_city_rebuild_snapshot_'..i,wire:sub((i-1)*1000+1,i*1000)) end
    Spring.SetGameRulesParam('mosaic_city_rebuild_snapshot_chunks',chunks)
end
function M.Load(Spring)
    if not Spring.GetGameRulesParam then return end
    local count=Spring.GetGameRulesParam('mosaic_city_rebuild_snapshot_chunks')
    if not count or count==0 then return end
    assert(count>0 and count<4096,'invalid city snapshot size')
    local chunks={}
    for i=1,count do chunks[i]=assert(Spring.GetGameRulesParam('mosaic_city_rebuild_snapshot_'..i),'missing city snapshot chunk') end
    local state=decode(table.concat(chunks));assert(state.version==1,'unsupported city snapshot version')
    state.byUnit,state.retiring={},{}
    for _,plot in pairs(state.plots) do
        if plot.unitID then state.byUnit[plot.unitID]=plot end
        if plot.sourceUnitID then state.retiring[plot.sourceUnitID]=plot end
    end
    return state
end
return M
