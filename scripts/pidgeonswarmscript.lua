include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(observer)
    hideT(Spring.GetUnitPieceList(unitID))
   
    for i = 1, #Birds, 1 do
        showLand(i)
    end

    StartThread(posBools)
    for i = 1, numberOfBirds, 1 do
        StartThread(birdOS, i)
    end

    Spring.SetUnitAlwaysVisible(unitID, true)

end

boolThreatend = false
function observer()
	while true do
		boolThreatend = false
		foreach(
			getAllNearUnit(unitID, 150),
			function(id)
				--is car or civilian
				boolThreatend = true
			end		
		)

		if boolThreatend then
			x,y,z = Spring.GetUnitPosition(unitID)
			x,z = x + math.random(-500,500), z + math.random(-500,500)
			Command( unitID, "go", {x,y,z})
		end
		Sleep(1000)
	end
end


bigRot1 = piece "bigRot1"
smallRot1 = piece "smallRot1"

RengerateInterval= 25000
--Bird, Bird, Bird is the word
local Birds = {rotator = piece("Rotator")}
local numberOfBirds = 5
for i = 1, numberOfBirds, 1 do

    LandPiece = piece("Land" .. i)
    LFoot = piece("L" .. i .. "1")
    RFoot = piece("L" .. i .. "2")
    Land = {
        [1] = LandPiece,
        [2] = LFoot,
        [3] = RFoot
    }
    AirPiece = piece("Fly" .. i)
    LWing = piece("RW" .. i)
    RWing = piece("LW" .. i)

    Air = {
        [1] = AirPiece,
        [2] = LWing,
        [3] = RWing
    }
    
    Center = piece("cent" .. i)
    smallRot = piece("smallRot" .. i)
    bigRot = piece("bigRot" .. i)

    Birds[i] = {
        Land = Land,
        Air = Air,
        Center = Center,
        sRot = smallRot,
        bRot = bigRot,
        boolAnimating = false,
        boolFlying = false,
        boolStillActive = true
    }
end

function HideBird(nr)
    Hide(Birds[nr].Air[1])
    Hide(Birds[nr].Air[2])
    Hide(Birds[nr].Air[3])

    Hide(Birds[nr].Land[1])
    Hide(Birds[nr].Land[2])
    Hide(Birds[nr].Land[3])
end

teamid = Spring.GetUnitTeam(unitID)

function showLand(nr)
    if Birds[nr].boolStillActive == true then
        Show(Birds[nr].Land[1])
        Show(Birds[nr].Land[2])
        Show(Birds[nr].Land[3])
        Hide(Birds[nr].Air[1])
        Hide(Birds[nr].Air[2])
        Hide(Birds[nr].Air[3])
    end
end



function showAir(nr)
    if Birds[nr].boolStillActive == true then
        Hide(Birds[nr].Land[1])
        Hide(Birds[nr].Land[2])
        Hide(Birds[nr].Land[3])
        Show(Birds[nr].Air[1])
        Show(Birds[nr].Air[2])
        Show(Birds[nr].Air[3])
    end
end

local SIG_ENERGY = 1
local SIG_METAL = 2
local SIG_LAND = 4
local SIG_AIR = 8
local SIG_WING1 = 16
local SIG_WING2 = 32
local SIG_WING3 = 64
local SIG_WING4 = 128

local boolStationary = true


function posBools()
    ox, oy, oz = Spring.GetUnitPosition(unitID)
    x, y, z = ox, oy, oz
    local spGetUnitPos = Spring.GetUnitPosition
    local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
    while true do
        x, y, z = spGetUnitPos(unitID)
        if (math.abs(math.abs(ox - x) + math.abs(oy - y) + math.abs(oz - z)) < 10) then
            boolStationary = true
        else
            boolStationary = false
        end

        for i = 1, numberOfBirds, 1 do
            px, py, pz, _, _, _ = spGetUnitPiecePosDir(unitID, Birds[i].Air[1])
            h = Spring.GetGroundHeight(px, pz)
            if (py - h > 21) then
                Birds[i].boolFlying = true
            else
                Birds[i].boolFlying = false
            end
        end

        ox, oy, oz = x, y, z
        Sleep(200)
    end
