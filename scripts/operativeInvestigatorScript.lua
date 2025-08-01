include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

local TablesOfPiecesGroups = {}

SIG_PISTOL = 1
SIG_RAID = 2
SIG_FIRE_VISIBLITY = 4
SIG_DELAYEDRECLOAK = 8
SIG_STAB = 16
SIG_AIM = 32
deg_1 = 3.141592653589793 / 180.0
local isInvestigator = unitDefID == UnitDefNames["operativeinvestigator"].id
local Animations = {}
local axisSign ={
	[x_axis]=1,
	[y_axis]=1,
	[z_axis]=1,
}


	Animations = include('animation_operativeinvestigator_female.lua') 

local center = piece('center');
local Torso = piece('Torso');
local Pistol = piece('Pistol');
local Gun = Pistol;
local Head = piece('Head');
local UpLeg2 = piece('UpLeg2');
local LowLeg2 = piece('LowLeg2');
local UpLeg1 = piece('UpLeg1');
local LowLeg1 = piece('LowLeg1');
local UpArm2 = piece('UpArm2');
local LowArm2 = piece('LowArm2');
local Hand2 = piece('Hand2');
local UpArm1 = piece('UpArm1');
local LowArm1 = piece('LowArm1');
local Hand1 = piece('Hand1');
local Eye1 = piece('Eye1');
local Eye2 = piece('Eye2');
local backpack = piece('backpack');
local Drone = piece("Drone")
local Micro = piece("Micro")

local Icon = piece("Icon")
local Shell1 = piece("Shell1")
local FoldtopUnfolded = piece'FoldtopUnfolded'
local FoldtopFolded= piece'FoldtopFolded'

local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget
local GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)
civilianSortedBySexTable = getCivlianDisguiseBySexTypeTable(UnitDefs, getOperatorSex(UnitDefs, unitDefID))
local disguiseDefID = randT(civilianSortedBySexTable)
local mySpeedReductionCloaked = GameConfig.investigatorCloakedSpeedReduction
local spGetUnitTeam = Spring.GetUnitTeam
local myTeamID= spGetUnitTeam(unitID)
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
local spGetUnitDefID = Spring.GetUnitDefID

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
	z_axis = z_axis,
}
eAnimState = getCivilianAnimationStates()
upperBodyPieces =
{
	[Head	]  = Head,
	[Pistol]= Pistol,
	[UpArm1 ] = UpArm1,
	[Hand1]  = Hand1,
	[Hand2]  = Hand2,
	[UpArm2]  = UpArm2,
	[LowArm1 ] = LowArm1,
	[LowArm2]  = LowArm2,
	[Torso  ]	= Torso,
	[Eye1 ]= Eye1,
	[Eye2 ]= Eye2,
	[backpack]= backpack,
	[center	]= center
	}
	
lowerBodyPieces =
{
	[UpLeg1	]= UpLeg1,
	[UpLeg2 ]= UpLeg2,
	[LowLeg1]= LowLeg1,
	[LowLeg2]= LowLeg2
}

local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "house", UnitDefs)

boolInClosedCombat = false
closeCombat= {}
function isNowInCloseCombat( arenaID)
    boolInClosedCombat = true
    closeCombat= {arenaID = arenaID}
end

function showFireArm()
	if not boolInClosedCombat then
		Show(Gun)
	end
end

function externalAimFunction(targetPosWorldT, remainderRotation)
    showFireArm()
    Turn(Torso,y_axis, -remainderRotation, 55)
    setOverrideAnimationState(eAnimState.aiming, nil,  true, nil, false)
end

function closeCombatOS()
    Sleep(5)
    oldState = 1
    setOverrideAnimationState(eAnimState.fighting, eAnimState.walking, true, nil, function() return boolInClosedCombat end,    false)  
    while true do
        if boolInClosedCombat == true then
             Hide(backpack)
             Hide(Pistol)
             Hide(Gun)
             Hide(FoldtopFolded)
             Hide(FoldtopUnfolded)
            while(doesUnitExistAlive(closeCombat.arenaID))do
                newState = math.random(1,3) 
                StartThread(PlayAnimation, "FIGHTING", lowerBodyPieces,1.0)
                    if oldState~= newState then
                        PlayAnimation("WALKCYCLE_RUNNING", upperBodyPieces,1.0)
                    else 
                        if maRa() then               
                            PlayAnimation("WALKCYCLE_WALK", upperBodyPieces,1.0)
                        else
                            PlayAnimation("UPBODY_STANDING_PISTOL", upperBodyPieces,1.0)
                        end
                    end
                oldState = newState
                Sleep(20)
            end
            boolInClosedCombat = false 
        end
    Sleep(1000)
    end
