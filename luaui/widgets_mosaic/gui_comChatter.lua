include("keysym.h.lua")
local versionNumber = "2.03"

function widget:GetInfo()
	return {
		name      = "ComChatter",
		desc      = "Creates com chatter from unit commands",
		author    = "pica",
		date      = "1 1, 2021",
		license   = "GNU GPL v2",
		layer     = -15,
		handler   = true,
		enabled   = true
	}
end

--callin driven
--"hot" units

local floor                 = math.floor
local abs					= math.abs

local udefs					= UnitDefs
local spGetUnitDefID        = Spring.GetUnitDefID
local spEcho                = Spring.Echo
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spGetMyPlayerID       = Spring.GetMyPlayerID
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spGetLocalTeamID		= Spring.GetLocalTeamID
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local spSelectUnitMap		= Spring.SelectUnitMap
local spGetTeamColor 		= Spring.GetTeamColor
local spGetGroundHeight 	= Spring.GetGroundHeight
local spIsSphereInView  	= Spring.IsSphereInView
local spGetSpectatingState	= Spring.GetSpectatingState
local spGetGameSeconds		= Spring.GetGameSeconds
local spIsGUIHidden			= Spring.IsGUIHidden

local spec = false
local showGui = false
local playerIsSpec = {}

--Internals------------------------------------------------------
local nextPlayerPoolId = 1
local myTeamID = Spring.GetMyTeamID()
local myPlayerID = Spring.GetMyPlayerID()
local playerSelectedUnits = {}
local hotUnits = {}
local circleLinesCoop
local circleLinesAlly
local lockPlayerID

local unitConf ={}
local selectedUnits = {}
------------------------------------------------------------------

local nextComFrame = Spring.GetGameFrame() + 1
function widget:Initialize()
	Spring.Echo("Initialize Comm Chatter")
	nextComFrame = Spring.GetGameFrame() + 1
	return true
end

function widget:Shutdown()
	Spring.Echo("Comchatter shutting down")
	return true
end

