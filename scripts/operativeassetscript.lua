include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"
myDefID = Spring.GetUnitDefID(unitID)
TablesOfPiecesGroups = {}

SIG_PISTOL = 1
SIG_GUN = 2
SIG_SNIPER = 4
SIG_STOP = 8
SIG_UP = 16
SIG_LOW = 32
SIG_FIRE_VISIBLITY = 64
SIG_DELAYEDRECLOAK = 128
local Animations = include('animation_assasin_male.lua')

local center = piece('center');
local Torso = piece('Torso');
local Pistol = piece('Pistol');
local Gun = piece('Gun');
local Head = piece('Head');
local UpLeg2 = piece('UpLeg2');
local LowLeg2 = piece('LowLeg2');
local UpLeg1 = piece('UpLeg1');
local LowLeg1 = piece('LowLeg1');
local UpArm2 = piece('UpArm2');
local LowArm2 = piece('LowArm2');
local UpArm1 = piece('UpArm1');
local LowArm1 = piece('LowArm1');
local Eye1 = piece('Eye1');
local Eye2 = piece('Eye2');
local backpack = piece('backpack');
GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)
local disguiseDefID = randT(civilianWalkingTypeTable)
mySpeedReductionCloaked = GameConfig.assetCloakedSpeedReduction

local scriptEnv = {
    center = center,
    Torso = Torso,
    Pistol = Pistol,
    Gun = Gun,
    Head = Head,
    UpLeg2 = UpLeg2,
    LowLeg2 = LowLeg2,
    UpLeg1 = UpLeg1,
    LowLeg1 = LowLeg1,
    UpArm2 = UpArm2,
    LowArm2 = LowArm2,
    UpArm1 = UpArm1,
    LowArm1 = LowArm1,
    Eye1 = Eye1,
    Eye2 = Eye2,
    backpack = backpack,

    x_axis = x_axis,
    y_axis = y_axis,
    z_axis = z_axis
}
eAnimState = getCivilianAnimationStates()
upperBodyPieces = {
    [Head] = Head,
    [Pistol] = Pistol,
    [UpArm1] = UpArm1,
    [UpArm2] = UpArm2,
    [LowArm1] = LowArm1,
    [LowArm2] = LowArm2,
    [Torso] = Torso,
    [Eye1] = Eye1,
    [Eye2] = Eye2,
    [backpack] = backpack,
    [center] = center
}

lowerBodyPieces = {
    [UpLeg1] = UpLeg1,
    [UpLeg2] = UpLeg2,
    [LowLeg1] = LowLeg1,
    [LowLeg2] = LowLeg2

}

boolWalking = false
boolTurning = false
boolTurnLeft = false
boolDecoupled = false

boolAiming = false
if not GG.OperativesDiscovered then GG.OperativesDiscovered = {} end

function script.Create()
    makeWeaponsTable()
    GG.OperativesDiscovered[unitID] = nil
    Hide(Gun)

    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Shell"])
    setupAnimation()
    -- StartThread(turnDetector)

    setOverrideAnimationState(eAnimState.slaved, eAnimState.standing, true, nil,
                              false)

    StartThread(threadStarter)
    StartThread(cloakLoop)
    -- StartThread(testAnimationLoop)
    StartThread(breathing)

end

function script.HitByWeapon(x, z, weaponDefID, damage) return damage end

function breathing()
    local breathSpeed = 0.1 / 3
    while true do
        if boolAiming == false and boolWalking == false then
            Turn(Head, x_axis, math.rad(-1), breathSpeed)
            WTurn(Torso, x_axis, math.rad(1), breathSpeed)
            Turn(Head, x_axis, math.rad(0), breathSpeed)
            WTurn(Torso, x_axis, math.rad(0), breathSpeed)
        end
        Sleep(250)
    end

end

function testAnimationLoop()
    Sleep(500)
    while true do
        PlayAnimation("UPBODY_STANDING_PISTOL")
        Sleep(100)

    end
