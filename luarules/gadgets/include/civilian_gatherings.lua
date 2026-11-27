local Calendar=VFS.Include("scripts/lib_city_calendar.lua")
local Intercepts=VFS.Include("scripts/lib_civilian_intercepts.lua")
local M={}
local function sorted(t)
    local ids={}; for id in pairs(t or {}) do ids[#ids+1]=id end
    table.sort(ids); return ids
end
local function count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
local function distance(a,b) return (a.x-b.x)^2+(a.z-b.z)^2 end

function M.New(c)
    local S,G,C=c.Spring,c.GG,c.config
    local api={events={},people={},cars={}}
    local gaia=S.GetGaiaTeamID()
    local cooldown,serial={},0
    local goodSince,badSince
    local lastDay=S.GetGameRulesParam("civilian_gathering_day") or 0
    local nextRecruit=0
    local function alive(id) return type(id)=="number" and S.ValidUnitID(id) and not S.GetUnitIsDead(id) end
    local function pos(id)
        if not alive(id) then return end
        local x,y,z=S.GetUnitPosition(id)
        if x then return {x=x,y=y,z=z} end
    end
    local function normal() return G.GlobalGameState==c.gameConfig.game.states.normal end
    local function call(id,name,...)
        local env=alive(id) and S.UnitScript.GetScriptEnv(id)
        if env and env[name] then return S.UnitScript.CallAsUnit(id,env[name],...) end
    end
    local function busy(id)
        local s=(G.CivilianUnitInternalLogicActive or {})[id]
        return (type(s)=="table" and s.state or s)==c.gameConfig.civilians.activityStates.started
    end
    local function ambient(id)
        return alive(id) and S.GetUnitTeam(id)==gaia and (G.CivilianTable or {})[id]
            and not (G.DisguiseCivilianFor or {})[id] and not S.GetUnitTransporter(id)
            and not (G.AerosolAffectedCivilians or {})[id]
            and not Intercepts.IsDetained(G,id) and not Intercepts.IsStunned(S,id)
            and not (G.HumanShield and G.HumanShield.IsHostage(id))
    end
    local function dangerous(p)
        return G.CityAreaState and G.CityAreaState:IsDangerous(p.x,p.z,C.dangerThreshold) or false
    end
    local function rule(id,value)
        if alive(id) then S.SetUnitRulesParam(id,"civilian_gathering",value,{public=true}) end
    end
    local function move(id,p) S.GiveOrderToUnit(id,CMD.MOVE,{p.x,p.y,p.z},{}) end
    local function point(def,x,z)
        if x<32 or z<32 or x>c.Game.mapSizeX-32 or z>c.Game.mapSizeZ-32 then return end
        local y=S.GetGroundHeight(x,z)
        if y<0 or not S.TestMoveOrder(def,x,y,z) then return end
        local p={x=x,y=y,z=z}
        if dangerous(p) or not c.clearance:SegmentClear(p,p) then return end
        return p
    end
    local function paradeBusy()
        if not G.CityParade then return false end
        local phase=G.CityParade:GetStatus()
        return phase~="idle"
    end
    function api:OwnsUnit(id) return self.people[id]~=nil or self.cars[id]~=nil end
    function api:HasEvents() return next(self.events)~=nil end
    function api:Status()
        return string.format("events=%d, participants=%d, cars=%d; %s",count(self.events),count(self.people),
            count(self.cars),self.reason or "ready")
    end
    local function release(id)
        local p=api.people[id]
        if p then
            local owned=call(id,"stopGathering",p.token,ambient(id))
            -- Never replace a command belonging to a newer activity.
            if owned and ambient(id) then S.GiveOrderToUnit(id,CMD.STOP,{},{}) end
            api.people[id]=nil; cooldown[id]=S.GetGameFrame()+C.cooldownFrames
        end
        api.cars[id]=nil; rule(id,0)
    end
    function api:Stop(reason,token)
        self.reason=reason
        for _,id in ipairs(sorted(self.people)) do
            if not token or self.people[id].token==token then release(id) end
        end
        for _,id in ipairs(sorted(self.cars)) do
            if not token or self.cars[id].token==token then
                if ambient(id) and not busy(id) then S.GiveOrderToUnit(id,CMD.STOP,{},{}) end
                release(id)
            end
        end
        for _,key in ipairs(sorted(self.events)) do if not token or key==token then self.events[key]=nil end end
    end
    local function departing(id,p,frame)
        if p.leaving then return end
        if not call(id,"stopGathering",p.token) then release(id); return end
        local event=api.events[p.token]
        if event and event.badWeather then
            release(id)
            if G.CivilianLife and G.CivilianLife.SeekShelter then G.CivilianLife:SeekShelter(id) end
            return
        end
        local here=pos(id)
        if not here or not point(S.GetUnitDefID(id),p.escape.x,p.escape.z) or
            not c.clearance:SegmentClear(here,p.escape) then release(id);return end
        p.leaving=frame+15*30
        -- Normal departures use the prevalidated outward escape lane.
        move(id,p.escape)
    end
    local function walkerCandidates(frame)
        local ids={}
        for _,id in ipairs(sorted(G.CivilianTable)) do
            if c.walkers[S.GetUnitDefID(id)] and ambient(id) and not busy(id) and not api:OwnsUnit(id)
                and not Intercepts.SocialEngineer(G,S,id)
                and frame>=(cooldown[id] or 0) and not (G.CityParade and G.CityParade:OwnsUnit(id)) then
                local p=pos(id)
                if p and not dangerous(p) then ids[#ids+1]=id end
            end
        end
        return ids
    end
    local function venue(kind,def,token)
        for _,id in ipairs(sorted(kind=="protest" and c.objectives() or G.BuildingTable)) do
            local p=pos(id)
            local profile=p and C.objectives[c.UnitDefs[S.GetUnitDefID(id)].name]
            if p and (kind~="protest" or profile) then
                local sx,_,sz=S.GetUnitCollisionVolumeData(id)
                local extent=math.sqrt((sx or 130)^2+(sz or 130)^2)*.5
                local fx,_,fz=S.GetUnitDirection(id)
                fx,fz=fx or 0,fz or 1
                if profile then fx,fz=fx*profile.side,fz*profile.side end
                local angles=kind=="protest" and {0} or {0,math.pi*.5,math.pi,math.pi*1.5}
                for _,angle in ipairs(angles) do
                    local dx,dz=fx*math.cos(angle)-fz*math.sin(angle),fx*math.sin(angle)+fz*math.cos(angle)
                    local offset=extent+C.profiles[kind].radius+(profile and profile.setback or 90)
                    local a=point(def,p.x+dx*offset,p.z+dz*offset)
                    local escape=a and point(def,a.x+dx*180,a.z+dz*180)
                    local separated=true
                    for _,e in pairs(api.events) do
                        if a and distance(a,e.center)<C.venueSeparation^2 then separated=false end
                    end
                    if a and escape and separated and c.clearance:SegmentClear(a,escape) then
                        local flat=true
                        for _,offsetPair in ipairs({{80,0},{-80,0},{0,80},{0,-80}}) do
                            if math.abs(S.GetGroundHeight(a.x+offsetPair[1],a.z+offsetPair[2])-a.y)>80*C.maxSlope then flat=false end
                        end
                        if kind~="yoga" or flat then return {center=a,escape=escape,objective=id,dx=dx,dz=dz} end
                    end
                end
            end
        end
    end
    function api:Start(kind,preview)
        local profile=C.profiles[kind]
        if not profile then return false,"unknown gathering" end
        if not normal() then return false,"peacetime only" end
        if paradeBusy() then return false,"parade has priority" end
        if count(self.events)>=2 then return false,"both gathering slots occupied" end
        local frame=S.GetGameFrame()
        local day,hour=Calendar.Clock(frame,c.gameConfig.game.dayLengthFrames)
        if not c.weather(frame,hour) then return false,"unsuitable outdoor weather or darkness" end
        if not preview and (not goodSince or frame-goodSince<C.clearFrames) then return false,"waiting for sustained clear weather" end
        c.clearance:Refresh(frame)
        local candidates=walkerCandidates(frame)
        if #candidates<profile.minimum then return false,"not enough available pedestrians" end
        if self:HasEvents() and (kind~="yoga" or #candidates<C.secondaryPopulation) then return false,"secondary activity needs a larger population" end
        serial=serial+1
        local e=venue(kind,S.GetUnitDefID(candidates[1]),serial)
        if not e then return false,"no accessible assembly area and escape lane" end
        e.kind,e.token,e.profile=kind,serial,profile
        e.start,e.nextThrow,e.recruited=frame,frame+C.escalation.intervalFrames,0
        e.finish=preview and frame+C.previewFrames or Calendar.AtHour(day,profile.endHour,c.gameConfig.game.dayLengthFrames)
        e.peak=preview and frame+C.previewFrames*.5 or Calendar.AtHour(day,profile.peakHour,c.gameConfig.game.dayLengthFrames)
        e.target=math.min(profile.maximum,#candidates)
        e.autoEscalate=kind=="protest" and not preview and math.random(1,100)<=C.escalation.chancePercent
        if kind=="convoy" then
            local cars={}
            for _,id in ipairs(sorted(G.CivilianTable)) do
                if c.cars[S.GetUnitDefID(id)] and ambient(id) and not busy(id) and not self:OwnsUnit(id)
                    and #(S.GetUnitIsTransporting(id) or {})==0 then cars[#cars+1]=id end
            end
            if #cars<C.convoy.minimum then return false,"not enough empty ordinary cars" end
            e.carCandidates=cars
            e.route=c.routes:Begin(day,S.GetUnitDefID(cars[1]),false)
            if not e.route then return false,"no validated road circuit available" end
            e.route.vehicleCount=math.min(C.convoy.maximum,#cars)
        end
        self.events[serial]=e; self.reason=kind.." assembling"
        return true,serial
    end
    local function recruit(e,frame)
        local span=math.max(1,e.peak-e.start)
        local cap=math.min(e.target,2+math.floor((e.target-2)*math.min(1,(frame-e.start)/span)))
        if e.recruited>=cap or frame>e.peak or e.dispersing then return end
        if e.kind=="convoy" and not e.depart then return end
        local added=0
        for _,id in ipairs(walkerCandidates(frame)) do
            if added>=2 or e.recruited>=cap then break end
            local p=pos(id)
            if distance(p,e.center)<=C.recruitRadius^2 then
                local index=e.recruited+1
                local role=e.profile.roles[(index-1)%#e.profile.roles+1]
                if e.kind=="wedding" and index>2 and role=="couple" then role="guest" end
                if e.kind=="yoga" and index>1 then role="yoga" end
                local angle=index*2.3999632297287
                local radius=25+math.sqrt(index/e.target)*e.profile.radius
                local x,z=e.center.x+math.cos(angle)*radius,e.center.z+math.sin(angle)*radius
                if e.kind=="wedding" then
                    if index<=2 then x,z=e.center.x+(index*2-3)*14,e.center.z
                    else local a=math.pi*(index-3)/math.max(1,e.target-3)
                        x,z=e.center.x+math.cos(a)*radius,e.center.z+math.sin(a)*radius end
                elseif e.kind=="yoga" then
                    if index==1 then x,z=e.center.x,e.center.z-100
                    else x,z=e.center.x+((index-2)%4-1.5)*48,e.center.z+math.floor((index-2)/4)*48-40 end
                end
                local dest=point(S.GetUnitDefID(id),x,z)
                if dest and c.clearance:SegmentClear(dest,e.escape) then
                    local def=c.UnitDefs[S.GetUnitDefID(id)]
                    local path=def.moveDef and S.RequestPath(def.moveDef.id,p.x,p.y,p.z,dest.x,dest.y,dest.z,24)
                    if path then
                        local accepted=call(id,"startGathering",e.token,e.kind,role)
                        if accepted then
                            api.people[id]={token=e.token,role=accepted,path=path,dest=dest,escape=e.escape,
                                deadline=frame+C.arrivalFrames,index=index,
                                leaveAt=e.peak+(e.finish-e.peak)*(.45+.55*(id%17)/16)}
                            e.recruited=index; added=added+1; rule(id,e.token)
                        end
                    end
                end
            end
        end
    end
    local function updatePerson(id,p,frame)
        local e=api.events[p.token]
        local here=pos(id)
        if not e or not ambient(id) or not here or dangerous(here) then release(id); return end
        if p.leaving then
            if busy(id) or frame>=p.leaving or distance(here,p.escape)<45^2 then release(id) end
            return
        end
        if not call(id,"isGatheringActive",p.token) then release(id); return end
        if not p.arrived and frame>=p.deadline then release(id);return end
        if (e.dispersing and frame>=e.dispersing+p.index*C.releaseFrames) or frame>=p.leaveAt then
            departing(id,p,frame); return
        end
        if not p.arrived then
            if p.path then
                local points=p.path:GetPathWayPoints()
                if points and #points>0 then
                    local last=points[#points]
                    if (last[1]-p.dest.x)^2+(last[3]-p.dest.z)^2>64^2 then release(id); return end
                    p.waypoints={}
                    local previous=here
                    for _,v in ipairs(points) do
                        local nextPoint=point(S.GetUnitDefID(id),v[1],v[3])
                        if not nextPoint or not c.clearance:SegmentClear(previous,nextPoint) then release(id);return end
                        p.waypoints[#p.waypoints+1]=nextPoint; previous=nextPoint
                    end
                    if not c.clearance:SegmentClear(previous,p.dest) then release(id);return end
                    p.waypoints[#p.waypoints+1]=p.dest
                    p.path=nil;p.waypoint=1
                    move(id,p.waypoints[1])
                end
            elseif distance(here,p.dest)<40^2 then
                S.GiveOrderToUnit(id,CMD.STOP,{},{})
                p.arrived=call(id,"arriveGathering",p.token)
                if S.SetUnitDirection then
                    local focus=e.center
                    if e.kind=="protest" and p.role~="speaker" and p.role~="organizer" then focus=pos(e.objective) or focus
                    elseif e.kind=="yoga" and p.role~="instructor" then focus={x=e.center.x,z=e.center.z-100} end
                    local dx,dz=focus.x-here.x,focus.z-here.z
                    local length=math.sqrt(dx*dx+dz*dz)
                    if length>1 then S.SetUnitDirection(id,dx/length,0,dz/length) end
                end
            elseif p.waypoints then
                local target=p.waypoints[p.waypoint]
                if target and distance(here,target)<35^2 then
                    p.waypoint=p.waypoint+1;target=p.waypoints[p.waypoint]
                    if target then move(id,target) end
                elseif target and not c.clearance:SegmentClear(here,target) then release(id) end
            end
        end
    end
    local function updateConvoy(e,frame)
        if e.route.status~="ready" then
            local status=c.routes:Poll(e.route)
            if status=="invalid" then api:Stop("convoy route blocked",e.token); return end
            if status~="ready" then return end
            e.depart=frame
            -- Spectators stand beside the actual circuit, outside car lanes.
            local a,b=e.route.points[1],e.route.points[2]
            local dx,dz=b.x-a.x,b.z-a.z
            local length=math.max(1,math.sqrt(dx*dx+dz*dz))
            local walker=walkerCandidates(frame)[1]
            local center=walker and point(S.GetUnitDefID(walker),a.x-dz/length*180,a.z+dx/length*180)
            local escape=center and point(S.GetUnitDefID(walker),a.x-dz/length*350,a.z+dx/length*350)
            if not center or not escape or not c.clearance:SegmentClear(center,escape) then
                api:Stop("convoy has no safe spectator curb",e.token);return
            end
            for token,other in pairs(api.events) do
                if token~=e.token and distance(center,other.center)<C.venueSeparation^2 then
                    api:Stop("convoy spectator curb already reserved",e.token);return
                end
            end
            e.center,e.escape=center,escape
            for i=1,math.min(C.convoy.maximum,#e.carCandidates) do
                local id=e.carCandidates[i]
                if ambient(id) and not busy(id) and not api:OwnsUnit(id) then
                    api.cars[id]={token=e.token,index=i,point=1,depart=frame+(i-1)*C.convoy.departureFrames,
                        deadline=frame+C.convoy.timeoutFrames,horn=frame+i*30}
                    rule(id,e.token); S.GiveOrderToUnit(id,CMD.STOP,{},{})
                end
            end
            if count(api.cars)<C.convoy.minimum then api:Stop("convoy cars became unavailable",e.token); return end
        end
        local previous
        for _,id in ipairs(sorted(api.cars)) do
            local car=api.cars[id]
            if car.token==e.token then
                local here=pos(id)
                if not here or not ambient(id) or busy(id) or dangerous(here) or frame>=car.deadline or e.dispersing then release(id)
                elseif frame>=car.depart then
                    local target=e.route.points[car.point]
                    if not target then release(id)
                    else
                        if distance(here,target)<C.convoy.goalRadius^2 then car.point=car.point+1; car.ordered=nil
                        elseif previous and distance(here,previous)<C.convoy.spacing^2 then
                            if car.ordered then S.GiveOrderToUnit(id,CMD.STOP,{},{});car.ordered=nil end
                        elseif car.ordered~=car.point then
                            if not c.clearance:SegmentClear(here,target) then release(id)
                            else move(id,target);car.ordered=car.point end
                        end
                        if frame>=car.horn then
                            S.PlaySoundFile("sounds/car/honk"..(id%7+1)..".ogg",.45,here.x,here.y,here.z)
                            car.horn=frame+C.convoy.hornFrames+id%90
                        end
                        previous=here
                    end
                end
            end
        end
    end
    function api:Escalate()
        if not normal() then return false end
        local changed=false
        for _,e in pairs(self.events) do
            if e.kind=="protest" and not e.dispersing then e.escalated=true;changed=true end
        end
        return changed
    end
    function api:ReleaseStone(id,token,target,variant)
        local p,e=self.people[id],self.events[token]
        if not normal() or not p or p.token~=token or not p.throwPending or not e or not e.escalated or e.dispersing
            or not ambient(id) or not call(id,"isGatheringActive",token) then return false end
        p.throwPending=nil
        if not alive(target) or target~=e.objective then return false end
        return c.stones:Throw(id,target,variant,C.escalation)
    end
    function api:UnitDamaged(id,damage)
        if not damage or damage<=0 then return end
        local p=self.people[id] or self.cars[id]
        if p then self:Stop("gathering interrupted by injury",p.token) end
    end
    function api:UnitDestroyed(id)
        release(id)
        cooldown[id]=nil
        for _,token in ipairs(sorted(self.events)) do
            if self.events[token].objective==id then self:Stop("venue destroyed",token) end
        end
    end
    function api:Recover()
        for _,id in ipairs(S.GetAllUnits()) do
            if (S.GetUnitRulesParam(id,"civilian_gathering") or 0)>0 then
                if call(id,"stopGathering") then S.GiveOrderToUnit(id,CMD.STOP,{},{}) end
                rule(id,0)
                -- A full synced reload may also rebuild civilian traffic. Put
                -- surviving ambient participants back on an ordinary trip.
                local traffic=G.CivilianTraffic
                if alive(id) and S.GetUnitTeam(id)==gaia and not busy(id) and not S.GetUnitTransporter(id)
                    and traffic and not (G.CivilianTable or {})[id] then
                    local graph=traffic.GetRoutes()
                    local here,best,goal,bestDistance=pos(id)
                    for _,node in ipairs(sorted(graph)) do
                        local origin=pos(node)
                        if origin and type(graph[node])=="table" then
                            for _,target in ipairs(graph[node]) do
                                if target~=node and alive(target) then
                                    local d=distance(here,origin)
                                    if not bestDistance or d<bestDistance then best,goal,bestDistance=node,target,d end
                                    break
                                end
                            end
                        end
                    end
                    if best then
                        G.CivilianTable=G.CivilianTable or {}
                        G.CivilianTable[id]={defID=S.GetUnitDefID(id),startID=best,goalID=goal}
                        if not traffic.BeginTravel(id) then G.CivilianTable[id]=nil end
                    end
                end
            end
        end
    end
    function api:Frame(frame)
        if frame%C.tickFrames~=0 then return end
        if not normal() then self:Stop("peacetime ended");goodSince=nil;return end
        c.clearance:Refresh(frame)
        local day,hour=Calendar.Clock(frame,c.gameConfig.game.dayLengthFrames)
        local good=c.weather(frame,hour)
        if good then goodSince=goodSince or frame;badSince=nil else badSince=badSince or frame;goodSince=nil end
        if paradeBusy() then self:Stop("parade has priority");return end
        for _,token in ipairs(sorted(self.events)) do
            local e=self.events[token]
            if not alive(e.objective) or dangerous(e.center) then self:Stop("venue unsafe",token)
            else
                if badSince and frame-badSince>=C.badWeatherFrames then e.badWeather=true end
                if frame>=e.finish or e.badWeather then e.dispersing=e.dispersing or frame end
                if e.kind=="convoy" then updateConvoy(e,frame) end
                if self.events[token] and good and frame>=nextRecruit then recruit(e,frame) end
                if e.autoEscalate and frame>=e.peak then e.escalated=true end
                if e.escalated and not e.dispersing and frame>=e.nextThrow then
                    local present=0
                    for _,p in pairs(self.people) do
                        if p.token==token and p.arrived and not p.leaving then present=present+1 end
                    end
                    local maximum=math.floor(present*C.escalation.fraction)
                    local throwers=0
                    for _,id in ipairs(sorted(self.people)) do
                        local p=self.people[id]
                        if p.token==token and p.arrived and not p.leaving and p.role=="chanter" and throwers<maximum then
                            if call(id,"throwGatheringStone",token,e.objective) then p.throwPending=true;throwers=throwers+1 end
                        end
                    end
                    e.nextThrow=frame+C.escalation.intervalFrames
                end
                if e.dispersing and frame>e.dispersing+(e.target+1)*C.releaseFrames+15*30 then self:Stop("gathering finished",token) end
            end
        end
        for _,id in ipairs(sorted(self.people)) do updatePerson(id,self.people[id],frame) end
        if frame>=nextRecruit then nextRecruit=frame+C.recruitFrames end
        if not self:HasEvents() and day>lastDay and Calendar.Weekday(day)==C.weekday and hour>=9 and hour<12 and good then
            local kind=C.mainKinds[(math.floor((day-1)/7))%#C.mainKinds+1]
            local ok,reason
            if hour>=C.profiles[kind].startHour then ok,reason=self:Start(kind,false) end
            if not ok and reason then self.reason=reason end
            if ok then
                lastDay=day;S.SetGameRulesParam("civilian_gathering_day",day)
                if hour<C.profiles.yoga.endHour then self:Start("yoga",false) end
            end
        end
    end
    return api
end
return M
