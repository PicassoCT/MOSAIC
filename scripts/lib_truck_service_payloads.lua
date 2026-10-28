-- Ordinary civilian truck bodies. The original truckpayload remains the
-- three-in-four branch, including its complete procedural piece inventory.
local M = {
    unitName = "truckpayloadservice",
    modelName = "truckPayloadService.dae",
    -- Measured from the ordinary carrier meshes and the shared service-body
    -- envelope. These offsets apply only to the new models' empty center root.
    carrierOffsets = {
        truck_arab6 = {y = 0, z = -3.5},
        truck_arab7 = {y = 3.5, z = 1},
        truck_arab8 = {y = 4.1, z = 0},
    },
    variants = {
        {key = "air_scrubber", title = "Air scrubber",
            description = "Municipal air scrubber - filter cartridges overdue"},
        {key = "night_kitchen", title = "Night kitchen",
            description = "Night kitchen - hot meals for the late shift"},
        {key = "battery_exchange", title = "Battery exchange",
            description = "Battery exchange - rented charge, refundable cells"},
        {key = "salvage_press", title = "Salvage press",
            description = "Salvage press - reclaiming tomorrow's spare parts"},
        {key = "cold_chain", title = "Cold chain",
            description = "Cold chain - sealed refrigerated cargo"},
        {key = "sleeper_shuttle", title = "Sleeper shuttle",
            description = "Sleeper shuttle - a bed between shifts", passenger = true},
        {key = "crematorium", title = "Mobile crematorium",
            description = "Mobile crematorium - final collection service"},
        {key = "noodle_shop", title = "Noodle shop",
            description = "Noodle shop - broth, steam and late-night customers"},
        {key = "casino", title = "Rolling casino",
            description = "Rolling casino - the house always moves"},
        {key = "strip_club", title = "Mobile strip club",
            description = "Mobile strip club - private entertainment on the night route"},
        {key = "bar", title = "Travelling bar",
            description = "Travelling bar - last orders at the next junction"},
        {key = "band", title = "Band stage",
            description = "Band stage - live music on borrowed power"},
        {key = "unato_rations", title = "UNATO ration dispenser",
            description = "UNATO ration dispenser - stackable civilian food relief"},
    },
}

for index, variant in ipairs(M.variants) do
    variant.pieceName = "container" .. index
end

-- Match the original payload's numbered container group, with one complete
-- body in each piece. Ordered cycling gives every available body equal use.
function M.selectVariant(containerPieces, state)
    local available = {}
    for index in ipairs(M.variants) do
        if containerPieces[index] then available[#available + 1] = index end
    end
    if #available == 0 then return end
    local nextSpawn = (state.spawns or 0) + 1
    local index = available[((nextSpawn - 1) % #available) + 1]
    state.spawns = nextSpawn
    return M.variants[index], containerPieces[index], index
end

function M.newSelector(options)
    local state = options.state or {}
    local serviceDefinition = options.unitDefNames[M.unitName]
    local available = serviceDefinition and serviceDefinition.id ~= nil

    local selector = {}
    function selector:IsEligible(carrierDefID, requested, teamID)
        if requested ~= "truckpayload" or teamID ~= options.gaiaTeamID
            or not options.loadableTypes[carrierDefID]
            or not options.civilianTypes[carrierDefID] then
            return false
        end
        local definition = options.unitDefs[carrierDefID]
        if not definition then return false end
        local name = definition.name or ""
        -- Positive civilian-family membership also rejects military and police
        -- definitions if a caller accidentally supplies a broader type table.
        if not (name:match("^truck_arab%d+$") or name:match("^truck_western%d+$")
            or name:match("^truck_asian%d+$")) then
            return false
        end
        local scriptName = string.lower(definition.scriptName or definition.script or "")
        return name ~= "truck_western3" and not scriptName:match("longtruckscript%.lua$")
    end

    function selector:Select(carrierDefID, requested, teamID)
        local eligible = self:IsEligible(carrierDefID, requested, teamID)
        if not eligible or not available
            or ((state.eligibleSpawns or 0) + 1) % 4 ~= 0 then
            return requested, eligible
        end
        return M.unitName, true
    end

    -- Commit only after a payload was created and attached. Failed attempts
    -- consume no slot; a failed new model falls back to the original payload.
    function selector:RecordSpawn(eligible, actualName)
        if not eligible then return end
        state.eligibleSpawns = (state.eligibleSpawns or 0) + 1
        if actualName == M.unitName then
            state.serviceSpawns = (state.serviceSpawns or 0) + 1
        end
    end

    return selector
end

return M
