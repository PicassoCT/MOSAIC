local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local source=read('scripts/house_western_brothel_hologram_script.lua')
for _,name in ipairs({'idle_stance','idle_stance2','idle_stance13','idle_stance15','idle_stance18','dancePole',
    'danceBurlesqueSway','danceBurlesqueWave','danceBurlesqueFan','lingerBrothel','danceBehindGlass'})do
    assert(source:find('idleAnimations[#idleAnimations +1] = '..name..'\n',1,true),'brothel omits '..name)
end
for _,file in ipairs({'house_western_hologram_script.lua','advertisingblimphologramscript.lua'})do
    local code=read('scripts/'..file)
    assert(not code:find('danceBehindGlass',1,true),'glass placeholder leaks into '..file)
    assert(not code:find('danceBurlesque',1,true),'brothel additions leak into '..file)
end
local styles=dofile('scripts/lib_tiglil_brothel.lua')
styles.behindGlass=dofile('scripts/lib_tiglil_glass.lua')
local player=dofile('scripts/lib_tiglil_dance.lua')
local signatures={}
for name,style in pairs(styles)do
    local time,finished,moves=0,false,0
    local last,signature={},{}
    player.play(name,{
        turn=function(id,a,ms)
            assert(ms>=100 and ms<=((id=='deathpivot' or name=='behindGlass') and 2000 or 1000))
            for i=1,3 do assert(math.abs(a[i])<=90,'burlesque pose exceeds intended range')end
            last[id]=a
            if id=='tigLil' then signature[#signature+1]=table.concat(a,',')end
        end,
        move=function(id,a)
            assert(id=='tigLil' and math.abs(a[1])<1 and math.abs(a[3])<=1)
            assert(a[2]>-3 and a[2]<1);moves=moves+1
        end,
        sleep=function(ms)time=time+ms end,
        finish=function()finished=true end,
    },style)
    assert(finished and time>=12000 and time<(name=='linger' and 35000 or 30000))
    assert(moves==#style.frames*#style.headings+2)
    for _,id in ipairs({'tigLil','tlHead','tllegUp','tllegUpR','tllegLow','tllegLowR','deathpivot'})do
        for i=1,3 do assert(last[id][i]==0,'pose leaks into next routine')end
    end
    if name=='linger' then
        local poses={}
        assert(#style.frames==10,'lingering needs ten distinct poses')
        for _,p in ipairs(style.frames)do
            assert(p.cue and not poses[p.cue]);poses[p.cue]=true
            assert(style.beat*p.beats*p.hold>=2000,'lingering hold is rushed')
        end
    end
    local key=table.concat(signature,';');assert(not signatures[key]);signatures[key]=true
end
print('PASS: original suggestive routines retained; five distinct bounded new routines including ten lingering poses exclusive to brothel')
