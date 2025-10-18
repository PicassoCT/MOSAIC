
function widget:GetInfo()
	return {
		name = "Tutorial",
		desc = "Save the Noobs",
		author = "A Noob to far",
		version = "v1.1",
		date = "Jul 18, 2009",
		license = "GNU GPL, v2 or later",
		layer = 3,
		enabled = true-- loaded by default?
	}
end

---------------------------------------------------------------------------
-- Speedups
---------------------------------------------------------------------------
local spGetMouseState = Spring.GetMouseState
local spGetActiveCommand = Spring.GetActiveCommand
local spGetDefaultCommand = Spring.GetDefaultCommand
local spGetModKeyState = Spring.GetModKeyState
local spGetSpecState = Spring.GetSpectatingState
local spGetMyTeamID = Spring.GetMyTeamID
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetUnitPos = Spring.GetUnitPosition
local spTraceScreenRay = Spring.TraceScreenRay
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetSelUnits = Spring.GetSelectedUnitsSorted
local spSelUnitArray = Spring.SelectUnitArray
local spGetUnitDefID = Spring.GetUnitDefID
local spPlaySoundFile=Spring.PlaySoundFile
local boolDebug = false

local 	function getDefID(name)
	   		for udid, ud in pairs(UnitDefs) do
		   		if ud.name == name then
		   			return udid
		   		end
			end
		end
---------------------------------------------------------------------------
-- Data
---------------------------------------------------------------------------
local boolOnAir = false
local silentPlaceHolder="Placeholder"
local boolTutorialActive= Spring.GetConfigInt("mosaic_startupcounter", 0) < 1 or boolDebug
local OperativePropagatorDefID = getDefID("operativepropagator")
local OperativeInvestigatorDefID = getDefID("operativeinvestigator")
local raidIconDefID = getDefID("icon_raid")
local mySide = "No valid side assigned"
local operativeAssetDefID = getDefID("operativeasset")

local spGetTeamUnitsCounts = Spring.GetTeamUnitsCounts
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetTeamInfo = Spring.GetTeamInfo
local spGetMyPlayerID = Spring.GetMyPlayerID
local startFrame = Spring.GetGameFrame()


