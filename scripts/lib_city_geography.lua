-- Shared city identity for synced generation and the location widget.
-- Keep the legacy GUI hash, region slots and country arrays unchanged: those
-- choices are part of a map's procedural identity, including fictional states.
-- This module is pure. It never reads client LOCATION messages or GG.Location.
local Geography = {}

local regions = {
    "MiddleEast", "CentralAsia", "Africa", "Europe", "NorthAmerica",
    "SouthAmerica", "SouthEastAsia", "CentralAsia", "CityState",
}

local regionCountries ={
    CityState = {"Redmond","Mare Silentio Company","Singapore", "London", "Dubai", "Hong Kong", "Shanghai", "Lagos", "Falklandia", "Thielon Arcology", "Panama Inc", "Kaliningrad"},
    Africa = {"Chad","Central African Republic","Senegal","Lesotho","Congo","Ghana","Botswana","Togo","Swaziland","South Africa","Eritrea","Zimbabwe","Algeria","Malawi","Sierra Leone","Liberia","Zambia","Kenya","Ethiopia","Guinea","Djibouti","Burkina Faso","Nigeria","Uganda","Comoros","Saint Helena","Guinea-Bissau","Namibia","Gambia","Benin","Gabon","Trinidad And Tobago","Niger","Cameroon","Angola","Cabo Verde","Burundi","Somalia","Mali","Tanzania","Rwanda","Mozambique","Côte D’Ivoire","Madagascar","Saint Martin"},
    MiddleEast = {"Tunisia","Libya","Sudan","Syria","Saudi Arabia","Jordan","Kuwait","Brunei","Algeria","Turkey","Iran","Lebanon","Qatar","West Bank","United Arab Emirates","Israel","Bahrain","Gaza Strip","Armenia","Iraq","Oman","Yemen","Egypt","Morocco","Pakistan", "Western Sahara", "Mauritania"},
    CentralAsia = {"Bhutan","Tajikistan","Iran","Georgia","Nepal","Azerbaijan","Russia","Kyrgyzstan","Afghanistan","Turkmenistan","Pakistan","Uzbekistan","Mongolia","Kazakhstan"},
    Europe = {"Cyprus","Belarus","Slovakia","Greece","Hungary","Montenegro","Macedonia","Kosovo","Sweden","Luxembourg","Belgium","Slovenia","Albania","Turkey","Serbia","Ukraine","France","Liechtenstein","United Kingdom","Iceland","Italy","Czechia","Andorra","Poland","Netherlands","Croatia","Russia","Malta","Germany","Ireland","Portugal","Monaco","Norway","Vatican City","Finland","Bulgaria","Moldova","Estonia","Lithuania","Latvia", "Switzerland","Romania","San Marino","Isle Of Man","Spain","Denmark","Austria","Gibraltar","Bosnia And Herzegovina"},
    NorthAmerica = {"United States","Panama","Canada","Greenland","Jersey","Village of Islands","El Salvador","Mexico",},
    SouthAmerica = {"Belize","Jamaica","Venezuela","Guyana","Equatorial Guinea","Argentina","Brazil","Peru","Ecuador","Honduras","Nicaragua","Bermuda","Bolivia","Cuba","Puerto Rico","Cayman Islands","Chile","Uruguay","Dominican Republic","Costa Rica","French Guiana","Saint Maarten","Mauritius","Saint Lucia","New Caledonia","Paraguay","Guatemala","Barbados","Colombia","French Polynesia",},
    SouthEastAsia = {"Bangladesh","Papua New Guinea","Myanmar","Cambodia","Australia","Thailand","Korea","China","Vietnam","New Zealand","Sri Lanka","Guadeloupe","Taiwan","Malaysia","Macau", "Wallis And Futuna","Grenada","Laos","Anguilla","Christmas Island","Pitcairn Islands","Guam","Singapore","Hong Kong","Japan","Philippines","Indonesia" }
  }

