include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
local Animations = include('animations_civilian_female.lua')
include "lib_mosaic.lua"
myDefID=Spring.GetUnitDefID(unitID)
TablesOfPiecesGroups = {}

SIG_ANIM = 1
SIG_UP = 2
SIG_LOW = 4
SIG_COVER_WALK= 8
SIG_BEHAVIOUR_STATE_MACHINE = 16

SIG_PISTOL = 32
local center = piece('center');
local Feet1 = piece('Feet1');
local Feet2 = piece('Feet2');
local Head1 = piece('Head1');
local LowArm1 = piece('LowArm1');
local LowArm2 = piece('LowArm2');
local LowLeg1 = piece('LowLeg1');
local LowLeg2 = piece('LowLeg2');
local trolley = piece('trolley');
local root = piece('root');
local UpArm1 = piece('UpArm1');
local UpArm2 = piece('UpArm2');
local UpBody = piece('UpBody');
local UpLeg1 = piece('UpLeg1');
local UpLeg2 = piece('UpLeg2');
local cigarett = piece('cigarett');
local Handbag = piece('Handbag');
local SittingBaby = piece('SittingBaby');
local ak47		= piece('ak47')
local cofee = piece('cofee');
local ProtestSign = piece"ProtestSign"
local cellphone1 = piece"cellphone1"
local cellphone2 = piece"cellphone2"
local molotow = piece"molotow"
local ShoppingBag = piece"ShoppingBag"


local scriptEnv = {
	Handbag = Handbag,
	trolley = trolley,
	SittingBaby = SittingBaby,
	center = center,
	Feet1 = Feet1,
	Feet2 = Feet2,
	Head1 = Head1,
	LowArm1 = LowArm1,
	LowArm2 = LowArm2,
	LowLeg1 = LowLeg1,
	LowLeg2 = LowLeg2,
	cigarett = cigarett,
	cofee = cofee,
	root = root,
	UpArm1 = UpArm1,
	UpArm2 = UpArm2,
	UpBody = UpBody,
	UpLeg1 = UpLeg1,
	UpLeg2 = UpLeg2,
	x_axis = x_axis,
	y_axis = y_axis,
	z_axis = z_axis,
}

local spGetUnitTeam = Spring.GetUnitTeam
local myTeamID = spGetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget 
local loc_doesUnitExistAlive = doesUnitExistAlive


GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)
	
eAnimState = getCivilianAnimationStates()
upperBodyPieces =
{
	[Head1	]  = Head1,
	[LowArm1 ] = LowArm1,
	[LowArm2]  = LowArm2,
	[UpBody  ]	= UpBody,
	[UpArm1 ]= UpArm1,
	[UpArm2 ]= UpArm2,
	}
	
lowerBodyPieces =
{
	[center	]= center,
	[UpLeg1	]= UpLeg1,
	[UpLeg2 ]= UpLeg2,
	[LowLeg1]= LowLeg1,
	[LowLeg2]= LowLeg2,
	[Feet1 	]= Feet1,
	[Feet2	]= Feet2
}

lowerBodyPiecesNoCenter =
{
	[UpLeg1	]= UpLeg1,
	[UpLeg2 ]= UpLeg2,
	[LowLeg1]= LowLeg1,
	[LowLeg2]= LowLeg2,
	[Feet1 	]= Feet1,
	[Feet2	]= Feet2
}

catatonicBodyPieces = lowerBodyPieces
catatonicBodyPieces[UpBody] = UpBody
--equipmentname: cellphone, shoppingbags, crates, baby, cigarett, food, stick, demonstrator sign, molotow cocktail



boolWalking = false
boolTurning = false
boolTurnLeft = false
boolDecoupled = false
boolAiming = false

loadMax = 8

local bodyConfig={}

	iShoppingConfig = math.random(0,8)
	function variousBodyConfigs()
		
		bodyConfig.boolShoppingLoaded = (iShoppingConfig <= 1)
		bodyConfig.boolCarrysBaby =( iShoppingConfig == 2)
		bodyConfig.boolTrolley = (iShoppingConfig == 3)
		bodyConfig.boolHandbag =( iShoppingConfig == 4)
		bodyConfig.boolLoaded = ( iShoppingConfig <  5)
		bodyConfig.boolProtest = GG.GlobalGameState== GameConfig.GameState.anarchy
	end


