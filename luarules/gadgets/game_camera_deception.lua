function gadget:GetInfo()
    return {
        name = "Camera Deception",
        desc = "Proximity-based false camera contacts, countered by ECM and temporary physical presence",
        author = "MOSAIC",
        layer = 0,
        enabled = true,
    }
end

local config = VFS.Include("scripts/lib_camera_deception.lua")
local cameraProfiles = {
    [UnitDefNames.spycam.id] = {range = UnitDefs[UnitDefNames.spycam.id].losRadius},
}
local sourceDefID = UnitDefNames.icon_cameradeception.id
local ecmDefID = UnitDefNames.icon_emc.id
local teamParam = "camera_deception_team"
local suppressedParam = "camera_deception_suppressed"
local function cameraProfile(id, defID)
    local profile = cameraProfiles[defID]
    if profile and not profile.eye then
        local pieces = Spring.GetUnitPieceMap(id)
        profile.eye = pieces and pieces.Eye
    end
    return profile
end

if gadgetHandler:IsSyncedCode() then
    local sources, cameras, affected = {}, {}, {}
    local allied = {allied = true}
    local gaiaTeam = Spring.GetGaiaTeamID()
    local physicalTypes = {}
    for defID, def in pairs(UnitDefs) do
        local cp, categories = def.customParams or {}, def.modCategories or {}
        if cp.baseclass ~= "Abstract" and not categories.abstract and not categories.notarget then
            physicalTypes[defID] = true
        end
    end

    local function operational(id)
        local stunned, _, inBuild = Spring.GetUnitIsStunned(id)
        return not stunned and not inBuild
    end

    local function setFeed(id, team, suppressed)
        local old = affected[id]
        if not old or old.team ~= team then
            Spring.SetUnitRulesParam(id, teamParam, team, allied)
        end
        if not old or old.suppressed ~= suppressed then
            Spring.SetUnitRulesParam(id, suppressedParam, suppressed and 1 or 0, allied)
        end
        if old then
            old.team, old.suppressed = team, suppressed
        else
            affected[id] = {team = team, suppressed = suppressed}
        end
    end

    local function clearFeed(id)
        if not affected[id] then return end
        affected[id] = nil
        Spring.SetUnitRulesParam(id, teamParam, -1, allied)
        Spring.SetUnitRulesParam(id, suppressedParam, 0, allied)
    end

    function gadget:UnitCreated(id, defID)
        if defID == sourceDefID then sources[id] = true end
        local profile = cameraProfile(id, defID)
        if profile then
            cameras[id] = profile
            SendToUnsynced("camera_deception_add", id)
        end
    end

    function gadget:UnitDestroyed(id)
        sources[id], affected[id] = nil, nil
        if cameras[id] then
            cameras[id] = nil
            SendToUnsynced("camera_deception_remove", id)
        end
        -- The next bounded update removes feeds with no nearby carrier.
    end

    function gadget:Initialize()
        for _, id in ipairs(Spring.GetAllUnits()) do
            self:UnitCreated(id, Spring.GetUnitDefID(id))
            if cameras[id] then
                local team = Spring.GetUnitRulesParam(id, teamParam)
                if team and team >= 0 then
                    affected[id] = {team = team,
                        suppressed = Spring.GetUnitRulesParam(id, suppressedParam) == 1}
                end
            end
        end
    end

    function gadget:GameFrame(frame)
        if frame % config.updateFrames ~= 0 then return end
        local candidates = {}
        -- Engine spatial index, bounded radius; never scan every unit per source.
        for sourceID in pairs(sources) do
            if operational(sourceID) then
                local x, _, z = Spring.GetUnitPosition(sourceID)
                local team = Spring.GetUnitTeam(sourceID)
                for _, id in ipairs(Spring.GetUnitsInCylinder(x, z, config.broadcastRange)) do
                    if cameras[id] and operational(id)
                        and not Spring.AreTeamsAllied(team, Spring.GetUnitTeam(id)) then
                        -- Stable winner when multiple carriers reach a camera together.
                        if not candidates[id] or sourceID < candidates[id].source then
                            candidates[id] = {source = sourceID, team = team}
                        end
                    end
                end
            end
        end
        -- Rebuild coverage from live carriers. Departed, destroyed, captured or
        -- disabled sources cannot leave active feeds behind. Uncovered cameras
        -- need no further spatial queries.
        for id in pairs(affected) do
            if not candidates[id] then clearFeed(id) end
        end
        for id, candidate in pairs(candidates) do
            local team = candidate.team
            local x, y, z = Spring.GetUnitPosition(id)
            local range = cameras[id].range
            local fx, fz = config.Direction(id, cameras[id].eye)
            local cleanse, suppressed = false, false
            -- One local query covers both ECM and physical verification.
            local nearby = Spring.GetUnitsInCylinder(x, z, math.max(range, config.countermeasureRange))
            for _, otherID in ipairs(nearby) do
                if otherID ~= id then
                    local otherTeam = Spring.GetUnitTeam(otherID)
                    if otherTeam ~= gaiaTeam and not Spring.AreTeamsAllied(team, otherTeam) then
                        local defID = Spring.GetUnitDefID(otherID)
                        local ox, oy, oz = Spring.GetUnitPosition(otherID)
                        local dx, dz = ox - x, oz - z
                        if defID == ecmDefID and operational(otherID)
                            and dx * dx + dz * dz <= config.countermeasureRange^2 then
                            cleanse = true
                            break
                        end
                        if physicalTypes[defID] and config.InCone(dx, dz, fx, fz, range, oy - y) then
                            suppressed = true
                        end
                    end
                end
            end
            if cleanse then clearFeed(id)
            else setFeed(id, team, suppressed) end
        end
    end
