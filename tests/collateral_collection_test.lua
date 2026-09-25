-- Lua 5.1+: exercise the actual collateral gadget, collector and configuration.
local function loadEnv(path, env)
    local f
    if setfenv then f = assert(loadfile(path)); setfenv(f, env)
    else f = assert(loadfile(path, 't', env)) end
    return f()
end
local function near(actual, expected, message)
    assert(math.abs(actual - expected) < 0.00001,
        (message or 'value') .. ': expected ' .. expected .. ', got ' .. tostring(actual))
end
local function noop() end
local cfg = dofile('luarules/configs/collateral.lua')
local D = {civilian=1,house_asian1=2,objective_airport=3,propagandaserver=4,
    protagonsafehouse=5,ground_tank_day=6,hivemind=7,transportedassembly=8}
-- Unique IDs without relying on dictionary iteration order.
for i, name in ipairs(cfg.militaryBuildings) do D[name] = 100 + i end

local function world()
    local w = {frame=0, units={}, money={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0},
        rules={}, messages={}, healthChanges={}, destroyed={}, failDebit={}, scans=0,
        gg={Propgandaservers={[2]=2}}, teams={4,0,2,3,1}, alliance={[0]=0,[1]=1,[2]=2,[3]=1,[4]=1}}
    local defs, byName = {}, {}
    for name, id in pairs(D) do defs[id]={name=name,id=id,health=1000};byName[name]={id=id} end
    local env = setmetatable({GG=w.gg,UnitDefs=defs,UnitDefNames=byName}, {__index=_G})
    env.Spring = {
        GetGaiaTeamID=function() return 0 end,
        GetGameFrame=function() return w.frame end,
        GetTeamList=function() local t={};for i,id in ipairs(w.teams) do t[i]=id end;return t end,
        AreTeamsAllied=function(a,b) return a==b or (w.alliance[a]~=nil and w.alliance[a]==w.alliance[b]) end,
        GetTeamResources=function(team,kind) assert(kind=='metal');return w.money[team] end,
        UseTeamResource=function(team,kind,amount)
            assert(kind=='metal' and amount>=0, 'only money may pay the fine')
            if w.failDebit[team] or w.money[team]+0.000001<amount then return false end
            w.money[team]=math.max(0,w.money[team]-amount);return true
        end,
        AddTeamResource=function(team,kind,amount)
            assert(kind=='metal' and amount>=0);w.money[team]=w.money[team]+amount
        end,
        GetTeamRulesParam=function(team,key) return w.rules[team] and w.rules[team][key] end,
        SetTeamRulesParam=function(team,key,value,visibility)
            assert(visibility.allied and not visibility.public)
            w.rules[team]=w.rules[team] or {};w.rules[team][key]=value
        end,
        GetAllUnits=function()
            w.scans=w.scans+1;local t={};for id,u in pairs(w.units) do if not u.dead then t[#t+1]=id end end;return t
        end,
        GetUnitTeam=function(id) local u=w.units[id];return u and not u.dead and u.team or nil end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return not w.units[id] or w.units[id].dead end,
        GetUnitHealth=function(id)
            local u=w.units[id];if u and not u.dead then return u.hp,u.maxhp,0,0,u.progress or 1 end
        end,
        GetUnitPosition=function(id) if w.units[id] then return id,0,id end end,
        SetUnitHealth=function(id,values)
            assert(values.health>0 and values.health<w.units[id].hp)
            w.healthChanges[#w.healthChanges+1]={id=id,loss=w.units[id].hp-values.health}
            w.units[id].hp=values.health
        end,
        DestroyUnit=function(id,selfDestruct,reclaimed)
            assert(not selfDestruct and not reclaimed)
            local u=w.units[id];assert(not u.dead);u.dead=true
            w.destroyed[#w.destroyed+1]=id
            w.gadget:UnitDestroyed(id,u.def,u.team) -- foreclosure has no attacker
        end,
    }
    env.VFS={Include=function(path)
        if path=='scripts/lib_UnitScript.lua' or path=='scripts/lib_mosaic.lua' then return end
        return loadEnv(path,env)
    end}
    env.gadgetHandler={IsSyncedCode=function() return true end}
    env.getGameConfig=function() return {instance={culture='western'},propandaServerFactor=0.1,
        costs={DestroyedHousePropanda=5000}} end
    env.getExemptFromRefundTypes=function() return {[D.objective_airport]=true} end
    env.getCultureUnitModelNames_Dict_DefIDName=function(culture)
        assert(culture=='international', 'arcologies in other cultures must count as houses')
        return {[D.house_asian1]='house_asian1'}
    end
    env.getChemTrailInfluencedTypes=function() return {} end
    env.getChemTrailTypes=function() return {} end
    env.infectWanderlostNearby=noop
    env.SendToUnsynced=function(...) w.messages[#w.messages+1]={...} end
    function w:reload()
        env.gadget={};loadEnv('luarules/gadgets/game_collateral.lua',env)
        env.spawnMilitiaInHousesNearby=noop -- unrelated militia placement
        self.gadget=env.gadget;self.gadget:Initialize()
    end
    function w:add(id,name,team,hp)
        self.units[id]={def=assert(D[name]),team=team,hp=hp or 1000,maxhp=hp or 1000}
        self.gadget:UnitCreated(id,D[name],team)
    end
    function w:damage(amount,attackerTeam,def,attackerID)
        self.gadget:UnitDamaged(10,def or D.civilian,0,amount,false,1,100,
            attackerID, D.ground_tank_day,attackerTeam or 1)
    end
    function w:tick()
        self.frame=self.frame+cfg.collectionIntervalFrames;self.gadget:GameFrame(self.frame)
    end
    function w:debt(team) return self.rules[team or 1].collateral_debt end
    w:reload()
    return w
end

-- Rich offender pays once; allied teams neither pay nor receive propaganda.
local w=world();w.money[1]=1000;w.money[3]=800
w:damage(300)
near(w.money[2],360,'immediate award');near(w.money[1],1000,'collection must be deferred')
w:tick();near(w.money[1],700);near(w.money[3],800);near(w:debt(),0)
w:damage(100,1,D.objective_airport);w:damage(100,0);w:damage(-10)
w:tick();near(w.money[2],360);near(w.money[1],700)

-- Partial funds are collected; allies share only the shortfall proportionally.
w=world();w.money[1]=25;w.money[3]=100;w.money[4]=300
w:add(50,'armybase',1,1000);w:damage(300);w:tick()
near(w.money[1],0);near(w.money[3],31.25);near(w.money[4],93.75)
near(w.units[50].hp,1000);near(w:debt(),0);near(w.money[2],360)

-- HP follows exhaustion of all friendly cash. Only the offender's military
-- buildings pay, in proportion to current health, including construction sites.
w=world();w.money[1]=10;w.money[3]=15;w.money[4]=5
w:add(50,'armybase',1,600);w:add(51,'antagonassembly',1,400);w.units[51].progress=.5
w:add(52,'armybase',3,1000);w:add(53,'armybase',2,1000)
for i,name in ipairs({'civilian','house_asian1','propagandaserver','protagonsafehouse','ground_tank_day','hivemind','transportedassembly'}) do
    w:add(60+i,name,1,1000)
end
w:damage(130);w:tick();near(w.units[50].hp,540);near(w.units[51].hp,360)
for id=52,53 do near(w.units[id].hp,1000) end
for id=61,67 do near(w.units[id].hp,1000) end
near(w:debt(),0);near(w.money[2],156)

-- House destruction never pays the attacker/allies, and uses each recipient's
-- propaganda multiplier. Attribution survives the bombing unit's destruction.
w=world();w.money[1]=10000;w.money[3]=10000
w.gadget:UnitDestroyed(10,D.house_asian1,0,999,D.ground_tank_day,1)
near(w.money[1],10000);near(w.money[3],10000);near(w.money[2],6000)
w:tick();near(w.money[1],5000);near(w.money[3],10000);near(w:debt(),0)

-- Every opponent gets its own propaganda award; the base fine is assessed once.
w=world();w.teams[#w.teams+1]=5;w.alliance[5]=5;w.money[5]=0
w.gg.Propgandaservers[5]=3;w.money[1]=20000;w:reload()
w.gadget:UnitDestroyed(10,D.house_asian1,0,nil,nil,1)
w:tick();near(w.money[2],6000);near(w.money[5],6500);near(w.money[1],15000)

-- Foreclosure can destroy buildings; the remainder survives ticks and reloads.
w=world();w:add(50,'armybase',1,100);w:add(51,'blacksite',1,200)
w.gadget:UnitDestroyed(10,D.house_asian1,0,nil,nil,1)
w:tick();assert(w.units[50].dead and w.units[51].dead)
near(w:debt(),4700);near(w.money[2],6000)
w:reload();near(w:debt(),4700);assert(w.gg.Propgandaservers[2]==2)
w:tick();near(w:debt(),4700);near(w.money[2],6000)
w.money[1]=200;w.money[4]=1000;w:add(52,'armybase',1,5000)
w:tick();near(w.units[52].hp,1500);near(w:debt(),0);near(w.money[2],6000)

-- A failed debit is not credited against the debt. Retry later without awards.
w=world();w.money[1]=100;w.failDebit[1]=true;w:damage(100);w:tick()
near(w.money[1],100);near(w:debt(),100);near(w.money[2],120)
w.failDebit[1]=nil;w:tick();near(w.money[1],0);near(w:debt(),0);near(w.money[2],120)

-- Capture/gifting and recycled IDs cannot make an enemy or a civilian pay HP.
w=world();w:add(50,'armybase',1,1000);w:add(51,'armybase',2,1000)
w:damage(300);w.units[50].team=2;w.gadget:UnitTaken(50,D.armybase,1,2)
w.units[51].team=1;w.gadget:UnitGiven(51,D.armybase,1,2)
w:tick();near(w.units[50].hp,1000);near(w.units[51].hp,700)
w.gadget:UnitDestroyed(51,D.armybase,1);w:add(51,'civilian',1,1000)
w:damage(100);w:tick();near(w.units[51].hp,1000);near(w:debt(),100)

-- Bank penalties (interrogations/checkpoints) also collect; awards never depend
-- on a surviving display unit or on whether the payer has money.
w=world();w:add(50,'nimrod',1,700)
w.gg.Bank:TransferToTeam(-500,1,nil);w.gg.Bank:TransferToTeam(500,2,nil)
w:tick();near(w.money[2],500);near(w.units[50].hp,200);near(w:debt(),0)

-- Bombing bursts use one queued debt per team, not repeated population scans.
w=world();w.money[1]=10000
for i=1,2000 do w:damage(1) end
w:tick();near(w.money[1],8000);near(w:debt(),0);assert(w.scans==1)
w:tick();assert(w.scans==1)
print('PASS: unconditional propaganda, house exclusion, partial/shared collection, military HP, debt persistence, attribution, transfers and bank fines')
