include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
local root = piece('root');
local center = piece('center');
local Feet1 = piece('Feet1');
local Feet2 = piece('Feet2');
local Head1 = piece('Head1');
local LowArm1 = piece('LowArm1');
local LowArm2 = piece('LowArm2');
local LowLeg1 = piece('LowLeg1');
local LowLeg2 = piece('LowLeg2');
local UpArm1 = piece('UpArm1');
local UpArm2 = piece('UpArm2');
local UpBody = piece('UpBody');
local UpLeg1 = piece('UpLeg1');
local UpLeg2 = piece('UpLeg2');
local scriptEnv = {	
	center = center,
	root = root,
	Feet1 = Feet1,
	Feet2 = Feet2,
	Head1 = Head1,
	LowArm1 = LowArm1,
	LowArm2 = LowArm2,
	LowLeg1 = LowLeg1,
	LowLeg2 = LowLeg2,
	UpArm1 = UpArm1,
	UpArm2 = UpArm2,
	UpBody = UpBody,
	UpLeg1 = UpLeg1,
	UpLeg2 = UpLeg2,
	x_axis = x_axis,
	y_axis = y_axis,
	z_axis = z_axis,
}
eAnimState = getCivilianAnimationStates()
upperBodyPieces =
{
	[Head1	]  = true,
	[LowArm1 ] = true,
	[LowArm2]  = true,
	[UpBody  ]	= true,
	[UpArm1 ]= true,
	[UpArm2 ]= true,
	}
	
lowerBodyPieces =
{
	[center	]= center,
	[UpLeg1	]= UpLeg1,
	[UpLeg2 ]	= UpLeg2,
	[LowLeg1]	 = LowLeg1,
	[LowLeg2]	 = LowLeg2,
	[Feet1 	]	= Feet1,
	[Feet2	]= Feet2
}
--equipmentname: cellphone, shoppingbags, crates, baby, cigarett, food, stick, demonstrator sign, molotow cocktail

function script.HitByWeapon(x, z, weaponDefID, damage)
end


boolWalking = false
boolTurning = false
boolTurnLeft = false
boolDecoupled = false

function script.Create()
    
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(turnDetector)

	bodyBuild()
	-- StartThread(randSignLoop)

	setupAnimation()
	StartThread(testLoop)
	-- StartThread(animationStateMachineUpper, UpperAnimationStateFunctions)
	-- StartThread(animationStateMachineLower, LowerAnimationStateFunctions)
	-- StartThread(threadStarter)
end

function testLoop()
	while true do
	Sleep(500)
	PlayAnimation(lowerBodyAnimations[eAnimState.Walking],{})

	end
end

function bodyBuild()
	hideAll(unitID)

	Show(UpBody)
	Show(center)
	showT(TablesOfPiecesGroups["UpLeg"])
	showT(TablesOfPiecesGroups["LowLeg"])
	showT(TablesOfPiecesGroups["LowArm"])
	showT(TablesOfPiecesGroups["UpArm"])
	showT(TablesOfPiecesGroups["Head"])
	showT(TablesOfPiecesGroups["Feet"])
	
	--TODO select Animations depending on buildState
end

function script.Killed(recentDamage, _)

 --   createCorpseCUnitGeneric(recentDamage)
    return 1
end

--- -aimining & fire weapon
function script.AimFromWeapon1()
    return center
end

function script.QueryWeapon1()
    return center
end

function script.AimWeapon1(Heading, pitch)
    --aiming animation: instantly turn the gun towards the enemy

    return true
end

function script.FireWeapon1()

    return true
