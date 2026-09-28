-- Run from the repository root: lua tests/sticky_bombs_test.lua
local frame, nextID, failCreate, failAttach = 0, 100, false, false
local rules, descs, attached, sent, spawned, damage, goals, threads = {}, {}, {}, {}, {}, {}, {}, {}
local units = {
    [1]={def=1,team=1,x=0,y=0,z=0}, [2]={def=1,team=1,x=0,y=0,z=0},
    [10]={def=3,team=2,x=400,y=0,z=0}, [11]={def=3,team=2,x=20,y=0,z=0},
    [12]={def=3,team=1,x=30,y=0,z=0}, [13]={def=4,team=2,x=40,y=0,z=0},
}
local resource = {m=10000,e=10000}
local function check(value, message) assert(value, message) end
local function near(a,b) return math.abs(a-b)<1e-6 end
CMD={INSERT=1,MOVE=10,STOP=0}
CMDTYPE={ICON=0,ICON_UNIT=12}
Game={gameSpeed=30}
GG={}
UnitDefNames={operativeasset={id=1},ground_stickybomb={id=2},operativeinvestigator={id=4}}
UnitDefs={[1]={buildOptions={2},buildSpeed=0.5},[2]={metalCost=300,energyCost=300,buildTime=0.5},[3]={},[4]={}}
gadget={}
gadgetHandler={IsSyncedCode=function() return true end,RegisterCMDID=function() end}
VFS={Include=dofile}
Spring={
    GetAllUnits=function() return {1,2,10,11,12,13} end,
    GetUnitDefID=function(id) return units[id] and units[id].def end,
    ValidUnitID=function(id) return units[id] ~= nil end,
    GetUnitIsDead=function(id) return units[id] and units[id].dead end,
    GetUnitTeam=function(id) return units[id].team end,
    GetUnitAllyTeam=function(id) return units[id].team end,
    AreTeamsAllied=function(a,b) return a==b end,
    GetUnitLosState=function(id) return {los=not units[id].hidden} end,
    GetUnitIsStunned=function(id) return units[id].stunned,false,units[id].beingBuilt end,
    GetUnitPosition=function(id) local u=units[id]; if u then return u.x,u.y,u.z end end,
    GetUnitRadius=function() return 10 end,
    GetUnitRulesParam=function(id,key) return rules[id] and rules[id][key] end,
    SetUnitRulesParam=function(id,key,value) rules[id]=rules[id] or {}; rules[id][key]=value end,
    FindUnitCmdDesc=function(id,cmd) return descs[id] and descs[id][cmd] and cmd end,
    EditUnitCmdDesc=function(id,cmd,desc) for k,v in pairs(desc) do descs[id][cmd][k]=v end end,
    InsertUnitCmdDesc=function(id,desc) descs[id]=descs[id] or {}; descs[id][desc.id]=desc end,
    GetGameFrame=function() return frame end,
    UseUnitResource=function(id,cost)
        if resource.m<cost.m or resource.e<cost.e then return false end
        resource.m,resource.e=resource.m-cost.m,resource.e-cost.e; return true
    end,
    AddTeamResource=function(team,key,amount) local k=key:sub(1,1); resource[k]=resource[k]+amount end,
    SetUnitMoveGoal=function(id,x,y,z) goals[id]={x,y,z} end,
    ClearUnitGoal=function(id) goals[id]=nil end,
    SetUnitBlocking=function() end,
    CreateUnit=function(name,x,y,z,facing,team)
        if failCreate then return nil end
        nextID=nextID+1; units[nextID]={def=2,team=team,x=x,y=y,z=z}
        spawned[#spawned+1]=nextID; return nextID
    end,
    DestroyUnit=function(id)
        gadget:UnitDestroyed(id,units[id].def,units[id].team)
        units[id]=nil; attached[id]=nil
    end,
    GetUnitPieceMap=function() return {other=9,first=2,last=7} end,
    UnitAttach=function(target,bomb,piece,force)
        check(piece==2 and force,'stable piece and forced attachment even for transport vehicles')
        if not failAttach then attached[bomb]=target end
    end,
    GetUnitTransporter=function(id) return attached[id] end,
    GetUnitsInCylinder=function() return {11,12} end,
    SpawnCEG=function() end,PlaySoundFile=function() end,
    AddUnitDamage=function(id,amount,paralyze,attacker) damage[#damage+1]={id,amount,attacker} end,
}
for _,id in ipairs({1,2}) do descs[id]={[-2]={id=-2,type=20,action='buildunit_ground_stickybomb'}} end
dofile('luarules/gadgets/game_sticky_bombs.lua')
gadget:Initialize()
local BUILD,PLANT=CMD_STICKY_BUILD,CMD_STICKY_PLANT
local function order(id,cmd,p,opts)
    return gadget:AllowCommand(id,units[id].def,units[id].team,cmd,p or {},opts or {})
end
local function tick(n)
    for i=1,n do frame=frame+1; gadget:GameFrame(frame) end
end
local function stock(id) return rules[id].sticky_bombs end
local function plant(id,target)
    return gadget:CommandFallback(id,units[id].def,units[id].team,PLANT,{target})
end
check(descs[1][-2].type==CMDTYPE.ICON,'build tile needs no ground placement')
check(not order(1,BUILD),'production must leave movement queue untouched')
tick(15); check(stock(1)==0 and near(resource.m,9850),'production consumes original costs over build time')
order(1,BUILD,{}, {right=true}); check(near(resource.m,10000),'cancel unfinished production refunds invested cost')
order(1,BUILD); resource.e=0; tick(30)
check(stock(1)==0 and near(resource.m,10000),'energy shortage cannot consume money')
resource.e=10000; units[1].stunned=true; tick(30); check(stock(1)==0,'stun pauses production')
units[1].stunned=false; tick(30)
check(stock(1)==1 and near(resource.m,9700) and near(resource.e,9700),'exact original cost per finished charge')
check(#spawned==0,'stock is inventory, with no ticking bomb unit')
tick(200); check(stock(1)==1 and #damage==0,'carried stock does not self-detonate')
check(not order(10,BUILD) and not order(10,PLANT,{11}),'non-builders cannot manufacture or plant')
check(not order(1,PLANT,{12}) and not order(1,PLANT,{13}),'allies and operatives excluded')
check(not order(1,PLANT,{0/0}) and not order(1,PLANT,{10,11}),'malformed orders rejected')
check(not order(1,CMD.INSERT,{0,-2,0,0,0,0}),'inserted legacy construction cannot bypass stock')
check(not gadget:AllowUnitCreation(2,1),'ground construction blocked')
check(order(1,PLANT,{10}),'explicit target accepted')
local _,done=plant(1,10); check(not done and goals[1][1]==400,'approaches clicked target, not nearby vehicle 11')
units[10].x=500; plant(1,10); check(goals[1][1]==500,'follows the same moving target')
units[10].hidden=true; _,done=plant(1,10); check(done and stock(1)==1 and #spawned==0,'lost LOS cancels without retargeting or consumption')
units[10].hidden=false; units[1].x=400
failCreate=true; plant(1,10); check(stock(1)==1,'unit limit does not consume stock')
failCreate=false; failAttach=true; plant(1,10); check(stock(1)==1,'attachment failure does not consume stock')
failAttach=false; plant(1,10)
local planted=spawned[#spawned]
check(stock(1)==0 and attached[planted]==10,'exact chosen vehicle receives one bomb')
check(GG.StickyBombPayloads[planted].fuse==5000,'planted fuse remains five seconds')
order(2,BUILD,{}, {shift=true}); tick(90)
check(stock(2)==3 and rules[2].sticky_bombs_queued==2,'queue produces multiple carried charges')
units[2].team=3; gadget:UnitGiven(2,1); check(stock(2)==3,'team transfer keeps inventory')
local before=#spawned
units[2].x=75; gadget:UnitDestroyed(2,1,3); units[2]=nil
tick(1)
local dropped=spawned[#spawned]
check(#spawned==before+1 and units[dropped].x==75,'death drops a bundle at the death location')
check(GG.StickyBombPayloads[dropped].count==3 and GG.StickyBombPayloads[dropped].fuse==2000,'all completed bombs explode after two seconds; unfinished bombs excluded')
-- Exercise the actual script coroutine and fuse, not a substitute implementation.
local function runFuse(id, expectedMs, expectedDamage, expectedVictim)
    unitID=id; script={}; include=function() end; piece=function(name) return name end
    Show=function() end; Hide=function() end; EmitSfx=function() end
    Spring.SetUnitNoSelect=function() end
    StartThread=function(fn) threads[id]=coroutine.create(fn) end
    Sleep=function(ms) coroutine.yield(ms) end
    dofile('scripts/ground_stickybombscript.lua'); script.Create()
    local elapsed,start=0,#damage
    while coroutine.status(threads[id])~='dead' do
        local ok,ms=coroutine.resume(threads[id]); check(ok,ms)
        if ms then
            elapsed=elapsed+ms
            check(#damage==start,'no damage before fuse expires')
        end
    end
    check(elapsed==expectedMs,'exact fuse duration')
    check(#damage>start and damage[start+1][1]==expectedVictim and near(damage[start+1][2],expectedDamage),'expected blast strength and victim')
end
runFuse(planted,5000,1150,10)
-- At the bundle location both nearby vehicles receive the combined three-charge blast.
runFuse(dropped,2000,3450*(1-55/150),11)
-- Death fallback still detonates if the engine cannot create any unit.
order(1,BUILD); tick(30); check(stock(1)==1)
units[1].x=20; gadget:UnitDestroyed(1,1,1); units[1]=nil
failCreate=true; before=#damage; tick(59)
check(#damage==before,'unit-limit fallback observes death delay')
tick(1); check(#damage>before and near(damage[before+1][2],1150),'unit-limit fallback explodes once at the deadline')
before=#damage; tick(90); check(#damage==before,'death blast never repeats')
-- Widget routes the existing tile to an immediate command, preserving queue modifiers.
widget={}; Spring.GiveOrder=function(cmd,p,opts) sent={cmd,p,opts} end
dofile('luaui/widgets_mosaic/cmd_sticky_bombs.lua')
check(widget:CommandNotify(-2,{}, {shift=true,right=true}),'tile click intercepted')
check(sent[1]==BUILD and #sent[2]==0 and sent[3][1]=='shift' and sent[3][2]=='right','one click build/cancel with modifiers')
check(not widget:CommandNotify(CMD.MOVE,{},{}),'unrelated orders unchanged')
print('PASS: one-click production, resources, cancellation, stun, stable target, movement, LOS, failed attachment, inventory transfer, planted fuse, delayed death bundle, unit-limit fallback, UI routing')
