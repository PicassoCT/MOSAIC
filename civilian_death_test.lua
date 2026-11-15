local names={'root','center','UpBody','Head1','UpArm1','UpArm2','LowArm1','LowArm2','UpLeg1','UpLeg2','LowLeg1','LowLeg2','Feet1','Feet2'}
local pieces={};for i,n in ipairs(names) do pieces[n]=i end
local parents={0,1,2,3,3,3,5,6,2,2,9,10,11,12}
local offsets={{0,0,0},{0,0,12},{0,0,1},{0,0,8},{-3,0,6},{3,0,6},{-3,0,-3},{3,0,-3},{-2,0,-1},{2,0,-1},{0,0,-5},{0,0,-5},{0,0,-5},{0,0,-5}}
local function identity() return {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1} end
local function mul(a,b)
 local out={}
 for col=0,3 do for row=0,3 do
  local v=0;for k=0,3 do v=v+a[k*4+row+1]*b[col*4+k+1] end
  out[col*4+row+1]=v
 end end
 return out
end
local angles,moves,time,trace,initial
local function matrix(p)
 local a=angles[p];local t=identity();for axis=1,3 do t[12+axis]=offsets[p][axis]+moves[p][axis] end
 if p==1 then t=mul(t,{1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1}) end
 for _,axis in ipairs({2,1,3}) do
  local c,s=math.cos(-a[axis]),math.sin(-a[axis]);local r=identity()
  if axis==1 then r[6],r[7],r[10],r[11]=c,s,-s,c
  elseif axis==2 then r[1],r[3],r[9],r[11]=c,-s,s,c
  else r[1],r[2],r[5],r[6]=c,s,-s,c end
  t=mul(t,r)
 end
 return parents[p]>0 and mul(matrix(parents[p]),t) or t
end
Spring={UnitScript={GetPieceRotation=function(p)return unpack(angles[p])end,
 GetPieceTranslation=function(p)return unpack(moves[p])end},
 GetUnitPieceMatrix=function(_,p)return unpack(matrix(p))end,
 GetUnitHeight=function()return 25 end,GetUnitPieceMap=function()return pieces end,
 GetUnitPieceInfo=function(_,p)return {parent=names[parents[p]] or '[null]',min={-0.5,-0.5,-0.5},max={0.5,0.5,0.5}}end,
 GetUnitPosition=function()return 0,0,0 end,
 GetUnitVectors=function()return {0,0,1},{0,1,0},{-1,0,0}end,
 GetGroundHeight=function()return 0 end}
function StopSpin() end
function Turn(p,axis,value,speed)
 assert(value==value and speed>=0 and speed<math.huge,'invalid animation command')
 if time==0 then assert(math.abs(value-angles[p][axis])<0.3,'first frame snapped into a canned pose') end
 angles[p][axis]=value
end
function Move(p,axis,value,speed)
 assert(value==value and math.abs(value)<100 and speed<math.huge,'unbounded translation')
 moves[p][axis]=value
end
function Sleep(ms)
 time=time+ms
 trace[#trace+1]={angles[1][1],angles[1][2],angles[4][1]}
end
local play=dofile('scripts/lib_civilian_death.lua')(1,pieces)
local seen={}
for seed=1,35 do
 math.randomseed(seed)
 for _,damage in ipairs({10,1000}) do
  angles,moves,trace,time={},{},{},0
  for p=1,#names do angles[p]={0.05,-0.03,0.02};moves[p]={0,0,0} end
  local selected=play(damage,100,seed%3-1,1)
  seen[selected]=true
  assert(time<5000 and time>2000,'fall must finish with a visible settle')
  local endPose=trace[#trace];local previous=trace[#trace-5]
  for axis=1,3 do assert(math.abs(endPose[axis]-previous[axis])<0.08,'joint failed to settle') end
  local head=matrix(pieces.Head1);assert(head[14]>-1,'head remained below the floor')
 end
end
for _,name in ipairs({'collapse','backwards','sideways','coiling','shivering','blasted','swirling'}) do
 assert(seen[name],'unreachable death variation: '..name)
end
-- Both script entry points must use their real head piece and record impact
-- direction, and bomber cook-off remains a distinct path.
for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'}) do
 local f=assert(io.open(path));local source=f:read('*a');f:close()
 assert(source:find('lastDamageDirX, lastDamageDirZ = x or 0, z or 0',1,true))
 assert(source:find('unitID, Head1, bloodyHell',1,true))
 assert(source:find("include('lib_civilian_death.lua')",1,true))
end
print('PASS: seven death variations, inherited poses, bounded joints/motion, finite settling, floor contact and both civilian scripts')