local TutorialInfoTable= {
	antagon = {
	intro = {
		speach= "sounds/tutorial/welcomeGeneral.ogg",	
		active = true,
		-- Connection: Established
		-- Channel: Secure: 
		-- Auto-Information Censoring: Enabled 
		-- Location: LOCATION
		time = 8000,
		text =  "\a|Welcome to MOSAIC \n A spy game of treason and betrayal.\n These markers will guide you in your first game \n The tutorial can be deactivated in the Widgetmanager (Press F11)",
	},
	welcome = {

		speach= "sounds/tutorial/welcomeBuildSafeHouse.ogg",
		active = true,


		time = 26000,
		text = "Build safehouse"
	},
	----BuildUnits
	[getDefID("operativepropagator")] = 
	{
		speach= "sounds/tutorial/antagon/operativepropagator.ogg",
		active = true,
		-- This operative, is our way to take hold in this city, form cells and forward the CAUSE. 
		-- S/he can create safehouses and recruit civilians to our cause.
		-- S/he can interrogate civilans suspected of aiding the enemy.
		-- S/he can raid houses suspected of being safehouses. 
		-- Build a safehouse inside the city. Upon creation, you will recieve further instructions.
		time = 3000,
		text =  "\a|Propaganda Operative \n Recruits Agents\n Builds Safehouses \n Raids & Interriogates enemy installations"
	},
		[getDefID("antagonassembly")] = 
	{	--A assembly is a factory creating automated warmachines
		--All this machinery should be last and least effort. This war is not won with grenades and bullets.
		--It can easily be lost through those though.
		speach= "sounds/tutorial/assembly.ogg",
		boolUponCreation = true,
		active = true,
		time = 5000,
		text =  "\a|Assembly \n Automated factory for war-units following the mosaic standard"
	},
	[getDefID("antagonsafehouse")] = 
	{	--We established our first cell in this city. Well hidden, dont leed them too it.
		--In this cell we can train new members, and if needed we can upgrade it to anything needed.
		--A safehouse can even become the location were we perfect the CAUSE.
		--But not today, not here. This here is just a start.
		--Train another operative and then build a propagandasever. It will help us get more funds, more supporters.
		speach= "sounds/tutorial/safehouse.ogg",
		--
		boolUponCreation = true,
		active = true,
		time = 3000,
		text =  "\a|Safehouse \n Trains Operators\n Transforms into  facilitys \n Knows about all trained there"
	},
	[getDefID("propagandaserver")] = 
	{	--This is a propagandaserver
		--The god we thought ourselves is dead, and the enlightment killed it as its final act.
		--The networks searched us, naked as we were & quantified us. Now they know all there is to know.
		--We are animals, easy to herd, milk and train to fight one another.
		--Just connect our goal to the tales in there head and they will donate, march and die for us.
		--If the enemy kills produces collateral, this will amplify what we reap.
		speach= "sounds/tutorial/antagon/propagandaserver.ogg",
		boolUponCreation = true,
		active = true,
		time = 5000,
		text =  "\a|Propagandaserver \n Creates money & material \n by swaying public opinion"
	},
	
	[operativeAssetDefID] = 
	{	--A well trained assasin
		--To deal out death, not indiscriminate, but like a surgeon, that takes somebody trained like a surgeon.

		speach= "sounds/tutorial/operativeasset.ogg",
		active = true,
		time = 3000,
		text =  "\a|Operative Asset \n Trained Assasin & Stealh operator"
	},
	[getDefID("civilianagent")] = 
	{	--A civilian recruited for our side
		--Activate him to turn this unit into a armed milita. More useful as observer then military asset though.
		--Can reveal his recruiter on capture

		speach= "sounds/tutorial/civilianagent.ogg",
		boolUponCreation = true,
		active = true,
		time = 3000,
		text =  "\a|Civilian Agent \n A recruited civilian spy"
	},[getDefID("launcher")] = 
	{	--Rejoice, victory is at hand brothers & sisters
		--They never expected this, that there toys and devices could turn on them 
		--This is a world, were the right small push to a peeble, can cause an avalanch that topples empires.
		--Rejoice for this is the moment of reckoning. For all they have murdered,
		--to end them stepping on us. 

		speach= "sounds/tutorial/antagon/launcher.ogg",
		active = true,
		time = 3000,
		text =  "\a|Launcher\n Used to built a hypersonic ICBM, which fires a exponential weapon"
	},
},
protagon = {
		intro = {
		speach= "sounds/tutorial/welcomeGeneral.ogg",	
		active = true,
		-- Connection: Established
		-- Channel: Secure: 
		-- Auto-Information Censoring: Enabled 
		-- Location: LOCATION
		time = 18000,
		text =  "\a|Welcome to MOSAIC \n A spy game of treason and betrayal.\n These markers will guide you in your first game \n The tutorial can be deactivated in the Widgetmanager (Press F11)",
	},
	welcome = {
		speach= "sounds/tutorial/welcomeBuildSafeHouse.ogg",
		active = true,
				--Protagon: 
				-- Welcome to MOSAIC. Mobile Orbital Strategic AI Counter-Terrorism
				-- Welcome to Protagon-agent Level 5 or higher. This Personalized Overview will accompany on your first mission in the region.
				-- SigInt intercepted data, indicating with 95 % certainty a infilitration in this city.
				-- Local Sec has detected unusually high number of rogue cells with 72 % certainty
				-- Threat Classification is above discrete with 69 % certainty.
				-- Nobody wastes this level of awareness for just another dirty bomb or rogue nuke.
				--So whats left is dark, civilization ending stuff.
				--Time to save the day - and if we can this city.
			time = 44000,

		},
	----BuildUnits
	[getDefID("operativeinvestigator")] = 
	{
		-- This is our Investigation Operative in this theater
		-- He will do whatever it takes, to track the Cells down. We are the defensive team. We only need to fail once. 
		-- The others have all the shots. Taking them down can not be accomplished with military action.
		-- Some bloody good it would do us to have some combat outpost blasting ont he civilians who still want to life here.
		-- S/he can create safehouses and recruit civilians as spys.
		-- S/he can interrogate civilans suspected of aiding the enemy.
		-- S/he can raid houses suspected of being safehouses. 
		-- Build a safehouse inside the city. Upon creation, you will recieve further instructions.
		speach= "sounds/tutorial/protagon/operativeinvestigator.ogg",
		time = 5000,
		active = true,
		text =  "\a|Investigator Operative \n Recruits Agents\n Builds Safehouses \n Raids & Interriogates enemy installations"
	},
		[getDefID("protagonassembly")] = 
	{	--A assembly is a factory creating automated warmachines
		--All this machinery should be last and least effort. This war is not won with grenades and bullets.
		--It can easily be lost through those though.
		speach= "sounds/tutorial/assembly.ogg",
		boolUponCreation = true,
		active = true,
		time = 5000,
		text =  "\a|Assembly \n Automated factory for war-units following the mosaic standard"
	},
	[getDefID("protagonsafehouse")] = 
	{	--Home is were the safehouse is
		--No more glassy skyscrapers, no more centralization, no more banquets, glamour and partys. This is is all that remains.
		--No more lavish monetary support from outside, this game is played in nearly every place of the planet.
		--We train new agents in situ, we install other facilities in situ.
		--For now train some additional operatives and build a propagandasever. 
		--It will help us to gain support in the upcoming fight against the radicals.
		--A word of warning: If the enemy ever raids a safehouse, all personal trained within will be revealed
		speach= "sounds/tutorial/protagon/safehouse.ogg",
		boolUponCreation = true,
		active = true,
		time = 5000,
		text =  "\a|Safehouse \n Trains Operators\n Transforms into  facilitys \n Knows about all trained there"
	},	
	[getDefID("propagandaserver")] = 
	{	--This is a propagandaserverfarm
		--It helps to sway public opinion towards us, it also allows us to mine cryptocurrency and buy material.
		--Any propagandaserver amplifys what we gain or loose.
		--If the enemy kills somebody innocent or raids the wrong house, we reap what they saw.
		speach= "sounds/tutorial/protagon/propagandaserver.ogg",
		boolUponCreation = true,
		active = true,
		time = 5000,
		text =  "\a|Propagandaserver \n Creates money & material \n by swaying public opinion"
	},
	[getDefID("blacksite")] = 
	{	
		speach= "sounds/tutorial/protagon/blacksite.ogg",
		active = true,
		time = 3000,
		text =  "\a|Blacksite\n Builds ▀▀▀▀▀ which can manipulate \nthe beehiveour of civilians.\n Usage of ▀▀▀▀▀▀ is a warcrime.\n Sometimes life without parole may \n be preferable to no life at all."
	},
},
general = {

	[getDefID("nimrod")] = 
	{	-- The nimrod is a cheap to build, reliable enough railgun
		-- Used to launch low-weight microsats into super-fast orbits.
		-- Can be used in desperation to fire on other parts of the city.
		speach= "sounds/tutorial/nimrod.ogg",
		active = true,
		time = 3000,
		text =  "\a|Nimrod \n Orbital Railgun and satellite factory"
	},
	[getDefID("icon_raid")] = 
	{	--This is the Raid Interface
		--Both sides place there teams, the round ends and who aims at who, decides who is stills standing.
		--Capturing the objective gives your team another member in the next round
		--The raid  defends when the attackers are victorious or give up

		speach= "sounds/tutorial/raidIcon.ogg",
		active = true,
		time = 3000,
		text =  "\a|Raid\n Storm | Defend a Safehouse Minigame \n Click & Drag to place your units before round ends"
	},
	[operativeAssetDefID] = 
	{	--A well trained assasin
		--To deal out death, not indiscriminate, but like a surgeon, that takes somebody trained like a surgeon.

		speach= "sounds/tutorial/operativeasset.ogg",
		active = true,
		time = 3000,
		text =  "\a|Operative Asset \n Trained Assasin & Stealh operator"
	},
	[getDefID("civilianagent")] = 
	{	--A civilian recruited for our side
		--Activate him to turn this unit into a armed milita. More useful as observer then military asset though.
		--Can reveal his recruiter on capture

		speach= "sounds/tutorial/civilianagent.ogg",
		boolUponCreation = true,
		active = true,
		time = 3000,
		text =  "\a|Civilian Agent \n A recruited civilian spy"
	},
	[getDefID("nimrod")] = 
	{	-- The nimrod is a cheap to build, reliable enough railgun
		-- Used to launch low-weight microsats into super-fast orbits.
		-- Can be used in desperation to fire on other parts of the city.
		speach= "sounds/tutorial/nimrod.ogg",
		active = true,
		time = 3000,
		text =  "\a|Nimrod \n Orbital Railgun and satellite factory"
	},
}

}