boolStarted= false
function script.Create()
	makeWeaponsTable()
    Move(root,y_axis, -3,0)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(turnDetector)
	hideAll(unitID)
	variousBodyConfigs()

	bodyConfig.boolArmed = false
	bodyConfig.boolWounded = false
	bodyConfig.boolInfluenced = false
	bodyConfig.boolCoverWalk = false
	
	bodyBuild()


	setupAnimation()

	setOverrideAnimationState( eAnimState.slaved, eAnimState.standing,  true, nil, false)

	StartThread(threadStarter)
	StartThread(cloakLoop)
end


function bodyBuild()




	Show(UpBody)
	Show(center)
	showT(TablesOfPiecesGroups["UpLeg"])
	showT(TablesOfPiecesGroups["LowLeg"])
	showT(TablesOfPiecesGroups["LowArm"])
	showT(TablesOfPiecesGroups["UpArm"])
	showT(TablesOfPiecesGroups["Head"])
	showT(TablesOfPiecesGroups["Feet"])
	
	if bodyConfig.boolArmed == true  then
		Show(ak47)	
		return
	end
	
	if bodyConfig.boolLoaded == true  and bodyConfig.boolWounded == false then
	
		if iShoppingConfig == 1 then
			Show(ShoppingBag);return
		end
		
		if iShoppingConfig == 2 then
			Show(SittingBaby);return
		end
		
		if iShoppingConfig == 3 then
			Show(trolley);return
		end
		
		if iShoppingConfig == 4 then
			Show(Handbag);return
		end
	end
end



---------------------------------------------------------------------ANIMATIONLIB-------------------------------------



---------------------------------------------------------------------ANIMATIONLIB-------------------------------------
---------------------------------------------------------------------ANIMATIONS-------------------------------------
-- +STOPED+---------------------------------------------------+    +----------------------------+
-- |                                                          |    |Aiming/Assaultanimation:    |
-- |  +--------------+         +----------------------------+ |    |Stick                       |
-- |  |Transfer Pose |         |Idle Animations:            | |    |Molotowcocktail             |
-- |  +--------+----++         |talk Cycle, debate-intensity| |    |Fist                        |
-- |           ^    ^          |stand alone idle:           | |    |                            |
-- |           |    |          |cellphone,                  | |    |                            |
-- |           |    |          |smoking, squatting          | |    |                            |
-- |           |    +--------->+prayer                      | |    |                            |
-- |           |    |          |sleep on street             | |    |                            |
-- |           |    |          +----------------------------+ |    +----------------------------+
-- |           |    |          +----------------------------+ |
-- |           |    |          |   ReactionAnimation:       | |    +----------------------------+
-- |           |    |          |		   Catastrophe:     | |    | Hit-Animation              |
-- |           |    |          |		     filming        | |    |touch Wound/ hold wound		|
-- |           |    +--------->+		     whailing       | |    |	                        |
-- |           |    |          |		     Protesting     | |    |                            |
-- |           |    |          +----------------------------+ |    |                            |
-- |           |    |          +-------------------------+    |    |                            |
-- |           |    +----------> Hit Animation           |    |    |                            |
-- |           |               | touch Wound/ hold wound |    |    +----------------------------+
-- +----------------------------------------------------------+
-- +-Walking+-------------------------------------------------+  +-------------------------------------+
-- |           v                                              |  |Death Animation                      |
-- | +---------+-------------------------+                    |  |Blasteded                            |
-- | |Transfer Pose|TransferPose Wounded +<--+                |  |Swirlingng                           |
-- | +-----------------------------------+   |                |  |Suprised                             |
-- +-----------------------------------------v----------------+  Collapsing, Shivering, Coiling Up     |
-- |    Walk Animation:                                       |  |                                     |
-- |walk Cycles: Normal/ Wounded/ Carrying/ Cowering/Run      |  +-------------------------------------+
-- |-----------------------------------------------------------

-- Animation StateMachine
	-- Every Animation optimized for fast blending
	-- Health movement loops
	-- Allows for External Override
	-- AnimationStates have abort Condition
	--Animations can be diffrent depending on buildScript (State_Idle/Walk Animation loaded)
	-- Usually the Lower animation state is the master- but the upper can detach, so seperate upper Body Animations are possible



