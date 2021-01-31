include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
stickyBombTimeMs = 5000
maxDamagePerUnit = 800
maxDamageDistance= 120
stickyCircle = 50
myTeamID = Spring.GetUnitTeamID(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()

center = piece"center"
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
	Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitAlwaysVisible(unitID, true)
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(attachAndBlow)
end

function attachAndBlow()
	waitTillComplete(unitID)
	victimID = nil
	smallestDistance = math.huge 
	x,y,z = Spring.GetUnitPosition(unitID)
	victims= process(getAllInCircle(x,z, stickyCircle),
		function(id)
			teamID= Spring.GetUnitTeam(id)
			if teamID ~= myTeamID and teamID ~= gaiaTeamID then
				return id
			end
		end,
		function(id)
			distances = distanceUnitToUnit(unitID, id)
			if distances < smallestDistance then
				victimID = id
				smallestDistance = distances
			end
		end
		)

	if victimID then
		map = Spring.GetUnitPieceMap(victimID)
		Spring.UnitAttach(unitID, victimID, randDict(map))
	end
	
	it = true
    period = 512

 	BOOM = stickyBombTimeMs
 	while BOOM > 0 do
        BOOM = math.max(0, BOOM - period)
        if BOOM == 0 then break end

        if it == true then
            it = false
            --Show(blink)
            for i = 1, 8, 1 do
                EmitSfx(center, 1025)
                Sleep(64)
            end
        else
            it = true
            --Hide(blink)
            Sleep(period)
        end
    end

    x, y, z = Spring.GetUnitPosition(unitID)
    process(getAllInCircle(x, z, maxDamageDistance, unitID),
    	function(id)
    		if id ~= unitID then
    			factor = (1-(distanceUnitToUnit(unitID, id)/maxDamageDistance))
       		 	Spring.AddUnitDamage(id, maxDamagePerUnit * factor)
    		end
    end)
 	EmitSfx(center, 1024)
 	Spring.SpawnCEG("bigbulletimpact", x, y + 25, z, 0, 1, 0, 50, 0)
    Spring.DestroyUnit(unitID, false, true)
end
function script.Killed(recentDamage, _)

    return 1
end