end


_, baseHealth = Spring.GetUnitHealth(unitID)
quater = math.ceil(baseHealth / 4)
half = math.ceil(baseHealth / (numberOfBirds/2))

thirthyfour = baseHealth * 0.75
aerodynamicHoles = baseHealth / 12
nextBigBarrier = baseHealth
Barriers = {
    [1] = quater,
    [2] = half,
    [3] = thirthyfour,
    [4] = baseHealth,
}


leftBirds= numberOfBirds

function birdOS(nr)

    while true do
        --idling
        idle(nr)

        --Starting     
        Starting(nr)
        --Flying

        Fly(nr)
        --Landing
        Landing(nr)
        Sleep(150)
    end
end

function Starting(nr)
    LiftOff(nr)
    showAir(nr)
    if (nr==1 and maRa()) then flyOneCircle() end
    --One Circle
end

function script.Activate()
    return 1
end

function script.Deactivate()
    return 0
end

function Fly(nr)

    Sleep(150)

    while Birds[nr].boolFlying == true do
        mrval = math.random(-15, -5)
        prval = math.random(12, 22)
        ClapWings(nr, prval, 1, mrval, 1, true)
        Turn(Birds[nr].Air[2], z_axis, math.rad(0), 0.9)
        Turn(Birds[nr].Air[3], z_axis, math.rad(0), 0.9)
        Sleep(900)
    end

end
boolOnTheFly = false


function script.StartMoving()
boolOnTheFly = true
end

function script.StopMoving()
boolOnTheFly = false
end


function ClapWings(nr, degreeEnd, Speed, degreeStart)


    Move(Birds[nr].Air[1], y_axis, -3, 1.8)

    -- if degreeStart then
    --UpStage
    Turn(Birds[nr].Air[2], z_axis, math.rad(degreeStart), Speed)
    Turn(Birds[nr].Air[3], z_axis, math.rad(-360 - degreeStart), Speed)
    WaitForTurn(Birds[nr].Air[2], z_axis)
    WaitForTurn(Birds[nr].Air[3], z_axis)

    Move(Birds[nr].Air[1], y_axis, 0, 1)
    -- end
    -- Move(Birds[nr].Air[1],y_axis,3.5,1)

    Turn(Birds[nr].Air[2], z_axis, math.rad(degreeEnd), Speed)
    Turn(Birds[nr].Air[3], z_axis, math.rad(360 - degreeEnd), Speed)
    WaitForTurn(Birds[nr].Air[2], z_axis)
    WaitForTurn(Birds[nr].Air[3], z_axis)
end

function LandingAnimation(nr)
    if Birds[nr].boolStillActive == true then
        if Birds[nr].boolAnimating == true then return else Birds[nr].boolAnimating = true end
        Show(Birds[nr].Land[1])
        Show(Birds[nr].Land[2])
        Show(Birds[nr].Land[3])
        Hide(Birds[nr].Air[1])
        Turn(Birds[nr].Land[3], x_axis, math.rad(60), 3)
        Turn(Birds[nr].Land[2], x_axis, math.rad(60), 3)
        Turn(Birds[nr].Land[1], x_axis, math.rad(-60), 3)
        Turn(Birds[nr].Air[1], x_axis, math.rad(-60), 3)


        for i = 1, 10, 1 do
            ClapWings(nr, (9 - i) * 10, 5000 - i * 3, (9 - i) * -10)
        end
        Turn(Birds[nr].Air[1], x_axis, math.rad(0), 3)
        showLand(nr)

        Birds[nr].boolAnimating = false
    end
end

function flyOneCircle()
	timeSecs = 7
	WTurn(Birds.rotator, y_axis, math.rad(180), 180/(timeSecs*0.5))
	WTurn(Birds.rotator, y_axis, math.rad(360), 180/(timeSecs*0.5))
	Turn(Birds.rotator, y_axis, 0, 0)
end

function Landing(i)

    Sleep(350)

    while Birds[i].boolFlying == true do
    	if (i == 1) then flyOneCircle() end
        Sleep(200)
    end

    LandingAnimation(i)
