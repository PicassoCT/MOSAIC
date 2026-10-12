-- Real tank firing script -> LOS-scoped shot stamp -> combat sources -> both
-- production renderers. Run from the repository root: texlua tests/tank_muzzle_effects.lua
unpack=unpack or table.unpack
local noop=function() end
local frame,offset,drawFrame,fullView,pointLOS=100,0,0,false,true
local traceLines={}
Game={gameSpeed=30,mapSizeX=4096,mapSizeZ=4096}
WeaponDefs={}
UnitDefs={[1]={name='ground_tank_day'},[2]={name='ground_tank_night'},[3]={name='civilian_arab0'}}
UnitDefNames={ground_tank_day={id=1},ground_tank_night={id=2}}
local env=setmetatable({MOSAIC_CONFIG_ONLY=true},{__index=_G})
local chunk=setfenv and setfenv(assert(loadfile('scripts/lib_mosaic.lua')),env)
    or assert(loadfile('scripts/lib_mosaic.lua','t',env))
local profiles=chunk().getTankMuzzleTypeTable(UnitDefs)
assert(profiles[1] and profiles[1]==profiles[2] and not profiles[3],
    'central muzzle property set lost a tank variant or included a civilian')
local profile=profiles[1]
local pieces={FireEmit=0,Cannon1=1,Body1=2,Turret1=3,Shell=4,DustEmit=5}
local units={}
local function newUnit(defID)
    return {defID=defID,rules={},los=true,sim={10,0,10},view={14,2,7},map=pieces,
        muzzle={10,32,104},barrel={10,32,10},mapCalls=0,pieceCalls=0}
