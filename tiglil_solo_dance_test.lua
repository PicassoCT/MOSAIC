-- Beat ownership, solo silhouettes and grounding inputs; native completion is
-- covered separately by the real float32 scheduler in tiglil_precision_test.
local dance=dofile('scripts/lib_tiglil_dance.lua')
local random=math.random
local signatures={}
for _,sign in ipairs({0,1}) do
    math.random=function(a,b)assert(a==0 and b==1);return sign end
    for name,style in pairs(dance.styles) do
        local time,finished,poses,held,headings=0,false,0,0,{}
        local rotation,position={},{}
        local signature={}
        dance.play(name,{
            turn=function(id,a,ms)
                assert(ms>=100 and ms<=(id=='deathpivot' and 6000 or 1000),'dance must use readable, bounded transitions')
                assert(#a>=3)
                for i=1,3 do assert(a[i]==a[i] and math.abs(a[i])<=(id=='deathpivot' and 360 or 90),'uncontrolled spin or inverted solo pose')end
                rotation[id]={a[1],a[2],a[3]}
                if id=='deathpivot' then headings[#headings+1]=a[2] end
                if id=='tigLil' then poses=poses+1;signature[#signature+1]=table.concat(a,',')end
            end,
            move=function(id,a,ms)
                assert(id=='tigLil','limb translations detach the skeleton')
                assert(math.abs(a[1])<1 and math.abs(a[3])<=1,'solo dance drifts off its stage')
                assert(a[2]>-3 and a[2]<1,'body dip exceeds the leg proportions')
                position=a
            end,
            sleep=function(ms)time=time+ms;assert(rotation.tlarm and rotation.tlarmr)end,
            finish=function()finished=true end,
        })
        assert(finished and time>10000 and time<30000,'dance did not complete its bounded musical phrases')
        assert(poses==#style.headings*#style.frames+2)
        assert(headings[1]==0 and headings[#headings]==0,'parent heading leaks into next routine')
        for _,id in ipairs({'tigLil','tlHead','tllegUp','tllegUpR','tllegLow','tllegLowR'})do
            for _,v in ipairs(rotation[id])do assert(v==0,'dance did not return to neutral: '..id)end
        end
        assert(position[1]==0 and position[3]==0)
        if sign==1 then
            local key=table.concat(signature,';');assert(not signatures[key],'styles have identical body choreography');signatures[key]=name
        end
        for _,p in ipairs(style.frames)do if p.hold>0 then held=held+1 end end
        if name=='joi' then assert(#style.frames==16 and style.turnBeats==8,'Joi lost its full phrase or slow turns')end
        if name=='popping' then assert(held==#style.frames,'popping lost its accented holds')end
    end
end
math.random=random
for _,file in ipairs({'house_western_hologram_script.lua','house_western_brothel_hologram_script.lua','advertisingblimphologramscript.lua'})do
    local f=assert(io.open('scripts/'..file));local source=f:read('*a');f:close()
    for _,name in ipairs({'danceShuffle','danceDisco','dancePopping','danceJoi'})do
        assert(source:find('idleAnimations[#idleAnimations +1] = '..name,1,true),file..' omits '..name)
    end
end
print('PASS: distinct solo styles, mirrored phrases, bounded beats/poses, attached limbs, neutral exits and production registration')
