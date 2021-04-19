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



function gadget:GameFrame(frame)
    if frame % 5 == 0 then
        updateLocationData()
    end
end

else --unsynced

    local function HandleRevealedLocationUpdates(cmd, NewRevealedLocations)
        if Script.LuaUI('RevealedGraphChanged')then
            Script.LuaUI.RevealedGraphChanged(NewRevealedLocations)
        end
    end

    function gadget:Initialize()
        gadgetHandler:AddSyncAction("HandleRevealedLocationUpdates")
    end

    function gadget:Shutdown()
        gadgetHandler:RemoveSyncAction("HandleRevealedLocationUpdates")
    end

end
