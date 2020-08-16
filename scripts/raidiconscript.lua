include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
whirl = {}
ring = {}
Blue = {}
Red = {}
step = {}
Wall ={}
OutPost ={}
DoorPost ={}
Door = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

Progresscenter = piece "Progresscenter"

protagon_talk = {
    "SkyCastle Ready",
    "Retro-Observation-Results",
    "TAC Plan has go",
    "(dart sounds)",
    "away from the window",
    "to the wall",
    "drop it",
    "Defeat device removed",
    "Subjects are dosed and stable",
    "System subverted",
    "Observation, Neutralization",
    "Encapsulated Cloud Interrogation ",
    "Individual Deprecation ",
    "Sampling Artefacts",
    "FragPellets in Sit, HiSpeedCam, Upload (BOOM)",
    "Investigating Distribution"
}

antagon_talk = {
    "-your guests torture people",
    "kings things, puppets and strings",
    "I m a old friend, i need the key for one day, to throw a suprise party..",
    "Suprise, Motherfuckers",
    "God is greater",
    "This must hurt so much ?",
    "Suffer like they did",
    "Talk, talk - your live depends on it",
    "Your side simply gave you up..",
    "Though i walk through the valley of shadows",
    "we, we are your own shadow, thats what you fight",
    "you would never betray them, but they already betrayed you",
    "You shouldnt have fucked her-",
    "And though i walk in the valley of death"
}

function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, true)
    -- Spring.SetUnitNoSelect(unitID,true)
    Spring.MoveCtrl.Enable(unitID, true)
    ox, oy, oz = Spring.GetUnitPosition(unitID)
    -- Spring.SetUnitPosition(unitID, ox,oy + 125, oz)
    showAll(unitID)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(raidAnimationLoop)
    -- StartThread(raidPercentage)
    whirl = TablesOfPiecesGroups["Whirl"]
    ring = TablesOfPiecesGroups["Ring"]
    Blue = TablesOfPiecesGroups["Blue"]
    Red = TablesOfPiecesGroups["Red"]
    step = TablesOfPiecesGroups["Step"]
	
	Wall = TablesOfPiecesGroups["Wall"]
	OutPost =TablesOfPiecesGroups["OutPost"]
	DoorPost =TablesOfPiecesGroups["DoorPost"]
	Door =TablesOfPiecesGroups["Door"]
	
	hideT(Wall)
	hideT(OutPost)
	hideT(DoorPost)
		
    StartThread(setAffiliatedHouseInvisible)
    StartThread(ringringUpOffset)
    updateShownPoints(3, 3)
    hideT(TablesOfPiecesGroups["Corner"])
end

myHouseID = nil
boolRoundEnd = false

function setAffiliatedHouseInvisible()
    Sleep(100)

    houseTypeTable = getHouseTypeTable(UnitDefs, GameConfig.instance.culture)
    process(
        getAllNearUnit(unitID, 200),
        function(id)
            if houseTypeTable[Spring.GetUnitDefID(id)] then
                myHouseID = id
                StartThread(mortallyDependant, unitID, myHouseID, 15, false, true)
                env = Spring.UnitScript.GetScriptEnv(id)
                if env and env.hideHouse then
                    Spring.UnitScript.CallAsUnit(id, env.hideHouse)
                end
                moveUnitToUnit(unitID, id)
                return
            end
        end
    )
end

function setAffiliatedHouseVisible()
    if doesUnitExistAlive(myHouseID) == true then
        env = Spring.UnitScript.GetScriptEnv(myHouseID)
        if env and env.showHouse then
            Spring.UnitScript.CallAsUnit(myHouseID, env.showHouse)
        end
    end
end

figures = {
    Red = "red",
    Blue = "blue"
}

-- Exposed Functions

function updateShownPoints(redPoints, bluePoints)
    hideT(Red)
    hideT(Blue)
    showT(Red, 1, redPoints)
    showT(Blue, 1, bluePoints)
end

--//not exposed functions
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
function getRoundProgressBar()
    return counter
end

function setRoundProgressBar(value)
    counter = value
end

