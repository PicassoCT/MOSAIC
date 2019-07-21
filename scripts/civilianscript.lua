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
	hideAll(unitID)
	bodyBuild()
	StartThread(randSignLoop)

end

function bodyBuild()
showT(TablesOfPiecesGroups["UpLeg"])
showT(TablesOfPiecesGroups["LowLeg"])
showT(TablesOfPiecesGroups["LowArm"])
showT(TablesOfPiecesGroups["UpArm"])
showT(TablesOfPiecesGroups["Head"])
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

Spring.SetUnitNanoPieces(unitID, { center })
function randSignLoop()
	ProtestSign = piece"ProtestSign"
	while true do
	resetAll(unitID)
	Show(ProtestSign)
	Turn(ProtestSign,x_axis,math.rad(-90),0)
	Sleep(5000)


	makeProtestSign(80, 30, 160,"SPRING")
	end

end


function makeProtestSign(signSizeX, signSizeZ, sizeLetter, sentence)
index = 0
xIndexMax= signSizeX/sizeLetter
zIndexMax= signSizeZ/sizeLetter

alreadyUsedLetter ={}


for i=1, #sentence do
	letter = string.upper(string.sub(sentence, i, i))
	if letter == "!" then letter = "Exclam" end
	if letter == "?" then letter = "Quest" end
	if letter == "\n" then zIndex=  math.floor(index /zIndexMax); zIndex = zIndex +1; index = zIndex*xIndexMax; break;  end
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
			zIndex=  math.floor(index /zIndexMax)

			-- Move(pieceToMove,z_axis, zIndex* sizeLetter,0)
			-- Move(pieceToMove,x_axis, xIndex* sizeLetter,0)
			index= index+1
		end

	end





end
