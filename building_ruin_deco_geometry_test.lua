-- Run from the repository root. Model-space transforms include authored mesh
-- offsets, import scale, noncentral pivots and the post-collapse lean.
local unpack = unpack or table.unpack
local function identity()
    return {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
end
local function multiply(a,b)
    local out={}
    for col=0,3 do for row=1,4 do
        local value=0
        for k=0,3 do value=value+a[k*4+row]*b[col*4+k+1] end
        out[col*4+row]=value
    end end
    return out
end
local function rotate(axis,angle)
    local m=identity()
    local a,b=axis%3+1,(axis+1)%3+1
    m[(a-1)*4+a],m[(b-1)*4+b]=math.cos(angle),math.cos(angle)
    m[(a-1)*4+b],m[(b-1)*4+a]=math.sin(angle),-math.sin(angle)
    return m
end
local function near(a,b,message)
    assert(math.abs(a-b)<1e-7,message..': '..tostring(a)..' ~= '..tostring(b))
end

for _,scale in ipairs({1,.0254}) do for _,swappedUp in ipairs({false,true}) do
    local root=identity()
    root[1],root[6],root[11]=scale,scale,scale
    if swappedUp then root=multiply(root,rotate(1,-math.pi/2)) end
    root[13],root[14],root[15]=3,4,-5
    local upAxis=swappedUp and 3 or 2
    local pieces={
        [1]={offset={40,7,20},move={0,0,0},angles={.08,0,.04},min={-10,0,-8},max={10,12,8}},
        -- Deliberately taller, but invisible: it must not anchor the ruin cap.
        [2]={offset={40,80,100},move={0,0,0},angles={0,0,0},min={-10,0,-8},max={10,12,8}},
        [20]={offset={17.447098,65.608765,-.872881},move={0,0,0},angles={0,0,0},min={-2,-4,-1},max={8,0,3}},
        [21]={offset={0,8,0},move={0,0,0},angles={0,0,0},min={-3,-2,-1},max={2,3,1}},
    }
    local function matrix(p)
        if p==99 then return root end
        local data=pieces[p]
        local m=identity()
        for axis=1,3 do m=multiply(m,rotate(axis,data.angles[axis])) end
        for axis=1,3 do m[12+axis]=data.offset[axis]+data.move[axis] end
        return multiply(root,m)
    end
    -- Independent corner enumeration checks the resulting visible geometry.
    local function corners(p)
        local data,m=pieces[p],matrix(p)
        local low,high={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
        for _,x in ipairs({data.min[1],data.max[1]}) do
        for _,y in ipairs({data.min[2],data.max[2]}) do
        for _,z in ipairs({data.min[3],data.max[3]}) do
            for axis=1,3 do
                local v=m[axis]*x+m[4+axis]*y+m[8+axis]*z+m[12+axis]
                low[axis],high[axis]=math.min(low[axis],v),math.max(high[axis],v)
            end
        end end end
        return low,high
    end
    Spring={
        GetUnitPieceMap=function() return {root=99} end,
        GetUnitPieceInfo=function(_,p)
            local d=pieces[p]
            return {parent='root',min=d.min,max=d.max}
        end,
        GetUnitPieceMatrix=function(_,p) return unpack(matrix(p)) end,
    }
    local function move(p,axis,value) pieces[p].move[axis]=value end
    local function turn(p,axis,value) pieces[p].angles[axis]=value end
    local helper=dofile('scripts/lib_building_ruin_deco.lua')
    local function placeAndCheck(p)
        assert(helper.Place(42,p,{{piece=1},{piece=2}},{[1]=true},move,turn))
        local low,high=corners(p)
        local targetLow,targetHigh=corners(1)
        near(low[2],targetHigh[2],'ruin base must touch the settled column top')
        for _,axis in ipairs({1,3}) do
            near((low[axis]+high[axis])*.5,(targetLow[axis]+targetHigh[axis])*.5,'off-centre rotated cap drifted')
        end
        for axis=1,3 do
            if axis==upAxis then assert(pieces[p].angles[axis]>0 and pieces[p].angles[axis]<2*math.pi)
            else near(pieces[p].angles[axis],0,'ruin cap tilted instead of turning about up') end
        end
    end
    placeAndCheck(20)
    local yaw=pieces[20].angles[upAxis]
    pieces[1].move[upAxis]=-5
    placeAndCheck(20)
    near(pieces[20].angles[upAxis],yaw,'repositioning changed the existing cap rotation')
    placeAndCheck(21)
    assert(pieces[21].angles[upAxis]~=yaw,'pieces all received one rotation')
    assert(not helper.Place(42,20,{{piece=1}},{},move,turn),'empty column received a cap')
end end
print('PASS: ruin caps fit tilted column tops, rotated parent axes, authored offsets and import scale')
