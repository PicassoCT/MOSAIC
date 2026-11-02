function gadget:GetInfo()
    return {
        name = "Seventh evening city parade",
        desc = "Peace-time float traffic, religious spectators and rooftop paper showers",
        author = "MOSAIC contributors", license = "GPL3", layer = 2, enabled = true,
    }
end
if not gadgetHandler:IsSyncedCode() then return false end

VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
VFS.Include("scripts/lib_staticstring.lua")
local controller = VFS.Include("luarules/gadgets/include/city_parade.lua")
local routes = VFS.Include("scripts/lib_city_parade_route.lua")
local config = VFS.Include("luarules/configs/city_parade.lua")
local catalog = VFS.Include("scripts/lib_truck_parade_payloads.lua")
local parade, chatRegistered

local function count(t)
    local total = 0
    for _ in pairs(t or {}) do total = total + 1 end
    return total
end

local function paradeCommand(_, line, words)
    local action = type(words) == "table" and words[1]
        or (type(line) == "string" and line:match("^%s*(%S+)")) or "status"
    action = tostring(action):lower()
    if action == "status" then
        Spring.Echo("City parade: " .. (parade and parade.phase or "unavailable") ..
            ", vehicles=" .. count(parade and parade.vehicles) ..
            ", participants=" .. count(parade and parade.participants))
        return true
    end
    if action ~= "start" and action ~= "stop" then
        Spring.Echo("Usage: /luarules parade start|stop|status")
        return true
    end
    if not Spring.IsCheatingEnabled() then
        Spring.Echo("City parade preview start/stop requires cheats; status is always available.")
        return true
    end
    if not parade then return true end
    if action == "start" then
        local accepted, reason = parade:RequestPreview(Spring.GetGameFrame())
        Spring.Echo("City parade preview " .. (accepted and "requested" or "unavailable") ..
            (reason and (": " .. tostring(reason)) or ""))
    else
        parade:Stop("manual preview stop")
        Spring.Echo("City parade stopped.")
    end
    return true
end

function gadget:Initialize()
    local gameConfig = getGameConfig()
    local ruins = getBuildingRuinTypeTable(UnitDefs)
    local scrap = getBuildingScrapHeapTypeTable(UnitDefs)
    local buildingTypes = {}
    for defID, value in pairs(getCultureUnitModelTypes("international", "house", UnitDefs)) do
        if not ruins[defID] and not scrap[defID] then buildingTypes[defID] = value end
    end
    local context = {
        Spring=Spring, GG=GG, Game=Game, UnitDefs=UnitDefs, UnitDefNames=UnitDefNames,
        gameConfig=gameConfig, config=config, catalog=catalog, setSpeed=setSpeedEnv,
        walkerTypes=getCultureUnitModelTypes("international", "civilian", UnitDefs),
        truckTypes=getCultureUnitModelTypes("international", "truck", UnitDefs),
        buildingTypes=buildingTypes,
    }
    context.routeBuilder = routes.new(context)
    parade = controller.New(context)
    GG.CityParade = parade
    parade:Recover()
    gadgetHandler:AddChatAction("parade", paradeCommand,
        "start|stop|status: preview the parade (start/stop require cheats)")
    chatRegistered = true
end
function gadget:GameFrame(frame) parade:Frame(frame) end
function gadget:UnitDamaged(id, defID, teamID, damage) parade:UnitDamaged(id,damage) end
function gadget:UnitDestroyed(id) parade:UnitDestroyed(id) end
function gadget:Shutdown()
    if chatRegistered then
        gadgetHandler:RemoveChatAction("parade")
        chatRegistered = false
    end
    if parade then parade:Shutdown() end
    if GG.CityParade == parade then GG.CityParade = nil end
end
