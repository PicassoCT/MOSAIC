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
assert(A.loadingState(0)==0)
local f,d=A.loadingState(60); assert(f==1 and d==A.holdDescent)
A.writeHandoff('art.png',20,1,0.16)
local tex,age,fade,descent=A.readHandoff(); assert(tex=='art.png' and age==20 and fade==1 and descent==0.16)
Game.mapName='Other'; assert(A.readHandoff()==nil); Game.mapName='LastDayOfDhubai'
local r=A.newRenderer(); assert(r)
assert(r:draw(1920,1080,'art.png',20,1,0.16))
local previous=renderCount
assert(r:draw(1920,1080,'art.png',20,1,0.16)); assert(renderCount==previous,'Post pass repeated procedural work')
r:destroy(); r:destroy()
local function newWidget()
 WG={}; widget={}; widgetHandler={RemoveWidget=function(_,w) if w.Shutdown then w:Shutdown() end end}
 assert(loadstring(VFS.LoadFile('luaui/widgets_mosaic/gfx_orbital_arrival.lua')))()
 widget:Initialize(); return widget
end
settings.FullscreenEdgeMove=0; settings.WindowedEdgeMove=1
A.writeHandoff('art.png',20,1,0.16)
local w=newWidget(); assert(WG.MosaicArrival.active)
w:DrawScreenEffects(); assert(hidden and settings.WindowedEdgeMove==0)
time=7; w:DrawScreenEffects(); assert(WG.MosaicArrival.descent==0.16,'Revealed unfinished city')
ready=1; w:DrawScreenEffects(); time=12; w:DrawScreenEffects()
assert(not hidden and not WG.MosaicArrival and WG.MosaicArrivalFinished)
assert(settings.FullscreenEdgeMove==0 and settings.WindowedEdgeMove==1)
assert(settings[A.configKey]==''); assert(cameraCalls==0)
-- Cancellation and errors release modal and preserve an already hidden interface.
ready=0; time=20; hidden=true
w=newWidget(); w:DrawScreenEffects(); WG.MosaicArrival.skip()
assert(hidden and not WG.MosaicArrival)
hidden=false; time=30
w=newWidget(); w:DrawScreenEffects(); w:Shutdown(); assert(not hidden and not WG.MosaicArrival)
time=40; w=newWidget(); textureFailure=true; w:DrawScreenEffects()
assert(not hidden and not WG.MosaicArrival); textureFailure=false
shaderFailure=true; w=newWidget(); assert(not WG.MosaicArrival and not hidden); shaderFailure=false
frame=300; w=newWidget(); assert(not WG.MosaicArrival,'Midgame reload replayed arrival')
frame=0; ready=0; time=50; w=newWidget(); w:DrawScreenEffects()
time=62; w:DrawScreenEffects(); time=67; w:DrawScreenEffects()
assert(not hidden and not WG.MosaicArrival,'Readiness timeout did not release UI')
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
print('PASS: handoff, same-frame GPU cache, city readiness/timeout, input routing, skip/failure/reload cleanup; zero camera writes')
-- Exercise the real location widget on both map spellings, including resize.
Spring.SendLuaRulesMsg=function(s) assert(s:match('City: Dubai')); end
Spring.PlaySoundFile=function() end
gl.Text=noop
for _,name in ipairs({'LastDayOfDubai v1','LastDayOfDhubai v2'}) do
 Game.mapName=name; widget={}; WG={}; time=0;frame=0
 assert(loadstring(VFS.LoadFile('luaui/widgets_mosaic/gui_cityname.lua')))()
 widget:Initialize(); assert(type(WG.DrawMosaicArrivalLocation)=='function')
 widget:ViewResize(1280,720); WG.DrawMosaicArrivalLocation(1280,720,2,0.5)
 widget:Shutdown(); assert(WG.DrawMosaicArrivalLocation==nil)
end
print('PASS: both Dubai/Dhubai location overrides and title resize/cleanup')
