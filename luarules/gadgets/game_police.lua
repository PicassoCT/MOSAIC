function gadget:GetInfo()
    return {
        name = "Game_Police",
        desc = "Handles Police Spawn and dispatch ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 3,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

local boolDebugPolice = false

local GameConfig = getGameConfig()
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitIsDead = Spring.GetUnitIsDead
local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame = Spring.GetGameFrame
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundNormal = Spring.GetGroundNormal
local spGetUnitLastAttacker = Spring.GetUnitLastAttacker
local spGetUnitNearestAlly = Spring.GetUnitNearestAlly
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spSetUnitNeutral = Spring.SetUnitNeutral
local spRequestPath = Spring.RequestPath
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit

local UnitDefNames = getUnitDefNames(UnitDefs)
local PoliceTypes = getPoliceTypes(UnitDefs)
local PoliceDamageCounter = 0

local activePoliceUnitIds_DispatchTime = {}
local maxNrPolice = GameConfig.Police.maxNr
local officersInReserve = maxNrPolice

local activePoliceUnitIds_Dispatchtime = {}
local MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
local CivAnimStates = getCivilianAnimationStates()
local PanicAbleCivliansTable = getPanicableCiviliansTypeTable(UnitDefs)
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                 GameConfig.instance.culture,
                                 "civilian", 
                                 UnitDefs)

local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "truck", UnitDefs)
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
local scrapHeapTypeTable =  getScrapheapTypeTable(UnitDefs)
local gaiaTeamID = Spring.GetGaiaTeamID() 
accumulatedCivilianDamage = 0

function randomAfterFirstFind(boolAtLeastOne)
if boolAtLeastOne == false then return true end
    return math.random(0,1) == 1
end

function getNearestHouse(x, z, minSpawnDistance)
    local locationBuildingTable =  GG.BuildingTable
    currentMinDistance = math.huge
    currentUnit = nil
    boolAtLeastOne = false

    for id, data in pairs(locationBuildingTable) do
        distanceToUnit = math.sqrt((x-data.x)^2 +  (z-data.z)^2)
        if distanceToUnit < currentMinDistance and distanceToUnit > minSpawnDistance and randomAfterFirstFind(boolAtLeastOne) == true then
            currentUnit = id
            currentMinDistance = distanceToUnit
            boolAtLeastOne = true
        end
    end
	
	if not currentUnit then return nil, nil, nil end

    return currentUnit, locationBuildingTable[currentUnit].x, locationBuildingTable[currentUnit].z
end

function getAnyHouseLocation()
    if GG.BuildingTable then
        _, randPos = randDict(GG.BuildingTable)
        if randPos then
            return randPos.x, 0, randPos.z
        end
    end
    conditionalEcho(boolDebugPolice,"Could not find a valid house to spawn police at")

    return math.ceil((math.random(10,90)/100)*game.mapSizeX), 0, math.ceil((math.random(10,90)/100)*game.mapSizeZ)
end

function getPoliceSpawnLocation(suspect)
    if not suspect or type(suspect) ~= "number"  then
       x,y,z =  getAnyHouseLocation()
       return x,y,z 
    end

    sx, sy, sz = spGetUnitPosition(suspect)
    if not sx then
        sx, sy, sz = (Game.mapSizeX/100) * math.random(10,90),0,(Game.mapSizeZ/100) * math.random(10,90) 
    end

    houseID, x, z = getNearestHouse(sx, sz, GameConfig.Police.minSpawnDistance)
    if houseID then
      sx, sz = x,z
    end

    return sx, 0, sz
end

local lastVictimID = nil
function gadget:UnitCreated(unitID, unitDefID, teamID)
    if PoliceTypes[unitDefID] then
        x,y,z = Spring.GetUnitPosition(unitID)
        conditionalEcho(boolDebugPolice, "Officer created at"..x.."/"..z)
        spSetUnitNeutral(unitID, false)        
        activePoliceUnitIds_DispatchTime[unitID] =  GameConfig.Police.maxDispatchTime 
        if lastVictimID and doesUnitExistAlive(lastVictimID) then
            conditionalEcho(boolDebugPolice, "guarding "..lastVictimID.. " a "..getTypeName(lastVictimID))
           tx,ty,tz =spGetUnitPosition(lastVictimID)
            Command(unitID, "go", {x = tx, y = ty, z = tz}, {"shift"})    
            Command(unitID, "go", {x=tx,y=ty, z=tz} )
        end
    end

    if isOffenceIcon(UnitDefs, unitDefID) then
        dispatchOfficer(unitID, unitID, true)
    end
	
	if scrapHeapTypeTable[unitDefID] then
		x,_,z = spGetUnitPosition(unitID)
		registerEmergency(x, z)
	end
