include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
stickyBombTimeMs = 5000
maxDamagePerUnit = 800
maxDamageDistance = 150
stickyCircle = 150

blink = piece"BLINK"
center = piece"center"
myTeamID = Spring.GetUnitTeam(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
operativeTypeTable = getOperativeTypeTable(UnitDefs)


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
			if teamID ~= myTeamID then -- teamID ~= gaiaTeamID
				return id
			end
		end,
		function(id)
			defID = Spring.GetUnitDefID(id)
			if not operativeTypeTable[defID] then
				return id
			end
		end,
		function(id)
			if GG.DisguiseCivilianFor and 
				GG.DisguiseCivilianFor[id] and
				GG.DisguiseCivilianFor[id] == unitID then
					return 
			end
			return id
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
		map= Spring.GetUnitPieceMap(victimID)
		name,nr = randDict(map)
		Spring.UnitAttach(victimID, unitID, nr)
	end
	
	it = true
    period = 512

 	BOOM = stickyBombTimeMs
 	while BOOM > 0 do
        BOOM = math.max(0, BOOM - period)
        if BOOM == 0 then break end

        if it == true then
            it = false
            Show(blink)
            for i = 1, 8, 1 do
                EmitSfx(center, 1025)
                Sleep(64)
            end
        else
            it = true
            Hide(blink)
            Sleep(period)
        end
    end

    x, y, z = Spring.GetUnitPosition(unitID)

    Spring.SpawnCEG("bigbulletimpact", x, y + 25, z, 0, 1, 0, 50, 0)
    EmitSfx(center, 1024)

    if doesUnitExistAlive(victimID)== true then
    Spring.AddUnitDamage(victimID, maxDamagePerUnit)
	else
    process(getAllInCircle(x, z, maxDamageDistance, unitID),
    	function(id)
    		if id ~= unitID then
    			factor = (1-(distanceUnitToUnit(unitID, id)/maxDamageDistance))
       		 	Spring.AddUnitDamage(id, maxDamagePerUnit * factor)
    		end
    end)
	end

    Spring.DestroyUnit(unitID, false, true)
end

function script.Killed(recentDamage, _)

    return 1
end

