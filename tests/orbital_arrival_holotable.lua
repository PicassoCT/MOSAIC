-- Run from the repository root: lua5.1 tests/orbital_arrival_holotable.lua
-- Execute the real widget/helper with a renderer spy that simulates expensive
-- compilation, allocation and first draw. No engine or camera is simulated.
local A = assert(loadfile('luaui/widgets_mosaic/include/orbital_arrival.lua'))()
local noop = function() end
local function near(a, b, message)
  assert(math.abs(a - b) < 0.00001, message or (tostring(a) .. ' ~= ' .. tostring(b)))
end
assert(A.blendSeconds == 0.5 and A.stepSeconds == 0.5 and A.revealSeconds == 0.9,
  'accepted arrival timing changed')
near(A.descentSeconds, 3.4)

local function scene(options)
  options = options or {}
  local clock, frame = 0, 0
  local hidden = options.hidden or false
  local settings = {FullscreenEdgeMove=1, WindowedEdgeMove=0}
  local count = {created=0, allocated=0, deleted=0, draws=0, destroyed=0, copies=0, art=0, lock=0}
  local samples = {}
  local firstDraw = true
  GL = {LINEAR=1, CLAMP_TO_EDGE=2, LINES=3}
  Game = {mapName='LastDayOfDhubai', mapChecksum=13579, gameID='holotable-test'}
  WG, widget = {}, {}
  Spring = {
    GetTimer=function() return clock end,
    DiffTimers=function(a,b) return a-b end,
    GetGameFrame=function() return frame end,
    GetViewGeometry=function() return 1280,720,139,43 end,
    GetConfigString=function(k,d) return settings[k] or d end,
    SetConfigString=function(k,v,temporary) assert(temporary); settings[k]=v end,
    GetConfigInt=function(k,d) if settings[k]==nil then return d end; return settings[k] end,
    SetConfigInt=function(k,v,temporary) assert(temporary); settings[k]=v end,
    IsGUIHidden=function() return hidden end,
    SendCommands=function(command) assert(command=='hideinterface'); hidden=not hidden end,
    Echo=noop,
    SetCameraState=function() error('physical camera changed') end,
  }
  gl = {
    Color=noop, Rect=noop, Texture=noop, LineWidth=noop, Vertex=noop,
    TexRect=function() count.art=count.art+1 end,
    BeginEnd=function(_,fn) fn() end,
    Text=function(text) if text=='TARGET LOCK' then count.lock=count.lock+1 end end,
    CreateTexture=function()
      count.allocated=count.allocated+1
      if options.allocationFail then return nil end
      clock=clock+(options.allocationCost or 0)
      return 17
    end,
    DeleteTexture=function(id) assert(id==17); count.deleted=count.deleted+1 end,
    CopyToTexture=function(_,a,b,x,y,w,h)
      assert(a==0 and b==0 and x==139 and y==43 and w==1280 and h==720)
      count.copies=count.copies+1
    end,
  }
  A.newRenderer = function()
    count.created=count.created+1
    clock=clock+(options.compileCost or 0)
    if options.shaderFail then return nil end
    return {
      draw=function(_,w,h,art,age,fade,progress,live)
        assert(w==1280 and h==720 and art=='loading.png' and live==17)
        count.draws=count.draws+1
        samples[#samples+1]={fade=fade, progress=progress, age=age}
        if firstDraw then clock=clock+(options.drawCost or 0); firstDraw=false end
        return not options.drawFail
      end,
      destroy=function() count.destroyed=count.destroyed+1 end,
    }
  end
  VFS = {Include=function(path)
    assert(path=='luaui/widgets_mosaic/include/orbital_arrival.lua'); return A
  end}
  widgetHandler = {RemoveWidget=function(_,w) w:Shutdown() end}
  A.beginHandoff(); A.writeHandoff('loading.png',0,0,0)
  assert(loadfile('luaui/widgets_mosaic/gfx_orbital_arrival.lua'))()
  local object=widget
  object:Initialize()
  return {
    widget=object, count=count, samples=samples, settings=settings,
    tick=function(delta,start)
      clock=clock+delta; if start then frame=1 end
      object:DrawScreenEffects()
    end,
    isHidden=function() return hidden end,
  }
end

-- Loading remains plain, including long waits and the post-screen pass.
local s=scene({compileCost=2, allocationCost=1, drawCost=3})
s.tick(20); s.widget:DrawScreenPost()
assert(s.count.created==0 and s.count.allocated==0 and s.count.lock==0 and s.count.art==2)
s.tick(0,true)
assert(s.count.created==1 and s.count.allocated==1 and s.count.copies==1)
near(s.samples[#s.samples].fade,0,'first snapshot preparation exposed the hologram early')
near(WG.MosaicArrival.elapsed,0)
local firstAge=s.samples[#s.samples].age
s.widget:DrawScreenPost()
near(s.samples[#s.samples].fade,0)
near(s.samples[#s.samples].age,firstAge,'post pass advanced the clock')
assert(s.count.lock==0)
s.tick(.05)
near(s.samples[#s.samples].fade,.1,'GPU warm-up consumed the handover')
assert(s.count.lock==0,'telemetry acquired a moving projection too early')
s.tick(.35)
near(s.samples[#s.samples].fade,.8)
assert(s.count.lock==0)
s.tick(.075)
near(s.samples[#s.samples].fade,.95)
assert(s.count.lock>0,'target lock did not appear as the image stabilized')
s.tick(.025)
near(s.samples[#s.samples].fade,1)
near(WG.MosaicArrival.elapsed,A.blendSeconds)
local stops={0,.30,.64,1}
for stage=1,4 do
  local optical,actual=A.snapDescent(WG.MosaicArrival.descent)
  near(optical,stops[stage]); assert(actual==stage)
  near(A.cloudDescent(WG.MosaicArrival.descent),0)
  near(s.samples[#s.samples].fade,1,'hologram leaked into the zoom')
  s.tick(A.stepSeconds)
end
near(WG.MosaicArrival.elapsed,A.revealStart)
s.tick(.4)
assert(A.cloudDescent(WG.MosaicArrival.descent)>0)
s.tick(.5)
-- Absolute timer subtraction can round just below the terminal frame.
if WG.MosaicArrival then near(WG.MosaicArrival.elapsed,A.descentSeconds); s.tick(1/60) end
assert(not WG.MosaicArrival and WG.MosaicArrivalFinished and not s.isHidden())
assert(s.count.deleted==1 and s.count.destroyed==1)
assert(s.settings.FullscreenEdgeMove==1 and s.settings.WindowedEdgeMove==0)
local draws=s.count.draws
s.widget:DrawScreenEffects(); s.widget:DrawScreenPost(); s.widget:Shutdown()
assert(s.count.draws==draws and s.count.deleted==1 and s.count.destroyed==1)
assert(A.introPhase()=='played')

-- Escape, errors and prior hidden-UI state retain their original cleanup.
for _,options in ipairs({{hidden=false},{hidden=true},{shaderFail=true},{allocationFail=true},{drawFail=true}}) do
  local r=scene(options); r.tick(0,true)
  if WG.MosaicArrival then r.widget:KeyPress(27) end
  assert(not WG.MosaicArrival and r.isHidden()==(options.hidden or false))
  assert(r.settings.FullscreenEdgeMove==1 and r.settings.WindowedEdgeMove==0)
  assert(r.count.deleted<=1 and r.count.destroyed<=1)
end
local beforeStart=scene(); beforeStart.widget:KeyPress(27)
assert(not WG.MosaicArrival and beforeStart.count.created==0)
print('PASS: static loading; excluded 6s first-frame preparation; unchanged 0.5s blend/four holds/cloud reveal; delayed lock only during projection; post-pass reuse; no camera writes; Escape and failure cleanup')