-- Approximate country-centre latitude, used only when the map does not declare
-- its city latitude. These are geographic fallbacks, not political damage ranks.
-- Based on the CIA-authored 2020 World Factbook Geographic coordinates field:
-- https://simonw.github.io/cia-world-factbook-2020/fields/277.html
-- (public-domain snapshot; the original cia.gov Factbook was retired in 2026).
-- Minutes are rounded to tenths. The two Koreas share a peninsula fallback;
-- the legacy "Congo" entry uses the Republic of the Congo. Country names retain
-- the widget's existing spelling. Overseas territories use their own latitude.
local countryLatitudes = {
    ["Afghanistan"] = 33, ["Albania"] = 41, ["Algeria"] = 28,
    ["Andorra"] = 42.5, ["Angola"] = -12.5, ["Anguilla"] = 18.3,
    ["Argentina"] = -34, ["Armenia"] = 40, ["Australia"] = -27,
    ["Austria"] = 47.3, ["Azerbaijan"] = 40.5, ["Bahrain"] = 26,
    ["Bangladesh"] = 24, ["Barbados"] = 13.2, ["Belarus"] = 53,
    ["Belgium"] = 50.8, ["Belize"] = 17.3, ["Benin"] = 9.5,
    ["Bermuda"] = 32.3, ["Bhutan"] = 27.5, ["Bolivia"] = -17,
    ["Bosnia And Herzegovina"] = 44, ["Botswana"] = -22, ["Brazil"] = -10,
    ["Brunei"] = 4.5, ["Bulgaria"] = 43, ["Burkina Faso"] = 13,
    ["Burundi"] = -3.5, ["Cabo Verde"] = 16, ["Cambodia"] = 13,
    ["Cameroon"] = 6, ["Canada"] = 60, ["Cayman Islands"] = 19.5,
    ["Central African Republic"] = 7, ["Chad"] = 15, ["Chile"] = -30,
    ["China"] = 35, ["Christmas Island"] = -10.5, ["Colombia"] = 4,
    ["Comoros"] = -12.2, ["Congo"] = -1, ["Costa Rica"] = 10,
    ["Croatia"] = 45.2, ["Cuba"] = 21.5, ["Cyprus"] = 35,
    ["Czechia"] = 49.8, ["Côte D’Ivoire"] = 8, ["Denmark"] = 56,
    ["Djibouti"] = 11.5, ["Dominican Republic"] = 19, ["Ecuador"] = -2,
    ["Egypt"] = 27, ["El Salvador"] = 13.8, ["Equatorial Guinea"] = 2,
    ["Eritrea"] = 15, ["Estonia"] = 59, ["Ethiopia"] = 8,
    ["Finland"] = 64, ["France"] = 46, ["French Guiana"] = 4,
    ["French Polynesia"] = -15, ["Gabon"] = -1, ["Gambia"] = 13.5,
    ["Gaza Strip"] = 31.4, ["Georgia"] = 42, ["Germany"] = 51,
    ["Ghana"] = 8, ["Gibraltar"] = 36.1, ["Greece"] = 39,
    ["Greenland"] = 72, ["Grenada"] = 12.1, ["Guadeloupe"] = 16.3,
    ["Guam"] = 13.5, ["Guatemala"] = 15.5, ["Guinea"] = 11,
    ["Guinea-Bissau"] = 12, ["Guyana"] = 5, ["Honduras"] = 15,
    ["Hong Kong"] = 22.3, ["Hungary"] = 47, ["Iceland"] = 65,
    ["Indonesia"] = -5, ["Iran"] = 32, ["Iraq"] = 33,
    ["Ireland"] = 53, ["Isle Of Man"] = 54.3, ["Israel"] = 31.5,
    ["Italy"] = 42.8, ["Jamaica"] = 18.3, ["Japan"] = 36,
    ["Jersey"] = 49.3, ["Jordan"] = 31, ["Kazakhstan"] = 48,
    ["Kenya"] = 1, ["Korea"] = 38.5, ["Kosovo"] = 42.6,
    ["Kuwait"] = 29.5, ["Kyrgyzstan"] = 41, ["Laos"] = 18,
    ["Latvia"] = 57, ["Lebanon"] = 33.8, ["Lesotho"] = -29.5,
    ["Liberia"] = 6.5, ["Libya"] = 25, ["Liechtenstein"] = 47.3,
    ["Lithuania"] = 56, ["Luxembourg"] = 49.8, ["Macau"] = 22.2,
    ["Macedonia"] = 41.8, ["Madagascar"] = -20, ["Malawi"] = -13.5,
    ["Malaysia"] = 2.5, ["Mali"] = 17, ["Malta"] = 35.8,
    ["Mauritania"] = 20, ["Mauritius"] = -20.3, ["Mexico"] = 23,
    ["Moldova"] = 47, ["Monaco"] = 43.7, ["Mongolia"] = 46,
    ["Montenegro"] = 42.5, ["Morocco"] = 32, ["Mozambique"] = -18.3,
    ["Myanmar"] = 22, ["Namibia"] = -22, ["Nepal"] = 28,
    ["Netherlands"] = 52.5, ["New Caledonia"] = -21.5, ["New Zealand"] = -41,
    ["Nicaragua"] = 13, ["Niger"] = 16, ["Nigeria"] = 10,
    ["Norway"] = 62, ["Oman"] = 21, ["Pakistan"] = 30,
    ["Panama"] = 9, ["Papua New Guinea"] = -6, ["Paraguay"] = -23,
    ["Peru"] = -10, ["Philippines"] = 13, ["Pitcairn Islands"] = -25.1,
    ["Poland"] = 52, ["Portugal"] = 39.5, ["Puerto Rico"] = 18.3,
    ["Qatar"] = 25.5, ["Romania"] = 46, ["Russia"] = 60,
    ["Rwanda"] = -2, ["Saint Helena"] = -16, ["Saint Lucia"] = 13.9,
    ["Saint Maarten"] = 18.1, ["Saint Martin"] = 18.1, ["San Marino"] = 43.8,
    ["Saudi Arabia"] = 25, ["Senegal"] = 14, ["Serbia"] = 44,
    ["Sierra Leone"] = 8.5, ["Singapore"] = 1.4, ["Slovakia"] = 48.7,
    ["Slovenia"] = 46.1, ["Somalia"] = 10, ["South Africa"] = -29,
    ["Spain"] = 40, ["Sri Lanka"] = 7, ["Sudan"] = 15,
    ["Swaziland"] = -26.5, ["Sweden"] = 62, ["Switzerland"] = 47,
    ["Syria"] = 35, ["Taiwan"] = 23.5, ["Tajikistan"] = 39,
    ["Tanzania"] = -6, ["Thailand"] = 15, ["Togo"] = 8,
    ["Trinidad And Tobago"] = 11, ["Tunisia"] = 34, ["Turkey"] = 39,
    ["Turkmenistan"] = 40, ["Uganda"] = 1, ["Ukraine"] = 49,
    ["United Arab Emirates"] = 24, ["United Kingdom"] = 54, ["United States"] = 38,
    ["Uruguay"] = -33, ["Uzbekistan"] = 41, ["Vatican City"] = 41.9,
    ["Venezuela"] = 8, ["Vietnam"] = 16.2, ["Wallis And Futuna"] = -13.3,
    ["West Bank"] = 32, ["Western Sahara"] = 24.5, ["Yemen"] = 15,
    ["Zambia"] = -15, ["Zimbabwe"] = -20,
    -- Existing real-world city-state names use their own approximate latitude.
    ["Redmond"] = 47.7, ["London"] = 51.5, ["Shanghai"] = 31.2,
    ["Lagos"] = 6.5, ["Kaliningrad"] = 54.7, ["Dubai"] = 25.2,
}

