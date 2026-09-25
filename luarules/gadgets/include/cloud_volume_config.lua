-- Shared, data-only presets. Bounds are in piece-local coordinates; explosions in elmos.
local M = {}
M.presets = {
    steam = {shape=0, density=3, speed=.25, emission=0, color={.72,.75,.78}, hot={1,.7,.25}},
    soot = {shape=0, density=3.4, speed=.3, emission=0, color={.22,.21,.2}, hot={1,.7,.25}},
    fire = {shape=0, density=4, speed=.7, emission=5.5, glow=1.2, color={.18,.15,.13}, hot={1,.55,.12}},
    plume = {shape=1, density=3.2, speed=1.4, emission=3, color={.25,.22,.2}, hot={1,.72,.32}},
    ring = {shape=2, density=2.8, speed=.35, emission=.4, color={.62,.58,.52}, hot={1,.4,.08}},
    impact = {shape=3, density=5, speed=.3, emission=3.5, color={.24,.21,.18}, hot={1,.5,.1}, duration=16, radius=460, height=700},
    nuclear = {shape=3, density=5, speed=.25, emission=4, color={.27,.26,.25}, hot={1,.72,.3}, duration=32, radius=850, height=1500},
    bio = {shape=0, density=2, speed=.2, emission=.15, color={.48,.55,.27}, hot={.7,.8,.35}, duration=12, radius=100, height=100},
    electric = {shape=0, density=1.8, speed=2, emission=3, color={.25,.35,.6}, hot={.55,.8,1}, duration=1.5, radius=70, height=110},
}
-- Curve keys are {seconds since Show/Burst, multiplier}. Smooth interpolation,
-- clamped endpoints: a final nonzero value holds for continuously fed emitters.
function M.Curve(keys, seconds, fallback)
    if not keys or #keys==0 then return fallback end
    if seconds<=keys[1][1] then return keys[1][2] end
    for i=2,#keys do
        local a,b=keys[i-1],keys[i]
        if seconds<b[1] then
            local t=(seconds-a[1])/(b[1]-a[1]);t=t*t*(3-2*t)
            return a[2]+(b[2]-a[2])*t
        end
    end
    return keys[#keys][2]
end
function M.Appearance(p,age)
    return M.Curve(p.opacityCurve,age,1), M.Curve(p.densityCurve,age,1),
        M.Curve(p.emissionCurve,age,1), M.Curve(p.expansionCurve,age,1)
end
local function variant(base,values)
    local p={};for k,v in pairs(M.presets[base]) do p[k]=v end
    for k,v in pairs(values) do p[k]=v end
    return p
end
M.presets.steam.opacityCurve={{0,0},{1,.65},{12,.6},{30,.25},{45,0}}
M.presets.steam.densityCurve={{0,.7},{8,1},{45,.15}}
M.presets.steam.expansionCurve={{0,.8},{12,1},{45,1.25}}
M.presets.steam.lifetime=45
M.presets.steam.linger=true
M.presets.soot.opacityCurve={{0,0},{.7,.7},{8,.65},{18,.35},{28,0}}
M.presets.soot.densityCurve={{0,.8},{4,1},{28,.2}}
M.presets.soot.expansionCurve={{0,.85},{12,1},{28,1.2}}
M.presets.soot.lifetime=28
M.presets.soot.linger=true
M.presets.fire.opacityCurve={{0,0},{.12,.8}}
M.presets.plume.opacityCurve={{0,0},{.08,.85}}
M.presets.ring.opacityCurve={{0,0},{.6,.65},{8,.5},{24,0}}
M.presets.ring.emissionCurve={{0,1},{1,.4},{3,0}}
M.presets.ring.lifetime=24
M.presets.gasExplosion=variant('fire',{
    emission=7, glow=1.6,
    lifetime=4, opacityCurve={{0,0},{.12,.9},{.7,.8},{2,.45},{4,0}},
    emissionCurve={{0,.8},{.2,1.3},{.8,1},{1.8,.55},{3,0}},
    densityCurve={{0,1},{1,.8},{4,.15}},
    expansionCurve={{0,.65},{.6,1},{4,1.2}},
})
M.presets.flameTongue=variant('plume',{
    emission=6, glow=1.4, hot={1,.58,.12},
    opacityCurve={{0,0},{.06,.9},{.5,.85}},
    emissionCurve={{0,.8},{.1,1},{.6,.9}},
})
-- The original pump smoke texture contains emissive patches. Preserve their
-- visual role as embedded fire which cools before the long-lived soot clears.
M.presets.risingSmoke=variant('soot',{
    emission=3.8, glow=.22, hot={1,.32,.045},
    emissionCurve={{0,1},{2.5,.9},{7,.35},{12,0}},
    -- Pump smoke only. Explosions/flames keep their own expansion and motion.
    windDeform=.38,
})
-- Launch-pad vapour must obscure the structure, not tint it through a fog veil.
-- Opacity multiplies the integrated volume, so density alone cannot overcome
-- the ordinary steam preset's .65 alpha ceiling. Keep this tuning spaceport-only.
M.presets.launchVapour=variant('steam',{
    density=8.5, color={.78,.80,.82}, lifetime=70,
    opacityCurve={{0,0},{.6,.97},{1.2,.995},{18,.995},{28,.96},{42,.72},{58,.22},{70,0}},
    densityCurve={{0,.85},{2,1},{28,1},{50,.65},{70,.15}},
    expansionCurve={{0,1},{2,1.3},{14,1.5},{35,1.65},{70,1.8}},
})
M.presets.launchGas=variant('gasExplosion',{
    density=8,
    opacityCurve={{0,0},{.12,.995},{.7,.995},{2,.9},{3,.55},{4,0}},
})
M.presets.launchRing=variant('ring',{
    density=8, lifetime=32,
    opacityCurve={{0,0},{.4,.99},{8,.985},{16,.8},{32,0}},
    densityCurve={{0,.85},{1,1},{16,.8},{32,.2}},
    expansionCurve={{0,1},{4,1.15},{16,1.3},{32,1.4}},
})
for _,name in ipairs({'impact','nuclear','bio','electric'}) do
    local p=M.presets[name];local t=p.duration
    p.opacityCurve={{0,0},{math.min(.12,t*.08),1},{t*.5,.85},{t,0}}
    p.densityCurve={{0,1},{t*.3,1},{t,.2}}
    p.emissionCurve={{0,1},{t*.04,1},{t*.22,0}}
    p.expansionCurve={{0,.15},{t*.06,.65},{t*.3,1},{t,1.1}}
end
-- Keep the established aerosol identification colours saturated, including at
-- night. Glow lights the whole gas body; it is independent of combustion heat.
M.aerosolColors={
    depressol={.18,.32,1}, tollwutox={1,.07,.035},
    orgyanyl={1,.42,.025}, wanderlost={.12,1,.2},
}
for kind,color in pairs(M.aerosolColors) do
    M.presets['aerosol_'..kind]={
        shape=0, density=1.8, speed=.3, emission=0, glow=2.2,
        color=color, hot=color, duration=6, radius=150, height=120,
        centerOffset=0, -- Burst position is the cloud centre, not an explosion base.
        opacityCurve={{0,0},{.25,.6},{1.8,.55},{4,.25},{6,0}},
        densityCurve={{0,.8},{1,1},{6,.3}},
        emissionCurve={{0,1},{2.5,1},{6,.45}},
        expansionCurve={{0,.35},{1,.7},{3,1},{6,1.15}},
    }
end
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<1e9 end
M.finite=finite
function M.Preset(name) return M.presets[name] end
function M.Bounds(id,piece)
    local info=Spring.GetUnitPieceInfo(id,piece)
    if not info then return nil,'piece info unavailable' end
    if info.isEmpty then return nil,'engine reports empty geometry' end
    if not info.min or not info.max then return nil,'piece bounds unavailable' end
    local center,half={},{}
    for i=1,3 do
        local a,b=info.min[i],info.max[i]
        if not finite(a) or not finite(b) or b<a then
            return nil,'invalid bounds on axis '..i..': '..tostring(a)..' / '..tostring(b)
        end
        center[i]=(a+b)*.5; half[i]=math.max((b-a)*.5, .1)
    end
    -- Enlarge the proxy to leave room for noise-eroded silhouettes.
    local largest=math.max(unpack(half))
    for i=1,3 do half[i]=math.max(half[i],largest*.12)*1.2 end
    return center,half
end
function M.SpaceportPreset(name)
    if name:match('^RocketPlumeB%d*$') then return 'launchVapour' end
    if name:match('^RocketPlumeA?%d*$') or name=='RocketFusionPlume'
        or name:match('^RocketThrustPillar%d*$') or name:match('^ReturningBooster%d+ThrusterPlum%d*$')
        or name:match('^LandCone%d*$') or name=='LaunchCone' then return 'plume' end
    if name=='GroundGases' or name:match('^FireFlower%d+$') then return 'launchGas' end
    if name:match('^GroundHeatedGasRing%d+$') then return 'launchRing' end
    if name:match('^CrawlerBoosterGasRing%d+$')
        or name:match('^CrawlerBoosterRing%d+$') or name:match('^CrawlerSmokeRing%d+$') then return 'ring' end
    if name=='ArenaSmoke' or name:match('^SmokeBubble%d+$') then return 'launchVapour' end
end
function M.PumpPreset(name)
    if name:match('^Smoke%d+$') or name=='SmokeStem' then return 'risingSmoke' end
    if name:match('^Explosion%d+$') or name=='ExplosionStem' then return 'gasExplosion' end
    if name:match('^FireRotor%d*$') or name=='Igniter' then return 'fire' end
    if name:match('^Flame[ABC]?%d+$') or name:match('^Flames%d+$') then return 'flameTongue' end
end
M.PiecePresets={spaceport=M.SpaceportPreset,pump=M.PumpPreset}
return M