uppperBodyAnimations = {
	[eAnimState.aiming] = { 
		[1] = "UPBODY_AIMING",
	},
	[eAnimState.slaved] = { 
		[1] = "SLAVED",	
	},
	[eAnimState.idle] = { 	
		[1] = "SLAVED",
		[2] = "UPBODY_PHONE",
		[3] = "UPBODY_CONSUMPTION",
	},
	[eAnimState.filming] = {
		[1] = "UPBODY_FILMING",
		[2] = "UPBODY_PHONE",
	},
	[eAnimState.wailing] = {
		[1] = "UPBODY_WAILING1",
		[2] = "UPBODY_WAILING2",
	},
	[eAnimState.talking] = {
		[1] = "UPBODY_AGGRO_TALK",
		[2] = "UPBODY_NORMAL_TALK",
	},
	[eAnimState.walking] ={ 
		[1] = "UPBODY_LOADED",
	},
	[eAnimState.protest] ={ 
		[1] = "UPBODY_PROTEST",
	},
	[eAnimState.handsup] ={ 
		[1] = "UPBODY_HANDSUP",
	},
}


lowerBodyAnimations = {
	[eAnimState.walking] = {
		[1]="WALKCYCLE_UNLOADED"},
	[eAnimState.wounded] = {
		[1]="WALKCYCLE_WOUNDED"},		
	[eAnimState.coverwalk] = {
		[1]="WALKCYCLE_COVERWALK"},
	[eAnimState.trolley] = {
		[1]="WALKCYCLE_ROLLY"},

}

accumulatedTimeInSeconds=0
function script.HitByWeapon(x, z, weaponDefID, damage)
	attackerID =Spring.GetUnitLastAttacker(unitID)
	if attackerID and confirmUnit(attackerID) then
	process(getAllNearUnit(unitID, GameConfig.civilianPanicRadius),
			function(id)
					if Spring.GetUnitDefID(id) == myDefID and not GG.DisguiseCivilianFor[unitID] then
						runAwayFrom(id, attackerID, 500)
					end				
				end
			)
	end

	clampedDamage = math.max(math.min(damage,10),35)
	StartThread(delayedWoundedWalkAfterCover,  clampedDamage)
	accumulatedTimeInSeconds = accumulatedTimeInSeconds + clampedDamage
	bodyConfig.boolCoverWalk = true
	bodyConfig.boolLoaded = false
	bodyConfig.boolWounded = true
	bodyBuild()
	StartThread(setAnimationState,getWalkingState(), getWalkingState())
end

function delayedWoundedWalkAfterCover(timeInSeconds)
	Signal(SIG_COVER_WALK)
	SetSignalMask(SIG_COVER_WALK)
	Sleep(accumulatedTimeInSeconds *1000)
	bodyConfig.boolWounded = true
	bodyConfig.boolCoverWalk = false
end


-- Civilian
-- Props:
	-- -Abstract Female and Male Skeletton
	-- - Bags, Luggage, Crates, Trolleys, Rucksack
	-- - Cellphones, Handbags
-- Animation:
	-- Walk Animation:
	-- - walk Cycle
	-- - cowering run Cycle
	-- - run Cycle
	-- - Carrying Animation
	
	-- Idle-Animation:
		-- - talk Cycle, debate-intensity
		-- - stand alone idle: cellphone, smoking, squatting
		-- - prayer
		-- sleep on street
	-- ReactionAnimation:
		-- Catastrophe:
		-- - filming
		-- - whailing
		-- - Protesting
	-- Hit Animation:
		-- - touch Wound/ hold wound
		
	-- AttackAnimation:
		-- - punching
		-- - hitting with stick
		-- - throwing molotow cocktail
	
	-- Death Animation:
		-- - Blasted
		-- - Swirling
		-- - Suprised 
		-- -Collapsing, Shivering, Coiling Up

function setupAnimation()
    local map = Spring.GetUnitPieceMap(unitID);
	local switchAxis = function(axis) 
		if axis == z_axis then return y_axis end
		if axis == y_axis then return z_axis end
		return axis
	end

    local offsets = constructSkeleton(unitID, map.center, {0,0,0});
    
    for a,anim in pairs(Animations) do
        for i,keyframe in pairs(anim) do
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
				
			   Animations[a][i]['commands'][k].a = switchAxis(command.a)	
            end
        end
    end
end

local animCmd = {['turn']=Turn,['move']=Move};

local axisSign ={
	[x_axis]=1,
	[y_axis]=1,
	[z_axis]=1,
}

function PlayAnimation(animname, piecesToFilterOutTable, speed)
	local speedFactor = speed or 1.0
	if not piecesToFilterOutTable then piecesToFilterOutTable ={} end
	assert(animname, "animation name is nil")