local function preProcesTutorialInfoTable()
	local TutInfT = TutorialInfoTable
	for k,v in ipairs(TutInfT.general) do
	--	Spring.Echo("Preprocessing "..k.." -> "..v)
		if  TutInfT.general[k].active == nil then TutInfT.general[k].active =  true end
		if not TutInfT.general[k].time then TutInfT.general[k].time = 4000 end
		if not TutInfT.general[k].speach then TutInfT.general[k].speach = silentPlaceHolder end
	end	
	for k,v in ipairs(TutInfT.protagon) do
	--	Spring.Echo("Preprocessing "..k.." -> "..v)
		if  TutInfT.protagon[k].active == nil then TutInfT.protagon[k].active =  true end
		if not TutInfT.protagon[k].time then TutInfT.protagon[k].time = 4000 end
		if not TutInfT.protagon[k].speach then TutInfT.protagon[k].speach = silentPlaceHolder end
	end
	for k,v in ipairs(TutInfT.antagon) do
	--	Spring.Echo("Preprocessing "..k.." -> "..v)
		if  TutInfT.antagon[k].active == nil then TutInfT.antagon[k].active =  true end
		if not TutInfT.antagon[k].time then TutInfT.antagon[k].time = 4000 end
		if not TutInfT.antagon[k].speach then TutInfT.antagon[k].speach = silentPlaceHolder end
	end

