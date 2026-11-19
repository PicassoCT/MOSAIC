local paths={'scripts/operativeassetscript.lua','scripts/operativePropagatorScript.lua','scripts/operativeInvestigatorScript.lua'}
for _,path in ipairs(paths) do
 local file=assert(io.open(path));local source=file:read('*a');file:close()
 local controller=assert(source:match('(function transportControl%(%).-\nend)'))
 for _,mode in ipairs({'combat_entry','parachute_to_combat','carrier_change'}) do
  local poses,overrides,resets=0,0,0
  local carrier=51
  local scope=setmetatable({unitID=7,boolInClosedCombat=mode=='combat_entry',
   GG={},parachuteDefId=51,motorBikeTypeTable={},
   eAnimState={slaved='slaved',riding='riding'},
   isTransported=function()return true end,waitTillComplete=function()end,
   Spring={GetUnitTransporter=function()return carrier end,GetUnitDefID=function(id)return id end},
   spGetUnitDefID=function(id)return id end,
   hasHumanShield=function()return false end,releaseHumanShield=function()end,
   setOverrideAnimationState=function()overrides=overrides+1 end,
   reset=function()resets=resets+1 end,
   PlayAnimation=function(name)assert(name=='PARACHUTE_POSE');poses=poses+1 end,
   Sleep=function(ms)coroutine.yield(ms)end,
  },{__index=_G})
  local loader
  if setfenv then loader=assert(loadstring(controller));setfenv(loader,scope)
  else loader=assert(load(controller,path,'t',scope)) end
  loader()
  local thread=coroutine.create(scope.transportControl)
  local function step()local ok,err=coroutine.resume(thread);assert(ok,err)end
  step();step();step()
  if mode=='combat_entry' then
   assert(poses==0 and overrides==0 and resets==0,path..': arena entered riding mode')
  else
   assert(poses>0,path..': normal parachute pose was lost')
   local before=poses
   if mode=='parachute_to_combat' then scope.boolInClosedCombat=true else carrier=52 end
   for i=1,5 do step()end
   assert(poses==before,path..': cached parachute overwrote the new owner')
   if mode=='parachute_to_combat' then assert(resets==0,path..': transport exit reset combat center')end
  end
 end
end
print('PASS: three real transport controllers preserve parachutes and hand body ownership to combat or a replacement carrier')