else
    local cameras, active = {}, {}
    local contactDefID = UnitDefNames.ground_walker_mg.id
    local function addCamera(_, id)
        cameras[id] = cameraProfile(id, Spring.GetUnitDefID(id))
    end
    local function removeCamera(_, id) cameras[id], active[id] = nil, nil end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("camera_deception_add", addCamera)
        gadgetHandler:AddSyncAction("camera_deception_remove", removeCamera)
        for _, id in ipairs(Spring.GetAllUnits()) do
            addCamera(nil, id)
        end
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("camera_deception_add")
        gadgetHandler:RemoveSyncAction("camera_deception_remove")
    end

    function gadget:GameFrame(frame)
        if frame % config.updateFrames ~= 0 then return end
        for id in pairs(cameras) do
            local team = Spring.GetUnitRulesParam(id, teamParam)
            if team and team >= 0 and Spring.GetUnitRulesParam(id, suppressedParam) == 0 then
                active[id] = team
            else active[id] = nil end
        end
    end

    function gadget:DrawWorld()
        local frame = Spring.GetGameFrame() + Spring.GetFrameTimeOffset()
        local _, fullView = Spring.GetSpectatingState()
        local myTeam = Spring.GetMyTeamID()
        gl.DepthTest(true)
        gl.Color(1, 1, 1, 1)
        for id, team in pairs(active) do
            local cameraTeam = Spring.GetUnitTeam(id)
            -- Recheck ownership live: cached contacts must not leak after a team switch.
            if cameraTeam and (fullView or Spring.AreTeamsAllied(myTeam, cameraTeam))
                and not Spring.AreTeamsAllied(team, cameraTeam)
                and Spring.GetUnitRulesParam(id, teamParam) == team
                and Spring.GetUnitRulesParam(id, suppressedParam) == 0 then
                local x, y, z = Spring.GetUnitPosition(id)
                local range = cameras[id].range
                if x and Spring.IsSphereInView(x, y, z, range) then
                    local fx, fz = config.Direction(id, cameras[id].eye)
                    for index = 1, config.contactCount do
                        local dx, dz = config.Contact(id, index, frame, range, fx, fz)
                        local px, pz = x + dx, z + dz
                        if px >= 0 and pz >= 0 and px <= Game.mapSizeX and pz <= Game.mapSizeZ then
                            local py = Spring.GetGroundHeight(px, pz)
                            if Spring.IsPosInLos(px, py, pz) then
                                gl.PushMatrix()
                                gl.Translate(px, py, pz)
                                gl.Rotate(math.deg(math.atan2(fx, fz)), 0, 1, 0)
                                gl.UnitShape(contactDefID, team, false, false, false)
                                gl.PopMatrix()
                            end
                        end
                    end
                end
            end
        end
        gl.DepthTest(false)
    end
end