end
---------------------------------------------------------------------ANIMATIONLIB-------------------------------------
Animations = {
["WALKCYCLE_UNLOADED"]={
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.003276, ['s']=0.047913},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.000000, ['s']=0.204093},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.000153, ['s']=0.452838},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.085212, ['s']=0.466964},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.034558, ['s']=0.142855},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.268229, ['s']=0.095394},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.599743, ['s']=0.269354},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.013580, ['s']=0.062876},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.080273, ['s']=0.294891},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.057800, ['s']=0.722131},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.026714, ['s']=0.000237},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.094179, ['s']=0.038655},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=-0.026055, ['s']=0.100874},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.035470, ['s']=0.016634},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.052342, ['s']=0.024826},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.414506, ['s']=1.270073},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.423360, ['s']=0.020010},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.411160, ['s']=1.259370},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.927582, ['s']=2.453976},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.384555, ['s']=0.039604},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.917523, ['s']=2.425568},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.029419, ['s']=0.024516},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.009034, ['s']=0.007240},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000266, ['s']=0.000222},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.297630, ['s']=0.030875},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.044986, ['s']=0.000408},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.013793, ['s']=0.001394},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.329292, ['s']=0.037396},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.111083, ['s']=0.001346},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.037865, ['s']=0.004166},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.206255, ['s']=0.483533},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.081233, ['s']=0.187461},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.009481, ['s']=0.021525},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.064082, ['s']=0.512269},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000097, ['s']=0.001129},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.003016, ['s']=0.024045},
		}
	},
	{
		['time'] = 24,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.714852, ['s']=0.143887},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.235444, ['s']=0.311280},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.117861, ['s']=0.046985},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.006093, ['s']=0.400324},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.006570, ['s']=0.149327},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.185108, ['s']=0.389179},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.586898, ['s']=1.003372},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.094934, ['s']=0.120752},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.008215, ['s']=0.520028},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.064437, ['s']=0.000709},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000098, ['s']=0.000002},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.003033, ['s']=0.000033},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.838224, ['s']=1.728558},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.070939, ['s']=0.212819},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.145042, ['s']=0.185401},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.339844, ['s']=0.097386},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.133514, ['s']=0.378060},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.352311, ['s']=0.076760},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=1.353885, ['s']=0.511563},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.298945, ['s']=0.102732},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.329117, ['s']=0.493913},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.106555, ['s']=0.382150},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.046785, ['s']=0.003599},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.005002, ['s']=0.017582},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.369630, ['s']=0.599076},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.109475, ['s']=0.001378},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.042305, ['s']=0.068717},
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.210448, ['s']=0.199107},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.097023, ['s']=0.091707},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.079812, ['s']=0.018740},
		}
	},
	{
		['time'] = 37,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.042060, ['s']=0.021069},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.006438, ['s']=0.025786},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.072026, ['s']=0.120487},
		}
	},
	{
		['time'] = 40,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.153070, ['s']=0.318327},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.000550, ['s']=0.012040},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.007179, ['s']=0.384576},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.244366, ['s']=1.027596},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.257361, ['s']=0.487281},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.020068, ['s']=0.035558},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.073620, ['s']=0.019678},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000128, ['s']=0.000064},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.003464, ['s']=0.000924},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.989116, ['s']=0.452677},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.077981, ['s']=0.021125},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.177607, ['s']=0.097694},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.150240, ['s']=0.550276},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.046522, ['s']=0.000563},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.007040, ['s']=0.025805},
		}
	},
	{
		['time'] = 48,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.919294, ['s']=0.219045},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.227440, ['s']=0.008576},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.195985, ['s']=0.083705},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.714108, ['s']=0.431844},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.088273, ['s']=0.052201},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.699948, ['s']=0.401120},
		}
	},
	{
		['time'] = 50,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.023288, ['s']=0.031212},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.199184, ['s']=0.665325},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.116855, ['s']=0.210759},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.185743, ['s']=0.308716},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.008452, ['s']=0.233072},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.058878, ['s']=0.179886},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.155684, ['s']=0.087545},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.352259, ['s']=2.122858},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.012897, ['s']=0.216945},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.107980, ['s']=0.232090},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=1.317765, ['s']=0.041677},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.363308, ['s']=0.074264},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.295207, ['s']=0.039127},
		}
	},
	{
		['time'] = 54,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.230526, ['s']=0.294199},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.001246, ['s']=0.002097},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.010759, ['s']=0.013679},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.294116, ['s']=0.269767},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.045034, ['s']=0.002791},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.013635, ['s']=0.012366},
		}
	},
	{
		['time'] = 55,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.094472, ['s']=0.285626},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.000210, ['s']=0.000393},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.004442, ['s']=0.013409},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.048213, ['s']=0.006152},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.039863, ['s']=0.033426},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.074782, ['s']=0.146808},
		}
	},
	{
		['time'] = 59,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.060649, ['s']=0.795301},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.020220, ['s']=0.090319},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.066024, ['s']=0.114425},
		}
	},
	{
		['time'] = 60,
		['commands'] = {
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.223497, ['s']=0.168615},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.114442, ['s']=0.005731},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.025949, ['s']=0.018872},
		}
	},
	{
		['time'] = 70,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.194615, ['s']=0.787598},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.209048, ['s']=0.184387},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.045303, ['s']=0.280881},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.426939, ['s']=0.535671},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.004227, ['s']=0.008131},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.019499, ['s']=0.023836},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.071312, ['s']=0.021327},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.033147, ['s']=0.025855},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.069208, ['s']=0.006366},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.228115, ['s']=0.180002},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.045834, ['s']=0.002183},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.010637, ['s']=0.008178},
		}
	},
	{
		['time'] = 74,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.502519, ['s']=0.288531},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.229538, ['s']=0.192634},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.507292, ['s']=0.262713},
		}
	},
	{
		['time'] = 76,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.369746, ['s']=0.659458},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.036195, ['s']=0.229494},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.027970, ['s']=0.201619},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.126631, ['s']=0.221585},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.083319, ['s']=0.045827},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.101024, ['s']=0.102487},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=1.232685, ['s']=0.159525},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.436671, ['s']=0.137557},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.214012, ['s']=0.152241},
		}
	},
	{
		['time'] = 81,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.347893, ['s']=0.950326},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.002991, ['s']=0.010431},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.015407, ['s']=0.041118},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.988378, ['s']=0.935733},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.021195, ['s']=0.028279},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.039334, ['s']=0.033057},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.283638, ['s']=0.852922},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.045174, ['s']=0.001100},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.013163, ['s']=0.039666},
		}
	},
	{
		['time'] = 85,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.006390, ['s']=0.376884},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.161777, ['s']=0.088634},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.009621, ['s']=0.066903},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.155586, ['s']=0.101129},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.040643, ['s']=0.008994},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.088654, ['s']=0.023335},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.037799, ['s']=0.026035},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.031178, ['s']=0.021713},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.128932, ['s']=0.135376},
		}
	},
	{
		['time'] = 86,
		['commands'] = {
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.043651, ['s']=0.320577},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.117223, ['s']=0.003338},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.005108, ['s']=0.037269},
		}
	},
	{
		['time'] = 89,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.251334, ['s']=0.241396},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.185155, ['s']=0.455410},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.154883, ['s']=0.348690},
		}
	},
	{
		['time'] = 91,
		['commands'] = {
		}
	},
	{
		['time'] = 92,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.568047, ['s']=0.631526},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.026920, ['s']=0.100217},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.060678, ['s']=0.036678},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.035599, ['s']=2.062076},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.352872, ['s']=0.076181},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-1.022932, ['s']=2.033585},
		}
	},
	{
		['time'] = 96,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.601552, ['s']=1.142143},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.407352, ['s']=0.183946},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.596336, ['s']=1.141684},
		}
	},
	{
		['time'] = 97,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.000000, ['s']=0.040499},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000346, ['s']=0.033776},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.138142},
		}
	},
	{
		['time'] = 99,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.237472, ['s']=1.501813},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.001322, ['s']=0.039746},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.011078, ['s']=0.056512},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.371919, ['s']=0.176562},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.043839, ['s']=0.002670},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.017093, ['s']=0.007861},
		}
	},
	{
		['time'] = 101,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.072447, ['s']=0.412816},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.000463, ['s']=0.426212},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.002833, ['s']=0.350885},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.288359, ['s']=0.352462},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.079726, ['s']=0.301879},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.191914, ['s']=0.251919},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.393238, ['s']=0.029365},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.034625, ['s']=0.001962},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.145810, ['s']=0.217225},
		}
	},
	{
		['time'] = 110,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.054644, ['s']=0.201883},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.048777, ['s']=0.016270},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.072203, ['s']=0.032902},
		}
	},
	{
		['time'] = 111,
		['commands'] = {
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.299375, ['s']=0.547981},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.112160, ['s']=0.010850},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.034532, ['s']=0.063051},
		}
	},
	{
		['time'] = 114,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.020845, ['s']=0.254432},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.074834, ['s']=0.202830},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.165887, ['s']=0.444695},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.034585, ['s']=0.676289},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000028, ['s']=0.004311},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.001629, ['s']=0.031496},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.272930, ['s']=0.269971},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.045312, ['s']=0.004018},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.012679, ['s']=0.012040},
		}
	},


}

}

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



