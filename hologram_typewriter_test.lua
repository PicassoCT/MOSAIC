local F=dofile('tests/kinetic_text_fixture.lua')
for _,scale in ipairs({.0254,.1,1})do for _,heading in ipairs({0,math.pi/2,math.pi})do
for _,speed in ipairs({1,3})do for _,upright in ipairs({false,true})do
    local strikes,printed,returns,feed={},{},{},false
    F.run('typewriterText',{scale=scale,heading=heading,speed=speed,upright=upright,phrase='AB CDEFGHIJKLMNOPQR'},function(s,f)
        local slot=tonumber(s.phase:match('typing slot (%d+)'))
        if slot then
            for id,p in pairs(s.points)do
                assert(f.leases[id][1]<=slot,'a future character appeared before its keystroke')
                if f.leases[id][1]==slot then
                    strikes[slot]=strikes[slot] or {};table.insert(strikes[slot],p)
                end
            end
        elseif s.phase=='typewriter: printed' then printed=s.points
        elseif s.phase=='typewriter: carriage return' and s.points[1] then returns[#returns+1]=s.points[1].x
        elseif s.phase=='typewriter: feeding out' and not next(s.points) then feed=true end
    end)
    for slot,points in pairs(strikes)do
        assert(points[1].z>points[2].z and points[2].z<points[#points].z,'missing strike or recoil')
        F.near(points[#points].z,printed[1].z)
        assert(#points==4,'keystroke timing changed')
    end
    assert(not strikes[3],'space became a character')
    assert(#returns==7 and returns[#returns]>returns[1],'carriage did not return')
    F.near(printed[3].x-printed[2].x,F.step*2)
    F.near(printed[12].y-printed[1].y,-F.height*1.35)
    assert(feed and F.logicalTime<10000)
    F.near(F.time*speed,F.logicalTime)
end end end end
-- Repeated strikes must take the shared mesh immediately, without showing
-- a later occurrence before its turn; all occurrences reappear in the hold.
local seen={}
F.run('typewriterText',{phrase='A A A'},function(s,f)
    if s.phase=='typewriter: printed' then for _,p in pairs(s.points)do seen[math.floor(p.x/f.step+.5)]=true end end
end)
local count=0;for _ in pairs(seen)do count=count+1 end;assert(count==3)
for _,mode in ipairs({'missing','tilted'})do F.run('typewriterText',{mode=mode})end
for _,phrase in ipairs({'','A','ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'})do F.run('typewriterText',{phrase=phrase})end
print('PASS: typewriter ordered strikes/recoil, spaces, carriage return, multiline page, shared glyphs, speed and cleanup')
