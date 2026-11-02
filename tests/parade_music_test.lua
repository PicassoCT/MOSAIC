-- Run from the game root: lua tests/parade_music_test.lua
local source = 'luaui/widgets_mosaic/snd_music.lua'
local paradeTrack = 'sounds/music/parade/seventh_night_procession.ogg'
local function fixture(config)
    local s = {active=0, played=0, duration=90, starts={}, gains={}, pauseCount=0,
        volume=27, gamePaused=false, raw={}, exists={[paradeTrack]=true}}
    for k,v in pairs(config or {}) do s[k]=v end
    local env = setmetatable({widget={}, WG={}, UnitDefs={}, LOG={ERROR=1}}, {__index=_G})
    env.math = setmetatable({randomseed=function(seed) math.randomseed(math.floor(seed)) end}, {__index=math})
    env.Spring = {
        GetGameFrame=function() return 9000 end,
        GetMyTeamID=function() return 1 end,
        GetSpectatingState=function() return false end,
        IsReplay=function() return false end,
        GetConfigInt=function() return s.volume end,
        SetConfigInt=function(_,v) s.volume=v end,
        SetSoundStreamVolume=function(v) s.gains[#s.gains+1]=v end,
        PlaySoundStream=function(track, gain)
            assert(gain==1, 'music source gain must not apply volume twice')
            s.starts[#s.starts+1]=track; s.played=0; s.duration=90
        end,
        StopSoundStream=function() s.played=0; s.duration=0 end,
        GetSoundStreamTime=function() return s.played,s.duration end,
        GetGameRulesParam=function(name) assert(name=='city_parade_active'); return s.active end,
        GetVisibleUnits=function() return {} end,
        GetGameSpeed=function() return 1,1,s.gamePaused end,
        PauseSoundStream=function() s.pauseCount=s.pauseCount+1 end,
        Echo=function() end,
        Log=function() end,
    }
    env.widgetHandler={RemoveCallIn=function() end}
    env.VFS={RAW_FIRST=1,RAW=2}
    env.VFS.FileExists=function(path,mode)
        if path=='sounds/music/playlist.lua' then return s.playlist~=nil end
        if mode==env.VFS.RAW then return s.raw[path] or false end
        return s.exists[path] or s.raw[path] or false
    end
    env.VFS.Include=function(path) assert(path=='sounds/music/playlist.lua'); return s.playlist end
    env.VFS.DirList=function(dir,_,mode)
        if dir=='sounds/music/parade/' then
            if mode==env.VFS.RAW_FIRST or s.raw[paradeTrack] then return {paradeTrack} end
            return {}
        end
        return {dir..'test.ogg',dir..'second.ogg'}
    end
    assert(loadfile(source,'t',env))()
    env.options.useIncludedTracks.value = s.included ~= false
    env.options.pausemusic.value = s.pauseWithGame or false
    env.widget:Initialize()
    function s.tick() env.widget:Update(1.1) end
    s.env=env
    return s
end

local early=fixture({active=1})
early.env.WG.Music.StopTrack(true); early.tick()
assert(#early.starts==0, 'first update must respect an existing stop request')
local s=fixture()
s.tick()
assert(#s.starts==1 and s.env.WG.Music.GetMusicType()=='peace_day')
s.active=1; s.tick()
assert(#s.starts==2 and s.starts[2]==paradeTrack, 'tour must start dedicated music immediately')
assert(s.gains[#s.gains]==0.27, 'respect persisted music volume')
s.played=40; s.tick()
assert(#s.starts==2, 'do not restart touring music every update')
s.played=s.duration; s.tick()
assert(#s.starts==3 and s.starts[3]==paradeTrack, 'parade playlist must continue through a long tour')
s.active=0; s.tick()
assert(#s.starts==4 and s.env.WG.Music.GetMusicType()=='peace_day', 'end/emergency must restore ambient music immediately')
s.active=1; s.tick()
s.env.WG.Music.StopTrack(true)
local stops=#s.starts
s.tick(); s.tick()
assert(#s.starts==stops, 'explicit stop must not be overridden by parade')
s.env.WG.Music.StartTrack('my_custom.ogg'); s.tick()
assert(s.starts[#s.starts]=='my_custom.ogg', 'custom soundtrack retains ownership')
s.env.WG.Music.StartLoopingTrack('my_intro.ogg','my_loop.ogg'); s.tick()
assert(s.starts[#s.starts]=='my_intro.ogg', 'custom looping intro retains ownership')
s.played=s.duration; s.tick()
assert(s.starts[#s.starts]=='my_loop.ogg', 'custom loop must keep its existing loop behavior')

s=fixture({active=1,volume=0})
s.tick()
assert(#s.starts==1 and s.starts[1]==paradeTrack, 'reload during a parade starts once')
assert(s.gains[#s.gains]==0, 'parade cannot unmute the music channel')
s.env.widget:GameOver()
local endCount=#s.starts
assert(s.starts[endCount]:find('/victory/'))
s.tick()
assert(#s.starts==endCount, 'victory/defeat music cannot be replaced by an active parade')

s=fixture({active=1,included=false})
s.tick()
assert(s.env.WG.Music.GetMusicType()~='parade', 'disabled included tracks must remain disabled')
s=fixture({active=1,included=false,raw={[paradeTrack]=true}})
s.tick()
assert(s.starts[#s.starts]==paradeTrack, 'raw user parade tracks still work with included tracks disabled')
s=fixture({active=1,playlist={parade={}}})
s.tick()
assert(s.env.WG.Music.GetMusicType()~='parade', 'an explicit empty parade playlist opts out')
s=fixture({active=1,playlist={parade={'missing.ogg'}}})
s.tick()
assert(s.env.WG.Music.GetMusicType()~='parade', 'missing custom tracks must not stop normal music')

s=fixture({active=1,playlist={parade={paradeTrack,'local_parade.ogg'}},raw={['local_parade.ogg']=true}})
s.tick()
s.env.options.useIncludedTracks.value=false
s.played=s.duration; s.tick()
assert(s.starts[#s.starts]=='local_parade.ogg', 'raw playlist must not choose a disabled included file')

s=fixture({pauseWithGame=true})
s.tick()
s.gamePaused=true; s.tick()
assert(s.pauseCount==1)
s.active=1; s.tick()
assert(s.pauseCount==2, 'replacement music must stay paused with the game')
s.gamePaused=false; s.tick()
assert(s.pauseCount==3, 'music resumes once when the game resumes')

local effects=dofile('gamedata/explosions/parade.lua')
local count=0
for name,effect in pairs(effects) do
    local budget=0
    for _,emitter in pairs(effect) do
        local p=emitter.properties
        assert(not p.alwaysvisible and not p.useairlos, name..' leaked outside ground LOS')
        assert(p.gravity:find('%-0%.05'), name..' must fall toward the parade')
        assert(p.particlelife+p.particlelifespread<=270, name..' particles outlive budget')
        budget=budget+emitter.count*p.numparticles
        local f=assert(io.open('bitmaps/ProjectileTextures/'..p.texture..'.png','rb'), 'missing parade sprite')
        f:close()
    end
    assert(budget<=18, name..' exceeds particle budget')
    count=count+1
end
assert(count==4, 'all four requested shower effects are required')
print('PASS: parade music lifecycle, custom/stop ownership, raw playlists, volume/mute, pause, game over, and bounded LOS-respecting shower effects')