end


function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    if PoliceTypes[unitDefID] then
        activePoliceUnitIds_DispatchTime[unitID] = nil
        officersInReserve = math.min(officersInReserve + 1,maxNrPolice)
        PoliceDamageCounter= PoliceDamageCounter + 500
    end
	
	if civilianWalkingTypeTable[unitDefID] then
		x,_,z = spGetUnitPosition(unitID)
		registerEmergency(x, z)
	end
end

function getOfficer(victimID, attackerID, boolBribeOverride)
    lastVictimID = victimID
    local officerID = nil
    if officersInReserve > 0 and  (math.ceil(accumulatedCivilianDamage/100) > count(activePoliceUnitIds_DispatchTime)) or boolBribeOverride then
        px, py, pz = getPoliceSpawnLocation(attackerID)
        _, pos = randDict(GG.BuildingTable)
        if not px then px, py, pz = pos.x, 0, pos.z end
        if not px then px,py,pz = math.random(10,90)*Game.mapSizeX/100, 0, math.random(10,90)*Game.mapSizeZ/100 end
        direction = math.random(1, 4)

        ptype = "policetruck"
        if GG.GlobalGameState == GameConfig.GameState.anarchy or
            GG.GlobalGameState == GameConfig.GameState.pacification or 
            PoliceDamageCounter > 2500
            then
            ptype = randT(PoliceTypes)
            PoliceDamageCounter = PoliceDamageCounter - 2500
        end

        conditionalEcho(boolDebugPolice, "Spawning Police Officer near "..px.."/"..pz)
        GG.UnitsToSpawn:PushCreateUnit(ptype, px, py, pz, direction,
                                 gaiaTeamID)
        officersInReserve = math.max(officersInReserve - 1, 0)
    end

     -- reasign one
        totalNrPolice =  count(activePoliceUnitIds_DispatchTime)
        if totalNrPolice > 1 then
                officerID = randDict(activePoliceUnitIds_DispatchTime)
        elseif totalNrPolice <= 1 then
            for k,v in pairs(activePoliceUnitIds_Dispatchtime) do
                if v then
                    officerID = k 
                    break
                end
            end
        end

        if officerID then
            activePoliceUnitIds_DispatchTime[officerID] =   GameConfig.Police.maxDispatchTime  +  math.random(1, GameConfig.Police.maxDispatchTime )
        end

    return officerID
end

function getRandomDispatchTargetPosition(officerID)
    id, pos = randDict(GG.BuildingTable)
    if not pos then
        nearestEnemy = Spring.GetUnitNearestEnemy(officerID)
        if nearestEnemy then
            pos = {}
            pos.x,_, pos.z = Spring.GetUnitPosition(nearestEnemy)
        end
    end

    return pos.x + math.random(GameConfig.houseSizeX/2, GameConfig.houseSizeX) * randSign(), 0, pos.z + math.random(GameConfig.houseSizeX/2, GameConfig.houseSizeX) * randSign()
end

