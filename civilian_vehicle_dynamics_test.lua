-- Production movement/ownership gadget with native-style event ordering.
local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a)..' ~= '..tostring(b)) end
local function callback(path,name,env)
    local f=assert(io.open(path));local source=f:read('*a');f:close()
    local code=assert(source:match('(function '..name..'%([^\n]*\n.-\nend)'))
    setmetatable(env,{__index=_G})
    if setfenv then setfenv(assert(loadstring(code)),env)() else assert(load(code,name,'t',env))() end
end
local config=dofile('luarules/configs/civilian_vehicle_dynamics.lua')
for _,profile in pairs(config.profiles) do
    local empty=config.Calculate(profile,0,1)
    near(empty.maxSpeed/(900*empty.accRate),profile.seconds)
    local loaded=config.Calculate(profile,12000,1)
    assert(loaded.maxSpeed<empty.maxSpeed and loaded.accRate<empty.accRate and loaded.decRate<empty.decRate)
    local slow=config.Calculate(profile,12000,0.25)
    near(slow.maxSpeed,loaded.maxSpeed/4);near(slow.accRate,loaded.accRate)
end
local definitions={'truck_arab6','truck_western3','truckpayload','truckpayloadservice',
    'truckpayloadparade','truckpayloadrefugee','civilianloot','stealvehicleicon','operativeasset',
    'truck_arab9','ground_truck_mg'}
UnitDefs,UnitDefNames={},{}
for id,name in ipairs(definitions) do UnitDefs[id]={id=id,name=name,speed=150};UnitDefNames[name]={id=id} end
local units,frame,scans,writes,transfers,destroyed,boarding={},{0},0,0,{},{},{}
local function add(id,def,team)
    units[id]={def=def,team=team or 0,rules={},cargo={},body='chosen-body-'..id,health=321,x=100,z=200}
    return units[id]
