function widget:GetInfo()
	return {
		name = "Tutorial",
		desc = "First-play guided tour",
		author = "PicassoCT / MOSAIC",
		version = "v2.0",
		date = "Oct 04, 2026",
		license = "GNU GPL, v2 or later",
		layer = 3,
		enabled = true,
	}
end

--------------------------------------------------------------------------------
-- MOSAIC first-play tutorial
--
-- Normal behaviour:
--   * Runs automatically on the first game only.
--   * Disabling and re-enabling the widget during the same LuaUI session
--     restarts the tutorial from step one.
--
-- Test commands:
--   /tutorial restart
--   /tutorial test on
--   /tutorial test off
--   /tutorial status
--------------------------------------------------------------------------------

local spGetGameFrame       = Spring.GetGameFrame
local spGetMouseState      = Spring.GetMouseState
local spGetMyPlayerID      = Spring.GetMyPlayerID
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetPlayerInfo      = Spring.GetPlayerInfo
local spGetSelectedUnits   = Spring.GetSelectedUnits
local spGetTeamInfo        = Spring.GetTeamInfo
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitPosition    = Spring.GetUnitPosition
local spMarkerAddPoint     = Spring.MarkerAddPoint
local spPlaySoundFile      = Spring.PlaySoundFile
local spSendCommands       = Spring.SendCommands
local spTraceScreenRay     = Spring.TraceScreenRay

local CONFIG_STARTUP_COUNTER = "mosaic_startupcounter"
local CONFIG_TEST_MODE       = "mosaic_tutorial_testmode"

local FPS = 30
local myTeamID
local mySide
local tutorialActive = false
local testMode = false
local currentStep = 1
local nextActionFrame = 0
local lastSelectionDefID
local lastSelectionUnitID

local function getDefID(name)
	local ud = UnitDefNames and UnitDefNames[name]
	return ud and ud.id
end

local defs = {
	operativepropagator = getDefID("operativepropagator"),
	operativeinvestigator = getDefID("operativeinvestigator"),
	antagonsafehouse = getDefID("antagonsafehouse"),
	protagonsafehouse = getDefID("protagonsafehouse"),
	propagandaserver = getDefID("propagandaserver"),
	civilianagent = getDefID("civilianagent"),
	icon_raid = getDefID("icon_raid"),
	antagonassembly = getDefID("antagonassembly"),
	protagonassembly = getDefID("protagonassembly"),
	operativeasset = getDefID("operativeasset"),
	nimrod = getDefID("nimrod"),
	launcher = getDefID("launcher"),
	blacksite = getDefID("blacksite"),
}

