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
    StartThread(lifeTime, unitID, GameConfig.socialEngineerLifetimeMs, true, false)  
    StartThread(hidePercentages, TablesOfPiecesGroups["Percentages"], GameConfig.socialEngineerLifetimeMs)  
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
        for i=1, #TablesOfPiecesGroups["Range"] do
            timers = (((Spring.GetGameFrame()/30)+ i*((interval/2)/#TablesOfPiecesGroups["Range"]) % interval)/interval)* math.pi*2
            Move(TablesOfPiecesGroups["Range"][i],z_axis, 500 + math.sin(timers)*500, 666 )
        end
         timers = (((Spring.GetGameFrame()/30)+  #TablesOfPiecesGroups["Range"]*((interval/2)/#TablesOfPiecesGroups["Range"]) % interval)/interval)* math.pi*2
        Sleep(50)
    end
end

function randomGraphMovement(piecename, timeMs)
	Hide(piecename)
	restTimeMs = math.ceil(timeMs*(math.random(10,40)/100))
	moveTimeMS= math.ceil(timeMs-restTimeMs)
	rx,rz = math.random(500,2000) * randSign(), math.random(500,2000) * randSign()
	ry = math.random(-1000,-500)
	Sleep(restTimeMs)
	Move(piecename,y_axis, ry, 0)
	Move(piecename,x_axis, rx, 0)
	Move(piecename,z_axis, rz, 0)
	WaitForMoves(piecename)
	Show(piecename)
	maxval= math.max(math.abs(rx),math.abs(rz))
	speedVal= (maxval/(moveTimeMS/1000))
	Move(piecename,y_axis, 0, speedVal)
	Move(piecename,z_axis, 0, speedVal)
	WaitForMoves(piecename)
end

function crowdAnimation()
	Graph = piece"Graph"
	while true do
		Hide(Graph)
		timeVal= math.random(1,6)*5*1000
		process(TablesOfPiecesGroups["Crowd"],
			function(id)
				StartThread(randomGraphMovement, id, timeVal)
			end)
		Sleep(timeVal)
		Show(Graph)
		Sleep(5000)
	end
end

function socialEngineeringPosWriteUp()
	if not GG.SocialEngineeredPeople then GG.SocialEngineeredPeople ={} end
	if not GG.SocialEngineers then GG.SocialEngineers ={} end
	GG.SocialEngineers[unitID] = true
	while true do
		x,y,z = spGetUnitPosition(unitID)
		 process(getAllInCircle(x,z, GameConfig.socialEngineeringRange, unitID, gaiaTeamID),
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
	GG.SocialEngineers[unitID] = nil
    -- createCorpseCUnitGeneric(recentDamage)
    return 1
end

