include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
local GameConfig = getGameConfig()

local IntegrationRadius = GameConfig.integrationRadius
local CHARGE_PER_MEMBER_MS = GameConfig.addSlowMoTimeInMsPerCitizen or 150
local TIME_MAX = GameConfig.maxNumberIntegratedIntoHive * CHARGE_PER_MEMBER_MS
local innerLimit = 96
local center = piece "center"
local Icon = piece "Icon"

local myTeamID = Spring.GetUnitTeam(unitID)
local level = 0

local function instantiate()
    if not GG.HiveMind then GG.HiveMind = {} end
    if not GG.HiveMind[myTeamID] then
        GG.HiveMind[myTeamID] = {teamActive = false}
    end
    if not GG.HiveMind[myTeamID][unitID] then
        GG.HiveMind[myTeamID][unitID] = {
            rewindMilliSeconds = 0,
            boolActive = false
        }
    end
    return GG.HiveMind[myTeamID][unitID]
end

local function addTemporalCharge()
    local state = instantiate()
    state.rewindMilliSeconds = math.min(
        TIME_MAX,
        state.rewindMilliSeconds + CHARGE_PER_MEMBER_MS
    )
end

function integrateNewMembers()
    waitTillComplete(unitID)

    local x, _, z = Spring.GetUnitPosition(unitID)
    local px, py, pz = Spring.GetUnitPosition(unitID)
    local integrateAbleUnits = getCultureUnitModelTypes(
        GG.GameConfig.instance.culture, "civilian", UnitDefs
    )

    while true do
        local state = instantiate()
        if state.rewindMilliSeconds < TIME_MAX then
            local aerosolUnits = GG.AerosolAffectedCivilians or {}

            foreach(
                getAllInCircle(x, z, IntegrationRadius),
                function(id)
                    local team = Spring.GetUnitTeam(id)
                    if team == myTeamID then
                        return nil
                    end
                    if GG.DisguiseCivilianFor[id] then
                        return GG.DisguiseCivilianFor[id]
                    end
                    return id
                end,
                function(id)
                    local currentState = instantiate()
                    if currentState.rewindMilliSeconds >= TIME_MAX then
                        return nil
                    end

                    local defID = Spring.GetUnitDefID(id)
                    if integrateAbleUnits[defID] and not isTransport(id) then
                        if aerosolUnits[id] then
                            return nil
                        end

                        Spring.SetUnitPosition(id, px, py, pz)
                        Spring.DestroyUnit(id, false, true)
                        addTemporalCharge()
                    end
                end
            )
        end
        Sleep(100)
    end
end

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)

    instantiate()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["body"])

    local intI = 0
    if TablesOfPiecesGroups["cable"] then
        foreach(TablesOfPiecesGroups["cable"], function(id)
            local randoVal = math.random(-10, 10) / 5
            local val = intI * ((360 / 8) + math.pi * randoVal)
            Turn(id, y_axis, math.rad(val), 0)
            intI = intI + 1
        end)
    end

    StartThread(showState)
    StartThread(integrateNewMembers)
end

function script.Killed(recentDamage, _)
    if GG.HiveMind and GG.HiveMind[myTeamID] then
        GG.HiveMind[myTeamID][unitID] = nil
    end
    return 1
end

local maxTurn = 6 * 90

function showState()
    local description = "Temporal reserve: "
    local bodies = TablesOfPiecesGroups["body"] or {}
    local bodyCount = #bodies

    for i = 1, math.min(innerLimit, bodyCount) do
        local degIndex = (i % 64) * (360 / 64)
        local randOffset = (math.random(-4, 4) / 2) * math.pi
        Turn(bodies[i], y_axis, math.rad(10 * degIndex + randOffset), 0)
    end

    for i = innerLimit + 1, bodyCount do
        local degIndex = ((i % 96) % 16) * (360 / 16)
        local randOffset = (math.random(-4, 4) / 8) * math.pi
        Turn(bodies[i], y_axis, math.rad(10 * degIndex + randOffset), 0)
    end

    hideT(bodies)

    local oldLevel = -1
    while true do
        local state = instantiate()
        local charge = state.rewindMilliSeconds or 0

        level = 0
        if bodyCount > 0 and TIME_MAX > 0 and charge > 0 then
            level = math.ceil((charge / TIME_MAX) * bodyCount)
        end

        if level ~= oldLevel then
            hideT(bodies)
            if level > 0 then
                showT(bodies, 1, level)
            end
            oldLevel = level
        end

        Spring.SetUnitTooltip(
            unitID,
            description ..
            string.format("%.1fs / %.1fs", charge / 1000, TIME_MAX / 1000)
        )

        Sleep(250)
    end
end

function setActive()
    local state = instantiate()
    if state.rewindMilliSeconds > 0 then
        state.boolActive = true
        return true
    end

    state.boolActive = false
    return false
end

function setPassiv()
    instantiate().boolActive = false
end

function script.Activate()
    setActive()
    return 1
end

function script.Deactivate()
    setPassiv()
    return 0
end

local boolLocalCloaked = false

function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then
        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        if TablesOfPiecesGroups then
            hideT(TablesOfPiecesGroups["body"])
        end
        Hide(Icon)
    end
end

function script.StartBuilding()
    SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
    SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.QueryBuildInfo()
    return center
end

Spring.SetUnitNanoPieces(unitID, {center})
