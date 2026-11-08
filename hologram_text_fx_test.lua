-- Run from repository root: lua5.1 tests/hologram_text_fx_test.lua
assert(_VERSION == 'Lua 5.1', 'test under the engine-compatible Lua 5.1 runtime')
x_axis,y_axis,z_axis=1,2,3
sizeSpacingLetter,sizeDownLetter=300,350
unitID,textSpinner,SIG_FLICKER=9,99,1
local moves, waits, sleeps, visible, turns = {},{},{},{},{}
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<math.huge end
function Move(id,axis,target,speed)
    assert(type(id)=='number' and id>0, 'Move requires piece ID')
    assert(axis==1 or axis==2 or axis==3, 'Move requires axis')
    assert(finite(target) and finite(speed) and speed>=0, 'invalid Move parameters')
    moves[#moves+1]={id,axis,target,speed}
end
function WaitForMove(id,axis)
    assert(type(id)=='number' and axis and axis>=1 and axis<=3)
    waits[#waits+1]={id,axis}
end
function Sleep(ms) assert(finite(ms) and ms>=0); sleeps[#sleeps+1]=ms end
function Turn(id,axis,angle,speed)
    assert(type(id)=='number' and axis>=1 and axis<=3 and finite(angle) and finite(speed) and speed>=0)
    turns[#turns+1]={id,axis,angle,speed}
end
function Spin(id,axis,speed,accel) assert(type(id)=='number' and finite(speed) and finite(accel)) end
function StopSpin(...) assert(select('#',...)==3) end
function ShowReg(id) assert(type(id)=='number');visible[id]=true end
function HideReg(id) assert(type(id)=='number');visible[id]=nil end
function foreach(t,fn) local out={}; for _,id in ipairs(t) do local v=fn(id);if v then out[#out+1]=v end end; return out end
function showTReg(t) for _,id in ipairs(t) do ShowReg(id) end end
function hideTReg(t) for _,id in ipairs(t) do HideReg(id) end end
function reset() end
function resetT() end
function hideResetAllLetters() end
function WaitForMoves(id) assert(type(id)=='number');for a=1,3 do WaitForMove(id,a) end end
function WMove(...) Move(...) end
function WTurn(...) Turn(...) end
function tP(id,x,y,z,speed) for a,v in ipairs({x,y,z}) do Turn(id,a,v,speed) end end
function randSign() return 1 end
function count(t) return #t end
function getDayTime() return 23 end
function getAllLetters(groups) return groups end
function maRa() return false end
function Signal() end
function StartThread() end
function delayedFlickerSingleLetter() end
function getCivilianTypeTable() return {[4]=true} end
local nearby, alive, lostPosition = {10}, true, false
function getAllNearUnit() return nearby end
function doesUnitExistAlive(id) assert(id==10);return alive end
function getSafeRandom(t) return t[1] end
function getAngleFromCoordinates(x,z) return math.atan2(x,z) end
UnitDefs={}
local identity={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
Spring={
    GetUnitDefID=function() return 4 end,
    GetGameSeconds=function() return 1 end,
    GetUnitPosition=function(id) if id==10 and lostPosition then return nil end; if id==10 then return 20,0,20 end; return 0,0,0 end,
    GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
    GetUnitPieceInfo=function() return {parent='root',min={0,0,0},max={2,2,2}} end,
    GetUnitPieceMap=function() return {root=99} end,
    GetUnitPieceMatrix=function() return unpack(identity) end,
    GetGroundHeight=function(x,z) return x*0.01+z*0.02 end,
}
dofile('scripts/lib_textFx.lua')
local function clear() moves,waits,sleeps,turns,visible={},{},{},{},{} end
local groups={A={1,2},B={3},C={4}}
local slots,leases=allocateHologramSlots('AaA B?AéC',groups)
assert(#slots==9 and slots[1]==1 and slots[2]==2 and slots[3]==' ' and slots[4]==' ')
assert(slots[5]==3 and slots[6]==' ' and slots[7]==' ' and slots[8]==' ' and slots[9]==4)
assert(leases[1][1]==1 and leases[1][2]==3 and leases[2][2]==7)
for i=1,20 do assert(selectHologramMessage({'AAAA','AB','?'},groups)=='AB') end
assert(selectHologramMessage({},groups)=='')
assert(selectHologramMessage({'AAAA'},groups)=='AAAA')
local letters={1,2,3,4}
local pos={myMessage='AaA B?AéC',spacing=slots,leases=leases,slotByPiece={[1]=1,[2]=2,[3]=5,[4]=9},slotPositions={},boolUpright=true,unitID=9,TriLetters=groups}
for i=1,#slots do pos.slotPositions[i]={0,-300*(i-1),0} end
for _,id in ipairs(letters) do pos[id]=pos.slotPositions[pos.slotByPiece[id]] end
clear();holdHologramText(letters,pos,1500)
assert(#sleeps==3 and sleeps[1]==500 and sleeps[2]==500 and sleeps[3]==500)
local destinations={}
for _,m in ipairs(moves) do if m[1]==1 and m[2]==2 then destinations[#destinations+1]=m[3] end end
assert(destinations[1]==0 and destinations[2]==-600 and destinations[3]==0 and destinations[4]==0)
clear();transitionHologramText(letters,pos,true,400)
assert(#waits==4 and #moves==8 and #sleeps==0)
assert(moves[1][3]==105 and moves[2][3]==0 and moves[2][4]==262.5)
clear();transitionHologramText(letters,pos,false,400);assert(not next(visible))
clear();matrixTextFx(letters,pos);assert(#waits==4)
clear();circleProject(letters,pos,2,true,true)
local radius=9*300*2/math.pi
assert(math.abs(moves[1][3]-radius)<1e-7 and #sleeps==0 and visible[1])
-- Curved text effects must use the matching layout/rotation axis in both orientations.
local function movedTarget(id, axis)
    for _,m in ipairs(moves) do
        if m[1]==id and m[2]==axis then return m[3] end
    end
end
local helixRadius=7*sizeSpacingLetter/(2*math.pi)
for _,upright in ipairs({false,true}) do
    pos.boolUpright=upright
    local axial=upright and z_axis or y_axis
    local radial=upright and y_axis or z_axis
    local sign=upright and -1 or 1
    for _,fx in ipairs({spiralProject,dnaHelix}) do
        clear();fx(letters,pos)
        assert(#turns==#letters)
        for _,turn in ipairs(turns) do assert(turn[2]==axial) end
        for _,id in ipairs(letters) do
            assert(movedTarget(id,x_axis) and movedTarget(id,radial) and movedTarget(id,axial))
        end
        assert(math.abs(movedTarget(2,radial)-helixRadius*math.sin(math.pi/7))<1e-7)
        assert(movedTarget(2,axial)==sign*sizeDownLetter)
        local tailOffset=(fx==dnaHelix) and (8-#slots/2) or 8
        assert(movedTarget(4,axial)==sign*tailOffset*sizeDownLetter)
    end
    assert(canProjectTextFx('dnaHelix',pos) and canProjectTextFx('spiralProject',pos))
    assert(canProjectTextFx('SpinLetters',pos)==(not upright))
end
-- Both script integrations execute the same allocation/layout path, not a test clone.
local function loadFunction(path,name,nextName)
    local f=assert(io.open(path));local text=f:read('*a');f:close()
    local start=assert(text:find('function '..name,1,true))
    local finish=nextName and assert(text:find('function '..nextName,start+1,true))-1 or #text
    assert(loadstring(text:sub(start,finish)))()
end
for _,path in ipairs({'scripts/house_western_hologram_script.lua','scripts/house_western_brothel_hologram_script.lua'}) do
    TableOfPiecesGroups=groups
    loadFunction(path,'setupMessage','restoreMessageOriginalPosition')
    clear();local ids,p,message=setupMessage({'AaA B?AéC'})
    assert(#ids==4 and #p.spacing==9 and message=='AaA B?AéC')
    assert(ids[1]==1 and ids[2]==2 and ids[3]==3 and ids[4]==4)
    assert(p[3][2]==-1200 and p[4][2]==-2400 and p.slotPositions[3][2]==-600)
    loadFunction(path,'waterFallProject','addHologramLetters')
    clear();waterFallProject(letters,pos)
    local seen={};for _,m in ipairs(moves) do if m[1]==1 and m[4]>0 then seen[m[2]]=m[3] end end
    assert(seen[1]==0 and seen[2]==0 and seen[3]==0)
    loadFunction(path,'disAppearGlowWorm','disAppearGlowWormSwarm')
    -- Load sequential reveal helpers independently; the effect retains its flicker branch.
    loadFunction(path,'fadeIn','disAppearGlowWorm')
    clear();disAppearGlowWorm({1,2},100,1000,100)
    local sum=0;for _,ms in ipairs(sleeps) do sum=sum+ms end
    assert(sum==1200,'flicker lifetime must not quadruple the intended hold')
    clear();disAppearGlowWorm({},100,1000,100);assert(#sleeps==0)
end
function restoreMessageOriginalPosition(ids,p) for _,id in ipairs(ids) do for a=1,3 do Move(id,a,p[id][a],0) end;ShowReg(id) end end
-- Exercise every registered mode in both orientations with strict animation APIs.
local modes=getAllTextFx();assert(count((function() local a={} for k in pairs(modes) do a[#a+1]=k end return a end)())==22)
for name,fn in pairs(modes) do
    for _,upright in ipairs({false,true}) do
        clear();pos.boolUpright=upright
        local ok,err=pcall(fn,letters,pos,groups);assert(ok,name..': '..tostring(err))
        clear();assert(pcall(fn,{},pos,groups),name..' empty')
    end
end
-- A parent rotated and scaled in model space must invert correctly for world targets.
local saved=Spring.GetUnitPieceMatrix
Spring.GetUnitPieceMatrix=function(owner,id)
    if id==99 then return 0,2,0,0,-3,0,0,0,0,0,4,0,0,0,0,1 end
    return unpack(identity)
end
clear();local mover=assert(hologramWorldMover(9,1,{0,0,0},{root=99}));mover(6,8,12,0.2)
assert(moves[1][3]==4 and moves[2][3]==-2 and moves[3][3]==3)
Spring.GetUnitPieceMatrix=saved
nearby={};clear();civilianCongaText(letters,pos);assert(#moves==0)
nearby={10};alive=false;clear();civilianCongaText(letters,pos);assert(#moves==0)
alive=true;lostPosition=true;clear();civilianCongaText(letters,pos)
lostPosition=false;clear();civilianCongaText(letters,pos)
assert(#sleeps==80 and sleeps[1]==800 and sleeps[2]==200)
assert(#moves<1100,'conga must remain a bounded 5-Hz effect')
-- Rival-only pieces persist while shared pieces alternate between slogans.
local oldRestore=restoreMessageOriginalPosition
local restored=false
restoreMessageOriginalPosition=function(ids,p) restored=true;oldRestore(ids,p) end
pos.messages={'AaA B?AéC','CAB'}
clear();hostileTakeoverText(letters,pos,groups)
local shootoutTime=0;for _,ms in ipairs(sleeps) do shootoutTime=shootoutTime+ms end
assert(#sleeps==70 and sleeps[1]==500 and sleeps[2]==120 and shootoutTime==12000 and restored)
local zTargets={}
for _,m in ipairs(moves) do if m[1]==1 and m[2]==3 then zTargets[#zTargets+1]=m[3] end end
assert(zTargets[1]==0 and zTargets[2]==-175 and zTargets[3]==-700 and zTargets[5]==0)
local animatedShot=false;for _,m in ipairs(moves) do if m[4]>0 then animatedShot=true end end
assert(animatedShot,"shared glyph bullets must travel using engine interpolation")
pos.messages={pos.myMessage};clear();hostileTakeoverText(letters,pos,groups);assert(#moves==0)
restoreMessageOriginalPosition=oldRestore
-- Shared effect temporaries may not leak into other animation threads.
for _,name in ipairs({'radius','radiant','circumference','civilian','speed','waitTime','oldValue','timeOut'}) do
    assert(rawget(_G,name)==nil,'leaked scratch global '..name)
end
print('hologram text effects: allocation, leases, layout, 22 modes, transforms and transitions passed')
