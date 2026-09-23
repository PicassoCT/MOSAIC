-- Run from repository root with Lua 5.1 or LuaJIT.
unpack=unpack or table.unpack
local synced=true
local dead,cloak,nodraw,inlos,fullview,visible=false,false,false,true,false,true
local x,viewX,frame=0,0,30
local drawn,deleted,lastOrigin,lastDirection,lastTime=0,0
local cameraY,cameraZ,frustumTests,lastOpacity=10,100,0,0
local wind,velocity,lastDrift={0,0,0},{0,0,0},{}
local windCalls,velocityCalls=0,0
local lastLength
GG={}; Game={gameSpeed=30}; gadget={}
gadgetHandler={IsSyncedCode=function() return synced end,RemoveGadget=function() error('unexpected removal') end}
VFS={Include=function(p) return dofile(p) end,LoadFile=function() return '' end}
Spring={ValidUnitID=function(id) return id==7 end,GetUnitIsDead=function() return dead end,
    GetWind=function() windCalls=windCalls+1;return unpack(wind) end,
    GetUnitVelocity=function() velocityCalls=velocityCalls+1;return unpack(velocity) end,
    GetUnitPieceMap=function() return {smoke=2,root=1} end,
    GetCameraPosition=function() return 0,cameraY,cameraZ end,GetSpectatingState=function() return false,fullview end,
    GetMyAllyTeamID=function() return 0 end,GetUnitLosState=function() return {los=inlos,radar=true} end,
    GetUnitIsCloaked=function() return cloak end,GetUnitNoDraw=function() return nodraw end,
    GetUnitTransporter=function() return nil end,IsUnitIcon=function() return false end,
    GetUnitPiecePosDir=function() return x,0,0,1,0,0 end,
    GetUnitPosition=function() return x,0,0 end,GetUnitViewPosition=function() return viewX,0,0 end,
    GetUnitVectors=function() return {1,0,0},{0,1,0},{0,0,-1} end,
    IsSphereInView=function() frustumTests=frustumTests+1;return visible end,GetGameFrame=function() return frame end,
    GetFrameTimeOffset=function() return 0.5 end,GetSelectedUnits=function() return {7} end,Echo=function() end}
GL={TRIANGLE_STRIP=5,ALL_ATTRIB_BITS=1,ONE=1,ONE_MINUS_SRC_ALPHA=2}
gl=setmetatable({CreateShader=function() return 1 end,GetUniformLocation=function(_,n) return n end,
    CreateList=function(fn) fn();return 1 end,BeginEnd=function(_,fn,...) fn(...) end,
    CallList=function() drawn=drawn+1 end,DeleteList=function() deleted=deleted+1 end,
    GetSun=function() return 0.3,0.3,0.3 end,
    Uniform=function(n,...)
        if n=='origin' then lastOrigin={...} elseif n=='direction' then lastDirection={...}
        elseif n=='effectTime' then lastTime=(...)
        elseif n=='strandOpacity' then lastOpacity=(...)
        elseif n=='plumeLength' then lastLength=(...)
        elseif n=='directionalDrift' then lastDrift={...} end
    end}, {__index=function() return function() end end})
local path='luarules/gadgets/gfx_smoke_ribbons.lua'
dofile(path); local producer=gadget;producer:Initialize()
local api=GG.SmokeRibbon
assert(not api.Set(7,'a','missing',{}),'unknown piece accepted')
assert(not api.Set(7,'a','smoke',{direction={0,0,0}}),'zero vector accepted')
assert(not api.Set(7,'a','smoke',{speed=0/0}),'NaN accepted')
local input={direction={0,2,0},speed=2}
assert(api.Set(7,'a','smoke',input));input.direction[2]=0
SYNCED=_G;synced=false;gadget={};dofile(path);gadget:Initialize()
gadget:DrawWorld();assert(drawn==1 and lastDirection[2]==1,'snapshot missing or aliased')
assert(lastTime==30.5/30*2,'animation does not use interpolated simulation clock')
viewX=9;gadget:DrawWorld();assert(lastOrigin[1]==9,'emitter draw interpolation absent')
local function hidden(check)
    local n=drawn;gadget:DrawWorld();assert(drawn==n,check)
