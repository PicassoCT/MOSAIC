function gadget:GetInfo()
    return {
        name = "Spawn TestUnits",
        desc = "This gadget surveils memory conditions",
        author = "Picasso",
        date = "Sep. 2022",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = false
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_OS.lua")
    VFS.Include("scripts/lib_UnitScript.lua")
    VFS.Include("scripts/lib_Animation.lua")
  --  VFS.Include("scripts/lib_Build.lua")
    VFS.Include("scripts/lib_mosaic.lua")

    local spGetUnitDefID = Spring.GetUnitDefID

    startFrame = Spring.GetGameFrame()+1
    startTestAfterSeconds = 5
    --Optimization
    gaiaTeamID = Spring.GetGaiaTeamID()
    GameConfig = getGameConfig()
    houseTypeTable = getCultureUnitModelNames_Dict_DefIDName(GameConfig.instance.culture, "house", UnitDefs)

    function gadget:Initialize()
        initalizeInheritanceManagement()
        startFrame = Spring.GetGameFrame()+1
    end

    boolFirst = false
    boolSecond = false

    allreadyUsedHouses= {}
    boolJustOnce = false
    spawnedSafeHouse = {}
    spawnedOperatives = {}

    function spawnTestNetwork()
          T = Spring.GetTeamList ()
            local nrOfTeams = #T
            result = {}
            playerTeam, aiTeam = false, false
            Spring.Echo("nr of teams "..nrOfTeams)
            for i = 1, nrOfTeams do
                echo(Spring.GetTeamInfo(T[i]))      
                teamID, leader,  isDead,  isAiTeam, side,  allyTeam,  incomeMultiplier,  customTeamKeys =   Spring.GetTeamInfo( T[i])
                echo("Team: "..teamID.." Leader:"..leader.." isDead:".. toString(isDead).." isAiTeam:"..toString(isAiTeam).." side:"..toString(side))
                
                if teamID ~= gaiaTeamID and not isAiTeam then
                    playerTeam = T[i]
                end

                if teamID ~= gaiaTeamID and isAiTeam then
                    aiTeam = T[i]
                end
            end

            if not playerTeam then
                echo("Error: No playerteam")
                return
            end

            if not aiTeam then
                echo("Error: No aiTeam")
                return                
            end 

    local size = 25

        foreach(Spring.GetAllUnits(),
            function(id)
                if houseTypeTable[spGetUnitDefID(id)] then return id end
                end,            
            function (id)
                if not allreadyUsedHouses[id] and size > 0 then
                    allreadyUsedHouses[id] = id
                    size = size - 1
                    echo("Spawn Test setup "..size)
                    spawnHouseID=randDict(spawnedSafeHouse)
                --    Spring.Echo("createUnitAtUnit ".."game_unittest.lua")      
                    trainedOperative = createUnitAtUnit(aiTeam,"operativeinvestigator", id, math.random(-40, 40), 0 ,  math.random(-40,40))
                    spawnedOperatives[trainedOperative] = trainedOperative

                    operativeCreatingNextSafeHouse = randDict(spawnedOperatives)
--                    Spring.Echo("createUnitAtUnit ".."game_unittest.lua")      
                    safehouseID = createUnitAtUnit(aiTeam, "antagonsafehouse", id, 0, 0, 0)
                    Spring.SetUnitAlwaysVisible(safehouseID, false)
                    spawnedSafeHouse[safehouseID] = safehouseID
                end
            end
            )
    end
    
    function connectTheDots()
      --  echo("Start Connecting the network")
        local allSafehouses = spawnedSafeHouse
        local safehouses = spawnedSafeHouse
        local operatives = spawnedOperatives
        root = randDict(operatives)
        registerParent(aiTeam, root)
        newSafeHouse = randDict(allSafehouses)
        registerChild(aiTeam, newSafeHouse, root)
        operatives[root] = nil

        while count(operatives) > 0 or count(safehouses)  > 0 do
            newSafeHouse = randDict(safehouses) 
            if newSafeHouse then
                registerChild(aiTeam, root, newSafeHouse)
                echo("Unit "..root.." is parent of "..newSafeHouse)
            end

            if not newSafeHouse then
                newSafeHouse = randDict(allSafehouses)
                if not newSafeHouse then break end
            end

            operatives[root] = nil
            root = randDict(operatives)
            if not root then return end

            registerChild(aiTeam, newSafeHouse, root)
            echo("Safehouse "..newSafeHouse.." is parent of "..root)
            safehouses[newSafeHouse] = nil          
        end
        echo("End Connecting the network")
    end 

boolDone = false
    function gadget:GameFrame(frame)

        if frame == (startFrame + (startTestAfterSeconds*30)) then
            echo("Game:Unit_Test:SpawningTestUnits")
            spawnTestNetwork()
        end
            
        if frame == (startFrame + (startTestAfterSeconds*30))+ 1 then
            connectTheDots()
            boolDone = true
        end 

 --[[       if frame % 10 == 0 and not boolDone then
            echo( "Starting in "..math.abs(frame - ( startFrame + (startTestAfterSeconds*30))))
        end--]]

        if frame > (startFrame + (startTestAfterSeconds*30)) and frame % 60 == 0  then
             foreach(spawnedOperatives,
                    function(id)
                        if doesUnitExistAlive(id) == true then 
                            return id 
                        end
                    end,
                    function (id)
                        spawnCegAtUnit(id,"redlight", 0, 50, 0)
                        return id
                    end
                    )
        end
    end
end