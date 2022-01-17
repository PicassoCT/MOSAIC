include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
local defuseCapableUnitTypes = getOperativeTypeTable(Unitdefs)
local GameConfig = getGameConfig()

--Explode on Impact
function script.HitByWeapon(x, z, weaponDefID, damage) 
return damage
end
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local myDefID = spGetUnitDefID(unitID)


function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitAlwaysVisible(unitID,true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
     hideT(TablesOfPiecesGroups["ProgressBars"])
     showT(TablesOfPiecesGroups["Rotor"])
end

local realRadii = {}

lastFrame = Spring.GetGameFrame()

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

function revealUnitsIfOfTeam()
	unitTeam = Spring.GetUnitTeam(unitID)
		children = getChildrenOfUnit(unitTeam, unitID)
    parent = getParentOfUnit(unitTeam, unitID)
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

    -- out of time to interrogate
    for disguiseID, agentID in pairs(GG.DisguiseCivilianFor) do
        if unitID == agentID then
            Spring.DestroyUnit(disguiseID, false, true)
            GG.DisguiseCivilianFor[disguiseID] = nil
        end
    end
end

function checkForFinderLoop()
  -- display the Progressbars																					
	showT(TablesOfPiecesGroups["ProgressBars"])
	for i=1,#TablesOfPiecesGroups["Rotor"] do
		val = math.random(15,50)
		Spin(TablesOfPiecesGroups["Rotor"][i],y_axis,math.rad(val)*randSign(),0)
	end
	
	boolDone = false
	while boolDone == false do
	 UnitsNear= process(
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
	 	registerRevealedUnitLocation(unitID)
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

