local F=dofile('tests/kinetic_text_fixture.lua')
for _,scale in ipairs({.0254,.1,1})do for _,heading in ipairs({0,math.pi/2,math.pi})do
for _,speed in ipairs({1,3})do for _,upright in ipairs({false,true})do
    local falling,held,dripping={},{},{}
    math.randomseed(11)
    F.run('rainOnGlassText',{scale=scale,heading=heading,speed=speed,upright=upright},function(s,f)
        if s.phase=='rain: collecting on glass' and s.points[7] then falling[#falling+1]=s.points[7]end
        if s.phase=='rain: readable on glass' then
            held=s.points
            for _,p in pairs(held)do F.near(p.angle,0)end
        end
        if s.phase=='rain: dripping away' then
            if s.points[7]then dripping[#dripping+1]=s.points[7]end
            for _,p in pairs(s.points)do
                assert(p.y-f.height*.5>Spring.GetGroundHeight(p.world[1],p.world[3]),'drip crossed terrain')
            end
            if s.phaseTime==3200 then assert(not next(s.points),'drips did not disappear')end
        end
    end)
    assert(#falling>20 and #dripping>5 and held[7])
    assert(falling[1].y>held[7].y+F.height*2,'no falling rain')
    assert(math.abs(falling[1].x-held[7].x)>F.step*.01,'no sideways slide into cell')
    F.near(falling[#falling].y,held[7].y);F.near(falling[#falling].x,held[7].x)
    F.near(held[7].y,held[6].y);F.near(held[7].x-held[6].x,F.step)
    assert(dripping[#dripping].y<dripping[1].y,'letters did not drip downward')
    F.near(F.time*speed,F.logicalTime)
end end end end
for _,mode in ipairs({'missing','tilted'})do F.run('rainOnGlassText',{mode=mode})end
for _,phrase in ipairs({'','A','A A A','ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'})do F.run('rainOnGlassText',{phrase=phrase})end
print('PASS: rain fall, sideways glass slide, readable rows, gravity/drip clearance, transforms/speed and cleanup')
