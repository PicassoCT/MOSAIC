-- Run from the repository root with Lua 5.1+. The returned fixture is also used
-- by standalone_building_shadows_gpu.py to render these exact protocol inputs.
local function read(path)
    local f=assert(io.open(path));local s=f:read('*a');f:close();return s
end
local function environment(t) return setmetatable(t or {},{__index=_G}) end
local function run(source,env)
    local f
    if setfenv then f=assert(loadstring(source));setfenv(f,env)
    else f=assert(load(source,'standalone shadow test','t',env)) end
    return f()
end
local function loadIn(path,env) return run(read(path),env) end
local function noop() end
local function near(a,b,label)
    assert(math.abs(a-b)<1e-7,(label or 'coordinate')..': '..tostring(a)..' ~= '..tostring(b))
end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function foreach(t,fn)
    local out={};for _,v in pairs(t) do local r=fn(v);if r~=nil then out[#out+1]=r end end;return out
end
local function include(path,env) return loadIn(path,env or environment()) end

-- Read the real unit definitions, including their absence of a throwsShadow
-- flag. Internal engine names come from the definition keys, not display names.
local class={};function class:New(t) return setmetatable(t or {},{__index=self}) end
local authored=loadIn('units/neutral/house_asian_standalone.lua',environment({
    Building=class,lowerkeys=function(t) return t end,
}))
local defs={}
for i=1,4 do
    local name='house_asian'..i;local d=assert(authored[name])
    defs[i]={id=i,name=name,customParams=d.customparams,script=d.script}
end
defs[5]={name='house_arab0',customParams={throwsShadow=true}}
defs[6]={name='house_western_variant',customParams={throwsshadow='true'}}
defs[7]={name='unmarked_house',customParams={throwsShadow=false}}
defs[8]={name='civilian_arab0',customParams={}}
local config=loadIn('scripts/lib_mosaic.lua',environment({MOSAIC_CONFIG_ONLY=true,VFS={Include=include}}))
local profiles=assert(config.getBuildingRadianceShadowTypeTable)(defs)
assert(profiles[1].kind=='solid' and profiles[3].kind=='solid')
assert(profiles[5].kind=='columns' and profiles[6].kind=='columns')
assert(not profiles[2] and not profiles[4] and not profiles[7] and not profiles[8])
assert(not defs[1].customParams.throwsShadow and not defs[3].customParams.throwsShadow)

local identity={1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
local pieceInfo={
    [10]={min={-8,-4,0},max={24,12,20}},
    [20]={min={0,0,0},max={32,40,32}},
    [11]={min={-500,-500,-500},max={500,500,500}},
    [21]={min={-500,-500,-500},max={500,500,500}},
    [30]={min={-10000,-10000,-10000},max={10000,10000,10000}},
    [40]={min={-20000,-20000,-20000},max={20000,20000,20000}},
    [99]={min={-100000,0,-80000},max={100000,80,80000}},
}
local pieceMatrix={
    -- Imported/pitched nonuniform basis: x'=2x+32, y'=4z+8, z'=-3y+16.
    -- The solid is therefore x=[16,80], y=[8,88], z=[-20,28].
    [10]={2,0,0,0, 0,0,-3,0, 0,4,0,0, 32,8,16,1},
    [20]={1,0,0,0, 0,1,0,0, 0,0,1,0, 112,16,-20,1},
}
local unpackValues=unpack or table.unpack
local helper=environment({Spring={
    GetUnitPieceInfo=function(_,id) return pieceInfo[id] end,
    GetUnitPieceMatrix=function(_,id) return unpackValues(pieceMatrix[id] or identity) end,
}})
loadIn('scripts/lib_building_solid_shadow.lua',helper)
local function bounds(grid)
    local nx,nz=#grid.columns,#grid.columns[1]
    local y=grid.baseHeights and grid.baseHeights[1][1] or 0
    return {grid.originX-grid.cellSize*.5,y,grid.originZ-grid.cellSize*.5,
        grid.originX+(nx-.5)*grid.cellSize,y+grid.levelHeight,
        grid.originZ+(nz-.5)*grid.cellSize}
end
local function checkBounds(grid,wanted)
    local b=bounds(grid);for i=1,6 do near(b[i],wanted[i],'solid bound '..i) end
    for _,row in ipairs(grid.columns) do for _,level in ipairs(row) do assert(level==1) end end
end
local single=assert(helper.BuildSolidBuildingShadowColumns(42,{10,10},profiles[1]))
assert(#single.columns==4 and #single.columns[1]==3)
checkBounds(single,{16,8,-20,80,88,28})
local dual=assert(helper.BuildSolidBuildingShadowColumns(42,{10,20},profiles[1]))
checkBounds(dual,{16,8,-20,144,88,28})
local huge=assert(helper.BuildSolidBuildingShadowColumns(42,{99},profiles[1]))
assert(#huge.columns*#huge.columns[1]<=profiles[1].maxCells,'solid geometry exceeded its transport budget')
local hb=bounds(huge)
assert(hb[1]<=-100000 and hb[4]>=100000 and hb[3]<=-80000 and hb[6]>=80000)
near(hb[2],0);near(hb[5],80)
assert(not helper.BuildSolidBuildingShadowColumns(42,{},profiles[1]))

-- Complete script -> synced gadget -> unsynced bridge -> production LuaUI
-- occupancy. Only engine APIs/content helpers unrelated to shadows are mocked.
local units,matrixReads,vertices,messages,actions={},{},{},{},{}
local spring={
    ValidUnitID=function(id) return units[id]~=nil end,
    GetUnitIsDead=function(id) return not units[id] or units[id].dead==true end,
    GetUnitDefID=function(id) return units[id] and units[id].def end,
    GetUnitBasePosition=function(id) local u=units[id];return u.x,u.y,u.z end,
    GetUnitPosition=function(id) local u=units[id];return u.x,u.y,u.z end,
    GetUnitVectors=function(id) local u=units[id];return u.front,{0,1,0},u.right end,
    GetUnitHealth=function(id) return 1000,1000,0,0,units[id].built end,
    GetUnitPieceInfo=function(_,id) return assert(pieceInfo[id]) end,
    GetUnitPieceMatrix=function(id,piece)
        assert(piece==10 or piece==20,'hidden model or decorative piece enlarged the solid blocker')
        matrixReads[id]=(matrixReads[id] or 0)+1
        return unpackValues(assert(pieceMatrix[piece]))
    end,
    GetGaiaTeamID=function() return 0 end,SetUnitTooltip=noop,Echo=noop,
    SetUnitRulesParam=noop,
    GetUnitPieceList=function() return {[10]='Arcology1',[11]='Arcology2',
        [20]='Project1',[21]='Project2',[30]='Arcology1Spinner1',[40]='Placeable42'} end,
    GetUnitPieceMap=function() return {} end,
}
local gl= setmetatable({GetViewSizes=function() return 512,512 end,
    Vertex=function(x,y,z) vertices[#vertices+1]={x,y,z} end,
    BeginEnd=function(_,fn,...) fn(...) end,
},{__index=function() return noop end})
local uiEnv=environment({widget={},gl=gl,Spring=spring,
    GL={QUADS=7,PROJECTION=0x1701,MODELVIEW=0x1700,COLOR_BUFFER_BIT=0x4000},
    Game={mapSizeX=512,mapSizeZ=512},VFS={Include=include}})
local ui=run(read('luaui/widgets_mosaic/gfx_neonlights_radiancecascade.lua')..[[
return {begin=receiveBuildingShadowBegin,add=receiveBuildingShadowColumn,
    finish=receiveBuildingShadowEnd,remove=receiveBuildingShadowRemove,
    buildings=occlusionBuildings,layer=drawOcclusionLayer}
]],uiEnv)
local luaUI=setmetatable({ReceiveBuildingShadowColumnsBegin=ui.begin,
    ReceiveBuildingShadowColumn=ui.add,ReceiveBuildingShadowColumnsEnd=ui.finish,
    ReceiveBuildingShadowColumnsRemove=ui.remove},{__call=function(t,k) return t[k]~=nil end})
local bridge=environment({gadget={},Script={LuaUI=luaUI},gadgetHandler={
    IsSyncedCode=function() return false end,
    AddSyncAction=function(_,key,fn) actions[key]=fn end,
    RemoveSyncAction=function(_,key) actions[key]=nil end,
}})
local gadgetSource=read('luarules/gadgets/gfx_building_shadow_volumes.lua')
run(gadgetSource,bridge);bridge.gadget:Initialize()
spring.UnitScript={GetScriptEnv=function(id) return units[id] and units[id].env end,
    CallAsUnit=function(_,fn) return fn() end}
local synced=environment({gadget={},GG={},Spring=spring,UnitDefs=defs,VFS={Include=include},
    gadgetHandler={IsSyncedCode=function() return true end},SendToUnsynced=function(name,...)
        for _,v in ipairs({...}) do assert(type(v)~='table','table crossed sync boundary') end
        messages[#messages+1]=name;assert(actions[name])(nil,...)
    end,
})
run(gadgetSource,synced);synced.gadget:Initialize()
local function flush() messages={};synced.gadget:GameFrame();return #messages end
local groups={Arcology={10,11},Project={20,21}}
local function create(id,def,dualModel,built)
    local u={def=def,x=224,y=0,z=144,front={0,0,1},right={-1,0,0},built=built or 1}
    units[id]=u;matrixReads[id]=0
    synced.GG.GlobalPieceCounterArcology={[10]=0,[11]=100,[20]=0,[21]=100}
    local env=environment({unitID=id,unitDefID=def,UnitDefs=defs,Spring=spring,
        GG=synced.GG,script={},Game={},piece=function() return -1 end,
        getGameConfig=function() return {city={buildings={maxMegaBuildings=12}}} end,
        getPieceTableByNameGroups=function() return groups end,
        count=count,foreach=foreach,getNthDictElement=function(t,n) return n,t[n] end,
        StartThread=noop,Show=noop,Hide=noop,showT=noop,hideT=noop,hideAll=noop,
        SetRadiancePlaceables=noop,showTSubSubSpins=function() return {30,40} end,
        showTSubSpins=function() return {30,40} end,
        ViewShadowGameRelevant=function() return false end,
        isNearCityCenter=function() return false end,
        isMapControlledBuildingPlacement=function() return false end,
        getDeterministicStationaryUnitHash=function() return 0 end,
        getDetermenisticMapHash=function() return 0 end,
        randChance=function() return dualModel or false end,
    })
    env.include=function(name)
        if name=='lib_mosaic.lua' then
            for key,value in pairs(config) do env[key]=value end
        elseif name=='lib_building_solid_shadow.lua' then loadIn('scripts/'..name,env) end
    end
    env.Sleep=function() assert(#env.GetBuildingShadowColumns().columns==0,'unfinished model blocked light') end
    loadIn('scripts/house_asian_standalone_script.lua',env);u.env=env
    assert(#env.GetBuildingShadowColumns().columns==0)
    env.script.Create();assert(#env.GetBuildingShadowColumns().columns==0)
    env.buildBuilding()
    return env
end

local primary=create(42,1,false,.5)
assert(matrixReads[42]==1,'selection did not use only its actual main body')
assert(#primary.GetBuildingShadowColumns().columns==0)
flush();assert(not ui.buildings[42],'unfinished engine build became a blocker')
units[42].built=1;synced.gadget:UnitFinished(42,1)
assert(flush()==14,'completed single body did not transfer exactly 12 columns')
local cached=primary.GetBuildingShadowColumns()
checkBounds(cached,{16,8,-20,80,88,28})
assert(ui.buildings[42] and #ui.buildings[42].columns==48)
for _=1,10 do assert(primary.GetBuildingShadowColumns()==cached) end
assert(matrixReads[42]==1,'cache polled model geometry again')

local function projectedBounds(layer)
    vertices={};ui.layer(layer)
    if #vertices==0 then return nil end
    local x0,z0,x1,z1=math.huge,math.huge,-math.huge,-math.huge
    for _,v in ipairs(vertices) do x0=math.min(x0,v[1]);z0=math.min(z0,v[2]);x1=math.max(x1,v[1]);z1=math.max(z1,v[2]) end
    return {x0,z0,x1,z1}
end
local function checkProjection(wanted)
    local actual=assert(projectedBounds(0))
    for i=1,4 do near(actual[i],wanted[i],'world footprint '..i) end
end
checkProjection({240,124,304,172})
assert(not projectedBounds(1),'solid below 88 blocked the 128..256 height band')
local function pose(turned,y)
    local u=units[42];u.y=y or 0
    u.front=turned and {1,0,0} or {0,0,1}
    u.right=turned and {0,0,1} or {-1,0,0}
    synced.GG.MarkBuildingShadowVolumeDirty(42);flush()
end
pose(true);checkProjection({204,64,252,128});assert(matrixReads[42]==1)
pose(false,160);assert(not projectedBounds(0) and projectedBounds(1),'unit base height was dropped')
pose(false)

-- Raid presentation hides pieces briefly; the physical body remains present.
primary.hideHouse();assert(primary.GetBuildingShadowColumns()==cached)
assert(flush()==0 and matrixReads[42]==1 and ui.buildings[42])
checkProjection({240,124,304,172})
primary.showHouse();assert(primary.GetBuildingShadowColumns()==cached)
assert(flush()==0 and matrixReads[42]==1)

local mixed=create(43,1,true)
checkBounds(mixed.GetBuildingShadowColumns(),{16,8,-20,144,88,28})
assert(matrixReads[43]==2,'dual main bodies were lost or decorations were included')
flush();assert(#ui.buildings[43].columns==96)
synced.gadget:UnitDestroyed(43);units[43]=nil;assert(not ui.buildings[43])
local project=create(44,3,false)
checkBounds(project.GetBuildingShadowColumns(),{112,16,-20,144,56,12})
flush();assert(ui.buildings[44],'Project definition was excluded by the old throwsShadow gate')
synced.gadget:UnitDestroyed(44);units[44]=nil

primary.script.Killed(1,1)
assert(#primary.GetBuildingShadowColumns().columns==0)
flush();assert(not ui.buildings[42],'killed standalone left a ghost blocker')
synced.GG.MarkBuildingShadowVolumeDirty(42);synced.gadget:UnitDestroyed(42)
assert(flush()==0 and not ui.buildings[42],'pending rebuild resurrected a destroyed blocker')
primary=create(42,1,false);flush();assert(ui.buildings[42],'reused unit ID failed to acquire fresh geometry')
print('PASS: actual standalone definitions and selection, imported bounds, bounded solid grid, dual models, compact protocol, rotation/height, construction, raid visibility, cache and destruction')

return {
    setGL=function(api) uiEnv.gl=api end,
    layer=ui.layer,pose=pose,
    hide=function() primary.hideHouse();flush() end,
    show=function() primary.showHouse();flush() end,
    destroy=function() primary.script.Killed(1,1);flush();synced.gadget:UnitDestroyed(42) end,
    count=function() return count(ui.buildings) end,
}