end

uppperBodyAnimations = {
    [eAnimState.idle] = {
        [1] = "UPBODY_STANDING_GUN",
        [2] = "UPBODY_STANDING_PISTOL"
    },
    [eAnimState.aiming] = {[1] = "UPBODY_AIMING"},
    [eAnimState.walking] = {[1] = "SLAVED"},

    [eAnimState.standing] = {
        [1] = "UPBODY_STANDING_GUN",
        [2] = "UPBODY_STANDING_PISTOL"
    }
}

lowerBodyAnimations = {
    [eAnimState.walking] = {[1] = "WALKCYCLE_RUNNING"},
    [eAnimState.standing] = {[1] = "UPBODY_STANDING_GUN"},
    [eAnimState.aiming] = {[1] = "UPBODY_STANDING_GUN"}
}

local animCmd = {['turn'] = Turn, ['move'] = Move};

function setupAnimation()
    local map = Spring.GetUnitPieceMap(unitID);
    local switchAxis = function(axis)
        if axis == z_axis then return y_axis end
        if axis == y_axis then return z_axis end
        return axis
    end

    local offsets = constructSkeleton(unitID, center, {0, 0, 0});

    for a, anim in pairs(Animations) do
        for i, keyframe in pairs(anim) do
            local commands = keyframe.commands;
            for k, command in pairs(commands) do
                if command.p and type(command.p) == "string" then
                    command.p = map[command.p]
                end
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                if (command.c == "move") then
                    local adjusted = command.t - (offsets[command.p][command.a]);
                    Animations[a][i]['commands'][k].t =
                        command.t - (offsets[command.p][command.a]);
                end

                Animations[a][i]['commands'][k].a = switchAxis(command.a)
            end
        end
    end
end

local animCmd = {['turn'] = Turn, ['move'] = Move};

local axisSign = {[x_axis] = 1, [y_axis] = 1, [z_axis] = 1}

