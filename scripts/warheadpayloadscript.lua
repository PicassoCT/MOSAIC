include "lib_mosaic.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
local defuseCapableUnitTypes = getDefusalCapableTypeTable(Unitdefs)
local GameConfig = getGameConfig()

local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "truck", UnitDefs)
local aerosolAffectableUnits = getChemTrailInfluencedTypes(UnitDefs)
local spGetTeamInfo = Spring.GetTeamInfo
local myTeamID = Spring.GetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local automationPayloadDisabledType = getAutomationPayloadDisabledType(UnitDefs)
local automationPayloadDestroyedType = getAutomationPayloadDestroyedType(UnitDefs)
launcherDefID = UnitDefNames["launcher"].id
boolIsAITeam = isTeamAITeam(Spring.GetUnitTeam(unitID))
BaseRotor = piece"BaseRotor1"

 function attachPayload(payLoadID, id)
    if payLoadID then
       pieceMap = Spring.GetUnitPieceMap(id)
       assert(pieceMap["attachPoint"], "Truck has no attachpoint")
       Spring.UnitAttach(id, payLoadID, pieceMap["attachPoint"])
       return payLoadID
    end
end

function moveAItoLauncher()	
	goal = unitID
	truckID  = createUnitAtUnit(myTeamID, randDict(TruckTypeTable) , unitID)
	while true do
	Sleep(1000)
	if not truckID then
		truckID = unitID
	end

		while goal == unitID do
		smallestDistance = math.huge
		foreach(Spring.GetTeamUnitsByDefs(myTeamID,launcherDefID),
							function(id)
								dist = distanceUnitToUnit(id, truckID)
								if dist < smallestDistance then 
									smallestDistance = dist
									goal = id
									return id
								end
							end
				)

		Sleep(250)
		end

		attachPayload(unitID, truckID)
		goalV= {}

		while goal ~= unitID and doesUnitExistAlive(goal) do

			goalV.x,goalV.y,goalV.z = Spring.GetUnitPosition(goal)
			Command(truckID, "go", goalV)		
			Sleep(1000)
		end
	end
end

function prepareDeformCraterTable(size, height, minimum)
    cent = math.ceil(size / 2)
    T = {}
    for o = 1, size, 1 do
        T[o] = {}
        for i = 1, size, 1 do
            --default
            T[o][i] = 0
            distcent = math.sqrt((cent - i) ^ 2 + (cent - o) ^ 2)

            if distcent < cent - 1 then
                T[o][i] = math.max(((cent - distcent) * height), minimum)
            end
        end
    end

    return T
end


