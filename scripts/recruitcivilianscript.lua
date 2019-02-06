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


function recruiteLoop()
	local recruitmentRange = gameConfig.agentConfig.recruitmentRange
	local civilianDefID=  UnitDefNames["civilian"].id
	local spGetUnitDefID =Spring.GetUnitDefID
	local spGetUnitTeam = Spring.GetUnitTeam
	Sleep(100)

	while true do
		Sleep(100)
		process(getAllNearUnit(unitID, recruitmentRange),
				function(id)
					if spGetUnitTeam(id)== gaiaTeamID then
						return id
					end
				end,	
				function(id)
					if spGetUnitDefID(id)== civilianDefID then
						assert(parent)
						ad = transformUnitInto(id, UnitDefNames["civilianagent"].id, parent)
						Spring.TransferUnit(ad, Spring.GetUnitTeam(unitID), true)


						if GG.DisguiseCivilianFor[id] then
							attachDoubleAgentToUnit(ad, Spring.GetUnitTeam(GG.DisguiseCivilianFor[id]))
							Spring.TransferUnit(ad, Spring.GetUnitTeam(unitID), true)
							defID =  Spring.GetUnitDefID(GG.DisguiseCivilianFor[id]) 
							if defID == UnitDefNames["operativeinvestigator"].id  or defID == UnitDefNames["operativeinvestigator"].id then
								--beam out  to nearest building
								beamOperativeToNearestHouse(GG.DisguiseCivilianFor[id])
							end	
						end	
						Spring.DestroyUnit(id,true,true)
						Spring.DestroyUnit(unitID,true,true)
						break
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