function PlayAnimation(animname, piecesToFilterOutTable, speed)
    local speedFactor = speed or 1.0
    if not piecesToFilterOutTable then piecesToFilterOutTable = {} end
    assert(animname, "animation name is nil")
    assert(type(animname) == "string",
           "Animname is not string " .. toString(animname))
    assert(Animations[animname], "No animation with name ")
    local anim = Animations[animname];
    local randoffset
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1, #commands do
            local cmd = commands[j];
            randoffset = 0.0
            if cmd.r then
                randVal = cmd.r * 100
                randoffset = math.random(-randVal, randVal) / 100
            end

            if cmd.ru or cmd.rl then
                randUpVal = (cmd.ru or 0.01) * 100
                randLowVal = (cmd.rl or 0) * 100
                randoffset = math.random(randLowVal, randUpVal) / 100
            end

            if not piecesToFilterOutTable[cmd.p] then
                animCmd[cmd.c](cmd.p, cmd.a,
                               axisSign[cmd.a] * (cmd.t + randoffset),
                               cmd.s * speedFactor)

            end
        end
        if (i < #anim) then
            local t = anim[i + 1]['time'] - anim[i]['time'];
            Sleep(t * 33 * math.abs(1 / speedFactor)); -- sleep works on milliseconds
        end
    end
end

function constructSkeleton(unit, piece, offset)
    if (offset == nil) then offset = {0, 0, 0}; end

    local bones = {};
    local info = Spring.GetUnitPieceInfo(unit, piece);

    for i = 1, 3 do info.offset[i] = offset[i] + info.offset[i]; end

    bones[piece] = info.offset;
    local map = Spring.GetUnitPieceMap(unit);
    local children = info.children;

    if (children) then
        for i, childName in pairs(children) do
            local childId = map[childName];
            local childBones = constructSkeleton(unit, childId, info.offset);
            for cid, cinfo in pairs(childBones) do
                bones[cid] = cinfo;
            end
        end
    end
    return bones;
end

function script.Killed(recentDamage, _)
    if doesUnitExistAlive(civilianID) == true then
        Spring.DestroyUnit(civilianID, true, true)
    end
    PlayAnimation("DEATH")
    return 1
end

local locAnimationstateUpperOverride
local locAnimationstateLowerOverride
local locBoolInstantOverride
local locConditionFunction
local boolStartThread = false
boolPistol = true

function threadStarter()
    Sleep(100)
    while true do
        if boolStartThread == true then
            boolStartThread = false
            StartThread(deferedOverrideAnimationState,
                        locAnimationstateUpperOverride,
                        locAnimationstateLowerOverride, locBoolInstantOverride,
                        locConditionFunction)
            while boolStartThread == false do Sleep(33) end
        end
        Sleep(33)
    end
end

function deferedOverrideAnimationState(AnimationstateUpperOverride,
                                       AnimationstateLowerOverride,
                                       boolInstantOverride, conditionFunction)
    if boolInstantOverride == true then
        if AnimationstateUpperOverride then
            UpperAnimationState = AnimationstateUpperOverride
            StartThread(animationStateMachineUpper, UpperAnimationStateFunctions)
        end
        if AnimationstateLowerOverride then
            LowerAnimationState = AnimationstateLowerOverride
            StartThread(animationStateMachineLower, LowerAnimationStateFunctions)
        end

    else
        StartThread(setAnimationState, AnimationstateUpperOverride,
                    AnimationstateLowerOverride)
    end

    if conditionFunction then StartThread(conditionFunction) end
end

function setAnimationState(AnimationstateUpperOverride,
                           AnimationstateLowerOverride)
    -- if we are already animating correctly early out
    if AnimationstateUpperOverride == UpperAnimationState and
        AnimationstateLowerOverride == LowerAnimationState then return end

    Signal(SIG_ANIM)
    SetSignalMask(SIG_ANIM)

    if AnimationstateUpperOverride then boolUpperStateWaitForEnd = true end
    if AnimationstateLowerOverride then boolLowerStateWaitForEnd = true end

    while AnimationstateLowerOverride and boolLowerAnimationEnded == false or
        AnimationstateUpperOverride and boolUpperAnimationEnded == false do
        Sleep(30)
        if AnimationstateUpperOverride == true then
            boolUpperStateWaitForEnd = true
        end

        if AnimationstateLowerOverride == true then
            boolLowerStateWaitForEnd = true
        end

        Sleep(30)
    end

    if AnimationstateUpperOverride then
        UpperAnimationState = AnimationstateUpperOverride
    end
    if AnimationstateLowerOverride then
        LowerAnimationState = AnimationstateLowerOverride
    end
    if boolUpperStateWaitForEnd == true then boolUpperStateWaitForEnd = false end
    if boolLowerStateWaitForEnd == true then boolLowerStateWaitForEnd = false end
end

-- <Exposed Function>

function setOverrideAnimationState(AnimationstateUpperOverride,
                                   AnimationstateLowerOverride,
                                   boolInstantOverride, conditionFunction,
                                   boolDecoupledStates)
    boolDecoupled = boolDecoupledStates
    locAnimationstateUpperOverride = AnimationstateUpperOverride
    locAnimationstateLowerOverride = AnimationstateLowerOverride
    locBoolInstantOverride = boolInstantOverride or false
    locConditionFunction = conditionFunction or (function() return true end)
    boolStartThread = true
end

-- </Exposed Function>
function conditionalFilterOutUpperBodyTable()
    if boolDecoupled == false then
        return {}
    else
        return upperBodyPieces
    end
end

function playUpperBodyIdleAnimation()

    selectedIdleFunction =
        math.random(1, #uppperBodyAnimations[eAnimState.idle])
    if selectedIdleFunction and uppperBodyAnimations[eAnimState.idle] and
        uppperBodyAnimations[eAnimState.idle][selectedIdleFunction] then
        PlayAnimation(
            uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
    end

end

UpperAnimationStateFunctions = {
    [eAnimState.standing] = function()
        resetT(lowerBodyPieces, 10)
        if boolPistol == true then
            PlayAnimation("UPBODY_STANDING_PISTOL", lowerBodyPieces)
        else
            PlayAnimation("UPBODY_STANDING_GUN", lowerBodyPieces, 3.0)
        end
        -- echo("UpperBody Standing")
        if boolDecoupled == true then
            if math.random(1, 10) > 5 then
                playUpperBodyIdleAnimation()
            end
        end
        Sleep(30)
        return eAnimState.standing
    end,
    [eAnimState.walking] = function()

        boolDecoupled = true
        playUpperBodyIdleAnimation()
        boolDecoupled = false

        return eAnimState.walking
    end,
    [eAnimState.slaved] = function()
        Sleep(100)
        return eAnimState.slaved
    end,
    [eAnimState.aiming] = function()
        if boolPistol == true then
            PlayAnimation("UPBODY_AIM_PISTOL")
        else
            PlayAnimation("UPBODY_AIMING", nil, 3.0)
        end
        Sleep(100)
        return eAnimState.aiming
    end
}

LowerAnimationStateFunctions = {
    [eAnimState.walking] = function()
        assert(lowerBodyAnimations[eAnimState.walking])
        if boolAiming == true then
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          upperBodyPieces)
        else
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]))
        end
        return eAnimState.walking
    end,
    [eAnimState.standing] = function()
        -- Spring.Echo("Lower Body standing")
        resetT(lowerBodyPieces, 12)
        Sleep(100)
        return eAnimState.standing
    end,
    [eAnimState.aiming] = function()
        AimDelay = AimDelay + 100
        if boolWalking == true or AimDelay < 1000 then
            AimDelay = 0
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          upperBodyPieces)
        elseif AimDelay > 1000 then

            PlayAnimation(randT(lowerBodyAnimations[eAnimState.standing]),
                          upperBodyPieces)
        end
        Sleep(100)
        return eAnimState.aiming
    end
}
AimDelay = 0
LowerAnimationState = eAnimState.standing
boolLowerStateWaitForEnd = false
boolLowerAnimationEnded = false