-- These fictional entities have no established physical coordinates in the
-- map data. Do not infer a continent from their names or procedural provinces.
-- A moderate 45-degree fallback is explicit until a map supplies its latitude.
local unknownLatitude = 45
local fictionalCountries = {
    ["Mare Silentio Company"] = true, ["Falklandia"] = true,
    ["Thielon Arcology"] = true, ["Panama Inc"] = true,
    ["Village of Islands"] = true,
}

local aliases = {
    ["uae"] = "United Arab Emirates", ["dhubay"] = "Dubai",
    ["dhubai"] = "Dubai", ["united states of america"] = "United States",
    ["usa"] = "United States", ["uk"] = "United Kingdom",
    ["north macedonia"] = "Macedonia", ["eswatini"] = "Swaziland",
    ["burma"] = "Myanmar", ["cote d'ivoire"] = "Côte D’Ivoire",
    ["ivory coast"] = "Côte D’Ivoire", ["sint maarten"] = "Saint Maarten",
}
local countryRegions = {}
-- Use the legacy region-slot order when a country occurs in several lists.
-- Procedurally selected regions are retained verbatim; this lookup is only for
-- explicit country metadata, which otherwise has no region of its own.
for i = 1, #regions do
    local region = regions[i]
    for _, country in ipairs(regionCountries[region]) do
        aliases[country:lower()] = country
        if not countryRegions[country] then countryRegions[country] = region end
    end
