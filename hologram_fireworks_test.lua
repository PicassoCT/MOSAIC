-- Exercise the actual world mover with the imported parent basis, unequal
-- glyph bind offsets, rotated units, terrain and the production axis aliases.
assert(_VERSION=='Lua 5.1')
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local header=read('gamedata/unit_script_header.lua')
local prefix={}
for _,axis in ipairs({'x_axis','y_axis','z_axis'}) do prefix[#prefix+1]=assert(header:match('local '..axis..' = %d+')) end
sizeSpacingLetter,sizeDownLetter=321,350
textSpinner=99
local positions,visible,shows,bursts,landings,waits,rotations,spins
local heading,scale,frame,activeBurst=0,0.02,0,nil
local plantCheck,plantObserver=false,nil
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b)) end
local function modelPosition(id)
    local p=positions[id] or {0,0,0}
    return 10+scale*(id*0.2+p[1]),80+scale*(id*0.1+p[3]),5-scale*(id*0.3+p[2])
end
local function world(id)
    local x,y,z=modelPosition(id)
    if heading==1 then x,z=z,-x end
    return {100+x,10+y,200+z}
end
local function ground(x,z) return 3+(x-100)*0.04+(z-200)*0.02 end
function Move(id,axis,target,speed)
    assert(target==target and speed==speed and speed>=0 and speed<math.huge)
    positions[id]=positions[id] or {0,0,0};positions[id][axis]=target
