
if addon.InGetInfo then
	return {
		name    = "Music",
		desc    = "plays music",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------

local function playMusicStream(track)
	Spring.PlaySoundStream(track, 1)
	Spring.SetSoundStreamVolume(math.max(0, math.min(100,
		Spring.GetConfigInt("snd_volmusic", 20))) / 100)
end


local musicfiles = VFS.DirList("sounds/music/briefing/", "*.ogg")
local function playMusicFile()
	if (#musicfiles > 0) then
		index=math.random(1,#musicfiles)
		playMusicStream(musicfiles[ index ])
	end
end

local advertisementFiles = VFS.DirList("sounds/advertising/", "*.ogg")
local function playAdvertisementFile()
	if (#advertisementFiles > 0) then
		index=math.random(1,#advertisementFiles)
		playMusicStream(advertisementFiles[ index ])
	end
end

local nextProgressStep = 0

function addon.Initialize()

end

function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()
	if nextProgressStep == 0 then
		nextProgressStep = nextProgressStep + 0.35
		playMusicFile()
		return
	end
--[[	if loadProgress > nextProgressStep then
		nextProgressStep = nextProgressStep + 0.35
		playAdvertisementFile()
	end--]]
end


function addon.Shutdown()
	Spring.StopSoundStream()
end

