function gadget:GetInfo()
    return {
        name = "Traffic Gadget",
        desc = "Coordinates Traffic ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

-- modified the script: only corpses with the customParam "featuredecaytime" will disappear

if (gadgetHandler:IsSyncedCode()) then
    local spGetPosition = Spring.GetUnitPosition
    local spIsUnitDead = Spring.GetUnitIsDead
    local spAddUnitDamage = Spring.AddUnitDamage

    GG.CivilianTable = {} --[id ] ={ defID, CurrentTargetNode{x,z} , LastTargetNode{x,z} }
    GG.UnitArrivedAtTarget = {} --[1]Car/Civilian UnitID
	
    local NodesTable = {} --by Convention the NodesTable is a [i][j] ={x ,z } table of visitable Coordinates
	 RouteTabel = {} --Every Subtable route = {consists of a finite series of coordpairs[i][1] [i][2] }, start, target
    numberOfVehicles = 25
    numberOfPersons = 50
    gaiaTeamID = Spring.GetGaiaTeamID()
	
	 function gadget:UnitCreated(unitID, unitDefID)
	 
	 end
	 
    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
       -- Transfer Funds according to who caused the destruction
    end

	 
	 function gadget:UnitDestroyed(unitID, unitDefID)
		--if building, get all Civilians/Trucks nearby in random range and let them get together near the rubble
	 end
	 
	 function spawnInitialPopulation()
	 
	 end
	 
	function spawnPerson(defID, x, z)
	
	end

   function spawnATruck(defID, x, z, i, j)


        dir = math.max(1, math.floor(math.random(1, 3)))
        --select track
        --	--Spring.Echo("JW_TrafficGadget::NrOfRouteTables",table.getn(RouteTabel))
       
        id = Spring.CreateUnit(defID, x, 100, z, dir, gaiaTeamID)
        --assert(id,"This Car needs a Repairer")
        if id then
            Spring.SetUnitNoSelect(id, true)
            Spring.SetUnitAlwaysVisible(id, true)
           GG.CivilianTable [id] = {defID= defID}
        end
		GG.UnitArrivedAtTarget[id]= true
   end

	function spawnBuilding(defID, x,z)
	--test Coordinates for reachability
	--add Building to traffic Nodes
	end


	 
	 function gadget:Initialize()
		-- spawn Buildings
		-- spawn Initial Population
	 end
	 


    function giveWaypointsToUnit(uID, starti, route)
			if math.random(0,1) == 1 or type is truck then -- direct route to target
				--generate EvenStream to have Unit regularly try to get towards building
			else --rectangular route
				--
			
			end
    end

    function buildRouteSquareFromTwoUnits(spotOne, spotTwo)
        Route = {}
        x1, y1, z1 = spGetPosition(spotOne)
        x2, y2, z2 = spGetPosition(spotTwo)


        Route[1] = {}
        Route[1][1] = x1
        Route[1][2] = z1

        Route[2] = {}
        Route[2][1] = x1
        Route[2][2] = z2

        Route[3] = {}
        Route[3][1] = x2
        Route[3][2] = z2

        Route[4] = {}
        Route[4][1] = x2
        Route[4][2] = z1

        Route[5] = {}
        Route[5][1] = x1
        Route[5][2] = z1

        return Route
    end


    function tableCopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[tableCopy(orig_key)] = tableCopy(orig_value)
            end
            setmetatable(copy, tableCopy(getmetatable(orig)))
        else
            copy = orig
        end
        return copy
    end





    function gadget:GameFrame(frame)
			
			--if Unit arrived at Location
			--give new Target
			
			--Check number of Units
			-- recreate buildings 
			-- recreate civilians
			
		
    end
end

