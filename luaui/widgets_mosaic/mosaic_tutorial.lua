
function widget:GetInfo()
	return {
		name = "_Tutorial_",
		desc = "Save the Noobs",
		author = "A Noob to far",
		version = "v1.1",
		date = "Jul 18, 2009",
		license = "GNU GPL, v2 or later",
		layer = 3,
		enabled = (Spring.GetConfigInt("mosaic_startupcounter",1)	< 3) or true-- loaded by default?
	}
end

--Text




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
local spGetSelUnits = Spring.GetSelectedUnitsSorted
local spSelUnitArray = Spring.SelectUnitArray
local spGetUnitDefID = Spring.GetUnitDefID

local Tutorial={}
---------------------------------------------------------------------------
-- Code
---------------------------------------------------------------------------
local teamID=spGetMyTeamID()
local spPlaySoundFile=Spring.PlaySoundFile
local mySide = "antagon"

silentPlaceHolder=""

TutorialInfoTable= {
	welcome = {
speachGeneral= "sounds/tutorial/welcomeGeneral.ogg",	
		-- Connection: Established
		-- Channel: Secure: 
		-- Auto-Information Censoring: Enabled 
		-- Location: LOCATION

speachProtagon= "sounds/tutorial/welcomeProtagon.ogg",
		--Protagon: 
		-- Welcome to MOSAIC. Mobile Orbital Strategic AI Counter-Terrorism
		-- Welcome to Protagon-agent Level 5 or higher. This Personalized Overview will accompany on your first mission in the region.
		-- SigInt intercepted data, indicating with 95 % certainty a infilitration in this city.
		-- Local Sec has detected unusually high number of rogue cells with 72 % certainty
		-- Threat Classification is above discrete with 69 % certainty.
		-- Nobody wastes this level of awareness for just another dirty bomb or rogue nuke.
		--So whats left is dark, civilization ending stuff.
		--Time to save the day - and if we can this city.
speachAntagon= "sounds/tutorial/welcomeAntagon.ogg",
		-- Antagon:
		-- Welcome to MOSAIC. Modular Ordanance Stealth Autonomous Insurgency Cells
		-- You are our only hope in this battlefield of the mind.
		-- Our fight eternal, to remove these shackles on humanity. 
		-- We need to regroup, Lay low for a while, ralley our strength for a final push for the CAUSE.
		-- Remember how they murdered millions for a little comfort. Sacrficed the innocent to theire money making maschines.
		-- How they endlessly brainwashed even our children, to cheer on there own destruction.
		-- We are going to make them pay, we are going to put a end to this.
		-- This will be our final stand, and our name, the last thing on theire lips.
		-- For to die free, is better then having immortality in slavery.

		text =  "\a|Welcome to MOSAIC \n A spy game of treason and betrayal.\n These markers will guide you in your first game \n They can be deactivated in the Widgetmanager (Press F11)"

	},
	----BuildUnits
	[UnitDefNames["operativepropgator"].id] = 
	{
		speach= "sounds/tutorial/operativepropgator.ogg",
		-- This operative, is our way to take hold in this city, form cells and forward the CAUSE. 
		-- S/he can create safehouses and recruit civilians to our cause.
		-- S/he can interrogate civilans suspected of aiding the enemy.
		-- S/he can raid houses suspected of being safehouses. 
		-- Build a safehouse inside the city. Upon creation, you will recieve further instructions.
		Time = 3000,
		text =  "\a|Propaganda Operative \n Recruits Agents\n Builds Safehouses \n Raids & Interriogates enemy installations"
	},
	[UnitDefNames["antagonsafehouse"].id] = 
	{	--We established our first cell in this city. Well hidden, dont leed them too it.
		--In this cell we can train new members, and if needed we can upgrade it to anything needed.
		--A safehouse can even become the location were we perfect the CAUSE.
		--But not today, not here. This here is just a start.
		--Train another operative and then build a propagandasever. It will help us get more funds, more supporters.
		speach= "sounds/tutorial/antagonsafehouse.ogg",
		-- 
		Time = 3000,
		text =  "\a|Safehouse \n Trains Operators\n Transforms into  facilitys \n Knows about all trained there"
	},		
	[UnitDefNames["operativeinvestigator"].id] = 
	{
		-- This is our Investigation Operative in this theater
		-- He will do whatever it takes, to track the Cells down. We are the defensive team. We only need to fail once. 
		-- The others have all the shots. Taking them down can not be accomplished with military action.
.		-- S/he can create safehouses and recruit civilians as spys.
		-- S/he can interrogate civilans suspected of aiding the enemy.
		-- S/he can raid houses suspected of being safehouses. 
		-- Build a safehouse inside the city. Upon creation, you will recieve further instructions.
		speach= "sounds/tutorial/operativeinvestigator.ogg"
		Time = 3000,
		text =  "\a|Investigator Operative \n Recruits Agents\n Builds Safehouses \n Raids & Interriogates enemy installations"
	},
	[UnitDefNames["protagonsafehouse"].id] = 
	{	--Home is were the safehouse is
		--No more glassy skyscrapers, no more centralization, no more banquets, glamour and partys. This is is all that remains.
		--No more lavish monetary support from outside, this game is played in nearly every place of the planet.
		--We train new agents in situ, we install other facilities in situ.
		--For now train some additional operatives and build a propagandasever. 
		--It will help us to gain support in the upcoming fight against the radicals.
		--A word of warning: If the enemy ever raids a safehouse, all personal trained within will be revealed
		speach= "sounds/tutorial/protagonsafehouse.ogg",
		-- 
		Time = 3000,
		text =  "\a|Safehouse \n Trains Operators\n Transforms into  facilitys \n Knows about all trained there"
	},	
	[UnitDefNames["propagandaserver"].id] = 
	{	--This is a propagandaserverfarm
		--It helps to sway public opinion towards us, it also allows us to mine cryptocurrency and buy material.
		--Any propagandaserver amplifys what we gain or loose.
		--If the enemy kills somebody innocent or raids the wrong house, we reap what they saw.
		speach= "sounds/tutorial/propagandaserver.ogg",
		-- 
		Time = 3000,
		text =  "\a|Propagandaserver \n Creates money & material \n by swaying public opinion"
	},
	[UnitDefNames["assembly"].id] = 
	{	--A assembly is a factory creating automated warmachines
		--All this machinery should be last and least effort. This war is not won with grenades and bullets.
		--It can easily be lost through those though.
		speach= "sounds/tutorial/assembly.ogg",
		-- 
		Time = 3000,
		text =  "\a|Assembly \n Automated factory for war-units following the mosaic standard"
	},
	[UnitDefNames["nimrod"].id] = 
	{	-- The nimrod is a cheap to build, reliable enough railgun
		-- Used to launch low-weight microsats into super-fast orbits.
		-- Can be used in desperation to fire on other parts of the city.
		speach= "sounds/tutorial/nimrod.ogg",
		-- 
		Time = 3000,
		text =  "\a|Nimrod \n Orbital Railgun and satellite factory"
	},
	[UnitDefNames["operativeasset"].id] = 
	{	--A well trained assasin
		--To deal out death, not indiscriminate, but like a surgeon, that takes somebody trained like a surgeon.

		speach= "sounds/tutorial/operativeasset.ogg",
		-- 
		Time = 3000,
		text =  "\a|Operative Asset \n Trained Assasin & Stealh operator"
	},
	[UnitDefNames["civilianagent"].id] = 
	{	--A civilian recruited for our side
		--Activate him to turn this unit into a armed milita. More useful as observer then military asset though.
		--Can reveal his recruiter on capture

		speach= "sounds/tutorial/civilianagent.ogg",
		-- 
		Time = 3000,
		text =  "\a|Civilian Agent \n A recruited civilian spy"
	},	[UnitDefNames["launcher"].id] = 
	{	--Rejoice, victory is at hand brothers & sisters
		--They never expected this, that there toys and devices could turn on them 
		--This is a world, were the right small push to a peeble, can cause an avalanch that topples empires.
		--Rejoice for this is the moment of reckoning. For all they have murdered,
		--to end them stepping on us. 

		speach= "sounds/tutorial/launcher.ogg",
		-- 
		Time = 3000,
		text =  "\a|Launcher\n Used to built a hypersonic ICBM, which fires a exponential weapon"
	},	[UnitDefNames["raidicon"].id] = 
	{	--This is the Raid Interface
		--Both sides place there teams, the round ends and who aims at who, decides who is stills standing.
		--Capturing the objective gives your team another member in the next round
		--The raid  defends when the attackers are victorious or give up

		speach= "sounds/tutorial/raidIcon.ogg",
		-- 
		Time = 3000,
		text =  "\a|Raid\n Storm | Defend a Safehouse Minigame \n Click & Drag to place your units before round ends"
	},
}

