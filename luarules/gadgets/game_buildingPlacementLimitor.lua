function gadget:GetInfo()
    return {name='Safehouse Building Limitator', desc='Only completed houses can host safehouses',
        author='MOSAIC', date='2026', license='GPL3', layer=0, enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end
VFS.Include('scripts/lib_UnitScript.lua')
VFS.Include('scripts/lib_mosaic.lua')
local config = getGameConfig()
local safehouses = getSafeHouseTypeTable(UnitDefs)
local houses = getCultureUnitModelNames_Dict_DefIDName(config.game.culture, 'house', UnitDefs)
houses[UnitDefNames.house_asian1.id] = houses[UnitDefNames.house_asian1.id] or 'house_asian1'
local hosts = {}
local maxX, maxZ = math.floor(Game.mapSizeX/16)-1, math.floor(Game.mapSizeZ/16)-1

local function refreshArea(host)
    -- Recompute affected engine squares so removing one house does not erase
    -- a neighbouring completed house's allowance. No duplicate Lua mask map.
    for x=math.max(1,host.x-4), math.min(maxX,host.x+4) do
        for z=math.max(1,host.z-4), math.min(maxZ,host.z+4) do
            local mask = 1
            for _, other in pairs(hosts) do
                if other.ready and math.abs(other.x-x)<=4 and math.abs(other.z-z)<=4 then mask=9; break end
            end
            Spring.SetSquareBuildingMask(x,z,mask)
        end
    end
end
local function refresh(id)
    local host = hosts[id]
    if not host then return end
    host.ready = isCityBuildingHabitable(id)
    refreshArea(host)
end
function gadget:Initialize()
    for x=1,maxX do for z=1,maxZ do Spring.SetSquareBuildingMask(x,z,1) end end
    GG.RefreshCityBuildingMask = refresh
    for _, id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id,Spring.GetUnitDefID(id)) end
end
function gadget:UnitCreated(id, def)
    if not houses[def] then return end
    local x, _, z = Spring.GetUnitPosition(id)
    if x then hosts[id]={x=math.floor(x/16),z=math.floor(z/16)}; refresh(id) end
end
function gadget:UnitFinished(id) refresh(id) end
function gadget:UnitDestroyed(id)
    if hosts[id] then
        local old=hosts[id]
        hosts[id]=nil
        refreshArea(old)
    end
end
function gadget:AllowUnitCreation(def, builder, team, x, y, z)
    if not safehouses[def] then return true end
    if not x or not z then return false end
    for _, id in ipairs(Spring.GetUnitsInCylinder(x,z,config.espionage.safehouses.buildRange) or {}) do
        if houses[Spring.GetUnitDefID(id)] and Spring.GetUnitTeam(id)==Spring.GetGaiaTeamID()
            and isCityBuildingHabitable(id) then return true end
    end
    return false
end
function gadget:Shutdown()
    if GG.RefreshCityBuildingMask == refresh then GG.RefreshCityBuildingMask=nil end
end
