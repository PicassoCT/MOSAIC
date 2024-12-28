function gadget:GetInfo()
    return {
        name = "Debris, damage and wind caused sfx",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2024",
        license = "GPL3",
        layer = 1,
        version = 1,
        enabled = Game.windMax >= 2 
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_debug.lua")
local spGetUnitPieceList = Spring.GetUnitPieceList
local spGetUnitLastAttackedPiece = Spring.GetUnitLastAttackedPiece
local spSpawnCEG = Spring.SpawnCEG
local spGetWind =Spring.GetWind
local GameConfig = getGameConfig()
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
local windLimit = Game.windMax*0.75


function getRandomPiece(unitID)
        assertNum(unitID)
        list = spGetUnitPieceList(unitID) 
        return  math.random(1,#list)
end
local smokeSwirls = {}
local boolAnySmokeSwirlActive = true
local spGetUnitPiecePosDir =  Spring.GetUnitPiecePosDir
function registerSmokeSwirl(unitID, pieceId)
    smokeSwirls[unitID] = {timeInFrames = 25*30, piece = pieceId}
    boolAnySmokeSwirlActive = true
end

-- > create a CEG at the given Piece with direction or piecedirectional Vector
function localspawnCegAtPiece(cegname, unitID, pieceId, offset, dx, dy, dz )
    assert(unitID)
    assert(pieceId)
    if not dx then -- default to upvector 
        dx, dy, dz = 0, 1, 0
    end

    boolAdd = offset or 10


    x, y, z, mx, my, mz = spGetUnitPiecePosDir(unitID, pieceId)

    if y then
        y = y + boolAdd
        spSpawnCEG(cegname, x, y, z, dx, dy, dz, 0, 0)
    end
end

function gadget:UnitDamaged(unitID,unitDefID,teamID, damage)
    if houseTypeTable[unitDefID] and dmage > 10 then
       
        lastHitPiece = spGetUnitLastAttackedPiece ( unitID ) 
        if not lastHitPiece then
            lastHitPiece = getRandomPiece(unitID)    
            if not lastHitPiece then return end    
        end
        --echo("UnitDamaged:"..toString(lastHitPiece))
        if lastHitPiece then            
            localspawnCegAtPiece("civilbuildingdamage", unitID, lastHitPiece)
            registerSmokeSwirl(unitID, lastHitPiece)

        end
    end
    return 
end

function gadget:GameFrame(frame)
    if frame % 270 == 0 then
        dirX, dirY, dirZ, strength, normDirX, normDirY, normDirZ = spGetWind()
        if strength > windLimit then
            factor = math.ceil((strength/Game.windMax) * 10.0)
            for i=1 , factor do
                unitId, pos =  randDict(GG.BuildingTable)
                if unitId then
                    localspawnCegAtPiece("flyinggarbage", unitId, getRandomPiece(unitId))
                end
            end
        end
    end

    if boolAnySmokeSwirlActive and frame % 6 == 0 then
         smokeSwirlsCounter = 0
         for id, data in pairs(smokeSwirls) do
            if data and data.piece then
                spawnCegAtPiece(id, data.piece, "vehsmokepillar")
                smokeSwirls[id].timeInFrames = smokeSwirls[id].timeInFrames - 6
                smokeSwirlsCounter = smokeSwirlsCounter + 1
                if smokeSwirls[id].timeInFrames < 0 then
                  smokeSwirls[id] = nil
                  smokeSwirlsCounter = smokeSwirlsCounter -1
                end
            end
         end
         boolAnySmokeSwirlActive = (smokeSwirlsCounter > 0)
    end
end