end

local boolWalking = false
local boolTurning = false
local boolTurnLeft = false
local boolDecoupled = false
local boolFlying = false
local boolAiming = false
local boolIsBuilding = false
if not GG.OperativesDiscovered then GG.OperativesDiscovered = {} end

function showBody()
	showT(upperBodyPieces)
	showT(lowerBodyPieces)
	Show(FoldtopFolded)
	showT(shownPieces)
end

shownPieces={}

function script.Create()
	--Spring.Echo("Operative Propagator spawned")
	makeWeaponsTable()
	GG.OperativesDiscovered[unitID] = nil

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	hideAll(unitID)
	shownPieces = randShowHide(unpack(TablesOfPiecesGroups["HeadDeco"]))
	showBody()
	setupAnimation()
    Show(FoldtopUnfolded)
	StartThread(flyingMonitored)
	StartThread(turnDetector)

	
	setOverrideAnimationState( eAnimState.slaved, eAnimState.standing,  true, nil, false)

    StartThread(threadStarter)
	StartThread(cloakLoop)
    StartThread(closeCombatOS)

    StartThread(breathing)
    StartThread(transportControl)
    StartThread(cloakIfAIPlayer)
    StartThread(testAnimation)
end

function testAnimation()
	if isInvestigator then return end
    Sleep(500)
  
    while true do
       -- PlayAnimation("WALKCYCLE_RUNNING", {}, 1.0)

    	Sleep(1000)
    end
end

function cloakIfAIPlayer()
   nteamID, leader, isDead, isAiTeam, side, allyTeam, incomeMultiplier, customTeamKeys = Spring.GetTeamInfo(myTeamID)

   if isAiTeam and isAiTeam == true then
        while true do
            Sleep(1000)
            if boolIsBuilding == false and boolInClosedCombat == false then
                if spGetUnitIsCloaked(unitID) == false then
                    setWantCloak(true)
                end
            end
        end
    end
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
        	transporterdefID = spGetUnitDefID(Spring.GetUnitTransporter(unitID))

        	if  motorBikeTypeTable[transporterdefID] then boolTransportedNoFiring = true end

            setOverrideAnimationState(eAnimState.slaved, eAnimState.riding, true, nil, function() return isTransported(unitID) end,    false)     
	           
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


function checkFirstUnit()
	if not GG.FirstUnitperTeamTable then GG.FirstUnitperTeamTable ={} end
	if not GG.FirstUnitperTeamTable[myTeamID]  then GG.FirstUnitperTeamTable[myTeamID] = unitID else return end

	x,y,z= Spring.GetUnitPosition(unitID)
	Sleep(1)
	giveParachutToUnit(unitID,x,y+GameConfig.OperativeDropHeigthOffset, z)
	setWantCloak(false)

    times = 0
    PIE = 3.14159 / 60
    med = 0
    while true do
        times = (times + PIE) % 6.28318530
        val = math.ceil(((math.sin(times) * GameConfig.bonusFirstUnitMoney_S) + med) / 2)
        med = val
        if val > 0 then
            Spring.AddUnitResource(unitID, "m", val)
            Spring.AddUnitResource(unitID, "e", val)
        else
            val = math.abs(val)
            Spring.UseUnitResource(unitID, "m", val)
            Spring.UseUnitResource(unitID, "e", val)
        end
        Sleep(1001)
    end
end

--gives the first unit of this type a parachut and drops it
function flyingMonitored()
	StartThread(checkFirstUnit)

	while true do
		boolFlying, posH, groundH = isUnitFlying(unitID)
		if boolFlying == true then
			while(boolFlying == true) do
				Sleep(100)
				boolFlying, posH, groundH = isUnitFlying(unitID)
				if (posH  < groundH + 150 ) then
					PlayAnimation("PARACHUTE_POSE", {}, 5.0)
				else
					flyingPose(unitID)
				end
			end
			WaitForTurns(TablesOfPiecesGroups)
			reset(center)
            PlayAnimation("UPBODY_STANDING_PISTOL", {}, 2.0)
            setOverrideAnimationState(eAnimState.standing, eAnimState.standing,  true, nil, true)
		end
		Sleep(100)
	end
end

function breathing()
	local breathSpeed= 0.1/3
	while true do
		if boolAiming == false and boolWalking == false and boolFlying == false then
			Turn(Head,x_axis,math.rad(-1),breathSpeed)
			WTurn(Torso,x_axis, math.rad(1), breathSpeed)
			Turn(Head,x_axis,math.rad(0),breathSpeed)
			WTurn(Torso,x_axis, math.rad(0), breathSpeed)
			rx,ry,rz = math.random(-40,40)/10, math.random(-40,40)/10, math.random(-40,40)/10
			tP(Eye1,rx,ry,rz, 16)
			tP(Eye2,rx,ry,rz, 16)
            tP(Head,0,math.random(-20,20),0, 2)
		end
		Sleep(250)
	end
