-- Invoked by house_asian_stacks_runtime_test.py with current-source piece trees,
-- or house_asian_split_models_test.py --runtime with Assimp piece maps.
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
local profiles=dofile('scripts/house_asian_stack_profiles.lua')
local shared={ManualRenderedBuildingWithWindowsVisiblePieces={},HouseAsianUnitPlans={}}
local fixtureByName={}
for i,fixture in ipairs(MODEL_FIXTURES) do fixture.id=i;fixtureByName[fixture.name]=fixture end
local stats={buildings=0,columns=0,requested=0,mismatched=0,shortened=0,foundationOnly=0,
    foundationOnlyPieces={},foundationOnlyGroups={},worstPlan=0,worstAssembly=0}
local serial=0
local function checkStructure(env,fixture,pieceMap,moves,turns,dimensions)
    local structure=assert(env.GetBuildingStructuralPlan(),'missing completed structural plan')
    local expected,used={},{}
    local columns=0
    for index,column in pairs(structure.columns) do
        columns=columns+1
        local x,z=(index-1)%6,math.floor((index-1)/6)
        assert(x==0 or x==5 or z==0 or z==5,'structural column outside perimeter')
        assert(column.height==#column.pieces-1,'incomplete planned column')
        assert(column.roofHeight>0,'missing planned roof height')
        if column.height==0 then
            local profile=profiles.pieces[column.pieces[1]]
            if profile and profile.max then
                assert(column.roofHeight>=profile.max[2],'roof height clips an oversized authored shopfront')
            end
        end
        if column.mismatchedFoundation then
            assert(column.mismatchRequested and column.pieces[1]~=column.originalFoundation,
                'unrequested foundation replacement')
        else
            assert(column.pieces[1]==column.originalFoundation,'unmarked foundation replacement')
        end
        for row,name in ipairs(column.pieces) do
            local id=assert(pieceMap[name],'planned piece absent from model: '..name)
            assert(not used[id],'piece used by two structural slots: '..name)
            used[id]=true
            expected[id]=row
            assert(env.toShowDict[id],'planned piece not shown: '..name)
            local position=assert(moves[id],'planned piece not moved: '..name)
            assert(position[1]==-env.centerP.x+x*dimensions.width,'column X changed between levels: '..name)
            assert(position[3]==-env.centerP.z+z*dimensions.width,'column Z changed between levels: '..name)
            assert(math.abs((position[2] or 0)-(row-1)*dimensions.height)<0.001,
                'column vertical order changed: '..name)
            local facing=assert(turns[id] and turns[id][3],'planned piece not oriented: '..name)
            local delta=(facing-math.rad(column.rotation))%(2*math.pi)
            assert(math.min(delta,2*math.pi-delta)<0.000001,
                'column facing changed between levels: '..name)
        end
    end
    assert(columns>0,'empty structural plan')
    -- Check the actual damage registration too: showing all planned pieces
    -- would not detect an extra independently selected foundation beneath them.
    for level,pieces in pairs(env.LevelPieces) do
        if type(level)=='number' then
            for _,id in ipairs(pieces) do
                if expected[id] then
                    assert(expected[id]==level,'damage registration disagrees with structural level')
                    expected[id]=nil
                else
                    -- Roof decorations replace their slot's public rooftop
                    -- entry, while the underlying cap stays registered. Check
                    -- that cap's actual height and facing instead of trusting
                    -- the overwritten rooftop list.
                    local name=fixture.pieces[id]
                    assert(name:lower():find('roof',1,true),'unplanned structural piece: '..name)
                    local position=assert(moves[id],'registered roof not placed: '..name)
                    local x=(position[1]+env.centerP.x)/dimensions.width
                    local z=(position[3]+env.centerP.z)/dimensions.width
                    local column=assert(structure.columns[1+x+z*6],'roof has no supporting column')
                    assert(level==math.ceil(column.roofHeight/dimensions.height)+1,
                        'roof damage level ignores actual roof height')
                    assert(math.abs(position[2]-(column.roofHeight-0.5))<0.001,
                        'roof placement ignores a short or oversized column')
                    local delta=(turns[id][3]-math.rad(column.rotation))%(2*math.pi)
                    assert(math.min(delta,2*math.pi-delta)<0.000001,'roof facing differs from its column')
                end
            end
        end
    end
    assert(next(expected)==nil,'planned structural piece missing from damage registration')
    return structure
end

local function assemble(fixture,plan)
    local started=os.clock()
    serial=serial+1
    local pieceMap, moves, turns, shown, dimensions = {}, {}, {}, {}, {}
    for i,name in ipairs(fixture.pieces) do pieceMap[name]=i end
    local cp=fixture.legacy and {} or {house_asian_base='house_asian0',house_asian_style_a=fixture.styles[1],
        house_asian_style_b=fixture.styles[#fixture.styles]}
    local env={GG=shared,unitID=serial,unitDefID=fixture.id,script={},Game={mapName='test'},
        UnitDefs={[fixture.id]={customParams=cp}},x_axis=1,y_axis=2,z_axis=3}
    setmetatable(env,{__index=_G})
    env._G=env
    env.VFS={Include=function(path,scope)
        if path=='scripts/lib_house_asian_split.lua' then return planner end
        local result=loadEnv(path,scope or env)
        if path=='scripts/lib_house_asian_stacks.lua' then
            local plan=result.plan
            result.plan=function(options)
                local start=os.clock()
                local structure=plan(options)
                stats.worstPlan=math.max(stats.worstPlan,os.clock()-start)
                stats.buildings=stats.buildings+1
                for _,column in pairs(structure.columns) do
                    stats.columns=stats.columns+1
                    if column.mismatchRequested then stats.requested=stats.requested+1 end
                    if column.mismatchedFoundation then stats.mismatched=stats.mismatched+1 end
                    if column.height<options.height then stats.shortened=stats.shortened+1 end
                    if column.height==0 then
                        stats.foundationOnly=stats.foundationOnly+1
                        local name=column.pieces[1]
                        stats.foundationOnlyPieces[name]=(stats.foundationOnlyPieces[name] or 0)+1
                        local group=options.featured and options.featured.id or '(none)'
                        stats.foundationOnlyGroups[group]=(stats.foundationOnlyGroups[group] or 0)+1
                    end
                end
                return structure
            end
        end
        return result
    end}
    local function valid(id)
        assert(type(id)=='number' and fixture.pieces[id], 'invalid piece: '..tostring(id))
    end
    local function move(id,axis,amount)
        valid(id);assert(amount==amount and math.abs(amount)<math.huge,'non-finite move')
        moves[id]=moves[id] or {};moves[id][axis]=amount
    end
    local function turn(id,axis,amount)
        valid(id);assert(amount==amount and math.abs(amount)<math.huge,'non-finite turn')
        turns[id]=turns[id] or {};turns[id][axis]=amount
    end
    env.Spring={GetUnitPieceList=function() return fixture.pieces end,
        GetUnitPieceMap=function() return pieceMap end,
        GetUnitPosition=function() return 400,0,800 end,
        GetGroundHeight=function() return 0 end,
        GetUnitPiecePosDir=function(_,id)
            valid(id);local p=moves[id] or {};return 400+(p[1] or 1),p[2] or 1,800+(p[3] or 1)
        end,
        GetUnitPieceInfo=function(_,id)
            valid(id)
            return {name=fixture.pieces[id],children=fixture.children and fixture.children[fixture.pieces[id]] or {}}
        end,
        SetUnitNanoPieces=noop,
        SetUnitRulesParam=noop,
    }
    -- Actual grouping, random-pool, table and shared-cache helper functions.
    loadEnv('scripts/lib_OS.lua',env)
    loadEnv('scripts/lib_UnitScript.lua',env)
    loadEnv('scripts/lib_Animation.lua',env)
    env.include=function(name)
        if name == 'lib_building_damage.lua' or name == 'lib_house_asian_animations.lua' then
            return loadEnv('scripts/'..name,env)
        end
        return noop
    end
    env.piece=function(name) return assert(pieceMap[name], 'missing literal piece '..name) end
    env.getGameConfig=function() return {city={buildings={sizeZ=100,roofGroupCount=1},neonStreetRadius=0}} end
    -- Legacy /give lacks the pre-spawn style plan; use a fixed neighbourhood
    -- style so each fixture can exercise this path independently of the city.
    env.getBuildingTypeHash=function() return fixture.legacyStyle or 4,400,0,800 end
    env.ViewShadowGameRelevant=function() return false end
    env.isNearCityCenter=function() return false,1000 end
    env.StartThread=noop;env.Sleep=noop;env.Signal=noop
    env.Move=move;env.WMove=move;env.Turn=turn;env.WTurn=turn;env.Spin=valid
    env.WaitForMoves=noop;env.Show=function(id) valid(id);shown[id]=true end;env.Hide=valid
    env.Spring.UnitScript={Show=env.Show,Hide=env.Hide,Move=move,Turn=turn,Spin=valid,
        GetPieceTranslation=function(id)
            valid(id);local p=moves[id] or {};return p[1] or 0,p[2] or 0,p[3] or 0
        end,
        GetPieceRotation=function(id)
            valid(id);local p=turns[id] or {};return p[1] or 0,p[2] or 0,p[3] or 0
        end,
    }
    env.initializeBuildingShadowVoxels=function(width,height,scale)
        assert(scale==0.0254);dimensions.width=width;dimensions.height=height
    end
    env.addShadowVoxel=noop;env.SetRadiancePlaceables=noop
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
    local structure=checkStructure(env,fixture,pieceMap,moves,turns,dimensions)
    if plan and plan.group then
        local layout=planner.layout(plan)
        local function canonical(name)
            return (name:lower():gsub('_(%d)','%1')
                :gsub('%d+',function(n) return tostring(tonumber(n)) end))
        end
        local aliases={}
        for name,id in pairs(pieceMap) do
            local key=canonical(name)
            if aliases[key]==nil then aliases[key]=id else aliases[key]=false end
        end
        for _,levels in pairs(layout) do for level,slots in pairs(levels) do
            for index,name in pairs(slots) do
                local id=pieceMap[name] or aliases[canonical(name)]
                if level==0 and structure.columns[index].mismatchedFoundation then
                    id=pieceMap[structure.columns[index].pieces[1]]
                end
                assert(id,'featured component cannot be resolved: '..name)
                assert(env.toShowDict[id], 'coherent component not shown: '..name)
                local p=moves[id];assert(p,'coherent component not placed: '..name)
                assert(p[1]==-env.centerP.x+(index-1)*dimensions.width,'component x misplaced: '..name)
                assert(math.abs((p[2] or 0)-level*dimensions.height)<1,'component y misplaced: '..name)
            end
        end end
    end
    stats.worstAssembly=math.max(stats.worstAssembly,os.clock()-started)
    return env
end

-- Every pure/pair model also works with manual /give (no pre-spawn plan).
for _,fixture in ipairs(MODEL_FIXTURES) do
    if fixture.legacy then
        for style=1,4 do fixture.legacyStyle=style;assemble(fixture) end
    else
        assemble(fixture)
    end
end
local state=planner.newState()
for i=1,#planner.catalog.groups do
    local plan=planner.choose(state,i*177,i*93,'test')
    assemble(assert(fixtureByName[plan.unitName]),plan)
    planner.commit(state,plan)
end
print('PASS: real assembly, complete structural plans, registered supports, stable column rotations, deliberate foundation exceptions and featured components')
print(string.format('Assembly stats: %d buildings, %d columns; mismatch draws %d, applied %d; shortened %d, foundation-only %d; max planner %.4fs, assembly %.4fs',
    stats.buildings,stats.columns,stats.requested,stats.mismatched,stats.shortened,stats.foundationOnly,
    stats.worstPlan,stats.worstAssembly))
return stats
