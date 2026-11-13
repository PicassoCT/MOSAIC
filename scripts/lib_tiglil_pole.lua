-- Native DAE X/Y/Z angles (Z up), positions in calibrated Journeywar body units.
-- Keep the pole still. Orbit the performer around its actual centre, rather
-- than spinning a shared parent whose origin is offset from the pole.
local M={pole={.063,1.34855},bodyBind={.07735,.8718,12},radius=.27124,top=24.6374}
local footGeometry=include("lib_tiglil_dance.lua")
local function add(a,b)return {a[1]+b[1],a[2]+b[2],a[3]+b[3]}end
local function sub(a,b)return {a[1]-b[1],a[2]-b[2],a[3]-b[3]}end
local function dot(a,b)return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]end
local function cross(a,b)return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}end
local function unit(a)local n=math.sqrt(dot(a,a));return {a[1]/n,a[2]/n,a[3]/n}end
local function apply(r,v)return {dot(r[1],v),dot(r[2],v),dot(r[3],v)}end
local function transpose(r)return {{r[1][1],r[2][1],r[3][1]},{r[1][2],r[2][2],r[3][2]},{r[1][3],r[2][3],r[3][3]}}end
local function rotation(a)
    local x,y,z=math.rad(a[1]),math.rad(a[2]),math.rad(a[3])
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return {{cy*cz+sy*sx*sz,-cy*sz+sy*sx*cz,sy*cx},{cx*sz,cx*cz,-sx},{-sy*cz+cy*sx*sz,sy*sz+cy*sx*cz,cy*cx}}
end
local function euler(r)
    local x=-math.asin(math.max(-1,math.min(1,r[2][3])))
    local y,z
    if math.abs(math.cos(x))<1e-6 then y=math.atan2(-r[3][1],r[1][1]);z=0
    else y=math.atan2(r[1][3],r[3][3]);z=math.atan2(r[2][1],r[2][2])end
    return {math.deg(x),math.deg(y),math.deg(z)}
end
local function aim(from,to)
    local a,b=unit(from),unit(to)
    local v,c=cross(a,b),dot(a,b)
    -- Chosen shoulder-to-pole directions never oppose the bind palm exactly.
    assert(c>-.99999,'pole grip crosses a singular shoulder rotation')
    local k={{0,-v[3],v[2]},{v[3],0,-v[1]},{-v[2],v[1],0}}
    local r={{},{},{}}
    for i=1,3 do for j=1,3 do
        local square=0;for n=1,3 do square=square+k[i][n]*k[n][j]end
        r[i][j]=(i==j and 1 or 0)+k[i][j]+square/(1+c)
    end end
    return euler(r)
