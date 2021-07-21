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
local loudness = 0.15
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

local function addSoundPath(sex, baseString)
	assert(baseString)
	assert(baseString ~= "")
	return "sounds/comchatter/"..sex.."/"..baseString..".ogg"
end


local function getNatoPhoneticsTime(letter)
	if not letter then return end
	local letter = string.lower(letter)
	local NatoPhoneticAlphabet = {
    ["a"]="alpha",
    ["b"]="bravo",
    ["c"]="charlie",
    ["d"]="delta",
    ["e"]="echo",
    ["f"]="foxtrott",
    ["g"]="golf",
    ["h"]="hotel",
    ["i"]="india",
    ["j"]="juliet",
    ["k"]="kilo",
    ["l"]="lima",
    ["m"]="mike",
    ["n"]="november",
    ["o"]="oscar",
    ["p"]="papa",
    ["q"]="quebec",
    ["r"]="romeo",
    ["s"]="sierra",
    ["t"]="tango",
    ["u"]="uniform",
    ["v"]="victor",
    ["w"]="whisky",
    ["x"]="xray",
    ["y"]="yankee",
    ["z"]="zulu",
    ["0"]= "zero",
    ["1"]= "one",
    ["2"]= "two",
    ["3"]= "three",
    ["4"]= "four",
    ["5"]= "five",
    ["6"]= "six",
    ["7"]= "seven",
    ["8"]= "eight",
    ["9"]= "niner"
    }
    assert(NatoPhoneticAlphabet.a)

if not NatoPhoneticAlphabet[letter] then assert(true==false, "Not a know letter in Nato Alphabet ".. letter) end

return NatoPhoneticAlphabet[letter], 2 *30
end


