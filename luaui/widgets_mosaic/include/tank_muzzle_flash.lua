-- A tank's short-lived forward flash and its light share one shot envelope.
-- Source membership and all visual dimensions live in lib_mosaic's config set.
local M = {}
function M.ActiveFrame(Spring, id, profile, frame)
    local born = Spring.GetUnitRulesParam(id, profile.shotParam)
    if type(born) ~= 'number' or born < 0 then return end
    local age = frame - born
    if age < 0 or age >= profile.durationFrames then return end
    return born, age
end

function M.Collect(Spring, id, record, frame)
    local p = record.profile
    local born, age = M.ActiveFrame(Spring, id, p, frame)
    if not born then return end
    if not record.pieces then
        local map = Spring.GetUnitPieceMap(id)
        if map and map[p.piece] and map[p.directionPiece] then
            record.pieces = {map[p.piece], map[p.directionPiece]}
        end
    end
    if not record.pieces then return end
    local x,y,z = Spring.GetUnitPiecePosDir(id, record.pieces[1])
    local bx,by,bz = Spring.GetUnitPiecePosDir(id, record.pieces[2])
    if not x or not bx then return end
    -- FireEmit is deliberately rotated for the legacy CEG. Its position is
    -- correct, but its local forward vector is not the cannon's firing axis.
    local dx,dy,dz = x-bx,y-by,z-bz
    local barrelLength = math.sqrt(dx*dx+dy*dy+dz*dz)
    if barrelLength < 0.001 then return end
    dx,dy,dz = dx/barrelLength,dy/barrelLength,dz/barrelLength
    local ux,uy,uz = Spring.GetUnitPosition(id)
    if Spring.GetUnitViewPosition then
        local vx,vy,vz = Spring.GetUnitViewPosition(id)
        if ux and vx then x,y,z = x+vx-ux,y+vy-uy,z+vz-uz end
    end
    x,y,z = x+dx*p.clearance,y+dy*p.clearance,z+dz*p.clearance
    local length = math.max(p.minLength, math.min(p.maxLength, barrelLength*p.lengthFactor))
    local width = length*p.widthFactor
    local fade = (1-age/p.durationFrames)^1.5
    -- Radiance peaks much faster than the lingering FlamePainter plume.  Keep
    -- the same shot lifetime so the ribbon can remain attached to the first
    -- source without allocating a separate renderer path.
    local lightFade = (1-age/p.durationFrames)^(p.lightFadePower or 1.5)
    local ribbon = {
        unitID=id, x=x,y=y,z=z, direction={dx,dy,dz},
        length=length,width=width,scale=1,
        speed=p.speed,curl=p.curl,seed=(id*37+born)%10000,strands=p.strands,
        colorStart=p.colorStart,colorEnd=p.colorEnd,emission=p.emission,
        sourceGlow=p.sourceGlow,opacity=fade,distanceFactor=p.distanceFactor,
        windInfluence=0.08,trailTime=0.05,
    }
    local offsets = p.lightOffsets or {0}
    local radiusFactors = p.lightRadiusFactors or {p.radiusFactor or 1}
    local strengthFactors = p.lightStrengthFactors or {1}
    local lightSources = {}
    for i,offsetFactor in ipairs(offsets) do
        local radiusFactor = radiusFactors[i] or radiusFactors[#radiusFactors] or p.radiusFactor or 1
        local strengthFactor = strengthFactors[i] or strengthFactors[#strengthFactors] or 1
        local offset = length*offsetFactor
        lightSources[i] = {
            x=x+dx*offset, y=y+dy*offset, z=z+dz*offset,
            radius=length*radiusFactor,
            strength=p.strength*strengthFactor*lightFade,
        }
    end
    local first = lightSources[1]
    return {x=x,y=y,z=z, radius=first.radius,color=p.color,
        strength=first.strength,direction={dx,dy,dz},lights=lightSources,ribbon=ribbon}
end
return M