end

function script.Killed(recentDamage, _)
	if doesUnitExistAlive(civilianID) == true then
		Spring.DestroyUnit(civilianID,true,true) 
	end
	PlayAnimation("DEATH")
   return 1
end

local	locAnimationstateUpperOverride 
local	locAnimationstateLowerOverride
local	locBoolInstantOverride 
local	locConditionFunction
local	boolStartThread = false
boolPistol = true

uppperBodyAnimations = { 
    [eAnimState.fighting] = {
        [1] = "FIGHTING",
    },
	[eAnimState.idle] = { 	
		[1] = "UPBODY_STANDING_GUN",
		[2] = "UPBODY_STANDING_PISTOL"
	},
	[eAnimState.aiming] = { 	
		[1] = "UPBODY_AIMING"
	},
	[eAnimState.walking] =  { 
		[1]="SLAVED"
	},
		
	[eAnimState.standing] =  { 	
		[1] = "UPBODY_STANDING_GUN",
		[2] = "UPBODY_STANDING_PISTOL"
	},
}


lowerBodyAnimations = {
	[eAnimState.riding] = {[1]= "FULLBODY_RIDING"},
	[eAnimState.walking] = {
		[1]="WALKCYCLE_RUNNING"
	},
	[eAnimState.standing] =  { 	
		[1] = "UPBODY_STANDING_GUN"
	},
	[eAnimState.aiming] =  { 	
		[1] = "UPBODY_STANDING_GUN"
	
	},
}


local animCmd = { ['turn'] = Turn, ['move'] = Move };

function setupAnimation()
    local map = Spring.GetUnitPieceMap(unitID);
	local switchAxis = function(axis) 
		if axis == z_axis then return y_axis end
		if axis == y_axis then return z_axis end
		return axis
	end

    local offsets = constructSkeleton(unitID, center, {0,0,0});
    
    for a,anim in pairs(Animations) do
        for i,keyframe in pairs(anim) do
        	if type(keyframe) == "number" then echo("animation ".. a.."has no keyframes") end
            local commands = keyframe.commands;
            for k,command in pairs(commands) do
				if command.p and type(command.p)== "string" then
					command.p = map[command.p]
				end
				
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                if (command.c == "move") then
                    local adjusted =  command.t - (offsets[command.p][command.a]);
                    Animations[a][i]['commands'][k].t = command.t - (offsets[command.p][command.a]);
                end
			   
               --if isInvestigator then
			     Animations[a][i]['commands'][k].a = switchAxis(command.a)	
               --end
            end
        end
    end
end

local animCmd = {['turn']=Turn,['move']=Move};