return TutInfT
end

TutorialInfoTable =	preProcesTutorialInfoTable()

function widget:Initialize()	
		local myTeamID= spGetMyTeamID()
		local playerID = spGetMyPlayerID()
		local tname,_, tspec, myTeamID, tallyteam, tping, tcpu, tcountry, trank = spGetPlayerInfo(playerID)
		if tspec then widgetHandler:RemoveWidget(self); return end

		mySide     = select(5, spGetTeamInfo(myTeamID)) 
		if mySide == nil then widgetHandler:RemoveWidget(self); return end

		Spring.SetConfigInt("mosaic_startupcounter", Spring.GetConfigInt("mosaic_startupcounter",0) + 1 )
		if  Spring.GetConfigInt("mosaic_startupcounter",0) > 2 and not boolDebug then widgetHandler:RemoveWidget(self); return end

		if (mySide ~= nil and (mySide == "antagon" or mySide == "protagon")) == false then

			if Spring.GetTeamUnitsByDefs(myTeamID, OperativePropagatorDefID) then
				mySide = "antagon"
			end
			if Spring.GetTeamUnitsByDefs(myTeamID, OperativeInvestigatorDefID) then
				mySide = "protagon"
			end

			if  (mySide ~= nil and (mySide == "antagon" or mySide == "protagon"))== false  then
				mySide = "antagon"
			end
		end
		
	startFrame = Spring.GetGameFrame()
end

