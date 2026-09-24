-- Use public chase markers only; no hidden graph or enemy safehouse information.
function CreateBetrayalMgr(myTeamID)
    local reserved = gadget.betrayalContacts
    local owned = {}
    local function release()
        for id in pairs(owned) do reserved[id]=nil end
        owned={}
    end
    local operativeDefs={}
    for _,name in ipairs({"operativepropagator","operativeinvestigator","operativeasset","civilianagent"}) do
        if UnitDefNames[name] then operativeDefs[UnitDefNames[name].id]=true end
    end
    local function GameFrame(frame)
        release()
        local teamUnits=Spring.GetTeamUnits(myTeamID) or {}
        for _,runner in ipairs(teamUnits) do
            if Spring.GetUnitRulesParam(runner,"betrayal_runner")==1 then
                local x,y,z=Spring.GetUnitPosition(runner)
                local best,score
                for _,id in ipairs(teamUnits) do
                    if id~=runner and not owned[id] and operativeDefs[Spring.GetUnitDefID(id)] and
                        Spring.GetUnitRulesParam(id,"betrayal_runner")~=1 then
                        local ux,_,uz=Spring.GetUnitPosition(id)
                        local hp,_,stun,_,built=Spring.GetUnitHealth(id)
                        if ux and hp and (stun or 0)<hp and (built or 1)>=1 then
                            local d=(ux-x)^2+(uz-z)^2
                            if not score or d<score then best,score=id,d end
                        end
                    end
                end
                if best then
                    reserved[best],owned[best]=true,true
                    -- The normal managers cannot overwrite this rendezvous order.
                    GiveOrderToUnit(best,CMD.MOVE,{x,y,z},{},true)
                end
            end
        end
    end
    return {GameFrame=GameFrame,Shutdown=release}
end
