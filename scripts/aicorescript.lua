include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}
GameConfig = getGameConfig()

IntegrationRadius = GameConfig.integrationRadius
TIME_MAX = GameConfig.maxNumberIntegratedIntoHive * 1000
bodyMax = 128
innerLimit = 96
Icon = piece "Icon"
Eye = piece "Eye"

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
membersIntegrated= 0

function integrateNewMembers()
    waitTillComplete(unitID)
    x, y, z = Spring.GetUnitPosition(unitID)
    local integrateAbleUnits = getCultureUnitModelTypes(  GG.GameConfig.instance.culture, "truck", UnitDefs)
    px, py, pz = Spring.GetUnitPosition(unitID)
    members = {}
    while true do
        if  membersIntegrated < GameConfig.maxNumberIntegratedIntoHive  then
        foreach(getAllInCircle(x, z, IntegrationRadius), 
            function(id)
                team = Spring.GetUnitTeam(id)
                if team == myTeamID then
                    return nil
                end
                if GG.DisguiseCivilianFor[id] then
                  return GG.DisguiseCivilianFor[id]
                end
                return id
            end, 
            function(id)
                if integrateAbleUnits[Spring.GetUnitDefID(id)] and not isTransport(id) then           
                    Spring.SetUnitPosition(id, px, py, pz)
                    Spring.DestroyUnit(id, false, true)
                    membersIntegrated = membersIntegrated  + 1
                end
            end
            )
        end
        Sleep(100)
    end
end

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)

    instanciate()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["body"])
    StartThread(wiggleEye)
    StartThread(showState)
    StartThread(integrateNewMembers)
end

function wiggleEye()

    while true do
        napTime = math.random(200, 2500)
        Sleep(napTime)

        EyeSpeed = math.random(20, 100) / 50
        reset(Eye, EyeSpeed)
        Sleep(500)
        turnPieceRandDir(Eye, EyeSpeed)
    end
end

function script.Killed(recentDamage, _) return 1 end

heigthPagode = 369
maxTurn = 6 * 90
function showState()

    instanciate()
    while true do
        level = math.ceil(GG.HiveMind[teamID][unitID].rewindMilliSeconds /
                              TIME_MAX) * (#TablesOfPiecesGroups["body"] or 1)
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
        Show(Eye)
    else
        showAll(unitID)
        if TablesOfPiecesGroups then hideT(TablesOfPiecesGroups["body"]) end
        Hide(Icon)
        Hide(Eye)
    end

end