function animationStateMachineLower(AnimationTable)
    Signal(SIG_LOW)
    SetSignalMask(SIG_LOW)

    boolLowerStateWaitForEnd = false

    local animationTable = AnimationTable
    -- Spring.Echo("lower Animation StateMachine Cycle")
    while true do
        assert(LowerAnimationState)
        assert(animationTable[LowerAnimationState],
               "Animationstate not existing " .. LowerAnimationState)
        LowerAnimationState = animationTable[LowerAnimationState]()

        -- Sync Animations
        -- echoNFrames("Unit "..unitID.." :LStatMach :"..LowerAnimationState, 500)
        if boolLowerStateWaitForEnd == true then
            boolLowerAnimationEnded = true
            while boolLowerStateWaitForEnd == true do
                Sleep(33)
                -- echoNFrames("Unit "..unitID.." :LWaitForEnd :"..LowerAnimationState, 500)
                -- Spring.Echo("lower Animation Waiting For End")
            end
            boolLowerAnimationEnded = false
        end
        Sleep(33)
    end
end

UpperAnimationState = eAnimState.standing
boolUpperStateWaitForEnd = false
boolUpperAnimationEnded = false

function animationStateMachineUpper(AnimationTable)
    Signal(SIG_UP)
    SetSignalMask(SIG_UP)

    boolUpperStateWaitForEnd = false
    local animationTable = AnimationTable

    while true do
        assert(UpperAnimationState)
        assert(animationTable[UpperAnimationState],
               "Upper Animationstate not existing " .. UpperAnimationState)

        UpperAnimationState = animationTable[UpperAnimationState]()
        -- echoNFrames("Unit "..unitID.." :UStatMach :"..UpperAnimationState, 500)
        -- Sync Animations
        if boolUpperStateWaitForEnd == true then
            boolUpperAnimationEnded = true
            while boolUpperStateWaitForEnd == true do Sleep(10) end
            boolUpperAnimationEnded = false
        end
        Sleep(33)
    end

