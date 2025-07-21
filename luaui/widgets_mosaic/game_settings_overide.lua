function widget:GetInfo()
	return {
	  name = "Overrides settings for mosaic",
        desc = "Store & Restore settings after gameend",
		author = "Pica",
		date = "April 2020",
		license = "GNU GPL, v2 or later",
		layer = 1,
		enabled = true,
		hidden = true
	}
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


local systemPreMosaicStart = {}
local userConfigMosaic = { 
                         HangTimeout = {name = "HangTimeout", value = 900, type="int" },
                         MaxTextureAtlasSizeX = {name = "MaxTextureAtlasSizeX", value = 4096, type="int" },
                         MaxTextureAtlasSizeY = {name = "MaxTextureAtlasSizeY", value = 2048, type="int" },
                         MaxTextureAtlasSizeZ = {name = "MaxTextureAtlasSizeZ", value = 4096, type="int" },
                         ShadowMapSize = {name = "ShadowMapSize", value = 8192, type="int" },
                         TextureMemPoolSize = {name = "TextureMemPoolSize", value = 256, type="int" },
                         }

local function GetTypeDependent(name, type, value)
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

local function SetTypeDependent(name, type, value)
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

local function RestoreTypeDependent(name, type, value)
    return SetTypeDependent(name, type, value)
end

function widget:Initialize()
	--store only changed old Value

    for name, values in  pairs(userConfigMosaic) do
        local configSetting = values
        systemPreMosaicStart[name] = { value = GetTypeDependent(configSetting.name, configSetting.type, configSetting.value), name = name, type = configSetting.type }
        SetTypeDependent(configSetting.name, configSetting.type, configSetting.value)
    end
end

function widget:Shutdown()
    for systemSettingName, values in pairs(systemPreMosaicStart) do
        local configSetting = values
        if configSetting then
            RestoreTypeDependent(configSetting.name, configSetting.type, configSetting.value)
        end
    end
end