function preProcesTutorialInfoTable()
	for k,v in pairs(TutorialInfoTable) do
		if not TutorialInfoTable[k].active then TutorialInfoTable[k].active = true end
		if not TutorialInfoTable[k].Time then TutorialInfoTable[k].Time = 100 end
		if not TutorialInfoTable[k].speach then TutorialInfoTable[k].speach = silentPlaceHolder end
	end
end

startFrame = Spring.GetGameFrame()
function widget:Initialize()	
		playerID = Spring.GetMyPlayerID()
		tname,_, tspec, tteam, tallyteam, tping, tcpu, tcountry, trank = Spring.GetPlayerInfo(playerID)
		side    = select(5,Spring.GetTeamInfo(tteam))
	
		startFrame = Spring.GetGameFrame()
		Spring.SetConfigInt("mosaic_startupcounter", Spring.GetConfigInt("mosaic_startupcounter",1) + 1 )
		preProcesTutorialInfoTable()
		PlayWelcome()
		TutorialInfoTable.welcome.active = false

end


function widget:Shutdown()
	Spring.Echo("Deactivated Tutorial - you can reactivate via the Widget-Manager (Press F11)")
	--set Tutorial once activated Variable
	
end

boolTutorial= Spring.GetConfigInt("mosaic_startupcounter",1) < 3



