--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    ico_customicons.lua
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
-- This gadget checks through the attributes of each unitdef and assigns an appropriate icon for use in the minimap & zoomed out mode.
--
-- The reason that this is a gadget (it could also be a widget) and not part of weapondefs_post.lua/iconTypes.lua is the following:  
-- the default valuesfor UnitDefs attributes that are not specified in our unitdefs lua files are only loaded into UnitDefs AFTER  
-- unitdefs_post.lua and iconTypes.lua have been processed. For example, at the time of unitdefs_post, for most units ud.speed is  
-- nil and not a number, so we can't e.g. compare it to zero. Also, it's more modularized as a widget/gadget. 
-- [We could set the default values up in unitdefs_post to match engine defaults but thats just too hacky.]
--
-- Bluestone 27/04/2013
--------------------------------------------------------------------------------
function gadget:GetInfo()
    return {
        name = "CustomIcons",
        desc = "Sets custom unit icons",
        author = "trepan,BD,TheFatController,Floris",
        date = "Jan 8, 2007",
        license = "GNU GPL, v2 or later",
        layer = -100,
        enabled = true --  loaded by default?
    }
end

--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then return false end

--------------------------------------------------------------------------------

local iconScale = 1.05
if Spring.GetConfigFloat then
    iconScale = Spring.GetConfigFloat("UnitIconScale", 1.05)
end

local icons = {
    -- ID,   icon png file,   scale
    {"satellitegodrod", "orbitalstrike_sat", 0.75},
    {"satelliteanti", "antisattelit_sat", 0.75},
    {"satellitescan", "surveilance_sat", 0.75}, {"house_arab0", "house", 0.75},
    {"policetruck", "truck_police", 1.0}, {"assembly", "assembly", 1.0},
    {"nimrod", "nimrod", 1.0}, {"doubleagent", "doubleagent", 1.0},
    {"launcher", "launcher", 1.0}, {"ground_tank_night", "tank", 1.0},
    {"ground_tank_day", "tank", 1.0},
    {"recruitcivilian", "recruitcivilian", 1.0}, {"raidicon", "raidicon", 1.0},
    {"interrogationicon", "interrogationicon", 1.0},
    {"propagandaserver", "propagandaserver", 1.0},
    {"antagonsafehouse", "antagonsafehouse", 1.0},
    {"protagonsafehouse", "protagonsafehouse", 1.0},
    {"operativeasset", "operativeasset", 1.0},
    {"operativepropagator", "operativepropagator", 1.0},
    {"operativeinvestigator", "operativeinvestigator", 1.0},
    {"civilianagent", "civilianagent", 1.0},
    {"ground_truck_mg", "truck_mg", 1.0}, {"blacksite", "blacksite", 1.0},
    {"ground_walker_mg", "ground_walker_mg", 1.0},
    {"truck_assembly", "truck_assembly", 1.0},
    {"air_antiarmour", "air_antiarmour", 1.0}, {"air_gun", "air_gun", 1.0},
    {"air_sniper", "air_sniper", 1.0}, {"air_copter_ssied", "air_copter_ssied", 1.0},
    {"AeroSolDrone", "AeroSolDrone", 1.0},
    {"ground_turret_spyder", "ground_turret_spyder", 1.0},
    {"ground_turret_ssied", "ground_turret_ssied", 1.0},
    {"ground_turret_mg", "ground_turret_mg", 1.0},
    {"ground_turret_rocket", "ground_turret_rocket", 1.0},
    {"ground_turret_cm", "ground_turret_cm", 1.0}, {"ai", "ai", 1.0},
    {"hivemind", "hivemind", 1.0}

}