end

local function finiteNumber(value)
    if type(value) ~= "number" and type(value) ~= "string" then return nil end
    local number = tonumber(value)
    if number and number == number and number > -math.huge and number < math.huge then
        return number
    end
end

function Geography.Latitude(value)
    local latitude = finiteNumber(value)
    if latitude and latitude >= -90 and latitude <= 90 then return latitude end
end

local function countryName(value)
    if type(value) ~= "string" then return nil end
    local name = value:match("^%s*(.-)%s*$")
    if name == "" then return nil end
    return aliases[name:lower()] or name
end

function Geography.Hash(game)
    game = game or {}
    local name = type(game.mapName) == "string" and game.mapName or ""
    local hash = 0
    for i = 1, #name do hash = hash + name:byte(i) end
    return hash + (finiteNumber(game.mapSizeX) or 0) + (finiteNumber(game.mapSizeZ) or 0)
end

function Geography.RegionByHash(hash)
    return regions[((finiteNumber(hash) or 0) % #regions) + 1]
end

function Geography.CountryByRegion(region, hash)
    local countries = regionCountries[region] or regionCountries.CityState
    return countries[(((finiteNumber(hash) or 0) * 69) % #countries) + 1]
end

function Geography.CountryLatitude(country)
    local name = countryName(country)
    if name and countryLatitudes[name] ~= nil then
        return countryLatitudes[name], "country-fallback"
    end
    if name and fictionalCountries[name] then
        return unknownLatitude, "fictional-country-fallback"
    end
    return unknownLatitude, "unknown-country-fallback"
end

function Geography.IsDubaiMap(mapName)
    local name = type(mapName) == "string" and mapName:lower():gsub("[^a-z]", "") or ""
    return name:find("lastdayofdubai", 1, true) ~= nil
        or name:find("lastdayofdhubai", 1, true) ~= nil
end

-- metadata comes from the map archive (mosaic/location.lua), not a LuaUI
-- message. Explicit city latitude wins, then a known named map, then a country
-- representative latitude. A country-only override intentionally re-localizes
-- a reused map and therefore does not inherit the original named city's latitude.
function Geography.Resolve(game, metadata)
    game = game or {}
    metadata = type(metadata) == "table" and metadata or {}
    local hash = Geography.Hash(game)
    local region = Geography.RegionByHash(hash)
    local explicitCountry = countryName(metadata.country)
    local isDubai = Geography.IsDubaiMap(game.mapName)
        and (not explicitCountry or explicitCountry == "United Arab Emirates" or explicitCountry == "Dubai")
    local country = explicitCountry
        or (isDubai and "United Arab Emirates")
        or Geography.CountryByRegion(region, hash)
    if isDubai then
        region = "MiddleEast"
    elseif explicitCountry then
        region = countryRegions[country] or "Unknown"
    end
    if type(metadata.region) == "string" and regionCountries[metadata.region] then
        region = metadata.region
    end
    local latitude = Geography.Latitude(metadata.latitude)
    local source = "map-metadata"
    if latitude == nil then
        if isDubai then
            -- Dubai: 25.252222 N (NGA GNS / UNGEGN), rounded for gameplay.
            -- https://ungegn.un.org/dashboard/cities/details?id=1893
            latitude, source = 25.2, "named-map"
        else
            latitude, source = Geography.CountryLatitude(country)
        end
    end
    return {hash = hash, region = region, country = country, latitude = latitude,
        source = source, isDubai = isDubai}
end

Geography.RegionCountries = regionCountries
Geography.UnknownLatitude = unknownLatitude
return Geography