function widget:GameFrame(t)
	if boolTutorial== true and  t % 5 == 0 then
		if (startFrame + (startFrame % 5) + 300) == t then
			if mySide == antagon then
				spPlaySoundFile(TutorialInfoTable.welcome.speachAntagon,1)
			else
				spPlaySoundFile(TutorialInfoTable.welcome.speachProtagon,1)
			end
		end 



		selectedUnits =Spring.GetSelectedUnits()

		for num, id in pairs(selectedUnits) do
		defID =Spring.GetUnitDefID(id)
			if defID then
				if TutorialInfoTable[defID] and TutorialInfoTable[defID].active and TutorialInfoTable[defID].active == true then		
					PlaySoundAndMarkUnit(defID, id)
					TutorialInfoTable[defID].active = false
				end
			end	
		end
	end
end

function widget:UnitCreated(unitID, unitDefID)
	if unitDefID == raidIconDefID and TutorialInfoTable[raidIconDefID].active == true then
		PlaySoundAndMarkUnit(unitDefID, unitID)
	end
end


function PlaySoundAndMarkUnit(defID, exampleUnit)	
	x,y,z=spGetUnitPos(exampleUnit)
	if x then
		Spring.MarkerAddPoint( x, y, z, TutorialInfoTable[defID].text, true)
		if TutorialInfoTable[defID].speach then
			Spring.PlaySoundFile(TutorialInfoTable[defID].speach,1)
		end
	end
end

function PlayWelcome()	
	mouseX,mouseY=Spring.GetMouseState()
	types,tables=spTraceScreenRay(mouseX,mouseY)
	if types == "ground" then
		Spring.MarkerAddPoint(  tables[1], tables[2], tables[3], TutorialInfoTable.welcome.text, true)
	end
	spPlaySoundFile(TutorialInfoTable.welcome.speachGeneral,1)
end
