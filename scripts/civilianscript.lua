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
local cigarett = piece('cigarett');
local cofee = piece('cofee');
local scriptEnv = {
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
["WALKCYCLE_WOUNDED"] ={
	{
		['time'] = 0,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.046779, ['s']=0.077966},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.001801, ['s']=0.003002},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.001366, ['s']=0.002276},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.017392, ['s']=0.030692},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.000917, ['s']=0.001618},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.108989, ['s']=0.163483},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.020146, ['s']=0.030219},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.210369, ['s']=0.371240},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.030644, ['s']=0.054077},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.001749, ['s']=0.003086},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.168795, ['s']=0.297873},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.024464, ['s']=0.043171},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.001759, ['s']=0.003104},
		}
	},
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.015086, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.184675, ['s']=0.277012},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.382633, ['s']=0.209045},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.618961, ['s']=0.067639},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.389230, ['s']=0.123862},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.246223, ['s']=0.000261},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.002229, ['s']=0.003519},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.148268, ['s']=0.234108},
		}
	},
	{
		['time'] = 2,
		['commands'] = {
		}
	},
	{
		['time'] = 3,
		['commands'] = {
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.209251, ['s']=0.283303},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.038430, ['s']=0.046891},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.004623, ['s']=0.005270},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.245139, ['s']=0.594142},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.044878, ['s']=0.098506},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.006218, ['s']=0.005829},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.201101, ['s']=0.462370},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.037074, ['s']=0.076922},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.003177, ['s']=0.001772},
		}
	},
	{
		['time'] = 18,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.044961, ['s']=0.010907},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.240925, ['s']=1.456358},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.304959, ['s']=1.837948},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.000000, ['s']=0.083837},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.015497},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.248179, ['s']=0.011739},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.057524, ['s']=0.331773},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.125526, ['s']=0.136452},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.019449, ['s']=0.032727},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.026917, ['s']=0.201880},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.160733, ['s']=0.179566},
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.347416, ['s']=0.264124},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.591575, ['s']=0.205393},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.360203, ['s']=0.217701},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.332979, ['s']=0.629901},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.060683, ['s']=0.300404},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.009261, ['s']=0.523700},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.015086, ['s']=0.008182},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.000000, ['s']=0.050470},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.046102, ['s']=0.387815},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.247212, ['s']=0.007255},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.026799, ['s']=0.230436},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.117445, ['s']=0.060608},
		}
	},
	{
		['time'] = 26,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.204393, ['s']=0.268170},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.666445, ['s']=0.140380},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.281122, ['s']=0.148278},
		}
	},
	{
		['time'] = 29,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.246388, ['s']=0.002059},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000068, ['s']=0.067168},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.004489, ['s']=0.304835},
		}
	},
	{
		['time'] = 40,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.000000, ['s']=0.387062},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.070860},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.009818},
		}
	},
	{
		['time'] = 41,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.015086, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.000000, ['s']=0.072793},
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.000000, ['s']=0.554965},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.000000, ['s']=0.101138},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.000000, ['s']=0.015435},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.000000, ['s']=0.348751},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.000000, ['s']=0.064050},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.246388, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000107},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.007088},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.000000, ['s']=0.335168},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.061790},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.005294},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.236302, ['s']=0.053182},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.666309, ['s']=0.000227},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.302527, ['s']=0.035675},
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
		['time'] = 0,
		['commands'] = {
		
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.139018, ['s']=0.214771},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.017453, ['s']=0.057163},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.091487, ['s']=0.152119},
			
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.104861, ['s']=0.786650},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.009331, ['s']=0.090051},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.051170, ['s']=0.984351},
			
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.000000, ['s']=0.891025},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.615430, ['s']=0.075622},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.000000, ['s']=0.507045},
			
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000000, ['s']=0.916466},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.615579, ['s']=0.080057},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.000000, ['s']=0.521190},
		}
	},
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
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.010911, ['s']=0.156055},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.029487, ['s']=0.068002},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.012414, ['s']=0.030243},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.280484, ['s']=0.676133},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.023582, ['s']=0.178514},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.005542, ['s']=0.058872},
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
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.137398, ['s']=0.088737},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.074715, ['s']=0.229217},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.293361, ['s']=0.660521},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.043998, ['s']=2.793819},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.008892, ['s']=0.004019},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.028198, ['s']=0.014104},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.465619, ['s']=0.997755},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.558981, ['s']=0.120961},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.283341, ['s']=0.607158},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.401825, ['s']=1.506842},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.580885, ['s']=0.130103},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.227009, ['s']=0.851283},
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
		}
	},
	{
		['time'] = 14,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.099758, ['s']=0.098149},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.104720, ['s']=0.305433},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.087433, ['s']=0.010135},
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
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000000, ['s']=1.095885},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.615579, ['s']=0.094620},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.000000, ['s']=0.619115},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=-0.009824, ['s']=0.269113},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.005613, ['s']=0.072528},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.029465, ['s']=0.006334},
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.121166, ['s']=0.044270},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.025828, ['s']=0.133329},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.077655, ['s']=0.588290},
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
		['time'] = 26,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.139018, ['s']=0.107072},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.017453, ['s']=0.333199},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.091487, ['s']=0.011056},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.000000, ['s']=1.396857},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.615430, ['s']=0.169346},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.000000, ['s']=0.850022},
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
		}
	},
	{
		['time'] = 31,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.809039, ['s']=0.752137},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.028867, ['s']=0.102793},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.022829, ['s']=0.033517},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.366586, ['s']=0.785542},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.583556, ['s']=0.068620},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.208476, ['s']=0.446734},
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.051281, ['s']=0.252817},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.100212, ['s']=0.447417},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.004147, ['s']=0.007434},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.183577, ['s']=0.831118},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.023688, ['s']=0.005837},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.309758, ['s']=1.056582},
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
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.356410, ['s']=1.188033},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.585181, ['s']=0.100829},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.202818, ['s']=0.676060},
		}
	},
	{
		['time'] = 37,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.080605, ['s']=1.372671},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.010041, ['s']=0.720064},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.021741, ['s']=1.807753},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=0.038792, ['s']=0.375849},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.009223, ['s']=0.100035},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.162475, ['s']=0.266209},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=-0.056713, ['s']=3.710367},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.000020, ['s']=0.123631},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.000691, ['s']=0.100802},
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
	{
		['time'] = 45,
		['commands'] = {
		}
	},
},
["WALKCYCLE_WOUNDED"]={
{
		['time'] = 0,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.046779, ['s']=0.077966},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=-0.001801, ['s']=0.003002},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.001366, ['s']=0.002276},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=-0.017392, ['s']=0.030692},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.000917, ['s']=0.001618},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.108989, ['s']=0.163483},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.020146, ['s']=0.030219},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.210369, ['s']=0.371240},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.030644, ['s']=0.054077},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.001749, ['s']=0.003086},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.168795, ['s']=0.297873},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.024464, ['s']=0.043171},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.001759, ['s']=0.003104},
		}
	},
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.015086, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.184675, ['s']=0.277012},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.382633, ['s']=0.209045},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.618961, ['s']=0.067639},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.389230, ['s']=0.123862},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.246223, ['s']=0.000261},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.002229, ['s']=0.003519},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.148268, ['s']=0.234108},
		}
	},
	{
		['time'] = 2,
		['commands'] = {
		}
	},
	{
		['time'] = 3,
		['commands'] = {
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.209251, ['s']=0.283303},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=-0.038430, ['s']=0.046891},
			{['c']='turn',['p']=Feet2, ['a']=z_axis, ['t']=-0.004623, ['s']=0.005270},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.245139, ['s']=0.594142},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.044878, ['s']=0.098506},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.006218, ['s']=0.005829},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.201101, ['s']=0.462370},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.037074, ['s']=0.076922},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.003177, ['s']=0.001772},
		}
	},
	{
		['time'] = 18,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.044961, ['s']=0.010907},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.240925, ['s']=1.456358},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.304959, ['s']=1.837948},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.000000, ['s']=0.083837},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.015497},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.248179, ['s']=0.011739},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.057524, ['s']=0.331773},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.125526, ['s']=0.136452},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.019449, ['s']=0.032727},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.026917, ['s']=0.201880},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.160733, ['s']=0.179566},
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.347416, ['s']=0.264124},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.591575, ['s']=0.205393},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.360203, ['s']=0.217701},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=-0.332979, ['s']=0.629901},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.060683, ['s']=0.300404},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=-0.009261, ['s']=0.523700},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.015086, ['s']=0.008182},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=0.000000, ['s']=0.050470},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.046102, ['s']=0.387815},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.247212, ['s']=0.007255},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.026799, ['s']=0.230436},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.117445, ['s']=0.060608},
		}
	},
	{
		['time'] = 26,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.204393, ['s']=0.268170},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.666445, ['s']=0.140380},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.281122, ['s']=0.148278},
		}
	},
	{
		['time'] = 29,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.246388, ['s']=0.002059},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000068, ['s']=0.067168},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.004489, ['s']=0.304835},
		}
	},
	{
		['time'] = 40,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.000000, ['s']=0.387062},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.070860},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.009818},
		}
	},
	{
		['time'] = 41,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=-0.015086, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.000000, ['s']=0.072793},
			{['c']='turn',['p']=Feet1, ['a']=x_axis, ['t']=0.000000, ['s']=0.554965},
			{['c']='turn',['p']=Feet1, ['a']=y_axis, ['t']=0.000000, ['s']=0.101138},
			{['c']='turn',['p']=Feet1, ['a']=z_axis, ['t']=0.000000, ['s']=0.015435},
			{['c']='turn',['p']=Feet2, ['a']=x_axis, ['t']=0.000000, ['s']=0.348751},
			{['c']='turn',['p']=Feet2, ['a']=y_axis, ['t']=0.000000, ['s']=0.064050},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.246388, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000107},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.007088},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.000000, ['s']=0.335168},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.061790},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.005294},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.236302, ['s']=0.053182},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.666309, ['s']=0.000227},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.302527, ['s']=0.035675},
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
["WALKCYCLE_ROLLY"]={{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.077418, ['s']=0.061639},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.894400, ['s']=0.062763},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.041369, ['s']=0.038654},
			{['c']='turn',['p']=trolley, ['a']=x_axis, ['t']=0.471759, ['s']=0.046341},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.242967, ['s']=0.002215},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.186960, ['s']=0.003036},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-1.157361, ['s']=0.375518},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.000145, ['s']=0.000141},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.009999, ['s']=0.009676},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.014522, ['s']=0.254374},
		}
	},
	{
		['time'] = 31,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.015778, ['s']=0.063765},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.831637, ['s']=0.064927},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.002715, ['s']=0.039987},
		}
	},
	{
		['time'] = 32,
		['commands'] = {
			{['c']='turn',['p']=trolley, ['a']=x_axis, ['t']=0.423873, ['s']=0.053206},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.240679, ['s']=0.002543},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.183823, ['s']=0.003486},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.769325, ['s']=0.431151},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.000000, ['s']=0.000161},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.011110},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.248331, ['s']=0.292060},
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
["UPBODY_AGGRO_TALK"]={
	{
		['time'] = 0,
		['commands'] = {
			
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.050508, ['s']=0.379929},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.794486, ['s']=0.364301},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-1.133969, ['s']=0.357030},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.797779, ['s']=1.292637},
		
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.055937, ['s']=0.079489},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.387603, ['s']=1.772668},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.034407, ['s']=0.095823},
		
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-2.374084, ['s']=2.784815},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.033274, ['s']=0.047021},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.013436, ['s']=0.003703},
			
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-2.053590, ['s']=2.333279},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.721923, ['s']=3.016129},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.740506, ['s']=3.256374},
		
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.015417, ['s']=0.236374},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 7,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-1.360008, ['s']=2.123916},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.730244, ['s']=0.513963},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.397316, ['s']=2.147583},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.203889, ['s']=2.774552},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.765950, ['s']=0.066041},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.695412, ['s']=2.153876},
		}
	},
	{
		['time'] = 10,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.048429, ['s']=0.228316},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.527957, ['s']=1.142270},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.725322, ['s']=1.751343},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.001014, ['s']=3.414708},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.103547, ['s']=0.509847},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.067904, ['s']=3.239687},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.529153, ['s']=1.177016},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.098887, ['s']=6.587234},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-1.136410, ['s']=1.687738},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.011287, ['s']=0.029982},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.016929, ['s']=0.004763},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.005059, ['s']=0.123433},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 24,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.344935, ['s']=1.807424},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.344614, ['s']=0.461348},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.047984, ['s']=2.627256},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.067652, ['s']=0.427998},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.499885, ['s']=2.867074},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.499941, ['s']=0.767678},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.310028, ['s']=5.691143},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.644192, ['s']=1.467679},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.160050, ['s']=2.019668},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.486740, ['s']=0.695572},
		}
	},
	{
		['time'] = 36,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.128774, ['s']=0.446110},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-2.144801, ['s']=5.999552},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-1.191648, ['s']=2.823448},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=2.444769, ['s']=7.989284},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.037389, ['s']=1.790915},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.026020, ['s']=1.753204},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.056765, ['s']=0.844208},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.509158, ['s']=2.883219},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.018160, ['s']=0.472968},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.019315, ['s']=1.558084},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.118529, ['s']=0.620602},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 41,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-1.313511, ['s']=1.328257},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.014428, ['s']=0.023552},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.018715, ['s']=0.013394},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.648766, ['s']=2.137193},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.991157, ['s']=0.286416},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.280725, ['s']=3.091492},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.433385, ['s']=1.412322},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=1.419432, ['s']=4.336356},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.136855, ['s']=3.580860},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.610368, ['s']=1.004489},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.003494, ['s']=0.015619},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.011091, ['s']=0.010890},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-3.119716, ['s']=4.831673},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.278273, ['s']=0.780341},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.029676, ['s']=0.031084},
		}
	},
	{
		['time'] = 55,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.037389, ['s']=1.283929},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.026020, ['s']=3.942142},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.056765, ['s']=3.255327},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.509158, ['s']=4.392430},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.018160, ['s']=0.709401},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.019315, ['s']=0.028259},
		}
	},
	{
		['time'] = 66,
		['commands'] = {
		}
	},
},
["UPBODY_NORMAL_TALK"]={
	{
		['time'] = 0,
		['commands'] = {
		
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.009083, ['s']=0.078608},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=LowArm2, ['a']=x_axis, ['t']=4.899570, ['s']=0.000000},
			{['c']='move',['p']=LowArm2, ['a']=y_axis, ['t']=0.088726, ['s']=0.000000},
			{['c']='move',['p']=LowArm2, ['a']=z_axis, ['t']=19.415604, ['s']=0.000000},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.011472, ['s']=0.452530},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.000554, ['s']=0.094582},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=0.008242, ['s']=0.317252},
			{['c']='move',['p']=UpArm1, ['a']=x_axis, ['t']=-2.304994, ['s']=0.000000},
			{['c']='move',['p']=UpArm1, ['a']=y_axis, ['t']=-0.067494, ['s']=0.000000},
			{['c']='move',['p']=UpArm1, ['a']=z_axis, ['t']=21.692083, ['s']=0.000000},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.004839, ['s']=0.009532},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.378985, ['s']=0.245984},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.028545, ['s']=0.021297},
			{['c']='move',['p']=UpBody, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='move',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.093853, ['s']=0.209316},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 1,
		['commands'] = {
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.014752, ['s']=0.148313},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 18,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.205645, ['s']=0.737109},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.163123, ['s']=0.212891},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.015469, ['s']=0.045869},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.113488, ['s']=0.122251},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.011511, ['s']=0.005133},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.551174, ['s']=0.132453},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.043453, ['s']=0.011468},
		}
	},
	{
		['time'] = 26,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.051642, ['s']=0.924019},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 30,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.441059, ['s']=0.452530},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.094028, ['s']=0.094582},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.309010, ['s']=0.317252},
		}
	},
	{
		['time'] = 31,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.037382, ['s']=0.085562},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.071781, ['s']=0.122203},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 36,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.111530, ['s']=0.741476},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 39,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.024322, ['s']=0.261623},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.010805, ['s']=0.165172},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 49,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.056248, ['s']=0.087070},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.361822, ['s']=0.541904},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.058280, ['s']=0.116756},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.227590, ['s']=0.311185},
		}
	},
	{
		['time'] = 60,
		['commands'] = {
		}
	},
	},
