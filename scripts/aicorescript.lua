include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
local GameConfig = getGameConfig()

local IntegrationRadius = GameConfig.integrationRadius
local CHARGE_PER_MEMBER_MS = GameConfig.addSlowMoTimeInMsPerCitizen or 150
local TIME_MAX = GameConfig.maxNumberIntegratedIntoHive * CHARGE_PER_MEMBER_MS
local Icon = piece "Icon"
local Eye = piece "Eye"

local teamID = Spring.GetUnitTeam(unitID)

local function instantiate()
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
    return GG.HiveMind[teamID][unitID]
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
        GG.GameConfig.instance.culture, "truck", UnitDefs
    )

    while true do
        local state = instantiate()
        if state.rewindMilliSeconds < TIME_MAX then
            foreach(
                getAllInCircle(x, z, IntegrationRadius),
                function(id)
                    local team = Spring.GetUnitTeam(id)
                    if team == teamID then
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

    StartThread(wiggleEye)
    StartThread(showState)
    StartThread(integrateNewMembers)
end

function wiggleEye()
    while true do
        local napTime = math.random(200, 2500)
        Sleep(napTime)

        local eyeSpeed = math.random(20, 100) / 50
        reset(Eye, eyeSpeed)
        Sleep(500)
        turnPieceRandDir(Eye, eyeSpeed)
    end
end

function script.Killed(recentDamage, _)
    if GG.HiveMind and GG.HiveMind[teamID] then
        GG.HiveMind[teamID][unitID] = nil
    end
    return 1
end

function showState()
    local bodies = TablesOfPiecesGroups["body"] or {}
    local bodyCount = #bodies
    local oldLevel = -1

    while true do
        local state = instantiate()
        local charge = state.rewindMilliSeconds or 0
        local level = 0

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
            "Temporal reserve: " ..
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
        Show(Eye)
    else
        showAll(unitID)
        if TablesOfPiecesGroups then
            hideT(TablesOfPiecesGroups["body"])
        end
        Hide(Icon)
        Hide(Eye)
    end
end