function PlayAnimation(animname, piecesToFilterOutTable, speed)
	local speedFactor = speed or 1.0
	if not piecesToFilterOutTable then piecesToFilterOutTable ={} end
	assert(animname, "animation name is nil")
    assert(type(animname)=="string", "Animname is not string "..toString(animname))
	assert(Animations[animname], "No animation with name "..animname)
    local anim = Animations[animname];
	local randoffset 
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1,#commands do
            local cmd = commands[j];
			randoffset = 0.0
			if cmd.r then
				randVal = cmd.r* 100
				randoffset = math.random(-randVal, randVal)/100
			end
			
			if cmd.ru or cmd.rl then
				randUpVal=	( cmd.ru or 0.01)*100
				randLowVal=	( cmd.rl or 0	)*100
				randoffset = math.random(randLowVal, randUpVal)/100
			end
			assert(cmd.p, animname..j)
			if  not piecesToFilterOutTable[cmd.p] then	
				animCmd[cmd.c](cmd.p, cmd.a, axisSign[cmd.a] * ((cmd.t or 0) + randoffset) ,cmd.s*speedFactor)	
			end
        end
        if(i < #anim) then
            local t = anim[i+1]['time'] - anim[i]['time'];
            Sleep(t*33* math.abs(1/speedFactor)); -- sleep works on milliseconds
        end
    end
end

function constructSkeleton(unit, piece, offset)
    if (offset == nil) then
        offset = { 0, 0, 0 };
    end

    local bones = {};
    local info = Spring.GetUnitPieceInfo(unit, piece);

    for i = 1, 3 do
        info.offset[i] = offset[i] + info.offset[i];
    end

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

function threadStarter()
	Sleep(100)
	while true do
		if boolStartThread == true then
			boolStartThread = false
			StartThread(deferedOverrideAnimationState, locAnimationstateUpperOverride, locAnimationstateLowerOverride, locBoolInstantOverride, locConditionFunction)
			while boolStartThread == false do
				Sleep(33)
			end
		end
		Sleep(33)
	end
end


function deferedOverrideAnimationState( AnimationstateUpperOverride, AnimationstateLowerOverride, boolInstantOverride, conditionFunction)
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
		StartThread(setAnimationState, AnimationstateUpperOverride, AnimationstateLowerOverride)
	end
	
	if conditionFunction then StartThread(conditionFunction) end
end

function setAnimationState(AnimationstateUpperOverride, AnimationstateLowerOverride)
	-- if we are already animating correctly early out
	if AnimationstateUpperOverride == UpperAnimationState and AnimationstateLowerOverride == LowerAnimationState then return end

	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)

		if AnimationstateUpperOverride then	boolUpperStateWaitForEnd = true end
		if AnimationstateLowerOverride then boolLowerStateWaitForEnd = true end
		
		
		 while AnimationstateLowerOverride and boolLowerAnimationEnded == false or AnimationstateUpperOverride and boolUpperAnimationEnded == false do
		 Sleep(30)
			if AnimationstateUpperOverride == true then
				boolUpperStateWaitForEnd = true
			end
			 
			if AnimationstateLowerOverride == true then		
				boolLowerStateWaitForEnd = true
			end

			Sleep(30)
		 end
			 
		if AnimationstateUpperOverride then	UpperAnimationState = AnimationstateUpperOverride end
		if AnimationstateLowerOverride then LowerAnimationState = AnimationstateLowerOverride end
		if boolUpperStateWaitForEnd == true then	boolUpperStateWaitForEnd = false end
		if boolLowerStateWaitForEnd == true then boolLowerStateWaitForEnd = false end
end

--<Exposed Function>

function setOverrideAnimationState( AnimationstateUpperOverride, AnimationstateLowerOverride,  boolInstantOverride, conditionFunction, boolDecoupledStates)
	boolDecoupled = boolDecoupledStates
	locAnimationstateUpperOverride =AnimationstateUpperOverride
	locAnimationstateLowerOverride = AnimationstateLowerOverride
	locBoolInstantOverride = boolInstantOverride or false
	locConditionFunction = conditionFunction or (function() return true end)
	boolStartThread = true
end

--</Exposed Function>
function conditionalFilterOutUpperBodyTable()
	if boolDecoupled == false  then 
		return {}
	 else
		return upperBodyPieces
	end
end


leftArmPosesPropagatorT ={
{
	UpArm2 ={math.rad(math.random(-15,5)),math.rad(math.random(0,5)*randSign()),math.rad(math.random(0,5)*randSign())},
	LowArm2 ={math.rad(math.random(-15,5)),math.rad(math.random(0,5)*randSign()),math.rad(math.random(0,5)*randSign())},
	Hand2 ={0,0, 0},
},
{
	UpArm2 ={math.rad(math.random(-15,5)),math.rad(math.random(0,5)*randSign()),math.rad(math.random(0,5)*randSign())},
	LowArm2 ={math.rad(math.random(-15,5)),math.rad(math.random(0,5)*randSign()),math.rad(math.random(0,5)*randSign())},
	Hand2 ={0,0, 0},
},
{
	UpArm2 ={math.rad(math.random(-15,5)),math.rad(math.random(0,5)*randSign()),math.rad(math.random(0,5)*randSign())},
	LowArm2 ={math.rad(math.random(-15,5)),math.rad(math.random(0,5)*randSign()),math.rad(math.random(0,5)*randSign())},
	Hand2 ={0,0, 0},
},
}

leftArmPosesInvestigatorT ={
{
	UpArm2 ={0,0, 35},
	LowArm2 ={0,0, 0},
	Hand2 ={0,0, 0},
},
{
	UpArm2 ={0,0, 35},
	LowArm2 ={math.random(10,35), 0, 0},
	Hand2 ={0,0, 0},
},
{
	UpArm2 ={25,0, 40},
	LowArm2 ={160, 0, 0},
	Hand2 ={0,0, 0},
},
{
	UpArm2 ={-130	,220, 140},
	LowArm2 ={90, 0	, 180},
	Hand2 ={0,0, 0},
},
{
	UpArm2 ={-45,0, 40},
	LowArm2 ={0, 180	, 0},
	Hand2 ={0,0, 0},
}



}


