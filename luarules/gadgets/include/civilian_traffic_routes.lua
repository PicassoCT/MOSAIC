-- Geometry only. Build once per road network; no random draws or engine state.
local M = {}
local floor, sqrt, abs = math.floor, math.sqrt, math.abs
function M.hash(text)
    local n=17
    for i=1,#text do n=(n*131+text:byte(i))%2147483647 end
    return n
end
local function cross(ax,az,bx,bz) return ax*bz-az*bx end
function M.junctions(network, config)
    local segments, cells, seen, points = {}, {}, {}, {}
    local cellSize=512
    for _,road in ipairs(network.roads or {}) do
        for i=2,#road.points do
            local a,b=road.points[i-1],road.points[i]
            local dx,dz=b[1]-a[1],b[2]-a[2]
            if dx*dx+dz*dz>1 then
                local s={x=a[1],z=a[2],dx=dx,dz=dz}
                segments[#segments+1]=s
                local index=#segments
                for cx=floor(math.min(a[1],b[1])/cellSize),floor(math.max(a[1],b[1])/cellSize) do
                    for cz=floor(math.min(a[2],b[2])/cellSize),floor(math.max(a[2],b[2])/cellSize) do
                        local key=cx..":"..cz
                        local bucket=cells[key] or {}; cells[key]=bucket
                        for _,other in ipairs(bucket) do
                            local pair=other..":"..index
                            if not seen[pair] then
                                seen[pair]=true
                                local t=segments[other]
                                local den=cross(dx,dz,t.dx,t.dz)
                                if abs(den)>0.001 then
                                    local qx,qz=t.x-s.x,t.z-s.z
                                    local u=cross(qx,qz,t.dx,t.dz)/den
                                    local v=cross(qx,qz,dx,dz)/den
                                    if u>=0 and u<=1 and v>=0 and v<=1 then
                                        local x,z=s.x+u*dx,s.z+u*dz
                                        local k=floor(x/8+0.5)..":"..floor(z/8+0.5)
                                        local p=points[k] or {id=k,x=x,z=z,arms={}}
                                        points[k]=p
                                        local function arm(ax,az)
                                            local length=sqrt(ax*ax+az*az)
                                            ax,az=ax/length,az/length
                                            for _,d in ipairs(p.arms) do
                                                if ax*d[1]+az*d[2]>0.98 then return end
                                            end
                                            p.arms[#p.arms+1]={ax,az}
                                        end
                                        if u>0.001 then arm(-dx,-dz) end
                                        if u<0.999 then arm(dx,dz) end
                                        if v>0.001 then arm(-t.dx,-t.dz) end
                                        if v<0.999 then arm(t.dx,t.dz) end
                                    end
                                end
                            end
                        end
                        bucket[#bucket+1]=index
                    end
                end
            end
        end
    end
    local candidates={}
    for _,p in pairs(points) do
        if #p.arms>=3 then p.rank=M.hash(p.id);candidates[#candidates+1]=p end
    end
    table.sort(candidates,function(a,b) return a.rank<b.rank or (a.rank==b.rank and a.id<b.id) end)
    local count=math.min(config.maxJunctions,math.max(1,floor(#candidates*config.junctionFraction)))
    local selected={}
    for i=1,math.min(count,#candidates) do selected[i]=candidates[i] end
    return selected
end

function M.decorate(route, junctions, config, radius, passable, ground)
    local result={route[1]}
    local offset=math.max(config.stopOffset,config.arrivalRadius+config.junctionRadius+radius)
    local lane=math.max(config.laneOffset,radius+24)
    for i=2,#route do
        local a,b=route[i-1],route[i]
        local dx,dz=b.x-a.x,b.z-a.z
        local length=sqrt(dx*dx+dz*dz)
        local crossings={}
        if length>offset*2 then
            dx,dz=dx/length,dz/length
            for _,j in ipairs(junctions) do
                local along=(j.x-a.x)*dx+(j.z-a.z)*dz
                local across=abs(cross(j.x-a.x,j.z-a.z,dx,dz))
                local entering,leaving=false,false
                for _,arm in ipairs(j.arms) do
                    local dot=arm[1]*dx+arm[2]*dz
                    entering=entering or dot < -0.95
                    leaving=leaving or dot > 0.95
                end
                if entering and leaving and across<=config.corridorWidth and along>offset and along<length-offset then
                    -- Keep opposing queues clear of each other's exits.
                    local stop={x=a.x+dx*(along-offset)+dz*lane,z=a.z+dz*(along-offset)-dx*lane}
                    local exit={x=a.x+dx*(along+offset)+dz*lane,z=a.z+dz*(along+offset)-dx*lane}
                    stop.y,exit.y=ground(stop.x,stop.z),ground(exit.x,exit.z)
                    if passable(stop) and passable(exit) then
                        stop.trafficJunction=j;stop.trafficExit=exit
                        crossings[#crossings+1]={along=along,stop=stop,exit=exit}
                    end
                end
            end
        end
        table.sort(crossings,function(x,y) return x.along<y.along or (x.along==y.along and x.stop.trafficJunction.id<y.stop.trafficJunction.id) end)
        local last=-offset*2
        for _,c in ipairs(crossings) do
            -- Close junctions need a proper lane graph; do not overlap holds.
            if c.along-last>offset*2 then
                result[#result+1]=c.stop;result[#result+1]=c.exit;last=c.along
            end
        end
        result[#result+1]=b
    end
    return result
end
return M