local TutorialInfo = {
	antagon = {
		intro = {
			speech = "sounds/tutorial/welcomeGeneral.ogg",
			time = 8000,
			text = "\a|Welcome to MOSAIC\nA spy game of treason and betrayal.\nFollow these markers for your first mission.\nDisable/re-enable this widget in F11 to restart the tour.",
		},
		welcome = {
			speech = "sounds/tutorial/welcomeBuildSafeHouse.ogg",
			time = 26000,
			text = "Build a safehouse inside the city.",
		},
		[defs.operativepropagator] = {
			speech = "sounds/tutorial/antagon/operativepropagator.ogg",
			time = 3000,
			text = "\a|Propaganda Operative\nRecruits Agents\nBuilds Safehouses\nRaids & Interrogates enemy installations",
		},
		[defs.antagonsafehouse] = {
			speech = "sounds/tutorial/safehouse.ogg",
			time = 3000,
			text = "\a|Safehouse\nTrains Operatives\nTransforms into facilities\nKnows about everyone trained there",
		},
		[defs.propagandaserver] = {
			speech = "sounds/tutorial/antagon/propagandaserver.ogg",
			time = 5000,
			text = "\a|Propaganda Server\nCreates money & material\nby swaying public opinion",
		},
		[defs.antagonassembly] = {
			speech = "sounds/tutorial/assembly.ogg",
			time = 5000,
			text = "\a|Assembly\nAutomated factory for Mosaic-standard war units",
		},
		[defs.launcher] = {
			speech = "sounds/tutorial/antagon/launcher.ogg",
			time = 3000,
			text = "\a|Launcher\nBuilds a hypersonic strategic weapon",
		},
	},
	protagon = {
		intro = {
			speech = "sounds/tutorial/welcomeGeneral.ogg",
			time = 18000,
			text = "\a|Welcome to MOSAIC\nA spy game of treason and betrayal.\nFollow these markers for your first mission.\nDisable/re-enable this widget in F11 to restart the tour.",
		},
		welcome = {
			speech = "sounds/tutorial/welcomeBuildSafeHouse.ogg",
			time = 44000,
			text = "Build a safehouse inside the city.",
		},
		[defs.operativeinvestigator] = {
			speech = "sounds/tutorial/protagon/operativeinvestigator.ogg",
			time = 5000,
			text = "\a|Investigator Operative\nRecruits Agents\nBuilds Safehouses\nRaids & Interrogates enemy installations",
		},
		[defs.protagonsafehouse] = {
			speech = "sounds/tutorial/protagon/safehouse.ogg",
			time = 5000,
			text = "\a|Safehouse\nTrains Operatives\nTransforms into facilities\nKnows about everyone trained there",
		},
		[defs.propagandaserver] = {
			speech = "sounds/tutorial/protagon/propagandaserver.ogg",
			time = 5000,
			text = "\a|Propaganda Server\nCreates money & material\nby swaying public opinion",
		},
		[defs.protagonassembly] = {
			speech = "sounds/tutorial/assembly.ogg",
			time = 5000,
			text = "\a|Assembly\nAutomated factory for Mosaic-standard war units",
		},
		[defs.blacksite] = {
			speech = "sounds/tutorial/protagon/blacksite.ogg",
			time = 3000,
			text = "\a|Blacksite\nBuilds classified tools that manipulate civilian behaviour.",
		},
	},
	general = {
		[defs.icon_raid] = {
			speech = "sounds/tutorial/raidIcon.ogg",
			time = 3000,
			text = "\a|Raid\nStorm or defend a Safehouse\nClick & drag to place your units before the round ends",
		},
		[defs.operativeasset] = {
			speech = "sounds/tutorial/operativeasset.ogg",
			time = 3000,
			text = "\a|Operative Asset\nTrained assassin & stealth operator",
		},
		[defs.civilianagent] = {
			speech = "sounds/tutorial/civilianagent.ogg",
			time = 3000,
			text = "\a|Civilian Agent\nA recruited civilian spy\nUseful as an observer; capture can expose the recruiter",
		},
		[defs.nimrod] = {
			speech = "sounds/tutorial/nimrod.ogg",
			time = 3000,
			text = "\a|Nimrod\nOrbital railgun and satellite factory",
		},
	},
}

local function normalizeInfoTable(tbl)
	for _, section in pairs(tbl) do
		for _, entry in pairs(section) do
			if type(entry) == "table" then
				if entry.time == nil then entry.time = 4000 end
				if entry.speech == nil then entry.speech = nil end
				if entry.text == nil then entry.text = "" end
			end
		end
	end
end
normalizeInfoTable(TutorialInfo)

local function getInfo(defID)
	if not defID then return nil end
	local sideInfo = TutorialInfo[mySide]
	return (sideInfo and sideInfo[defID]) or TutorialInfo.general[defID]
end

local function markerAtUnit(unitID, text)
	if not unitID or not text or text == "" then return end
	local x, y, z = spGetUnitPosition(unitID)
	if not x then return end
	spSendCommands({"clearmapmarks"})
	spMarkerAddPoint(x, y, z, text, true)
end

local function markerAtCursor(text)
	if not text or text == "" then return end
	local mx, my = spGetMouseState()
	local kind, pos = spTraceScreenRay(mx, my)
	if kind == "ground" and pos then
		spMarkerAddPoint(pos[1], pos[2], pos[3], text, true)
	end
end

local function playEntry(entry, unitID)
	if not entry then return 0 end
	if unitID then
		markerAtUnit(unitID, entry.text)
	else
		markerAtCursor(entry.text)
	end
	if entry.speech then
		if unitID then
			local x, y, z = spGetUnitPosition(unitID)
			if x then
				spPlaySoundFile(entry.speech, 1, x, y, z, 0, 0, 0, "ui")
			else
				spPlaySoundFile(entry.speech, 1)
			end
		else
			spPlaySoundFile(entry.speech, 1)
		end
	end
	return entry.time or 4000
end

local function setCooldown(milliseconds)
	nextActionFrame = spGetGameFrame() + math.ceil((milliseconds or 0) / 1000 * FPS)
end

