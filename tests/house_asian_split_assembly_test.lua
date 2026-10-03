-- Invoked by house_asian_split_models_test.py --runtime with Assimp piece maps.
local function loadEnv(path, env)
    local f
    if setfenv then f=assert(loadfile(path));setfenv(f,env)
    else f=assert(loadfile(path,'t',env)) end
    return f()
end
local function noop() end
local plannerEnv={VFS={Include=dofile}}
setmetatable(plannerEnv,{__index=_G})
local planner=loadEnv('scripts/lib_house_asian_split.lua',plannerEnv)
local shared={ManualRenderedBuildingWithWindowsVisiblePieces={},HouseAsianUnitPlans={}}
local fixtureByName={}
for i,fixture in ipairs(MODEL_FIXTURES) do fixture.id=i;fixtureByName[fixture.name]=fixture end
local serial=0
local function assemble(fixture,plan)
    serial=serial+1
    local pieceMap, moves, shown, dimensions = {}, {}, {}, {}
    for i,name in ipairs(fixture.pieces) do pieceMap[name]=i end
    local cp={house_asian_base='house_asian0',house_asian_style_a=fixture.styles[1],
        house_asian_style_b=fixture.styles[#fixture.styles]}
    local env={GG=shared,unitID=serial,unitDefID=fixture.id,script={},Game={mapName='test'},
        UnitDefs={[fixture.id]={customParams=cp}},x_axis=1,y_axis=2,z_axis=3}
    setmetatable(env,{__index=_G})
    env.VFS={Include=function(path)
        if path=='scripts/lib_house_asian_split.lua' then return planner end
    end}
    local function valid(id)
        assert(type(id)=='number' and fixture.pieces[id], 'invalid piece: '..tostring(id))
    end
    local function move(id,axis,amount)
        valid(id);assert(amount==amount and math.abs(amount)<math.huge,'non-finite move')
        moves[id]=moves[id] or {};moves[id][axis]=amount
    end
    env.Spring={GetUnitPieceList=function() return fixture.pieces end,
        GetUnitPieceMap=function() return pieceMap end,
        GetUnitPosition=function() return 400,0,800 end,
        GetGroundHeight=function() return 0 end,
        GetUnitPiecePosDir=function(_,id)
            valid(id);local p=moves[id] or {};return 400+(p[1] or 1),p[2] or 1,800+(p[3] or 1)
        end,
        GetUnitPieceInfo=function(_,id) valid(id);return {name=fixture.pieces[id],children={}} end,
        SetUnitNanoPieces=noop,
    }
    -- Actual grouping, random-pool, table and shared-cache helper functions.
    loadEnv('scripts/lib_OS.lua',env)
    loadEnv('scripts/lib_UnitScript.lua',env)
    loadEnv('scripts/lib_Animation.lua',env)
    env.include=function() return noop end
    env.piece=function(name) return assert(pieceMap[name], 'missing literal piece '..name) end
    env.getGameConfig=function() return {city={buildings={sizeZ=100,roofGroupCount=1},neonStreetRadius=0}} end
    env.ViewShadowGameRelevant=function() return false end
    env.isNearCityCenter=function() return false,1000 end
    env.StartThread=noop;env.Sleep=noop;env.Signal=noop
    env.Move=move;env.WMove=move;env.Turn=valid;env.WTurn=valid;env.Spin=valid
    env.WaitForMoves=noop;env.Show=function(id) valid(id);shown[id]=true end;env.Hide=valid
    env.initializeBuildingShadowVoxels=function(width,height,scale)
        assert(scale==0.0254);dimensions.width=width;dimensions.height=height
    end
    env.addShadowVoxel=noop;env.SetRadiancePlaceables=noop
    env.houseAddDestructionTable=function(t,level,id) valid(id);t[#t+1]=id;return t end
    env.startPieceOS=function(_,_,descriptor) assert(type(descriptor)=='table') end
    shared.HouseAsianUnitPlans[serial]=plan
    loadEnv('scripts/house_asian_script.lua',env)
    env.script.Create()
    -- Engine resumes buildHouse after Sleep(1); spawnUnit has now published plan.
    env.buildBuilding()
    assert(env.boolDoneShowing, 'assembly did not finish')
    assert(env.script.QueryBuildInfo()==pieceMap.center)
    local roofs=env.getRooftopPieces()
    local roofCount=0;for _,id in pairs(roofs) do valid(id);roofCount=roofCount+1 end
    local expectedRoofs=0
    for index=1,37 do
        if env.getLocationInPlan(index,env.materialColourName) then expectedRoofs=expectedRoofs+1 end
    end
    assert(roofCount==expectedRoofs,'roof incomplete for '..fixture.name..': '..roofCount..'/'..expectedRoofs)
    for _,id in pairs(env.toShowDict) do valid(id) end
    if plan and plan.group then
        local layout=planner.layout(plan)
        for _,levels in pairs(layout) do for level,slots in pairs(levels) do
            for index,name in pairs(slots) do
                local id=pieceMap[name]
                assert(env.toShowDict[id], 'coherent component not shown: '..name)
                local p=moves[id];assert(p,'coherent component not placed: '..name)
                assert(p[1]==-env.centerP.x+(index-1)*dimensions.width,'component x misplaced: '..name)
                assert(math.abs((p[2] or 0)-level*dimensions.height)<1,'component y misplaced: '..name)
            end
        end end
    end
    return env
end

-- Every pure/pair model also works with manual /give (no pre-spawn plan).
for _,fixture in ipairs(MODEL_FIXTURES) do assemble(fixture) end
local state=planner.newState()
for i=1,#planner.catalog.groups do
    local plan=planner.choose(state,i*177,i*93,'test')
    assemble(assert(fixtureByName[plan.unitName]),plan)
    planner.commit(state,plan)
end
print('PASS: real assembly with all 10 imported piece maps, all 95 coherent components, optional animations and model-specific caches')
