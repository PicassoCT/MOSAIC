function gadget:GetInfo()
    return {name="Civilian weekend gatherings",desc="Peacetime protests, weddings, yoga and ordinary-car convoys",
        author="MOSAIC contributors",license="GPL3",layer=3,enabled=true}
end
local StoneAudio=VFS.Include("luarules/gadgets/include/civilian_stone_audio.lua")
if not gadgetHandler:IsSyncedCode() then
    local player
    local function impact(_,kind,x,y,z,projectile,bounce)
        player:Receive(kind,x,y,z,projectile,bounce)
    end
    function gadget:Initialize()
        player=StoneAudio.NewPlayer(Spring,Game)
        gadgetHandler:AddSyncAction(StoneAudio.event,impact)
    end
    function gadget:Shutdown() gadgetHandler:RemoveSyncAction(StoneAudio.event) end
    return
end
VFS.Include("scripts/lib_UnitScript.lua")
VFS.Include("scripts/lib_mosaic.lua")
local config=VFS.Include("luarules/configs/civilian_gatherings.lua")
local Controller=VFS.Include("luarules/gadgets/include/civilian_gatherings.lua")
local Stones=VFS.Include("luarules/gadgets/include/civilian_stones.lua")
local controller,stones
local stoneWeapons,stoneDefs={},{}
local stoneUnitKinds
local obscuringWeather={smog=true,sandstorm=true,fog=true}
local weather
local weatherMode=(Spring.GetMapOptions() or {}).dhubai_weather or "automatic"
local weatherPath="LuaUI/Widgets_Map/Include/dhubai_weather.lua"
if VFS.FileExists(weatherPath,VFS.MAP) then weather=VFS.Include(weatherPath,nil,VFS.MAP).New(Game.mapChecksum) end
local function suitableWeather(frame,hour)
    if hour<config.daylightStart or hour>=config.daylightEnd or isRaining(hour) then return false end
    if weather then
        local kind,strength=weather.Evaluate(frame,0,weatherMode)
        if obscuringWeather[kind] and strength>=.05 then return false end
    end
    return not GG.CivilianWeatherMasks
end
local function command(_,line,words)
    local args=words or {}; if #args==0 then for word in (line or ""):gmatch("%S+") do args[#args+1]=word end end
    local action=args[1] or "status"
    if action=="status" then Spring.Echo("Civilian gatherings: "..controller:Status());return true end
    if not Spring.IsCheatingEnabled() then Spring.Echo("Gathering preview commands require cheats.");return true end
    if action=="start" then
        local ok,reason=controller:Start(args[2] or "protest",true)
        Spring.Echo("Gathering "..(ok and "started: " or "unavailable: ")..tostring(reason))
    elseif action=="stop" then controller:Stop("manual stop")
    elseif action=="escalate" then Spring.Echo("Protest escalation: "..tostring(controller:Escalate()))
    else Spring.Echo("Usage: /luarules gatherings start protest|wedding|yoga|convoy, stop, status, escalate") end
    return true
end
function gadget:Initialize()
    for variant=1,2 do
        local def=WeaponDefNames["civilianstone"..variant]
        if def then stoneWeapons[variant]=def.id;stoneDefs[def.id]=true
            Script.SetWatchProjectile(def.id,true);Script.SetWatchExplosion(def.id,true) end
    end
    stoneUnitKinds=StoneAudio.UnitKinds(UnitDefs)
    stones=Stones.New(Spring,Game,stoneWeapons,StoneAudio.NewEmitter(Spring,SendToUnsynced))
    local cars={}
    for _,name in ipairs({"truck_arab0","truck_arab1","truck_western0","truck_western1"}) do
        if UnitDefNames[name] then cars[UnitDefNames[name].id]=true end
    end
    local context={Spring=Spring,GG=GG,Game=Game,UnitDefs=UnitDefs,config=config,gameConfig=getGameConfig(),
        walkers=getCultureUnitModelTypes("international","civilian",UnitDefs),cars=cars,stones=stones,weather=suitableWeather}
    context.objectives=function()
        local out={}
        for _,id in ipairs(Spring.GetAllUnits()) do
            local def=UnitDefs[Spring.GetUnitDefID(id)]
            if def and config.objectives[def.name] then out[id]=true end
        end
        return out
    end
    context.clearance=VFS.Include("scripts/lib_parade_clearance.lua").new(context)
    context.routes=VFS.Include("scripts/lib_city_parade_route.lua").new(context)
    controller=Controller.New(context);GG.CivilianGatherings=controller
    controller:Recover();stones:Recover()
    gadgetHandler:AddChatAction("gatherings",command,"start protest|wedding|yoga|convoy; stop; status; escalate (cheats)")
end
function gadget:GameFrame(frame) controller:Frame(frame);stones:Frame(frame) end
function gadget:UnitDamaged(id,def,team,damage) controller:UnitDamaged(id,damage) end
function gadget:UnitDestroyed(id) controller:UnitDestroyed(id) end
function gadget:UnitTaken(id) controller:UnitDestroyed(id) end
function gadget:ProjectileDestroyed(id) stones:Destroyed(id) end
function gadget:Explosion(def,x,y,z,owner,id)
    if stoneDefs[def] then return stones:Explosion(id,x,y,z) end
end
function gadget:UnitPreDamaged(id,def,team,damage,paralyzer,weapon,projectile)
    if stoneDefs[weapon] then stones:Hit(projectile,stoneUnitKinds[def] or "building_ground") end
    return damage,1
end
function gadget:FeaturePreDamaged(id,def,team,damage,weapon,projectile)
    if stoneDefs[weapon] then stones:Hit(projectile,"building_ground") end
    return damage,1
end
function gadget:Shutdown()
    gadgetHandler:RemoveChatAction("gatherings")
    if controller then controller:Stop("shutdown") end
    if GG.CivilianGatherings==controller then GG.CivilianGatherings=nil end
end
