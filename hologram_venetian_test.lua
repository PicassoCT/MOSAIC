local F=dofile('tests/kinetic_text_fixture.lua')
for _,scale in ipairs({.0254,.1,1})do for _,heading in ipairs({0,math.pi/2,math.pi})do
for _,speed in ipairs({1,3})do for _,upright in ipairs({false,true})do
    local centres,opened,waved,closed,staggered={},false,false,false,false
    F.run('venetianBlindsText',{scale=scale,heading=heading,speed=speed,upright=upright,phrase='ABCDEFGHIJKLMNO'},function(s,f)
        for id,p in pairs(s.points)do
            local first=centres[id] or p;centres[id]=first
            F.near(p.x,first.x);F.near(p.y,first.y);F.near(p.z,first.z)
            assert(p.angle>=-1e-7 and p.angle<=math.pi/2+1e-7)
            local leader=math.floor((id-1)/5)*5+1
            if s.points[leader]then F.near(p.angle,s.points[leader].angle)end
            if s.phase=='venetian: open' then F.near(p.angle,0);opened=true end
            if s.phase=='venetian: flip wave' and p.angle>1.5 then waved=true end
        end
        if s.phase=='venetian: opening slats' and s.points[1] and s.points[11] then
            staggered=staggered or s.points[1].angle<s.points[11].angle
        end
        if s.phase=='venetian: closing slats' and not next(s.points)then closed=true end
    end)
    assert(opened and waved and closed and staggered,'missing readable hold, flip wave, stagger or closure')
    F.near(F.time*speed,F.logicalTime)
end end end end
for _,mode in ipairs({'missing','tilted'})do F.run('venetianBlindsText',{mode=mode})end
for _,phrase in ipairs({'','A','A A A','ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'})do F.run('venetianBlindsText',{phrase=phrase})end
print('PASS: Venetian row hinges, fixed centres, staggered reveal/wave/close, transforms/speed and cleanup')
