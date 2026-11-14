-- Rolling sphere, pedestrian pass, debris and cleanup across imported transforms.
x_axis,y_axis,z_axis=1,3,2
sizeSpacingLetter,sizeDownLetter,textSpinner=321,350,99
local positions,rotations,visible,scale,heading,mode,spin,restored,time,seen,full,partial,off,reports
local function near(a,b)assert(math.abs(a-b)<1e-5,a..' ~= '..b)end
local function rotate(x,z)
    return math.cos(heading)*x+math.sin(heading)*z,-math.sin(heading)*x+math.cos(heading)*z
end
local function world(id)
    local p=positions[id] or {0,0,0}
    local x,z=rotate(10+scale*(id*.2+p[1]),5-scale*(id*.3+p[2]))
    return {100+x,80+scale*(id*.1+p[3]),200+z}
end
function Move(id,a,v,s)assert(s>=0);positions[id]=positions[id] or {0,0,0};positions[id][a]=v end
function Turn(id,a,v,s)rotations[id]=rotations[id] or {0,0,0};rotations[id][a]=v end
function StopSpin(id,a)if id==textSpinner then assert(a==3);spin=nil end end
function Spin(id,a,v)assert(id==textSpinner and a==3);spin=v end
function ShowReg(id)visible[id]=true end
function HideReg(id)visible[id]=nil end
function hideTReg(ids)for _,id in ipairs(ids)do HideReg(id)end end
function restoreMessageOriginalPosition(ids,p)
    restored=restored+1
    for _,id in ipairs(ids)do
        for a=1,3 do near(positions[id][a],0);near(rotations[id][a],0);Move(id,a,p[id][a],0)end
        ShowReg(id)
    end
end
Spring={
    GetUnitPosition=function()return 100,0,200 end,
    GetUnitVectors=function()
        local fx,fz=rotate(0,1);local rx,rz=rotate(-1,0)
        return {fx,0,fz},{0,1,0},{rx,0,rz}
    end,
    GetUnitPieceMap=function()return {text_spin=textSpinner}end,
    GetUnitPieceInfo=function()return {parent='text_spin',min={-20,-120,-40},max={20,120,360}}end,
    GetUnitPieceMatrix=function(_,id)
        if mode=='missing' then return end
        local p=positions[id] or {0,0,0}
        if mode=='tilted' then return scale,0,0,0,0,scale,0,0,0,0,scale,0,10,80,5,1 end
        return scale,0,0,0,0,0,-scale,0,0,scale,0,0,
            10+(id~=99 and scale*(id*.2+p[1]) or 0),
            80+(id~=99 and scale*(id*.1+p[3]) or 0),
            5-(id~=99 and scale*(id*.3+p[2]) or 0),1
    end,
    GetGroundHeight=function(x,z)return 7+.02*x+.03*z end,
}
local stage, samples, debrisSpins, disappearance, stopped, transported, repeated, observed
UnitDefs={[1]={customParams={baseclass='Civilian'}},[2]={customParams={baseclass='Truck'}}}
Spring.GetUnitsInCylinder=function()return {7,800,801}end
Spring.GetUnitDefID=function(id)return id==800 and 1 or 2 end
Spring.GetUnitVelocity=function()return stopped and 0 or .2,0,0 end
Spring.GetUnitRadius=function()return 6 end
Spring.GetUnitIsDead=function(id)return id==800 and disappearance and time>3000 end
Spring.ValidUnitID=function()return true end
Spring.GetUnitTransporter=function(id)return id==800 and transported end
Spring.GetUnitPosition=function(id)
    if id==7 then return 100,0,200 end
    local x,z=140+time*.006,200
    return x,Spring.GetGroundHeight(x,z),z
end
function Spin(id,a,v)
    if id==textSpinner then spin=v else debrisSpins=debrisSpins+1 end
end
-- Recover the sphere centre from four points, independently of the layout code.
local function centre()
    local w,rows={},{}
    for id=1,4 do w[id]=world(id)end
    for i=2,4 do
        local row={};local rhs=0
        for a=1,3 do row[a]=2*(w[i][a]-w[1][a]);rhs=rhs+w[i][a]^2-w[1][a]^2 end
        row[4]=rhs;rows[i-1]=row
    end
    for col=1,3 do
        local pivot=col
        for row=col+1,3 do if math.abs(rows[row][col])>math.abs(rows[pivot][col])then pivot=row end end
        rows[col],rows[pivot]=rows[pivot],rows[col]
        local n=rows[col][col];assert(math.abs(n)>1e-8)
        for a=col,4 do rows[col][a]=rows[col][a]/n end
        for row=1,3 do if row~=col then
            local factor=rows[row][col]
            for a=col,4 do rows[row][a]=rows[row][a]-factor*rows[col][a]end
        end end
    end
    return {rows[1][4],rows[2][4],rows[3][4]}