function leftArmPoses()
	pose = nil
	if isInvestigator then
		pose= leftArmPosesInvestigatorT[math.random(1,#leftArmPosesInvestigatorT)]
	else
		pose= leftArmPosesPropagatorT[math.random(1,#leftArmPosesPropagatorT)]
	end

	Turn(UpArm2, x_axis, math.rad(pose.UpArm2[1] + math.random(-5,5)),10)
	Turn(UpArm2, y_axis, math.rad(pose.UpArm2[2] + math.random(-5,5)),10)
	Turn(UpArm2, z_axis, math.rad(pose.UpArm2[3] + math.random(-5,5)),10) 
  
 	Turn(LowArm2, x_axis, math.rad(pose.LowArm2[1] + math.random(-5,5)),10)
	Turn(LowArm2, y_axis, math.rad(pose.LowArm2[2] + math.random(-5,5)),10)
	Turn(LowArm2, z_axis, math.rad(pose.LowArm2[3] + math.random(-5,5)),10)

	Turn(Hand2, x_axis, math.rad(pose.Hand2[1] + math.random(-5,5)),10)
	Turn(Hand2, y_axis, math.rad(pose.Hand2[2] + math.random(-5,5)),10)
	Turn(Hand2, z_axis, math.rad(pose.Hand2[3] + math.random(-5,5)),10)

	WaitForTurns(UpArm2,LowArm2, Hand2)
end

function playUpperBodyIdleAnimation()
		selectedIdleFunction = math.random(1,#uppperBodyAnimations[eAnimState.idle])
		PlayAnimation(uppperBodyAnimations[eAnimState.idle][selectedIdleFunction], lowerBodyPieces, math.random(1,5)/2.5)	
end


UpperAnimationStateFunctions ={
  [eAnimState.fighting] = function()
                    PlayAnimation("FIGHTING", lowerBodyPieces, 1.0)

                    if boolInClosedCombat then
                        return eAnimState.fighting
                    else
                        return eAnimState.standing
                    end
                end,
[eAnimState.standing] = 	function () 
								--echo("Idling")
								if boolFlying == true then 	 return eAnimState.standing end

								resetT(lowerBodyPieces, 10)
								boolDecoupled = true
								while not boolAiming and not boolWalking and not boolFlying do			
									playUpperBodyIdleAnimation()		
									if maRa()== true then leftArmPoses() end
									Sleep(30)
								end
						
								Sleep(30)	
								return eAnimState.standing
							end,
[eAnimState.walking] = 	function () 
								if boolFlying == true then return eAnimState.walking end
								boolDecoupled = true
								
								boolDecoupled = false
				
						return eAnimState.walking
					end,
[eAnimState.slaved] = 	function () 
						Sleep(100)
						return eAnimState.slaved
					end,
[eAnimState.aiming] = 	function () 
						Hide(FoldtopUnfolded)
						Show(FoldtopFolded)
						if boolPistol == true and isInvestigator then
							PlayAnimation("UPBODY_AIM_PISTOL")
						else	
							PlayAnimation("UPBODY_AIMING", nil, 3.0)
						end
						Sleep(100)
						return eAnimState.aiming 
					end
} 

LowerAnimationStateFunctions ={
 [eAnimState.riding] = 			function()
						PlayAnimation(randT(lowerBodyAnimations[eAnimState.riding]), {})
					 
						return eAnimState.riding
					end,
[eAnimState.walking] = function()
						if boolFlying == true then return eAnimState.walking end
						if not boolAiming then reset(center, 1.3, false) end
						PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]))					
						return eAnimState.walking
						end,
[eAnimState.standing] = 	function () 
						if boolFlying == true then return eAnimState.standing end

						resetT(lowerBodyPieces, 12)
						Sleep(100)
						return eAnimState.standing
					end,
[eAnimState.aiming] = 	function () 
						AimDelay=AimDelay+100
						if boolWalking == true  or AimDelay < 1000 then
							AimDelay=0	
							PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]),upperBodyPieces)	
						elseif AimDelay > 1000 then		

							PlayAnimation(randT(lowerBodyAnimations[eAnimState.standing]),upperBodyPieces)	
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
		assert(animationTable[LowerAnimationState], "Animationstate not existing "..LowerAnimationState)
		LowerAnimationState = animationTable[LowerAnimationState]()
		
		--Sync Animations
		--echoNFrames("Unit "..unitID.." :LStatMach :"..LowerAnimationState, 500)
		if boolLowerStateWaitForEnd == true then
			boolLowerAnimationEnded = true
			while boolLowerStateWaitForEnd == true do
				Sleep(33)
				--echoNFrames("Unit "..unitID.." :LWaitForEnd :"..LowerAnimationState, 500)
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
		assert(animationTable[UpperAnimationState], "Upper Animationstate not existing "..UpperAnimationState)

		UpperAnimationState = animationTable[UpperAnimationState]()
		--echoNFrames("Unit "..unitID.." :UStatMach :"..UpperAnimationState, 500)
		--Sync Animations
		if boolUpperStateWaitForEnd == true then
			boolUpperAnimationEnded = true
			while boolUpperStateWaitForEnd == true do
				Sleep(10)
			end
			boolUpperAnimationEnded = false
		end
	Sleep(33)
	end

