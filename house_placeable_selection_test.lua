-- run.sh -- lua5.1 tests/house_placeable_selection_test.lua
VFS={Include=dofile}
local planner=dofile('scripts/lib_house_asian_placeables.lua')
local factory=dofile('luarules/gadgets/include/house_placeable_selection.lua')
local variation=dofile('scripts/lib_house_placeable_variation.lua')
local originalRandom,originalSeed=math.random,math.randomseed
math.random=function() error('selection consumed simulation RNG') end
math.randomseed=function() error('selection reseeded simulation RNG') end
local function fixture()
    local f={frame=0,rules={},units={},dead={},order={},applied=0}
    f.spring={GetGameFrame=function() return f.frame end,
        ValidUnitID=function(id) return not f.dead[id] end,GetUnitIsDead=function(id) return f.dead[id] end,
        GetGameRulesParam=function(k) return f.rules[k] end,
        SetGameRulesParam=function(k,v) f.rules[k]=v end,
        GetUnitRulesParam=function(id,k) return (f.units[id] or {})[k] end,
        SetUnitRulesParam=function(id,k,v) f.units[id]=f.units[id] or {};f.units[id][k]=v end,
        UnitScript={CallAsUnit=function(id,fn) f.order[#f.order+1]=id;return fn() end}}
    function f:reload(keep)
        self.state=keep and self.state or {}
        self.service=factory(self.spring,'selection-test',self.state)
    end
    function f:step()
        self.frame=self.frame+1; self.service:GameFrame(self.frame)
    end
    f:reload();f.service:GameID('0123456789abcdef0123456789abcdef')
    return f
end
local function pool(p)
    local names,result={},{}
    for name in pairs(p.catalogue.pieces) do names[#names+1]=name end
    table.sort(names);for id,name in ipairs(names) do result[name]=id end
    return result
end
local function request(f,id,p,options)
    return f.service:Request(id,function(selection,saved)
        f.applied=f.applied+1
        if saved then return saved end
        options=options or {}; options.pieces=options.pieces or pool(p);options.seed=83;options.selection=selection
        return p.plan(options)
    end)
end
local function signature(result)
    local t={};for _,p in ipairs(result) do t[#t+1]=p.name..':'..p.x..':'..p.z..':'..p.rotation end
    return table.concat(t,'|')
end
-- A small interchangeable pool makes the no-repeat guarantee exact.
local catalog={scale=1,pieces={}}
for i=1,6 do catalog.pieces['P'..i]={label='Type '..i,category='lighting',walkway=true,poses={}}
    for pose=1,8 do catalog.pieces['P'..i].poses[pose]={footMin={-1,0,-1},footMax={1,2,1},min={-1,0,-1},max={1,2,1}} end
end
local toy=planner.withCatalogue(catalog)
local a,b=fixture(),fixture();local ta,tb={},{}
for id=1,18 do ta[id]=request(a,id,toy,{count=1}) end
for id=18,1,-1 do tb[id]=request(b,id,toy,{count=1}) end
-- No same-frame execution and at most eight placements per tick.
a.service:GameFrame(0);assert(a.applied==0)
a:step();b:step();assert(a.applied==8)
a:step();b:step();a:step();b:step()
local uses={}
for id=1,18 do
    assert(ta[id].done and not ta[id].error,ta[id].error)
    assert(signature(ta[id].result)==signature(tb[id].result),'request insertion order affected result')
    assert(a.order[id]==id,'requests not sorted by unit ID')
    local key=ta[id].result[1].typeKey
    uses[key]=(uses[key] or 0)+1
    assert(uses[key]==math.ceil(id/6),'repeated a type before exhausting its tier')
end
local before=a.applied
assert(request(a,1,toy)==ta[1] and a.applied==before,'duplicate request consumed a choice')
-- Reload from persisted rules alone: exact layouts and counts survive.
a:reload()
local replay=request(a,1,toy);a:step()
assert(signature(replay.result)==signature(ta[1].result),'reload changed an existing layout')
local nextA=request(a,19,toy,{count=1});local nextB=request(b,19,toy,{count=1})
a:step();b:step()
assert(signature(nextA.result)==signature(nextB.result),'reload changed future choices')
-- Pending callbacks survive gadget-only reload; destroyed requests consume nothing.
local pending=request(a,20,toy,{count=1});a:reload(true);a:step();assert(pending.done and not pending.error)
local cancel=request(a,21,toy,{count=1});a.service:UnitDestroyed(21)
local seq=a.rules.house_placeable_v1_sequence;a:step();assert(cancel.done and a.rules.house_placeable_v1_sequence==seq)
local dead=request(a,22,toy,{count=1});a.dead[22]=true;a:step();assert(dead.done and #dead.result==0)
-- Unplaceable types remain unused, and cannot block suitable repeats.
local f=fixture()
for id=1,4 do
    local t=request(f,id,toy,{count=2,accept=function(p) return p.name=='P1' or p.name=='P2' end})
    f:step();assert(not t.error and #t.result==2,t.error)
end
assert(f.rules['house_placeable_v1_used_Type 1']==4 and not f.rules['house_placeable_v1_used_Type 3'])
local denied=request(f,5,toy,{accept=function() return false end});f:step();assert(#denied.result==0)
-- An unused type that needs the relaxed pass beats a repeated strict-fit type.
local fallback=toy.plan{pieces={P1=1,P2=2},count=1,selection={seed=7,getUses=function(k) return k=='Type 1' and 0 or 8 end},
    accept=function(p) return p.name=='P2' or p.relaxed end}
assert(#fallback==1 and fallback[1].name=='P1' and fallback[1].relaxed)
-- Different model names for one type must share a counter.
local standalone=planner.withCatalogue(dofile('scripts/house_asian_standalone_placeable_catalog.lua'))
assert(variation.typeKey('Placeable22',planner.catalogue.pieces.Placeable22)==
    variation.typeKey('Placeable053',standalone.catalogue.pieces.Placeable053))
local alias=fixture()
local x=request(alias,1,planner,{pieces={Placeable22=22},count=1});alias:step()
local y=request(alias,2,standalone,{pieces={Placeable053=53},count=1});alias:step()
assert(not x.error and not y.error and alias.rules['house_placeable_v1_used_Mesh fence panel']==2)
-- Real catalogs retain minimums, big props and deterministic bounded fallback.
local city=fixture()
local reached={}
for id=1,100 do
    local p=id%2==0 and standalone or planner
    local t=request(city,id,p);city:step();assert(not t.error,t.error)
    assert(#t.result>=2 and #t.result<=5)
    local big,seen=false,{}
    for _,q in ipairs(t.result) do
        assert(not seen[q.typeKey]);seen[q.typeKey]=true;reached[q.typeKey]=true
        big=big or p.isLarge(q.name)
        for _,other in ipairs(t.result) do if other~=q then assert(not p.overlap(q,other,0)) end end
    end
    assert(big,'global selection lost the large prop')
end
local reachedCount=0;for _ in pairs(reached) do reachedCount=reachedCount+1 end
assert(reachedCount==59,'not all authored types reached: '..reachedCount)
math.random,math.randomseed=originalRandom,originalSeed
print('PASS: global usage tiers, stable queue, bounded work, aliases, failed sites, repeat fallback, reload and all 59 types')
-- Real unit-script helper waits for the service, applies the actual terrain
-- plan in unit context, and resolves saved piece names back to local IDs.
local f=fixture();local shown={};local pieces=pool(planner)
f.spring.GetUnitPosition=function() return 2000,20,2000 end
f.spring.GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end
f.spring.GetGroundHeight=function() return 20 end
local function applyHouse()
    local env=setmetatable({unitID=77,GG={HousePlaceableSelection=f.service},
        Game={mapSizeX=8000,mapSizeZ=8000,squareSize=8},Spring=f.spring,
        Move=function(id) assert(id>0) end,Turn=function(id) assert(id>0) end,
        Show=function(id) shown[id]=true end,SetRadiancePlaceables=function() end,
        Sleep=function() f:step() end},{__index=_G})
    local helper=planner:bindPlacement(env)
    return helper({seed=83,cell=770,pieces=pieces,addToShowTable=function() end})
end
local applied=applyHouse();assert(#applied>=2)
for _,p in ipairs(applied) do assert(shown[p.id]) end
local signatureBefore=signature(applied);local sequence=f.rules.house_placeable_v1_sequence
f:reload();shown={}
for name,id in pairs(pieces) do pieces[name]=id+100 end
local reloaded=applyHouse()
assert(signature(reloaded)==signatureBefore and f.rules.house_placeable_v1_sequence==sequence)
for _,p in ipairs(reloaded) do assert(p.id>100 and shown[p.id]) end
print('PASS: queued production helper, actual placement, persisted replay and piece-ID remapping')
-- One cached planner can serve several units, without capturing the first or
-- most recently bound unit's identity, coordinates, or engine hooks.
local requests,shownByUnit={},{}
local sharedService={Request=function(_,unit,apply)
    requests[#requests+1]=unit
    return {done=true,result=apply(nil)}
end}
local function bindUnit(unit)
    local pool=pool(planner)
    for name,id in pairs(pool) do pool[name]=unit*1000+id end
    shownByUnit[unit]=0
    local env={unitID=unit,GG={HousePlaceableSelection=sharedService},
        Game={mapSizeX=8192,mapSizeZ=8192,squareSize=8},
        Spring={GetUnitPosition=function(id) assert(id==unit);return 2000,20,2000 end,
            GetUnitVectors=function(id) assert(id==unit);return {0,0,1},{0,1,0},{-1,0,0} end,
            GetGroundHeight=function() return 20 end},
        Move=function(id) assert(math.floor(id/1000)==unit,'wrong unit Move binding') end,
        Turn=function(id) assert(math.floor(id/1000)==unit,'wrong unit Turn binding') end,
        Show=function(id) assert(math.floor(id/1000)==unit);shownByUnit[unit]=shownByUnit[unit]+1 end,
        SetRadiancePlaceables=function(ids) assert(math.floor(ids[1]/1000)==unit) end,
        Sleep=function() error('completed request should not sleep') end}
    return planner:bindPlacement(env),{seed=83,cell=770,pieces=pool,addToShowTable=function() end}
end
local placeA,optionsA=bindUnit(101)
local placeB,optionsB=bindUnit(202)
assert(#placeA(optionsA)>=2 and #placeB(optionsB)>=2 and #placeA(optionsA)>=2)
assert(requests[1]==101 and requests[2]==202 and requests[3]==101)
assert(shownByUnit[101]>shownByUnit[202] and shownByUnit[202]>0)
print('PASS: cached planner preserves each house identity, coordinate queries and header-local engine hooks')
