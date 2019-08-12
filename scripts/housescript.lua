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
	--	Fenster, Sichtschutz, Wohnung, Baustellen, Anbauten, AC-Units, Water-Installations, Pflanzen, Lagerhaus,Werbung
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
	
function buildBuilding()
	selectBase()
	selectBackYard()
	buildGroundLvl()
	decorateGroundLvl()
	for i=1, 3 do
		buildLvl(i)
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

