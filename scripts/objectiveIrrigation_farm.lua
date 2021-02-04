include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
Irrigation1 = piece"Irrigation1"
GameConfig = getGameConfig()
local houseTypeTable = getCultureUnitModelNames(GameConfig.instance.culture, "house", UnitDefs)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitAlwaysVisible(unitID,true)
    resetAll(unitID)
    StartThread(spawnDecalAtPiece,Irrigation1)
    StartThread(startRotation, 1)
end

function spawnDecalAtPiece(pieceName)
    Sleep(500)
    px,py,pz = Spring.GetUnitPiecePosDir(unitID, pieceName)
    dir =  math.random(1,4)
    Spring.CreateUnit("agriculture_decal01",  px, py, pz,dir, Spring.GetGaiaTeamID())
end

function script.Killed(recentDamage, _)
    return 1
end

function startRotation(nr)
    Rotator = piece("Rotator"..nr)
    Sprinkler = piece("Sprinkler"..nr)
    Sensor = piece("Sensor"..nr)
    Spin(Rotator,y_axis, math.rad(4.2),0)
    val= 0
    while true do
        x,y,z = Spring.GetUnitPiecePosDir(unitID, Sensor)
        groundHeight = Spring.GetGroundHeight(x,z)
        if y > groundHeight then
            val= val - 1
        else
            val= val + 1
        end
        WTurn(Sprinkler, x_axis, math.rad(val), 0.0250)
        Sleep(10)
    end
end