end

function delayedStop()
    Signal(SIG_STOP)
    SetSignalMask(SIG_STOP)
    Sleep(250)
    boolWalking = false
    -- Spring.Echo("Stopping")
    setOverrideAnimationState(eAnimState.standing, eAnimState.standing, true,
                              nil, true)
end

function script.StartMoving()
    boolWalking = true
    Turn(center, y_axis, math.rad(0), 12)
    setOverrideAnimationState(eAnimState.slaved, eAnimState.walking, true, nil,
                              false)
end

function script.StopMoving() StartThread(delayedStop) end

local civilianID

function spawnDecoyCivilian()
    -- spawnDecoyCivilian
    Sleep(10)
    if civilianID ~= nil and doesUnitExistAlive(civilianID) == true then
        return
    end

    x, y, z = Spring.GetUnitPosition(unitID)
    civilianID = Spring.CreateUnit(disguiseDefID, x + randSign() * 5, y,
                                   z + randSign() * 5, 1, Spring.GetGaiaTeamID())
    transferUnitStatusToUnit(unitID, civilianID)
    Spring.SetUnitNoSelect(civilianID, true)
    Spring.SetUnitAlwaysVisible(civilianID, true)

    persPack = {
        myID = civilianID,
        syncedID = unitID,
        startFrame = Spring.GetGameFrame() + 1
    }
    if not GG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end
    GG.DisguiseCivilianFor[civilianID] = unitID
    if not GG.DiedPeacefully then GG.DiedPeacefully = {} end
    GG.DiedPeacefully[civilianID] = false

    if civilianID then
        GG.EventStream:CreateEvent(syncDecoyToAgent, persPack,
                                   Spring.GetGameFrame() + 1)

    end

    return 0
end

function getWantCloak()
    wantCloak = Spring.UnitScript.GetUnitValue(COB.WANT_CLOAK)
    if wantCloak == 1 then
        return true
    else
        return false
    end
    return false
end

boolIsBuilding = false

function transitionToUncloaked()
    setSpeedEnv(unitID, 1.0)
    setWantCloak(false)
    if civilianID and doesUnitExistAlive(civilianID) == true then
        GG.DiedPeacefully[civilianID] = true
        Spring.DestroyUnit(civilianID, true, true)
    end
    return "decloaked"
end

function setWantCloak(boolWantCloak)
    if boolWantCloak == true then
        SetUnitValue(COB.WANT_CLOAK, 1)
    else
        SetUnitValue(COB.WANT_CLOAK, 0)
    end
end

function transitionToCloaked()
    setWantCloak(true)
    setSpeedEnv(unitID, mySpeedReductionCloaked)
    StartThread(spawnDecoyCivilian)
    return "cloaked"
end

function OperativesDiscovered()
    if GG.OperativesDiscovered == nil then return false end

    if GG.OperativesDiscovered[unitID] == nil then
        return false
    elseif type(GG.OperativesDiscovered[unitID]) == "boolean" then
        return GG.OperativesDiscovered[unitID]
    end

    return false
end

