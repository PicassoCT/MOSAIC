include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
local cubeDim ={length = 14.4 *1.45, heigth= 13.65 * 0.75*1.45, roofHeigth = 2}
decoChances={ roof = 0.4, yard = 0.6, street = 0.8, powerpoles = 0.5, door = 0.6, windowwall= 0.8}
ToShowTable ={}

_x_axis = 1
_y_axis = 2
_z_axis = 3

function script.HitByWeapon(x, z, weaponDefID, damage)
end

AlreadyUsedPiece ={}
center = piece "center"

pericodicRotationYPieces ={}
spinYPieces ={}
clocks ={}

function script.Create()
  TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
  StartThread(buildHouse)
  
  spinYPieces ={
  TablesOfPiecesGroups["StreetDeco29Sub"][1] ,
  TablesOfPiecesGroups["RoofDeco32Sub"][1]   ,
  TablesOfPiecesGroups["RoofDeco33Sub"][1]   ,
  TablesOfPiecesGroups["RoofDeco38Sub"][1]   ,
  TablesOfPiecesGroups["RoofDeco30Sub"][1]   ,
  TablesOfPiecesGroups["RoofDeco31Sub"][1]   ,
  }
  
 pericodicRotationYPieces= {
  [TablesOfPiecesGroups["StreetWallDeco4Sub"][1]]= false, 
  [TablesOfPiecesGroups["StreetWallDeco13Sub"][1]]= false, 
  [TablesOfPiecesGroups["StreetWallDeco12Sub"][1]]= false, 
  [TablesOfPiecesGroups["StreetWallDeco10Sub"][1]]= false, 
  [TablesOfPiecesGroups["StreetWallDeco11Sub"][1]]= false, 
  [TablesOfPiecesGroups["StreetWallDeco3Sub"][1]]= false, 
  [TablesOfPiecesGroups["StreetWallDeco5Sub"][1]] = false 
  }
  windsolar= {
  [TablesOfPiecesGroups["RoofDeco"][4]]= false, 
  [TablesOfPiecesGroups["RoofDeco"][6]]= false, 
  [TablesOfPiecesGroups["RoofDeco"][5]]= false
  }
  

  
  StartThread(rotations)
  
end


function rotations()
	process(spinYPieces,
			function(id)
				direction = 42*randSign()
				Spin(id,y_axis, math.rad(direction), math.pi)
				end
				)
	
	periodicFunc= function(p) while true do Sleep(500); dir= math.random(-45,45); WTurn(p,y_axis,math.rad(dir),math.pi/1000); end;end
	for k,v in pairs(pericodicRotationYPieces) do		
				StartThread(periodicFunc, k)			
	end
	
	windfunc= function(p) 
		while true do 
			Sleep(500)
			TurnTowardsWind(p, math.pi/500, math.random(-10,10))
			WaitForTurns(p)
		end 
	end
	
	for k,v in pairs(windsolar) do		
		StartThread(windfunc, k)			
	end
	
   showT(TablesOfPiecesGroups["StreetDeco6Sub"])
   Spin(TablesOfPiecesGroups["StreetDeco6Sub"][1],	z_axis,math.rad(3),10)
   Spin(TablesOfPiecesGroups["StreetDeco6Sub"][2],	z_axis,math.rad(36),10)



end

