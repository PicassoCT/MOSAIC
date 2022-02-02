include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
local operativeTypeTable = getOperativeTypeTable(Unitdefs)
local GameConfig = getGameConfig()

--Explode on Impact
function script.HitByWeapon(x, z, weaponDefID, damage) 
return damage
end
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local myDefID = spGetUnitDefID(unitID)
center = piece"center"

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitAlwaysVisible(unitID,true)
    Spring.MoveCtrl.Enable(unitID,true)
    x,y,z =Spring.GetUnitPosition(unitID)
    Spring.MoveCtrl.SetPosition(unitID, x,y+25,z)
    Show(center)
     showT(TablesOfPiecesGroups["Rotor"])
     StartThread(lifeTime, unitID, 3*60*1000, true, false)
     StartThread(checkForFinderLoop)
end

local realRadii = {}

lastFrame = Spring.GetGameFrame()


function revealUnitsIfOfTeam(finderID)
	unitTeam = Spring.GetUnitTeam(unitID)
	children = getChildrenOfUnit(unitTeam, unitID)
    parent = getParentOfUnit(unitTeam, unitID)

    if parent and Spring.GetUnitTeam(finderID) == Spring.GetUnitTeam(parent) then -- caught by own team - no reveal
    	Spring.DestroyUnit(unitID, true)
    	return
    end

    registerRevealedUnitLocation(persPack.unitID)

    for childID, v in pairs(children) do
        echo("DeadDrop: Reavealing child " .. childID)
        if doesUnitExistAlive(childID) == true then
            Spring.GiveOrderToUnit(childID, CMD.CLOAK, {}, {})
            GG.OperativesDiscovered[childID] = true
            Spring.SetUnitAlwaysVisible(childID, true)
        end
    end

    if doesUnitExistAlive(parent) == true then
        Spring.GiveOrderToUnit(parent, CMD.CLOAK, {}, {})
        GG.OperativesDiscovered[parent] = true
        Spring.SetUnitAlwaysVisible(parent, true)
    end
end

function checkForFinderLoop()
  -- display the Progressbars																					
	for i=1,#TablesOfPiecesGroups["Rotor"] do
		val = math.random(15,50)
		Spin(TablesOfPiecesGroups["Rotor"][i],y_axis,math.rad(val)*randSign(),0)
	end
	
	boolDone = false
	while boolDone == false do
	 UnitsNear= foreach(
	 				getAllNearUnit(unitID, GameConfig.WarheadDefusalStartDistance ),
				   function(id)
					   if operativeTypeTable[spGetUnitDefID(id)] then
					    return id 
						end
					end
					)
	 Sleep(100)
	 if #UnitsNear > 0 then
	 	boolDone = true
	 	revealUnitsIfOfTeam()
	 	return
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

