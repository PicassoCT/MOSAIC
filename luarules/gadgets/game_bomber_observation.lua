function gadget:GetInfo()
    return {name = "Bomber observation", desc = "Surveillance flags disguised and exposed bombers",
        author = "MOSAIC", license = "GPL3", layer = 1, enabled = true}
end

if not gadgetHandler:IsSyncedCode() then return end

VFS.Include("scripts/lib_mosaic.lua")
local cone = VFS.Include("scripts/lib_camera_deception.lua")
local bomberTypes = getSuicideBombermanTypeTable(UnitDefs)
local config = getGameConfig()
local namedProfiles = {
    spycam = {cone = true},
    satellitescan = {orbital = true},
    checkpoint = {range = config.police.checkpoints.revealRange},
}
local observerTypes = {}
for defID, def in pairs(UnitDefs) do
    local categories = def.modCategories or {}
    if namedProfiles[def.name] then
        observerTypes[defID] = namedProfiles[def.name]
    elseif categories.surveilance or categories.surveillance then
        observerTypes[defID] = {}
    end
end

local observers, bombers = {}, {}
local paramPrefix = "bomber_observed_"
local visibility = {inlos = true}
local gaia = Spring.GetGaiaTeamID()

local function alive(id)
    return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
end

local function flag(id, allyTeam, value)
    if alive(id) then
        Spring.SetUnitRulesParam(id, paramPrefix .. allyTeam, value, visibility)
    end
end

function gadget:UnitCreated(id, defID)
    if observerTypes[defID] then observers[id] = observerTypes[defID] end
    if bomberTypes[defID] then bombers[id] = {allies = {}, body = id} end
end

function gadget:UnitDestroyed(id)
    observers[id] = nil
    local record = bombers[id]
    if record then
        for allyTeam in pairs(record.allies) do flag(record.body, allyTeam, 0) end
        bombers[id] = nil
    end
end

function gadget:Initialize()
    local allyTeams = Spring.GetAllyTeamList()
    for _, id in ipairs(Spring.GetAllUnits()) do
        self:UnitCreated(id, Spring.GetUnitDefID(id))
        local record = bombers[id]
        if record then
            for _, allyTeam in ipairs(allyTeams) do
                if Spring.GetUnitRulesParam(id, paramPrefix .. allyTeam) == 1 then
                    record.allies[allyTeam] = true
                end
            end
        end
    end
end

function gadget:GameFrame(frame)
    if frame % cone.updateFrames ~= 0 or not next(bombers) then return end

    -- The civilian cover is a separate Gaia unit; remember the real bomber so
    -- shedding that cover cannot erase an earlier surveillance identification.
    local bodies = {}
    for body, bomber in pairs(GG.DisguiseCivilianFor or {}) do
        if bombers[bomber] and alive(body) and Spring.GetUnitIsCloaked(bomber) then
            bodies[bomber] = body
        end
    end
    for id, record in pairs(bombers) do
        local body = bodies[id] or id
        if body ~= record.body then
            for allyTeam in pairs(record.allies) do
                if record.body ~= id then flag(record.body, allyTeam, 0) end
                flag(body, allyTeam, 1)
            end
            record.body = body
        end
    end

    for observer, profile in pairs(observers) do
        local stunned, _, inBuild = Spring.GetUnitIsStunned(observer)
        local def = UnitDefs[Spring.GetUnitDefID(observer)]
        local team = Spring.GetUnitTeam(observer)
        if team ~= gaia and not stunned and not inBuild
            and (not def.onOffable or Spring.GetUnitIsActive(observer))
            and (not profile.orbital or Spring.GetUnitRulesParam(observer, "orbital_state") == 1) then
            local range = profile.range or Spring.GetUnitSensorRadius(observer, "los")
            local x, y, z = Spring.GetUnitPosition(observer)
            local allyTeam = Spring.GetUnitAllyTeam(observer)
            if x and range and range > 0 then
                local fx, fz
                if profile.cone then
                    local pieces = Spring.GetUnitPieceMap(observer)
                    fx, fz = cone.Direction(observer, pieces and pieces.Eye)
                end
                local disguises = GG.DisguiseCivilianFor or {}
                for _, candidate in ipairs(Spring.GetUnitsInCylinder(x, z, range)) do
                    local id = disguises[candidate] or candidate
                    local record = bombers[id]
                    if record and not record.allies[allyTeam]
                        and not Spring.AreTeamsAllied(team, Spring.GetUnitTeam(id)) then
                        local tx, ty, tz = Spring.GetUnitPosition(record.body)
                        local dx, dz = tx and tx - x, tz and tz - z
                        if tx and dx * dx + dz * dz <= range * range
                            and (not profile.cone or cone.InCone(dx, dz, fx, fz, range, ty - y))
                            and Spring.IsPosInLos(tx, ty, tz, allyTeam) then
                            record.allies[allyTeam] = true
                            flag(id, allyTeam, 1)
                            if record.body ~= id then flag(record.body, allyTeam, 1) end
                        end
                    end
                end
            end
        end
    end
end
