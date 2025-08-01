include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}

SIG_PISTOL = 1
SIG_GUN = 2
SIG_SNIPER = 4
SIG_STOP = 8
SIG_UP = 16
SIG_LOW = 32
SIG_FIRE_VISIBLITY = 64
SIG_DELAYEDRECLOAK = 128
SIG_STAB = 256
SIG_ROOF_TOP = 512
local Animations = include('animation_assasin_male.lua')
boolStartRoofTopThread = false
local center = piece('center');
local Torso = piece('Torso');
local Pistol = piece('Pistol');
local Gun = piece('Gun');
local HolsteredGun = piece('HolsteredGun');
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
local silencer = piece('Silencer');
local GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)
local disguiseDefID = randT(civilianWalkingTypeTable)
speedCloaked            = GameConfig.assetCloakedSpeedReduction
speedRunning            = GameConfig.assetSpeedRunning
speedWalking            = GameConfig.assetSpeedWalking
local runningTimeInMS = 0
local gaiaTeamID = Spring.GetGaiaTeamID()
local houseTypeTable = getHouseTypeTable(UnitDefs)
local climbAbleHouseTypeTable = getClimbableHouseTypeTable(Unitefs)
westernHouseDefID= UnitDefNames["house_western0"].id


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

shownPieces={}
local boolWalking = false
local boolTurning = false
local boolTurnLeft = false
local boolDecoupled = false
local boolFlying = false
local boolAiming = false
local boolOnRoof = false
function onRooftop()
    --Spring.Echo("Is on Rooftop")
    boolOnRoof = true
    boolStartRoofTopThread= true
end

if not GG.OperativesDiscovered then GG.OperativesDiscovered = {} end
local civilianWalkingTypeTable = getCultureUnitModelTypes(  GameConfig.instance.culture, 
                                                             "civilian", UnitDefs)
boolInClosedCombat = false
closeCombat= {}
function isNowInCloseCombat( arenaID)
	boolInClosedCombat = true
	closeCombat= { arenaID = arenaID}
end

function closeCombatOS()
    Sleep(5)
    Hide(Gun)
    StartThread(delayedPieceDrop, Pistol, math.random(3,12)*1000)
    oldState = 1
    setOverrideAnimationState(eAnimState.fighting, eAnimState.walking, true, nil, function() return boolInClosedCombat end,    false)  
    while true do
        if boolInClosedCombat then
            --Spring.Echo("Operativeasset: Is now in close combat")
            while(doesUnitExistAlive(closeCombat.arenaID))do
                newState = math.random(1,3) 
                if newState ~= oldState then
                    if newState == 1   then 
                        setOverrideAnimationState(eAnimState.fighting, eAnimState.standing, true, nil, function() return boolInClosedCombat end,    false)  
                    else
                        setOverrideAnimationState(eAnimState.fighting, eAnimState.walking, true, nil, function() return boolInClosedCombat end,    false) 
                    end
                end
                oldState = newState
                Sleep(500)
            end
            --Spring.Echo("Operativeasset: Is leaving close combat")
            boolInClosedCombat = false 
        end
    Sleep(250)
    end
end

function delayedPieceDrop (pieces, times)
    for i=0,times, 1000 do
        EmitSfx(pieces,1024)
        Sleep(1000)
    end
    Sleep(times)
    --Explode(pieces, SFX.FALL)
    Hide(pieces)
end

function showGun()
    Show(Gun)
    Show(silencer)
    Hide(HolsteredGun)
 end

function hideGun()
    Hide(Gun)
    Hide(silencer)
    Show(HolsteredGun)
 end
 
 function hideFireArm()
	Hide(lastShownWeapon)
    Hide(silencer)
	if lastShownWeapon == Gun then
		hideGun()
	end
end

 function showFireArm()
	Hide(Gun)
	Hide(Pistol)
	Hide(silencer)
    if not boolInClosedCombat then
    	Show(lastShownWeapon)
    	if lastShownWeapon == Gun then
    		showGun()
    	end
    end
end

function externalAimFunction(targetPosT, remainderRotationRad)
    showFireArm()
    Turn(Torso,y_axis, remainderRotationRad, 55)
    setOverrideAnimationState(eAnimState.aiming, nil,  true, nil, false)
end

