function gadget:GetInfo()
    return {
        name = "Building Shadow Volumes",
        desc = "Caches collision volumes for radiance-cascade occlusion",
        author = "Picasso, Codex",
        date = "2026",
        license = "GNU GPL, v2 or later",
        layer = -10,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then
    return
end

local shadowVolumes = {}
local pendingUnits = {}
local dirty = true

local function throwsShadow(unitDefID)
    local unitDef = UnitDefs[unitDefID]
    local params = unitDef and unitDef.customParams
    local value = params and (params.throwsshadow or params.throwsShadow)
    return value == true or value == 1 or value == "1" or value == "true"
end

local function addVolume(volumes, x, y, z, heading, sx, sy, sz,
        ox, oy, oz, volumeType, primaryAxis, disabled)
    if not sx or disabled then
        return
    end

    volumes[#volumes + 1] = {
        x = x + (ox or 0),
        y = y + (oy or 0),
        z = z + (oz or 0),
        heading = heading or 0,
        sx = sx,
        sy = sy,
        sz = sz,
        volumeType = volumeType or 2,
        primaryAxis = primaryAxis or 1,
    }
end

local function rebuildUnit(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    if not unitDefID or not throwsShadow(unitDefID) then
        shadowVolumes[unitID] = nil
        return
    end

    local volumes = {}
    local heading = Spring.GetUnitHeading(unitID) or 0
    local pieceMap = Spring.GetUnitPieceMap(unitID) or {}

    for _, pieceID in pairs(pieceMap) do
        local sx, sy, sz, ox, oy, oz, volumeType, _, primaryAxis, disabled =
            Spring.GetUnitPieceCollisionVolumeData(unitID, pieceID)

        if sx and not disabled then
            local x, y, z = Spring.GetUnitPiecePosDir(unitID, pieceID)
            if x then
                addVolume(
                    volumes, x, y, z, heading,
                    sx, sy, sz, ox, oy, oz,
                    volumeType, primaryAxis, disabled
                )
            end
        end
    end

    if #volumes == 0 then
        local x, y, z = Spring.GetUnitBasePosition(unitID)
        local sx, sy, sz, ox, oy, oz, volumeType, _, primaryAxis, disabled =
            Spring.GetUnitCollisionVolumeData(unitID)

        if x then
            addVolume(
                volumes, x, y, z, heading,
                sx, sy, sz, ox, oy, oz,
                volumeType, primaryAxis, disabled
            )
        end
    end

    shadowVolumes[unitID] = volumes
end

local function markDirty(unitID)
    if Spring.ValidUnitID(unitID) then
        pendingUnits[unitID] = true
    else
        shadowVolumes[unitID] = nil
    end
    dirty = true
end

function gadget:Initialize()
    GG.BuildingShadowVolume = shadowVolumes
    GG.MarkBuildingShadowVolumeDirty = markDirty

    local allUnits = Spring.GetAllUnits()
    for i = 1, #allUnits do
        pendingUnits[allUnits[i]] = true
    end
end

function gadget:UnitCreated(unitID)
    markDirty(unitID)
end

function gadget:UnitFinished(unitID)
    markDirty(unitID)
end

function gadget:UnitDestroyed(unitID)
    pendingUnits[unitID] = nil
    shadowVolumes[unitID] = nil
    dirty = true
end

function gadget:GameFrame()
    if not dirty then
        return
    end

    for unitID in pairs(pendingUnits) do
        rebuildUnit(unitID)
        pendingUnits[unitID] = nil
    end

    if Script.LuaUI("ReceiveBuildingShadowVolumes") then
        Script.LuaUI.ReceiveBuildingShadowVolumes(shadowVolumes)
        dirty = false
    end
end

function gadget:Shutdown()
    GG.BuildingShadowVolume = nil
    GG.MarkBuildingShadowVolumeDirty = nil
end