end
function Turn(id,axis,angle) rotations[#rotations+1]={id,axis,angle} end
function StopSpin(id,axis) assert(id==textSpinner and axis==3);spins[axis]=nil end
function Spin(id,axis,speed) assert(id==textSpinner and axis==3);spins[axis]=speed end
function reset(id) for a=1,3 do Move(id,a,0,0);Turn(id,a,0) end end
function ShowReg(id)
    assert(not visible[id],'glyph shown twice in launch')
    visible[id]=true;shows[#shows+1]={id=id,p=world(id)}
end
function HideReg(id)
    if visible[id] then
        local p=world(id)
        if not plantCheck then near(p[2],ground(p[1],p[3])+sizeDownLetter*scale/2) end
        landings[#landings+1]=id
    end
    visible[id]=nil
end
function showTReg(ids) for _,id in ipairs(ids) do ShowReg(id) end end
function hideTReg(ids) for _,id in ipairs(ids) do HideReg(id) end end
function WaitForMove(id,axis)
    waits[#waits+1]={id=id,p=world(id)}
end
function Sleep(ms)
    frame=frame+ms
    if plantCheck then assert(ms==6000);plantObserver();return end
    if ms==3000 then
        local burst={}
        for id in pairs(visible) do burst[id]=world(id) end
        bursts[#bursts+1]=burst;activeBurst=burst
    elseif ms==200 then
        assert(activeBurst,'fall begins before readable burst')
        local drop
        for id in pairs(visible) do
            local p,start=world(id),activeBurst[id]
            near(p[1],start[1]);near(p[3],start[3])
            assert(p[2]>=ground(p[1],p[3])+sizeDownLetter*scale/2-1e-6)
            if p[2]>ground(p[1],p[3])+sizeDownLetter*scale/2+1e-6 then
                if drop then near(start[2]-p[2],drop) else drop=start[2]-p[2] end
            end
        end
    elseif ms==500 then assert(not next(visible),'launches overlap')
    else error('unexpected fireworks phase '..ms) end
end
Spring={
    UnitScript={IsInMove=function(id) waits[#waits+1]={id=id,p=world(id)};return false end,IsInTurn=function()return false end},
    GetUnitPieceMap=function()return {text_spin=textSpinner} end,
    GetUnitPieceInfo=function()return {parent='text_spin'} end,
    GetUnitPosition=function()return 100,10,200 end,
    GetUnitVectors=function()
        if heading==1 then return {1,0,0},{0,1,0},{0,0,1} end
        return {0,0,1},{0,1,0},{-1,0,0}
    end,
    GetUnitPieceMatrix=function(_,id)
        local x,y,z=10,80,5
        if id~=textSpinner then x,y,z=modelPosition(id) end
        return scale,0,0,0, 0,0,-scale,0, 0,scale,0,0, x,y,z,1
    end,
    GetGroundHeight=ground,
}
assert(loadstring(table.concat(prefix,'\n')..'\n'..read('scripts/lib_textFx.lua')))()
for _,unitHeading in ipairs({0,1}) do
    heading=unitHeading
    for _,count in ipairs({1,2,10,12,13,25}) do
        positions,visible,shows,bursts,landings,waits,rotations,spins={},{},{},{},{},{},{},{}
        activeBurst=nil
        local ids,pos={}, {unitID=7,spacing={},slotByPiece={},spinnerSpeed=-0.3}
        for id=1,count do
            ids[id]=id;pos[id]={0,-id*321,0}
            pos.spacing[#pos.spacing+1]=id;pos.slotByPiece[id]=#pos.spacing
            if id%4==0 then pos.spacing[#pos.spacing+1]=' ' end
        end
        fireWorksProjectTextFx(ids,pos)
        assert(#shows==count and #landings==count and not next(visible),'letters lost or left visible')
        near(spins[3],-0.3)
        local expectedGroups=math.ceil(count/12)
        assert(#bursts==expectedGroups)
        local shared=shows[1].p
        for _,s in ipairs(shows) do
            for a=1,3 do near(s.p[a],shared[a]) end
        end
        for _,r in ipairs(rotations) do assert(r[3]==0,'readable spark rotates or tumbles') end
        for group,burst in ipairs(bursts) do
            local first=math.floor((group-1)*count/expectedGroups)+1
            local last=math.floor(group*count/expectedGroups)
            local slots=pos.slotByPiece[last]-pos.slotByPiece[first]+1
            local spacing=math.max(321*scale,350*scale)*1.15
            local radius=slots>1 and spacing/(2*math.sin(math.pi/slots)) or 0
            local peak=burst[first][2]-radius
            assert(peak>shared[2],'burst did not rise')
            for id=first,last do
                local theta=2*math.pi*(pos.slotByPiece[id]-pos.slotByPiece[first])/slots
                local horizontal=radius*math.sin(theta)
                near(burst[id][2],peak+radius*math.cos(theta))
                near(burst[id][heading==0 and 3 or 1],shared[heading==0 and 3 or 1]+horizontal)
                near(burst[id][heading==0 and 1 or 3],shared[heading==0 and 1 or 3])
                local launchWait
                for _,w in ipairs(waits) do if w.id==id then launchWait=w.p;break end end
                near(launchWait[1],shared[1]);near(launchWait[2],peak);near(launchWait[3],shared[3])
            end
        end
    end
end
print('fireworks: shared ground launch, grouped rise, readable circles, upright fall and terrain contact PASS')
-- Plant uses the same world conversion but grows a stem, then leaves in
-- alternating directions. Test true terrain origins in two unit headings.
function restoreMessageOriginalPosition(ids,p)
    for _,id in ipairs(ids) do for axis=1,3 do Move(id,axis,p[id][axis],0) end;visible[id]=true end
end
plantCheck=true
for _,unitHeading in ipairs({0,1}) do
    heading=unitHeading
    for _,count in ipairs({1,2,5,12}) do
        positions,visible,shows,bursts,landings,waits,rotations,spins={},{},{},{},{},{},{},{}
        local ids,p={}, {unitID=7,spinnerSpeed=0.3}
        for id=1,count do ids[id]=id;p[id]={0,-id*321,0} end
        local stemCount=math.ceil(count/2)
        local inspected=false
        plantObserver=function()
            inspected=true
            local root=shows[1].p
            local height=sizeDownLetter*scale
            near(root[2],ground(root[1],root[3])+height*0.5)
            assert(#shows==count and #waits==3*count)
            for id=1,count do
                assert(shows[id].id==id,'plant grew out of order')
                local grown=world(id)
                assert(grown[2]>=ground(grown[1],grown[3])+height*0.5-1e-6,'plant buried below terrain')
                if id<=stemCount then
                    for axis=1,3 do near(shows[id].p[axis],root[axis]) end
                    near(grown[1],root[1]);near(grown[3],root[3])
                    near(grown[2],root[2]+(id-1)*height*1.1)
                else
                    local leaf=id-stemCount
                    local horizontal=heading==0 and 3 or 1
                    local offset=grown[horizontal]-root[horizontal]
                    assert(offset*(leaf%2==1 and -1 or 1)>0,'branches do not alternate sides')
                    near(shows[id].p[1],root[1]);near(shows[id].p[3],root[3])
                    assert(grown[2]>shows[id].p[2],'leaf does not sprout upward')
                end
            end
            for _,r in ipairs(rotations) do assert(r[3]==0,'plant glyph not upright') end
        end
        letterPlant(ids,p)
        assert(inspected);near(spins[3],0.3)
        for _,id in ipairs(ids) do for axis=1,3 do near(positions[id][axis],p[id][axis]) end end
    end
end
print('plant: terrain root, sequential stem growth, alternating leaves, heading conversion and phrase restoration PASS')
