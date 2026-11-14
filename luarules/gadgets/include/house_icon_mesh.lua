-- Column centres and floor elevations are model-local elmos. Emit only the
-- exposed intervals on each face, including under overhangs and beside slopes.
local M = {}

function M.surface(grid, emit)
    local first = grid.columns[1]
    if not first then return end
    local rows = {}
    local dx, dz = grid.dx, grid.dz
    for _, column in ipairs(grid.columns) do
        local ix = math.floor((column.x - first.x) / dx + 0.5)
        local iz = math.floor((column.z - first.z) / dz + 0.5)
        column.ix, column.iz = ix, iz
        local runs, bits, bottom = {}, column.mask, column.base
        while bits > 0 do
            if bits % 2 == 1 then
                local low = bottom
                repeat
                    bits = math.floor(bits / 2)
                    bottom = bottom + grid.dy
                until bits % 2 == 0
                runs[#runs+1] = {low, bottom}
            else
                bits = math.floor(bits / 2)
                bottom = bottom + grid.dy
            end
        end
        rows[ix] = rows[ix] or {}
        rows[ix][iz] = runs
    end
    local empty = {}
    local function side(ix, iz, low, high, x1, z1, x2, z2)
        local function quad(a, b)
            emit(x1,a,z1, x1,b,z1, x2,b,z2, x2,a,z2)
        end
        for _, n in ipairs((rows[ix] or empty)[iz] or empty) do
            if n[1] >= high then break end
            if n[1] > low then quad(low, n[1]) end
            low = math.max(low, n[2])
            if low >= high then return end
        end
        if low < high then quad(low, high) end
    end
    for _, c in ipairs(grid.columns) do
        local x0,x1 = c.x-dx/2,c.x+dx/2
        local z0,z1 = c.z-dz/2,c.z+dz/2
        for _, run in ipairs(rows[c.ix][c.iz]) do
            local a,b = run[1],run[2]
            emit(x0,b,z0, x0,b,z1, x1,b,z1, x1,b,z0)
            emit(x0,a,z0, x1,a,z0, x1,a,z1, x0,a,z1)
            side(c.ix-1,c.iz, a,b, x0,z1,x0,z0)
            side(c.ix+1,c.iz, a,b, x1,z0,x1,z1)
            side(c.ix,c.iz-1, a,b, x0,z0,x1,z0)
            side(c.ix,c.iz+1, a,b, x1,z1,x0,z1)
        end
    end
end

function M.body(encoded, info)
    local lo, hi = info.min, info.max
    local dx,dy,dz = (hi[1]-lo[1])/8,(hi[2]-lo[2])/8,(hi[3]-lo[3])/8
    if dx <= 0 or dy <= 0 or dz <= 0 then return end
    local grid = {dx=dx, dy=dy, dz=dz, columns={}}
    for x=0,7 do
        for z=0,7 do
            local index = 2*(8*x+z)+1
            local mask = tonumber(encoded:sub(index,index+1), 16)
            if mask > 0 then
                grid.columns[#grid.columns+1] = {
                    x=lo[1]+(x+0.5)*dx, z=lo[3]+(z+0.5)*dz, base=lo[2], mask=mask,
                }
            end
        end
    end
    return grid
end
return M
