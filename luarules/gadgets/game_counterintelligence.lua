function gadget:GetInfo()
    return {name="Counterintelligence", desc="Hub subversion and operative investigations",
        author="Mosaic contributors", license="GPL3", layer=2, enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("luarules/configs/commandsIDs.lua")
local cfg = VFS.Include("luarules/configs/counterintelligence.lua")
local replaceUnit = VFS.Include("scripts/lib_unit_replacement.lua")
local INVESTIGATE, ACTIVATE = CMD_INVESTIGATE, CMD_ACTIVATE_NETWORK
local operatives, safehouses = getOperativeTypeTable(UnitDefs), getSafeHouseTypeTable(UnitDefs)
local factories, hubs = {}, {}
for def in pairs(safehouses) do hubs[def]=true end
for _, name in ipairs(cfg.factories) do
    local def = UnitDefNames[name]
    if def then factories[def.id]=true;hubs[def.id]=true end
end
local markerDef = UnitDefNames.doubleagent.id
local gaia = Spring.GetGaiaTeamID()
local allied = {allied=true}
-- rosters include every surviving descendant, even after an intermediate builder
-- dies. Only actual builder IDs establish provenance; never choose a nearby hub.
local rosters, ancestors, parents = {}, {}, {}
local networks, markers, burned, secured, morphing = {}, {}, {}, {}, {}
local orphans = {} -- surviving members reference a detached record, never a dead unit ID
local jobs, actorJobs = {}, {}
local internal = false
local api = {}
local function alive(id)
    return type(id)=="number" and id==id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function sorted(t)
    local out={};for id in pairs(t or {}) do out[#out+1]=id end;table.sort(out);return out
end
local function complete(id)
    if not alive(id) then return false end
    local hp,_,_,_,built = Spring.GetUnitHealth(id)
    return hp and hp>0 and (built or 1)>=1
end
local function productionUnit(def)
    local ud=UnitDefs[def]
    if not ud or def==markerDef then return false end
    if hubs[def] or operatives[def] then return true end
    local cp=ud.customParams or {}
    local categories=ud.modCategories or {}
    return cp.baseclass~="Abstract" and not categories.abstract and not categories.notarget
        and not ud.name:find("_morph_",1,true)
end
local function order(id,cmd,p)
    internal=true;Spring.GiveOrderToUnit(id,cmd,p or {},{});internal=false
end
local function message(team,text) Spring.SendMessageToTeam(team,"Counterintelligence: "..text) end
local function targets(root,n)
    local out={}
    local owner=n.activated and not n.blocked and n.beneficiary or n.owner
    if alive(root) and Spring.GetUnitTeam(root)==owner and not secured[root] then out[root]=true end
    if n.mass then
        for id in pairs(n.survivors or rosters[root] or {}) do
            if alive(id) and Spring.GetUnitTeam(id)==owner and not secured[id] then out[id]=true end
        end
    end
    return out
end
local function compromise(id)
    if secured[id] or not alive(id) then return end
    if networks[id] and (not networks[id].activated or networks[id].blocked) and Spring.GetUnitTeam(id)==networks[id].owner then return id,networks[id] end
    for _,root in ipairs(sorted(ancestors[id])) do
        local n=networks[root]
        if n and n.mass and (not n.activated or n.blocked) and Spring.GetUnitTeam(id)==n.owner then return root,n end
    end
    local n=orphans[id]
    if n and (not n.activated or n.blocked) and Spring.GetUnitTeam(id)==n.owner then return nil,n end
end
local function detachOrphan(id)
    local n=orphans[id]
    if n then n.survivors[id]=nil;orphans[id]=nil end
end
local function removeMarker(root,n)
    local icon=n.icon
    n.icon=nil;GG.DoubleAgents[root]=nil
    if icon then markers[icon]=nil;if alive(icon) then Spring.DestroyUnit(icon,false,true) end end
end
local function removeNetwork(root)
    local n=networks[root]
    if n then removeMarker(root,n);networks[root]=nil end
end
local function burnUnit(id)
    if not alive(id) then return end
    burned[id]=true
    Spring.SetUnitRulesParam(id,"ci_production_disabled",1,allied)
    order(id,CMD.STOP)
    if hubs[Spring.GetUnitDefID(id)] then order(id,CMD.ONOFF,{0}) end
end
local function burnNetwork(root,n)
    n.blocked=true -- deliberately do not change the handler's icon or notify them
    for _,id in ipairs(sorted(targets(root,n))) do burnUnit(id) end
end
local function finishJob(target)
    local job=jobs[target]
    if not job then return end
    jobs[target]=nil;actorJobs[job.actor]=nil
    if alive(job.actor) then
        local index=Spring.FindUnitCmdDesc(job.actor,INVESTIGATE)
        if index then Spring.EditUnitCmdDesc(job.actor,index,{name="Investigate"}) end
        Spring.SetUnitRulesParam(job.actor,"ci_investigating",0,allied)
        Spring.SetUnitRulesParam(job.actor,"ci_progress",0,allied)
        Spring.ClearUnitGoal(job.actor)
    end
end
local function rewardOpposition(team)
    local enemies={}
    for _,other in ipairs(Spring.GetTeamList()) do
        local _,_,dead=Spring.GetTeamInfo(other,false)
        if other~=gaia and not dead and not Spring.AreTeamsAllied(team,other) then enemies[#enemies+1]=other end
    end
    table.sort(enemies)
    for _,other in ipairs(enemies) do
        Spring.AddTeamResource(other,"metal",cfg.falseAccusationReward/#enemies)
    end
end
local function recovery(target,team)
    if secured[target] or not factories[Spring.GetUnitDefID(target)] then return end
    local current=Spring.GetUnitTeam(target)
    local function eligible(n)
        return n and (n.activated or n.used) and n.owner==team
            and (current==team or current==n.beneficiary)
    end
    local n=networks[target]
    if eligible(n) then return n end
    for _,root in ipairs(sorted(ancestors[target])) do
        n=networks[root]
        if eligible(n) then return n end
    end
    n=orphans[target]
    if eligible(n) then return n end
end
local function validTarget(actor,target,team)
    if actor==target or not complete(actor) or not complete(target) then return false end
    if not operatives[Spring.GetUnitDefID(actor)] then return false end
    local def=Spring.GetUnitDefID(target)
    if not operatives[def] and not hubs[def] then return false end
    if Spring.GetUnitRulesParam(actor,"betrayal_runner")==1 or Spring.GetUnitRulesParam(actor,"betrayal_pending")==1
        or Spring.GetUnitRulesParam(target,"betrayal_runner")==1 or Spring.GetUnitRulesParam(target,"betrayal_pending")==1 then return false end
    if Spring.GetUnitTeam(actor)~=team then return false end
    if Spring.GetUnitTeam(target)~=team then
        if not recovery(target,team) then return false end
        local los=Spring.GetUnitLosState(target,Spring.GetUnitAllyTeam(actor))
        if not los or not los.los then return false end
    end
    return true
end
local function factoryCleanup(target,team,n)
    local sourceRoot, sourceNetwork=compromise(target)
    local group={[target]=true}
    for id in pairs(rosters[target] or {}) do group[id]=true end
    -- Returning an activated factory is an ownership restoration, not an execution.
    -- Keep unfinished restorations retryable when the receiving team is at its cap.
    local pending, humanRemainder=false,false
    for _,id in ipairs(sorted(group)) do
        if alive(id) then
            local current=Spring.GetUnitTeam(id)
            if current==team or (n and current==n.beneficiary) then
                local def=Spring.GetUnitDefID(id)
                if operatives[def] or safehouses[def] then
                    -- Rekeying machinery cannot reset human loyalty. This matters
                    -- when a compromised safehouse was morphed into a factory.
                    if current==team then humanRemainder=true;burnUnit(id) end
                else
                local restored=id
                local wasBurned=burned[id]
                if current~=team then restored=replaceUnit(id,team) end
                if restored then
                    detachOrphan(restored)
                    secured[restored]=true;burned[restored]=nil
                    Spring.SetUnitRulesParam(restored,"ci_production_disabled",0,allied)
                    Spring.SetUnitRulesParam(restored,"ci_secured",1,allied)
                    if wasBurned and hubs[def] then order(restored,CMD.ONOFF,{1}) end
                    if restored==target or (id==target and restored~=id) then target=restored end
                else pending=true end
                end
            end
        end
    end
    if humanRemainder and sourceNetwork then burnNetwork(sourceRoot,sourceNetwork)
    elseif humanRemainder and networks[target] then networks[target].blocked=true
    elseif not pending then removeNetwork(target) end
    return not pending,target,humanRemainder
end
local function resolve(target,job)
    local root,n=compromise(target)
    local recovered=recovery(target,job.team)
    local def=Spring.GetUnitDefID(target)
    if factories[def] then
        if n or recovered or burned[target] then
            local done,_,humanRemainder=factoryCleanup(target,job.team,recovered)
            if not done then
                message(job.team,"Some units could not be restored at the unit limit. Free capacity and investigate again.")
            else
                message(job.team,humanRemainder and "Factory software secured. Historical human recruits remain under suspicion and cannot build."
                    or "Factory software secured; its surviving products are no longer subject to the backdoor.")
            end
        else message(job.team,"Factory audit complete. No subversion found.") end
    elseif n then
        burnNetwork(root,n)
        if operatives[def] then
            GG.StartBetrayalRunner(target,n.beneficiary)
            message(job.team,"Double agent exposed. The compromised network is disabled; the suspect is fleeing.")
        else
            message(job.team,"Compromised safehouse network disabled. Its handler has not been notified. Production is shut down.")
        end
    elseif operatives[def] then
        rewardOpposition(job.team)
        message(job.team,"The accusation was unfounded. The opposition gains "..cfg.falseAccusationReward.." money.")
    else message(job.team,"Safehouse investigation complete. No subversion found.") end
end
function api.Register(root,beneficiary)
    if not alive(root) or secured[root] then return false end
    local def=Spring.GetUnitDefID(root)
    local owner=Spring.GetUnitTeam(root)
    if (not hubs[def] and not operatives[def]) or beneficiary==nil or beneficiary==gaia
        or owner==gaia or Spring.AreTeamsAllied(owner,beneficiary) then return false end
    local _,existing=compromise(root)
    if existing then return true end
    networks[root]={owner=owner,beneficiary=beneficiary,mass=hubs[def] or false}
    return true
end
function api.IsProductionDisabled(id) return burned[id]==true end
function api.AdoptRecruit(id,builder)
    -- Recruitment establishes a new cover identity under the actual recruiter.
    removeNetwork(id)
    detachOrphan(id)
    for root in pairs(ancestors[id] or {}) do if rosters[root] then rosters[root][id]=nil end end
    ancestors[id]={};parents[id]=nil
    if alive(builder) and Spring.GetUnitTeam(builder)==Spring.GetUnitTeam(id) then
        if orphans[builder] then orphans[id]=orphans[builder];orphans[id].survivors[id]=true end
        parents[id]=builder
        for root in pairs(ancestors[builder] or {}) do ancestors[id][root]=true end
        if hubs[Spring.GetUnitDefID(builder)] then ancestors[id][builder]=true end
        for root in pairs(ancestors[id]) do
            rosters[root]=rosters[root] or {};rosters[root][id]=true
        end
    end
end
function api.UnitReplaced(oldID,newID)
    -- Explicit migration is the only way a new ID inherits an old identity.
    local lineage=ancestors[oldID] or {}
    local orphan=orphans[oldID]
    if orphan then
        orphans[oldID]=nil;orphans[newID]=orphan
        orphan.survivors[oldID]=nil;orphan.survivors[newID]=true
    end
    ancestors[oldID]=nil;ancestors[newID]=lineage
    for root in pairs(lineage) do
        if rosters[root] then rosters[root][oldID]=nil;rosters[root][newID]=true end
    end
    local roster=rosters[oldID]
    if roster then
        rosters[oldID]=nil;rosters[newID]=roster
        for child in pairs(roster) do
            local a=ancestors[child]
            if a then a[oldID]=nil;a[newID]=true end
        end
    end
    parents[newID]=parents[oldID];parents[oldID]=nil
    for child,parent in pairs(parents) do if parent==oldID then parents[child]=newID end end
    local n=networks[oldID]
    if n then
        networks[oldID]=nil;networks[newID]=n
        GG.DoubleAgents[oldID]=nil
        if n.icon then markers[n.icon]=newID;GG.DoubleAgents[newID]=n.icon end
    end
    secured[newID]=secured[oldID];secured[oldID]=nil
    local wasBurned=burned[oldID];burned[oldID]=nil
    if wasBurned then burnUnit(newID) end
    finishJob(oldID)
    if actorJobs[oldID] then finishJob(actorJobs[oldID]) end
end
function api.BeginMorph(id) morphing[id]=true end
function api.EndMorph(oldID,newID)
    morphing[oldID]=nil
    if not newID then gadget:UnitDestroyed(oldID);return end
    if oldID~=newID then api.UnitReplaced(oldID,newID) end
    if hubs[Spring.GetUnitDefID(newID)] then rosters[newID]=rosters[newID] or {} end
    if networks[newID] then networks[newID].mass=hubs[Spring.GetUnitDefID(newID)] or false end
    if burned[newID] then burnUnit(newID) end
end
local function activate(root,n)
    if n.activated then return end
    if n.blocked then
        -- Consume the handler's signal normally; no secret-state warning is sent.
        removeMarker(root,n);n.activated=true;return
    end
    local list=sorted(targets(root,n))
    -- Replace the hub last, after its production roster has migrated.
    for i=#list,1,-1 do if list[i]==root then table.remove(list,i);break end end
    list[#list+1]=root
    local failed=false
    for _,id in ipairs(list) do
        if complete(id) and Spring.GetUnitTeam(id)==n.owner and not secured[id] and not burned[id] then
            local newID=replaceUnit(id,n.beneficiary)
            if not newID then failed=true else n.used=true;if id==root then root=newID end end
        end
    end
    if failed then
        message(n.beneficiary,"Some sleepers could not change sides at the unit limit. Free capacity and signal again.")
    else removeMarker(root,n);n.activated=true end
end
local function refreshMarker(root,n)
    if n.activated or not complete(root) then return end
    local x,y,z=Spring.GetUnitPosition(root)
    if not alive(n.icon) then
        local icon=Spring.CreateUnit("doubleagent",x,y+cfg.markerHeight,z,0,n.beneficiary)
        if not icon then return end -- keep the record; retry when capacity is available
        n.icon=icon;markers[icon]=root;GG.DoubleAgents[root]=icon
        Spring.MoveCtrl.Enable(icon)
        Spring.SetUnitCloak(icon,true)
        local cloak=Spring.FindUnitCmdDesc(icon,CMD.CLOAK)
        if cloak then Spring.RemoveUnitCmdDesc(icon,cloak) end
        Spring.InsertUnitCmdDesc(icon,{id=ACTIVATE,type=CMDTYPE.ICON,name="Turn network",
            action="activatesleepernetwork",tooltip="Activate this hub's sleeper network, or turn this individual agent."})
    end
    Spring.MoveCtrl.SetPosition(n.icon,x,y+cfg.markerHeight,z)
    local list=sorted(targets(root,n))
    local description={}
    for _,id in ipairs(list) do
        if complete(id) then
            local def=UnitDefs[Spring.GetUnitDefID(id)]
            description[#description+1]=(def.humanName or def.name).." #"..id
        end
    end
    local text="Turn "..#description.." surviving units:\n"..table.concat(description,"\n")
    if text~=n.description then
        n.description=text
        local index=Spring.FindUnitCmdDesc(n.icon,ACTIVATE)
        if index then Spring.EditUnitCmdDesc(n.icon,index,{name=n.mass and "Turn network" or "Turn agent",tooltip=text}) end
    end
end
function gadget:UnitCreated(id,def,team,builder)
    if operatives[def] then
        Spring.InsertUnitCmdDesc(id,{id=INVESTIGATE,type=CMDTYPE.ICON_UNIT,name="Investigate",
            action="investigatesubversion",cursor="Repair",
            tooltip="Investigate another operative, safehouse or factory. Stay nearby for 30s / 300 money; factories 90s / 2000 money + 1000 supply. False operative accusations reward the enemy 500 money."})
    end
    if GG.UnitReplacement or morphing[id] or team==gaia or not productionUnit(def) then return end
    if hubs[def] then rosters[id]=rosters[id] or {} end
    ancestors[id]={}
    if alive(builder) and Spring.GetUnitTeam(builder)==team then
        if secured[builder] then secured[id]=true end
        if orphans[builder] and not secured[id] then
            orphans[id]=orphans[builder];orphans[id].survivors[id]=true
        end
        parents[id]=builder
        for root in pairs(ancestors[builder] or {}) do
            if alive(root) then ancestors[id][root]=true end
        end
        if hubs[Spring.GetUnitDefID(builder)] then ancestors[id][builder]=true end
        for root in pairs(ancestors[id]) do
            rosters[root]=rosters[root] or {};rosters[root][id]=true
        end
    end
end
function gadget:UnitDestroyed(id)
    if morphing[id] then return end
    if markers[id] then
        local root=markers[id];markers[id]=nil
        local n=networks[root]
        if n then n.icon=nil;GG.DoubleAgents[root]=nil end
    end
    local n=networks[id]
    if n then
        -- The channel dies with the hub; surviving guilt does not disappear.
        n.survivors=targets(id,n)
        n.survivors[id]=nil
        for member in pairs(n.survivors) do
            if not orphans[member] then orphans[member]=n
            else n.survivors[member]=nil end
        end
    end
    removeNetwork(id)
    detachOrphan(id)
    for root in pairs(ancestors[id] or {}) do if rosters[root] then rosters[root][id]=nil end end
    for child in pairs(rosters[id] or {}) do if ancestors[child] then ancestors[child][id]=nil end end
    rosters[id],ancestors[id],parents[id],burned[id],secured[id]=nil,nil,nil,nil,nil
    for child,parent in pairs(parents) do if parent==id then parents[child]=nil end end
    finishJob(id);if actorJobs[id] then finishJob(actorJobs[id]) end
end
function gadget:UnitGiven(id)
    finishJob(id);if actorJobs[id] then finishJob(actorJobs[id]) end
    -- Giving/capturing a unit never makes it eligible to steal from an unrelated team.
    if networks[id] and Spring.GetUnitTeam(id)~=networks[id].owner then removeNetwork(id) end
end
function gadget:AllowCommand(id,def,team,cmd,p)
    if internal then return true end
    if markers[id] then
        if cmd==ACTIVATE then local root=markers[id];activate(root,networks[root]) end
        return false
    end
    if cmd==INVESTIGATE then
        return p and #p==1 and validTarget(id,p[1],team) and (not jobs[p[1]] or jobs[p[1]].actor==id)
    end
    if burned[id] and (cmd<0 or cmd==CMD.REPAIR or cmd==CMD.ONOFF or cmd==CMD_STICKY_BUILD) then return false end
    if cmd==CMD.INSERT and p and type(p[2])=="number" then
        if p[2]==INVESTIGATE then return #p==4 and validTarget(id,p[4],team) end
        if burned[id] and (p[2]<0 or p[2]==CMD.REPAIR or p[2]==CMD.ONOFF or p[2]==CMD_STICKY_BUILD) then return false end
    end
    return cmd~=ACTIVATE
end
function gadget:CommandFallback(id,def,team,cmd,p)
    if cmd~=INVESTIGATE then return false end
    local target=p and p[1]
    if not validTarget(id,target,team) then
        if actorJobs[id] then finishJob(actorJobs[id]) end
        return true,true
    end
    if jobs[target] and jobs[target].actor~=id then return true,true end
    local x,y,z=Spring.GetUnitPosition(id)
    local tx,ty,tz=Spring.GetUnitPosition(target)
    local range=cfg.range+(Spring.GetUnitRadius(target) or 0)
    if (x-tx)^2+(y-ty)^2+(z-tz)^2>range^2 then
        Spring.SetUnitMoveGoal(id,tx,ty,tz,range-8);return true,false
    end
    Spring.ClearUnitGoal(id)
    if not jobs[target] then
        if actorJobs[id] then finishJob(actorJobs[id]) end
        jobs[target]={actor=id,team=team,progress=0,factory=factories[Spring.GetUnitDefID(target)] or false}
        actorJobs[id]=target
        Spring.SetUnitRulesParam(id,"ci_investigating",target,allied)
    end
    return true,false
end
function gadget:AllowUnitCreation(def,builder)
    return not burned[builder]
end
function gadget:AllowUnitBuildStep(builder,team,id,def,part)
    if markers[id] then return false end
    if part>0 then return not burned[builder] and not ((burned[id] or burned[parents[id]]) and not complete(id)) end
    return true
end
function gadget:AllowUnitTransfer(id) return not markers[id] end
function gadget:AllowUnitDecloak(id) return not markers[id] end
function gadget:UnitPreDamaged(id,def,team,damage)
    if markers[id] then return 0,0 end
    return damage
end
function gadget:GameFrame(frame)
    if frame%cfg.updateFrames~=0 then return end
    for _,root in ipairs(sorted(networks)) do
        local n=networks[root]
        if not alive(root) then removeNetwork(root) else refreshMarker(root,n) end
    end
    for _,target in ipairs(sorted(jobs)) do
        local job=jobs[target]
        local cmd,_,_,commandTarget=Spring.GetUnitCurrentCommand(job.actor)
        if cmd~=INVESTIGATE or commandTarget~=target or not validTarget(job.actor,target,job.team) then
            finishJob(target)
        else
            local x,y,z=Spring.GetUnitPosition(job.actor)
            local tx,ty,tz=Spring.GetUnitPosition(target)
            local range=cfg.range+(Spring.GetUnitRadius(target) or 0)
            local stunned=Spring.GetUnitIsStunned(job.actor)
            local targetStunned=Spring.GetUnitIsStunned(target)
            if not stunned and not targetStunned and not Spring.GetUnitTransporter(job.actor)
                and not Spring.GetUnitTransporter(target) and (x-tx)^2+(y-ty)^2+(z-tz)^2<=range^2 then
                local duration=job.factory and cfg.factoryFrames or cfg.investigationFrames
                local increment=math.min(cfg.updateFrames/duration,1-job.progress)
                local money=job.factory and cfg.factoryMoney or cfg.investigationMoney
                local supply=job.factory and cfg.factorySupply or cfg.investigationSupply
                if Spring.UseUnitResource(job.actor,{m=money*increment,e=supply*increment}) then
                    job.progress=job.progress+increment
                    Spring.SetUnitRulesParam(job.actor,"ci_progress",job.progress,allied)
                    local index=Spring.FindUnitCmdDesc(job.actor,INVESTIGATE)
                    if index then Spring.EditUnitCmdDesc(job.actor,index,{name="Investigate "..math.floor(job.progress*100).."%"}) end
                    if job.progress>=1-1e-9 then
                        finishJob(target)
                        order(job.actor,CMD.STOP)
                        resolve(target,job)
                    end
                end
            end
        end
    end
end
function gadget:Initialize()
    GG.DoubleAgents={};GG.Counterintelligence=api
    gadgetHandler:RegisterCMDID(INVESTIGATE);gadgetHandler:RegisterCMDID(ACTIVATE)
    for _,id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id,Spring.GetUnitDefID(id),Spring.GetUnitTeam(id)) end
end
function gadget:Shutdown()
    GG.Counterintelligence=nil;GG.DoubleAgents=nil
end
