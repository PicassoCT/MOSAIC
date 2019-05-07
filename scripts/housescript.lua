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
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
end

function script.Killed(recentDamage, _)

    createCorpseCUnitGeneric(recentDamage)
    return 1
end


--- -aimining & fire weapon
--TODO generate Algo to create building

--parts
--roofdeco:
-- Gardens, Atenna, Sunsails and Beds, AC-Units, Solarpanels, Penthouse, Swimmingpool, Werbung, , Windkraftwerk, Belüftung, Vögel

--Walls:
	--	Fenster, Sichtschutz, Wohnung, Baustellen, Anbauten, AC-Units, Water-Installations, Pflanzen, Lagerhaus,Werbung
-- Floor:
--innenhof
		-- Abgehängt:  Sunsail/Teppich überspannt, NeonLeuchten, Kinoleinwand
		-- Boden: Pflanzen, Spielplatz, Fuss/Basketball, Mini-Chemiewerk(Destillery), Basar
--FloorWall:
	--	 Shop, Kleidung, Spielzeug, Elektronika, Tankstelle, Essen, Cafes, Religion (Mosque), Waffenladen, minimarket
-- Street:
	-- Parked Motorbikes, Tables, Garbagedumps, Sitting People, NeonLeuchten/Neonsigns, Bildschirme, Straßenleuchten, Hydranten
	
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

