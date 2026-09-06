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

if gadgetHandler:IsSyncedCode() then
    local MAX_VOLUMES_PER_UNIT = 128
    local shadowVolumes = {}
    local pendingUnits = {}

    local function throwsShadow(unitDefID)
        local unitDef = UnitDefs[unitDefID]
        local params = unitDef and unitDef.customParams
        local value = params and (params.throwsshadow or params.throwsShadow)
        return value == true or value == 1 or value == "1" or value == "true"
    end

    local function sendVolume(unitID, volumes, x, y, z, heading, sx, sy, sz,
            ox, oy, oz, volumeType, primaryAxis, disabled)
        if not sx or disabled then
            return
        end

        local volume = {
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
        volumes[#volumes + 1] = volume

        SendToUnsynced(
            "buildingShadowVolumeAdd",
            unitID,
            volume.x, volume.y, volume.z, volume.heading,
            volume.sx, volume.sy, volume.sz,
            volume.volumeType, volume.primaryAxis
        )
    end

    local function rebuildUnit(unitID)
        local unitDefID = Spring.GetUnitDefID(unitID)
        if not unitDefID or not throwsShadow(unitDefID) then
            if shadowVolumes[unitID] then
                shadowVolumes[unitID] = nil
                SendToUnsynced("buildingShadowVolumeRemove", unitID)
            end
            return
        end

        local volumes = {}
        local heading = Spring.GetUnitHeading(unitID) or 0
        local pieceMap = Spring.GetUnitPieceMap(unitID) or {}
        SendToUnsynced("buildingShadowVolumeBegin", unitID)

        for _, pieceID in pairs(pieceMap) do
            if #volumes >= MAX_VOLUMES_PER_UNIT then
                Spring.Echo(
                    "Building Shadow Volumes: capped unit " ..
                    unitID .. " at " .. MAX_VOLUMES_PER_UNIT .. " volumes"
                )
                break
            end

            local sx, sy, sz, ox, oy, oz, volumeType, _, primaryAxis, disabled =
                Spring.GetUnitPieceCollisionVolumeData(unitID, pieceID)

            if sx and not disabled then
                local x, y, z = Spring.GetUnitPiecePosDir(unitID, pieceID)
                if x then
                    sendVolume(
                        unitID, volumes, x, y, z, heading,
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
                sendVolume(
                    unitID, volumes, x, y, z, heading,
                    sx, sy, sz, ox, oy, oz,
                    volumeType, primaryAxis, disabled
                )
            end
        end

        shadowVolumes[unitID] = volumes
        SendToUnsynced("buildingShadowVolumeEnd", unitID)
    end

    local function markDirty(unitID)
        if Spring.ValidUnitID(unitID) then
            pendingUnits[unitID] = true
        else
            shadowVolumes[unitID] = nil
            SendToUnsynced("buildingShadowVolumeRemove", unitID)
        end
    end

    function gadget:Initialize()
        GG.BuildingShadowVolume = shadowVolumes
        GG.MarkBuildingShadowVolumeDirty = markDirty

        -- Houses opt in only after their procedural build animation is stable.
    end

    function gadget:UnitDestroyed(unitID)
        pendingUnits[unitID] = nil
        shadowVolumes[unitID] = nil
        SendToUnsynced("buildingShadowVolumeRemove", unitID)
    end

    function gadget:GameFrame()
        for unitID in pairs(pendingUnits) do
            rebuildUnit(unitID)
            pendingUnits[unitID] = nil
        end
    end

    function gadget:Shutdown()
        GG.BuildingShadowVolume = nil
        GG.MarkBuildingShadowVolumeDirty = nil
    end
else
    local shadowVolumes = {}
    local changed = false

    local function beginVolume(_, unitID)
        shadowVolumes[unitID] = {}
    end

    local function addVolume(_, unitID, x, y, z, heading, sx, sy, sz,
            volumeType, primaryAxis)
        local volumes = shadowVolumes[unitID]
        if not volumes then
            volumes = {}
            shadowVolumes[unitID] = volumes
        end

        volumes[#volumes + 1] = {
            x = x, y = y, z = z,
            heading = heading,
            sx = sx, sy = sy, sz = sz,
            volumeType = volumeType,
            primaryAxis = primaryAxis,
        }
    end

    local function endVolume()
        changed = true
    end

    local function removeVolume(_, unitID)
        shadowVolumes[unitID] = nil
        changed = true
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("buildingShadowVolumeBegin", beginVolume)
        gadgetHandler:AddSyncAction("buildingShadowVolumeAdd", addVolume)
        gadgetHandler:AddSyncAction("buildingShadowVolumeEnd", endVolume)
        gadgetHandler:AddSyncAction("buildingShadowVolumeRemove", removeVolume)
    end

    function gadget:GameFrame()
        if changed and Script.LuaUI("ReceiveBuildingShadowVolumes") then
            Script.LuaUI.ReceiveBuildingShadowVolumes(shadowVolumes)
            changed = false
        end
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("buildingShadowVolumeBegin")
        gadgetHandler:RemoveSyncAction("buildingShadowVolumeAdd")
        gadgetHandler:RemoveSyncAction("buildingShadowVolumeEnd")
        gadgetHandler:RemoveSyncAction("buildingShadowVolumeRemove")
    end
end
