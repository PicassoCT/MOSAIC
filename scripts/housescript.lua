include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"


function script.Create()
	
	StartThread(buildHouse)
end

function buildHouse()
resetAll(unitID)
Sleep(1)
	hideAll(unitID)
        TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
		
         buildBuilding()
	 StartThread(showPowerPoles)
end

function absdiff(value, compval)
  if value < compval then 
    return math.abs(compval - value)
  end
return math.abs( value - compval) 
end

function showPowerPoles()
	Sleep(1)
	startHeigth= getUnitGroundHeigth(unitID)
	WTurn(TablesOfPiecesGroups["PowerPole"][1],z_axis, math.rad(math.random(-360,360)),0)
	process(TablesOfPiecesGroups["PowerPole"],
			function(id)
					if id == TablesOfPiecesGroups["PowerPole"][1] then return end
				thisHeigth= getGroundHeigthAtPiece(unitID,id)
				diff  = absdiff(startHeigth , thisHeigth)
				Spring.Echo("Diff:"..diff)
				if diff < 100 then
					WTurn(id,z_axis, math.rad(math.random(-10,10)),0)
					Show(id)
				else
					value=randSign()*math.random(70,90)
					WTurn(id,z_axis, math.rad(value),0)
					diff  = absdiff(startHeigth , thisHeigth)
					if diff < 100 then
						Show(id)
					end
				end
			end
			)
			

end

function script.Killed(recentDamage, _)
    createCorpseCUnitGeneric(recentDamage)
    return 1
end

function showOne(T)
  if not T then return end
dice = math.random(1,#T)
Show(T[dice])
return dice
end

function showOneOrNone(T)
	if not T then return end
	if math.random(1,100) > 50 then
	  return showOne(T)
	else
	  return
	end
end


function selectBase()
	showOne(TablesOfPiecesGroups["base"])
end

function selectBackYard()
	showOneOrNone(TablesOfPiecesGroups["back"])
end




function removeElementFromBuildMaterial(element, buildMaterial)
		local result = process(buildMaterial,
					function(id) 
						if id ~= element then 
							return id
						end
				    end
				    )
return result
end

function selectGroundBuildMaterial( )
  diceTable ={ "FloorBlock", "BrownFloorBlock", "WhiteFloorBlock", "RedFloorBLock"}
  dice = diceTable[math.random(1,#diceTable)]
  dice = "FloorBlock"
  return TablesOfPiecesGroups[dice], dice
end
function selectBuildMaterial(dice)
  diceTable ={ "FloorBlock", "BrownFloorBlock", "YellowFloorBlock", "RedFloorBLock"}
 
  return TablesOfPiecesGroups[dice], dice
end

function DecorateDoor(element,xRealLoc,zRealLoc, xLoc,zLoc)
 
end

function DecorateStreet(element,xRealLoc,zRealLoc, xLoc,zLoc) 

end

function getRandomBuildMaterial(buildMaterial)
 
 if not buildMaterial then return end
  total = count(buildMaterial)
 if total == 0 then  return end 
 
 
 dice = math.random(1,total)
 total =0
 for k,v in pairs (buildMaterial) do 
	
	total = total + 1
	if total == dice then
		return v
	end
 end

end

-- x:0-6 z:0-6   
function  getLocationInPlan(index)

	if index < 7 then
		return true, (index - 1),  0
	end
	
	if index > 30 and index < 37 then
		return true,   ((index -30) - 1), 5
	end

	if (index % 6) == 1 and ( index < 37 and index > 6)then
		return true, 0 , math.floor( (index-1)/6.0)
	end

	if (index % 6) == 0 and ( index < 37 and index > 6) then
		return true, 5 ,  math.floor((index-1)/6.0)
	end
	
	return false, 0, 0
end

function buildDecorateGroundLvl()
	local cubeDim ={length = 14.5, heigth= 8}
	centerP = {x = (cubeDim.length/2) * 5, z= (cubeDim.length/2) *  5}

	buildMaterial = {} 
	buildMaterial, materialGroup = selectGroundBuildMaterial()
	countElements= 0

		for i=1, 37, 1 do
			local index = i
			partOfPlan, xLoc,zLoc= getLocationInPlan(index)
			echo(xLoc.."/"..zLoc)
			if partOfPlan == true then
				xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length) 
				local element = getRandomBuildMaterial(buildMaterial)
				while not element do
					element = getRandomBuildMaterial(buildMaterial)
					Sleep(1)
				end
				
				if element then
					countElements = countElements+1
					buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
					Move(element, 1, xRealLoc, 0)
					Move(element, 3, zRealLoc, 0)
					Show(element)
					if countElements == 24 then return materialGroup end
				end
				--DecorateDoor(element,xRealLoc,zRealLoc, xLoc,zLoc)
				--DecorateStreet(element,xRealLoc,zRealLoc, xLoc,zLoc)
			end
		end
		
	return materialGroup
end

function buildDecorateLvl(Level, materialGroup)

end

function decorateLvl(lvl)
end
function decorateBackYard()

end
	
function buildBuilding()
	selectBase()
	selectBackYard()
	-- decorateBackYard()
materialGroup= buildDecorateGroundLvl()

	--for i=1, 2 do
	--	buildDecorateLvl(i, materialGroup)
	--	decorateLvl(i)
	--end

end
function script.StartMoving()
end

function script.StopMoving()
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

