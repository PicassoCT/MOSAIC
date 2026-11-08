-- Run from the repository root with Lua 5.1. Tests the actual one-time skyline
-- calculation and selected geometry; native aircraft physics is not simulated.
local function loadIn(path, env)
    local chunk=assert(loadfile(path));setfenv(chunk,env);return chunk()
end
local function near(actual, expected, label)
    assert(math.abs(actual-expected)<1e-7,
        (label or "height")..": "..tostring(actual).." ~= "..tostring(expected))
end
local function matrix(scale,x,y,z)
    return {scale,0,0,0, 0,scale,0,0, 0,0,scale,0, x or 0,y or 0,z or 0,1}
end
local function fixture()
    local w={units={},gameRules={},removed={},frame=0,worldScans=0,pieceReads=0,modelReads=0,
        providers=0,collisionReads=0,nativeReads=0,context=nil,warnings={}}
    local e=setmetatable({GG={},gadget={}}, {__index=_G})
    e.UnitDefs={
        [1]={name="house_asian0",customParams={baseclass="Building"}},
        [2]={name="house_asian_split_1_2",customParams={house_asian_base="house_asian0"}},
        [3]={name="house_asian1",customParams={}},
        [4]={name="house_asian2",customParams={}},
        [5]={name="house_asian3",customParams={}},
        [6]={name="house_asian4",customParams={}},
        [7]={name="house_western0",customParams={}},
        [8]={name="house_arab0",customParams={}},
        [9]={name="objective_courthouse",isBuilding=true,customParams={baseclass="Building"}},
        [10]={name="house_hologram",isBuilding=true,customParams={baseclass="Abstract"}},
        [11]={name="mobile_assembly",canMove=true,customParams={baseclass="Building"}},
        [12]={name="air_building",canFly=true,customParams={baseclass="Building"}},
        [13]={name="command_icon",isBuilding=true,customParams={baseclass="Human"}},
    }
    e.gadgetHandler={IsSyncedCode=function() return true end,
        RemoveCallIn=function(_,name) w.removed[name]=true end}
    e.VFS={Include=function(path,env) return loadIn(path,env or e) end}
    local function forbidden() error("skyline calculation must not move, order, or use per-unit caches") end
    e.Spring={
        GetAllUnits=function()
            w.worldScans=w.worldScans+1
            local ids={};for id in pairs(w.units) do ids[#ids+1]=id end;table.sort(ids);return ids
        end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return not w.units[id] or w.units[id].dead end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetGameRulesParam=function(key) return w.gameRules[key] end,
        SetGameRulesParam=function(key,value,visibility)
            assert(visibility.public==true);w.gameRules[key]=value
        end,
        GetUnitRulesParam=forbidden,SetUnitRulesParam=forbidden,
        GetUnitPosition=function(id)
            local u=w.units[id];if u then return u.x,u.y,u.z,u.x,u.midY or u.y,u.z end
        end,
        GetUnitVectors=function(id)
            local u=w.units[id];return u.front or {0,0,1},u.up or {0,1,0},u.right or {-1,0,0}
        end,
        GetUnitHeight=function(id) w.modelReads=w.modelReads+1;return w.units[id].height end,
        GetUnitRadius=function(id) return w.units[id].radius end,
        GetUnitPieceInfo=function(id,piece)
            w.pieceReads=w.pieceReads+1;return w.units[id].geometry[piece]
        end,
        GetUnitPieceMatrix=function(id,piece)
            local m=w.units[id].matrices[piece];if m then return unpack(m) end
        end,
        GetUnitCollisionVolumeData=function(id)
            w.collisionReads=w.collisionReads+1
            return unpack(w.units[id].collision or {130,60,130,0,30,0})
        end,
        Echo=function(message) w.warnings[#w.warnings+1]=message end,
        GetUnitsInCylinder=forbidden,GetUnitsInRectangle=forbidden,
        SetUnitPosition=forbidden,SetUnitVelocity=forbidden,GiveOrderToUnit=forbidden,
        MoveCtrl=setmetatable({}, {__index=function() return forbidden end}),
        UnitScript={
            GetScriptEnv=function(id) return w.units[id] and w.units[id].env end,
            CallAsUnit=function(id,fn)
                local previous=w.context;w.context=id
                local result=fn();w.context=previous;return result
            end,
        },
    }
    for name,fn in pairs(e.Spring) do
        if type(fn)=="function" and (name:sub(1,3)=="Get" or name=="ValidUnitID") then
            local original=fn
            e.Spring[name]=function(...) w.nativeReads=w.nativeReads+1;return original(...) end
        end
    end
    function w:add(id,def,y,height,pieces)
        local u={def=def or 1,x=0,y=y or 0,z=0,height=height or 100,radius=0,
            geometry={},matrices={},pieces=pieces,ready=pieces~=nil,env={}}
        self.units[id]=u
        u.env.GetBuildingClearancePieces=function()
            assert(w.context==id,"provider must run in its own script context")
            w.providers=w.providers+1;return u.ready and u.pieces or nil
        end
        return u
    end
    function w:piece(id,piece,height,scale,offset)
        local u=self.units[id];u.geometry[piece]={min={-2,0,-3},max={2,height,3}}
        u.matrices[piece]=matrix(scale or 1,0,offset or 0,0)
    end
    function w:reload()
        if self.gadget then self.gadget:Shutdown() end
        self.removed={};e.gadget={}
        loadIn("luarules/gadgets/game_building_clearance.lua",e)
        self.gadget=e.gadget;self.gadget:Initialize()
        assert(not self.gadget.UnitCreated and not self.gadget.UnitFinished,
            "fixed map-wide result must not track later construction")
    end
    function w:tick(n)
        for _=1,n or 1 do
            self.frame=self.frame+1
            if not self.removed.GameFrame then self.gadget:GameFrame(self.frame) end
        end
    end
    function w:dirty(id)
        if e.GG.MarkBuildingClearanceDirty then e.GG.MarkBuildingClearanceDirty(id) end
    end
    function w:destroy(id)
        self.units[id]=nil
        if not self.removed.UnitDestroyed then self.gadget:UnitDestroyed(id) end
    end
    function w:spawnComplete() e.GG.CitySpawnComplete=true end
    w.env=e;w.bounds=loadIn("scripts/lib_building_clearance.lua",e)
    return w
end

-- Real selected geometry: import scale once, decoration, sparse selections,
-- duplicate IDs and hidden library variants.
local w=fixture()
local u=w:add(1,1,500,9000,{11,12,11,[6]=13})
w:piece(1,11,1000,.0254,30);w:piece(1,12,2000,.0254,50)
w:piece(1,13,10,1,110);w:piece(1,99,100000,1,0)
near(w.bounds.SelectedRoof(w.env.Spring,1,u.pieces),620,"selected decoration")
assert(w.pieceReads==3,"selected IDs must be deduplicated")
near(w.bounds.SelectedRoof(w.env.Spring,1,{11}),555.4,"import scale once")
u.front={0,.6,.8};u.up={0,.8,-.6};u.right={-1,0,0}
near(w.bounds.SelectedRoof(w.env.Spring,1,{13}),597.8,"world elevation and tilt")
u.front=nil;u.up=nil;u.right=nil;u.matrices[13]=nil
assert(w.bounds.SelectedRoof(w.env.Spring,1,u.pieces)==nil)
u.matrices[13]=matrix(1,0,110,0)

-- Wait for map-wide placement, then take one snapshot. Include raised civic
-- buildings and selected houses; never include holograms/mobile/abstract units.
w:add(2,9,700,80).env={}
for id=3,6 do w:add(id,id+7,10000,10000) end
w:reload();w:tick(30)
assert(w.worldScans==0 and not w.env.GG.IcarusSkylineReady)
w:spawnComplete();w:tick()
near(w.env.GG.IcarusSkylineHeight,780,"raised static roof")
assert(w.env.GG.IcarusSkylineReady and w.worldScans==1)
assert(w.modelReads==1,"procedural hidden-library models must never be measured")
assert(w.gameRules.icarus_city_roof_height==780 and w.gameRules.icarus_city_roof_ready==1)
assert(w.removed.GameFrame and w.removed.UnitDestroyed and not w.env.GG.MarkBuildingClearanceDirty)
local reads,pieces,providers,models=w.nativeReads,w.pieceReads,w.providers,w.modelReads
w:destroy(1);w:destroy(2);w:add(20,1,10000,1e9,{1});w:piece(20,1,50000)
w:dirty(20);w:tick(300)
-- Even stale references to removed callbacks do no work after freezing.
w.gadget:GameFrame();w.gadget:UnitDestroyed(20)
near(w.env.GG.IcarusSkylineHeight,780,"later destruction/construction cannot recompute")
assert(w.nativeReads==reads and w.pieceReads==pieces and w.providers==providers and w.modelReads==models)
w:reload();near(w.env.GG.IcarusSkylineHeight,780,"reload restores frozen map result")
assert(w.worldScans==1 and w.pieceReads==pieces and w.modelReads==models and w.providers==providers)
w:tick(300);assert(w.worldScans==1)

-- All eight house families/variants participate once, at four queue entries per
-- frame. The shared height stays unpublished until the complete initial pass.
w=fixture()
for id=1,8 do w:add(id,id,id*10,100000,{1});w:piece(id,1,id*5) end
w:reload();w:spawnComplete();w:tick()
assert(w.providers==4 and not w.env.GG.IcarusSkylineReady)
near(w.env.GG.IcarusSkylineHeight,0,"no partial or provisional skyline")
w:tick()
assert(w.providers==8 and w.pieceReads==8 and w.modelReads==0 and w.worldScans==1)
near(w.env.GG.IcarusSkylineHeight,120)
assert(w.env.GG.IcarusSkylineReady)

-- Delayed planning is event-driven, not polled. An enormous unselected model
-- cannot raise the skyline or cause aircraft to expire during construction.
w=fixture()
u=w:add(1,1,100,1e9,nil)
w:add(2,9,0,80).env={}
w:reload();w:spawnComplete();w:tick()
assert(not w.env.GG.IcarusSkylineReady and w.worldScans==1)
near(w.env.GG.IcarusSkylineHeight,0)
reads=w.nativeReads;providers=w.providers;models=w.modelReads
w:tick(300)
assert(w.nativeReads==reads and w.providers==providers and w.modelReads==models,
    "pending planning must wait for its event without polling")
u.ready=true;u.pieces={1};w:piece(1,1,400)
w:dirty(1);w:dirty(1);w:dirty(1);w:tick()
near(w.env.GG.IcarusSkylineHeight,500,"planned tall roof included before cosmetic reveal")
assert(w.env.GG.IcarusSkylineReady and w.pieceReads==1 and w.modelReads==1)
reads=w.nativeReads;w:dirty(1);w:tick(60);assert(w.nativeReads==reads)

-- Malformed ready geometry resolves once using the physical collision envelope,
-- rather than polling forever or measuring the huge hidden-variant model.
w=fixture();w:add(1,1,100,1e9,{999})
w:reload();w:spawnComplete();w:tick()
near(w.env.GG.IcarusSkylineHeight,160)
assert(w.env.GG.IcarusSkylineReady and w.collisionReads==1 and w.modelReads==0 and #w.warnings==1)

-- A throwing getter must not escape CallAsUnit, corrupt its active-unit context,
-- or stall every aircraft. Resolve that failed provider once through collision.
w=fixture();u=w:add(1,1,100,1e9,{1})
u.env.GetBuildingClearancePieces=function()
    assert(w.context==1);error("failed house selection provider")
end
w:reload();w:spawnComplete();w:tick()
near(w.env.GG.IcarusSkylineHeight,160)
assert(w.context==nil and w.env.GG.IcarusSkylineReady)
assert(w.collisionReads==1 and w.modelReads==0 and #w.warnings==1 and w.worldScans==1)
reads=w.nativeReads;w:tick(300);assert(w.nativeReads==reads)

-- An unresolved initial building can disappear before planning completes.
w=fixture();w:add(1,1,0,1e9,nil);w:add(2,9,0,70).env={}
w:reload();w:spawnComplete();w:tick();assert(not w.env.GG.IcarusSkylineReady)
w:destroy(1);near(w.env.GG.IcarusSkylineHeight,70);assert(w.env.GG.IcarusSkylineReady)

-- Empty city and persisted zero are valid. The saved placement flag also starts
-- the pass when the Lua-side city flag has not been restored yet.
w=fixture();w.gameRules.mosaic_city_spawn_complete=1;w:reload();w:tick()
near(w.env.GG.IcarusSkylineHeight,0)
assert(w.env.GG.IcarusSkylineReady and w.worldScans==1)
w:reload();assert(w.env.GG.IcarusSkylineReady and w.worldScans==1)
near(w.env.GG.IcarusSkylineHeight,0)

-- Missing/broken planning scripts get one bounded failure pass after sixty
-- simulation seconds. No readiness polling, hidden-model fallback or softlock.
w=fixture()
for id=1,6 do w:add(id,1,id*10,1e9,nil).env={} end
w:reload();w:spawnComplete();w:tick(2)
reads=w.nativeReads;w:tick(1798)
assert(w.nativeReads==reads and not w.env.GG.IcarusSkylineReady and w.collisionReads==0)
w:tick()
assert(w.collisionReads==4 and not w.env.GG.IcarusSkylineReady,
    "timeout fallback must retain the four-buildings-per-frame budget")
w:tick()
assert(w.env.GG.IcarusSkylineReady and w.collisionReads==6 and #w.warnings==6)
assert(w.worldScans==1 and w.modelReads==0)
near(w.env.GG.IcarusSkylineHeight,120)
reads=w.nativeReads;w:tick(1800);assert(w.nativeReads==reads)

-- Execute Luxor's actual selection/completion/getter path. Its existing helper
-- chooses shown sub/spin pieces once; clearance must retain that returned set
-- without adding another random choice or changing raid visibility lists.
local ids, names, nextID={}, {}, 0
local selectionCalls, notifications=0,0
local function noop() end
local comb=setmetatable({unitID=50,script={},GG={},include=noop,
    getGameConfig=function() return {} end,
    piece=function(name)
        if not ids[name] then nextID=nextID+1;ids[name]=nextID;names[nextID]=name end
        return ids[name]
    end,
    count=function(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end,
    StartThread=noop,Sleep=noop,Show=noop,Hide=noop,showT=noop,hideT=noop,
    SetRadiancePlaceables=noop,
    Spring={GetUnitPieceList=function() return names end,
        GetUnitPieceMap=function() return ids end,SetUnitRulesParam=noop},
}, {__index=_G})
comb.GG.MarkBuildingClearanceDirty=function(id) assert(id==50);notifications=notifications+1 end
comb.showTSubSpins=function(base)
    assert(base==ids.base2);selectionCalls=selectionCalls+1
    return {100,101}
end
loadIn("scripts/house_asian_comb_script.lua",comb)
comb.TablesOfPieceGroups={base={ids.base2},RoofTopSquare={999}}
assert(comb.GetBuildingClearancePieces()==nil,"unassembled Luxor must not expose partial geometry")
comb.buildBuilding()
assert(selectionCalls==1 and #comb.ToShowTable==3)
assert(comb.GetBuildingClearancePieces()~=nil and notifications==1,
    "completed selection must be available before cosmetic reveal")
comb.buildAnimation()
local physical=comb.GetBuildingClearancePieces()
assert(selectionCalls==1 and notifications==2 and #comb.ToShowTable==3 and #physical==5,
    "clearance must include selected extras without modifying content or visibility")
u=w:add(50,6,100,9000,physical)
w:piece(50,ids.base2,60);w:piece(50,ids.Plate,5)
w:piece(50,100,140);w:piece(50,101,80);w:piece(50,999,10000)
near(w.bounds.SelectedRoof(w.env.Spring,50,physical),240,"selected Luxor roof decoration")
comb.hideHouse()
near(w.bounds.SelectedRoof(w.env.Spring,50,comb.GetBuildingClearancePieces()),240,
    "raid presentation must retain Luxor physical clearance")

-- Every selected-house script must provide the common readiness interface and
-- notify the one-time calculation, including refugeecamp and Luxor without shadows.
for _,name in ipairs({"house_asian_script", "house_western_script", "house_arab_script",
    "house_asian_standalone_script", "house_asian_refugeecamp_script", "house_asian_comb_script"}) do
    local path="scripts/"..name..".lua"
    assert(loadfile(path))
    local f=assert(io.open(path));local source=f:read("*a");f:close()
    assert(source:find("function GetBuildingClearancePieces()",1,true),name.." missing selected geometry")
    assert(source:find("GG.MarkBuildingClearanceDirty(unitID)",1,true),name.." missing completion event")
end
print("Icarus building clearance tests passed")
