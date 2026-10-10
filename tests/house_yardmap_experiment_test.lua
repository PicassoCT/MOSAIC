local generator = dofile("scripts/lib_house_yardmap_experiment.lua")
local function check(f, n, exits)
    local map, rows = generator.make(f,f,{cameraBack="north",exits=exits})
    assert(map:sub(1,2)=="h\n")
    assert(#rows==n)
    for _,r in ipairs(rows) do assert(#r==n) end
    assert(rows[1]==string.rep("o",n))
    assert(rows[n]:find("yyy",1,true))
    if exits==3 then assert(rows[math.floor((n+1)/2)]:sub(1,3)=="yyy") end
end
check(6,12,2)
check(8,16,3)
local masked = {}
for z=1,12 do masked[z] = string.rep("#",12) end
local _,rows = generator.make(6,6,{courtyardMask=masked,exits=3})
for _,r in ipairs(rows) do assert(r==string.rep("o",12)) end
print("experimental high-resolution house yardmaps passed")
