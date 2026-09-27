-- Fit only the facade pieces selected by the building script. Imported model
-- bounds contain hidden variants and street furniture thousands of elmos away.
local M={}
local function transform(m,x,y,z)
    return m[1]*x+m[5]*y+m[9]*z+m[13],
        m[2]*x+m[6]*y+m[10]*z+m[14],m[3]*x+m[7]*y+m[11]*z+m[15]
end
function M.Read(id)
    local count=Spring.GetUnitRulesParam(id,'mosaic_window_piece_count')
    if not count or count<1 then return nil,'waiting for facade piece list (restart after updating)' end
    local world={Spring.GetUnitTransformMatrix(id)}
    if not world[16] then return nil,'unit transform unavailable' end
    local lo,hi={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
    for i=1,count do
        local piece=Spring.GetUnitRulesParam(id,'mosaic_window_piece_'..i)
        if piece then
            local info=Spring.GetUnitPieceInfo(id,piece)
            local m={Spring.GetUnitPieceMatrix(id,piece)}
            if info and not info.isEmpty and info.min and info.max and m[16] then
                for corner=0,7 do
                    local x=corner%2==0 and info.min[1] or info.max[1]
                    local y=math.floor(corner/2)%2==0 and info.min[2] or info.max[2]
                    local z=corner<4 and info.min[3] or info.max[3]
                    local p={transform(world,transform(m,x,y,z))}
                    for a=1,3 do lo[a]=math.min(lo[a],p[a]);hi[a]=math.max(hi[a],p[a]) end
                end
            end
        end
    end
    if lo[1]==math.huge then return nil,'selected facade pieces have no geometry' end
    local width=math.max(hi[1]-lo[1],hi[3]-lo[3],128)
    local margin=math.max(8,width/64*2)
    return {x=(lo[1]+hi[1])/2,y=lo[2]-margin,z=(lo[3]+hi[3])/2,
        span=width+2*margin,height=math.max(64,hi[2]-lo[2]+2*margin)}
end
return M
