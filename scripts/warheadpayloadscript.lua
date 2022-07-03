include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
local defuseCapableUnitTypes = getDefusalCapableTypeTable(Unitdefs)
local GameConfig = getGameConfig()
local WarnText = piece"WarnText"
local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "truck", UnitDefs)
local aerosolAffectableUnits = getChemTrailInfluencedTypes(UnitDefs)
local spGetTeamInfo = Spring.GetTeamInfo
local myTeamID = Spring.GetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local automationPayloadDisabledType = getAutomationPayloadDisabledType(UnitDefs)
local automationPayloadDestroyedType = getAutomationPayloadDestroyedType(UnitDefs)
 launcherDefID = UnitDefNames["launcher"].id
 boolIsAITeam = isTeamAITeam(Spring.GetUnitTeam(unitID))

function moveAItoLauncher()	
	goal = unitID
	while goal == unitID do
	smallestDistance = math.huge
	foreach(Spring.GetTeamUnitsByDefs(myTeamID,launcherDefID),
						function(id)
							dist = distanceUnitToUnit(id, unitID)
							if dist < smallestDistance then 
								smallestDistance = dist
								goal = id
								return id
							end
						end
			)

	Sleep(250)
	end

		factor = 0.0
	while true do
		goalV= {}
		goalV.x,goalV.y,goalV.z = Spring.GetUnitPosition(goal)
		myPosV= {}
		myPosV.x,myPosV.y,myPosV.z = Spring.GetUnitPosition(unitID)
		resultV = mix(goalV, myPosV, factor)
		Spring.SetUnitPosition(unitID, resultV.x, resultV.y, resultV.z)
		factor = math.min(1.0, factor + 0.01)
		Sleep(1000)
	end
end

function mightyBadaBoom()
myDefID = Spring.GetUnitDefID(unitID)

if UnitDefs[myDefID].name == "physicspayload" then
 x,y,z = Spring.GetUnitPosition(unitID)
            weaponDefID = WeaponDefNames["godrod"].id
                        local params = {
                            pos = { x,  y + 10,  z},
                           ["end"] = { x,  y+ 5,  z},
                        speed = {0,0,0},
                        spread = {0,0,0},
                        error = {0,0,0},
                        owner = unitID,
                        team = myTeamID,
                        ttl = 1,
                        gravity = 1.0,
                        tracking = unitID,
                        maxRange = 9000,
                        startAlpha = 0.0,
                        endAlpha = 0.1,
                        model = "emptyObjectIsEmpty.s3o",
                        cegTag = ""
                        }

                        id=Spring.SpawnProjectile ( weaponDefID, params) 
                        Spring.SetProjectileAlwaysVisible (id, true)
                         protagonT = getAllTeamsOfType("protagon", UnitDefs)
                         antagonT = getAllTeamsOfType("antagon", UnitDefs)
                         local rubbleDefID = UnitDefNames["gcscrapheap"].id

                         foreach(getAllNearUnit(unitID, GameConfig.payloadDestructionRange ),
                         	function(id)
                         		if not( Spring.GetUnitDefID(id) == rubbleDefID) then
                         			return id
                         		end
                         	end,
						   function(id)
	                            for tid, _ in pairs(protagonT) do
	                                GG.Bank:TransferToTeam(GameConfig.Warhead.DefusalPunishment, tid,
	                                                       id, {r=255,g=255,b=255})
	                            end
	                            for tid, _ in pairs(antagonT) do
	                                GG.Bank:TransferToTeam(GameConfig.Warhead.DefusalPunishment, tid,
	                                                       id, {r=255,g=255,b=255})
	                            end

							  Spring.DestroyUnit(id, true, false)
							end)

end

if UnitDefs[myDefID].name == "biopayload" then
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

if UnitDefs[myDefID].name == "informationpayload" then
	
 	foreach(Spring.GetAllUnits(),
                        function(id)
                        	defID = Spring.GetUnitDefID(id)
                             if automationPayloadDisabledType[defID] then
                                stunUnit(id, GameConfig.Warhead.automationPayloadStunTimeSeconds)
                                spawnCegAtUnit(id, "electric_explosion",0, 50, 0)
                              end  
								
							 if automationPayloadDestroyedType[defID] then
                              	Spring.DestroyUnit(id, false, true)
                              	spawnCegAtUnit(id, "electric_explosion")
                              end
                        	end)

end


						Spring.DestroyUnit(unitID, false, true)
end

--Explode on Impact
function script.HitByWeapon(x, z, weaponDefID, damage) 
    hp,maxHp= Spring.GetUnitHealth(unitID)
        if hp - damage < maxHp/2 then
           mightyBadaBoom()
        end
return damage
end
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local myDefID = spGetUnitDefID(unitID)