---------------------------------------------------------------------------
-- Code
---------------------------------------------------------------------------
local function PlayWelcomeConditional(t)	

	if TutorialInfoTable and TutorialInfoTable.welcome and TutorialInfoTable.welcome.active == true then 
		local mouseX,mouseY=Spring.GetMouseState()
		local types,tables=spTraceScreenRay(mouseX,mouseY)
		if types == "ground" then
			Spring.MarkerAddPoint(  tables[1], tables[2], tables[3], TutorialInfoTable[mySide].intro.text, true)
		end
		spPlaySoundFile(TutorialInfoTable[mySide].intro.speach,1)
		TutorialInfoTable[mySide].intro.active = false
		return true, TutorialInfoTable[mySide].intro.time
	end

	if TutorialInfoTable[mySide].welcome.active == true then
		spPlaySoundFile(TutorialInfoTable[mySide].welcome.speach,1)
		TutorialInfoTable[mySide].welcome.active = false

		return true, TutorialInfoTable[mySide].welcome.time
	end	

	return false, 0
end

local function PlaySoundAndMarkUnit(defID, exampleUnit)	
	x,y,z=spGetUnitPos(exampleUnit)
	if x then
		Spring.SendCommands({"clearmapmarks"})
		if TutorialInfoTable[mySide][defID].text then
			Spring.MarkerAddPoint( x, y, z, TutorialInfoTable[mySide][defID].text, true)
		elseif TutorialInfoTable.general[defID].text then
			Spring.MarkerAddPoint( x, y, z, TutorialInfoTable.general[defID].text, true)
		end

		if TutorialInfoTable[mySide][defID].speach then
			Spring.PlaySoundFile(TutorialInfoTable[mySide][defID].speach,1, x, y, z, 0, 0, 0, "ui")
		elseif TutorialInfoTable.general[defID].speach then
			Spring.PlaySoundFile(TutorialInfoTable.general[defID].speach,1, x, y, z, 0, 0, 0, "ui")
		end	
	end
end

function widget:Shutdown()
	Spring.Echo("Deactivated Tutorial - you can reactivate via the Widget-Manager (Press F11)")
end

local function playUnitExplaination()
	local selectedUnits = spGetSelectedUnits()

	if selectedUnits then
		for num, id in pairs(selectedUnits) do
		local defID = spGetUnitDefID(id)
			if defID and 
			(TutorialInfoTable[mySide] and TutorialInfoTable[mySide][defID] and TutorialInfoTable[mySide][defID].active ) or 
			(TutorialInfoTable.general[defID] and TutorialInfoTable.general[defID].active )
			 then
				PlaySoundAndMarkUnit(defID, id)
				TutorialInfoTable[mySide][defID].active = false
				TutorialInfoTable.general[defID].active = false
				return true, TutorialInfoTable[defID].time
			end	
		end
	end

	return false, 0
	end

local OnAirTillTimeFrame = 0
local boolOnAir = false

function widget:GameFrame(t)
	local timeOnAirMS = 0
	if t > startFrame + 90 and t > OnAirTillTimeFrame then
		boolOnAir = false 
		if boolTutorialActive == true and  t % 10 == 0   then
			boolOnAir, timeOnAirMS = PlayWelcomeConditional(t)
			if boolOnAir == false then 
				boolOnAir, timeOnAirMS = playUnitExplaination()
			end

			if boolOnAir == true then
				OnAirTillTimeFrame = math.max(OnAirTillTimeFrame, t) + (math.ceil(timeOnAirMS  /1000) *30)
			end
		end
	end
end

function widget:UnitCreated(unitID, unitDefID)
	if TutorialInfoTable[raidIconDefID] and TutorialInfoTable[raidIconDefID].active == true and TutorialInfoTable[raidIconDefID].boolUponCreation  then
			PlaySoundAndMarkUnit(unitDefID, unitID)
			OnAirTillTimeFrame = math.max(OnAirTillTimeFrame,t) + (math.ceil(TutorialInfoTable[raidIconDefID].time  /1000) *30)
			TutorialInfoTable[raidIconDefID].active = false
	end
end