function script.Create()
    makeWeaponsTable()
    GG.OperativesDiscovered[unitID] = nil
    hideGun()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Shell"])
    shownPieces = randShowHide(unpack(TablesOfPiecesGroups["HeadDeco"]))
    Hide(backpack)
    hideT(TablesOfPiecesGroups["backpackX"])
    shownPieces[#shownPieces+1] =TablesOfPiecesGroups["backpackX"][math.random(1,#TablesOfPiecesGroups["backpackX"])]

    setupAnimation()
    --StartThread(turnDetector)
    StartThread(flyingMonitored)
    setOverrideAnimationState(eAnimState.slaved, eAnimState.standing, true, nil, false)

    StartThread(threadStarter)
    StartThread(cloakLoop)
    StartThread(breathing)
    StartThread(transportControl)
    StartThread(runningReactor)
    StartThread(speedMonitoring)
    StartThread(closeCombatOS)
    StartThread(gunVisibleOS)
    StartThread(instantParanoiaOS)
end

function instantParanoiaOS()
    walkingTypeTable = getCultureUnitModelTypes( GameConfig.instance.culture,  "civilian", UnitDefs)

    while true do
        minutes = math.random(3,12)*60*1000
        Sleep(minutes)
        delayInMs = math.random(2,5)*1000
        timeToFollowInMs = math.random(8,21)*1000
        if maRa() then              
            StartThread(instantParanoia, unitID, 250, delayInMs, timeToFollowInMs, walkingTypeTable)
        end
    end
end

function gunVisibleOS()
    while true do
	Sleep(1000)
		if not boolVisiblyForced and not boolAiming then
			Sleep(3000)
			hideFireArm()
		else
		-- TODDO Cause Fleeing People event
		end
	end
end

function script.HitByWeapon(x, z, weaponDefID, damage) 
    return damage 
end


function flyingPose(id)
	Turn(center, x_axis, math.rad(45),0)
	Turn(UpArm1, z_axis, math.rad(-40),0)
	Turn(UpArm2, z_axis, math.rad(40),0)
	Turn(center, x_axis, math.rad(65),0)
	Turn(center, x_axis, math.rad(65),0)
	reset(UpLeg1, 15)	
	reset(UpLeg2, 15)	
	reset(LowLeg2, 15)	
	reset(LowLeg1, 15)	
end

boolTransportedNoFiring = false
motorBikeTypeTable = getMotorBikeTypeTable(UnitDefs)
parachuteDefId = UnitDefNames["air_parachut"].id
function transportControl()
    Sleep(10)  

    waitTillComplete(unitID)
    while true do
        if isTransported(unitID) == true then
            transporterdefID = Spring.GetUnitDefID(Spring.GetUnitTransporter(unitID))

            if  motorBikeTypeTable[transporterdefID] then
                boolTransportedNoFiring = true 
                setOverrideAnimationState(eAnimState.slaved, eAnimState.riding, true, nil, function() return isTransported(unitID) end,    false)     
            end
               
            while isTransported(unitID) == true do    
                Sleep(100)
                if transporterdefID == parachuteDefId then
                    PlayAnimation("PARACHUTE_POSE")
                end
            end
            
            boolTransportedNoFiring = false
        
        end
        Sleep(1000)
    end
end

boolRunningTimeOut = false

function canRunFor(TimeInMS)
    return runningTimeInMS - TimeInMS > 0 and boolRunningTimeOut == false
end

function runFor(TimeInMS)
    runningTimeInMS = runningTimeInMS - TimeInMS
    if runningTimeInMS <= 101 then
        boolRunningTimeOut = true
         --echo("Running Timeout true")
    end
end


function runningReactor()
    runningTimeInMS = GameConfig.assetMaxRunTimeInSeconds*1000
    while true do
    runningTimeInMS = math.min(runningTimeInMS + 100, GameConfig.assetMaxRunTimeInSeconds*1000)
    Sleep(100)
    end
end

local cachedSpeed= math.huge
function setSpeedEnvCached(unitID, newSpeed )
    if newSpeed ~= cachedSpeed then
     --   echo("Setting Operativespeed to "..newSpeed)
        setSpeedEnv(unitID, newSpeed)
        cachedSpeed = newSpeed
    end

end

function speedMonitoring()
    while true do
    Sleep(50)
        if boolRunningPossible == true then
            if boolWalking == true then
                if canRunFor(50) == true then
                    setSpeedEnvCached(unitID, speedRunning)
                    runFor(50)
                else
                    if runningTimeInMS >= ((GameConfig.assetMaxRunTimeInSeconds*1000)) then
                        boolRunningTimeOut = false
                      --  echo("Running Timeout false")
                    end
                    setSpeedEnvCached(unitID, speedWalking)
                end
            end
        end
    end
end


function breathing()
    local breathSpeed = 0.1 / 3
    while true do
        if boolAiming == false and boolWalking == false then
            Turn(Head, x_axis, math.rad(-1), breathSpeed)
            WTurn(Torso, x_axis, math.rad(1), breathSpeed)
            Turn(Head, x_axis, math.rad(0), breathSpeed)
            WTurn(Torso, x_axis, math.rad(0), breathSpeed)
	       rx,ry,rz = math.random(-40,40)/10, math.random(-40,40)/10, math.random(-40,40)/10
            tP(Eye1,rx,ry,rz, 16)
    	    tP(Eye2,rx,ry,rz, 16)
            tP(Head,0,math.random(-25,25),0, 2)
        end
        Sleep(250)
    end

end

local boolFlying = false
function script.Falling()
    boolFlying = Spring.GetUnitTransporter(unitID) == nil
end

function script.Landed()
    boolFlying = false
end

--gives the first unit of this type a parachut and drops it
function flyingMonitored()
	while true do
		if boolFlying == true then		
			while(boolFlying == true) do
				Sleep(100)
				flyingPose(unitID)
			end
			WaitForTurns(TablesOfPiecesGroups)
			reset(center)
		end
		Sleep(100)
	end
end

uppperBodyAnimations = {
       [eAnimState.fighting] = {
        [1] = "FIGHTING",
    },
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
    [eAnimState.riding] = {[1]= "FULLBODY_RIDING"},
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
                -- -Spring.Echo("Piece "..command.p.." maps to "..getUnitPieceName(unitID, command.p))
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

            if not cmd.t then cmd.t = 0 end

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
			if not map[childName] then assert(false, childName) end
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
        if boolStartRoofTopThread == true then
            boolStartRoofTopThread = false
            StartThread(onRoof)
            --echo("Start Thread on Roof")
        end
        if boolStartThread == true then
            boolStartThread = false
            StartThread(deferedOverrideAnimationState,
                        locAnimationstateUpperOverride,
                        locAnimationstateLowerOverride, locBoolInstantOverride,
                        locConditionFunction)
            while boolStartThread == false do Sleep(33) end
        end
        Sleep(100)
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
      [eAnimState.fighting] = function()
                    PlayAnimation("FIGHTING", lowerBodyPieces, 1.0)

                    if boolInClosedCombat then
                        return eAnimState.fighting
                    else
                        return eAnimState.standing
                    end
                end,
    [eAnimState.standing] = function()  
	if boolFlying == true then  return eAnimState.standing end
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
	if boolFlying == true then return eAnimState.walking end
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
     [eAnimState.riding] = function()
        PlayAnimation(randT(lowerBodyAnimations[eAnimState.riding]), {})
 
        return eAnimState.riding
    end,



    [eAnimState.walking] = function()
	if boolFlying == true then return eAnimState.walking end

        if boolAiming == true then
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),
                          upperBodyPieces)
        else
            PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]))
        end
        return eAnimState.walking
    end,
    [eAnimState.standing] = function()
	if boolFlying == true then return eAnimState.standing end
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
    Turn(center,x_axis, math.rad(-10), 1)
    Signal(SIG_STOP)
    SetSignalMask(SIG_STOP)
    Sleep(250)
    if not GG.OperativeTurnTable then GG.OperativeTurnTable = {} end
    GG.OperativeTurnTable[unitID] = nil
    boolWalking = false
    -- Spring.Echo("Stopping")
    setOverrideAnimationState(eAnimState.standing, eAnimState.standing, true, nil, true)
    Turn(center,x_axis, math.rad(0), 12)
