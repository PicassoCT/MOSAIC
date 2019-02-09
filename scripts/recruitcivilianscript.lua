include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
gameConfig = getGameConfig()
gaiaTeamID = Spring.GetGaiaTeamID()

function script.Create()
       TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	   StartThread(recruiteLoop)
	   StartThread(lifeTime, unitID, 10000, true, false)

end

boolKillParent= false
overWriteIDOnCreation= nil
boolSetVelocity= true

operativeTypeTable = getOperativeTypeTable(UnitDefs)
civilianAgentDefID = UnitDefNames["civilianagent"].id

function recruiteLoop()
	local recruitmentRange = gameConfig.agentConfig.recruitmentRange
	local civilianDefID=  UnitDefNames["civilian"].id
	local spGetUnitDefID =Spring.GetUnitDefID
	local spGetUnitTeam = Spring.GetUnitTeam
	Sleep(100)

	while true do
		Sleep(100)
		process(
				getAllNearUnit(unitID, recruitmentRange),
				function(id)
					if spGetUnitTeam(id)== gaiaTeamID then
						return id
					end
				end,	
				function(id) --filter out disguise units
boolIsDisguiseCivilian =GG.DisguiseCivilianFor[id] and GG.DisguiseCivilianFor[id] ~= fatherID and Spring.GetUnitTeam( GG.DisguiseCivilianFor[id]) ~= Spring.GetUnitTeam(unitID)  
					
					if spGetUnitDefID(id)== civilianDefID and  not GG.DisguiseCivilianFor[id]	or 		boolIsDisguiseCivilian == true			
					then
						return id
					end
				end,
				function(id)
					if id then
						--create a civilian agent
						recruitedDefID = Spring.GetUnitDefID(id)
						teamID =Spring.GetUnitTeam(unitID)
			
						x,y,z,_,_,_ =Spring.GetUnitPosition(id)
						ad = Spring.CreateUnit("civilianagent",			
								x,y,z, 			
								1,		
								teamID,	
								false,				
								false,	
								nil,
								fatherID)
						assert(ad)
						transferUnitStatusToUnit(id, ad)
						transferOrders(id, ad)
						
						--if the recruitedunit was a civilianagent
							if recruitedDefID == civilianAgentDefID then
								attachDoubleAgentToUnit(ad,  Spring.GetUnitTeam(GG.DisguiseCivilianFor[id]))
								Spring.DestroyUnit( id , false, true)
							elseif operativeTypeTable[recruitedDefID] and recruitedDefID ~= civilianAgentDefID then
								--if the recruited unit was a operative
								attachDoubleAgentToUnit(ad,  Spring.GetUnitTeam(GG.DisguiseCivilianFor[id]))
								beamOperativeToNearestHouse(GG.DisguiseCivilianFor[id])
								MoveUnitToUnit(id, GG.DisguiseCivilianFor[id])
							end
							
							if recruitedDefID == civilianDefID then
								Spring.DestroyUnit( id , false, true)
							end
					Spring.DestroyUnit(unitID, false, true) 
					while true do
						Sleep(1000)
					end
					end
				end
			)				
	
		end
end

function beamOperativeToNearestHouse(id)
	x,y,z= Spring.GetUnitPosition(id)
	maxdist= math.huge
	local jumpID
	
	T= Spring.GetTeamUnitsByDefs(gaiaTeamID, UnitDefNames["house"].id)
		for i=1,#T do
			id = T[i]
			tx,ty,tz= Spring.GetUnitPosition(id)
			dist = distance(x,y,z, tx,ty,tz)
				if dist < maxdist then 
					maxdist = dist
					jumpID = id 
				end
		end
			
	moveUnitToUnit(id, jumpID, 15*randSign(),0, 15*randSign())	
end


function script.Killed(recentDamage, _)
    return 1
end



function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, { center })

