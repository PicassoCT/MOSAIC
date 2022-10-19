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

local timeTotal = 35*1000
function script.Create()
  Spring.SetUnitAlwaysVisible(unitID,true)
  Spring.SetUnitBlocking(unitID,false)
  Spring.SetUnitNeutral(unitID, true)
  StartThread(lifeTime, unitID, timeTotal, true, false)
  StartThread(respawnCEG, unitID, timeTotal, true, false)
  StartThread(doDamage)
end

function respawnCEG()
  while true do
    spawnCegAtUnit(unitID, "teargas", 0, 15, 0 )
    rest = math.random(7000,9000)
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
                           if civilianWalkingTypeTable[defID] and not sentFleeing[id] then
                              stunUnit(id, 1.0)
                              reduced= math.random(0,3)/10
                              setSpeedEnv(id, reduced)
                              sentFleeing[id] = id
                              StartThread(startInternalBehaviourOfState,id,"startFleeing", unitID)
                           end
                        end
                        )
    Sleep(5000)
  end
end

function script.Killed(recentDamage, _)
    return 1
end
