local F=dofile('tests/kinetic_text_fixture.lua')
for _,scale in ipairs({.0254,.1,1})do for _,heading in ipairs({0,math.pi/2,math.pi})do
for _,speed in ipairs({1,3})do for _,upright in ipairs({false,true})do
    local holds,arrival,depart,seen={}, {}, {}, {}
    F.run('trainArrivalText',{scale=scale,heading=heading,speed=speed,upright=upright},function(s,f)
        local phase=s.phase
        if phase=='train: at the platform' then
            for id,p in pairs(s.points)do
                local key=math.floor(p.x/f.step+.5)
                seen[id..':'..key]=true
                if not holds[id] or p.x<holds[id].x then holds[id]=p end
                F.near(p.angle,0)
            end
        elseif phase=='train: arriving and braking' then
            if s.points[7] then arrival[#arrival+1]={s.phaseTime,s.points[7].x}end
        elseif phase=='train: departing' then
            if s.points[7] then depart[#depart+1]={s.phaseTime,s.points[7].x}end
        end
    end)
    assert(#arrival>20 and #depart>20)
    -- Unique G carriage moves right, brakes, holds, then accelerates away.
    local a,b,c=arrival[2],arrival[3],arrival[4]
    assert(b[2]>a[2] and c[2]-b[2]<b[2]-a[2],'arrival did not brake')
    local n=#depart
    assert(depart[n][2]-depart[n-1][2]>depart[n-1][2]-depart[n-2][2],'departure did not accelerate')
    F.near(holds[7].x-holds[6].x,F.step)
    F.near(holds[3].x-holds[2].x,2*F.step) -- blank slot retained
    local occurrences=0;for key in pairs(seen)do if key:match('^1:')then occurrences=occurrences+1 end end
    assert(occurrences==2,'repeated A lost one carriage')
    assert(F.logicalTime>7000 and F.logicalTime<11000)
    F.near(F.time*speed,F.logicalTime)
end end end end
for _,mode in ipairs({'missing','tilted'})do F.run('trainArrivalText',{mode=mode})end
for _,phrase in ipairs({'','A','A A A','ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ'})do F.run('trainArrivalText',{phrase=phrase})end
print('PASS: train braking, readable word gaps and repeated carriages, accelerated departure, scale/heading/speed/layout and cleanup')