local function teamHasDef(defID)
	if not defID then return nil end
	local units = spGetTeamUnitsByDefs(myTeamID, defID)
	if units and #units > 0 then
		return units[1]
	end
	return nil
end

local function sideOperativeDef()
	return mySide == "protagon" and defs.operativeinvestigator or defs.operativepropagator
end

local function sideSafehouseDef()
	return mySide == "protagon" and defs.protagonsafehouse or defs.antagonsafehouse
end

local function resetTour(reason)
	currentStep = 1
	nextActionFrame = spGetGameFrame() + FPS
	lastSelectionDefID = nil
	lastSelectionUnitID = nil
	tutorialActive = true
	spSendCommands({"clearmapmarks"})
	Spring.Echo("[MOSAIC Tutorial] Restarted" .. (reason and (" (" .. reason .. ")") or "") .. ".")
end

local function finishTour()
	tutorialActive = false
	spSendCommands({"clearmapmarks"})
	Spring.Echo("[MOSAIC Tutorial] First mission tour complete. Disable/re-enable the Tutorial widget to replay it, or use /tutorial restart.")
end

local function advance()
	currentStep = currentStep + 1
end

local function runTourStep()
  if WG.MosaicArrival and WG.MosaicArrival.active then return end
	if not tutorialActive or spGetGameFrame() < nextActionFrame then return end
	local sideInfo = TutorialInfo[mySide]
	if not sideInfo then return end

	-- 1: Introduction.
	if currentStep == 1 then
		setCooldown(playEntry(sideInfo.intro))
		advance()
		return
	end

	-- 2: Introduce/select the starting operative.
	if currentStep == 2 then
		local wantedDef = sideOperativeDef()
		local unitID = teamHasDef(wantedDef)
		if unitID then
			setCooldown(playEntry(getInfo(wantedDef), unitID))
			advance()
		end
		return
	end

	-- 3: Direct the player to establish a safehouse, then wait for one.
	if currentStep == 3 then
		setCooldown(playEntry(sideInfo.welcome))
		advance()
		return
	end
	if currentStep == 4 then
		local unitID = teamHasDef(sideSafehouseDef())
		if unitID then
			setCooldown(playEntry(getInfo(sideSafehouseDef()), unitID))
			advance()
		end
		return
	end

	-- 5: Establish the economy. Existing server also counts, so test mode can
	-- be restarted in a developed match.
	if currentStep == 5 then
		local unitID = teamHasDef(defs.propagandaserver)
		if unitID then
			setCooldown(playEntry(getInfo(defs.propagandaserver), unitID))
			advance()
		end
		return
	end

	-- 6: Recruitment / human intelligence.
	if currentStep == 6 then
		local unitID = teamHasDef(defs.civilianagent)
		if unitID then
			setCooldown(playEntry(getInfo(defs.civilianagent), unitID))
			advance()
		end
		return
	end

	-- 7: First raid. The raid icon may be short-lived, so UnitCreated also
	-- advances this step immediately.
	if currentStep == 7 then
		local unitID = teamHasDef(defs.icon_raid)
		if unitID then
			setCooldown(playEntry(getInfo(defs.icon_raid), unitID))
			advance()
		end
		return
	end

	if currentStep >= 8 then
		finishTour()
	end
end

local function resolveSide()
	myTeamID = spGetMyTeamID()
	local side = select(5, spGetTeamInfo(myTeamID))
	if type(side) == "string" then
		side = string.lower(side)
	end
	if side == "protagon" or side == "antagon" then
		return side
	end

	local protagonistUnits = defs.operativeinvestigator and spGetTeamUnitsByDefs(myTeamID, defs.operativeinvestigator)
	if protagonistUnits and #protagonistUnits > 0 then return "protagon" end

	local antagonistUnits = defs.operativepropagator and spGetTeamUnitsByDefs(myTeamID, defs.operativepropagator)
	if antagonistUnits and #antagonistUnits > 0 then return "antagon" end

	return "antagon"
end