function raidAnimationLoop()
    Sleep(1)
    resetAll(unitID)

    index = 0
    process(
        ring,
        function(id)
            index = index + 1
            Spin(id, y_axis, math.rad(index * 4.2) * randSign(), 2.5)
            if index > 3 and index < 8 then
                StartThread(waveSpin, id, math.random(1, 4), math.random(4, 40), 500, false)
            end
        end
    )
    Spin(Progresscenter, y_axis, math.rad(42), 0.5)
    Spin(ring[8], y_axis, math.rad(42), 0.5)
    process(
        whirl,
        function(id)
            Spin(id, y_axis, math.rad(42) * randSign(), 2.5)
            StartThread(waveSpin, id, math.random(1, 6), math.random(4, 800), 100, true)
        end
    )

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
  
	nrDoors = math.random(0,#Door)
	nrWalls = math.random(0,#Wall)
	if nrWalls > 0 then
		for i=1,nrWalls do
			rx, rz = math.random(xMax/-2, xMax/2), math.random(zMax/-2, zMax/2)
			Move(Wall[i],x_axis, rx, 0)
			Move(Wall[i],y_axis, rz, 0)
			rot = math.random(0,8)*45
			Turn(Wall[i],y_axis, math.rad(rot), 0)
			Show(Wall[i])
			if OutPost[(i-1)*2 + 1] then Show(OutPost[(i-1)*2 + 1]) end
			if OutPost[(i-1)*2 + 2] then Show(OutPost[(i-1)*2 + 2]) end
		end
	end

	if nrDoors > 0 then
		for i=1,nrDoors do
			if Door[i] then
					Show(Door[i])
				if DoorPost[(i-1)*2 + 1] then Show(DoorPost[(i-1)*2 + 1]) end
				if DoorPost[(i-1)*2 + 2] then Show(DoorPost[(i-1)*2 + 2]) end
			
				post = DoorPost[(i-1)*2 + 1]
				if nrWalls == 0 then
					rx, rz = math.random(xMax/-2, xMax/2), math.random(zMax/-2, zMax/2)
					Move(post, y_axis, rx, 0)
					Move(post, z_axis, rz, 0)
					rot = math.random(0,3)*90
					Turn(post, y_axis, math.rad(rot), 0)
				else
					targWal= 1
					if nrWalls > 1 then targWal = math.random(1,nrWalls) end
					dice = math.random(1,2)
					conPost = OutPost[(targWal-1)*2 + dice]				
					movePieceToPiece(unitID, post, conPost, 0)
				end
			end
		end
	end
end

--compares too world coords
function isLineOfFireFree(x,z, tx, tz)
 for i=1, nrWalls do
	wall1, wall2 = OutPost[(i-1)*2 + 1] , OutPost[(i-1)*2 + 2] 
	if wall1 and wall2 then
	w1x,_,w1z = Spring.GetUnitPiecePosDir(unitID, wall1)
	w2x,_,w2z = Spring.GetUnitPiecePosDir(unitID, wall2)
	ix, iz = get_line_intersection(x,z,tx,tz, w1x,w1z,w2x,w2z)
		if ix then return false end
	end
 end
 
 for i=1, nrDoors do
	door1, door2 = DoorPost[(i-1)*2 + 1] , DoorPost[(i-1)*2 + 2] 
	if door1 and door2 then
	w1x,_,w1z = Spring.GetUnitPiecePosDir(unitID, door1)
	w2x,_,w2z = Spring.GetUnitPiecePosDir(unitID, door2)
	ix, iz = get_line_intersection(x,z,tx,tz, w1x,w1z,w2x,w2z)
		if ix then return false end
	end 
 end

return true
end

ringUpOffset = 0

function ringringUpOffset()
    boolOldRoundEnd = not boolRoundEnd
    index = 0
    process(
        ring,
        function(id)
            index = index + 1
            Spin(id, y_axis, math.rad(index * 4.2) * randSign(), 15)
        end
    )
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

function waveSpin(id, val, speedtime, randoffset, boolRandoHide)
    randoffset = math.abs(randoffset) or 1
    if val < 1 then
        val = 1
    end
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
        distDance = val * -1 + ringUpOffset + math.random(-randoffset, randoffset)
        WMove(id, z_axis, distDance, math.abs(distDance / speedtime))
    end
end

function getPlayingFieldMaxMinZ()
    xMax, xMin, zMax, zMin, height = -math.huge, math.huge, -math.huge, math.huge, 0

    process(
        TablesOfPiecesGroups["Corner"],
        function(id)
            dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, id)
            if dx > xMax then
                xMax = dx
            end
            if dx < xMin then
                xMin = dx
            end
            if dz > zMax then
                zMax = dz
            end
            if dz < zMin then
                zMin = dz
            end
            height = dy
        end
    )

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

function script.Killed(recentDamage, _)
    setAffiliatedHouseVisible()
    --createCorpseCUnitGeneric(recentDamage)
    return 1
end

function script.Activate()
    return 1
end

function script.Deactivate()
    return 0
end
