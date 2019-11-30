include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"
TablesOfPiecesGroups = {}

center = piece "center"
attachPoint = piece "attachPoint"
myDefID = Spring.GetUnitDefID(unitID)
boolIsCivilianTruck = (myDefID == UnitDefNames["truck"].id)
gameConfig= getGameConfig()

SIG_LOUDNESOVERRIDE= 2

function showAndTell()
	showAll(unitID)
	if TablesOfPiecesGroups["LightEmit"] then
		hideT(TablesOfPiecesGroups["LightEmit"])
	end

	if TablesOfPiecesGroups["Body"]  then
		hideT(TablesOfPiecesGroups["Body"])
		Show(TablesOfPiecesGroups["Body"][2])
	end

end

function script.Create()
    generatepiecesTableAndArrayCode(unitID)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false)
	showAndTell()
	StartThread(delayedSirens)
end

function delayedSirens()
	sleeptime= math.random(1,10)
	Sleep(sleeptime*1000)
	for i=1,3 do
		StartThread( PieceLight, unitID, TablesOfPiecesGroups["LightEmit"][i], "policelight",1000)
		Sleep(350)
	end
	seconds = 35
	framesPerSecond=30

	while true do
		sirenDice=math.random(1,gameConfig.maxSirenSoundFiles)
		loudness = math.max(0,math.sin((((Spring.GetGameFrame()/framesPerSecond)%seconds)/seconds)*2*math.pi))
		if boolLoudnessOverrideActive == true then loudness = 1.0 end
		StartThread(PlaySoundByUnitDefID, myDefID, "sounds/civilian/police/siren"..sirenDice..".ogg", 0.9,50, 2)
		Sleep(50*1000)	
	end
end
boolLoudnessOverrideActive = false
function loudnessOverride()
	Signal(SIG_LOUDNESOVERRIDE)
	SetSignalMask(SIG_LOUDNESOVERRIDE)
	boolLoudnessOverrideActive = true
	Sleep(30000)

	boolLoudnessOverrideActive = false
end

function script.HitByWeapon(x, z, weaponDefID, damage)
StartThread(loudnessOverride)
return damage
end
function script.Killed(recentDamage, _)
	if doesUnitExistAlive(loadOutUnitID) then Spring.DestroyUnit(loadOutUnitID,true,true) end

    createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.StartMoving()
	spinT(TablesOfPiecesGroups["wheel"], x_axis ,0.3 , -160)
end

function script.StopMoving()
	stopSpinT(TablesOfPiecesGroups["wheel"], x_axis, 3)	
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

