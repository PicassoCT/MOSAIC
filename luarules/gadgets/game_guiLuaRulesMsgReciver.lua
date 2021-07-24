function gadget:GetInfo()
    return {
        name = "mosaic_guiReciver",
        desc = "Recives messages from the gui thread",
        author = "zwzsg",
        date = "3rd of May 2010",
        license = "Free",
        layer = 0,
        version = 1,
        enabled = true
    }
end

VFS.Include("scripts/lib_OS.lua")
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_Animation.lua")
VFS.Include("scripts/lib_Build.lua")
VFS.Include("scripts/lib_mosaic.lua")

-- modified the script: only corpses with the customParam "featuredecaytime" will disappear

if (gadgetHandler:IsSyncedCode()) then
    local GameConfig = getGameConfig()

    function gadget:RecvLuaMsg(msg, playerID)
        if msg then
            -- Spring.Echo("RecvLuaMsg"..msg)

            if string.find(msg, "SetGameState:") then 
                msg = msg:gsub("SetGameState:", "")
                    GG.GlobalGameStateOverride = msg
            end

            if string.find(msg, "ResetGameState") then
                GG.GlobalGameStateOverride = nil
            end

        end
    end
end