function buildHouse()
  resetAll(unitID)
  hideAll(unitID)
  Sleep(1)



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
  teamID =Spring.GetUnitTeam(unitID)
  
  process(TablesOfPiecesGroups["PowerPole"],
  function(id)
    if id == TablesOfPiecesGroups["PowerPole"][1] then return end
    thisHeigth= getGroundHeigthAtPiece(unitID,id)
    diff  = absdiff(startHeigth , thisHeigth)

	unitsNearPole = getAllInCircle(x,z, 200, unitID, teamID)
	boolHouseToHouseWire= false
	process(unitsNearPole,
			function(id)
				if Spring.GetUnitDefID(id) == UnitDefNames["house"].id then
					boolHouseToHouseWire = true
				end
			end
			)
	if boolHouseToHouseWire == true then
		ToShowTable[#ToShowTable+1]=id
	return
	end	

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
	if not nice then nice = 1 end
  dice = diceTable[nice]


  return dice
end

function getPieceGroupName(Deco)
	t = Spring.GetUnitPieceInfo(unitID, Deco)

return t.name:gsub('%d+','')
end

function DecorateBlockWall( xRealLoc,zRealLoc,  level, DecoMaterial, yoffset)
 if count(DecoMaterial) <= 0 then 
	 echo("Material exausted")
	 return DecoMaterial, piecename
 end
 
 y_offset = yoffset or 0
  local Deco,nr = getRandomBuildMaterial(DecoMaterial)
  while not Deco  do
    Deco,nr = getRandomBuildMaterial(DecoMaterial)
    Sleep(1)
  end
    
	piecename=""

  if Deco then
    DecoMaterial = removeElementFromBuildMaterial(Deco, DecoMaterial)
    Move(Deco, _x_axis, xRealLoc, 0)
    Move(Deco, _y_axis, level* cubeDim.heigth + y_offset, 0)
    Move(Deco, _z_axis, zRealLoc, 0)
   
    ToShowTable[#ToShowTable+1]=Deco
	piecename = getPieceGroupName(Deco)
  end

  if TablesOfPiecesGroups[piecename..nr.."Sub"] then
    showOneOrAll(TablesOfPiecesGroups[piecename..nr.."Sub"])
  end

  return DecoMaterial, piecename, Deco
end


function getRandomBuildMaterial(buildMaterial)
  
  if not buildMaterial then return end
  total = count(buildMaterial)
  if total == 0 then 
	echo("getRandomBuildMaterial:buildMaterial: exausted")
  return 
  end
  
  dice = math.random(1,total)
  total =0
  for k,v in pairs (buildMaterial) do
    if not AlreadyUsedPiece[v] then
      total = total + 1
      if total == dice  then
        AlreadyUsedPiece[v] = true
        return v, k
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
  if index == 1 or index == 6 or index == 31 or index == 36 then return false end
	
  if index > 1 and index < 6 then
    return true
  end

  if index > 31 and index < 36 then
    return true
  end

  if (index % 6) == 0 or (index %6) == 1 and not (index > 31 and index < 36) and not (index > 1 and index < 6 ) then
    return true
  end

  return false
end

function  getWallBackyardDeocrationRotation(index)
  if index == 1 or index == 6 or index == 31 or index == 36 then return 0 end
	
  if index > 1 and index < 6 then
    return 270
  end

    if index > 31 and index < 36 then
    return 90
  end

  if (index % 6) == 0 then
    return 180
  end
  
 if (index % 6) == 1  then
    return 0
  end

return 0
end

function  getOutsideFacingRotationOfBlockFromPlan(index)

  if (index > 30 and index < 37)  then
	if (index == 31 ) then
		return 270 - math.random(0,1)*90
	end
	
	if (index == 36 ) then
		return 270 + math.random(0,1)*90
	end

	return 270
  end
  
   if (index > 0 and index < 7)  then
	if (index == 1 ) then
		return 90 + math.random(0,1)*90
	end
	
	if (index == 6 ) then
		return 90 - math.random(0,1)*90
	end

	return 90
  end
  
  if ((index % 6) == 1 and ( index < 31 and index > 6)) then
	return 180  
  end 
  
  if ((index % 6) == 0 and ( index < 31 and index > 6) )then
	return 0
  end

  return 0
end

function getElasticTable( ...)
  local arg = arg; if (not arg) then arg = { ... } end
   mergeTable={}
 for k, searchterm in pairs(arg) do
    for k, v in pairs(TablesOfPiecesGroups) do
		-- s = "Searching for "..string.lower(searchterm).." in "..string.lower(k)
      if string.find(string.lower(k), string.lower(searchterm)) and  string.find(string.lower(k), "sub") == nil and string.find(string.lower(k), "_ncl1_") == nil then
		-- Spring.Echo (s.." with succes")
		for num, piecenum in pairs(TablesOfPiecesGroups[k]) do 
			mergeTable[#mergeTable + 1] = piecenum 
		end 
	  end
    end
  end

  return mergeTable
end

function buildDecorateGroundLvl()
  Sleep(1)
  centerP = {x = (cubeDim.length/2) * 5, z= (cubeDim.length/2) *  5}
  local StreetDecoMaterial = getElasticTable("Street")
  local DoorMaterial = TablesOfPiecesGroups["Door"]
  local DoorDecoMaterial = TablesOfPiecesGroups["DoorDeco"]
  local yardMaterial = getElasticTable("Yard")
  


  materialColourName = selectGroundBuildMaterial()
  materialGroupName = materialColourName.."FloorBlock"
  buildMaterial = TablesOfPiecesGroups[materialGroupName]

  countElements= 0
	
  for i=1, 37, 1 do
	Sleep(1)

    local index = i
	rotation = getOutsideFacingRotationOfBlockFromPlan(index)
    partOfPlan, xLoc,zLoc= getLocationInPlan(index)

    if partOfPlan == true then
      xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length)
      local element, nr = getRandomBuildMaterial(buildMaterial)
      while not element do
        element, nr = getRandomBuildMaterial(buildMaterial)
        Sleep(1)
      end

      if element then
       
        countElements = countElements + 1
        buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
        Move(element, _x_axis, xRealLoc, 0)
        Move(element, _z_axis, zRealLoc, 0)
		ToShowTable[#ToShowTable+1]=element

        if countElements == 24 then return materialColourName end	
	
			if  chancesAre(10) < decoChances.street   then	
				rotation = getOutsideFacingRotationOfBlockFromPlan(index)			
				StreetDecoMaterial, piecename, StreetDeco  = DecorateBlockWall( xRealLoc,zRealLoc, 0, StreetDecoMaterial, 0)
				Turn(StreetDeco, 3, math.rad(rotation),0)
				
			end
			
			 if chancesAre(10) < decoChances.door  then
				axis = _z_axis
				DoorMaterial,piecename, Door = DecorateBlockWall( xRealLoc, zRealLoc , 0, DoorMaterial, 0 )
				Turn(Door,axis, math.rad(rotation),0)
				if chancesAre(10) < decoChances.door  then
					DoorDecoMaterial, piecename, DoorDeco = DecorateBlockWall( xRealLoc, zRealLoc, 0, DoorDecoMaterial)  
					Turn(DoorDeco,axis, math.rad(rotation),0)
				end
			end
      end

    end

	if   isBackYardWall(index) == true then
      --BackYard

      if chancesAre(10) < decoChances.yard then
		rotation = getWallBackyardDeocrationRotation(index)
		yardDeco, yardMaterial = decorateBackYard(index, xLoc, zLoc, yardMaterial, 0, rotation)
		if yardDeco then
			Turn(yardDeco, _z_axis, math.rad(rotation),0)
		end
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
  local WindowWallMaterial = getElasticTable("Window")--getElasticTable( "Window")--"Wall",
  yardMaterial = getElasticTable("YardWall")
  countElements= 0


  for i=1, 37, 1 do
	Sleep(1)
    local index = i
	rotation = getOutsideFacingRotationOfBlockFromPlan(i)
	
    partOfPlan, xLoc,zLoc= getLocationInPlan(index)
    if partOfPlan == true then
      xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length)
      local element, nr = getRandomBuildMaterial(buildMaterial)
      while not element do
        element, nr = getRandomBuildMaterial(buildMaterial)
        Sleep(1)
      end

      if element then
        
        countElements = countElements+1
        buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
        Move(element, _x_axis, xRealLoc, 0)
        Move(element, _z_axis, zRealLoc, 0)
        Move(element, _y_axis, Level * cubeDim.heigth , 0)
        WaitForMoves(element)
        Turn(element, _z_axis, math.rad(rotation),0)
		echo("Adding Element to level"..Level)
        ToShowTable[#ToShowTable + 1] = element

        if  chancesAre(10) > decoChances.windowwall then	
			rotation = getOutsideFacingRotationOfBlockFromPlan(index)
			echo("Adding Window decoration to"..Level)
			WindowWallMaterial,  piecename, WindowDeco = DecorateBlockWall( xRealLoc, zRealLoc,  Level, WindowWallMaterial, 0)
			Turn(WindowDeco, _z_axis, math.rad(rotation),0)
        end

        if countElements == 24 then return materialGroupName, buildMaterial end
      end
    end
	
	if  isBackYardWall(index) == true then
      --BackYard

      if chancesAre(10) < decoChances.yard then
		echo("Adding YardWall decoration to"..Level)
		-- yardWall, yardMaterial = decorateBackYard(index, xLoc, zLoc, yardMaterial, Level, rotation )
		if yardWall and roation then
			Turn(yardWall, _z_axis, math.rad(rotation), 0)
		end
      end
    end
	
  end

  return materialGroupName, buildMaterial
end

function decorateBackYard(index, xLoc, zLoc, buildMaterial, Level, rotation)
  if count(buildMaterial) == 0 then return nil, buildMaterial end 
  local element, nr = getRandomBuildMaterial(buildMaterial)
  while not element do
    element, nr = getRandomBuildMaterial(buildMaterial)
    Sleep(1)
  end
  
  buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)

  -- rotation = math.random(0,4) *90
  xRealLoc, zRealLoc = -centerP.x + (xLoc* cubeDim.length),  -centerP.z + (zLoc* cubeDim.length)
  Move(element, _x_axis, xRealLoc, 0)
  Move(element, _z_axis, zRealLoc, 0)
  Move(element, _y_axis, Level*cubeDim.heigth, 0)
  
  pieceGroupName = getPieceGroupName(element)

  if TablesOfPiecesGroups[pieceGroupName..nr.."Sub"] then
	showOneOrAll(TablesOfPiecesGroups[pieceGroupName..nr.."Sub"])
  end
  
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
      local element, nr = getRandomBuildMaterial(buildMaterial)
      while not element do
        element, nr = getRandomBuildMaterial(buildMaterial)
        Sleep(1)
      end

      if element then
        rotation = getOutsideFacingRotationOfBlockFromPlan(i)
        countElements = countElements+1
        buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
        Move(element, _x_axis, xRealLoc, 0)
        Move(element, _z_axis, zRealLoc, 0)
        Move(element, _y_axis, Level * cubeDim.heigth -0.5 , 0)
        WaitForMoves(element)
        Turn(element, _z_axis, math.rad(rotation),0)
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
      local element, nr = getRandomBuildMaterial(decoMaterial)
      while not element do
        element, nr = getRandomBuildMaterial(decoMaterial)
        Sleep(1)
      end

      if element and chancesAre(10) > decoChances.roof then
        rotation = getOutsideFacingRotationOfBlockFromPlan(i)
        countElements = countElements+1
        decoMaterial = removeElementFromBuildMaterial(element, decoMaterial)
        Move(element, _x_axis, xRealLoc, 0)
        Move(element, _z_axis, zRealLoc, 0)
        Move(element, _y_axis, Level * cubeDim.heigth -0.5 + cubeDim.roofHeigth , 0)
        WaitForMoves(element)
        Turn(element, _z_axis, math.rad(rotation),0)
		piecename = getPieceGroupName(element)
        if TablesOfPiecesGroups[piecename..nr.."Sub"] then
          showOneOrAll(TablesOfPiecesGroups[piecename..nr.."Sub"])
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
	axis = _y_axis
	for i=1,3 do
		WMove(builT[i], axis,  i* -cubeDim.heigth*2,0)
	end
	moveT(TablesOfPiecesGroups["Build01Sub"],axis ,-60,0)
	
	WaitForMoves(TablesOfPiecesGroups["Build01Sub"])
	WaitForMoves(builT)
	showT(builT)
	showT(TablesOfPiecesGroups["Build01Sub"])
	showT(TablesOfPiecesGroups["BuildCrane"])
	
	moveSyncInTimeT(builT,0,0,0, 5000)
	moveSyncInTimeT(TablesOfPiecesGroups["Build01Sub"],0,0,0, 5000)

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
	
	for i=1,3 do
		Move(builT[i], _y_axis,  i* -cubeDim.heigth*10, 3*math.pi)
	end
	moveSyncInTimeT(TablesOfPiecesGroups["Build01Sub"],0,0, -1000,8000)
	moveSyncInTimeT(TablesOfPiecesGroups["BuildCrane"],0,0, -1000,8000)
	Sleep(1000)
	hideT(TablesOfPiecesGroups["BuildCrane"])
	Sleep(7000)
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