end

function isInBuilding()
    boolOnAtLeastOneRoof= false
    ux,uy,uz = Spring.GetUnitPosition(unitID)
    resultDefID= nil
    foreach( 
            getAllNearUnit(unitID, GameConfig.houseSizeX, gaiaTeamID),
            function(id)
                defID= Spring.GetUnitDefID(id)
                if climbAbleHouseTypeTable[defID]then 
                    if IsOnPremisesOfBuilding(unitID, id, GameConfig.houseSizeX) then
                        boolOnAtLeastOneRoof = true
                        resultDefID = defID
                    end
                    return id
                end
            end
            )
     return boolOnAtLeastOneRoof, ux, uy, uz, resultDefID
end
    


function onRoof()
    Signal(SIG_ROOF_TOP)
    SetSignalMask(SIG_ROOF_TOP)
    echo("operative: on Roof")
    boolHasMoveCommand = getUnitMoveGoal(unitID, 1)
    boolVisiblyForced= true
    while not boolHasMoveCommand  do
        Sleep(15)
       boolHasMoveCommand = getUnitMoveGoal(unitID, 1)
    end
    boolVisiblyForced = false
    transporter = Spring.GetUnitTransporter(unitID)
    if transporter then
        transporterDefID = Spring.GetUnitDefID(transporter)
        if climbAbleHouseTypeTable[transporterDefID] then
            Spring.UnitDetach(unitID)
        end
    end
    boolOnRoof= false
