include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
GameConfig = getGameConfig()
gaiaTeamID= Spring.GetGaiaTeamID()
boolLaunchReady = false
myTeamID = Spring.GetUnitTeam(unitID)
RocketAttach = piece "RocketAttach"
Crane = piece "Crane"
Craddle = piece "Craddle"
Elevator = piece "Elevator"
center = piece "Elevator"
Icon = piece "Icon"
upaxis = y_axis
teamID = Spring.GetUnitTeam(unitID)
stepIndex = 0
rocketHeigth = 3400
stepHeight = rocketHeigth / GameConfig.LaunchReadySteps
rocket= piece"Step1"
payLoadTypes= getPayloadTypes(UnitDefs)
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam

function moveRocketToPos(height,speed)
    Move(RocketAttach, upaxis, height, speed)
    Move(Elevator, upaxis, height, speed)
    Move(rocket, z_axis, height, speed)
end

function script.Create()
    Spring.SetUnitBlocking(unitID, false, false, false)
    if not GG.Launchers then GG.Launchers = {} end
    if not GG.Launchers[teamID] then GG.Launchers[teamID] = {} end
    GG.Launchers[teamID][unitID] = {steps=0}
    moveRocketToPos(-rocketHeigth, 0)
    Hide(RocketAttach)
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    hideT(TablesOfPiecesGroups["Step"])
    hideT(TablesOfPiecesGroups["WIP"])
    hideT(TablesOfPiecesGroups["Gantry"])
    StartThread(accountForBuiltLauncherSteps)
    StartThread(workCycle)
    Spin(Craddle, y_axis, math.rad(-1), 0.1)
    Spin(RocketAttach, y_axis, math.rad(-1), 0.1)
    Spin(rocket, y_axis, math.rad(-1), 0.1)
    Hide(Icon)
    StartThread(detectArrivingPayload)
end



function updateDescriptionDelayed()
    alreadyBuildStages = 0
    if GG.Launchers and GG.Launchers[myTeamID] and GG.Launchers[myTeamID][unitID] then
        alreadyBuildStages = GG.Launchers[myTeamID][unitID].steps
    end

    description = alreadyBuildStages.." stages completed out of "..(GameConfig.LaunchReadySteps+1).." stages. Build icmb-stages to win the game."
    Spring.SetUnitTooltip(unitID, description)
end