end
local shoulders={{1.86521,-.45105,4.57199},{-1.49415,-.45105,4.57199}}
local palms={{5.1,-.2,.15},{-5.1,-.2,.15}}
-- Each stage preserves at least one hand contact. The free hand extends and
-- returns before the other hand can release. Bent-leg and extended-leg shapes
-- are separate phases, not one pose held through the entire orbit.
M.sequence={
    {name='approach and grip',ground=1,ms=900,angle=0,height=0,radius=3.8,pitch=3,roll=0,left=-8,leftKnee=16,right=-8,rightKnee=16,freeLeft=0,freeRight=0},
    {name='walking turn',ground=1,ms=2000,angle=100,height=0,radius=3.8,pitch=3,roll=-3,left=-24,leftKnee=32,right=12,rightKnee=10,freeLeft=0,freeRight=1,walk=1},
    {name='second grip',ground=1,ms=650,angle=120,height=0,radius=3.8,pitch=3,roll=0,left=-18,leftKnee=32,right=-18,rightKnee=32,freeLeft=0,freeRight=0},
    {name='tucked spin',ms=2200,angle=350,height=1,radius=3.8,pitch=5,roll=5,left=-34,leftKnee=105,right=-30,rightKnee=115,freeLeft=0,freeRight=0},
    {name='reach for climb',ms=850,angle=380,height=1.5,radius=3.7,pitch=3,roll=0,left=-34,leftKnee=110,right=-32,rightKnee=110,freeLeft=.8,freeRight=0},
    {name='first climb',ms=1100,angle=400,height=2.5,radius=3.7,pitch=3,roll=0,left=-32,leftKnee=105,right=-34,rightKnee=110,freeLeft=0,freeRight=0},
    {name='change lower grip',ms=700,angle=420,height=2.5,radius=3.7,pitch=3,roll=3,left=-32,leftKnee=105,right=-34,rightKnee=110,freeLeft=0,freeRight=.8},
    {name='second climb',ms=1100,angle=440,height=3.5,radius=3.7,pitch=3,roll=0,left=-35,leftKnee=110,right=-32,rightKnee=105,freeLeft=0,freeRight=0},
    {name='sideways tucked hold',ms=1500,angle=450,height=3.5,radius=3.7,pitch=0,roll=-75,left=-39,leftKnee=147,right=-71,rightKnee=142,rightYaw=69,freeLeft=0,freeRight=0},
    {name='extended-leg turn',ms=2300,angle=620,height=3.5,radius=3.9,pitch=7,roll=-10,left=-34,leftKnee=112,right=30,rightKnee=8,freeLeft=0,freeRight=0},
    {name='side flourish',ms=1000,angle=650,height=3,radius=3.8,pitch=4,roll=-8,left=-34,leftKnee=108,right=12,rightKnee=18,freeLeft=0,freeRight=1},
    {name='recover both grips',ms=800,angle=680,height=2.5,radius=3.8,pitch=3,roll=0,left=-30,leftKnee=95,right=-30,rightKnee=95,freeLeft=0,freeRight=0},
    {name='controlled descent',ground=1,ms=2400,angle=720,height=0,radius=3.8,pitch=3,roll=0,left=-8,leftKnee=16,right=-8,rightKnee=16,freeLeft=0,freeRight=0},
}
function M.calibrate(info,scale)
    local body,pivot,pole=info('tigLil'),info('dancepivot'),info('tlpole')
    if not (body and body.offset and pivot and pivot.offset and pole and pole.offset and pole.min and pole.max) then return M end
    local bind={}
    for axis=1,3 do bind[axis]=(body.offset[axis]+pivot.offset[axis])/scale end
    -- The blimp pole is baked along Y before its quarter-turn bind rotation;
    -- the house poles are along Z. Both are upright in their parent space.
    local half=math.max(math.abs(pole.min[2]),math.abs(pole.max[2]),math.abs(pole.min[3]),math.abs(pole.max[3]))/scale
    return {bodyBind=bind,pole={pole.offset[1]/scale,pole.offset[2]/scale},
        radius=math.max(math.abs(pole.min[1]),math.abs(pole.max[1]))/scale,top=pole.offset[3]/scale+half}
