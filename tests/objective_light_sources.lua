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
    env.getGameConfig=function() return {game={culture='international'}} end
    env.getCultureUnitModelNames_Dict_DefIDName=function() return {} end
    env.getDayTime=function() return 0,0,0,0 end
    env.getObjectiveAboveGroundOffset=function() return 0 end
    env.getDetermenisticMapHash=function() return 1 end
    env.getDeterministicStationaryUnitHash=function() return 2 end
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
assert(lights[e.piece('CombatOutPost')].preset=='outpost_searchlight')
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

-- The military headquarters uses its mask and follows deployed track visibility.
e,lights,shown,groups=unit('objectiveWestHemHQ.lua')
groups.HyperLoop={}
for i=1,10 do groups.HyperLoop[i]=e.piece('HyperLoop'..i) end
e.resetAll=function() end;e.randSign=function() return 1 end
e.Game.mapSizeX=1024;e.Game.mapSizeZ=1024
e.Spring.GetUnitPiecePosDir=function(_,id)
    return id==groups.HyperLoop[1] and 512 or 2048,50,512
end
e.script.Create()
local headquarters=e.piece('center')
assert(lights[headquarters].mode=='material','military headquarters lost masked emission')
co=coroutine.create(e.delayShowAllElements)
assert(resume(co)==10000)
for _,id in ipairs(groups.HyperLoop) do assert(not shown[id] and not lights[id]) end
resume(co)
for i,id in ipairs(groups.HyperLoop) do
    assert((lights[id]~=nil)==(shown[id]==true),'military track visibility/emission diverged')
    assert((lights[id]~=nil)==(i<=2),'hidden track emitted or visible boundary segment was omitted')
    if lights[id] then assert(lights[id].mode=='material') end
end
local plane,rotor1,rotor2=e.piece('Plane1'),e.piece('Plane1Sub1'),e.piece('Plane1Sub2')
e.showHidePlane(true,plane,rotor1,rotor2)
for _,id in ipairs({plane,rotor1,rotor2}) do assert(shown[id] and not lights[id]) end
e.showHidePlane(false,plane,rotor1,rotor2)
for _,id in ipairs({plane,rotor1,rotor2}) do assert(not shown[id] and not lights[id]) end
assert(lights[headquarters],'VTOL visibility removed headquarters emission')
print('PASS: military headquarters and visible boundary tracks emit through their mask; VTOLs do not')

e,lights,shown,groups=unit('objective_presidentialpalacescript.lua')
local selected=e.piece('Palast4')
groups.Palast={selected,e.piece('Palast1')}
for _,name in ipairs({'Street','Park','Post1Flag','Post2Flag','Post3Flag'}) do groups[name]={e.piece(name..'1')} end
e.showOne=function(t) return t[1] end
e.showSeveral=function() return {} end
e.isInTable=function() return false end
e.TablesOfPiecesGroups=groups
e.buildShowUnit()
assert(shown[selected] and lights[selected].preset=='palace_facade')
assert(not lights[groups.Palast[2]] and not lights[e.Base],'unselected palace or structural base emitted')
print('PASS: only the chosen palace variant owns facade floodlights')

local scale=1
local sourceEnv=setmetatable({Game={gameSpeed=30},Spring={
    GetUnitDefID=function(id) return id end,
    GetUnitPieceInfo=function() return {min={-20,-10,-5},max={20,10,5}} end,
    GetUnitPieceMatrix=function() return scale,0,0,0, 0,0,scale,0, 0,scale,0,0, 0,0,0,1 end,
    GetUnitPiecePosDir=function() return 100,50,200 end,
    GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
    GetUnitNoDraw=function() return false end,GetUnitIsCloaked=function() return false end,
    GetSpectatingState=function() return false,false end,
    GetUnitLosState=function() return {los=true} end,
    GetGroundHeight=function() return 0 end,
    ValidUnitID=function() return true end,GetUnitIsDead=function() return false end,
    GetCameraPosition=function() return 100,50,200 end,
}}, {__index=_G})
local sources=loadIn('luaui/widgets_mosaic/include/radiance_objective_sources.lua',sourceEnv)
assert(sources.PlaceableEligible(1,1))
scale=.1;assert(not sources.PlaceableEligible(2,1),'raw DAE size bypassed world-space minimum')
scale=1
local uplights=sources.AttachedLights(1,1,'palace_facade',0)
assert(#uplights==8)
for _,l in ipairs(uplights) do
    assert(l.direction[2]>0 and l.y==50 and l.range>0,'floodlight did not point up from the base')
    assert(math.abs(l.x-100)>20 or math.abs(l.z-200)>10,'floodlight remained inside the building')
end
scale=.0254
local a=sources.AttachedLights(1,1,'outpost_searchlight',0)[1]
local b=sources.AttachedLights(1,1,'outpost_searchlight',.5)[1]
local cycle=sources.AttachedLights(1,1,'outpost_searchlight',480)[1]
assert(math.abs(a.x-(100+500*scale))<.001 and math.abs(a.y-(53+3300*scale))<.001)
assert(a.direction[2]<0 and a.outerCos>.97,'searchlight lost its narrow downward cone')
assert(math.abs(a.direction[1]-b.direction[1])>.0001,'subframe motion waited for cascade refresh')
assert(math.abs(a.direction[1]-cycle.direction[1])<.0001,'searchlight did not return smoothly after one sweep')
assert(a.x==b.x and a.y==b.y and a.z==b.z,'searchlight moved off its tower')
local records={}
for id=1,8 do records[id]={[1]={piece=1,mode='lamp',preset='palace_facade'}} end
assert(#sources.CollectDirect(records,0)==24,'direct light budget was not enforced')
scale=1
assert(sources.PlaceablesVisible(1))
sourceEnv.Spring.GetUnitLosState=function() return {los=false,radar=true} end
assert(not sources.PlaceablesVisible(1),'radar-only house leaked lighting')
assert(#sources.AttachedLights(1,1,'palace_facade',0)==0,'palace light leaked outside LOS')
sourceEnv.Spring.GetSpectatingState=function() return true,true end
assert(sources.PlaceablesVisible(1))
sourceEnv.Spring.GetUnitNoDraw=function() return true end
assert(not sources.PlaceablesVisible(1),'hidden house leaked lighting')
assert(#sources.CollectDirect(records,0)==0,'hidden objective leaked direct light')
print('PASS: imported model scale, placeable cutoff, roof placement under rotation and LOS/nodraw filtering')
