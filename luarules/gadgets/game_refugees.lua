function gadget:GetInfo()
    return {
        name = "Refugee Streams and Military Gadget",
        desc = "Coordinates Refugeestreams ",
        author = "Picasso",
        date = "3rd of May 2022",
        license = "GPL3",
        layer = 4,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

statistics = {}
local GameConfig = getGameConfig()
--if not Game.version then Game.version = GameConfig.instance.Version end
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
local spSetUnitRotation = Spring.SetUnitRotation

local spSetUnitBlocking = Spring.SetUnitBlocking
local spSetUnitAlwaysVisible = Spring.SetUnitAlwaysVisible
local spSetUnitNeutral = Spring.SetUnitNeutral
local spSetUnitNoSelect = Spring.SetUnitNoSelect
local spRequestPath = Spring.RequestPath
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit

local UnitDefNames = getUnitDefNames(UnitDefs)
local TruckTypeTable = getCultureUnitModelTypes(GameConfig.instance.culture,
                                                "truck", UnitDefs)

local loadableTruckType = getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local refugeeAbleTruckType = getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, GameConfig.instance.culture)
local gaiaTeamID = Spring.GetGaiaTeamID() 

local isFailedState = (( getDetermenisticMapHash(Game) % 2 ) == 0) or true
local MAX_STUCK_COUNTER = 3
local isPeaceTime= true

Spring.Echo("Game:Civilians: Map is a failed state ".. toString(isFailedState))

function attachPayload(payLoadID, id)
    if payLoadID then
           --echo("Attaching payload to refugee")
           Spring.SetUnitAlwaysVisible(payLoadID,true)
           pieceMap = Spring.GetUnitPieceMap(id)
           --assert(pieceMap["attachPoint"], "Truck has no attachpoint")
           Spring.UnitAttach(id, payLoadID, pieceMap["attachPoint"])
           return payLoadID
    end
end

function loadTruck(id, loadType)
    if loadableTruckType[spGetUnitDefID(id)] then
        --Spring.Echo(id .. " is a loadable truck ")
--        Spring.Echo("createUnitAtUnit ".."game_refugees.lua")   
        payLoadID = createUnitAtUnit(gaiaTeamID, loadType, id)

        return attachPayload(payLoadID, id)
    end
end

function loadRefugee(id, loadType)
    if refugeeAbleTruckType[spGetUnitDefID(id)] then
     --   Spring.Echo(id .. " is a refugee loadable truck ")
        --Spring.Echo("createUnitAtUnit ".."game_refugees.lua") 
        payLoadID = createUnitAtUnit(gaiaTeamID, loadType, id)
        return attachPayload(payLoadID, id)
    end
end

function getCultureDependentDiretion(culture)
    if culture == "arabic" then return 0 end
    
    return math.max(1, math.floor(math.random(1, 3)))
 end

function spawnUnit(defID, x, z)
    if not x then
        echo("Spawning unit of typ " .. UnitDefs[defID].name ..
                 " with no coords")
    end
    
    dir = getCultureDependentDiretion(GameConfig.instance.culture)
    h = spGetGroundHeight(x, z)
    id = spCreateUnit(defID, x, h, z, dir, gaiaTeamID)

    if id then
        spSetUnitAlwaysVisible(id, true)
        return id
    end
end



function gadget:Initialize()
    for i=1,4 do
        setUpRefugeeWayPoints(i)
    end
end

