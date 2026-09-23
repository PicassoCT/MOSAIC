-- Unsynced renderer lifecycle and resource/culling tests; run from repository root.
local calls,visible,far={},true,false
local units={}
local function count(k)calls[k]=(calls[k] or 0)+1 end
Game={gameSpeed=30};Platform={glSupportClipSpaceControl=true}
GL={QUADS=7,MODELVIEW=0x1700,PROJECTION=0x1701,NEAREST=1,CLAMP_TO_EDGE=2,ONE=1,ONE_MINUS_SRC_ALPHA=2}
local proj={2,0,0,0, 0,2,0,0, 0,0,-1,-1, 0,0,-.2,0}
local mv={1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,-4,1}
Spring={GetViewGeometry=function()return 256,256,0,0 end,GetCameraPosition=function()return 0,0,far and 100000 or 20 end,
    GetSpectatingState=function()return false,false end,GetMyAllyTeamID=function()return 0 end,
    GetGameFrame=function()return 60 end,GetFrameTimeOffset=function()return 0 end,
    GetUnitLosState=function()return {los=visible}end,IsPosInLos=function()return visible end,
    GetUnitIsDead=function()return false end,GetUnitIsCloaked=function()return false end,
    GetUnitNoDraw=function()return false end,GetUnitTransporter=function()return nil end,
    IsUnitIcon=function()return false end,GetUnitPiecePosDir=function()return 0,0,0 end,
    GetUnitPosition=function()return 0,0,0 end,GetUnitViewPosition=function()return 0,0,0 end,
    GetUnitPieceMatrix=function()return unpack(mv)end,IsSphereInView=function()return true end}
local noop=function()end
local matrixDepth,attribDepth=0,0
local lastSteps=0
local samples=0
local area=0
gl={CreateShader=function()return 1 end,GetUniformLocation=function(_,n)return n end,
    CreateList=function()return 2 end,CreateTexture=function()count('alloc');return 3 end,
    CopyToTexture=function()count('copy')end,DeleteTexture=function()count('deleteTex')end,
    DeleteShader=function()count('deleteShader')end,DeleteList=function()count('deleteList')end,
    GetMatrixData=function(mode)return unpack(mode==GL.PROJECTION and proj or mv)end,
    GetSun=function()return .5,.5,.5 end,
    PushMatrix=function()matrixDepth=matrixDepth+1 end,PopMatrix=function()matrixDepth=matrixDepth-1 end,
    PushAttrib=function()attribDepth=attribDepth+1 end,PopAttrib=function()attribDepth=attribDepth-1 end,
    Uniform=function()end,UniformInt=function(n,v)if n=='steps' then lastSteps=v end end,
    CallList=function()count('draw');samples=samples+area*lastSteps end,
    Scissor=function(x,y,w,h)area=w*h end,
    Translate=noop,Scale=noop,UnitMultMatrix=noop,UnitPieceMatrix=noop,DepthTest=noop,DepthMask=noop,
    Culling=noop,Blending=noop,Texture=noop,UseShader=noop}
VFS={LoadFile=function()return ''end}
local config=dofile('luarules/gadgets/include/cloud_volume_config.lua')
local renderer=assert(dofile('luarules/gadgets/include/cloud_volume_renderer.lua')(config))
renderer.records={a={unitID=1,piece=2,preset='fire',center={0,0,0},half={3,4,3},born=0,seed=1}}
visible=false;renderer:Draw();assert(not calls.copy and not calls.draw,'LOS leak')
visible=true;far=true;renderer:Draw();assert(not calls.copy and not calls.draw,'distance culling late')
far=false;renderer:Draw();assert(calls.draw==1 and calls.copy==1 and calls.alloc==1)
renderer:Draw();assert(calls.alloc==1,'depth texture reallocates every frame')
renderer.records={}
for i=1,100 do renderer.records[tostring(i)]={preset='nuclear',x=i,y=0,z=0,born=0,scale=1,seed=i} end
calls.draw=0;samples=0
renderer:Draw();assert(calls.draw<=24 and samples<=256*256*64,'sample budget exceeded')
assert(matrixDepth==0 and attribDepth==0,'GL state leaked')
renderer:Shutdown();assert(calls.deleteTex==1 and calls.deleteShader==1 and calls.deleteList==1)
print('PASS: LOS and size culling before depth copy, cached resources, sample/draw budgets, balanced GL state, cleanup')
