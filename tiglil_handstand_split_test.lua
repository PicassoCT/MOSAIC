local f=assert(io.open('tests/tiglil_precision_test.lua'));local source=f:read('*a');f:close()
source=source:sub(1,assert(source:find('local routines={',1,true))-1)
source=source..[=[
local function rotate(v,name)
    local a=rotations[pieceIDs[name]] or {0,0,0}
    local cx,sx,cy,sy,cz,sz=math.cos(a[1]),math.sin(a[1]),math.cos(a[2]),math.sin(a[2]),math.cos(a[3]),math.sin(a[3])
    local x,y=cz*v[1]-sz*v[2],sz*v[1]+cz*v[2]
    local z=sx*y+cx*v[3];y=cx*y-sx*v[3]
    return {cy*x+sy*z,y,-sy*x+cy*z}
end
for _,entry in ipairs({{idle_stance5,false},{danceHandstandSplit,true}})do
    StartThread(TigLilSetup);drain(1000)
    local start,held,maxSpread,turn,previous=frame,0,0,0,0
    StartThread(entry[1])
    while next(threads)do
        tick();assert(frame-start<30*60,'handstand never completes')
        local body=rotations[pieceIDs.tigLil][1]
        turn=turn+delta(body,previous,true);previous=body
        local spread=math.abs(delta(0,rotations[pieceIDs.tllegUp][2],true))
        maxSpread=math.max(maxSpread,spread)
        if spread>math.rad(89.9) then
            held=held+1
            near(math.abs(delta(0,body,true)),math.pi,.001)
            near(math.abs(delta(0,rotations[pieceIDs.tllegUpR][2],true)),math.pi/2,.002)
            for side,name in ipairs({'tlarm','tlarmr'})do
                local p=rotate({side==1 and 5.1 or -5.1,-.2,.15},name)
                p[1]=p[1]+(side==1 and 1.86521 or -1.49415)
                p[2]=p[2]-.45105;p[3]=p[3]+4.57199
                p=rotate(p,'tigLil')
                near(12+translations[pieceIDs.tigLil][3]/(11060.378906/12)+p[3],0,.002)
            end
        end
    end
    near(turn,-2*math.pi,.001)
    if entry[2] then assert(held>=54,'split not held long enough');near(maxSpread,math.pi/2,.001)
    else assert(held==0 and maxSpread<.001,'original handstand changed')end
    for _,name in ipairs({'tigLil','tlHead','tllegUp','tllegUpR','tllegLow','tllegLowR'})do
        for _,a in ipairs(rotations[pieceIDs[name]])do near(delta(0,a,true),0,.001)end
    end
    for _,v in ipairs(translations[pieceIDs.tigLil] or {0,0,0})do near(v,0,.001)end
end
print('PASS: original handstand preserved; full split held on both palms; legs close, full rotation and neutral recovery')
]=]
assert(loadstring(source))()
