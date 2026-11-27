-- Destination dwell and bounded junction holds. The engine owns braking and
-- paths. This controller issues no movement orders: the existing travel loop
-- issues exactly the next leg when Step releases an arrival.
local defaults=VFS.Include("luarules/configs/civilian_traffic.lua")
local geometry=VFS.Include("luarules/gadgets/include/civilian_traffic_routes.lua")
return function(context)
    local S,G=Spring,GG
    local config=context.config or defaults
    local gaia=S.GetGaiaTeamID()
    local records,holds,crossings,gates,gateNext={},{},{},{},{}
    local vehicleCount,parkedCount,nextDeparture=0,0,0
    local network,junctions=nil,{}
    local service={}
    local public={inlos=true}
    local function alive(id)
        return type(id)=="number" and S.ValidUnitID(id) and not S.GetUnitIsDead(id)
    end
    local function publish(id,state,untilFrame)
        if not alive(id) then return end
        S.SetUnitRulesParam(id,"traffic_activity",state,public)
        S.SetUnitRulesParam(id,"traffic_activity_until",untilFrame or 0,public)
    end
    local function radius(id) return S.GetUnitRadius(id) or 32 end
    local function releaseHold(id)
        local h=holds[id]
        if h and not h.junction then parkedCount=parkedCount-1 end
        holds[id]=nil
        if h then publish(id,"driving",0) end
    end
    function service:Register(id,defID)
        if not context.types[defID] or records[id] then return end
        records[id]={trip=0};vehicleCount=vehicleCount+1
    end
    function service:Cancel(id,avoidUntil)
        releaseHold(id)
        local crossing=crossings[id]
        if crossing then
            if gates[crossing.junction.id]==id then gates[crossing.junction.id]=nil end
            crossings[id]=nil
        end
        local r=records[id]
        if r then
            if r.queuedGoal then r.queuedGoal=nil;publish(id,"driving",0) end
            r.avoidUntil=math.max(r.avoidUntil or 0,avoidUntil or 0)
        end
    end
    function service:Remove(id)
        self:Cancel(id)
        if records[id] then records[id]=nil;vehicleCount=vehicleCount-1 end
    end
    function service:IsHolding(id) return holds[id]~=nil end
    function service:PrepareRoute(id,route)
        self:Register(id,S.GetUnitDefID(id))
        self:Cancel(id)
        local r=records[id]
        if not r then return route end
        r.trip=r.trip+1;r.seenGoal=nil
        if G.CityRoadNetworkFrozen and G.CityRoadNetwork~=network then
            network=G.CityRoadNetwork
            junctions=network and geometry.junctions(network,config) or {}
        end
        return geometry.decorate(route,junctions,config,radius(id),function(p)
            return p.y>=0 and S.TestMoveOrder(S.GetUnitDefID(id),p.x,p.y,p.z)
        end,S.GetGroundHeight)
    end
    local function externallyOwned(id,pack,frame)
        local state=(G.CivilianUnitInternalLogicActive or {})[id]
        state=type(state)=="table" and state.state or state
        return not alive(id) or S.GetUnitTeam(id)~=gaia or S.GetUnitTransporter(id)
            or (G.CityParade and G.CityParade:OwnsUnit(id))
            or (G.CivilianGatherings and G.CivilianGatherings:OwnsUnit(id))
            or (G.DisguiseCivilianFor or {})[id] or (G.AerosolAffectedCivilians or {})[id]
            or state==context.gameConfig.civilians.activityStates.started
            or G.GlobalGameState~=context.gameConfig.game.states.normal
            or pack.boolRefugee or pack.boolTraumatized
            or frame<(records[id].avoidUntil or 0)
    end
    local function clearAt(id,x,z,range)
        for _,other in ipairs(S.GetUnitsInCylinder(x,z,range) or {}) do
            if other~=id and alive(other) and not S.GetUnitTransporter(other) then
                local def=UnitDefs[S.GetUnitDefID(other)]
                -- Buildings and unrelated mobile units also occupy an exit.
                if def and (def.isImmobile or def.canMove or context.types[def.id or S.GetUnitDefID(other)]) then
                    return false
                end
            end
        end
        return true
    end
    local function profile(id)
        local kind=S.GetUnitRulesParam(id,"vehicle_profile")
        if not config.profiles[kind] then
            local defID=S.GetUnitDefID(id)
            if context.motorcycles[defID] then kind="motorcycle"
            elseif context.freight[defID] then kind="rigid"
            else kind="car" end
        end
        return config.profiles[kind]
    end
    local function parkingAvailable(id,goal)
        local limit=math.min(config.maxParked,math.max(1,math.floor(vehicleCount*config.maxParkedFraction)))
        if parkedCount>=limit then return false end
        local clearance=config.parkingClearance+radius(id)
        for other,h in pairs(holds) do
            if not h.junction then
                local dx,dz=goal.x-h.goal.x,goal.z-h.goal.z
                if dx*dx+dz*dz<(clearance+radius(other))^2 then return false end
            end
        end
        return clearAt(id,goal.x,goal.z,clearance)
    end
    local function eligibleDestination(id,goal,frame)
        return goal.trafficDestination and alive(goal.trafficDestination)
            and not (G.CityAreaState and G.CityAreaState:IsDangerous(goal.x,goal.z))
    end
    local function newHold(id,pack,goal,frame)
        local r=records[id]
        if r.seenGoal==goal then return end
        r.seenGoal=goal
        local j=goal.trafficJunction
        local p,seed,duration
        if not j then
            if not eligibleDestination(id,goal,frame) then return end
            p=profile(id)
            seed=geometry.hash(id..":"..r.trip..":"..pack.goalIndex)
            if seed%100>=p.chance or not parkingAvailable(id,goal) then return end
            local low,high=p.min,p.max
            if p.freight then
                low=context.gameConfig.civilians.traffic.truckBreakMinSeconds*30
                high=context.gameConfig.civilians.traffic.truckBreakMaxSeconds*30
            end
            duration=low+math.floor(seed/100)%(high-low+1)
        end
        local h={goal=goal,route=pack.goalList,index=pack.goalIndex,junction=j,
            profile=p,duration=duration,phase="approaching",started=frame,
            pack=pack}
        holds[id]=h
        if not j then parkedCount=parkedCount+1 end
        publish(id,"approaching",0)
        return h
    end
    local function crossingClear(id,h,frame)
        local j=h.junction
        if gates[j.id] or frame<(gateNext[j.id] or 0) then return false end
        -- Oldest arrived vehicle wins, independent of EventStream order.
        for other,waiting in pairs(holds) do
            if other~=id and waiting.junction and waiting.junction.id==j.id and waiting.phase~="approaching"
                and (waiting.arrived<h.arrived or (waiting.arrived==h.arrived and other<id)) then return false end
        end
        local exit=h.goal.trafficExit
        return clearAt(id,j.x,j.z,config.junctionRadius+radius(id))
            and clearAt(id,exit.x,exit.z,config.exitClearance+radius(id))
    end
    local function waitingBehindHold(id,goal,x,z)
        if not goal.trafficJunction then return false end
        local exit=goal.trafficExit
        local dx,dz=exit.x-goal.x,exit.z-goal.z
        local length=math.sqrt(dx*dx+dz*dz);dx,dz=dx/length,dz/length
        local behind=(goal.x-x)*dx+(goal.z-z)*dz
        local across=math.abs((goal.x-x)*dz-(goal.z-z)*dx)
        if behind<=0 or behind>config.queueDistance or across>radius(id)+32 then return false end
        if gates[goal.trafficJunction.id] then return true end
        for other,h in pairs(holds) do
            if other~=id and h.junction and h.junction.id==goal.trafficJunction.id then
                local ox,_,oz=S.GetUnitPosition(other)
                if ox then
                    local ahead=(ox-x)*dx+(oz-z)*dz
                    local lateral=math.abs((ox-x)*dz-(oz-z)*dx)
                    if ahead>0 and lateral<radius(id)+radius(other)+16 then return true end
                end
            end
        end
        return false
    end
    function service:Step(id,pack,frame)
        local r=records[id]
        if not r then return false end
        if externallyOwned(id,pack,frame) then self:Cancel(id);return false end
        local goal=pack.goalList and pack.goalList[pack.goalIndex]
        local h=holds[id]
        if h and (h.route~=pack.goalList or h.index~=pack.goalIndex) then self:Cancel(id);h=nil end
        if not goal then return false end
        local x,_,z=S.GetUnitPosition(id)
        if not x then self:Remove(id);return false end
        if G.CityAreaState and G.CityAreaState:IsDangerous(x,z) then
            self:Cancel(id,frame+30*30);return false
        end
        local dx,dz=x-goal.x,z-goal.z
        local distanceSq=dx*dx+dz*dz
        if not h and distanceSq>=config.arrivalRadius^2 and waitingBehindHold(id,goal,x,z) then
            if r.queuedGoal~=goal then r.queuedGoal=goal;publish(id,"queued",0) end
            pack.stuckCounter=0;pack.currPos={x=x,y=S.GetGroundHeight(x,z),z=z}
            return true,frame+config.pollFrames
        end
        if r.queuedGoal then r.queuedGoal=nil;publish(id,"driving",0) end
        if not h and distanceSq<config.arrivalRadius^2 then h=newHold(id,pack,goal,frame) end
        if not h then return false end
        if not h.junction and not eligibleDestination(id,goal,frame) then self:Cancel(id);return false end
        local command=S.GetUnitCurrentCommand(id)
        local vx,vy,vz=S.GetUnitVelocity(id)
        local stopped=vx and vx*vx+vy*vy+vz*vz<=config.stoppedSpeed^2
        if h.phase=="approaching" then
            -- Do not stop/reissue a still-active move. Let its native goal
            -- completion and braking determine when the activity can begin.
            if frame-h.started>config.approachTimeout or distanceSq>(config.arrivalRadius*2)^2 then
                self:Cancel(id);return false
            end
            if command~=nil and command~=CMD.MOVE then self:Cancel(id);return false end
            if command==nil and stopped and distanceSq<config.arrivalRadius^2 then
                h.arrived=frame
                h.untilFrame=frame+(h.junction and config.junctionStopFrames or h.duration)
                h.phase=h.junction and "intersection" or h.profile.activity
                publish(id,h.phase,h.untilFrame)
            end
        else
            -- A new order, displacement, or external movement relinquishes
            -- this activity; never erase another system's command queue.
            if command~=nil or not stopped or distanceSq>(config.arrivalRadius*2)^2 then
                self:Cancel(id);return false
            end
            if h.profile and h.profile.freight and h.phase=="unloading"
                and frame>=h.arrived+math.floor(h.duration/2) then
                h.phase="loading";publish(id,h.phase,h.untilFrame)
            end
            if frame>=h.untilFrame and frame>=nextDeparture
                and (not h.junction or crossingClear(id,h,frame)) then
                nextDeparture=frame+config.departureSpacing
                if h.junction then
                    local exit=h.goal.trafficExit
                    local ex,ez=exit.x-goal.x,exit.z-goal.z
                    local length=math.sqrt(ex*ex+ez*ez)
                    crossings[id]={junction=h.junction,dx=ex/length,dz=ez/length,started=frame}
                    gates[h.junction.id]=id
                    gateNext[h.junction.id]=frame+config.junctionHeadway
                end
                releaseHold(id)
                pack.stuckCounter=0;pack.currPos={x=x,y=S.GetGroundHeight(x,z),z=z}
                return false
            end
        end
        pack.stuckCounter=0;pack.currPos={x=x,y=S.GetGroundHeight(x,z),z=z}
        return true,frame+config.pollFrames
    end
    function service:Frame(frame)
        if frame%config.pollFrames~=0 then return end
        -- Only active reservations need housekeeping. Native lifecycle
        -- callbacks maintain the vehicle census without scanning moving cars.
        local ids={}
        for id in pairs(holds) do ids[#ids+1]=id end
        for id in pairs(crossings) do if not holds[id] then ids[#ids+1]=id end end
        table.sort(ids)
        for _,id in ipairs(ids) do
            if not alive(id) or S.GetUnitTeam(id)~=gaia then self:Remove(id)
            else
                local h=holds[id]
                if h and externallyOwned(id,h.pack,frame) then self:Cancel(id) end
                local c=crossings[id]
                if c then
                    local x,_,z=S.GetUnitPosition(id)
                    local j=c.junction
                    if (x-j.x)*c.dx+(z-j.z)*c.dz>config.junctionRadius+radius(id)
                        or (frame-c.started>config.crossingTimeout and clearAt(id,j.x,j.z,config.junctionRadius)) then
                        if gates[j.id]==id then gates[j.id]=nil end
                        crossings[id]=nil
                    end
                end
            end
        end
    end
    function service:Shutdown()
        local ids={};for id in pairs(records) do ids[#ids+1]=id end
        for _,id in ipairs(ids) do self:Remove(id) end
    end
    return service
end
