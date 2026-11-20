-- Two-car containment uses the police pool and city roads, not combat dispatch.
local M = {}
function M.New(config, officers, position, move, spawnLocation)
    local cfg = config.police.hostages
    local records, api = {}, {}
    local gaia, carDef = Spring.GetGaiaTeamID(), UnitDefNames.policetruck.id
    local function sorted(t)
        local ids = {}; for id in pairs(t) do ids[#ids+1] = id end
        table.sort(ids); return ids
    end
    local function roadblocks(p)
        local candidates = {}
        for _, road in ipairs((GG.CityRoadNetwork or {}).roads or {}) do
            for i=2,#road.points do
                local a,b=road.points[i-1],road.points[i]
                local dx,dz=b[1]-a[1],b[2]-a[2]
                local length=math.sqrt(dx*dx+dz*dz)
                if length>0 then
                    local projection=((p.x-a[1])*dx+(p.z-a[2])*dz)/(length*length)
                    for _, offset in ipairs({-cfg.radius,0,cfg.radius}) do
                        local t=math.max(0,math.min(1,projection+offset/length))
                        local x,z=a[1]+dx*t,a[2]+dz*t
                        local distance=(x-p.x)^2+(z-p.z)^2
                        if distance>=cfg.minDistance^2 and distance<=cfg.maxDistance^2
                            and Spring.TestMoveOrder(carDef,x,Spring.GetGroundHeight(x,z),z) then
                            candidates[#candidates+1]={x=x,z=z,y=Spring.GetGroundHeight(x,z),
                                heading=math.atan2(-dz,dx),score=math.abs(math.sqrt(distance)-cfg.radius)}
                        end
                    end
                end
            end
        end
        table.sort(candidates,function(a,b)
            if a.score~=b.score then return a.score<b.score end
            if a.x~=b.x then return a.x<b.x end
            return a.z<b.z
        end)
        local result={}
        for _,p in ipairs(candidates) do
            local separate=true
            for _,q in ipairs(result) do
                if (p.x-q.x)^2+(p.z-q.z)^2<cfg.separation^2 then separate=false end
            end
            if separate then result[#result+1]=p end
            if #result==cfg.cars then break end
        end
        return result
    end
    function api.IsHoldingFire(id)
        return officers[id] ~= nil and officers[id].cordon ~= nil
    end
    local function restore(id,state)
        state.cordon=nil
        Spring.GiveOrderToUnit(id,CMD.FIRE_STATE,{state.cordonFireState or 2},{})
        state.cordonFireState=nil
    end
    function api.End(carrier,civilian,dead)
        local record=records[carrier]
        if not record or record.civilian~=civilian then return end
        records[carrier]=nil
        local frame=Spring.GetGameFrame()
        for _,id in ipairs(sorted(record.cars)) do
            local state=officers[id]
            if state and state.cordon==record then
                restore(id,state)
                state.expires=frame+config.police.dispatch.durationFrames
                if dead and position(carrier) then
                    -- Hand the same cars to the existing sighting/search pursuit.
                    state.incident={attacker=carrier,kind='hostage_death',location=record.location}
                    state.nextOrder=0
                    Spring.GiveOrderToUnit(id,CMD.FIRE_STATE,{2},{})
                else
                    GG.PoliceInPursuit[id]=nil
                    Spring.GiveOrderToUnit(id,CMD.STOP,{},{})
                end
            end
        end
    end
    function api.Report(carrier,civilian)
        if records[carrier] then return end
        local p=position(civilian)
        if not p then return end
        records[carrier]={carrier=carrier,civilian=civilian,location=p,cars={},
            due=Spring.GetGameFrame()+config.police.dispatch.reportDelayFrames}
        GG.PoliceActionSoundInterVallStartFrame=Spring.GetGameFrame()
    end
    function api.Update(frame)
        for _,carrier in ipairs(sorted(records)) do
            local record=records[carrier]
            if not position(carrier) or not position(record.civilian) then
                api.End(carrier,record.civilian,not position(record.civilian))
            elseif frame>=record.due then
                record.goals=record.goals or roadblocks(record.location)
                if #record.goals<cfg.cars then record.goals=roadblocks(record.location) end
                for slot,goal in ipairs(record.goals) do
                    local assigned
                    for id,n in pairs(record.cars) do if n==slot then assigned=id end end
                    if not assigned then
                        local count,id=0,nil
                        for _,candidate in ipairs(sorted(officers)) do
                            count=count+1
                            local state=officers[candidate]
                            if not id and not state.incident and not state.cordon and not GG.PoliceBribes[candidate]
                                and position(candidate) and Spring.GetUnitDefID(candidate)==carDef then id=candidate end
                        end
                        if not id and count<config.police.population.maxOfficers then
                            local x,y,z=spawnLocation(record.location)
                            if x then id=Spring.CreateUnit('policetruck',x,y,z,0,gaia) end
                        end
                        if id then
                            local state=officers[id]
                            state.cordon, state.cordonGoal, state.cordonParked=record,goal,false
                            state.cordonFireState=(Spring.GetUnitStates(id) or {}).firestate or 2
                            state.nextOrder=frame+90
                            record.cars[id]=slot
                            GG.PoliceInPursuit[id]=carrier -- reserves movement from the truck's wander loop
                            Spring.GiveOrderToUnit(id,CMD.STOP,{},{})
                            Spring.GiveOrderToUnit(id,CMD.FIRE_STATE,{0},{})
                            for n in ipairs(UnitDefs[carDef].weapons or {}) do
                                Spring.SetUnitWeaponState(id,n,{salvoLeft=0})
                            end
                            move(id,goal)
                        end
                    end
                end
                for _,id in ipairs(sorted(record.cars)) do
                    local state,p=officers[id],position(id)
                    if state and p and not GG.PoliceBribes[id] then
                        local goal=state.cordonGoal
                        if (p.x-goal.x)^2+(p.z-goal.z)^2<=cfg.arrivalDistance^2 then
                            if not state.cordonParked then
                                Spring.GiveOrderToUnit(id,CMD.STOP,{},{})
                                Spring.SetUnitRotation(id,0,goal.heading,0)
                                state.cordonParked=true
                            end
                        elseif frame>=state.nextOrder then
                            state.cordonParked=false;move(id,goal);state.nextOrder=frame+90
                        end
                    end
                end
            end
        end
    end
    function api.Destroyed(id)
        local state=officers[id]
        if state and state.cordon and position(id) then restore(id,state) end
        for _,record in pairs(records) do record.cars[id]=nil end
        local record=records[id]
        if record then api.End(id,record.civilian,false) end
    end
    function api.Shutdown()
        for _,id in ipairs(sorted(records)) do api.End(id,records[id].civilian,false) end
    end
    return api
end
return M