end

function delayedStop()
    Turn(center,x_axis, math.rad(-5), 1)
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP) 
	Sleep(50)
	if not GG.OperativeTurnTable then GG.OperativeTurnTable = {} end
	GG.OperativeTurnTable[unitID] = nil
    for _,part in pairs (lowerBodyPieces) do
        reset(part, 10)
    end
    Sleep(200)


	boolWalking = false
	-- Spring.Echo("Stopping")
    Turn(center,x_axis, math.rad(0), 1)
    showFoldLaptop(true)
	setOverrideAnimationState(eAnimState.standing, eAnimState.standing,  true, nil, true)
end

function showFoldLaptop(boolUnfold)
	if boolUnfold == true then
		Sleep(2500)
        Hide(FoldtopFolded)
		Show(FoldtopUnfolded)
	else
        Hide(FoldtopUnfolded)
		Show(FoldtopFolded)
	end
end

function script.StartMoving()
	Hide(Gun)
	boolWalking = true
	showFoldLaptop(false)
	Turn(center,y_axis, math.rad(0), 12)
    Turn(center, x_axis, math.rad(2.5), 12)
	setOverrideAnimationState(eAnimState.slaved, eAnimState.walking,  true, nil, false)
end

function script.StopMoving()
	StartThread(delayedStop)
end

local civilianID 

function spawnDecoyCivilian()
--spawnDecoyCivilian
		Sleep(10)	
		if civilianID ~= nil and doesUnitExistAlive(civilianID) == true then return end

		x,y,z= Spring.GetUnitPosition(unitID)
		civilianID = Spring.CreateUnit(disguiseDefID, x + randSign()*5 , y, z+ randSign()*5 , 1, Spring.GetGaiaTeamID())

		--Spring.SetUnitNoSelect(civilianID, true)
		Spring.SetUnitAlwaysVisible(civilianID, true)
	
		persPack = {myID= civilianID, syncedID= unitID, startFrame = Spring.GetGameFrame()+1 }
		if not GG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end
		GG.DisguiseCivilianFor[civilianID]= unitID
		if not GG.DiedPeacefully then GG.DiedPeacefully ={} end
		GG.DiedPeacefully[civilianID] = false
				
		if civilianID then
            transferUnitStatusToUnit(unitID, civilianID)
			GG.EventStream:CreateEvent(
			syncDecoyToAgent,
			persPack,
			Spring.GetGameFrame()+1
			)
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
function transitionToUncloaked()
	setSpeedEnv(unitID, 1.0)
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
		Spring.UnitScript.SetUnitValue(COB.WANT_CLOAK, 1)
	else
		Spring.UnitScript.SetUnitValue(COB.WANT_CLOAK, 0)
	end
end

function transitionToCloaked()
	setWantCloak(true)
	setSpeedEnv(unitID, mySpeedReductionCloaked)
	myCollideData = setNoneCollide(unitId)
	StartThread(spawnDecoyCivilian)
	return "cloaked"
end

function OperativesDiscovered()
	if  GG.OperativesDiscovered == nil then
	 return false 
	end

	if  GG.OperativesDiscovered[unitID] == nil then 
		return false 
	elseif  type(GG.OperativesDiscovered[unitID]) == "boolean" then
		return GG.OperativesDiscovered[unitID]
	end

return false
end

