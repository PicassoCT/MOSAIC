-- Run with Lua 5.1+ from the repository root. Exercise the recruitment script
-- and command/dispatcher helpers that the gadget integration mock does not load.
local function read(path)
    local f=assert(io.open(path));local s=f:read('*a');f:close();return s
end
local function between(path,first,last)
    local s=read(path);local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
    return s:sub(a,b-1)
end
local function recruitment(def,team,fail)
    local w={units={
        [2]={def=def,team=team,x=10,z=10},[3]={def=3,team=0,x=20,z=20},
        [14]={def=4,team=1,x=10,z=10},[90]={def=9,team=0,x=10,z=10},
        [99]={def=10,team=1,x=10,z=10}},created={},marked={},moved={},orders={}}
    unitID,fatherID,script=99,14,{}
    UnitDefs={[1]={name='civilianagent'},[3]={name='house'},[4]={name='operative'},[9]={name='civilian'}}
    UnitDefNames={civilianagent={id=1}}
    GG={DisguiseCivilianFor={[90]=2},Counterintelligence={
        IsProductionDisabled=function() return w.disabled end,
        AdoptRecruit=function(id,builder) w.adopted={id,builder} end,
        UnitReplaced=function(old,new) w.replaced={old,new} end}}
    Spring={
        GetGaiaTeamID=function() return 0 end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetUnitTeam=function(id) return w.units[id] and w.units[id].team end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return not w.units[id] end,
        GetUnitPosition=function(id) local u=w.units[id];return u.x,0,u.z end,
        GetUnitHealth=function() return 75,100,0,0,1 end,
        GetUnitExperience=function() return 2 end,GetUnitRotation=function() return 0,0,0 end,
        GetUnitBuildFacing=function() return 0 end,
        SetUnitHealth=function() end,SetUnitExperience=function() end,SetUnitRotation=function() end,
        SetUnitNanoPieces=function() end,
        AreTeamsAllied=function(a,b) return a==b or (a==3 and b==1) or (a==1 and b==3) end,
        GetTeamUnits=function() return {3,90} end,
        GiveOrderToUnit=function(...) w.orders[#w.orders+1]={...} end,
        CreateUnit=function(d,x,y,z,facing,t,built,flatten,forced,builder)
            w.attempts=(w.attempts or 0)+1
            if fail then return end
            assert(t==1,'recruit must belong to the recruiter, never an undefined team')
            w.units[101]={def=type(d)=='string' and UnitDefNames[d].id or d,team=t,x=x,z=z}
            w.created[#w.created+1]=101;return 101
        end,
        DestroyUnit=function(id) assert(w.units[id]);w.units[id]=nil end,
    }
    VFS={Include=dofile}
    function include() end
    function getGameConfig() return {game={culture='test'},espionage={recruitment={range=100}}} end
    function getCultureUnitModelTypes(_,kind) return kind=='house' and {[3]=true} or {[9]=true} end
    function getOperativeTypeTable() return {[1]=true,[4]=true} end
    function getTruckTypeTable() return {} end
    function getAllNearUnit() return {90} end
    function foreach(ids,...)
        local filters={...}
        for _,id in ipairs(ids) do
            for _,f in ipairs(filters) do if id then id=f(id) end end
        end
    end
    function StartThread() end
    function waitTillComplete() return true end
    local sleeps=0
    function Sleep(ms)
        sleeps=sleeps+1
        if ms==1000 or sleeps>1 then error('TEST_LOOP_END',0) end
    end
    function doesUnitExistAlive(id) return w.units[id]~=nil end
    function registerChild(t,b,id) assert(t==1 and b==14 and id==101) end
    function transferUnitStatusToUnit(old,new) w.status={old,new} end
    function attachDoubleAgentToUnit(id,t) w.marked[id]=t end
    function moveUnitToUnit(id,house) w.moved[#w.moved+1]={id,house} end
    function randSign() return 1 end
    dofile('scripts/recruitcivilianscript.lua')
    function w:run()
        local ok,err=pcall(recruiteLoop)
        assert(not ok and err=='TEST_LOOP_END',tostring(err))
    end
    return w
end

local w=recruitment(1,2);w:run()
assert(not w.units[2] and not w.units[99] and w.units[101].team==1)
assert(w.marked[101]==2 and w.adopted[2]==14 and #w.orders==0)
assert(GG.UnitReplacement==nil,'replacement context must not leak')

w=recruitment(1,2,true);w:run()
assert(w.units[2] and w.units[99] and #w.created==0 and w.attempts==1,
    'failed existing-agent replacement must not destroy it or fall through to another spawn')
assert(GG.UnitReplacement==nil)

w=recruitment(4,2);w:run()
assert(w.units[2] and w.marked[101]==2 and w.units[101].team==1)
assert(#w.moved==1 and w.moved[1][1]==2 and w.moved[1][2]==3,
    'move the disguised operative to the nearest house, never the last scanned neutral unit')

w=recruitment(4,3);w:run()
assert(#w.created==0 and #w.moved==0,'allied operatives must not be recruited as enemies')
w=recruitment(4,2,true);w:run()
assert(w.units[2] and #w.moved==0 and w.units[99],'unit cap must not move the original operative')
w=recruitment(4,2,true);GG.DisguiseCivilianFor={};w:run()
assert(w.units[90] and w.units[99],'failed civilian recruitment preserves the civilian')
w=recruitment(4,2);w.disabled=true;w:run()
assert(#w.created==0 and not w.units[99],'discovered recruiters cannot use an existing recruit icon')

local orders={}
CMD={CLOAK=95}
Spring={GetUnitDefID=function() return 1 end,GetUnitIsCloaked=function(id) return id==2 end,
    GiveOrderToUnit=function(...) orders[#orders+1]={...} end}
assert(loadstring(between('scripts/lib_UnitScript.lua','function Command(','function getPieceNrByName(')))()
Command(2,'cloak');Command(14,'cloak')
assert(orders[1][1]==2 and orders[1][2]==95 and orders[1][3][1]==0)
assert(orders[2][1]==14 and orders[2][3][1]==1,'cloak command must address the requested unit')

gadgetHandler={AllowUnitDecloakList={{AllowUnitDecloak=function(_,id) return id~=5 end}},
    AllowUnitTransportList={{AllowUnitTransport=function(_,carrier,def,team,id)
        assert(carrier==20 and def==21 and team==1);return id~=2
    end}}}
assert(loadstring(between('luarules/gadgets.lua','function gadgetHandler:AllowUnitDecloak(',
    'function gadgetHandler:AllowWeaponTarget(')))()
assert(not gadgetHandler:AllowUnitDecloak(5) and gadgetHandler:AllowUnitDecloak(6))
assert(not gadgetHandler:AllowUnitTransport(20,21,1,2,4,2))
assert(gadgetHandler:AllowUnitTransport(20,21,1,14,4,1))

-- A safehouse takeover must retain its original house without interpreting
-- already-transferred nearby factories as a duplicate construction.
unitID,unitDefID,script=101,2,{}
GG={UnitReplacement={oldID=10},houseHasSafeHouseTable={[3]=10}}
Spring={GetGaiaTeamID=function() return 0 end,GetUnitTeam=function() return 2 end,
    GetUnitDefID=function() return 2 end,SetUnitNanoPieces=function() end,
    SetUnitBlocking=function() end}
function piece(name) return name end
function getSafeHouseUpgradeTypeTable() return {[4]=true} end
function getSafeHouseTypeTable() return {[2]=true} end
function getHouseTypeTable() return {[3]=true} end
function getPieceTableByNameGroups() return {} end
function setSafeHouseTeamName() end
local threads={}
function StartThread(f) threads[f]=true end
dofile('scripts/safehousescript.lua')
function preventBuildingNearPreexistingSafehouse() error('ownership replacement is not new construction') end
script.Create()
assert(containingHouseID==3 and GG.houseHasSafeHouseTable[3]==101)
assert(not threads[houseAttach] and not threads[killDelayed] and threads[drawMapRoom])
print('PASS counterintelligence helpers: recruitment team, alliances, unit caps, operative escape identity, disabled recruitment, targeted cloak, cloak/transport dispatch, safehouse attachment')
