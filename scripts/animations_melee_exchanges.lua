-- Short paired exchanges for the existing arena and keyframe players.
-- Source axes, as in the operative animation banks; setupAnimation converts once.
local M={}
local axes={x_axis,y_axis,z_axis}
local parts={'center','Torso','Head','UpArm1','UpArm2','LowArm1','LowArm2'}
local profiles={
 {name='JAB',lead=1,shoulder=-105,elbow=-18,spread=9,twist=9,lean=5,frames=18},
 {name='CROSS',lead=2,shoulder=-116,elbow=-22,spread=12,twist=16,lean=7,frames=21},
 {name='HOOK',lead=1,shoulder=-82,elbow=-78,spread=35,twist=20,lean=4,frames=21},
 {name='ELBOW',lead=2,shoulder=-94,elbow=-115,spread=30,twist=15,lean=5,frames=18},
 {name='SHOVE',lead=1,shoulder=-100,elbow=-30,spread=15,twist=5,lean=9,frames=24,both=true},
 {name='BODY',lead=2,shoulder=-70,elbow=-24,spread=8,twist=12,lean=13,frames=21},
 {name='CLINCH',lead=1,shoulder=-92,elbow=-88,spread=20,twist=10,lean=7,frames=27,both=true},
}
local guard={center={0,0,0},Torso={4,0,0},Head={7,0,0},UpArm1={-55,-15,0},UpArm2={-55,15,0},LowArm1={-95,0,12},LowArm2={-95,0,-12}}
local strikeDirections={
 JAB={{.18,-.97,.12},{.04,-1,.03}},
 CROSS={{.12,-.96,.20},{-.10,-1,.05}},
 HOOK={{.70,-.70,.12},{-.80,-.60,.05}},
 ELBOW={{.45,-.82,.35},{-.30,.45,.84}},
 SHOVE={{.20,-.97,-.10},{.08,-1,.05}},
 BODY={{.18,-.75,-.64},{.05,-.98,-.20}},
 CLINCH={{.50,-.75,.43},{-.35,-.72,.60}},
}
local function blendDirection(a,b,w,side)
 return {side*(a[1]+(b[1]-a[1])*w),a[2]+(b[2]-a[2])*w,a[3]+(b[3]-a[3])*w}
end
local function pose(p,defend,weight,retarget)
 local value={}
 for _,part in ipairs(parts) do value[part]={guard[part][1],guard[part][2],guard[part][3]} end
 local sign=p.lead==1 and 1 or -1
 value.Torso={4+(defend and -5 or p.lean)*weight,0,sign*p.twist*weight*(defend and -.5 or 1)}
 value.Head={7+(defend and 6 or -3)*weight,0,-sign*5*weight}
 for arm=1,2 do
  if defend then
   value['UpArm'..arm]={-55-25*weight,(arm==1 and -1 or 1)*(15+8*weight),0}
   value['LowArm'..arm]={-95-12*weight,0,(arm==1 and 1 or -1)*12}
  elseif arm==p.lead or p.both then
   value['UpArm'..arm]={-55+(p.shoulder+55)*weight,(arm==1 and -1 or 1)*(15+(p.spread-15)*weight),0}
   value['LowArm'..arm]={-95+(p.elbow+95)*weight,0,(arm==1 and 1 or -1)*12*(1-weight)}
  end
 end
 if retarget then
  for arm=1,2 do
   local side=arm==1 and -1 or 1
   local upper,lower={.35,-.40,-.84},{-.12,-.45,.89}
   local targetUpper,targetLower,w=upper,lower,0
   if defend then targetUpper,targetLower,w={.40,-.50,-.72},{-.10,-.32,.94},weight
   elseif arm==p.lead or p.both then targetUpper,targetLower,w=strikeDirections[p.name][1],strikeDirections[p.name][2],weight end
   value['UpArm'..arm],value['LowArm'..arm]=retarget(arm,
    blendDirection(upper,targetUpper,w,side),blendDirection(lower,targetLower,w,side))
  end
 end
 return value