currentState = "cloaked"
previousState = currentState
boolRecloakOnceDone = false
function cloakLoop()
    local cloakStateMachine = {
        ["cloaked"] = function(boolCloakRequest, boolPreviouslyCloaked,
                               visibleForced)
            boolCloakRequest = getWantCloak()
            boolVisiblyForced = (boolIsBuilding == true) or
                                    (boolFireForcedVisible == true) or
                                    (not OperativesDiscovered() == false)
            boolPreviouslyCloaked = (previousState == "cloaked")

            if not boolVisiblyForced == false then
                boolRecloakOnceDone = true
                return transitionToUncloaked()
            end

            if (not boolCloakRequest == true) then
                return transitionToUncloaked()
            end

            return "cloaked"
        end,
        ["decloaked"] = function()
            boolCloakRequest = getWantCloak()
            boolVisiblyForced = (boolIsBuilding == true) or
                                    (boolFireForcedVisible == true) or
                                    (not OperativesDiscovered() == false)
            boolPreviouslyCloaked = (previousState == "cloaked")

            if boolVisiblyForced == true then return "decloaked" end

            if not boolVisiblyForced == true and boolRecloakOnceDone == true then
                boolRecloakOnceDone = false
                return transitionToCloaked()
            end

            if not boolCloakRequest == false then
                return transitionToCloaked()
            end

            if boolPreviouslyCloaked == true and boolCloakRequest == false then
                return "decloaked"
            end

            if boolCloakRequest == true and boolVisiblyForced == true then
                return "decloaked"
            end

            return "decloaked"
        end
    }

    Sleep(100)
    waitTillComplete(unitID)

    -- initialisation
    setSpeedEnv(unitID, mySpeedReductionCloaked)
    StartThread(spawnDecoyCivilian)
    showHideIcon(true)

    while true do
        currentState = cloakStateMachine[currentState]()
        --	if currentState ~= previousState then echoState() end
        previousState = currentState
        Sleep(100)
    end
end

function echoState()
    echo("============================================")
    echo("State: " .. currentState)
    echo("boolCloakRequest: " .. toString(getWantCloak()))
    echo("boolIsBuilding: " .. toString(boolIsBuilding))
    echo("boolFireForcedVisible: " .. toString(boolFireForcedVisible))
    echo("boolPreviouslyCloaked: " .. toString((previousState == "cloaked")))
    echo("============================================")
end

function script.QueryBuildInfo() return center end

function delayedStopBuilding()
    Signal(SIG_DELAYEDRECLOAK)
    SetSignalMask(SIG_DELAYEDRECLOAK)
    Sleep(500)
    boolIsBuilding = false
end

function script.StopBuilding()
    StartThread(delayedStopBuilding)
    SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.StartBuilding(heading, pitch)
    Signal(SIG_DELAYEDRECLOAK)
    boolIsBuilding = true
    SetUnitValue(COB.INBUILDSTANCE, 1)
end

local spGetUnitTeam = Spring.GetUnitTeam
local myTeamID = spGetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget
local loc_doesUnitExistAlive = doesUnitExistAlive

function pistolAimFunction(weaponID, heading, pitch)
    boolAiming = true
    if boolWalking == true then
        setOverrideAnimationState(eAnimState.aiming, eAnimState.walking, true,
                                  nil, false)
    else
        setOverrideAnimationState(eAnimState.aiming, eAnimState.standing, true,
                                  nil, false)
    end
    WTurn(center, y_axis, heading, 22)
    WaitForTurns(UpArm1, UpArm2, LowArm1, LowArm2)
    return true
end

function gunAimFunction(weaponID, heading, pitch)
    boolAiming = true
    if boolWalking == true then
        setOverrideAnimationState(eAnimState.aiming, eAnimState.walking, true,
                                  nil, false)
    else
        setOverrideAnimationState(eAnimState.aiming, eAnimState.standing, true,
                                  nil, false)
    end
    WTurn(center, y_axis, heading, 22)
    WaitForTurns(UpArm1, UpArm2, LowArm1, LowArm2)
    return true
end

function sniperAimFunction(weaponID, heading, pitch)
    boolAiming = true
    if boolWalking == true then
        setOverrideAnimationState(eAnimState.aiming, eAnimState.walking, true,
                                  nil, false)
    else
        setOverrideAnimationState(eAnimState.aiming, eAnimState.standing, true,
                                  nil, false)
    end
    WTurn(center, y_axis, heading, 22)
    WaitForTurns(UpArm1, UpArm2, LowArm1, LowArm2)
    return true
end

