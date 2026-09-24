function gadget:GetInfo()
    return {name = "Treason and Betrayal Gadget", desc = "Visible defections and recoverable intelligence",
        author = "Picasso, contributors", date = "2026", license = "GPL3", layer = 1, enabled = true}
end
if not gadgetHandler:IsSyncedCode() then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local cfg = VFS.Include("luarules/configs/betrayal.lua")
local operatives = getOperativeTypeTable(UnitDefs)
local safehouses = getSafeHouseTypeTable(UnitDefs)
local interrogatable = getInterrogateAbleTypeTable(UnitDefs)
local gaia = Spring.GetGaiaTeamID()
local runners, defectors, drops, pending, executions = {}, {}, {}, {}, {}
local roots, contacts, replacing = {}, {}, false
local walkingDef
for def in pairs(operatives) do if not walkingDef or def < walkingDef then walkingDef=def end end
local internalOrder = false
local public = {public = true}
local PRIVATE = {private = true}
local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function allied(a, b) return a and b and Spring.AreTeamsAllied(a, b) end
local function sortedKeys(t)
    local keys = {}; for id in pairs(t) do keys[#keys + 1] = id end
    table.sort(keys); return keys
end
local function distance(x,z,xx,zz) return math.sqrt((x-xx)^2+(z-zz)^2) end
local function order(id, cmd, params)
    internalOrder = true
    Spring.GiveOrderToUnit(id, cmd, params or {}, {})
    internalOrder = false
end
local function label(id, text) Spring.SetUnitTooltip(id, text) end
local function snapshot(id, team)
    local x,y,z = Spring.GetUnitPosition(id)
    local links = {}
    local parent = getParentOfUnit(team, id)
    if alive(parent) then links[parent] = true end
    for child in pairs(getChildrenOfUnit(team, id) or {}) do
        if alive(child) then links[child] = false end
    end
    return {team = team, sourceID = id, x = x or 0, y = y or 0, z = z or 0, links = links}
end
local function reveal(record, x,y,z)
    if record.disclosed then return end
    record.disclosed = true
    local loc = {teamID = record.team, x = x, y = y, z = z, radius = 40, revealedUnits = {},
        endFrame = Spring.GetGameFrame() + ((GG.GameConfig and GG.GameConfig.raid and
            GG.GameConfig.raid.revealGraphLifeTimeFrames) or cfg.revealFrames)}
    for id, isParent in pairs(record.links) do
        if alive(id) then
            local ux,uy,uz = Spring.GetUnitPosition(id)
            local defID = Spring.GetUnitDefID(id)
            loc.revealedUnits[id] = {pos = {x=ux,y=uy,z=uz}, defID = defID,
                boolIsParent = isParent, name = UnitDefs[defID].humanName or UnitDefs[defID].name}
        end
    end
    GG.RevealedLocations = GG.RevealedLocations or {}
    GG.RevealedLocations[#GG.RevealedLocations+1] = loc
end
local function expose(id)
    Spring.SetUnitCloak(id, false)
    Spring.SetUnitStealth(id, false)
    Spring.SetUnitAlwaysVisible(id, true)
    -- AlwaysVisible only affects drawing; LOS state also permits selection/targeting.
    for _, allyTeam in ipairs(Spring.GetAllyTeamList()) do
        Spring.SetUnitLosMask(id, allyTeam, 15)
        Spring.SetUnitLosState(id, allyTeam, 15)
    end
end
local function eligible(id, oldTeam, receivingTeam)
    if not alive(id) or runners[id] then return false end
    if Spring.GetUnitTransporter(id) then return false end
    local team, def = Spring.GetUnitTeam(id), Spring.GetUnitDefID(id)
    if team == gaia or allied(team, oldTeam) or (receivingTeam and not allied(team, receivingTeam)) then return false end
    if not operatives[def] and not safehouses[def] then return false end
    local hp,_,stun,_,built = Spring.GetUnitHealth(id)
    return hp and hp > 0 and (built or 1) >= 1 and (stun or 0) < hp
end
local function chooseRecipient(oldTeam, x,z, targetDistance, receivingTeam)
    local best, bestScore
    for _, id in ipairs(sortedKeys(contacts)) do
        if eligible(id, oldTeam, receivingTeam) then
            local ux,_,uz = Spring.GetUnitPosition(id)
            -- Prefer a field rendezvous; do not force the route to a secret base.
            local score = math.abs(distance(x,z,ux,uz)-targetDistance)
            if safehouses[Spring.GetUnitDefID(id)] then score = score + 300 end
            if not bestScore or score < bestScore or (score == bestScore and id < best) then
                best, bestScore = id, score
            end
        end
    end
    return best
end
local function groundPoint(x,z,defID)
    local margin = 64
    if x < margin or z < margin or x > Game.mapSizeX-margin or z > Game.mapSizeZ-margin then return end
    local y = Spring.GetGroundHeight(x,z)
    if y < 0 then return end
    if defID and not Spring.TestMoveOrder(defID,x,y,z,0,0,0,true,true,true) then return end
    return x,y,z
end
local function dropPoint(record)
    local recipient = chooseRecipient(record.team, record.x, record.z, cfg.minRunDistance)
    local x,z = Game.mapSizeX/2, Game.mapSizeZ/2
    if recipient then
        local rx,_,rz = Spring.GetUnitPosition(recipient)
        x,z = (record.x+rx)/2, (record.z+rz)/2
    end
    -- Fixed bounded search; no all-operative pair scan or random-house dependency.
    for ring=1,4 do
        for sector=0,11 do
            local angle = sector*math.pi/6
            local px,py,pz = groundPoint(x+math.cos(angle)*ring*160,z+math.sin(angle)*ring*160,walkingDef)
            if px and distance(px,pz,record.x,record.z) >= 300 then return px,py,pz end
        end
    end
    return math.max(64,math.min(Game.mapSizeX-64,x)), math.max(0,Spring.GetGroundHeight(x,z)),
        math.max(64,math.min(Game.mapSizeZ-64,z))
end
local function createDrop(record)
    if record.disclosed or record.dropID then return end
    local x,y,z = dropPoint(record)
    local id = Spring.CreateUnit("deaddropicon", x,y,z,0,gaia)
    if not id then
        -- Unit cap/spawn failure must never silently delete compromised evidence.
        reveal(record,x,y,z)
        return
    end
    record.dropID = id
    drops[id] = {record=record, expires=Spring.GetGameFrame()+cfg.dropLifetimeFrames}
    Spring.SetUnitRulesParam(id,"betrayal_drop",1,public)
    label(id,"Dead drop: operative contact reveals secrets; former allies can recover and suppress it")
    expose(id)
end
local function threatened(x,z, oldTeam)
    for _, id in ipairs(Spring.GetUnitsInCylinder(x,z,1800)) do
        if allied(Spring.GetUnitTeam(id),oldTeam) then
            local def = UnitDefs[Spring.GetUnitDefID(id)]
            local range = def and def.maxWeaponRange or 0
            if range > 0 then
                local ux,_,uz = Spring.GetUnitPosition(id)
                if distance(x,z,ux,uz) < range+150 then return true end
            end
        end
    end
    return false
end
local function escapePoint(id, recipient, targetDistance, oldTeam)
    local x,y,z = Spring.GetUnitPosition(id)
    local rx,_,rz = Spring.GetUnitPosition(recipient)
    local defID = Spring.GetUnitDefID(id)
    local best, score
    -- One escape only. Its distance is modest; travel time is a target, not a guarantee.
    for ring=1,2 do
        for sector=0,15 do
            local a = sector*math.pi/8
            local px,py,pz = groundPoint(x+math.cos(a)*cfg.escapeDistance*ring,
                z+math.sin(a)*cfg.escapeDistance*ring,defID)
            if px and not threatened(px,pz,oldTeam) then
                local cost = math.abs(distance(px,pz,rx,rz)-targetDistance)+ring*100
                if not score or cost < score then best,score = {px,py,pz},cost end
            end
        end
    end
    -- No safe ground: keep the physical escape risky. The dead drop protects the intel.
    return best or {x,y,z}
end
local function finishRunner(id, runner)
    local x,y,z = Spring.GetUnitPosition(id)
    reveal(runner.record,x,y,z)
    if alive(runner.contact) then registerChild(runner.team,runner.contact,id) end
    runners[id] = nil
    Spring.SetUnitRulesParam(id,"betrayal_runner",0,public)
    Spring.SetUnitRulesParam(id,"betrayal_delivered",1,public)
    label(id,"Defector: intelligence delivered; permanently exposed")
    order(id,CMD.STOP)
    order(id,CMD.FIRE_STATE,{1})
    -- The new employer may command them now. The blown identity never cloaks again.
end
local function defect(id, record)
    if not alive(id) or defectors[id] then return end
    local defID = Spring.GetUnitDefID(id)
    local speed = UnitDefs[defID].speed or 60
    local targetDistance = math.max(cfg.minRunDistance,math.min(cfg.maxRunDistance,speed*cfg.targetRunSeconds))
    local recipient = chooseRecipient(record.team,record.x,record.z,targetDistance)
    if not recipient then
        -- No enemy contact exists. Keep the witness exposed and retry without inventing one.
        pending[id] = record
        Spring.SetUnitRulesParam(id,"betrayal_pending",1,public)
        label(id,"DEFECTOR: exposed and awaiting an opposing contact")
        expose(id)
        return
    end
    local team = Spring.GetUnitTeam(recipient)
    local pos = escapePoint(id,recipient,targetDistance,record.team)
    local hp,_,paralyze = Spring.GetUnitHealth(id)
    local experience = Spring.GetUnitExperience(id)
    -- Scripts cache their team at creation. Recreate with the correct employer and
    -- preserve health/experience, but never inherit build, self-destruct or attack orders.
    replacing = true
    local newID = Spring.CreateUnit(defID,pos[1],pos[2],pos[3],Spring.GetUnitBuildFacing(id) or 0,team)
    replacing = false
    if not newID then
        createDrop(record)
        pending[id]=record
        Spring.SetUnitRulesParam(id,"betrayal_pending",1,public)
        label(id,"DEFECTOR: exposed and awaiting an opposing contact")
        expose(id)
        return
    end
    defectors[newID] = true
    runners[newID] = {record=record,team=team,recipient=recipient,started=Spring.GetGameFrame(),
        lastProgress=Spring.GetGameFrame(),lastX=pos[1],lastZ=pos[3]}
    Spring.SetUnitRulesParam(newID,"betrayal_defector",1,public)
    Spring.SetUnitRulesParam(newID,"betrayal_runner",1,public)
    Spring.SetUnitRulesParam(newID,"betrayal_origin_team",record.team,public)
    Spring.SetUnitRulesParam(newID,"betrayal_recipient",recipient,PRIVATE)
    Spring.SetUnitHealth(newID,{health=hp,paralyze=paralyze})
    Spring.SetUnitExperience(newID,experience or 0)
    expose(newID)
    label(newID,"DEFECTOR: reach a friendly operative or safehouse to deliver intelligence. Cannot cloak.")
    pending[id],executions[id] = nil,nil
    replacing = true
    Spring.DestroyUnit(id,false,true)
    replacing = false
    removeUnit(record.team,id)
    order(newID,CMD.FIRE_STATE,{0})
    order(newID,CMD.MOVE_STATE,{0})
    local tx,ty,tz = Spring.GetUnitPosition(recipient)
    order(newID,CMD.MOVE,{tx,ty,tz})
end
function gadget:UnitCreated(id,def,team,builder)
    if operatives[def] or safehouses[def] then contacts[id]=true end
    if replacing or team == gaia or not interrogatable[def] then return end
    if builder and alive(builder) then registerChild(team,builder,id); return end
    if operatives[def] and not roots[team] then
        roots[team]=id;registerParent(team,id);return
    end
    -- Stable fallback for script-spawned units. The graph stays parent/direct children.
    for _, other in ipairs(Spring.GetTeamUnits(team)) do
        local d = Spring.GetUnitDefID(other)
        if other~=id and ((operatives[def] and safehouses[d]) or (safehouses[def] and operatives[d])) then
            registerChild(team,other,id);return
        end
    end
    registerParent(team,id)
end
local function deliberateHit(id,team,attacker,attackerTeam)
    if not attacker or attacker==id or attackerTeam~=team then return false end
    local cmd,_,_,target = Spring.GetUnitCurrentCommand(attacker)
    return cmd==CMD.ATTACK and target==id
end
function gadget:UnitPreDamaged(id,def,team,damage,paralyzer,weapon,projectile,attacker,attackerDef,attackerTeam)
    if drops[id] then return 0 end
    if damage<=0 or paralyzer or replacing then return damage end
    if deliberateHit(id,team,attacker,attackerTeam) and interrogatable[def] and not defectors[id] then
        pending[id] = pending[id] or snapshot(id,team)
    end
    -- A safehouse can die through its containing neutral house's death script.
    local safe = GG.houseHasSafeHouseTable and GG.houseHasSafeHouseTable[id]
    if safe and alive(safe) and deliberateHit(id,attackerTeam,attacker,attackerTeam)
        and Spring.GetUnitTeam(safe)==attackerTeam then
        pending[safe] = pending[safe] or snapshot(safe,attackerTeam)
    end
    return damage
end
function gadget:AllowCommand(id,def,team,cmd,params)
    if internalOrder then return true end
    if runners[id] or (pending[id] and operatives[def]) then
        -- Players choose a rendezvous by moving their contact. The fleeing witness
        -- cannot be turned into a scout, transport passenger, builder or attacker.
        return false
    end
    if defectors[id] and (cmd==CMD.CLOAK or cmd==CMD.SELFD) then return false end
    if cmd==CMD.LOAD_UNITS and params and #params==1 and runners[params[1]] then return false end
    if cmd~=CMD.SELFD or team==gaia or not interrogatable[def] then return true end
    if executions[id] then
        executions[id]=nil
        Spring.SetUnitRulesParam(id,"betrayal_execution_frame",0,public)
        label(id,UnitDefs[def].humanName or UnitDefs[def].name)
    else
        local finish = Spring.GetGameFrame()+cfg.selfDestructFrames
        executions[id] = {frame=finish,record=snapshot(id,team)}
        Spring.SetUnitRulesParam(id,"betrayal_execution_frame",finish,public)
        label(id,"Termination ordered: betrayal in 5 seconds. Ctrl+D again cancels.")
    end
    return false
end
function gadget:AllowUnitCloak(id)
    return not defectors[id] and not pending[id]
end
function gadget:AllowUnitTransport(transporter,transporterDef,transporterTeam,id)
    return not runners[id]
end
function gadget:AllowUnitTransfer(id) return not runners[id] and not pending[id] and not executions[id] end
function gadget:UnitDestroyed(id,def,team,attacker,attackerDef,attackerTeam)
    contacts[id]=nil
    local runner = runners[id]
    if runner then createDrop(runner.record) end
    if not replacing and not runner and interrogatable[def] and team~=gaia then
        local record = pending[id] or (executions[id] and executions[id].record)
        if not record and attackerTeam==team then record=snapshot(id,team) end
        if record and not defectors[id] then createDrop(record) end
    end
    runners[id],defectors[id],pending[id],executions[id],drops[id]=nil,nil,nil,nil,nil
    if not replacing and interrogatable[def] then removeUnit(team,id) end
    -- Prevent a recycled unit ID from inheriting a dead contact's identity.
    for _, r in pairs(runners) do r.record.links[id]=nil end
    for _, d in pairs(drops) do d.record.links[id]=nil end
    for _, r in pairs(pending) do r.links[id]=nil end
    for _, e in pairs(executions) do e.record.links[id]=nil end
end
function gadget:GameFrame(frame)
    for _, id in ipairs(sortedKeys(executions)) do
        local execution=executions[id]
        if frame>=execution.frame then
            executions[id]=nil
            if alive(id) then
                execution.record=snapshot(id,Spring.GetUnitTeam(id))
                Spring.SetUnitRulesParam(id,"betrayal_execution_frame",0,public)
                if operatives[Spring.GetUnitDefID(id)] then
                    pending[id]=execution.record
                else
                    createDrop(execution.record)
                    replacing=true;Spring.DestroyUnit(id,true,false);replacing=false
                    removeUnit(execution.record.team,id)
                end
            end
        end
    end
    if frame % cfg.updateFrames ~= 0 then return end
    for _, id in ipairs(sortedKeys(pending)) do
        if alive(id) and operatives[Spring.GetUnitDefID(id)] then defect(id,pending[id]) end
    end
    for _, id in ipairs(sortedKeys(runners)) do
        local r=runners[id]
        if alive(id) then
            expose(id)
            local x,y,z=Spring.GetUnitPosition(id)
            local contact
            for _, other in ipairs(Spring.GetUnitsInCylinder(x,z,cfg.deliveryRadius)) do
                if other~=id and eligible(other,r.record.team,r.team) then contact=other;break end
            end
            if contact then
                if r.contact~=contact then
                    r.contact=contact;r.contactSince=frame;order(id,CMD.STOP)
                end
                if frame-r.contactSince>=cfg.deliveryFrames then finishRunner(id,r) end
            else
                r.contact,r.contactSince=nil,nil
                if not eligible(r.recipient,r.record.team,r.team) then
                    r.recipient=chooseRecipient(r.record.team,x,z,cfg.minRunDistance,r.team)
                end
                if r.recipient then
                    local tx,ty,tz=Spring.GetUnitPosition(r.recipient)
                    order(id,CMD.MOVE,{tx,ty,tz})
                end
                if distance(x,z,r.lastX,r.lastZ)>32 then
                    r.lastProgress,r.lastX,r.lastZ=frame,x,z
                elseif frame-r.lastProgress>cfg.stalledFrames then
                    -- Failed path / destroyed bridge: publish the backup, never teleport again.
                    createDrop(r.record)
                    r.lastProgress=frame
                end
            end
        end
    end
    for _, id in ipairs(sortedKeys(drops)) do
        local d=drops[id]
        if alive(id) then
            local x,y,z=Spring.GetUnitPosition(id)
            for _, other in ipairs(Spring.GetUnitsInCylinder(x,z,cfg.deliveryRadius)) do
                if alive(other) and operatives[Spring.GetUnitDefID(other)] and not runners[other]
                    and not Spring.GetUnitTransporter(other) and Spring.GetUnitTeam(other)~=gaia then
                    if not allied(Spring.GetUnitTeam(other),d.record.team) then reveal(d.record,x,y,z) end
                    drops[id]=nil;Spring.DestroyUnit(id,false,true);break
                end
            end
            if drops[id] and frame>=d.expires then drops[id]=nil;Spring.DestroyUnit(id,false,true) end
        else drops[id]=nil end
    end
end
function gadget:Initialize()
    initalizeInheritanceManagement()
    GG.OperativesDiscovered=GG.OperativesDiscovered or {}
    for _,id in ipairs(Spring.GetAllUnits()) do
        local def=Spring.GetUnitDefID(id)
        if operatives[def] or safehouses[def] then contacts[id]=true end
    end
    -- Public lifecycle tables also let other synced systems avoid commandeering runners.
    GG.BetrayalRunners,GG.BetrayalDefectors=runners,defectors
end
function gadget:Shutdown()
    GG.BetrayalRunners,GG.BetrayalDefectors=nil,nil
end