end
inlos=false;hidden('radar-only unit leaks smoke');inlos=true
cloak=true;hidden('cloaked unit leaks smoke');cloak=false
nodraw=true;hidden('nodraw unit leaks smoke');nodraw=false
visible=false;hidden('offscreen plume drawn');visible=true
api.SetEnabled(7,'a',false);hidden('disabled effect drawn');api.SetEnabled(7,'a',true)
assert(api.Set(7,'a','smoke',{direction={0,0,1},directionSpace='unit'}))
gadget:DrawWorld();assert(lastDirection[1]==1,'unit-relative direction wrong')
assert(api.Set(7,'a','smoke',{directionSpace='emitter',speed=0}))
gadget:DrawWorld();assert(lastDirection[1]==1 and lastTime==0,'emitter axis or freeze wrong')
-- Size-based cutoff, continuous fade and cheap rejection before frustum work.
viewX=0;cameraY=0;cameraZ=1920
gadget:DrawWorld();assert(math.abs(lastOpacity-1.6/3)<1e-8,'fade starts too early')
cameraZ=2160;gadget:DrawWorld()
assert(math.abs(lastOpacity-0.8/3)<1e-8,'fade midpoint wrong')
cameraZ=2399;gadget:DrawWorld();assert(lastOpacity<1e-5,'cutoff would pop')
cameraZ=2400;local queries=frustumTests
hidden('default size drawn at cutoff');assert(frustumTests==queries,'distant plume reached frustum work')
cameraZ=3000;hidden('default size drawn beyond cutoff')
assert(api.Set(7,'a','smoke',{scale=2}));local before=drawn
gadget:DrawWorld();assert(drawn==before+1,'larger plume culled too soon')
assert(api.Set(7,'a','smoke',{scale=0.5}));cameraZ=1200;hidden('half-size cutoff wrong')
assert(api.Set(7,'a','smoke',{length=10,width=50}));cameraZ=3000;before=drawn
gadget:DrawWorld();assert(drawn==before+1,'wide plume size ignored')
assert(api.Set(7,'a','smoke',{distanceFactor=10}));cameraZ=600;hidden('custom distance factor lost')
cameraZ=100;before=drawn;gadget:DrawWorld();assert(drawn==before+1,'plume failed to return in range')
-- Default wind, optional motion, both together and one sample per unit/draw.
wind={4,0,0};assert(api.Set(7,'a','smoke',{}));gadget:DrawWorld()
assert(math.abs(lastDrift[1]-0.84)<1e-8,'default wind disabled or incorrectly scaled')
assert(api.Set(7,'a','smoke',{windAffected=false}));gadget:DrawWorld()
assert(lastDrift[1]==0,'wind opt-out ignored')
velocity={0.2,0,0}
assert(api.Set(7,'a','smoke',{windAffected=false,motionAffected=true,trailTime=1}))
gadget:DrawWorld();assert(lastDrift[1]==-6,'motion must trail opposite velocity with frame conversion')
assert(api.Set(7,'a','smoke',{motionAffected=true,trailTime=1,windInfluence=1}))
gadget:DrawWorld();assert(lastDrift[1]==-2,'wind and motion do not combine')
assert(api.Set(7,'b','smoke',{motionAffected=true}));local wc,vc=windCalls,velocityCalls
gadget:DrawWorld();assert(windCalls==wc+1 and velocityCalls==vc+1,'duplicate wind/velocity reads')
api.Remove(7,'b');cameraZ=3000;wc,vc=windCalls,velocityCalls
hidden('distance culling failed with drift')
assert(windCalls==wc and velocityCalls==vc,'culled plume sampled wind or velocity')
cameraZ=100;velocity={1000,0,0};gadget:DrawWorld()
assert(math.abs(lastDrift[1])<=120+1e-8,'unbounded motion drift')
velocity={0,0,0};wind={0,0,0};gadget:DrawWorld()
assert(lastDrift[1]==0,'stationary plume retained motion drift')
-- Ground-fit configuration survives the synced/unsynced snapshot.
Spring.GetUnitPiecePosDir=function() return 0,128,0,1,0,0 end
Spring.GetGroundHeight=function(gx,gz) return gx > 0 and 30 or 10 end
wind={10,20,0};velocity={0,2,0}
assert(api.Set(7,'a','smoke',{groundDirected=true,windInfluence=1,trailTime=1,motionAffected=true}))
gadget:DrawWorld()
assert(lastDirection[2]==-1 and lastDrift[2]==0,'ground spray tilted by climb/wind')
assert(lastLength==98,'ground spray does not reach displaced terrain')
Spring.GetGroundHeight=function() return -100 end
gadget:DrawWorld();assert(lastLength==128,'ground spray ends below water')
cameraZ=6000;hidden('ground plume ignored distance culling');cameraZ=100
assert(api.Set(7,'a','smoke',{}));wind={0,0,0};velocity={0,0,0}
gadget:Shutdown();gadget={};dofile(path);gadget:Initialize()
local n=drawn;gadget:DrawWorld();assert(drawn==n+1,'reload lost registered effect')
api.Remove(7,'a');hidden('removed effect survives')
assert(api.Set(7,'a','smoke',{}));assert(api.Set(7,'b','smoke',{}))
producer:UnitDestroyed(7);hidden('destroyed unit retains slots')
gadget:TextCommand('smokeribbon smoke glow');n=drawn;gadget:DrawWorld();assert(drawn==n+1)
gadget:TextCommand('smokeribbon off');hidden('preview did not stop')
gadget:Shutdown();assert(deleted==16,'mesh resources leaked')
producer:Shutdown();assert(GG.SmokeRibbon==nil)
print('PASS: API validation, copied parameters, registration/update/reload/removal, destruction, visibility, draw interpolation, direction modes, pause, size/distance culling, fade, re-entry, wind, motion trailing, local preview, cleanup')
