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

SIG_ANIM = 1
SIG_UP = 2
SIG_LOW = 4

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
boolLoaded	= false
function script.Create()
    Move(root,y_axis, -3,0)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(turnDetector)

	bodyBuild()
	-- StartThread(randSignLoop)
	-- spinT(TablesOfPiecesGroups["UpArm"],x_axis,math.rad(2),math.pi)
	setupAnimation()
	-- StartThread(testLoop)

	setOverrideAnimationState( eAnimState.slaved, eAnimState.walking,  true, nil, false)

	StartThread(threadStarter)
end

function testLoop()
	while true do
	PlayAnimation(lowerBodyAnimations[eAnimState.walking],{})

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
["SLAVED"]={
		{
			['time'] = 1,
			['commands'] = {		
			},
		},		
		{
			['time'] = 60,
			['commands'] = {		
			},
		},


},
["UPBODY_PHONE"]={
{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.317617, ['s']=0.076913},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000626, ['s']=0.729646},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.003907, ['s']=0.262642},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.356655, ['s']=0.360143},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.409520, ['s']=0.951310},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.344713, ['s']=2.232887},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-1.066430, ['s']=1.103204},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.285977, ['s']=0.148830},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.045669, ['s']=1.081726},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.009983, ['s']=0.014974},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.436585, ['s']=1.056268},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.804000, ['s']=1.206000},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.783519, ['s']=1.422880, r= 0.25},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.238784, ['s']=0.569120, r= 0.25},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.434815, ['s']=0.300341, r= 0.25},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.278025, ['s']=0.197959},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.163020, ['s']=0.811970},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.003865, ['s']=0.000214},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.218613, ['s']=0.222794},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000298, ['s']=0.610207},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.002713, ['s']=0.004317},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-1.272995, ['s']=0.863781,r= 0.25 },
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.483588, ['s']=1.274776 ,r= 0.25 },
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.211576, ['s']=0.393952,r= 0.25 },
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.604630, ['s']=1.317027},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.280064, ['s']=1.535677},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.869592, ['s']=0.140554},
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.351973, ['s']=1.333600},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000661, ['s']=0.003628},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.126216, ['s']=1.289298},
		}
	},
	{
		['time'] = 30,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.311133, ['s']=0.408401},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000601, ['s']=0.000599},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.003830, ['s']=1.300466},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.655820, ['s']=1.368700},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.214088, ['s']=0.239629},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.895085, ['s']=0.501947},
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.412977, ['s']=0.611068},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000997, ['s']=0.002376},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.088928, ['s']=0.556548},
		}
	},
	{
		['time'] = 35,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.046619, ['s']=1.395026},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.027228, ['s']=3.268232},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.555935, ['s']=3.563817},
		}
	},
	{
		['time'] = 38,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.318324, ['s']=0.354949},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000566, ['s']=0.001617},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.104319, ['s']=0.724677},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-2.160848, ['s']=2.421416,r= 0.25 	},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.443659, ['s']=0.108899 ,r= 0.25		},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.191915, ['s']=0.053620,r= 0.25	},
		}
	},
	{
		['time'] = 39,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-1.019890, ['s']=0.910175},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.278650, ['s']=0.161406},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.240725, ['s']=0.864099},
		}
	},
	{
		['time'] = 46,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.286851, ['s']=0.067442},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.292484, ['s']=0.625540},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.108964, ['s']=0.009953},
		}
	},
	{
		['time'] = 47,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.000000, ['s']=0.116549},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.140764, ['s']=0.283839},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.000000, ['s']=1.389838},
		}
	},
	{
		['time'] = 49,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.224603, ['s']=5.280669, r= 0.25},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.060707, ['s']=1.375542, r= 0.25},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.525988, ['s']=1.816166, r= 0.25},
		}
	},
	{
		['time'] = 51,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.000000, ['s']=3.399633},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.429846, ['s']=0.503986},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.000000, ['s']=4.135748},
		}
	},
	{
		['time'] = 59,
		['commands'] = {
		}
	},
	{
		['time'] = 60,
		['commands'] = {
		}
	},
},
["WALKCYCLE_UNLOADED"]={
{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.040484, ['s']=0.158043},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.156793, ['s']=1.186987},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.097370, ['s']=0.537055},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.017156, ['s']=0.022929},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.212970, ['s']=1.967028},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.018212, ['s']=0.123941},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.236178, ['s']=0.042580},
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.054269, ['s']=0.009961},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.036623, ['s']=0.211963},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000688, ['s']=0.011530},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.216088, ['s']=0.111122},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.203170, ['s']=0.161006},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.391176, ['s']=1.103589},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.391800, ['s']=0.946693},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.075297, ['s']=0.164961},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.105083, ['s']=0.147731},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.010911, ['s']=0.156055},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.029487, ['s']=0.068002},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.012414, ['s']=0.030243},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.280484, ['s']=0.676133},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.023582, ['s']=0.178514},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.005542, ['s']=0.058872},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0, ['s']=2.594607},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.311438, ['s']=0.220333},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.61, ['s']=2.537622},					
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000070, ['s']=3.669806},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.314122, ['s']=0.362698},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.000154, ['s']=3.578656},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.005538, ['s']=0.015104},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.066086, ['s']=0.160734},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000143, ['s']=0.000389},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.025493, ['s']=0.883404},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.026542, ['s']=0.050210},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.014260, ['s']=0.042770},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.291093, ['s']=0.918559},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.076399, ['s']=0.092268},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.003685, ['s']=0.000876},
		}
	},
	{
		['time'] = 5,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.882144, ['s']=2.578542},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.007687, ['s']=0.068122},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.023967, ['s']=0.078963},
		}
	},
	{
		['time'] = 7,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.001485, ['s']=0.791390},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.094039, ['s']=0.016655},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.160515, ['s']=0.888355},
		}
	},
	{
		['time'] = 9,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.124491, ['s']=1.124870},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.028319, ['s']=0.033693},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.414133, ['s']=0.593184},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.461219, ['s']=3.458617},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.293560, ['s']=0.154216},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.455343, ['s']=3.416228},
		}
	},
	{
		['time'] = 10,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.029068, ['s']=0.357159},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.038794, ['s']=0.323215},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000427, ['s']=0.001115},
		}
	},
	{
		['time'] = 11,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.077246, ['s']=0.196216},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.312621, ['s']=1.762362},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.034372, ['s']=0.562660},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.040431, ['s']=1.169149},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.043998, ['s']=2.793819},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.008892, ['s']=0.004019},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.028198, ['s']=0.014104},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.015869, ['s']=0.028175},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.105000, ['s']=0.466599},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000978, ['s']=0.003056},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.345989, ['s']=0.939555},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.016579, ['s']=0.211254},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.179203, ['s']=0.050967},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.031109, ['s']=0.906234},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.059460, ['s']=0.033937},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.033922, ['s']=0.297869},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0  		, ['s']=2.585034},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.304638, ['s']=0.027696},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0		, ['s']=2.559561},
		}
	},
	{
		['time'] = 14,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.212402, ['s']=0.464978},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.025069, ['s']=0.010194},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.021892, ['s']=0.021874},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.271179, ['s']=0.566968},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.132604, ['s']=0.244759},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.036954, ['s']=0.052371},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.000000, ['s']=0.087204},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.079206, ['s']=0.121236},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.001282},
		}
	},
	{
		['time'] = 18,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.152109, ['s']=0.165710},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.042260, ['s']=0.423479},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.105737, ['s']=1.850375},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.294232, ['s']=0.023543},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.052187, ['s']=0.181584},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000498, ['s']=0.023898},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.434997, ['s']=0.458909},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.199754, ['s']=0.620184},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.087931, ['s']=0.178123},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=-0.009824, ['s']=0.269113},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.005613, ['s']=0.072528},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.029465, ['s']=0.006334},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0, ['s']=0.053383},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1.142516, ['s']=0.253383},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.360676, ['s']=0.253383},

		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.193087, ['s']=2.588971},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.116693, ['s']=0.558244},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.008607, ['s']=0.857579},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.012521, ['s']=0.085170},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.095028, ['s']=0.029916},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000363, ['s']=0.004022},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.260042, ['s']=0.791821},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.131759, ['s']=0.113674},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.003159, ['s']=0.003801},
		}
	},
	{
		['time'] = 24,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.243292, ['s']=3.535683},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.004427, ['s']=0.126037},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.025981, ['s']=1.231108},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0, ['s']=3.450537},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.361461, ['s']=0.131130},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0, ['s']=3.413466},
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.154303, ['s']=1.157964},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.154733, ['s']=0.126801},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.032344, ['s']=0.136503},
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.041419, ['s']=0.207093},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.063841, ['s']=0.076824},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.001421, ['s']=0.007103},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.671168, ['s']=1.915300},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.052752, ['s']=0.018296},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.218376, ['s']=0.503056},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.658612, ['s']=3.346578},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.049425, ['s']=0.182669},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.029532, ['s']=0.057300},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.190333, ['s']=0.353219},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.000220, ['s']=0.009517},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.002308, ['s']=0.056069},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.385206, ['s']=1.312770},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.031172, ['s']=0.202865},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.002828, ['s']=0.079564},
		}
	},
	{
		['time'] = 29,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.012197, ['s']=0.130097},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.400895, ['s']=2.415698},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.178056, ['s']=0.651109},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.400068, ['s']=1.597684},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.343877, ['s']=0.303731},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.126608, ['s']=0.243821},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.112900, ['s']=0.669436},
		}
	},
	{
		['time'] = 31,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.809039, ['s']=0.752137},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.028867, ['s']=0.102793},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.022829, ['s']=0.033517},
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.051281, ['s']=0.252817},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.100212, ['s']=0.447417},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.004147, ['s']=0.007434},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.000000, ['s']=0.034148},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.007151, ['s']=0.278669},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000990},
		}
	},
	{
		['time'] = 36,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.311571, ['s']=0.589755},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.014839, ['s']=0.524602},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=0.247533, ['s']=0.806955},
		}
	},
	{
		['time'] = 37,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.080605, ['s']=1.372671},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.010041, ['s']=0.720064},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.021741, ['s']=1.807753},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=-0.056713, ['s']=3.710367},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000020, ['s']=0.123631},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.000691, ['s']=0.100802},
		}
	},
	{
		['time'] = 38,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.175343, ['s']=2.596101},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.144134, ['s']=0.087631},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.013474, ['s']=0.497133},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.770477, ['s']=0.496548},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.141282, ['s']=0.442650},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.164176, ['s']=1.912759},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.978545, ['s']=4.892724},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=1.217402, ['s']=0.720294},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.954462, ['s']=4.772306},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.357315, ['s']=0.418358},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.048299, ['s']=0.256915},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.004274, ['s']=0.021689},
		}
	},
	{
		['time'] = 44,
		['commands'] = {
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
[eAnimState.idle] = { 
	[1] = "UPBODY_PHONE",
	[2] = "SLAVED"
},
[eAnimState.walking] = "WALKCYCLE_UNLOADED",
}

lowerBodyAnimations ={
[eAnimState.walking] = "WALKCYCLE_UNLOADED"

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
	local switchAxis = function(axis) 
		if axis == z_axis then return y_axis end
		if axis == y_axis then return z_axis end
		return axis
	end

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

function PlayAnimation(animname, piecesToFilterOutTable)
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
				animCmd[cmd.c](cmd.p, cmd.a, axisSign[cmd.a] * (cmd.t + randoffset) ,cmd.s)
				
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
			if AnimhationstateUpperOverride then
				boolUpperStateWaitForEnd = true
			end
			 
			if AnimationstateLowerOverride	then		
				boolLowerStateWaitForEnd = true
			end

			Sleep(30)
		 end
		if AnimationstateUpperOverride then	UpperAnimationState = AnimationstateUpperOverride end
		if AnimationstateLowerOverride then LowerAnimationState = AnimationstateLowerOverride end
		if AnimationstateUpperOverride then	boolUpperStateWaitForEnd = false end
		if AnimationstateLowerOverride then boolLowerStateWaitForEnd = false end
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

function setBehaviourStateMachineExternal( boolStartStateMachine, BEHAVIOUR_STATE)
	Spring.Echo("TODO: Create behavioural State machine")
end
--</Exposed Function>
function conditionalFilterOutUpperBodyTable()
	if boolDecoupled == false  then 
		return {}
	 else
		return upperBodyPieces
	end
end

function showHideProps(selectedIdleFunction, bShow)
	if selectedIdleFunction== 1 then
	
	elseif selectedIdleFunction == 2 then
	
	elseif selectedIdleFunction == 3 then
	
	end

end

function playUpperBodyIdleAnimation()
							selectedIdleFunction =math.random(1,#uppperBodyAnimations[eAnimState.idle])
							showHideProps(selectedIdleFunction, true)
							PlayAnimation(uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
							showHideProps(selectedIdleFunction, false)

end

UpperAnimationStateFunctions ={
[eAnimState.standing] = 	function () 
								--playUpperBodyIdleAnimation()
								Sleep(10)						
								return eAnimState.standing
							end,
[eAnimState.walking] = 	function () 
							if boolLoaded == false and math.random(1,100) > 50 then
								boolDecoupled = true
								--playUpperBodyIdleAnimation()
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
						PlayAnimation(lowerBodyAnimations[eAnimState.walking], conditionalFilterOutUpperBodyTable())					
						return eAnimState.walking
						end,
[eAnimState.standing] = 	function () 
						resetT(lowerBodyPieces, math.pi)
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
	Spring.Echo("lower Animation StateMachine Cycle")
	while true do
		assert(animationTable[LowerAnimationState], "Animationstate not existing "..LowerAnimationState)
		LowerAnimationState = animationTable[LowerAnimationState]()
		
		--Sync Animations
		if boolLowerStateWaitForEnd == true then
			boolLowerAnimationEnded = true
			while boolLowerStateWaitForEnd == true do
				Sleep(33)
				Spring.Echo("lower Animation Waiting For End")
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
	"ALWAYS&LCOK ON&BRIGHTSIDE",
	
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
	"FOR WHOM&THE BELL",
	"IS TOLLS&FOR THEE",
	"MEMENTO",
	"MORI",
	"CARPE&DIEM",
	
	--Personification
	"I&LOVE&Ü",
	"Ü&U HAVE A&SON",
	"Ü&MARRY&ME",
	" DEATH&TO&Ü",
	"  I& BLAME&Ü",
	"WHAT DO&YOU DESIRE?Ü",
	--Humor
	" PRO&TEST&ICLES",
	"NO MORE&TAXES",
	"NO&PROTEST"
	
}


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
	-- makeProtestSign(8, 3, lettersize, letterSizeZ, signMessages[math.random(1,#signMessages)], "RAPHI")
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
