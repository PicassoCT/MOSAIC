function gadget:GetInfo()
    return {
        name = "Building Shadow Geometry",
        desc = "Forwards completed building-script voxel arrays to LuaUI",
        author = "Picasso, Codex",
        date = "2026",
        license = "GNU GPL, v2 or later",
        layer = -10,
        enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then
    local MAX_VOXELS_PER_UNIT = 16000
    local pendingUnits = {}

    local function throwsShadow(unitDefID)
        local unitDef = UnitDefs[unitDefID]
        local params = unitDef and unitDef.customParams
        local value = params and (params.throwsshadow or params.throwsShadow)
        return value == true or value == 1 or value == "1" or value == "true"
    end

    local function finite(value)
        return type(value) == "number" and value == value and math.abs(value) < math.huge
    end

    local function rebuildUnit(unitID)
        local unitDefID = Spring.GetUnitDefID(unitID)
        if not unitDefID or not throwsShadow(unitDefID) then
            SendToUnsynced("buildingShadowVoxelRemove", unitID)
            return
        end
        local env = Spring.UnitScript.GetScriptEnv(unitID)
        if not env or type(env.GetBuildingShadowVoxels) ~= "function" then
            SendToUnsynced("buildingShadowVoxelRemove", unitID)
            return
        end
        local voxels, voxelSize = Spring.UnitScript.CallAsUnit(unitID, env.GetBuildingShadowVoxels)
        if type(voxels) ~= "table" or #voxels > MAX_VOXELS_PER_UNIT or
           not finite(voxelSize) or voxelSize <= 0 then
            Spring.Echo("Building Shadow Geometry: invalid voxel array for unit " .. unitID)
            SendToUnsynced("buildingShadowVoxelRemove", unitID)
            return
        end
        for i = 1, #voxels do
            local v = voxels[i]
            if type(v) ~= "table" or not finite(v.x) or not finite(v.y) or not finite(v.z) then
                Spring.Echo("Building Shadow Geometry: invalid voxel for unit " .. unitID)
                SendToUnsynced("buildingShadowVoxelRemove", unitID)
                return
            end
        end
        -- Tables stay in synced Lua. Every cross-boundary argument is primitive.
        SendToUnsynced("buildingShadowVoxelBegin", unitID, unitDefID, voxelSize)
        for i = 1, #voxels do
            local v = voxels[i]
            SendToUnsynced("buildingShadowVoxelAdd", unitID, v.x, v.y, v.z)
        end
        SendToUnsynced("buildingShadowVoxelEnd", unitID)
    end

    local function markDirty(unitID)
        if not Spring.ValidUnitID(unitID) then
            pendingUnits[unitID] = nil
            SendToUnsynced("buildingShadowVoxelRemove", unitID)
            return
        end
        pendingUnits[unitID] = true
    end

    function gadget:Initialize()
        GG.MarkBuildingShadowVolumeDirty = markDirty
        -- Houses opt in only after their procedural build animation is stable.
    end

    function gadget:UnitDestroyed(unitID)
        pendingUnits[unitID] = nil
        SendToUnsynced("buildingShadowVoxelRemove", unitID)
    end

    function gadget:GameFrame()
        for unitID in pairs(pendingUnits) do
            rebuildUnit(unitID)
            pendingUnits[unitID] = nil
        end
    end

    function gadget:Shutdown()
        GG.MarkBuildingShadowVolumeDirty = nil
    end
else
    local function beginVoxels(_, unitID, unitDefID, voxelSize)
        if Script.LuaUI("ReceiveBuildingShadowBegin") then
            Script.LuaUI.ReceiveBuildingShadowBegin(unitID, unitDefID, voxelSize)
        end
    end

    local function addVoxel(_, unitID, x, y, z)
        if Script.LuaUI("ReceiveBuildingShadowVoxel") then
            Script.LuaUI.ReceiveBuildingShadowVoxel(unitID, x, y, z)
        end
    end

    local function endVoxels(_, unitID)
        if Script.LuaUI("ReceiveBuildingShadowEnd") then
            Script.LuaUI.ReceiveBuildingShadowEnd(unitID)
        end
    end

    local function removeVoxels(_, unitID)
        if Script.LuaUI("ReceiveBuildingShadowRemove") then
            Script.LuaUI.ReceiveBuildingShadowRemove(unitID)
        end
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("buildingShadowVoxelBegin", beginVoxels)
        gadgetHandler:AddSyncAction("buildingShadowVoxelAdd", addVoxel)
        gadgetHandler:AddSyncAction("buildingShadowVoxelEnd", endVoxels)
        gadgetHandler:AddSyncAction("buildingShadowVoxelRemove", removeVoxels)
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("buildingShadowVoxelBegin")
        gadgetHandler:RemoveSyncAction("buildingShadowVoxelAdd")
        gadgetHandler:RemoveSyncAction("buildingShadowVoxelEnd")
        gadgetHandler:RemoveSyncAction("buildingShadowVoxelRemove")
    end
end
