function gadget:GetInfo()
    return {name="Civilian weather masks", desc="Civilians mask up during smog and sandstorms",
        author="MOSAIC contributors", license="GPL v2 or later", layer=-5, enabled=true}
end
if not gadgetHandler:IsSyncedCode() then return false end

-- Reuse the map's pure simulation-frame schedule, rather than independently
-- rolling weather or trusting a player's local renderer/preview settings.
local weatherPath="LuaUI/Widgets_Map/Include/dhubai_weather.lua"
if not VFS.FileExists(weatherPath,VFS.MAP) then return false end
local Weather=VFS.Include(weatherPath,nil,VFS.MAP)
local controller=Weather.New(Game.mapChecksum)
local mode=(Spring.GetMapOptions() or {}).dhubai_weather or "automatic"
local maskingWeather={smog=true,sandstorm=true}
local active=false
local civilians={}
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local civilianDefs=getCultureUnitModelTypes("international","civilian",UnitDefs)
if UnitDefNames.civilianagent then civilianDefs[UnitDefNames.civilianagent.id]=true end

local function refresh(id)
    if not Spring.ValidUnitID(id) or Spring.GetUnitIsDead(id) then return end
    local env=Spring.UnitScript.GetScriptEnv(id)
    if env and env.updateWeatherMask then Spring.UnitScript.CallAsUnit(id,env.updateWeatherMask) end
end

local function setActive(value)
    active=value
    GG.CivilianWeatherMasks=value
    for id in pairs(civilians) do refresh(id) end
end

local function update(frame)
    -- Smog/storm slots are daytime, after natural rain has dried and before
    -- the next rainy evening. Fog does not trigger masks. Local rain previews
    -- are deliberately not simulation input.
    local weather,strength=controller.Evaluate(frame,0,mode)
    local masked=maskingWeather[weather] == true and strength >= (active and 0.02 or 0.05)
    if masked~=active then setActive(masked) end
end

function gadget:UnitCreated(id,defID)
    if civilianDefs[defID] then civilians[id]=true end
    -- The civilian's own Create/bodyBuild applies the current flag, including
    -- births in mid-storm, independent of script/gadget initialization order.
end

function gadget:UnitDestroyed(id)
    civilians[id]=nil
end

function gadget:Initialize()
    GG.CivilianWeatherMasks=false
    for _,id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id,Spring.GetUnitDefID(id)) end
    update(Spring.GetGameFrame())
    if not active then setActive(false) end -- clear stale presentation after reload
end

function gadget:GameFrame(frame)
    if frame%30==0 then update(frame) end
end

function gadget:Shutdown()
    setActive(false)
    GG.CivilianWeatherMasks=nil
end
