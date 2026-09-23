-- Exercise the real drone spray coroutine, including chemical/tank behaviour.
for index,kind in ipairs({'depressol','tollwutox','orgyanyl','wanderlost'}) do
    local flying,sets,removes,affected,destroyed=true,0,0,0,0
    local options,thread
    unitID=7;unitDefID=index;script={}
    UnitDefs={[index]={name='air_copter_aerosol_'..kind}}
    GG={GameConfig={Aerosols={[kind]={sprayTimePerUnitInMs=300}}}}
    GG.SmokeRibbon={Set=function(id,slot,piece,o)
        assert(id==7 and slot=='aerosol' and piece==2)
        sets=sets+1;options=o;return true
    end,Remove=function() removes=removes+1 end}
    Spring={GetUnitDefID=function(id) return id==7 and index or 99 end,
        SetUnitNoSelect=function() end,DestroyUnit=function() destroyed=destroyed+1 end}
    include=function() end;piece=function(name) return name=='emitor' and 2 or 1 end
    getChemTrailTypes=function() return {wanderlost='wanderlost'} end
    getAerosolUnitDefIDs=function() return {[index]=kind} end
    getGameConfig=function() return {Aerosols={sprayRange=100}} end
    getChemTrailInfluencedTypes=function() return {[99]=true} end
    getPieceTableByNameGroups=function() return {Tank={1,2,3,4}} end
    hideT=function() end;Show=function() end;Hide=function() end
    PlaySoundByUnitDefID=function() end
    StartThread=function(fn) if fn==aerosolDeployRibbons then thread=coroutine.create(fn) end end
    Sleep=function() coroutine.yield() end
    isUnitFlying=function() return flying end
    EmitSfx=function() error('legacy aerosol CEG emitted') end
    getAllNearUnit=function() return {9} end
    foreach=function(t,fn) for _,id in ipairs(t) do fn(id) end end
    setAerosolCivilianBehaviour=function(id,t)
        assert(id==9 and t==kind);affected=affected+1;return true
    end
    dofile('scripts/air_copter_aerosolscript.lua')
    script.Create()
    local function step() local ok,err=coroutine.resume(thread);assert(ok,err) end
    step();step() -- initial wait, then first spray
    assert(sets==1 and options.groundDirected and options.direction[2]==-1)
    assert(options.motionAffected and options.windAffected)
    assert(options.colorStart[index==1 and 3 or 1]>0)
    flying=false;step() -- consume first dose, stop on landing
    assert(removes==1 and timeTank==200 and affected==1)
    flying=true;step();assert(sets==2,'spray did not restart')
    step();assert(sets==2 and timeTank==100,'repeated registration while spraying')
    step();assert(timeTank==0 and destroyed==1 and removes==2)
    assert(affected==1,'civilian affected more than once')
    -- A death during emission removes it and blocks subsequent registrations.
    timeTank=300;step();assert(sets==3)
    script.Killed(1,1);assert(removes==3)
    step();assert(sets==3,'dead drone restarted spray')
end
print('PASS: four aerosol types, downward preset, start/stop/restart, tank consumption, chemical behaviour, exhaustion, death, no CEG emissions')