launcherStepDefID = UnitDefNames["launcherstep"].id
local buildID
function accountForBuiltLauncherSteps()
    while boolLaunchReady == false do
        -- Spring.Echo("Detect Upgrade")
        buildID = Spring.GetUnitIsBuilding(unitID)
        if buildID then
            updateDescriptionDelayed()
            if boolLaunchReady == false then
                buildDefID = Spring.GetUnitDefID(buildID)
                if buildDefID == launcherStepDefID then
                    stepIndex = stepIndex + 1
                    moveRocketToPos(-rocketHeigth + stepIndex * stepHeight, 100)
                   
                    Hide(TablesOfPiecesGroups["WIP"][stepIndex])
                    Show(TablesOfPiecesGroups["WIP"][math.min(
                             #TablesOfPiecesGroups["WIP"], stepIndex + 1)])
                    showT(TablesOfPiecesGroups["Gantry"], 0, math.min(
                              #TablesOfPiecesGroups["Gantry"], stepIndex * 2))
                    waitTillComplete(buildID)
                    if doesUnitExistAlive(buildID) == true then
                        showT(TablesOfPiecesGroups["Step"], 1, math.min(#TablesOfPiecesGroups["Step"],stepIndex + 1))
                        GG.Launchers[teamID][unitID].steps = GG.Launchers[teamID][unitID].steps + 1
                        --Spring.Echo("Launcherstep Complete")
                        Spring.DestroyUnit(buildID, false, true)
                    end
                end
            elseif boolLaunchReady == true then
                Spring.DestroyUnit(buildID, false, true)
            end
        end

        if stepIndex >= GameConfig.LaunchReadySteps and boolLaunchReady == false then
            prePareForLaunch()
            boolLaunchReady = true
        end
        Sleep(500)
    end
end

function payloadCheck(id)
    defID = spGetUnitDefID(id)   
    transporterID = Spring.GetUnitTransporter(id)  
    if payLoadTypes[defID] and transporterID and spGetUnitTeam(transporterID) == myTeamID then
            GG.Launchers[teamID][unitID].payload = defID
            echo("Payload recieved")
            Spring.DestroyUnit(id, true, false)
            return true
    end
    return false
end

function detectArrivingPayload()
    boolPayload= false
    while not boolPayload do
        process(
                getAllNearUnit(unitID, 100),
                function(id)
                    if  boolPayload then return end
                    
                    boolPayload = payloadCheck(id)
                    
                    if not boolPayload then
                        loadedUnits = Spring.GetUnitIsTransporting(id)
                        if loadedUnits then
                            for i=1, #loadedUnits do
                                boolPayload = payloadCheck(loadedUnits[i])
                                if boolPayload == true then break end
                            end
                        end
                    end
                end
                ) 
    Sleep(250)
    end
end

boolWorkCycle = true
function prePareForLaunch()
    boolWorkCycle = false
    hideT(TablesOfPiecesGroups["WIP"])
    showT(TablesOfPiecesGroups["Step"])

    StopSpin(Craddle, y_axis, 0.1)
    StopSpin(RocketAttach, y_axis, 0.1)
    StopSpin(rocket, y_axis, 0.1)
    moveRocketToPos(0, 25)
    WaitForTurns(RocketAttach, Elevator, rocket)
    Sleep(2500)
    WTurn(Crane, y_axis, math.rad(95), 5)

end

function WMoveRobotToPos(robotID, JointPos, MSpeed)
    Turn(TablesOfPiecesGroups["AAxis"][robotID], y_axis, math.rad(JointPos[1]),
         MSpeed)
    Turn(TablesOfPiecesGroups["BAxis"][robotID], z_axis, math.rad(JointPos[2]),
         MSpeed)
    Turn(TablesOfPiecesGroups["CAxis"][robotID], z_axis, math.rad(JointPos[3]),
         MSpeed)
    Turn(TablesOfPiecesGroups["DAxis"][robotID], x_axis, math.rad(JointPos[4]),
         MSpeed)
    Turn(TablesOfPiecesGroups["EAxis"][robotID], z_axis, math.rad(JointPos[5]),
         MSpeed)

    WaitForTurns(TablesOfPiecesGroups["AAxis"][robotID],
                 TablesOfPiecesGroups["BAxis"][robotID],
                 TablesOfPiecesGroups["CAxis"][robotID],
                 TablesOfPiecesGroups["DAxis"][robotID],
                 TablesOfPiecesGroups["EAxis"][robotID])
end

function moveToWorkBasePos(i)
    WMoveRobotToPos(i, WorkPos[i], math.rad(4, 12))
    WMoveRobotToPos(i, BasePos[i], math.rad(4, 12))
end

WorkPos = {
    [1] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0},
    [2] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0},
    [3] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0},
    [4] = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
}

BasePos = {
    [1] = {[1] = 0, [2] = -45, [3] = 45, [4] = 0, [5] = 0},
    [2] = {[1] = 0, [2] = -45, [3] = 45, [4] = 0, [5] = 0},
    [3] = {[1] = 0, [2] = 45, [3] = -45, [4] = 0, [5] = 0},
    [4] = {[1] = 0, [2] = 45, [3] = -45, [4] = 0, [5] = 0}
}

function workCycle()
    while boolWorkCycle == true do

        if boolBuilding == true then
            for i = 1, 4 do StartThread(moveToWorkBasePos, i) end
        end

        startFrame = Spring.GetGameFrame()
        endFrame = Spring.GetGameFrame() + 1

        while startFrame ~= endFrame do
            startFrame = Spring.GetGameFrame()
            for i = 1, 4 do
                robotID = i
                WaitForTurns(TablesOfPiecesGroups["AAxis"][robotID],
                             TablesOfPiecesGroups["BAxis"][robotID],
                             TablesOfPiecesGroups["CAxis"][robotID],
                             TablesOfPiecesGroups["DAxis"][robotID],
                             TablesOfPiecesGroups["EAxis"][robotID])
            end
            endFrame = Spring.GetGameFrame()
            Sleep(5)
        end
        Sleep(100)
    end
end

function script.Killed(recentDamage, _)
    myTeamID = Spring.GetUnitTeam(unitID)
    x,y,z = Spring.GetUnitPosition(unitID)
    if GG.Launchers[teamID][unitID] then 
        if GG.Launchers[teamID][unitID].payload then
            name = UnitDefs[GG.Launchers[teamID][unitID].payload ].name
            if name == "biopayload" then  --infect all nearby
                process(getAllNearUnit(unitID, GameConfig.bioWeaponPayloadKillRadius, gaiaTeamID),
                        function(id)
                            defID= Spring.GetUnitDefID(id)
                            if civilianTypeTable[defID] or truckTypeTable[defID] then
                                Spring.DestroyUnit(id, true, false)
                            end
                        end
                        )
            end

            if name == "physicspayload" then   --blow up this part of town
              
                weaponDefID = WeaponDefs["godrod"].id
                local params = {
                    pos = { x,  y,  z},
                   ["end"] = { x,  y,  z},
                speed = {0,0,0},
                spread = {0,0,0},
                error = {0,0,0},
                owner = unitID,
                team = myTeamID,
                ttl = 1,
                gravity = 1.0,
                tracking = unitID,
                maxRange = 9000,
                startAlpha = 0.0,
                endAlpha = 0.1,
                model = "emptyObjectIsEmpty.s3o",
                cegTag = ""

                }

                xOff,  zOff = math.random(0, 125)*randSign(), math.random(0, 125)*randSign()
                param.pos.x,param.pos.y, param.pos.z = x+xOff, y, z+zOff
                id=Spring.SpawnProjectile ( weaponDefID, param) 
                Spring.SetProjectileAlwaysVisible (id, true)


            end

            if name == "informationpayload" then
                --create social engineering and anarchy
                for i=1, 3 do 
                   id=  createUnitAtUnit(gaiaTeamID, "socialengineeringicon", unitID)
                   Command(id, "go",{x= x + math.random(512,1024)*randSign(), y= y, z= z + math.random(512,1024)*randSign()})
                end
                GG.SetGameStateTo = GameConfig.GameState.anarchy -- instigate chaos (add random social engineering)
            end
        end

        GG.Launchers[teamID][unitID] = nil 
    end
    if doesUnitExistAlive(buildID) == true then
        GG.UnitsToKill:PushKillUnit(buildID, true, false)
    end

    return 1
end

boolBuilding = false
function script.Activate()
    boolBuilding = true
    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    return 1
end

function script.Deactivate()
    boolBuilding = false
    SetUnitValue(COB.YARD_OPEN, 0)
    SetUnitValue(COB.BUGGER_OFF, 0)
    SetUnitValue(COB.INBUILDSTANCE, 0)
    return 0
end

function script.QueryBuildInfo() return center end

Spring.SetUnitNanoPieces(unitID, {center})
boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Icon)
    end
end