local function createIdentifierFromID(id, teamSex)
	local sounds, times = {}, {}
	assert(id)
	assert(type(id) == "number")
	local idStr = ((id % 99)..""):gsub("%s+", "")

	while string.len(idStr) < 2 do
		idStr = "0"..idStr
	end

	assert(string.len(idStr)>= 2)
	local firstLetter = idStr:sub(1,1):lower()
	assert(firstLetter)
	sounds[#sounds+1], times[#times+1] = addSoundPath(teamSex, getNatoPhoneticsTime(firstLetter)), 20
--	Spring.Echo("FirstLetter"..firstLetter)
	local secondLetter = idStr:sub(2):lower()
	assert(secondLetter)

	--	Spring.Echo("secondLetter"..secondLetter)
	sounds[#sounds+1], times[#times+1] = addSoundPath(teamSex, getNatoPhoneticsTime(secondLetter)), 20
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
		return "_neutral", 30
	end

	if civilianAgentDefID ==  defID then
		return "_mobile", 30
	end

	if operativeTypeTable[defID] then
		return "_operative", 30
	end

	if udefs[defID].isbuilding then
		return "_safehouse", 30
	end

	if assetDefID == defID then
		return "_asset", 30
	end

	if udefs[defID].canattack == true then
		return "_strike", 30
	end

	return "_mobile", 30
end



local function getCommandTarget(x,y)
	typestring, result = Spring.TraceScreenRay(x,y)
	return typestring, result
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

local function getActionSound(teamSex)
	local activeCmd = select(4, Spring.GetActiveCommand())
	local default ="_move"

	local validComand = {
		["Move"] = "_move",
		["Stop"] = "_stop",
		["Patrol"] = "_patrol",
		["Attack"] = "_attack",
		["Fight"] = "_strike",
		["Guard"] = "_guard",
		["Load"] = "_pickup",
		["Unload"] = "_drop",

	}
	if validComand[activeCmd] then
		assert(validComand[activeCmd])
		local soundPath = addSoundPath(teamSex, validComand[activeCmd])
		return soundPath , 20
	end

	assert(default)
	local soundPath = addSoundPath(teamSex, default)
	return  soundPath , 20
end

local function getObjectSounds(x,y, teamSex)
 	--Unit getCommandStringFromDefID
	goalType, goalLocation = getCommandTarget(x,y)
	local objectData ={ sounds={}, times = {}}

	if not goalType then
		return 
	end

	if goalType == "unit" then
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("a")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("t")),10

		local objectName, objectTime = getCommandStringFromDefID(Spring.GetUnitDefID(goalLocation)), 30
		assert(objectName)
		objectData.sounds[#objectData.sounds + 1] = addSoundPath(teamSex, objectName)
		objectData.times[#objectData.times + 1] = objectTime
	end

	if goalType == "feature" then
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("n")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("e")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("a")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("r")),10

		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = addSoundPath(teamSex, getNatoPhoneticsTime("f")), 10
		
		local FeatureName = FeatureDefs[Spring.GetFeatureDefID(goalLocation)].name
		assert(FeatureName)
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime(string.sub(FeatureName,1,1))),10
	end

	if goalType == "ground" then
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("2")),10

		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("s")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("e")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("c")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("t")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("o")),10
		objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1]  = addSoundPath(teamSex, getNatoPhoneticsTime("r")),10

		local x,z = goalLocation[1],goalLocation[3]
		x,z = getQuadrant(x,z)
		xHex, zHex = dec2hex(x),dec2hex(z)
		for s=1,string.len(xHex) do
			local subStr = xHex:sub(s,1)
			if subStr and subStr ~= "" then
				objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = addSoundPath(teamSex, getNatoPhoneticsTime(subStr)), 5
			end
		end

		for s=1,string.len(zHex) do
			local subStr = zHex:sub(s,1)
			if subStr and subStr ~= "" then
				objectData.sounds[#objectData.sounds + 1],objectData.times[#objectData.times + 1] = addSoundPath(teamSex, getNatoPhoneticsTime(subStr)), 5
			end
		end
	end
	--Grid
 	return objectData
 end
 
local function createSubject(sound, times, identifierSounds, identifierTimes, teamSex)
	local soundList = {}
	soundList[#soundList+1] = {sound = sound ,times = times}

	for i=1, #identifierSounds do
		soundList[#soundList + 1] = {sound ="", times = 0}
		soundList[#soundList].sound = identifierSounds[i]
		soundList[#soundList].times = identifierTimes[i]
	end

	return {soundList = soundList}
end

local function createAction(sound, times)
	return {sound = sound, times = times}
end

local function createObject(sounds, times)
	local result={}
	for i=1,#sounds do
		result[#result+1] = {sound =  sounds[i], times = times[i]}
	end
	return result
end

local commandStack ={
--[[	[1]={ subject = {soundList = {}},
		  action = {sound ="", times=2000},
		  object = {
		  		soundList= {}}
		  		
		  }
--]]
}

local function addCommandStack(subject, action, object)
	assert(subject)
	assert(action)
	assert(object)
--	Spring.Echo("Gui_ComChatter:addCommandStack")

local objectToInsert ={
	subject = subject,
	action = action,
	object = object
	}

	if #commandStack == 0 then
		commandStack[#commandStack + 1] = objectToInsert
		return
	end
	
	--duplicate detection
	if commandStack[#commandStack].subject ~= objectToInsert.subject and
		commandStack[#commandStack].action ~= objectToInsert.action and
		commandStack[#commandStack].object ~= objectToInsert.object then
		commandStack[#commandStack + 1] = objectToInsert
	end
end


local function getRandomTeamSex()
		if math.random(0,1) == 1 then return "male" end
		return "female"
	end

local function buildSoundCommand( x, y)
	local units = Spring.GetSelectedUnits()

	if not units or #units < 1 then 
		return 
	end

	if not x or not y then 
	return
	end
	--highest priority unit

	local resultID 
	local maxHP = -1
	local higestOrderDefID
	local teamSex = getRandomTeamSex()

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

	--command type
	local subjectName, subjectTime
	assert( getCommandStringFromDefID(higestOrderDefID))
	subjectName, subjectTime = addSoundPath(teamSex, getCommandStringFromDefID(higestOrderDefID)), 15

	local subjectIdentifier, subjectIdentifierTimes
	subjectIdentifierSounds,subjectIdentifierTimes = createIdentifierFromID(resultID, teamSex)

	local actionSound, actionTime 
	actionSound, actionTime = getActionSound(teamSex)
	if  actionSound == nil then 
		return 
	end

	--object
	local objectData  = getObjectSounds(x,y, teamSex)


	if not subjectName or not actionSound or not objectData then 
		return 
	end

	addCommandStack(createSubject(subjectName,subjectTime, subjectIdentifierSounds, subjectIdentifierTimes),
					createAction(actionSound, actionTime),
					createObject(objectData.sounds, objectData.times)					
					)
end

local function playCurrentComset(frame, currentComSetIndex)
	if not currentComSetIndex then return false, nil end
	local currentComSet = commandStack[currentComSetIndex]

	--play subject
	for i=1, #currentComSet.subject.soundList do
		if currentComSet.subject.soundList[i].times > 0 then
			--Spring.Echo("ComChatter: Play subject"..currentComSet.subject.soundList[i].sound)
			Spring.PlaySoundFile(currentComSet.subject.soundList[i].sound, loudness, 'comchatter')
			local totalTime = commandStack[currentComSetIndex].subject.soundList[i].times
			commandStack[currentComSetIndex].subject.soundList[i].times = 0
			return  true, frame + totalTime
		end
	end

	--play action
	if currentComSet.action.times > 0 then
		--Spring.Echo("ComChatter: Play action ".. currentComSet.action.sound )
		Spring.PlaySoundFile(currentComSet.action.sound, loudness, 'comchatter')
		local totalTime = currentComSet.action.times 
		commandStack[currentComSetIndex].action.times = 0
		return true, frame + totalTime
	end

	--play object list
	for i=1, #currentComSet.object do
		if currentComSet.object[i].times > 0 then
			--Spring.Echo("ComChatter: Play object "..currentComSet.object[i].sound)
			Spring.PlaySoundFile(currentComSet.object[i].sound, loudness, 'comchatter')
			local totalTime = commandStack[currentComSetIndex].object[i].times
			commandStack[currentComSetIndex].object[i].times = 0
			return true, frame + totalTime
		end
	end

	commandStack[currentComSetIndex] = nil
	--Spring.Echo("ComChatter Comframe worked off")
	return  false, frame
end

function widget:MousePress(x, y, button)
	--Spring.Echo("Gui_ComChatter:GameFrame MousePress"..button.." "..type(button))
	local selectedUnits = Spring.GetSelectedUnits()
	if (button == 3 or (button == 1 and selectedUnits and #selectedUnits > 0)) then 	
		buildSoundCommand( x, y)
	end
	return false
end

local currentComSetIndex = 1
local boolComSetActive = false
local accumulatedDT = 0.0
function widget:Update(dt)
	accumulatedDT = accumulatedDT + dt
	if accumulatedDT > 0.5 and nextComFrame and Spring.GetGameFrame() > nextComFrame then
	accumulatedDT = 0

		if not boolComSetActive then
			if commandStack and #commandStack > 0 then
			--	Spring.Echo("ComChatter new ComFrame")
				for nr, comSet in ipairs(commandStack) do
					if comSet then
						boolComSetActive = true
						currentComSetIndex = nr
						break
					end
				end
			end
		else
			boolComSetActive, nextComFrame = playCurrentComset(Spring.GetGameFrame(), currentComSetIndex)
		end
	end
end

