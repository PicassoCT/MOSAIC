include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
GameConfig = getGameConfig()
TablesOfPiecesGroups = {}
Rotor = piece("Rotor")
Icon = piece("Icon")
Door = piece("Door")
Leaver = piece("Leaver")
TruckTypeTable = getTruckTypeTable(UnitDefs)
gaiaTeamID = Spring.GetGaiaTeamID()

function script.HitByWeapon(x, z, weaponDefID, damage) end

myTeamID = Spring.GetUnitTeam(unitID)
Volume = piece "Volume"
function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups)
    StartThread(animationLoop)
    StartThread(stealVehicle)
end

function animationLoop()
    hideAll(unitID)
    while true do
        resetT(TablesOfPiecesGroups,0)
        Spin(Volume,y_axis,math.rad(42), 4.2)
        Spin(Rotor,y_axis,math.rad(-42), 4.2)
        Show(Rotor)
        Show(Volume)
        Move(Icon,3, -250, 0)
        Move(Icon,3,0, 250)
        Show(Icon)
        Show(Door)
        WaitForMoves(Icon)
        Show(Leaver)
        WTurn(Leaver, z_axis, math.rad(-42), 12)
        for i=0,8 do
            WTurn(Leaver, z_axis, math.rad(10*i), 12)
        end
        Move(Leaver,2, -10, 50)
        Turn(Leaver,z_axis, 0, 50)
        WTurn(Door, y_axis, math.rad(-38.5), 5.5)
        Hide(Leaver)
        Sleep(250)
        WTurn(Door, y_axis, math.rad(0), 10)
        WMove(Icon,3, 1000, 250)
        hideT(TablesOfPiecesGroups)
        Show(Rotor)
    Sleep(100)
    end
end
function stealVehicle()
    local recruitmentRange = GameConfig.agentConfig.recruitmentRange
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitPosition = Spring.GetUnitPosition
    local spDestroyUnit = Spring.DestroyUnit
    waitTillComplete(unitID)
    StartThread(lifeTime, unitID, 15000, true, false)

    while true do
        Sleep(100)
        foreach(getAllNearUnit(unitID, recruitmentRange), 
        function(id)
            if spGetUnitTeam(id) == gaiaTeamID then return id end
        end, 
        function(id)
            recruitedDefID = spGetUnitDefID(id)
            if TruckTypeTable[recruitedDefID] then
               ad = copyUnit(id, teamID)
                fatherID = fatherID or unitID
                x,y,z = Spring.GetUnitPosition(fatherID)
                if doesUnitExistAlive(id) == true and
                   doesUnitExistAlive(fatherID) then
                     Spring.SetUnitLoadingTransport(fatherID, ad)
                     env = Spring.UnitScript.GetScriptEnv(ad) 
                    if env and env.TransportPickup then
                        Spring.UnitScript.CallAsUnit(ad, env.TransportPickup,fatherID)
                    end
                end
               spDestroyUnit(id, false, true)
               spDestroyUnit(unitID, false, true)
               endIcon()
            end
        end
        )
    end
end

function endIcon()
    Spring.DestroyUnit(unitID, false, true)
    while true do Sleep(1000) end
end


function script.Killed(recentDamage, _)
    return 1
end
