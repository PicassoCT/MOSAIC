-- Diffuse graphene veils rise from the harness into a broad, rolling crown.
-- Electrical branches share the same material paths, so charge remains attached.
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
    local radius = span * 12
    local layout = {radius=radius, span=span, roots={}, directions={}, arcRoots={},
        arcIndices={1,3,6,8}}
    local cx, cy = (info.min[1]+info.max[1])*0.5, (info.min[2]+info.max[2])*0.5
    for i = 1, 8 do
        -- Uneven spacing and root reach break the old radial-disc symmetry.
        -- These seeds describe the material, not fresh random choices per frame.
        local angle = math.pi * (0.25 + (i-1)*0.25) + 0.16*math.sin(i*2.1)
        local x, y = math.cos(angle), math.sin(angle)
        -- Keep the roots within the support's scale. A wider source ring left
        -- an empty centre when the diffuse canopy was viewed from overhead.
        local rootRadius = radius*(0.03+0.01*math.sin(i*2.3))
        -- GetUnitPiecePosDir emits from mesh vertex zero, not necessarily the
        -- pivot. Undo that offset before clustering the roots over the harness.
        layout.roots[i] = {cx+x*rootRadius/scale[1]-emitterLocal[1],
            cy+y*rootRadius/scale[2]-emitterLocal[2], info.max[3]-emitterLocal[3]}
        -- The shader grows each veil upward, then bends it out into the crown.
        -- It retains bounded material length while rolling and trailing wind.
        layout.directions[i] = {0.85*x/scale[1], 0.85*y/scale[2], 1.45/scale[3]}
    end
    for i, bundle in ipairs(layout.arcIndices) do
        layout.arcRoots[i] = layout.roots[bundle]
    end
    return layout
end

function M.RibbonOptions(layout, index)
    return {
        mode='canopy', rootOffset=layout.roots[index],
        directionSpace='piece', direction=layout.directions[index],
        length=layout.radius*(1.98+0.12*math.sin(index*1.7)^2),
        -- Broad soft veils retain the cloud between occasional clear branches.
        width=layout.radius*(0.90+0.10*math.sin(index*2.3)^2), strands=3,
        stiffness=0.28, gravity=0.18, curl=1.3, speed=0.8,
        windAffected=true, windInfluence=1.2, motionAffected=true,
        motionInfluence=0.7, trailTime=0.45,
        colorStart={0,0,0,1}, colorEnd={0.34,0.12,1,1},
        emission={0,0.45}, sourceGlow={0,0,0,0},
        distanceFactor=40, drawInIcon=true, seed=index*19,
    }
end

function M.ArcOptions(layout, index)
    -- Copy every geometric and dynamic parameter from the charged bundle.
    -- Matching phase, strand count and width also keeps its animated roots and
    -- folds aligned; the canopy_arc shader supplies narrow luminous coverage.
    local options = M.RibbonOptions(layout, layout.arcIndices[index])
    local electric = GrapheneArc.Options(options.seed, options.rootOffset)
    options.mode = 'canopy_arc'
    for _, field in ipairs({'colorStart','colorEnd','emission','sourceGlow'}) do
        options[field] = electric[field]
    end
    return options
end

return M
