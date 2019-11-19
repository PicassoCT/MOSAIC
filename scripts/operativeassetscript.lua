
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end


local center = piece('center');
local Torso = piece('Torso');
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


local scriptEnv = {
	center = center,
	Torso = Torso,
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
	[Head	]  = true,
	[UpArm1 ] = true,
	[UpArm2]  = true,
	[LowArm1 ] = true,
	[LowArm2]  = true,
	[Torso  ]	= true,
	[Eye1 ]= true,
	[Eye2 ]= true,
	[backpack]= true,
	}
	
lowerBodyPieces =
{
	[center	]= true,
	[UpLeg1	]= true,
	[UpLeg2 ]= true,
	[LowLeg1]= true,
	[LowLeg2]= true,

}

boolWalking = false
boolTurning = false
boolTurnLeft = false
boolDecoupled = false

if not GG.OperativesDiscovered then  GG.OperativesDiscovered={} end

function script.Create()
	makeWeaponsTable()
	GG.OperativesDiscovered[unitID] = nil

    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	setupAnimation()
	StartThread(turnDetector)
	
	setOverrideAnimationState( eAnimState.slaved, eAnimState.walking,  true, nil, false)
	StartThread(animationStateMachineUpper, UpperAnimationStateFunctions)
	StartThread(animationStateMachineLower, LowerAnimationStateFunctions)
	StartThread(threadStarter)
	StartThread(cloakLoop)
	StartThread(testAnimationLoop)
	
end

function testAnimationLoop()
	Sleep(500)
	while true do
		PlayAnimation("WALKCYCLE_RUNNING", nil, 1.0)	
		Sleep(10)
	end
end

