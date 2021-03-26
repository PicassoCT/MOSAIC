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

----------------------------------------------------------------


local xRelPos, yRelPos		= 0.835, 0.88	-- (only used here for now)
local vsx, vsy				= gl.GetViewSizes()
local xPos, yPos            = xRelPos*vsx, yRelPos*vsy

local panelWidth = 200;
local panelHeight = 55;

local sizeMultiplier = 1

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
------------------------------------------------------------------

local nextComFrame = Spring.GetGameFrame()
function widget:Initialize()
	Spring.Echo("Initialize Comm Chatter")
	nextComFrame = Spring.GetGameFrame()
end

function widget:Shutdown()
end


local selectedUnits= {}
function widget:CommandsChanged( id, params, options )
	selectedUnits = Spring.GetSelectedUnits()
end

function createIdentifierFromID(id, defID)

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

function getCommandStringFromDefID(defID)
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
function addSoundPath(baseString)
	return "/sounds/comchat/"..baseString..".ogg", soundFilesLengthInFrames[baseString]
end

function getCommandTarget(x,y)
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

function getIdentifierFromID(id)
		local idStr = (id % 100)..""

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

local function buildSoundCommand(units, x, y)
	if not units or #units < 1 then return end
	if not x or not y then return end

--highest priority unit
local higestOrderDefID, id = getHighestOrderUnit(units)

--command type
local subjectName, subjectTime = getCommandStringFromDefID(higestOrderDefID)
local subjectIdentifier = createIdentifierFromID(id, higestOrderDefID)

local actionSound, actionTime = getActionSound(id)

--object
local objectData = getObjectSounds(x,y)

if not subjectName or not actionSound or not objectSounds then return end

addCommandStack(createSubject(subjectName, subjectIdentifier, subjectTime),
				createAction(actionSound, actionTime),
				createObject(objectData.sounds, objectData.times)
				)
end

function createSubject(sound, identifier, time)
	return {sound = addSoundPath(sound), identifier = identifier, time = time}
end

function createAction(sound, time)
	return {sound = addSoundPath(sound), time = time}
end

function createObject(sounds, times)
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

commandStack ={
--[[	[1]={ subject = {sound ="", identifier = 1 time=2000},
		  action = {sound ="", time=2000},
		  object = {
		  		soundList={sound ="", time=2000}
		  		..-
		  }
--]]
}

function widget:MouseRelease(x, y, mButton)
		-- Only left click
		Spring.Echo(mButton)
	if (mButton == 1) then 	
		Spring.Echo("Left clicked on location", location )
		buildSoundCommand(selctedUnits, x,y)
	end
	
end

local function playCurrentComset(frame, currentComSetIndex)
	if not currentComSetIndex then return end
	local boolComSetActive = false

	local currentComSet = commandStack[currentComSetIndex]

	--play subject
	if currentComSet.subject.time > 0 then
		Spring.Echo("ComChatter:".. currentComSet.subject.sound.." -> ".. currentComSet.subject.identifier )
		local totalTime = currentComSet.subject.time 
		commandStack[currentComSetIndex].subject.time = 0
		return true, frame + totalTime
	end

	--play action
	if currentComSet.action.time > 0 then
	Spring.Echo("ComChatter:".. currentComSet.action.sound )
		local totalTime = currentComSet.action.time 
		commandStack[currentComSetIndex].action.time = 0
		return true, frame + totalTime
	end

	--play object list
	for i=1, #currentComSet.object.soundList do
		if currentComSet.object.soundList[i].time > 0 then
			Spring.Echo("ComChatter:"..currentComSet.object.soundList[i].sound)
			local totalTime = commandStack[currentComSetIndex].object.soundList[i].time
			commandStack[currentComSetIndex].object.soundList[i].time = 0
			return true, frame + totalTime
		end
	end

	commandStack[currentComSetIndex] = nil
	return false, frame
end

local currentComSetIndex =0
local boolComSetActive = false
function widget:GameFrame(n)
	if n % 5 == 0 and n > nextComFrame then
		if not boolComSetActive then
		if commandStack and #commandStack > 0 then
			for nr, comSet in pairs(commandStack) do
				if comSet then
					boolComSetActive = true
					currentComSetIndex = nr
					break
				end
			end
		end
		else
			boolComSetActive, nextComFrame = playCurrentComset(n, currentComSetIndex)
		end
	end
end


