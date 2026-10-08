-- Run from the repository root:
-- texlua tests/cinder_flame_stream_test.lua
-- Engine-independent tests for Cinder's persistent visuals and no per-shot VFX.
unpack=unpack or table.unpack
local frame,drawFrame,los,alive,untilFrame=200,0,true,true,0
local icon=false
local originX,originY,originZ=50,20,60
Game={gameSpeed=30}
WeaponDefs={
    {name='walkerflamethrower',type='Flame',damageAreaOfEffect=22,
        customParams={no_projectile_vfx='1'},visuals={}},
    {name='molotow',type='Cannon',damageAreaOfEffect=50,visuals={}},
}
UnitDefs={[11]={name='ground_walker_flame'},[12]={name='vehiclecorpse'},
    [13]={name='policetruck'}}
Spring={
    GetGameFrame=function() return frame end,
    GetDrawFrame=function() return drawFrame end,
    GetFrameTimeOffset=function() return .25 end,
    GetSpectatingState=function() return false,false end,
    GetMyAllyTeamID=function() return 0 end,
    IsPosInLos=function() return los end,
    GetUnitLosState=function() return {los=los} end,
    ValidUnitID=function() return alive end,
    GetUnitIsDead=function() return not alive end,
    GetUnitIsCloaked=function() return false end,
    IsUnitIcon=function() return icon end,
    GetUnitNoDraw=function() return false end,
    GetUnitTransporter=function() end,
    GetUnitPosition=function() return originX,0,originZ end,
    GetUnitViewPosition=function() return originX,0,originZ end,
    GetUnitPieceMap=function() return {emitfire=4} end,
    GetUnitPiecePosDir=function() return originX,originY,originZ,1,0,0 end,
    GetUnitWeaponVectors=function() return originX,originY,originZ,1,0,0 end,
    GetUnitVectors=function() return {1,0,0},{0,1,0},{0,0,1} end,
    GetUnitRulesParam=function(id,key)
        if id==21 and key=='mosaic_pyro_fire_until' then return untilFrame end
    end,
    GetCameraPosition=function() return 0,30,0 end,
    GetGroundHeight=function() return 0 end,
    GetVisibleProjectiles=function() return {301} end,
    GetProjectileDefID=function() return 1 end,
    GetProjectilePosition=function() return 80,18,60 end,
    GetProjectileVelocity=function() return 3,0,0 end,
}
local M=dofile('luaui/widgets_mosaic/include/combat_light_sources.lua')
assert(M.Weapon(WeaponDefs[1])==nil,'damage-only flame still produces pellet VFX')
assert(M.Weapon(WeaponDefs[2]).fire,'ordinary Molotov trail should be unchanged')
local fx=M.New({})
fx:UnitCreated(21,11)
local function collect()
    drawFrame=drawFrame+1
    return fx:Collect()
end
fx:Update(.1)
local lights,flames=collect()
assert(#lights==0 and #flames==0,'idle Cinder emitted flame or shot lights')
untilFrame=frame+12
lights,flames=collect()
assert(#lights==2,'Cinder must submit two bounded radiance sources, not per-shot lights')
assert(#flames>=5 and #flames<=7,'Cinder should have one main stream and 4-6 smaller deflections')
assert(flames[1].length==175 and flames[1].direction[1]>.9
    and flames[1].strands==4,'main FlamePainter stream not attached to nozzle/aim/range')
assert(flames[1].terrainGuard and flames[1].terrainGuard[4]>=9,
    'full-length Cinder stream is missing its ground-clearance guard')
for _,light in ipairs(lights) do
    assert(light.radius<=62 and light.strength<=0.46,
        'Cinder attack is flooding the ground with excessively broad radiance')
end
local firstFlameCount=#flames
frame=frame+3;untilFrame=frame+12
lights,flames=collect()
assert(#lights==2 and #flames==firstFlameCount,
    'each damage pulse creates an additional effect rather than refreshing one jet')
los=false
lights,flames=collect()
assert(#lights==0 and #flames==0,'Cinder flame leaked across LOS')
los=true
lights,flames=collect()
assert(#lights==2 and #flames>=5,'Cinder flame failed to resume on LOS reentry')
icon=true
lights,flames=collect()
assert(#lights==0 and #flames==0,'distant Cinder icon still submitted its full flame')
icon=false
frame=untilFrame+1;fx:Update(.1)
lights,flames=collect()
assert(#lights==0 and #flames==0,'firing stream did not expire after 12 frames')
frame=frame+1;untilFrame=frame+12
fx:UnitDestroyed(21)
lights,flames=collect()
assert(#lights==0 and #flames==0,'dead walker continued to fire')
fx:AddPyroTorch(50,0,60,21)
lights,flames=collect()
assert(#lights==5 and #flames==5,'death torch should remain independent of weapon visuals')
frame=frame+43;fx:Update(.1)
lights,flames=collect()
assert(#lights==0 and #flames==0,'death torch did not expire')
-- Master already has red/blue police lightbars; the merge must preserve them.
fx:UnitCreated(31,13)
lights,flames=collect()
assert(#lights==1 and lights[1].color[1]==1,'master police lightbar was lost')
frame=frame+5
lights,flames=collect()
assert(#lights==1 and lights[1].color[3]==1,'police lightbar no longer alternates blue')

local weaponSource=assert(io.open('weapons/walker_incendiary.lua','rb')):read('*a')
assert(weaponSource:find('flameGfxTime = 1.0',1,true) and
    weaponSource:find('size = 0.01',1,true),
    'flame projectiles must retain their range while having sub-pixel visuals')
local gadgetSource=assert(io.open('luarules/gadgets/gfx_explosion_lights.lua','rb')):read('*a')
assert(gadgetSource:find('tonumber%(cp.no_projectile_vfx%)~=1'),
    'per-shot synced events are not suppressed for Cinder')
local widgetSource=assert(io.open('luaui/widgets_mosaic/gfx_light_effects.lua','rb')):read('*a')
assert(widgetSource:find('tonumber%(customParams.no_projectile_vfx%)~=1'),
    'per-shot LUPS/radiance flashes are not suppressed for Cinder')
local holoSource=assert(io.open('luarules/gadgets/gfx_neonHolograms.lua','rb')):read('*a')
assert(not holoSource:find('SetUniformFloatArray%("viewPortSize"'),
    'Neon hologram is still setting an optimized-out viewport uniform')
assert(not holoSource:find('SetUniformFloat%("rainPercent"'),
    'Neon hologram is still setting an optimized-out rain uniform')
local vertexSource=assert(io.open('luarules/gadgets/shaders/smokeRibbon.vert','rb')):read('*a')
assert(vertexSource:find('terrainGuard',1,true) and vertexSource:find('p.y = max(p.y, terrain + terrainGuard.w)',1,true),
    'FlamePainter must keep strip vertices above terrain after turbulent offsets')
print('PASS: Cinder damage-only pellets, range, terrain guard, nozzle flame, deflections, bounded lighting, LOS, expiry, death torch, police lights, hologram uniforms')
