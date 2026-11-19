for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'}) do
 local f=assert(io.open(path));local source=f:read('*a');f:close()
 local code=assert(source:match('(function blendShortestPath%([^\n]*\n.-\nend)'))..'\n'
  ..assert(source:match('(function turnUnitTowardsUnit%([^\n]*\n.-\nend)'))..'\n'
  ..assert(source:match('(function chatting%(%).-\nend)'))
 local frame,dx,dz=0,0,1
 local target={28,0,0}
 local atTwoSeconds
 local scope=setmetatable({unitID=1,chatPartner=2,chattingTime=5000,SIG_INTERNAL=1,
  boolWalking=false,lowerBodyPieces={},eAnimState={slaved='slaved',standing='standing'},
  GameConfig={civilians={conversation={range=100},activityStates={ended='ended'}}},
  spGetUnitPosition=function(id)if id==1 then return 0,0,0 else return target[1],target[2],target[3] end end,
  spGetGameFrame=function()return frame end,frameToMs=function(n)return n*1000/30 end,
  Spring={GetUnitDirection=function()return dx,0,dz end,
   SetUnitDirection=function(_,x,y,z)
    assert(y==0 and math.abs(x*x+z*z-1)<1e-8)
    -- Engine 058c8ea adds (2*z-1)*1e-6 to its heading denominator.
    -- A tiny positive cos(pi/2) therefore reverses the resulting heading.
    assert(z==0 or math.abs(z)>=1e-5,'cardinal residue reaches the legacy heading singularity')
    dx,dz=x,z
    if frame==60 then atTwoSeconds=x end
   end},
  Signal=function()end,SetSignalMask=function()end,setOverrideAnimationState=function()end,
  doesUnitExistAlive=function()return true end,distanceUnitToUnit=function()return 28 end,
  maRa=function()return true end,randChance=function()return true end,
  resetUpperBodyNoTPose=function()end,setCivilianUnitInternalStateMode=function()end,
  Sleep=function(ms)frame=frame+math.ceil(ms*30/1000)end,
  PlayAnimation=function(_,_,_,onFrame)
   assert(type(onFrame)=='function','chat clip lost its facing callback')
   for i=1,30 do frame=frame+1;onFrame()end
   return 30
  end,
 },{__index=_G})
 local loader
 if setfenv then loader=assert(loadstring(code));setfenv(loader,scope)
 else loader=assert(load(code,path,'t',scope)) end
 loader()
 local function turn(factor,start)
  if path:find('agentscript',1,true) then scope.turnUnitTowardsUnit(1,2,factor,start)
  else scope.turnUnitTowardsUnit(factor,start)end
 end
 for _,position in ipairs({{28,0,0},{-28,0,0},{0,0,28},{0,0,-28}}) do
  target=position;turn(1,0)
  assert(math.abs(dx-position[1]/28)<1e-8 and math.abs(dz-position[3]/28)<1e-8,'character faces away from partner')
 end
 for _,angle in ipairs({math.pi/2+1e-8,math.pi/2-1e-8,-math.pi/2+1e-8,-math.pi/2-1e-8}) do
  turn(0,angle)
  assert(dz==0 and dx*math.sin(angle)>.9999,'east/west heading reversed at a cardinal boundary')
 end
 target={28,0,0};dx,dz=0,1;frame=0
 scope.chatting()
 assert(math.abs(dx-1)<1e-8 and math.abs(dz)<1e-8)
 assert(atTwoSeconds and math.abs(atTwoSeconds-math.sin(math.pi/2*2000/3500))<1e-8,
  'facing progress must follow simulation time during a clip, not number of completed gestures')
end
print('PASS: both civilian scripts face partners in all quadrants and blend on elapsed simulation time during gestures')