end
local car=add(10,1);local long=add(11,2)
local cargo=add(20,3);local service=add(21,4);local loot=add(22,7)
add(30,9,1);add(40,8,1);add(41,8,2);add(50,11)
local inCallback,deny=false,false
local trafficGadget
Spring={
    GetGaiaTeamID=function() return 0 end,
    ValidUnitID=function(id) return units[id]~=nil end,
    GetUnitIsDead=function(id) return not units[id] end,
    GetUnitDefID=function(id) return units[id] and units[id].def end,
    GetUnitTeam=function(id) return units[id] and units[id].team end,
    GetUnitRulesParam=function(id,key) return units[id].rules[key] end,
    SetUnitRulesParam=function(id,key,v) units[id].rules[key]=v end,
    GetUnitIsTransporting=function(id) return units[id].cargo end,
    GetUnitTransporter=function(id) return units[id] and units[id].parent end,
    GetAllUnits=function() scans=scans+1;local r={};for id in pairs(units) do r[#r+1]=id end;return r end,
    GetUnitSeparation=function(a,b) return math.abs(units[a].x-units[b].x) end,
    SetUnitAlwaysVisible=function(id,v) units[id].visible=v end,
    SetUnitNoSelect=function(id,v) units[id].noselect=v end,
    SetUnitNeutral=function(id,v) units[id].neutral=v end,
    GiveOrderToUnit=function(id,cmd) units[id].command=cmd end,
    MoveCtrl={SetGroundMoveTypeData=function(id,data) writes=writes+1;units[id].motion=data end},
    TransferUnit=function(id,team)
        assert(not inCallback,'Transfer recursively entered an ownership callback')
        if deny then return end
        local previous=units[id].team
        if trafficGadget then trafficGadget:UnitTaken(id,units[id].def,previous,team) end
        units[id].team=team
        transfers[#transfers+1]=id;inCallback=true
        gadget:UnitGiven(id,units[id].def,team,previous)
        if trafficGadget then trafficGadget:UnitGiven(id,units[id].def,team,previous) end
        inCallback=false
    end,
    DestroyUnit=function(id) destroyed[id]=true;gadget:UnitDestroyed(id);units[id]=nil end,
    UnitScript={GetScriptEnv=function(id)
        return {script={TransportPickup=function(passenger) boarding[#boarding+1]={id,passenger} end}}
    end,CallAsUnit=function(id,fn,...) assert(not inCallback);fn(...) end},
}
GG={CivilianLife={Interrupt=function() end}};CMD={STOP=0}
VFS={Include=dofile};gadgetHandler={IsSyncedCode=function() return true end}
gadget={};dofile('luarules/gadgets/game_civilian_vehicle_dynamics.lua');gadget:Initialize()
local api=GG.CivilianVehicles
local function tick() gadget:GameFrame() end
local function attach(child,parent)
    units[child].parent=parent;table.insert(units[parent].cargo,child)
    gadget:UnitLoaded(child,units[child].def,units[child].team,parent)
end
local function detach(child)
    local parent=units[child].parent;units[child].parent=nil
    for i,id in ipairs(units[parent].cargo) do if id==child then table.remove(units[parent].cargo,i);break end end
    gadget:UnitUnloaded(child,units[child].def,units[child].team,parent)
end
tick();near(car.motion.maxSpeed,75);assert(car.rules.vehicle_profile=='rigid')
api.SetLongBody(11,3);tick();assert(long.rules.vehicle_profile=='bus');near(long.motion.maxSpeed,81)
api.SetLongBody(11,5);tick();assert(long.rules.vehicle_profile=='limousine')
api.SetLongBody(11,1);tick();assert(long.rules.vehicle_profile=='articulated')
attach(20,10);api.SetPayload(20,'legacy',11);tick()
local loadedSpeed=car.motion.maxSpeed;assert(loadedSpeed<75)
near(car.motion.accRate,config.Calculate(config.profiles.rigid,12000,1).accRate)
api.ScaleSpeed(10,0.2);near(car.motion.maxSpeed,loadedSpeed/5)
api.SetPayload(20,'legacy',25);tick();near(car.motion.maxSpeed,15)
api.ScaleSpeed(10,1);near(car.motion.maxSpeed,75)
api.SetPayload(20,'legacy','FortNox');tick();assert(car.motion.maxSpeed<75)
detach(20);tick();near(car.motion.maxSpeed,75)
attach(21,10);api.SetPayload(21,'service','salvage_press');tick()
near(car.motion.accRate,config.Calculate(config.profiles.rigid,12000,1).accRate)
attach(22,21);tick()
near(car.motion.accRate,config.Calculate(config.profiles.rigid,13000,1).accRate)
detach(22);tick();near(car.motion.accRate,config.Calculate(config.profiles.rigid,12000,1).accRate)
local count=writes;for i=1,100 do tick() end
assert(writes==count and scans==1,'Idle frames must not scan units or rewrite movement')
-- Run the actual traffic ownership callbacks during native transfer, too.
local holds={[10]=true}
GG.CivilianTable={[10]={}};GG.UnitArrivedAtTarget={[10]=true}
local trafficEnv={gadget={},GG=GG,gaiaTeamID=0,trafficActivities={
    Remove=function(_,id) holds[id]=nil end,Register=function() end}}
callback('luarules/gadgets/game_civilians.lua','gadget:UnitTaken',trafficEnv)
callback('luarules/gadgets/game_civilians.lua','gadget:UnitGiven',trafficEnv)
trafficGadget=trafficEnv.gadget
-- Stealing retains native instances: selected body, cargo variant, health and attachments.
gadget:UnitCreated(40,8,1,30);api.ScaleSpeed(10,0.1)
assert(api.RequestHijack(10,40,60));assert(not api.RequestHijack(11,40,60))
assert(#transfers==0 and not destroyed[40],'Request is deferred')
tick();assert(units[10]==car and units[21]==service and service.parent==10)
assert(car.body=='chosen-body-10' and car.health==321 and service.rules.vehicle_cargo_mass==12000)
assert(not holds[10] and not GG.CivilianTable[10] and not GG.UnitArrivedAtTarget[10], 'Capture must cancel traffic holds/arrival queues')
assert(car.team==1 and service.team==1 and destroyed[40] and not destroyed[10] and not destroyed[21])
assert(not car.visible and not car.noselect and not service.visible and service.noselect)
near(car.motion.maxSpeed,config.Calculate(config.profiles.rigid,12000,1).maxSpeed)
assert(#boarding==0,'Boarding waits until after ownership processing')
tick();assert(#boarding==1 and boarding[1][1]==10 and boarding[1][2]==30)
assert(not api.RequestHijack(10,41,60),'Cannot steal an already owned car')
assert(not api.RequestHijack(50,41,60),'Military trucks excluded')
-- Ordinary capture also transfers existing attached visual cargo, without re-selection.
attach(20,11);api.SetPayload(20,'legacy',16);tick()
Spring.TransferUnit(11,2,false);assert(cargo.team==0)
tick();assert(cargo.team==2 and cargo.parent==11 and units[20]==cargo)
assert(long.rules.vehicle_profile=='articulated' and cargo.rules.vehicle_cargo_mass==12000)
-- Denied/out-of-range theft must retain the icon and original target.
Spring.TransferUnit(11,0,false);tick();deny=true
assert(api.RequestHijack(11,41,60));tick();assert(units[41] and long.team==0)
deny=false;long.x=1000;assert(api.RequestHijack(11,41,60));tick();assert(long.team==0 and units[41])
long.x=100
-- Rules restore selected body/cargo and current speed factor after gadget reload.
api.ScaleSpeed(11,0.4);local expected=long.motion.maxSpeed
gadget:Shutdown();gadget={};dofile('luarules/gadgets/game_civilian_vehicle_dynamics.lua');gadget:Initialize();tick()
near(long.motion.maxSpeed,expected);assert(long.rules.vehicle_profile=='articulated')

-- Actual long-body selection reports the chosen variant, never the piece ID.
for index=1,5 do
    local pieces={3,80,11,50,20}
    local env={unitID=11,GG=GG,TablesOfPiecesGroups={Truck=pieces,Wheel={},Cabin={}},
        LimoTruck=20,Show=function() end,Hide=function() end,Move=function() end,
        hideT=function() end,showT=function() end,
        showOne=function(group) return group==pieces and pieces[index] or nil end}
    callback('scripts/LongTruckscript.lua','showAndTell',env);env.showAndTell();tick()
    assert(long.rules.vehicle_profile==config.longBodies[index])
end
-- Legacy payload choice uses the actual displayed container, including empties.
local containerIndex=11
local env={unitID=20,GG=GG,TablesOfPiecesGroups={container={[11]=333,[25]=444}},
    busPieces={},showOnePiece=function(group) return group[containerIndex] end,
    getSetPayLoadDescription=function() return 'cargo' end,StartThread=function() end}
callback('scripts/truckPayloadScript.lua','selectPayloadPiece',env)
env.selectPayloadPiece();tick();assert(cargo.rules.vehicle_cargo_mass==12000)
containerIndex=25;env.selectPayloadPiece();tick();assert(cargo.rules.vehicle_cargo_mass==0)
-- Both speed wrappers use the selected profile instead of UnitDef.speed.
env={GG=GG,Spring=Spring,UnitDefs=UnitDefs}
callback('scripts/lib_UnitScript.lua','setSpeedEnv',env)
callback('scripts/lib_UnitScript.lua','setSpeedIntern',env)
env.setSpeedEnv(11,0.25);near(long.motion.maxSpeed,config.profiles.limousine.speed/4)
env.setSpeedIntern(11,1);near(long.motion.maxSpeed,config.profiles.limousine.speed)
-- Native boarding rejection must not hide the operative or disturb existing cargo.
local attached,selected,threads=false,false,0
env={unitID=10,script={},boolIsCivilianTruck=true,NotTruckLoadableUnitType={},
    Spring={GetUnitDefID=function() return 9 end,UnitAttach=function() end,
        GetUnitTransporter=function() return attached and 10 or nil end,
        SetUnitNoSelect=function() selected=true end},
    StartThread=function() threads=threads+1 end}
callback('scripts/Truckscript.lua','script.TransportPickup',env)
env.script.TransportPickup(30);assert(not selected and threads==0)
attached=true;env.script.TransportPickup(30);assert(selected and threads==1)
print('PASS: native acceleration units, cargo/variant changes, speed restoration, bounded updates, original-instance theft, capture, deferred boarding, denied transfer, reload')