["UPBODY_PHONE"]={
		{
		['time'] = 0,
		['commands'] = {
			
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.045881, ['s']=0.229407},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.196004, ['s']=0.001407},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.005441, ['s']=0.027205},
		
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-2.100111, ['s']=0.070260},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=1.226809, ['s']=0.032465},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.652054, ['s']=0.053747},
		
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.481837, ['s']=5.372822},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=2.859853, ['s']=2.345814},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=2.101742, ['s']=3.011065},
			
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.904468, ['s']=0.205598},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.269985, ['s']=0.064629},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.336757, ['s']=0.047300},
		
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.964919, ['s']=0.006732},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.414678, ['s']=1.108110},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.002218, ['s']=0.049504},
		
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.045319, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.053385, ['s']=0.042968},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 5,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=1.240101, ['s']=3.791323},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=2.235171, ['s']=3.123409},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=2.841845, ['s']=3.700511},
		}
	},
	{
		['time'] = 6,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.000802, ['s']=0.175062},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.196288, ['s']=0.001065},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000095, ['s']=0.020761},
		}
	},
	{
		['time'] = 11,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.738226, ['s']=1.158174},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=2.852072, ['s']=1.423618},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=1.920629, ['s']=2.125883},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.052336, ['s']=0.201731},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.105158, ['s']=1.199621},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.092752, ['s']=0.219161},
		}
	},
	{
		['time'] = 14,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.098156, ['s']=0.296875},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.195385, ['s']=0.002707},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.011617, ['s']=0.035137},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.045319, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.080521, ['s']=0.054271},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 21,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-2.149293, ['s']=0.061477},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=1.204084, ['s']=0.028407},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.614431, ['s']=0.047028},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.760550, ['s']=0.179898},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.315225, ['s']=0.056551},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.303648, ['s']=0.041387},
		}
	},
	{
		['time'] = 24,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.017473, ['s']=0.302563},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.196207, ['s']=0.003081},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.002074, ['s']=0.035788},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=2.671537, ['s']=5.272667},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=2.409114, ['s']=1.208068},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=3.865303, ['s']=5.303657},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.212641, ['s']=0.437195},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.070820, ['s']=0.093650},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.029634, ['s']=0.172140},
		}
	},
	{
		['time'] = 32,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.098156, ['s']=0.201709},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.195385, ['s']=0.002054},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.011617, ['s']=0.023859},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.045319, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.053385, ['s']=0.067839},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 35,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=2.310166, ['s']=1.548734},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=1.965195, ['s']=1.902509},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=2.910463, ['s']=4.092169},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-2.386995, ['s']=5.032946},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=-0.009300, ['s']=0.263655},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.002601, ['s']=0.138147},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=1.240101, ['s']=3.566881},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=2.235171, ['s']=0.899919},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=2.841845, ['s']=0.228729},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.967388, ['s']=2.661764},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.008370, ['s']=0.033133},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.015934, ['s']=0.034752},
		}
	},
	{
		['time'] = 44,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.017473, ['s']=0.403418},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.196207, ['s']=0.004108},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.002074, ['s']=0.047717},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.077734, ['s']=0.052175},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
		}
	},
	{
		['time'] = 50,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.000000, ['s']=0.074883},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.196285, ['s']=0.000335},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.008887},
		}
	},
	{
		['time'] = 51,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=1.377307, ['s']=0.588025},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=2.468884, ['s']=1.001626},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=2.603586, ['s']=1.021106},
		}
	},
	{
		['time'] = 57,
		['commands'] = {
		}
	},
	{
		['time'] = 58,
		['commands'] = {
		}
	},
},
["UPBODY_LOADED"]={
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Handbag, ['a']=x_axis, ['t']=-0.029155, ['s']=0.016287},
			{['c']='turn',['p']=Handbag, ['a']=y_axis, ['t']=-0.045022, ['s']=0.118480},
			{['c']='turn',['p']=Handbag, ['a']=z_axis, ['t']=-1.416788, ['s']=0.143623},
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.265485, ['s']=0.140177},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.014153, ['s']=0.003016},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.159935, ['s']=0.018162},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.134383, ['s']=0.047092},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.244268, ['s']=0.070327},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.153013, ['s']=0.044243},
			{['c']='turn',['p']=ShoppingBag, ['a']=x_axis, ['t']=-0.117924, ['s']=0.005448},
			{['c']='turn',['p']=ShoppingBag, ['a']=y_axis, ['t']=-0.148104, ['s']=0.046261},
			{['c']='turn',['p']=ShoppingBag, ['a']=z_axis, ['t']=-1.794599, ['s']=0.384701},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.169240, ['s']=0.024587},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.459893, ['s']=0.022664},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.143636, ['s']=0.016866},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.183250, ['s']=0.305417},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.301351, ['s']=0.008707},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.054955, ['s']=0.091592},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.011348, ['s']=0.022963},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 3,
		['commands'] = {
			{['c']='turn',['p']=SittingBaby, ['a']=x_axis, ['t']=-0.016479, ['s']=0.017047},
			{['c']='turn',['p']=SittingBaby, ['a']=y_axis, ['t']=0.157080, ['s']=0.162496},
			{['c']='turn',['p']=SittingBaby, ['a']=z_axis, ['t']=0.052360, ['s']=0.054165},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.185410, ['s']=0.014700},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.474434, ['s']=0.013220},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.132428, ['s']=0.010190},
		}
	},
	{
		['time'] = 18,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.059251, ['s']=0.055273},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=ShoppingBag, ['a']=x_axis, ['t']=-0.119448, ['s']=0.011434},
			{['c']='turn',['p']=ShoppingBag, ['a']=y_axis, ['t']=-0.133895, ['s']=0.106565},
			{['c']='turn',['p']=ShoppingBag, ['a']=z_axis, ['t']=-1.676702, ['s']=0.884227},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.107804, ['s']=0.379636},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.304904, ['s']=0.004634},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.032478, ['s']=0.114042},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=Handbag, ['a']=x_axis, ['t']=-0.019781, ['s']=0.011249},
			{['c']='turn',['p']=Handbag, ['a']=y_axis, ['t']=0.026275, ['s']=0.085556},
			{['c']='turn',['p']=Handbag, ['a']=z_axis, ['t']=-1.516682, ['s']=0.119873},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=ShoppingBag, ['a']=x_axis, ['t']=-0.118826, ['s']=0.001166},
			{['c']='turn',['p']=ShoppingBag, ['a']=y_axis, ['t']=-0.097433, ['s']=0.068367},
			{['c']='turn',['p']=ShoppingBag, ['a']=z_axis, ['t']=-1.373211, ['s']=0.569046},
		}
	},
	{
		['time'] = 26,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.148671, ['s']=0.106194},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.016667, ['s']=0.002285},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.175070, ['s']=0.013759},
		}
	},
	{
		['time'] = 32,
		['commands'] = {
			{['c']='turn',['p']=SittingBaby, ['a']=x_axis, ['t']=0.000000, ['s']=0.019014},
			{['c']='turn',['p']=SittingBaby, ['a']=y_axis, ['t']=0.000000, ['s']=0.181246},
			{['c']='turn',['p']=SittingBaby, ['a']=z_axis, ['t']=0.000000, ['s']=0.060415},
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.084152, ['s']=0.055812},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.319284, ['s']=0.083351},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.200206, ['s']=0.052437},
		}
	},
	{
		['time'] = 39,
		['commands'] = {
			{['c']='turn',['p']=ShoppingBag, ['a']=x_axis, ['t']=-0.120942, ['s']=0.010576},
			{['c']='turn',['p']=ShoppingBag, ['a']=y_axis, ['t']=-0.113837, ['s']=0.082020},
			{['c']='turn',['p']=ShoppingBag, ['a']=z_axis, ['t']=-1.509792, ['s']=0.682902},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000000, ['s']=0.179674},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.306575, ['s']=0.002785},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.000000, ['s']=0.054129},
		}
	},
	{
		['time'] = 44,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.024360, ['s']=0.069781},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
			{['c']='turn',['p']=Handbag, ['a']=x_axis, ['t']=-0.018840, ['s']=0.001881},
			{['c']='turn',['p']=Handbag, ['a']=y_axis, ['t']=0.030015, ['s']=0.007481},
			{['c']='turn',['p']=Handbag, ['a']=z_axis, ['t']=-1.507750, ['s']=0.017865},
			{['c']='turn',['p']=ShoppingBag, ['a']=x_axis, ['t']=-0.121193, ['s']=0.000502},
			{['c']='turn',['p']=ShoppingBag, ['a']=y_axis, ['t']=-0.120347, ['s']=0.013020},
			{['c']='turn',['p']=ShoppingBag, ['a']=z_axis, ['t']=-1.563779, ['s']=0.107974},
		}
	},
	{
		['time'] = 46,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.159405, ['s']=0.055725},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.450827, ['s']=0.050587},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.150382, ['s']=0.038475},
		}
	},
	{
		['time'] = 58,
		['commands'] = {
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
["UPBODY_CONSUMPTION"]={
{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=-0.024027, ['s']=0.075866},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.692945, ['s']=0.139575},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.346358, ['s']=1.353786},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.296930, ['s']=0.884950},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.018606, ['s']=0.026580},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.533651, ['s']=0.267672},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.021920, ['s']=0.031314},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.320708, ['s']=1.448925},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.013759, ['s']=0.019656},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.551230, ['s']=0.109403},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.580449, ['s']=0.829214},
		}
	},
	{
		['time'] = 2,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.073488, ['s']=0.348357},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 10,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.042848, ['s']=0.131317},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.650712, ['s']=0.097461},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.152739, ['s']=1.151762},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.419367, ['s']=0.282548},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.276352, ['s']=1.377832},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.015963, ['s']=0.070570},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.038829, ['s']=0.015069},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.000000, ['s']=0.017443},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.474207, ['s']=0.055729},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.000000, ['s']=0.020550},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000000, ['s']=0.012899},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.576427, ['s']=0.023622},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.000000, ['s']=0.544171},
		}
	},
	{
		['time'] = 25,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-2.644823, ['s']=2.982333},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.150740, ['s']=0.005998},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=2.097920, ['s']=2.035660},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.633075, ['s']=0.713446},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.898955, ['s']=1.797910},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.038546, ['s']=0.000850},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 32,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.130177, ['s']=0.428302},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 35,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.403009, ['s']=7.450884},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.352192, ['s']=3.017588},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.752484, ['s']=2.072619},
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.090092, ['s']=0.128866},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 40,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.100193, ['s']=0.449771},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.120828, ['s']=0.309535},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 44,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.064020, ['s']=0.852129},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 46,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.130177, ['s']=0.116749},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 47,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=-0.037477, ['s']=0.112746},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 54,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.721021, ['s']=0.352592},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.627812, ['s']=0.073408},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 61,
		['commands'] = {
			{['c']='turn',['p']=UpBody, ['a']=x_axis, ['t']=0.019407, ['s']=0.121895},
			{['c']='turn',['p']=UpBody, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpBody, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 63,
		['commands'] = {
			{['c']='turn',['p']=Head1, ['a']=x_axis, ['t']=0.011378, ['s']=0.296999},
			{['c']='turn',['p']=Head1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.650712, ['s']=1.486218},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.152739, ['s']=3.029583},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.419367, ['s']=1.998701},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.276352, ['s']=2.675424},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.000000, ['s']=6.742162},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 67,
		['commands'] = {
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.210564, ['s']=0.246706},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 68,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.641768, ['s']=0.038334},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.150030, ['s']=0.011608},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.621411, ['s']=0.865904},
		}
	},
	{
		['time'] = 75,
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
	[1] = "SLAVED",
	[2] = "UPBODY_PHONE",
	[3] = "UPBODY_CONSUMPTION",
},
[eAnimState.walking] = "WALKCYCLE_UNLOADED",
[eAnimState.talking] = {
	[1] = "UPBODY_AGGRO_TALK",
	[2] = "UPBODY_NORMAL_TALK",
	}
}

lowerBodyAnimations ={
[eAnimState.walking] = "WALKCYCLE_UNLOADED",
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
							selectedIdleFunction =math.random(1,#uppperBodyAnimations[eAnimState.idle])
							showHideProps(selectedIdleFunction, true)
							PlayAnimation(uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
							showHideProps(selectedIdleFunction, false)
end

UpperAnimationStateFunctions ={
[eAnimState.standing] = 	function () 
								resetT(upperBodyPieces, math.pi, false, true)
									-- if boolDecoupled == true then
										if math.random(1,10) > 5 then
										playUpperBodyIdleAnimation()							
										resetT(upperBodyPieces, math.pi, false, true)
										end
									-- end
								Sleep(30)	
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
						Spring.Echo("Lower Body standing")
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
