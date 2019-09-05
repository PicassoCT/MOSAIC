include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
local cubeDim ={length = 14.4 *1.45, heigth= 13.65 * 0.75*1.45, roofHeigth = 2.5}
decoChances={ roof = 0.5, yard = 0.3, street = 1, powerpoles = 0.5, door = 0.6, windowwall= 0.7}
ToShowTable ={}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

AlreadyUsedPiece ={}
center = piece "center"


function script.Create()

  StartThread(buildHouse)
end

function buildHouse()
  resetAll(unitID)
  hideAll(unitID)
  Sleep(1)

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
  if chancesAre(10) < decoChances.powerpoles then return end

  startHeigth= getUnitGroundHeigth(unitID)
  WTurn(TablesOfPiecesGroups["PowerPole"][1],z_axis, math.rad(math.random(-360,360)),0)
  ToShowTable[#ToShowTable+1]=TablesOfPiecesGroups["PowerPole"][1]

  process(TablesOfPiecesGroups["PowerPole"],
  function(id)
    if id == TablesOfPiecesGroups["PowerPole"][1] then return end
    thisHeigth= getGroundHeigthAtPiece(unitID,id)
    diff  = absdiff(startHeigth , thisHeigth)

    if diff < 100 then
      WTurn(id,z_axis, math.rad(math.random(-10,10)),0)
      ToShowTable[#ToShowTable+1]=id
    else
      value=randSign()*math.random(70,90)
      WTurn(id,z_axis, math.rad(value),0)
      diff  = absdiff(startHeigth , thisHeigth)
      if diff < 100 then
        ToShowTable[#ToShowTable+1]=id
      end
    end
  end
  )


end

function script.Killed(recentDamage, _)
  createCorpseCUnitGeneric(recentDamage)
  return 1
end

function showOne(T, bNotDelayd)
  if not T then return end
  dice = math.random(1,count(T))
  c= 0
  for k,v in pairs(T) do
    if k and v then
      c= c+1
    end
    if c== dice  then
	  if bNotDelayd and bNotDelayd == true then
		Show(v)
	  else
		ToShowTable[#ToShowTable+1]=v
	  end
      return v
    end
  end
end

function showOneOrNone(T)
  if not T then return end
  if math.random(1,100) > 50 then
    return showOne(T, true)
  else
    return
  end
end

function showOneOrAll(T)
  if not T then return end
  if chancesAre(10) > 0.5 then
    return showOne(T)
  else
		for num, val in pairs(T) do
			ToShowTable[#ToShowTable+1]=val
		end
    return
  end
end

function selectBase()
  showOne(TablesOfPiecesGroups["base"], true)
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
  diceTable ={ "", "Brown", "White", "Red"}
  x,y,z =Spring.GetUnitPosition(unitID)
  x, z = math.ceil(x/1000), math.ceil(z/1000)
  nice= ((x+z)%(#diceTable)+1)
  dice = diceTable[nice]
  --echo(dice)

  return dice
end

function DecorateBlockWall(element, xRealLoc,zRealLoc, xLoc,zLoc, rotation, level, DecoMaterial,name, yoffset)
 piecegroupName = name or ""
 y_offset = yoffset or 0
  local Deco, piecename = getRandomBuildMaterial(DecoMaterial, piecegroupName)
  while not Deco do
    Deco, piecename = getRandomBuildMaterial(DecoMaterial, piecegroupName)
    Sleep(1)
  end

  if Deco then
    DecoMaterial = removeElementFromBuildMaterial(Deco, DecoMaterial)
    Move(Deco, 1, xRealLoc, 0)
    Move(Deco, 3, zRealLoc, 0)
    Move(Deco, 2, level* cubeDim.heigth + y_offset, 0)
    Turn(Deco, y_axis, math.rad(rotation),0)
    ToShowTable[#ToShowTable+1]=Deco
  end

  if TablesOfPiecesGroups[piecename.."Sub"] then
    showOneOrAll(TablesOfPiecesGroups[piecename.."Sub"])
  end

  return DecoMaterial, piecename
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
    if not AlreadyUsedPiece[v] then
      total = total + 1
      if total == dice  then
        AlreadyUsedPiece[v] = true
        return v, piecegroupName..total
      end
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

function isBackYardWall(index)
	return (getLocationInPlan(index)==false)

  -- if index > 7 and index < 11 then
    -- return true
  -- end

  -- if index > 25 and index < 30 then
    -- return true
  -- end

  -- if (index % 6) == 2 or (index %6) == 4 and (index > 11 and index < 25) then
    -- return true
  -- end

  -- return false
end

function  getWallDeocrationRotation(index)

  if index < 7 then
    return 90
  end

  if index > 30 and index < 37 then
    return 270
  end

  if (index % 6) == 1 and ( index < 37 and index > 6)then
    return 180
  end

  if (index % 6) == 0 and ( index < 37 and index > 6) then
    return 0
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



function getElasticTable( ...)
  if (not arg) then arg = {...}; arg.n = #arg end
   mergeTable={}
  for i=1, arg.n do 
    for k, v in pairs(TablesOfPiecesGroups) do
      if string.find(string.lower(k), string.lower(arg[i])) then
		for a,b in pairs(TablesOfPiecesGroups[k]) do mergeTable[a] = b end
      end
    end
  end

  return mergeTable
end

function buildDecorateGroundLvl()
  Sleep(1)
  centerP = {x = (cubeDim.length/2) * 5, z= (cubeDim.length/2) *  5}
  StreetDecoMaterial = getElasticTable("Street")
  local DoorMaterial = TablesOfPiecesGroups["Door"]
  DoorDecoMaterial = TablesOfPiecesGroups["DoorDeco"]
  yardMaterial = getElasticTable("Yard")

  materialColourName = selectGroundBuildMaterial()
  materialGroupName = materialColourName.."FloorBlock"
  buildMaterial = TablesOfPiecesGroups[materialGroupName]

  countElements= 0
	
  for i=1, 37, 1 do
	Sleep(1)

    local index = i
    partOfPlan, xLoc,zLoc= getLocationInPlan(index)
    if partOfPlan == true then
      xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length)
      local element = getRandomBuildMaterial(buildMaterial, materialGroupName)
      while not element do
        element = getRandomBuildMaterial(buildMaterial, materialGroupName)
        Sleep(1)
      end

      if element then
        rotation = getRotationOfBlockInPlan(index)
        countElements = countElements + 1
        buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
        Move(element, 1, xRealLoc, 0)
        Move(element, 3, zRealLoc, 0)
        ToShowTable[#ToShowTable+1]=element
        if countElements == 24 then return materialColourName end
		
		rotation = getWallDeocrationRotation(index)
			if chancesAre(10) < decoChances.street   then
			
				StreetMaterial,piecename  = DecorateBlockWall(element, xRealLoc,zRealLoc, xLoc,zLoc,  rotation, 0, StreetDecoMaterial)
				if TablesOfPiecesGroups[piecename.."Sub"] then
					showOneOrAll(TablesOfPiecesGroups[piecename.."Sub"])
				end
			end
			
			 if chancesAre(10) < decoChances.door  then
				rotation = getWallDeocrationRotation(index)
				DoorMaterial = DecorateBlockWall(element, xRealLoc,zRealLoc, xLoc,zLoc, rotation, 0, DoorMaterial, 3 )
				if chancesAre(10) < decoChances.door  then
				--	DoorDecoMaterial = DecorateBlockWall(element, xRealLoc,zRealLoc, xLoc,zLoc, rotation, 0, DoorDecoMaterial)  
				end
			end
      end

    end

	if  isBackYardWall(index) == true then
      --BackYard
	  Spring.Echo("Backyard")
      if chancesAre(10) < decoChances.yard then
		element, yardMaterial = decorateBackYard(index, xLoc, zLoc, yardMaterial)
      end
    end
  end

  return materialColourName
end

function chancesAre(outOfX)
  return (math.random(1,outOfX)/outOfX)
end

function buildDecorateLvl(Level, materialGroupName, buildMaterial)
  Sleep(1)
  centerP = {x = (cubeDim.length/2) * 5, z= (cubeDim.length/2) *  5}
  local WindowWallMaterial = TablesOfPiecesGroups["Window"]--getElasticTable( "Window")--"Wall",

  countElements= 0

  for i=1, 37, 1 do
	Sleep(1)
    local index = i
    partOfPlan, xLoc,zLoc= getLocationInPlan(index)
    if partOfPlan == true then
      xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length)
      local element = getRandomBuildMaterial(buildMaterial, materialGroupName)
      while not element do
        element = getRandomBuildMaterial(buildMaterial, materialGroupName)
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
        ToShowTable[#ToShowTable+1]=element

        if chancesAre(10) > decoChances.windowwall then	
			--WindowWallMaterial = DecorateBlockWall(element, xRealLoc, zRealLoc, xLoc, zLoc, getWallDeocrationRotation(index), Level, WindowWallMaterial, "Window")
        end

        if countElements == 24 then return materialGroupName, buildMaterial end
      end
    end
  end

  return materialGroupName, buildMaterial
end

function decorateBackYard(index, xLoc, zLoc, buildMaterial)
  local element = getRandomBuildMaterial(buildMaterial)
  while not element do
    element = getRandomBuildMaterial(buildMaterial)
    Sleep(1)
  end
  
  buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)

  -- rotation = math.random(0,4) *90
  xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length)
  Move(element, 1, xRealLoc, 0)
  Move(element, 3, zRealLoc, 0)
  
  ToShowTable[#ToShowTable+1]=element

  return element, buildMaterial
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
        ToShowTable[#ToShowTable+1]=element
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

      if element and chancesAre(10) > decoChances.roof then
        rotation = getRotationOfBlockInPlan(i)
        countElements = countElements+1
        decoMaterial = removeElementFromBuildMaterial(element, decoMaterial)
        Move(element, 1, xRealLoc, 0)
        Move(element, 3, zRealLoc, 0)
        Move(element, 2, Level * cubeDim.heigth -0.5 + cubeDim.roofHeigth , 0)
        WaitForMoves(element)
        --Turn(element, 3, math.rad(rotation),0)

        if TablesOfPiecesGroups[piecename.."Sub"] then
          showOneOrAll(TablesOfPiecesGroups[piecename.."Sub"])
        end
        --

        ToShowTable[#ToShowTable+1]=element
        if countElements == 24 then return  end
      end
    end
  end
end

function buildAnimation()
	local builT= TablesOfPiecesGroups["Build"]
	axis= 2
		for i=1,3 do
			Move(builT[i],axis, -1*cubeDim.heigth,0)
		end
	moveT(TablesOfPiecesGroups["Build01Sub"],3 ,-3000,0)
	WaitForMoves(TablesOfPiecesGroups["Build01Sub"])
	WaitForMoves(builT)
	showT(builT)
	showT(TablesOfPiecesGroups["Build01Sub"])
	showT(TablesOfPiecesGroups["BuildCrane"])
	
	moveSyncInTimeT(builT,0,0,0, 3000)
	moveSyncInTimeT(TablesOfPiecesGroups["Build01Sub"],0,0,0, 3000)

	process(TablesOfPiecesGroups["BuildCrane"],
		function(id) 
			craneFunction = function(id)
								while true do
									target = math.random(-120,120)
									WTurn(id, y_axis, math.rad(target),math.pi/10)
									Sleep(1000)
								end
							end
		
				StartThread(craneFunction, id)
				end
				)

	Sleep(15000)
	showT(ToShowTable)
	
	moveSyncInTimeT(builT,0, -1*cubeDim.heigth,0, 50000)
	moveSyncInTimeT(TablesOfPiecesGroups["Build01Sub"],0,-200,0, 50000)
	WaitForMoves(TablesOfPiecesGroups["Build01Sub"])
	WaitForMoves(builT)
	hideT(builT)
	hideT(TablesOfPiecesGroups["Build01Sub"])
	hideT(TablesOfPiecesGroups["BuildCrane"])
end


function buildBuilding()
  StartThread(buildAnimation)
  selectBase()
  selectBackYard()

  materialColourName= buildDecorateGroundLvl()

  buildMaterial = TablesOfPiecesGroups[materialColourName.."WallBlock"]
  for i=1, 2 do
    _, buildMaterial = buildDecorateLvl(i, materialColourName.."WallBlock", buildMaterial)
  end

  addRoofDeocrate(3, TablesOfPiecesGroups[materialColourName.."Roof"])

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

