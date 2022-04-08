include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

TablesOfPiecesGroups = {}
FireEmit= piece"FireEmit"
DustEmit= piece"DustEmit"
center = piece "Body1"
aimpiece = piece "Turret1"
Cannon1 = piece "Cannon1"
Shell = piece"Shell"
SIG_RESETAIM = 1
myDefID = Spring.GetUnitDefID(unitID)
myTeamID = Spring.GetUnitTeam(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
lastTurretRotation = 0

function delayedResetFirestate()
 orgstate = getFireState(unitID)
 Sleep(2500)
 setFireState(unitID, orgstate)
end

function script.HitByWeapon(x, z, weaponDefID, damage) 
    StartThread(delayedResetFirestate)
    setFireState(unitID, "fireatwill")
return damage
end


function script.Create()
    Hide(DustEmit)
    Hide(FireEmit)    
    Hide(Shell)

    generatepiecesTableAndArrayCode(unitID)

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    resetAll(unitID)
    if gaiaTeamID == myTeamID then
        Spring.SetUnitAlwaysVisible(unitID, true)
    end
    StartThread(emitDustRotateWheels)
end

function script.Killed(recentDamage, _)
    for groupname, list in pairs (TablesOfPiecesGroups) do
        if list then
            for i=1,#list do
                if list[i] then
                Explode(list[i], SFX.EXPLODE + SFX.SMOKE + SFX.FIRE)
                end
            end
        end
    end

    createTankCorpse(unitID, recentDamage, lastTurretRotation + 180)
    return 1
end

boolMoving= false
function emitDustRotateWheels()
    while true do
    Sleep(100)
        while (boolMoving == true) do
            de = math.ceil(math.random(240, 360))
            Sleep(de)
            EmitSfx(DustEmit, 1024)
        end
    end

end
--- -aimining & fire weapon
function script.AimFromWeapon1() return aimpiece end

function script.QueryWeapon1() return Cannon1 end

boolNoLongerAiming = true

function noLongerAiming()
    Signal(SIG_RESETAIM)
    SetSignalMask(SIG_RESETAIM)
    boolNoLongerAiming = false
    Sleep(5000)
    boolNoLongerAiming = true
    StartThread(PlaySoundByUnitDefID, myDefID, "sounds/tank/rotate.ogg", 0.8,
                1000, 1)
    WTurn(aimpiece, 2, 0, 0.5)
    WTurn(Cannon1, 1, 0, 0.5)
    lastTurretRotation = 0
end

function script.AimWeapon1(Heading, pitch)
    -- aiming animation: instantly turn the gun towards the enemy
    StartThread(PlaySoundByUnitDefID, myDefID, "sounds/tank/rotate.ogg", 1.0,
                1000, 1)
    StartThread(noLongerAiming)
    WTurn(aimpiece, 2, Heading, 0.7)
    lastTurretRotation = math.deg(Heading)
    WTurn(Cannon1, 1, -pitch, 0.7)
    return true
end


function script.FireWeapon1()
    tP(FireEmit,5*45,0,10,0)
    Explode(Shell, SFX.FALL)
    EmitSfx(FireEmit, 1026)
    EmitSfx(FireEmit, 1025)
    EmitSfx(FireEmit, 1024)
 return true 
end

function script.StartMoving()
    StartThread(PlaySoundByUnitDefID, myDefID, "sounds/tank/drive_4_30.ogg",
                1.0, 30000, 1)
    boolMoving = true
end

function script.StopMoving() boolMoving=false end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

