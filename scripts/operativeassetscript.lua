
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
	-- StartThread(turnDetector)
	
	-- setOverrideAnimationState( eAnimState.slaved, eAnimState.walking,  true, nil, false)
	-- StartThread(animationStateMachineUpper, UpperAnimationStateFunctions)
	-- StartThread(animationStateMachineLower, LowerAnimationStateFunctions)
	-- StartThread(threadStarter)
	-- StartThread(cloakLoop)
	StartThread(testAnimationLoop)
	
end

function testAnimationLoop()
	Sleep(500)
	while true do
		PlayAnimation("UPBODY_AIMING", nil,1.0)	
		Sleep(100)
			
	end
end
deg_45=math.pi/4
deg_90=math.pi/2
local Animations = {
["WALKCYCLE_RUNNING"]= {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Gun, ['a']=x_axis, ['t']=0, ['s']=0.67402},
			{['c']='turn',['p']=Gun, ['a']=y_axis, ['t']=0, ['s']=0.99771},
			{['c']='turn',['p']=Gun, ['a']=z_axis, ['t']=0, ['s']=0.5199562},
	
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=-0.081532, ['s']=0.188139},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.004441, ['s']=0.007041},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.001655, ['s']=0.002265},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.034907, ['s']=0.261799},
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.338011, ['s']=0.690723},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.063962, ['s']=0.029047},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.125517, ['s']=0.016983},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.916591, ['s']=0.285447},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.523640, ['s']=0.382075},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.456327, ['s']=0.319208},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.75, ['s']=0.978454},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']= 0.75, ['s']=1.332592},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.750, ['s']=0.522145},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.082255, ['s']=0.305251},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.012048, ['s']=0.004467},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.010295, ['s']=0.007160},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.768217, ['s']=7.945775},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.000881, ['s']=0.194981},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.038351, ['s']=0.108102},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.150878, ['s']=0.358902},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.014680, ['s']=0.032226},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.063723, ['s']=0.009007},
			
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.744037, ['s']=2.256671},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=1.077152, ['s']=1.509577},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.740462, ['s']=3.263970},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=1.064529, ['s']=2.393872},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.009877, ['s']=4.112632},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.212061, ['s']=0.175365},
			
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.231430, ['s']=1.824491},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.002070, ['s']=0.048473},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000470, ['s']=0.013741},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-1.483661, ['s']=2.126740},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.011399, ['s']=0.053675},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.003260, ['s']=0.033883},
		}
	},

	{
		['time'] = 4,
		['commands'] = {
			
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.400654, ['s']=3.183989},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.006188, ['s']=0.058605},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.003776, ['s']=0.065191},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.779883, ['s']=9.883336},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.005588, ['s']=0.047066},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.011436, ['s']=0.269145},
			
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.317284, ['s']=0.858539},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.004420, ['s']=0.023495},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000806, ['s']=0.003361},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-1.271417, ['s']=2.122433},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.006043, ['s']=0.053559},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000123, ['s']=0.033827},
		}
	},
	{
		['time'] = 6,
		['commands'] = {

		}
	},
	{
		['time'] = 7,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.349149, ['s']=9.484946},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.018539, ['s']=0.247268},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.001368, ['s']=0.051434},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.474690, ['s']=3.051929},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.001593, ['s']=0.039944},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.003643, ['s']=0.077929},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.252447, ['s']=0.507849},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.005373, ['s']=0.046535},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.065473, ['s']=0.008748},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0, ['s']=1.869554},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.35, ['s']=0.136385},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.17, ['s']=0.29960},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.093012, ['s']=2.242721},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.001631, ['s']=0.060512},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000491, ['s']=0.012979},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.958104, ['s']=3.133134},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.002870, ['s']=0.089134},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.002885, ['s']=0.027623},
		}
	},
	{
		['time'] = 9,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.034907, ['s']=0.149600},
		}
	},
	{
		['time'] = 10,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=-0.003130, ['s']=1.176039},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.000641, ['s']=0.056993},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.000325, ['s']=0.019938},
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=-0.130794, ['s']=0.310825},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.055248, ['s']=0.013071},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.130612, ['s']=0.007642},
			
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=2.079041, ['s']=7.298924},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.034434, ['s']=0.158947},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.010326, ['s']=0.116932},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.329347, ['s']=1.453438},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.001098, ['s']=0.026915},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.000441, ['s']=0.032025},
			
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.514699, ['s']=6.077104},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.015027, ['s']=0.133955},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.010203, ['s']=0.097114},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.764441, ['s']=1.936625},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.008646, ['s']=0.057763},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.003157, ['s']=0.002719},
		}
	},
	{
		['time'] = 11,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.744037, ['s']=2.256671},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=1.077152, ['s']=1.509577},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.740462, ['s']=3.263970},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.064529, ['s']=2.393872},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.609877, ['s']=4.112632},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.912061, ['s']=0.175365},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=-0.113843, ['s']=0.415175},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.009835, ['s']=0.034475},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.004758, ['s']=0.016621},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.539443, ['s']=5.395979},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.023448, ['s']=0.109863},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.000504, ['s']=0.098211},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.333047, ['s']=0.037002},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.001436, ['s']=0.003382},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.000915, ['s']=0.004744},
			
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.343001, ['s']=8.283019},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.020001, ['s']=0.049743},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.031888, ['s']=0.216854},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.178405, ['s']=9.428462},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.032196, ['s']=0.235496},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.010368, ['s']=0.135243},
		}
	},
	{
		['time'] = 16,
		['commands'] = {
			
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.742473, ['s']=7.969708},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.002029, ['s']=0.214189},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000803, ['s']=0.013077},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.728927, ['s']=3.958806},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.005089, ['s']=0.065256},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.010056, ['s']=0.091406},
			
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.111584, ['s']=2.314162},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.020466, ['s']=0.004650},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.025522, ['s']=0.063659},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.325902, ['s']=1.474968},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.034324, ['s']=0.021280},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.014225, ['s']=0.038570},
		}
	},
	{
		['time'] = 18,
		['commands'] = {

			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-0.75, ['s']=0.978454},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']= 0.75, ['s']=1.332592},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.350, ['s']=0.522145},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.34, ['s']=1.869554},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.35, ['s']=0.136385},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0, ['s']=0.29960},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.223117, ['s']=3.895171},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.009867, ['s']=0.089218},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.006772, ['s']=0.056812},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.242091, ['s']=3.848724},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.006773, ['s']=0.012628},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.024578, ['s']=0.108912},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.687378, ['s']=3.181545},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.017532, ['s']=0.022005},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.014259, ['s']=0.084472},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.127869, ['s']=1.485248},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.031339, ['s']=0.022387},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.009124, ['s']=0.038258},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=-0.027690, ['s']=0.861526},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.002076, ['s']=0.077587},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.000924, ['s']=0.038338},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.150878, ['s']=0.609419},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.014680, ['s']=0.055842},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.063723, ['s']=0.010498},
			
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			-- {['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.941012, ['s']=3.011342},
			-- {['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.410213, ['s']=2.501020},
			-- {['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.438315, ['s']=4.420413},
			
			-- {['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.309195, ['s']=2.327354},
			-- {['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.020747, ['s']=3.277045},
			-- {['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.000926, ['s']=0.917767},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=backpack, ['a']=x_axis, ['t']=-0.025091, ['s']=0.011141},
			{['c']='turn',['p']=backpack, ['a']=y_axis, ['t']=0.002328, ['s']=0.001082},
			{['c']='turn',['p']=backpack, ['a']=z_axis, ['t']=-0.000975, ['s']=0.000219},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.051730, ['s']=0.734513},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.012495, ['s']=0.011262},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.011011, ['s']=0.018167},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.977427, ['s']=7.353367},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.003315, ['s']=0.100880},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.042662, ['s']=0.180843},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.350753, ['s']=3.366254},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.012036, ['s']=0.054961},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.006804, ['s']=0.074556},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.288721, ['s']=4.165900},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.022159, ['s']=0.091805},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.000842, ['s']=0.082820},
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
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.079097, ['s']=0.430682},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.021125, ['s']=0.038671},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.061922, ['s']=0.010808},
		}
	},
	{
		['time'] = 26,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=2.562794, ['s']=4.390253},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.018617, ['s']=0.114765},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.049161, ['s']=0.048744},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.048981, ['s']=2.998004},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.002777, ['s']=0.069444},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.000904, ['s']=0.044251},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-1.163148, ['s']=6.558200},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.003066, ['s']=0.189189},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.001392, ['s']=0.016751},
		}
	},
	{
		['time'] = 27,
		['commands'] = {
			
		}
	},
	{
		['time'] = 30,
		['commands'] = {
		}
	},

}
,["WALKCYCLE_WALK"]=  {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.087266, ['s']=0.327249},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.766573, ['s']=3.832864},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.184435, ['s']=2.702649},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.387580, ['s']=0.318066},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.581724, ['s']=0.816132},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.350141, ['s']=0.151935},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.379829, ['s']=1.543785},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.585767, ['s']=0.071736},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.217219, ['s']=0.886505},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.244089, ['s']=0.630598},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=0.287684, ['s']=1.709853},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 5,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.562900, ['s']=1.135397},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.875361, ['s']=4.197938},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 6,
		['commands'] = {
		}
	},
	{
		['time'] = 7,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.082989, ['s']=1.356068},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-0.061324, ['s']=0.955516},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.660788, ['s']=0.225064},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.212901, ['s']=1.290359},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.563596, ['s']=2.338242},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 14,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.354295, ['s']=10.930402},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.366473, ['s']=2.191562},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 16,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.000000, ['s']=0.759204},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0.228547, ['s']=0.340785},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.173658, ['s']=0.874428},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.426108, ['s']=0.162787},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.826259, ['s']=3.341829},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.087266, ['s']=0.402768},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=0.160009, ['s']=1.669857},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 22,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=0.186225, ['s']=0.928310},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.612070, ['s']=0.182693},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=0.107833, ['s']=0.394005},
		}
	},
	{
		['time'] = 26,
		['commands'] = {
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.544788, ['s']=6.162637},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.567242, ['s']=1.942624},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.000000, ['s']=0.000000},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.000000, ['s']=0.000000},
		}
	},
	{
		['time'] = 30,
		['commands'] = {
		}
	},
}
,["UPBODY_AIMING"] =  {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.287310, ['s']=0.615665},
			{['c']='turn',['p']=Gun, ['a']=x_axis, ['t']=0, ['s']=1.315678},
			{['c']='turn',['p']=Gun, ['a']=y_axis, ['t']=0.5234, ['s']=1.007879},
			{['c']='turn',['p']=Gun, ['a']=z_axis, ['t']=0, ['s']=0.37769},
			
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.059612, ['s']=0.127739},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.479208, ['s']=1.026874},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.169718, ['s']=0.48891},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=2.3526900, ['s']=3.198304},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.3495886, ['s']=0.405196},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=1.2671090, ['s']=0.50394},
			
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=deg_90*2 + deg_45, ['s']=2.668237},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-1*deg_45 , ['s']=1.80692},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=-1*deg_45, ['s']=1.77392},
		
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-3*deg_45, ['s']=0.929477},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0, ['s']=0.21964},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=2.5*deg_45, ['s']=4.221870},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1*deg_90+ deg_45, ['s']=7.328537},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0, ['s']=0.456564},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-1*deg_45, ['s']=7.078054},
		}
	},
	{
	['time'] =4,
	['commands'] = {}
	}

}