assert(type(animname)=="string", "Animname is not string "..toString(animname))
	assert(Animations[animname], "No animation with name ")
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
			
			if  not piecesToFilterOutTable[cmd.p] then	
				animCmd[cmd.c](cmd.p, cmd.a, axisSign[cmd.a] * (cmd.t + randoffset) ,cmd.s*speedFactor)
				
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
        offset = {0,0,0};
    end
	
    local bones = {};

    local info = Spring.GetUnitPieceInfo(unit,piece);

    for i=1,3 do
        info.offset[i] = offset[i]+info.offset[i];
    end 

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


local	locAnimationstateUpperOverride 
local	locAnimationstateLowerOverride
local	locBoolInstantOverride 
local	locConditionFunction
local	boolStartThread = false

-- allow external behaviour statemachine to be started and stopped, and set
function setBehaviourStateMachineExternal( boolStartStateMachine, State, boolInfluenced)
	if bodyConfig.boolInfluenced == true then return end
	
	if boolStartStateMachine == true then
		StartThread(beeHaviourStateMachine, State, boolInfluenced)
	else

		Signal(SIG_BEHAVIOUR_STATE_MACHINE)
		if bodyConfig.boolArmed == true then
			Hide(ak47)
			Explode(ak47, SFX.FALL + SFX.NO_HEATCLOUD)
			bodyConfig.boolArmed = false
		end
		bodyBuild(bodyConfig)
		Command(unitID, "stop")
	end
end

AerosolTypes = getChemTrailTypes()
influencedStateMachine = {}
--getInfluencedStateMachine(UnitID, UnitDefs)

oldBehaviourState =  ""
function beeHaviourStateMachine(startState, boolInfluenced)
newState= startState
if boolInfluenced == true then
influencedStateMachine =getInfluencedStateMachine(UnitID, UnitDefs, startState)
end
bodyConfig.boolInfluenced = boolInfluenced
Signal(SIG_BEHAVIOUR_STATE_MACHINE)
SetSignalMask(SIG_BEHAVIOUR_STATE_MACHINE)

	while true do
		if bodyConfig.boolInfluenced == true then
			newState = influencedStateMachine(oldBehaviourState, newState, unitID) 
		else
			newState = normalBehavourStateMachine[newState](oldBehaviourState, newState, unitID) 
		end		
		-- Verschiedene States
		Sleep(250)
		oldBehaviourState = newState
	end
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
			-- echo(unitID.." Starting new Animation State Machien Upper")
			UpperAnimationState = AnimationstateUpperOverride
			StartThread(animationStateMachineUpper, UpperAnimationStateFunctions)
		end
		if AnimationstateLowerOverride then
			-- echo(unitID.." Starting new Animation State Machien Lower")
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
	locAnimationstateUpperOverride = AnimationstateUpperOverride
	locAnimationstateLowerOverride = AnimationstateLowerOverride
	locBoolInstantOverride = boolInstantOverride or false
	locConditionFunction = conditionFunction or (function() return true end)
	boolStartThread = true
end

--</Exposed Function>
function conditionalFilterOutUpperBodyTable()
	if boolDecoupled == true or boolAiming == true then 
		return upperBodyPieces
	 else
		return {}
	end
end

