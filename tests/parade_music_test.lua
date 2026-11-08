-- Run from the game root: lua tests/parade_music_test.lua
local source = 'luaui/widgets_mosaic/snd_music.lua'
local paradeTrack = 'sounds/music/parade/seventh_night_procession1.ogg'
local function fixture(config)
    local s = {active=0, played=0, duration=90, starts={}, gains={}, pauseCount=0,
        volume=27, gamePaused=false, camera={0,124,0}, carriers={20}, positions={[20]={0,0,0}}, los=true, raw={}, exists={[paradeTrack]=true}}
    for k,v in pairs(config or {}) do s[k]=v end
    local env = setmetatable({widget={}, WG={}, UnitDefs={}, LOG={ERROR=1}}, {__index=_G})
    env.math = setmetatable({randomseed=function(seed) math.randomseed(math.floor(seed)) end,
        random=function(a,b) return s.pick or math.random(a,b) end}, {__index=math})
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
        GetCameraPosition=function() return table.unpack(s.camera) end,
        GetUnitsInSphere=function() s.spatialReads=(s.spatialReads or 0)+1;return s.carriers end,
        GetMyAllyTeamID=function() return 0 end,
        GetUnitRulesParam=function(id,key) assert(key=='city_parade_vehicle');return s.inactive and 0 or 1 end,
        GetUnitIsDead=function() return s.dead or false end,
        GetUnitNoDraw=function() return s.hidden or false end,
        GetUnitIsCloaked=function() return s.cloaked or false end,
        GetUnitLosState=function() return {los=s.los} end,
        GetUnitViewPosition=function(id) return table.unpack(s.positions[id]) end,
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
            if mode==env.VFS.RAW_FIRST or s.raw[paradeTrack] then return s.tracks or {paradeTrack} end
            return {}
        end
        return {dir..'test.ogg',dir..'second.ogg'}
    end
    assert(loadfile(source,'t',env))()
    env.options.useIncludedTracks.value = s.included ~= false
    env.options.pausemusic.value = s.pauseWithGame or false
    env.widget:Initialize()
    function s.tick(dt) env.widget:Update(dt or 1.1) end
    s.env=env
    return s
end

local early=fixture({active=1})
early.env.WG.Music.StopTrack(true); early.tick()
assert(#early.starts==0, 'first update must respect an existing stop request')
local s=fixture()
s.tick()
assert(#s.starts==1 and s.env.WG.Music.GetMusicType()=='peace_day')
s.played=40
s.active=1; s.tick(0.016)
assert(s.played==0, 'parade starts at the beginning of the selected song')
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

-- Each procession owns one song, even when more tracks are supplied later.
local second='sounds/music/parade/another_procession.ogg'
s=fixture({tracks={paradeTrack,second},exists={[paradeTrack]=true,[second]=true},pick=1})
s.tick();s.active=1;s.tick(0.016)
assert(s.starts[#s.starts]==paradeTrack)
s.pick=2;s.played=s.duration;s.tick(0.04)
assert(s.starts[#s.starts]==paradeTrack,'long procession switched to another song')
s.active=0;s.tick(0.016);s.active=1;s.tick(0.016)
assert(s.starts[#s.starts]==second,'new procession did not choose anew')
-- Refresh directory discovery at the next start, without reloading the widget.
s=fixture({tracks={paradeTrack},pick=1});s.tick()
s.tracks={second};s.exists[paradeTrack]=nil;s.exists[second]=true
s.active=1;s.tick(0.016)
assert(s.starts[#s.starts]==second,'replacement track was not discovered at parade start')
s=fixture({pauseWithGame=true,gamePaused=true});s.tick()
local pauses=s.pauseCount
s.active=1;s.tick(0.016)
assert(s.pauseCount==pauses+1,'immediate start briefly unpaused the score')

-- Distance fading follows the moving convoy and camera height without
-- restarting the song or changing the persisted music-volume preference.
s=fixture({active=1});s.tick();s.played=35
local starts=#s.starts
s.camera={0,724,0};s.tick(0.11)
assert(math.abs(s.gains[#s.gains]-.27*.5)<1e-6,'height does not attenuate the parade')
s.camera={0,2024,0};s.tick(0.11)
assert(s.gains[#s.gains]==0,'zoomed-out camera still hears parade')
s.env.WG.Music.SetMusicVolume(60)
assert(s.volume==60 and s.gains[#s.gains]==0,'volume slider bypassed distance fade')
s.camera={0,124,0};s.tick(0.11)
assert(s.gains[#s.gains]==.6 and #s.starts==starts and s.played==35,'zooming in restarted the song')
s.positions[20]={2000,0,0};s.tick(0.11)
assert(s.gains[#s.gains]==0,'sound did not follow the departing truck')
s.carriers={20,21};s.positions[21]={0,0,0};s.tick(0.11)
assert(s.gains[#s.gains]==.6,'nearest truck did not carry the score')
s.positions[20]={0,0,0};s.tick(0.11)
assert(s.gains[#s.gains]==.6,'multiple trucks amplified the score')
for _,flag in ipairs({'hidden','cloaked','dead','inactive'}) do
 s[flag]=true;s.tick(0.11);assert(s.gains[#s.gains]==0,flag..' carrier leaked music');s[flag]=false
end
s.los=false;s.tick(0.11);assert(s.gains[#s.gains]==0,'unseen procession leaked music')
s.los=true;s.tick(0.11)
local reads=s.spatialReads;s.tick(0.016);s.tick(0.016)
assert(s.spatialReads==reads,'spatial query ran every render frame')
s.camera={0,2024,0};s.tick(0.11);s.active=0;s.tick(0.016)
assert(s.gains[#s.gains]==.6,'parade fade leaked into ambient music')
s=fixture({active=1,camera={0,2024,0}});s.tick(0.016)
for _,gain in ipairs(s.gains) do assert(gain==0,'distant parade began with a loud burst') end
s.env.widget:Shutdown()
assert(s.gains[#s.gains]==.27,'shutdown left the shared music channel attenuated')

local effects=dofile('gamedata/explosions/parade.lua')
local count=0
for name,effect in pairs(effects) do
    local budget=0
    for _,emitter in pairs(effect) do
        local p=emitter.properties
        assert(not p.alwaysvisible and not p.useairlos, name..' leaked outside ground LOS')
        assert(p.gravity:find('%-0%.05') or (name=='parade_petals' and p.gravity=='dir'), name..' must fall toward the parade')
        assert(p.particlelife+p.particlelifespread<=(name=="parade_petals" and 405 or 270), name..' particles outlive budget')
        budget=budget+emitter.count*p.numparticles
        local f=assert(io.open('bitmaps/ProjectileTextures/'..p.texture..'.png','rb'), 'missing parade sprite')
        f:close()
    end
    assert(budget<=18, name..' exceeds particle budget')
    count=count+1
end
assert(count==4, 'all four requested shower effects are required')
print('PASS: parade music lifecycle, custom/stop ownership, raw playlists, volume/mute, pause, game over, and bounded LOS-respecting shower effects')
