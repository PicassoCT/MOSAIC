    include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

GameConfig = getGameConfig()
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)
gaiaTeamID = Spring.GetGaiaTeamID()

local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)

function script.Create()
    Spring.MoveCtrl.Enable(unitID, true)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(recruiteLoop)
    x, y, z = Spring.GetUnitPosition(unitID)

    Spring.MoveCtrl.SetPosition(unitID, x, y + GameConfig.iconGroundOffset, z)

    StartThread(animationLoop, 2)
end

boolKillParent = false
overWriteIDOnCreation = nil
boolSetVelocity = true
myTeam = Spring.GetUnitTeam(unitID)

operativeTypeTable = getOperativeTypeTable(UnitDefs)
civilianAgentDefID = UnitDefNames["civilianagent"].id

TruckTypeTable = getTruckTypeTable(UnitDefs)
--assert(type(TruckTypeTable)=="table")
--assert(#TruckTypeTable >0)


function isDisguisedRecruitableCivilian(id)
    return (GG.DisguiseCivilianFor[id] and GG.DisguiseCivilianFor[id] ~=
               fatherID)
end

function isNormalCivilian(id, defID)
    return civilianWalkingTypeTable[defID] and not GG.DisguiseCivilianFor[id]
end

function recruiteLoop()
    local recruitmentRange = GameConfig.agentConfig.recruitmentRange
    local spGetUnitTeam = Spring.GetUnitTeam
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitPosition = Spring.GetUnitPosition
    local spDestroyUnit = Spring.DestroyUnit
    waitTillComplete(unitID)
    StartThread(lifeTime, unitID, 15000, true, false)

    while true do
        Sleep(100)
        foreach(getAllNearUnit(unitID, recruitmentRange), 
        function(id)

            if spGetUnitTeam(id) == gaiaTeamID then return id end
        end, 
        function(id)
            if isDisguisedRecruitableCivilian(id) == true then
                if spGetUnitTeam(GG.DisguiseCivilianFor[id]) ~= myTeam then
                    return GG.DisguiseCivilianFor[id] -- make unit transparent
                else
                    return -- swallow disguised civilians of our own operatives
                end
            end
            return id -- push all others through unaltered
        end, 
        function(id)
            recruitedDefID = spGetUnitDefID(id)
            x, y, z = spGetUnitPosition(id)

            if isNormalCivilian(id, recruitedDefID) == true then
                --echo("Recruited normal civilian")
                recruitCivilianAgent(id, x, y, z, myTeam, fatherID)
                spDestroyUnit(id, false, true)
                endIcon()
            end

            if recruitedDefID == civilianAgentDefID then
                --echo("Recruited civilian agent")
                oldTeam = Spring.GetUnitTeam(id)
                ad = copyUnit(id, teamID)
                attachDoubleAgentToUnit(ad, oldTeam)
                spDestroyUnit(id, false, true)
                endIcon()
            end

            if operativeTypeTable[recruitedDefID] then
                --echo("Recruited operative")
                ad = recruitCivilianAgent(id, x, y, z, myTeam, fatherID)
                attachDoubleAgentToUnit(ad, Spring.GetUnitTeam(id))
                beamOperativeToNearestHouse(id)
                endIcon()
            end

        end)
    end
end

function endIcon()
    Spring.DestroyUnit(unitID, false, true)
    while true do Sleep(1000) end
end

function recruitCivilianAgent(id, x, y, z, myTeam, fatherID)
    ad = Spring.CreateUnit("civilianagent", x, y, z, 1, myTeam, false, false,
                           nil, fatherID)
    transferUnitStatusToUnit(id, ad)
    transferOrders(id, ad)
    return ad
end

function beamOperativeToNearestHouse(id)
    x, y, z = Spring.GetUnitPosition(id)
    maxdist = math.huge
    local jumpID

    T = Spring.GetTeamUnits(gaiaTeamID)
    for i = 1, #T do
        id = T[i]
        if houseTypeTable[Spring.GetUnitDefID(id)] then
            tx, ty, tz = Spring.GetUnitPosition(id)
            dist = distance(x, y, z, tx, ty, tz)
            if dist < maxdist then
                maxdist = dist
                jumpID = id
            end
        end
    end

    if jumpID then
        moveUnitToUnit(id, jumpID, 15 * randSign(), 0, 15 * randSign())
    end
end

function script.Killed(recentDamage, _) return 0 end

function animationLoop(speedfactor)
    civhat = piece "civhat"
    civloop = piece "civloop"
    GoodCiv = piece "GoodCiv"
    BadCiv = piece "BadCiv"
    agentloop = piece "agentloop"
    civbodyup = piece "civbodyup"
    civbodydown = piece "civbodydown"
    agent1 = TablesOfPiecesGroups["Agent"][1]
    agent2 = TablesOfPiecesGroups["Agent"][2]

    while true do
        resetAll(unitID)
        hideAll(unitID)
        Show(civloop)

        Show(TablesOfPiecesGroups["CivBox"][1])
        Show(civbodyup)
        Show(civbodydown)
        Show(agent1)
        Move(civbodydown, x_axis, -900, 450 * speedfactor)
        Move(agent1, x_axis, 900, 450 * speedfactor)
        WaitForMoves(civbodydown, agent1)
        Sleep(500)
        Turn(civbodydown, y_axis, math.rad(-45), 15 * speedfactor)
        Turn(agent1, y_axis, math.rad(-45), 10 * speedfactor)
        WaitForTurns(civbodydown, agent1)
        Sleep(100)
        Hide(TablesOfPiecesGroups["CivBox"][1])
        Show(TablesOfPiecesGroups["AgentBox"][1])
        Show(TablesOfPiecesGroups["AgentBox"][2])
        Show(agent2)
        WTurn(agent1, y_axis, math.rad(-180), 25 * speedfactor)
        Turn(civbodydown, y_axis, math.rad(90), 5 * speedfactor)
        Move(agent2, 3, 900, 450 * speedfactor)
        Move(agent1, x_axis, 0, 450 * speedfactor)
        Show(GoodCiv)
        Move(GoodCiv, y_axis, 512, 750 * speedfactor)
        Move(BadCiv, y_axis, 512, 750 * speedfactor)
        WMove(civbodyup, y_axis, 1024, 750 * speedfactor)
        Hide(GoodCiv)
        Show(BadCiv)
        Sleep(250)
        Move(civbodyup, y_axis, 0, 750 * speedfactor)
        Move(GoodCiv, y_axis, 0, 750 * speedfactor)
        WMove(BadCiv, y_axis, 0, 750 * speedfactor)
        WMove(agent2, 3, 900, 450 * speedfactor)
        Hide(agent1)
        Hide(TablesOfPiecesGroups["AgentBox"][1])
        Hide(TablesOfPiecesGroups["AgentBox"][2])
        Show(TablesOfPiecesGroups["CivBox"][2])
        Show(agentloop)
        Hide(civloop)
        -- point of handover	
        Turn(civbodydown, y_axis, math.rad(180), 5 * speedfactor)
        -- matroshka	
        WTurn(agent2, y_axis, math.rad(90), 5 * speedfactor)
        Show(civhat)
        Turn(civbodydown, y_axis, math.rad(180), 15 * speedfactor)
        Turn(agent2, y_axis, math.rad(180), 5 * speedfactor)
        Move(civbodydown, x_axis, 0, 450 * speedfactor)
        WMove(agent2, y_axis, 0, 450 * speedfactor)

    end

end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})

