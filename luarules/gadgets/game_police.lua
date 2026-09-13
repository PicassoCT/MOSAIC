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
local civilians = getMobileCivilianDefIDTypeTable(UnitDefs)
local walking = getCultureUnitModelTypes(config.instance.culture,"civilian",UnitDefs)
local trucks = getCultureUnitModelTypes(config.instance.culture,"truck",UnitDefs)
local houses = getCultureUnitModelTypes(config.instance.culture,"house",UnitDefs)
local scraps = getScrapheapTypeTable(UnitDefs)
local incidents, officers = {}, {}
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
    expose(attacker,frame)
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
        if not state.incident and alive(id) and (not officer or id<officer) then officer=id end
    end
    if not officer and count < cfg.maxNr then
        local x,y,z = spawnLocation(incident.location)
        if x then
            local name = "policetruck"
            if damageToPolice > 2500 or config.GameState.anarchy == GG.GlobalGameState or
                config.GameState.pacification == GG.GlobalGameState then
                local choices = {}
                for defID in pairs(policeTypes) do choices[#choices+1]=defID end
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
        Spring.GiveOrderToUnit(id,CMD.STOP,{}, {})
    end
end

function gadget:UnitCreated(id,defID)
    if policeTypes[defID] then
        officers[id]={expires=Spring.GetGameFrame()+cfg.maxDispatchTime}
        Spring.SetUnitNeutral(id,false)
    end
    if isOffenceIcon(UnitDefs,defID) then report(id,id) end
    if scraps[defID] then
        local x,_,z=Spring.GetUnitPosition(id)
        if x then registerEmergency(x,z) end
    end
end
function gadget:UnitDestroyed(id,defID)
    if officers[id] then
        local incident=officers[id].incident
        if incident then incident.officer=nil end
        officers[id]=nil
        GG.PoliceInPursuit[id]=nil
        damageToPolice=damageToPolice+500
    end
    incidents[id]=nil
    GG.PoliceExposureUntil[id]=nil
    if walking[defID] then
        local x,_,z=Spring.GetUnitPosition(id)
        if x then registerEmergency(x,z) end
    end
end
function gadget:UnitDamaged(id,defID,team,damage,paralyzer,weaponID,projectileID,attacker,attackerDef,attackerTeam)
    if not attackerTeam or attackerTeam==gaia or damage<=0 or paralyzer then return end
    -- Silent stabbing remains outside the gunfire/report mechanism.
    if weaponID==WeaponDefNames.closecombat.id then return end
    if civilians[defID] or trucks[defID] or houses[defID] or policeTypes[defID] then
        report(id,attacker)
    end
end
function gadget:Initialize()
    GG.PoliceActionSoundInterVallStartFrame=Spring.GetGameFrame()
    for _,id in ipairs(Spring.GetAllUnits()) do
        if policeTypes[Spring.GetUnitDefID(id)] then self:UnitCreated(id,Spring.GetUnitDefID(id)) end
    end
end
function gadget:GameFrame(frame)
    if frame%15~=0 then return end
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
        if incident then
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
end
