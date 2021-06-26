function gadget:GetInfo()
    return {
        name = "Police",
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

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

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

local spSetUnitBlocking = Spring.SetUnitBlocking
local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local spSetUnitNeutral = Spring.SetUnitNeutral
local spSetUnitNoSelect = Spring.SetUnitNoSelect
local spRequestPath = Spring.RequestPath
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit

local UnitDefNames = getUnitDefNames(UnitDefs)
local PoliceTypes = getPoliceTypes(UnitDefs)
local PoliceDamageCounter = 0

local activePoliceUnitIds_DispatchTime = {}
local maxNrPolice = GameConfig.maxNrPolice
local officersInReserve = maxNrPolice

local activePoliceUnitIds_Dispatchtime = {}
local MobileCivilianDefIds = getMobileCivilianDefIDTypeTable(UnitDefs)
local CivAnimStates = getCivilianAnimationStates()
local PanicAbleCivliansTable = getPanicableCiviliansTypeTable(UnitDefs)


local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "truck", UnitDefs)
local houseTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture, "house", UnitDefs)
local gaiaTeamID = Spring.GetGaiaTeamID() 
accumulatedCivilianDamage =0

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

    return math.random(10,90)*game.mapSizeX/100, 0, math.random(10,90)*game.mapSizeZ/100
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

    houseID, x, z = getNearestHouse(sx, sz, GameConfig.policeSpawnMinDistance)
    if houseID then
      sx, sz = x,z
    end

    return sx, 0, sz
end



function gadget:UnitCreated(unitID, unitDefID, teamID)
    if PoliceTypes[unitDefID] then
        spSetUnitNeutral(unitID, false)        
        activePoliceUnitIds_DispatchTime[unitID] =  GameConfig.policeMaxDispatchTime 
    end

    if isOffenceIcon(UnitDefs, unitDefID) then
        dispatchOfficer(unitID, unitID)
    end
end



function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
    if PoliceTypes[unitDefID] then
        activePoliceUnitIds_DispatchTime[unitID] = nil
        officersInReserve = math.min(officersInReserve + 1,maxNrPolice)
        PoliceDamageCounter= PoliceDamageCounter + 500
    end
end


function getOfficer(victimID, attackerID)
    local officerID = nil
    if officersInReserve > 0 and  math.ceil(accumulatedCivilianDamage/100) > count(activePoliceUnitIds_DispatchTime) then
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
            activePoliceUnitIds_DispatchTime[officerID] =   GameConfig.policeMaxDispatchTime +  math.random(1, GameConfig.policeMaxDispatchTime)
        end

    return officerID
end

function getRandomHousePos()
    id, pos = randDict(GG.BuildingTable)
return pos.x + math.random(200,500)*randSign(), 0, pos.z+ math.random(200,500)*randSign()
end

function dispatchOfficer(victimID, attackerID )
    if not attackerID then attackerID = Spring.GetUnitLastAttacker(victimID) end
    officerID = getOfficer(victimID, attackerID)
    boolFoundSomething = false
    if officerID and doesUnitExistAlive(officerID) == true then
         setFireState(officerID, 2)
         setMoveState(officerID, 2)
        -- Spring.AddUnitImpulse(officerID,15,0,0)
        tx, ty, tz = getRandomHousePos()
        if not attackerID or doesUnitExistAlive(attackerID) then attackerID = Spring.GetUnitLastAttacker(officerID) end
      
        if attackerID then 
            unitStates = Spring.GetUnitStates( victimID ) 
            if unitStates and unitStates.cloak == true then
                attackerID = nil
                Spring.Echo("Attack was cloaked")
            end
        end

        booleanDoesAttackerExistAlive = doesUnitExistAlive(attackerID) 
        if attackerID and booleanDoesAttackerExistAlive == true then
            if not GG.PoliceInPursuit then
                GG.PoliceInPursuit = {}
            end
            GG.PoliceInPursuit[officerID] = attackerID
            x, y, z = spGetUnitPosition(attackerID)
            if x then
                tx, ty, tz = x, y, z;
                boolFoundSomething = true
                --Spring.Echo("")
            end
        elseif boolFoundSomething == false and victimID and doesUnitExistAlive(victimID) == true then 
            Command(officerID, "guard", victimID, {"shift"})
            return
        elseif boolFoundSomething == false  then 
            x, y, z = spGetUnitPosition(officerID)
            if x then
                tx, ty, tz = x + math.random(500,1500)*randSign(), y, z + math.random(500,1500)*randSign();
            end
        end

        Command(officerID, "go", {x = tx, y = ty, z = tz}, {"shift"})
        if maRa() == true  or booleanDoesAttackerExistAlive == false then
            Command(officerID, "go", {x = tx, y = ty, z = tz})
        else
            Command(officerID, "attack", {attackerID}, 4)
        end
    end
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,
                            weaponID, projectileID, attackerID, attackerDefID,
                            attackerTeam)
    if MobileCivilianDefIds[unitDefID] or TruckTypeTable[unitDefID] or houseTypeTable[unitDefID] then
        accumulatedCivilianDamage = accumulatedCivilianDamage + damage
        dispatchOfficer(unitID, attackerID)
    end
end

local firstFrame = Spring.GetGameFrame()

function gadget:Initialize()
    firstFrame = Spring.GetGameFrame() + 1
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

function gadget:GameFrame(frame)
    if frame % 5 == 0 and frame > firstFrame and frame > 0 then
        policeActionTimeSurveilance(frame)       
    end
end
