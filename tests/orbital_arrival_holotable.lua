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
  local samples, messages = {}, {}
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
    Echo=function(message) messages[#messages+1]=message end,
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
      draw=function(renderer,w,h,art,age,fade,progress,live)
        assert(w==1280 and h==720 and art=='loading.png' and live==17)
        renderer.artworkAvailable=not options.noArtwork
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
    widget=object, count=count, samples=samples, settings=settings, messages=messages,
    tick=function(delta,start)
      clock=clock+delta; if start then frame=1 end
      object:DrawScreenEffects()
    end,
    wait=function(delta) clock=clock+delta end,
    isHidden=function() return hidden end,
  }
end

local function messageCount(s, text)
  local count=0
  for _,message in ipairs(s.messages) do
    if message:find(text,1,true) then count=count+1 end
  end
  return count
end

-- A stall AFTER the initial warm-up used to jump directly from fade zero to
-- one, skipping every pixel in the shader's strictly interior holotable branch.
for _, gap in ipairs({0.5, 0.905, 3}) do
  local stalled = scene()
  stalled.tick(0, true)
  stalled.widget:DrawScreenPost()
  stalled.tick(gap)
  local first = stalled.samples[#stalled.samples]
  assert(first.fade > 0 and first.fade < 1,
    'post-warmup ' .. gap .. 's stall skipped the complete holotable handover')
  assert(first.fade <= 0.1 + 1e-7, 'a startup stall rushed past the initial projection')
  local elapsed=WG.MosaicArrival.elapsed
  stalled.wait(gap)
  stalled.widget:DrawScreenPost()
  near(WG.MosaicArrival.elapsed,elapsed,'post pass advanced stalled presentation time')
  near(stalled.samples[#stalled.samples].fade,first.fade,'post pass changed the stalled projection')
  stalled.widget:KeyPress(27)
end

-- Repeated slow frames must show projection, breakup and lingering fragments,
-- then leave the same first orbital snapshot and the same later shot pacing.
local slow=scene()
slow.tick(0,true)
local interior,early,breakup,linger=0,false,false,false
for _=1,20 do
  slow.tick(3)
  local sample=slow.samples[#slow.samples]
  if sample.fade>=1 then break end
  interior=interior+1
  early=early or sample.fade<=0.3
  breakup=breakup or (sample.fade>=0.35 and sample.fade<=0.65)
  linger=linger or (sample.fade>=0.7 and sample.fade<=0.95)
  near(A.cloudDescent(sample.progress),0,'stalled blend exposed cloud transit')
  local elapsed=WG.MosaicArrival.elapsed
  slow.widget:DrawScreenPost()
  near(WG.MosaicArrival.elapsed,elapsed,'post pass counted as a new presentation frame')
end
assert(interior>=9 and early and breakup and linger,'slow startup did not show the handover phases')
near(slow.samples[#slow.samples].fade,1)
near(WG.MosaicArrival.elapsed,A.blendSeconds,'slow blend consumed an orbital hold')
assert(messageCount(slow,'holotable v2; artwork=true')==1,'handover readiness was not reported once')
assert(messageCount(slow,'holotable handover complete; transition draws='..interior)==1,
  'handover diagnostics counted post passes or missed transition draws')
for stage=1,4 do
  local _,actual=A.snapDescent(WG.MosaicArrival.descent)
  assert(actual==stage,'slow blend changed the subsequent shot order')
  slow.tick(3)
end
near(WG.MosaicArrival.elapsed,A.revealStart)
slow.tick(3)
assert(not WG.MosaicArrival and not slow.isHidden(),'slow startup did not release the interface')
assert(messageCount(slow,'holotable handover complete;')==1,'handover completion repeated during zoom')

-- Recovery discards old stall time: the next healthy display frame advances
-- by its own delta rather than catching up and erasing the remaining tiles.
local recovery=scene()
recovery.tick(0,true)
recovery.tick(3)
local resumed=WG.MosaicArrival.elapsed
recovery.tick(1/60)
near(WG.MosaicArrival.elapsed,resumed+1/60,'startup stall left catch-up time behind')
recovery.tick(1/60); recovery.tick(1/60)
local middle=WG.MosaicArrival.elapsed
recovery.tick(3)
assert(WG.MosaicArrival.elapsed-middle<=0.05+1e-7,'mid-blend stall skipped the tile breakup')
resumed=WG.MosaicArrival.elapsed
recovery.tick(1/60)
near(WG.MosaicArrival.elapsed,resumed+1/60,'mid-blend stall left catch-up time behind')
recovery.widget:KeyPress(27)
assert(not WG.MosaicArrival and not recovery.isHidden())

-- At healthy display rates, the original half-second handover is exact; the
-- protective cap must neither slow ordinary playback nor quantize its beats.
for _,fps in ipairs({20,25,30,60,144}) do
  local normal=scene()
  normal.tick(0,true)
  local frames=math.floor(A.blendSeconds*fps)
  for _=1,frames do normal.tick(1/fps) end
  local remainder=A.blendSeconds-frames/fps
  if remainder>1e-7 then normal.tick(remainder) end
  near(WG.MosaicArrival.elapsed,A.blendSeconds,'healthy '..fps..' FPS blend changed duration')
  near(normal.samples[#normal.samples].fade,1,'healthy blend did not reach clean orbit')
  normal.widget:KeyPress(27)
end

-- The renderer's missing-art fallback must be explicit in infolog and must
-- never be reported as successful holotable draws.
local missing=scene({noArtwork=true})
missing.tick(0,true)
for _=1,10 do missing.tick(.05); missing.widget:DrawScreenPost() end
near(WG.MosaicArrival.elapsed,A.blendSeconds)
assert(messageCount(missing,'holotable v2; artwork=false')==1)
assert(messageCount(missing,'holotable unavailable: loading artwork missing;')==1)
assert(messageCount(missing,'holotable handover complete; transition draws=0')==1)
missing.widget:KeyPress(27)
assert(not WG.MosaicArrival and not missing.isHidden(),'missing-art fallback retained the interface')

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
for _=1,7 do s.tick(.05) end
near(s.samples[#s.samples].fade,.8)
assert(s.count.lock==0)
s.tick(.05); s.tick(.025)
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
print('PASS: post-warmup and repeated stalls retain holotable phases; healthy 20-144 FPS keeps 0.5s blend; recovery has no catch-up debt; four holds/cloud reveal unchanged; static loading and 6s preparation excluded; post-pass reuse; no camera writes; Escape and failure cleanup')