function showHideProps(selectedIdleFunction, bShow)
	--1 slaved
	if selectedIdleFunction== 2 then
		index = unitID %(#TablesOfPiecesGroups["cellphone"])
		index = math.min(#TablesOfPiecesGroups["cellphone"], math.max(1,index))
		showHide(TablesOfPiecesGroups["cellphone"][index], bShow)
	elseif selectedIdleFunction == 3 then --consumption
		if unitID%2 == 1 then
			showHide(cigarett, bShow)
		else
			showHide(cofee, bShow)
		end
	end

end

function playUpperBodyIdleAnimation()
	 if bodyConfig.boolLoaded == false then
		selectedIdleFunction = (unitID % #uppperBodyAnimations[eAnimState.idle])+1
		showHideProps(selectedIdleFunction, true)
		PlayAnimation(uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
		showHideProps(selectedIdleFunction, false)
	end
end

UpperAnimationStateFunctions ={
[eAnimState.catatonic] = 	function () 
							PlayAnimation(randT(uppperBodyAnimations[eAnimState.wailing]),catatonicBodyPieces)
							Turn(UpBody,x_axis, math.rad(126.2),60)
							Turn(center,x_axis, math.rad(-91.2),45)
							return eAnimState.talking
							end,
[eAnimState.talking] = 	function () 
								if bodyConfig.boolLoaded == false then
									PlayAnimation(randT(uppperBodyAnimations[eAnimState.talking]))	
								end
							return eAnimState.talking
						end,
[eAnimState.standing] = function () 
							Sleep(30)	
							if bodyConfig.boolArmed == true then
								PlayAnimation(randT(uppperBodyAnimations[eAnimState.aiming]),lowerBodyPieces)
								return eAnimState.standing
							end
							
							if bodyConfig.boolProtest == true then
								PlayAnimation(randT(uppperBodyAnimations[eAnimState.protest]), lowerBodyPieces)
								return eAnimState.standing
							end
							
							if bodyConfig.boolLoaded == true then
								return eAnimState.standing
							end
							
							
							if bodyConfig.boolLoaded == false then
								Turn(LowArm1, y_axis,math.rad(12),1)
								Turn(LowArm2, y_axis,math.rad(-12),1)
								WaitForTurns(TablesOfPiecesGroups["LowArm"])
							end
							
							
							if boolDecoupled == true then
								if math.random(1,10) > 5 then
								playUpperBodyIdleAnimation()	
								resetT(TablesOfPiecesGroups["UpArm"],math.pi,false,true)
								end
							 end
							 
							Sleep(30)	
							return eAnimState.standing
						end,
[eAnimState.walking] = 	function () 
							if bodyConfig.boolArmed == true  then
								PlayAnimation("UPBODY_LOADED")		
								return eAnimState.walking									
							end

							if bodyConfig.boolProtest == true  then
								return eAnimState.protest									
							end								
						
							if  bodyConfig.boolLoaded == true  then
								PlayAnimation("UPBODY_LOADED")		
								return eAnimState.walking									
							end	

							if bodyConfig.boolLoaded == false and math.random(1,100) > 50 then
								boolDecoupled = true
									playUpperBodyIdleAnimation()
									WaitForTurns(upperBodyPieces)
									resetT(upperBodyPieces, math.pi,false, true)
								return eAnimState.walking
							end											
					
						return eAnimState.walking
					end,
[eAnimState.filming] = 	function () 
								cellID= (unitID%2)+1
								Show(TablesOfPiecesGroups["cellphone"][cellID])
								PlayAnimation(randT(uppperBodyAnimations[eAnimState.filming]))								
								Hide(TablesOfPiecesGroups["cellphone"][cellID])
						return eAnimState.filming
					end,					
[eAnimState.wailing] = 	function () 								
								PlayAnimation(randT(uppperBodyAnimations[eAnimState.filming]))								
								
						return eAnimState.wailing
					end,	
[eAnimState.handsup] = 	function () 								
								PlayAnimation(randT(uppperBodyAnimations[eAnimState.handsup]))															
						return eAnimState.handsup
					end,		

[eAnimState.protest] = 	function () 
		
								PlayAnimation(randT(uppperBodyAnimations[eAnimState.protest]))															
						return eAnimState.protest
					end,						
					
[eAnimState.slaved] = 	function () 
						Sleep(100)
						return eAnimState.slaved
					end,
[eAnimState.coverwalk] = function()		
			
						Hide(ShoppingBag);				
						Hide(SittingBaby);				
						Hide(trolley);			
						Hide(Handbag);
			
						Sleep(100)
							Turn(UpArm1,z_axis,math.rad(0), 7)
							Turn(UpArm1,y_axis,math.rad(0), 7)
							Turn(UpArm1,x_axis,math.rad(-120), 7)
							
							Turn(LowArm1,y_axis,math.rad(0), 7)
							Turn(LowArm1,x_axis,math.rad(-60), 7)
							Turn(LowArm1,z_axis,math.rad(-45), 7)
							
							Turn(UpArm2,x_axis,math.rad(-120), 7)
							Turn(UpArm2,y_axis,math.rad(0), 7)
							Turn(UpArm2,z_axis,math.rad(0), 7)
							
							Turn(LowArm2,x_axis,math.rad(-60), 7)
							Turn(LowArm2,y_axis,math.rad(0), 7)
							Turn(LowArm2,z_axis,math.rad(45), 7)
						return eAnimState.coverwalk
						end,	
[eAnimState.wounded] = function()					
						Sleep(100)
						return eAnimState.wounded
						end,
						
[eAnimState.aiming] = function()					
						Sleep(100)
						PlayAnimation(randT(uppperBodyAnimations[eAnimState.aiming]),lowerBodyPieces)
						return eAnimState.aiming
						end,

}

LowerAnimationStateFunctions ={
[eAnimState.standing] = 	function () 
						-- Spring.Echo("Lower Body standing")
						WaitForTurns(lowerBodyPieces)
						resetT(lowerBodyPiecesNoCenter, math.pi,false, true)
						WaitForTurns(lowerBodyPiecesNoCenter)
						Sleep(10)
						return eAnimState.standing
					end,
				
[eAnimState.walking] = function()
									
						if bodyConfig.boolArmed == true then	
							PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]), conditionalFilterOutUpperBodyTable())					
							return eAnimState.walking
						end
						
						Turn(center,y_axis, math.rad(0), 12)
							
						if bodyConfig.boolWounded == true then
							PlayAnimation(randT(lowerBodyAnimations[eAnimState.wounded],conditionalFilterOutUpperBodyTable()))
							return eAnimState.walking
						end					
						
						if bodyConfig.boolProtest == true then	
							PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]), upperBodyPieces)
							return eAnimState.walking
						end
						
						if bodyConfig.boolTrolley == true then
								PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]), conditionalFilterOutUpperBodyTable())					
						else
							PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]), conditionalFilterOutUpperBodyTable())					
						end
						
						return eAnimState.walking
						end,
