-- Pure topology helper: four independent horizontal wall bands, four-neighbour fill.
-- No model parser or 3D voxel framework. Input values are rasterised wall barriers.
local M={}
function M.Fill(walls,size)
    local outside={}
    for i=1,size*size do outside[i]={0,0,0,0} end
    for band=1,4 do
        local queue,head={},1
        local function visit(x,y)
            if x<0 or y<0 or x>=size or y>=size then return end
            local i=y*size+x+1
            if outside[i][band]==0 and walls[i][band]<0.5 then
                outside[i][band]=1;queue[#queue+1]=i
            end
        end
        for p=0,size-1 do visit(p,0);visit(p,size-1);visit(0,p);visit(size-1,p) end
        while head<=#queue do
            local i=queue[head]-1;head=head+1
            local x,y=i%size,math.floor(i/size)
            visit(x-1,y);visit(x+1,y);visit(x,y-1);visit(x,y+1)
        end
    end
    return outside
end
return M
