-- Parade-only clearance: city houses deliberately do not block native traffic.
-- A sparse index of live collision footprints also guards waypoint shortcuts.
local M = {}
local function intersects(a,b,box,pad)
    local lo,hi=0,1
    for _,axis in ipairs({'x','z'}) do
        local d=b[axis]-a[axis]
        local minimum,maximum=box[axis]-box['h'..axis]-pad,box[axis]+box['h'..axis]+pad
        if math.abs(d)<1e-8 then
            if a[axis]<minimum or a[axis]>maximum then return false end
        else
            local enter,leave=(minimum-a[axis])/d,(maximum-a[axis])/d
            if enter>leave then enter,leave=leave,enter end
            lo,hi=math.max(lo,enter),math.min(hi,leave)
            if lo>hi then return false end
        end
    end
    return true
end
function M.new(context)
    local S,G=context.Spring,context.GG
    local padding=(context.config or {}).routeHouseClearance or 45
    local buckets,boxes,updated={},{},-math.huge
    local cell=256
    local api={}
    function api:Refresh(frame)
        frame=frame or S.GetGameFrame()
        if frame>=updated and frame-updated<30 then return end
        updated,buckets,boxes=frame,{},{}
        for id in pairs(G.BuildingTable or {}) do
            if S.ValidUnitID(id) and not S.GetUnitIsDead(id) then
                local x,_,z=S.GetUnitPosition(id)
                local sx,_,sz,ox,_,oz=S.GetUnitCollisionVolumeData(id)
                if x then
                    sx,sz=sx or 130,sz or 130
                    local front,_,right=S.GetUnitVectors(id)
                    local hx,hz=sx*.5,sz*.5
                    if front and right then
                        x,z=x+right[1]*(ox or 0)+front[1]*(oz or 0),z+right[3]*(ox or 0)+front[3]*(oz or 0)
                        hx,hz=math.abs(right[1])*sx*.5+math.abs(front[1])*sz*.5,
                            math.abs(right[3])*sx*.5+math.abs(front[3])*sz*.5
                    end
                    local box={id=id,x=x,z=z,hx=hx,hz=hz}
                    boxes[id]=box
                    for ix=math.floor((x-hx-padding)/cell),math.floor((x+hx+padding)/cell) do
                        for iz=math.floor((z-hz-padding)/cell),math.floor((z+hz+padding)/cell) do
                            local key=ix..':'..iz
                            buckets[key]=buckets[key] or {};buckets[key][#buckets[key]+1]=box
                        end
                    end
                end
            end
        end
    end
    function api:SegmentClear(a,b)
        local checked={}
        for ix=math.floor(math.min(a.x,b.x)/cell),math.floor(math.max(a.x,b.x)/cell) do
            for iz=math.floor(math.min(a.z,b.z)/cell),math.floor(math.max(a.z,b.z)/cell) do
                for _,box in ipairs(buckets[ix..':'..iz] or {}) do
                    if not checked[box.id] then
                        checked[box.id]=true
                        if intersects(a,b,box,padding) then return false,box.id end
                    end
                end
            end
        end
        return true
    end
    -- Ordinary traffic uses a smaller radial exclusion. Parade assembly must
    -- instead start outside the live, rotated collision box plus truck padding.
    function api:FindCurb(id, toward, passable)
        local box=boxes[id]
        if not box then return nil end
        for ring=0,3 do
            local hx,hz=box.hx+padding+16+ring*64,box.hz+padding+16+ring*64
            local candidates={}
            for ix=-1,1 do for iz=-1,1 do
                if ix~=0 or iz~=0 then
                    candidates[#candidates+1]={x=box.x+ix*hx,z=box.z+iz*hz}
                end
            end end
            table.sort(candidates,function(a,b)
                local ad=(a.x-toward.x)^2+(a.z-toward.z)^2
                local bd=(b.x-toward.x)^2+(b.z-toward.z)^2
                if ad~=bd then return ad<bd end
                return a.x==b.x and a.z<b.z or a.x<b.x
            end)
            for _,p in ipairs(candidates)do
                if p.x>16 and p.z>16 and p.x<context.Game.mapSizeX-16 and p.z<context.Game.mapSizeZ-16
                    and self:SegmentClear(p,p) then
                    local accepted=passable(p)
                    if accepted then return accepted end
                end
            end
        end
    end
    -- Native paths ignore these houses. Re-route only a rejected leg through
    -- a bounded local road grid; keep native movement for the resulting goals.
    function api:Detour(a,b,passable,budget)
        local step=32
        local heap,seen={},{}
        local function push(n)
            heap[#heap+1]=n
            local i=#heap
            while i>1 do
                local parent=math.floor(i/2)
                if heap[parent].score<=n.score then break end
                heap[i]=heap[parent];i=parent
            end
            heap[i]=n
        end
        local function pop()
            local best,last=heap[1],table.remove(heap)
            if #heap>0 then
                local i=1
                while i*2<=#heap do
                    local child=i*2
                    if child<#heap and heap[child+1].score<heap[child].score then child=child+1 end
                    if heap[child].score>=last.score then break end
                    heap[i]=heap[child];i=child
                end
                heap[i]=last
            end
            return best
        end
        local function distance(p,q)return math.sqrt((p.x-q.x)^2+(p.z-q.z)^2)end
        local function clear(p,q)
            return self:SegmentClear(p,q) and passable(q)
                and passable({x=(p.x+q.x)*.5,z=(p.z+q.z)*.5})
        end
        local first={x=a.x,z=a.z,i=0,j=0,cost=0,score=distance(a,b)}
        seen['0:0']=first;push(first)
        local expansions=0
        while #heap>0 and expansions<budget do
            local n=pop()
            if not n.closed then
                n.closed=true;expansions=expansions+1
                if distance(n,b)<=step*2 and clear(n,b) then
                    local reverse={b}
                    while n do reverse[#reverse+1]={x=n.x,z=n.z};n=n.parent end
                    local result={}
                    for i=#reverse,1,-1 do result[#result+1]=reverse[i] end
                    return result,expansions
                end
                for di=-1,1 do for dj=-1,1 do
                    if di~=0 or dj~=0 then
                        local i,j=n.i+di,n.j+dj
                        local key=i..':'..j
                        local old=seen[key]
                        local cost=n.cost+step*math.sqrt(di*di+dj*dj)
                        local candidate={x=a.x+i*step,z=a.z+j*step,i=i,j=j,cost=cost,parent=n}
                        if (not old or cost<old.cost) and candidate.x>16 and candidate.z>16
                            and candidate.x<context.Game.mapSizeX-16 and candidate.z<context.Game.mapSizeZ-16
                            and clear(n,candidate) then
                            candidate.score=cost+distance(candidate,b)
                            if old then old.closed=true end
                            seen[key]=candidate;push(candidate)
                        end
                    end
                end end
            end
        end
        return nil,expansions
    end
    return api
end
return M
