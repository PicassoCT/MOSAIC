include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

myTeamID = Spring.GetUnitTeam(unitID)

TablesOfPiecesGroups = {}
whirl = {}
ring = {}
Blue = {}
Red = {}
step = {}
Wall = {}
OutPost = {}
DoorPost = {}
Door = {}
raidStates = getRaidStates()
raidResultStates = getRaidResultStates()

function script.HitByWeapon(x, z, weaponDefID, damage) end

Progresscenter = piece "Progresscenter"
talk={
protagon = {
    "Team Standby", "Team Ready", "Go Go Go","Datastreams Isolated",
    "SkyCastle Ready", "Retro-Observation-Results", "TAC Plan has go",
    "<dart sounds>", "away from the window", "to the wall", "drop it",
    "Defeat device removed", "Subjects are dosed and stable",
    "Conversation Mimicry in Progress",
    "System subverted", "Observation, Neutralization",
    "Encapsulated Cloud Interrogation ", "Individual Deprecation ",
    "Sampling Artefacts", "FragPellets in Sit, HiSpeedCam, Upload. Now.", "Drug-Injections. Go.", "Memory-formation prevented", 
    "Virtual Interrogation started", "Suspect is drained, deprecating.",
    "Investigating Distribution", "Systemic Coordination Scenario 9", 
    "Deadmans Killswitch Defused", "Allah al Akbar", "Communication jammed. Fallback to Pre-Scenariotrees",
    "Extraction. Complete."
},

antagon = {
    "Empire instead of the empire", "Allah al Akbar", "Jamming engaged",
    "Death to the West", "Jamal, take them out-","Traitors and Treason to every word they say",
    "Living the dream of sucking billionaire cock-", "Die Motherfuckers, die..",
    "-your guests torture people", "kings things, puppets and strings",
    "I m a old friend, i need the key for one day, to throw a suprise party..",
    "Suprise, Motherfuckers", "God is greater", "This must hurt so much ?",
    "Suffer like they did", "Talk, talk - your life depends on it",
    "Your side simply gave you up..",
    "Though i walk through the valley of shadows",
    "we, we are your own shadow, thats what you fight",
    "you would never betray them, but they already betrayed you",
    "You shouldnt have fucked her-", "And though i walk in the valley of death",
    "Fighting your fellow men, for mindcontrolling machines and stranger things.."
}
}

DefenderWin = piece("DefenderWin")
RaidSuccess = piece("RaidSuccess")
RaidAborted = piece("RaidAborted")
RaidEmpty = piece("RaidEmptz")
raidNoUplink = piece("raidNoUplink")
RaidUploadInProgressDish = piece("RaidUploadInProgressDish")
local satelliteTypeTable = getSatteliteTypes(UnitDefs)

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitStealth(unitID, false)
    Spring.SetUnitNeutral(unitID, true)
    --The unit must be selectable, to appear to a screen trace ray. 
    Spring.SetUnitNoSelect(unitID,false)
    Spring.MoveCtrl.Enable(unitID, true)
  
    showAll(unitID)
    Hide(DefenderWin)
    Hide(RaidSuccess)
    Hide(RaidAborted)
    Hide(RaidEmpty)
    Hide(raidNoUplink)
    Hide(RaidUploadInProgressDish)


    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["RaidUploadInProgress"])
    StartThread(raidAnimationLoop)
    StartThread(raidConversationLoop)
    -- StartThread(raidPercentage)
    whirl = TablesOfPiecesGroups["Whirl"]
    ring = TablesOfPiecesGroups["Ring"]
    Blue = TablesOfPiecesGroups["Blue"]
    Red = TablesOfPiecesGroups["Red"]
    step = TablesOfPiecesGroups["Step"]

    Wall = TablesOfPiecesGroups["Wall"]
    OutPost = TablesOfPiecesGroups["OutPost"]
    DoorPost = TablesOfPiecesGroups["DoorPost"]
    Door = TablesOfPiecesGroups["Door"]

    hideT(Wall)
    hideT(OutPost)
    hideT(DoorPost)
    hideT(Door)

    StartThread(setAffiliatedHouseInvisible)
    StartThread(shoveAllNonCombatantsOut)
    StartThread(ringringUpOffset)
    updateShownPoints(3, 3)
    hideT(TablesOfPiecesGroups["Corner"])
    StartThread(watchRaidIconTable)
