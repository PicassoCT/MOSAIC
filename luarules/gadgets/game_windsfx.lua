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
                        state = {started=effect.started, credit=0}
                        spawnCegAtPiece("civilbuildingdamage", unitID, piece)
                    end
                    local fade = config.effectFadeFrames > 0
                        and math.min(1, (effect.smokeUntil-frame)/config.effectFadeFrames) or 1
                    -- CEG particles retain their natural lifetime. Reduce new
                    -- emission during the final two seconds without inventing
                    -- an unsupported per-CEG alpha or lifetime override.
                    state.credit = state.credit+fade
                    if state.credit >= 1 then
                        spawnCegAtPiece("vehsmokepillar", unitID, piece, 0)
                        state.credit = state.credit-1
                    end
                    nextSwirls[unitID] = nextSwirls[unitID] or {}
                    nextSwirls[unitID][piece] = state
                end
            end
        end
    end
    smokeSwirls = nextSwirls
end

function gadget:UnitDestroyed(unitID)
    smokeSwirls[unitID] = nil
end
