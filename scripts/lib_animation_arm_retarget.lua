-- Compile semantic arm directions into each model's existing Turn keyframes.
-- Uses the native bind matrices once, before setupAnimation resolves commands.
-- Runtime playback remains the ordinary animation player; no IK thread runs.
local M={}
local function dot(a,b)return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]end
local function normal(v)
 local n=math.sqrt(dot(v,v));assert(n>1e-8,'degenerate arm bind direction')
 return {v[1]/n,v[2]/n,v[3]/n}
end
local function cross(a,b)return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}end
local function mul(a,b)
 local r={{},{},{}}
 for i=1,3 do for j=1,3 do r[i][j]=0;for k=1,3 do r[i][j]=r[i][j]+a[i][k]*b[k][j]end end end
 return r
end
local function transpose(a)return {{a[1][1],a[2][1],a[3][1]},{a[1][2],a[2][2],a[3][2]},{a[1][3],a[2][3],a[3][3]}}end
local function apply(a,v)return {dot(a[1],v),dot(a[2],v),dot(a[3],v)}end
local function rotation(from,to)
 local a,b=normal(from),normal(to)
 local d=math.max(-1,math.min(1,dot(a,b)))
 local v=cross(a,b)
 if d<-.999999 then
  local axis=normal(cross(a,math.abs(a[1])<.8 and {1,0,0} or {0,1,0}))
  local r={{},{},{}};for i=1,3 do for j=1,3 do r[i][j]=2*axis[i]*axis[j]-(i==j and 1 or 0)end end
  return r
 end
 local k={{0,-v[3],v[2]},{v[3],0,-v[1]},{-v[2],v[1],0}}
 local kk=mul(k,k);local r={{},{},{}}
 for i=1,3 do for j=1,3 do r[i][j]=(i==j and 1 or 0)+k[i][j]+kk[i][j]/(1+d)end end
 return r
end
local function angles(r)
 -- Same Y-X-Z decomposition used by the existing grounded pose helper.
 local x=-math.asin(math.max(-1,math.min(1,r[2][3])))
 local y,z
 if math.abs(math.cos(x))<1e-6 then y,z=math.atan2(-r[3][1],r[1][1]),0
 else y,z=math.atan2(r[1][3],r[3][3]),math.atan2(r[2][1],r[2][2])end
 return {math.deg(x),math.deg(y),math.deg(z)}
end
local function basis(m)
 local r={{},{},{}};local scale={}
 for col=1,3 do
  local k=(col-1)*4+1;scale[col]=math.sqrt(m[k]^2+m[k+1]^2+m[k+2]^2)
  assert(scale[col]>1e-8,'degenerate arm bind matrix')
  for row=1,3 do r[row][col]=m[k+row-1]/scale[col]end
 end
 return r,scale
end
function M.new(id, options)
 options=options or {}
 local map=Spring.GetUnitPieceMap(id)
 local torso=basis({Spring.GetUnitPieceMatrix(id,map[options.torso or 'Torso'])})
 local arms={}
 for i=1,2 do
  local upper,lower=map['UpArm'..i],map['LowArm'..i]
  local u,us=basis({Spring.GetUnitPieceMatrix(id,upper)})
  local l,ls=basis({Spring.GetUnitPieceMatrix(id,lower)})
  local info=Spring.GetUnitPieceInfo(id,lower)
  local hand=options.hands and Spring.GetUnitPieceInfo(id,map['Hand'..i])
  local upperVector,lowerVector={},{}
  for axis=1,3 do
   upperVector[axis]=info.offset[axis]*us[axis]
   lowerVector[axis]=(hand and hand.offset[axis] or (info.min[axis]+info.max[axis])*.5)*ls[axis]
  end
  arms[i]={upper=u,lower=l,upperVector=normal(upperVector),lowerVector=normal(lowerVector)}
 end
 return function(index,upperGoal,lowerGoal)
  local arm=arms[index]
  local u=rotation(arm.upperVector,apply(transpose(arm.upper),apply(torso,upperGoal)))
  local changedLower=mul(mul(mul(arm.upper,u),transpose(arm.upper)),arm.lower)
  local l=rotation(arm.lowerVector,apply(transpose(changedLower),apply(torso,lowerGoal)))
  return angles(u),angles(l)
 end
end
return M
