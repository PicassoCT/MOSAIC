include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

center = piece "center"
Circle001 = piece "Circle001"
Money = piece "Base"
DollarSign = piece "DollarSign"

local GameConfig = getGameConfig()
myTeamID = Spring.GetUnitTeam(unitID)

function script.Create()
    Hide(Money)
    Hide(DollarSign)
    Hide(Circle001)
    sign = randSign()
    Spin(DollarSign,y_axis,math.rad(42*sign),0)
    Spin(DollarSign,y_axis,math.rad(42*sign),0)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(AnimationTest)
    StartThread(CrimeDoesPay)
    StartThread(DollarSignRisingLoop)
end
allDoneIndex = 0

function AnimationTest()
    antline = TablesOfPiecesGroups["antline "]
    Sleep(100)
    resetAll(unitID)
    hideT(antline)
    while true do
        randOffset = math.random(1, #antline)
        for index = 1, #antline do
            randPiece = ((index + randOffset) % #antline) + 1
            dist = math.random(75, 90)
            if antline[randPiece] then
                allDoneIndex = allDoneIndex + 1
                StartThread(queuedLineMove, antline[randPiece], index, dist,   dist / 5)
            end
        end
        while allDoneIndex > 0 do Sleep(100) end
    end
end

function DollarSignRisingLoop()
    local upDownAxis = z_axis
    local moveDistance = 420
    while true do
        Spin(DollarSign, 3, math.rad(42*randSign()), 0)
        Spin(Money, 3, math.rad(42*randSign()), 0)
        Move(DollarSign,upDownAxis,-moveDistance, 0)
        Show(DollarSign)
        Move(Money,upDownAxis, 0,0)
        Move(Money,upDownAxis, -moveDistance * 2, moveDistance * 2)

        Show(Money)
        WMove(DollarSign,upDownAxis,0, moveDistance)
        Hide(DollarSign)
        Hide(Money)
        Sleep(50)
    end
end

function CrimeDoesPay()
    waitTillComplete(unitID)
    waitTime = GameConfig.rewardWaitTimeCyberCrimeSeconds * 1000
    Sleep(waitTime)

   GG.Bank:TransferToTeam(GameConfig.RewardCyberCrime, myTeamID, unitID)  
   Spring.AddTeamResource(myTeamID, "energy", GameConfig.RewardCyberCrime)
    Sleep(1000)
   Spring.DestroyUnit(unitID,true,false)
end

function queuedLineMove(piecename, nr, distance, speed)
    reset(piecename, 0)
    naptime = nr * (distance / speed) * 100
    Sleep(naptime)
    if maRa() == true then Show(piecename) end
    Move(piecename, z_axis, distance, speed)
    WMove(piecename, y_axis, -distance, speed)
    Hide(piecename)
    allDoneIndex = allDoneIndex - 1
end

function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