[eAnimState.transported] = function()
						echo("TODO: Civilian State transported")
						return eAnimState.transported
						end,	
[eAnimState.slaved] = function()
						Sleep(100)
						return eAnimState.slaved
						end,
[eAnimState.coverwalk] = function()					
							PlayAnimation(randT(lowerBodyAnimations[eAnimState.wounded]),upperBodyPieces)							
					
						return eAnimState.coverwalk
						end,	

[eAnimState.wounded] = function()					
							PlayAnimation(randT(lowerBodyAnimations[eAnimState.wounded]))
						return eAnimState.wounded
						end,							
[eAnimState.trolley] = function()
						
						PlayAnimation(randT(lowerBodyAnimations[eAnimState.trolley]))
						

						return eAnimState.trolley
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
				--echoNFrames("Unit "..unitID.." :UWaitForEnd :"..UpperAnimationState, 500)
			end
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
	setOverrideAnimationState(eAnimState.standing, eAnimState.standing,  true, nil, true)
end

function getWalkingState()
if bodyConfig.boolCoverWalk == true then return eAnimState.coverwalk end
if bodyConfig.boolWounded == true then return eAnimState.wounded end

return eAnimState.walking
end

function script.StartMoving()
	boolWalking = true
	setOverrideAnimationState(eAnimState.walking, eAnimState.walking,  true, nil, true)
end

function script.StopMoving()
	StartThread(delayedStop)
end
---------------------------------------------------------------------ANIMATIONS-------------------------------------
function script.Activate()
    return 1
end

function script.Deactivate()

    return 0
end

function script.QueryBuildInfo()
    return center
end

