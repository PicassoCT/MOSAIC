-- Exercise the real world conversion against rotated/scaled imported glyphs.
assert(_VERSION=='Lua 5.1')
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local header=read('gamedata/unit_script_header.lua');local prefix={}
for _,axis in ipairs({'x_axis','y_axis','z_axis'})do prefix[#prefix+1]=assert(header:match('local '..axis..' = %d+'))end
sizeSpacingLetter,sizeDownLetter,textSpinner=321,350,99
local positions,angles,visible,heading,scale,slope,spin,restores,missing
local tick,hold,impact,restoring,stopped,ids,p
local function near(a,b)assert(math.abs(a-b)<1e-6,a..' ~= '..b)end
local function world(id)
    local v=positions[id] or {0,0,0}
    local x,y,z=10+scale*(id*0.2+v[1]),80+scale*(id*0.1+v[3]),5-scale*(id*0.3+v[2])
    if heading==1 then x,z=z,-x end
    return {100+x,10+y,200+z}
end
local function ground(x,z)return slope and 3+(x-100)*0.04+(z-200)*0.02 or 3 end
function Move(id,axis,value,speed)
    assert(value==value and speed>=0 and speed<math.huge)
    positions[id]=positions[id] or {0,0,0};positions[id][axis]=value
end
function Turn(id,axis,value,speed)
    assert(value==value and speed>=0 and speed<math.huge)
    angles[id]=angles[id] or {0,0,0};angles[id][axis]=value
end
function StopSpin(id,axis)if id==textSpinner then assert(axis==3);spin=nil;stopped=true end end
function Spin(id,axis,value)assert(id==textSpinner and axis==3);spin=value end
function ShowReg(id)visible[id]=true end
function HideReg(id)visible[id]=nil end
function showTReg(t)for _,id in ipairs(t)do ShowReg(id)end end
function hideTReg(t)for _,id in ipairs(t)do HideReg(id)end end
function WaitForMove()end
function restoreMessageOriginalPosition(t,pos)
    restores=restores+1;restoring=true
    for _,id in ipairs(t)do
        for axis=1,3 do near(positions[id][axis],0);near(angles[id][axis],0);Move(id,axis,pos[id][axis],0)end
        ShowReg(id)
    end
end
Spring={UnitScript={IsInMove=function()return false end,IsInTurn=function()return false end},
    GetUnitPieceMap=function()return {text_spin=textSpinner}end,
    GetUnitPieceInfo=function()return {parent='text_spin'}end,
    GetUnitPosition=function()return 100,10,200 end,
    GetUnitVectors=function()if heading==1 then return {1,0,0},{0,1,0},{0,0,1}end;return {0,0,1},{0,1,0},{-1,0,0}end,
    GetUnitPieceMatrix=function(_,id)
        if missing then return end
        local v=positions[id] or {0,0,0}
        local x,y,z=10,80,5
        if id~=textSpinner then x,y,z=10+scale*(id*0.2+v[1]),80+scale*(id*0.1+v[3]),5-scale*(id*0.3+v[2])end
        return scale,0,0,0,0,0,-scale,0,0,scale,0,0,x,y,z,1
    end,GetGroundHeight=ground}
function Sleep(ms)
    if ms==34 then return end
    assert(stopped and not spin,'meteor must freeze parent for world-space targets')
    local height=sizeDownLetter*scale
    if ms==100 then
        tick=tick+1
        for _,id in ipairs(ids)do local w=world(id);assert(w[2]>=ground(w[1],w[3])+height*0.5-1e-6)end
        if tick==1 and #ids>1 then assert(world(ids[2])[2]>world(ids[1])[2],'phrase does not trail above meteor')end
    elseif ms==80 then
        assert(tick==24);impact=world(ids[1])
        near(impact[2],ground(impact[1],impact[3])+height*0.5)
        for _,id in ipairs(ids)do local w=world(id);for axis=1,3 do near(w[axis],impact[axis])end end
    elseif ms==350 then
        assert(tick==48)
        for _,id in ipairs(ids)do
            local w=world(id);assert((w[1]-impact[1])^2+(w[3]-impact[3])^2>height^2,'debris did not scatter')
            near(w[2],ground(w[1],w[3])+height*0.5)
        end
    elseif ms==500 then
        assert(tick==66);hold=hold+1
        local radius=math.max(height*1.15*2,#p.spacing*height*1.15/(2*math.pi))
        local ringPositions={}
        for _,id in ipairs(ids)do
            local w=world(id)
            near(math.sqrt((w[1]-impact[1])^2+(w[3]-impact[3])^2),radius)
            near(w[2],ground(w[1],w[3])+height*0.5)
            for axis=1,3 do near(angles[id][axis],0)end
            ringPositions[id]=w
        end
        if hold==1 then p.firstRing=ringPositions end
        if hold==2 and p.leases then
            local a,b=p.firstRing[1],ringPositions[1]
            assert(math.abs(a[1]-b[1])+math.abs(a[3]-b[3])>height,'repeated glyph lease did not move around ring')
        end
    else error('unexpected phase '..ms)end
end
assert(loadstring(table.concat(prefix,'\n')..'\n'..read('scripts/lib_textFx.lua')))()
for _,h in ipairs({0,1})do for _,sc in ipairs({0.01,0.03})do for _,sl in ipairs({false,true})do
    for _,count in ipairs({1,4})do
        heading,scale,slope=h,sc,sl
        positions,angles,visible,spin,restores,missing={},{},{},-0.3,0,false
        tick,hold,impact,restoring,stopped,ids=0,0,nil,false,false,{}
        p={unitID=7,spacing={},slotByPiece={},spinnerSpeed=-0.3,boolUpright=sl}
        for id=1,count do ids[id]=id;p[id]={0,-321*(id-1),0};p.spacing[id]=id;p.slotByPiece[id]=id end
        if count>1 then p.spacing[5]=' ';p.spacing[6]=1;p.leases={[1]={1,6}}end
        meteorCraterText(ids,p)
        assert(tick==66 and hold==12 and restores==1 and restoring);near(spin,-0.3)
        assert(canProjectTextFx('meteorCraterText',p))
    end
end end end
missing=true;restores=0;meteorCraterText(ids,p);assert(restores==1);near(spin,-0.3)
restores=0;meteorCraterText({},p);assert(restores==0)
print('PASS: meteor wake, common impact, scattered debris, sloped crater ring, leases, transforms and cleanup')
