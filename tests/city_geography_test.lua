-- Run from repository root: lua5.1 tests/city_geography_test.lua
local function loadInEnvironment(path, environment)
    local chunk, err
    if setfenv then
        chunk, err = loadfile(path)
        assert(chunk, err)
        setfenv(chunk, environment)
    else
        chunk, err = loadfile(path, "t", environment)
        assert(chunk, err)
    end
    return chunk()
end

local function eq(actual, expected, message)
    assert(actual == expected, (message or "unexpected value") .. ": "
        .. tostring(actual) .. " ~= " .. tostring(expected))
end

local forbidden = setmetatable({}, {
    __index = function() error("geography must not read runtime or client state") end,
})
local pureEnvironment = setmetatable({
    GG = forbidden, Spring = forbidden, VFS = forbidden,
    math = setmetatable({random = function() error("geography must be deterministic") end}, {__index = math}),
}, {__index = _G})
local Geography = loadInEnvironment("scripts/lib_city_geography.lua", pureEnvironment)
local game = {mapName = "TestMap", mapSizeX = 1024, mapSizeZ = 2048}

-- Preserve the exact pre-refactor map identity and every legacy country choice.
local legacy = Geography.Resolve(game)
eq(legacy.hash, 3774, "legacy byte-sum hash")
eq(legacy.region, "Europe", "legacy region slot")
eq(legacy.country, "Italy", "legacy country choice")
eq(legacy.latitude, 42.8)
eq(legacy.source, "country-fallback")
local snapshots = {
    CityState = {count = 12, checksum = 831150},
    Africa = {count = 45, checksum = 8958483},
    MiddleEast = {count = 27, checksum = 2556285},
    CentralAsia = {count = 14, checksum = 905030},
    Europe = {count = 49, checksum = 9825980},
    NorthAmerica = {count = 8, checksum = 340082},
    SouthAmerica = {count = 30, checksum = 4805277},
    SouthEastAsia = {count = 27, checksum = 3583667},
}
local unique = {}
for region, snapshot in pairs(snapshots) do
    local countries = Geography.RegionCountries[region]
    eq(#countries, snapshot.count, region .. " content count")
    local content, checksum = table.concat(countries, "|"), 0
    for i = 1, #content do checksum = (checksum + i * content:byte(i)) % 2147483647 end
    eq(checksum, snapshot.checksum, region .. " content and ordering")
    for _, country in ipairs(countries) do
        unique[country] = true
        local latitude, source = Geography.CountryLatitude(country)
        assert(Geography.Latitude(latitude), "missing valid fallback for " .. country)
        assert(source ~= "unknown-country-fallback", "unclassified legacy country " .. country)
    end
end
local count = 0
for _ in pairs(unique) do count = count + 1 end
eq(count, 205, "all legacy country and city-state names remain available")

local zero = Geography.Resolve(game, {country = "Ecuador", latitude = 0})
eq(zero.latitude, 0, "the equator is a valid explicit latitude")
eq(zero.country, "Ecuador")
eq(zero.source, "map-metadata")
eq(Geography.Resolve(game, {country = "Brazil", latitude = -12.25}).latitude, -12.25)
eq(Geography.Resolve(game, {country = "Finland"}).latitude, 64)
eq(Geography.Resolve(game, {country = "Brazil"}).latitude, -10)
eq(Geography.Resolve(game, {country = "Singapore"}).latitude, 1.4)
eq(Geography.Resolve(game, {country = " New Zealand "}).latitude, -41)
eq(Geography.Resolve(game, {latitude = "0"}).latitude, 0)
eq(Geography.Resolve(game, {latitude = -90}).latitude, -90)
eq(Geography.Resolve(game, {latitude = 90}).latitude, 90)

for _, invalid in ipairs({91, -91, math.huge, -math.huge, 0/0, "north", {}, false, true}) do
    local location = Geography.Resolve(game, {country = "Finland", latitude = invalid})
    eq(location.latitude, 64, "invalid metadata must use the country fallback")
    eq(location.source, "country-fallback")
end
eq(Geography.Resolve(game, false).country, legacy.country)
eq(Geography.Resolve(game, {country = " "}).country, legacy.country)
local unknown = Geography.Resolve(game, {country = "The Ice March"})
eq(unknown.country, "The Ice March", "custom names are retained")
eq(unknown.latitude, 45, "unknown country fallback must be explicit and moderate")
eq(unknown.source, "unknown-country-fallback")
local fictional = Geography.Resolve(game, {country = "Thielon Arcology"})
eq(fictional.country, "Thielon Arcology")
eq(fictional.latitude, 45)
eq(fictional.source, "fictional-country-fallback")

for _, mapName in ipairs({"LastDayOfDubai v1", "LastDayOfDhubai v2", "MOSAIC_Last_Day_of_Dhubai_v5"}) do
    local dubaiGame = {mapName = mapName, mapSizeX = 8192, mapSizeZ = 8192}
    local dubai = Geography.Resolve(dubaiGame)
    eq(dubai.country, "United Arab Emirates")
    eq(dubai.region, "MiddleEast")
    eq(dubai.latitude, 25.2)
    eq(dubai.source, "named-map")
    assert(dubai.isDubai)
    local relocated = Geography.Resolve(dubaiGame, {country = "Finland"})
    eq(relocated.latitude, 64, "a country override re-localizes reused map terrain")
    eq(relocated.country, "Finland")
    assert(not relocated.isDubai)
    eq(Geography.Resolve(dubaiGame, {latitude = 0}).latitude, 0, "authored city latitude overrides named map")
end
print("PASS: pure shared geography, metadata validation, both hemispheres, 205 legacy names, Dubai aliases")

-- Exercise the real config import and location widget together. Metadata comes
-- from the map VFS; client LOCATION output must never select a different country.
local function startLocationWidget(mapName, metadata)
    local messages = {}
    local engineEnvironment = setmetatable({
        Game = {mapName = mapName, mapSizeX = 8192, mapSizeZ = 8192},
        Spring = {
            GetGameFrame = function() return 100 end,
            GetViewGeometry = function() return 1920, 1080 end,
            GetGameRulesParam = function() return "international" end,
            SendLuaRulesMsg = function(message) messages[#messages + 1] = message end,
            Echo = function() end, PlaySoundFile = function() end,
        },
        gl = {Color = function() end, Text = function() end},
    }, {__index = _G})
    -- LuaUI copies this exact allowlist into each widget. It exposes pairs,
    -- getfenv and VFS but deliberately has no _G fallback; using an unrestricted
    -- environment here previously hid a real config-import startup crash.
    loadInEnvironment("luaui/system.lua", engineEnvironment)
    local environment = {widget = {}, WG = {}}
    for key, value in pairs(engineEnvironment.System) do environment[key] = value end
    assert(environment._G == nil and environment.pairs == pairs,
        "location fixture must reproduce the real LuaUI builtins without _G")
    environment.VFS = {MAP = "map", GAME = "game"}
    environment.VFS.FileExists = function(path, mode)
        return path == "mosaic/location.lua" and mode == "map" and metadata ~= nil
    end
    environment.VFS.Include = function(path, includeEnvironment, mode)
        if path == "mosaic/location.lua" then
            eq(mode, "map", "metadata must come from the map archive")
            return metadata
        end
        return loadInEnvironment(path, includeEnvironment or environment)
    end
    local configEnvironment = setmetatable({MOSAIC_CONFIG_ONLY = true}, {__index = environment})
    local config = loadInEnvironment("scripts/lib_mosaic.lua", configEnvironment)
    local expectedLocation = config.getCityGeography(environment.Game)
    loadInEnvironment("luaui/widgets_mosaic/gui_cityname.lua", environment)
    environment.widget:Initialize()
    environment.widget:ViewResize(1280, 720)
    environment.widget:DrawScreenEffects(1280, 720)
    environment.widget:Shutdown()
    assert(configEnvironment.GG == nil and environment.GG == nil, "config-only GUI import must not initialize synced state")
    eq(#messages, 1)
    return messages[1], expectedLocation
end

for _, name in ipairs({"LastDayOfDubai v1", "LastDayOfDhubai v2"}) do
    local message, location = startLocationWidget(name)
    assert(message:find("Country: Dhubay", 1, true))
    assert(message:find("City: Dubai", 1, true))
    assert(message:find("Province: Capital City", 1, true))
    assert(message:find("District: Trade center", 1, true))
    eq(location.latitude, 25.2)
end
local message, location = startLocationWidget("Generic Arena", {country = "Finland", latitude = 64})
eq(location.country, "Finland")
assert(message:find("Country: Finland, Europe", 1, true))
message, location = startLocationWidget("Generic Arena", {country = "The Ice March", latitude = -55})
eq(location.latitude, -55)
assert(message:find("Country: The Ice March", 1, true))
assert(message:find("Province: Unspecified", 1, true))
assert(message:find("City: Unspecified", 1, true))
message = startLocationWidget("LastDayOfDubai v1", {country = "Finland"})
assert(message:find("Country: Finland, Europe", 1, true))
assert(not message:find("Dhubay", 1, true), "overridden country must also change the displayed locale")
print("PASS: shared synced/UI country, archive metadata, preserved Dubai titles, safe custom-country display")