local militaryExitPointType = getMilitarySpawnExitTypes(UnitDefs)
function getMilitaryObjectiveEntryPoint()
    local result = {}
    local objectives = GG.Objectives
    for unitID, objective in pairs(objectives) do 
        if militaryExitPointType[objective.defID] then
            result[#result+1] = unitID
        end 
    end
    return result
end

local refugeeEntryExitPointType = getRefugeeSpawnExitTypes(UnitDefs)
function getRefugeeObjectiveEntryPoint()
    local result = {}
    local objectives = GG.Objectives
    for unitID, objective in pairs(objectives) do 
        if refugeeEntryExitPointType[objective.defID] then
            result[#result+1] = unitID
        end 
    end
    return result
end

function getMilitarySpawnPoint(index, boolIgnoreObjectives)
    if not boolIgnoreObjectives then
        militaryEntryPoints = getMilitaryObjectiveEntryPoint()
        if #militaryEntryPoints > 0 then
            mine = militaryEntryPoints[(index % #militaryEntryPoints) +1]
            if mine then
                x,y,z = spGetUnitPosition(mine)
                return x, z
            end 
        end 
    end
    return getMilitaryPoint(index)
end

function getMilitaryExitPoint(index, boolIgnoreObjectives)
    return getMilitaryPoint(index)
end


function getRefugeeExitPoint(index, boolIgnoreObjectives)
    if not boolIgnoreObjectives and isPeaceTime then
        refugeeEntryPoints = getRefugeeObjectiveEntryPoint()
        if #refugeeEntryPoints > 0 then
            mine = refugeeEntryPoints[(index % #refugeeEntryPoints) +1]
            if mine then
                x,y,z = spGetUnitPosition(mine)
                return x, z
            end 
        end 
    end
    return getRefugeePoint(index)
end

function getRefugeeEntryPoint(index, boolIgnoreObjectives)
    if not isPeaceTime then
        unitId, pos =  randDict(GG.BuildingTable)
        if unitId then
            return pos.x, pos.z
        end
    end

    if not boolIgnoreObjectives then
        refugeeEntryPoints = getRefugeeObjectiveEntryPoint()
        if #refugeeEntryPoints > 0 then
            mine = getSafeRandom(refugeeEntryPoints, 1)
            if mine then
                x,y,z = spGetUnitPosition(mine)
                return x, z
            end 
        end 
    end
    return getRefugeePoint(index)
end

indexOffset = 0


function getMilitaryPoint(index)
    if index == 1 then return 25,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
    if index == 2 then return Game.mapSizeX,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
    if index == 3 then return GG.CivilianEscapePointTable[index] * Game.mapSizeX, 25 end
    if index == 4 then return GG.CivilianEscapePointTable[index] * Game.mapSizeX, Game.mapSizeZ end
    Spring.Echo("Unknown EscapePoint")
end

function setUpRefugeeWayPoints(index)
    if not GG.CivilianEscapePointTable then GG.CivilianEscapePointTable = {} end
     GG.CivilianEscapePointTable[index] = math.random(1,1000)/1000  
end


local escapeeHash = getDetermenisticMapHash(Game)
local rStuck = {}
local refugeeTable = {}
function refugeeStream(frame)
    ex,ez = getRefugeeExitPoint(((escapeeHash + 1 + indexOffset)%4)+1)
    ey = spGetGroundHeight(ex,ez)
    if ey < 0 then
        indexOffset = indexOffset +1
    end

  
    boolAtLeastOnePath = false
         foreach(refugeeTable,
            function(id)
                if  id and  not spGetUnitIsDead(id) then return id else   refugeeTable[id] = nil end
            end,
             function(id) --stuckdetection
                    if not rStuck[id] then 
                        rStuck[id] = {counter = 0, pos = {}}
                        rStuck[id].pos.x,rStuck[id].pos.y,rStuck[id].pos.z = 0,0,0
                    end

                    x,y,z = spGetUnitPosition(id)
                    if x then 
                        dist = distance(x,y,z, rStuck[id].pos.x,rStuck[id].pos.y,rStuck[id].pos.z )
                            if dist < 30 then
                               rStuck[id].counter = rStuck[id].counter + 1 
                            else
                                rStuck[id].counter = math.max(0, rStuck[id].counter -1)
                            end
                        rStuck[id].pos.x,rStuck[id].pos.y,rStuck[id].pos.z = x,y,z
                        return id
                    end
                end,
            function(id)
                if distanceUnitToPoint(id, ex,ey,ez) < 150 or rStuck[id].counter > MAX_STUCK_COUNTER then
                    spDestroyUnit(id, false, true)
                    refugeeTable[id] = nil
                    if rStuck[id].counter > MAX_STUCK_COUNTER then
                       setUpRefugeeWayPoints(((escapeeHash + 1 + indexOffset)%4)+1)
                       rStuck[id] = nil
                    end
                else
  
                     ex,ez = getRefugeeExitPoint(((escapeeHash + 1+ indexOffset)%4)+1)
                     ey = spGetGroundHeight(ex,ez)
                     if ey < 0 then
                        indexOffset = indexOffset +1
                     end
                     offx, offz = math.random(25, 50) , math.random(25, 50) 
                     Command(id, "go", {x = ex + offx,y = ey,z = ez + offz }, {"shift"})
                     Command(id, "go", {x = ex + offx,y = ey,z = ez + offz }, {})
                     path = Spring.GetUnitEstimatedPath(id)
                     if path then
                        boolAtLeastOnePath = true
                    end
                end
            end
        )
    if not boolAtLeastOnePath then
        setUpRefugeeWayPoints(((escapeeHash + 1 + indexOffset)%4)+1)
    end

    if count(refugeeTable) < math.random(3,5) then
       sx,sz = getRefugeeEntryPoint(((escapeeHash+ indexOffset) % 4) + 1, maRa())
       if spGetGroundHeight(sx,sz) < 0 then
            indexOffset = indexOffset +1
            return
       end
       local id =  spawnUnit("truck_arab"..math.random(1,8), sx, sz)
--       echo("Start Loading refugee")
       payloadID = loadRefugee(id, "truckpayloadrefugee")
       --assert(payloadID)

       refugeeTable[id]= id   
       Spring.SetUnitTooltip(id, "Refugee from ".. getCountryByCulture(GameConfig.instance.culture , escapeeHash + math.random(0,1)*randSign()))

        offx, offz = math.random(25, 50) * randSign(), math.random(25, 50) * randSign()
        Spring.SetUnitMoveGoal(id, ex, ey, ez)
        Command(id, "go", {x = ex + offx,y = ey,z = ez + offz }, {})
    end   
end

local militaryTable = {}
local mStuck = {}
local militaryUnitTypesTable = getSpawnedMilitaryUnitTypeTable()
function militaryStream(frame)
    local ex,ez = getMilitaryExitPoint(((escapeeHash + indexOffset)%4)+1)
    local ey = spGetGroundHeight(ex,ez)
    if ey < 0 then
        indexOffset = indexOffset +1
        return
    end

    if not isPeaceTime then        
        aex,aez =  GG.DamageHeatMap:getHighestDangerLocation()
        if aex then
            ex, ez = aex, aez
            ey = spGetGroundHeight(ex,ez)
        end
    end

    boolAtLeastOnePath = false
         foreach(militaryTable,           
            function(id)
                if  id and not spGetUnitIsDead(id) then return id else  militaryTable[id] = nil end 
            end,
             function(id) --stuckdetection
                    if not mStuck[id] then 
                        mStuck[id] = {counter = 0, pos = {}}
                        mStuck[id].pos.x,mStuck[id].pos.y,mStuck[id].pos.z = 0,0,0
                    end

                    x,y,z = spGetUnitPosition(id)
                    if not x then return end
                    dist = distance(x,y,z, mStuck[id].pos.x,mStuck[id].pos.y,mStuck[id].pos.z )
          
                        if dist < 30 then
                           mStuck[id].counter = mStuck[id].counter + 1 
                        else
                            mStuck[id].counter = math.max(0, mStuck[id].counter -1)                      
                        end

                    mStuck[id].pos.x,mStuck[id].pos.y,mStuck[id].pos.z= x,y,z        
                    return id
                end,
            function(id)
                if distanceUnitToPoint(id, ex,ey,ez) < 150 or mStuck[id].counter > MAX_STUCK_COUNTER then
                    spDestroyUnit(id, false, true)
                    militaryTable[id] = nil
                    if mStuck[id].counter > MAX_STUCK_COUNTER then
                        setUpRefugeeWayPoints(((escapeeHash + indexOffset)%4)+1)
                    end
                    mStuck[id] = nil              
                else                    
                     offx, offz = math.random(25, 50) , math.random(25, 50) 
                     Command(id, "go", {x = ex + offx,y = ey,z = ez + offz }, {"shift"})
                     Command(id, "go", {x = ex + offx,y = ey,z = ez + offz }, {})
                     path = Spring.GetUnitEstimatedPath(id)
                     if path then
                        boolAtLeastOnePath = true
                    end
                end
            end
        )
    if not boolAtLeastOnePath then
        setUpRefugeeWayPoints(((escapeeHash + indexOffset)%4)+1)
    end

    target =  math.max(0,math.random(3,5) - count(militaryTable))
    for i= 1, target, 1 do
       local sx,sz = getMilitarySpawnPoint(((escapeeHash + indexOffset + 1)%4)+1)
       local id =  spawnUnit(militaryUnitTypesTable[math.random(1,#militaryUnitTypesTable)], sx, sz) 
       militaryTable[id]= id         
      
        --Spring.AddUnitImpulse(id, math.random(-10,10)/2, 5, math.random(-10,10)/2)
        offx, offz = math.random(25, 50) * randSign(), math.random(25, 50) * randSign()
        Spring.SetUnitMoveGoal(id, ex, ey, ez)
        Command(id, "go", {x = ex + offx,y = ey,z = ez + offz }, {})
    end   
end

function gadget:GameFrame(frame)
    if frame % 60 == 0 then
        isPeaceTime = GG.GlobalGameState == GameConfig.GameState.normal

        if isFailedState or not isPeaceTime  then
            refugeeStream(frame)
        end
    end

    if (isFailedState or not isPeaceTime) and frame % 600 == 0 then
        militaryStream(frame)
    end
end
