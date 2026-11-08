-- Production lifecycle and visibility regression checks: texlua tests/hivemind_cognition_test.lua
local units={
 [1]={def=1,ally=0,active=1,x=100,y=0,z=100},
 [2]={def=1,ally=1,active=1,x=500,y=0,z=100,cloaked=true},
 [3]={def=2,ally=0,active=0,x=300,y=0,z=100},
 [10]={def=3,ally=1,x=180,y=0,z=180},
 [11]={def=3,ally=1,x=220,y=0,z=140},
}
local hiddenPositions,scans,vertices,paused,fullView=0,0,0,false,false
local frame,globalActive=0,0
local params,teams,commands,messages={},{},{},{}
local unitWrites,teamWrites=0,0
UnitDefs={[1]={name='hivemind'},[2]={name='aicore'},[3]={name='civilian',customParams={}}}
Game={gameSpeed=30,mapSizeX=4096,mapSizeZ=4096}
Spring={
 ValidUnitID=function(id) return units[id]~=nil end,
 GetUnitIsDead=function(id) return not units[id] or units[id].dead end,
 SetUnitRulesParam=function(id,key,v,scope)
  assert(scope.inlos and not scope.public,'source activity published publicly')
  params[id]=params[id] or {};params[id][key]=v;unitWrites=unitWrites+1
 end,
 SetTeamRulesParam=function(id,key,v,scope)
  assert(scope.allied and not scope.public,'team privileges published publicly')
  teams[id]=teams[id] or {};teams[id][key]=v;teamWrites=teamWrites+1
 end,
 SetGameRulesParam=function(key,v) if key=='slowMoActive' then globalActive=v end end,
 SendCommands=function(c) commands[#commands+1]=c end,PlaySoundFile=function() end,
 GetGameFrame=function() return frame end,
}
SendToUnsynced=function(...) messages[#messages+1]={...} end
GG={HiveMind={
 [0]={[1]={rewindMilliSeconds=500,boolActive=true},[3]={rewindMilliSeconds=500,boolActive=false}},
 [1]={[2]={rewindMilliSeconds=500,boolActive=false}},
}}
gadget={};gadgetHandler={IsSyncedCode=function() return true end}
dofile('luarules/gadgets/game_SlowMo.lua');gadget:Initialize()
assert(params[1].slowMoSourceActive==0 and teams[0].slowMoPrivileged==0,'reload retained stale flags')
gadget:GameFrame(1)
assert(globalActive==1 and params[1].slowMoSourceActive==1 and params[2].slowMoSourceActive==1)
assert(params[3].slowMoSourceActive==0 and teams[0].slowMoPrivileged==1)
local uw,tw=unitWrites,teamWrites
gadget:GameFrame(2)
assert(unitWrites==uw and teamWrites==tw,'unchanged flags sent every frame')
GG.HiveMind[0][1].boolActive=false;GG.HiveMind[0][3].boolActive=true
gadget:GameFrame(4)
assert(params[1].slowMoSourceActive==0 and params[3].slowMoSourceActive==1,'same-team source handoff missed')
assert(teamWrites==tw,'handoff needlessly rebroadcast team state')
for _,t in pairs(GG.HiveMind) do for _,d in pairs(t) do d.rewindMilliSeconds=0;d.boolActive=false end end
gadget:GameFrame(5)
assert(globalActive==0 and params[2].slowMoSourceActive==0 and params[3].slowMoSourceActive==0)
assert(teams[0].slowMoPrivileged==0 and commands[#commands]=='setSpeed 1.0')
for _,msg in ipairs(messages) do for _,v in ipairs(msg) do assert(type(v)~='table','table crossed sync boundary') end end
print('PASS: synced start, transition-only publication, source handoff, drain/stop, reload and primitive messages')

-- Unsynced client. Hidden units deliberately remain in the discovery list.
Spring.GetAllUnits=function() local t={};for id in pairs(units) do t[#t+1]=id end;return t end
Spring.GetUnitDefID=function(id) return units[id] and units[id].def end
Spring.GetSpectatingState=function() return fullView,fullView end
Spring.GetMyAllyTeamID=function() return 0 end
Spring.GetMyTeamID=function() return 0 end
Spring.GetUnitAllyTeam=function(id) return units[id].ally end
Spring.GetUnitIsCloaked=function(id) return units[id].cloaked or false end
Spring.GetUnitNoDraw=function(id) return units[id].noDraw or false end
Spring.GetUnitLosState=function(id) return {los=not units[id].hidden} end
Spring.GetUnitRulesParam=function(id) return units[id] and units[id].active end
Spring.GetCameraPosition=function() return 100,350,500 end
Spring.GetCameraVectors=function() return {right={1,0,0},up={0,1,0}} end
Spring.GetUnitPosition=function(id)
 local u=units[id];if u.hidden or (u.cloaked and u.ally==1 and not fullView) then hiddenPositions=hiddenPositions+1 end
 return u.x,u.y,u.z
end
Spring.GetUnitViewPosition=Spring.GetUnitPosition
Spring.GetGroundHeight=function() return 0 end
Spring.IsSphereInView=function() return true end
Spring.GetVisibleUnits=function() scans=scans+1;return {10,11} end
Spring.GetGameSpeed=function() return 1,.4,paused end
Spring.GetGameRulesParam=function(k) if k=='slowMoActive' then return globalActive else return .4 end end
Spring.GetTeamRulesParam=function() return 1 end
Spring.GetViewGeometry=function() return 800,600,40,20 end
Spring.GetSelectedUnits=function() return {1} end
Spring.Echo=function() end;Spring.Log=function() end
GL={ALL_ATTRIB_BITS=1,LINES=1,SRC_ALPHA=2,ONE_MINUS_SRC_ALPHA=3,LINEAR=4,NEAREST=5,CLAMP_TO_EDGE=6}
gl={BeginEnd=function(_,f) f() end,Vertex=function(x,y,z)
 assert(x==x and y==y and z==z,'NaN vertex');vertices=vertices+1
end}
for _,name in ipairs({'Color','PushAttrib','PopAttrib','DepthTest','DepthMask','Blending','LineWidth'}) do gl[name]=function() end end
local M=dofile('luaui/widgets_mosaic/include/hivemind_cognition.lua')
local c=M.New();c:Update(1,false);assert(#c:Collect()==0 and scans==0)
c:Update(.5,true);assert(#c:Collect()==1 and hiddenPositions==0)
assert(#c.sources[1].glyphs==M.maxGlyphs/M.maxSources)
local n=scans;c:Update(.01,true);c:Collect();c:Collect();assert(scans==n,'unthrottled unit discovery')
c:Update(1,true);c:Draw(1);assert(vertices>0)
-- Cached endpoints becoming hidden must never have their positions fetched.
units[10].hidden=true;units[11].cloaked=true;hiddenPositions=0;c:Draw(1)
assert(hiddenPositions==0,'cached graph leaked hidden/cloaked endpoint')
units[1].ally=1;units[1].cloaked=true;assert(#c:Collect()==0,'source survived enemy cloak')
units[1].ally=0;assert(#c:Collect()==1,'allied cloaked icon lost its effect')
c:UnitDestroyed(1);c:Update(.1,true);assert(#c:Collect()==0)
c:UnitCreated(1,1);c:Update(.1,true);assert(#c:Collect()==1)
for id=20,30 do units[id]={def=1,ally=0,active=1,x=id,y=0,z=100};c:UnitCreated(id,1) end
c:Update(.5,true);assert(#c:Collect()==M.maxSources,'source budget exceeded')
c:Update(.1,false);assert(#c:Collect()==0 and next(c.records)==nil,'stop retained active effects')
print('PASS: client discovery, budgets, 2 Hz scan, cloak/LOS filtering, allied icons, death and immediate stop')

-- Full production widget: lazy resources, viewport offsets, reload, pause and local preview.
local alloc,copies,deleted,uniforms=0,0,0,{}
VFS={Include=dofile,LoadFile=function(p) local f=assert(io.open(p));local s=f:read('*a');f:close();return s end}
Platform={glSupportClipSpaceControl=true};LOG={ERROR='error'}
gl.CreateTexture=function() alloc=alloc+1;return alloc end
gl.DeleteTexture=function() deleted=deleted+1 end
gl.CreateShader=function() return 50 end;gl.DeleteShader=function() end
gl.GetUniformLocation=function(_,name) return name end
-- Match engine numeric locations while recording names.
local locations,names={},{}
gl.GetUniformLocation=function(_,name) local i=#names+1;names[i]=name;locations[name]=i;return i end
gl.Uniform=function(i,...) uniforms[names[i]]={...} end
gl.UniformInt=gl.Uniform
gl.UniformMatrix=function(_,name) assert(name=='viewprojectioninverse') end
gl.CopyToTexture=function(_,_,_,x,y,w,h) assert(x==40 and y==20 and w==800 and h==600);copies=copies+1 end
for _,name in ipairs({'UseShader','Texture','TexRect'}) do gl[name]=function() end end
widgetHandler={RemoveWidget=function() error('unexpected widget removal') end}
widget={};dofile('luaui/widgets_mosaic/gfx_slowMoShader.lua');widget:Initialize()
widget:Update(.5);widget:DrawScreenEffects();assert(alloc==0 and copies==0,'idle allocated or copied textures')
globalActive=1;widget:Update(1);widget:DrawScreenEffects()
assert(alloc==2 and copies==2 and uniforms.sourceCount[1]==4,'reload did not restore active source state')
local age=uniforms['rippleSources[0]'][4];local time=uniforms.realTime[1]
paused=true;widget:Update(10);widget:DrawScreenEffects()
assert(uniforms['rippleSources[0]'][4]==age and uniforms.realTime[1]==time,'pause advanced effects')
paused=false;widget:Update(1);widget:DrawScreenEffects();assert(uniforms.realTime[1]>time)
widget:ViewResize();assert(deleted==2);widget:DrawScreenEffects();assert(alloc==4)
globalActive=0;widget:Update(1);local copyCount=copies;widget:DrawScreenEffects();assert(copies==copyCount)
local oldCommands=#commands
assert(widget:TextCommand('hivefx 2'));widget:Update(.2);widget:DrawScreenEffects()
assert(uniforms.sourceCount[1]==1 and #commands==oldCommands,'preview changed gameplay or lit inactive sources')
widget:Update(3);copyCount=copies;widget:DrawScreenEffects();assert(copies==copyCount,'preview did not expire')
widget:Shutdown();assert(deleted==4)
print('PASS: LuaUI reload, idle zero work, lazy allocation, viewport, pause/resume, resize, preview expiry and resource cleanup')
