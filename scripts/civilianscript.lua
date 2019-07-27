include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
--Contains:
-- center
-- uparm (1= left, 2 = right)
-- lowarm
-- hand
-- torso
-- upbody
-- head
-- upleg
-- lowleg
-- feet

--equipmentname: cellphone, shoppingbags, crates, baby, cigarett, food, stick, demonstrator sign, molotow cocktail

function script.HitByWeapon(x, z, weaponDefID, damage)
end

center = piece "center"
boolWalking = false
boolTurning = false
boolTurnLeft = false

local SIG_STOP = 1
AnimationState = "Stopping_TransferPose"
function setOverrideAnimationState( Animationstate, ConditionFunction, boolInstantOverride)

end
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
	-- Every Animation e for fast blending
	-- Health dependent loops
	-- External Override
	-- AnimationStates have abort Condition

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




function script.Create()
    
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	StartThread(turnDetector)

	bodyBuild()
	StartThread(randSignLoop)

end

function bodyBuild()
	hideAll(unitID)
showT(TablesOfPiecesGroups["UpLeg"])
showT(TablesOfPiecesGroups["LowLeg"])
showT(TablesOfPiecesGroups["LowArm"])
showT(TablesOfPiecesGroups["UpArm"])
showT(TablesOfPiecesGroups["Head"])
showT(TablesOfPiecesGroups["Feet"])
Show(center)


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



function script.StartMoving()
	boolWalking= true
end

function delayedStop()
	Signal(SIG_STOP)
	SetSignalMask(SIG_STOP)
	Sleep(250)
	boolWalking = false
	
end

function script.StopMoving()
	StartThread(delayedStop)
end

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
	" ICBM& UP YOUR ASS",
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
	"NO GODS&ONLY US",

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
function randSignLoop()
	lettersize = 34
	letterSizeZ= 62
	ProtestSign = piece"ProtestSign"
	resetAll(unitID)
	
	while true do
	WTurn(ProtestSign,z_axis, math.rad(0), 1)
	bodyBuild()
	resetAll(unitID)	
	WTurn(ProtestSign,z_axis, math.rad(0), 0)
	Show(ProtestSign)
	makeProtestSign(8, 3, lettersize, letterSizeZ, seriously[math.random(1,#seriously)], "RAPHI")
	WTurn(ProtestSign,x_axis,math.rad(-90),5)
	WTurn(ProtestSign,y_axis,math.rad(0),5)
	WTurn(ProtestSign,z_axis,math.rad(0),5)
	Spin(ProtestSign,z_axis, math.rad(math.random(-3,3)*2),3)
	Spin(ProtestSign,x_axis, math.rad(math.random(-2,2)),1)
	Spin(ProtestSign,y_axis, math.rad(math.random(-2,2)),1)
	Sleep(5000)


	
	end

end


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
