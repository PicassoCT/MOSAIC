-- Public renderer contract: bounded work, independent expiry and full paths.
local frame,visible=60,true
local vertices,attributes={},{}
local batches,created,deleted,pushed,popped=0,0,0,0,0
local depthMask
Game={gameSpeed=30}
Spring={GetGameFrame=function() return frame end,GetFrameTimeOffset=function() return 0 end,
    GetCameraPosition=function() return 0,80,500 end,
    GetWind=function() return 7,0,2 end,
    IsSphereInView=function() return visible end}
GL={ALL_ATTRIB_BITS=1,QUADS=7,ONE=1,ONE_MINUS_SRC_ALPHA=771}
VFS={LoadFile=function(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end}
gl={CreateShader=function(spec)
        assert(spec.vertex:find('wakeUVTime') and spec.fragment:find('wakeUVTime'))
        created=created+1;return created
    end,GetShaderLog=function() return 'compile failed' end,GetUniformLocation=function() return 1 end,
    GetSun=function() return .3,.3,.3 end,Uniform=function() end,UseShader=function() end,
    PushAttrib=function() pushed=pushed+1 end,PopAttrib=function() popped=popped+1 end,
    DepthTest=function(v) assert(v) end,DepthMask=function(v) depthMask=v end,
    Culling=function(v) assert(v==false) end,Texture=function(v) assert(v==false) end,
    Blending=function(a,b) assert(a==GL.ONE and b==GL.ONE_MINUS_SRC_ALPHA) end,
    MultiTexCoord=function(index,...) attributes[index]={...} end,
    Vertex=function(x,y,z,t)
        local copy={x=x,y=y,z=z,t=t}
        for k,v in pairs(attributes) do copy[k]={v[1],v[2],v[3],v[4]} end
        vertices[#vertices+1]=copy
    end,
    BeginEnd=function(mode,fn,...)
        assert(mode==GL.QUADS);batches=batches+1;fn(...)
    end,
    DeleteShader=function() deleted=deleted+1 end}
local make=dofile('luaui/widgets_mosaic/include/railgun_wake_renderer.lua')
local renderer=assert(make())
local function reset() vertices={};batches=0 end
local function span(seed,x,expires)
    return {ax=x,ay=15,az=0,bx=x+32,by=15,bz=0,bornA=0,bornB=30,
        expires=expires or 450,seed=seed,distance=x,width=3.5}
end
renderer:Draw({span(1,0)},frame)
assert(batches==1 and #vertices==8,'single wake must use one batch with bounded detail')
assert(depthMask==false and pushed==popped,'wake changed scene depth writes/state lifetime')
assert(vertices[1][0][3]==2 and vertices[#vertices][0][3]==1,'span ages are not interpolated')
assert(vertices[1][0][4]==13,'shot expiry must remain independent from endpoint ages')
assert(vertices[1][1][1]==1 and vertices[1][1][2]==0,'recorded trajectory tangent lost')
assert(vertices[1].x==0 and vertices[#vertices].x==32,'renderer changed stored path endpoints')
assert(created==1,'renderer recompiles per shot')
reset();frame=450;renderer:Draw({span(1,0)},frame)
assert(batches==0 and renderer:GetStats().drawnSpans==0,'expired wake submitted geometry')
reset();frame=60;visible=false;renderer:Draw({span(1,0)},frame)
assert(batches==0,'offscreen wake submitted geometry');visible=true
reset();local transparent=span(1,0);transparent.opacity=0;renderer:Draw({transparent},frame)
assert(batches==0,'zero opacity wake submitted geometry')
reset();local short=span(1,0);short.bx=1;short.fadeA=0;short.fadeB=0
renderer:Draw({short},frame)
assert(#vertices==4 and vertices[1].t==0 and vertices[3].t==1,'short-shot span coordinate lost')
assert(vertices[1][2][3]==0 and vertices[1][2][4]==0,'true endpoint fade flags lost')
-- Three competing complete paths: keep two newest groups, never six random
-- nearest spans drawn from all three. All retained paths preserve their end.
reset();renderer.maxSpans=6;renderer.maxCells=8
local all={}
for shot=1,3 do
    for i=0,2 do
        local r=span(shot,shot*1000+i*32,450+shot*10)
        r.shotKey='shot-'..shot;all[#all+1]=r
    end
end
renderer:Draw(all,frame)
local stats=renderer:GetStats()
assert(stats.drawnSpans==6 and stats.drawnShots==2 and stats.droppedShots==1,'whole-shot retention failed')
assert(stats.cells<=8 and stats.vertices==#vertices and #vertices<=32 and batches==1,'cell/draw budget exceeded')
local seen={}
for _,v in ipairs(vertices) do
    local seed=v[2][1];assert(seed~=1,'oldest path survived budget selection')
    seen[seed]=seen[seed] or {};seen[seed][v.x]=true
end
for shot=2,3 do
    assert(seen[shot][shot*1000] and seen[shot][shot*1000+96],'retained path lost an end')
end
-- Explicit shot keys disambiguate coincident seeds and expiration values.
reset();renderer.maxSpans=1;renderer.maxCells=1
local a,b=span(5,0),span(5,100);a.shotKey='a';b.shotKey='b'
renderer:Draw({a,b},frame)
assert(renderer:GetStats().drawnShots==1,'shot identities merged on a seed collision')
renderer:Shutdown();renderer:Shutdown();assert(deleted==1,'shutdown did not release shader exactly once')
reset();renderer:Draw({span(1,0)},frame);assert(batches==0,'destroyed renderer submitted a batch')
print('PASS: railgun wake renderer batches, ages, endpoint flags, whole-shot budgets and cleanup')
