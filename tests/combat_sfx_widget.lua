-- Reuse the real collector fixture, then exercise the actual widget callback
-- chain and diagnostics with only the unchanged renderers/config as spies.
dofile('tests/combat_sfx_collector.lua')
local baseInclude=VFS.Include
local callbacks,heat,drawn,logs={},0,{},{}
local zoom,frame=100,100
Spring.GetCameraPosition=function() return 0,zoom,0 end
Spring.GetGameFrame=function() return frame end
Spring.GetDrawFrame=function() frame=frame+1;return frame end
Spring.GetAllUnits=function() return {} end
Spring.GetVisibleProjectiles=function() return {} end
Spring.GetFrameTimeOffset=function() return 0 end
Spring.IsPosInLos=function() return true end
Spring.IsSphereInView=function() return true end
Spring.Echo=function(s) logs[#logs+1]=s end
for _,wd in pairs(WeaponDefs) do wd.damageAreaOfEffect=120;wd.visuals={} end
local noop=function() end
VFS.Include=function(path,...)
    if path=='scripts/lib_mosaic.lua' then return {
        getPoliceLightTypeTable=function() return {} end,getTankMuzzleTypeTable=function() return {} end,
        getRadianceDebugLampTypeTable=function() return {} end} end
    if path:find('radiance_time.lua',1,true) then return {AtFrame=function() return 1 end} end
    if path:find('railgun_wakes.lua',1,true) then return {New=function() return {
        Update=noop,Collect=function() return {} end,GetStats=function() return {} end,Clear=noop} end} end
    if path:find('_renderer.lua',1,true) or path:find('combat_tracers.lua',1,true) then
        return function() return {Capture=noop,Draw=function(_,records) drawn[#drawn+1]=records end,
            Shutdown=noop,GetStats=function() return {} end} end
    end
    return baseInclude(path,...)
end
widget={};WG={Lups={AddParticles=function() heat=heat+1 end}}
widgetHandler={RegisterGlobal=function(_,name,fn) callbacks[name]=fn end,
    DeregisterGlobal=function(_,name) callbacks[name]=nil end}
dofile('luaui/widgets_mosaic/gfx_light_effects.lua');widget:Initialize()
assert(WG.lighteffects and WG.CaptureCombatLightEmission)
callbacks.GadgetWeaponExplosion(0,10,0,2,10);assert(heat==1,'near mortar lost heat distortion')
zoom=12000
callbacks.GadgetWeaponExplosion(0,10,0,2,10);assert(heat==1,'Low heat bypassed orbit gate')
callbacks.GadgetWeaponExplosion(0,10,0,-101,10)
widget:DrawWorld()
assert(#drawn[1]==2,'sticky negative visual ID failed actual widget callback/render chain')
assert(widget:TextCommand('sfx status') and logs[#logs]:find('new High events=1',1,true))
local stats=WG.lighteffects.getSfxBudgetStats()
assert(stats.high==1 and stats.low==0 and stats.ribbons==2)
widget:Shutdown();assert(not next(callbacks) and not WG.lighteffects and not WG.CaptureCombatLightEmission)
print('PASS: actual widget callbacks, orbit heat suppression, High event rendering, status command, provider cleanup')
