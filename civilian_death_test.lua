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
 -- ComposeTransform uses clockwise RotateEulerYXZ(-r): positive script angles
 -- therefore produce the right-handed rotations below (Coil 058c8ea).
 for _,axis in ipairs({2,1,3}) do
  local c,s=math.cos(a[axis]),math.sin(a[axis]);local r=identity()
  if axis==1 then r[6],r[7],r[10],r[11]=c,s,-s,c
  elseif axis==2 then r[1],r[3],r[9],r[11]=c,-s,s,c
  else r[1],r[2],r[5],r[6]=c,s,-s,c end
  t=mul(t,r)
 end
 return parents[p]>0 and mul(matrix(parents[p]),t) or t
end
Spring={UnitScript={GetPieceRotation=function(p)
 -- Native Spring Turn stores the equivalent positive angle, not signed input.
 return angles[p][1]%(2*math.pi),angles[p][2]%(2*math.pi),angles[p][3]%(2*math.pi)
 end,
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
 -- Raised arms can exceed resting limits; death must inherit that pose.
 angles[pieces.UpArm1][1]=-2.5
  local selected=play(damage,100,seed%3-1,1)
  seen[selected]=true
  assert(time<5000 and time>2000,'fall must finish with a visible settle')
  local endPose=trace[#trace];local previous=trace[#trace-5]
  for axis=1,3 do assert(math.abs(endPose[axis]-previous[axis])<0.08,'joint failed to settle') end
  local head=matrix(pieces.Head1);assert(head[14]>-1,'head remained below the floor')
  local torso=matrix(pieces.UpBody)
  assert(torso[14]<5,'a distal limb left the torso suspended above the floor: '..torso[14]..' seed '..seed..' damage '..damage)
 end
end
for _,name in ipairs({'collapse','backwards','sideways','coiling','shivering','blasted','swirling'}) do
 assert(seen[name],'unreachable death variation: '..name)
end
-- A previously horizontal root must not be interpreted as the bind frame.
math.randomseed(3)
angles,moves,trace,time={},{},{},0
for p=1,#names do angles[p]={0,0,0};moves[p]={0,0,0}end
angles[pieces.root][1]=math.pi/2
play(10,100,0,-1)
local fallen=matrix(pieces.root)
assert(math.abs(fallen[10])<.2 and fallen[11]>.9,'pre-rotated root lost its fall direction or ended upright')

-- Operatives use the pelvis as the root and have no separate center/foot joints.
-- Exercise the shared solver from a non-neutral fighting pose on that topology.
local operativePieces={root=pieces.center}
for name,piece in pairs(pieces) do
 if name~='root' and name~='center' and name~='Feet1' and name~='Feet2' then
  operativePieces[name]=piece
 end
end
local operativeFall=dofile('scripts/lib_civilian_death.lua')(1,operativePieces)
for seed=1,14 do
 math.randomseed(seed)
 angles,moves,trace,time={},{},{},0
 for p=1,#names do angles[p]={0.12,-0.1,0.15};moves[p]={0,0,0} end
 angles[pieces.UpArm1]={-0.9,-0.25,0.1}
 angles[pieces.LowArm1]={-1.5,0,0.2}
 operativeFall(1000,100,1,0)
 assert(time<5000)
 assert(matrix(pieces.Head1)[14]>-1,'operative head remained below floor')
end

-- Validate the actual contact Jacobian against independent finite differences
-- of the native Y-X-Z transform, including a rotated ancestor chain.
local f=assert(io.open('scripts/lib_civilian_death.lua'));local solver=f:read('*a');f:close()
local formula=assert(solver:match('(local axes=%b{}.-)for _,axis in ipairs'))
angles,moves,trace,time={},{},{},1
for p=1,#names do angles[p]={.12,-.2,.3};moves[p]={0,0,0}end
local part=pieces.UpArm2;angles[part]={.4,-.5,.7}
local m=matrix(part);local basis={}
for axis=1,3 do
 local k=(axis-1)*4+1;local n=math.sqrt(m[k]^2+m[k+1]^2+m[k+2]^2)
 basis[axis]={m[k]/n,m[k+1]/n,m[k+2]/n}
end
local env=setmetatable({basis=basis,rx=.4,rz=.7},{__index=_G})
local fn
if setfenv then fn=setfenv(assert(loadstring(formula..'return axes')),env)
else fn=assert(load(formula..'return axes','contact Jacobian','t',env))end
local axes=fn();local point={2,-3,1}
local function transformed(a,row)return a[row]*point[1]+a[4+row]*point[2]+a[8+row]*point[3]+a[12+row]end
local dx,dz=transformed(m,1)-m[13],transformed(m,3)-m[15]
for axis=1,3 do
 local v=assert(axes[axis],'missing usable joint axis')
 local predicted=v[3]*dx-v[1]*dz
 local old=angles[part][axis];angles[part][axis]=old+1e-6
 local actual=(transformed(matrix(part),2)-transformed(m,2))/1e-6
 angles[part][axis]=old
 assert(math.abs(predicted-actual)<1e-4,'contact gradient disagrees with native rotation on axis '..axis)
end

-- Both script entry points must use their real head piece and record impact
-- direction, and bomber cook-off remains a distinct path.
for _,path in ipairs({'scripts/civilianscript.lua','scripts/civilianagentscript.lua'}) do
 local f=assert(io.open(path));local source=f:read('*a');f:close()
 assert(source:find('lastDamageDirX, lastDamageDirZ = x or 0, z or 0',1,true))
 assert(source:find('unitID, Head1, bloodyHell',1,true))
 assert(source:find("include('lib_civilian_death.lua')",1,true))
end
print('PASS: operative pelvis-root topology, seven death variations, inherited poses, bounded joints/motion, finite settling, floor contact and both civilian scripts')
