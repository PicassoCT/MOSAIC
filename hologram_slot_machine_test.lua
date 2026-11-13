-- Exercise the real effect with production axis aliases and scarce/shared glyphs.
assert(_VERSION=='Lua 5.1')
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local header=read('gamedata/unit_script_header.lua')
local aliases={}
for _,axis in ipairs({'x_axis','y_axis','z_axis'}) do aliases[#aliases+1]=assert(header:match('local '..axis..' = %d+')) end
sizeSpacingLetter,sizeDownLetter=321,350
textSpinner=999
local positions,angles,visible,locked,ids,pos,now,spin,groups,character,finalIndex
local borrowed,owners,previous,holding,lockCount,landings,movingAfterLock,firstLandingTime
local radius=sizeDownLetter*0.85
local function near(a,b) assert(math.abs(a-b)<1e-5,tostring(a)..' ~= '..tostring(b)) end
local function finite(value) assert(type(value)=='number' and value==value and math.abs(value)<math.huge) end
function Move(id,axis,target,speed)
    finite(target);finite(speed);assert(speed>=0)
    assert(holding or lockCount==#ids or not locked[id],'locked prize moved while other reels spin')
    positions[id]=positions[id] or {0,0,0};positions[id][axis]=target
end
function Turn(id,axis,angle,speed)
    finite(angle);finite(speed);assert(speed>=0)
    assert(holding or lockCount==#ids or not locked[id],'locked prize rotated while other reels spin')
    angles[id]=angles[id] or {0,0,0};angles[id][axis]=angle
    if finalIndex[id] and visible[id] and axis==3 and speed==0 and angle==0 then
        lockCount=lockCount+1
        assert(finalIndex[id]==lockCount,'prizes stopped out of order')
        for a=1,3 do near(positions[id][a],pos[id][a]);near(angles[id][a],0) end
        locked[id]=true
    end
end
function StopSpin(id,axis)
    if id==textSpinner then assert(axis==3);spin=nil end
end
function Spin(id,axis,speed) assert(id==textSpinner and axis==3);spin=speed end
function ShowReg(id)
    assert(not visible[id],'a mesh is displayed twice')
    visible[id]=true
    if holding or lockCount==#ids then return end
    if finalIndex[id] then
        landings=landings+1
        if landings==1 then firstLandingTime=now end
        assert(finalIndex[id]==lockCount+1,'final letters appeared before their reel stops')
        near(positions[id][1],pos[id][1]-2*radius)
        near(positions[id][3],pos[id][3])
        near(angles[id][2],math.pi)
    else
        borrowed[id]=true
        local owner
        for i,finalID in ipairs(ids) do
            if positions[id][2]==pos[finalID][2] then owner=i end
        end
        assert(owner,'wheel overwrites a word gap')
        assert(character[id]~=character[ids[owner]],'wheel uses its winning character as filler')
        owners[id]=owner
    end
end
function HideReg(id)
    assert(holding or lockCount==#ids or not locked[id],'locked prize hidden before hold')
    visible[id]=nil
end
function hideTReg(list) for _,id in ipairs(list) do HideReg(id) end end
function Sleep(ms)
    finite(ms);assert(ms>0)
    if ms==500 then holding=true;assert(lockCount==#ids,'hold started before final lock') end
    if not holding then
        assert(spin==nil,'parent rotates during wheel sequence')
        local active={}
        for id in pairs(visible) do
            if borrowed[id] then
                local i=owners[id];assert(i>lockCount,'locked reel still displays filler')
                local target=pos[ids[i]]
                local x=positions[id][1]-target[1]+radius
                local z=positions[id][3]-target[3]
                near((x*x+z*z)/(radius*radius),1)
                near(x/radius,math.cos(angles[id][2]))
                near(z/radius,-math.sin(angles[id][2]))
                near(positions[id][2],target[2])
                if previous[id] and lockCount>0 and (math.abs(x-previous[id][1])+math.abs(z-previous[id][2]))>0.01 then
                    movingAfterLock[i]=true
                end
                previous[id]={x,z};active[i]=true
            end
        end
        if next(borrowed) and lockCount<#ids and ms~=34 then
            -- Full fixtures have enough glyphs for every remaining wheel.
            if groups.Z then for i=lockCount+1,#ids do assert(active[i],'remaining reel disappeared') end end
        end
    end
    now=now+ms
end
function WaitForMove() error('reels must not block on an unbounded move wait') end
assert(loadstring(table.concat(aliases,'\n')..'\n'..read('scripts/lib_textFx.lua')))()
assert(getAllTextFx().oneArmedBandit==oneArmedBandit)
assert(canProjectTextFx('oneArmedBandit',{boolUpright=false}))
assert(not canProjectTextFx('oneArmedBandit',{boolUpright=true}))
for _,case in ipairs({{'A',true},{'AB C',true},{'AA BAA',true},{'AB C',false},{'A',false}}) do
    groups,character={},{}
    local last=case[2] and 90 or 67
    for code=65,last do
        local ch=string.char(code);groups[ch]={}
        for n=1,(case[2] and 3 or 1) do
            local id=(code-65)*3+n;groups[ch][n]=id;character[id]=ch
        end
    end
    positions,angles,visible,locked,borrowed,owners,previous,movingAfterLock={},{},{},{},{},{},{},{}
    now,spin,holding,lockCount,landings,firstLandingTime=0,-0.2,false,0,0,0
    local slots,leases=allocateHologramSlots(case[1],groups)
    ids,finalIndex,pos={},{},{myMessage=case[1],spacing=slots,leases=leases,slotPositions={},slotByPiece={},spinnerSpeed=-0.2,TriLetters=groups}
    for index,id in ipairs(slots) do
        local target={0,-(index-1)*sizeSpacingLetter,0};pos.slotPositions[index]=target
        if id~=' ' then ids[#ids+1]=id;finalIndex[id]=#ids;pos[id]=target;pos.slotByPiece[id]=index end
    end
    math.randomseed(123)
    oneArmedBandit(ids,pos,groups)
    assert(lockCount==#ids and landings==#ids and holding)
    near(spin,-0.2)
    for _,id in ipairs(ids) do
        assert(visible[id]);for axis=1,3 do near(positions[id][axis],pos[id][axis]);near(angles[id][axis],0) end
    end
    for id in pairs(borrowed) do
        assert(not visible[id],'borrowed symbol leaked after effect')
        for axis=1,3 do near(positions[id][axis],0);near(angles[id][axis],0) end
        if case[2] then assert(not case[1]:find(character[id],1,true),'available unrelated letters were not preferred') end
    end
    if case[2] then
        assert(firstLandingTime>=3633,'six free revolutions were shortened')
        for i=2,#ids do assert(movingAfterLock[i],'remaining wheel stopped with its neighbour') end
    end
end
local before=now;oneArmedBandit({},pos,groups);assert(now==before and spin==-0.2)
print('PASS: unrelated wheel symbols, circular travel/rotation, continuing reels, ordered prize landings, spaces, leases, scarce pools and cleanup')
