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

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

function gadget:Initialize()
    if not GG.RevealedLocations then GG.RevealedLocations = {} end
end

function updateLocationData()
    if not GG.RevealedLocations then GG.RevealedLocations = {} end
    for unitID, LocationData in pairs(GG.RevealedLocations) do
         for id, data in pairs(LocationData.revealedUnits) do
            if doesUnitExistAlive(id) == false then
                GG.RevealedLocations[unitID].revealedUnits[id] = nil
            end
         end
    end
end

function gadget:GameFrame(frame)
   updateLocationData()
end