uppperBodyAnimations ={
[eAnimState.Walking] = "WALKCYCLE_UNLOADED",
[eAnimState.Slaved] = "SLAVED"
}
lowerBodyAnimations ={
[eAnimState.Walking] = "WALKCYCLE_UNLOADED"

}

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

    local offsets = constructSkeleton(unitID, map.root, {0,0,0});
    
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
            end
        end
    end
end

local animCmd = {['turn']=Turn,['move']=Move};
function PlayAnimation(animname, piecesToFilterOutTable)
	if not piecesToFilterOutTable then piecesToFilterOutTable ={} end
	
    local anim = Animations[animname];
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1,#commands do
            local cmd = commands[j];
			if  not piecesToFilterOutTable[cmd.p] then
				animCmd[cmd.c](cmd.p,cmd.a,cmd.t,cmd.s);
			end
        end
        if(i < #anim) then
            local t = anim[i+1]['time'] - anim[i]['time'];
            Sleep(t*33); -- sleep works on milliseconds
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
		StartThread(setAnimationState, AnimationstateUpperOverride, AnimationstateLowerOverride)
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

--Exposed Function
function setOverrideAnimationState( AnimationstateUpperOverride, AnimationstateLowerOverride,  boolInstantOverride, conditionFunction, boolDecoupledStates)
	boolDecoupled = boolDecoupledStates
	locAnimationstateUpperOverride =AnimationstateUpperOverride
	locAnimationstateLowerOverride = AnimationstateLowerOverride
	locBoolInstantOverride = boolInstantOverride or false
	locConditionFunction = conditionFunction or (function() return true end)
	boolStartThread = true
end


function conditionalFilterOutUpperBodyTable()
	if boolDecoupled == false  then 
		return {}
	 else
		return upperBodyPieces
	end
end

UpperAnimationStateFunctions ={
[eAnimState.Standing] = 	function () 
						resetAll(unitID)
						Sleep(100)
						
						return eAnimState.Standing
					end,
[eAnimState.Walking] = 	function () 
					
						return eAnimState.Walking
					end,
[eAnimState.Slaved] = 	function () 
					
						return eAnimState.Slaved
					end
}

LowerAnimationStateFunctions ={
[eAnimState.Walking] = function()
						PlayAnimation(Animations[lowerBodyAnimations[eAnimState.Walking]], conditionalFilterOutUpperBodyTable())					
						return eAnimState.Walking
				end,
[eAnimState.Standing] = 	function () 
						WMove(center,y_axis, 0, math.pi)
						Sleep(100)
						return eAnimState.Standing
					end
}
LowerAnimationState = eAnimState.Standing
boolLowerStateWaitForEnd = false
boolLowerAnimationEnded = false

function animationStateMachineLower(AnimationTable)
Signal(SIG_UP)
SetSignalMask(SIG_UP)

boolUpperStateWaitForEnd = false

local animationTable = AnimationTable
	Spring.Echo("lower Animation StateMachine Cycle")
	while true do
		assert(animationTable[LowerAnimationState], "Animationstate not existing "..LowerAnimationState)
		LowerAnimationState = animationTable[LowerAnimationState]()
		
		--Sync Animations
		if boolUpperStateWaitForEnd == true then
			boolUpperAnimationEnded = true
			while boolUpperStateWaitForEnd == true do
				Sleep(10)
			end
			boolUpperAnimationEnded = false
		end
	Sleep(1)
	end
	

	

end

UpperAnimationState = eAnimState.Standing
boolUpperStateWaitForEnd = false
boolUpperAnimationEnded = false

function animationStateMachineUpper(AnimationTable)
Signal(SIG_LOW)
SetSignalMask(SIG_LOW)

boolLowerStateWaitForEnd = false
local animationTable = AnimationTable

	while true do
		assert(animationTable[UpperAnimationState], "Animationstate not existing "..UpperAnimationState)

		LowerAnimationState = animationTable[LowerAnimationState]()
		
		--Sync Animations
		if boolLowerStateWaitForEnd == true then
			boolLowerAnimationEnded = true
			while boolLowerStateWaitForEnd == true do
				Sleep(10)
			end
			boolLowerAnimationEnded = false
		end
	Sleep(1)
	end

end

function delayedStop()
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP)
	Sleep(250)
	StartThread(setAnimationState, eAnimState.Standing, eAnimState.Standing)