function createCrater(x,y,z,defID)
    if GG.DynDefMap == nil then GG.DynDefMap = {} end
    if GG.DynRefMap == nil then GG.DynRefMap = {} end
    GG.DynDefMap[#GG.DynDefMap + 1] = { creator=UnitDefs[defID].name, 
    x = x / 8, z = z / 8, 
	Size = size, 
	blendType = "sub", 
	filterType = "borderblur" }
    GG.DynRefMap[#GG.DynRefMap + 1] = prepareDeformTable(1024, -8, -4)
    GG.boolForceLandLordUpdate = true
end

function mightyBadaBoom(lastAttackerTeam)

if UnitDefs[unitDefID].name == "physicspayload" then
 	x,y,z = Spring.GetUnitPosition(unitID)

	             Spring.SetProjectileAlwaysVisible (id, true)
	             protagonT = getAllTeamsOfType("protagon", UnitDefs)
	             antagonT = getAllTeamsOfType("antagon", UnitDefs)
	             local rubbleDefID = UnitDefNames["gcscrapheap"].id
	             x, y, z = Spring.GetUnitPosition(unitID)
				Spring.SpawnCeg("nukeshroom", x ,y + 10, z )
				Spring.SpawnCeg("nuclearexplosionbig", x ,y + 100, z )
	             createCrater(x,y,z, unitDefID)
	             for i=1, GameConfig.visuals.falloutParticlesMax do 
	            	valx = math.random(-768, 768)
	            	valz =  math.random(-768, 768)

	            	Spring.SpawnCeg("ashflakes", x + valx, y + 1024 +  math.random(-128, 128), z + valz)
	             end
	             foreach(getAllNearUnit(unitID, GameConfig.payloadDestructionRange ),
	             	function(id)
	             		if not( Spring.GetUnitDefID(id) == rubbleDefID) then
	             			return id
	             		end
	             	end,
				   function(id)						   		
	                    for tid, _ in pairs(protagonT) do
	                        GG.Bank:TransferToTeam(GameConfig.Warhead.DefusalPunishment, tid, id, {r=255,g=0,b=0})
	                    end
               		  GG.UnitsToKill:PushKillUnit(id, true, false)
					end
					)
	              id = createUnitAtUnit(gaiaTeamID, unitID, "nukedecalfactory")
	              Spring.SetUnitAlwaysVisible(id, true)

end

if UnitDefs[unitDefID].name == "biopayload" then
	local AerosolTypes = getChemTrailTypes()

 	foreach(getAllNearUnit(unitID, GameConfig.payloadDestructionRange), 
                        function(id)
                             if aerosolAffectableUnits[Spring.GetUnitDefID(id)] and
                                    not GG.AerosolAffectedCivilians[id] then -- you can only get infected once
                                if setAerosolCivilianBehaviour(id,  AerosolTypes.wanderlost) == true then
                                GG.AerosolAffectedCivilians[id] = AerosolTypes.wanderlost
								for i=1,3 do
									spawnCegAtUnit(id, "wanderlost", math.random(10,35)*randSign(), 50, math.random(10,35)*randSign())
								end

								return id
                              end
                            end
                        end)
end

if UnitDefs[unitDefID].name == "informationpayload" then
	
 	foreach(Spring.GetAllUnits(),
                        function(id)
                        	defID = Spring.GetUnitDefID(id)
                        	 if houseTypeTable[defID] then
                        	 	distance = distanceUnitToUnit(unitID, id)
                        	   stunUnit(id, GameConfig.Warhead.automationPayloadStunTimeSeconds)
                        	   genericCallUnitFunctionPassArgs(unitID, "stunHouse", 30000, math.max(1000, math.ceil(distance)))
                        	end	

                             if automationPayloadDisabledType[defID] then
                                stunUnit(id, GameConfig.Warhead.automationPayloadStunTimeSeconds)
                                spawnCegAtUnit(id, "electric_explosion",0, 50, 0)
                              end  
								
							 if automationPayloadDestroyedType[defID] then
								spawnCegAtUnit(id, "electric_explosion")
							 	GG.UnitsToKill:PushKillUnit(id, false, true)                             
                              end
                        	end)

end


						Spring.DestroyUnit(unitID, false, true)
end

--Explode on Impact
function script.HitByWeapon(x, z, weaponDefID, damage) 
    hp,maxHp= Spring.GetUnitHealth(unitID)
        if hp - damage < maxHp/2 then
           lastAttacker = Spring.GetUnitLastAttacker(unitID)
           attackerTeam = Spring.GetUnitTeam(lastAttacker)
           mightyBadaBoom(attackerTeam)
        end
return damage
end


local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local center = piece("center")

typeDependentTable = {
	["potemkinpayload"] = { piece("PhysicsPayload")},
	["biopayload"] = { piece("BioPayload")},
	["physicspayload"] = { piece("PhysicsPayload")},
	["informationpayload"] = { piece("InfoPayload")},
}

function showTypeDependantWarhead()
	Hide(center)
	showTypeDependent(unitID, typeDependentTable)
end


RepairDefuseRod = piece"RepairDefuseRod"
HereBeDragons = piece"HereBeDragons"

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    showTypeDependantWarhead()
    Spring.SetUnitAlwaysVisible(unitID, true)
    showTypeDependantWarhead()
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
     StartThread(defuseStateMachine)
     hideT(TablesOfPiecesGroups["ProgressBars"])
     hideT(TablesOfPiecesGroups["BaseRotor"])
     StartThread(PlaySoundByUnitDefID, unitDefID,
                            "sounds/icons/warhead_created.ogg", 1,
                            500, 2)
     if boolIsAITeam then StartThread(moveAItoLauncher) end
end

local realRadii = {}

lastFrame = Spring.GetGameFrame()
local copyGGDisguisedCivilianFor
function isUnitDisguised(id)
	if Spring.GetGameFrame() ~= lastFrame then
		lastFrame =  Spring.GetGameFrame()
		copyGGDisguisedCivilianFor = GG.DisguiseCivilianFor
	end

	if copyGGDisguisedCivilianFor then
		for disguiseID, operator in pairs (copyGGDisguisedCivilianFor) do
			if operator == id then
				return true
			end
		end
	end

	return false
end

local function GetUnitDefRealRadius(udid)
  local radius = realRadii[udid]
  if (radius) then
    return radius
  end

  local ud = UnitDefs[udid]
  if (ud == nil) then return nil end

  local dims = Spring.GetUnitDefDimensions(udid)
  if (dims == nil) then return nil end

  local scale = ud.hitSphereScale -- missing in 0.76b1+
  scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
  radius = dims.radius / scale
  realRadii[udid] = radius
  return radius
end

function registerBombLocationAndProducer(unitID)
                local Location = {}
                Location.x, Location.y, Location.z = Spring.GetUnitBasePosition(unitID)
                Location.teamID = Spring.GetUnitTeam(unitID)
                Location.radius = GetUnitDefRealRadius(unitID)

                local revealedUnits = {}
				if GG.PayloadParents then
					parent = GG.PayloadParents[unitID]
					if parent and doesUnitExistAlive(parent) then
						revealedUnits[parent] = {defID = Spring.GetUnitDefID(parent), boolIsParent = true}
					end
                end

                Location.revealedUnits = revealedUnits 	
				Location.endFrame = Spring.GetGameFrame()+ GG.GameConfig.raid.revealGraphLifeTimeFrames

                if not GG.RevealedLocations then GG.RevealedLocations = {} end
                GG.RevealedLocations[#GG.RevealedLocations + 1] = Location
            end


function displayProgressBar(timeInMs)
  -- display the Progressbars		
  		Show(BaseRotor)																						
        progressBarIndex = math.ceil(#TablesOfPiecesGroups["ProgressBars"]* (timeInMs/GameConfig.Warhead.DefusalTimeMs))
        hideT(TablesOfPiecesGroups["ProgressBars"])
        showT(TablesOfPiecesGroups["ProgressBars"], 1, math.max(1,progressBarIndex))
end

function getOperatorsNearby(unitID)
	Allies = {}
	Enemies = {}
	foreach(getAllNearUnit(unitID, GameConfig.Warhead.DefusalStartDistance),
				   function(id)			
					   defID = spGetUnitDefID(id)
					   pTeamID = spGetUnitTeam(id) 
					   if defuseCapableUnitTypes[defID] then
						  if pTeamID == myTeamID then
						  	Allies[#Allies+1] = id
						  else
							Enemies[#Enemies+1] = id
						  end
					   end						
					end						
					)

	return Allies, Enemies
end

function showWarHeadIcon()	
	showT(TablesOfPiecesGroups["WarHead"])
	Show(HereBeDragons)
end

openDistance = 500
function openWarHeadDefusalRepair()
	for i=2, #TablesOfPiecesGroups["WarHead"] do
		Move(TablesOfPiecesGroups["WarHead"][i], y_axis, openDistance, 500)
	end
	WaitForMoves(TablesOfPiecesGroups["WarHead"])
	Show(RepairDefuseRod)
end

function closeWarhead()
	Hide(RepairDefuseRod)
	resetT(TablesOfPiecesGroups["WarHead"], 500)	
end

function hideWarHeadIcon()
	hideT(TablesOfPiecesGroups["WarHead"])
end


function showDefusalIcon()
	hideAllLogos()
	StartThread(openWarHeadDefusalRepair)
	showT(TablesOfPiecesGroups["DefuseRotor"])
	spinT(TablesOfPiecesGroups["DefuseRotor"],y_axis, 25, 5, 25)
end

function hideAllLogos()
	hideT(TablesOfPiecesGroups["DefuseRotor"])
	hideT(TablesOfPiecesGroups["RepairRotor"])
	hideT(TablesOfPiecesGroups["DamagedRotor"])
	hideT(TablesOfPiecesGroups["DormantRotor"])
	Hide(BaseRotor)
end

function showRepairIcon()
	hideAllLogos()
	Show(BaseRotor)	
	StartThread(openWarHeadDefusalRepair)
	showT(TablesOfPiecesGroups["RepairRotor"],y_axis, 25, 5, 25)
	spinT(TablesOfPiecesGroups["RepairRotor"],y_axis, 25, 5, 25)
end

function showDormantIcon()
	hideAllLogos()
	closeWarhead()
	showT(TablesOfPiecesGroups["DormantRotor"])
	spinT(TablesOfPiecesGroups["DormantRotor"],y_axis, 25, 5, 25)
	Hide(BaseRotor)
	hideT(TablesOfPiecesGroups["ProgressBars"])
end

function showDamagedIcon()
	hideAllLogos()
	Show(BaseRotor)	
	openWarHeadDefusalRepair()
	showT(TablesOfPiecesGroups["DamagedRotor"])
	spinT(TablesOfPiecesGroups["DamagedRotor"],y_axis, 25, 5, 25)
end


defuseStatesMachine = {
    dormant =   function(oldState, frame, persPack)
                    nextState = "dormant"

					Allies, Enemies = getOperatorsNearby(unitID)

					-- if both sides are nearby do nothing
					if #Allies > 0 and #Enemies > 0 then
						return "dormant", persPack
					end


					if #Enemies > 0 then
						StartThread(showDefusalIcon)
						Spring.SetUnitAlwaysVisible(unitID, true)
						return "defuse_in_progress", persPack
					end
	
					if #Allies > 0 and persPack.defuseTimeMs < GameConfig.Warhead.DefusalTimeMs then
						StartThread(showRepairIcon)
						Spring.SetUnitAlwaysVisible(unitID, true)
						return "repair_in_progress", persPack
					end

					if persPack.defuseTimeMs < GameConfig.Warhead.DefusalTimeMs then

						StartThread(showDamagedIcon)
						return "kaputt", persPack
					end					
							
					return nextState, persPack
					end,
					
    defuse_in_progress= function(oldState, frame, persPack)
						nextState = "defuse_in_progress"

						Allies, Enemies = getOperatorsNearby(unitID)
						if #Allies > 0 and #Enemies > 0 then
							return "dormant", persPack
						end
						
						if #Allies > 0 then
							StartThread(showRepairIcon)
							Spring.SetUnitAlwaysVisible(unitID, true)
							return "repair_in_progress", persPack
						end

						if #Enemies == 0 then
							StartThread(showDamagedIcon)
							Spring.SetUnitAlwaysVisible(unitID, true)
							return "kaputt", persPack
						end
					
                      	persPack.defuseTimeMs = persPack.defuseTimeMs - 100
						
						displayProgressBar( persPack.defuseTimeMs)
						if  not persPack.soundStart and persPack.defuseTimeMs < 12000  then
							persPack.soundStart = true
					        StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/icons/warhead_defusal"..math.random(1,2)..".ogg", 1,  25000, 2)
						end

						if persPack.defuseTimeMs <= 0 then --"defused"
							-- show Graph
							 registerBombLocationAndProducer(unitID)
							-- Reward Defuser Team
							GG.Bank:TransferToTeam(GameConfig.PayloadDefusedReward, Spring.GetUnitTeam(Enemies[1]), Enemies[1], {r=255,g=255,b=255})
							--DestroyUnit
							Spring.DestroyUnit(unitID, false, true)
						end

							return nextState, persPack
						end,
	repair_in_progress= function(oldState, frame, persPack)
			nextState = "repair_in_progress"

			Allies, Enemies = getOperatorsNearby(unitID)
			if #Allies == 0 or #Allies > 0 and #Enemies > 0 then
				StartThread(showDamagedIcon)
				return "kaputt", persPack
			end
							
	
			persPack.defuseTimeMs = persPack.defuseTimeMs + 100
			displayProgressBar(persPack.defuseTimeMs)
			
			if persPack.defuseTimeMs > GameConfig.Warhead.DefusalTimeMs then
				StartThread(showDormantIcon)
				return "dormant", persPack
			end
			 
		
        return nextState, persPack
    end,

    kaputt = function(oldState, frame, persPack)
    	nextState = "kaputt"
		Allies, Enemies = getOperatorsNearby(unitID)
		if  #Allies > 0 and #Enemies > 0 then
			return "kaputt", persPack
		end

		if  #Allies > 0  then
			StartThread(showRepairIcon)
			return "repair_in_progress", persPack
		end

		if  #Enemies > 0  then
			StartThread(showDefusalIcon)
			return "defuse_in_progress", persPack
		end

    	return nextState, persPack
    end
  
}


--Reveal Productionplace, Propagandaplus

function defuseStateMachine()
	if not GG.WarHeadState then GG.WarHeadState = {} end
    myTeamID = Spring.GetUnitTeam(unitID)
    currentState = "dormant"
    StartThread(showDormantIcon)
    persPack={defuseTimeMs = GameConfig.Warhead.DefusalTimeMs}
    while true do
     newState, persPack = defuseStatesMachine[currentState](currentState, Spring.GetGameFrame(), persPack)
     GG.WarHeadState[unitID] = newState
     -- if currentState ~= newState then	  echo("defuseStatesMachine in "..currentState) end
	  currentState = newState
	 -- echo("defuseStatesMachine alive: with "..currentState)
	  Sleep(100)
     	if not Spring.GetUnitTransporter(unitID) then
      	 --detect transports nearby and autoload
      	 boolLoaded = false
      	 foreach(getAllNearUnit(unitID, 75),
      	 			function(id)
      	 				if boolLoaded ==true then return end
      	 				if spGetUnitTeam(id) == myTeamID and TruckTypeTable[spGetUnitDefID(id)] then
  	 					    pieceMap = Spring.GetUnitPieceMap(id)
       						assert(pieceMap["attachPoint"])
       						Spring.UnitAttach(id, unitID, pieceMap["attachPoint"])
							boolLoaded= true
      	 				end
      	 			end
      	 		)
     	end
    end
end

function script.Killed(recentDamage, _)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

-- function script.QueryBuildInfo()
-- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

