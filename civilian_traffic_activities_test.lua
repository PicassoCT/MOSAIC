-- Real traffic controller and road geometry; engine commands/physics are spies.
local function loadEnv(path,env)
    local f=assert(loadfile(path))
    if setfenv then setfenv(f,env);return f() end
    return assert(loadfile(path,"t",env))()
end
local function copy(t)
    local out={};for k,v in pairs(t) do out[k]=type(v)=="table" and copy(v) or v end;return out
end
local function world()
    local w={frame=0,units={},writes=0}
    local env=setmetatable({CMD={MOVE=10},GG={GlobalGameState="normal",
        CivilianUnitInternalLogicActive={}},UnitDefs={
        [1]={id=1,name="car",canMove=true},[2]={id=2,name="truck",canMove=true},
        [3]={id=3,name="house",isImmobile=true},[4]={id=4,name="bike",canMove=true}}},{__index=_G})
    w.env=env;w.units[900]={x=9000,z=9000,def=3,team=0}
    env.Spring={
        GetGaiaTeamID=function() return 0 end,
        ValidUnitID=function(id) return w.units[id]~=nil end,
        GetUnitIsDead=function(id) return not w.units[id] end,
        GetUnitTeam=function(id) return w.units[id] and w.units[id].team end,
        GetUnitDefID=function(id) return w.units[id] and w.units[id].def end,
        GetUnitTransporter=function(id) return w.units[id] and w.units[id].transporter end,
        GetUnitPosition=function(id) local u=w.units[id];if u then return u.x,0,u.z end end,
        GetUnitRadius=function() return 32 end,
        GetUnitRulesParam=function(id,key) return (w.units[id].params or {})[key] end,
        SetUnitRulesParam=function(id,key,value)
            local u=assert(w.units[id]);u.params=u.params or {};u.params[key]=value;w.writes=w.writes+1
        end,
        GetGroundHeight=function() return 0 end,TestMoveOrder=function() return true end,
        GetUnitCurrentCommand=function(id) return w.units[id].command end,
        GetUnitVelocity=function(id) return w.units[id].speed or 0,0,0 end,
        GetUnitsInCylinder=function(x,z,r)
            local ids={};for id,u in pairs(w.units) do
                if (u.x-x)^2+(u.z-z)^2<=r*r then ids[#ids+1]=id end
            end;table.sort(ids);return ids
        end,
        GiveOrderToUnit=function() error("dwell controller issued an order") end,
        MoveCtrl={SetGroundMoveTypeData=function() error("dwell controller changed physics") end},
    }
    env.VFS={Include=function(path) return loadEnv(path,env) end}
    w.config=copy(dofile("luarules/configs/civilian_traffic.lua"))
    for _,p in pairs(w.config.profiles) do p.chance=100;p.min=90;p.max=90 end
    w.config.maxParkedFraction=1
    w.service=env.VFS.Include("luarules/gadgets/include/civilian_traffic_activities.lua")({config=w.config,
        types={[1]=true,[2]=true,[4]=true},freight={[2]=true},motorcycles={[4]=true},
        gameConfig={game={states={normal="normal"}},civilians={activityStates={started=1},
            traffic={truckBreakMinSeconds=4,truckBreakMaxSeconds=4}}}})
    function w:add(id,x,z,profile,def)
        self.units[id]={x=x,z=z,team=0,def=def or 1,params={vehicle_profile=profile or "car"}}
        self.service:Register(id,def or 1)
        local goal={x=x,y=0,z=z,trafficDestination=900}
        local route=self.service:PrepareRoute(id,{{x=x-500,y=0,z=z},goal})
        return {goalIndex=2,goalList=route,stuckCounter=12}
    end
    function w:step(id,pack,frame) self.frame=frame;return self.service:Step(id,pack,frame) end
    function w:state(id) return self.units[id].params.traffic_activity end
    return w
end

local w=world();local p=w:add(1,1000,1000)
w.units[1].command=10;w.units[1].speed=2
assert(w:step(1,p,0) and w:state(1)=="approaching" and p.stuckCounter==0)
w.units[1].command=nil
assert(w:step(1,p,15) and w:state(1)=="approaching","braking must finish before parking")
w.units[1].speed=0
assert(w:step(1,p,30) and w:state(1)=="parked")
assert(w.units[1].params.traffic_activity_until==120)
local writes=w.writes
for f=45,105,15 do assert(w:step(1,p,f) and p.stuckCounter==0) end
assert(w.writes==writes,"holding must not spam state writes")
assert(not w:step(1,p,120) and w:state(1)=="driving")
assert(not w:step(1,p,135),"same waypoint must not park twice")

w=world();p=w:add(1,1000,1000,"articulated",2)
assert(w:step(1,p,0) and w:state(1)=="unloading")
assert(w:step(1,p,60) and w:state(1)=="loading")
assert(not w:step(1,p,120))
-- Actual selected long-body class wins over the truck definition.
w=world();p=w:add(1,1000,1000,"bus",2)
assert(w:step(1,p,0) and w:state(1)=="parked")
assert(w.units[1].params.traffic_activity_until==90)
w=world();p=w:add(1,1000,1000,"unknown",4)
assert(w:step(1,p,0) and w:state(1)=="parked")

-- Capacity, reservations and participation are separate controls.
w=world();w.config.maxParked=1
p=w:add(1,1000,1000);local q=w:add(2,2000,2000)
assert(w:step(1,p,0));assert(not w:step(2,q,0))
w.service:Remove(1);assert(not w:step(2,q,15),"capacity is not rerolled every poll")
w=world();w.config.profiles.car.chance=0;p=w:add(1,1000,1000)
assert(not w:step(1,p,0))
w=world();p=w:add(1,1000,1000);q=w:add(2,1100,1000)
assert(not w:step(1,p,0),"occupied curb must not be reserved")
w=world();p=w:add(1,1000,1000);q=w:add(2,2000,2000)
assert(w:step(1,p,0) and w:step(2,q,0))
assert(not w:step(1,p,90) and w:step(2,q,90),"departures must be staggered")
assert(not w:step(2,q,105))

for _,reason in ipairs({"capture","parade","panic","transport","danger","demolition","new_order","displacement","route"}) do
    w=world();p=w:add(1,1000,1000);assert(w:step(1,p,0))
    if reason=="capture" then w.units[1].team=1
    elseif reason=="parade" then w.env.GG.CityParade={OwnsUnit=function() return true end}
    elseif reason=="panic" then w.env.GG.CivilianUnitInternalLogicActive[1]={state=1}
    elseif reason=="transport" then w.units[1].transporter=999
    elseif reason=="danger" then w.env.GG.CityAreaState={IsDangerous=function() return true end}
    elseif reason=="demolition" then w.units[900]=nil
    elseif reason=="new_order" then w.units[1].command=10
    elseif reason=="displacement" then w.units[1].x=1500
    elseif reason=="route" then p.goalIndex=1 end
    assert(not w:step(1,p,15) and not w.service:IsHolding(1),"failed cancellation: "..reason)
end
w=world();p=w:add(1,1000,1000);w.units[1].command=10
assert(w:step(1,p,0));assert(not w:step(1,p,w.config.approachTimeout+1),"blocked approaches need ordinary recovery")
w=world();p=w:add(1,1000,1000);assert(w:step(1,p,0));w.units[1]=nil
w.service:Frame(15);assert(not w.service:IsHolding(1))

local geometry=dofile("luarules/gadgets/include/civilian_traffic_routes.lua")
local cfg=dofile("luarules/configs/civilian_traffic.lua")
local network={roads={
    {points={{0,1000},{2000,1000}}}, {points={{1000,0},{1000,2000}}},
}}
local junctions=geometry.junctions(network,cfg)
assert(#junctions==1 and #junctions[1].arms==4)
local route={{x=0,y=0,z=1000},{x=2000,y=0,z=1000,trafficDestination=900}}
local decorated=geometry.decorate(route,junctions,cfg,32,function() return true end,function() return 0 end)
assert(#decorated==4 and decorated[2].trafficJunction==junctions[1] and decorated[2].x<1000)
assert(decorated[3].x>1000 and decorated[4]==route[2],"destination identity was lost")
assert(#geometry.decorate(route,junctions,cfg,32,function() return false end,function() return 0 end)==2)
assert(#geometry.junctions({roads={{points={{0,0},{1000,0},{1000,1000}}}}},cfg)==0,"bend is not a junction")
assert(#geometry.junctions({roads={{points={{0,1000},{2000,1000}}},{points={{1000,0},{1000,1000}}}}},cfg)==1,"T-junction missing")
-- Reverse directions use opposite lanes, so an approaching car does not
-- occupy the outgoing lane and permanently block its opposite number.
local reverse=geometry.decorate({route[2],route[1]},junctions,cfg,32,function() return true end,function() return 0 end)
assert(decorated[2].z<1000 and reverse[2].z>1000)

w=world();p=w:add(1,decorated[2].x,decorated[2].z)
q=w:add(2,reverse[2].x,reverse[2].z)
p.goalList=decorated;q.goalList=reverse
assert(w:step(1,p,0) and w:step(2,q,0))
local follower=w:add(3,decorated[2].x-180,decorated[2].z)
follower.goalList=decorated;follower.stuckCounter=13;w.units[3].command=10
assert(w:step(3,follower,15) and follower.stuckCounter==0 and w:state(3)=="queued",
    "a legitimate junction queue must not trigger destructive stuck recovery")
w.service:Remove(3);w.units[3]=nil
assert(w:step(2,q,60),"FIFO must not depend on callback order")
assert(not w:step(1,p,60),"opposite queue must leave outgoing lane clear")
assert(w:step(2,q,75),"junction remains reserved while first car crosses")
w.units[1].x,w.units[1].z=1000,936
w.service:Frame(90);assert(w:step(2,q,90))
w.units[1].x,w.units[1].z=1500,936
w.service:Frame(120);assert(not w:step(2,q,120),"junction release failed after crossing cleared")
-- Do not release into a blocked exit even after the dwell timer expires.
w=world();p=w:add(1,decorated[2].x,decorated[2].z)
-- Use fresh geometry to avoid a previous fixture's nextRelease timestamp.
decorated=geometry.decorate(route,geometry.junctions(network,cfg),cfg,32,function() return true end,function() return 0 end)
p.goalList=decorated;assert(w:step(1,p,0))
w.units[9]={x=decorated[3].x,z=decorated[3].z,team=1,def=1}
assert(w:step(1,p,1000),"blocked exit must retain hold")
w.units[9]=nil;assert(not w:step(1,p,1015))

-- Exercise the real parent travel loop: dwelling must bypass destructive stuck
-- recovery, then advance once without reissuing the completed leg.
w=world();p=w:add(1,1000,1000)
p.unitID=1;p.myTeam=0;p.goalList[3]={x=2000,y=0,z=1000}
p.currPos={x=1000,y=0,z=1000};p.stuckCounter=13
local e=w.env
e.GG.CivilianTable={[1]={defID=1,startID=900}}
p.trafficRegistration=e.GG.CivilianTable[1]
e.trafficActivities=w.service
e.gaiaTeamID=0;e.spGetUnitTeam=e.Spring.GetUnitTeam
e.isCivilianPassenger=function() return false end;e.isHostageWitness=function() return false end
e.GameConfig={game={states={normal="normal"}},civilians={movement={minProgressDistance=10}}}
e.civilianLife={Step=function() return false end,Arrive=function() return false end}
e.travelInitialization=function(_,_,pack)
    local x,y,z=e.Spring.GetUnitPosition(pack.unitID);return false,nil,pack,x,y,z,100
end
e.unitInternalLogic=function(_,_,pack) return false,nil,pack end
e.snychronizedSocialEvents=e.unitInternalLogic;e.sozialize=e.unitInternalLogic
e.distance=function(x,y,z,a,b,c) return math.sqrt((x-a)^2+(y-b)^2+(z-c)^2) end
e.distanceUnitToPoint=function(id,x,y,z)
    local a,b,c=e.Spring.GetUnitPosition(id);return e.distance(a,b,c,x,y,z)
end
e.spDestroyUnit=function() error("intentional stop reached destructive stuck recovery") end
local orders={}
e.Command=function(id,kind,target)
    assert(kind=="go");orders[#orders+1]={id=id,target=target}
end
e.GG.UnitArrivedAtTarget={}
local f=assert(io.open("luarules/gadgets/game_civilians.lua"));local source=f:read("*a");f:close()
local function section(first,last)
    local a=assert(source:find(first,1,true));local b=assert(source:find(last,a+#first,true))
    return source:sub(a,b-1)
end
local code=section("local metaStuckDetection =", "CivilianInternalDebugStateStartTabel =")
    ..section("function packStep(","function getTargetNodeInWalkingDistance(")
if setfenv then setfenv(assert(loadstring(code)),e)() else assert(load(code,"travel integration","t",e))() end
for frame=0,75,15 do
    local due=e.travellFunction(1,frame,p,0)
    assert(due==frame+15 and #orders==0 and p.goalIndex==2 and p.stuckCounter==0)
end
e.travellFunction(1,90,p,0)
assert(#orders==1 and orders[1].target.x==2000 and p.goalIndex==3,
    "departure must issue exactly the next leg, never the completed goal")
print("PASS: native braking, dwell phases, profiles, budgets, cancellation, road stops, opposing lanes, FIFO and exit clearance")
