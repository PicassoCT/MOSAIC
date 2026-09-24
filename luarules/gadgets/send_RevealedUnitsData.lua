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
VFS.Include("scripts/lib_mosaic.lua")

local  boolTestGraph = false

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
local function updateLocationData(frame)
    local active = {}
    for _, location in pairs(GG.RevealedLocations or {}) do
        if type(location) == "table" and location.revealedUnits and
            location.endFrame and location.endFrame > frame then
            local anyAlive = false
            for id, data in pairs(location.revealedUnits) do
                local x,y,z = Spring.GetUnitPosition(id)
                if not data or not x or not doesUnitExistAlive(id) then
                    location.revealedUnits[id] = nil
                else
                    data.pos = {x=x,y=y,z=z}
                    anyAlive = true
                end
            end
            if anyAlive then active[#active+1] = location end
        end
    end
    GG.RevealedLocations = active
    SendToUnsynced("HandleRevealedLocationUpdates", serializeTableToString(active))
end

startFrame = Spring.GetGameFrame()

function gadget:GameFrame(frame)
    if frame % 3 == 0 then updateLocationData(frame) end

    if boolTestGraph == true and frame > 0 and frame % (60*30) == 0  then
        --Spring.Echo("Debugmode: adding TestLocation")
        addTestLocation()
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