,["DEATH"] =  {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.012275, ['s']=0.040917},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.038357, ['s']=0.127856},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.391733, ['s']=2.030506},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.773810, ['s']=2.738270},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.118065, ['s']=3.828865},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.616990, ['s']=2.420037},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.180666, ['s']=1.354995},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.450301, ['s']=8.218482},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.526147, ['s']=0.685053},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.227333, ['s']=4.788938},
		}
	},
	{
		['time'] = 4,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.489307, ['s']=4.893069},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.147165, ['s']=1.471653},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.039268, ['s']=0.392682},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.295494, ['s']=2.954939},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.074379, ['s']=0.743790},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.042007, ['s']=0.420068},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.451120, ['s']=4.511197},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.245891, ['s']=1.001871},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.091405, ['s']=0.914051},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.349365, ['s']=3.493646},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=-0.009591, ['s']=0.095907},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.019255, ['s']=0.192550},
		}
	},
	{
		['time'] = 5,
		['commands'] = {
			
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=0.046549, ['s']=0.698232},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.007968, ['s']=0.119518},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.264523, ['s']=3.967850},
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-0.556859, ['s']=1.627131},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.046874, ['s']=1.237042},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.002497, ['s']=4.646155},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=1.071996, ['s']=21.050318},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=0.727727, ['s']=4.910329},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-0.034440, ['s']=12.492974},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=-0.273762, ['s']=4.106432},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.150280, ['s']=2.254205},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.234367, ['s']=0.805511},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.009742, ['s']=3.304197},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.163538, ['s']=5.172638},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.037093, ['s']=1.426796},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-2.718354, ['s']=6.062516},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.695841, ['s']=2.545855},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.124604, ['s']=6.034559},
		}
	},
	{
		['time'] = 7,
		['commands'] = {
			
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=0.840329, ['s']=1.984450},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.143841, ['s']=0.339683},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=0.095761, ['s']=0.421907},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.522945, ['s']=0.201831},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.148411, ['s']=0.7475},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.044366, ['s']=0.030590},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.207624, ['s']=0.219674},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.159147, ['s']=0.583815},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.392899, ['s']=0.877229},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.000000, ['s']=1.173266},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.000000, ['s']=0.644059},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.180666, ['s']=0.230146},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.372730, ['s']=0.470339},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.235834, ['s']=0.060343},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.071377, ['s']=0.120166},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.641107, ['s']=1.750452},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.057897, ['s']=0.404926},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=0.006977, ['s']=0.073671},
		}
	},
	{
		['time'] = 9,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.295679, ['s']=0.764297},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=-0.151824, ['s']=0.108569},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=0.754365, ['s']=0.782961},
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-3.430196, ['s']=22.510961},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=1.296987, ['s']=2.846302},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-4.250356, ['s']=21.079579},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.387768, ['s']=1.030982},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.277694, ['s']=1.203358},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=0.749283, ['s']=1.942336},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.144068, ['s']=7.871433},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.406044, ['s']=1.448982},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.368319, ['s']=1.218576},
		}
	},
	{
		['time'] = 10,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.058430, ['s']=0.138466},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.124140, ['s']=0.487492},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.272142, ['s']=0.358772},
		}
	},
	{
		['time'] = 12,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=0.092614, ['s']=1.844275},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.018919, ['s']=0.554967},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.021374, ['s']=0.098539},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-0.783288, ['s']=1.759537},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.308334, ['s']=0.310713},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.062053, ['s']=0.039960},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-1.211158, ['s']=2.443076},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.148861, ['s']=0.389846},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.039379, ['s']=0.198665},
		}
	},
	{
		['time'] = 14,
		['commands'] = {
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.007921, ['s']=0.008487},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.001015, ['s']=0.001087},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.453327, ['s']=0.292137},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-2.595122, ['s']=1.043842},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=1.372088, ['s']=0.093876},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-3.400448, ['s']=1.062385},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.150837, ['s']=0.005488},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.399083, ['s']=0.005645},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.702959, ['s']=0.271329},
		}
	},
	{
		['time'] = 19,
		['commands'] = {
		
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=2.378822, ['s']=4.899016},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.417579, ['s']=0.854271},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.395614, ['s']=0.893546},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=2.060633, ['s']=3.970733},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.009120, ['s']=0.360571},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=-0.337228, ['s']=0.119293},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.579282, ['s']=1.705702},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.302480, ['s']=0.12544},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=-0.294464, ['s']=0.498023},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.200526, ['s']=1.318215},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.086898, ['s']=0.080821},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=1.142460, ['s']=1.541529},
		}
	},
	{
		['time'] = 20,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.651947, ['s']=0.613983},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.074181, ['s']=0.205160},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.111658, ['s']=0.166019},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.451369, ['s']=0.106002},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0.363077, ['s']=1.067951},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.133079, ['s']=0.639659},
		}
	},
	{
		['time'] = 31,
		['commands'] = {
			{['c']='move',['p']=center, ['a']=y_axis, ['t']=-390.881045, ['s']=420.848571},
			
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=1.601398, ['s']=2.075642},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.595451, ['s']=1.231664},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.032034, ['s']=0.348530},
		}
	},
	{
		['time'] = 33,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=2.377244, ['s']=0.005260},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.236271, ['s']=0.604358},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.304821, ['s']=0.302644},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=1.046275, ['s']=3.381194},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=0.120014, ['s']=0.430447},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.102346, ['s']=1.465248},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.555597, ['s']=0.078950},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.304979, ['s']=0.8328},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.891049, ['s']=3.951710},
		}
	},
	{
		['time'] = 38,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.452320, ['s']=0.261068},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.042352, ['s']=0.323627},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.059170, ['s']=1.355892},
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=-0.375636, ['s']=0.119579},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=-0.288793, ['s']=1.029268},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=1.300624, ['s']=0.264544},
		}
	},
	{
		['time'] = 39,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-5.167154, ['s']=5.511498},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=1.309442, ['s']=0.134242},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-5.908609, ['s']=5.374632},
		}
	},
	{
		['time'] = 42,
		['commands'] = {
			{['c']='turn',['p']=center, ['a']=x_axis, ['t']=1.620991, ['s']=0.73474},
			{['c']='turn',['p']=center, ['a']=y_axis, ['t']=-0.955859, ['s']=1.351527},
			{['c']='turn',['p']=center, ['a']=z_axis, ['t']=-0.045979, ['s']=0.52293},
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=2.346144, ['s']=0.155497},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=-0.118839, ['s']=0.587160},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=-0.340214, ['s']=0.176966},
			{['c']='turn',['p']=LowLeg2, ['a']=x_axis, ['t']=0.890206, ['s']=0.260114},
			{['c']='turn',['p']=LowLeg2, ['a']=y_axis, ['t']=-0.562421, ['s']=1.137392},
			{['c']='turn',['p']=LowLeg2, ['a']=z_axis, ['t']=0.560960, ['s']=0.764357},
			{['c']='turn',['p']=Torso, ['a']=x_axis, ['t']=0.655753, ['s']=1.079720},
			{['c']='turn',['p']=Torso, ['a']=y_axis, ['t']=0.104544, ['s']=0.172549},
			{['c']='turn',['p']=Torso, ['a']=z_axis, ['t']=0.469124, ['s']=0.26328},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.552817, ['s']=0.13902},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=0.310193, ['s']=0.26073},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.603548, ['s']=1.437505},
			{['c']='turn',['p']=UpLeg2, ['a']=x_axis, ['t']=-0.717913, ['s']=0.862312},
			{['c']='turn',['p']=UpLeg2, ['a']=y_axis, ['t']=0.087034, ['s']=0.0226},
			{['c']='turn',['p']=UpLeg2, ['a']=z_axis, ['t']=-0.133681, ['s']=2.126901},
		}
	},
	{
		['time'] = 45,
		['commands'] = {
		}
	},
	{
		['time'] = 48,
		['commands'] = {
			{['c']='turn',['p']=LowLeg1, ['a']=x_axis, ['t']=1.990833, ['s']=1.184371},
			{['c']='turn',['p']=LowLeg1, ['a']=y_axis, ['t']=0.207123, ['s']=1.086542},
			{['c']='turn',['p']=LowLeg1, ['a']=z_axis, ['t']=0.704333, ['s']=3.481824},
			{['c']='turn',['p']=UpLeg1, ['a']=x_axis, ['t']=-1.443258, ['s']=0.365196},
			{['c']='turn',['p']=UpLeg1, ['a']=y_axis, ['t']=-0.449373, ['s']=2.531888},
			{['c']='turn',['p']=UpLeg1, ['a']=z_axis, ['t']=0.314086, ['s']=0.964873},
		}
	},
	{
		['time'] = 49,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.513740, ['s']=1.382072},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.467071, ['s']=5.412517},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.145750, ['s']=0.340919},
		}
	},
	{
		['time'] = 50,
		['commands'] = {
		}
	},
	{
		['time'] = 52,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.635789, ['s']=0.732294},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.138901, ['s']=1.969022},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=-0.112834, ['s']=0.197493},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.151454, ['s']=0.2315},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.399043, ['s']=0.0148},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.704849, ['s']=0.7091},
		}
	},
	{
		['time'] = 53,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-4.825895, ['s']=1.462541},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=1.367499, ['s']=0.248816},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-5.618681, ['s']=1.242548},
		}
	},
	{
		['time'] = 56,
		['commands'] = {
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-1.463935, ['s']=0.87112},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.122121, ['s']=0.598272},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-0.317984, ['s']=1.941101},
		}
	},
	{
		['time'] = 57,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.085227, ['s']=5.505620},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.734328, ['s']=8.732288},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.381708, ['s']=4.945422},
		}
	},
	{
		['time'] = 60,
		['commands'] = {
		}
	},
}

