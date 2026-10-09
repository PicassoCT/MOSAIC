-- Prometheus runs strategy on its owning client and submits orders through the
-- authenticated synced bridge. No economy bonuses or hidden enemy state.
function gadget:GetInfo()
    return {name="Prometheus", desc="Dispersed MOSAIC economy, reconnaissance and raids",
        author="Mosaic contributors", license="GNU GPL v2", layer=1, enabled=true}
end
local levels={"easy","medium","hard","impossible"}
gadget.difficulty=levels[tonumber((Spring.GetModOptions() or {}).craig_difficulty) or 2] or "medium"
if not gadgetHandler:IsSyncedCode() then
    include("LuaRules/Gadgets/prometheus/strategy.lua")
    include("LuaRules/Gadgets/prometheus/team.lua")
    include("LuaRules/Gadgets/prometheus/betrayal.lua")
    local player=Spring.GetMyPlayerID()
    local teams, unresolved, deadTeams={}, {}, {}
    local lastFrame=-1
    local debug=false
    gadget.betrayalContacts={}
    function gadget.IsDebug() return debug end
    function gadget.Log(...) if debug then Spring.Echo("Prometheus",...) end end
    local function resolve(id, units)
        local side=select(5,Spring.GetTeamInfo(id))
        side=type(side)=="string" and side:lower() or ""
        if side=="antagon" or side=="protagon" then return side,"team" end
        local start=tonumber(Spring.GetTeamRulesParam(id,"startUnit"))
        for _,pair in ipairs({{"antagon","operativepropagator"},{"protagon","operativeinvestigator"}}) do
            local def=UnitDefNames[pair[2]]
            if def then
                if def.id==start then return pair[1],"startUnit" end
                for _,u in ipairs(units) do
                    if not Spring.GetUnitIsDead(u) and Spring.GetUnitDefID(u)==def.id then return pair[1],"unit" end
                end
            end
        end
    end
    function gadget:Initialize()
        gadgetHandler:AddChatAction("prometheus",function()
            debug=not debug
            Spring.Echo("Prometheus diagnostics",debug and "on" or "off")
            return true
        end,"Toggle bounded Prometheus strategy diagnostics")
    end
    function gadget:GameFrame(f)
        if f<2 or f==lastFrame then return end
        lastFrame=f
        for _,id in ipairs(Spring.GetTeamList()) do
            local _,leader,dead=Spring.GetTeamInfo(id)
            if not dead and not deadTeams[id] and leader==player and Spring.GetTeamLuaAI(id)=="Prometheus" then
                if not teams[id] then
                    local units=Spring.GetTeamUnits(id) or {}
                    local side,source=resolve(id,units)
                    if side then
                        Spring.Echo("Prometheus: initializing team "..id.." as "..side.." (from "..source..")")
                        teams[id]=CreateTeam(id,select(6,Spring.GetTeamInfo(id)),side)
                        teams[id].GameStart()
                        for _,u in ipairs(units) do
                            if not Spring.GetUnitIsDead(u) then
                                local def=Spring.GetUnitDefID(u)
                                teams[id].UnitCreated(u,def,id)
                                local _,_,_,_,built=Spring.GetUnitHealth(u)
                                if (built or 0)>=1 then teams[id].UnitFinished(u,def,id) end
                            end
                        end
                    elseif not unresolved[id] or f-unresolved[id].frame>=900 then
                        local n=(unresolved[id] and unresolved[id].count or 0)+1
                        if n<=5 or debug then
                            Spring.Echo("Prometheus: team "..id.." faction unresolved; retrying team/startUnit/operative")
                        end
                        unresolved[id]={frame=f,count=n}
                    end
                end
                if teams[id] then teams[id].GameFrame(f) end
            end
        end
    end
    function gadget:TeamDied(id)
        if teams[id] then teams[id].Shutdown();teams[id]=nil end
        deadTeams[id]=true
    end
    function gadget:Shutdown()
        for _,team in pairs(teams) do team.Shutdown() end
        if gadgetHandler.RemoveChatAction then gadgetHandler:RemoveChatAction("prometheus") end
    end
    for _,name in ipairs({"UnitCreated","UnitFinished","UnitDestroyed","UnitTaken","UnitGiven",
        "UnitIdle","UnitLoaded","UnitUnloaded","UnitDamaged"}) do
        local event=name
        gadget[event]=function(self,u,def,t,...)
            if teams[t] and teams[t][event] then teams[t][event](u,def,t,...) end
        end
    end
end
callInList={"TeamDied","UnitCreated","UnitFinished","UnitDestroyed","UnitTaken","UnitGiven",
    "UnitIdle","UnitLoaded","UnitUnloaded","UnitDamaged"}
return VFS.Include("LuaRules/Gadgets/prometheus/framework.lua",nil,VFS.ZIP)