local currentCloakState = "decloaked"
previousState = currentCloakState
boolRecloakOnceDone = false
function cloakLoop()
	local cloakStateMachine = {
	["cloaked"] = function (boolCloakRequest,  boolPreviouslyCloaked, visibleForced)
					boolCloakRequest = getWantCloak()
					boolVisiblyForced =  (boolIsBuilding == true) or (boolFireForcedVisible == true) or (not OperativesDiscovered()  == false) 
					boolPreviouslyCloaked = (previousState == "cloaked")


					if not boolVisiblyForced == false then
						boolRecloakOnceDone= true
						return transitionToUncloaked()
					end	

					if (not boolCloakRequest == true  ) then
						return transitionToUncloaked()
					end		

                    if boolInClosedCombat == true then 
                        return transitionToUncloaked()
                    end

		return  "cloaked"
		end,
	["decloaked"] = function () 
					boolCloakRequest = getWantCloak()
					boolVisiblyForced =  (boolIsBuilding == true) or (boolFireForcedVisible == true) or (not OperativesDiscovered()  == false) 
					boolPreviouslyCloaked = (previousState == "cloaked")
			
					if not boolVisiblyForced == true and boolRecloakOnceDone == true then
						boolRecloakOnceDone = false
						return 	transitionToCloaked()
					end

					if not boolCloakRequest == false  then 
						return transitionToCloaked()
					end

                    if not boolVisiblyForced == false then
                        return "decloaked"
                    end

					if boolPreviouslyCloaked  == true and boolCloakRequest == false then
						return "decloaked"
					end

					if boolCloakRequest == true and boolVisiblyForced == true then
						return "decloaked"
					end

				return "decloaked"
				end
	}
	
	Sleep(100)
	setSpeedEnv(unitID, 1.0)
	waitTillComplete(unitID)	
	--initialisation
	showHideIcon(false)

	while true do  
		currentCloakState = cloakStateMachine[currentCloakState]()
		--if currentCloakState ~= previousState then echoState() end
		previousState = currentCloakState
		Sleep(100)
	end
end

function echoState()
	echo("============================================")
	echo("State: "..currentCloakState)
	echo("boolCloakRequest: ".. toString(getWantCloak()))
	echo("boolIsBuilding: "..toString(boolIsBuilding))
	echo("boolFireForcedVisible: "..toString(boolFireForcedVisible))
	echo("boolPreviouslyCloaked: "..toString( (previousState == "cloaked")))
	echo("============================================")
end

function script.Activate()
	-- echo("Activate")
	-- SetUnitValue(COB.WANT_CLOAK, 1)
	return 1
end

function script.Deactivate()
-- echo("Dectivate")
	-- SetUnitValue(COB.WANT_CLOAK, 0)
    return 0
end

function script.QueryBuildInfo()
    return center
end

function delayedStopBuilding()
	Signal(SIG_DELAYEDRECLOAK)
	SetSignalMask(SIG_DELAYEDRECLOAK)
	Sleep(1500)
	boolIsBuilding = false
	--echo("Stop Building")
	SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.StopBuilding()
	StartThread(delayedStopBuilding)

end

function script.StartBuilding(heading, pitch)
	boolIsBuilding = true
	SetUnitValue(COB.INBUILDSTANCE, 1)
    Signal(SIG_DELAYEDRECLOAK)
--	echo("Starting Building")
end

Spring.SetUnitNanoPieces(unitID, { Pistol })

function aimAutoReset()
	boolAiming = true
	Show(Gun)
	SetSignalMask(SIG_AIM)
	Signal(SIG_AIM)
	Sleep(100)
	boolAiming = false

end

function raidAimFunction(weaponID, heading, pitch, targetType, isUserTarget, targetID)
	if targetType == "u" and targetID then
		defID = spGetUnitDefID(targetID)
		if 	houseTypeTable[defID] and 
			GG.houseHasSafeHouseTable[targetID] and 
			spGetUnitTeam(GG.houseHasSafeHouseTable[targetID]) == myTeamID then
			-- if the civilianhouse contains a safehouse of our own team then
			return false
		end
	end
	return  currentCloakState == "decloaked"
end

function pistolAimFunction(weaponID, heading, pitch, targetType, isUserTarget, targetID)
	StartThread(aimAutoReset)
    if boolWalking == true then
	   setOverrideAnimationState(eAnimState.aiming, eAnimState.walking,  true, nil, false)
    else
        setOverrideAnimationState(eAnimState.aiming, eAnimState.standing,  true, nil, false)
    end
    if isInvestigator then
		WTurn(center, y_axis,heading, 22)
	else
		WTurn(center, z_axis,heading, 22)
	end
	WaitForTurns(UpArm1, UpArm2, LowArm1,LowArm2)
	-- echo("Aiming Pistol finnished")
	return  true
end

boolFireForcedVisible= false
function visibleAfterWeaponsFireTimer()
	boolFireForcedVisible = true
	Signal(SIG_FIRE_VISIBLITY)
	SetSignalMask(SIG_FIRE_VISIBLITY)	
	value= GameConfig.operativeShotFiredWaitTimeToRecloak_MS
	Sleep(value)
	boolFireForcedVisible = false
end

function delayedFlashBang( )
	Sleep(5000)
	Spring.PlaySoundFile("sounds/weapons/raid/flashbang.ogg", 1.0)
end
function raidFireFunction(weaponID, heading, pitch)
	StartThread(visibleAfterWeaponsFireTimer)
	StartThread(delayedFlashBang)
	StartThread(showDroneHovering)
	return true