function dispatchOfficer(victimID, attackerID, boolBribeOverride)
    conditionalEcho(boolDebugPolice, "dispatching officer to help ".. victimID .. " a "..getTypeName(victimID))
    if not attackerID then attackerID = Spring.GetUnitLastAttacker(victimID) end

    officerID = getOfficer(victimID, attackerID, boolBribeOverride)
    boolFoundSomething = false
    if officerID and doesUnitExistAlive(officerID) == true then
        -- Spring.AddUnitImpulse(officerID,15,0,0)
        tx, ty, tz = getRandomDispatchTargetPosition(officerID)

        if not attackerID or doesUnitExistAlive(attackerID) == false then attackerID = Spring.GetUnitLastAttacker(officerID) end
      
        if attackerID then 
            unitStates = Spring.GetUnitStates( victimID ) 
            if unitStates and unitStates.cloak == true then
                attackerID = nil
            end
        end

        booleanDoesAttackerExistAlive = doesUnitExistAlive(attackerID) 
        if attackerID and booleanDoesAttackerExistAlive == true then
            if not GG.PoliceInPursuit then
                GG.PoliceInPursuit = {}
            end
            GG.PoliceInPursuit[officerID] = attackerID
            x, y, z = spGetUnitPosition(attackerID)
            if x and x > 0 and z and z > 0 then
                tx, ty, tz = x, y, z;
                boolFoundSomething = true
            end
        elseif boolFoundSomething == false and victimID and doesUnitExistAlive(victimID) == true then 

            if GG.GlobalGameState == GameConfig.GameState.normal then
                conditionalEcho(boolDebugPolice,"Dispatch Unit ".. officerID.. " to guard ".. victimID .. " a "..getTypeName(victimID))
                Command(officerID, "guard", victimID, {})
            end
            return officerID
        elseif boolFoundSomething == false  then 
            x, y, z = spGetUnitPosition(officerID)
            if x then
                tx, ty, tz = x + math.random(500,1500)*randSign(), y, z + math.random(500,1500)*randSign();
            end
        end

        Command(officerID, "go", {x = tx, y = ty, z = tz}, {"shift"})
        conditionalEcho(boolDebugPolice,"Dispatch Unit ".. officerID.. " to go to ".. tx.."/"..tz)
        if maRa() == true  or booleanDoesAttackerExistAlive == false then
            if GG.GlobalGameState == GameConfig.GameState.normal then
                Command(officerID, "go", {x = tx, y = ty, z = tz})
            else
                --attack some house nearby
                housesNearby = getAllOfTypeNearUnit(officerID, houseTypeTable, 300)
                houseNearby= getSafeRandom(housesNearby)
                if houseNearby  then
                    Command(officerID, "attack", {houseNearby}, 4)
                end
            end
        else
            Command(officerID, "attack", {attackerID}, 4)
            conditionalEcho(boolDebugPolice,"Dispatch Unit ".. officerID.. " to attack ".. attackerID .. " a "..getTypeName(attackerID))
        end

        return officerID
    else
        conditionalEcho(boolDebugPolice, "No officer found to dispatch")
    end   
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                            weaponID, projectileID, attackerID, attackerDefID,
                            attackerTeam)
    if attackerTeam and attackerTeam ~= gaiaTeamID then -- prevent police shooting itself and going full madhouse
        if MobileCivilianDefIds[unitDefID] or TruckTypeTable[unitDefID] or houseTypeTable[unitDefID] then
            accumulatedCivilianDamage = accumulatedCivilianDamage + damage
            officerID = dispatchOfficer(unitID, attackerID)
            boolActionIntervalStart= true
           --[[ if officerID and attackerID then
                echo("officer ".. officerID.. " dispatched to protect "..unitID.. " from "..attackerID)
            end--]]
        end
  

        if PoliceTypes[unitDefID] then 
            activePoliceUnitIds_DispatchTime[unitID] = GameConfig.policeMaxDispatchTime 
            if attackerID and doesUnitExistAlive(attackerID) == true and maRa() then
                Command(unitID, "attack", {attackerID}, 4)
            end
        end
    end
end

local firstFrame = Spring.GetGameFrame()

function gadget:Initialize()
    Spring.Echo("gadget: Loading game_police")
    firstFrame = Spring.GetGameFrame() + 1
    GG.PoliceActionSoundInterVallStartFrame = firstFrame
end

function policeActionTimeSurveilance(frame)
    for id, times in pairs(activePoliceUnitIds_DispatchTime) do
        if times then
            activePoliceUnitIds_DispatchTime[id] = times - 5
            if activePoliceUnitIds_DispatchTime[id] <= 0 then
                spDestroyUnit(id, false, true)
            end
        end
    end
end



local newActionIntervallOffset = (GameConfig.actionIntervallFrames +GameConfig.peaceIntervallFrames)
boolActionIntervalStart = false
function gadget:GameFrame(frame)
    if frame % 5 == 0 and frame > firstFrame and frame > 0 then
        policeActionTimeSurveilance(frame)       
    end

    if boolActionIntervalStart== true and not  GG.PoliceActionSoundInterVallStartFrame or 
        GG.PoliceActionSoundInterVallStartFrame and GG.PoliceActionSoundInterVallStartFrame + newActionIntervallOffset  < frame then
        boolActionIntervalStart = false
        GG.PoliceActionSoundInterVallStartFrame = frame
    end
end