end
-- Engine piece orientation RY * RX * RZ, then the imported parent transform.
local function turned(id,v)
    local a=rotations[id]
    local x,y,z=v[1],v[2],v[3]
    x,y=math.cos(a[3])*x-math.sin(a[3])*y,math.sin(a[3])*x+math.cos(a[3])*y
    y,z=math.cos(a[1])*y-math.sin(a[1])*z,math.sin(a[1])*y+math.cos(a[1])*z
    x,z=math.cos(a[2])*x+math.sin(a[2])*z,-math.sin(a[2])*x+math.cos(a[2])*z
    local wx,wz=rotate(x,-y)
    return {wx,z,wz}
end
function Sleep(ms)
    if ms~=34 and mode=='normal' then
        assert(not spin,'cached world targets rotated by parent')
        if stage=='forming' or stage=='rolling' or stage=='accelerating' then
            local c=centre();local radius=800*scale
            local px,_,pz=Spring.GetUnitPosition(800)
            samples[#samples+1]={c=c,along=c[1]-px,side=c[3]-pz,stage=stage,normal=turned(1,{1,0,0})}
            for id in pairs(visible)do
                local w=world(id);local d=0
                for axis=1,3 do d=d+(w[axis]-c[axis])^2 end
                near(math.sqrt(d),radius)
                local normal=turned(id,{1,0,0})
                for axis=1,3 do near(normal[axis],(w[axis]-c[axis])/radius)end
                for _,x in ipairs({-20,20})do for _,y in ipairs({-120,120})do for _,z in ipairs({-40,360})do
                    local v=turned(id,{x*scale,y*scale,z*scale})
                    assert(w[2]+v[2]>=Spring.GetGroundHeight(w[1]+v[1],w[3]+v[3])-1e-5,'glyph below terrain')
                end end end
                if repeated then
                    local key=math.floor((time-1034)/400)
                    if stage=='rolling' then observed[id..':'..key]=true end
                end
            end
        elseif stage=='breaking' then
            local n=0;for _ in pairs(visible)do n=n+1 end
            observed.landed=observed.landed or n==0
        end
    end
    time=time+ms
end
dofile('scripts/lib_textFx.lua')
assert(getAllTextFx().rollingTextBall==rollingTextBall)
local function run(s,h,m,repeatGlyph,dead,stop,transport)
    scale,heading,mode=s,h,m
    positions,rotations,visible={},{},{}
    spin,restored,time,stage,samples,debrisSpins=.3,0,0,nil,{},0
    disappearance,stopped,transported,repeated,observed=dead,stop,transport,repeatGlyph,{}
    local ids,p={},{unitID=7,spinnerSpeed=.3,spacing={},leases={},slotByPiece={}}
    for i=1,(repeatGlyph and 16 or 8)do
        local id=(i-1)%8+1
        if not p[id] then ids[#ids+1]=id;p[id]={0,-i*321,i*350};p.slotByPiece[id]=i end
        p.spacing[i]=id;p.leases[id]=p.leases[id] or {};table.insert(p.leases[id],i)
    end
    p.debugTextFx=function(message)stage=message:match('textball: (%w+)')end
    assert(canProjectTextFx('rollingTextBall',p))
    rollingTextBall(ids,p)
    assert(spin==.3 and time<8500,'spinner not restored or effect unbounded')
    if stop or transport then assert(restored==0 and time==0 and stage=='skipped');return end
    assert(restored==1)
    if m~='normal' then assert(time<100 and stage=='skipped');return end
    if dead then assert(stage=='stopped' and time<3200 and debrisSpins==0);return end
    assert(#samples==111 and debrisSpins==8 and observed.landed)
    near(samples[1].along,-2400*scale)
    near(samples[31].along,-2400*scale)
    assert(samples[111].along>0 and math.abs(samples[111].side)>800*scale+6,'did not pass beside pedestrian')
    local previousDelta=-math.huge
    for i=33,111 do
        local delta=samples[i].along-samples[i-1].along
        assert(delta>previousDelta,'pass did not accelerate');previousDelta=delta
    end
    -- Two consecutive follow frames: radial vector rotates by travelled distance / radius.
    if not repeatGlyph then
        local a,b=samples[10],samples[11]
        local theta=math.abs(b.c[1]-a.c[1])/(800*scale)
        near(b.normal[1],a.normal[1]*math.cos(theta)+a.normal[2]*math.sin(theta))
        near(b.normal[2],a.normal[2]*math.cos(theta)-a.normal[1]*math.sin(theta))
        near(b.normal[3],a.normal[3])
    else assert(observed['1:0'] and observed['1:2'],'repeated glyph lease phases missing')end
end
for _,s in ipairs({.0254,.1,1})do for _,h in ipairs({0,math.pi/2,math.pi})do
    for _,rep in ipairs({false,true})do run(s,h,'normal',rep)end
end end
for _,m in ipairs({'missing','tilted'})do run(.1,0,m)end
run(.1,0,'normal',false,true)
run(.1,0,'normal',false,false,true)
run(.1,0,'normal',false,false,false,true)
rollingTextBall({}, {})
print('PASS: textball sphere/facing, terrain clearance, accelerated pass, debris, repeated letters, missing pedestrian and cleanup')