signMessages ={
	--Denial
	"JUST&NUKE&THEM",
	" SHAME ",
	"THEY &ARE NOT& US",
	"INOCENT",
	"NOT&GUILTY",
	"COULD&BE&WORSER",
	"CONSPIRACY",
	"CHEMTRAJLS DID THIS",
	"GOD SAVE US",
	
	" CITY &FOR AN &CITY",
	" BROTHFRS& KEEPFRS",
	"WE WILL &NOT DIE",
	"VENGANCE IS MURDFR",
	"  IT &CANT BE& US",
	"PUNISH&GROUPS ",
	"VIVE&LA RESISTANCE ",
	"LIES ANDWAR&CRIMES",
	"THE END&IS& NIGH",
	"PHOENIX &FACTION",
	"FOR MAN&KIND",
	"THATS&LIFE",
	"AND LET LIFE",

	"ALWAYS&LCOK ON&BRIGHTSIDE",
	
	--Anger
	"ANTIFA",
	"ROCKET&IS&RAPE",
	"HICBM& UP YOUR ASS",
	"RISE &UP",
	"UNDEFEATED",
	" BURN& THE& BRIDGE",	
	" BURN&THEM& ALL",
	" ANARCHY",
	" FUCK& YOU& ALL",
	" HOPE&  IT&HURTS",
	"VENGANCE IS& OURS",
	"MAD&IS&MURDER",
	"WE& SHALL& REBUILD",
	
	--Bargaining
	" SPARE& US",
	" SPARE& OUR&CHILDREN",
	"ANYTHINGFOR LIFE",
	"NO ISM&WORTH IT",
	"ANARCHY",
	"KILL THE GODS",
	"NO GODS&JUST MEN",
	" SEX&SAVES",
	" MERCY",

	--DEPRESSION
	"HIROSHIMA&ALL OVER",
	" SEX& KILLS",
	" GOD& IS& DEATH",
	"TEARS& IN& RAIN",
	"NEVR &FORGET& LA",
	"REMBR&HONG&KONG",
	"NEVR &FORGET& SA",
	"REMEMBR PALO& ALTO",
	"REMEBR  LAGOS",
	"REMEBR  DUBAI",
	"HITLER&WOULD&BE PROUD",
	"NEVER &AGAIN",
	"  HOLO&  CAUST",
	"IN DUBIO&PRU REO",
	--Accepting
	"NO&CITYCIDE",
	" REPENT& YOUR& SINS",
	"DUST&IN THE&WIND",
	"MAN IS& MEN A& WULF",
	"POMPEJ  ALLOVER",
	"AVENGE&US",
	"SHIT&HAPPENS",
	"FOR WHOM&THE BELL",
	"IS TOLLS&FOR THEE",
	"MEMENTO",
	"MORI",
	"CARPE&DIEM",
	
	--Personification
	"Ü&HAS SMALL&DICK",
	"I&LOVE&Ü",
	"Ü&U HAVE A&SON",
	"Ü&MARRY&ME",
	" DEATH&TO&Ü",
	"  I& BLAME&Ü",
	"WHAT DO&YOU DESIRE?Ü",
	"MUMS&AGAINST&Ü",	
	"HATE Ü",
	"FUCK Ü",
	"Ü IS&EVIL",
	
	
	--Humor
	" PRO&TEST&ICLES",
	"NO MORE&TAXES",
	"PRO&TAXES",
	"NO&PROTEST",
	"NEVER GONNA GIVE",
	"YOU UP",
	"NEVER GONNA LET",
	"YOU DOWN",
}



function makeProtestSign(xIndexMax, zIndexMax, sizeLetterX, sizeLetterZ, sentence, personification)
	for i=1, 26 do
		charOn = string.char(64+i) 
		if TablesOfPiecesGroups[charOn] then
			resetT(TablesOfPiecesGroups[charOn])
			hideT(TablesOfPiecesGroups[charOn])
		end		
	end
	hideT(TablesOfPiecesGroups["Quest"])
	resetT(TablesOfPiecesGroups["Quest"])
	hideT(TablesOfPiecesGroups["Exclam"])
	resetT(TablesOfPiecesGroups["Exclam"])

index = 0
Show(ProtestSign)
alreadyUsedLetter ={} 
sentence = string.gsub(sentence, "Ü", personification or "")

	for i=1, #sentence do
		letter = string.upper(string.sub(sentence, i, i))
		if letter == "!" then letter = "Exclam" end
		if letter == "?" then letter = "Quest" end

			if letter == "&" then 
				index = (index + xIndexMax ) - ((index + xIndexMax)%xIndexMax); 
			else	
				local pieceToMove 
				if TablesOfPiecesGroups[letter] then 
					if  not alreadyUsedLetter[letter] then 
						alreadyUsedLetter[letter]= 1; 
						pieceToMove = TablesOfPiecesGroups[letter][alreadyUsedLetter[letter]]		
					else
					alreadyUsedLetter[letter]= alreadyUsedLetter[letter] +  1; 
						if TablesOfPiecesGroups[letter][alreadyUsedLetter[letter]] then
							pieceToMove = TablesOfPiecesGroups[letter][alreadyUsedLetter[letter]]
						end
					end
				end
				
				if letter == " " then	
					index= index+1
				elseif pieceToMove ~= nil then
					--place and show letter
					assert(pieceToMove)
					Show(pieceToMove)

					xIndex= index % xIndexMax
					zIndex=  math.floor((index/xIndexMax))
					Turn(pieceToMove,z_axis,math.rad(math.random(-2,2)),0)
					Move(pieceToMove,z_axis, zIndex* sizeLetterZ ,0)
					Move(pieceToMove,x_axis, xIndex* sizeLetterX,0)
					index= index + 1
					if zIndex > zIndexMax then return end
				end

			end
	end
	
end



local civilianID 

		