for i = 0, 3 do icons[#icons + 1] = {"civilian_arab" .. i, "civilian", 0.5} end

for i = 0, 8 do icons[#icons + 1] = {"truck_arab" .. i, "truck", 0.5} end

function getIconID(name) -- does not check if file exists
    if string.sub(name, #name - 4) ~= '.user' then name = name .. '.user' end
    for i, icon in ipairs(icons) do
        local iconName = icon[1]
        if string.sub(iconName, #iconName - 4) ~= '.user' then
            iconName = iconName .. '.user'
        end
        if iconName == name then
            if icon[4] then
                return i
            else
                return false
            end
        end
    end
    return false
end

local iconTypes = {}
function addUnitIcon(icon, file, size)
    Spring.AddUnitIcon(icon, file, size)
    iconTypes[icon] = file
end

local loadedIcons = {}
function loadUnitIcons()

    -- free up icons
    for i, icon in ipairs(loadedIcons) do Spring.FreeUnitIcon(icon) end
    iconTypes = {}
    loadedIcons = {}

    -- load icons
    for i, icon in ipairs(icons) do
        icons[i][4] = nil -- reset
        -- Spring.FreeUnitIcon(icon[1])
        if VFS.FileExists('icons/' .. icon[2] .. icon[3] .. '.png') then -- check if specific custom sized icon is availible
            addUnitIcon(icon[1], 'icons/' .. icon[2] .. icon[3] .. '.png',
                        icon[3] * iconScale)
        else
            addUnitIcon(icon[1], 'icons/' .. icon[2] .. '.png',
                        icon[3] * iconScale)
        end
        loadedIcons[#loadedIcons + 1] = icon[1]
    end

    -- load custom unit icons when availible
    local files = VFS.DirList('icons', "*.png")
    local files2 = VFS.DirList('icons/inverted', "*.png")
    for k, file in ipairs(files2) do files[#files + 1] = file end
    for k, file in ipairs(files) do
        local scavPrefix = ''
        local scavSuffix = ''
        local inverted = ''
        if string.find(file, 'inverted') then
            scavPrefix = 'scav_'
            scavSuffix = '_scav'
            inverted = 'inverted/'
        end
        local name = string.gsub(file, 'icons\\', '') -- when located in spring folder
        name = string.gsub(name, 'icons/', '') -- when located in game archive
        name = string.gsub(name, 'inverted/', '') -- when located in game archive
        local iconname = string.gsub(name, '.png', '')
        if iconname then
            local iconname = string.match(iconname, '([a-z0-9-_]*)')

            for i, icon in ipairs(icons) do
                if string.gsub(icon[1], '.user', '') == iconname then

                    local scalenum = icon[3]

                    addUnitIcon(icon[1], 'icons/' .. iconname .. '.png',
                                tonumber(scalenum) * iconScale)
                    loadedIcons[#loadedIcons + 1] = icon[1]
                end
            end
        end
    end

    -- tag all icons that have a valid file
    for i, icon in ipairs(icons) do
        if VFS.FileExists('icons/' .. icon[2] .. '.png') then
            icons[i][4] = true
        end
    end

    -- assign (standard) icons

    -- load and assign custom unit icons when availible
    local customUnitIcons = {}
    local files = VFS.DirList('icons', "*.png")
    local files2 = VFS.DirList('icons/inverted', "*.png")
    for k, file in ipairs(files2) do files[#files + 1] = file end
    for k, file in ipairs(files) do
        local scavPrefix = ''
        local scavSuffix = ''

        local name = string.gsub(file, 'icons\\', '') -- when located in spring folder
        name = string.gsub(name, 'icons/', '') -- when located in game archive
        name = string.gsub(name, 'inverted/', '') -- when located in game archive
        name = string.gsub(name, '.png', '')
        if name then
            local unitname = string.match(name, '([a-z0-9]*)')
            if unitname and UnitDefNames[unitname] then
                local scale = string.gsub(name, unitname, '')
                scale = string.gsub(scale, '_', '')
                if scale ~= '' and UnitDefNames[unitname] then
                    addUnitIcon(scavPrefix .. unitname .. ".user", file,
                                tonumber(scale) * iconScale)
                    Spring.SetUnitDefIcon(UnitDefNames[unitname].id,
                                          scavPrefix .. unitname .. ".user")
                    loadedIcons[#loadedIcons + 1] = unitname .. ".user"
                end
            end
        end
    end
end

local myPlayerID = Spring.GetMyPlayerID()

function gadget:GotChatMsg(msg, playerID)
    if playerID == myPlayerID then
        if string.sub(msg, 1, 14) == "uniticonscale " then
            iconScale = tonumber(string.sub(msg, 15))
            Spring.SetConfigFloat("UnitIconScale", iconScale)
            loadUnitIcons()
            -- Spring.SendCommands("minimap unitsize "..Spring.GetConfigFloat("MinimapIconScale", 3.5-(iconScale-1)))
        end
    end
end

function GetIconTypes() return iconTypes end

function gadget:Initialize()
    gadgetHandler:RegisterGlobal('GetIconTypes', GetIconTypes)
    loadUnitIcons()
end

--------------------------------------------------------------------------------

