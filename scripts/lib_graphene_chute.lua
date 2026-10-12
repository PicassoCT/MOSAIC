-- Four fibrous FlamePainter sheets replace the parachute's polygon web.
-- The stable step/support owns both the sheets and their electrical rim pins.
local GrapheneArc = VFS.Include('scripts/lib_graphene_arc.lua')
local M = {}
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
local function cross(a,b)
    return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}
end

function M.Layout(unitID, support)
    local info = Spring.GetUnitPieceInfo(unitID, support)
    local matrix = Spring.GetUnitPieceMatrix and {Spring.GetUnitPieceMatrix(unitID, support)} or {}
    if not info or not info.min or not info.max or not matrix[16] then return end
    local front, up, right = Spring.GetUnitVectors(unitID)
    local ux, uy, uz = Spring.GetUnitPosition(unitID)
    local ex, ey, ez = Spring.GetUnitPiecePosDir(unitID, support)
    if not front or not up or not right or not ux or not ex then return end
    local function transform(x,y,z)
        return {-right[1]*x+up[1]*y+front[1]*z,
            -right[2]*x+up[2]*y+front[2]*z,-right[3]*x+up[3]*y+front[3]*z}
    end
    local basis = {transform(matrix[1],matrix[2],matrix[3]),
        transform(matrix[5],matrix[6],matrix[7]),transform(matrix[9],matrix[10],matrix[11])}
    local cofactors = {cross(basis[2],basis[3]),cross(basis[3],basis[1]),cross(basis[1],basis[2])}
    local determinant = dot(basis[1],cofactors[1])
    if math.abs(determinant) < 1e-12 then return end
    local pivot = transform(matrix[13],matrix[14],matrix[15])
    local emitted = {ex-ux-pivot[1],ey-uy-pivot[2],ez-uz-pivot[3]}
    local emitterLocal = {}
    for axis=1,3 do emitterLocal[axis]=dot(emitted,cofactors[axis])/determinant end
    local scale, span = {}, 0
    for axis = 1, 3 do
        local i = 1 + (axis - 1) * 4
        scale[axis] = math.sqrt(matrix[i]^2 + matrix[i+1]^2 + matrix[i+2]^2)
        if scale[axis] <= 1e-6 then return end
        span = math.max(span, (info.max[axis] - info.min[axis]) * scale[axis])
    end
    if span <= 1e-6 then return end

    -- air_parachut.dae's step has local +Z upward and X/Y across its top.
    -- Imported matrix scale converts its bounds to world-sized sheet lengths;
    -- offsets stay piece-local because the renderer applies that matrix once.
    local radius = span * 6
    local layout = {radius=radius, span=span, roots={}, directions={}}
    local cx, cy = (info.min[1]+info.max[1])*0.5, (info.min[2]+info.max[2])*0.5
    for i = 1, 4 do
        local angle = math.pi * (0.25 + (i-1)*0.5)
        local x, y = math.cos(angle), math.sin(angle)
        -- GetUnitPiecePosDir emits from mesh vertex zero, not necessarily the
        -- pivot. Undo that offset before adding our intended local rim point.
        layout.roots[i] = {cx+x*radius/scale[1]-emitterLocal[1],
            cy+y*radius/scale[2]-emitterLocal[2], info.max[3]-emitterLocal[3]}
        -- Broad edges surround the suspension point; tapered ends rise inward
        -- into a shallow canopy. Hair mode preserves their material length.
        layout.directions[i] = {-x/scale[1], -y/scale[2], 0.45/scale[3]}
    end
    return layout
end

function M.RibbonOptions(layout, index)
    return {
        mode='hair', rootOffset=layout.roots[index],
        directionSpace='piece', direction=layout.directions[index],
        length=layout.radius*1.16, width=layout.radius*0.42, strands=1,
        stiffness=0.72, gravity=0.3, curl=0.3, speed=1,
        windAffected=true, windInfluence=1.2, motionAffected=true,
        motionInfluence=0.5, trailTime=0.3,
        colorStart={0,0,0,1}, colorEnd={0,0,0,1},
        emission={0,0}, sourceGlow={0,0,0,0},
        distanceFactor=40, drawInIcon=true, seed=index*19,
    }
end

function M.ArcOptions(layout, index)
    local options = GrapheneArc.Options(index*19, layout.roots[index])
    -- Keep the existing cyan/violet discharge, sized to the new canopy rather
    -- than to the enormous hidden Rotator sheets.
    options.length = layout.radius*1.5
    options.width = layout.radius*0.14
    return options
end

return M
