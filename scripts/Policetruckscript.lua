include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"
include "lib_debug.lua"
local TablesOfPiecesGroups = {}

local center = piece "center"
local attachPoint = piece "attachPoint"
local TruckTypeTable = getTruckTypeTable(UnitDefs)
local boolIsCivilianTruck = (TruckTypeTable[unitDefID] == nil)
local GameConfig = getGameConfig()
local boolIsCivilianUnit = Spring.GetUnitTeam(unitID) == Spring.GetGaiaTeamID()

SIG_LOUDNESOVERRIDE = 2

function showAndTell()
    showAll(unitID)
    if TablesOfPiecesGroups["LightEmit"] then
        hideT(TablesOfPiecesGroups["LightEmit"])
    end

    if TablesOfPiecesGroups["Body"] then
        hideT(TablesOfPiecesGroups["Body"])
        Show(TablesOfPiecesGroups["Body"][2])
    end
end

policeOfficerID = nil

function spawnRiotPolice()
    if not doesUnitExistAlive(policeOfficerID) then
        policeOfficerID = createUnitAtUnit(gaiaTeamID, "riotpolice", unitID, math.random(-10,10),0 , math.random(-10,10))
         while doesUnitExistAlive(policeOfficerID) do
            if not (GG.PoliceBribes and GG.PoliceBribes[policeOfficerID]) and
                not (GG.PoliceInPursuit and GG.PoliceInPursuit[policeOfficerID]) then
                T = foreach(getAllNearUnit(policeOfficerID, 120),
                        function(id)
                            defID = Spring.GetUnitDefID(id)
                            if civilianWalkingTypeTable[defID] and gaiaTeamID == Spring.GetUnitTeam(id) then
                                return id
                            end
                            end
                            )
                if #T > 0 then
                    Command(policeOfficerID, "attack", getSafeRandom(T, unitID))
                else
                    Command(policeOfficerID, "guard", unitID)
                end
            end
            Sleep(10000)  
         end
    end
end


function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNeutral(unitID, false)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
    showAndTell()
    StartThread(delayedSirens)
    StartThread(theySeeMeRollin)
    StartThread(tearGasState)
end

function theySeeMeRollin()
    -- Active incident movement belongs to game_police; do not overwrite its orders.
    while true do
        if not (GG.PoliceInPursuit and GG.PoliceInPursuit[unitID]) and
            not (GG.PoliceBribes and GG.PoliceBribes[unitID]) then
            local x,y,z = Spring.GetUnitPosition(unitID)
            local angle = math.random()*2*math.pi
            local tx = math.max(1,math.min(Game.mapSizeX-1,x+math.cos(angle)*400))
            local tz = math.max(1,math.min(Game.mapSizeZ-1,z+math.sin(angle)*400))
            Command(unitID,"go",{x=tx,y=Spring.GetGroundHeight(tx,tz),z=tz},{})
        end
        Sleep(8000)
    end
end

function isInActionInterval(frame)
    if not GG.PoliceActionSoundInterVallStartFrame then return true end

    if frame < GG.PoliceActionSoundInterVallStartFrame + GameConfig.actionIntervallFrames then return true end

    return false
end

function delayedSirens()
    setFireState(unitID, 2)
    setMoveState(unitID, 2)
    sleeptime = math.random(1, 10)
    Sleep(sleeptime * 1000)
    for i = 1, 3 do
        StartThread(PieceLight, unitID, TablesOfPiecesGroups["LightEmit"][i],
                    "policelight", 1000)
        Sleep(350)
    end
    seconds = 35
    framesPerSecond = 30
    startFrame = Spring.GetGameFrame()
    while true do
        sirenDice = math.random(1, GameConfig.maxSirenSoundFiles)
        loudness = math.max(0, math.sin(
                                ((((Spring.GetGameFrame() - startFrame) /
                                    framesPerSecond) % seconds) / seconds) * 2 *
                                    math.pi))
        if boolLoudnessOverrideActive == true then loudness = 1.0 end
        if isInActionInterval(Spring.GetGameFrame()) == true then
            StartThread(PlaySoundByUnitDefID, unitDefID,
                        "sounds/civilian/police/siren" .. sirenDice .. ".ogg", 0.9,
                        50, 2)
        end
        Sleep(50 * 1000)
    end
end

boolLoudnessOverrideActive = false
function loudnessOverride()
    Signal(SIG_LOUDNESOVERRIDE)
    SetSignalMask(SIG_LOUDNESOVERRIDE)
    boolLoudnessOverrideActive = true
    Sleep(30000)

    boolLoudnessOverrideActive = false
end
boolHasBeenHitBy= false
function script.HitByWeapon(x, z, weaponDefID, damage)
    StartThread(loudnessOverride)
    boolHasBeenHitBy = true
    return damage
end

function tearGasState()
    while true do
        if boolHasBeenHitBy == true and GG.GlobalGameState ~= GameConfig.GameState.normal then
            boolHasBeenHitBy = false
            StartThread(spawnRiotPolice)
        end
        Sleep(1000)
    end
end

function script.Killed(recentDamage, _)
    if doesUnitExistAlive(loadOutUnitID) then
        Spring.DestroyUnit(loadOutUnitID, true, true)
    end
    createCorpseCUnitGeneric(recentDamage)
    return 1
end

function script.StartMoving()
    spinT(TablesOfPiecesGroups["wheel"], x_axis, -160, 0.3)
end

function script.StopMoving() stopSpinT(TablesOfPiecesGroups["wheel"], x_axis, 3) end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

--- -aimining & fire weapon
function script.AimFromWeapon1() return center end

function script.QueryWeapon1() return center end

function script.AimWeapon1(Heading, pitch) return true end

function script.FireWeapon1() return true end

function script.AimFromWeapon2() return center end

function script.QueryWeapon2() return center end

function script.AimWeapon2(Heading, pitch) return true end

function script.FireWeapon2() return true end
