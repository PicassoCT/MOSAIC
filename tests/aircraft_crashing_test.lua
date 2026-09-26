-- Run from the repository root with lua or texlua.
local function read(path)
    local f = assert(io.open(path)); local text = f:read('*a'); f:close(); return text
end
local function normalize(t)
    if type(t) ~= 'table' then return t end
    local result = {}
    for k, v in pairs(t) do
        result[type(k) == 'string' and k:lower() or k] = normalize(v)
    end
    return result
end
function lowerkeys(t)
    local result = normalize(t)
    for k in pairs(t) do t[k] = nil end
    for k, v in pairs(result) do t[k] = v end
    return t
end
Spring = {GetModOptions = function() return {} end}
VFS = {ZIP = 1, Include = function(path)
    if path == 'gamedata/VFSUtils.lua' then return end
    if path == 'gamedata/system.lua' then return {lowerkeys = lowerkeys} end
    if path == 'gamedata/sidedata.lua' then return {} end
    return dofile(path)
end}
-- Use the actual inheritance rules, including overrides in derived units.
local pre = read('gamedata/unitdefs_pre.lua')
assert((loadstring or load)(pre:sub(1, assert(pre:find('local sharedEnv =', 1, true)) - 1)))()
for _, path in ipairs({'AirDrones', 'Abstract', 'Satellite'}) do
    for name, class in pairs(dofile('baseclasses/units/'..path..'.lua')) do _G[name] = class end
end
local files = {
    'units/shared/chasis/air/plane/air_plane_fighterjet.lua',
    'units/shared/chasis/air/plane/air_plane_artillery.lua',
    'units/shared/chasis/air/plane/air_plane_rocket.lua',
    'units/shared/chasis/air/plane/air_plane_sniper.lua',
    'units/shared/chasis/air/copter/air_copter_blackhawk.lua',
    'units/shared/chasis/air/copter/air_copter_mg.lua',
    'units/shared/chasis/air/copter/air_copter_antiarmor.lua',
    'units/shared/chasis/air/copter/air_copter_scoutlett.lua',
    'units/shared/chasis/air/copter/air_copter_ssied.lua',
    'units/shared/chasis/air/copter/air_parachute_dropdrone.lua',
    'units/protagon/air_copteraerosol.lua',
    'units/neutral/advertisingblimp.lua',
    'units/neutral/house_spinner.lua',
    'units/neutral/house_vtol.lua',
}
UnitDefs = {}
local names, covered = {}, 0
for _, file in ipairs(files) do
    for name, def in pairs(dofile(file)) do
        assert(def.canfly and def.customparams.crashable == 1, name..' missing crash opt-in')
        covered = covered + 1; names[name] = covered
        UnitDefs[covered] = {canFly = true, customParams = def.customparams, weapons = def.weapons or {}}
    end
end
assert(covered == 17, 'all 17 concrete aircraft definitions covered')
assert(Aero:New().customparams.crashable == 1)
assert(not Rocket:New().customparams.crashable, 'ICBM keeps its scripted flight/death')
for _, def in pairs(dofile('units/shared/chasis/air/copter/air_parachut.lua')) do
    assert(def.customparams.crashable == 0, 'infantry parachute excluded')
end
-- Runtime excludes other flying entities and respects explicit opt-outs.
UnitDefs[100] = {canFly = true, customParams = {baseclass = 'Abstract'}, weapons = {}}
UnitDefs[101] = {canFly = true, customParams = {crashable = '0'}, weapons = {}}
UnitDefs[102] = {canFly = false, customParams = {crashable = '1'}, weapons = {}}
UnitDefs[103] = {canFly = true, customParams = {crashable = '1'}, weapons = {{}}}