function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitAlwaysVisible(unitID, true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
     StartThread(defuseStateMachine)
     hideT(TablesOfPiecesGroups["ProgressBars"])
     hideT(TablesOfPiecesGroups["Rotor"])
     StartThread(PlaySoundByUnitDefID, myDefID,
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

function isTeamProtagon(teamID, defID)
	  return (select(5, spGetTeamInfo(teamID)) == "protagon") or UnitDefs[defID].name == "operativeinvestigator"
end   



function displayProgressBar(timeInMs)
  -- display the Progressbars																								
        progressBarIndex = math.ceil(#TablesOfPiecesGroups["ProgressBars"]* (timeInMs/GameConfig.Warhead.DefusalTimeMs))
        hideT(TablesOfPiecesGroups["ProgressBars"])
        showT(TablesOfPiecesGroups["ProgressBars"], 1, math.max(1,progressBarIndex))
end

boolDefuseThreadRunning = false
defuseStatesMachine = {
    dormant =   function(oldState, frame, persPack)
                    nextState = "dormant"
					
					boolFoundSomething = false
					
					 foreach(getAllNearUnit(unitID, GameConfig.Warhead.DefusalStartDistance ),
						   function(id)
							   if boolFoundSomething == true then return end
							   defID = spGetUnitDefID(id)
							   	  teamID = spGetUnitTeam(id)
								 if teamID ~= myTeamID and defuseCapableUnitTypes[defID] and isTeamProtagon(teamID, defID)  then -- 
									boolFoundSomething = true
									 persPack.defuserID = id 
									  persPack.defuseTimeMs = GameConfig.Warhead.DefusalTimeMs 
										showT(TablesOfPiecesGroups["Rotor"])
										for i=1,#TablesOfPiecesGroups["Rotor"] do
											val = math.random(15,50)
											Spin(TablesOfPiecesGroups["Rotor"][i],y_axis,math.rad(val)*randSign(),0)
										end
										Spring.SetUnitAlwaysVisible(unitID, true)
										nextState = "defuse_in_progress"
										Hide(WarnText)
								   end
							end)
							
						return nextState, persPack
					end,
					
    defuse_in_progress= function(oldState, frame, persPack)
						nextState = "defuse_in_progress"
						if doesUnitExistAlive( persPack.defuserID) == false then
							hideT(TablesOfPiecesGroups["Rotor"])
			
							return "decay_in_progress", persPack
						end
						
                        if distanceUnitToUnit( persPack.defuserID, unitID) > GameConfig.Warhead.DefusalStartDistance then
                            if persPack.defuseTimeMs/ GameConfig.Warhead.DefusalTimeMs > 0.2 then
							hideT(TablesOfPiecesGroups["Rotor"])		
							Show(WarnText)				
                             return "decay_in_progress", persPack
                            else
                                hideT(TablesOfPiecesGroups["Rotor"])		
                                return "dormant", persPack
                            end
						end
						persPack.defuseTimeMs = persPack.defuseTimeMs - 100
						
						displayProgressBar( persPack.defuseTimeMs)
						if  not persPack.soundStart and persPack.defuseTimeMs < 12000  then
							persPack.soundStart = true
					        StartThread(PlaySoundByUnitDefID, myDefID,
                                    "sounds/icons/warhead_defusal"..math.random(1,2)..".ogg", 1,
                                    25000, 2)
						end

						if persPack.defuseTimeMs <= 0 then --"defused"
							-- show Graph
							 registerBombLocationAndProducer(unitID)
							-- Reward Defuser Team
							GG.Bank:TransferToTeam(GameConfig.PayloadDefusedReward, Spring.GetUnitTeam(persPack.defuserID), persPack.defuserID, {r=255,g=255,b=255})
							--DestroyUnit
							Spring.DestroyUnit(unitID, false, true)
						end

							return nextState, persPack
						end,
		decay_in_progress= function(oldState, frame, persPack)
			nextState = "decay_in_progress"
			
			persPack.defuseTimeMs = persPack.defuseTimeMs + 100
			displayProgressBar(persPack.defuseTimeMs)
			
			if persPack.defuseTimeMs > GameConfig.Warhead.DefusalTimeMs then
				mightyBadaBoom()
			end
			
			boolFoundFoe = false
			boolFoundFriend = false
			 foreach(getAllNearUnit(unitID, GameConfig.Warhead.DefusalStartDistance ),
			   function(id)
				if boolFoundFoe or boolFoundFriend then return end
		
				   defID = spGetUnitDefID(id)
				   pTeamID = spGetUnitTeam(id) 
					 if pTeamID == myTeamID and defuseCapableUnitTypes[defID] and not boolFoundFriend then
							hideT(TablesOfPiecesGroups["Rotor"])
							boolFoundFriend = true
							nextState = "dormant"
							Hide(WarnText)
					   end
					   
					  if  pTeamID ~= myTeamID and defuseCapableUnitTypes[defID] and not boolFoundFoe then
							showT(TablesOfPiecesGroups["Rotor"])
							boolFoundFoe = true
							nextState = "defuse_in_progress"
							Hide(WarnText)
					   end
				end)
		
        return nextState, persPack
    end,
  
}

--Reveal Productionplace, Propagandaplus

function defuseStateMachine()
    myTeamID = Spring.GetUnitTeam(unitID)
    currentState = "dormant"
    Hide(WarnText)
    persPack={}
    while true do
      newState, persPack = defuseStatesMachine[currentState](currentState, Spring.GetGameFrame(), persPack)
     -- if currentState ~= newState then	  echo("defuseStatesMachine in "..currentState) end
	  currentState = newState
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

    -- createCorpseCUnitGeneric(recentDamage)
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

