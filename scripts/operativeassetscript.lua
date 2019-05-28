
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

deathpivot = piece "deathpivot"
center = piece "center"
torso = piece "Torso"
gun = piece "Gun"


if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end

function script.Create()
	makeWeaponsTable()
	GG.OperativesDiscovered[unitID] = nil

    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	initializeAnimationSystem()
	StartThread(animationStateMachineUpper, UpperAnimationStateFunctions)
	StartThread(animationStateMachineLower, LowerAnimationStateFunctions)
	StartThread(threadStarter)
end

local Animations = {};


local animCmd = { ['turn'] = Turn, ['move'] = Move };

function PlayAnimation(animname)


    if not Animations[animname] then Spring.Echo(animname.." is missing") end

    local anim = Animations[animname];
    assert(anim, animname)
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1, #commands do
            local cmd = commands[j];
            animCmd[cmd.c](cmd.p, cmd.a, cmd.t, cmd.s);
        end
        if (i < #anim) then
            local t = anim[i + 1]['Time'] - anim[i]['Time'];
            Sleep(t * 33); -- sleep works on milliseconds
        end
    end
end
function initializeAnimationSystem()
    local map = Spring.GetUnitPieceMap(unitID)
    local offsets = constructSkeleton(unitID, deathpivot, { 0, 0, 0 })

    for a, anim in pairs(Animations) do
        for i, keyframe in pairs(anim) do
            local commands = keyframe.commands;
            for k, command in pairs(commands) do
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                if (command.c == "move") then
                    local adjusted = command.t - (offsets[command.p][command.a]);
                    Animations[a][i]['commands'][k].t = command.t - (offsets[command.p][command.a]);
                end
            end
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
		Spring.DestroyUnit(civilianID,true,true) 
	end
   return 1
end

local	locAnimationstateUpperOverride 
local	locAnimationstateLowerOverride
local	locBoolInstantOverride 
local	locConditionFunction
local	boolStartThread = false

function threadStarter()
	while true do
		if boolStartThread == true then
			boolStartThread = false
			StartThread(deferedOverrideAnimationState, locAnimationstateUpperOverride, locAnimationstateLowerOverride, locBoolInstantOverride, locConditionFunction)
			while boolStartThread == false do
				Sleep(1)
			end
		end
		Sleep(1)
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
		setAnimationState( AnimationstateUpperOverride, AnimationstateLowerOverride)
	end
	
	if conditionFunction then StartThread(conditionFunction) end
end

function setAnimationState(AnimationstateUpperOverride, AnimationstateLowerOverride)

		if AnimationstateUpperOverride then		boolUpperStateWaitForEnd = true end
		if AnimationstateLowerOverride then boolLowerStateWaitForEnd = true end
		
		
		 while AnimationstateLowerOverride and boolLowerAnimationEnded == false or AnimationstateUpperOverride and boolUpperAnimationEnded == false do
			if AnimhationstateUpperOverride then
				boolUpperStateWaitForEnd = true
			end
			 
			if AnimationstateLowerOverride	then		
				boolLowerStateWaitForEnd = true
			end

			Sleep(10)
		 end
		if AnimationstateUpperOverride then	UpperAnimationState = AnimationstateUpperOverride end
		if AnimationstateLowerOverride then LowerAnimationState = AnimationstateLowerOverride end
		if AnimationstateUpperOverride then	boolUpperStateWaitForEnd = false end
		if AnimationstateLowerOverride then boolLowerStateWaitForEnd = false end
end

function setOverrideAnimationState( AnimationstateUpperOverride, AnimationstateLowerOverride, boolInstantOverride, conditionFunction)
	locAnimationstateUpperOverride =AnimationstateUpperOverride
	locAnimationstateLowerOverride = AnimationstateLowerOverride
	locBoolInstantOverride = boolInstantOverride
	locConditionFunction = conditionFunction
	boolStartThread = true
end

State_Standing = "standing"
State_Idle	   = "idle"

--Interaction Cycles
State_Idle = "idling" --observing, comchatter, guncleaning
State_Aiming = "aim"
State_Hit 	= "hit"
State_Death ="dieing"
--Walk Cycle
State_Walking = "walk"
	-- State_Running = "walk"
	-- State_CoverWalk = "cowering"
	-- State_Limping = "wounded"

UpperAnimationStateFunctions ={
[State_Standing] = 	function () 
						WTurn(torso,y_axis,math.rad(0),math.pi)
						Sleep(100)
						return State_Standing
					end,
[State_Walking] = 	function () 
						WTurn(torso,y_axis,math.rad(15),math.pi)
						WTurn(torso,y_axis,math.rad(-15),math.pi)
						return State_Walking
					end

}
LowerAnimationStateFunctions ={
[State_Walking] = function()
						WMove(center,y_axis, 15, math.pi)
						Sleep(100)
						WMove(center,y_axis, 0, math.pi)
						return State_Walking
				end,
[State_Standing] = 	function () 
						WMove(center,y_axis, 0, math.pi)
						Sleep(100)
						return State_Standing
					end
}


UpperAnimationState = State_Standing
boolUpperStateWaitForEnd = false
boolUpperAnimationEnded = false
function animationStateMachineLower(AnimationTable)
Signal(SIG_UP)
SetSignalMask(SIG_UP)

boolUpperStateWaitForEnd = false

local animationTable = AnimationTable

	while true do
		UpperAnimationState = animationTable[UpperAnimationState]()
		
		--Sync Animations
		if boolUpperStateWaitForEnd == true then
			boolUpperAnimationEnded = true
			while boolUpperStateWaitForEnd == true do
				Sleep(10)
			end
			boolUpperAnimationEnded = false
		end
		
	end
	

	

end

LowerAnimationState = State_Standing
boolLowerStateWaitForEnd = false
boolLowerAnimationEnded = false

function animationStateMachineUpper(AnimationTable)
Signal(SIG_LOW)
SetSignalMask(SIG_LOW)

boolLowerStateWaitForEnd = false
local animationTable = AnimationTable

	while true do
		LowerAnimationState = animationTable[LowerAnimationState]()
		
		--Sync Animations
		if boolLowerStateWaitForEnd == true then
			boolLowerAnimationEnded = true
			while boolLowerStateWaitForEnd == true do
				Sleep(10)
			end
			boolLowerAnimationEnded = false
		end
		
		
	end

end



function delayedStop()
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP)
	Sleep(250)
	StartThread(setAnimationState, State_Standing, State_Standing)
