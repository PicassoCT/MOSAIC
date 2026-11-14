local F=dofile('tests/kinetic_text_fixture.lua')
for _,scale in ipairs({.0254,.1,1})do for _,heading in ipairs({0,math.pi/2,math.pi})do
for _,speed in ipairs({1,3})do for _,upright in ipairs({false,true})do
    local radii,orbits,peeling,assembled={}, {}, {}, {}
    F.run('orbitTransferText',{scale=scale,heading=heading,speed=speed,upright=upright,phrase='AB CDEFGHIJKLMNO'},function(s,f)
        if s.phase=='orbit transfer: orbiting civilian 800' then
            local tx,_,tz=unpack(f.target)
            for id,p in pairs(s.points)do
                local radius=math.sqrt((p.world[1]-tx)^2+(p.world[3]-tz)^2)
                radii[id]=radii[id] or radius;F.near(radius,radii[id])
                assert(radius>6+f.height,'orbit intersects pedestrian')
                assert(p.y-f.height*.5>Spring.GetGroundHeight(p.world[1],p.world[3]))
                F.near(p.angle,0)
            end
            orbits[#orbits+1]=s.points[1].world
        elseif s.phase=='orbit transfer: peeling into the phrase' then
            peeling[#peeling+1]=s
        elseif s.phase=='orbit transfer: assembled' then assembled=s.points end
    end)
    assert(#orbits==56 and #peeling>40 and assembled[1])
    assert(math.abs(orbits[1][1]-orbits[14][1])>scale*100,'letters did not circle')
    F.near(assembled[3].x-assembled[2].x,2*F.step)
    F.near(assembled[12].y-assembled[1].y,-F.height*1.35)
    -- First letter arrives while later letters are still in transit.
    local middle=peeling[30].points
    F.near(middle[1].x,assembled[1].x);F.near(middle[1].y,assembled[1].y)
    assert(math.abs(middle[14].y-assembled[14].y)>F.height*.1,'letters did not peel off in order')
    for id,p in pairs(peeling[#peeling].points)do F.near(p.x,assembled[id].x);F.near(p.y,assembled[id].y)end
    assert(F.logicalTime<11000);F.near(F.time*speed,F.logicalTime)
end end end end
for _,target in ipairs({'dead','invalid','transported','departed','missing'})do
    F.run('orbitTransferText',{targetMode=target})
    assert(F.phase=='orbit transfer: stopped; pedestrian left' and F.logicalTime<4700,'lost target did not abort cleanly')
end
F.run('orbitTransferText',{targetMode='absent',skipTarget=true})
assert(F.phase=='orbit transfer: skipped; no nearby civilian' and F.logicalTime==0)
for _,mode in ipairs({'missing','tilted'})do F.run('orbitTransferText',{mode=mode})end
for _,phrase in ipairs({'','A','A A A','ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'})do F.run('orbitTransferText',{phrase=phrase})end
print('PASS: orbit follows moving civilian, radial clearance, ordered peel/arrival, lifecycle exits, scaled/rotated layouts and speed')
