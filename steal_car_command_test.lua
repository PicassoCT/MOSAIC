-- Regression: stealing is once again an ordinary constructed icon, never a custom order.
local function eq(a,b,message) assert(a==b,message or (tostring(a)..' ~= '..tostring(b))) end
local started, destroyed, requests = {}, {}, {}
local env={unitID=99,teamID=1,fatherID=1,script={},GG={CivilianVehicles={RequestHijack=function(id,icon,range)
        requests[#requests+1]={id,icon,range};return true
    end}},UnitDefs={},
    include=function() end,piece=function(name) return name end,
    getGameConfig=function() return {espionage={recruitment={range=60}}} end,
    getTruckTypeTable=function() return {[2]=true} end,
    getPieceTableByNameGroups=function() return {} end,hideT=function() end,
    StartThread=function(fn,...) started[#started+1]={fn,...} end,
    Sleep=coroutine.yield,lifeTime=function() end,
    waitTillComplete=function(id) eq(id,99);coroutine.yield('construction') end,
    getAllNearUnit=function(id,range) eq(id,99);eq(range,60);return {11,12,10} end,
    foreach=function(list,filter,action) for _,id in ipairs(list) do local v=filter(id);if v then action(v) end end end,
    doesUnitExistAlive=function() return true end,
    copyUnit=function() error('Theft must never recreate the vehicle') end,
}
env.Spring={GetGaiaTeamID=function() return 0 end,
    GetUnitTeam=function(id) return (id==10 or id==12) and 0 or 1 end,
    GetUnitDefID=function(id) return id==12 and 3 or 2 end,
    GetUnitPosition=function() return 100,0,200 end,
    DestroyUnit=function(id) destroyed[id]=true end,

}
setmetatable(env,{__index=_G})
local chunk=assert(loadfile('scripts/stealVehicleScript.lua'))
if setfenv then setfenv(chunk,env) else chunk=assert(loadfile('scripts/stealVehicleScript.lua','t',env)) end
chunk();env.script.Create()
eq(#started,2);eq(started[1][1],env.animationLoop);eq(started[2][1],env.stealVehicle)
local thread=coroutine.create(env.stealVehicle)
local ok,delay=coroutine.resume(thread);assert(ok,delay);eq(delay,'construction');eq(#requests,0)
ok,delay=coroutine.resume(thread);assert(ok,delay);eq(delay,100)
eq(started[3][1],env.lifeTime);eq(started[3][2],99);eq(started[3][3],15000)
ok,delay=coroutine.resume(thread);assert(ok,delay);eq(delay,100)
eq(#requests,1);eq(requests[1][1],10);eq(requests[1][2],99);eq(requests[1][3],60)
assert(not next(destroyed),'Icon and vehicle stay alive until deferred ownership transfer')
assert(not io.open('luarules/gadgets/game_steal_car.lua','r'),'custom command gadget must stay removed')
for _,path in ipairs({'units/antagon/OperativePropagator.lua','units/protagon/operativeInvestigator.lua','units/shared/human/OperativeAsset.lua'}) do
 local f=assert(io.open(path));local source=f:read('*a');f:close();assert(source:find('"stealvehicleicon"',1,true),path..' must retain the icon build option')
end
print('PASS: build-icon animation, construction gate, deferred civilian capture without cloning, and 15-second lifetime; no custom command')
