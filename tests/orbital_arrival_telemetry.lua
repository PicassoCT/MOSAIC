-- Run from the repository root: lua5.1 tests/orbital_arrival_telemetry.lua
-- Exercise the production widget and inspect submitted draw primitives. The
-- shader renderer is the only stub: this suite verifies the display-rate HUD.
local function read(path)
  local file = assert(io.open(path))
  local result = file:read('*a'); file:close(); return result
end
local A = assert(loadstring(read('luaui/widgets_mosaic/include/orbital_arrival.lua')))()
assert(type(A.targetFrame) == 'function', 'target projection helper missing')
local calls, currentColor, lineWidth, vertices = {}, {1,1,1,1}, 1, nil
local clock, frame, viewW, viewH, hidden = 0, 0, 1920, 1080, false
local settings, nextTexture, allocations, deleted, creates = {}, 0, 0, {}, 0
local packetCalls, lastProgress = 0, nil
local sourcePacket = A.riskPacket
A.riskPacket = function(game)
  packetCalls = packetCalls + 1
  return sourcePacket(game)
end
local function record(kind, fields)
  fields.kind = kind
  fields.color = {unpack(currentColor)}
  calls[#calls + 1] = fields
end
local noop = function() end
GL = {LINES=1, LINEAR=2, CLAMP_TO_EDGE=3}
gl = {
  Color = function(r,g,b,a) currentColor={r,g,b,a or 1} end,
  Rect = function(x1,y1,x2,y2) record('rect',{x1=x1,y1=y1,x2=x2,y2=y2}) end,
  Text = function(text,x,y,size,options)
    record('text',{text=text,x=x,y=y,size=size,options=options})
  end,
  GetTextWidth = function(text) return #text * 0.6 end,
  LineWidth = function(width) lineWidth=width end,
  Vertex = function(x,y) vertices[#vertices+1]={x,y} end,
  BeginEnd = function(mode,fn)
    assert(mode==GL.LINES); vertices={}; fn()
    assert(#vertices%2==0)
    for i=1,#vertices,2 do
      record('line',{x1=vertices[i][1],y1=vertices[i][2],
        x2=vertices[i+1][1],y2=vertices[i+1][2],width=lineWidth})
    end
    vertices=nil
  end,
  CreateTexture = function()
    allocations=allocations+1; nextTexture=nextTexture+1; return nextTexture
  end,
  DeleteTexture = function(id) deleted[id]=true end,
  CopyToTexture=noop, Texture=noop, TexRect=noop,
}
Spring = {
  GetTimer=function() return clock end,
  DiffTimers=function(a,b) return a-b end,
  GetGameFrame=function() return frame end,
  GetViewGeometry=function() return viewW,viewH,0,0 end,
  GetConfigString=function(key,default) return settings[key] or default end,
  SetConfigString=function(key,value) settings[key]=value end,
  GetConfigInt=function(key,default)
    if settings[key]~=nil then return settings[key] end; return default
  end,
  SetConfigInt=function(key,value) settings[key]=value end,
  IsGUIHidden=function() return hidden end,
  SendCommands=function(command) assert(command=='hideinterface'); hidden=not hidden end,
  Echo=noop,
  SetCameraState=function() error('Telemetry changed the game camera') end,
}
Game={mapName='LastDayOfDhubai',mapChecksum=4294967295,gameID='telemetry-match-01'}
VFS={LoadFile=read,Include=function(path)
  assert(path=='luaui/widgets_mosaic/include/orbital_arrival.lua'); return A
end}
A.newRenderer=function()
  creates=creates+1
  return {draw=function(_,w,h,texture,age,fade,progress)
    lastProgress=progress; record('scene',{progress=progress}); return true
  end,destroy=noop}
end

local captures={}
local function newWidget(w,h)
  clock,frame,viewW,viewH,hidden=0,0,w,h,false
  settings={}; WG={}; widget={}
  widgetHandler={RemoveWidget=function(_,object) object:Shutdown() end}
  A.beginHandoff(); A.writeHandoff('art.png',0,0,0)
  assert(loadstring(read('luaui/widgets_mosaic/gfx_orbital_arrival.lua')))()
  widget:Initialize()
  return widget
end
local function atProgress(object,wanted)
  while WG.MosaicArrival and (WG.MosaicArrival.descent or 0)<wanted-1e-7 do
    clock=clock+1/240; calls={}; object:DrawScreenEffects()
  end
  return lastProgress
end
local function textCall(text)
  for _,call in ipairs(calls) do
    if call.kind=='text' and call.text==text and call.color[4]>0 then return call end
  end
end
local function close(a,b) return math.abs(a-b)<0.0001 end
local function point(call,x,y)
  return close(call.x1,x) and close(call.y1,y)
      or close(call.x2,x) and close(call.y2,y)
end
local function validateVisible(progress,label)
  local target=A.targetFrame(progress,viewW,viewH)
  local packet=sourcePacket(Game)
  assert(textCall('TARGET LOCK'),label..': target panel disappeared')
  assert(textCall(Game.mapName:upper()),label..': target identity changed')
  assert(textCall('TARGET // 01'),label..': destination identifier changed between shots')
  assert(textCall(packet.theme) and textCall('MODEL ESTIMATE // CONF '..packet.confidence..'%'),
    label..': theme or confidence changed during descent')
  assert(textCall(packet.status),label..': risk status disappeared')
  for _,metric in ipairs(packet.lines) do
    assert(textCall(metric.label),label..': dropped risk metric '..metric.label)
    assert(textCall(string.format('%02d%%',metric.value)),label..': changed metric value')
  end
  assert(textCall(string.format('%02d',target.stage)..' / '..target.label),
    label..': phase did not follow the projected target')
  local leader,edges,panel=false,{false,false,false,false},nil
  for _,call in ipairs(calls) do
    if call.kind=='line' and call.color[4]>0 then
      if point(call,target.right,target.top)
          and math.abs(call.x2-call.x1)>1 and math.abs(call.y2-call.y1)>1 then leader=true end
      if point(call,target.left,target.bottom) and point(call,target.right,target.bottom) then edges[1]=true end
      if point(call,target.right,target.bottom) and point(call,target.right,target.top) then edges[2]=true end
      if point(call,target.right,target.top) and point(call,target.left,target.top) then edges[3]=true end
      if point(call,target.left,target.top) and point(call,target.left,target.bottom) then edges[4]=true end
    elseif call.kind=='rect' then
      assert(call.x1>=-0.001 and call.y1>=-0.001 and call.x2<=viewW+0.001 and call.y2<=viewH+0.001,
        label..': rectangle outside viewport')
      if call.color[1]<0.03 and call.color[4]>0.5 then panel=call end
    elseif call.kind=='text' then
      local textW=gl.GetTextWidth(call.text)*call.size
      local x1=call.options:find('r',1,true) and call.x-textW or call.x
      assert(x1>=-0.001 and x1+textW<=viewW+0.001 and call.y>=0 and call.y+call.size<=viewH,
        label..': text outside viewport: '..call.text)
    end
  end
  assert(leader,label..': no visible leader to the actual target rectangle')
  for i=1,4 do assert(edges[i],label..': missing projected target edge '..i) end
  assert(panel and not (target.cx>=panel.x1 and target.cx<=panel.x2
    and target.cy>=panel.y1 and target.cy<=panel.y2),label..': panel covers city focus')
  assert(panel.x1>target.right or panel.y1>target.top or panel.x2<target.left or panel.y2<target.bottom,
    label..': selected footprint overlaps telemetry rows')
  assert(lineWidth==1,'overlay leaked line width')
  assert(currentColor[1]==1 and currentColor[2]==1 and currentColor[3]==1 and currentColor[4]==1,
    'overlay leaked draw color')
  return target,panel
end

for _,size in ipairs({{1920,1080},{1280,720},{640,360}}) do
  local object=newWidget(size[1],size[2])
  local beforeAlloc,beforeCreates,beforePackets=allocations,creates,packetCalls
  calls={}; object:DrawScreenEffects(); object:DrawScreenPost()
  assert(not textCall('TARGET LOCK'),'telemetry changed pre-start loading artwork')
  assert(allocations==beforeAlloc and creates==beforeCreates and packetCalls==beforePackets,
    'telemetry allocated resources or risk packet before gameframe started')
  frame=1; object:DrawScreenEffects()
  local packetCount=packetCalls
  assert(packetCount==beforePackets+1,'risk packet was not sampled once at startup')
  local points={}
  for stage=1,A.snapshotCount do
    points[#points+1]=(A.blendSeconds+(stage-0.5)*A.stepSeconds)/A.descentSeconds
  end
  points[#points+1]=(A.revealStart+A.revealSeconds*0.20)/A.descentSeconds
  points[#points+1]=(A.revealStart+A.revealSeconds*0.76)/A.descentSeconds
  local focus,firstPanel,footprints,seenStages=nil,nil,{},{}
  for index,wanted in ipairs(points) do
    local progress=atProgress(object,wanted)
    local target,panel=validateVisible(progress,'phase '..index)
    assert(target.stage==index,'six visual phases did not retain telemetry')
    seenStages[target.stage]=true
    if focus then assert(close(target.cx,focus[1]) and close(target.cy,focus[2]),'destination wandered')
    else focus={target.cx,target.cy}; firstPanel=panel end
    assert(close(panel.x1,firstPanel.x1) and close(panel.y1,firstPanel.y1),'risk card moved across the city')
    footprints[#footprints+1]=target.right-target.left
    captures[#captures+1]={width=viewW,height=viewH,phase=index,progress=progress,
      target=target,calls=calls}
    calls={}; object:DrawScreenPost(); validateVisible(progress,'post phase '..index)
    assert(packetCalls==packetCount,'risk values were rerolled while zooming')
    assert(allocations==beforeAlloc+1 and creates==beforeCreates+1,
      'telemetry recreated GPU resources during the descent')
  end
  assert(footprints[4]>footprints[1],'target rectangle did not follow optical scale')
  local fadeProgress=(A.revealStart+A.revealSeconds*0.96)/A.descentSeconds
  atProgress(object,fadeProgress)
  local terminalFading=textCall('TARGET LOCK')
  assert(terminalFading and terminalFading.color[4]>0 and terminalFading.color[4]<1,
    'target disappeared abruptly instead of fading at terminal handoff')
  local clearProgress=(A.revealStart+A.revealSeconds*0.985)/A.descentSeconds
  atProgress(object,clearProgress)
  assert(not textCall('TARGET LOCK'),'telemetry obscured exact terminal framebuffer')
  calls={}; object:DrawScreenPost()
  assert(not textCall('TARGET LOCK'),'post pass restored telemetry over terminal framebuffer')
  atProgress(object,1)
  assert(not WG.MosaicArrival and not hidden,'telemetry retained modal ownership after handoff')
  assert(packetCalls==packetCount,'terminal handoff rerolled telemetry')
end

-- Return captured production primitives for optional graphical QA. They are
-- not a replacement HUD implementation and are never loaded by the game.
OrbitalTelemetryCaptures=captures
print('PASS: six persistent telemetry phases, exact target leader and rectangle, unchanged risk content, fixed edge panel, 1080p/720p/360p bounds, terminal fade, prestart and resource lifecycle')
return captures
