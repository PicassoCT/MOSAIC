-- Lua 5.1: production controller, owning scripts, animation data and hive worker.
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function chunk(s,e)local f=assert(loadstring(s));setfenv(f,e);return f()end
local lib=read('scripts/lib_mosaic.lua')
local function section(s,a,b)local i=assert(s:find(a,1,true));local j=assert(s:find(b,i+#a,true));return s:sub(i,j-1)end
local function scenario(kind)
 local s={frame=4245,orders={},hits={},speed={},queries=0,walkable=true,terrain=function()return 0 end}
 s.units={[42]={def=1,x=512,y=0,z=512,team=0}}
 local defs={[1]={name='civilian',weapons={{}}},[2]={name='house',weapons={}},
  [3]={name='ground_tank_day',weapons={{}}},[4]={name='hivemind'},
  [5]={name='truck_western',weapons={{}}},[6]={name='air_copter_mg',canFly=true,weapons={{}}},[7]={name='ground_walker_mg',weapons={{}}}}
 local config={instance={culture='international'},integrationRadius=75,maxNumberIntegratedIntoHive=300,addSlowMoTimeInMsPerCitizen=150,
  Aerosols={tollwutox={VictimLiftime=420000,searchRadius=900,meleeDamage=30,shambleSpeed=.4,lungeSpeed=.85},
  wanderlost={VictimLiftime=180000,searchRadius=650,shambleSpeed=.3,reinfectRange=50},
  depressol={VictimLiftime=180000,searchRadius=1800,shambleSpeed=.35,meleeDamage=8}}}
 local e=setmetatable({GG={GameConfig=config,AerosolAffectedCivilians={},HiveMind={},DisguiseCivilianFor={}},
  Game={gameSpeed=30,mapSizeX=4096,mapSizeZ=4096},UnitDefs=defs},{__index=_G})
 e.Spring={GetGameFrame=function()return s.frame end,ValidUnitID=function(id)return s.units[id]~=nil end,
  GetUnitIsDead=function(id)return not s.units[id] or s.units[id].dead end,
  GetUnitPosition=function(id)local u=s.units[id];if u and not u.dead then return u.x,u.y,u.z end end,
  GetUnitDefID=function(id)return s.units[id] and s.units[id].def end,GetUnitTeam=function(id)return s.units[id] and s.units[id].team end,
  GetUnitTransporter=function(id)return s.units[id].transport end,GetUnitIsCloaked=function(id)return s.units[id].cloaked end,
  GetUnitHealth=function(id)return 100,100,0,0,s.units[id].build or 1 end,AreTeamsAllied=function(a,b)return a==b end,
  GetUnitCurrentCommand=function()return s.currentCommand end,GetGroundHeight=function(x,z)return s.terrain(x,z)end,
  GetUnitRadius=function()return 20 end,TestMoveOrder=function()return s.walkable end,
  GetUnitsInCylinder=function(x,z,r)
   s.queries=s.queries+1;local found={};for id,u in pairs(s.units)do if (u.x-x)^2+(u.z-z)^2<=r*r then found[#found+1]=id end end
   table.sort(found);return found
  end,
  SetUnitNeutral=function(id,v)assert(id==42 and v==false);s.exposed=true end,
  AddUnitDamage=function(id,d,p,attacker,w)assert(not s.units[id].dead and attacker==42 and p==0 and w==-1);s.hits[#s.hits+1]={id=id,damage=d}end}
 e.getChemTrailInfluencedTypes=function()return {[1]=true}end;e.getGameConfig=function()return config end
 e.setSpeedIntern=function(id,v)assert(id==42 and v>0 and v<=1);s.speed[#s.speed+1]=v end
 e.Command=function(id,cmd,pos,options)
  assert(id==42 and not options,'orders must replace, not queue');if cmd=='go'then assert(pos.x and pos.y and pos.z)end
  s.currentCommand=cmd=='go' and 10 or nil;s.orders[#s.orders+1]={cmd=cmd,pos=pos}
 end
 e.spawnCegAtUnit=function(id,name)assert(s.units[id].def==1 and name=='bloodslay')end
 e.include=function(name)return chunk(read('scripts/'..name),e)end
 chunk(section(lib,'function getAerosolInfluencedStateMachine(','function headShake('),e)
 s.status={};s.env=e;s.config=config;s.controller=e.getAerosolInfluencedStateMachine(42,defs,kind,11,12,13,14,s.status)
 function s:add(id,def,x,z,team)self.units[id]={def=def,x=x,y=0,z=z or 512,team=team or 0}end
 function s:tick(frames)self.frame=self.frame+(frames or 16);return self.controller()end
 function s:go()for i=#self.orders,1,-1 do if self.orders[i].cmd=='go'then return self.orders[i].pos end end end
 s.controller();return s
end
local s=scenario('tollwutox')
s:add(50,1,540);s.env.GG.AerosolAffectedCivilians[50]='tollwutox';s:add(51,2,520);s:add(52,1,600);s:add(53,1,515);s.units[53].dead=true
s:tick();assert(s:go().x==600 and s.status.aerosolAgitated,'fresh civilian must take priority over herd/building/dead unit')
local orders,queries=#s.orders,s.queries;for i=1,8 do s:tick(1)end
assert(#s.orders==orders and s.queries==queries,'controller reissued every tick')
s.units[42].x=590;s:tick(16);assert(#s.hits==1 and s.hits[1].id==52 and s.hits[1].damage==30 and s.exposed)
s:tick(16);assert(#s.hits==1,'melee cooldown lost');s.units[52].dead=true;s:tick(50);s:tick(40)
assert(#s.hits==1 and not s.status.aerosolAgitated,'dead target still attacked')
s.frame=4245+420000*30/1000;assert(s:tick(0)=='Exit','victim lifetime restarted')
s=scenario('wanderlost');s:add(50,1,650);s:tick();assert(s:go().x==650 and s.speed[#s.speed]==.3 and not s.status.aerosolAgitated)
s.units[42].x=630;s:tick(16);assert(#s.hits==0,'Wanderlost should infect rather than maul')
s.env.GG.AerosolAffectedCivilians[50]='wanderlost';s:tick(40);s:tick(40);assert(#s.hits==0 and not s.status.aerosolAgitated)
s=scenario('depressol');s:add(70,4,650,512,1);s:add(71,3,660,512,1)
s.env.GG.HiveMind[1]={[70]={rewindMilliSeconds=0},teamActive=false};s:tick();assert(s:go().x==650,'available hive not selected')
s.env.GG.HiveMind[1][70].rewindMilliSeconds=45000;s:tick(16);s:tick(40);assert(s:go().x==660,'full hive trapped victim')
s.units[42].x=640;s:tick(16);assert(s.hits[1].id==71 and s.hits[1].damage==8 and s.exposed,'military not provoked')
s.units[71].dead=true;s:tick(40);assert(#s.hits==1)
s=scenario('depressol');s:add(70,3,540,512,0);s:add(71,5,545,512,1);s:add(72,6,550,512,1);s:add(73,7,650,512,1);s:tick()
assert(s:go().x==650,'targeted ally/traffic/aircraft instead of robot');local old=s:go().x;s:tick(250);s:tick(40)
assert(s:go().x~=old,'blocked target never abandoned')
s=scenario('depressol');s.terrain=function(x)return x<=700 and 0 or -(x-700)*.2 end;s:tick();local shore=s:go()
assert(shore and shore.x>700 and shore.y>=-5 and shore.y<-1,'no walkable shoreline')
s.units[42].x=shore.x;s.units[42].z=shore.z;s.units[42].y=shore.y;s:tick(16)
assert(s.status.aerosolDrowning and s:tick(100)=='Exit','water victim never collapsed/expired')
s=scenario('depressol');s.walkable=false;s.terrain=function()return -50 end;s:tick();assert(not s:go() and not s.status.aerosolDrowning)
s=scenario('depressol');s.units[42].transport=200;s:tick();assert(s.queries==0 and not s:go(),'transported victim moved')
-- Snapshot spread: new infections must wait for the next shared pass.
s=scenario('wanderlost');s:add(50,1,540);s:add(51,1,570);s:add(52,1,580);s.units[52].dead=true
local infected={};s.env.getAllNearUnit=function(id)return id==42 and {50}or {51,52}end
s.env.setAerosolCivilianBehaviour=function(id)infected[id]=true;return true end
chunk(section(lib,'    function infectWanderlostNearby(','\n    function getChildrenOfUnit('),s.env)
local function spread()s.env.infectWanderlostNearby(s.config,{wanderlost='wanderlost'},{[1]=true})end
spread();assert(infected[50] and not infected[51],'same-tick chain infection');spread();assert(infected[51] and not infected[52])
-- Real owner entrypoints and animation state tables, including normal rig conversion.
for _,file in ipairs({'civilianscript.lua','civilianagentscript.lua'})do
 local source=read('scripts/'..file);local status,seen={},{}
 local e=setmetatable({unitID=42,UnitDefs={},aeroSolType='tollwutox',bodyConfig=status,center=11,UpArm1=12,UpArm2=13,Head1=14,
  lowerBodyPieces={[11]=true},upperBodyPieces={[14]=true},x_axis=1,y_axis=2,z_axis=3,SIG_INTERNAL=128,SIG_COVER_WALK=8,
  SIG_PISTOL=32,SIG_MOLOTOW=64,SIG_RPG=256,script={},
  eAnimState=setmetatable({},{__index=function(_,k)return k end}),Signal=function(mask)assert(type(mask)=='number')end,hideAllProps=function()end,
  setOverrideAnimationState=function()end,Sleep=function()coroutine.yield()end,Spring={GetGameFrame=function()return 5000 end},
  getAerosolInfluencedStateMachine=function(id,defs,kind,c,l,r,h,st)
   assert(id==42 and h==14 and st==status and c==11 and l==12 and r==13);return function()return 'Outbreak'end
  end},{__index=_G})
 chunk(section(source,'function aeroSolStateBehaviour()','\nfunction wailing()'),e)
 local co=coroutine.create(e.aeroSolStateBehaviour);assert(coroutine.resume(co));assert(status.boolInfluenced and status.aerosolType=='tollwutox')
 chunk(assert(source:match('(function script%.HitByWeapon%(.-\nend)')),e)
 assert(e.script.HitByWeapon(0,0,1,25)==25,'influence changed incoming damage')
 chunk(assert(source:match('(function script%.AimWeapon%(.-\nend)')),e)
 assert(e.script.AimWeapon(1,0,0)==false,'affected victim aimed a hidden gun')
 e.GG={CivilianUnitInternalLogicActive={[42]={behaviour='aerosol'}}}
 chunk(assert(source:match('(function setCivilianUnitInternalStateMode%(.-\nend)')),e)
 e.setCivilianUnitInternalStateMode(42,1,'pray')
 assert(e.GG.CivilianUnitInternalLogicActive[42].behaviour=='aerosol','prayer replaced influence state')
 e.AerosolAnimations=chunk(read('scripts/animations_civilian_aerosols.lua'),e)
 e.Animations=chunk(read('scripts/animations_civilian_female.lua'),e);e.AerosolAnimations.register(e.Animations)
 e.map={center=11,UpArm1=12,UpArm2=13,Head1=14,LowArm1=15,LowArm2=16,UpBody=17,UpLeg1=18,UpLeg2=19,LowLeg1=20,LowLeg2=21,Feet1=22,Feet2=23}
 e.constructSkeleton=function()local t={};for _,id in pairs(e.map)do t[id]={0,0,0}end;return t end
 chunk(section(source,'function setupAnimation()','\nlocal axisSign'),e);e.setupAnimation()
 e.PlayAnimation=function(name,exclude,speed)
  assert(e.Animations[name] and speed>0)
  for _,key in ipairs(e.Animations[name])do for _,cmd in pairs(key.commands)do assert(type(cmd.p)=='number','bad animation handle')end end
  seen[#seen+1]={name=name,exclude=exclude}
 end
 chunk(section(source,'local function playAerosolAnimation(','\nAimDelay = 0'),e);e.Sleep=function()end
 for _,kind in ipairs({'tollwutox','wanderlost','depressol'})do
  status.aerosolType=kind;assert(e.UpperAnimationStateFunctions.standing()=='standing');assert(seen[#seen].exclude==e.lowerBodyPieces)
  assert(e.LowerAnimationStateFunctions.standing()=='standing');assert(seen[#seen].exclude==e.upperBodyPieces)
  assert(e.UpperAnimationStateFunctions.walking()=='walking');assert(e.LowerAnimationStateFunctions.walking()=='walking')
 end
end
-- Actual hive admission, own-team Depressol recruits, and capacity limits.
for _,charge in ipairs({0,44850})do
 local destroyed={};local gg={GameConfig={instance={culture='international'}},DisguiseCivilianFor={},
  AerosolAffectedCivilians={[11]='depressol',[12]='wanderlost',[13]='depressol',[16]='tollwutox'},HiveMind={[1]={[200]={rewindMilliSeconds=charge}}}}
 local e=setmetatable({unitID=200,GG=gg,UnitDefs={[2]={name='civilianagent'}},script={},include=function()end,piece=function()return 1 end,
  getGameConfig=function()return {integrationRadius=75,addSlowMoTimeInMsPerCitizen=150,maxNumberIntegratedIntoHive=300}end,
  getCultureUnitModelTypes=function()return {[1]=true}end,waitTillComplete=function()end,getAllInCircle=function()return {11,12,13,14,15,16}end,
  isTransport=function()return false end,Sleep=function()coroutine.yield()end,
  foreach=function(list,filter,act)for _,id in ipairs(list)do local v=filter(id);if v then act(v)end end end,
  Spring={GetUnitTeam=function(id)return (id==200 or id==13 or id==14)and 1 or 0 end,GetUnitDefID=function(id)return id==13 and 2 or 1 end,
  GetUnitPosition=function()return 512,0,512 end,SetUnitPosition=function()end,SetUnitNanoPieces=function()end,DestroyUnit=function(id)destroyed[id]=true end}}, {__index=_G})
 chunk(read('scripts/hivemindscript.lua'),e);local co=coroutine.create(e.integrateNewMembers);local ok,err=coroutine.resume(co);assert(ok,err)
 assert(destroyed[11] and not destroyed[12] and not destroyed[14] and not destroyed[16])
 if charge==0 then assert(destroyed[13] and destroyed[15] and gg.HiveMind[1][200].rewindMilliSeconds==450)
 else assert(not destroyed[13] and not destroyed[15] and gg.HiveMind[1][200].rewindMilliSeconds==45000)end
end
do
 local e=setmetatable({gadget={},gaiaTeamID=0,GG={AerosolAffectedCivilians={[42]='wanderlost'},TollWutoxAfflicted={[42]=42}}},{__index=_G})
 local source=read('luarules/gadgets/game_civilians.lua')
 chunk(assert(source:match('(function gadget:UnitDestroyed%(.-\nend)')),e)
 e.gadget:UnitDestroyed(42,1,1)
 assert(not e.GG.AerosolAffectedCivilians[42] and not e.GG.TollWutoxAfflicted[42],'dead victim remained a source')
end
print('PASS: zombie pursuit/melee, contact infection, hive/water/military/robot choices, blocked/dead goals, cadence/lifetime, owner entrypoints, numeric animation handles, distinct poses, hive admission/capacity')
