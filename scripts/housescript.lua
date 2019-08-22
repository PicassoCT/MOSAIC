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
	resetAll(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	buildHouse()
end

function buildHouse()
	hideAll(unitID)
	if math.random(0,1)== true then
	process(TablesOfPiecesGroups["PowerPole"],
			function(id)
				Turn(id,z_axis, math.rad(math.random(-10,10)),0)
				Show(id)
			end
			)
			Turn(TablesOfPiecesGroups["PowerPole"][1],z_axis, math.rad(math.random(-360,360)),0)
	end

	 buildBuilding()

end


function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
--TODO generate Algo to create building

--parts
--roofdeco:
-- Japan Gardens, Automated Veggie or Ganjagarden, Atenna, Beds, AC-Units,  Penthouse, Swimmingpool, Werbung, Windkraftwerk, Belüftung, Vögel
-- Clothing drying, Sunsails, Satantenna, Chicken Coop, Sunbathing Sightline

--Walls:
	--	Fenster, Sichtschutz, Wohnung,  Anbauten,  Pflanzen, Lagerhaus,Werbung
-- Floor:
--innenhof
		-- Abgehängt:  NeonLeuchten, Lautsprecher
		-- Boden: , Spielplatz, Fuss/Basketball, Mini-Chemiewerk(Destillery), Basar
--FloorWall:
	--	 Shop, Kleidung, Spielzeug, Elektronika, Tankstelle, Essen, Cafes,  Waffenladen, minimarket
-- Street:
	--  Garbagedumps, Sitting People, NeonLeuchten/Neonsigns, Bildschirme, , Hydranten

--[[
--necessary
-- + optional
-- > at least one

--BuildingBase  + DecoPlate
			   -- Buildingblock  + Window
								 + Door
								 + Decoration	
				+ HoodDecoration
				 
]]
function showOne(T)
dice = math.random(1,#T)
Show(T[dice])
return dice
end

function showOneOrNone(T)
	if math.random(1,100) > 50 then
		return showOne(T)
	else
		return
	end
end


function selectBase()
	showOne(TablesOfPiecesGroups["Base"])
end

function selectBackYard()
	showOneOrNone(TablesOfPiecesGroups["Back"])
end

-- x:0-6 z:0-6   
function  getLocationInPlan(index)
if index > 0 and index < 7 then
return index -1, 0
end

if index > 31 and index < 37 then
return index-1, 5
end

if (index % 6)== 1 then
	return index-1, math.floor(index/6)
end
if (index % 6) == 0 then
return 5 ,  math.floor(index/6)
end
end


function partOfPlan(index)
if index > 0 and index < 7 or index > 31 and index < 37 then return true end

if (index % 6)== 1 or (index % 6) == 0 then return true end

return false
end

function removeElementFromBuildMaterial(element, buildMaterial)

end

function selectBuildMaterial
return TablesOfPiecesGroups["FloorBlock"]
end
function buildDecorateGroundLvl()
local cubeDim ={length = 32, heigth= 16}
centerP = {x = (cubeDim.length/2)*2.5, z= (cubeDim.length/2)*2.5}
buildMaterial = {}
buildMaterial, materialGroup = selectBuildMaterial()

	for i=1, 36 do
		if partOfPlan(i)==true then
			xLoc,zLoc = getLocationInPlan(i)
			xRealLoc, zRealLoc = -centerP.x + xLoc* cubeDim.length,  -centerP.z + zLoc* cubeDim.length 
			element = getRandomElementRing(buildMaterial)
			buildMaterial = removeElementFromBuildMaterial(element, buildMaterial)
			mP(element,xRealLoc,0, zRealLoc,0, true)
			DecorateDoor(element,xRealLoc,zRealLoc, xLoc,zLoc)
			DecorateStreet(element,xRealLoc,zRealLoc, xLoc,zLoc)
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
	decorateBackYard()
	materialGroup= buildDecorateGroundLvl()

	for i=1, 2 do
		buildDecorateLvl(i, materialGroup)
		decorateLvl(i)
	end

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

