function gadget:GetInfo()
    return {
        name = "SendRevealedUnitsData",
        desc = "Updates tables for revealed Unit Display widget",
        author = "Picasso",
        date = "3rd of May 2021",
        license = "GPL3",
        layer = 0,
        version = 1,
        enabled = true
    }
end

if ( gadgetHandler:IsSyncedCode()) then 

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

local  boolTestGraph = true

function gadget:Initialize()
    if not GG.RevealedLocations then GG.RevealedLocations = {} end
end

local function addTestLocation()
  local locations = GG.RevealedLocations
  local allUnits = Spring.GetAllUnits()
  if #allUnits < 1 then return {} end

  local choiceIndex = math.random(1,#allUnits)
  local locationID = allUnits[choiceIndex]
  local coordinates = {}
  coordinates.x,coordinates.y, coordinates.z = Spring.GetUnitBasePosition(locationID)
  local revealedUnits = {}
  local upperBound = math.random(3,6)

  local i = 1
  local boolOneParentOnly= true
  for i=1,  upperBound do
    local rIndex = math.random(1,#allUnits)
    local dependent = allUnits[rIndex]

    if dependent then
        revealedUnits[dependent]={}
        revealedUnits[dependent].defID = Spring.GetUnitDefID(dependent)
        revealedUnits[dependent].name = extractNameFromDescription(dependent)
    	x,y,z = Spring.GetUnitPosition(dependent)
        revealedUnits[dependent].pos = {x=x,y=y,z=z}
        if boolOneParentOnly == false then   
          revealedUnits[dependent].boolIsParent = false
        else
           boolOneParentOnly= false
          revealedUnits[dependent].boolIsParent = true
        end      
    end
  end

  local n = #locations +1
  locations[n]  = {}
  locations[n].radius = 50 --coordinates.x
  locations[n].x = math.random(2000, 4000) --coordinates.x
  locations[n].y = 0 --coordinates.y + 10
  locations[n].z = math.random(2000, 4000) --coordinates.z
  locations[n].teamID = Spring.GetUnitTeam(locationID)
  locations[n].revealedUnits = revealedUnits
  locations[n].endFrame = Spring.GetGameFrame() + GG.GameConfig.raid.revealGraphLifeTimeFrames

  GG.RevealedLocations = locations
end

local function updateLocationData()
    for nr, LocationData in pairs(GG.RevealedLocations) do
        boolAtLeastOneAlive = false
        if LocationData and type(LocationData) == "table" and LocationData.revealedUnits then
         for id, data in pairs(LocationData.revealedUnits) do
            if data and doesUnitExistAlive(id) == false then
                GG.RevealedLocations[nr].revealedUnits[id] = nil
            else
                x,y,z = Spring.GetUnitPosition(id)
                GG.RevealedLocations[nr].revealedUnits[id].pos= {x=x,y=y,z=z}
                boolAtLeastOneAlive = true
            end
         end
        end
         if not boolAtLeastOneAlive then
            GG.RevealedLocations[nr] = nil
         end
    end

    if GG.RevealedLocations then
        SendToUnsynced("HandleRevealedLocationUpdates", 
		serializeTableToString(GG.RevealedLocations))
    end
end

startFrame = Spring.GetGameFrame()

function gadget:GameFrame(frame)
    if frame % 3 == 0 then
        updateLocationData()
    end

    --remove outdated graph data
    if frame % 30 == 0 then
        for i= #GG.RevealedLocations or 1, 1, -1 do
            if GG.RevealedLocations[i] and GG.RevealedLocations[i].endFrame < frame then
                GG.RevealedLocations = table.remove(GG.RevealedLocations,i)
            end
        end
    end

    if boolTestGraph == true and frame > 0 and frame % (60*30) == 0  then
        --Spring.Echo("Debugmode: adding TestLocation")
        --addTestLocation()
    end
end

else --unsynced
   local function HandleRevealedLocationUpdates(_, NewRevealedLocations)
        if Script.LuaUI('RevealedGraphChanged') then
            Script.LuaUI.RevealedGraphChanged(NewRevealedLocations)
        end
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction('HandleRevealedLocationUpdates', HandleRevealedLocationUpdates)
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction('HandleRevealedLocationUpdates', HandleRevealedLocationUpdates)
    end
end
