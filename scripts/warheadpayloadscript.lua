include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
defuseCapableUnitTypes = getOperativeTypeTable(Unitdefs)
GameConfig = getGameConfig()
WarnText = piece"WarnText"

function mightyBadaBoom()
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


                         process(getAllNearUnit(unitID, 333 ),
						   function(id)
	                            for tid, _ in pairs(protagonT) do
	                                GG.Bank:TransferToTeam(GameConfig.WarheadDefusalPunishment, tid,
	                                                       id, {r=255,g=255,b=255})
	                            end
	                            for tid, _ in pairs(antagonT) do
	                                GG.Bank:TransferToTeam(GameConfig.WarheadDefusalPunishment, tid,
	                                                       id, {r=255,g=255,b=255})
	                            end

							  Spring.DestroyUnit(id, true, false)
							end)
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

    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
     StartThread(defuseStateMachine)
     hideT(TablesOfPiecesGroups["ProgressBars"])
     hideT(TablesOfPiecesGroups["Rotor"])
    StartThread(PlaySoundByUnitDefID, myDefID,
                            "sounds/icons/warhead_created.ogg", 1,
                            500, 2)
end

local realRadii = {}


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
        progressBarIndex = math.ceil(#TablesOfPiecesGroups["ProgressBars"]* (timeInMs/GameConfig.WarheadDefusalTimeMs))
        hideT(TablesOfPiecesGroups["ProgressBars"])
        showT(TablesOfPiecesGroups["ProgressBars"], 1, math.max(1,progressBarIndex))
end

boolDefuseThreadRunning = false
defuseStatesMachine = {
    dormant =   function(oldState, frame, persPack)
                    nextState = "dormant"
					
					boolFoundSomething = false
					
					 process(getAllNearUnit(unitID, GameConfig.WarheadDefusalStartDistance ),
						   function(id)
							   if boolFoundSomething == true then return end
							   defID = spGetUnitDefID(id)
								 if  spGetUnitTeam(id) ~= myTeamID and defuseCapableUnitTypes[defID]  then
									boolFoundSomething = true
									 persPack.defuserID = id 
									  persPack.defuseTimeMs = GameConfig.WarheadDefusalTimeMs 
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
						
                        if distanceUnitToUnit( persPack.defuserID, unitID) > GameConfig.WarheadDefusalStartDistance then
                            if persPack.defuseTimeMs/ GameConfig.WarheadDefusalTimeMs > 0.2 then
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
			
			if persPack.defuseTimeMs > GameConfig.WarheadDefusalTimeMs then
				mightyBadaBoom()
			end
			
			boolFoundFoe = false
			boolFoundFriend = false
			 process(getAllNearUnit(unitID, GameConfig.WarheadDefusalStartDistance ),
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
	  currentState = newState
       Sleep(100)
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
