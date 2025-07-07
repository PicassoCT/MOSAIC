include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

local TablesOfPiecesGroups = {}
local GameConfig = getGameConfig()
local spGetUnitPosition = Spring.GetUnitPosition
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture, "civilian",
                                     UnitDefs)
local gaiaTeamID = Spring.GetGaiaTeamID()
									 
local spGetUnitDefID = Spring.GetUnitDefID
Rotor = piece"Rotor"

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Spring.SetUnitNeutral(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    StartThread(hoverAboveGround, unitID, GameConfig.iconHoverGroundOffset, 0.3)  
	StartThread(socialEngineeringPosWriteUp)
	StartThread(ringAnimation)
	StartThread(crowdAnimation)
	Spin(Rotor,y_axis, math.rad(-42),0)	
end

function ringAnimation()
    Sleep(100)
    showT(TablesOfPiecesGroups["Range"])
    interval = 5
    while true do
    	spawnCegAtUnit(unitID, "orangematrix", math.random(-10,10), math.random(-10,10), math.random(-10,10))
        for i=1, #TablesOfPiecesGroups["Range"] do
            timers = (((Spring.GetGameFrame()/30)+ i*((interval/2)/#TablesOfPiecesGroups["Range"]) % interval)/interval)* math.pi*2
            Move(TablesOfPiecesGroups["Range"][i],z_axis, 500 + math.sin(timers)*500, 666 )
            if maRa() == maRa() then
            	randTurn = math.random(0,360)
            	Spin(TablesOfPiecesGroups["Range"][i],y_axis,math.rad(randTurn),0)
        	end
        end
         timers = (((Spring.GetGameFrame()/30)+  #TablesOfPiecesGroups["Range"]*((interval/2)/#TablesOfPiecesGroups["Range"]) % interval)/interval)* math.pi*2
        Sleep(50)
    end
end

function randomGraphMovement(piecename, timeMs, id)
	Hide(piecename)
	restTimeMs = math.ceil(timeMs*(math.random(10,40)/100))
	moveTimeMS= math.ceil(timeMs-restTimeMs)
	local rx = math.random(250,1000) * randSign()
	local rz = math.random(250,1000) * randSign()
	local ry = math.random(-1000,-500)
	Sleep(restTimeMs)
	if id > 24 then
		Move(piecename,y_axis, ry, 0)
	end
	Move(piecename,x_axis, rx, 0)
	Move(piecename,z_axis, rz, 0)
	WaitForMoves(piecename)
	Show(piecename)
	maxval= math.max(math.max(math.abs(rx),math.abs(rz)),math.abs(ry))
	speedVal= (maxval/(moveTimeMS/1000))
	Move(piecename,x_axis, 0, speedVal)
	Move(piecename,y_axis, 0, speedVal)
	Move(piecename,z_axis, 0, speedVal)
	WaitForMoves(piecename)
end

function crowdAnimation()
	Graph = piece"Graph"
	while true do
		Hide(Graph)
		timeVal= math.random(1,6)*5*1000
		count=1
		foreach(TablesOfPiecesGroups["Crowd"],
			function(id)
				StartThread(randomGraphMovement, id, timeVal, count)
				count= count+1
			end)
		Sleep(timeVal)
		WaitForMoves(TablesOfPiecesGroups["Crowd"])
		Show(Graph)
		Sleep(5000)
	end
end

function socialEngineeringPosWriteUp()
	waitTillComplete(unitID)
	soundnameTime= {{name = "sounds/icons/social_engineering.ogg", time = 2*60*1000}}
	StartThread(playSoundByUnitTypOS, unitID, 0.75, soundnameTime)
	StartThread(lifeTime, unitID, GameConfig.socialEngineerLifetimeMs, true, false)  
    StartThread(hidePercentages, TablesOfPiecesGroups["Percentages"], GameConfig.socialEngineerLifetimeMs)  
	if not GG.SocialEngineeredPeople then GG.SocialEngineeredPeople ={} end
	if not GG.SocialEngineers then GG.SocialEngineers ={} end
	GG.SocialEngineers[unitID] = true
	while true do
		x,y,z = spGetUnitPosition(unitID)
		 foreach(getAllInCircle(x,z, GameConfig.socialEngineeringRange, unitID, gaiaTeamID),
				function(id)
					if GG.DisguiseCivilianFor[id] then return end
					defID = spGetUnitDefID(id)
					if civilianWalkingTypeTable[defID] then
						GG.SocialEngineeredPeople[id] = unitID
						return id
					end
				end
				)
		Sleep(250)
	end

end

function script.Killed(recentDamage, _)
	for k,v in pairs(GG.SocialEngineeredPeople[id]) do
		if v == unitID then
			GG.SocialEngineers[v] = nil
		end
	end
	
	Explode(center,  SFX.SHATTER)
	Explode(Rotor,  SFX.SHATTER)
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

