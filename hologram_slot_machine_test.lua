assert(_VERSION=='Lua 5.1')
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('gamedata/unit_script_header.lua')
local aliases={}
for _,axis in ipairs({'x_axis','y_axis','z_axis'}) do aliases[#aliases+1]=assert(source:match('local '..axis..' = %d+')) end
sizeSpacingLetter,sizeDownLetter=321,350
textSpinner=99
local positions,ends,visible,locked,ids,pos,now,roll,spin,shuffled,shown
local function near(a,b) assert(math.abs(a-b)<1e-6) end
function Move(id,axis,target,speed)
    assert(not locked[id] or roll==6+#ids,'locked reel moved before final readable hold')
    assert(target==target and speed==speed and speed>=0 and speed<math.huge)
    positions[id]=positions[id] or {0,0,0};ends[id]=ends[id] or {}
    local delta=math.abs(target-positions[id][axis])
    positions[id][axis]=target;ends[id][axis]=now+(speed>0 and delta/speed*1000 or 0)
    if speed>0 then assert(axis==3,'reel rolls along wrong axis') end
end
function Turn(id,axis,angle) assert(angle==0,'slot glyph rotated') end
function StopSpin(id,axis) assert(id==textSpinner and axis==3);spin=nil end
function Spin(id,axis,speed) assert(id==textSpinner and axis==3);spin=speed end
function reset(id) for a=1,3 do Move(id,a,0,0);Turn(id,a,0) end end
function ShowReg(id)
    assert(not visible[id],'piece is on two reels')
    visible[id]=true;shown[id]=(shown[id] or 0)+1
    if roll<6+#ids then
        local matched
        for index,targetID in ipairs(ids) do
            local target=pos[targetID]
            if positions[id][1]==target[1] and positions[id][2]==target[2] then
                matched=index
                near(positions[id][3],target[3]+sizeDownLetter*1.25)
                if id~=targetID then shuffled=true end
            end
        end
        assert(matched,'reel overwrites a space')
    end
end
function HideReg(id)
    assert(not locked[id] or roll==6+#ids,'locked reel hidden')
    visible[id]=nil
end
function hideTReg(list) for _,id in ipairs(list) do HideReg(id) end end
function WaitForMove(id,axis) now=math.max(now,ends[id][axis] or now) end
function Sleep(ms)
    if ms==40 then
        roll=roll+1
        assert(spin==nil,'parent rotates during reels')
        local occupied={}
        for id in pairs(visible) do
            local y=positions[id][2]
            assert(not occupied[y],'two letters occupy one reel');occupied[y]=id
            near(positions[id][3],0)
        end
        if roll>6 then
            local id=ids[roll-6]
            for axis=1,3 do near(positions[id][axis],pos[id][axis]) end
            locked[id]=true
        end
    else
        assert(ms==500 and roll==6+#ids,'hold begins before all reels stop')
        locked={} -- normal repeated-glyph leases may now move again
    end
    now=now+ms
end
assert(loadstring(table.concat(aliases,'\n')..'\n'..read('scripts/lib_textFx.lua')))()
assert(getAllTextFx().oneArmedBandit==oneArmedBandit)
assert(canProjectTextFx('oneArmedBandit',{boolUpright=false}))
assert(not canProjectTextFx('oneArmedBandit',{boolUpright=true}))
for _,phrase in ipairs({'A','AB C','AA BAA'}) do
    positions,ends,visible,locked,now,roll,spin,shuffled,shown={},{},{},{},0,0,-0.2,false,{}
    local slots,leases=allocateHologramSlots(phrase,{A={1,2},B={3},C={4}})
    ids,pos={}, {spacing=slots,leases=leases,slotPositions={},slotByPiece={},spinnerSpeed=-0.2}
    for index,id in ipairs(slots) do
        local target={0,-(index-1)*sizeSpacingLetter,0};pos.slotPositions[index]=target
        if id~=' ' then ids[#ids+1]=id;pos[id]=target;pos.slotByPiece[id]=index end
    end
    math.randomseed(123)
    oneArmedBandit(ids,pos)
    assert(roll==6+#ids and now>=3000+(6+#ids)*240-80-1e-6,'rolls did not finish before hold')
    near(spin,-0.2)
    for _,id in ipairs(ids) do
        assert(visible[id] and shown[id]>1)
        for axis=1,3 do near(positions[id][axis],pos[id][axis]) end
    end
    if #ids>1 then assert(shuffled,'reels never change letters') end
end
locked={};now=0;spin=-0.2;oneArmedBandit({},pos)
assert(now==0 and spin==-0.2,'empty effect changed state')
print('slot machine: changing reels, true vertical travel, ordered stops, spaces, leases and spin restoration PASS')
