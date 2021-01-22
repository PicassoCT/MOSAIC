include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
GameConfig = getGameConfig()

IntegrationRadius = GameConfig.integrationRadius
TIME_MAX = GameConfig.maxTimeForSlowMotionRealTimeSeconds * 1000
bodyMax = 128
innerLimit = 96
center = piece "center"
Icon = piece "Icon"
y_rotationAxis = y_axis

teamID = Spring.GetUnitTeam(unitID)
function instanciate()
    if not GG.HiveMind then GG.HiveMind = {} end
    if not GG.HiveMind[teamID] then
        GG.HiveMind[teamID] = {teamActive = false}
    end
    if not GG.HiveMind[teamID][unitID] then
        GG.HiveMind[teamID][unitID] = {
            rewindMilliSeconds = 0,
            boolActive = false
        }
    end
end

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)
    instanciate()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["body"])
    StartThread(integrateNewMembers)

    intI = 0
    if TablesOfPiecesGroups["cable"] then
        process(TablesOfPiecesGroups["cable"], function(id)
            randoVal = math.random(-10, 10) / 5
            val = intI * ((360 / 8) + math.pi * randoVal)
            Turn(id, y_rotationAxis, math.rad(val), 0)
            intI = intI + 1
        end)
    end
    StartThread(showState)
end

function script.Killed(recentDamage, _) return 1 end

function integrateNewMembers()
    instanciate()
    waitTillComplete(unitID)
    x, y, z = Spring.GetUnitPosition(unitID)
    local integrateAbleUnits = getMobileCivilianDefIDTypeTable(UnitDefs)
    px, py, pz = Spring.GetUnitPosition(unitID)
    members = {}
    while true do
        process(getAllInCircle(x, z, IntegrationRadius), function(id)
            if GG.DisguiseCivilianFor[id] then
                return GG.DisguiseCivilianFor[id]
            end
            return id
        end, function(id)
            defID = Spring.GetUnitDefID(id)
            if integrateAbleUnits[defID] and
                GG.HiveMind[teamID][unitID].rewindMilliSeconds < TIME_MAX and
                members[id] == nil then
                GG.HiveMind[teamID][unitID].rewindMilliSeconds =
                    GG.HiveMind[teamID][unitID].rewindMilliSeconds +
                        GameConfig.addSlowMoTimeInMsPerCitizen
                members[id] = true
                Spring.SetUnitPosition(id, px, py, pz)
                Spring.DestroyUnit(id, false, true)
            end
        end)
        Sleep(100)
    end

end

heigthPagode = 369
maxTurn = 6 * 90
function showState()
    bodyCount = count(TablesOfPiecesGroups["body"])
    for i = 1, innerLimit, 1 do
        degIndex = (i % 64) * (360 / 64)
        randOffset = (math.random(-4, 4) / 2) * math.pi
        Turn(TablesOfPiecesGroups["body"][i], y_rotationAxis,
             math.rad(10 * degIndex + randOffset), 0)
    end

    for i = innerLimit, #TablesOfPiecesGroups["body"], 1 do
        degIndex = ((i % 96) % 16) * (360 / 16)
        randOffset = (math.random(-4, 4) / 8) * math.pi
        Turn(TablesOfPiecesGroups["body"][i], y_rotationAxis,
             math.rad(10 * degIndex + randOffset), 0)
    end

    instanciate()
    while true do

        level = (GG.HiveMind[teamID][unitID].rewindMilliSeconds / TIME_MAX) *
                    (bodyCount)

        hideT(TablesOfPiecesGroups["body"])
        if level > 1 then showT(TablesOfPiecesGroups["body"], 1, level) end
        Sleep(100)
    end
end

SIG_SLOWMO = 2
function slowMo()
    SetSignalMask(SIG_SLOWMO)
    GG.HiveMind[teamID][unitID].boolActive = true
    modulator = 0

    x, y, z = Spring.GetUnitPosition(unitID)
    team = Spring.GetUnitTeam(unitID)

    while GG.HiveMind[teamID][unitID].rewindMilliSeconds > 0 do
        Sleep(100)
        modulator = inc(modulator)
        if modulator % 3 == 0 then
            selectbody = TablesOfPiecesGroups["body"][math.random(1,
                                                                  #TablesOfPiecesGroups["body"])]
            Hide(selectbody)
        end
        GG.HiveMind[teamID][unitID].rewindMilliSeconds =
            math.max(0, GG.HiveMind[teamID][unitID].rewindMilliSeconds - 100)
    end

    GG.HiveMind[teamID][unitID].boolActive = false

end

function lookForOtherActiveHives()
    boolOneOtherActive = false
    other = nil
    for team, utab in pairs(GG.HiveMind) do
        for unit, utab in pairs(utab) do
            if utab.boolActive == true then
                boolOneOtherActive = true
                other = unit
            end
        end
    end
end

function setActive() StartThread(slowMo) end

function setPassiv() GG.HiveMind[teamID][unitID].boolActive = false end

function script.Activate()
    instanciate()
    if GG.HiveMind[teamID][unitID].rewindMilliSeconds > 0 then setActive() end
    return 1
end

function script.Deactivate()
    Signal(SIG_SLOWMO)
    GG.HiveMind[teamID][unitID].boolActive = false

    return 0
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        if TablesOfPiecesGroups then hideT(TablesOfPiecesGroups["body"]) end
        Hide(Icon)
    end

end