boolFireForcedVisible = false
function visibleAfterWeaponsFireTimer()
    boolFireForcedVisible = true
    Signal(SIG_FIRE_VISIBLITY)
    SetSignalMask(SIG_FIRE_VISIBLITY)
    value = GameConfig.assetShotFiredWaitTimeToRecloak_MS
    Sleep(value)
    boolFireForcedVisible = false
end

function pistolFireFunction(weaponID)
    StartThread(visibleAfterWeaponsFireTimer)
    boolAiming = false
    -- Explode(TablesOfPiecesGroups["Shell"][1], SFX.FALL + SFX.NO_HEATCLOUD)
    return true
end

function gunFireFunction(weaponID)
    StartThread(visibleAfterWeaponsFireTimer)
    boolAiming = false
    -- Explode(TablesOfPiecesGroups["Shell"][2], SFX.FALL + SFX.NO_HEATCLOUD)
    return true
end

function sniperFireFunction(weaponID)
    StartThread(visibleAfterWeaponsFireTimer)
    boolAiming = false
    --	Explode(TablesOfPiecesGroups["Shell"][2], SFX.FALL + SFX.NO_HEATCLOUD)
    Spring.PlaySoundFile("sounds/weapons/sniper/sniperEject.wav", 0.8)
    return true
end

WeaponsTable = {}
function makeWeaponsTable()
    WeaponsTable[1] = {
        aimpiece = center,
        emitpiece = Pistol,
        aimfunc = pistolAimFunction,
        firefunc = pistolFireFunction,
        signal = SIG_PISTOL
    }
    WeaponsTable[2] = {
        aimpiece = center,
        emitpiece = Gun,
        aimfunc = gunAimFunction,
        firefunc = gunFireFunction,
        signal = SIG_GUN
    }
    WeaponsTable[3] = {
        aimpiece = center,
        emitpiece = Gun,
        aimfunc = sniperAimFunction,
        firefunc = sniperFireFunction,
        signal = SIG_SNIPER
    }
end

function script.AimFromWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].aimpiece
    else
        return center
    end
end

validTargetType = {[1] = true, [2] = true}

function script.QueryWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].emitpiece
    else
        return center
    end
end

function script.FireWeapon(weaponID)
    return WeaponsTable[weaponID].firefunc(weaponID, heading, pitch)
end

lastShownWeapon = Pistol
function script.AimWeapon(weaponID, heading, pitch)
    targetType, isUserTarget, targetID = spGetUnitWeaponTarget(unitID, weaponID)

    if not targetType or (not validTargetType[targetType]) then
        -- echo("TargetType:"..targetType.." TargetID:");echo(targetID)
        return false
    end
    -- echo(targetType, targetID)
    dist = 0
    if targetType == 2 then
        dist = distanceOfUnitToPoint(unitID, targetID[1], targetID[2],
                                     targetID[3])
    elseif targetType == 1 then
        dist = distanceUnitToUnit(unitID, targetID)
        -- echo("Distance to target:"..distanceUnitToUnit(unitID, targetID))
    end

    -- Do not aim at your own disguise civilian
    if targetType == 1 and spGetUnitTeam(targetID) == gaiaTeamID then
        if GG.DisguiseCivilianFor[targetID] and
            spGetUnitTeam(GG.DisguiseCivilianFor[targetID]) == myTeamID then
            return false
        end
    end

    -- if distance to target is smaller then 500 switch to pistol

    if dist < 250 then
        Hide(Gun)
        Show(Pistol)
        lastShownWeapon = Pistol
        boolPistol = true
        if weaponID == 1 then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        end
    else
        Hide(Pistol)
        lastShownWeapon = Gun
        Show(Gun)
        boolPistol = false
        if weaponID ~= 1 then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        end
    end

    return false
end

Spring.SetUnitNanoPieces(unitID, {center})

Icon = piece("Icon")

function showHideIcon(boolCloaked)
    if boolCloaked == true then
        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Gun)
        Hide(Pistol)
        Show(lastShownWeapon)
        hideT(TablesOfPiecesGroups["Shell"])
        Hide(Icon)
    end
end