local Animations = {
["WALKCYCLE_RUNNING"]= {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.065737, ['s']=0.328686},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.014720, ['s']=0.073598},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.004413, ['s']=0.022063},
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.118847, ['s']=0.149288},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.057335, ['s']=0.156527},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.277932, ['s']=0.835026},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.230036, ['s']=1.718207},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.738090, ['s']=0.793059},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.934927, ['s']=2.432867},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.752669, ['s']=0.149001},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.435072, ['s']=1.629982},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.474226, ['s']=0.448821},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.386631, ['s']=0.814625},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.578274, ['s']=2.767078},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=-0.002088, ['s']=0.453128},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=-0.080214, ['s']=0.174433},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=-0.267598, ['s']=0.649768},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-1.156206, ['s']=1.473168},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.214646, ['s']=1.190777},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.102668, ['s']=0.454101},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.223397, ['s']=5.562797},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.921747, ['s']=0.140302},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-1.398399, ['s']=4.939349},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.221193, ['s']=2.273890},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.130732, ['s']=1.815864},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 2,
		['commands'] = {
		}
	},
	{
		['time'] = 4,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.316854, ['s']=5.581337},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.055635, ['s']=1.660970},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 7,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=-0.037772, ['s']=0.388160},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.031035, ['s']=0.061182},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.013450, ['s']=0.033892},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.511197, ['s']=0.201230},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 9,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.166292, ['s']=0.101668},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.068234, ['s']=0.269077},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.138595, ['s']=0.892559},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.792489, ['s']=3.567262},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=-0.016113, ['s']=0.210381},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=-0.085614, ['s']=0.080987},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=-0.287710, ['s']=0.301678},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.227561, ['s']=8.789441},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 11,
		['commands'] = {
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.047390, ['s']=0.272158},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=-0.009735, ['s']=0.325195},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=-0.028001, ['s']=1.113040},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.693068, ['s']=0.111751},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.216921, ['s']=1.222486},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.653754, ['s']=0.336616},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.530243, ['s']=7.573471},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.900349, ['s']=1.963272},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 14,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.168116, ['s']=0.928795},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.738002, ['s']=0.001330},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.751934, ['s']=2.744903},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.000000, ['s']=0.226633},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.000000, ['s']=0.186208},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=0.000000, ['s']=0.080702},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=1.372574, ['s']=5.562797},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.856273, ['s']=0.140302},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.906631, ['s']=4.939349},
		}
	},
	{
		['time'] = 16,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.167521, ['s']=0.839094},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.881735, ['s']=0.359333},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.452305, ['s']=0.749072},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.008430, ['s']=3.729244},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.065482, ['s']=0.391502},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 18,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.139318, ['s']=0.977314},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.097778, ['s']=0.251940},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.050473, ['s']=0.301037},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.178071, ['s']=1.030357},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.228790, ['s']=1.678897},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-2.157432, ['s']=1.877298},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.594524, ['s']=1.162729},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.410176, ['s']=0.576577},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.026035, ['s']=0.111579},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.043227, ['s']=0.185260},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.015428, ['s']=0.066122},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.820833, ['s']=2.708011},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-1.295938, ['s']=6.152280},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.109182, ['s']=0.171328},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.024611, ['s']=0.278538},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.114849, ['s']=0.760334},
		}
	},
	{
		['time'] = 24,
		['commands'] = {
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=-0.085507, ['s']=0.916426},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.004788, ['s']=0.228424},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.002755, ['s']=0.876580},
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.001778, ['s']=0.145544},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.040133, ['s']=0.018570},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.015667, ['s']=0.001430},
		}
	},
	{
		['time'] = 28,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.131869, ['s']=0.534783},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.984609, ['s']=1.543117},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.528309, ['s']=1.140061},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.130732, ['s']=1.664580},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 29,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.752669, ['s']=0.105177},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.435072, ['s']=1.150575},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.474226, ['s']=0.316815},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.223397, ['s']=4.867447},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.921747, ['s']=0.122764},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-1.398399, ['s']=4.321930},
		}
	},
	{
		['time'] = 30,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.156556, ['s']=0.074061},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-1.352191, ['s']=1.102746},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.616878, ['s']=0.265705},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.386631, ['s']=1.483877},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.578274, ['s']=6.212797},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.068412, ['s']=0.513064},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=-0.057720, ['s']=0.208360},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=-0.180451, ['s']=0.610686},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.221193, ['s']=3.374872},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 32,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.000000, ['s']=0.005926},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.000000, ['s']=0.133775},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=0.000000, ['s']=0.052223},
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.117007, ['s']=0.021339},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.009107, ['s']=0.091958},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.004923, ['s']=0.299799},
		}
	},
	{
		['time'] = 34,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.055635, ['s']=1.660970},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 35,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.316854, ['s']=5.581337},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-1.133684, ['s']=2.559370},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.260087, ['s']=1.663908},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.048394, ['s']=0.904456},
		}
	},
	{
		['time'] = 36,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.511197, ['s']=0.201230},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 39,
		['commands'] = {
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=-0.038016, ['s']=0.354761},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.002099, ['s']=0.199399},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.001275, ['s']=0.605754},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.227561, ['s']=8.789441},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 40,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.002447, ['s']=1.155820},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-1.078839, ['s']=2.050138},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.657756, ['s']=0.306585},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.792489, ['s']=3.567262},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 41,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.026035, ['s']=0.097632},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.043227, ['s']=0.162103},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.015428, ['s']=0.057857},
		}
	},
	{
		['time'] = 43,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.900349, ['s']=1.963272},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 44,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.126578, ['s']=0.028713},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.079301, ['s']=0.210583},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.252836, ['s']=0.773277},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.468482, ['s']=2.825569},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.722622, ['s']=2.137305},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.195459, ['s']=3.226218},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.530243, ['s']=7.573471},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=1.372574, ['s']=5.191943},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.856273, ['s']=0.130948},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.906631, ['s']=4.610059},
		}
	},
	{
		['time'] = 46,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.693068, ['s']=0.127715},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.216921, ['s']=1.397127},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.653754, ['s']=0.384704},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.008430, ['s']=3.729244},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 47,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-2.040107, ['s']=2.091746},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.500180, ['s']=1.753632},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.375129, ['s']=0.754005},
		}
	},
	{
		['time'] = 48,
		['commands'] = {
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.061706, ['s']=0.427381},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.087603, ['s']=0.366445},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.297189, ['s']=1.268200},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.006196, ['s']=2.235382},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 49,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.001778, ['s']=0.145544},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.040133, ['s']=0.018570},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.015667, ['s']=0.001430},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.544730, ['s']=2.763305},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.998220, ['s']=0.751633},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.250066, ['s']=3.942340},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.468093, ['s']=0.169500},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.065482, ['s']=0.391502},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 50,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.820833, ['s']=2.437210},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 54,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=0.000000, ['s']=0.008889},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.000000, ['s']=0.200663},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=0.000000, ['s']=0.078334},
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.079037, ['s']=0.237706},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.015594, ['s']=0.474476},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.055259, ['s']=1.540473},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-1.295938, ['s']=6.152280},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 55,
		['commands'] = {
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.118746, ['s']=0.342243},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=-0.033699, ['s']=0.727813},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=-0.094327, ['s']=2.349092},
		}
	},
	{
		['time'] = 60,
		['commands'] = {
		}
	},
},
["UPBODY_AIMING"] =  {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Gun, ['a']=x_axis, ['t']=2.111455, ['s']=0.658464},
			{['c']='turn',['p']=Gun, ['a']=y_axis, ['t']=0.787261, ['s']=0.895506},
			{['c']='turn',['p']=Gun, ['a']=z_axis, ['t']=0.311661, ['s']=0.166201},
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.298118, ['s']=0.435911},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.000000, ['s']=0.100691},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=2.645682, ['s']=3.229899},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.970290, ['s']=0.017308},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-2.702104, ['s']=3.454835},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-1.913730, ['s']=2.190272},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.065394, ['s']=0.949069},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.634728, ['s']=0.762471},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.160193, ['s']=0.208947},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-1.619180, ['s']=0.972581},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.392761, ['s']=0.244176},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.344300, ['s']=0.263560},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.426495, ['s']=0.138497},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.484474, ['s']=0.105602},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-1.848696, ['s']=2.081306},
		}
	},
	{
		['time'] = 2,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.221821, ['s']=0.182437},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.383792, ['s']=0.523352},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.052757, ['s']=0.005633},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.021291, ['s']=0.029033},
		}
	},
	{
		['time'] = 24,
		['commands'] = {
		}
	},
	{
		['time'] = 25,
		['commands'] = {
		}
	},
}






};

