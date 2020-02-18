
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"
myDefID=Spring.GetUnitDefID(unitID)
TablesOfPiecesGroups = {}

SIG_PISTOL = 1
SIG_RAID = 1

local Animations = include('animation_assasin_female.lua')

function script.HitByWeapon(x, z, weaponDefID, damage)
return damage
end

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
local UpArm1 = piece('UpArm1');
local LowArm1 = piece('LowArm1');
local Eye1 = piece('Eye1');
local Eye2 = piece('Eye2');
local backpack = piece('backpack');
local Drone = piece("Drone")
Icon = piece("Icon")
Shell1 = piece("Shell1")
FoldtopUnfolded = piece'FoldtopUnfolded'
FoldtopFolded= piece'FoldtopFolded'

GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "civilian", UnitDefs)


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
	[UpArm2]  = UpArm2,
	[LowArm1 ] = LowArm1,
	[LowArm2]  = LowArm2,
	[Torso  ]	= Torso,
	[Eye1 ]= Eye1,
	[Eye2 ]= Eye2,
	[backpack]= backpack,
	[center	]= center,
	}
	
lowerBodyPieces =
{
	[UpLeg1	]= UpLeg1,
	[UpLeg2 ]= UpLeg2,
	[LowLeg1]= LowLeg1,
	[LowLeg2]= LowLeg2,

}

boolWalking = false
boolTurning = false
boolTurnLeft = false
boolDecoupled = false

boolAiming = false

if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end

function script.Create()

	makeWeaponsTable()
	GG.OperativesDiscovered[unitID] = nil

-- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	hideAll(unitID)

	hideT(TablesOfPiecesGroups["SoftRobot"])
	showT(upperBodyPieces)
	showT(lowerBodyPieces)
	setupAnimation()
	-- StartThread(turnDetector)
	
	setOverrideAnimationState( eAnimState.slaved, eAnimState.standing,  true, nil, false)

	StartThread(threadStarter)
	StartThread(cloakLoop)
	-- StartThread(testAnimationLoop)
	StartThread(breathing)
	StartThread(raidReactor)
-- echo("Create complted")
end

function breathing()
	local breathSpeed= 0.1/3
	while true do
		if boolAiming == false and boolWalking == false then
			Turn(Head,x_axis,math.rad(-1),breathSpeed)
			WTurn(Torso,x_axis, math.rad(1), breathSpeed)
			Turn(Head,x_axis,math.rad(0),breathSpeed)
			WTurn(Torso,x_axis, math.rad(0), breathSpeed)
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
			assert(cmd.p, animname..j)
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