end

function pistolFireFunction(weaponID, heading, pitch)
	StartThread(visibleAfterWeaponsFireTimer)
	boolAiming = false
	if boolCloaked == true then
        Spring.PlaySoundFile("sounds/weapons/pistol/stealthpistol.ogg", 1.0)
    else
        Spring.PlaySoundFile("sounds/weapons/pistol/pistolshot"..math.random(1,3)..".ogg", 1.0)
    end
	--Explode(Shell1, SFX.FALL + SFX.NO_HEATCLOUD)
	return true
end

function stabFireFunction(weaponID)
    boolAiming = false
    return true
end

function stabAimFunction(weaponID, heading, pitch)
    StartThread(aimAutoReset)
    return true
end

WeaponsTable = {}
function makeWeaponsTable()
    WeaponsTable[1] = { aimpiece = Drone, emitpiece = Drone, aimfunc = raidAimFunction, firefunc = raidFireFunction, signal = SIG_RAID }
	WeaponsTable[2] = { aimpiece = Pistol, emitpiece = Pistol, aimfunc = pistolAimFunction, firefunc = pistolFireFunction, signal = SIG_PISTOL }
	WeaponsTable[3] = { aimpiece = Pistol, emitpiece = Pistol, aimfunc = stabAimFunction, firefunc = stabFireFunction, signal = SIG_STAB }
end

function script.AimFromWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].aimpiece
    else
        return center
    end
end

function script.QueryWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].emitpiece
    else
        return center
    end
end

local validTargetType={
	[1]=true,
	[2]=true,
}

function script.FireWeapon(weaponID)
	return WeaponsTable[weaponID].firefunc(weaponID, heading, pitch)
end

boolInterrogated = false
function setBoolInterrogatedExternally(boolInterrogatedExternally)
	boolInterrogated = boolInterrogatedExternally
end
drone = piece("Drone")
policeLineDoNotCross = piece("DroneSpin")
boolAlreadyHasRaidDrones = false
function showDroneHovering()
	if boolAlreadyHasRaidDrones then return end
	boolAlreadyHasRaidDrones= true
	Move(drone, y_axis, 250, 0)
	Show(drone)
	Move(drone, y_axis, 0, 250)
	Spin(policeLineDoNotCross, y_axis, math.random(15)*randSign(), 0)
	Show(policeLineDoNotCross)
	showT(TablesOfPiecesGroups["WarnCone"])
	while (not boolMoving and not boolCloaked) do
		for axis=1,3 do
			Move(drone,axis, math.random(1,3)*randSign())
		end
		Sleep(1000)
	end
	Hide(policeLineDoNotCross)
	hideT(TablesOfPiecesGroups["WarnCone"])
	Move(drone, y_axis, 250, 900)
	Sleep(3000)
	Hide(drone)
	boolAlreadyHasRaidDrones = false
end

function script.AimWeapon(weaponID, heading, pitch)
	if boolInClosedCombat == true then return false end

    if weaponID == 3 and not boolInterrogated then --closecombat
        --Spring.Echo("weaponAim:"..weaponID.." targetType"..targetType)
        return true
    end    

	targetType,  isUserTarget, targetID = spGetUnitWeaponTarget(unitID, weaponID)

	if not targetType or  (not validTargetType[targetType])  then
			-- echo("Not a valid target "..weaponID)
			return false 
	end
	
	--Do not aim at your own disguise civilian
	if targetType == 1 and spGetUnitTeam(targetID) == gaiaTeamID then		
		if GG.DisguiseCivilianFor[targetID] and GG.DisguiseCivilianFor[targetID] == unitID then	
            -- echo("Aiming at disguised civilian ")
			return false
		end
	end		

    if WeaponsTable[weaponID] then
        if WeaponsTable[weaponID].aimfunc then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch, targetType, isUserTarget, targetID) and not boolInterrogated
        else
            WTurn(WeaponsTable[weaponID].aimpiece, y_axis, heading, turretSpeed)
            WTurn(WeaponsTable[weaponID].aimpiece, x_axis, -pitch, turretSpeed)
            return not boolInterrogated 
        end
    end

    return false
end

function showHideIcon(boolShowIcon)
    if  boolShowIcon == true then
        hideAll(unitID)
        Show(Icon)
    else
    	showBody()
		Hide(Drone)
		hideT(TablesOfPiecesGroups["Shell"])			
		Show(FoldtopUnfolded)
		Hide(FoldtopFolded)
		if TablesOfPiecesGroups["Jacket"] then
			if unitId % 3== 0 then 
				showT(TablesOfPiecesGroups["Jacket"])
			end
		end
        Hide(Icon)
    end
end


