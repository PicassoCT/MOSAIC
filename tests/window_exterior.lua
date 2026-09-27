local M=assert(loadfile('luaui/widgets_mosaic/include/window_exterior.lua'))()
local N=24
local walls={}
for i=1,N*N do walls[i]={0,0,0,0} end
local function set(x,y,band) walls[y*N+x+1][band]=1 end
-- Closed courtyard; open U at a second floor; diagonal contact at a third.
for p=5,18 do
    for b=1,4 do set(5,p,b);set(18,p,b);set(p,5,b) end
    for _,b in ipairs({1,3,4}) do set(p,18,b) end
end
set(5,5,3);walls[5*N+5+1][3]=0 -- only a diagonal escape, not a doorway
local outside=M.Fill(walls,N)
assert(outside[1][1]==1)
assert(outside[12*N+12+1][1]==0,'closed courtyard connected to street')
assert(outside[12*N+12+1][2]==1,'open U/recess incorrectly rejected')
assert(outside[12*N+12+1][3]==0,'diagonal corner leaked flood fill')
assert(outside[5*N+12+1][1]==0,'wall became outside')
for p=0,N-1 do assert(outside[p+1][4]==1,'exterior border was lost') end
print('PASS: four independent height bands, closed courtyard rejection, open recess retention, diagonal barriers')
