-- A solid selected-building envelope in the existing compact column protocol.
-- Piece bounds are raw mesh coordinates; Recoil's model-space piece matrix
-- includes ancestor/import transforms. Apply it once, before the unit basis is
-- applied by the shared occupancy renderer. No selection/collision bounds here.
local function finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end

function BuildSolidBuildingShadowColumns(id,pieces,profile)
    profile=profile or {}
    local cellSize,maxCells=profile.cellSize or 16,profile.maxCells or 1024
    if not finite(cellSize) or cellSize<=0 or not finite(maxCells) or maxCells<1 then
        return nil,"invalid solid shadow grid limits"
    end
    -- The shared transport accepts at most 4096 cells. A square dimension cap
    -- makes work bounded even for an unusually wide or tall imported variant.
    local maxAxis=math.floor(math.sqrt(math.min(4096,maxCells)))
    local lo,hi={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
    local seen={}
    for _,pieceID in ipairs(pieces or {}) do
        if not seen[pieceID] then
            seen[pieceID]=true
            local info=Spring.GetUnitPieceInfo(id,pieceID)
            local matrix={Spring.GetUnitPieceMatrix(id,pieceID)}
            if not info or not info.min or not info.max then
                return nil,"selected building piece bounds unavailable"
            end
            for axis=1,3 do
                if not finite(info.min[axis]) or not finite(info.max[axis]) or info.min[axis]>info.max[axis] then
                    return nil,"invalid selected building piece bounds"
                end
            end
            for index=1,16 do
                if not finite(matrix[index]) then return nil,"selected building piece transform unavailable" end
            end
            if not info.isEmpty then
                for corner=0,7 do
                    local x=corner%2==0 and info.min[1] or info.max[1]
                    local y=math.floor(corner/2)%2==0 and info.min[2] or info.max[2]
                    local z=corner<4 and info.min[3] or info.max[3]
                    local transformed={matrix[1]*x+matrix[5]*y+matrix[9]*z+matrix[13],
                        matrix[2]*x+matrix[6]*y+matrix[10]*z+matrix[14],
                        matrix[3]*x+matrix[7]*y+matrix[11]*z+matrix[15]}
                    for axis=1,3 do
                        if not finite(transformed[axis]) then return nil,"invalid transformed building bounds" end
                        lo[axis]=math.min(lo[axis],transformed[axis])
                        hi[axis]=math.max(hi[axis],transformed[axis])
                    end
                end
            end
        end
    end
    local width,height,depth=hi[1]-lo[1],hi[2]-lo[2],hi[3]-lo[3]
    if not finite(width) or not finite(height) or not finite(depth) or width<=0 or height<=0 or depth<=0 then
        return nil,"selected building pieces have no solid volume"
    end
    cellSize=math.max(cellSize,width/maxAxis,depth/maxAxis)
    local nx=math.max(1,math.min(maxAxis,math.ceil(width/cellSize)))
    local nz=math.max(1,math.min(maxAxis,math.ceil(depth/cellSize)))
    local grid={columns={},cellSize=cellSize,levelHeight=height,
        originX=(lo[1]+hi[1]-(nx-1)*cellSize)*.5,
        originZ=(lo[3]+hi[3]-(nz-1)*cellSize)*.5}
    if lo[2]~=0 then grid.baseHeights={} end
    for x=1,nx do
        local row={};grid.columns[x]=row
        local bases=grid.baseHeights and {};if bases then grid.baseHeights[x]=bases end
        for z=1,nz do row[z]=1;if bases then bases[z]=lo[2] end end
    end
    return grid
end