function playUpperBodyIdleAnimation()
	
		selectedIdleFunction = math.random(1,#uppperBodyAnimations[eAnimState.idle])
		if selectedIdleFunction and uppperBodyAnimations[eAnimState.idle] and uppperBodyAnimations[eAnimState.idle][selectedIdleFunction] then
			PlayAnimation(uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
		end	
	
end


UpperAnimationStateFunctions ={
[eAnimState.standing] = 	function () 
							resetT(lowerBodyPieces, 10)
							if boolPistol== true then							
								PlayAnimation("UPBODY_STANDING_PISTOL", lowerBodyPieces)
							else
								PlayAnimation("UPBODY_STANDING_GUN", lowerBodyPieces, 3.0)
							end
								-- echo("UpperBody Standing")
							if boolDecoupled == true then
										if math.random(1,10) > 5 then
										playUpperBodyIdleAnimation()							
										end
							 end
								Sleep(30)	
								return eAnimState.standing
							end,
[eAnimState.walking] = 	function () 
							
								boolDecoupled = true
									playUpperBodyIdleAnimation()
								boolDecoupled = false
				
						return eAnimState.walking
					end,
[eAnimState.slaved] = 	function () 
						Sleep(100)
						return eAnimState.slaved
					end,
[eAnimState.aiming] = 	function () 
						if boolPistol == true then
							PlayAnimation("UPBODY_AIM_PISTOL")
						else	
							PlayAnimation("UPBODY_AIMING", nil, 3.0)
						end
						Sleep(100)
						return eAnimState.aiming 
					end
} 

LowerAnimationStateFunctions ={
[eAnimState.walking] = function()
						assert(lowerBodyAnimations[eAnimState.walking])
						PlayAnimation(randT(lowerBodyAnimations[eAnimState.walking]))					
						return eAnimState.walking
						end,
[eAnimState.standing] = 	function () 
						-- Spring.Echo("Lower Body standing")
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
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP)
	Sleep(250)

	boolWalking = false
	-- Spring.Echo("Stopping")
	setOverrideAnimationState(eAnimState.standing, eAnimState.standing,  true, nil, true)
	


end

function showFoldTop()
	Sleep(2500)
	 if  boolCloaked == false then
	Show(FoldtopUnfolded)
	Hide(FoldtopFolded)
	end

end

function script.StartMoving()
	boolWalking = true
	if  boolCloaked == false then
	Hide(FoldtopUnfolded)
	Show(FoldtopFolded)
	end
	Turn(center,y_axis, math.rad(0), 12)
	setOverrideAnimationState(eAnimState.slaved, eAnimState.walking,  true, nil, false)
end

function script.StopMoving()
	StartThread(delayedStop)
	StartThread(showFoldTop)
end

local civilianID 


function spawnDecoyCivilian()
--spawnDecoyCivilian
		Sleep(10)	

		x,y,z= Spring.GetUnitPosition(unitID)
		civilianID = Spring.CreateUnit(randT(civilianWalkingTypeTable) , x + randSign()*5 , y, z+ randSign()*5 , 1, Spring.GetGaiaTeamID())
		transferUnitStatusToUnit(unitID,civilianID)
		Spring.SetUnitNoSelect(civilianID, true)
		Spring.SetUnitAlwaysVisible(civilianID, true)
	
			persPack = {myID= civilianID, syncedID= unitID, startFrame = Spring.GetGameFrame()+1 }
			if not GG.DisguiseCivilianFor then GG.DisguiseCivilianFor = {} end
			GG.DisguiseCivilianFor[civilianID]= unitID
			if not GG.DiedPeacefully then GG.DiedPeacefully ={} end
			GG.DiedPeacefully[civilianID] = false
				
			if civilianID then
				GG.EventStream:CreateEvent(
				syncDecoyToAgent,
				persPack,
				Spring.GetGameFrame()+1
				)

			end

	return 0
end



	boolCloaked = false

function cloakLoop()
	local spGetUnitIsActive = Spring.GetUnitIsActive
	local boolIsCurrentlyActive= spGetUnitIsActive(unitID)
	Sleep(100)
	waitTillComplete(unitID)

	Sleep(100)

	
	while true do 
	
		boolIsCurrentlyActive = spGetUnitIsActive(unitID)
		if boolCloaked == false and boolIsCurrentlyActive == true  and not  GG.OperativesDiscovered[unitID]  then
			setSpeedEnv(unitID, 0.35)
			SetUnitValue(COB.WANT_CLOAK, 1)
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
			boolCloaked=true
			StartThread(spawnDecoyCivilian)
		end
		Sleep(100)
		if (boolIsCurrentlyActive == true and  GG.OperativesDiscovered[unitID] ) or  
		 (boolIsCurrentlyActive == false and boolCloaked == true )then
	
			setSpeedEnv(unitID, 1.0)
			SetUnitValue(COB.WANT_CLOAK, 0)
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {1}, {}) 
			boolCloaked= false
			if civilianID and doesUnitExistAlive(civilianID) == true then
				GG.DiedPeacefully[civilianID] = true
				Spring.DestroyUnit(civilianID, true, true)
			end
		end
		Sleep(100)
	end
end





function script.Activate()
	SetUnitValue(COB.WANT_CLOAK, 1)
	return 1
end

function script.Deactivate()
	SetUnitValue(COB.WANT_CLOAK, 0)
    return 0
end


function script.QueryBuildInfo()
    return center
end


function script.StopBuilding()

	SetUnitValue(COB.INBUILDSTANCE, 0)
end


function script.StartBuilding(heading, pitch)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

Spring.SetUnitNanoPieces(unitID, { Pistol })


raidDownTime = GameConfig.agentConfig.raidWeaponDownTimeInSeconds * 1000
local raidComRange = GameConfig.agentConfig.raidComRange
myRaidDownTime = raidDownTime
local scanSatDefID = UnitDefNames["satellitescan"].id
local raidBonusFactorSatellite=  GameConfig.agentConfig.raidBonusFactorSatellite


function raidReactor()
	myTeam = Spring.GetUnitTeam(unitID)
	while true do
		Sleep(100)
		--if myRaidDownTime % 500 == 0 and myRaidDownTime ~= oldRaidDownTime then Spring.Echo("raid reactor :"..myRaidDownTime); oldRaidDownTime =myRaidDownTime end
		boolComSatelliteNearby= false
		process(getAllNearUnit(unitID, raidComRange),
				function (id)
					if myTeam == Spring.GetUnitTeam(id) and Spring.GetUnitDefID(id) == scanSatDefID then
						myRaidDownTime= math.max( -100, myRaidDownTime - 100* GameConfig.agentConfig.raidBonusFactorSatellite)
						boolComSatelliteNearby = true
					end				
				end
				)

		myRaidDownTime= math.max( 0, myRaidDownTime - 100)

	end
end

function raidReloadComplete()
	return myRaidDownTime <= 0
end


function raidAimFunction(weaponID, heading, pitch)
	return raidReloadComplete() and boolCloaked == false
end

function pistolAimFunction(weaponID, heading, pitch)
	boolAiming = true
	setOverrideAnimationState(eAnimState.aiming, eAnimState.standing,  true, nil, false)
	WTurn(center,y_axis,heading, 22)
	WaitForTurns(UpArm1, UpArm2, LowArm1,LowArm2)
	-- echo("Aiming Pistol finnished")
	return  true
end


function raidFireFunction(weaponID, heading, pitch)
	myRaidDownTime = raidDownTime
	return true
end

function pistolFireFunction(weaponID, heading, pitch)
	boolAiming = false
	Explode(Shell1, SFX.FALL + SFX.NO_HEATCLOUD)
	return true
end



WeaponsTable = {}
function makeWeaponsTable()
    WeaponsTable[1] = { aimpiece = Drone, emitpiece = Drone, aimfunc = raidAimFunction, firefunc = raidFireFunction, signal = SIG_RAID }
    WeaponsTable[2] = { aimpiece = Pistol, emitpiece = Pistol, aimfunc = pistolAimFunction, firefunc = pistolFireFunction, signal = SIG_PISTOL }
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




function script.AimWeapon(weaponID, heading, pitch)
    if WeaponsTable[weaponID] then
        if WeaponsTable[weaponID].aimfunc then
            return WeaponsTable[weaponID].aimfunc(weaponID, heading, pitch)
        else
            WTurn(WeaponsTable[weaponID].aimpiece, y_axis, heading, turretSpeed)
            WTurn(WeaponsTable[weaponID].aimpiece, x_axis, -pitch, turretSpeed)
            return true
        end
    end
    return false
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if  boolCloaked == true then
        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
		Hide(Drone)
		hideT(TablesOfPiecesGroups["SoftRobot"])
		hideT(TablesOfPiecesGroups["Shell"])			
		Show(FoldtopUnfolded)
		Hide(FoldtopFolded)
		
        Hide(Icon)
    end
end