end

function raidConversationLoop()
    mySide  = getUnitSide(unitID)
    while true do
        assert(talk[mySide],mySide)
        line = talk[mySide][math.random(1,#talk[mySide])]
        say(line, 2500, { r = 1.0, g = 1.0, b = 1.0 }, { r = 1.0, g = 1.0, b = 1.0 }, "", unitID)

        Sleep(150000)
    end
end

function watchRaidIconTable()
    while not GG.raidStatus or GG.raidStatus[unitID] == nil do 
        Sleep(10)
    end 
    
    while (GG.raidStatus[unitID] and GG.raidStatus[unitID].boolInterogationComplete == false) do
        Sleep(1)
    end

    Show(raidNoUplink)
    --wait for Uplink

 --[[      if GG.raidStatus[unitID].state == raidStates.WaitingForUplink then
        local scanSatDefID = UnitDefNames["satellitescan"].id
        local satelliteAlitudeTable = getSatelliteAltitudeTable(UnitDefs)
        local raidComRange = GameConfig.agentConfig.raidComRange +  satelliteAlitudeTable[scanSatDefID]

        local raidBonusFactorSatellite=  GameConfig.agentConfig.raidBonusFactorSatellite
        local spGetUnitDefID = Spring.GetUnitDefID
        boolComSatelliteNearby= false
     while boolComSatelliteNearby == false do
            Sleep(100)
            foreach(getAllNearUnitSpherical(unitID, raidComRange),
                    function (id)
                        defID = spGetUnitDefID(id)
                        if myTeam == Spring.GetUnitTeam(id) and satelliteTypeTable[defID] then
                            boolComSatelliteNearby = true
                        end             
                    end
                    )
        end

        GG.raidStatus[unitID].state = raidStates.UplinkCompleted
    end--]]
    Sleep(1000)
    Hide(raidNoUplink)

    UplinkAnimation()


    if GG.raidStatus[unitID] and GG.raidStatus[unitID].result  then
        local result = GG.raidStatus[unitID].result
        hideAll(unitID)
        if result ==  raidResultStates.Unknown then
             showRaidAbortedAnimation()
        elseif result == raidResultStates.DefenderWins then
            showDefenderSuccesAnimation()
        elseif result == raidResultStates.AggressorWins then
            showRaidSuccesAnimation()
        elseif  result == raidResultStates.HouseEmpty then
            showHouseEmptyAnimation()
        else
            showRaidAbortedAnimation()
        end
    else
        showRaidAbortedAnimation()
    end
    Sleep(1000)
    GG.raidStatus[unitID].state =  raidStates.VictoryStateSet
    GG.raidStatus[unitID].boolAnimationComplete = true
    while true do
        Sleep(100)
    end
end

function UplinkAnimation()
    Show(RaidUploadInProgressDish)
    times = GameConfig.Satellite.uploadTimesMs/1000
    speed = 1500/1000 

    for i=1, times do
        hideT(TablesOfPiecesGroups["RaidUploadInProgress"])
        moveT(TablesOfPiecesGroups["RaidUploadInProgress"],y_axis, -500, 0)
        WaitForMoves(TablesOfPiecesGroups["RaidUploadInProgress"])
        showT(TablesOfPiecesGroups["RaidUploadInProgress"])
        moveT(TablesOfPiecesGroups["RaidUploadInProgress"],y_axis, 1000, speed )
        WaitForMoves(TablesOfPiecesGroups["RaidUploadInProgress"])
        Sleep(250)
    end
    Hide(RaidUploadInProgressDish)
    hideT(TablesOfPiecesGroups["RaidUploadInProgress"])
end

function popPieceUp(pieceID, speed)
    axis = z_axis
    Move(pieceID, axis, -800, 0)
    Show(pieceID)
    WMove(pieceID, axis, 50, speed)
    WMove(pieceID, axis, 0, speed)
end

function showDefenderSuccesAnimation()
    popPieceUp(DefenderWin, 500)
    Sleep(2000)
end

function showRaidAbortedAnimation()
    popPieceUp(RaidAborted, 500)
    Sleep(2000)
end

function showHouseEmptyAnimation()
    popPieceUp(RaidEmpty, 300)
    Sleep(2000)
end

function showRaidSuccesAnimation()
    popPieceUp(RaidSuccess, 600)
    Sleep(4000)
end

myHouseID = nil
boolRoundEnd = false

function setAffiliatedHouseInvisible()
    Sleep(100)
    boolFoundHouse  = false

    houseTypeTable = getHouseTypeTable(UnitDefs, GameConfig.instance.culture)
    foreach(getAllNearUnit(unitID, GameConfig.houseSizeX-25), 
        function(id)
        if houseTypeTable[Spring.GetUnitDefID(id)] and boolFoundHouse == false then
            myHouseID = id
            boolFoundHouse = true
            StartThread(mortallyDependant, unitID, myHouseID, 15, false, true)
            env = Spring.UnitScript.GetScriptEnv(id)
            if env and env.hideHouse then
                Spring.UnitScript.CallAsUnit(id, env.hideHouse)
            end
            ox, oy, oz = Spring.GetUnitPosition(id)
            min, avg, max = getGroundHeigthGrid(ox,oz, 75) 

            moveUnitToUnit(unitID, id,0, max - oy, 0)
            return
        end
    end)
end

function setAffiliatedHouseVisible()
    if doesUnitExistAlive(myHouseID) == true then
        env = Spring.UnitScript.GetScriptEnv(myHouseID)
        if env and env.showHouse then
            Spring.UnitScript.CallAsUnit(myHouseID, env.showHouse)
        end
    end
end

figures = {Red = "red", Blue = "blue"}

-- Exposed Functions

function updateShownPoints(redPoints, bluePoints)
    hideT(Red)
    hideT(Blue)
    if redPoints > 0 then
     showT(Red, 1, redPoints)
    end
    if bluePoints > 0 then
        showT(Blue, 1, bluePoints)
    end
end

-- //not exposed functions
function showPercent(percent)
    if percent >= 100 then
        boolRoundEnd = true
    else
        boolRoundEnd = false
    end
    percent = math.ceil(math.max(1, percent) / 100 * #step)

    hideT(step)
    showT(step, 1, percent)
end

local counter = 1
function getRoundProgressBar() return counter end

function setRoundProgressBar(value) counter = value end

upgradeTypeTable = getSafeHouseUpgradeTypeTable(UnitDefs, myDefID)
safeHouseTypeTable = getSafeHouseTypeTable(UnitDefs)
raidIconTypeTable = getRaidIconTypeTable(UnitDefs)
operativeTypeTable = getOperativeTypeTable(UnitDefs)
function shoveAllNonCombatantsOut()
    Sleep(1000)
    radius = 140

    while true do
        sx, sy, sz = Spring.GetUnitPosition(unitID)
        foreach(getAllNearUnit(unitID, radius), function(id)
            defID = Spring.GetUnitDefID(id)
            if houseTypeTable[defID] or upgradeTypeTable[defID] or
                safeHouseTypeTable[defID] or raidIconTypeTable[defID] or
                operativeTypeTable[defID] then
            else
                return id
            end
        end, function(id)
            tx, ty, tz = Spring.GetUnitPosition(id)
            factor = distanceUnitToUnit(id, unitID) / radius -- 0
            factor = math.max(0.1, math.min(2, (factor)))

            px, py, pz = (tx - sx), 0, (tz - sz)
            norm = math.max(0.1, math.max(math.abs(px), math.abs(pz)))

            px, pz = px / norm, pz / norm
            px, pz = px * factor, pz * factor

            Spring.AddUnitImpulse(id, px, py, pz, 0.95)
            Command(id, "go", {
                x = tx+math.random(50,70)*randSign(), 
                y = ty, 
                z = tz +math.random(50,70)*randSign()}, {}
                )
        end)
        Sleep(10)
    end
end

function raidAnimationLoop()
    Sleep(1)
    resetAll(unitID)
    assert(type(ring) == "table", "Not a table")

    index = 0
    foreach(ring, function(id)
        index = index + 1
        Spin(id, y_axis, math.rad(index * 4.2) * randSign(), 2.5)
        if index > 3 and index < 8 then
            StartThread(waveSpin, id, math.random(1, 4), math.random(4, 40),
                        500, false)
        end
    end)
    Spin(Progresscenter, y_axis, math.rad(42), 0.5)
    Spin(ring[8], y_axis, math.rad(42), 0.5)
    foreach(whirl, function(id)
        Spin(id, y_axis, math.rad(42) * randSign(), 2.5)
        StartThread(waveSpin, id, math.random(1, 6), math.random(4, 800), 100,
                    true)
    end)

    roundStep = math.ceil(GameConfig.raid.maxRoundLength / 100)
    hideT(step)
    totalTime = 0

    while true do
        if counter == 0 then placeWallAndDoors() end
        counter = (counter + 1)
        showPercent(counter)

        totalTime = totalTime + roundStep
        Sleep(roundStep)
    end
end

nrDoors = 0
nrWalls = 0

function placeWallAndDoors()
    hideT(Wall)
    resetT(Wall)
    hideT(Door)
    resetT(Door)
    hideT(DoorPost)
    resetT(DoorPost)
    hideT(OutPost)
    resetT(OutPost)

    xMax, xMin, zMax, zMin, height = getPlayingFieldMaxMinZ()

    nrDoors = math.random(0, #Door)
    nrWalls = math.random(2, 5)
    if nrWalls > 0 then
        for i = 1, nrWalls do
            rx, rz = math.random(xMax / -2, xMax / 2),
                     math.random(zMax / -2, zMax / 2)
            Move(Wall[i], x_axis, rx, 0)
            Move(Wall[i], y_axis, rz, 0)
            rot = math.random(0, 8) * 90
            Turn(Wall[i], y_axis, math.rad(rot), 0)
            Show(Wall[i])
            if OutPost[(i - 1) * 2 + 1] then
                Show(OutPost[(i - 1) * 2 + 1])
            end
            if OutPost[(i - 1) * 2 + 2] then
                Show(OutPost[(i - 1) * 2 + 2])
            end
        end
    end

    if nrDoors > 0 then
        for i = 1, nrDoors do
            if Door[i] then
                Show(Door[i])
                if DoorPost[(i - 1) * 2 + 1] then
                    Show(DoorPost[(i - 1) * 2 + 1])
                end
                if DoorPost[(i - 1) * 2 + 2] then
                    Show(DoorPost[(i - 1) * 2 + 2])
                end

                post = DoorPost[(i - 1) * 2 + 1]

                rx, rz = math.random(xMax / -2, xMax / 2),
                         math.random(zMax / -2, zMax / 2)
                Move(post, x_axis, rx, 0)
                Move(post, y_axis, rz, 0)
                rot = math.random(0, 360 / 90) * 90
                Turn(post, y_axis, math.rad(rot), 0)

            end
        end
    end
end

function testTwoUnits(id, ad)
    ix, iy, iz = Spring.GetUnitPosition(id)
    ax, ay, az = Spring.GetUnitPosition(ad)
    return isLineOfFireFree(ix, iz, ax, az)
end
-- compares too world coords
function isLineOfFireFree(x, z, tx, tz)
    for i = 1, nrWalls do
        wall1, wall2 = OutPost[(i - 1) * 2 + 1], OutPost[(i - 1) * 2 + 2]
        if wall1 and wall2 then
            w1x, _, w1z = Spring.GetUnitPiecePosDir(unitID, wall1)
            w2x, _, w2z = Spring.GetUnitPiecePosDir(unitID, wall2)
            ix, iz = get_line_intersection(x, z, tx, tz, w1x, w1z, w2x, w2z)
            if ix then return false end
        end
    end

    for i = 1, nrDoors do
        door1, door2 = DoorPost[(i - 1) * 2 + 1], DoorPost[(i - 1) * 2 + 2]
        if door1 and door2 then
            w1x, _, w1z = Spring.GetUnitPiecePosDir(unitID, door1)
            w2x, _, w2z = Spring.GetUnitPiecePosDir(unitID, door2)
            ix, iz = get_line_intersection(x, z, tx, tz, w1x, w1z, w2x, w2z)
            if ix then return false end
        end
    end

    return true
end

ringUpOffset = 0

function ringringUpOffset()
    boolOldRoundEnd = not boolRoundEnd
    index = 0
    foreach(ring, function(id)
        index = index + 1
        Spin(id, y_axis, math.rad(index * 4.2) * randSign(), 15)
    end)
    moveT(ring, z_axis, 6000, 18000, false, 3, 7)

    while true do
        if boolRoundEnd == false then
            ringUpOffset = -2000
        else
            ringUpOffset = 6000
        end
        if boolOldRoundEnd ~= boolRoundEnd then
            StartThread(showIntervallRing, ring, 3000)
            boolOldRoundEnd = boolRoundEnd
        end
        moveT(ring, z_axis, ringUpOffset, math.random(1500, 3600), false, 3, 7)
        Sleep(3000)
    end
end

function showIntervallRing(t, times)
    showT(t, 3, 7)
    Sleep(times)
    hideT(t, 3, 7)
end
SIG_WAVE = 2
function waveSpin(id, val, speedtime, randoffset, boolRandoHide)
    SetSignalMask(SIG_WAVE)
    randoffset = math.abs(randoffset) or 1
    if val < 1 then val = 1 end
    Move(id, z_axis, ringUpOffset, math.abs(ringUpOffset))
    while true do
        distDance = val + ringUpOffset + math.random(-randoffset, randoffset)
        if boolRandoHide == true and maRa() == true then
            Hide(id)
        else
            Show(id)
        end
        WMove(id, z_axis, distDance, math.abs(distDance / speedtime))
        if boolRandoHide == true and maRa() == true then
            Hide(id)
        else
            Show(id)
        end
        distDance = val * -1 + ringUpOffset +
                        math.random(-randoffset, randoffset)
        WMove(id, z_axis, distDance, math.abs(distDance / speedtime))
    end
end

function getPlayingFieldMaxMinZ()
    xMax, xMin, zMax, zMin, height = -math.huge, math.huge, -math.huge,
                                     math.huge, 0

    foreach(TablesOfPiecesGroups["Corner"], function(id)
        dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, id)
        if dx > xMax then xMax = dx end
        if dx < xMin then xMin = dx end
        if dz > zMax then zMax = dz end
        if dz < zMin then zMin = dz end
        height = dy
    end)

    return xMax, xMin, zMax, zMin, height
end

function registerPlaceUnit(idToRegister, boolIsObjctive)
    Spring.MoveCtrl.Enable(idToRegister, true)
    mx, my, mz = Spring.GetUnitPosition(unitID)
    rx, ry, rz = Spring.GetUnitPosition(idToRegister)
    xMax, xMin, zMax, zMin, height = getPlayingFieldMaxMinZ()
    -- Spring.Echo("xMax,xMin,zMax,zMin, height", xMax, xMin, zMax, zMin, height)
    rx = math.min(xMax, math.max(xMin, rx))
    rz = math.min(zMax, math.max(zMin, rz))
    ry = math.max(ry, height)
    Spring.MoveCtrl.SetPosition(idToRegister, rx, ry, rz)
end

function playEndAnimation()
    Signal(SIG_WAVE)

    foreach(whirl, function(id)
        runHide = function(id)
            dest, speed = math.random(600, 900), math.random(600, 900)
            WMove(id, z_axis, dest, speed)
            Hide(id)
        end

        StartThread(runHide, id)
    end)

    foreach(ring, function(id)
        runHide = function(id)
            dest, speed = math.random(600, 1200), math.random(900, 2400)
            WMove(id, z_axis, dest, speed)
            Hide(id)
        end

        StartThread(runHide, id)
    end)

    Sleep(1)
    WaitForMoves(whirl)
    WaitForMoves(ring)
end

function script.Killed(recentDamage, _)
    playEndAnimation()
    setAffiliatedHouseVisible()

    return 1
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