end

function script.StartMoving()
	StartThread(setAnimationState, eAnimState.Walking, eAnimState.Walking)
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

seriously ={
	--Denial
	" SHAME ",
	"THEY &ARE NOT& US",
	"INOCENT",
	"NOT&GUILTY",
	"COULD&BE&WORSER",
	"CONSPIRACY",
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
	"MOTHERS&AGAINST$",
	
	--Anger
	"ROCKET&IS&RAPE",
	"HYICBM& UP YOUR ASS",
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
	"IT TOLLS&FOR THEE",
	"MEMENTO",
	"MORI",
	"CARPE&DIEM",
	
	--Personification
	"I&LOVE&Ü",
	"Ü&MARRY&ME",
	" DEATH&TO&Ü",
	"  I& BLAME&Ü",
	"WHAT DO&YOU DESIRE?Ü",
	--Humor
	" PRO&TEST&ICLES",
	"NO MORE&TAXES",
	
}
usedPieces ={}
Spring.SetUnitNanoPieces(unitID, { center })
-- function randSignLoop()
	-- lettersize = 34
	-- letterSizeZ= 62
	-- ProtestSign = piece"ProtestSign"
	-- resetAll(unitID)
	
	-- while true do
	-- WTurn(ProtestSign,z_axis, math.rad(0), 1)
	-- bodyBuild()
	-- resetAll(unitID)	
	-- WTurn(ProtestSign,z_axis, math.rad(0), 0)
	-- Show(ProtestSign)
	-- makeProtestSign(8, 3, lettersize, letterSizeZ, seriously[math.random(1,#seriously)], "RAPHI")
	-- WTurn(ProtestSign,x_axis,math.rad(-90),5)
	-- WTurn(ProtestSign,y_axis,math.rad(0),5)
	-- WTurn(ProtestSign,z_axis,math.rad(0),5)
	-- Spin(ProtestSign,z_axis, math.rad(math.random(-3,3)*2),3)
	-- Spin(ProtestSign,x_axis, math.rad(math.random(-2,2)),1)
	-- Spin(ProtestSign,y_axis, math.rad(math.random(-2,2)),1)
	-- Sleep(5000)


	
	-- end

-- end


function makeProtestSign(xIndexMax, zIndexMax, sizeLetterX, sizeLetterZ, sentence, personification)
index = 0

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
