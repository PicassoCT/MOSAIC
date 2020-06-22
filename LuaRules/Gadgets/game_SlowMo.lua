function gadget:GetInfo()
	return {
		name = "Slowmotion gadget",
		desc = "This gadget coordinates gamespeed sets by hiveMinds and AI-Cores",
		author = "PicassoCT",
		date = "Juli. 2017",
		license = "GNU GPL, v2 or later",
		layer = 0,
		version = 1,
		enabled = true		
	}
end

if (gadgetHandler:IsSyncedCode()) then	
	VFS.Include("scripts/lib_UnitScript.lua")
	side= "antagon"
	if math.random(0,1)==1 then side = "protagon" end
	
	
	function gadget:Initialize()

		SendToUnsynced("Initialize")
	end
	
	--check for active HiveMinds and AI Nodes
	function areHiveMindsActive()
		if not GG.HiveMind then GG.HiveMind = {}; return false, {} end
		tableTeamsActive = {}
		boolActive = false
		for team, uTab in pairs(GG.HiveMind) do
			if uTab then
				for unit, data in pairs(uTab) do
					if type(data) ~= "boolean" then
						if data.boolActive == true then
							tableTeamsActive[team] = unit
							boolActive = true
						end
					end
				end
			end
		end		
	return boolActive, tableTeamsActive
	end
	
	-- if active ones, find others that could be active
	function activateOtherHiveminds(tableTeamsActive)
		hiveMindMaxTime= DurationInSeconds * 1000
		if not GG.HiveMind then GG.HiveMind = {} end
		
		for team, uTab in pairs(GG.HiveMind) do
			if not tableTeamsActive[team] then
				for unit, data in pairs(uTab) do
					hiveMindMaxTime= math.max(hiveMindMaxTime,data.rewindMilliSeconds)
					if data.rewindMilliSeconds > 0 then
						env = Spring.UnitScript.GetScriptEnv(unit)
						if env then
							Spring.UnitScript.CallAsUnit(unit, env.setActive)
							tableTeamsActive[team] = unit
						end
						break
					end
				end
			end
		end
	return tableTeamsActive, hiveMindMaxTime
	end
	
	oldGameSpeed = 1.0
	targetSlowMoSpeed= 0.4
	DurationInSeconds = 30 * 40
	--set SlowMotion effect
	
	currentSpeed= 1.0
	
	function slowMotion(frame, boolActive, startFrame, endFrame)
	GG.GameSpeed= currentSpeed
	if boolActivate== false or frame > endFrame then
			if frame % 10 == 0 and currentSpeed < oldGameSpeed - 0.1 then
				Spring.SendCommands("speedup ")
			end
	end
	
	--Slow Down
	if frame > startFrame and frame < endFrame then			
		if currentSpeed > targetSlowMoSpeed - 0.11 then
			Spring.Echo("slowdown to " .. currentSpeed)
			Spring.SendCommands("slowdown")
		end		
	end
	
	if frame == startFrame then
		oldGameSpeed= currentSpeed
		Spring.PlaySoundFile("sounds/HiveMind/StartLoop.ogg", 1.0)
		return
	end

	--SlowMoPhase
	if frame >= startFrame and frame < endFrame then			
		if frame - startFrame % 210 == 0 then
			if side== "antagon" then
			Spring.PlaySoundFile("sounds/HiveMind/Antagonloop.ogg", 1.0)
			else
			Spring.PlaySoundFile("sounds/HiveMind/Protagonloop.ogg", 1.0)
			end
		end
		return
	end
		
	--Speed up phase
	if frame == endFrame then
		Spring.PlaySoundFile("sounds/HiveMind/EndLoop.ogg", 1.0)
		return
	end
end
	
	--for teams without a active node or no node at all - hide the cursor during the slowMotionPhase
	function deactivateCursorForNormalTeams(tableTeamsActive)
		deactivatedTeams = {}
		allTeams = Spring.GetTeamList()
		process(allTeams,
		function(team)
			if not tableTeamsActive[team] then
				deactivatedTeams[team] = true
				SendToUnsynced("hideCursor", team)
			end
		end)
	end
	
	--restore Cursor for non-active teams
	function restoreCursorNonActiveTeams(tableTeamsActive)
		allTeams = Spring.GetTeamList()
		process(allTeams,
		function(team)
			if not tableTeamsActive[team] then
				SendToUnsynced("restoreCursor", team)
			end
		end)
	end
	
	boolPreviouslyActive = false
	endFrame = 0
	startFrame = 0
	
	function gadget:GameFrame(n)

		boolActive, activeHiveMinds = areHiveMindsActive()
		if boolActive == true then
			
			if boolPreviouslyActive == false then
				SendToUnsynced("ActivateSlowMoShadder", true)
				boolPreviouslyActive = true
				startFrame = n
			end
			
			activeHiveMinds, MaxTimeInMs = activateOtherHiveminds(activeHiveMinds)
			deactivateCursorForNormalTeams(activeHiveMinds)
			
			endFrame = (n + math.ceil(MaxTimeInMs/1000) * 30)
		elseif boolActive == false and endFrame == n then
			SendToUnsynced("ActivateSlowMoShadder", false)
			restoreCursorNonActiveTeams(activeHiveMinds)
			boolPreviouslyActive = false
		end

		SendToUnsynced("frameCall", n)
		slowMotion(n, boolActive, startFrame, endFrame)
	end	
	
	 function gadget:RecvLuaMsg(msg, playerID)
	 
		start,ends= string.find(msg,"CurrentGameSpeed:")
		if ends then
			currentSpeed= tonumber(string.sub(msg,ends+1,#msg))
		end
	 end
	
else --Unsynced
	local	formerCommandTable = {}
	alt, ctrl, meta, shift, left, right = 0, 0, 0, 0, 0, 0
	-- deactivate mouse icon
	local	boolLameDuck = false
	local	boolDraw = false
	
	local function restoreCursor(_, team)
		myTeam = Spring.GetMyTeamID()
		if myTeam == team then
			boolLameDuck = true
			oldCommand = Spring.GetActiveCommand()
			formerCommandTable[team] = oldCommand
			
			alt, ctrl, meta, shift = Spring.GetModKeyState()
			local _, _, left, _, right = Spring.GetMouseState()
		end
	end
	
	local function frameCall(_,n)

		if boolLameDuck == true then
			--Spring.SetActiveCommand(Spring.GetCmdDescIndex(CMD.WAIT), 1, left, right, alt, ctrl, meta, shift)
		end
		
		if n % 5 == 0 then
		currentGameSpeed = Spring.GetGameSpeed() or 1.0
		Spring.SendLuaRulesMsg("CurrentGameSpeed:"..currentGameSpeed)
		end
	end
	
	local function hideCursor(_, team)
		myTeam = Spring.GetMyTeamID()
		if myTeam == team then
			boolLameDuck = false
			Spring.SetActiveCommand(formerCommandTable[team], 1, left, right, alt, ctrl, meta, shift)
		end
	end 
	
	local function ActivateSlowMoShadder(_, boolActivate)
		if 	Script.LuaUI('ActivateSlowMoShader') then
			Script.LuaUI.ActivateSlowMoShader(boolActivate)
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction("Initialize", Initialize)
		gadgetHandler:AddSyncAction("ActivateSlowMoShadder", ActivateSlowMoShadder)
		gadgetHandler:AddSyncAction("restoreCursor", restoreCursor)
		gadgetHandler:AddSyncAction("hideCursor", hideCursor)
		gadgetHandler:AddSyncAction("frameCall", frameCall)	 
	end
end