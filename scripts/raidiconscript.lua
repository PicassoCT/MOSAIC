include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

--include "lib_Build.lua"

myTeamID = Spring.GetUnitTeam(unitID)
GameConfig = getGameConfig()
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
ecmIconTypes =  getECMIconTypes(UnitDefs)     
Grid = piece("Grid")

function script.HitByWeapon(x, z, weaponDefID, damage) end

Progresscenter = piece "Progresscenter"
talk={
    ["protagon"] = {
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

    ["antagon"] = {
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
PlacementPhase = piece("PlacementPhase")
EvaluationPhase = piece("EvaluationPhase")
Satellite = piece("Satellite")

local satelliteTypeTable = getSatteliteTypes(UnitDefs)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
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
    Hide(PlacementPhase)
    Hide(EvaluationPhase)
    Hide(Satellite)
    Spin(EvaluationPhase,z_axis,math.rad(-42),0)
    Spin(PlacementPhase,z_axis,math.rad(42),0)


    hideT(TablesOfPiecesGroups["RaidUploadInProgress"])
    hideT(TablesOfPiecesGroups["RaidUploadRotor"])
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
    updateShownPoints(GameConfig.espionage.sniping.aggressorStartPoints, GameConfig.espionage.sniping.defenderStartPoints)
    hideT(TablesOfPiecesGroups["Corner"])
    StartThread(watchRaidIconTable)
end

function raidConversationLoop()
    mySide  = string.lower(getUnitSideString(unitID))
    while true do
        line = talk[mySide][math.random(1,#talk[mySide])]
        say(line, 2500, { r = 1.0, g = 1.0, b = 1.0 }, { r = 1.0, g = 1.0, b = 1.0 }, "", unitID)
        Sleep(5000)
    end
end

function watchRaidIconTable()
    while not GG.raidStatus or GG.raidStatus[unitID] == nil do
        Sleep(10)
    end

    -- The gadget owns the round state. The icon only animates a terminal
    -- result once the public state leaves OnGoing.
    while GG.raidStatus[unitID] and
        GG.raidStatus[unitID].state == raidStates.OnGoing do
        Sleep(50)
    end

    local status = GG.raidStatus[unitID]
    if not status then
        showRaidAbortedAnimation()
        return
    end

    local result = status.result or raidResultStates.Unknown
    local needsUplink =
        status.state == raidStates.WaitingForUplink and
        (result == raidResultStates.AggressorWins or
         result == raidResultStates.DefenderWins)

    if needsUplink then
        Show(raidNoUplink)
        Sleep(350)
        Hide(raidNoUplink)
        StartThread(UplinkAnimation)
    end

    hideAll(unitID)
    StartThread(playEndAnimation)

    if result == raidResultStates.DefenderWins then
        showDefenderSuccesAnimation()
    elseif result == raidResultStates.AggressorWins then
        showRaidSuccesAnimation()
    elseif result == raidResultStates.HouseEmpty then
        showHouseEmptyAnimation()
    else
        showRaidAbortedAnimation()
    end

    if needsUplink then
        Sleep(GameConfig.military.satellites.uploadTimeMs)
        boolRaidUploadInProgress = false
    else
        Sleep(1000)
    end

    status = GG.raidStatus[unitID]
    if status then
        if status.state ~= raidStates.Aborted then
            status.state = raidStates.VictoryStateSet
        end
        status.boolAnimationComplete = true
    end

    while true do
        Sleep(100)
    end
end

boolRaidUploadInProgress = false

function UplinkAnimation()
    Show(Satellite)
    boolRaidUploadInProgress = true
    showT(TablesOfPiecesGroups["RaidUploadRotor"])    
    spinT(TablesOfPiecesGroups["RaidUploadRotor"], z_axis, 42, 0, 0)  

   while boolRaidUploadInProgress == true do
        hideT(TablesOfPiecesGroups["RaidUploadInProgress"])
         for i=1,# TablesOfPiecesGroups["RaidUploadInProgress"] do
            Move(TablesOfPiecesGroups["RaidUploadInProgress"][i],z_axis,  -100*i, 0)
        end
        WaitForMoves(TablesOfPiecesGroups["RaidUploadInProgress"])
        showT(TablesOfPiecesGroups["RaidUploadInProgress"])
        for i=1,# TablesOfPiecesGroups["RaidUploadInProgress"] do
            Move(TablesOfPiecesGroups["RaidUploadInProgress"][i],z_axis, 1500, 700)
            Sleep(250)
        end
        WaitForMoves(TablesOfPiecesGroups["RaidUploadInProgress"])
        Sleep(250)  
        spawnCegAtPiece(unitID, Satellite, "paperflying")
    end
    hideT(TablesOfPiecesGroups["RaidUploadRotor"])
    hideT(TablesOfPiecesGroups["RaidUploadInProgress"])
end

function popPieceUp(pieceID, speed)
    axis = z_axis
    val= math.random(25,50)
    Spin(pieceID,y_axis, math.rad(val),0)
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
    for  houseID, raidIconID in pairs(GG.HouseRaidIconMap) do
        if doesUnitExistAlive(houseID) and raidIconID and raidIconID == unitID then
            myHouseID = houseID
            boolFoundHouse = true

            StartThread(mortallyDependant, unitID, myHouseID, 15, false, true)
            env = Spring.UnitScript.GetScriptEnv(myHouseID)
            if env and env.hideHouse then
                Spring.UnitScript.CallAsUnit(myHouseID, env.hideHouse)
            end
            ox, oy, oz = Spring.GetUnitPosition(myHouseID)
            min, avg, max = getGroundHeigthGrid(ox,oz, 75) 

            moveUnitToUnit(unitID, myHouseID,0, max - oy, 0)
        end
    end
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

local counter = 0
local roundResetSerial = 0

function getRoundProgressBar()
    return counter
end

function setRoundProgressBar(value)
    value = tonumber(value) or 0
    counter = value
    if value <= 0 then
        roundResetSerial = roundResetSerial + 1
    end
end

-- Fast opening, deliberately slow middle, then a visible sprint through the
-- final 15 percent. Total round duration remains maxRoundDurationMs.
local function nonLinearRoundProgress(timeFraction)
    local t = math.max(0, math.min(1, timeFraction))

    if t <= 0.25 then
        local u = t / 0.25
        return 0.35 * (1 - (1 - u) * (1 - u))
    elseif t <= 0.90 then
        local u = (t - 0.25) / 0.65
        local smooth = u * u * (3 - 2 * u)
        return 0.35 + 0.50 * smooth
    else
        local u = (t - 0.90) / 0.10
        return 0.85 + 0.15 * u * u
    end
end

function raidAnimationLoop()
    Sleep(1)
    resetAll(unitID)
    assert(type(ring) == "table", "Not a table")

    StartThread(waveSpins)
    hideT(step)

    local tickMs = 50
    local roundDurationMs = math.max(
        tickMs,
        GameConfig.espionage.raids.maxRoundDurationMs
    )
    local observedReset = -1

    while true do
        if observedReset ~= roundResetSerial then
            observedReset = roundResetSerial
            local elapsedMs = 0

            counter = 0
            Hide(EvaluationPhase)
            Show(PlacementPhase)
            placeWallAndDoors()
            showPercent(0)

            while observedReset == roundResetSerial and
                elapsedMs < roundDurationMs do
                counter = nonLinearRoundProgress(
                    elapsedMs / roundDurationMs
                ) * 100
                showPercent(counter)
                Sleep(tickMs)
                elapsedMs = elapsedMs + tickMs
            end

            if observedReset == roundResetSerial then
                counter = 100
                showPercent(100)
            end
        end
        Sleep(25)
    end
end

nrDoors = 0
nrWalls = 0
lx_axis = 1
ly_axis = 2
lz_axis = 3
-- This model's exported local axes are non-standard; walls and doors rotate
-- correctly around local Z, not world-up Y.
turnAxis = z_axis

local roomLayouts = {
    {
        -- Offset L-room plus a side chamber.
        walls = {
            {-0.38, -0.02, 90},
            {-0.10, -0.34, 0},
            { 0.34,  0.18, 90},
            { 0.10,  0.38, 0}
        },
        doors = {
            {-0.08, 0.02, 90},
            { 0.26, 0.02, 0}
        }
    },
    {
        -- Two staggered rooms connected by a bent corridor.
        walls = {
            {-0.34, -0.24, 90},
            {-0.10,  0.02, 0},
            { 0.34,  0.24, 90},
            { 0.08, -0.38, 0},
            { 0.12,  0.40, 0}
        },
        doors = {
            {-0.08, -0.18, 0},
            { 0.18,  0.18, 90}
        }
    },
    {
        -- T-junction: three distinct sight lines, no single safe corner.
        walls = {
            { 0.00, -0.30, 0},
            { 0.00,  0.28, 0},
            {-0.34,  0.04, 90},
            { 0.34, -0.06, 90}
        },
        doors = {
            { 0.00, 0.00, 90},
            { 0.22, 0.30, 0}
        }
    },
    {
        -- Apartment-like central partition with two flanking rooms.
        walls = {
            {-0.42,  0.02, 90},
            { 0.42, -0.02, 90},
            {-0.10, -0.34, 0},
            { 0.12,  0.34, 0},
            { 0.00,  0.00, 90}
        },
        doors = {
            {-0.02, -0.10, 90},
            { 0.02,  0.18, 0}
        }
    }
}

function plopElementUp(pieceID, height, speed)
    Move(pieceID, ly_axis, 0, 0)
    WMove(pieceID, ly_axis, height + 50, speed)
    Sleep(250)
    WMove(pieceID, ly_axis, height, speed)
end

local function normalizedArenaPosition(
    normalizedX,
    normalizedZ,
    xMin,
    xMax,
    zMin,
    zMax,
    pieceScale
)
    local centerX = (xMin + xMax) * 0.5
    local centerZ = (zMin + zMax) * 0.5
    local halfX = (xMax - xMin) * 0.5
    local halfZ = (zMax - zMin) * 0.5

    return
        (centerX + normalizedX * halfX) * pieceScale,
        (centerZ + normalizedZ * halfZ) * pieceScale
end

local function placeArenaPiece(
    pieceID,
    layoutEntry,
    xMin,
    xMax,
    zMin,
    zMax,
    pieceScale
)
    if not pieceID or not layoutEntry then return end

    local px, pz = normalizedArenaPosition(
        layoutEntry[1],
        layoutEntry[2],
        xMin, xMax, zMin, zMax,
        pieceScale
    )

    Move(pieceID, lx_axis, px, 0)
    Move(pieceID, lz_axis, pz, 0)
    Turn(pieceID, turnAxis, math.rad(layoutEntry[3] or 0), 0)
    Show(pieceID)
    StartThread(plopElementUp, pieceID, 50, 250)

    return px, pz
end

local function placeDoorPosts(
    doorIndex,
    px,
    pz,
    rotationDegrees,
    postOffset
)
    local postA = DoorPost[(doorIndex - 1) * 2 + 1]
    local postB = DoorPost[(doorIndex - 1) * 2 + 2]
    if not postA or not postB then return end

    local rotation = math.rad(rotationDegrees or 0)
    local dx = math.cos(rotation) * postOffset
    local dz = math.sin(rotation) * postOffset

    Move(postA, lx_axis, px - dx, 0)
    Move(postA, lz_axis, pz - dz, 0)
    Move(postB, lx_axis, px + dx, 0)
    Move(postB, lz_axis, pz + dz, 0)
    Turn(postA, turnAxis, rotation, 0)
    Turn(postB, turnAxis, rotation, 0)
    Show(postA)
    Show(postB)
end

function placeWallAndDoors()
    hideT(Wall)
    resetT(Wall)
    hideT(Door)
    resetT(Door)
    hideT(DoorPost)
    resetT(DoorPost)
    hideT(OutPost)
    resetT(OutPost)

    local xMax, xMin, zMax, zMin = getPlayingFieldMaxMinUnit()
    local pieceScale = 0.85 * 12 * 2
    local layout = roomLayouts[math.random(1, #roomLayouts)]

    nrWalls = math.min(#Wall, #layout.walls)
    nrDoors = math.min(#Door, #layout.doors)

    for i = 1, nrWalls do
        local wallEntry = layout.walls[i]
        placeArenaPiece(
            Wall[i],
            wallEntry,
            xMin, xMax, zMin, zMax,
            pieceScale
        )

        -- OutPost pairs are the model's wall endpoints used for line-of-fire.
        -- If they are children of Wall they follow the transform; showing them
        -- keeps the visible posts consistent with the blocking segment.
        local postA = OutPost[(i - 1) * 2 + 1]
        local postB = OutPost[(i - 1) * 2 + 2]
        if postA then Show(postA) end
        if postB then Show(postB) end
    end

    local arenaSpan = math.min(
        math.abs(xMax - xMin),
        math.abs(zMax - zMin)
    ) * pieceScale
    local postOffset = math.max(8, arenaSpan * 0.035)

    for i = 1, nrDoors do
        local doorEntry = layout.doors[i]
        local px, pz = placeArenaPiece(
            Door[i],
            doorEntry,
            xMin, xMax, zMin, zMax,
            pieceScale
        )

        if px and pz then
            placeDoorPosts(
                i,
                px,
                pz,
                doorEntry[3],
                postOffset
            )
        end
    end
end

function testTwoUnits(id, ad)
    local ix, _, iz = Spring.GetUnitPosition(id)
    local ax, _, az = Spring.GetUnitPosition(ad)
    if not ix or not ax then return false end
    return isLineOfFireFree(ix, iz, ax, az)
end

function isLineOfFireFree(x, z, tx, tz)
    for i = 1, nrWalls do
        local wall1 = OutPost[(i - 1) * 2 + 1]
        local wall2 = OutPost[(i - 1) * 2 + 2]
        if wall1 and wall2 then
            local w1x, _, w1z = Spring.GetUnitPiecePosDir(unitID, wall1)
            local w2x, _, w2z = Spring.GetUnitPiecePosDir(unitID, wall2)
            if w1x and w2x then
                local intersectionX = get_line_intersection(
                    x, z, tx, tz,
                    w1x, w1z, w2x, w2z
                )
                if intersectionX then return false end
            end
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
            Show(EvaluationPhase)
            Hide(PlacementPhase)
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

function getPlayingFieldMaxMinUnit()
    xMax, xMin, zMax, zMin, height = -math.huge, math.huge, -math.huge, math.huge, 0

    foreach(TablesOfPiecesGroups["Corner"], function(id)
        dx, dy, dz = Spring.GetUnitPiecePosition(unitID, id)
        xMax = math.max(xMax,dx) 
        xMin = math.min(xMin,dx) 
        zMax = math.max(zMax,dz) 
        zMin = math.min(zMin,dz) 
        height = dy
    end)

    return xMax, xMin, zMax, zMin, height
end

function getPlayingFieldMaxMinWorld()
    xMax, xMin, zMax, zMin, height = -math.huge, math.huge, -math.huge, math.huge, 0

    foreach(TablesOfPiecesGroups["Corner"], function(id)
        dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, id)
        xMax = math.max(xMax,dx) 
        xMin = math.min(xMin,dx) 
        zMax = math.max(zMax,dz) 
        zMin = math.min(zMin,dz) 
        height = dy
    end)

    return xMax, xMin, zMax, zMin, height
end

function registerPlaceUnit(idToRegister, boolIsObjctive)
    Spring.MoveCtrl.Enable(idToRegister, true)
    mx, my, mz = Spring.GetUnitPosition(unitID)
    rx, ry, rz = Spring.GetUnitPosition(idToRegister)
    xMax, xMin, zMax, zMin, height = getPlayingFieldMaxMinWorld()
    -- Spring.Echo("xMax,xMin,zMax,zMin, height", xMax, xMin, zMax, zMin, height)
    rx = math.min(xMax, math.max(xMin, rx))
    rz = math.min(zMax, math.max(zMin, rz))
    ry = math.max(ry, height)
    Spring.MoveCtrl.SetPosition(idToRegister, rx, ry, rz)
end

function playEndAnimation()
    Signal(SIG_WAVE)
    Hide(EvaluationPhase)
    Hide(PlacementPhase)

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
    StartThread(playEndAnimation)
    setAffiliatedHouseVisible()

    return 1
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
