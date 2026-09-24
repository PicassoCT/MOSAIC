-- Shared, data-only presets. Bounds are in piece-local coordinates; explosions in elmos.
local M = {}
M.presets = {
    steam = {shape=0, density=3, speed=.25, emission=0, color={.72,.75,.78}, hot={1,.7,.25}},
    soot = {shape=0, density=3.4, speed=.3, emission=0, color={.22,.21,.2}, hot={1,.7,.25}},
    fire = {shape=0, density=4, speed=.7, emission=2.5, color={.18,.15,.13}, hot={1,.55,.12}},
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
    lifetime=4, opacityCurve={{0,0},{.12,.9},{.7,.8},{2,.45},{4,0}},
    emissionCurve={{0,1},{.2,1.4},{.8,.3},{1.8,0}},
    densityCurve={{0,1},{1,.8},{4,.15}},
    expansionCurve={{0,.65},{.6,1},{4,1.2}},
})
M.presets.flameTongue=variant('plume',{
    opacityCurve={{0,0},{.06,.8},{.5,.7}},
    emissionCurve={{0,.7},{.1,1},{.6,.8}},
})
for _,name in ipairs({'impact','nuclear','bio','electric'}) do
    local p=M.presets[name];local t=p.duration
    p.opacityCurve={{0,0},{math.min(.12,t*.08),1},{t*.5,.85},{t,0}}
    p.densityCurve={{0,1},{t*.3,1},{t,.2}}
    p.emissionCurve={{0,1},{t*.04,1},{t*.22,0}}
    p.expansionCurve={{0,.15},{t*.06,.65},{t*.3,1},{t,1.1}}
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
    if name:match('^RocketPlumeB%d*$') then return 'steam' end
    if name:match('^RocketPlumeA?%d*$') or name=='RocketFusionPlume'
        or name:match('^RocketThrustPillar%d*$') or name:match('^ReturningBooster%d+ThrusterPlum%d*$')
        or name:match('^LandCone%d*$') or name=='LaunchCone' then return 'plume' end
    if name=='GroundGases' or name:match('^FireFlower%d+$') then return 'gasExplosion' end
    if name:match('^GroundHeatedGasRing%d+$') or name:match('^CrawlerBoosterGasRing%d+$')
        or name:match('^CrawlerBoosterRing%d+$') or name:match('^CrawlerSmokeRing%d+$') then return 'ring' end
    if name=='ArenaSmoke' or name:match('^SmokeBubble%d+$') then return 'steam' end
end
function M.PumpPreset(name)
    if name:match('^Smoke%d+$') or name=='SmokeStem' then return 'soot' end
    if name:match('^Explosion%d+$') or name=='ExplosionStem' then return 'gasExplosion' end
    if name:match('^FireRotor%d*$') or name=='Igniter' then return 'fire' end
    if name:match('^Flame[ABC]?%d+$') or name:match('^Flames%d+$') then return 'flameTongue' end
end
M.PiecePresets={spaceport=M.SpaceportPreset,pump=M.PumpPreset}
return M