end

function script.StartMoving()
    boolWalking = true
    Turn(center, y_axis, math.rad(5), 12)

    setOverrideAnimationState(eAnimState.slaved, eAnimState.walking, true, nil,
                              false)
end

function script.StopMoving() 

    StartThread(delayedStop) 
end

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
    --Spring.SetUnitNoSelect(civilianID, true)
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
        GG.EventStream:CreateEvent(syncDecoyToAgent, persPack, Spring.GetGameFrame() + 1)
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

myCollideData = getCollideData(unitID)
boolIsBuilding = false
boolRunningPossible = false
function transitionToUncloaked()
    boolRunningPossible = true
    setSpeedEnvCached(unitID, speedRunning)
    setWantCloak(false)
    restoreCollide(unitID, myCollideData)
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
    boolRunningPossible = false
    setSpeedEnvCached(unitID, speedCloaked)
    myCollideData = setNoneCollide(unitId)
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

currentCloakState = "cloaked"
previousState = currentCloakState
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


            if boolInClosedCombat == true then 
                return transitionToUncloaked()
            end

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

            if boolInClosedCombat == true then 
                return "decloaked"
            end

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
    setSpeedEnv(unitID, speedCloaked)
    StartThread(spawnDecoyCivilian)
    showHideIcon(true)

    while true do
        currentCloakState = cloakStateMachine[currentCloakState]()
        --	if currentCloakState ~= previousState then echoState() end
        previousState = currentCloakState
        Sleep(100)
    end
end

function echoState()
    echo("============================================")
    echo("State: " .. currentCloakState)
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
	showFireArm()
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
	showFireArm()
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
	if not boolOnRoof then return false end
    boolAiming = true
	showFireArm()
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

function stabAimFunction(weaponID, heading, pitch)
    boolAiming = true
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
    if boolCloaked == true then
        Spring.PlaySoundFile("sounds/weapons/pistol/stealthpistol.ogg", 1.0)
    else
        Spring.PlaySoundFile("sounds/weapons/pistol/pistolshot"..math.random(1,3)..".ogg", 1.0)
    end
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

function stabFireFunction(weaponID)
    Spring.Echo("Firing Weapon stab")
    boolAiming = false
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
    WeaponsTable[4] = {
        aimpiece = Gun,
        emitpiece = Gun,
        aimfunc = stabAimFunction,
        firefunc = stabFireFunction,
        signal = SIG_STAB
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
     if weaponID == 4 then 
      --  Spring.Echo("weaponAim:"..weaponID.." targetType"..targetType)
        return true
    end
    
    if boolInClosedCombat == true then return false end
    if boolTransportedNoFiring == true then return false end

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
        lastShownWeapon = Pistol
		showFireArm()
        boolPistol = true
        if weaponID == 1 then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        end

        if weaponID == 4 then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        end
    else
        lastShownWeapon = Gun
		showFireArm()
        boolPistol = false
        if weaponID > 1 then
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
        hideT(TablesOfPiecesGroups.HeadDeco)
        showT(shownPieces)
        showFireArm()
        hideT(TablesOfPiecesGroups["Shell"])
        Hide(Icon)
    end
end
