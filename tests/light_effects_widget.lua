-- End-to-end widget wiring: preserve heat distortion, own no light queues/API
-- for the removed deferred renderer, and release callbacks and GL resources.
unpack=unpack or table.unpack
local frame,drawFrame=0,0
local registered,shaders,lists,particles={},{},{},0
local nextObject=0
local function object(t) nextObject=nextObject+1;t[nextObject]=true;return nextObject end
widget={};WG={Lups={AddParticles=function(kind,p)
    assert(kind=='JitterParticles2' and p.life>0 and p.strength>0);particles=particles+1
end}}
WeaponDefs={{name='tankcannon',type='Cannon',damageAreaOfEffect=80,size=2,visuals={colorR=1,colorG=.6,colorB=.2},customParams={}}}
UnitDefs={};Game={gameSpeed=30,mapSizeX=512,mapSizeZ=512}
Spring={GetAllUnits=function() return {} end,GetVisibleProjectiles=function() return {} end,
    GetGameFrame=function() return frame end,GetDrawFrame=function() return drawFrame end,
    GetFrameTimeOffset=function() return .5 end,GetCameraPosition=function() return 0,100,0 end,
    GetSpectatingState=function() return false,false end,GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return true end,IsSphereInView=function() return true end,
    GetGroundHeight=function() return 0 end,GetWind=function() return 1,0,0 end,
    Echo=function(msg) error(msg) end}
GL={ONE=1,QUADS=7,TRIANGLE_STRIP=5,ALL_ATTRIB_BITS=1,ONE_MINUS_SRC_ALPHA=2}
gl=setmetatable({CreateShader=function() return object(shaders) end,
    DeleteShader=function(id) assert(shaders[id]);shaders[id]=nil end,
    CreateList=function(fn) fn();return object(lists) end,
    DeleteList=function(id) assert(lists[id]);lists[id]=nil end,
    CreateTexture=function() error('combat effects allocated a texture') end,
    CreateFBO=function() error('combat effects allocated a framebuffer') end,
    GetUniformLocation=function(_,name) return name end,
    BeginEnd=function(_,fn,...) fn(...) end,GetSun=function() return .3,.3,.3 end,
}, {__index=function() return function() end end})
VFS={Include=function(p) return dofile(p) end,LoadFile=function(p)
    local f=assert(io.open(p));local s=f:read('*a');f:close();return s
end}
widgetHandler={RegisterGlobal=function(_,name,fn) assert(not registered[name]);registered[name]=fn end,
    DeregisterGlobal=function(_,name) registered[name]=nil end}
local function start()
    widget={};dofile('luaui/widgets_mosaic/gfx_light_effects.lua');widget:Initialize()
    assert(WG.CaptureCombatLightEmission and WG.lighteffects)
    assert(not registered.GadgetCreateLight and not registered.GadgetCreateBeamLight,'dead queue API survived')
end
start()
assert(not WG.HasCombatLightEmission(1),'idle effects keep the direct capture active')
registered.GadgetWeaponExplosion(0,5,0,1)
assert(particles==1,'working explosion heat distortion was removed')
assert(not WG.HasCombatLightEmission(0) and WG.HasCombatLightEmission(1),'night-only weapon light activity')
registered.GadgetCombatFire(1,30,1,30,frame,frame+450)
assert(WG.HasCombatLightEmission(0),'daylight fire did not activate the shared field')
widget:DrawWorld();WG.CaptureCombatLightEmission(0,128,1,0)
WG.lighteffects.setGlobalBrightness(1.5);WG.lighteffects.setGlobalRadius(1.4)
WG.lighteffects.setLife(.8);WG.lighteffects.setHeatDistortion(false)
registered.GadgetWeaponExplosion(0,5,0,1);assert(particles==1)
local saved=widget:GetConfigData()
assert(saved.globalLightMult==1.5 and saved.globalRadiusMult==1.4 and saved.globalLifeMult==.8)
frame=500;drawFrame=1;widget:Update(.1);widget:DrawWorld()
assert(not WG.HasCombatLightEmission(1),'expired sources keep capture active')
widget:Shutdown()
assert(not next(registered) and not next(shaders) and not next(lists))
assert(not WG.CaptureCombatLightEmission and not WG.HasCombatLightEmission and not WG.lighteffects)
start();widget:SetConfigData(saved);assert(WG.lighteffects.getGlobalBrightness()==1.5)
widget:Shutdown()
assert(not next(registered) and not next(shaders) and not next(lists))
print('PASS: widget registration, heat distortion, live fire capture, settings, expiry, no light textures/FBOs, reload and full cleanup')
