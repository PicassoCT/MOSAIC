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
VFS.Include=function(p, env)
 local chunk=assert(loadstring(VFS.LoadFile(p)))
 if env then setfenv(chunk,env) end
 return chunk()
end
local noop=function() end
local blend = true
local renderCount = 0
local textureSizes = {}
gl = {CreateShader=function() if not shaderFailure then return id() end end,
 DeleteShader=function(n) deleted[n]=true end, GetShaderLog=function() return '' end,
 CreateTexture=function(w,h)
  if not textureFailure then local n=id(); textureSizes[n]={w,h}; return n end
 end,
 DeleteTexture=function(n) deleted[n]=true end, TextureInfo=function() return {xsize=1920,ysize=1080} end,
 GetUniformLocation=function(_,n) return n end, Uniform=function(n, ...) draws[n]={...} end,
 UniformInt=function(n, ...) draws[n]={...} end,
 UseShader=noop, Texture=noop, Color=noop, TexRect=noop, Text=noop,
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
assert(A.blendSeconds==0.5 and A.stepSeconds==0.35 and A.descentSeconds==2.5)
assert(A.snapshotCount==4 and A.revealSeconds==0.6)
local shots={0,0.30,0.64,1}
for i,optical in ipairs(shots) do
 local start=A.blendSeconds+(i-1)*A.stepSeconds
 local a,stage=A.snapDescent((start+0.01)/A.descentSeconds)
 local b=A.snapDescent((start+A.stepSeconds-0.01)/A.descentSeconds)
 assert(stage==i and a==optical and b==optical, 'planetary shot must hold its own optical scale')
 assert(A.cloudDescent((start+A.stepSeconds-0.01)/A.descentSeconds)==0,
   'cloud reveal started before all four snapshots were shown')
end
assert(A.cloudDescent(A.revealStart/A.descentSeconds)==0)
assert(A.cloudDescent((A.revealStart+0.3)/A.descentSeconds)>0)
assert(A.cloudDescent(1)==1)
A.beginHandoff(); assert(A.introPhase()=='pending')
A.writeHandoff('art.png',20,1,0)
local tex,age,fade,descent=A.readHandoff(); assert(tex=='art.png' and age==20 and fade==1 and descent==0)
A.finishIntro(); assert(A.introPhase()=='finished')
Game.mapName='Other'; assert(A.readHandoff()==nil); Game.mapName='LastDayOfDhubai'
-- Each match chooses a reproducible region; missing game IDs have a stable
-- map fallback. This visual seed must not consume or reseed the global RNG.
local random, randomseed = math.random, math.randomseed
math.random=function() error('Arrival consumed the global RNG') end
math.randomseed=function() error('Arrival reseeded the global RNG') end
local function region(game) return {A.regionOffset(game)} end
local function sameRegion(a,b) return a[1]==b[1] and a[2]==b[2] end
local identity={mapName='LastDayOfDhubai',mapChecksum=4294967295,gameID='match-01'}
local seededRegion=region(identity)
assert(sameRegion(seededRegion,region(identity)), 'same match changed its generated Earth region')
local function packetSignature(packet)
  local out={packet.theme,packet.status,tostring(packet.confidence)}
  for _,line in ipairs(packet.lines) do
    out[#out+1]=line.label .. '=' .. tostring(line.value)
  end
  return table.concat(out,'|')
end
local risk=A.riskPacket(identity)
assert(#risk.lines==5 and risk.confidence>=61 and risk.confidence<=94,
  'orbital risk packet shape or confidence range is invalid')
for _,line in ipairs(risk.lines) do
  assert(type(line.label)=='string' and line.label~='' and line.value>=0 and line.value<=100,
    'orbital risk metric is invalid')
end
assert(packetSignature(risk)==packetSignature(A.riskPacket(identity)),
  'same match changed its orbital risk telemetry')
local alternateRisk=A.riskPacket({mapName=identity.mapName,mapChecksum=identity.mapChecksum,gameID='match-risk-alt'})
assert(packetSignature(risk)~=packetSignature(alternateRisk),
  'different match did not vary orbital risk telemetry')
for _,game in ipairs({
 {mapName='Other',mapChecksum=identity.mapChecksum,gameID=identity.gameID},
 {mapName=identity.mapName,mapChecksum=4294967294,gameID=identity.gameID},
 {mapName=identity.mapName,mapChecksum=identity.mapChecksum,gameID='match-02'},
 {mapName=identity.mapName,mapChecksum=identity.mapChecksum,gameID=string.rep('long\0id',100)},
}) do
 local offset=region(game)
 assert(not sameRegion(seededRegion,offset), 'a changed map or game did not select another region')
 for _,v in ipairs(offset) do assert(v>=0 and v<128, 'invalid procedural region coordinate') end
 assert(sameRegion(offset,region(game)), 'region hash was not deterministic')
end
local fallback=region({mapName=identity.mapName,mapChecksum=identity.mapChecksum})
assert(sameRegion(fallback,region({mapName=identity.mapName,mapChecksum=identity.mapChecksum,gameID=''})),
  'missing gameID did not use the stable map fallback')
assert(not sameRegion(fallback,region({mapName='Other',mapChecksum=identity.mapChecksum})),
  'map fallback ignored the map name')
assert(not sameRegion(region({mapName='ab',mapChecksum='c'}),region({mapName='a',mapChecksum='bc'})),
  'region seed lost the boundaries between identity fields')
assert(sameRegion(region({}),region({})), 'missing identity fields broke the stable fallback')
local r=A.newRenderer(); assert(r)
local rendererRegion={r.regionOffset[1],r.regionOffset[2]}
assert(r:draw(1920,1080,'art.png',20,0,0))
assert(textureSizes[r.orbitTexture][1]==1920 and textureSizes[r.orbitTexture][2]==1080,
  'planetary snapshots were still downsampled below native 1080p')
assert(sameRegion(draws.regionOffset,rendererRegion) and draws.elapsed==nil,
  'Earth shader did not receive its fixed region independently of elapsed time')
local previous=renderCount
assert(r:draw(1920,1080,'art.png',20,0,0)); assert(renderCount==previous,'Post pass repeated procedural work')
assert(r:draw(1920,1080,'art.png',20.04,0.1,0.02))
assert(r:draw(1920,1080,'art.png',20.1,0.2,0.04))
assert(r:draw(1920,1080,'art.png',25,1,0.2))
assert(renderCount==previous,'Stationary orbital snapshot redrew during artwork blending or a hold')
-- Detect a clock reset even when the new age is later than the last Earth
-- render: held snapshots can outlive many display frames without rendering.
assert(r:draw(1920,1080,'art.png',24.9,1,0.2))
assert(renderCount==previous+1,'An age reset during a held snapshot did not invalidate the cache')
-- Resolution and aspect changes refresh the snapshot, but never choose a new
-- region even if Game receives another identity after renderer construction.
local savedGameID=Game.gameID; Game.gameID='identity-changed-after-renderer-creation'
for i,size in ipairs({{1280,720,1280,720},{3840,2160,1920,1080},
 {3840,2159,1920,1079},{3841,2159,1920,1079},{1920,1080,1920,1080}}) do
 previous=renderCount
 local oldTexture=r.orbitTexture
 local oldSize=textureSizes[oldTexture]
 assert(r:draw(size[1],size[2],'art.png',24.9+i*0.01,1,0.2))
 assert(renderCount==previous+1,'Viewport resize or aspect change reused a stale snapshot')
 local actual=textureSizes[r.orbitTexture]
 assert(actual[1]==size[3] and actual[2]==size[4], 'snapshot resolution exceeded its cap or lost native detail')
 if oldSize[1]~=size[3] or oldSize[2]~=size[4] then
  assert(deleted[oldTexture], 'resize leaked the previous orbital texture')
 else
  assert(r.orbitTexture==oldTexture, 'an aspect-only refresh reallocated the same texture dimensions')
 end
 assert(sameRegion(draws.regionOffset,rendererRegion), 'resize changed the selected planet region')
 assert(r:draw(size[1],size[2],'art.png',24.9+i*0.01,1,0.2))
 assert(renderCount==previous+1,'Post pass rerendered a resized snapshot')
end
Game.gameID=savedGameID
-- Cuts must bypass the cache, including the fourth (closest) planetary shot.
for stage=2,4 do
 previous=renderCount
 local progress=(A.blendSeconds+(stage-1)*A.stepSeconds)/A.descentSeconds
 local sampleAge=25+stage*0.01
 assert(r:draw(1920,1080,'art.png',sampleAge,1,progress,'live.png'))
 assert(renderCount==previous+1 and r.lastStage==stage,
   '12 Hz cache swallowed a planetary snapshot')
 assert(draws.descent[1]==0 and draws.hasLive[1]==0,
   'a planetary snapshot started the live-city compositor')
 assert(r:draw(1920,1080,'art.png',sampleAge,1,progress,'live.png'))
 assert(renderCount==previous+1,'Post pass repeated an optical cut')
 assert(sameRegion(draws.regionOffset,rendererRegion), 'an optical cut chose a different planet region')
end
local function revealProgress(x) return (A.revealStart+x*A.revealSeconds)/A.descentSeconds end
previous=renderCount
assert(r:draw(1920,1080,'art.png',25.05,1,revealProgress(0.01),'live.png'))
assert(renderCount==previous+1,'Entering the cloud reveal did not invalidate the cache')
assert(r:draw(1920,1080,'art.png',25.2,1,revealProgress(0.3),'live.png'))
previous=renderCount
assert(r:draw(1920,1080,'art.png',25.24,1,revealProgress(0.6),'live.png'))
assert(renderCount==previous and draws.hasLive[1]==0,
  'compositor exposed the live projection before its cached clouds were ready')
assert(r:draw(1920,1080,'art.png',25.3,1,revealProgress(0.61),'live.png'))
assert(renderCount==previous+1,'Moving cloud descent did not refresh at the bounded 12 Hz rate')
assert(draws.hasLive[1]==1,'cloud reveal did not enable the captured city')
previous=renderCount
assert(r:draw(1920,1080,'art.png',25.31,1,1,'live.png'))
assert(renderCount==previous+1 and r.lastCloudDescent==1,
  'final cloud frame was swallowed by the cache')
assert(r:draw(1920,1080,'art.png',30,1,1,'live.png'))
assert(renderCount==previous+1,'Completed cloud frame needlessly repeated procedural work')
assert(sameRegion(draws.regionOffset,rendererRegion), 'cloud reveal changed the selected planet region')
r:destroy(); r:destroy()
math.random,math.randomseed=random,randomseed
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
  'the working half-second artwork/sky blend changed')
assert(A.snapDescent(WG.MosaicArrival.descent)==0 and draws.descent[1]==0,
  'the first snapshot was consumed underneath the loading artwork')
time=0.5; w:DrawScreenEffects()
assert(draws.fade[1]==1 and math.abs(WG.MosaicArrival.descent-0.2)<0.00001,
  'first planetary snapshot must be fully visible after the 0.5s blend')
for stage=2,4 do
 time=A.blendSeconds+(stage-1)*A.stepSeconds; w:DrawScreenEffects()
 local optical,actualStage=A.snapDescent(WG.MosaicArrival.descent)
 assert(actualStage==stage and optical==shots[stage] and draws.descent[1]==0,
   'the four planetary snapshots must finish before cloud reveal')
end
time=A.revealStart; w:DrawScreenEffects()
assert(WG.MosaicArrival and draws.descent[1]==0,'clouds revealed the city during the fourth shot')
time=2.2; w:DrawScreenEffects()
assert(WG.MosaicArrival and draws.descent[1]>0,'cloud reveal did not follow the four snapshots')
time=2.5; w:DrawScreenEffects()
assert(not hidden and not WG.MosaicArrival and WG.MosaicArrivalFinished,
  'four snapshots plus clouds must finish in nominal 2.5s without city readiness')
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
for i=1,60 do time=50+i/20; w:DrawScreenEffects() end
assert(not hidden and not WG.MosaicArrival, 'late-initialized arrival did not finish')
-- Even multi-second startup stalls must show every planetary shot. Simulation
-- frame stays fixed: progress is still driven by rendered wall time when paused.
A.beginHandoff(); frame=1; time=60; w=newWidget(); w:DrawScreenEffects()
local seen={1}
for i=1,8 do
 time=60+i; w:DrawScreenEffects(); w:DrawScreenPost()
 if WG.MosaicArrival then
  local _,stage=A.snapDescent(WG.MosaicArrival.descent)
  if stage~=seen[#seen] then seen[#seen+1]=stage end
  if stage<4 then assert(draws.descent[1]==0,'startup stall bypassed a planetary shot') end
 end
end
assert(table.concat(seen,',')=='1,2,3,4','slow startup skipped a planetary snapshot')
assert(not WG.MosaicArrival and not hidden,'paused or stalled arrival did not release the city')
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
print('PASS: static loading bridge, stable generated Earth region, native 1080p stationary snapshot cache, bounded 12Hz cloud reveal and live handoff, four cuts, resize, stall-safe timing, input/cleanup, no camera writes')
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