local units, frame, nextID, destroyed = {}, 90, 0, {}
GG = {}; Game = {gameSpeed = 30}; CMD = {SELFD = 65}; COB = {CRASHING = 97}
gadgetHandler = {IsSyncedCode = function() return true end}
local function unit(def, options)
    nextID = nextID + 1
    local u = {def = def, health = 100, build = 1, y = 100, ground = 0,
        state = 'flying', rules = {}, sensors = {}, weapons = {}, selfD = 0, hooks = 0}
    for k, v in pairs(options or {}) do u[k] = v end
    units[nextID] = u
    return nextID, u
end
Spring = {
    GetUnitDefID = function(id) return units[id] and units[id].def end,
    GetUnitIsDead = function(id) return units[id].dead end,
    GetUnitHealth = function(id) local u=units[id]; return u.health,100,0,0,u.build end,
    GetUnitTransporter = function(id) return units[id].transporter end,
    GetUnitPosition = function(id) return id,units[id].y,0 end,
    GetGroundHeight = function(x) return units[x].ground end,
    GetUnitMoveTypeData = function(id)
        local u=units[id]; return {name=u.scripted and 'script' or 'airplane',
            aircraftState=not u.scripted and u.state or nil}
    end,
    MoveCtrl = {
        GetTag = function(id) return units[id].scripted and 0 or nil end,
        Disable = function(id) units[id].scripted=false end,
    },
    SetUnitCrashing = function(id)
        local u=units[id]
        if u.state=='landed' then return false end
        u.state='crashing'; return true
    end,
    SetUnitCOBValue = function(id, key, value)
        assert(key==COB.CRASHING and value==1); units[id].state='crashing'
    end,
    GetUnitSelfDTime = function(id) return units[id] and units[id].selfD end,
    GetUnitIsStunned = function(id) return units[id].stunned end,
    GiveOrderToUnit = function(id, cmd)
        assert(cmd==CMD.SELFD); assert(gadget:AllowCommand(id))
        units[id].selfD=0; gadget:UnitCommand(id,units[id].def,1,cmd)
    end,
    GetGameFrame = function() return frame end,
    SetUnitNoSelect = function(id,v) units[id].noSelect=v end,
    SetUnitNeutral = function(id,v) units[id].neutral=v end,
    SetUnitCloak = function(id,v) units[id].cloak=v end,
    SetUnitSensorRadius = function(id,key,v) units[id].sensors[key]=v end,
    SetUnitWeaponState = function(id, weapon, state) units[id].weapons[weapon]=state end,
    SetUnitRulesParam = function(id,key,v) units[id].rules[key]=v end,
    GetUnitRulesParam = function(id,key) return units[id].rules[key] end,
    UnitScript = {
        GetScriptEnv = function(id) return {BeginAircraftCrash=function() units[id].hooks=units[id].hooks+1 end} end,
        CallAsUnit = function(id, fn) return fn() end,
    },
    GetAllUnits = function()
        local ids={};for id,u in pairs(units) do if not u.dead then ids[#ids+1]=id end end
        table.sort(ids);return ids
    end,
    ValidUnitID = function(id) return units[id]~=nil end,
    DestroyUnit = function(id, selfd, reclaimed, attacker)
        assert(selfd and not reclaimed, 'timeout must preserve explosion and wreck')
        units[id].dead=true; destroyed[id]={attacker=attacker}
        gadget:UnitDestroyed(id)
    end,
}
local function reload()
    if gadget then gadget:Shutdown() end
    gadget={};dofile('luarules/gadgets/unit_aircraft_crashing.lua');gadget:Initialize()
end
reload()
local function damage(id, amount, paralyze, attacker)
    return gadget:UnitPreDamaged(id,units[id].def,1,amount,paralyze or false,1,1,attacker)
end
-- Every current aircraft opts into the lethal hit path, including exact HP.
for def=1,covered do
    local id,u=unit(def)
    assert(damage(id,99)==99 and u.state=='flying', 'nonlethal hit starts crash')
    assert(damage(id,200,true)==200 and u.state=='flying', 'EMP starts crash')
    local d,impulse=damage(id,100)
    assert(d==100 and impulse==0 and u.state=='crashing', 'exact-health kill must crash')
    assert(u.noSelect and u.neutral and u.cloak==false and u.hooks==1)
    for _,sensor in ipairs({'los','airLos','radar','sonar'}) do assert(u.sensors[sensor]==0) end
    for weapon=1,#UnitDefs[def].weapons do
        local w=u.weapons[weapon]
        assert(w and w.range==0 and w.salvoLeft==0 and w.reloadState>frame+450)
    end
    assert(not gadget:AllowCommand(id) and not gadget:AllowUnitBuildStep(999,1,id))
    assert(damage(id,1000)==0 and damage(id,1000,true)==0 and u.hooks==1)
    -- Native impact destroys the unit and the gadget forgets it.
    u.dead=true;gadget:UnitDestroyed(id)
    assert(gadget:AllowCommand(id))
end
for _,opts in ipairs({{state='landed'},{y=0},{y=3},{build=.5},{transporter=999}}) do
    local id,u=unit(1,opts);assert(damage(id,500)==500 and not u.noSelect)
end
for _,def in ipairs({100,101,102}) do
    local id,u=unit(def);assert(damage(id,500)==500 and u.state=='flying')
end
local id,u=unit(103);assert(damage(id,500)==500 and u.state=='crashing', 'string custom params')
local launch,lu=unit(names.air_plane_artillery,{scripted=true,state='landed',y=600})
assert(damage(launch,200)==200 and not lu.scripted and lu.state=='crashing')
local api=Spring.SetUnitCrashing;Spring.SetUnitCrashing=nil
local legacy,le=unit(1);assert(damage(legacy,200)==200 and le.state=='crashing', 'COB fallback')
Spring.SetUnitCrashing=api
local water,wa=unit(1,{ground=-100,y=-10})
assert(damage(water,200)==200 and wa.state=='flying', 'already under water')
-- Expiry callbacks use the same transition; repeat calls must be harmless.
local expired,ex=unit(names.air_copter_scoutlett)
assert(GG.AircraftCrash(expired) and GG.AircraftCrash(expired) and ex.hooks==1)
-- Ctrl+D can be cancelled, retains the countdown, and respects stun.
local sd,su=unit(1,{selfD=4})
gadget:UnitCommand(sd,1,1,CMD.SELFD);gadget:GameFrame(frame)
assert(su.state=='flying');su.selfD=0;gadget:GameFrame(frame)
assert(su.state=='flying')
su.selfD=1;su.stunned=true;gadget:UnitCommand(sd,1,1,CMD.SELFD);gadget:GameFrame(frame)
assert(su.state=='flying');su.stunned=false;gadget:GameFrame(frame)
assert(su.state=='crashing' and su.selfD==0)
-- Reload must not extend a falling aircraft's cleanup deadline.
frame=150;reload();frame=535;gadget:GameFrame(frame)
assert(not ex.dead);frame=540;gadget:GameFrame(frame)
assert(ex.dead and su.dead and le.dead and lu.dead and u.dead)
-- Destruction of several expired aircraft synchronously mutates the table.
local attacker,att=unit(1)
local a=unit(1);local b=unit(1);damage(a,100,false,attacker);damage(b,100,false,attacker)
frame=990;gadget:GameFrame(frame)
assert(destroyed[a].attacker==attacker and destroyed[b].attacker==attacker)
local c=unit(1);damage(c,100,false,attacker);att.dead=true
frame=1440;gadget:GameFrame(frame);assert(destroyed[c].attacker==nil)
gadget:Shutdown();assert(GG.AircraftCrash==nil)

print('PASS: 17 real aircraft definitions; lethal/exact/EMP hits; weapon/sensor shutdown; ground/build/transport exclusions; launch and Spring fallback; expiry; self-D cancellation/stun; reload and bounded cleanup')
