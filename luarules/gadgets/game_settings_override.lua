function gadget:GetInfo()
    return {
        name = "Overrides settings for mosaic",
        desc = "& Restore settings after gameend",
        author = "Picasso",
        date = "3rd of May 2022",
        license = "GPL3",
        layer = 3,
        version = 1,
        enabled = true
    }
end

if (not gadgetHandler:IsSyncedCode()) then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")

local GameConfig = getGameConfig()

local systemPreMosaicStart = {}
local userConfigMosaic = { 
                         HangTimeout= {name="HangTimeout", value = 303, type="int" }
                         }

function GetTypeDependent(name, type, value)
    if type == "int" then
        return  Spring.GetConfigInt(name) or value
    end
    if type == "float" then
        return  Spring.GetConfigFloat(name) or value
    end
    if type == "string" then
        return  Spring.GetConfigString(name) or value
    end
end

function RestoreTypeDependent(name, type, value)
    return SetTypeDependent(name, type, value)
end

function SetTypeDependent(name, type, value)
    if type == "int" then
        return  Spring.SetConfigInt(name, value)
    end
    if type == "float" then
        return  Spring.SetConfigFloat(name, value)
    end
    if type == "string" then
        return  Spring.SetConfigString(name, value)
    end
end

function gadget:Initialize()
    for name, values in  pairs(userConfigMosaic) do
        local configSetting = values
        systemPreMosaicStart[name] = GetTypeDependent(configSetting.name, configSetting.type, configSetting.value)
        SetTypeDependent(configSetting.name, configSetting.type, configSetting.value)
    end
end

function gadget:Shutdown()
    for systemSetting, value in pairs(systemPreMosaicStart) do
        RestoreTypeDependent(systemSetting, userConfigMosaic[systemSetting].type, value)
    end
end
