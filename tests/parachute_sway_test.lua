-- Run from repository root: lua tests/parachute_sway_test.lua
math.atan2 = math.atan2 or function(y,x) return math.atan(y,x) end
local sway = dofile("scripts/lib_parachute_sway.lua")
local function near(a,b) assert(math.abs(a-b)<1e-8, tostring(a).." ~= "..tostring(b)) end
local function rotation(x,y,z)
    local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
    return {{cy*cz+sy*sx*sz,-cy*sz+sy*sx*cz,sy*cx},
            {cx*sz,cx*cz,-sx},{-sy*cz+cy*sx*sz,sy*sz+cy*sx*cz,cy*cx}}
end
local function mul(a,b)
    local out={{},{},{}}
    for i=1,3 do for j=1,3 do
        out[i][j]=a[i][1]*b[1][j]+a[i][2]*b[2][j]+a[i][3]*b[3][j]
    end end
    return out
end
local x,z=sway.wind(30,40,10)
near(x,0.6); near(z,0.8)
x,z=sway.wind(0,0,0); near(x,0); near(z,0)
-- Guard the baked parent-axis assumption against changes to the actual asset.
local asset=assert(io.open("objects3d/air_parachut.dae"))
local dae=asset:read("*a"); asset:close()
local matrix=assert(dae:match('<node name="step"[^>]*><matrix[^>]*>([^<]+)'))
local values={}
for value in matrix:gmatch("%S+") do values[#values+1]=tonumber(value) end
near(values[3],0); near(values[7],1); near(values[11],0) -- local Z = model up
near(values[2],0); near(values[6],0); near(values[10],-1) -- local Y = -model Z
-- Independent matrix composition verifies Euler extraction for all elements.
for i=1,156 do
    for _,flow in ipairs({{0,0},{1,0},{-1,0},{0,1},{0,-1}}) do
        local time=3.7
        local azimuth=(i-1)*2.399963229728653
        local phase=azimuth+(i%7)*0.37
        local curl=0.12+0.14*math.sin(time*1.1-phase)+0.045*math.sin(time*2.3+phase*1.7)
        local a=azimuth+0.035*math.sin(time*0.7+phase)
        local expected=mul(mul(rotation(flow[2]*0.18,flow[1]*0.18,0),rotation(0,0,a)),rotation(curl,0,0))
        local actual=rotation(sway.pose(time,i,156,flow[1],flow[2]))
        for row=1,3 do for col=1,3 do near(actual[row][col],expected[row][col]) end end
    end
end
-- Run the real animation worker with a sparse piece group.
local file=assert(io.open("scripts/parachutscript.lua")); local source=file:read("*a"); file:close()
local worker=assert(source:match("(function Strandanimation%(%).-)%s*function script.Killed"))
local frame, shown, turned=0,{},{}
local group={}
for i=1,156 do group[i*2]=1000+i end
local e={math=math,table=table,type=type,pairs=pairs,ipairs=ipairs,
    unitID=5,Game={windMax=20},TablesOfPiecesGroups={Rotator=group},
    parachuteSway=sway,x_axis=1,y_axis=2,z_axis=3,steeringX=0,steeringZ=0}
e.Spring={GetGameFrame=function() return frame end,GetUnitHeading=function() return 0 end,
    GetWind=function() return 20,0,0 end}
e.Show=function(id) shown[id]=true end
e.Turn=function(id,axis,value,speed)
    assert(id>1000 and id<=1156, "Must not animate descent spiral")
    assert(value==value and speed>0)
    turned[id]=true
end
e.Sleep=function(ms) assert(ms==100); coroutine.yield() end
if _VERSION=="Lua 5.1" then local f=assert(loadstring(worker)); setfenv(f,e); f()
else assert(load(worker,"sway","t",e))() end
local co=coroutine.create(e.Strandanimation)
for i=0,20 do frame=i*3; local ok,err=coroutine.resume(co); assert(ok,err) end
for _,id in pairs(group) do assert(shown[id] and turned[id]) end
near(e.windX,1); near(e.windZ,0)
-- Test the actual idle-drift block, including steering overriding wind drift.
local drift=assert(source:match("(steeringX, steeringZ = xOff, zOff.-)\n        Sleep%(1%)"))
e.WIND_DRIFT=0.12; e.x=0; e.y=50; e.z=0; e.dropRate=0.5
local pos
e.Spring.MoveCtrl={SetPosition=function(_,x,y,z) pos={x,y,z} end}
local f
if _VERSION=="Lua 5.1" then f=assert(loadstring(drift)); setfenv(f,e)
else f=assert(load(drift,"drift","t",e)) end
e.xOff=0; e.zOff=0; f(); near(pos[1],0.12); near(pos[2],49.5)
e.xOff=1.52; f(); near(pos[1],1.52)
print("parachute sway: matrices, all 156 strands, spiral isolation and idle drift passed")