local function createIdentifierFromID(id, defID)
	local sounds, times = {}, {}
	local idStr = (id % 99)..""
	sounds[#sounds+1], times[#times+1] =getNatoPhoneticsTime(idStr[1])
	sounds[#sounds+1], times[#times+1] =getNatoPhoneticsTime(idStr[2])
	return sounds, times
end

local function getDefIDFromName(name)
	for i=1,#UnitDefs do
		if UnitDefs[i].name == name then
			return UnitDefs[i].id
		end
	end
end

local assetDefID = getDefIDFromName("operative_asset")
local civilianAgentDefID = getDefIDFromName("civilian_agent")
local operativeTypeTable = {
	[getDefIDFromName("operativeinvestigator")] = true,
	[getDefIDFromName("operativepropagator")] = true
	}

local function getCommandStringFromDefID(defID)
	if civilianWalkingTypeTable[defID] then
		return "_neutral"
	end

	if civilianAgentDefID ==  defID then
		return "_mobile"
	end

	if operativeTypeTable[defID] then
		return "_operative"
	end

	if UnitDefs[defID].isbuilding then
		return "_safehouse"
	end

	if assetDefID == defID then
		return "_asset"
	end

	if UnitDefs[defID].canattack == true then
		return "_strike"
	end

	return "_mobile"
end

local soundFilesLengthInFrames = {}
local function addSoundPath(baseString)
	return "/sounds/comchat/"..baseString..".ogg", soundFilesLengthInFrames[baseString]
end

local function getCommandTarget(x,y)
	typestring, result = Spring.TraceScreenRay(x,y)
	return typestring, result
end

local function getNatoPhoneticsTime(letter)
	local NatoPhoneticAlphabet = {
    a="alpha",
    b="bravo",
    c="charlie",
    d="delta",
    e="echo",
    f="foxtrot",
    g="golf",
    h="hotel",
    i="india",
    j="juliet",
    k="kilo",
    l="lima",
    m="mike",
    n="november",
    o="oscar",
    p="papa",
    q="quebec",
    r="romeo",
    s="sierra",
    t="tango",
    u="uniform",
    v="victor",
    w="whisky",
    x="xray",
    y="yankee",
    z="zulu",
    [0]= "zero",
    [1]= "one",
    [2]= "two",
    [3]= "three",
    [4]= "four",
    [5]= "five",
    [6]= "six",
    [7]= "seven",
    [8]= "eight",
    [9]= "niner",
    }
return NatoPhoneticAlphabet[string.lower(letter)], 2 *30
end

local function getHighestOrderUnit(units)
	local maxHP = math.huge*-1
	local resultID, resultDefID

	for i=1, #units do
		local defID  = Spring.GetUnitDefID(units[i])
		if defID then
			if udefs[defID].maxDamage > maxHP then
				maxHP = udefs[defID].maxDamage
				resultID = units[i]
				resultDefID = defID
			end
		end
	end
	return resultDefID, resultID
end

local QuadrantSize = 512
local function getQuadrant(x,z)
	return x/QuadrantSize, z/QuadrantSize
end

local function dec2hex(num)
    local hexstr = '0123456789abcdef'
    local s = ''

    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
    return s
end


local function getObjectSounds(x,y)
 	--Unit getCommandStringFromDefID
	goalType, goalLocation = getCommandTarget(x,y)
	local objectData ={ sounds={}, times = {}}

	if not goalType then
		return 
	end

	if goalType == "unit" then
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = "_at" , 15
		local objectName, objectTime = getCommandStringFromDefID(Spring.GetUnitDefID(goalLocation))
		objectData.sounds[#objectData.sounds + 1] = objectName
		objectData.times[#objectData.times + 1] = objectTime
	end

	if goalType == "feature" then
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = "_near" , 30
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = getNatoPhoneticsTime("F")
		
		local FeatureName = FeatureDefs[Spring.GetFeatureDefID(goalLocation)].name
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = getNatoPhoneticsTime(FeatureName[1])
	end

	if goalType == "ground" then
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = "_to" , 15
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = "_sector" , 30

		local x,z = goalLocation[1],goalLocation[3]
		x,z = getQuadrant(x,z)
		xHex, zHex = dec2hex(x),dec2hex(z)
		for s=1,string.len(xHex)do
			objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = getNatoPhoneticsTime(xHex[s])
		end
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = " " , 30
		for s=1,string.len(zHex)do
			objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = getNatoPhoneticsTime(zHex[s])
		end
	end
	--Grid
 	return objectData
 end
local function createSubject(sound, time, identifierSounds, identifierTimes)
	local soundList = {}
	soundList[#soundList+1] = {sound =addSoundPath(sound) , time = time}

	for i=1, #identifierSounds do
		soundList[#soundList+1] = {}
		soundList[#soundList].sound =		identifierSounds[i]
		soundList[#soundList].time =		identifierTimes[i]
	end

	return {soundList = soundList}
end
local function buildSoundCommand(units, x, y)
	if not units or #units < 1 then return end
	if not x or not y then return end

	--highest priority unit
	local higestOrderDefID, id
	higestOrderDefID, id = getHighestOrderUnit(units)

	--command type
	local subjectName, subjectTime
	subjectName, subjectTime = getCommandStringFromDefID(higestOrderDefID)
	local subjectIdentifier, subjectIdentifierTimes
	subjectIdentifierSounds,subjectIdentifierTimes = createIdentifierFromID(id, higestOrderDefID)

	local actionSound, actionTime 
	actionSound, actionTime = getActionSound(id)

	--object
	local objectData 
	objectData = getObjectSounds(x,y)

	if not subjectName or not actionSound or not objectSounds then return end

	addCommandStack(createSubject(subjectName,subjectTime, subjectIdentifierSounds, subjectIdentifierTimes),
					createAction(actionSound, actionTime),
					createObject(objectData.sounds, objectData.times)
					)
end



local function createAction(sound, time)
	return {sound = addSoundPath(sound), time = time}
end

local function createObject(sounds, times)
	local result={}
	for i=1,#sounds do
		result[#result+1] = {sound = addSoundPath(sounds[i]), time = times[i]}
	end
	return result
end

function addCommandStack(subject, action, object)
local objectToInsert ={
	subject = subject,
	action = action,
	object = object
	}

	--duplicate detection
	if commandStack[#commandStack].subject ~= objectToInsert.subject and
		commandStack[#commandStack].action ~= objectToInsert.action and
		commandStack[#commandStack].object ~= objectToInsert.object then
		commandStack[#commandStack + 1] = objectToInsert
	end
end

local commandStack ={
--[[	[1]={ subject = {soundList = {}},
		  action = {sound ="", time=2000},
		  object = {
		  		soundList= {}}
		  		
		  }
--]]
}

local function playCurrentComset(frame, currentComSetIndex)
	if not currentComSetIndex then return end

	local currentComSet = commandStack[currentComSetIndex]

	--play subject
	for i=1, #currentComSet.subject.soundList do
		if currentComSet.subject.soundList[i].time > 0 then
			Spring.Echo("ComChatter:"..currentComSet.subject.soundList[i].sound)
			local totalTime = commandStack[currentComSetIndex].subject.soundList[i].time
			commandStack[currentComSetIndex].subject.soundList[i].time = 0
			return  frame + totalTime
		end
	end

	--play action
	if currentComSet.action.time > 0 then
	Spring.Echo("ComChatter:".. currentComSet.action.sound )
		local totalTime = currentComSet.action.time 
		commandStack[currentComSetIndex].action.time = 0
		return frame + totalTime
	end

	--play object list
	for i=1, #currentComSet.object.soundList do
		if currentComSet.object.soundList[i].time > 0 then
			Spring.Echo("ComChatter:"..currentComSet.object.soundList[i].sound)
			local totalTime = commandStack[currentComSetIndex].object.soundList[i].time
			commandStack[currentComSetIndex].object.soundList[i].time = 0
			return frame + totalTime
		end
	end

	commandStack[currentComSetIndex] = nil
	return  frame
end

function widget:MouseRelease(x, y, mButton)
		-- Only left click
		Spring.Echo(mButton)
		selectedUnits = Spring.GetSelectedUnits()
	if (mButton == 1) then 	
		Spring.Echo("Left clicked on location", location )
		buildSoundCommand(selctedUnits, x,y)
	end
	
end

local currentComSetIndex = 1
local boolComSetActive = false
function widget:GameFrame(n)

	if n % 5 == 0 and n > nextComFrame then

		if boolComSetActive == false then
			if commandStack and #commandStack > 0 then
				Spring.Echo("ComChatter new ComFrame")
				for nr, comSet in ipairs(commandStack) do
					if comSet then
						boolComSetActive = true
						currentComSetIndex = nr
						break
					end
				end
			end
		else
			boolComSetActive, nextComFrame = playCurrentComset(n, currentComSetIndex)
			Spring.Echo("ComChatter Comframe worked off")
		end
	end
end