,["WALKCYCLE_STANDING"] =  {
	{
		['time'] = 1,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-1.461476, ['s']=0.067402},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.660466, ['s']=0.099771},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.401301, ['s']=0.199562},
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.567193, ['s']=0.108948},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.002495, ['s']=0.075341},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.605631, ['s']=0.002462},
			
			-- {['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=math.pi/4, ['s']=0.67402},
			-- {['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0, ['s']=0.99771},
			-- {['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=math.pi/2, ['s']=0.5199562},		
			
			{['c']='turn',['p']=LowArm1, ['a']=x_axis, ['t']=-2.56, ['s']=0.67402},
			{['c']='turn',['p']=LowArm1, ['a']=y_axis, ['t']=0.86, ['s']=0.99771},
			{['c']='turn',['p']=LowArm1, ['a']=z_axis, ['t']=-1.02+deg_90, ['s']=0.5199562},
			
			{['c']='turn',['p']=UpArm1, ['a']=x_axis, ['t']=0, ['s']=0.108948},
			{['c']='turn',['p']=UpArm1, ['a']=y_axis, ['t']=0, ['s']=0.075341},
			{['c']='turn',['p']=UpArm1, ['a']=z_axis, ['t']=math.pi/2, ['s']=0.5462},
			
			{['c']='turn',['p']=Gun, ['a']=x_axis, ['t']=math.pi/4, ['s']=0.67402},
			{['c']='turn',['p']=Gun, ['a']=y_axis, ['t']=0, ['s']=0.99771},
			{['c']='turn',['p']=Gun, ['a']=z_axis, ['t']=math.pi/4, ['s']=0.5199562},
			
		}
	},
	{
		['time'] = 3,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.377194, ['s']=0.381404},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.150969, ['s']=0.040773},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.113492, ['s']=0.159586},
		}
	},
	{
		['time'] = 13,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.359545, ['s']=0.176491},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=-0.004512, ['s']=1.554812},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.112196, ['s']=0.012952},
		}
	},
	{
		['time'] = 15,
		['commands'] = {
			{['c']='turn',['p']=LowArm2, ['a']=x_axis, ['t']=-1.492930, ['s']=0.067402},
			{['c']='turn',['p']=LowArm2, ['a']=y_axis, ['t']=-0.707026, ['s']=0.099771},
			{['c']='turn',['p']=LowArm2, ['a']=z_axis, ['t']=-1.308172, ['s']=0.199562},
		}
	},
	{
		['time'] = 16,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.582607, ['s']=0.955981},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.044248, ['s']=0.208969},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.124763, ['s']=0.053857},
		}
	},
	{
		['time'] = 17,
		['commands'] = {
			{['c']='turn',['p']=UpArm2, ['a']=x_axis, ['t']=-1.509087, ['s']=0.145264},
			{['c']='turn',['p']=UpArm2, ['a']=y_axis, ['t']=0.042677, ['s']=0.100454},
			{['c']='turn',['p']=UpArm2, ['a']=z_axis, ['t']=-0.604319, ['s']=0.003282},
		}
	},
	{
		['time'] = 23,
		['commands'] = {
			{['c']='turn',['p']=Head, ['a']=x_axis, ['t']=0.250059, ['s']=1.425205},
			{['c']='turn',['p']=Head, ['a']=y_axis, ['t']=0.137379, ['s']=0.399133},
			{['c']='turn',['p']=Head, ['a']=z_axis, ['t']=0.060296, ['s']=0.276286},
		}
	},
	{
		['time'] = 29,
		['commands'] = {
		}
	},
	{
		['time'] = 30,
		['commands'] = {
		}
	},
}
};

uppperBodyAnimations = {
	[eAnimState.idle] = { 	
		[1] = "WALKCYCLE_STANDING"
	},
	[eAnimState.walking] = "SLAVED",
	[eAnimState.talking] =  "WALKCYCLE_STANDING",
}


lowerBodyAnimations = {
	[eAnimState.walking] = "WALKCYCLE_RUNNING"
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
	
		selectedIdleFunction = math.random(1,#uppperBodyAnimations[eAnimState.idle])
		if selectedIdleFunction and uppperBodyAnimations[eAnimState.idle] and uppperBodyAnimations[eAnimState.idle][selectedIdleFunction] then
			PlayAnimation(uppperBodyAnimations[eAnimState.idle][selectedIdleFunction])
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
							
								boolDecoupled = true
									playUpperBodyIdleAnimation()
								boolDecoupled = false
				
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
