include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

center = piece "center"
Icon = piece "Icon"
attachpoint = piece "attachpoint"
Packed = piece "Packed"
GameConfig = getGameConfig()

local id
function attachSatellite()
    Sleep(1)
    x, y, z = Spring.GetUnitPosition(unitID)
    teamID = Spring.GetUnitTeam(unitID)
    id = Spring.CreateUnit("noone", x, y, z, 1, teamID)
    if Icon then
        Move(Icon, y_axis, GameConfig.Satellite.iconDistance, 0);
        Show(Icon)
    end
    -- Spring.SetUnitAlwaysVisible(id,true)
    Spring.UnitAttach(unitID, id, attachpoint)
    sendMessage(unitID, id)
    Spring.SetUnitNoSelect(unitID, true)
    hp, mp = Spring.GetUnitHealth(id)
    while hp and hp > 0 do
        hp, mp = Spring.GetUnitHealth(id)
        Sleep(10)
    end
    Spring.DestroyUnit(unitID, true, false)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- echo("Satellite Anti Script here")

    StartThread(delayedShow)
    StartThread(observeTeamChange)
    StartThread(threeBeepLoop)
end

function observeTeamChange()
    myTeam = Spring.GetUnitTeam(unitID)
    while true do
        newTeam = Spring.GetUnitTeam(unitID)
        if newTeam ~= myTeam then -- Team changed
            if doesUnitExistAlive(id) == true then
                transferUnitTeam(id, newTeam)
            end
            myTeam = newTeam
        end
        delay = math.random(10,15)*50
        Sleep(delay)
    end
end

function delayedShow()
    Turn(center, x_axis, math.rad(180), 0)
    hideAll(unitID)
    Show(Packed)
    waitTillComplete(unitID)
    WTurn(center, x_axis, math.rad(0), math.pi)
    spindeg = math.random(10, 42) * randSign()
    Spin(center, y_axis, math.rad(spindeg), 0.01)
    Explode(Packed, SFX.SHATTER)
    showAll(unitID)
    Hide(Packed)
    StartThread(attachSatellite)

end

function script.Killed(recentDamage, _)
    if id and isUnitAlive(id) == true then
        Spring.UnitDetach(id, true);
        Spring.DestroyUnit(id, true, false)
    end
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

boolBeep = false
function threeBeepLoop()
    while true do
        Sleep(1000)
        if boolBeep then
            if boolParked == false then
            for i=1,3 do 
                Spring.PlaySoundFile("sounds/satellite/beep.wav", 1.0/i)
                Sleep(1000)
            end
            else
            for i=3,1,-1 do 
                Spring.PlaySoundFile("sounds/satellite/beep.wav", 1.0/i)
                Sleep(1000)
            end
            end
        boolBeep = false
        end
    end
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then
        hideAll(unitID)
        Show(Icon)
        boolParked = true
        boolPeep = true
    else
        showAll(unitID)
        Hide(Icon)
        boolParked = false
        boolPeep = true
    end
end
