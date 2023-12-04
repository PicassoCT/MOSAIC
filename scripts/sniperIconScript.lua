include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local GameConfig = getGameConfig()
local TablesOfPiecesGroups = {}
local myDefID = Spring.GetUnitDefID(unitID)
local storePassengerID = nil
local attachPoint = piece("attachPoint")
local Icon = piece("Icon")
local gaiaTeamID = Spring.GetGaiaTeamID()
local houseTypeTable = getHouseTypeTable(UnitDefs)
local ux,uy,uz = Spring.GetUnitPosition(unitID)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitNoSelect(unitID, true)
    Hide(attachPoint)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