end

local unitdef = Spring.GetUnitDefID(unitID)
function LiftOff(nr)
    PlaySoundByUnitDefID(unitdef, "sounds/jwatchbird/Raven.ogg", 1, 2000, 2)

    if Birds[nr].boolStillActive == true then
        Turn(Birds[nr].Land[3], x_axis, math.rad(60), 3)
        Turn(Birds[nr].Land[2], x_axis, math.rad(60), 3)
        Turn(Birds[nr].Air[1], x_axis, math.rad(-60), 3)
        Turn(Birds[nr].Land[1], x_axis, math.rad(-60), 3)
        Turn(Birds[nr].Land[1], y_axis, math.rad(0), 25)
        Show(Birds[nr].Air[2])
        Show(Birds[nr].Air[3])

        for i = 1, 10, 1 do
            ClapWings(nr, 90 - i * 7, math.min(120, i * 15), -90 - (i * -7))
        end
        Turn(Birds[nr].Air[1], x_axis, math.rad(0), 3)
    end
end

function idle(nr)
    while boolStationary == true and Birds[nr].boolFlying == false do


        Turn(Birds[nr].Land[3], x_axis, math.rad(-45), 4)
        Turn(Birds[nr].Land[2], x_axis, math.rad(-45), 4)
        Turn(Birds[nr].Land[1], x_axis, math.rad(45), 4)
        if boolStationary == true and Birds[nr].boolFlying == false then
            Sleep(800)
        end
        Turn(Birds[nr].Land[3], x_axis, math.rad(25), 2)
        Turn(Birds[nr].Land[2], x_axis, math.rad(25), 2)
        Turn(Birds[nr].Land[1], x_axis, math.rad(-25), 2)
        if boolStationary == true and Birds[nr].boolFlying == false then
            Sleep(700)
        end
        Turn(Birds[nr].Land[3], x_axis, math.rad(0), 0.5)
        Turn(Birds[nr].Land[2], x_axis, math.rad(0), 0.5)
        Turn(Birds[nr].Land[1], x_axis, math.rad(0), 0.5)

        d = math.random(0, 360)
        Turn(Birds[nr].Land[1], y_axis, math.rad(d), 2)
        WaitForTurn(Birds[nr].Land[1], y_axis)
        x = math.random(0, 600)
        while boolStationary == true and Birds[nr].boolFlying == false and x < 5000 do
            Sleep(100)
            x = x + 100
        end
    end
end


function ReAlign(i)
    StopSpin(Birds[i].bRot, y_axis)
    StopSpin(Birds[i].sRot, y_axis)
    Speed = 3.3
    if boolOnTheFly and boolOnTheFly == false then
        Speed = 1.2
    end
    _, ry, _ = Spring.UnitScript.GetPieceRotation(Birds[i].sRot)
    _, by, _ = Spring.UnitScript.GetPieceRotation(Birds[i].bRot)


    if by and (math.deg(by) + 360) % 360 > 180 then
        Turn(Birds[i].bRot, y_axis, math.rad(0), Speed)
    else
        Turn(Birds[i].bRot, y_axis, math.rad(179), Speed)
        WaitForTurn(Birds[i].bRot, y_axis)
        Turn(Birds[i].bRot, y_axis, math.rad(181), Speed)
        WaitForTurn(Birds[i].bRot, y_axis)
        Turn(Birds[i].bRot, y_axis, math.rad(360), Speed)
        WaitForTurn(Birds[i].bRot, y_axis)
    end

    if ry and (math.deg(ry) + 360) % 360 > 180 then
        Turn(Birds[i].sRot, y_axis, math.rad(0), Speed)
    else
        Turn(Birds[i].sRot, y_axis, math.rad(179), Speed)
        WaitForTurn(Birds[i].sRot, y_axis)
        Turn(Birds[i].sRot, y_axis, math.rad(181), Speed)
        WaitForTurn(Birds[i].sRot, y_axis)
        Turn(Birds[i].sRot, y_axis, math.rad(0), Speed)
        WaitForTurn(Birds[i].sRot, y_axis)
    end
end




function script.Killed()

    return 1
end






boolFlying= false
