include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
center = piece("center")

TablesOfPiecesGroups = {}

myTeamID = Spring.GetUnitTeam(unitID)
local ecmIconTypes = getECMIconTypes(UnitDefs)
local ecmIconSfxTypes = getECMSpecialSFXIconTypes(UnitDefs)
local stunnableUnitTypes = getStunnedInBlackOutUnitTypes(UnitDefs)
function script.HitByWeapon(x, z, weaponDefID, damage) end
GameConfig= getGameConfig()
speedfactor = 2.0

local function isTruthyCustomParam(value)
    return value == true or value == 1 or value == "1" or value == "true"
end

local function isECMHackableUnit(defID)
    local unitDef = defID and UnitDefs[defID]
    return unitDef and unitDef.customParams and isTruthyCustomParam(unitDef.customParams.ecmhackable)
end

local function hackUnit(id)
    local targetTeamID = Spring.GetUnitTeam(id)
    if not targetTeamID or targetTeamID == myTeamID then
        return false
    end

    Spring.TransferUnit(id, myTeamID)
    Spring.SetUnitNeutral(id, false)
    spawnCegAtUnit(id, "orangematrix", 0, 0, 0)
    return true
end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Data"])
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    StartThread(hoverAboveGrounds, GameConfig.iconHoverGroundOffset)
    StartThread(eatECMcon)
end

function eatECMcon()
    boolFoundSomething = false
    while true do
        foreach(getAllNearUnit(unitID, 100),
            function (id)
                defID = Spring.GetUnitDefID(id)
				--stun all blackout stunable Units in Range
				if stunnableUnitTypes[defID] then
					stunUnit(unitID, 0.5)
				end

                -- Physical surveillance devices may opt into ECM capture via
                -- customParams.ecmhackable. Ownership persists until another
                -- ECM unit captures the device again.
                if isECMHackableUnit(defID) then
                    hackUnit(id)
                    return
                end

                if ecmIconTypes[defID] then
                    if Spring.GetUnitTeam(id) ~= myTeamID then
                        name = UnitDefs[defID].name 
                        if name == "icon_emc" then
                            Spring.DestroyUnit(id, false, true)
                            Spring.DestroyUnit(unitID, false, true)
                            return
                        end

                        if name == "icon_bribe" then
                            Spring.DestroyUnit(id, false, true)
                            GG.Bank:TransferToTeam( 350, myTeam, unitID)
                            return
                        end
                      Spring.DestroyUnit(id, false, true)
                    end
                end
            end
            )
        Sleep(500)
    end
end

function script.Killed(recentDamage, _)
    Explode(center,  SFX.SHATTER)

    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

function moveParticle(pieceID, distances, speed)
    reset(pieceID)
    Show(pieceID)
    WMove(pieceID, y_axis, -distances, speed)
    Hide(pieceID)
end

SIG_PARTICLE = 1
SIG_SFX =2
function showParticles()
    Signal(SIG_PARTICLE)
    SetSignalMask(SIG_PARTICLE)
    while true do
        if maRa() then
            step=math.random(2,10)
            for i=1, #TablesOfPiecesGroups["Data"], step do
            distance = math.random(2500,6000)
            StartThread(moveParticle,TablesOfPiecesGroups["Data"][i], distance, 7500*speedfactor)
            end
            Sleep(100)
        else
            dice = math.random(1, #TablesOfPiecesGroups["Data"])
            distance = math.random(2500,6000)
            StartThread(moveParticle,TablesOfPiecesGroups["Data"][dice], distance, 7500*speedfactor)
            Sleep(30)
        end
        if randChance(5) then
            spawnCegAtUnit(unitID, "orangematrix", math.random(-10,10), math.random(-10,10), math.random(-10,10))
        end
    end
end

-- Tune the deliberate aiming phase separately from the charge.
local ECM_TURN_RATE = math.rad(20) -- radians per simulation second
local ECM_CHARGE_SPEED = 1800      -- elmos per simulation second
local ECM_ARRIVAL_RADIUS = 10

local function wrapAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

function hoverAboveGrounds(distanceToHover)
    local dt = 1 / Game.gameSpeed
    local turnStep = ECM_TURN_RATE * dt
    local chargeStep = ECM_CHARGE_SPEED * dt
    local _, yaw = Spring.GetUnitRotation(unitID)
    yaw = yaw or 0
    local charging = false
    Spring.MoveCtrl.Enable(unitID)
    Spring.MoveCtrl.SetVelocity(unitID, 0, 0, 0)

    while true do
        local x, _, z = Spring.GetUnitPosition(unitID)
        local commands = Spring.GetUnitCommands(unitID, 1)
        local command = commands and commands[1]
        local moving = false
        if command then
            local gx, _, gz = GetCommandPos(command)
            if gx and gz and gx ~= -10 and gz ~= -10 then
                local dx, dz = gx - x, gz - z
                local distance = math.sqrt(dx * dx + dz * dz)
                if distance > ECM_ARRIVAL_RADIUS then
                    -- MoveCtrl Euler yaw uses the opposite sign to heading.
                    local targetYaw = math.atan2(-dx, dz)
                    local delta = wrapAngle(targetYaw - yaw)
                    if math.abs(delta) > turnStep then
                        -- Re-aim in place, including after a mid-charge redirect.
                        yaw = wrapAngle(yaw + (delta > 0 and turnStep or -turnStep))
                    else
                        yaw = targetYaw
                        local travel = math.min(chargeStep, distance)
                        x, z = x + dx / distance * travel, z + dz / distance * travel
                        moving = true
                    end
                elseif command.id == CMD.MOVE and command.tag then
                    -- MoveCtrl bypasses normal move completion. Remove only the
                    -- reached order, preserving queued moves and unit targets.
                    Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {command.tag}, {})
                end
            end
        end

        if moving ~= charging then
            charging = moving
            if charging then
                StartThread(showParticles)
            else
                Signal(SIG_PARTICLE)
                hideT(TablesOfPiecesGroups["Data"])
            end
        end

        Spring.MoveCtrl.SetRotation(unitID, 0, yaw, 0)
        local ground = Spring.GetGroundHeight(x, z)
        Spring.MoveCtrl.SetPosition(unitID, x, math.max(0, ground) + distanceToHover, z)
        Sleep(30) -- one simulation frame at the engine's 30 Hz base rate
    end
end

function script.StartMoving() 
end

function script.StopMoving() 
end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch) return false end

function script.FireWeapon1() return false end
