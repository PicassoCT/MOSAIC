include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"
local spGetUnitDefID = Spring.GetUnitDefID
local GameConfig = getGameConfig()
local civilianWalkingTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture,
                                     "civilian", UnitDefs)

local truckTypeTable = getCultureUnitModelTypes(
                                     GameConfig.instance.culture,
                                     "truck", UnitDefs)

local timeTotal = 35*1000
function script.Create()
  Spring.SetUnitAlwaysVisible(unitID,true)
  Spring.SetUnitBlocking(unitID,false)
  Spring.SetUnitNeutral(unitID, true)
  StartThread(lifeTime, unitID, timeTotal, true, false)
  StartThread(respawnCEG, unitID, timeTotal, true, false)
  StartThread(doDamage)
end
teargasCEGs = {
                "teargas",
                "teargasdark"
                }
function respawnCEG()
  while true do
    spawnCegAtUnit(unitID, teargasCEGs[math.random(1,#teargasCEGs)], 0, 15, 0 )
    rest = math.random(5000,7000)
    Sleep(rest)
  end
end


function startInternalBehaviourOfState(id, name, enemyID)
    rest = math.min(1,id % 5)*500
    Sleep(rest)
    setSpeedEnv(id, 1.0)

  env = Spring.UnitScript.GetScriptEnv(id)
  if env and env.startFleeing then
      Spring.UnitScript.CallAsUnit(id, 
                                   env.startFleeing,
                                   enemyID)
  end
end    

function doDamage()
  while true do
    foreach(getAllInCircle(px,pz, GameConfig.teargasRadius, unitID),
                        function(id)
                           defID= spGetUnitDefID(id)
                           if civilianWalkingTypeTable[defID] then
                              stunUnit(id, 1.0)
                              reduced= math.random(0,3)/10
                              setSpeedEnv(id, reduced)
                              StartThread(startInternalBehaviourOfState,id,"startFleeing", unitID)
                           end
                           if truckTypeTable[defID] then
                                stunUnit(id, 4.0)
                           end
                        end
                        )
    Sleep(5000)
  end
end

function script.Killed(recentDamage, _)
    return 1
end
