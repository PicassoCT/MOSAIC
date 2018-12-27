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
    disDance = 25
    TruckTable = {} --[1]CarUnitID [2]CurrentTargetNode [i][j] [3] LastVisitedNode [i][j] SpawnerNumber
    local NodesTable = {} --by Convention the NodesTable is a [i][j].x [i][j].z table of visitable Coordinates
    sPTable = {}
    numberOfVehicles = 25
    val = GG.Valerie
    RouteTabel = {} --Every Subtable consists of a finite series of coordpairs[i][1] [i][2]

    gaiaTeamID = Spring.GetGaiaTeamID()

    function mOx(val)
        return math.max(1, val)
    end

    function exploreNode(direction, i, j, ei, ej)
        fi, fj = 0, 0
        if direction == "s" then fi, fj = i, mOx(j - 1) end
        if direction == "n" then fi, fj = i, j + 1 end
        if direction == "w" then fi, fj = i + 1, j end
        if direction == "e" then fi, fj = mOx(i - 1), j end
        if fi == ei and fj == ej then return nil, nil, true end
        --Spring.Echo(fi,fj)
        printTable(NodesTable)

        if NodesTable[fi][fj] == true then
            ti, tj = addSubByDir(direction)
            return fi * val + ti, fj * val + tj, false
        else
            return nil, nil, false
        end
    end

    function randomExDir(direction)
        dirNr = 0
        if direction == "s" then dirNr = 0 end
        if direction == "n" then dirNr = 1 end
        if direction == "w" then dirNr = 2 end
        if direction == "e" then dirNr = 3 end
        newDir = math.floor(math.random(0, 3))
        if newDir == dirNr then newDir = (newDir + 1) % 4 end

        if newDir == 0 then return "s" end
        if newDir == 1 then return "n" end
        if newDir == 2 then return "w" end
        if newDir == 3 then return "e" end
    end


    function randomSpot()
        if #RouteTabel == 0 then Spring.Echo("Error: Not enough Routes") end
        if #RouteTabel == 1 then return 1, RouteTabel[1][1], RouteTabel[1][2] end
        i = math.floor(math.random(1, table.getn(RouteTabel)))
        x = math.floor(math.random(1, table.getn(RouteTabel[i])))

        --Spring.Echo( RouteTabel[i][2],"invalid number in RouteTabel"..i)

        return i, RouteTabel[i][x][1], RouteTabel[i][x][2] or RouteTabel[i][x][1]
    end


    function giveWaypointsToUnit(uID, starti, route)
        assert((RouteTabel[route]), "Route doesent exist" .. route)
        Spring.Echo("JW_TrafficGadget::RouteNodesTotal:", table.getn(RouteTabel[route]))
        for i = 1, table.getn(RouteTabel[route]), 1 do
            local rx = 0 --math.random (-20,20)
            local rz = 0 --math.random (-20,20)
            Spring.GiveOrderToUnit(uID, CMD.PATROL, { RouteTabel[route][i][1], 100, RouteTabel[route][i][2] }, { "shift" })
        end
    end

    function buildRouteFromTwoSpots(spotOne, spotTwo)
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



    function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
       -- Civilian aggregation around catastrophe 
    end

  
    gcarDefID = UnitDefNames["truck"].id or nil
	if not gcarDefID then gcarDefID = 0 end

    function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)


        if unitDefID == gcarDefID then
            for i = 1, table.getn(TruckTable), 1 do
                if TruckTable[i].unitid == unitID then
                    table.remove(TruckTable, i)
                    break
                end
            end
        end
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

    function init()
        --Spring.Echo("JW_TrafficGadget InitReached")
        if sPTable and table.getn(sPTable) > 2 and RouteTable and #RouteTabel > 0 then

            return true
        end


        if GG.SpawnPointTable then
            --		printTable(GG.SpawnPointTable)
            for i = 1, #GG.SpawnPointTable, 1 do
                for j = 1, #GG.SpawnPointTable, 1 do
                    if j ~= i then
                        RouteTabel[#RouteTabel + 1] = buildRouteFromTwoSpots(GG.SpawnPointTable[i].unitid, GG.SpawnPointTable[j].unitid)
                    end
                end
            end
            sPTable = tableCopy(GG.SpawnPointTable)
        end


        if RouteTabel == nil or #RouteTabel == 0 then return false end

        return true
    end

    --starts at nine o Clock with 1 going clockwise
    function mapNumbToCoords(ox, oz, n)
        x = 0
        z = 0
        if n > 1 and n < 5 then x = -1 elseif n < 9 and n > 5 then x = 1 end
        if n == 2 or n == 1 or n == 8 then z = -1 elseif n == 4 or n == 5 or n == 6 then z = 1 end
        return ox + x, oz + z
    end

    Val = 320





    function spawnACar(building, i, j)
        --Spring.Echo("JW_TrafficGadget::SpawnACar")
        --assert(RouteTabel,"Error:Route Tabel doesent exist")
        val = math.floor(math.random(1, 3))
        dir = math.max(1, val)
        --select track
        --	--Spring.Echo("JW_TrafficGadget::NrOfRouteTables",table.getn(RouteTabel))
        trackNr = math.floor(math.random(1, table.getn(RouteTabel)))
        i, x, z = randomSpot(RouteTabel[trackNr])
        id = Spring.CreateUnit("gcar", x, 100, z, dir, gaiaTeamID)
        --assert(id,"This Car needs a Repairer")
        if id then
            Spring.SetUnitNoSelect(id, true)
            Spring.SetUnitAlwaysVisible(id, true)
            Spring.SetUnitNeutral(id, true)
            TruckTable[table.getn(TruckTable) + 1] = {}
            TruckTable[table.getn(TruckTable)] = { unitid = id, ctnI = i, ctnJ = j, lvnI = i, lvnJ = j, tNr = trackNr }
            giveWaypointsToUnit(id, i, TruckTable[table.getn(TruckTable)].tNr)
        end
    end



    function gadget:GameFrame(frame)
        --	--assert(init(),"Init Failed")
        if frame % disDance == 0 and init() == true then
            --spawn Cars if necessary
            for i = 1, numberOfVehicles - table.getn(TruckTable), 1 do
                selector = math.max(1, math.floor(math.random(1, table.getn(sPTable))))
                if sPTable and selector and sPTable[selector].unitid then
                    if true == Spring.ValidUnitID(sPTable[selector].unitid) and false == Spring.GetUnitIsDead(sPTable[selector].unitid) then
                        spawnACar(sPTable[selector].unitid, sPTable[selector].CoordI, sPTable[selector].CoordJ)
                    end
                end
            end

        end
    end
end

