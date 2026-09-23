include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end
chemTrails = getChemTrailTypes()
aerosoltype = chemTrails.wanderlost

SIG_AEROSOL_DEPLOY = 1
emitor = piece "emitor"
center = piece "center"
aimpiece = center
if not aimpiece then
    echo("Unit of type " .. UnitDefs[Spring.GetUnitDefID(unitID)].name ..
             " has no aimpiece")
end
if not center then
    echo("Unit of type" .. UnitDefs[Spring.GetUnitDefID(unitID)].name ..
             " has no center")
end
timeTank = 9999

typeTankMap = {
    ["depressol"] = 1,
    ["tollwutox"] = 2,
    ["orgyanyl"] = 3,
    ["wanderlost"] = 4
}
-- Keep the chemical identities of the original CEGs.
local aerosolColours = {
    depressol = {0.5, 0.5, 1},
    tollwutox = {1, 0.5, 0.5},
    orgyanyl = {1, 0.5, 0},
    wanderlost = {0.25, 1, 0.25},
}
local sprayRegistered = false
local sprayDead = false
local function setSprayVisible(enabled)
    local api = GG.SmokeRibbon
    if not api then return end
    if not enabled or sprayDead then
        if sprayRegistered then api.Remove(unitID, "aerosol") end
        sprayRegistered = false
        return
    end
    if sprayRegistered then return end
    local c = aerosolColours[AerosolUnitDefIDMap[unitDefID]]
    sprayRegistered = api.Set(unitID, "aerosol", emitor, {
        direction = {0, -1, 0}, directionSpace = "world",
        groundDirected = true,
        length = 128, width = 22, curl = 0.65, speed = 1.2,
        colorStart = {c[1], c[2], c[3], 0.32},
        colorEnd = {c[1], c[2], c[3], 0}, emission = {0, 0},
        windAffected = true, windInfluence = 0.4,
        motionAffected = true, motionInfluence = 0.35, trailTime = 0.8,
        strands = 3, distanceFactor = 40,
    })
end

AerosolUnitDefIDMap = getAerosolUnitDefIDs(UnitDefs)

function colCode(searchstr)
    for name, num in pairs(typeTankMap) do
        if string.match(searchstr, name) then return num end
    end

    return 1
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Tank"])
    Show(TablesOfPiecesGroups["Tank"][colCode(UnitDefs[unitDefID].name)])
    timeTank = GG.GameConfig.Aerosols[AerosolUnitDefIDMap[unitDefID]]
                   .sprayTimePerUnitInMs
    StartThread(aerosolDeployRibbons)
    Hide(emitor)
end

function script.Killed(recentDamage, _)
    sprayDead = true
    setSprayVisible(false)
    return 1
end

-- aimining & fire weapon
function script.AimFromWeapon1() return aimpiece end

function script.QueryWeapon1() return aimpiece end

function script.AimWeapon1(Heading, pitch) return true end

function script.FireWeapon1()
    Command(unitID, "setactive", 1)
    return true
end

function script.StartMoving()
    Turn(center, x_axis, math.rad(10), 0)
    spinT(TablesOfPiecesGroups["uprotor"], y_axis, 350, 9500)
    for i = 1, #TablesOfPiecesGroups["lowrotor"] do
        if TablesOfPiecesGroups["lowrotor"][i] then
            Spin(TablesOfPiecesGroups["lowrotor"][i], y_axis, math.rad(1900),
                 500)
        end
    end
end

function script.StopMoving()
    Turn(center, x_axis, math.rad(0), 0)
    stopSpinT(TablesOfPiecesGroups["uprotor"], y_axis, math.pi)
    for i = 1, #TablesOfPiecesGroups["lowrotor"] do
        if TablesOfPiecesGroups["lowrotor"][i] then
            StopSpin(TablesOfPiecesGroups["lowrotor"][i], y_axis, math.pi)
        end
    end
end

boolStopped = false
boolDeactivated = true

function aerosolDeployRibbons()
    Sleep(100)

    local lisUnitFlying = isUnitFlying

    while true do
        soundIntervall = 0
        while lisUnitFlying(unitID) == true and timeTank > 0 do
            if soundIntervall == 0  then
                StartThread(PlaySoundByUnitDefID, unitDefID, "sounds/plane/aerosol.wav", math.random(7,10)/10, 900, 3)
            end
            setSprayVisible(true)
            Sleep(100)
            timeTank = timeTank - 100
            sprayTank()
            soundIntervall = soundIntervall + 1 % 10

        end
        setSprayVisible(false)
        if timeTank <= 0 then
            Spring.SetUnitNoSelect(unitID, false, true)
            Spring.DestroyUnit(unitID, false, true)
        end
        Sleep(100)
    end
end

local GameConfig = getGameConfig()

aerosolAffectableUnits = getChemTrailInfluencedTypes(UnitDefs)
local alreadyChecked = {}
if not GG.AerosolAffectedCivilians then    GG.AerosolAffectedCivilians = {}    end
aerosolTypeOfUnit = AerosolUnitDefIDMap[unitDefID]
assert(aerosolTypeOfUnit)
assert(type(aerosolTypeOfUnit)=="string")

function sprayTank()
            foreach(getAllNearUnit(unitID, GameConfig.Aerosols.sprayRange), 
                        function(id)
                            if alreadyChecked[id] then return end

                            if aerosolAffectableUnits[Spring.GetUnitDefID(id)] and
                                    not GG.AerosolAffectedCivilians[id] then -- you can only get infected once
                                if setAerosolCivilianBehaviour(id,  aerosolTypeOfUnit) == true then
                                    --Spring.Echo("Unit " .. id .." is now under the influence of " ..aerosolTypeOfUnit)
                                    GG.AerosolAffectedCivilians[id] = aerosolTypeOfUnit
                                    alreadyChecked[id] = id
                                    return id
                                end
                            end
                            alreadyChecked[id] = id
                        end)

end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

