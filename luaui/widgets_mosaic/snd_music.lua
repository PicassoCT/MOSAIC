--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	file:		gui_music.lua
--	brief:	yay music
--	author:	cake
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name	= "Music Player",
		desc	= "Plays music based on situation",
		author	= "cake, trepan, Smoth, Licho, xponen",
		date	= "Mar 01, 2008, Aug 20 2009, Nov 23 2011",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled	= true	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Audio'
options = {
	useIncludedTracks = {
		name = "Use Included Tracks",
		type = 'bool',
		value = true,
		desc = 'Use the tracks included with MOSAIC',
		noHotkey = true,
	},
	pausemusic = {
		name = 'Pause Music',
		type = 'bool',
		value = false,
		desc = "Music pauses with game",
		noHotkey = true,
	},
}


local windows = {}

local warThreshold = 5000
local peaceThreshold = 1000
local PLAYLIST_FILE = 'sounds/music/playlist.lua'
local LOOP_BUFFER = 0.015	-- if looping track is this close to the end, go ahead and loop
local UPDATE_PERIOD = 1

local musicType = 'peace'
local dethklok = {} -- keeps track of the number of doods killed in each time frame
local timeframetimer = 0
local timeframetimer_short = 0
local loopTrack = ''
local previousTrack = ''
local previousTrackType = ''
local newTrackWait = 1000
local numVisibleEnemy = 0
local fadeVol
local curTrack	= "no name"
local songText	= "no name"
local haltMusic = false
local looping = false
local paused = false
local lastTrackTime = -1
local streamRestarted = false
local ambientMusicType = 'peace'
local paradeTrack
local paradeWasActive = false
local explicitParadePlaylist = false
local paradeAudibility = 0
local musicVolumeTimer = 0
local PARADE_FULL_VOLUME_DISTANCE = 200
local PARADE_SILENT_DISTANCE = 1200

local warTracks, peaceDayTracks, peaceNightTracks, briefingTracks, victoryTracks, defeatTracks, paradeTracks

local firstTime = false
local wasPaused = false
local firstFade = true
local initSeed = 0
local initialized = false
local gameStarted = Spring.GetGameFrame() > 0
local gameOver = false

local myTeam = Spring.GetMyTeamID()
local isSpec = Spring.GetSpectatingState() or Spring.IsReplay()
local defeat = false
unitExceptions ={}
local unitExceptionsNames ={}
unitExceptionsNames["air_parachut"] = true

for defId, data in pairs(UnitDefs) do
	if unitExceptionsNames[data.name] then
		unitExceptions[defId] = data.name
	end	
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetMusicType()
	return musicType
end


local function getDayTime()
    local DAYLENGTH =28800
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent --= getDayTime()
end

local function isNight()
   	local hours, minutes, seconds, percent = getDayTime()			
	return hours > 19 or hours < 6
end


-- F10 and playback share the persisted 0-100 music-channel setting.
local function GetMusicVolume()
	return math.max(0, math.min(100, Spring.GetConfigInt("snd_volmusic", 20)))
end

-- Streams have no positional API. Keep one synchronized song and measure
-- the camera's 3D distance to the nearest visible, active carrier instead.
local function ParadeDistanceGain()
	local cx, cy, cz = Spring.GetCameraPosition()
	local _, fullView = Spring.GetSpectatingState()
	local allyTeam = Spring.GetMyAllyTeamID()
	local nearest = PARADE_SILENT_DISTANCE
	for _, id in ipairs(Spring.GetUnitsInSphere(cx, cy, cz, PARADE_SILENT_DISTANCE + 30) or {}) do
		if Spring.GetUnitRulesParam(id, 'city_parade_vehicle') == 1
			and not Spring.GetUnitIsDead(id) and not Spring.GetUnitNoDraw(id)
			and not Spring.GetUnitIsCloaked(id) then
			local los = fullView or Spring.GetUnitLosState(id, allyTeam)
			if fullView or (los and los.los) then
				local x, y, z = Spring.GetUnitViewPosition(id)
				if x then
					local dx, dy, dz = cx-x, cy-(y+24), cz-z
					nearest = math.min(nearest, math.sqrt(dx*dx + dy*dy + dz*dz))
				end
			end
		end
	end
	local t = math.max(0, math.min(1, (nearest-PARADE_FULL_VOLUME_DISTANCE)
		/ (PARADE_SILENT_DISTANCE-PARADE_FULL_VOLUME_DISTANCE)))
	return 1-t*t*(3-2*t)