uppperBodyAnimations = {
	[eAnimState.idle] = { 	
		[1] = "SLAVED"
	},
	[eAnimState.walking] = "SLAVED",
	[eAnimState.talking] = {
	},
}


lowerBodyAnimations = {
	[eAnimState.walking] = "WALKCYCLE_UNLOADED"
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
	assert(Animations[animname], "No animation with name "..animname)
    local anim = Animations[animname];
	local randoffset 
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1,#commands do
            local cmd = commands[j];
			randoffset = 0.0
			if cmd.r then
				randoffset = math.random(-cmd.r, cmd.r)
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
			if AnimationstateUpperOverride == true then
				boolUpperStateWaitForEnd = true
			end
			 
			if AnimationstateLowerOverride == true then		
				boolLowerStateWaitForEnd = true
			end

			Sleep(30)
		 end
		 
		if AnimationstateUpperOverride == true then	UpperAnimationState = AnimationstateUpperOverride end
		if AnimationstateLowerOverride == true then LowerAnimationState = AnimationstateLowerOverride end
		if AnimationstateUpperOverride == true then	boolUpperStateWaitForEnd = false end
		if AnimationstateLowerOverride == true then boolLowerStateWaitForEnd = false end
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
	 if bodyConfig.boolLoaded == false then
		selectedIdleFunction = math.random(1,#uppperBodyAnimations[eAnimState.idle])
		if selectedIdleFunction and uppperBodyAnimations[eAnimState.idle] and uppperBodyAnimations[eAnimState.idle][selectedIdleFunction] then
			PlayAnimation(uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
		end	
	end
end

UpperAnimationStateFunctions ={
[eAnimState.standing] = 	function () 
								echo("UpperBody Standing")
								resetT(upperBodyPieces, math.pi, false, true)
									 if boolDecoupled == true then
										if math.random(1,10) > 5 then
										playUpperBodyIdleAnimation()							
										resetT(upperBodyPieces, math.pi, false, true)
										end
									 end
								Sleep(30)	
								return eAnimState.standing
							end,
[eAnimState.walking] = 	function () 
							if bodyConfig.boolLoaded == false and math.random(1,100) > 50 then
								boolDecoupled = true
									playUpperBodyIdleAnimation()
								boolDecoupled = false
							end
					
						return eAnimState.walking
					end,
[eAnimState.slaved] = 	function () 
						Sleep(100)
						return eAnimState.slaved
					end
}

LowerAnimationStateFunctions ={
[eAnimState.walking] = function()
						assert(lowerBodyAnimations[eAnimState.walking])
						PlayAnimation(lowerBodyAnimations[eAnimState.walking], conditionalFilterOutUpperBodyTable())					
						return eAnimState.walking
						end,
[eAnimState.standing] = 	function () 
						Spring.Echo("Lower Body standing")
						resetT(lowerBodyPieces, math.pi,false, true)
						Sleep(100)
						return eAnimState.standing
					end
}
LowerAnimationState = eAnimState.standing
boolLowerStateWaitForEnd = false
boolLowerAnimationEnded = false

function animationStateMachineLower(AnimationTable)
Signal(SIG_UP)
SetSignalMask(SIG_UP)

boolLowerStateWaitForEnd = false

local animationTable = AnimationTable
	-- Spring.Echo("lower Animation StateMachine Cycle")
	while true do
		assert(animationTable[LowerAnimationState], "Animationstate not existing "..LowerAnimationState)
		LowerAnimationState = animationTable[LowerAnimationState]()
		
		--Sync Animations
		if boolLowerStateWaitForEnd == true then
			boolLowerAnimationEnded = true
			while boolLowerStateWaitForEnd == true do
				Sleep(33)
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
Signal(SIG_LOW)
SetSignalMask(SIG_LOW)

boolUpperStateWaitForEnd = false
local animationTable = AnimationTable

	while true do
		assert(animationTable[UpperAnimationState], "Animationstate not existing "..UpperAnimationState)

		LowerAnimationState = animationTable[LowerAnimationState]()
		
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
	StartThread(setAnimationState, eAnimState.standing, eAnimState.standing)
end

function script.StartMoving()
	StartThread(setAnimationState, eAnimState.walking, eAnimState.walking)
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


boolStartDecloaking= false
boolStartCloaking= true

function cloakLoop()
	Sleep(100)
	waitTillComplete(unitID)
	Sleep(100)
	while true do 
		if boolStartCloaking == true and not  GG.OperativesDiscovered[unitID]  then
			boolStartCloaking= false
			setSpeedEnv(unitID, 0.175) -- 9,00 -> 1,575  must be as slow as a civilian when moving hidden
			Spring.Echo("Hide "..UnitDefs[Spring.GetUnitDefID(unitID)].name)
			SetUnitValue(COB.WANT_CLOAK, 1)
			boolCloaked= true
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
			StartThread(spawnDecoyCivilian)
		end
		
		Sleep(100)
		if boolStartDecloaking == true then
		boolStartDecloaking= false
			setSpeedEnv(unitID, 1.0)
			SetUnitValue(COB.WANT_CLOAK, 0)
			Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {1}, {}) 
			boolCloaked= false
			if civilianID and doesUnitExistAlive(civilianID) == true then
				Spring.DestroyUnit(civilianID, true, true)
			end
		end
		Sleep(100)
	end
end


function script.Activate()
	boolStartCloaking = true
	return 1
end

function script.Deactivate()
	setSpeedEnv(unitID, 1.0)
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
	StartThread(PlayAnimation,"UPBODY_AIMING")
return  allowTarget(weaponID)
end

function gunAimFunction(weaponID, heading, pitch)
	StartThread(PlayAnimation,"UPBODY_AIMING")
return  allowTarget(weaponID)
end

function sniperAimFunction(weaponID, heading, pitch)
	StartThread(PlayAnimation,"UPBODY_AIMING")
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
