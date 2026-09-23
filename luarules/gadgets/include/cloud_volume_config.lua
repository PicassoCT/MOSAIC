-- Shared, data-only presets. Bounds are in piece-local coordinates; explosions in elmos.
local M = {}
M.presets = {
    steam = {shape=0, density=3, speed=.25, emission=0, color={.72,.75,.78}, hot={1,.7,.25}},
    fire = {shape=0, density=4, speed=.7, emission=2.5, color={.18,.15,.13}, hot={1,.55,.12}},
    plume = {shape=1, density=3.2, speed=1.4, emission=3, color={.25,.22,.2}, hot={1,.72,.32}},
    ring = {shape=2, density=2.8, speed=.35, emission=.4, color={.62,.58,.52}, hot={1,.4,.08}},
    impact = {shape=3, density=5, speed=.3, emission=3.5, color={.24,.21,.18}, hot={1,.5,.1}, duration=16, radius=460, height=700},
    nuclear = {shape=3, density=5, speed=.25, emission=4, color={.27,.26,.25}, hot={1,.72,.3}, duration=32, radius=850, height=1500},
    bio = {shape=0, density=2, speed=.2, emission=.15, color={.48,.55,.27}, hot={.7,.8,.35}, duration=12, radius=100, height=100},
    electric = {shape=0, density=1.8, speed=2, emission=3, color={.25,.35,.6}, hot={.55,.8,1}, duration=1.5, radius=70, height=110},
}
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<1e9 end
M.finite=finite
function M.Preset(name) return M.presets[name] end
function M.Bounds(id,piece)
    local info=Spring.GetUnitPieceInfo(id,piece)
    if not info or info.isEmpty or not info.min or not info.max then return end
    local center,half={},{}
    for i=1,3 do
        local a,b=info.min[i],info.max[i]
        if not finite(a) or not finite(b) or b<a then return end
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
    if name=='GroundGases' or name:match('^FireFlower%d+$') then return 'fire' end
    if name:match('^GroundHeatedGasRing%d+$') or name:match('^CrawlerBoosterGasRing%d+$')
        or name:match('^CrawlerBoosterRing%d+$') or name:match('^CrawlerSmokeRing%d+$') then return 'ring' end
    if name=='ArenaSmoke' or name:match('^SmokeBubble%d+$') then return 'steam' end
end
return M
