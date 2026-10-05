include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
local spGetUnitPosition = Spring.GetUnitPosition
TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end

GameConfig = getGameConfig()
center = piece "center"
Icon = piece "Icon"
Packed = piece "Packed"
GodRod = piece "GodRod"
AimPiece = piece "AimPiece"
NumberOfRods = 3
myTeamID = Spring.GetUnitTeam(unitID)

function script.Create()
    --Spring.Echo("Satellite godrod created")

    --Spin(center,y_axis,math.rad(5),0.5)
    if Icon then
        Move(Icon, y_axis, GameConfig.presentation.icons.satelliteHeight, 0);
        Hide(Icon)
    end
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(delayedShow)
    StartThread(manuallyTargetingGodRod)
    StartThread(threeBeepLoop)
    Hide(GodRod)

end

function delayedShow()
    hideAll(unitID)
    Show(Packed)
    waitTillComplete(unitID)
    Explode(Packed, SFX.SHATTER)
    showAll(unitID)
    Hide(Packed)
    Hide(GodRod)
    Hide(AimPiece)
    Hide(Icon)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.AimFromWeapon1() return AimPiece end

function script.QueryWeapon1() return AimPiece end

function script.AimWeapon1(Heading, pitch)
    return  true
end

function script.FireWeapon1()
    if NumberOfRods == 0 then
        Explode(center, SFX.SHATTER + SFX.FALL + SFX.FIRE)
        Spring.DestroyUnit(unitID, true, false)
    end
end

function getPositionFromParams(params)
    if not params then return nil end
    if params[1] and params[2] and params[3] then
        return params[1], params[2], params[3]
    end

    if params[1] and doesUnitExistAlive(params[1]) then
        return Spring.GetUnitPosition(params[1])
    end
    return nil
end

function unitHasAttackCommand()
    local commands = Spring.GetUnitCommands(unitID, 1)
    local command = commands and commands[1]
    if not command then return nil end

    if command.id == CMD.ATTACK or
        command.id == CMD.AREA_ATTACK or
        command.id == CMD.FIGHT then
        return getPositionFromParams(command.params)
    end
    return nil
end

local lastTargetKey = nil

local function targetKey(x, z)
    if not x then return nil end
    return math.floor(x + 0.5) .. ":" .. math.floor(z + 0.5)
end

function manuallyTargetingGodRod()
    while true do
        local ax, ay, az = unitHasAttackCommand()
        if ax and NumberOfRods > 0 then
            local key = targetKey(ax, az)

            if key ~= lastTargetKey and
                GG.Orbital and GG.Orbital.RequestGodRodStrike then
                if GG.Orbital.RequestGodRodStrike(unitID, ax, az) then
                    lastTargetKey = key
                end
            end

            if lastTargetKey and
                GG.Orbital and GG.Orbital.CanGodRodFire then
                local canFire, tx, ty, tz =
                    GG.Orbital.CanGodRodFire(unitID)

                if canFire then
                    StartThread(dropGodRodAt, unitID, tx, ty, tz)

                    if TablesOfPiecesGroups["GodRod"] and
                        TablesOfPiecesGroups["GodRod"][NumberOfRods] then
                        Hide(TablesOfPiecesGroups["GodRod"][NumberOfRods])
                    end

                    NumberOfRods = NumberOfRods - 1
                    if GG.Orbital.ConsumeGodRodPositioning then
                        GG.Orbital.ConsumeGodRodPositioning(unitID)
                    end

                    -- The same attack order may remain queued, but every rod
                    -- must request and complete another positioning downtime.
                    lastTargetKey = nil

                    if NumberOfRods <= 0 then
                        GG.DiedPeacefully[unitID] = true
                        Spring.DestroyUnit(unitID, true, false)
                        return
                    end

                    Sleep(GameConfig.military.satellites.godRod.reloadTimeMs)
                end
            end
        else
            lastTargetKey = nil
        end

        Sleep(100)
    end
end

local impactorWeaponDefID = WeaponDefNames["godrod"].id

function dropGodRodAt(unitID, tx, ty, tz)
    local x, y, z = spGetUnitPosition(unitID)
    if not x or not tx then return end

    ty = ty or Spring.GetGroundHeight(tx, tz)
    local ImpactorParameter = {
        pos = {x, y + 100, z},
        ["end"] = {tx, ty, tz},
        speed = {0, -1, 0},
        owner = unitID,
        team = myTeamID,
        spread = {
            math.random(-5, 5),
            math.random(-5, 5),
            math.random(-5, 5)
        },
        ttl = GameConfig.military.satellites.godRod.timeToImpactMs,
        error = {0, 0, 0},
        maxRange = 3000,
        gravity = Game.gravity,
        startAlpha = 0.5,
        endAlpha = 1,
        model = "GodRod.s3o",
        cegTag = "impactor"
    }

    local projectileID =
        Spring.SpawnProjectile(impactorWeaponDefID, ImpactorParameter)

    if projectileID then
        Sleep(3000)
        StartThread(
            PlaySoundByUnitDefID,
            unitDefID,
            "sounds/weapons/godrod/impactor.wav",
            1.0,
            GameConfig.military.satellites.godRod.timeToImpactMs,
            5
        )
    end
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

boolParked= false
boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then
        hideAll(unitID)
        Hide(Icon)

        boolParked = true
        boolBeep = true
    else
        showAll(unitID)
        Hide(Icon)
        Hide(Packed)
        Hide(GodRod)
        Hide(AimPiece)
        boolParked = false
        boolBeep = true
    end
end