end
Spring={
    Echo=function(line) traceLines[#traceLines+1]=line end,
    GetGameFrame=function() return frame end,GetFrameTimeOffset=function() return offset end,
    GetDrawFrame=function() return drawFrame end,GetCameraPosition=function() return 10,100,10 end,
    GetSpectatingState=function() return fullView,fullView end,GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return pointLOS end,IsSphereInView=function() return true end,
    GetUnitLosState=function(id) return {los=units[id].los} end,
    ValidUnitID=function(id) return units[id]~=nil and not units[id].invalid end,
    GetUnitIsDead=function(id) return units[id].dead end,
    GetUnitIsCloaked=function(id) return units[id].cloaked end,
    GetUnitNoDraw=function(id) return units[id].noDraw end,
    GetUnitTransporter=function(id) return units[id].transporter end,
    GetUnitTeam=function() return 1 end,GetGaiaTeamID=function() return 0 end,
    GetUnitDefID=function(id) return units[id].defID end,
    GetUnitPosition=function(id) return unpack(units[id].sim) end,
    GetUnitViewPosition=function(id) return unpack(units[id].view) end,
    GetUnitPieceMap=function(id) local u=units[id];u.mapCalls=u.mapCalls+1;return u.map end,
    GetUnitPiecePosDir=function(id,piece)
        local u=units[id];u.pieceCalls=u.pieceCalls+1
        local p=piece==u.map.FireEmit and u.muzzle or (piece==u.map.Cannon1 and u.barrel)
        -- The legacy CEG rotates FireEmit; a wrong +Y direction must be ignored.
        if p then return p[1],p[2],p[3],0,1,0 end
    end,
    GetUnitRulesParam=function(id,key) return units[id].rules[key] end,
    SetUnitRulesParam=function(id,key,value,access)
        assert(access.inlos and not access.public,'shot state leaked outside unit LOS')
        units[id].rules[key]=value
    end,
    SetUnitNanoPieces=noop,GetGroundHeight=function() return 0 end,
    GetWind=function() return 1,0,0 end,GetVisibleProjectiles=function() return {} end,
}
include=noop;piece=function(name) return assert(pieces[name],name) end
randChance=function() return false end
Show=noop;Hide=noop;hideT=noop;resetAll=noop;StartThread=noop
getPieceTableByNameGroups=function() return {} end
tP=noop;SFX={FALL=1}
local ceg,shell,ground={},{},{}
EmitSfx=function(piece,code) ceg[code]=(ceg[code] or 0)+1 end
Explode=function(piece,flags) shell[#shell+1]={piece,flags} end
spawnCegAtPieceGround=function(id,piece,name) ground[name]=(ground[name] or 0)+1 end
local Sources=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
local function fresh() return Sources.New({},nil,profiles) end
local function collect(s) drawFrame=drawFrame+1;return s:Collect() end
local function near(a,b,message) assert(math.abs(a-b)<0.00001,message..': '..tostring(a)..' != '..b) end
local function fire(id)
    unitID=id;unitDefID=units[id].defID;script={}
    dofile('scripts/tankscript.lua')
    script.Create()
    assert(units[id].rules[profile.shotParam]==-1,'new tank inherited an old shot')
    script.FireWeapon1()
end

-- Both real tank variants use the same script event, including the legacy CEGs.
local s=fresh()
for _,defID in ipairs({1,2}) do
    local id=defID+10;units[id]=newUnit(defID);fire(id);s:UnitCreated(id,defID)
    assert(units[id].rules[profile.shotParam]==frame,'FireWeapon1 failed to stamp the shot')
    local lights,flames=collect(s)
    assert(#lights==1 and #flames==1,'tank shot did not produce both light and FlamePainter')
    local light,ribbon=lights[1],flames[1]
    assert(not light.nightOnly and light.unitID==id and ribbon.unitID==id,
        'muzzle flash lost daytime emission or validated owner')
    near(light.x,14,'render-interpolated muzzle X');near(light.y,34,'muzzle Y')
    near(light.z,103,'external muzzle plus forward clearance')
    near(ribbon.direction[1],0,'barrel direction X');near(ribbon.direction[2],0,'barrel direction Y')
    near(ribbon.direction[3],1,'barrel direction Z')
    near(ribbon.length,94*profile.lengthFactor,'model-proportional flame length')
    near(ribbon.width,ribbon.length*profile.widthFactor,'model-proportional flame width')
    near(light.radius,ribbon.length*profile.radiusFactor,'model-proportional radiance reach')
    local queries=units[id].pieceCalls
    assert(s:Collect()==lights and queries==units[id].pieceCalls,'same draw repeats piece queries')
    s:UnitDestroyed(id)
end
assert(ceg[1026]==2 and ceg[1024]==2 and #shell==2 and ground.tankfireshockwave==2
    and ground.bigbulletimpact==2,'existing shell/CEG complexity changed')

local id=11;local u=units[id]
s:UnitCreated(id,1)
local lights,flames=collect(s)
local born=frame
assert(s:HasTankMuzzleFlash(id),'active tank shot not recognized for duplicate-flash suppression')
assert(not s:HasTankMuzzleFlash(999),'unrelated weapon suppressed as tank muzzle')

-- Turret pitch/heading and model translation are sampled afresh; cached IDs
-- must not freeze the muzzle. A diagonal 3D barrel also detects axis confusion.
u.barrel={100,30,100};u.muzzle={156.4,48.8,172.06}
u.sim={100,10,100};u.view={105,13,98}
lights,flames=collect(s)
local vx,vy,vz=56.4,18.8,72.06
local span=math.sqrt(vx*vx+vy*vy+vz*vz)
near(lights[1].x,161.4+vx/span*profile.clearance,'animated muzzle X')
near(lights[1].y,51.8+vy/span*profile.clearance,'animated muzzle pitch')
near(lights[1].z,170.06+vz/span*profile.clearance,'animated muzzle Z')
near(flames[1].direction[2],vy/span,'pitch direction')

frame=born+6;lights,flames=collect(s)
near(lights[1].strength/profile.strength,flames[1].opacity,'light and flame envelopes diverged')
assert(flames[1].opacity<.5,'shot did not decay')
local reloaded=fresh();reloaded:UnitCreated(id,1)
assert(#collect(reloaded)==1,'LuaUI reload lost the active part of a shot')
frame=born+11;offset=.999;assert(#collect(s)==1,'shot expired before its exact endpoint')
frame=born+12;offset=0
assert(#collect(s)==0 and not s:HasTankMuzzleFlash(id),'shot outlived 12 frames')
reloaded=fresh();reloaded:UnitCreated(id,1)
assert(#collect(reloaded)==0,'LuaUI reload replayed an expired shot')
local queries=u.pieceCalls
frame=born+900;assert(#collect(s)==0 and u.pieceCalls==queries,'idle tank loops/replays muzzle geometry')
u.rules[profile.shotParam]=frame+1
assert(#collect(s)==0,'future stamp emitted early')
u.rules[profile.shotParam]=frame

-- Sources and renderer both honor unit visibility; ordinary positional effects
-- retain their stricter positional LOS. Full-view spectating only bypasses LOS.
for _,flag in ipairs({'cloaked','noDraw','transporter','dead','invalid'}) do
    u[flag]=true;assert(#collect(s)==0,flag..' tank retained muzzle light');u[flag]=nil
end
u.los=false;assert(#collect(s)==0,'tank flash leaked outside unit LOS')
fullView=true;assert(#collect(s)==1,'full-view spectator lost a visible tank shot')
fullView=false;u.los=true;pointLOS=false
lights,flames=collect(s)
assert(#lights==1 and #flames==1,'visible owner was rehidden by terrain positional LOS')

-- The point-light pass emits in daylight and allocates no extra targets.
local gain,draws,allocations=0,0,0
GL={ONE=1,ONE_MINUS_SRC_ALPHA=2,QUADS=7,TRIANGLE_STRIP=5,ALL_ATTRIB_BITS=1}
gl=setmetatable({
    CreateShader=function() return 1 end,GetUniformLocation=function(_,name) return name end,
    CreateTexture=function() allocations=allocations+1;error('new target allocated') end,
    CreateList=function(fn) fn();return 1 end,CallList=function() draws=draws+1 end,
    GetSun=function() return .6,.6,.6 end,
    Uniform=function(name,value) if name=='strength' then gain=value end end,
    BeginEnd=function(_,fn,...) fn(...) end,
},{__index=function() return noop end})
VFS={LoadFile=function() return '' end};WG={GetVehicleLightOcclusion=function() return 9 end}
local lightRenderer=assert(dofile('luaui/widgets_mosaic/include/combat_light_renderer.lua')(s))
lightRenderer:Capture(0,128,1,0)
assert(gain>0 and allocations==0,'daytime muzzle radiance missing or extra target allocated')
lightRenderer:Shutdown()
local renderer=assert(dofile('luarules/gadgets/include/smoke_ribbon_renderer.lua')())
renderer.maxVisible=64;renderer:Draw(flames)
assert(draws==1,'production FlamePainter rejected a visible attached muzzle outside positional LOS')
u.los=false;pointLOS=true;renderer:Draw(flames)
assert(draws==1,'attached ribbon leaked a hidden owner through positional LOS')
u.los=true;pointLOS=false
local stray={};for key,value in pairs(flames[1]) do stray[key]=value end;stray.unitID=nil
renderer:Draw({stray});assert(draws==1,'ordinary world ribbon lost positional visibility gate')
for _,flag in ipairs({'cloaked','noDraw','transporter','dead','invalid'}) do
    u[flag]=true;renderer:Draw(flames);assert(draws==1,flag..' owner survived renderer validation');u[flag]=nil
end
renderer:Shutdown()

-- Destruction/reuse removes cached model pieces; replacement vehicles cannot
-- inherit a tank's shot, and a new tank script clears an old stamp explicitly.
s:UnitDestroyed(id);assert(#collect(s)==0,'destroyed tank retained registry entry')
units[id]=newUnit(3);s:UnitCreated(id,3)
units[id].rules[profile.shotParam]=frame
assert(#collect(s)==0,'reused civilian ID inherited tank muzzle capability')
units[id]=newUnit(2);units[id].rules[profile.shotParam]=frame
unitID=id;unitDefID=2;script={};dofile('scripts/tankscript.lua');script.Create()
s:UnitCreated(id,2);assert(#collect(s)==0,'new tank inherited an earlier unit shot')

-- Trace the actual script -> collector -> renderer handoff. A successful source
-- is not a submitted draw, and an expired first observation must not replay it.
local function traceCount(stage, reason)
    local n=0
    for _,line in ipairs(traceLines) do
        if line:find(' stage='..stage..' ',1,true)
            and (not reason or line:find('reason='..reason,1,true)) then n=n+1 end
    end
    return n
end
local function output() return table.concat(traceLines,'\n') end
id=41;units[id]=newUnit(1);u=units[id]
frame,offset,pointLOS=2000,0,true
s=fresh();traceLines={};fire(id);s:UnitCreated(id,1)
lights,flames=collect(s)
local traceRenderer=assert(dofile('luarules/gadgets/include/smoke_ribbon_renderer.lua')())
local before=draws
traceRenderer:Draw(flames);lights,flames=collect(s);traceRenderer:Draw(flames)
assert(draws==before+2, 'diagnostic deduplication suppressed real repeated draws')
for _,stage in ipairs({'tank_shot_published','tank_registered','tank_shot_observed',
    'tank_muzzle_anchors','tank_muzzle_source_ready','tank_muzzle_queued',
    'tank_muzzle_render_ready','tank_muzzle_draw_submitted'}) do
    assert(traceCount(stage)==1, stage..' was absent or repeated for one shot')
end
assert(output():find('meaning=cpu_submission_returned',1,true))
frame=2012;traceLines={};lights,flames=collect(s)
assert(#flames==0 and traceCount('tank_muzzle_rejected','expired_stamp')==1)
assert(output():find('expired_on_first_observation=false',1,true), 'ordinary expiry mislabeled as missed first observation')
frame=2040;s=fresh();s:UnitCreated(id,1);traceLines={};lights,flames=collect(s)
assert(#flames==0 and traceCount('tank_shot_observed')==1)
assert(output():find('expired_on_first_observation=true',1,true), 'first observation of expired shot not recorded')
collect(s);assert(traceCount('tank_shot_observed')==1, 'expired shot spammed each draw')

local function prepare()
    frame=frame+20;u.rules[profile.shotParam]=frame
    s=fresh();s:UnitCreated(id,1)
    lights,flames=collect(s);traceLines={}
    return flames[1]
end
local reasons={invalid='invalid_unit',dead='dead_unit',cloaked='cloaked_unit',
    noDraw='unit_nodraw',transporter='transported_unit'}
for flag,reason in pairs(reasons) do
    prepare();u[flag]=true
    before=draws;traceRenderer:Draw(flames)
    assert(draws==before and traceCount('tank_muzzle_render_rejected',reason)==1,
        'renderer did not report '..reason)
    assert(traceCount('tank_muzzle_draw_submitted')==0, 'rejected '..reason..' reported a draw')
    traceLines={};collect(s)
    assert(traceCount('tank_muzzle_rejected',reason)==1, 'source did not report '..reason)
    u[flag]=nil
end
prepare();u.los=false;before=draws;traceRenderer:Draw(flames)
assert(draws==before and traceCount('tank_muzzle_render_rejected','outside_unit_los')==1)
assert(traceCount('tank_muzzle_draw_submitted')==0);u.los=true
local r=prepare();r.x=1e7;before=draws;traceRenderer:Draw(flames)
assert(draws==before and traceCount('tank_muzzle_render_rejected','distance_cutoff')==1)
prepare();local inView=Spring.IsSphereInView;Spring.IsSphereInView=function() return false end
before=draws;traceRenderer:Draw(flames)
assert(draws==before and traceCount('tank_muzzle_render_rejected','outside_frustum')==1)
assert(traceCount('tank_muzzle_draw_submitted')==0);Spring.IsSphereInView=inView
prepare();traceRenderer.maxVisible=0;before=draws;traceRenderer:Draw(flames)
assert(draws==before and traceCount('tank_muzzle_render_rejected','ribbon_budget')==1)
assert(traceCount('tank_muzzle_draw_submitted')==0);traceRenderer.maxVisible=128

-- Exhaust the existing shared light budget with closer fires. The tank's
-- source must report this handoff loss, without bypassing the established cap.
prepare()
for i=1,128 do s:SetFire(i,10,95,10,frame,frame+100) end
traceLines={};lights,flames=collect(s)
assert(#lights==96 and traceCount('tank_muzzle_budget_dropped','light_budget')==1)
assert(traceCount('tank_muzzle_queued')==0)

-- Piece data failures stay explicit and retain the original no-flash result.
local originalMap,originalMuzzle,originalBarrel=u.map,u.muzzle,u.barrel
for _,test in ipairs({
    {reason='missing_anchors', setup=function() u.map={} end},
    {reason='missing_piece_position', setup=function() u.muzzle=nil end},
    {reason='degenerate_direction', setup=function() u.barrel=u.muzzle end},
}) do
    u.map,u.muzzle,u.barrel=originalMap,originalMuzzle,originalBarrel
    test.setup();frame=frame+20;u.rules[profile.shotParam]=frame
    s=fresh();s:UnitCreated(id,1);traceLines={};lights,flames=collect(s)
    assert(#flames==0 and traceCount('tank_muzzle_rejected',test.reason)==1)
end
u.map,u.muzzle,u.barrel=originalMap,originalMuzzle,originalBarrel

-- Ordinary ribbons acquire no diagnostics. Explicitly tagged piece-attached
-- building records use their own prefix and retain distinct emitter slots.
r=prepare();r.executionTrace=nil;before=draws;traceRenderer:Draw(flames)
assert(draws==before+1 and #traceLines==0, 'untagged ribbon emitted diagnostic noise')
local Trace=dofile('luarules/gadgets/include/execution_trace.lua')
local buildingTrace=Trace.New('BuildingDestruction')
r.piece=pieces.FireEmit;r.enabled=true;r.rootOffset={0,0,0};r.drawInIcon=true
r.executionTrace={logger=buildingTrace,unitID=id,cycle=frame,stagePrefix='building_fire',piece=r.piece,slot=1}
local r2={};for key,value in pairs(r) do r2[key]=value end
r2.executionTrace={logger=buildingTrace,unitID=id,cycle=frame-5,stagePrefix='building_fire',piece=r.piece,slot=2}
traceRenderer.records={one=r,two=r2};traceLines={};before=draws
traceRenderer:Draw();traceRenderer:Draw()
assert(draws==before+4 and traceCount('building_fire_draw_submitted')==2,
    'piece-attached traces lost their family, slot identity or real repeated draws')
u.los=false;traceLines={};before=draws;traceRenderer:Draw()
assert(draws==before and traceCount('building_fire_render_rejected','outside_unit_los')==2)
assert(traceCount('building_fire_draw_submitted')==0)
traceRenderer:Shutdown()

print('PASS tank muzzle: real script/source/renderer, preserved CEGs/dimensions/expiry/LOS, bounded shot traces, expired-first-observation, explicit source and render rejection, budgets, CPU submission and tagged building slots')
