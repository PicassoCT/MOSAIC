function gadget:GetInfo()
    return {
        name = "Send Revealed UnitsData",
        desc = "Updates tables for revealed Unit Display widget",
        author = "Picasso",
        date = "3rd of May 2021",
        license = "GPL3",
        layer = 3,
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

function gadget:Initialize()
    if not GG.RevealedLocations then GG.RevealedLocations = {} end
end


local function addTestLocation()
  local locations = {}
  local allUnits = Spring.GetAllUnits()
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
      if boolOneParentOnly == false then   
        revealedUnits[dependent].boolIsParent = false
      else
         boolOneParentOnly= false
        revealedUnits[dependent].boolIsParent = true
      end
    end
  end

  local n = #locations
  locations[n + 1]  = {}
  locations[#locations].radius = 50 --coordinates.x
  locations[#locations].x = math.random(2000, 4000) --coordinates.x
  locations[#locations].y = 0 --coordinates.y + 10
  locations[#locations].z = math.random(2000, 4000) --coordinates.z
  locations[#locations].teamID = Spring.GetUnitTeam(locationID)
  locations[#locations].revealedUnits = revealedUnits

  return locations
end

function updateLocationData()
    if not GG.RevealedLocations then GG.RevealedLocations = {} end

    for nr, LocationData in pairs(GG.RevealedLocations) do
        boolAtLeastOneAlive = false
         for id, data in pairs(LocationData.revealedUnits) do
            if doesUnitExistAlive(id) == false then
                GG.RevealedLocations[nr].revealedUnits[id] = nil
            else
                boolAtLeastOneAlive = true
            end
         end
         if not boolAtLeastOneAlive then
            GG.RevealedLocations[nr] = nil
         end
    end

    if GG.RevealedLocations then
        SendToUnsynced("HandleRevealedLocationUpdates", serializeTableToString(GG.RevealedLocations))
    end
end

startFrame = Spring.GetGameFrame()

function gadget:GameFrame(frame)
    if frame % 5 == 0 then
        updateLocationData()
    end

    if frame % 30*10 == 0 and frame > startFrame then
        GG.RevealedLocations = addTestLocation()
    end
end

else --unsynced

    function HandleRevealedLocationUpdates(cmd, NewRevealedLocations)
        if Script.LuaUI('RevealedGraphChanged')then
            Script.LuaUI.RevealedGraphChanged(NewRevealedLocations)
        end
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("HandleRevealedLocationUpdates", HandleRevealedLocationUpdates)
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("HandleRevealedLocationUpdates")
    end

end
