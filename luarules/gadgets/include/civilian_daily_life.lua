-- Synced civilian routines. Records survive route changes; observers never drive
-- simulation choices. Only ambient Gaia pedestrians receive automatic orders.
local config = VFS.Include("luarules/configs/civilian_daily_life.lua")
local dialogue = VFS.Include("scripts/lib_civilian_dialogue.lua")
VFS.Include("luarules/configs/commandsIDs.lua")
local BLEND=CMD_CIVILIAN_BLEND
return function(context)
    local S, G = Spring, GG
    local C = context.gameConfig
    local people, groups, venues, vehicles, sessions = {}, {}, {}, {}, {}
    local guardedUntil, busVehicles = {}, {}
    local nextVehicleEvent = 0
    local life = {people = people}
    local gaia = S.GetGaiaTeamID()
    local function sorted(t)
        local keys = {}; for id in pairs(t or {}) do keys[#keys + 1] = id end
        table.sort(keys); return keys
    end
    -- Recoil C callins require actual numeric unit IDs; numeric strings are not safe.
    local function alive(id)
        return type(id) == "number" and S.ValidUnitID(id) and not S.GetUnitIsDead(id)
    end
    local function ambient(id)
        return alive(id) and G.CivilianTable[id] and context.walkers[S.GetUnitDefID(id)]
            and S.GetUnitTeam(id) == gaia and not (G.DisguiseCivilianFor or {})[id]
            and not S.GetUnitTransporter(id) and not (G.AerosolAffectedCivilians or {})[id]
    end
    local function hash(text)
        local n = 17
        for i = 1, #text do n = (n * 131 + text:byte(i)) % 2147483647 end
        return n
    end
    local function draw(p, low, high)
        p.seed = (p.seed * 48271) % 2147483647
        return low + p.seed % (high - low + 1)
    end
    local function call(id, name, ...)
        local env = alive(id) and S.UnitScript.GetScriptEnv(id)
        if env and env[name] then return S.UnitScript.CallAsUnit(id, env[name], ...) end
    end
    local function distance(x, z, a, b) return (x-a)*(x-a) + (z-b)*(z-b) end
    local function position(id)
        if not alive(id) then return nil end
        local x, _, z = S.GetUnitPosition(id)
        return x, z
    end
    local function move(id, x, z)
        S.GiveOrderToUnit(id, CMD.MOVE, {x, S.GetGroundHeight(x,z), z}, {})
    end
    local function normal() return G.GlobalGameState == C.game.states.normal end
    local function busy(id)
        local state = (G.CivilianUnitInternalLogicActive or {})[id]
        return type(state) == "table" and state.state == C.civilians.activityStates.started
    end
    local function speaking(id)
        local state=(G.CivilianUnitInternalLogicActive or {})[id]
        return type(state)=="table" and state.state==C.civilians.activityStates.started and
            (state.behaviour=="talk" or state.behaviour=="phone")
    end
    local function location(x, z)
        -- Only public place names; no attacker identity or hidden unit metadata.
        local best, bestD
        for _, id in ipairs(sorted(venues)) do
            if alive(id) then
                local vx,vz = position(id)
                local d = vx and distance(x,z,vx,vz)
                if d and (not bestD or d < bestD) then best,bestD=id,d end
            end
        end
        local street = best and S.GetUnitRulesParam(best,"city_street_name")
        if street and bestD < 900*900 then return "on "..tostring(street) end
        return "near the " .. (x < Game.mapSizeX/2 and "west" or "east") ..
            (z < Game.mapSizeZ/2 and " end of the north side" or " end of the south side")
    end
    local function record(id)
        local p = people[id]
        if not p then
            local seed = hash(Game.mapName..":"..id..":"..S.GetGameFrame())
            p = {seed=seed, memories={}, trip=0, cautious=seed%3, social=math.floor(seed/3)%3,
                curious=math.floor(seed/9)%3, lastEvent={}, bag="none"}
            p.nextPhone = S.GetGameFrame() + draw(p,config.phoneMin,config.phoneMax)
            people[id] = p
        end
        return p
    end
    function life:Remember(id, kind, x, z, detail)
        if not alive(id) then return end
        local p, frame = record(id), S.GetGameFrame()
        if frame - (p.lastEvent[kind] or -100000) < 20*30 then return end
        p.lastEvent[kind] = frame
        p.memories[#p.memories+1] = {kind=kind, frame=frame,
            place=x and location(x,z) or "round the corner", vehicle=detail}
        if #p.memories > config.memoryLimit then table.remove(p.memories,1) end
    end
    local function latestMemory(p, frame)
        for i=#p.memories,1,-1 do
            local m = p.memories[i]
            if frame-m.frame <= config.memoryLifetime and m ~= p.lastTold then
                return m
            end
        end
    end
    function life:Conversation(a, b, duration)
        if not alive(a) or (b and not alive(b)) or sessions[a] or (b and sessions[b]) then return end
        local frame, p = S.GetGameFrame(), record(a)
        local memory = latestMemory(p,frame)
        if not memory and not p.conspiracyThread and b then
            local otherPerson = record(b)
            local other = latestMemory(otherPerson,frame)
            if other or otherPerson.conspiracyThread then a,b,p,memory=b,a,otherPerson,other end
        end
        -- Alternate mundane news with an unfinished argument. Fresh distress
        -- always takes precedence, but never deletes the argument it interrupts.
        local urgent = memory and (memory.kind=="gunfire" or memory.kind=="injured" or
            memory.kind=="home_lost" or memory.kind=="companion_lost")
        if p.conspiracyThread and p.lastConversationWasMemory and not urgent then memory=nil end
        local seed = hash(a..":"..tostring(b or 0)..":"..frame)
        local thread = not memory and p.conspiracyThread
        local lines, kind
        if thread then lines=thread.lines else
            lines,kind=dialogue.build(seed,memory,{conspiracyChance=p.conspiracyThread and 0 or config.conspiracyChance,
                listenerSeed=b and hash(Game.mapName..":"..b) or hash(Game.mapName..":"..a..":phone")})
            if kind=="conspiracy" then
                thread={lines=lines,next=1}; p.conspiracyThread=thread
            end
        end
        if memory then p.lastTold=memory end
        p.lastConversationWasMemory=memory~=nil
        local session = {a=a,b=b,lines=lines,index=thread and thread.next or 1,thread=thread,
            untilFrame=frame+duration,nextFrame=frame,phone=not b}
        if thread and thread.next>1 and thread.lastClaim then
            -- Re-establish the claim even when the listener changed, or an
            -- interruption left us halfway through a claim/reply pair.
            session.recap="About what I was saying: "..thread.lastClaim
        end
        session.lineFrames=math.min(config.lineFrames,math.max(90,math.floor(duration/4)))
        p.nextChat=frame+duration+draw(p,25,65)*30+(2-p.social)*15*30
        if b then record(b).nextChat=p.nextChat end
        sessions[a]=session; if b then sessions[b]=session end
    end
    local function closeSession(s)
        -- The cursor advances only after a line is emitted. An unfinished thread
        -- stays on its living speaker across animation expiry, danger and calls.
        local p=people[s.a]
        if p and s.thread and s.thread.next>#s.thread.lines and p.conspiracyThread==s.thread then
            p.conspiracyThread=nil
        end
        if sessions[s.a] == s then sessions[s.a]=nil end
        if s.b and sessions[s.b] == s then sessions[s.b]=nil end
    end
    function life:RegisterVenue(id, kind)
        if alive(id) then venues[id]=kind end
    end
    function life:UnitCreated(id, defID)
        local def = UnitDefs[defID]
        if not def then return end
        local cp, name = def.customParams or {}, def.name or ""
        local kind = cp.civilian_venue
        if not kind then
            if name:find("airport",1,true) or name:find("hotel",1,true) then kind="luggage"
            elseif name:find("market",1,true) then kind="shopping" end
        end
        if kind then venues[id]=kind end
        if context.trucks[defID] then vehicles[id]={lastMove=S.GetGameFrame(),cooldown=0} end
    end
    function life:Register(id, home)
        local p=record(id); p.home=home or p.home
    end
    local function removeFromGroup(id)
        local p=people[id]; if not p or not p.group then return end
        local group=groups[p.group]; p.group=nil; p.guardLeader=nil
        if not group then return end
        for i=#group.members,1,-1 do if group.members[i]==id then table.remove(group.members,i) end end
        if #group.members==0 then groups[group.id]=nil
        elseif group.leader==id then group.leader=group.members[1] end
    end
    function life:Interrupt(id)
        local p=people[id]; if not p then return end
        p.visit=nil; p.board=nil; p.waitUntil=nil; p.guardingVisit=nil
        if sessions[id] then closeSession(sessions[id]) end
        call(id,"externalInterruptCivilian")
    end
    function life:UnitDestroyed(id, attackerID)
        local p=people[id]
        if p and p.group and attackerID and not (G.DiedPeacefully or {})[id] then
            local group=groups[p.group]
            if group then for _,other in ipairs(group.members) do
                if other~=id then self:Remember(other,"companion_lost") end
            end end
        end
        if sessions[id] then closeSession(sessions[id]) end
        removeFromGroup(id)
        for _,other in ipairs(sorted(people)) do
            if people[other].home==id then
                self:Remember(other,"home_lost"); people[other].home=nil
            end
            if people[other].work==id then people[other].work=nil end
        end
        people[id],venues[id],vehicles[id],guardedUntil[id]=nil,nil,nil,nil
    end
    local function unsafe(x,z,frame,person)
        if person then
            local memory=person.avoid
            if memory and frame<memory.untilFrame and distance(x,z,memory.x,memory.z)<config.dangerRadius^2 then return true end
        end
        return G.CityAreaState and G.CityAreaState:IsDangerous(x,z) or false
    end
    local function approach(id, destination, salt)
        local x,z=position(destination); if not x then return end
        local radius=math.max(90, math.min(S.GetUnitRadius(destination) or 128,420))
        local defID=S.GetUnitDefID(id)
        local best,bestCost
        for i=0,7 do
            local angle=((salt+i)%8)*math.pi/4
            local px,pz=x+math.cos(angle)*radius,z+math.sin(angle)*radius
            if px>16 and pz>16 and px<Game.mapSizeX-16 and pz<Game.mapSizeZ-16 then
                local py=S.GetGroundHeight(px,pz)
                if py>=0 and S.TestMoveOrder(defID,px,py,pz) then
                    local nearby=S.GetUnitsInCylinder(px,pz,80) or {}
                    local cost=#nearby*100+i+(unsafe(px,pz,S.GetGameFrame(),people[id]) and 10000 or 0)
                    if not bestCost or cost<bestCost then best,bestCost={x=px,y=py,z=pz,venue=destination},cost end
                end
            end
        end
        return best
    end
    function life:SelectTarget(id, start, candidates)
        if not alive(id) then return nil end
        local sx,sz=position(id)
        if not sx then return nil end
        local p=record(id)
        p.home=alive(p.home) and p.home or (alive(start) and start or nil)
        p.trip=p.trip+1
        local targets, nearbyTargets={},{}
        -- Route tables may outlive buildings, and old saves can contain
        -- nonnumeric IDs. Do not pass those values into Spring callins.
        for _,candidate in ipairs(type(candidates)=="table" and candidates or {}) do
            if alive(candidate) and candidate~=p.home then
                local tx,tz=position(candidate)
                if tx then
                    targets[#targets+1]=candidate
                    if distance(sx,sz,tx,tz)<C.civilians.movement.maxWalkingDistance^2 then
                        nearbyTargets[#nearbyTargets+1]=candidate
                    end
                end
            end
        end
        if #nearbyTargets>0 then targets=nearbyTargets end
        table.sort(targets)
        if #targets==0 then return nil end

        -- A remembered workplace may be gone or no longer reachable
        -- from this node. Keep it only while it remains an eligible target.
        local workAvailable=false
        for _,candidate in ipairs(targets) do
            if candidate==p.work then workAvailable=true; break end
        end
        if not workAvailable then p.work=targets[draw(p,1,#targets)] end
        local target=p.work
        if p.trip%3==0 then target=targets[draw(p,1,#targets)] end

        -- Occasional purposeful visits to actual registered venues.
        if draw(p,1,100)<=30 then
            local nearby={}
            for _,venue in ipairs(sorted(venues)) do
                if alive(venue) then
                    local vx,vz=position(venue)
                    if vx and distance(sx,sz,vx,vz)<config.venueRadius^2 then
                        nearby[#nearby+1]=venue
                    end
                end
            end
            if #nearby>0 then target=nearby[draw(p,1,#nearby)] end
        end
        local tx,tz=position(target)
        if not tx then
            target=targets[draw(p,1,#targets)]
            tx,tz=position(target)
        end
        if tx and unsafe(tx,tz,S.GetGameFrame(),p) then
            self:Remember(id,"detour",tx,tz)
            for _,candidate in ipairs(targets) do
                local cx,cz=position(candidate)
                if cx and not unsafe(cx,cz,S.GetGameFrame(),p) then
                    target=candidate; break
                end
            end
        end
        return target
    end
    function life:BuildRoute(id, start, destination)
        if not alive(id) or not alive(destination) then return nil end
        local x,z=position(id)
        if not x then return nil end
        local p=record(id)
        local target=approach(id,destination,id)
        local home=alive(p.home) and approach(id,p.home,id+2)
        if not target then return end
        target.kind=venues[destination] or "errand"
        local route={{x=x,y=S.GetGroundHeight(x,z),z=z},target}
        if home then home.kind="home"; route[#route+1]=home end
        return route
    end
    local function setBag(id,kind)
        local p=record(id)
        if call(id,"externalSetCivilianBags",kind)==true then p.bag=kind; return true end
        return false
    end
    function life:FinishVisit(id, visit)
        local p=record(id)
        local changed=false
        if visit.kind=="home" then
            if p.bag~="none" then self:Remember(id,"returned_home") end
            changed=setBag(id,"none")
        elseif visit.kind=="luggage" then
            changed=setBag(id,"luggage")
            if changed then self:Remember(id,"luggage",visit.x,visit.z) end
        elseif visit.kind=="shopping" or (visit.kind=="errand" and draw(p,1,100)<=55) then
            changed=setBag(id,"shopping")
            if changed then self:Remember(id,"shopping",visit.x,visit.z) end
        end
        visit.completed=true
        if changed and p.group then
            local group=groups[p.group]
            if group and group.leader==id then
                for _,member in ipairs(group.members) do
                    if member~=id and ambient(member) then
                        local mx,mz=position(member)
                        if mx and distance(mx,mz,visit.x,visit.z)<300^2 then
                            if setBag(member,p.bag) and p.bag~="none" then self:Remember(member,p.bag,visit.x,visit.z) end
                        end
                    end
                end
            end
        end
    end
    function life:Arrive(id, goal, frame)
        if not goal.kind or not ambient(id) then return false end
        local p=record(id)
        if p.finishedGoal==goal then p.finishedGoal=nil; return false end
        local duration=draw(p,config.visitMin,config.visitMax)
        if goal.kind=="brothel" then
            duration=draw(p,config.lingerMin,config.lingerMax)
            self:Remember(id,"brothel",goal.x,goal.z)
        end
        p.visit={goal=goal,kind=goal.kind,x=goal.x,z=goal.z,untilFrame=frame+duration,
            nextShift=frame+draw(p,7*30,14*30)}
        S.GiveOrderToUnit(id,CMD.STOP,{},{})
        local group=p.group and groups[p.group]
        if group and group.leader==id and frame>=(p.nextChat or 0) then
            for _,member in ipairs(group.members) do
                if member~=id and ambient(member) and not busy(member) then
                    local mx,mz=position(member)
                    if distance(mx,mz,goal.x,goal.z)<C.civilians.conversation.range^2 then
                        local talkFrames=math.max(15*30,math.min(duration,25*30))
                        S.GiveOrderToUnit(member,CMD.STOP,{},{})
                        if call(id,"startChatting",talkFrames*1000/30,member) and
                            call(member,"startChatting",talkFrames*1000/30,id) then
                            self:Conversation(id,member,talkFrames)
                        end
                        break
                    end
                end
            end
        end
        return true
    end
    function life:ReportDanger(id, damage)
        local x,z=position(id); if not x then return end
        local frame=S.GetGameFrame()
        -- Damage is recorded once by City Area State. This event supplies only
        -- individual memories/flee reactions, never another spatial danger map.
        local nearby=S.GetUnitsInCylinder(x,z,config.dangerRadius) or {}; table.sort(nearby)
        for _,person in ipairs(nearby) do
            if context.walkers[S.GetUnitDefID(person)] then
                self:Remember(person,person==id and "injured" or "gunfire",x,z)
                local p=record(person)
                p.avoid={x=x,z=z,untilFrame=frame+config.dangerMemory}
                if ambient(person) then
                    if not p.fear or frame>p.fear.moveAfter+90 then
                        self:Interrupt(person)
                        local px,pz=position(person)
                        local delay=distance(px,pz,x,z)<180^2 and 0 or draw(p,0,15)+p.curious*5
                        p.fear={x=x,z=z,moveAfter=frame+delay,
                            untilFrame=frame+draw(p,config.refugeMin,config.refugeMax)+p.cautious*90}
                    else p.fear.untilFrame=math.max(p.fear.untilFrame,frame+config.refugeMin) end
                end
            end
        end
    end
    local function tryGroup(id,p,frame)
        if p.group or p.triedGroup then return end
        p.triedGroup=true
        if draw(p,1,100)>config.groupChance+p.social*5 then return end
        local x,z=position(id); local near=S.GetUnitsInCylinder(x,z,config.groupRadius,gaia) or {}
        table.sort(near)
        local members={id}; local desired=draw(p,2,config.groupMax)
        for _,other in ipairs(near) do
            if other~=id and ambient(other) and not busy(other) then
                local op=record(other)
                if not op.group and not op.fear and not op.visit and not op.board then
                    members[#members+1]=other
                    if #members==desired then break end
                end
            end
        end
        if #members<2 then return end
        local group={id=id,leader=id,members=members}; groups[id]=group
        for _,member in ipairs(members) do record(member).group=id end
    end
    function life:Step(id, pack, frame)
        if vehicles[id] then return self:VehiclePause(id,pack,frame) end
        if not ambient(id) then return false end
        local p=record(id); local x,z=position(id)
        if not normal() then
            p.fear,p.visit,p.board,p.waitUntil=nil,nil,nil,nil
            return false
        end
        if p.fear then
            local fear=p.fear
            if frame>=fear.untilFrame then
                local goal=pack.goalList[pack.goalIndex]
                if goal and unsafe(goal.x,goal.z,frame,p) then
                    local home=alive(p.home) and approach(id,p.home,id)
                    if home and not unsafe(home.x,home.z,frame,p) then
                        home.kind="home"; pack.goalList={home}; pack.goalIndex=1; goal=home
                        self:Remember(id,"detour",fear.x,fear.z)
                    else fear.untilFrame=frame+6*30; pack.stuckCounter=0; return true end
                end
                p.fear=nil; p.guardLeader=nil
                if goal then move(id,goal.x,goal.z) end
                return true
            end
            if frame>=fear.moveAfter and not fear.moved then
                local dx,dz=x-fear.x,z-fear.z; local length=math.sqrt(dx*dx+dz*dz)
                if length<1 then dx,dz,length=1,0,1 end
                local tx=math.max(24,math.min(Game.mapSizeX-24,x+dx/length*500))
                local tz=math.max(24,math.min(Game.mapSizeZ-24,z+dz/length*500))
                -- Prefer a nearby building approach away from the impact.
                local best,bestD
                for _,venue in ipairs(sorted(venues)) do
                    local vx,vz=position(venue)
                    if vx and distance(x,z,vx,vz)<700^2 and distance(vx,vz,fear.x,fear.z)>distance(x,z,fear.x,fear.z) then
                        local d=distance(tx,tz,vx,vz)
                        if not bestD or d<bestD then best,bestD=venue,d end
                    end
                end
                local cover=best and approach(id,best,id)
                if cover then tx,tz=cover.x,cover.z end
                local def=S.GetUnitDefID(id)
                if S.GetGroundHeight(tx,tz)>=0 and S.TestMoveOrder(def,tx,S.GetGroundHeight(tx,tz),tz) then
                    move(id,tx,tz)
                else
                    -- A blocked escape direction is not a reason to walk into water.
                    for i=0,7 do
                        local angle=(id+i)%8*math.pi/4
                        local ax,az=x+math.cos(angle)*250,z+math.sin(angle)*250
                        if ax>16 and az>16 and ax<Game.mapSizeX-16 and az<Game.mapSizeZ-16 and
                            distance(ax,az,fear.x,fear.z)>distance(x,z,fear.x,fear.z) and
                            S.GetGroundHeight(ax,az)>=0 and S.TestMoveOrder(def,ax,S.GetGroundHeight(ax,az),az) then
                            move(id,ax,az); break
                        end
                    end
                end
                fear.moved=true
            end
            pack.stuckCounter=0; return true
        end
        if not normal() or busy(id) then return false end
        if p.board then
            local vehicle=p.board.vehicle; local state=vehicles[vehicle]
            if not alive(vehicle) or S.GetUnitTeam(vehicle)~=gaia or not state or frame-state.lastMove<config.vehicleStoppedFrames or frame>p.board.untilFrame then
                p.board=nil
                local goal=pack.goalList[pack.goalIndex]; if goal then move(id,goal.x,goal.z) end
                return true
            end
            local vx,vz=position(vehicle)
            if distance(x,z,vx,vz)<config.vehicleDoorDistance^2 then
                removeFromGroup(id)
                G.DiedPeacefully[id]=true
                S.DestroyUnit(id,false,true)
            end
            pack.stuckCounter=0; return true
        end
        if p.visit then
            local visit=p.visit
            if frame>=visit.untilFrame or not alive(visit.goal.venue) then
                if alive(visit.goal.venue) then self:FinishVisit(id,visit) end
                p.finishedGoal=visit.goal; p.visit=nil
                if pack.goalList[pack.goalIndex]~=visit.goal then
                    local goal=pack.goalList[pack.goalIndex]; if goal then move(id,goal.x,goal.z) end
                end
            elseif visit.kind=="brothel" and frame>=visit.nextShift then
                visit.nextShift=frame+draw(p,8*30,15*30)
                move(id,visit.x+draw(p,-30,30),visit.z+draw(p,-30,30))
            end
            pack.stuckCounter=0; return true
        end
        tryGroup(id,p,frame)
        local group=p.group and groups[p.group]
        if group and group.leader~=id then
            if not ambient(group.leader) then removeFromGroup(id); return false end
            local lx,lz=position(group.leader)
            if distance(x,z,lx,lz)>config.groupBreakDistance^2 then
                p.lostSince=p.lostSince or frame
                if frame-p.lostSince>45*30 then removeFromGroup(id); return false end
            else p.lostSince=nil end
            local command=(S.GetUnitCommands(id,1) or {})[1]
            if p.guardLeader~=group.leader or not command or command.id~=CMD.GUARD or command.params[1]~=group.leader then
                S.GiveOrderToUnit(id,CMD.GUARD,{group.leader},{})
                p.guardLeader=group.leader
            end
            pack.stuckCounter=0; return true
        elseif group then
            if p.waitUntil then
                if frame<p.waitUntil then pack.stuckCounter=0; return true end
                p.waitUntil=nil; p.nextWait=frame+15*30
                local goal=pack.goalList[pack.goalIndex]; if goal then move(id,goal.x,goal.z) end
            elseif frame>=(p.nextWait or 0) then
                for _,member in ipairs(group.members) do
                    if member~=id and ambient(member) then
                        local mx,mz=position(member)
                        if distance(x,z,mx,mz)>config.groupWaitDistance^2 then
                            S.GiveOrderToUnit(id,CMD.STOP,{},{}); p.waitUntil=frame+4*30
                            pack.stuckCounter=0; return true
                        end
                    end
                end
            end
        end
        -- Passers-by can linger without making every trip a brothel visit.
        if frame>=(p.nextLinger or 0) then
            p.nextLinger=frame+60*30
            for _,venue in ipairs(sorted(venues)) do
                if venues[venue]=="brothel" and alive(venue) then
                    local vx,vz=position(venue)
                    if distance(x,z,vx,vz)<300^2 and draw(p,1,100)<=config.lingerChance then
                        self:Arrive(id,{x=x,z=z,venue=venue,kind="brothel"},frame); return true
                    end
                end
            end
        end
        if frame>=(p.nextShelter or 0) then
            p.nextShelter=frame+20*30
            if context.raining() and draw(p,1,100)<25+p.cautious*20 then
                local closest,bestD
                for _,venue in ipairs(sorted(venues)) do
                    if alive(venue) then
                        local vx,vz=position(venue); local d=distance(x,z,vx,vz)
                        if d<500^2 and (not bestD or d<bestD) then closest,bestD=venue,d end
                    end
                end
                local spot=closest and approach(id,closest,id)
                if spot then
                    self:Remember(id,"rain",x,z)
                    spot.kind="shelter"; self:Arrive(id,spot,frame)
                    move(id,spot.x,spot.z); return true
                end
            end
        end
        return false
    end
    function life:CanSocialize(id)
        local p=people[id]
        return ambient(id) and not busy(id) and not (p and (p.visit or p.board or p.fear))
            and not (p and p.nextChat and S.GetGameFrame()<p.nextChat)
            and not (p and p.group and groups[p.group] and groups[p.group].leader~=id)
    end
    function life:ResumeGroup(id)
        local p=people[id]; local group=p and p.group and groups[p.group]
        if group and group.leader~=id and ambient(group.leader) then
            S.GiveOrderToUnit(id,CMD.GUARD,{group.leader},{})
            p.guardLeader=group.leader
            return true
        end
        return p and p.visit~=nil
    end
    function life:GuardedVisit(decoy,parent,frame)
        -- The operative keeps its command queue. Observe arrival/departure only.
        if not alive(decoy) or not alive(parent) then return end
        local p=record(decoy); local command=(S.GetUnitCommands(parent,1) or {})[1]
        local target=command and (command.id==CMD.GUARD or (command.id==BLEND and #command.params==1)) and command.params[1]
        local tp=target and people[target]
        if target then guardedUntil[target]=frame+90 end
        local visit=tp and tp.visit
        local x,z=position(decoy)
        -- Guard is the shared movement primitive. Mirror social poses only while
        -- the parent has stopped; never stop, turn or reroute the player's unit.
        local px,pz=position(parent)
        local moving=p.parentX and distance(px,pz,p.parentX,p.parentZ)>4
        p.parentX,p.parentZ=px,pz
        local state=target and (G.CivilianUnitInternalLogicActive or {})[target]
        local behaviour=not moving and type(state)=="table" and state.state==C.civilians.activityStates.started and state.behaviour
        local explicitPhone=command and command.id==BLEND and p.mimicUntil and frame<p.mimicUntil
        if p.mimicActivity and (moving or (not behaviour and not explicitPhone)) then
            call(decoy,"externalInterruptCivilian"); p.mimicActivity=nil
        end
        if p.mimicActivity and not busy(decoy) then p.mimicActivity=nil end
        if target and behaviour and behaviour~=p.mimicActivity then
            local tx,tz=position(target)
            if tx and distance(x,z,tx,tz)<300^2 then
                if behaviour=="talk" then call(decoy,"startChatting",10*1000,target); p.mimicActivity=behaviour
                elseif behaviour=="phone" then
                    if call(decoy,"startPhoneCall",20*1000) then
                        p.mimicActivity=behaviour; self:Conversation(decoy,nil,20*30)
                    end
                elseif behaviour=="pray" and G.ActivePrayerCall then
                    call(decoy,"startPraying",G.ActivePrayerCall.index); p.mimicActivity=behaviour
                end
            end
        end
        if command and command.id==BLEND and not moving and not p.mimicActivity and frame>=p.nextPhone then
            p.nextPhone=frame+draw(p,config.phoneMin,config.phoneMax)
            if call(decoy,"startPhoneCall",20*1000) then
                p.mimicActivity="phone"; p.mimicUntil=frame+20*30; self:Conversation(decoy,nil,20*30)
            end
        end
        if visit and distance(x,z,visit.x,visit.z)<300^2 then
            if not p.guardingVisit or p.guardingVisit.goal~=visit.goal then
                p.guardingVisit={source=visit,goal=visit.goal,kind=visit.kind,x=visit.x,z=visit.z,started=frame}
            end
        elseif p.guardingVisit then
            local prior=p.guardingVisit; p.guardingVisit=nil
            if prior.source.completed and frame-prior.started>=config.visitMin then self:FinishVisit(decoy,prior) end
        end
        -- Explicitly moving/stopping at a venue is also a valid civilian errand.
        if (not tp) and frame>=(p.nextVenueCheck or 0) then
            p.nextVenueCheck=frame+90
            local found
            for _,venue in ipairs(sorted(venues)) do
                if alive(venue) then
                    local vx,vz=position(venue)
                    if distance(x,z,vx,vz)<(math.min(S.GetUnitRadius(venue) or 128,420)+90)^2 then found=venue; break end
                end
            end
            if found then
                if not p.manualVisit or p.manualVisit.goal~=found then
                    p.manualVisit={goal=found,kind=venues[found],x=x,z=z,started=frame}
                end
                local current=p.manualVisit
                if moving then current.stillSince=nil
                else
                    current.stillSince=current.stillSince or frame
                    if frame-current.stillSince>=config.visitMin then current.ready=true end
                end
            elseif p.manualVisit then
                local prior=p.manualVisit; p.manualVisit=nil
                if prior.ready then self:FinishVisit(decoy,prior) end
            end
        end
    end
    function life:CoverPoint(parent,target)
        if context.walkers[S.GetUnitDefID(target)] then return S.GetUnitPosition(target) end
        local p=record(parent)
        if p.coverTarget~=target or not p.coverPoint then
            p.coverTarget=target; p.coverPoint=approach(parent,target,parent)
        end
        local point=p.coverPoint
        if point then return point.x,point.y,point.z end
    end
    function life:IsProtected(id)
        local frame=S.GetGameFrame()
        if (guardedUntil[id] or 0)>frame then return true end
        local p=people[id]; local group=p and p.group and groups[p.group]
        if group then
            for _,member in ipairs(group.members) do if (guardedUntil[member] or 0)>frame then return true end end
        end
        return false
    end
    local function passengerVehicle(id)
        local def=UnitDefs[S.GetUnitDefID(id)]
        return busVehicles[id] or (def and (def.name:match("^truck_western[01]$") or def.name:match("^truck_arab[01]$")))
    end
    function life:VehiclePause(id,pack,frame)
        local v=vehicles[id]
        if not normal() or busy(id) or not passengerVehicle(id) or S.GetUnitTeam(id)~=gaia or pack.boolRefugee then
            v.parkUntil=nil; return false
        end
        if v.parkUntil then
            if frame<v.parkUntil then pack.stuckCounter=0; return true end
            v.parkUntil=nil
            local goal=pack.goalList[pack.goalIndex]
            if goal then move(id,goal.x,goal.z) end
            return false
        end
        local goal=pack.goalList[pack.goalIndex]
        local x,z=position(id)
        if goal and v.lastParkGoal~=goal and distance(x,z,goal.x,goal.z)<100^2 then
            v.lastParkGoal=goal
            local seed=hash(id..":"..frame)
            if seed%100<config.vehicleParkChance then
                v.parkUntil=frame+config.vehicleParkMin+seed%(config.vehicleParkMax-config.vehicleParkMin+1)
                S.GiveOrderToUnit(id,CMD.STOP,{},{})
                pack.stuckCounter=0; return true
            end
        end
        return false
    end
    function life:VehicleOrigin(frame)
        if frame<nextVehicleEvent then return end
        for _,id in ipairs(sorted(vehicles)) do
            local v=vehicles[id]
            if alive(id) and passengerVehicle(id) and S.GetUnitTeam(id)==gaia and frame-v.lastMove>=config.vehicleStoppedFrames and frame>=v.cooldown then
                local seed=hash(id..":"..math.floor(frame/config.vehicleInterval))
                if seed%100<config.vehicleChance then
                    v.cooldown=frame+config.vehicleCooldown
                    nextVehicleEvent=frame+config.vehicleInterval
                    return id
                end
            end
        end
    end
    function life:SpawnedFromVehicle(id,vehicle)
        local x,z=position(vehicle)
        self:Remember(id,"vehicle_exit",x,z,busVehicles[vehicle] and "the bus" or "the car")
    end
    function life:Frame(frame)
        if frame%30~=0 then return end
        busVehicles={}
        for _,id in ipairs(sorted(G.BusesTable)) do
            if alive(id) then busVehicles[S.GetUnitTransporter(id) or id]=true end
        end
        for _,id in ipairs(sorted(vehicles)) do
            local v=vehicles[id]
            if not alive(id) then vehicles[id]=nil else
                local x,z=position(id)
                if not v.x or distance(x,z,v.x,v.z)>4 then v.lastMove=frame end
                v.x,v.z=x,z
            end
        end
        for _,id in ipairs(sorted(sessions)) do
            local s=sessions[id]
            if s and id==s.a then
                if not alive(s.a) or (s.b and not alive(s.b)) or frame>=s.untilFrame or
                    not speaking(s.a) or (s.b and not speaking(s.b)) then closeSession(s)
                elseif frame>=s.nextFrame then
                    local recap=s.recap
                    local speaker=(recap or s.index%2==1 or not s.b) and s.a or s.b
                    local prefix=(not recap and not s.b and s.index%2==0) and "Phone: " or ""
                    local partner=s.b and (speaker==s.a and s.b or s.a) or 0
                    local text=recap or s.lines[s.index]
                    local rate=s.thread and dialogue.lineFrames(text,config.lineFrames) or s.lineFrames
                    SendToUnsynced("CivilianConversation",speaker,partner,prefix..text,rate)
                    if recap then s.recap=nil else
                        if s.thread then
                            if s.index%2==1 then s.thread.lastClaim=text end
                            s.thread.next=s.index+1
                        end
                        s.index=s.index+1
                    end
                    s.nextFrame=frame+rate
                    if s.index>#s.lines then closeSession(s) end
                end
            end
        end
        if frame%90==0 then
            for _,id in ipairs(sorted(people)) do
                local p=people[id]
                if ambient(id) and normal() and not p.fear and not p.board and not sessions[id] and frame>=p.nextPhone then
                    p.nextPhone=frame+draw(p,config.phoneMin,config.phoneMax)
                    if not busy(id) and not p.group then
                        S.GiveOrderToUnit(id,CMD.STOP,{},{})
                        if call(id,"startPhoneCall",20*1000) then self:Conversation(id,nil,20*30) end
                    end
                end
            end
        end
        if frame%(15*30)==0 then
            for _,id in ipairs(sorted(G.BuildingTable)) do
                if alive(id) and not (G.CityConstructionSites or {})[id] and venues[id]~="brothel" then
                    local tooltip=(S.GetUnitTooltip(id) or ""):lower()
                    if tooltip:find("hotel",1,true) or tooltip:find("motel",1,true) then venues[id]="luggage"
                    elseif not venues[id] then venues[id]="errand" end
                end
            end
        end
        if frame%config.vehicleInterval==0 and normal() then
            local vehicle=self:VehicleOrigin(frame)
            if vehicle then
                local vx,vz=position(vehicle)
                local near=S.GetUnitsInCylinder(vx,vz,config.vehicleBoardDistance,gaia) or {}; table.sort(near)
                for _,id in ipairs(near) do
                    local p=people[id]
                    if p and self:CanSocialize(id) and not p.group and not sessions[id] and not self:IsProtected(id) then
                        p.board={vehicle=vehicle,untilFrame=frame+8*30}
                        move(id,vx,vz); break
                    end
                end
            end
        end
    end
    function life:Shutdown() if G.CivilianLife==self then G.CivilianLife=nil end end
    return life
end
