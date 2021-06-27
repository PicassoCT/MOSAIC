include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "center"
Circle001 = piece "Circle001"
Money = piece "Base"
DollarSign = piece "DollarSign"
local GameConfig = getGameConfig()
myTeamID = Spring.GetUnitTeam()

antline = {}

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    antline = TablesOfPiecesGroups["antline "]
    Hide(Circle001)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    StartThread(AnimationTest)
    StartThread(CrimeDoesPay)
end
allDoneIndex = 0

function AnimationTest()
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
                StartThread(queuedLineMove, antline[randPiece], index, dist,
                            dist / 5)
            end
        end
        while allDoneIndex > 0 do Sleep(100) end

    end
end

function DollarSignRisingLoop()
    while true do
        Spin(DollarSign,y_axis,math.rad(42*randSign(),0)
        Move(DollarSign,y_axis,-60, 0)
        Show(DollarSign)
        WMove(DollarSign,y_axis,0, 60)
        Hide(DollarSign)
        Sleep(50)
    end
end

function CrimeDoesPay()
    Hide(Money)
    Hide(DollarSign)
    waitTillComplete(unitID)
    Spin(DollarSign,y_axis, math.rad(42), 0)
    for i=1,5 do
        Sleep(150)
        Explode(Money.SFX.FALL + SFX.NO_HEATCLOUD)
    end

   GG.Bank:TransferToTeam(GameConfig.RewardCyberCrime, myTeamID, unitID)  
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