function widget:Initialize()
	local playerID = spGetMyPlayerID()
	local _, _, spectator = spGetPlayerInfo(playerID)
	if spectator then
		widgetHandler:RemoveWidget(self)
		return
	end

	mySide = resolveSide()
	testMode = Spring.GetConfigInt(CONFIG_TEST_MODE, 0) == 1

	local startupCounter = Spring.GetConfigInt(CONFIG_STARTUP_COUNTER, 0)
	local firstPlay = startupCounter < 1

	-- Increment once per running LuaUI session/game. A widget replay must not
	-- accidentally consume another "launch".
	if not WG.MosaicTutorialCountedThisGame then
		Spring.SetConfigInt(CONFIG_STARTUP_COUNTER, startupCounter + 1)
		WG.MosaicTutorialCountedThisGame = true
	end

	-- Shutdown sets this only in WG, which survives an F11 widget toggle but
	-- not an engine/game restart. Thus re-enable == replay, next game != replay.
	local replayRequested = WG.MosaicTutorialRestartRequested == true
	WG.MosaicTutorialRestartRequested = false

	if firstPlay or replayRequested or testMode then
		resetTour(replayRequested and "widget re-enabled" or (testMode and "test mode" or "first play"))
	else
		tutorialActive = false
		Spring.Echo("[MOSAIC Tutorial] Already completed. Disable/re-enable this widget or use /tutorial restart to replay.")
	end
end

function widget:Shutdown()
	-- This flag intentionally lives only in LuaUI memory. Re-enabling the widget
	-- during this game restarts it; exiting the game discards the flag.
	WG.MosaicTutorialRestartRequested = true
	Spring.Echo("[MOSAIC Tutorial] Deactivated. Re-enable the widget to restart from step one.")
end

function widget:GameFrame(frame)
	if frame % 10 == 0 then
		runTourStep()
	end
end

function widget:SelectionChanged(selectedUnits)
  if WG.MosaicArrival and WG.MosaicArrival.active then return end
	if not tutorialActive or not selectedUnits or #selectedUnits == 0 then return end
	local unitID = selectedUnits[1]
	local defID = spGetUnitDefID(unitID)
	if not defID or (defID == lastSelectionDefID and unitID == lastSelectionUnitID) then return end
	lastSelectionDefID = defID
	lastSelectionUnitID = unitID

	-- Contextual explanations remain available alongside the ordered tour.
	-- Do not disturb the tour while narration is already playing.
	if spGetGameFrame() >= nextActionFrame then
		local entry = getInfo(defID)
		if entry then
			setCooldown(playEntry(entry, unitID))
		end
	end
end

local function maybeAdvanceCreation(unitID, unitDefID, unitTeam)
  if WG.MosaicArrival and WG.MosaicArrival.active then return end
	if not tutorialActive or unitTeam ~= myTeamID then return end
	if currentStep == 4 and unitDefID == sideSafehouseDef() then
		setCooldown(playEntry(getInfo(unitDefID), unitID))
		advance()
	elseif currentStep == 5 and unitDefID == defs.propagandaserver then
		setCooldown(playEntry(getInfo(unitDefID), unitID))
		advance()
	elseif currentStep == 6 and unitDefID == defs.civilianagent then
		setCooldown(playEntry(getInfo(unitDefID), unitID))
		advance()
	elseif currentStep == 7 and unitDefID == defs.icon_raid then
		setCooldown(playEntry(getInfo(unitDefID), unitID))
		advance()
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	maybeAdvanceCreation(unitID, unitDefID, unitTeam)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	-- Raid icons can be transient and may never reach UnitFinished.
	if unitDefID == defs.icon_raid then
		maybeAdvanceCreation(unitID, unitDefID, unitTeam)
	end
end

function widget:TextCommand(command)
	local cmd = string.lower(command or "")
	if cmd == "tutorial restart" or cmd == "tutorial reset" then
		resetTour("command")
		return true
	elseif cmd == "tutorial test on" then
		testMode = true
		Spring.SetConfigInt(CONFIG_TEST_MODE, 1)
		resetTour("test mode")
		Spring.Echo("[MOSAIC Tutorial] Test mode ON: tutorial will start whenever this widget initializes.")
		return true
	elseif cmd == "tutorial test off" then
		testMode = false
		Spring.SetConfigInt(CONFIG_TEST_MODE, 0)
		Spring.Echo("[MOSAIC Tutorial] Test mode OFF.")
		return true
	elseif cmd == "tutorial status" then
		Spring.Echo("[MOSAIC Tutorial] active=" .. tostring(tutorialActive)
			.. " step=" .. tostring(currentStep)
			.. " side=" .. tostring(mySide)
			.. " testMode=" .. tostring(testMode))
		return true
	elseif cmd == "tutorial" then
		Spring.Echo("[MOSAIC Tutorial] /tutorial restart | /tutorial test on | /tutorial test off | /tutorial status")
		return true
	end
	return false
end
