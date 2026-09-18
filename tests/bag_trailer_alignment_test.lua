-- Run from repository root: lua tests/bag_trailer_alignment_test.lua
math.atan2 = math.atan2 or function(y,x) return math.atan(y,x) end
local M=dofile("scripts/lib_bag_alignment.lua")
local function near(a,b) assert(math.abs(a-b)<1e-6, tostring(a).." ~= "..tostring(b)) end
local function apply(r,v)
    return {r[1][1]*v[1]+r[1][2]*v[2]+r[1][3]*v[3],
            r[2][1]*v[1]+r[2][2]*v[2]+r[2][3]*v[3],
            r[3][1]*v[1]+r[3][2]*v[2]+r[3][3]*v[3]}
end
local vectors={{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1},{0.6,0.8,0}}
for _,a in ipairs(vectors) do for _,b in ipairs(vectors) do
    local x,y,z=M.align(a[1],a[2],a[3],b[1],b[2],b[3])
    local v=apply(M.rotation(x,y,z),a)
    for i=1,3 do near(v[i],b[i]) end
end end

-- Exercise the real finite bag worker against animated parent matrices.
local frame, starts, co=0,0,nil
local angles, parent={0,0,0},{0,0,0}
x_axis,y_axis,z_axis=1,2,3
SetSignalMask=function() end
Sleep=function() coroutine.yield() end
StartThread=function(fn)
    starts=starts+1; co=coroutine.create(fn)
    local ok,err=coroutine.resume(co); assert(ok,err)
end
Turn=function(_,axis,value) angles[axis]=value end
local function multiply(a,b)
    local c={{},{},{}}
    for i=1,3 do for j=1,3 do
        c[i][j]=a[i][1]*b[1][j]+a[i][2]*b[2][j]+a[i][3]*b[3][j]
    end end
    return c
end
Spring={
    GetGameFrame=function() return frame end,
    GetUnitPieceInfo=function() return {min={-1,-4,-1},max={1,0,1}} end,
    GetUnitVectors=function() return {0,0,1},{0,1,0},{-1,0,0} end,
    UnitScript={GetPieceRotation=function() return angles[1],angles[2],angles[3] end},
    GetUnitPieceMatrix=function()
        local r=multiply(M.rotation(parent[1],parent[2],parent[3]),M.rotation(angles[1],angles[2],angles[3]))
        return r[1][1],r[2][1],r[3][1],0,r[1][2],r[2][2],r[3][2],0,r[1][3],r[2][3],r[3][3],0,0,0,0,1
    end
}
local config=M.add(1,1,{},1,0)
M.wake(0); assert(starts==1)
local function tick()
    frame=frame+3
    local ok,err=coroutine.resume(co); assert(ok,err)
end
for _,p in ipairs({{0,0,1.2},{0.7,-0.6,-1},{-0.4,1.3,0.8}}) do
    parent=p
    M.wake(0)
    tick()
    local world=multiply(M.rotation(p[1],p[2],p[3]),M.rotation(angles[1],angles[2],angles[3]))
    local down=apply(world,{0,-1,0})
    near(down[1],0); near(down[2],-1); near(down[3],0)
    -- Repeating the same pose must not feed the previous correction back.
    tick()
    world=multiply(M.rotation(p[1],p[2],p[3]),M.rotation(angles[1],angles[2],angles[3]))
    down=apply(world,{0,-1,0})
    near(down[1],0); near(down[2],-1); near(down[3],0)
end
while coroutine.status(co)~="dead" do tick() end
M.wake(0); assert(starts==2)

-- Run the actual trailer loop with deterministic headings.
local file=assert(io.open("scripts/LongTruckscript.lua")); local source=file:read("*a"); file:close()
local code=assert(source:match("(local function wrapTrailerAngle.-)\n\nlocal loadOutUnitID"))
local function trailer(headings,moving)
    local index,yaw=1,0
    local e={math=math,unitID=1,PayloadCenter=1,DetectPiece=2,x_axis=1,y_axis=2,z_axis=3}
    e.clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
    e.newMotionSampler=function() return function() return moving,true,false end end
    e.Spring={GetUnitHeading=function() return headings[index] end,
        GetGameFrame=function() return (index-1)*3 end,
        GetUnitPiecePosDir=function() return 0,7,0 end,
        GetGroundHeight=function() return 0 end,
        UnitScript={GetPieceRotation=function() return 0,0,yaw end}}
    e.Turn=function(_,axis,target)
        assert(axis~=2, "Trailer steering must not use local Y")
        if axis==3 then yaw=target end
    end
    e.Sleep=function() coroutine.yield() end
    if _VERSION=="Lua 5.1" then local f=assert(loadstring(code)); setfenv(f,e); f()
    else assert(load(code,"trailer","t",e))() end
    local thread=coroutine.create(e.turnTrailerLoop)
    for i=1,#headings do index=i; local ok,err=coroutine.resume(thread); assert(ok,err) end
    return yaw
end
near(trailer({0,1000,2000},false),-2000*math.pi/32768)
near(trailer({0,-1000,-2000},false),2000*math.pi/32768)
near(trailer({32760,-32760},false),-16*math.pi/32768)
near(trailer({-32760,32760},false),16*math.pi/32768)
near(trailer({0,1000,2000},true),-trailer({0,-1000,-2000},true))

-- Verify the steering axis against the authored model, not an identity parent.
local modelFile=assert(io.open("objects3d/truck_western3.dae"))
local model=modelFile:read("*a"); modelFile:close()
local function authoredRotation(name)
    local values={}
    local matrix=assert(model:match('<node name="'..name..'"[^>]*><matrix[^>]*>([^<]+)'))
    for value in matrix:gmatch("%S+") do values[#values+1]=tonumber(value) end
    local rotation={{values[1],values[2],values[3]},
                    {values[5],values[6],values[7]},
                    {values[9],values[10],values[11]}}
    for column=1,3 do
        local length=math.sqrt(rotation[1][column]^2+rotation[2][column]^2+rotation[3][column]^2)
        for row=1,3 do rotation[row][column]=rotation[row][column]/length end
    end
    return rotation
end
local authored=multiply(authoredRotation("center"),authoredRotation("PayloadCenter"))
local up=apply(authored,{0,0,1})
near(up[1],0); near(up[2],1); near(up[3],0)
for _,headings in ipairs({
    {0,8192,16384}, {0,-8192,-16384},
    {32760,-32760}, {-32760,32760},
    {12000,14000,14000,14000},
}) do
    local yaw=trailer(headings,false)
    local start=multiply(M.rotation(0,headings[1]*math.pi/32768,0),authored)
    local finish=multiply(M.rotation(0,headings[#headings]*math.pi/32768,0),
                          multiply(authored,M.rotation(0,0,yaw)))
    for row=1,3 do for column=1,3 do near(finish[row][column],start[row][column]) end end
end
assert(math.abs(trailer({0,8192,8192,8192},true))<
       math.abs(trailer({0,8192,8192,8192},false)),
       "Physical movement should straighten the trailer")
print("bag and trailer alignment tests passed")
