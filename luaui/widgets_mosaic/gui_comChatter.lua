local versionNumber = "2.03"

function widget:GetInfo()
	return {
		name      = "ComChatter",
		desc      = "Creates com chatter from unit commands",
		author    = "pica",
		date      = "1.1.2021",
		license   = "GNU GPL v2",
		layer     = 10000-1,
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

local function createIdentifierFromID(id)
	local sounds, times = {}, {}
	local idStr = (id % 99)..""
	sounds[#sounds+1], times[#times+1] =getNatoPhoneticsTime(idStr[1])
	sounds[#sounds+1], times[#times+1] =getNatoPhoneticsTime(idStr[2])
	return sounds, times
end

local function getDefIDFromName(name)
	for id, udef in pairs(udefs) do
		if udef.name == name then
			return id
		end
	end
end

local assetDefID = getDefIDFromName("operative_asset")
local civilianAgentDefID = getDefIDFromName("civilian_agent")
local operativeTypeTable = {
	[getDefIDFromName("operativeinvestigator")] = true,
	[getDefIDFromName("operativepropagator")] = true
	}

local civilianWalkingTypeTable = {
		[getDefIDFromName("civilian_arab0")] = true,
		[getDefIDFromName("civilian_arab1")] = true,
		[getDefIDFromName("civilian_arab2")] = true,
		[getDefIDFromName("civilian_arab3")] = true,
}

local function getCommandStringFromDefID(defID)
	if civilianWalkingTypeTable[defID] then
		return "_neutral", 1000
	end

	if civilianAgentDefID ==  defID then
		return "_mobile", 1000
	end

	if operativeTypeTable[defID] then
		return "_operative", 1000
	end

	if udefs[defID].isbuilding then
		return "_safehouse", 1000
	end

	if assetDefID == defID then
		return "_asset", 1000
	end

	if udefs[defID].canattack == true then
		return "_strike", 1000
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

local function doesUnitExistAlive(id)
    local valid = Spring.ValidUnitID(id)
    if valid == nil or valid == false then
        -- echo("doesUnitExistAlive::Invalid ID")
        return false
    end

    local dead = Spring.GetUnitIsDead(id)
    if dead == nil or dead == true then
        -- echo("doesUnitExistAlive::Dead Unit")
        return false
    end

    return true
end


local QuadrantSize = 512
local function getQuadrant(x,z)
	return math.ceil(x/QuadrantSize), math.ceil(z/QuadrantSize)
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
 
local function createSubject(sound, times, identifierSounds, identifierTimes)
	local soundList = {}
	soundList[#soundList+1] = {sound =addSoundPath(sound) , times = times}

	for i=1, #identifierSounds do
		soundList[#soundList+1] = {}
		soundList[#soundList].sound =		identifierSounds[i]
		soundList[#soundList].times =		identifierTimes[i]
	end

	return {soundList = soundList}
end
local function buildSoundCommand( x, y)
	local units = Spring.GetSelectedUnits()
	Spring.Echo("PrintDebug 1")
	if not units or #units < 1 then 
		Spring.Echo("Called it 1")
		return 
	end
	Spring.Echo("PrintDebug 2")
	if not x or not y then 
	Spring.Echo("Called it 2")
	return
	end
	Spring.Echo("PrintDebug 3")
	--highest priority unit

	local resultID 
	local maxHP = -1
	local higestOrderDefID

	for i=1, #units do
		local id = units[i]
		if id and doesUnitExistAlive(id) == true then
			local defID  = spGetUnitDefID(id)
			if i==1 or defID and udefs[defID] and udefs[defID].speed and udefs[defID].speed > 0 then
				if i == 1 or udefs[defID] and udefs[defID].damage and udefs[defID].damage > maxHP then
						maxHP = udefs[defID].damage 
						resultID = id
						higestOrderDefID = defID
				end		
			end
		end
	end


	Spring.Echo("PrintDebug 4")
	--command type
	local subjectName, subjectTime
	local subjectName, subjectTime = getCommandStringFromDefID(higestOrderDefID)
	local subjectIdentifier, subjectIdentifierTimes
	local subjectIdentifierSounds,subjectIdentifierTimes = createIdentifierFromID(resultID, higestOrderDefID)
	Spring.Echo("PrintDebug 5")
	local actionSound, actionTime 
	local actionSound, actionTime = getActionSound(resultID)

	--object
	local objectData 
	local objectData = getObjectSounds(x,y)

	if not subjectName or not actionSound or not objectSounds then 
		Spring.Echo("Called it 3")
		return 
	end

	addCommandStack(createSubject(subjectName,subjectTime, subjectIdentifierSounds, subjectIdentifierTimes),
					createAction(actionSound, actionTime),
					createObject(objectData.sounds, objectData.times)
					)
end

local function createAction(sound, times)
	return {sound = addSoundPath(sound), times = times}
end

local function createObject(sounds, times)
	local result={}
	for i=1,#sounds do
		result[#result+1] = {sound = addSoundPath(sounds[i]), times = times[i]}
	end
	return result
end

local function addCommandStack(subject, action, object)
	Spring.Echo("Gui_ComChatter:addCommandStack")
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
		  action = {sound ="", times=2000},
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
		if currentComSet.subject.soundList[i].times > 0 then
			Spring.Echo("ComChatter:"..currentComSet.subject.soundList[i].sound)
			local totalTime = commandStack[currentComSetIndex].subject.soundList[i].times
			commandStack[currentComSetIndex].subject.soundList[i].times = 0
			return  frame + totalTime
		end
	end

	--play action
	if currentComSet.action.times > 0 then
	Spring.Echo("ComChatter:".. currentComSet.action.sound )
		local totalTime = currentComSet.action.times 
		commandStack[currentComSetIndex].action.times = 0
		return frame + totalTime
	end

	--play object list
	for i=1, #currentComSet.object.soundList do
		if currentComSet.object.soundList[i].times > 0 then
			Spring.Echo("ComChatter:"..currentComSet.object.soundList[i].sound)
			local totalTime = commandStack[currentComSetIndex].object.soundList[i].times
			commandStack[currentComSetIndex].object.soundList[i].times = 0
			return frame + totalTime
		end
	end

	commandStack[currentComSetIndex] = nil
	return  frame
end



function widget:MousePress(x, y, button)
	Spring.Echo("Gui_ComChatter:GameFrame MousePress"..button.." "..type(button))
	if (button == 3) then 	

		buildSoundCommand( x, y)
	end
	return false
end

local currentComSetIndex = 1
local boolComSetActive = false
local accumulatedDT = 0.0
function widget:Update(dt)
	accumulatedDT = accumulatedDT + dt
	if accumulatedDT > 0.5 and Spring.GetGameFrame() > nextComFrame then
	accumulatedDT = 0

		if not boolComSetActive then
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