end

local function ApplyMusicVolume(refreshParade)
	if musicType == 'parade' and refreshParade then paradeAudibility = ParadeDistanceGain() end
	local gain = musicType == 'parade' and paradeAudibility or 1
	Spring.SetSoundStreamVolume(GetMusicVolume() / 100 * gain)
end

local function SetMusicVolume(value)
	value = tonumber(value)
	if not value or value ~= value then return end
	value = math.floor(math.max(0, math.min(100, value)) + 0.5)
	Spring.SetConfigInt("snd_volmusic", value)
	ApplyMusicVolume(true)
end

local function PlayMusicStream(track)
	-- Keep source gain at unity: the channel applies the user's volume once.
	-- Older engines bypass channel gain on start, so reapply it after playback.
	ApplyMusicVolume(true) -- silence a distant parade before the stream starts
	Spring.PlaySoundStream(track, 1)
	ApplyMusicVolume(false)
	streamRestarted = true
end

local function GetAvailableParadeTracks()
	local available = {}
	local mode = options.useIncludedTracks.value and VFS.RAW_FIRST or VFS.RAW
	for _, track in ipairs(paradeTracks or {}) do
		if VFS.FileExists(track, mode) then available[#available + 1] = track end
	end
	return available
end

local function StartLoopingTrack(trackInit, trackLoop)
	if not (VFS.FileExists(trackInit) and VFS.FileExists(trackLoop)) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Missing one or both tracks for looping")
	end
	haltMusic = true
	Spring.StopSoundStream()
	musicType = 'custom'
	
	curTrack = trackInit
	loopTrack = trackLoop
	PlayMusicStream(trackInit)
	looping = 0.5
end



local function StartTrack(track)
	if not peaceDayTracks then
		Spring.Echo("Missing peaceDayTracks file, no music started")
		return
	end

	haltMusic = false
	looping = false
	Spring.StopSoundStream()
	
	local newTrack = previousTrack
	if musicType == 'custom' then
		previousTrackType = "peace_night"
		musicType = "peace_night"
	end
	if track then
		newTrack = track	-- play specified track
		musicType = 'custom'
	elseif musicType == 'parade' and gameStarted then
		local available = GetAvailableParadeTracks()
		if #available == 0 then return end
		local retained = false
		for _, candidate in ipairs(available) do
			if candidate == paradeTrack then retained = true; break end
		end
		if not retained then paradeTrack = available[math.random(1, #available)] end
		newTrack = paradeTrack
	else
		local tries = 0
		repeat
			if (not gameStarted) then
				if (#briefingTracks == 0) then return end
				newTrack = briefingTracks[ #briefingTracks -math.random(1, #briefingTracks-1)]
				musicType = "briefing"
			elseif musicType == 'peace_day' then
				if (#peaceDayTracks == 0) then return end
				newTrack = peaceDayTracks[math.random(1, #peaceDayTracks)]
			elseif musicType == 'peace_night' then
				if (#peaceNightTracks == 0) then return end
				newTrack = peaceNightTracks[math.random(1, #peaceNightTracks)]
			elseif musicType == 'war' then
				if (#warTracks == 0) then return end
				newTrack = warTracks[math.random(1, #warTracks)]
			end
			tries = tries + 1
		until newTrack ~= previousTrack or tries >= 10
	end
	-- for key, val in pairs(oggInfo) do
		-- Spring.Echo(key, val)	
	-- end
	firstFade = false
	--if newTrack ~= previousTrack then
	--	Spring.Echo("Playing track:".. newTrack)
	--end
	previousTrack = newTrack
	
	-- if (oggInfo.comments.TITLE and oggInfo.comments.TITLE) then
		-- Spring.Echo("Song changed to: " .. oggInfo.comments.TITLE .. " By: " .. oggInfo.comments.ARTIST)
	-- else
		-- Spring.Echo("Song changed but unable to get the artist and title info")
	-- end
	curTrack = newTrack
	PlayMusicStream(newTrack)
	
end

local function StopTrack(noContinue)
	looping = false
	Spring.StopSoundStream()
	if noContinue then
		haltMusic = true
	else
		haltMusic = false
		StartTrack()
	end
end


local function SetWarThreshold(num)
	if num and num >= 0 then
		warThreshold = num
	else
		warThreshold = 5000
	end
end

local function SetPeaceThreshold(num)
	if num and num >= 0 then
		peaceThreshold = num
	else
		peaceThreshold = 1000
	end	
end

function widget:Update(dt)
	if gameOver then
		return
	end
	if not initialized then
		math.randomseed(os.clock()* 100)
		initialized=true
		-- these are here to give epicmenu time to set the values properly
		-- (else it's always default at startup)
		if VFS.FileExists(PLAYLIST_FILE, VFS.RAW_FIRST) then
			local tracks = VFS.Include(PLAYLIST_FILE, nil, VFS.RAW_FIRST)
			warTracks = tracks.war
			peaceDayTracks = tracks.peace
			peaceNightTracks = tracks.night
			briefingTracks = tracks.briefing
			victoryTracks = tracks.victory
			defeatTracks = tracks.defeat
			paradeTracks = tracks.parade
			explicitParadePlaylist = tracks.parade ~= nil
		end
		
		local vfsMode = (options.useIncludedTracks.value and VFS.RAW_FIRST) or VFS.RAW
		warTracks	= warTracks or VFS.DirList('sounds/music/war/', '*.ogg', vfsMode)
		peaceDayTracks	= peaceDayTracks or VFS.DirList('sounds/music/peace/', '*.ogg', vfsMode)
		peaceNightTracks = peaceNightTracks or  VFS.DirList('sounds/music/peace/night/', '*.ogg', vfsMode)
		briefingTracks  = briefingTracks or VFS.DirList('sounds/music/briefing/', '*.ogg', vfsMode)
		victoryTracks	= victoryTracks or VFS.DirList('sounds/music/victory/', '*.ogg', vfsMode)
		defeatTracks	= defeatTracks or VFS.DirList('sounds/music/defeat/', '*.ogg', vfsMode)
		-- A playlist may provide its own parade selection (including an empty
		-- table to opt out); otherwise discover all parade tracks.
		paradeTracks = paradeTracks or VFS.DirList('sounds/music/parade/', '*.ogg', vfsMode)
		local validParadeTracks = {}
		for _, track in ipairs(paradeTracks) do
			if type(track) == 'string' and VFS.FileExists(track, vfsMode) then
				validParadeTracks[#validParadeTracks + 1] = track
			end
		end
		paradeTracks = validParadeTracks
	end
	
	-- Choose once per procession, restarting that song from its beginning.
	-- Detect the start on this update, without waiting for the ambient poll.
	local paradeActive = gameStarted and Spring.GetGameRulesParam('city_parade_active') == 1
	local paradeStateChanged = paradeActive ~= paradeWasActive
	if paradeStateChanged then
		paradeWasActive = paradeActive
		paradeTrack = nil
		if paradeActive and not explicitParadePlaylist then
			local mode = options.useIncludedTracks.value and VFS.RAW_FIRST or VFS.RAW
			paradeTracks = VFS.DirList('sounds/music/parade/', '*.ogg', mode)
		end
	end
	if paradeStateChanged and not haltMusic and not looping and
		(musicType == 'war' or string.find(musicType, 'peace') or musicType == 'parade') then
		local wantsParade = paradeActive and #GetAvailableParadeTracks() > 0
		if wantsParade and musicType ~= 'parade' then
			ambientMusicType = musicType == 'peace' and (isNight() and 'peace_night' or 'peace_day') or musicType
			musicType = 'parade'
			StartTrack()
			previousTrackType, firstTime = musicType, true
		elseif not wantsParade and musicType == 'parade' then
			musicType = ambientMusicType
			StartTrack()
			previousTrackType, firstTime = musicType, true
		end
	end

	timeframetimer_short = timeframetimer_short + dt
	if timeframetimer_short > 0.03 then
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = tonumber( ("%.2f"):format(playedTime) )
		paused = (playedTime == lastTrackTime)
		lastTrackTime = playedTime
		if looping then
			if looping == 0.5 then
				looping = 1
			elseif playedTime >= totalTime - LOOP_BUFFER then
				Spring.StopSoundStream()
				PlayMusicStream(loopTrack)
			end
		elseif musicType == 'parade' and not haltMusic and totalTime > 0
			and playedTime >= totalTime - LOOP_BUFFER
			and Spring.GetGameRulesParam('city_parade_active') == 1
			and #GetAvailableParadeTracks() > 0 then
			-- Use the existing short polling cadence for the seamless parade
			-- score, avoiding the ordinary playlist's one-second end-of-track gap.
			StartTrack()
		end
		timeframetimer_short = 0
	end
	
	timeframetimer = timeframetimer + dt
	if (timeframetimer > UPDATE_PERIOD) then	-- every second
		timeframetimer = 0
		newTrackWait = newTrackWait + 1
		local PlayerTeam = Spring.GetMyTeamID()
		numVisibleEnemy = 0
		local doods = Spring.GetVisibleUnits()
		for i=1,#doods do
			if (Spring.IsUnitAllied(doods[i]) ~= true) then
				numVisibleEnemy = numVisibleEnemy + 1
			end
		end
			
		local totalKilled = 0
		for i = 1, 10, 1 do --calculate the first half of the table (1-15)
			totalKilled = totalKilled + (dethklok[i] * 2)
		end
		
		for i = 11, 20, 1 do -- calculate the second half of the table (16-45)
			totalKilled = totalKilled + dethklok[i]
		end
		
		for i = 20, 1, -1 do -- shift value(s) to the end of table
			dethklok[i+1] = dethklok[i]
		end
		dethklok[1] = 0 -- empty the first row
		
		local previousMusicType = musicType
		if (musicType == 'war' or string.find(musicType,"peace") or musicType == 'parade') then
			if musicType ~= 'parade' then ambientMusicType = musicType end
			if (totalKilled >= warThreshold) then
				ambientMusicType = 'war'
			elseif (totalKilled <= peaceThreshold) then
				if isNight() then
					ambientMusicType = 'peace_night'
				else
					ambientMusicType = 'peace_day'
				end
			end
			-- The synced director publishes only actual touring, so assembly,
			-- emergencies, and disbanding return immediately to ordinary music.
			-- Explicit custom/looping tracks and StopTrack(true) retain ownership.
			local paradeAvailable = #GetAvailableParadeTracks() > 0
			local paradeTouring = gameStarted and Spring.GetGameRulesParam('city_parade_active') == 1
			musicType = (paradeTouring and paradeAvailable and not haltMusic and not looping)
				and 'parade' or ambientMusicType
		end
		local paradeChanged = previousMusicType ~= musicType
			and (previousMusicType == 'parade' or musicType == 'parade')
		
		local startedThisUpdate = false
		if (not firstTime) then
			if not (haltMusic or looping or musicType == 'custom') then
				StartTrack()
				startedThisUpdate = true
			end
			firstTime = true -- pop this cherry	
		end
		
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = math.floor(playedTime)
		totalTime = math.floor(totalTime)
		--Spring.Echo(playedTime, totalTime)
		
		--Spring.Echo(playedTime, totalTime, newTrackWait)
		
		--if((totalTime - playedTime) <= 6 and (totalTime >= 1) ) then
			--Spring.Echo("time left:", (totalTime - playedTime))
			--Spring.Echo("volume:", (totalTime - playedTime)/6)
			--if ((totalTime - playedTime)/6 >= 0) then
			--	Spring.SetSoundStreamVolume((totalTime - playedTime)/6)
			--else
			--	Spring.SetSoundStreamVolume(0.1)
			--end
		--elseif(playedTime <= 5 )then--and not firstFade
			--Spring.Echo("time playing:", playedTime)
			--Spring.Echo("volume:", playedTime/5)
			--Spring.SetSoundStreamVolume( playedTime/5)
		--end
		--Spring.Echo(previousTrackType, musicType)
		if ((string.find(previousTrackType, "peace") and musicType == 'war')
		 or paradeChanged or (playedTime >= totalTime)) -- both zero means track stopped
		 and not(startedThisUpdate or haltMusic or looping) then
			previousTrackType = musicType
			StartTrack()
			
			--Spring.Echo("Track: " .. newTrack)
			newTrackWait = 0
		end
	end
	-- Nearby spatial queries run at 10 Hz, not once per truck or per frame.
	musicVolumeTimer = musicVolumeTimer + dt
	if musicType == 'parade' and musicVolumeTimer >= 0.1 then
		ApplyMusicVolume(true)
		musicVolumeTimer = 0
	end
	local _, _, gamePaused = Spring.GetGameSpeed()
	if options.pausemusic.value then
		if (streamRestarted and gamePaused) or (not streamRestarted and gamePaused ~= wasPaused) then
			Spring.PauseSoundStream()
		end
		wasPaused = gamePaused
	end
	streamRestarted = false
end

function widget:GameStart()
	if not gameStarted then
		gameStarted = true
		previousTrackType = musicType
		musicType = "peace_day"
		StartTrack()
	end
	
	--Spring.Echo("Track: " .. newTrack)
	newTrackWait = 0	
end

-- Safety of a heisenbug
function widget:GameFrame()
	widget:GameStart()
	widgetHandler:RemoveCallIn('GameFrame')
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if unitExceptions[unitDefID] then
		return
	end


	
	if (damage < 1.5) then return end
	local PlayerTeam = Spring.GetMyTeamID()
	
	if (UnitDefs[unitDefID] == nil) then return end
		
	if paralyzer then
		return
	else
		if (teamID == PlayerTeam) then
			damage = damage * 1.5
		end
		local multifactor = 1
		if (numVisibleEnemy > 3) then
			multifactor = math.log(numVisibleEnemy)
		end
		dethklok[1] = dethklok[1] + (damage * multifactor);
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID) 
	if unitExceptions[unitDefID] then
		return
	end

	local attackerID =  Spring.GetUnitLastAttacker(unitID)
	if attackerID == nil then return end

	local unitWorth = 50
	if (UnitDefs[unitDefID].metalCost > 500) then
		unitWorth = 200
	end
	if (UnitDefs[unitDefID].metalCost > 1000) then
		unitWorth = 300
	end
	if (UnitDefs[unitDefID].metalCost > 3000) then
		unitWorth = 500
	end
	if (UnitDefs[unitDefID].metalCost > 8000) then
		unitWorth = 700
	end
	if (teamID == PlayerTeam) then
		unitWorth = unitWorth * 1.5
	end
	local multifactor = 1
	if (numVisibleEnemy > 3) then
		multifactor = math.log(numVisibleEnemy)
	end
	dethklok[1] = dethklok[1] + (unitWorth*multifactor);
end

function widget:TeamDied(team)
	if team == myTeam and not isSpec then
		defeat = true
	end
end

local function PlayGameOverMusic(gameWon)
	local track
	if gameWon then
		if #victoryTracks <= 0 then return end
		track = victoryTracks[math.random(1, #victoryTracks)]
		musicType = "victory"
	else
		if #defeatTracks <= 0 then return end
		track = defeatTracks[math.random(1, #defeatTracks)]
		musicType = "defeat"
	end
	looping = false
	Spring.StopSoundStream()
	PlayMusicStream(track)
end

function widget:GameOver()
	gameOver = true
	PlayGameOverMusic(not defeat)
end

function widget:Initialize()
	WG.Music = WG.Music or {}
	WG.Music.GetMusicVolume = GetMusicVolume
	WG.Music.SetMusicVolume = SetMusicVolume
	WG.Music.StartTrack = StartTrack
	WG.Music.StartLoopingTrack = StartLoopingTrack
	WG.Music.StopTrack = StopTrack
	WG.Music.SetWarThreshold = SetWarThreshold
	WG.Music.SetPeaceThreshold = SetPeaceThreshold
	WG.Music.GetMusicType = GetMusicType
	WG.Music.PlayGameOverMusic = PlayGameOverMusic

	-- Spring.Echo(math.random(), math.random())
	-- Spring.Echo(os.clock())
 
	-- for TrackName,TrackDef in pairs(peaceDayTracks) do
		-- Spring.Echo("Track: " .. TrackDef)	
	-- end
	--math.randomseed(os.clock()* 101.01)--lurker wants you to burn in hell rgn
	-- for i=1,20 do Spring.Echo(math.random()) end
	
	for i = 1, 30, 1 do
		dethklok[i]=0
	end
end

function widget:Shutdown()
	Spring.StopSoundStream()
	Spring.SetSoundStreamVolume(GetMusicVolume() / 100)
	WG.Music = nil
	
	for i=1,#windows do
		(windows[i]):Dispose()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
