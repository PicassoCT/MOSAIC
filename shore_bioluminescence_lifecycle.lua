-- Standalone Lua 5.4; mocks GPU ownership, not the GLSL behavior.
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local modulePath='luaui/widgets_mosaic/include/shore_bioluminescence.lua'
local M=assert(loadfile(modulePath))()
assert(M.DryFactor(0)==1 and M.DryFactor(0.03)==0 and M.DryFactor(1)==0)
assert(M.DryFactor(0.01)>M.DryFactor(0.02))
local scan=coroutine.create(function() return M.CollectTiles(1024,1024,function(x,z) return (x-320)*0.1 end) end)
local tiles
while coroutine.status(scan)~='dead' do local ok,t=coroutine.resume(scan);assert(ok,t);tiles=t or tiles end
assert(#tiles==2,'unexpected coastal tiles')
for _,t in ipairs(tiles) do assert(t.x==0 and next(t.cells)) end
local layout=assert(M.Layout(tiles));assert(layout.width<=1088 and layout.height<=1088)
-- Layout must remain bounded even on a long fragmented coastline.
local many={};for i=1,1024 do many[i]={x=i*512,z=0} end
local crowded=assert(M.Layout(many));assert(crowded.width<=1088 and crowded.height<=1088)
local function exercise(failAllocation)
    local allocated,deleted,bound,passes={},{},{},{}
    local serial,active,draws=0,0,0
    local uniforms={}
    local function alloc(kind)
        serial=serial+1;if serial==failAllocation then return nil end
        local id=kind..serial;allocated[id]=true;return id
    end
    local function delete(id) assert(allocated[id] and not deleted[id]);deleted[id]=true end
    local gl={CreateShader=function() return alloc('shader') end,
        CreateTexture=function(w,h) assert(w<=1088 and h<=1088);return alloc('texture') end,
        CreateList=function() return alloc('list') end,
        DeleteShader=delete,DeleteTexture=delete,DeleteList=delete,
        GetUniformLocation=function(_,name) return name end,GetShaderLog=function() return 'test failure' end,
        Texture=function(unit,id) bound[unit]=id end,
        UseShader=function(id) active=id end,
        Uniform=function(name,...) uniforms[name]={...} end,
        UniformInt=function(name,...) uniforms[name]={...} end,
        BeginEnd=function(_,fn,...) fn(...) end,
        CallList=function() draws=draws+1 end,
        RenderToTexture=function(target,fn,...)
            for _,id in pairs(bound) do assert(id~=target,'framebuffer feedback') end
            fn(...);passes[#passes+1]={target=target,shader=active}
        end}
    setmetatable(gl,{__index=function() return function() end end})
    local env=setmetatable({gl=gl,GL={},Game={mapSizeX=1024,mapSizeZ=1024},Spring={},VFS={LoadFile=read}},{__index=_G})
    local m=assert(load(read(modulePath),'shore','t',env))()
    local f,reason=m.New(tiles,'sand')
    if failAllocation then assert(not f and reason,'allocation failure not handled') else
        assert(f and not f.ready)
        for i=1,#tiles do f:Step(i*.1,1) end
        assert(f.ready)
        local before=#passes;f:Step(1,1)
        assert(#passes==before+1,'history must update in one pass')
        local previous=f.previous
        f:Step(1,1);assert(f.previous==previous,'paused history changed')
        f:Draw(true,0,128);assert(uniforms.capture[1]==1)
        before=draws;f:Draw(true,128,256);assert(draws==before,'light escaped ground band')
        f:Step(2,0);assert(f.dormant)
        before=#passes;f:Step(3,0);assert(#passes==before,'dormant work continued')
        f:Step(4,1);assert(not f.dormant)
        f:Step(1,1);assert(f.historyTime==1,'rewind not reset')
        f:Shutdown();f:Shutdown()
        assert(not f.ready and not bound[0] and not bound[1] and not bound[2])
    end
    for id in pairs(allocated) do assert(deleted[id],'leaked '..id) end
    return serial
end
local allocations=exercise()
for i=1,allocations do exercise(i) end
print('PASS: dry gate, bounded coast scan/layout, ping-pong ownership, pause/rewind, dormancy, height bands, allocation failures and cleanup')

-- Actual widget wiring: calls before allocation, missing weather, forced test,
-- rain suppression, paused clocks, and WG ownership on reload.
local timeFrame,paused,rain,removed,created=14400,false,0,false,0
local lastAmount,lastTime,lastCapture
local fakeField={Step=function(self,t,a) lastTime,lastAmount=t,a end,
    Draw=function(self,c,b,t,d) lastCapture={c,b,t,d} end,
    Shutdown=function(self) self.closed=true end}
local env=setmetatable({widget={},WG={},GL={},Game={mapSizeX=1024,mapSizeZ=1024},
    Spring={GetGameFrame=function() return timeFrame end,GetFrameTimeOffset=function() return .5 end,
        GetGameSpeed=function() return 1,1,paused end,Echo=function() end},
    gl={RenderToTexture=function() end,CreateShader=function() end,MultiTexCoord=function() end,
        TextureInfo=function() return {xsize=129,ysize=129} end},
    widgetHandler={RemoveWidget=function() removed=true end}}, {__index=_G})
env.VFS={MAP=1,FileExists=function(p) return p=='maps/LastDayOfDubai_distribution.dds' end,
    Include=function(p)
        if p==modulePath then return {CollectTiles=function() coroutine.yield();return tiles end,
            New=function() created=created+1;return fakeField end,DryFactor=M.DryFactor} end
        return assert(load(read(p),p,'t',env))()
    end}
assert(load(read('luaui/widgets_mosaic/gfx_shore_bioluminescence.lua'),'widget','t',env))()
local w=env.widget
w:Initialize();assert(not removed and env.WG.CaptureShoreBioluminescence)
env.WG.CaptureShoreBioluminescence(0,128) -- before scan
w:Update();w:Update();env.WG.CaptureShoreBioluminescence(0,128) -- pending allocation
assert(created==0);w:DrawWorldPreUnit();assert(created==1 and lastAmount==0,'missing rain provider must fail closed')
env.WG.GetMosaicRainIntensity=function() return rain end
w:DrawWorldPreUnit();assert(lastAmount>.99,'dry midnight should glow')
rain=1;w:DrawWorldPreUnit();assert(lastAmount==0,'rain should suppress glow')
w:TextCommand('biowaves test on');w:DrawWorldPreUnit();assert(lastAmount==1)
w:TextCommand('biowaves test off');w:DrawWorldPreUnit();assert(lastAmount==0)
rain=0;timeFrame=0;w:DrawWorldPreUnit();assert(lastAmount==0,'noon should be dark')
timeFrame=14400;paused=true;w:DrawWorldPreUnit();assert(lastTime==480,'paused frame offset was included')
local domain={x=10,z=20,span=512};env.WG.CaptureShoreBioluminescence(0,128,domain)
assert(lastCapture[1] and lastCapture[4]==domain)
w:Shutdown();assert(fakeField.closed and env.WG.CaptureShoreBioluminescence==nil)
w:Initialize();local replacement=function() end;env.WG.CaptureShoreBioluminescence=replacement
w:Shutdown();assert(env.WG.CaptureShoreBioluminescence==replacement,'removed another provider')
print('PASS: real widget initialization, pending captures, current rain/night gating, pause, debug override and provider ownership')
