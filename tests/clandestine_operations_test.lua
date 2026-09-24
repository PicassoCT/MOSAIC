-- Standalone Lua 5.1+: actual gadgets with a deterministic, resource-aware Spring mock.
local unpack = table.unpack or unpack
local D = {operative=1, civilian=2, house=3, policetruck=4, riotpolice=5,
    ground_tank_night=6, house_spinner=7, icon_cybercrime=8, icon_bribe=9,
    protagonsafehouse=10, propagandaserver=11}
local function world()
    local w = {frame=0, units={}, rules={}, teamRules={}, orders={}, nextID=1000,
        money={[0]=0,[1]=2000,[2]=2000,[3]=2000}, energy={[0]=0,[1]=2000,[2]=2000,[3]=2000},
        created={}, debits={}, payments={}}
    GG={InstanceCulture='arabic', BuildingTable={}, houseHasSafeHouseTable={}}
    Game={mapSizeX=10000,mapSizeZ=10000}
    UnitDefs,UnitDefNames={},{}
    for name,id in pairs(D) do
        UnitDefNames[name]={id=id};UnitDefs[id]={id=id,name=name,metalCost=0,energyCost=0}
    end
    UnitDefs[D.propagandaserver].metalCost=1000
    UnitDefs[D.propagandaserver].energyCost=1000
    CMD={STOP=0,MOVE=10,ATTACK=20,GUARD=25}
    WeaponDefNames={closecombat={id=5}}
    gadgetHandler={IsSyncedCode=function() return true end}
    VFS={Include=function(path)
        if path=='luarules/gadgets/include/police_bribery.lua' then return dofile(path) end
    end}
    function w:position(id,x,z) self.units[id].x=x;self.units[id].z=z end
    function w:finish(id)
        local u=self.units[id];u.progress=1
        self.police:UnitFinished(id,u.def,u.team)
        self.cyber:UnitFinished(id,u.def,u.team)
    end
    function w:add(id,def,team,x,z,finished,builder)
        self.units[id]={def=def,team=team,x=x,z=z,progress=finished==false and 0.5 or 1,cloak=false}
        if def==D.house then GG.BuildingTable[id]={x=x,z=z} end
        self.police:UnitCreated(id,def,team,builder)
        self.cyber:UnitCreated(id,def,team,builder)
        if finished~=false then self:finish(id) end
        return id
    end
    function w:tick(frame)
        self.frame=frame
        self.cyber:GameFrame(frame)
        self.police:GameFrame(frame)
    end
    function w:damage(victim,attacker,weapon)
        local v,a=self.units[victim],self.units[attacker]
        self.police:UnitDamaged(victim,v.def,v.team,20,false,weapon or 6,nil,attacker,a.def,a.team)
    end
    Spring={
        GetGaiaTeamID=function() return 0 end,GetTeamAllyTeamID=function(t) return t end,
        GetGameFrame=function() return w.frame end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return not w.units[id] or w.units[id].dead end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetUnitTeam=function(id) return w.units[id] and w.units[id].team end,
        GetUnitPosition=function(id)
            local u=w.units[id];if u and not u.dead then return u.x,0,u.z end
        end,
        GetUnitHealth=function(id) if w.units[id] then return 100,100,0,0,w.units[id].progress end end,
        GetUnitIsCloaked=function(id) return w.units[id] and w.units[id].cloak end,
        GetUnitStates=function(id) return {cloak=w.units[id].cloak} end,
        SetUnitCloak=function(id,v) w.units[id].cloak=v end,
        GetUnitLosState=function(id) return {los=not w.units[id].hidden} end,
        AreTeamsAllied=function(a,b) return a==b or (a==1 and b==3) or (a==3 and b==1) end,
        GetGroundHeight=function() return 0 end,GetUnitRadius=function() return 100 end,
        TestMoveOrder=function() return true end,SetUnitNeutral=function() end,
        GetAllUnits=function()
            local ids={};for id,u in pairs(w.units) do if not u.dead then ids[#ids+1]=id end end
            table.sort(ids);return ids
        end,
        GetUnitsInCylinder=function(x,z,r)
            local ids={};for id,u in pairs(w.units) do
                if not u.dead and (x-u.x)^2+(z-u.z)^2<=r*r then ids[#ids+1]=id end
            end;table.sort(ids);return ids
        end,
        GetTeamUnitsByDefs=function(team,def)
            local ids={};for id,u in pairs(w.units) do
                if not u.dead and u.team==team and u.def==def then ids[#ids+1]=id end
            end;return ids
        end,
        GetTeamResources=function(team,kind) return (kind=='metal' and w.money or w.energy)[team] end,
        AddTeamResource=function(team,kind,amount)
            local t=kind=='metal' and w.money or w.energy;t[team]=(t[team] or 0)+amount
        end,
        UseTeamResource=function(team,kind,amount)
            local t=kind=='metal' and w.money or w.energy
            assert(amount>=0 and t[team]>=amount,'debit exceeds available resources')
            t[team]=t[team]-amount;w.debits[#w.debits+1]={team,amount};return true
        end,
        SetUnitRulesParam=function(id,key,value,visibility)
            assert(visibility.private and not visibility.public,'operation details must stay private')
            w.rules[id]=w.rules[id] or {};w.rules[id][key]=value
        end,
        GetTeamRulesParam=function(team,key) return w.teamRules[team] and w.teamRules[team][key] end,
        SetTeamRulesParam=function(team,key,value,visibility)
            assert(visibility.private);w.teamRules[team]=w.teamRules[team] or {};w.teamRules[team][key]=value
        end,
        GiveOrderToUnit=function(id,cmd,p) w.orders[id]={cmd=cmd,p=p} end,
        MoveCtrl={SetPosition=function(id,x,y,z) w:position(id,x,z) end},
        CreateUnit=function(name,x,y,z,heading,team)
            w.nextID=w.nextID+1;w.created[#w.created+1]=w.nextID
            return w:add(w.nextID,D[name],team,x,z)
        end,
        DestroyUnit=function(id)
            local u=w.units[id];assert(u and not u.dead,'double destruction')
            u.dead=true
            -- Police runs first to exercise cleanup independently of gadget ordering.
            w.police:UnitDestroyed(id,u.def);w.cyber:UnitDestroyed(id,u.def)
            GG.BuildingTable[id]=nil
        end,
    }
    local file=assert(io.open('scripts/lib_mosaic.lua','r'))
    local source=file:read('*a');file:close()
    -- Load the actual config without unrelated top-level faction/build-menu setup.
    assert((loadstring or load)(source:sub(1,assert(source:find('   function getAllCultures',1,true))-1)))()
    local config=getGameConfig();getGameConfig=function() return config end;w.config=config
    getPoliceTypes=function() return {[D.policetruck]=true,[D.ground_tank_night]=true,[D.house_spinner]=true} end
    getSafeHouseTypeTable=function() return {[D.protagonsafehouse]=true} end
    getOperativeTypeTable=function() return {[D.operative]=true} end
    getMobileCivilianDefIDTypeTable=function() return {[D.civilian]=true} end
    getCultureUnitModelTypes=function(_,kind) return kind=='civilian' and {[D.civilian]=true} or
        kind=='house' and {[D.house]=true} or {} end
    getScrapheapTypeTable=function() return {} end
    isOffenceIcon=function(_,def) return def==D.icon_cybercrime end
    registerEmergency=function() end
    GG.Bank={TransferToTeam=function(_,amount,team,id)
        assert(amount>0,'enemy debit must not create a location popup')
        w.money[team]=w.money[team]+amount;w.payments[#w.payments+1]={team,amount,id}
    end}
    gadget={};dofile('luarules/gadgets/game_cybercrime.lua');w.cyber=gadget;w.cyber:Initialize()
    gadget={};dofile('luarules/gadgets/game_police.lua');w.police=gadget;w.police:Initialize()
    w:add(1,D.operative,1,1000,1000)
    w:add(2,D.civilian,0,1050,1000)
    w:add(10,D.house,0,1000,1000)
    w:add(11,D.house,0,4000,4000)
    return w
end
local function node(w,id,house,builder,complete)
    local h=w.units[house or 10];return w:add(id,D.icon_cybercrime,1,h.x,h.z,complete,builder or 1)
end
local function officer(w,id,def) return w:add(id,def or D.policetruck,0,1100,1000) end
local function bribe(w,id,builder,complete)
    return w:add(id,D.icon_bribe,1,1000,1000,complete,builder)
end

-- Construction is the investment: no extraction, reports or recovery before completion.
do
    local w=world();w.money[1]=0;w.energy[1]=0;node(w,20,10,1,false)
    w:tick(1800);assert(w.money[1]==0 and #w.created==0 and not w.teamRules[1])
    w:finish(20);w:tick(2070);assert(w.money[1]==0)
    w:tick(2100);assert(w.money[1]==1025 and w.energy[1]==1000,'recovery funds one server from zero')
    assert(w.teamRules[1].cybercrime_comeback_used==1)
    w.money[1]=0;w.energy[1]=0;w:tick(2400)
    assert(w.money[1]==25 and w.energy[1]==0,'recovery cannot be farmed')
end
-- Completed servers disqualify recovery; a stranded unfinished server does not.
do
    local w=world();w.money[1]=0;w.energy[1]=0
    w:add(30,D.propagandaserver,1,1300,1000);node(w,20);w:tick(300)
    assert(w.money[1]==25 and not w.teamRules[1])
    Spring.DestroyUnit(30);w:add(31,D.propagandaserver,1,1300,1000,false)
    w:tick(600);assert(w.money[1]==1050 and w.energy[1]==1000)
end
-- Simultaneous recovery requests share one persistent team token.
do
    local w=world();w.money[1]=0;w.energy[1]=0;node(w,20);node(w,21,11);w:tick(300)
    assert(w.money[1]==1050 and w.energy[1]==1000)
    assert(w.rules[20].cybercrime_comeback==1000 and not w.rules[21].cybercrime_comeback)
    w.cyber:Shutdown();gadget={};dofile('luarules/gadgets/game_cybercrime.lua');w.cyber=gadget;w.cyber:Initialize()
    w.money[1]=0;w.energy[1]=0;w:tick(600)
    assert(w.money[1]==50 and w.energy[1]==0,'reload cannot renew recovery')
end
-- Ordinary extraction and safehouse support.
do
    local w=world();node(w,20);w:tick(300)
    assert(w.money[1]==2025 and w.money[2]==2000 and w.energy[1]==2000)
    w:add(30,D.protagonsafehouse,1,1200,1000);w:tick(600);assert(w.money[1]==2075)
    w.units[30].team=3;w:tick(900);assert(w.money[1]==2100,'only own safehouses improve the payout')
end
-- Hidden occupation overrides nearby support, drains 2x base, and never publishes the victim.
do
    local w=world();w:add(30,D.protagonsafehouse,2,1000,1000)
    GG.houseHasSafeHouseTable[10]=30;w:add(31,D.protagonsafehouse,1,1200,1000)
    node(w,20);w:tick(300)
    assert(w.money[1]==2025 and w.money[2]==1950 and w.rules[20].cybercrime_paid==25)
    for key in pairs(w.rules[20]) do assert(not key:find('enemy') and not key:find('victim')) end
    w.money[2]=10;w:tick(600);assert(w.money[1]==2050 and w.money[2]==0)
    w:tick(900);assert(w.money[1]==2075 and w.money[2]==0,'empty enemy account does not change your payout')
    w.units[30].team=3;w:tick(1200);assert(w.money[3]==2000,'allies cannot be siphoned')
end
-- Recovery aid is city-funded, never multiplied into the enemy debit.
do
    local w=world();w.money[1]=0;w.energy[1]=0;w:add(30,D.protagonsafehouse,2,1000,1000)
    GG.houseHasSafeHouseTable[10]=30;node(w,20);w:tick(300)
    assert(w.money[1]==1025 and w.money[2]==1950)
end
-- One stream per building, finite reserves, slow recovery, and bounded simultaneous debits.
do
    local w=world();node(w,20);node(w,21);assert(w.units[21].dead)
    w:tick(300);assert(w.money[1]==2025)
    local v=world();v.config.CyberCrime.buildingCapacity=50
    node(v,20);v:tick(300);v:tick(600);assert(v.units[20].dead)
    node(v,21);assert(v.units[21].dead,'spamming nodes does not replenish the building')
    v:tick(1350);node(v,22);assert(not v.units[22].dead)
    v:tick(1650);assert(v.money[1]==2075 and v.units[22].dead)
    local x=world();x:add(30,D.protagonsafehouse,2,1000,1000);x:add(31,D.protagonsafehouse,2,4000,4000)
    GG.houseHasSafeHouseTable[10]=30;GG.houseHasSafeHouseTable[11]=31;x.money[2]=60
    node(x,20);node(x,21,11);x:tick(300);assert(x.money[1]==2050 and x.money[2]==0)
end
-- Police wait, spawn remotely, investigate the building and terminate extraction on arrival.
do
    local w=world();node(w,20);w:tick(1785);assert(#w.created==0)
    w:tick(1800);assert(#w.created==1)
    local cop=w.created[1];assert(w.units[cop].x>3000 and w.orders[cop].p[1]==1000)
    w:position(cop,1100,1000);w:tick(1815)
    assert(w.units[20].dead and not GG.PoliceInPursuit[cop])
    local paid=w.money[1];w:tick(2100);assert(w.money[1]==paid)
end
-- Destruction/capture cleanup must not leave an officer permanently assigned.
do
    local w=world();node(w,20);w:tick(1800);local cop=w.created[1]
    Spring.DestroyUnit(20);assert(not GG.PoliceInPursuit[cop])
    node(w,21);w.cyber:UnitTaken(21,D.icon_cybercrime);assert(w.units[21].dead)
    node(w,22);Spring.DestroyUnit(10);assert(w.units[22].dead)
end
-- Police-only whitelist and capped, private feedback. The builder is protected by default.
do
    local w=world();for id=40,43 do officer(w,id) end;officer(w,44,D.riotpolice)
    officer(w,45,D.ground_tank_night);officer(w,46,D.house_spinner)
    bribe(w,50,1,false);w:tick(15);assert(not next(GG.PoliceBribes),'unfinished bribe has no effect')
    w:finish(50);w:tick(30)
    assert(w.rules[50].bribe_count==3 and w.rules[50].bribe_target==1)
    assert(not GG.PoliceBribes[45] and not GG.PoliceBribes[46],'military helpers cannot be bribed')
    assert(not w.police:AllowWeaponTarget(40,1) and w.police:AllowWeaponTarget(45,1))
    local allowed,priority=w.police:AllowWeaponTarget(45,1,1,1,73)
    assert(allowed and priority==73,'military target priority must remain unchanged')
    assert(w.orders[40].cmd==CMD.MOVE and w.orders[40].p[1]>1500,'protection steers officers away')
    w.police:AllowCommand(50,D.icon_bribe,1,CMD.MOVE,{2000,0,1000});w:tick(45)
    assert(w.units[50].x<1100,'the icon must travel, not teleport')
    assert(w.orders[40].p[1]==2000 and w.rules[50].bribe_target==-1)
    w:tick(1815);assert(w.units[50].dead and not next(GG.PoliceBribes))
    assert(#w.created==0,'bribery must not generate a police incident')
end
-- Bribes cover routine cybercrime by the guarded operative and block shutdown.
do
    local w=world();node(w,20);w:tick(1800);local cop=w.created[1]
    w:position(cop,1300,1000);bribe(w,50,1);w:tick(1815)
    assert(GG.PoliceBribes[cop]==50)
    w:position(cop,1050,1000);w:tick(1830);assert(not w.units[20].dead)
    Spring.DestroyUnit(50);w:tick(1845);assert(w.units[20].dead,'police resume after bribe destruction')
end
-- Witnessed violence overrides a bribe immediately; silence and active combat remain distinct.
do
    local w=world();officer(w,40);bribe(w,50,1);w:tick(15);assert(GG.PoliceBribes[40])
    w:damage(2,1,5);assert(GG.PoliceBribes[40],'silent stabbing does not create a gunfire report')
    w:damage(2,1,6);assert(not GG.PoliceBribes[40] and w.police:AllowWeaponTarget(40,1))
    w:tick(30);assert(not GG.PoliceBribes[40],'combat grace prevents immediate rebribing')
    w:tick(180);assert(not GG.PoliceBribes[40],'a witnessed shooter still in sight cannot buy off the witness')
end
-- Officers in direct pursuit refuse diversion, but searching after losing sight can be misled.
do
    local w=world();w:damage(2,1);w:tick(240);local cop=w.created[1]
    w:position(cop,1100,1000);w:tick(330);assert(w.orders[cop].cmd==CMD.ATTACK)
    bribe(w,50);w:tick(345);assert(not GG.PoliceBribes[cop])
    w:position(1,8000,8000);w:tick(480);assert(GG.PoliceBribes[cop]==50)
end
-- A nearby police shootout reveals safehouses temporarily; ordinary reports do not.
do
    local w=world();w:add(30,D.protagonsafehouse,1,1200,1000);w.units[30].cloak=true
    w:add(31,D.protagonsafehouse,1,2000,1000);w.units[31].cloak=true
    officer(w,40);w:damage(2,1);assert(w.units[30].cloak)
    w:damage(40,1);assert(not w.units[30].cloak and w.units[31].cloak)
    assert(not w.police:AllowUnitCloak(30));w:tick(900)
    assert(w.units[30].cloak and w.police:AllowUnitCloak(30))
    -- Verify real handler registration/forwarding, not only direct gadget calls.
    local f=assert(io.open('luarules/gadgets.lua','r'));local source=f:read('*a');f:close()
    local lists=assert(source:match('local callInLists = (%b{})'))
    assert(lists:find('"AllowUnitCloak"',1,true),'engine handler must register the cloak veto')
    gadgetHandler.AllowUnitCloakList={w.police}
    assert((loadstring or load)(assert(source:match('function gadgetHandler:AllowUnitCloak.-\nend'))))()
    w:damage(40,1);assert(not gadgetHandler:AllowUnitCloak(30))
    gadgetHandler.AllowWeaponTargetList={w.police}
    assert((loadstring or load)(assert(source:match('function gadgetHandler:AllowWeaponTarget%([^\n]*.-\nend'))))()
    local allowed,priority=gadgetHandler:AllowWeaponTarget(99,1,1,1,73)
    assert(allowed and priority==73,'handler preserves priorities for unaffected units')
end
-- Unit definitions enforce the time-versus-money split and expose both operative commands.
do
    local function normalize(t)
        if type(t)~='table' then return t end
        local out={};for k,v in pairs(t) do out[type(k)=='string' and k:lower() or k]=normalize(v) end
        return out
    end
    function lowerkeys(t) return normalize(t) end
    local base={New=function(_,t) return setmetatable(t or {},{__index=base}) end}
    -- New() must preserve the fields of the prototype used for the final :New call.
    function base:New(t)
        local result={};for k,v in pairs(self) do result[k]=v end
        for k,v in pairs(t or {}) do result[k]=v end
        return result
    end
    Abstract,Human=base,base
    local defs=dofile('units/shared/abstracts/Icons.lua')
    assert(defs.icon_cybercrime.buildcostmetal==0 and defs.icon_cybercrime.buildcostenergy==0)
    assert(defs.icon_cybercrime.buildtime==30 and defs.icon_bribe.buildtime==1)
    assert(defs.icon_bribe.buildcostmetal==150 and defs.icon_bribe.canguard)
    local function contains(t,v) for _,x in ipairs(t) do if x==v then return true end end end
    assert(contains(dofile('units/antagon/OperativePropagator.lua').operativepropagator.buildoptions,'icon_bribe'))
    assert(contains(dofile('units/protagon/operativeInvestigator.lua').operativeinvestigator.buildoptions,'icon_bribe'))
end
print('PASS: construction gate, recovery, secrecy, siphoning, reserves, police interruption, cleanup, bribery, military exclusion, violence, search, exposure, definitions')
