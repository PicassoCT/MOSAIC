-- Run from repository root: lua5.1 tests/orbital_arrival.lua
local root = ''
local time, frame, ready, hidden = 0, 0, 0, false
local settings, draws, deleted, cameraCalls = {}, {}, {}, 0
local textureFailure, shaderFailure = false, false
local serial = 0
local function id() serial = serial + 1; return serial end
GL = {LINEAR=1, CLAMP_TO_EDGE=2, PROJECTION=3, MODELVIEW=4}
Spring = {
 GetTimer=function() return time end, DiffTimers=function(a,b) return a-b end,
 GetGameFrame=function() return frame end, GetGameRulesParam=function() return ready end,
 GetConfigString=function(k,d) return settings[k] or d end,
 SetConfigString=function(k,v,temp) assert(temp == true); settings[k]=v end,
 GetConfigInt=function(k,d) if settings[k]==nil then return d end; return settings[k] end,
 SetConfigInt=function(k,v,temp) assert(temp == true); settings[k]=v end,
 IsGUIHidden=function() return hidden end,
 SendCommands=function(c) assert(c=='hideinterface'); hidden=not hidden end,
 GetViewGeometry=function() return 1920,1080,0,0 end,
 Echo=function() end, SetCameraState=function() cameraCalls=cameraCalls+1; error('Physical camera move') end,
}
Game={mapName='LastDayOfDhubai', mapSizeX=8192, mapSizeZ=8192}
VFS={LoadFile=function(p) local f=assert(io.open(root..p)); local s=f:read('*a'); f:close(); return s end}
VFS.Include=function(p) return assert(loadstring(VFS.LoadFile(p)))() end
local noop=function() end
local blend = true
local renderCount = 0
gl = {CreateShader=function() if not shaderFailure then return id() end end,
 DeleteShader=function(n) deleted[n]=true end, GetShaderLog=function() return '' end,
 CreateTexture=function() if not textureFailure then return id() end end,
 DeleteTexture=function(n) deleted[n]=true end, TextureInfo=function() return {xsize=1920,ysize=1080} end,
 GetUniformLocation=function(_,n) return n end, Uniform=function(n, ...) draws[n]={...} end,
 UniformInt=noop, UseShader=noop, Texture=noop, Color=noop, TexRect=noop,
 Clear=noop, MatrixMode=noop, PushMatrix=noop, PopMatrix=noop, LoadIdentity=noop,
 Blending=function(v) blend=v end,
 CopyToTexture=noop, RenderToTexture=function(_,fn) renderCount=renderCount+1; fn(); assert(blend) end,
}
local A=VFS.Include('luaui/widgets_mosaic/include/orbital_arrival.lua')
-- Loading must remain static, keep its progress bar, and never create shaders.
local picturePasses = 0
gl.TexRect=function() picturePasses = picturePasses + 1 end
gl.Rect=noop; gl.Scale=noop; gl.PushMatrix=noop; gl.PopMatrix=noop
gl.GetViewSizes=function() return 1920,1080 end
VFS.DirList=function() return {'art.png'} end
SG={}; addon={}
local beforeIntro = serial
assert(loadstring(VFS.LoadFile('luaintro/Addons/bg_texture.lua')))()
for i=1,3 do addon.DrawLoadScreen() end
assert(picturePasses==3,'LuaIntro did not draw static artwork on every loading frame')
assert(serial==beforeIntro,'LuaIntro allocated orbital shader/GPU texture during load')
assert(not SG.IsOrbitalArrivalActive(),'Loading progress was suppressed by orbital view')
local art, age, fade = A.readHandoff()
assert(art=='art.png' and age==0 and fade==0,'LuaIntro passed non-static handoff')
local introMain=VFS.LoadFile('luaintro/Addons/main.lua')
assert(not introMain:find('if SG.IsOrbitalArrivalActive and SG.IsOrbitalArrivalActive()',1,true),
  'LuaIntro main hides the progress bar')
