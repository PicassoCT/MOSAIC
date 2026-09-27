-- Run from the repository root with Lua 5.1/LuaJIT.
local function loadIn(path, env)
    local chunk=assert(loadfile(path)); setfenv(chunk,env); return chunk()
end
local function unit(scriptName)
    local pieces,names,shown,emitting,smoke={},{},{},{},{}
    local env=setmetatable({unitID=42,unitDefID=1,script={},x_axis=1,y_axis=2,z_axis=3,
        UnitDefs={},Game={},GG={},math=math}, {__index=_G})
    env.piece=function(name)
        if not pieces[name] then local id=#names+1;pieces[name]=id;names[id]=name end
        return pieces[name]
    end
    env.Show=function(p) shown[p]=true end
    env.Hide=function(p) shown[p]=false end
    env.showT=function(t) for _,p in pairs(t or {}) do env.Show(p) end end
    env.hideT=function(t) for _,p in pairs(t or {}) do env.Hide(p) end end
    env.Sleep=coroutine.yield
    for _,name in ipairs({'StartThread','Move','Turn','WMove','WTurn','Spin','moveT','setFireState'}) do env[name]=function() end end
    env.foreach=function(t,fn) for _,v in pairs(t) do fn(v) end end
    env.getGameConfig=function() return {instance={culture='international'}} end
    env.getCultureUnitModelNames_Dict_DefIDName=function() return {} end
    env.getDayTime=function() return 0,0,0,0 end
    env.getObjectiveAboveGroundOffset=function() return 0 end
    env.isPieceAboveGround=function() return false end
    local groups={SigLightOn={env.piece('SigLightOn001'),env.piece('SigLightOn002')},
        SigLightOff={env.piece('SigLightOff001'),env.piece('SigLightOff002')},Container={},
        BlinkyLight={env.piece('BlinkyLight01'),env.piece('BlinkyLight002')},Plane={},Gun={}}
    env.getPieceTableByNameGroups=function() return groups end
    env.Spring={SetUnitBlocking=function() end,GetGaiaTeamID=function() return 0 end,
        GetUnitPieceList=function() return names end,GetUnitPieceMap=function() return pieces end,
        GetUnitPieceInfo=function() return {min={-100,-20,-10},max={100,20,10}} end,
        Echo=function(message) error(message) end}
    env.GG.SetObjectiveRadiancePieceVisible=function(_,p,visible,mode,preset)
        emitting[p]=visible and {mode=mode or 'diffuse',preset=preset} or nil
    end
    env.GG.SmokeRibbon={Set=function(_,slot,p,options) smoke[slot]={piece=p,options=options};return true end,
        Remove=function(_,slot) smoke[slot]=nil end}
    env.include=function(name)
        if name=='lib_radiance_emitters.lua' or name=='lib_objective_ribbon_flames.lua' then
            return loadIn('scripts/'..name,env)
        end
    end
    loadIn('scripts/'..scriptName,env)
    return env,emitting,shown,groups,smoke
end
local function resume(co,...)
    local ok,delay=coroutine.resume(co,...);assert(ok,delay);return delay
end
local e,lights,shown,groups=unit('refugeecampscript.lua')
e.script.Create()
local p=groups.SigLightOn[1]
assert(not lights[p] and not shown[p])
local co=coroutine.create(e.AnimationTest)
assert(resume(co)==1000 and not lights[p])
assert(resume(co)==2000 and lights[p] and shown[p])
assert(resume(co)==1000 and not lights[p] and not shown[p])

e,lights,shown=unit('objectiveArtificalGlacierScript.lua')
p=e.piece('Logo');co=coroutine.create(e.flickerScript)
assert(resume(co,{p},function() return true end,0,30,2)==500 and not lights[p])
assert(resume(co)==40 and lights[p] and shown[p])
for i=1,76 do resume(co);assert((lights[p]~=nil)==(shown[p]==true),'logo visibility/emission diverged') end

local smoke
e,lights,shown,groups,smoke=unit('objectiveGeoEngineeringScript.lua')
e.script.Create()
local plume=assert(smoke['objective-sulfur']).options
assert(plume.length/plume.width>100 and plume.colorStart[1]>plume.colorStart[3]*2)
assert(plume.colorEnd[4]==0 and plume.emission[1]==0 and plume.windAffected)
assert(plume.directionSpace=='piece' and plume.rootOffset[1]>100,'outlet remained inside blimp')
co=coroutine.create(e.blinkLights);resume(co)
assert(not lights[groups.BlinkyLight[1]] and lights[groups.BlinkyLight[2]])
resume(co);assert(lights[groups.BlinkyLight[1]] and not lights[groups.BlinkyLight[2]])
assert(next(shown)==nil,'rotation-based blinking hid the mesh')
e.script.Killed();assert(next(smoke)==nil,'dead station retained plume')

