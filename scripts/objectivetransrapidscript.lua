include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}

function script.HitByWeapon(x, z, weaponDefID, damage) end
local trainAxis = x_axis
local maxDistanceTrain = 9000
local trainspeed = 500

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(trainLoop, 1)
    StartThread(trainLoop, 2)
    rVal = math.random(0,360)
    Turn(center, y_axis, math.rad(rVal),0)
end

function deployTunnels(nr)


end

function buildTrain(nr)

end

function hideTrain(nr)

end

function trainLoop(nr)
	rSleepValue = math.random(1,100)*100
	Sleep(rSleepValue)
	local train = piece("Train"..nr)
	direction = randSign()
	
	while true do
		WMove(train, trainAxis, maxDistanceTrain*direction, 0)
		buildTrain(nr)
		WMove(train, trainAxis, 0, trainspeed)
		breakTime = math.random(0,10)*1000
		Sleep(breakTime)
		WMove(train, trainAxis, maxDistanceTrain*direction*-1, trainspeed)
		hideTrain(nr)
		betweenInterval = math.random(1,5)*60*1000
		Sleep(betweenInterval)
	end
end


function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
