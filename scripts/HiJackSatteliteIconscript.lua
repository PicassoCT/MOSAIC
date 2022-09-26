include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
myAllyTeamID = Spring.GetUnitAllyTeam(unitID)
satelliteTypeTable = getSatteliteTypes(UnitDefs)
myTeam = Spring.GetUnitTeam(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
    StartThread(hijackObservationSatellite)
    StartThread(uploadAnimation)
end

function uploadAnimation()
    index =1
    hideT(TablesOfPiecesGroups["Data"])
    dist = 500000
    speed = dist/#TablesOfPiecesGroups["Data"]
    rest = math.ceil(dist/#TablesOfPiecesGroups["Data"])
    while(true) do
        WaitForMoves(TablesOfPiecesGroups["Data"])
        for index= 1, #TablesOfPiecesGroups["Data"] do
        reset(TablesOfPiecesGroups["Data"][index],0)
        Show(TablesOfPiecesGroups["Data"][index])
        Move(TablesOfPiecesGroups["Data"][index],z_axis, dist,speed)
        Sleep(rest)
        end

    
    end
end

function hijackObservationSatellite()
    waitTillComplete(unitID)
    chosenSatellite = nil
    while (chosenSatellite == nil) do
        spySatellites = {}
        allSattelites = foreach(Spring.GetAllUnits(),
            function(id)
                if Spring.GetUnitAllyTeam(id) ~= myAllyTeamID then
                    return id
                end
            end,
            function (id)
                defID = Spring.GetUnitDefID(id)

                if defID == spySatteliteDefID then
                    spySatellites[#spySatellites+1] = id
                end
                return id
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
        end
        Sleep(1000)
    end
    Spring.DestroyUnit(unitID, false, true) 
end


function script.Killed(recentDamage, _)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end