e,lights=unit('objective_oilrigscript.lua');e.script.Create()
assert(lights[e.center].mode=='material','oil rig did not use its illumination mask')
e,lights=unit('objectivecombatoutpostscript.lua');e.script.Create()
assert(lights[e.piece('CombatOutPost')].preset=='outpost_roof')
e,lights=unit('objectivetransrapidscript.lua')
e.isStationVisible=function() return true,0 end
p=e.piece('EndPoint1');e.deployTrack(0,0,e.rail1,{},e.sub1,p)
assert(lights[p].mode=='material','visible station has no masked emission')
e.isStationVisible=function() return false,0 end
e.deployTrack(0,0,e.rail1,{},e.sub1,p);assert(not lights[p],'hidden station still emitted')

local root,child,trash=e.piece('Placeable003'),e.piece('Placeable003Sub1'),e.piece('SimCan1')
e.SetRadiancePlaceables({root,child,trash},true)
assert(lights[root].preset=='placeable:'..root and lights[child].preset==lights[root].preset)
assert(not lights[trash],'unselected simulation debris was registered')
e.SetRadiancePlaceables({root,child},false);assert(not lights[root] and not lights[child])
print('PASS: production objective blink/flicker events, masked oil/station light, roof lamp, sulfur outlet/death and placeable visibility')

-- Airport aircraft remain animated, but only ground lights enter radiance.
e,lights,shown,groups=unit('objectiveAirportscript.lua')
groups.Shuttle={};groups.Gateway={};groups.AirCar={};groups.SwingCenter={1,2}
groups.SwitchLight={e.piece('SwitchLight1')}
groups.SignalLightOn={e.piece('SignalLightOn1'),e.piece('SignalLightOn2')}
groups.SignalLightOff={e.piece('SignalLightOff1'),e.piece('SignalLightOff2')}
e.hideAll=function() end;e.StopSpin=function() end
e.script.Create()
co=coroutine.create(e.blink);resume(co)
local runway=groups.SwitchLight[1];assert(lights[runway],'runway light lost its radiance')
e.boolCircling=true;co=coroutine.create(e.PlaneLights)
resume(co);assert(shown[groups.SignalLightOn[1]] and not lights[groups.SignalLightOn[1]])
resume(co);assert(shown[groups.SignalLightOn[2]] and not lights[groups.SignalLightOn[2]])
e.boolCircling=false;resume(co)
assert(not shown[groups.SignalLightOn[2]],'plane light failed to switch off')
co=coroutine.create(e.showThruster);resume(co,1,500,false);resume(co)
for id in pairs(lights) do assert(id==runway,'airborne airport emitter illuminated the ground') end
assert(lights[runway],'aircraft cleanup removed runway emission')
print('PASS: airport runway still emits; giant-plane navigation and scramjet effects never enter ground radiance')

local scale=1
local sourceEnv=setmetatable({Spring={
    GetUnitDefID=function(id) return id end,
    GetUnitPieceInfo=function() return {min={-20,-10,-5},max={20,10,5}} end,
    GetUnitPieceMatrix=function() return scale,0,0,0, 0,0,scale,0, 0,scale,0,0, 0,0,0,1 end,
    GetUnitPiecePosDir=function() return 100,50,200 end,
    GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
    GetUnitNoDraw=function() return false end,GetUnitIsCloaked=function() return false end,
    GetSpectatingState=function() return false,false end,
    GetUnitLosState=function() return {los=true} end,
}}, {__index=_G})
local sources=loadIn('luaui/widgets_mosaic/include/radiance_objective_sources.lua',sourceEnv)
assert(sources.PlaceableEligible(1,1))
scale=.1;assert(not sources.PlaceableEligible(2,1),'raw DAE size bypassed world-space minimum')
scale=1
local lamp=sources.RoofLamp(1,1,'outpost_roof')
assert(lamp.x==100 and lamp.y==58 and lamp.z==200,'roof lamp ignored the rotated local up axis')
assert(sources.PlaceablesVisible(1))
sourceEnv.Spring.GetUnitLosState=function() return {los=false,radar=true} end
assert(not sources.PlaceablesVisible(1),'radar-only house leaked lighting')
sourceEnv.Spring.GetSpectatingState=function() return true,true end
assert(sources.PlaceablesVisible(1))
sourceEnv.Spring.GetUnitNoDraw=function() return true end
assert(not sources.PlaceablesVisible(1),'hidden house leaked lighting')
print('PASS: imported model scale, placeable cutoff, roof placement under rotation and LOS/nodraw filtering')
