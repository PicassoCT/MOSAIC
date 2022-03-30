function widget:GetInfo()
	return {
	  name = "Overrides settings for mosaic",
        desc = "& Restore settings after gameend",
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
                         HangTimeout= {name="HangTimeout", value = 303, type="int" }
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

local function RestoreTypeDependent(name, type, value)
    return SetTypeDependent(name, type, value)
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

function widget:Initialize()
    for name, values in  pairs(userConfigMosaic) do
        local configSetting = values
        systemPreMosaicStart[name] = GetTypeDependent(configSetting.name, configSetting.type, configSetting.value)
        SetTypeDependent(configSetting.name, configSetting.type, configSetting.value)
    end
end

function widget:Shutdown()
    for systemSetting, value in pairs(systemPreMosaicStart) do
        RestoreTypeDependent(systemSetting, userConfigMosaic[systemSetting].type, value)
    end
end