addon.Shutdown()
assert(A.introPhase()=='finished','LuaIntro did not mark its informational shutdown')
assert(A.loadingState(0)==0)
local f,d=A.loadingState(60); assert(f==1 and d==0,'loading screen must never advance descent')
assert(A.snapDescent(0)==0 and A.snapDescent(1)==1)
assert(A.blendSeconds==0.5 and A.stepSeconds==0.5 and A.descentSeconds==2.5)
assert(A.snapDescent(0.10)>0 and A.snapDescent(0.10)<0.16, 'first beat must visibly magnify')
assert(A.snapDescent(0.20)>=0.16, 'snap must advance to the next scale')
A.beginHandoff(); assert(A.introPhase()=='pending')
A.writeHandoff('art.png',20,1,0)
local tex,age,fade,descent=A.readHandoff(); assert(tex=='art.png' and age==20 and fade==1 and descent==0)
A.finishIntro(); assert(A.introPhase()=='finished')
Game.mapName='Other'; assert(A.readHandoff()==nil); Game.mapName='LastDayOfDhubai'
local r=A.newRenderer(); assert(r)
assert(r:draw(1920,1080,'art.png',20,1,0.16))
local previous=renderCount
assert(r:draw(1920,1080,'art.png',20,1,0.16)); assert(renderCount==previous,'Post pass repeated procedural work')
assert(r:draw(1920,1080,'art.png',20.04,1,0.2))
assert(renderCount==previous,'Orbital shader still runs at full screen refresh rate')
assert(r:draw(1920,1080,'art.png',20.1,1,0.2))
assert(renderCount==previous+1,'Orbital shader did not refresh at 12 Hz')
r:destroy(); r:destroy()
local function newWidget()
 WG={}; widget={}; widgetHandler={RemoveWidget=function(_,w) if w.Shutdown then w:Shutdown() end end}
 assert(loadstring(VFS.LoadFile('luaui/widgets_mosaic/gfx_orbital_arrival.lua')))()
 widget:Initialize(); return widget
end
settings.FullscreenEdgeMove=0; settings.WindowedEdgeMove=1
A.beginHandoff()
A.writeHandoff('art.png',0,0.2,0)
local w=newWidget(); assert(WG.MosaicArrival.active)
local beforePreGame = serial
local beforeArtwork = picturePasses
w:DrawScreenEffects()
w:DrawScreenPost()
assert(picturePasses>=beforeArtwork+2,
  'LuaUI left a gap between LuaIntro shutdown and the first gameframe')
assert(serial==beforePreGame,'LuaUI compiled orbital shaders before game start')
assert(not hidden and settings.WindowedEdgeMove==1,
  'the arrival must wait for the first advancing simulation frame')
frame=1; w:DrawScreenEffects()
assert(hidden and settings.WindowedEdgeMove==0 and A.introPhase()=='pending',
  'frame > 0 must start the transition even while LuaIntro is pending')
assert(WG.MosaicArrival.descent==0)
time=0.25; w:DrawScreenEffects()
assert(draws.fade[1]>=0.5 and math.abs(WG.MosaicArrival.descent-0.1)<0.00001,
  'the first optical beat starts DURING the blend')
time=0.5; w:DrawScreenEffects()
assert(draws.fade[1]==1 and math.abs(WG.MosaicArrival.descent-0.2)<0.00001,
  'first zoom beat must be complete at 0.5s')
time=1.0; w:DrawScreenEffects()
assert(math.abs(WG.MosaicArrival.descent-0.4)<0.00001, 'second 0.5-second step')
time=1.5; w:DrawScreenEffects()
assert(math.abs(WG.MosaicArrival.descent-0.6)<0.00001, 'third 0.5-second step')
time=2.5; w:DrawScreenEffects()
assert(not hidden and not WG.MosaicArrival and WG.MosaicArrivalFinished,
  'five half-second steps must finish in 2.5s without city readiness')
