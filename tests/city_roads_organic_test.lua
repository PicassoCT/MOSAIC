-- Irregular neighbourhoods, authored asphalt and navigation names.
local roads=dofile('scripts/lib_city_roads.lua')
math.random=function() error('Street generation must never consume engine RNG') end
local plots={{x=480,z=480},{x=900,z=600},{x=1300,z=820},{x=620,z=1080},{x=1100,z=1300},{x=1580,z=1450}}
local function blocked(x,z) return z<192 or x>2100 end
local a=roads.infer(plots,4096,4096,blocked,'arabic','fixture',112)
local reversed={};for i=#plots,1,-1 do reversed[#reversed+1]=plots[i] end
local b=roads.infer(reversed,4096,4096,blocked,'arabic','fixture',112)
assert(roads.encode(a)==roads.encode(b),'Plot order changed street geometry or names')
assert(#a.roads>0,'Irregular city generated no streets')
local curved=false
for _,r in ipairs(a.roads) do
    assert(not r.name:find('lane/') and not r.name:find('%d'),'Internal IDs leaked into street labels')
    for _,p in ipairs(r.points) do
        assert(p[1]<2300 and p[2]<2200,'Street crossed empty outer city')
        assert(not blocked(p[1],p[2]),'Street crossed forbidden terrain')
        for _,house in ipairs(plots) do
            assert(math.abs(p[1]-house.x)>96 or math.abs(p[2]-house.z)>96,'Street ran through house footprint')
        end
    end
    for i=3,#r.points do
        local p,q,t=r.points[i-2],r.points[i-1],r.points[i]
        if (q[1]-p[1])*(t[2]-q[2])~=(q[2]-p[2])*(t[1]-q[1]) then curved=true end
    end
end
assert(curved,'City roads remained a rectangular grid')
-- A straight main street keeps its name across a perpendicular junction.
local mask={};local n=40
for z=1,n do for x=1,n do if (z>=19 and z<=21) or (x>=19 and x<=21) then mask[(z-1)*n+x]=true end end end
local cross=roads.trace(mask,n,n,32,'arabic','cross')
local horizontal={}
for _,r in ipairs(cross.roads) do
    local p,q=r.points[1],r.points[#r.points]
    if math.abs(q[1]-p[1])>math.abs(q[2]-p[2]) then horizontal[#horizontal+1]=r end
end
assert(#horizontal==2 and horizontal[1].name==horizontal[2].name,'Junction renamed a continuous street')
assert(horizontal[1].street_id==horizontal[2].street_id,'Continuous street has split address identity')
local authored=roads.normalize(dofile('scripts/city_roads/dhubai.lua'))
assert(#authored.roads>100 and #authored.roads<500)
for _,r in ipairs(authored.roads) do for _,p in ipairs(r.points) do assert(p[1]>=0 and p[1]<=8192 and p[2]>=0 and p[2]<=8192) end end
assert(roads.sector(0,0,8192,8192)=='A1')
assert(roads.sector(1024,2048,8192,8192)=='B3')
assert(roads.sector(8192,8192,8192,8192)=='H8')
assert(roads.sector(26*1024,0,30000,8192)=='AA1')
print('PASS: organic plot clearance, sparse outskirts, terrain exclusion, junction naming and Dhubai authored roads')