function spawnDecoyCivilian()
--spawnDecoyCivilian
		Sleep(10)
		x,y,z= Spring.GetUnitPosition(unitID)

		civilianID = Spring.CreateUnit(randT(civilianWalkingTypeTable) , x +  randSign()*5 , y, z +  randSign()*5, 1, Spring.GetGaiaTeamID())
		transferUnitStatusToUnit(unitID,civilianID)
		Spring.SetUnitNoSelect(civilianID, true)
		Spring.SetUnitAlwaysVisible(civilianID, true)
		

			
			persPack = {myID= civilianID, syncedID= unitID, startFrame = Spring.GetGameFrame()+1 }
			
			GG.DisguiseCivilianFor[civilianID]= unitID
			GG.DiedPeacefully[civilianID] = false
			
			if civilianID then
				GG.EventStream:CreateEvent(
				syncDecoyToAgent,
				persPack,
				Spring.GetGameFrame() + 1
				)
			end


	return 0
end

boolCloaked = Spring.GetUnitIsCloaked(unitID)
boolDeCloaked = false

function cloakLoop()
	local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
	Sleep(100)
	waitTillComplete(unitID)
	Sleep(100)
	
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
	SetUnitValue(COB.WANT_CLOAK, 1)
	SetUnitValue(COB.CLOAKED, 1)
	while (spGetUnitIsCloaked(unitID)== false) do
		Sleep(100)
	end

	boolCloaked=spGetUnitIsCloaked(unitID)
	StartThread(spawnDecoyCivilian)
	echoOverload("invisible")
	while true do 
		boolCloaked=spGetUnitIsCloaked(unitID)
		Sleep(100)

		if boolCloaked == false and boolDeCloaked == false then
			echoOverload("revealed")
			boolDeCloaked = true
			Spring.SetUnitTooltip(unitID, "Militia : Cover blown")
			boolArmed = true
			Show(ak47)
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {1}, {}) 

			if civilianID and doesUnitExistAlive(civilianID) == true then
				GG.DiedPeacefully[civilianID] = true
				Spring.DestroyUnit(civilianID, true, true)
			end
		end

		if boolCloaked == true and boolDeCloaked == true then 
			echoOverload("recloak prevented")
			SetUnitValue(COB.WANT_CLOAK, 0)
			SetUnitValue(COB.CLOAKED, 0)
		end

		Sleep(100)
	end
end


function echoOverload(res)
	Spring.Echo("CivilianAgent: ".. res)
end


function akAimFunction(weaponID, heading, pitch)
	boolAiming = true

	setOverrideAnimationState(eAnimState.aiming, eAnimState.standing,  true, nil, false)
	WTurn(center,y_axis,heading, 22)
	WaitForTurns(UpArm1, UpArm2, LowArm1,LowArm2)
	boolAiming = false
return  allowTarget(weaponID)
end

function akFireFunction(weaponID, heading, pitch)
	boolAiming = false

	return true
end



WeaponsTable = {}
function makeWeaponsTable()
    WeaponsTable[1] = { aimpiece = center, emitpiece = ak47, aimfunc = akAimFunction, firefunc = akFireFunction, signal = SIG_PISTOL }
end

function script.AimFromWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].aimpiece
    else
        return ak47
    end
end

function script.QueryWeapon(weaponID)
    if WeaponsTable[weaponID] then
        return WeaponsTable[weaponID].emitpiece
    else
        return ak47
    end
end

function script.AimWeapon(weaponID, heading, pitch)
    if WeaponsTable[weaponID] then
        if WeaponsTable[weaponID].aimfunc then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        else
            WTurn(WeaponsTable[weaponID].aimpiece, y_axis, heading, turretSpeed)
            WTurn(WeaponsTable[weaponID].aimpiece, x_axis, -pitch, turretSpeed)
            return allowTarget(weaponID)
        end
    end
    return false
end

local validTargetType={
[1]=true,
[2]=true,
}

function allowTarget(weaponID)
		targetType,  isUserTarget, targetID = spGetUnitWeaponTarget(unitID, weaponID)
	
		if not targetType or  (not validTargetType[targetType])  then
			-- echo("TargetType:"..targetType.." TargetID:");echo(targetID)
			return false 
		end
			
		--Do not aim at your own disguise civilian
		if targetType == 1 and spGetUnitTeam(targetID) == gaiaTeamID then		
			if GG.DisguiseCivilianFor[targetID] and spGetUnitTeam(GG.DisguiseCivilianFor[targetID]) == myTeamID then	
					return false
			end
		end
		
	return boolCloaked == false
end
function script.Killed(recentDamage, _)
	if doesUnitExistAlive(civilianID) == true then
		Spring.DestroyUnit(civilianID,true,true) 
	end
   return 1
end


