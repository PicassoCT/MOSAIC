
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

Spring.SetSoundStreamVolume(1)


local musicfiles = VFS.DirList("sounds/music/briefing/", "*.ogg")
local function playMusicFile()
	if (#musicfiles > 0) then
		index=math.random(1,#musicfiles)
		Spring.PlaySoundStream(musicfiles[ index ], 1)
		Spring.SetSoundStreamVolume(1)
	end
end

local advertisementFiles = VFS.DirList("sounds/advertising/", "*.ogg")
local function playAdvertisementFile()
	if (#advertisementFiles > 0) then
		index=math.random(1,#advertisementFiles)
		Spring.PlaySoundStream(advertisementFiles[ index ], 1)
	end
end

local nextProgressStep = 0

function addon.Initialize()

end

function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()
	if loadProgress > nextProgressStep then
		nextProgressStep = nextProgressStep + 0.30
		playMusicFile()
		playAdvertisementFile()
	end
end


function addon.Shutdown()
	Spring.StopSoundStream()
	Spring.SetSoundStreamVolume(1)
end