A.finishIntro(); assert(A.introPhase()=='played','late LuaIntro shutdown clobbered completion')
assert(settings.FullscreenEdgeMove==0 and settings.WindowedEdgeMove==1)
assert(settings[A.configKey]==''); assert(cameraCalls==0)
-- Camera Remember must not mutate/rotate the live camera while arrival owns startup.
Spring.GetCameraNames=function() return {ta=1,ov=2} end
Spring.GetCameraState=function() return {name='ov',mode=2} end
widget={}; WG={MosaicArrival={active=true}}
assert(loadstring(VFS.LoadFile('luaui/widgets_mosaic/camera_remember_mode.lua')))()
widget:SetConfigData({name='ta'}); widget:Initialize()
assert(cameraCalls==0,'Camera Remember mutated camera underneath orbital arrival')
-- A finished intro must not replay even if LuaUI reloads during early frames.
time=4; frame=1; w=newWidget()
assert(not WG.MosaicArrival, 'completed arrival replayed at an early game frame')
-- Cancellation and errors release modal and preserve an already hidden interface.
A.beginHandoff(); time=20; frame=0; hidden=true
w=newWidget(); frame=1; w:DrawScreenEffects(); WG.MosaicArrival.skip()
assert(hidden and not WG.MosaicArrival)
A.beginHandoff(); hidden=false; time=30; frame=0
w=newWidget(); frame=1; w:DrawScreenEffects(); w:Shutdown()
assert(not hidden and not WG.MosaicArrival)
A.beginHandoff(); time=40; frame=0; w=newWidget()
textureFailure=true; frame=1; w:DrawScreenEffects()
assert(not hidden and not WG.MosaicArrival); textureFailure=false
A.beginHandoff(); shaderFailure=true; frame=0
w=newWidget(); assert(WG.MosaicArrival and WG.MosaicArrival.active,
  'widget should only arm the artwork before game start')
frame=1; w:DrawScreenEffects()
assert(not WG.MosaicArrival and not hidden); shaderFailure=false
A.beginHandoff(); frame=A.latestStartFrame+1; w=newWidget()
assert(not WG.MosaicArrival,'midgame reload replayed arrival')
-- A widget initialized just AFTER gameframe begins must still play the zoom.
A.beginHandoff(); frame=1; time=50; w=newWidget()
assert(WG.MosaicArrival and WG.MosaicArrival.active)
w:DrawScreenEffects(); assert(hidden)
time=53; w:DrawScreenEffects()
assert(not hidden and not WG.MosaicArrival, 'late-initialized arrival did not finish')
-- Test the actual router functions: keys must be intercepted BEFORE bound actions.
local source=VFS.LoadFile('luaui/mosaicwidgets.lua')
local first=assert(source:find('local function ArrivalActive',1,true))
local last=assert(source:find('function widgetHandler:CommandsChanged',first,true))
-- Only load the helper; function slicing below avoids handler startup dependencies.
local helper=source:match('(local function ArrivalActive.-\nend)')
local function method(name)
 local start=assert(source:find('function widgetHandler:'..name..'(',1,true))
 local stop=source:find('\nfunction widgetHandler:',start+1,true) or #source+1
 return source:sub(start,stop-1)
end
KEYSYMS={ESCAPE=27}; widgetHandler={WG={}, actionHandler={KeyAction=function() error('Bound action leaked') end}}
assert(loadstring(helper..'\n'..method('KeyPress')..'\n'..method('TextInput')..'\n'..method('MouseWheel')..'\n'..method('CommandNotify')))()
local skipped=false
widgetHandler.WG.MosaicArrival={active=true,skip=function() skipped=true end}
assert(widgetHandler:KeyPress(65,{},false)); assert(widgetHandler:TextInput('a'))
assert(widgetHandler:MouseWheel(true,1)); assert(widgetHandler:CommandNotify(10,{},{}))
assert(widgetHandler:KeyPress(27,{},false) and skipped)
print('PASS: static LuaIntro and load bar, pregame artwork bridge, gameframe-only GPU zoom, 12Hz shader cache, no map gap or camera writes')
-- Exercise the real location widget on both map spellings, including resize.
Spring.SendLuaRulesMsg=function(s) assert(s:match('City: Dubai')); end
Spring.PlaySoundFile=function() end
gl.Text=noop
for _,name in ipairs({'LastDayOfDubai v1','LastDayOfDhubai v2'}) do
 Game.mapName=name; widget={}; WG={}; time=0;frame=0
 assert(loadstring(VFS.LoadFile('luaui/widgets_mosaic/gui_cityname.lua')))()
 widget:Initialize(); assert(WG.DrawMosaicArrivalLocation==nil)
 widget:ViewResize(1280,720)
 widget:Shutdown()
end
print('PASS: both Dubai/Dhubai location overrides and original post-arrival title path')
