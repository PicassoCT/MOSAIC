-- Experimental high-resolution residential yardmaps (8-elmo cells).
-- UnitDef yardmaps are immutable after loading; camera-relative gates require
-- facing-specific definitions or runtime blocking-map work, not this generator.
local M = {}

local function validMask(mask, n)
    if mask == nil then return nil end
    assert(type(mask) == "table" and #mask == n, "courtyard mask height mismatch")
    for z = 1, n do
        assert(type(mask[z]) == "string" and #mask[z] == n, "courtyard mask row mismatch")
        assert(not mask[z]:find("[^.#]"), "courtyard mask uses only . and #")
    end
    return mask
end

-- cameraBack = north/south/east/west in MODEL-LOCAL coordinates,
-- fixed at definition load time.  Not the player's moving camera.
-- mask '#' means solid architecture, '.' means existing exterior/courtyard.
-- With a supplied mask we ONLY open existing '.' cells; never cut new holes
-- through surveyed solid geometry.  Without a mask this is a schematic prototype.
function M.make(footprintX, footprintZ, opts)
    opts = opts or {}
    assert(type(footprintX) == "number" and footprintX >= 3 and footprintX % 1 == 0)
    assert(type(footprintZ) == "number" and footprintZ >= 3 and footprintZ % 1 == 0)
    local width, height = footprintX * 2, footprintZ * 2
    assert(width == height, "prototype supports square houses only")
    local n = width
    local count = opts.exits or 2
    assert(count == 2 or count == 3, "two or three gates supported")
    local back = opts.cameraBack or "north"
    assert(back == "north" or back == "south" or back == "east" or back == "west")
    local mask = validMask(opts.courtyardMask, n)
    local cells = {}
    for z = 1, n do
        cells[z] = {}
        for x = 1, n do cells[z][x] = "o" end
    end
    local function open(x,z)
        if x < 1 or x > n or z < 1 or z > n then return end
        if mask and mask[z]:sub(x,x) ~= "." then return end
        cells[z][x] = "y"
    end
    if mask then
        for z = 1,n do for x = 1,n do open(x,z) end end
    else
        -- Internal yard and spoke corridors are ONLY a schematic approximation.
        -- For real algorithm buildings, pass a geometry-derived courtyard mask.
        for z = 3,n-2 do for x = 3,n-2 do open(x,z) end end
    end
    local mid = math.floor((n+1)/2)
    local sides = {}
    for _,side in ipairs({"north","east","south","west"}) do
        if side ~= back then sides[#sides+1] = side end
    end
    for i = 1,count do
        local side = sides[i]
        -- 3-cell-wide gate; require masked geometry to already be open.
        for t = mid-1,mid+1 do
            if side == "north" then
                for z=1,3 do open(t,z) end
            elseif side == "south" then
                for z=n-2,n do open(t,z) end
            elseif side == "west" then
                for x=1,3 do open(x,t) end
            else
                for x=n-2,n do open(x,t) end
            end
        end
    end
    -- The entire camera-opposite edge remains impassable, even if the mask
    -- indicates an opening.  It takes precedence over courtyard preservation.
    for i=1,n do
        if back=="north" then cells[1][i]="o"
        elseif back=="south" then cells[n][i]="o"
        elseif back=="west" then cells[i][1]="o"
        else cells[i][n]="o" end
    end
    local lines = {}
    for z=1,n do lines[z]=table.concat(cells[z]) end
    return "h\n" .. table.concat(lines,"\n"), lines
end

return M
