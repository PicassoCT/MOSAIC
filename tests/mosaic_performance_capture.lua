-- Run from repository root with Lua 5.1+.
local now,frame=0,0
local logs,files,globals={},{},{}
local nativeIO=io
local function contains(text)
    for _,s in ipairs(logs) do if s:find(text,1,true) then return true end end
    return false
end
Spring={GetTimer=function() return now end,DiffTimers=function(a,b) return a-b end,
    Echo=function(s) logs[#logs+1]=s end,GetGameFrame=function() return 42 end,
    GetDrawFrame=function() return frame end,GetViewGeometry=function() return 1920,1080 end,
    GetCameraState=function() return {name='ta',px=1,py=2,pz=3} end,
    GetGameSpeed=function() return 1,1,true end,GetConfigInt=function(_,v) return v end,
    CreateDir=function() end}
Game={mapName='test',gameVersion='test'};Engine={version='test'}
widget={whInfo={name="Mosaic Performance Capture"}}
local w={whInfo={name='Test renderer'}}
local original=function(self,x) assert(self==w);now=now+.002;return x,nil,'tail',nil end
w.DrawWorld=original
widgetHandler={widgets={w,widget},DrawWorldList={w},DrawScreenPostList={widget}}
function widgetHandler:RegisterGlobal(owner,name,fn) assert(owner==widget);globals[name]=fn end
function widgetHandler:DeregisterGlobal(owner,name) assert(owner==widget);globals[name]=nil end
assert(loadfile('luaui/widgets_mosaic/dbg_mosaic_performance.lua'))()
io={open=function(path)
    return {write=function(self,s) files[path]=s;return self end,close=function() end}
end}
widget:Initialize()
assert(globals.MosaicPerfDrawEnabled('clouds'))
assert(not widget:TextCommand('mosaicperformance start 5 nope'))
widget:TextCommand('mosaicperf effect clouds off')
assert(not globals.MosaicPerfDrawEnabled('clouds'))
widget:TextCommand('mosaicperf start 5 baseline')
assert(w.DrawWorld==original) -- frame-only mode has no timing hooks
widget:TextCommand('mosaicperf effect clouds on')
assert(not globals.MosaicPerfDrawEnabled('clouds')) -- reject mutation during capture
now=3;frame=1;widget:DrawScreenPost()
widget:DrawScreenPost() -- duplicate callback is not another frame
for i=1,50 do now=3+i*.1;frame=frame+1;widget:DrawScreenPost() end
assert(contains('10.00 FPS; mean 100.00 ms'))
assert(contains('50 intervals'))
local csv
for _,s in pairs(files) do csv=s end
assert(csv:find('effect_clouds=false',1,true))
assert(csv:find('frame_interval,ms',1,true))
widget:TextCommand('mosaicperf reset');assert(globals.MosaicPerfDrawEnabled('clouds'))
widget:TextCommand('mosaicperf start 5 timed lua')
assert(w.DrawWorld~=original)
now=now+3;frame=frame+1;widget:DrawScreenPost()
local function pack(...) return {n=select('#',...),...} end
local result=pack(w:DrawWorld(17))
assert(result.n==4 and result[1]==17 and result[2]==nil and result[3]=='tail' and result[4]==nil)
now=now+.1;frame=frame+1;widget:DrawScreenPost()
widget:TextCommand('mosaicperf stop');assert(w.DrawWorld==original)
assert(contains('LuaUI Test renderer:DrawWorld'))
-- Never overwrite a callback replaced by another widget while capturing.
widget:TextCommand('mosaicperf start 5 replace lua')
local replacement=function() end;w.DrawWorld=replacement
widget:TextCommand('mosaicperf stop');assert(w.DrawWorld==replacement)
w.DrawWorld=original
-- File errors still leave hooks restored and useful log output.
io.open=function() return nil,'denied' end
widget:TextCommand('mosaicperf start 5 denied lua')
now=now+3;frame=frame+1;widget:DrawScreenPost()
now=now+.1;frame=frame+1;widget:DrawScreenPost()
widget:TextCommand('mosaicperf stop');assert(w.DrawWorld==original)
assert(contains('CSV unavailable:'))
widget:TextCommand('mosaicperf start 5 teardown lua')
widget:Shutdown();assert(w.DrawWorld==original and globals.MosaicPerfDrawEnabled==nil)
io=nativeIO
print('PASS: pacing, warmup, duplicate frames, modes, nil returns, hooks, gates, metadata, file failure, shutdown')
