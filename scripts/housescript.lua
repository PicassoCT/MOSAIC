include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
local cubeDim ={length = 14.5*1.45, heigth= 14 * 0.75*1.45, roofHeigth = 1.5}

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
	Show(TablesOfPiecesGroups["PowerPole"][1])
	
	process(TablesOfPiecesGroups["PowerPole"],
			function(id)
				if id == TablesOfPiecesGroups["PowerPole"][1] then return end
				thisHeigth= getGroundHeigthAtPiece(unitID,id)
				diff  = absdiff(startHeigth , thisHeigth)

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
  diceTable ={ "FloorBlock", "BrownFloorBlock", "WhiteFloorBlock", "RedFloorBlock"}
  dice = diceTable[math.random(1,#diceTable)]
  echo(dice)

  return TablesOfPiecesGroups[dice], string.gsub(dice, "FloorBlock", "")
end


function DecorateDoor(element,xRealLoc,zRealLoc, xLoc,zLoc)
 
end

function DecorateStreet(element,xRealLoc,zRealLoc, xLoc,zLoc) 

end

function getRandomBuildMaterial(buildMaterial, orgstring)
	piecegroupName = orgstring or ""
 
 if not buildMaterial then return end
  total = count(buildMaterial)
 if total == 0 then  echo("BuildMaterial exausted");return end 
 
 
 dice = math.random(1,total)
 total =0
 for k,v in pairs (buildMaterial) do 
	
	total = total + 1
	if total == dice then
		return v, piecegroupName..total
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


function  getWallDeocrationRotation(index)

	if index < 7 then
		return 0
	end
	
	if index > 30 and index < 37 then
		return 180
	end

	if (index % 6) == 1 and ( index < 37 and index > 6)then
		return -90
	end

	if (index % 6) == 0 and ( index < 37 and index > 6) then
		return 90
	end
end

function  getRotationOfBlockInPlan(index)
	
	if (index > 30 and index < 37) or (index < 7)  then
		if math.random(0,1)== 1 then
			return 90
		else
			return -90
		end	
	end

	if ((index % 6) == 1 and ( index < 37 and index > 6)) or ((index % 6) == 0 and ( index < 37 and index > 6) )then
		if math.random(0,1)== 1 then
			return 0
		else
			return 180
		end			
	end
end

function buildDecorateGroundLvl()

	centerP = {x = (cubeDim.length/2) * 5, z= (cubeDim.length/2) *  5}

	buildMaterial = {} 
	buildMaterial, materialGroup = selectGroundBuildMaterial()
	countElements= 0

		for i=1, 37, 1 do
			local index = i
			partOfPlan, xLoc,zLoc= getLocationInPlan(index)
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
		
	return materialGroup.."WallBlock"
end

function buildDecorateLvl(Level, materialGroup, buildMaterial)
	
	centerP = {x = (cubeDim.length/2) * 5, z= (cubeDim.length/2) *  5}

	
	countElements= 0

		for i=1, 37, 1 do
			local index = i
			partOfPlan, xLoc,zLoc= getLocationInPlan(index)
			if partOfPlan == true then
				xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length) 
				local element = getRandomBuildMaterial(buildMaterial)
				while not element do
					element = getRandomBuildMaterial(buildMaterial)
					Sleep(1)
				end
				
				if element then
					rotation = getRotationOfBlockInPlan(i)
					countElements = countElements+1
					buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
					Move(element, 1, xRealLoc, 0)
					Move(element, 3, zRealLoc, 0)
					Move(element, 2, Level * cubeDim.heigth , 0)
					WaitForMoves(element)
					Turn(element, 3, math.rad(rotation),0)
					Show(element)
					if countElements == 24 then return materialGroup end
				end
			end
		end
		
	return materialGroup, buildMaterial
end

function decorateLvl(lvl)
end
function decorateBackYard()
end

function addRoofDeocrate(Level, buildMaterial)
	
	centerP = {x = (cubeDim.length/2) * 5, z= (cubeDim.length/2) *  5}

	
	countElements= 0

		for i=1, 37, 1 do
			local index = i
			partOfPlan, xLoc,zLoc= getLocationInPlan(index)
			if partOfPlan == true then
				xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length) 
				local element = getRandomBuildMaterial(buildMaterial)
				while not element do
					element = getRandomBuildMaterial(buildMaterial)
					Sleep(1)
				end
				
				if element then
					rotation = getRotationOfBlockInPlan(i)
					countElements = countElements+1
					buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
					Move(element, 1, xRealLoc, 0)
					Move(element, 3, zRealLoc, 0)
					Move(element, 2, Level * cubeDim.heigth -0.5 , 0)
					WaitForMoves(element)
					Turn(element, 3, math.rad(rotation),0)
					Show(element)
					if countElements == 24 then break; end
				end
			end
		end
	countElements= 0	
	local 	decoMaterial = TablesOfPiecesGroups["RoofDeco"]
		
		for i=1, 37, 1 do
			partOfPlan, xLoc,zLoc= getLocationInPlan(i)
			if partOfPlan == true  then
				xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length), -centerP.z + (zLoc* cubeDim.length) 
				local element, piecename = getRandomBuildMaterial(decoMaterial,"RoofDeco")
				while not element do
					element, piecename = getRandomBuildMaterial(decoMaterial,"RoofDeco")
					Sleep(1)
				end
				
				if element and math.random(0,10) > 5 then
					rotation = getRotationOfBlockInPlan(i)
					countElements = countElements+1
					decoMaterial = removeElementFromBuildMaterial(element, decoMaterial)
					Move(element, 1, xRealLoc, 0)
					Move(element, 3, zRealLoc, 0)
					Move(element, 2, Level * cubeDim.heigth -0.5 +cubeDim.roofHeigth , 0)
					WaitForMoves(element)
					if TablesOfPiecesGroups[piecename.."sub"] then
						showT(TablesOfPiecesGroups[piecename.."sub"])
					end
					
					if TablesOfPiecesGroups[piecename.."Sub"] then
						showT(TablesOfPiecesGroups[piecename.."Sub"])
					end
					-- 
					-- Turn(element, 3, math.rad(rotation),0)
					Show(element)
					if countElements == 24 then return  end
				end
			end
		end
		
	
end
	
function buildBuilding()
	selectBase()
	selectBackYard()
	-- decorateBackYard()
	materialGroup= buildDecorateGroundLvl()

	buildMaterial = TablesOfPiecesGroups[materialGroup]
	for i=1, 2 do
		materialGroup, buildMaterial = buildDecorateLvl(i, materialGroup, buildMaterial)
	end
	
	addRoofDeocrate(3, TablesOfPiecesGroups[string.gsub(materialGroup,"WallBlock","").."Roof"])

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

