-- Run from repository root: lua5.1 tests/cinder_flame_budget_test.lua
-- 100 simultaneously firing Cinders must not scale collision/ribbon work x100.
unpack=unpack or table.unpack
local frame=100
local traceCalls,guardCalls,fanCalls,liteCalls,sliceCalls=0,0,0,0,0
local active=true
local icon=false
local inView=true
local ruleCalls=0
local dirs={}
local function guard()
    return {near={2,2,2,2},far={2,2,2,2},pad=9}
end
local collision={
    Trace=function()
        traceCalls=traceCalls+1
        return {distance=175,kind=nil}
    end,
    Guard=function()
        guardCalls=guardCalls+1
        return guard()
    end,
    FanGuard=function()
        fanCalls=fanCalls+1
        return guard()
    end,
    SliceGuard=function()
        sliceCalls=sliceCalls+1
        return guard()
    end,
    Lite=function()
        liteCalls=liteCalls+1
        return 175,guard()
    end,
}
local spring={
    GetGameFrame=function() return frame end,
    GetUnitRulesParam=function(id,key)
        ruleCalls=ruleCalls+1
        assert(key=='mosaic_pyro_fire_until')
        return active and frame+10 or 0
    end,
    GetUnitViewPosition=function(id) return id*10,20,0 end,
    GetUnitPosition=function(id) return id*10,20,0 end,
    IsUnitIcon=function() return icon end,
    IsSphereInView=function() return inView end,
    GetSpectatingState=function() return false,false end,
    GetMyAllyTeamID=function() return 0 end,
}
local Budget=assert(dofile('luaui/widgets_mosaic/include/pyro_flame_budget.lua'))(spring,collision)
local records={}
for i=1,100 do records[i]={} end
local drawCount,totalLights,totalRibbons=0,0,0
local function collect(other)
    drawCount=drawCount+1
    totalLights,totalRibbons=0,0
    local extras={}
    local env={
        simFrame=frame,frame=frame+.25,cx=0,cy=25,cz=0,
        otherRibbons=other or 0,extraFlames=extras,brightness=1.3,
        unitVisible=function() return true end,
        origin=function(id) return id*10,20,0,-1,0,0 end,
        flame=function(x,y,z,_,seed,_,_,_,_,opacity)
            return {x=x,y=y,z=z,seed=seed,opacity=opacity}
        end,
        add=function(x,y,z,radius,color,strength,nightOnly,ribbon)
            assert(not nightOnly and radius<=62,'unbounded Cinder light')
            totalLights=totalLights+1
            if ribbon then totalRibbons=totalRibbons+1 end
        end,
    }
    Budget.Collect(records,env)
    totalRibbons=totalRibbons+#extras
    return Budget.lastStats
end
local previousTrace=0
for i=1,20 do
    local stats=collect()
    assert(stats.candidateCount==100,'nearby Cinders vanished from discovery')
    assert(stats.detailed<=8 and stats.simplified<=16 and stats.selected<=24,
        'unbounded Cinder detail/LOD population')
    assert(stats.tracesThisFrame<=2 and stats.liteThisFrame<=4,
        'global per-sim-frame collision sampling budget exceeded')
    assert(totalRibbons<=48 and totalLights<=32,
        'ribbon/light renderer exceeded fixed total budget')
    if i==1 then
        local before=traceCalls
        collect()
        assert(traceCalls==before,'multiple camera draws retraced geometry in one sim frame')
    end
    previousTrace=traceCalls
    frame=frame+1
end
assert(traceCalls<=40 and guardCalls==traceCalls,
    'high-detail sampling was not bounded and reused across ribbons')
assert(liteCalls<=80,'simplified sampling exceeded shared budget')
assert(sliceCalls>0 and sliceCalls<=120,
    'side tongues did not reuse cached terrain rather than querying again')
assert(fanCalls==0,'unobstructed flames unnecessarily sampled impact ground')
assert(traceCalls>0 and liteCalls>0,'both detail tiers must receive update slots')
-- Existing game effects eat into the *shared* budget before any Cinder
-- rays/ribbons are produced. Their own fire remains higher priority.
local before=traceCalls
local zero=collect(64)
assert(zero.selected==0 and traceCalls==before and totalRibbons==0,
    'pyro collision work ran with no global FlamePainter capacity')
local partial=collect(32)
assert(partial.selected<=24 and totalRibbons<=32,
    'shared renderer capacity was exceeded with ordinary fires present')
-- Check cooldown: turning all Cinders into icons must skip work entirely.
icon=true;frame=frame+1
before=traceCalls
local hidden=collect()
assert(hidden.candidateCount==0 and hidden.selected==0 and traceCalls==before,
    'icon Cinders consumed collision work')
icon=false;inView=false;frame=frame+1
local outside=collect()
assert(outside.selected==0,'offscreen Cinders consumed ribbon budget')
inView=true;active=false;frame=frame+1
local idle=collect()
assert(idle.selected==0,'idle walkers entered collision budget')
print('PASS: 100 firing Cinders share 8 detailed + 16 simplified LOD, 2 ray/4 lite samples per frame, cached terrain, and 48 ribbons')
