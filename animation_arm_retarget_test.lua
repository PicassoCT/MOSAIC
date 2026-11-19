local function identity()return {{1,0,0},{0,1,0},{0,0,1}}end
local function mul(a,b)local r={{},{},{}};for i=1,3 do for j=1,3 do r[i][j]=0;for k=1,3 do r[i][j]=r[i][j]+a[i][k]*b[k][j]end end end;return r end
local function apply(a,v)return {a[1][1]*v[1]+a[1][2]*v[2]+a[1][3]*v[3],a[2][1]*v[1]+a[2][2]*v[2]+a[2][3]*v[3],a[3][1]*v[1]+a[3][2]*v[2]+a[3][3]*v[3]}end
local function normal(v)local n=math.sqrt(v[1]^2+v[2]^2+v[3]^2);return {v[1]/n,v[2]/n,v[3]/n}end
local function rotation(a)
 local x,y,z=math.rad(a[1]),math.rad(a[2]),math.rad(a[3]);local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
 return mul(mul({{cy,0,sy},{0,1,0},{-sy,0,cy}},{{1,0,0},{0,cx,-sx},{0,sx,cx}}),{{cz,-sz,0},{sz,cz,0},{0,0,1}})
end
local function nativeMatrix(r,scale)
 local m={};for col=1,3 do for row=1,3 do m[(col-1)*4+row]=r[row][col]*scale end;m[col*4]=0 end
 m[13],m[14],m[15],m[16]=0,0,0,1;return m
end
local function sameDirection(a,b)
 a,b=normal(a),normal(b)
 assert(a[1]*b[1]+a[2]*b[2]+a[3]*b[3]>.99999,'compiled arm misses its semantic direction')
end
local map={Torso=1,UpArm1=2,LowArm1=3,UpArm2=4,LowArm2=5}
x_axis,y_axis,z_axis=1,3,2 -- actual included script header
function include(path)return dofile('scripts/'..path)end
local module=dofile('scripts/lib_animation_arm_retarget.lua')
for _,bind in ipairs({'A','T'}) do
 for _,orientation in ipairs({{0,0,0},{90,0,0},{90,35,0}})do
  local basis=rotation(orientation)
  local vectors={}
  for arm=1,2 do local side=arm==1 and -1 or 1;vectors[arm]=bind=='T' and {side*10,0,.2} or {side*7,0,-8}end
  Spring={GetUnitPieceMap=function()return map end,
   GetUnitPieceMatrix=function()return unpack(nativeMatrix(basis,.25))end,
   GetUnitPieceInfo=function(_,id)local arm=id==3 and 1 or 2;local v=vectors[arm];return {offset=v,min={v[1]*.5-1,-1,v[3]*.5-1},max={v[1]*.5+1,1,v[3]*.5+1}}end}
  local retarget=module.new(1)
  for arm=1,2 do
   local side=arm==1 and -1 or 1
   for _,goals in ipairs({{{side*.35,-.4,-.84},{-side*.12,-.45,.89}},{{side*.2,-.97,.1},{0,-1,.05}},{{side*.7,-.7,.1},{-side*.8,-.6,0}}})do
    local upper,lower=retarget(arm,goals[1],goals[2])
    local u,l=rotation(upper),rotation(lower)
    sameDirection(apply(mul(basis,u),vectors[arm]),apply(basis,goals[1]))
    sameDirection(apply(mul(mul(basis,u),l),vectors[arm]),apply(basis,goals[2]))
   end
  end
  local bank={};dofile('scripts/animations_melee_exchanges.lua').register(bank,1)
  local count=0
  for name,clip in pairs(bank)do
   count=count+1
   for _,frame in ipairs(clip)do for _,cmd in ipairs(frame.commands)do
    assert(cmd.t==cmd.t and math.abs(cmd.t)<=math.pi)
    assert(cmd.s>=0 and cmd.s<40,'retargeting introduced an angular wrap spike')
   end end
  end
  assert(count==17)
 end
end
print('PASS: compiled guards and strikes preserve semantic arm directions across A/T binds and rotated/scaled model frames')
