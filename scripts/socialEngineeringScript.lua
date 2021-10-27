include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local TablesOfPiecesGroups = {}
local GameConfig = getGameConfig()
local DollarSign = piece "DollarSign"
local Rotator1 = piece "Rotator1"
local spGetUnitPosition = Spring.GetUnitPosition
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)
									 
local spGetUnitDefID = Spring.GetUnitDefID

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    StartThread(hoverAboveGround, unitID, GameConfig.iconHoverHeight)  
    StartThread(lifeTime, unitID,true, false)  
	StartThread(socialEngineeringPosWriteUp)	
end

function socialEngineeringPosWriteUp()
	if not GG.SocialEngineeredPeople then GG.SocialEngineeredPeople ={} end
	if not GG.SocialEngineers then GG.SocialEngineers ={} end
	GG.SocialEngineers[unitID] = true
	while true do
		x,y,z = spGetUnitPosition(unitID)
		 process(getAllInCircle(x,z, GameConfig.socialEngineeringRange),
														function(id)
															if GG.DisguiseCivilianFor[id] then return end
															defID = spGetUnitDefID(id)
															if civilianWalkingTypeTable[defID] then
																GG.SocialEngineeredPeople[id] = unitID
																return id
															end
														end
														)
		Sleep(250)
	end

end

function script.Killed(recentDamage, _)
	GG.SocialEngineers[unitID] = nil
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