end
function M.pose(p,stage,rig)
    stage=stage or 0
    rig=rig or M
    local radius=p.radius+math.max(0,(M.top-rig.top)*.12)
    local angle=math.rad(p.angle)
    local radial={math.cos(angle),math.sin(angle),0}
    local center={rig.pole[1]+radial[1]*radius,rig.pole[2]+radial[2]*radius,12+stage+p.height}
    -- Retain the old sideways tucked silhouette, shifting the hips sideways
    -- so the shorter imported arms can still meet the pole in that lean.
    local side=3*math.sin(math.rad(p.roll))
    center[1],center[2]=center[1]-radial[2]*side,center[2]+radial[1]*side
    local yaw,lean=rotation({0,0,p.angle-90}),rotation({p.pitch,p.roll,0})
    local R={{},{},{}}
    for i=1,3 do for j=1,3 do
        R[i][j]=0;for k=1,3 do R[i][j]=R[i][j]+yaw[i][k]*lean[k][j]end
    end end
    local body=euler(R)
    local result={move=sub(center,rig.bodyBind),turns={tigLil=body},contacts={}}
    local walk=p.walk or 0
    local step=math.sin(angle*8)*walk
    result.turns.tllegUp={p.left+step*16,-3,0}
    result.turns.tllegLow={p.leftKnee+math.max(0,-step)*22,0,0}
    result.turns.tllegUpR={p.right-step*16,3,p.rightYaw or 0}
    result.turns.tllegLowR={p.rightKnee+math.max(0,step)*22,0,0}
    local floor=footGeometry.height({body={body[1],body[3],body[2]},
        left={result.turns.tllegUp[1],0,-3,result.turns.tllegLow[1]},
        right={result.turns.tllegUpR[1],result.turns.tllegUpR[3],3,result.turns.tllegLowR[1]}})
    center[3]=center[3]+floor*(p.ground or 0)
    result.move=sub(center,rig.bodyBind)
    result.turns.tlHead={-p.pitch*.65,-p.roll*.5,8}
    result.turns.tlhairup={-65-p.pitch,-p.roll*.5,-8}
    result.turns.tlhairdown={-19-p.pitch*.4,0,0}
    local lead=add(center,apply(R,shoulders[1]))
    local gx=rig.pole[1]+radial[1]*rig.radius-lead[1]
    local gy=rig.pole[2]+radial[2]*rig.radius-lead[2]
    local upper=lead[3]+math.sqrt(math.max(0,dot(palms[1],palms[1])-gx*gx-gy*gy))
    center[3]=center[3]-math.max(0,upper-stage-rig.top+.3)
    result.move=sub(center,rig.bodyBind)
    for side,name in ipairs({'tlarm','tlarmr'}) do
        local shoulder=add(center,apply(R,shoulders[side]))
        local contact={rig.pole[1]+radial[1]*rig.radius,rig.pole[2]+radial[2]*rig.radius,0}
        local dx,dy=contact[1]-shoulder[1],contact[2]-shoulder[2]
        local reach=dot(palms[side],palms[side])-dx*dx-dy*dy
        assert(reach>0,'pole is out of reach at '..p.angle..' degrees, hand '..side)
        contact[3]=shoulder[3]+(side==1 and 1 or -1)*math.sqrt(reach)
        assert(contact[3]>stage+.4 and contact[3]<stage+rig.top-.1,'grip exceeds pole length')
        local localTarget=sub(apply(transpose(R),sub(contact,center)),shoulders[side])
        local release=side==1 and p.freeLeft or p.freeRight
        -- Released hands sweep out to the side; the opposite hand stays planted.
        local free={side==1 and 4.5 or -4.5,-1,side==1 and 2 or .5}
        local vector={}
        for i=1,3 do vector[i]=(1-release)*localTarget[i]+release*free[i] end
        result.turns[name]=aim(palms[side],vector)
        if release==0 then result.contacts[name]=contact end
    end
    return result
end
function M.play(api,stage,rig)
    local previous=M.sequence[1]
    api.show()
    api.apply(M.pose(previous,stage,rig),previous.ms)
    api.sleep(previous.ms)
    for index=2,#M.sequence do
        local target=M.sequence[index]
        if api.phase then api.phase(target.name) end
        local ticks=math.ceil(target.ms/50)
        local dt=target.ms/ticks
        for tick=1,ticks do
            local t=tick/ticks
            local ease=t*t*t*(10+t*(-15+6*t))
            local p={}
            for _,key in ipairs({'angle','height','radius','pitch','roll','left','leftKnee','right','rightKnee','freeLeft','freeRight','walk','ground','rightYaw'}) do
                p[key]=(previous[key] or 0)+((target[key] or 0)-(previous[key] or 0))*ease
            end
            api.apply(M.pose(p,stage,rig),dt)
            api.sleep(dt)
        end
        previous=target
    end
end
return M
