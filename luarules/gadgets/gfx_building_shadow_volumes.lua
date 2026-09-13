function gadget:GetInfo()
    return {
        name = "Building Shadow Geometry",
        desc = "Forwards compact completed building columns to LuaUI",
        author = "Picasso, Codex", date = "2026", license = "GNU GPL, v2 or later",
        layer = -10, enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then
    local pendingUnits = {}
    local MAX_GRID_CELLS = 4096
    local MAX_LEVELS = 30

    local function finite(n)
        return type(n) == "number" and n == n and math.abs(n) < math.huge
    end

    local function denseLength(t)
        if type(t) ~= "table" then return nil end
        local n = #t
        if n > MAX_GRID_CELLS then return nil end
        local count = 0
        for k in pairs(t) do
            if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then return nil end
            count = count + 1
        end
        if count ~= n then return nil end
        return n
    end

    local function optionalCell(t, x, z, default)
        if t == nil then return default end
        if type(t) ~= "table" then return nil end
        local row = t[x]
        if row == nil then return default end
        if type(row) ~= "table" then return nil end
        if row[z] == nil then return default end
        return row[z]
    end

    local function validate(g)
        if type(g) ~= "table" or not finite(g.cellSize) or g.cellSize <= 0 or
            not finite(g.levelHeight) or g.levelHeight <= 0 then return nil end
        local nx = denseLength(g.columns)
        if not nx then return nil end
        local nz = nx > 0 and denseLength(g.columns[1]) or 0
        if not nz or nx * nz > MAX_GRID_CELLS then return nil end
        local ox = g.originX or -(nx - 1) * g.cellSize / 2
        local oz = g.originZ or -(nz - 1) * g.cellSize / 2
        if not finite(ox) or not finite(oz) then return nil end
        for x = 1, nx do
            if denseLength(g.columns[x]) ~= nz then return nil end
            for z = 1, nz do
                local levels = g.columns[x][z]
                if not finite(levels) or levels < 0 or levels > MAX_LEVELS or
                    levels ~= math.floor(levels) then return nil end
                local base = optionalCell(g.baseHeights, x, z, 0)
                local mask = optionalCell(g.masks, x, z, 2 ^ levels - 1)
                if not finite(base) or not finite(mask) or mask ~= math.floor(mask) or
                    mask < 0 or mask > 2 ^ levels - 1 or
                    (levels > 0 and mask == 0) then return nil end
                if not finite(ox + (x - 1) * g.cellSize) or
                    not finite(oz + (z - 1) * g.cellSize) or
                    not finite(base + levels * g.levelHeight) then return nil end
            end
        end
        return nx, nz, ox, oz
    end

    local function rebuildUnit(unitID)
        local unitDefID = Spring.GetUnitDefID(unitID)
        local def = unitDefID and UnitDefs[unitDefID]
        local cp = def and def.customParams
        local enabled = cp and (cp.throwsshadow or cp.throwsShadow)
        local env = Spring.UnitScript.GetScriptEnv(unitID)
        if not (enabled == true or enabled == 1 or enabled == "1" or enabled == "true") or
            not env or type(env.GetBuildingShadowColumns) ~= "function" then
            SendToUnsynced("buildingShadowColumnsRemove", unitID)
            return
        end
        local g = Spring.UnitScript.CallAsUnit(unitID, env.GetBuildingShadowColumns)
        local nx, nz, ox, oz = validate(g)
        if not nx then
            Spring.Echo("Building Shadow Geometry: invalid column grid for unit " .. unitID)
            SendToUnsynced("buildingShadowColumnsRemove", unitID)
            return
        end
        -- One message per occupied column. No table crosses the sync boundary.
        SendToUnsynced("buildingShadowColumnsBegin", unitID, unitDefID, g.cellSize, g.levelHeight)
        for x = 1, nx do
            for z = 1, nz do
                local levels = g.columns[x][z]
                if levels > 0 then
                    SendToUnsynced("buildingShadowColumn", unitID,
                        ox + (x - 1) * g.cellSize, oz + (z - 1) * g.cellSize,
                        optionalCell(g.baseHeights, x, z, 0),
                        optionalCell(g.masks, x, z, 2 ^ levels - 1))
                end
            end
        end
        SendToUnsynced("buildingShadowColumnsEnd", unitID)
    end

    local function markDirty(unitID)
        if not Spring.ValidUnitID(unitID) then
            pendingUnits[unitID] = nil
            SendToUnsynced("buildingShadowColumnsRemove", unitID)
            return
        end
        pendingUnits[unitID] = true
    end

    function gadget:Initialize()
        GG.MarkBuildingShadowVolumeDirty = markDirty
    end

    function gadget:UnitDestroyed(unitID)
        pendingUnits[unitID] = nil
        SendToUnsynced("buildingShadowColumnsRemove", unitID)
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
    local function beginColumns(_, unitID, unitDefID, cellSize, levelHeight)
        if Script.LuaUI("ReceiveBuildingShadowColumnsBegin") then
            Script.LuaUI.ReceiveBuildingShadowColumnsBegin(unitID, unitDefID, cellSize, levelHeight)
        end
    end
    local function addColumn(_, unitID, x, z, base, mask)
        if Script.LuaUI("ReceiveBuildingShadowColumn") then
            Script.LuaUI.ReceiveBuildingShadowColumn(unitID, x, z, base, mask)
        end
    end
    local function endColumns(_, unitID)
        if Script.LuaUI("ReceiveBuildingShadowColumnsEnd") then
            Script.LuaUI.ReceiveBuildingShadowColumnsEnd(unitID)
        end
    end
    local function removeColumns(_, unitID)
        if Script.LuaUI("ReceiveBuildingShadowColumnsRemove") then
            Script.LuaUI.ReceiveBuildingShadowColumnsRemove(unitID)
        end
    end
    function gadget:Initialize()
        gadgetHandler:AddSyncAction("buildingShadowColumnsBegin", beginColumns)
        gadgetHandler:AddSyncAction("buildingShadowColumn", addColumn)
        gadgetHandler:AddSyncAction("buildingShadowColumnsEnd", endColumns)
        gadgetHandler:AddSyncAction("buildingShadowColumnsRemove", removeColumns)
    end
    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("buildingShadowColumnsBegin")
        gadgetHandler:RemoveSyncAction("buildingShadowColumn")
        gadgetHandler:RemoveSyncAction("buildingShadowColumnsEnd")
        gadgetHandler:RemoveSyncAction("buildingShadowColumnsRemove")
    end
end
