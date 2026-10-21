-- Run with Lua 5.1 from the repository root.
-- Exercise the real widget in the environment built by LuaUI/System, where
-- standard functions exist but _G does not. Standalone module tests missed it.
assert(setfenv and getfenv, 'this regression must run with Lua 5.1')
local frame, drawFrame = 100, 1
local shot = {[72] = 100, [73] = -1}
local messages, globals, draws = {}, {}, 0
local wakeVertices = 0
local hidden, missingPieces = {}, {}
local captureMode, captureDepth, captureDepthMask
local captureOwners = {}
local shaderFailure = false
Game = {gameSpeed=30, mapSizeX=4096, mapSizeZ=4096}
UnitDefs = {
    [1]={name='policetruck'},
    [2]={name='ground_tank_day'},
    [3]={name='ground_tank_night'},
}
WeaponDefs = {
    {name='tankcannon', type='Cannon', damageAreaOfEffect=80, visuals={}},
    {name='railgun', type='Cannon', damageAreaOfEffect=160, visuals={},customParams={railgun_wake=1}},
}
Spring = {
    Echo=function(s) messages[#messages+1]=s end,
    GetGameFrame=function() return frame end,
    GetDrawFrame=function() return drawFrame end,
    GetFrameTimeOffset=function() return 0 end,
    GetAllUnits=function() return {71,72,73} end,
    GetUnitDefID=function(id) return id-70 end,
    GetCameraPosition=function() return 200,150,200 end,
    GetSpectatingState=function() return false,false end,
    GetMyAllyTeamID=function() return 0 end,
    GetUnitLosState=function(id) return {los=not hidden[id]} end,
    IsPosInLos=function() return true end,
    ValidUnitID=function() return true end,
    GetUnitIsDead=function() return false end,
    GetUnitIsCloaked=function() return false end,
    GetUnitNoDraw=function() return false end,
    GetUnitTransporter=function() end,
    GetUnitRulesParam=function(id,key)
        if key=='mosaic_tank_muzzle_frame' then return shot[id] end
    end,
    GetUnitPieceMap=function(id)
        if missingPieces[id] then return {} end
        return {FireEmit=1,Cannon1=2,LightEmit01=3,LightEmit2=4}
    end,
    GetUnitPiecePosDir=function(_,piece)
        if piece==1 then return 194,30,100,0,1,0 end
        if piece==2 then return 100,30,100,0,1,0 end
        return 100,29,100,0,1,0
    end,
    GetUnitPosition=function() return 100,0,100 end,
    GetUnitVectors=function() return {0,0,1},{0,1,0},{1,0,0} end,
    GetUnitViewPosition=function() return 102,0,100 end,
    GetVisibleProjectiles=function() return {} end,
    GetGroundHeight=function() return 0 end,
    IsSphereInView=function() return true end,
    GetWind=function() return 0,0,0 end,
}
GL = {ONE=1, QUADS=7, TRIANGLE_STRIP=5, ALL_ATTRIB_BITS=1, ONE_MINUS_SRC_ALPHA=2, LESS=513}
local function noop() end
gl = {
    CreateShader=function() if not shaderFailure then return 1 end end,
    GetShaderLog=function() return 'deliberate unavailable renderer' end,
    GetUniformLocation=function(_,name) return name end,
    CreateList=function(fn) fn();return 1 end,
    CallList=function() draws=draws+1 end,
    BeginEnd=function(_,fn,...) fn(...) end,
    GetSun=function() return .3,.3,.3 end,
    Uniform=function(name,value) if name=='sourceOwner' then captureOwners[value]=true end end,
    UniformInt=function(name,value) if name=='sourceMetadata' then captureMode=value end end,
    DepthTest=function(value) captureDepth=value end,
    DepthMask=function(value) captureDepthMask=value end,
    Vertex=function(_,_,_,t) if t~=nil then wakeVertices=wakeVertices+1 end end,
    TexCoord=noop, MultiTexCoord=noop, DeleteList=noop, DeleteShader=noop,
    PushAttrib=noop, PopAttrib=noop, AlphaTest=noop,
    Culling=noop, Texture=noop, Blending=noop, UseShader=noop, Color=noop,
}
VFS = {
    Include=function(path,env)
        return setfenv(assert(loadfile(path)),env or getfenv(2))()
    end,
    LoadFile=function(path)
        local f=assert(io.open(path,'rb'));local data=f:read('*a');f:close();return data
    end,
}
dofile('luaui/system.lua')
local shared = {}
local function loadWidget()
    -- Same construction as widgetHandler:NewWidget, not a host _G fallback.
    local w={}
    for key,value in pairs(System) do w[key]=value end
    w.widget,w.WG=w,shared
    w.widgetHandler={
        RegisterGlobal=function(_,name,fn) globals[name]=fn end,
        DeregisterGlobal=function(_,name) globals[name]=nil end,
    }
    assert(w.pairs and not w._G, 'fixture must match the LuaUI global layout')
    setfenv(assert(loadfile('luaui/widgets_mosaic/gfx_light_effects.lua')),w)()
    w:Initialize()
    return w
end

local w=loadWidget()
assert(shared.lighteffects and shared.CaptureCombatLightEmission and shared.HasCombatLightEmission,
    'combat widget failed to publish its render providers')
assert(globals.GadgetWeaponBarrelfire and globals.GadgetWeaponExplosion and globals.GadgetCombatFire
    and globals.GadgetRailgunWakePoint and globals.GadgetRailgunWakeGap,
    'combat callbacks were lost during widget initialization')
assert(not w.getPoliceLightTypeTable and not w.getTankMuzzleTypeTable and not w.MOSAIC_CONFIG_ONLY,
    'config-only include leaked helpers or flags into the widget environment')
local status=shared.lighteffects.getStatus()
assert(status.flamePainter and status.radiance and status.tracers and status.railgunWake,
    'normal startup did not report linked renderers')
assert(status.tanks.tracked==2 and status.tanks.active==1 and status.tanks.queued==1,
    'central config membership did not reach the live source collector')
assert(status.tanks.latestShotFrame==100 and status.tanks.latestShotAge==0)
assert(shared.HasCombatLightEmission(0), 'daylight muzzle emission unavailable')
w:DrawWorld();assert(draws==1, 'active tank flash did not reach the real ribbon renderer')
shared.CaptureCombatLightEmission(0,256,1,0,true)
assert(captureMode==1 and captureOwners[72] and captureOwners[71] and captureDepth==GL.LESS and captureDepthMask,
    'mobile-shadow capture lost source height mode, tank ownership or depth ordering')
shared.CaptureCombatLightEmission(0,256,1,0,false)
assert(captureMode==0 and captureDepth==false and captureDepthMask==false,
    'ordinary light capture retained mobile-shadow metadata state')
assert(w:TextCommand('effects status'))
assert(messages[#messages-2]:find('FlamePainter=ready',1,true))
assert(messages[#messages]:find('railgun-wake=ready',1,true))
assert(not w:TextCommand('unrelated command'), 'effect status consumed an unrelated command')

-- Actual railgun callbacks reach both persistent world geometry and shared
-- radiance capture, with source-owner metadata confined to the muzzle.
globals.GadgetRailgunWakePoint(501,100,2,200,30,200,100,0)
frame,drawFrame=101,2
globals.GadgetRailgunWakePoint(501,100,2,280,32,200,101,1)
globals.GadgetWeaponBarrelfire(200,30,200,2,99)
captureOwners={}
shared.CaptureCombatLightEmission(0,256,1,0,true)
assert(captureOwners[99],'railgun muzzle source ownership was dropped by widget bridge')
w:DrawWorld()
assert(wakeVertices>0 and shared.lighteffects.getRailgunWakeStats().tracked==1,
    'observed railgun path did not reach its renderer')
assert(w:TextCommand('railgun status') and messages[#messages]:find('tracked=1',1,true),
    'railgun diagnostics did not report the live path')

frame,drawFrame=112,3
status=shared.lighteffects.getStatus()
assert(status.tanks.active==0 and status.tanks.queued==0,
    'expired flash persisted in validation status')
assert(status.tanks.latestShotFrame==100 and status.tanks.latestShotAge==12,
    'diagnostics cannot distinguish an expired flash from an absent firing event')
hidden[72]=true;drawFrame=4
status=shared.lighteffects.getStatus()
assert(status.tanks.visible==1 and status.tanks.latestShotFrame==nil,
    'diagnostics exposed a hidden tank firing stamp')
hidden[72]=nil
missingPieces[73]=true;shot[73]=112;drawFrame=5
status=shared.lighteffects.getStatus()
assert(status.tanks.active==1 and status.tanks.queued==0 and status.tanks.missingAnchors==1,
    'missing muzzle geometry was not reported')
w:Shutdown()
assert(not next(globals) and not shared.lighteffects and not shared.CaptureCombatLightEmission,
    'shutdown retained combat providers')

-- An unavailable shader is distinct from a removed/crashed widget. Reporting
-- unavailable must work, without advertising a functional radiance provider.
shaderFailure=true
w=loadWidget()
status=shared.lighteffects.getStatus()
assert(not status.flamePainter and not status.radiance and not status.tracers and not status.railgunWake)
assert(not shared.CaptureCombatLightEmission)
assert(w:TextCommand('effects status'))
assert(messages[#messages-2]:find('FlamePainter=unavailable',1,true))
assert(messages[#messages]:find('railgun-wake=unavailable',1,true))
w:Shutdown()
print('PASS: real LuaUI environment startup, isolated config, combat/railgun callbacks and draws, source metadata, expiry/LOS/anchor diagnostics, shutdown and unavailable renderer reporting')

