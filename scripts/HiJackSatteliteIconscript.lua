include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
satelliteTypeTable = getSatteliteTypes(UnitDefs)
myTeam = Spring.GetUnitTeam(unitID)
center = piece("center")
Sat = piece("Sat")
function script.HitByWeapon(x, z, weaponDefID, damage) end
GameConfig = getGameConfig()

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitAlwaysVisible(unitID, true)
    StartThread(hoverAboveGround, unitID, GameConfig.iconHoverGroundOffset, 0.3)  
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    StartThread(hijackObservationSatellite)
    StartThread(uploadAnimation)  
end

SIG_DATA = 1
function uploadAnimation()
    SetSignalMask(SIG_DATA)
    Spin(center,y_axis,math.rad(42),0)
    index =1
    hideT(TablesOfPiecesGroups["Data"])
    dist = 26500
    seconds= 2
    speed = dist/seconds
    rest = math.ceil((1/#TablesOfPiecesGroups["Data"])*1000*seconds)

    while(true) do
        WaitForMoves(TablesOfPiecesGroups["Data"])
        for index= 1, #TablesOfPiecesGroups["Data"] do
            reset(TablesOfPiecesGroups["Data"][index],0)
            if maRa() then
                Hide(TablesOfPiecesGroups["Data"][index])
            else
                Show(TablesOfPiecesGroups["Data"][index])
                Move(TablesOfPiecesGroups["Data"][index],z_axis, dist,speed)
            end
            Sleep(rest)
        end
        val = math.random(5,150)
        Sleep(val)    
    end
end

function hijackObservationSatellite()
    waitTillComplete(unitID)
    chosenSatellite = nil

    Sleep(GameConfig.Sattelite.SatteliteHijackTimeMs)
    while true do
        spySatellites = {}
        allSattelites = foreach(Spring.GetAllUnits(),
            function(id)
                if Spring.GetUnitTeam(id) ~= myTeam then
                    return id
                end
            end,
            function (id)
                defID = Spring.GetUnitDefID(id)

                if defID == spySatteliteDefID then
                    spySatellites[#spySatellites+1] = id
                end
                if satelliteTypeTable[defID] then
                    return id
                end
            end
            )
        
        if spySatellites and #spySatellites > 0 then
            chosenSatellite = getSafeRandom(spySatellites)
        end

        if not chosenSatellite and allSattelites and #allSattelites > 0 then
            chosenSatellite = getSafeRandom(allSattelites)
        end
        if chosenSatellite ~= nil then
          transferUnitTeam(chosenSatellite, myTeam)
          Signal(SIG_DATA)
          hideT(TablesOfPiecesGroups["Data"])
          blinkPiece(Sat, 5000, 500)
          Spring.DestroyUnit(unitID, false, true) 
        end
        Sleep(1000)
    end
end


function script.Killed(recentDamage, _)
    Explode(center,  SFX.SHATTER)
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end
