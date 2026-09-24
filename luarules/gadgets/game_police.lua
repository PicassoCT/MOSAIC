function gadget:GetInfo()
    return {name="Game_Police",desc="Delayed incident response and fallible police searches",
        author="Picasso, Mosaic contributors",license="GPL3",layer=3,enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return end
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

local config = getGameConfig()
local cfg = config.Police
local gaia = Spring.GetGaiaTeamID()
local ally = Spring.GetTeamAllyTeamID(gaia)
local policeTypes = getPoliceTypes(UnitDefs)
local responseTypes = getPoliceTypes(UnitDefs)
local safehouseTypes = getSafeHouseTypeTable(UnitDefs)
local cyberDef = UnitDefNames.icon_cybercrime.id
local civilians = getMobileCivilianDefIDTypeTable(UnitDefs)
local walking = getCultureUnitModelTypes(config.instance.culture,"civilian",UnitDefs)
local trucks = getCultureUnitModelTypes(config.instance.culture,"truck",UnitDefs)
local houses = getCultureUnitModelTypes(config.instance.culture,"house",UnitDefs)
local scraps = getScrapheapTypeTable(UnitDefs)
local incidents, officers = {}, {}
local revealedSafehouses = {}
local bribery
local damageToPolice = 0
local reportDelay = cfg.reportDelayFrames or 240
local escapeTime = cfg.escapeFrames or 900
local searchTime = cfg.searchFrames or 1350
local sightRange = cfg.sightRange or 650
local searchRadius = cfg.searchRadius or 600
GG.PoliceInPursuit = GG.PoliceInPursuit or {}
GG.PoliceExposureUntil = GG.PoliceExposureUntil or {}

local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end
local function position(id)
    if not alive(id) then return end
    local x,y,z = Spring.GetUnitPosition(id)
    if x then return {x=x,y=y,z=z} end
end
local function move(id,p)
    Spring.GiveOrderToUnit(id,CMD.MOVE,{p.x,Spring.GetGroundHeight(p.x,p.z),p.z},{})
end
local function expose(id,frame)
    if alive(id) then GG.PoliceExposureUntil[id] = frame+escapeTime end
end
local function canSee(officer, target)
    local p,t = position(officer),position(target)
    local los = t and Spring.GetUnitLosState(target,ally)
    return p and t and not Spring.GetUnitIsCloaked(target) and
        (p.x-t.x)^2+(p.z-t.z)^2 <= sightRange^2 and los and los.los
end
bribery = VFS.Include("luarules/gadgets/include/police_bribery.lua").New(config, officers, position, move, canSee)
for defID in pairs(bribery.types) do policeTypes[defID] = true end

local function revealSafehouses(incidentUnit, frame)
    local p = position(incidentUnit)
    if not p then return end
    for _, id in ipairs(Spring.GetUnitsInCylinder(p.x,p.z,config.Bribe.safehouseRevealRange)) do
        if safehouseTypes[Spring.GetUnitDefID(id)] then
            local previous = revealedSafehouses[id]
            local states = Spring.GetUnitStates(id) or {}
            revealedSafehouses[id] = {untilFrame = frame+config.Bribe.safehouseRevealFrames,
                restore = previous and previous.restore or states.cloak == true or states.cloak == 1}
            Spring.SetUnitCloak(id,false)
        end
    end
end
local function report(victim,attacker)
    local p = position(victim)
    if not p or not alive(attacker) then return end
    local frame = Spring.GetGameFrame()
    local incident = incidents[attacker]
    if not incident then
        incident = {attacker=attacker,due=frame+reportDelay}
        incidents[attacker] = incident
    end
    -- The caller reports the victim's location, not the shooter's live coordinates.
    incident.location,incident.expires = p,frame+reportDelay+searchTime
    incident.kind = "violence"
    expose(attacker,frame)
    bribery.Witness(attacker)
    GG.PoliceActionSoundInterVallStartFrame = frame
end

local function spawnLocation(p)
    local candidates = {}
    for id,data in pairs(GG.BuildingTable or {}) do
        if alive(id) and (data.x-p.x)^2+(data.z-p.z)^2 >= cfg.minSpawnDistance^2 then
            candidates[#candidates+1] = id
        end
    end
    table.sort(candidates,function(a,b)
        local pa,pb = GG.BuildingTable[a],GG.BuildingTable[b]
        local da,db = (pa.x-p.x)^2+(pa.z-p.z)^2,(pb.x-p.x)^2+(pb.z-p.z)^2
        return da < db or (da == db and a < b)
    end)
    for _,id in ipairs(candidates) do
        local b = GG.BuildingTable[id]
        local r = (Spring.GetUnitRadius(id) or 100)+80
        for side=0,7 do
            local angle = side*math.pi/4
            local x,z = b.x+math.cos(angle)*r,b.z+math.sin(angle)*r
            if x>0 and z>0 and x<Game.mapSizeX and z<Game.mapSizeZ then
                local y = Spring.GetGroundHeight(x,z)
                if Spring.TestMoveOrder(UnitDefNames.policetruck.id,x,y,z) then
                    return x,y,z
                end
            end
        end
    end
end

local function dispatch(incident,frame)
    local officer, count = nil,0
    for id,state in pairs(officers) do
        count=count+1
        if not state.incident and not GG.PoliceBribes[id] and alive(id) and
            (not officer or id<officer) then officer=id end
    end
    if not officer and count < cfg.maxNr then
        local x,y,z = spawnLocation(incident.location)
        if x then
            local name = "policetruck"
            if damageToPolice > 2500 or config.GameState.anarchy == GG.GlobalGameState or
                config.GameState.pacification == GG.GlobalGameState then
                local choices = {}
                for defID in pairs(responseTypes) do choices[#choices+1]=defID end
                table.sort(choices)
                if #choices>0 then name=UnitDefs[choices[math.random(#choices)]].name end
                damageToPolice=math.max(0,damageToPolice-2500)
            end
            -- Creation here returns the exact officer for this incident.
            officer=Spring.CreateUnit(name,x,y,z,0,gaia)
        end
    end
    if not officer then return false end
    officers[officer] = {incident=incident,nextOrder=frame+90,expires=frame+cfg.maxDispatchTime}
    incident.officer=officer
    GG.PoliceInPursuit[officer]=incident.attacker
    move(officer,incident.location)
    return true
end

local function releaseOfficer(id,frame)
    local state=officers[id]
    if state and state.incident then state.incident.officer=nil end
    GG.PoliceInPursuit[id]=nil
    if state then
        state.incident=nil
        state.expires=frame+cfg.maxDispatchTime
        if not GG.PoliceBribes[id] then Spring.GiveOrderToUnit(id,CMD.STOP,{}, {}) end
    end
end

local function cancelCyberCrime(id)
    local incident = incidents[id]
    if incident and incident.kind == "cybercrime" then
        if incident.officer then releaseOfficer(incident.officer,Spring.GetGameFrame()) end
        incidents[id] = nil
    end
end
local function reportCyberCrime(id, building, due)
    local p = position(building)
    if not p or not alive(id) then return end
    incidents[id] = {attacker=id,location=p,due=due,kind="cybercrime",
        expires=Spring.GetGameFrame()+config.CyberCrime.durationFrames+searchTime}
end

function gadget:UnitFinished(id,defID,team)
    bribery.Finished(id,defID,team)
end
function gadget:AllowCommand(id,defID,team,command,params)
    if revealedSafehouses[id] and command==CMD.CLOAK then
        revealedSafehouses[id].restore=params[1]~=0
    end
    return bribery.Command(id,defID,team,command,params)
end
function gadget:AllowWeaponTarget(id,target,weaponNum,weaponDef,priority)
    return bribery.AllowWeaponTarget(id,target),priority
end
function gadget:AllowUnitCloak(id)
    local exposure = revealedSafehouses[id]
    return not exposure or Spring.GetGameFrame() >= exposure.untilFrame
end
function gadget:UnitTaken(id,defID)
    bribery.Destroyed(id)
    if defID == UnitDefNames.icon_bribe.id and alive(id) then Spring.DestroyUnit(id,false,true) end
    if officers[id] then
        releaseOfficer(id,Spring.GetGameFrame())
        officers[id] = nil
    end
end

function gadget:UnitCreated(id,defID,team,builder)
    bribery.Created(id,defID,builder)
    if policeTypes[defID] and Spring.GetUnitTeam(id)==gaia then
        officers[id]={expires=Spring.GetGameFrame()+cfg.maxDispatchTime}
        Spring.SetUnitNeutral(id,false)
    end
    -- Cybercrime reports only after completion, at its building, with a slow response.
    if defID ~= cyberDef and isOffenceIcon(UnitDefs,defID) then report(id,id) end
    if scraps[defID] then
        local x,_,z=Spring.GetUnitPosition(id)
        if x then registerEmergency(x,z) end
    end
end
function gadget:UnitDestroyed(id,defID)
    bribery.Destroyed(id)
    if officers[id] then
        local incident=officers[id].incident
        if incident then incident.officer=nil end
        officers[id]=nil
        GG.PoliceInPursuit[id]=nil
        damageToPolice=damageToPolice+500
    end
    if incidents[id] and incidents[id].officer then
        releaseOfficer(incidents[id].officer,Spring.GetGameFrame())
    end
    incidents[id]=nil
    revealedSafehouses[id]=nil
    GG.PoliceExposureUntil[id]=nil
    if walking[defID] then
        local x,_,z=Spring.GetUnitPosition(id)
        if x then registerEmergency(x,z) end
    end
end
function gadget:UnitDamaged(id,defID,team,damage,paralyzer,weaponID,projectileID,attacker,attackerDef,attackerTeam)
    bribery.Damaged(id,attacker,damage)
    if damage>0 and not paralyzer and weaponID~=WeaponDefNames.closecombat.id and
        (officers[id] or officers[attacker]) then
        revealSafehouses(id,Spring.GetGameFrame())
    end
    if not attackerTeam or attackerTeam==gaia or damage<=0 or paralyzer then return end
    -- Silent stabbing remains outside the gunfire/report mechanism.
    if weaponID==WeaponDefNames.closecombat.id then return end
    if civilians[defID] or trucks[defID] or houses[defID] or policeTypes[defID] then
        report(id,attacker)
    end
end
function gadget:Initialize()
    GG.ReportCyberCrime = reportCyberCrime
    GG.CancelCyberCrimeReport = cancelCyberCrime
    GG.PoliceActionSoundInterVallStartFrame=Spring.GetGameFrame()
    for _,id in ipairs(Spring.GetAllUnits()) do
        if policeTypes[Spring.GetUnitDefID(id)] then self:UnitCreated(id,Spring.GetUnitDefID(id)) end
        local _,_,_,_,progress=Spring.GetUnitHealth(id)
        if progress and progress>=1 then self:UnitFinished(id,Spring.GetUnitDefID(id),Spring.GetUnitTeam(id)) end
    end
end
function gadget:GameFrame(frame)
    if frame%15~=0 then return end
    bribery.Update(frame)
    for attacker,incident in pairs(incidents) do
        if not alive(attacker) or frame>=incident.expires then
            if incident.officer then releaseOfficer(incident.officer,frame) end
            incidents[attacker]=nil
        elseif not incident.officer and frame>=incident.due then
            if not dispatch(incident,frame) then incident.due=frame+90 end
        end
    end
    for id,state in pairs(officers) do
        local incident=state.incident
        if GG.PoliceBribes[id] then
            -- Movement and target suppression are owned by the active bribe.
        elseif incident and incident.kind=="cybercrime" then
            local p=position(id)
            if p and (p.x-incident.location.x)^2+(p.z-incident.location.z)^2 <= config.CyberCrime.policeInterruptRange^2 then
                if GG.CyberCrime then GG.CyberCrime.Stop(incident.attacker) end
            elseif p and frame>=state.nextOrder then
                move(id,incident.location)
                state.nextOrder=frame+90
            end
        elseif incident then
            local p,target=position(id),position(incident.attacker)
            local los=target and Spring.GetUnitLosState(incident.attacker,ally)
            local visible=p and target and not Spring.GetUnitIsCloaked(incident.attacker) and
                (p.x-target.x)^2+(p.z-target.z)^2 <= sightRange^2 and los and los.los
            if visible then
                expose(incident.attacker,frame)
                incident.expires=frame+searchTime
                state.lastSeen={x=target.x,y=target.y,z=target.z}
                if frame>=state.nextOrder then
                    Spring.GiveOrderToUnit(id,CMD.ATTACK,{incident.attacker},{})
                    state.nextOrder=frame+90
                end
                state.wasVisible=true
            elseif p and frame>=state.nextOrder then
                local goal=state.lastSeen or incident.location
                local d=(p.x-goal.x)^2+(p.z-goal.z)^2
                if d<180^2 then state.searching=true end
                if state.searching then
                    local angle=math.random()*2*math.pi
                    local r=math.random(100,searchRadius)
                    move(id,{x=math.max(1,math.min(Game.mapSizeX-1,goal.x+math.cos(angle)*r)),
                        z=math.max(1,math.min(Game.mapSizeZ-1,goal.z+math.sin(angle)*r))})
                else move(id,goal) end
                state.nextOrder=frame+150
                state.wasVisible=false
            end
        elseif frame>=state.expires then
            Spring.DestroyUnit(id,false,true)
        end
    end
    for id,untilFrame in pairs(GG.PoliceExposureUntil) do
        if frame>=untilFrame or not alive(id) then GG.PoliceExposureUntil[id]=nil end
    end
    for id,exposure in pairs(revealedSafehouses) do
        if frame>=exposure.untilFrame or not alive(id) then
            revealedSafehouses[id]=nil
            if alive(id) and exposure.restore then Spring.SetUnitCloak(id,true) end
        end
    end
end

function gadget:Shutdown()
    GG.ReportCyberCrime,GG.CancelCyberCrimeReport=nil,nil
    GG.PoliceBribes=nil
end
