function gadget:GetInfo()
    return {
        name = "Building Shadow Geometry",
        desc = "Forwards completed building piece IDs to LuaUI for DAE voxelization",
        author = "Picasso, Codex",
        date = "2026",
        license = "GNU GPL, v2 or later",
        layer = -10,
        enabled = true,
    }
end

if gadgetHandler:IsSyncedCode() then
    local MAX_PIECES_PER_UNIT = 128
    local pendingUnits = {}
    local lastSelectedPieces = {}

    local function throwsShadow(unitDefID)
        local unitDef = UnitDefs[unitDefID]
        local params = unitDef and unitDef.customParams
        local value = params and (params.throwsshadow or params.throwsShadow)
        return value == true or value == 1 or value == "1" or value == "true"
    end

    local function copySelection(selectedPieces)
        local copy = {}
        for key, value in pairs(selectedPieces or {}) do
            copy[key] = value
        end
        return copy
    end

    local function rebuildUnit(unitID, selectedPieces)
        local unitDefID = Spring.GetUnitDefID(unitID)
        if not unitDefID or not throwsShadow(unitDefID) then
            SendToUnsynced("buildingShadowPieceRemove", unitID)
            return
        end

        local pieces = {}
        local seenPieces = {}

        for key, value in pairs(selectedPieces or {}) do
            local pieceID
            if type(value) == "number" then
                pieceID = value
            elseif type(key) == "number" and value then
                pieceID = key
            end

            if pieceID and not seenPieces[pieceID] then
                seenPieces[pieceID] = true
                pieces[#pieces + 1] = pieceID
                if #pieces >= MAX_PIECES_PER_UNIT then
                    Spring.Echo(
                        "Building Shadow Geometry: capped unit " .. unitID ..
                        " at " .. MAX_PIECES_PER_UNIT .. " pieces"
                    )
                    break
                end
            end
        end

        -- Keep every synced -> unsynced payload primitive-only. LuaUI reconstructs
        -- the short piece list locally, then reads the DAE and live piece matrices.
        SendToUnsynced("buildingShadowPieceBegin", unitID, unitDefID)
        for i = 1, #pieces do
            SendToUnsynced("buildingShadowPieceAdd", unitID, pieces[i])
        end
        SendToUnsynced("buildingShadowPieceEnd", unitID)
    end

    local function markDirty(unitID, selectedPieces)
        if not Spring.ValidUnitID(unitID) then
            pendingUnits[unitID] = nil
            lastSelectedPieces[unitID] = nil
            SendToUnsynced("buildingShadowPieceRemove", unitID)
            return
        end

        if selectedPieces ~= nil then
            local snapshot = copySelection(selectedPieces)
            lastSelectedPieces[unitID] = snapshot
            pendingUnits[unitID] = snapshot
        elseif lastSelectedPieces[unitID] then
            -- A few older building scripts still issue a parameterless dirty mark.
            -- Reuse the last explicit visible-piece set instead of falling back to
            -- every model piece (which would reintroduce hidden/placeable geometry).
            pendingUnits[unitID] = lastSelectedPieces[unitID]
        end
    end

    function gadget:Initialize()
        GG.MarkBuildingShadowVolumeDirty = markDirty
        -- Houses opt in only after their procedural build animation is stable.
    end

    function gadget:UnitDestroyed(unitID)
        pendingUnits[unitID] = nil
        lastSelectedPieces[unitID] = nil
        SendToUnsynced("buildingShadowPieceRemove", unitID)
    end

    function gadget:GameFrame()
        for unitID, selectedPieces in pairs(pendingUnits) do
            rebuildUnit(unitID, selectedPieces)
            pendingUnits[unitID] = nil
        end
    end

    function gadget:Shutdown()
        GG.MarkBuildingShadowVolumeDirty = nil
    end
else
    local function beginPieces(_, unitID, unitDefID)
        if Script.LuaUI("ReceiveBuildingShadowBegin") then
            Script.LuaUI.ReceiveBuildingShadowBegin(unitID, unitDefID)
        end
    end

    local function addPiece(_, unitID, pieceID)
        if Script.LuaUI("ReceiveBuildingShadowPiece") then
            Script.LuaUI.ReceiveBuildingShadowPiece(unitID, pieceID)
        end
    end

    local function endPieces(_, unitID)
        if Script.LuaUI("ReceiveBuildingShadowEnd") then
            Script.LuaUI.ReceiveBuildingShadowEnd(unitID)
        end
    end

    local function removePieces(_, unitID)
        if Script.LuaUI("ReceiveBuildingShadowRemove") then
            Script.LuaUI.ReceiveBuildingShadowRemove(unitID)
        end
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("buildingShadowPieceBegin", beginPieces)
        gadgetHandler:AddSyncAction("buildingShadowPieceAdd", addPiece)
        gadgetHandler:AddSyncAction("buildingShadowPieceEnd", endPieces)
        gadgetHandler:AddSyncAction("buildingShadowPieceRemove", removePieces)
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("buildingShadowPieceBegin")
        gadgetHandler:RemoveSyncAction("buildingShadowPieceAdd")
        gadgetHandler:RemoveSyncAction("buildingShadowPieceEnd")
        gadgetHandler:RemoveSyncAction("buildingShadowPieceRemove")
    end
end