end

function script.StartMoving()
	StartThread(setAnimationState, State_Walking, State_Walking)
end

function script.StopMoving()
	StartThread(delayedStop)
end

local civilianID 


function spawnDecoyCivilian()
--spawnDecoyCivilian
		Sleep(10)	

		x,y,z= Spring.GetUnitPosition(unitID)
		civilianID = Spring.CreateUnit("civilian" , x + randSign()*5 , y, z+ randSign()*5 , 1, Spring.GetGaiaTeamID())
		transferUnitStatusToUnit(unitID, civilianID)
		Spring.SetUnitNoSelect(civilianID, true)
		Spring.SetUnitAlwaysVisible(civilianID, true)
	

			
			persPack = {myID= civilianID, syncedID= unitID, startFrame = Spring.GetGameFrame()+1 }
			GG.DisguiseCivilianFor[civilianID]= unitID
			
			if civilianID then
				GG.EventStream:CreateEvent(
				syncDecoyToAgent,
				persPack,
				Spring.GetGameFrame()+1
				)

			end

	return 0
end

function script.Activate()
	setSpeedEnv(unitID, 0.175) -- 9,00 -> 1,575  must be as slow as a civilian when moving hidden
	Spring.Echo("Activate "..UnitDefs[Spring.GetUnitDefID(unitID)].name)
	if not GG.OperativesDiscovered[unitID] then
		 Spring.Echo("Operative still hidden")
        SetUnitValue(COB.WANT_CLOAK, 1)
		Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
		StartThread(spawnDecoyCivilian)
		return 1
   else
		Spring.Echo("Operative ".. unitID.." is discovered")
		return 0
   end
  
end

function script.Deactivate()
	setSpeedEnv(unitID, 1.0)
	Spring.Echo("Deactivate "..unitID)
	SetUnitValue(COB.WANT_CLOAK, 0)
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {1}, {}) 
	if civilianID and doesUnitExistAlive(civilianID) == true then
		Spring.DestroyUnit(civilianID, true, true)
	end
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

local spGetUnitTeam = Spring.GetUnitTeam
local myTeamID = spGetUnitTeam(unitID)
local gaiaTeamID = Spring.GetGaiaTeamID()
local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget 
local loc_doesUnitExistAlive = doesUnitExistAlive

function allowTarget(weaponNumber)
	isGround, isUserTarget, targetID = spGetUnitWeaponTarget(unitID, weaponNumber)
	if isGround and isGround == 1  then
	
		if spGetUnitTeam(targetID) == gaiaTeamID then

			if GG.DisguiseCivilianFor[targetID] and spGetUnitTeam(GG.DisguiseCivilianFor[targetID]) == myTeamID then
		
			return false
			end
		end
	end
return true
end

function pistolAimFunction(weaponID, heading, pitch)
return  allowTarget(weaponID)
end

function gunAimFunction(weaponID, heading, pitch)
return  allowTarget(weaponID)
end

function sniperAimFunction(weaponID, heading, pitch)
return  allowTarget(weaponID)
end



function pistolFireFunction(weaponID, heading, pitch)
return true
end

function gunFireFunction(weaponID, heading, pitch)
return true
end

function sniperFireFunction(weaponID, heading, pitch)
return true
end

SIG_PISTOL =1
SIG_GUN = 2
SIG_SNIPER = 4
SIG_STOP = 8
SIG_UP = 16
SIG_LOW = 32

WeaponsTable = {}
function makeWeaponsTable()
    WeaponsTable[1] = { aimpiece = gun, emitpiece = gun, aimfunc = pistolAimFunction, firefunc = pistolFireFunction, signal = SIG_PISTOL }
	WeaponsTable[2] = { aimpiece = gun, emitpiece = gun, aimfunc = gunAimFunction, firefunc = gunFireFunction, signal = SIG_GUN }
	WeaponsTable[3] = { aimpiece = gun, emitpiece = gun, aimfunc = sniperAimFunction, firefunc = sniperFireFunction, signal = SIG_SNIPER }
end


function turretReseter()
    while true do
        Sleep(1000)
        for i = 1, #WeaponsTable do
			if WeaponsTable[i].coolDownTimer then
				if WeaponsTable[i].coolDownTimer > 0 then
					WeaponsTable[i].coolDownTimer = math.max(WeaponsTable[i].coolDownTimer - 1000, 0)

				elseif WeaponsTable[i].coolDownTimer <= 0 then
					tP(WeaponsTable[i].emitpiece, -90, 0, 0, 0)
					WeaponsTable[i].coolDownTimer = -1
				end
			end
        end
    end
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

Spring.SetUnitNanoPieces(unitID, { center })
