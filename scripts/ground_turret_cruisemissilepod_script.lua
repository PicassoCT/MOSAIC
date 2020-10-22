include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage)
end

Pod = piece "Pod"
assert(Pod)
PodTop = piece "PodTop"
aimpiece = piece "aimpiece"
if not aimpiece then echo("Unit of type "..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no aimpiece") end
if not Pod then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no Pod") end		
rocketPiece= aimpiece

DefIDPieceMap = {
	[UnitDefNames["ground_turret_cm_airdrop"].id	]= "cm_airstrike_fold",
	[UnitDefNames["ground_turret_cm_walker"].id		]= "cm_walker_fold",
	[UnitDefNames["ground_turret_cm_antiarmor"].id	]= "cm_AntiArmour_fold" ,
	[UnitDefNames["ground_turret_cm_ssied"].id		]= "cm_turret_ssied_fold" 
	}

function showDependantOnType()
	myDefID= Spring.GetUnitDefID(unitID)
	assert(DefIDPieceMap[myDefID])
	name = DefIDPieceMap[myDefID]
	rocketPiece = piece(name)
	Show(rocketPiece)
end

function script.Create()

    -- generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	resetAll(unitID)
	hideAll(unitID)
	Show(Pod)
	Show(PodTop)
	showDependantOnType()
	showT(TablesOfPiecesGroups["UpLeg"])
	showT(TablesOfPiecesGroups["LowLeg"])
	Hide(aimpiece)
	Turn(aimpiece,x_axis,math.rad(180),0)
	StartThread(walkLoop)
end


function walkLoop()
	while (true) do
	
		if boolMoving == true then 
			while(boolMoving == true) do 
				for i=1,4 do
					if(i%2==1) then				
						Turn(TablesOfPiecesGroups["UpLeg"][i], y_axis,math.rad(-42),10)
						Turn(TablesOfPiecesGroups["LowLeg"][i], y_axis, math.rad(42),10)
					else
						Turn(TablesOfPiecesGroups["UpLeg"][i], x_axis,math.rad(-42),10)
						Turn(TablesOfPiecesGroups["LowLeg"][i], x_axis, math.rad(42),10)
					end
				end
				WaitForTurnT(TablesOfPiecesGroups["UpLeg"])
				WaitForTurnT(TablesOfPiecesGroups["LowLeg"])
				
				for i=1,4 do
							
				resetT(TablesOfPiecesGroups["UpLeg"], 10)
				resetT(TablesOfPiecesGroups["LowLeg"], 10)
			
				end
				WaitForTurnT(TablesOfPiecesGroups["UpLeg"])
				WaitForTurnT(TablesOfPiecesGroups["LowLeg"])
			Sleep(5)
			end
		end

		resetT(TablesOfPiecesGroups["UpLeg"], 25)
		resetT(TablesOfPiecesGroups["LowLeg"], 25)
		WaitForTurnT(TablesOfPiecesGroups["UpLeg"])
		WaitForTurnT(TablesOfPiecesGroups["LowLeg"])
	Sleep(50)
	end

end

function script.Killed(recentDamage, _)
    return 1
end

--aimining & fire weapon
function script.AimFromWeapon1()
    return aimpiece
end

function script.QueryWeapon1()
    return aimpiece
end

function script.AimWeapon1(Heading, pitch)
	WTurn(PodTop,z_axis, math.rad(180),math.pi*3)
	WMove(rocketPiece,y_axis, 1000, 2000)
    return true
end

function script.FireWeapon1()
	Spring.DestroyUnit(unitID, true, false)
	return true
end

boolMoving = false

function script.StartMoving()
	boolMoving= true
end

function script.StopMoving()
	boolMoving = false
end

function script.Activate()
    return 1
end

function script.Deactivate()
    return 0
end
