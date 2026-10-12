function gadget:GetInfo()
    return {
        name = "Debris, damage and wind caused sfx",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2024",
        license = "GPL3",
        layer = 1,
        version = 1,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_debug.lua")
local spGetUnitPieceList = Spring.GetUnitPieceList
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
local spSpawnCEG = Spring.SpawnCEG
local spGetWind = Spring.GetWind
local spValidUnitID = Spring.ValidUnitID
local spGetUnitIsDead = Spring.GetUnitIsDead
local config = getBuildingDamageConfig()
local windMax = Game.windMax or 0
local windLimit = windMax*.75
local smokeSwirls = {}
-- Temporary, bounded lifecycle diagnostics; removed with the printf commit.
local smokeTrace = VFS.Include('luarules/gadgets/include/execution_trace.lua')
    .New('BuildingDestruction', {maxEvents=32})

local function traceAnchorStopped(unitID, piece, state, reason)
    smokeTrace.Log(unitID, state.started, 'building_smoke_anchor_stopped',
        {piece=piece, reason=reason, started=state.started, smokeUntil=state.smokeUntil})
end

local function getRandomPiece(unitID)
    local list = spGetUnitPieceList(unitID)
    if list and #list > 0 then return math.random(1, #list) end
end

local function spawnCegAtPiece(cegname, unitID, piece, offset)
    if not piece then return false end
    local x, y, z = spGetUnitPiecePosDir(unitID, piece)
    if not y then return false end
    spSpawnCEG(cegname, x, y+(offset or 10), z, 0, 1, 0, 0, 0)
    return true
end

function gadget:GameFrame(frame)
    -- Damage smoke also works on calm maps. Only windblown newspaper uses the
    -- original wind threshold, 270-frame cadence and random building/piece.
    if windMax >= 2 and frame % 270 == 0 then
        local _, _, _, strength = spGetWind()
        if strength > windLimit then
            local factor = math.ceil((strength/windMax)*10)
            for _ = 1, factor do
                local unitID = randDict(GG.BuildingTable)
                if unitID then spawnCegAtPiece("flyinggarbage", unitID, getRandomPiece(unitID)) end
            end
        end
    end

    if frame % 6 ~= 0 then return end
    local nextSwirls = {}
    -- Structure is authoritative. There is no UnitDamaged timer or last-hit
    -- anchor to refresh after a piece disappears; absent records stop emission.
    for unitID, pieces in pairs(GG.BuildingDamageEffects or {}) do
        if spValidUnitID(unitID) and not spGetUnitIsDead(unitID) then
            local previous = smokeSwirls[unitID] or {}
            for piece, effect in pairs(pieces) do
                if effect.visible == true and effect.piece == piece
                    and frame >= effect.started and frame < effect.smokeUntil then
                    local state = previous[piece]
                    if not state or state.started ~= effect.started then
                        state = {started=effect.started, credit=0, smokeUntil=effect.smokeUntil}
                        smokeTrace.Log(unitID, effect.started, 'building_smoke_anchor_started',
                            {piece=piece, started=effect.started, fireUntil=effect.fireUntil,
                                smokeUntil=effect.smokeUntil})
                        spawnCegAtPiece("civilbuildingdamage", unitID, piece)
                    end
                    local fade = config.effectFadeFrames > 0
                        and math.min(1, (effect.smokeUntil-frame)/config.effectFadeFrames) or 1
                    if fade < 1 and not state.fadeLogged then
                        state.fadeLogged = true
                        smokeTrace.Log(unitID, effect.started, 'building_smoke_fade_started',
                            {piece=piece, fade=fade, remainingFrames=effect.smokeUntil-frame,
                                fadeFrames=config.effectFadeFrames, smokeUntil=effect.smokeUntil})
                    end
                    -- CEG particles retain their natural lifetime. Reduce new
                    -- emission during the final two seconds without inventing
                    -- an unsupported per-CEG alpha or lifetime override.
                    state.credit = state.credit+fade
                    if state.credit >= 1 then
                        local submitted = spawnCegAtPiece("vehsmokepillar", unitID, piece, 0)
                        if submitted and not state.emissionLogged then
                            state.emissionLogged = true
                            smokeTrace.Log(unitID, effect.started, 'building_smoke_emission_started',
                                {piece=piece, ceg='vehsmokepillar', meaning='spawn_call_returned'})
                        elseif not submitted and not state.missingPositionLogged then
                            state.missingPositionLogged = true
                            smokeTrace.Log(unitID, effect.started, 'building_smoke_emission_skipped',
                                {piece=piece, reason='missing_piece_position'})
                        end
                        state.credit = state.credit-1
                    end
                    nextSwirls[unitID] = nextSwirls[unitID] or {}
                    nextSwirls[unitID][piece] = state
                end
            end
        end
    end
    -- Observe states the existing nextSwirls replacement is about to retire.
    -- This never edits the authoritative records or keeps an emitter alive.
    for unitID, pieces in pairs(smokeSwirls) do
        for piece, state in pairs(pieces) do
            if not nextSwirls[unitID] or nextSwirls[unitID][piece] ~= state then
                local current = GG.BuildingDamageEffects and GG.BuildingDamageEffects[unitID]
                local effect = current and current[piece]
                local reason
                if not spValidUnitID(unitID) then reason='invalid_unit'
                elseif spGetUnitIsDead(unitID) then reason='dead_unit'
                elseif effect and effect.started ~= state.started then reason='replaced'
                elseif effect and effect.visible ~= true then reason='hidden_piece'
                elseif frame >= state.smokeUntil then reason='expired'
                elseif not effect then reason='record_removed'
                elseif effect.piece ~= piece then reason='piece_mismatch'
                elseif frame >= effect.smokeUntil then reason='expired'
                else reason='not_started' end
                traceAnchorStopped(unitID, piece, state, reason)
            end
        end
    end
    smokeSwirls = nextSwirls
end

function gadget:UnitDestroyed(unitID)
    for piece, state in pairs(smokeSwirls[unitID] or {}) do
        traceAnchorStopped(unitID, piece, state, 'unit_destroyed')
    end
    smokeSwirls[unitID] = nil
end
