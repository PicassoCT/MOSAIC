-- Loaded by tiglil_ground_model_test.py with real DAE transforms and bounds.
-- MODEL_FIXTURES
assert(fixtures,'run through tiglil_ground_model_test.py')
local module=dofile('scripts/lib_tiglil_ground.lua')
local function mul(a,b)local r={{},{},{},{}};for i=1,4 do for j=1,4 do r[i][j]=0;for k=1,4 do r[i][j]=r[i][j]+a[i][k]*b[k][j]end end end;return r end
local function apply(m,p)return {m[1][1]*p[1]+m[1][2]*p[2]+m[1][3]*p[3]+m[1][4],m[2][1]*p[1]+m[2][2]*p[2]+m[2][3]*p[3]+m[2][4],m[3][1]*p[1]+m[3][2]*p[2]+m[3][3]*p[3]+m[3][4]}end
local function rotation(a,t)
    t=t or {0,0,0};local x,y,z=a[1],a[2],a[3]
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return {{cy*cz+sy*sx*sz,-cy*sz+sy*sx*cz,sy*cx,t[1]},{cx*sz,cx*cz,-sx,t[2]},{-sy*cz+cy*sx*sz,sy*sz+cy*sx*cz,cy*cx,t[3]},{0,0,0,1}}
end
for filename,fixture in pairs(fixtures)do
 for _,unitHeading in ipairs({0,.8,2.4})do
    local moves,turns={0,0,0},{0,0,0}
    local map={tiglil_anchor=1,brothel_spin=2};local parts={}
    for name,p in pairs(fixture.parts)do local id=#parts+3;map[name]=id;parts[#parts+1]=p;p.id=id end
    local parentR=fixture.parent
    local unitR=rotation({0,unitHeading,0},{100,20,100})
    local actorChange=rotation({0,0,0})
    local native={}
    function native.Move(id,axis,value)assert(id==1);moves[axis]=value end
    function native.Turn(id,axis,value)assert(id==1);turns[axis]=value end
    local function model(id)
        if id==2 then return parentR end
        local anchor=mul(parentR,rotation(turns,moves))
        if id==1 then return anchor end
        return mul(anchor,mul(actorChange,parts[id-2].matrix))
    end
    local people={[10]={x=130,z=100,def=1},[11]={x=101,z=100,def=2},[12]={x=105,z=100,def=1,fast=true},[13]={x=108,z=100,def=1,dead=true},[14]={x=110,z=100,def=1,transport=true}}
    local blocked=false
    local personHead=false
    local spring={}
    function spring.GetUnitPieceMap(id)if id==10 and personHead then return {Head1=30}end;return map end
    function spring.GetUnitPieceInfo(_,id)if id==1 then return {parent='brothel_spin'}end;return parts[id-2]end
    function spring.GetUnitPieceMatrix(_,id)
        local m=model(id);local result={};for j=1,4 do for i=1,4 do result[#result+1]=m[i][j]end end;return unpack(result)
    end
    function spring.GetUnitVectors()return {unitR[1][3],unitR[2][3],unitR[3][3]},{0,1,0},{-unitR[1][1],0,-unitR[3][1]}end
    function spring.GetUnitPosition(id)if id==3 then return 100,20,100 end;local p=people[id];return p.x,6+p.x*.01,p.z end
    function spring.GetUnitVelocity(id)return people[id].fast and 2 or 0,0,0 end
    function spring.GetUnitDefID(id)return people[id].def end
    function spring.ValidUnitID(id)return people[id]~=nil end
    function spring.GetUnitIsDead(id)return people[id].dead end
    function spring.GetUnitTransporter(id)return people[id].transport and 5 end
    function spring.GetUnitRadius()return 5 end
    function spring.GetUnitsInCylinder()return {14,13,12,11,10}end
    function spring.GetGroundHeight(x)return 6+x*.01 end
    function spring.GetGroundBlocked()return blocked and 'unit' or nil end
    local worker,mask
    function Signal(signal)assert(signal==32768);worker=nil end
    function SetSignalMask(value)mask=value end
    function Sleep()coroutine.yield()end
    function StartThread(fn)worker=coroutine.create(fn);assert(coroutine.resume(worker))end
    local placement=module.new(spring,native,3,{[1]={customParams={baseclass='Civilian'}},[2]={customParams={baseclass='Truck'}}},130)
    assert(placement.begin(),'no street projection on '..filename)
    assert(mask==32898 and worker,'placement worker lacks parent cancellation mask')
    local fixedX,fixedZ
    local function check()
        local lowest=math.huge
        for _,p in ipairs(parts)do
            local world=mul(unitR,model(p.id))
            for m=0,7 do
                local v={};for axis=1,3 do v[axis]=(math.floor(m/2^(axis-1))%2==0 and p.min or p.max)[axis]end
                lowest=math.min(lowest,apply(world,v)[2])
            end
        end
        local body=mul(unitR,model(map.tigLil));local x,z=body[1][4],body[3][4]
        if not fixedX then fixedX,fixedZ=x,z end
        assert(math.abs(lowest-(spring.GetGroundHeight(fixedX,fixedZ)+.1))<1e-5,'animated silhouette penetrates/loses the ground')
        if actorChange[1][1]==1 and actorChange[2][2]==1 then
            assert(math.abs(x-fixedX)<1e-5 and math.abs(z-fixedZ)<1e-5,'parent spin moves conversation off its mark')
            local up=math.sqrt(body[1][3]^2+body[2][3]^2+body[3][3]^2)
            assert(body[2][3]/up>.999,'projection is not upright')
            local dx,dz=people[10].x-x,people[10].z-z;local length=math.sqrt(dx*dx+dz*dz)
            assert((-body[1][2]*dx-body[3][2]*dz)/(up*length)>.999,'projection faces the wrong civilian')
            assert(length>10 and length<80,'projection is not beside the person')
        end
    end
    check()
    parentR=mul(rotation({.3,1.1,-.2},{0,80,0}),fixture.parent)
    assert(placement.update());check()
    actorChange=rotation({math.pi/2,0,0},{0,0,500})
    assert(placement.update());check()
    people[10].fast=true;assert(not placement.update())
    for i=1,3 do assert(moves[i]==0 and turns[i]==0,'departure leaves anchor displaced')end
    assert(not worker)
    people[10].fast=false;blocked=true
    assert(not placement.begin(),'projects through blocked terrain')
    blocked=false;assert(placement.begin());placement.stop()
    assert(not worker)
    for i=1,3 do assert(moves[i]==0 and turns[i]==0,'cancellation leaves anchor displaced')end
    actorChange=rotation({0,0,0})
    local context=placement.begin({personal=true,distance=4.8})
    assert(context and context.person==10)
    local closeBody=mul(unitR,model(map.tigLil))
    local dx,dz=closeBody[1][4]-people[10].x,closeBody[3][4]-people[10].z
    local front=spring.GetUnitVectors(10)
    assert((dx*front[1]+dz*front[3])/math.sqrt(dx*dx+dz*dz)>.999,'personal interaction is not in front of pedestrian')
    placement.stop()
    spring.GetUnitHeight=function()return context.bodyScale*3 end
    assert(not placement.begin({personal=true,distance=2.8}),'contact gesture ignores incompatible actor heights')
    spring.GetUnitHeight=function()return 40 end
    spring.GetUnitRadius=function()return 25 end
    spring.GetUnitCollisionVolumeData=function()return 10,25,10 end
    spring.GetUnitPiecePosDir=function(id,head)assert(id==10 and head==30);return 130,spring.GetGroundHeight(130)+18*context.bodyScale,100 end
    personHead=true
    assert(placement.begin({personal=true,distance=4.8}),'generic metadata height hides a valid head match')
    closeBody=mul(unitR,model(map.tigLil))
    dx,dz=closeBody[1][4]-people[10].x,closeBody[3][4]-people[10].z
    assert(math.sqrt(dx*dx+dz*dz)<context.bodyScale*6,'generic metadata radius keeps embrace out of reach')
    placement.stop()
    spring.GetUnitHeight=nil
    people[10].dead=true;assert(not placement.begin(),'truck/dead/moving/transported units selected')
 end
 print('PASS: '..filename..': grounded conversation, person selection, facing, rotated parents, animated bounds, fallback and restoration')
end
