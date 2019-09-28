include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
local center = piece('center');
local Feet1 = piece('Feet1');
local Feet2 = piece('Feet2');
local Head1 = piece('Head1');
local LowArm1 = piece('LowArm1');
local LowArm2 = piece('LowArm2');
local LowLeg1 = piece('LowLeg1');
local LowLeg2 = piece('LowLeg2');
local root = piece('root');
local UpArm1 = piece('UpArm1');
local UpArm2 = piece('UpArm2');
local UpBody = piece('UpBody');
local UpLeg1 = piece('UpLeg1');
local UpLeg2 = piece('UpLeg2');
local scriptEnv = {
	center = center,
	Feet1 = Feet1,
	Feet2 = Feet2,
	Head1 = Head1,
	LowArm1 = LowArm1,
	LowArm2 = LowArm2,
	LowLeg1 = LowLeg1,
	LowLeg2 = LowLeg2,
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
	[UpLeg2 ]= UpLeg2,
	[LowLeg1]= LowLeg1,
	[LowLeg2]= LowLeg2,
	[Feet1 	]= Feet1,
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
    Move(root,y_axis, -3,0)
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
		['time'] = 0,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.040484, ['s']=0.105362},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.156793, ['s']=0.791325},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.097370, ['s']=0.358037},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.017156, ['s']=0.015286},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.212970, ['s']=1.311352},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.018212, ['s']=0.082627},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.236178, ['s']=0.028387},
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.054269, ['s']=0.006896},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.036623, ['s']=0.146744},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000688, ['s']=0.007982},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.216088, ['s']=0.064334},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.203170, ['s']=0.093214},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.391176, ['s']=0.638920},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.391800, ['s']=0.516378},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.075297, ['s']=0.089979},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.105083, ['s']=0.080581},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.010911, ['s']=0.081149},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.029487, ['s']=0.035361},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.012414, ['s']=0.015726},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.280484, ['s']=0.450755},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.023582, ['s']=0.119009},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.005542, ['s']=0.039248},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.885990, ['s']=1.864874},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-1.142516, ['s']=0.158364},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.860676, ['s']=1.823916},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000070, ['s']=2.668950},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.314122, ['s']=0.263780},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.000154, ['s']=2.602659},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.005538, ['s']=0.009773},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.066086, ['s']=0.104004},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000143, ['s']=0.000252},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.025493, ['s']=0.499315},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.026542, ['s']=0.028379},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.014260, ['s']=0.024174},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.291093, ['s']=0.551135},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.076399, ['s']=0.055361},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.003685, ['s']=0.000526},
		}
	},
	{
		['time'] = 6,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.882144, ['s']=1.640890},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.007687, ['s']=0.043350},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.023967, ['s']=0.050249},
		}
	},
	{
		['time'] = 9,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.001485, ['s']=0.431667},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.094039, ['s']=0.009084},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.160515, ['s']=0.484557},
		}
	},
	{
		['time'] = 11,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.461219, ['s']=1.257679},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.293560, ['s']=0.056079},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.455343, ['s']=1.242265},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.124491, ['s']=0.595519},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.028319, ['s']=0.017837},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.414133, ['s']=0.314039},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.029068, ['s']=0.178579},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.038794, ['s']=0.161607},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000427, ['s']=0.000557},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.077246, ['s']=0.113932},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.043998, ['s']=1.676291},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.008892, ['s']=0.002412},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.028198, ['s']=0.008463},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.015869, ['s']=0.018231},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.105000, ['s']=0.301917},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000978, ['s']=0.001978},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.312621, ['s']=1.220097},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.034372, ['s']=0.389534},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.040431, ['s']=0.809411},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.345989, ['s']=0.645944},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.016579, ['s']=0.145237},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.179203, ['s']=0.035040},
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.031109, ['s']=0.667752},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.059460, ['s']=0.025006},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.033922, ['s']=0.219483},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=1.495232, ['s']=2.068027},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.304638, ['s']=0.022157},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.479168, ['s']=2.047649},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.271179, ['s']=0.460661},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.132604, ['s']=0.198867},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.036954, ['s']=0.042552},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.212402, ['s']=0.377795},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.025069, ['s']=0.008283},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.021892, ['s']=0.017773},
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.000000, ['s']=0.072670},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.079206, ['s']=0.101030},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.001069},
		}
	},
	{
		['time'] = 29,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.152109, ['s']=0.207138},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.042260, ['s']=0.529349},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.105737, ['s']=2.312969},
		}
	},
	{
		['time'] = 30,
		['commands'] = {
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.294232, ['s']=0.018834},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.052187, ['s']=0.145267},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.000498, ['s']=0.019118},
		}
	},
	{
		['time'] = 32,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.434997, ['s']=0.282405},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.199754, ['s']=0.381652},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.087931, ['s']=0.109614},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=-0.009824, ['s']=0.201835},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.005613, ['s']=0.054396},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.029465, ['s']=0.004751},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=1.103209, ['s']=1.808363},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-1.311438, ['s']=0.153565},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.084834, ['s']=1.768645},
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.193087, ['s']=1.150654},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.116693, ['s']=0.248108},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.008607, ['s']=0.381146},
		}
	},
	{
		['time'] = 34,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.012521, ['s']=0.056780},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.095028, ['s']=0.019944},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000363, ['s']=0.002682},
		}
	},
	{
		['time'] = 35,
		['commands'] = {
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.260042, ['s']=0.554274},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.131759, ['s']=0.079572},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.003159, ['s']=0.002661},
		}
	},
	{
		['time'] = 36,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.243292, ['s']=2.525488},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.004427, ['s']=0.090026},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.025981, ['s']=0.879363},
		}
	},
	{
		['time'] = 37,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.000001, ['s']=2.242849},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.361461, ['s']=0.085235},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.000001, ['s']=2.218753},
		}
	},
	{
		['time'] = 39,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.041419, ['s']=0.112960},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.063841, ['s']=0.041904},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.001421, ['s']=0.003875},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.385206, ['s']=0.895070},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.031172, ['s']=0.138317},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.002828, ['s']=0.054248},
		}
	},
	{
		['time'] = 40,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.190333, ['s']=0.240189},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.000220, ['s']=0.006472},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.002308, ['s']=0.038127},
		}
	},
	{
		['time'] = 41,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.671168, ['s']=1.170461},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.052752, ['s']=0.011181},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.218376, ['s']=0.307423},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.658612, ['s']=1.912330},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.049425, ['s']=0.104382},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.029532, ['s']=0.032743},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.154303, ['s']=1.042168},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.154733, ['s']=0.114121},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.032344, ['s']=0.122853},
		}
	},
	{
		['time'] = 43,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.400895, ['s']=1.610466},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.178056, ['s']=0.434072},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.400068, ['s']=1.065123},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.343877, ['s']=0.195255},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.126608, ['s']=0.156742},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.112900, ['s']=0.430352},
		}
	},
	{
		['time'] = 46,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.012197, ['s']=0.102708},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 48,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.809039, ['s']=0.902564},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.028867, ['s']=0.123351},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.022829, ['s']=0.040221},
		}
	},
	{
		['time'] = 49,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.000000, ['s']=0.023477},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.007151, ['s']=0.191585},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000681},
		}
	},
	{
		['time'] = 50,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.051281, ['s']=0.185399},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.100212, ['s']=0.328106},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.004147, ['s']=0.005452},
		}
	},
	{
		['time'] = 52,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.311571, ['s']=0.362926},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.014839, ['s']=0.322832},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.247533, ['s']=0.496588},
		}
	},
	{
		['time'] = 53,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=-0.056713, ['s']=2.164381},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.000020, ['s']=0.072118},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000691, ['s']=0.058801},
		}
	},
	{
		['time'] = 55,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.080605, ['s']=0.960869},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.010041, ['s']=0.504045},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.021741, ['s']=1.265427},
		}
	},
	{
		['time'] = 57,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.978545, ['s']=3.669543},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.217402, ['s']=0.540220},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.954462, ['s']=3.579230},
		}
	},
	{
		['time'] = 59,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.175343, ['s']=2.596101},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.144134, ['s']=0.087631},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.013474, ['s']=0.497133},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.770477, ['s']=0.496548},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.141282, ['s']=0.442650},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.164176, ['s']=1.912759},
		}
	},
	{
		['time'] = 61,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.357315, ['s']=0.209179},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.048299, ['s']=0.128458},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.004274, ['s']=0.010844},
		}
	},
	{
		['time'] = 65,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.040484, ['s']=0.105362},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.156793, ['s']=0.791325},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.097370, ['s']=0.358037},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.017156, ['s']=0.015286},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.212970, ['s']=1.311352},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.018212, ['s']=0.082627},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.236178, ['s']=0.028387},
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.054269, ['s']=0.006896},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.036623, ['s']=0.146744},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000688, ['s']=0.007982},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.216088, ['s']=0.064334},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.203170, ['s']=0.093214},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.391176, ['s']=0.638920},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.391800, ['s']=0.516378},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.075297, ['s']=0.089979},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.105083, ['s']=0.080581},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.010911, ['s']=0.081149},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.029487, ['s']=0.035361},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.012414, ['s']=0.015726},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.280484, ['s']=0.450755},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.023582, ['s']=0.119009},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.005542, ['s']=0.039248},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.885990, ['s']=1.864874},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-1.142516, ['s']=0.158364},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.860676, ['s']=1.823916},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000070, ['s']=2.668950},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=1.314122, ['s']=0.263780},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.000154, ['s']=2.602659},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.005538, ['s']=0.009773},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.066086, ['s']=0.104004},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000143, ['s']=0.000252},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.025493, ['s']=0.499315},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.026542, ['s']=0.028379},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.014260, ['s']=0.024174},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.291093, ['s']=0.551135},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.076399, ['s']=0.055361},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.003685, ['s']=0.000526},
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
	
				animCmd[cmd.c](cmd.p,cmd.a,cmd.t ,cmd.s)
				
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
							--resetAll(unitID)
						Sleep(10)
						
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