end
local function clip(p,defend,retarget)
 local result={};local last=pose(p,defend,0,retarget)
 local beats={{0,0},{3,.16},{6,1},{9,.88},{p.frames-3,0}}
 for i,beat in ipairs(beats) do
  local target=pose(p,defend,beat[2],retarget);local commands={}
  local seconds=(i==1 and 3 or beat[1]-beats[i-1][1])/30
  for _,part in ipairs(parts) do for axis=1,3 do
   local delta=(math.rad(target[part][axis]-last[part][axis])+math.pi)%(2*math.pi)-math.pi
   if i==1 or math.abs(delta)>1e-7 then
    commands[#commands+1]={c='turn',p=part,a=axes[axis],t=math.rad(target[part][axis]),s=i==1 and 12 or math.abs(delta)/seconds}
   end
  end end
  -- Targets are reached at the beat; commands begin in the preceding interval.
  result[#result+1]={time=i==1 and 0 or beats[i-1][1]+6,commands=commands}
  last=target
 end
 result[#result+1]={time=p.frames+6,commands={}}
 return result
end
local function footwork(direction)
 local result={};local previous
 for frame=0,24,3 do
  local stride=direction*14*math.sin(frame*math.pi/12)
  local target={UpLeg1={-8+stride,0,4},UpLeg2={-8-stride,0,-4},
   LowLeg1={16+math.max(0,-stride)*1.5,0,0},LowLeg2={16+math.max(0,stride)*1.5,0,0}}
  local commands={}
  for _,part in ipairs({'UpLeg1','UpLeg2','LowLeg1','LowLeg2'})do for axis=1,3 do
   local value=math.rad(target[part][axis])
   local delta=previous and math.rad(target[part][axis]-previous[part][axis]) or 0
   if not previous or math.abs(delta)>1e-7 then commands[#commands+1]={c='turn',p=part,a=axes[axis],t=value,s=previous and math.abs(delta)/.1 or 4}end
  end end
  result[#result+1]={time=frame,commands=commands};previous=target
 end
 result[#result+1]={time=27,commands={}}
 return result
end
function M.register(bank,id)
 local retarget=id and include('lib_animation_arm_retarget.lua').new(id)
 bank.MELEE_STEP_ADVANCE=footwork(1)
 bank.MELEE_STEP_RETREAT=footwork(-1)
 bank.MELEE_BRACE=footwork(0)
 for _,p in ipairs(profiles) do
  bank['MELEE_'..p.name..'_ATTACK']=clip(p,false,retarget)
  bank['MELEE_'..p.name..'_DEFEND']=clip(p,true,retarget)
 end
end
function M.select(name,arena,id)
 if name~='FIGHTING' or not arena or not Spring.ValidUnitID(arena) or Spring.GetUnitIsDead(arena) then return name end
 local epoch=Spring.GetUnitRulesParam(arena,'melee_exchange')
 local index=Spring.GetUnitRulesParam(arena,'melee_style')
 local profile=profiles[index]
 if not profile then return name,epoch end -- retain the original authored fight as a variation
 local attacker=Spring.GetUnitRulesParam(arena,'melee_attacker')
 return 'MELEE_'..profile.name..(attacker==id and '_ATTACK' or '_DEFEND'),epoch
end
function M.duration(style)
 local profile=profiles[style]
 return profile and (profile.frames+6)*1000/30 or 800
end
function M.footwork(arena,id,legacy,standing)
 if standing then return 'MELEE_BRACE' end
 local style=arena and Spring.GetUnitRulesParam(arena,'melee_style')
 if not style or style==8 then return legacy end
 if style==7 then return 'MELEE_BRACE' end
 return Spring.GetUnitRulesParam(arena,'melee_attacker')==id and 'MELEE_STEP_ADVANCE' or 'MELEE_STEP_RETREAT'
end
function M.stale(arena,epoch)
 return epoch and (not arena or not Spring.ValidUnitID(arena) or Spring.GetUnitIsDead(arena)
     or Spring.GetUnitRulesParam(arena,'melee_exchange')~=epoch)
end
return M
