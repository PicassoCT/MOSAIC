local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local shared={'greetPasserby','embracePasserby','kissPasserby'}
for _,file in ipairs({'house_western_hologram_script.lua','house_western_brothel_hologram_script.lua'})do
    local code=read('scripts/'..file)
    assert(code:find('tigLilAnimations.enablePeopleAnimations()',1,true))
    for _,name in ipairs(shared)do assert(code:find('idleAnimations[#idleAnimations +1] = '..name..'\n',1,true))end
end
local brothel=read('scripts/house_western_brothel_hologram_script.lua')
assert(brothel:find('idleAnimations[#idleAnimations +1] = invitePasserby\n',1,true))
local normal=read('scripts/house_western_hologram_script.lua')
assert(not normal:find('invitePasserby',1,true),'seductress invitation leaks into ordinary advertising')
assert(normal:find('businessPresentations[animation] = true',1,true),'personal interactions inherit glow sticks')
local blimp=read('scripts/advertisingblimphologramscript.lua')
for _,name in ipairs({'greetPasserby','embracePasserby','kissPasserby','invitePasserby','enablePeopleAnimations'})do
    assert(not blimp:find(name,1,true),'blimp enables personalized interaction: '..name)
end
local player=dofile('scripts/lib_tiglil_dance.lua')
local styles=dofile('scripts/lib_tiglil_social.lua')
for name,style in pairs(styles)do
    local poses,finished,time=0,false,0
    player.play(name,{
        turn=function(id,a,ms)assert(ms>=100 and ms<=1600);for i=1,3 do assert(math.abs(a[i])<=90)end end,
        move=function(id,a)assert(id=='tigLil' and math.abs(a[1])<1 and math.abs(a[3])<1);poses=poses+1 end,
        sleep=function(ms)time=time+ms end,
        finish=function()finished=true end,
    },style)
    assert(finished and time>6000 and time<15000 and poses==#style.frames+2)
    local held=0;for _,p in ipairs(style.frames)do if p.hold>0 then held=held+1 end end
    assert(held>=1,'social routine does not pause for its gesture')
end
assert(styles.embrace.distance>styles.kiss.distance,'close interactions have no distinct staging')
print('PASS: shared building interactions, brothel-only invitation, blimp exclusion and bounded social choreography')
