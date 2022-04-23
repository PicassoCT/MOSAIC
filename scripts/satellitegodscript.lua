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
myDefID = Spring.GetUnitDefID(unitID)
function script.Create()
    --Spring.Echo("Satellite godrod created")

    --Spin(center,y_axis,math.rad(5),0.5)
    if Icon then
        Move(Icon, y_axis, GameConfig.Satellite.iconDistance, 0);
        Hide(Icon)
    end
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(delayedShow)
    StartThread(manuallyTargetingGodRod)
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
    if params[1] and params[2] and params[3] then return params[1], params[2],params[3] end

    if doesUnitExistAlive(params[1]) then 
        x,y,z = Spring.GetUnitPosition(params[1])
        return x,y,z
    end

    x,y,z = Spring.GetUnitPosition(unitID)
    return x,y,z
end

function unitHasAttackCommand()
    commands = Spring.GetUnitCommands(unitID, 1)
        if commands and commands[1] then
            command = commands[1]
            if command and 
                command.id == CMD.ATTACK or 
                command.id == CMD.AREA_ATTACK or 
                command.id == CMD.FIGHT then
                ax,ay, az = getPositionFromParams(command.params)
                return ax,ay,az 
            end
        end
end

function manuallyTargetingGodRod()
    while true do
        x,y,z = spGetUnitPosition(unitID)
     
        ax,ay,az = unitHasAttackCommand()
        if ax then
            if distance(x,0 ,z, ax, 0, az) < GameConfig.Satellite.GodRodDropDistance then
            StartThread(dropGodRodAt, unitID,x,y,z)
            Hide(TablesOfPiecesGroups["GodRod"][NumberOfRods])
            NumberOfRods = NumberOfRods - 1
            Sleep(GameConfig.Satellite.GodRodReloadTimeInMs) 

                if NumberOfRods <= 0 then
                    GG.DiedPeacefully[unitID] = true
                    Spring.DestroyUnit(unitID, true, false)
                end

            end
        end
        Sleep(100)
    end
end

 local impactorWeaponDefID = WeaponDefNames["godrod"].id

function dropGodRodAt(unitID, x,y,z)
    tx,ty,tz = x,Spring.GetGroundHeight(x,z),z

            local ImpactorParameter = {
                                pos = { x,y,z},
                               ["end"] = { tx, ty, tz },
                                speed = { 0, -1, 0},
                                owner = unitID,
                                team = myTeamID,
                                spread = { math.random(-5, 5), math.random(-5, 5), math.random(-5, 5) },
                                ttl = GameConfig.Satellite.GodRodTimeToImpactInMs,
                                error = { 0, 0, 0 },
                                maxRange = 3000,
                                gravity = Game.gravity,
                                startAlpha = 0.5,
                                endAlpha = 1,
                                model = "GodRod.s3o",
                                cegTag = "impactor"
                            }

       projectileID =  Spring.SpawnProjectile(impactorWeaponDefID,ImpactorParameter)
       if projectileID then       
           StartThread(PlaySoundByUnitDefID,myDefID, "sounds/weapons/godrod/impactor.wav", 1.0, GameConfig.Satellite.GodRodTimeToImpactInMs, 5)
        end
   end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

boolParked= false
boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then
        hideAll(unitID)
        Show(Icon)
        boolParked = true
    else
        showAll(unitID)
        Hide(Icon)
        Hide(Packed)
        Hide(GodRod)
        Hide(AimPiece)
        boolParked = false
    end
end
