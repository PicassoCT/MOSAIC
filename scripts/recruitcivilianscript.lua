include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end


gameConfig = getGameConfig()
gaiaTeamID = Spring.GetGaiaTeamID()

function script.Create()
		Spring.MoveCtrl.Enable(unitID,true)
       TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	   StartThread(recruiteLoop)
	   x,y,z= Spring.GetUnitPosition(unitID)

	   Spring.MoveCtrl.SetPosition(unitID, x,y+ gameConfig.iconGroundOffset,z)
	   StartThread(lifeTime, unitID, 10000, true, false)
	   StartThread(animationLoop, 2)

end

boolKillParent= false
overWriteIDOnCreation= nil
boolSetVelocity= true

operativeTypeTable = getOperativeTypeTable(UnitDefs)
civilianAgentDefID = UnitDefNames["civilianagent"].id
truckDefID = UnitDefNames["truck"].id

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

					defID = spGetUnitDefID(id)
					if defID== truckDefID then
					
								x,y,z,_,_,_ =Spring.GetUnitPosition(id)
								ad = Spring.CreateUnit("truck",			
								x,y,z, 			
								1,		
								teamID,	
								false,				
								false,	
								nil,
								fatherID)
							transferUnitStatusToUnit(id, ad)
							transferOrders(id, ad)	
								
							consumeAvailableRessourceUnit(unitID, "metal", gameConfig.costs.RecruitingTruck)
							Spring.DestroyUnit( id , false, true)
							Spring.DestroyUnit( unitID , false, true)
							while true do
								Sleep(1000)
							end	
					
					end
					
					if spGetUnitDefID(id)== civilianDefID and  not GG.DisguiseCivilianFor[id]	or 		boolIsDisguiseCivilian == true			
					then
						return id
					end
				end,
				function(id)
					if id then
						--create a civilian agent
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

function animationLoop(speedfactor)
civhat = piece"civhat"
civloop = piece"civloop"
GoodCiv = piece"GoodCiv"
BadCiv = piece"BadCiv"
agentloop = piece"agentloop"
civbodyup = piece"civbodyup"
civbodydown = piece"civbodydown"
agent1 = TablesOfPiecesGroups["Agent"][1]
agent2 = TablesOfPiecesGroups["Agent"][2]

while true do
	resetAll(unitID)
	hideAll(unitID)
	Show(civloop)

	Show(TablesOfPiecesGroups["CivBox"][1])
	Show(civbodyup)
	Show(civbodydown)
	Show(agent1)
	Move(civbodydown,x_axis, -900, 450 * speedfactor)
	Move(agent1, x_axis, 900, 450* speedfactor)
	WaitForMoves(civbodydown,agent1)
	Sleep(500)
	Turn(civbodydown,y_axis, math.rad(-45),15* speedfactor)
	Turn(agent1,y_axis, math.rad(-45),10* speedfactor)
	WaitForTurns(civbodydown,agent1)
	Sleep(100)
	Hide(TablesOfPiecesGroups["CivBox"][1])
	Show(TablesOfPiecesGroups["AgentBox"][1])
	Show(TablesOfPiecesGroups["AgentBox"][2])
	Show(agent2)
	WTurn(agent1,y_axis, math.rad(-180),25* speedfactor)
	Turn(civbodydown,y_axis, math.rad(90),5* speedfactor)
	Move(agent2, 3, 900, 450* speedfactor)
	Move(agent1, x_axis, 0, 450* speedfactor)
	Show(GoodCiv)
	Move(GoodCiv,y_axis, 512, 750* speedfactor)
	Move(BadCiv,y_axis, 512, 750* speedfactor)
	WMove(civbodyup,y_axis, 1024, 750* speedfactor)
	Hide(GoodCiv)
	Show(BadCiv)
	Sleep(250)
	Move(civbodyup,y_axis, 0, 750* speedfactor)
	Move(GoodCiv,y_axis, 0, 750* speedfactor)
	WMove(BadCiv,y_axis, 0, 750* speedfactor)
	WMove(agent2, 3, 900, 450* speedfactor)
	Hide(agent1)
	Hide(TablesOfPiecesGroups["AgentBox"][1])
	Hide(TablesOfPiecesGroups["AgentBox"][2])
	Show(TablesOfPiecesGroups["CivBox"][2])
	Show(agentloop)
	Hide(civloop)
	--point of handover	
	Turn(civbodydown,y_axis, math.rad(180),5* speedfactor)
	--matroshka	
	WTurn(agent2,y_axis, math.rad(90),5* speedfactor)
	Show(civhat)
	Turn(civbodydown,y_axis, math.rad(180),15* speedfactor)
	Turn(agent2,y_axis, math.rad(180),5* speedfactor)
	Move(civbodydown, x_axis, 0, 450* speedfactor)
	WMove(agent2, y_axis, 0, 450* speedfactor)

end

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

