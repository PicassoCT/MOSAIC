
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

Spring.SetSoundStreamVolume(0)
local musicfiles = VFS.DirList("sounds/Intro", "*.ogg")
if (#musicfiles > 0) then
	index=math.random(1,#musicfiles)
	Spring.PlaySoundStream(musicfiles[ index ], 1)
	Spring.SetSoundStreamVolume(1)
end


function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()

end


function addon.Shutdown()
	Spring.StopSoundStream()
	Spring.SetSoundStreamVolume(1)
end
