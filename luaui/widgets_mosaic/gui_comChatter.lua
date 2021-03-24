include("keysym.h.lua")
local versionNumber = "2.03"

function widget:GetInfo()
	return {
		name      = "ComChatter",
		desc      = "Creates com chatter from unit commands",
		author    = "pica",
		date      = "1 1, 2021",
		license   = "GNU GPL v2",
		layer     = -10,
		enabled   = false
	}
end

local fontfile = LUAUI_DIRNAME .. "fonts/" .. Spring.GetConfigString("bar_font", "Poppins-Regular.otf")
local vsx,vsy = Spring.GetViewGeometry()
local fontfileScale = (0.5 + (vsx*vsy / 5700000))
local fontfileSize = 25
local fontfileOutlineSize = 5
local fontfileOutlineStrength = 1.3
local font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)

--callin driven
--"hot" units

local floor                 = math.floor
local abs					= math.abs

local udefTab				= UnitDefs
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


function widget:Initialize()

end

function widget:Shutdown()
	
end


local selectedUnits= {}

function widget:ViewResize(n_vsx,n_vsy)
	vsx,vsy = Spring.GetViewGeometry()
	widgetScale = (0.5 + (vsx*vsy / 5700000))
  local newFontfileScale = (0.5 + (vsx*vsy / 5700000))
  if (fontfileScale ~= newFontfileScale) then
    fontfileScale = newFontfileScale
    gl.DeleteFont(font)
    font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)
  end

	xPos, yPos            = xRelPos*vsx, yRelPos*vsy
	sizeMultiplier = 0.55 + (vsx*vsy / 8000000)
end


function widget:CommandsChanged( id, params, options )
	selectedUnits= Spring.GetSelectedUnits()
end

function createIdentifierFromID(id, defID)

end

function getCommandStringFromDefID(defID)

end

local soundFilesLengthInFrames = {}
function addSoundPath(baseString)
	return "/sounds/comchat/"..baseString..".ogg", soundFilesLengthInFrames[soundLength]
end

function getCommandTarget(x,y)
	return Spring.TraceScreenRay(x,y)
end



function getHighestOrderUnit(units)
	for i=1, #units do
		local defID  = Spring.GetUnitDefID(units[i])
	end

end

 function getObjectSounds(location)
 	--Unit getCommandStringFromDefID

 	--Grid

 end

function buildSoundCommand(units, location)
	if not units or #units < 1 then return end

--highest priority unit
local higestOrderDefID, id = getHighestOrderUnit(units)

--command type
local commandName, commandTime = addSoundPath(getCommandStringFromDefID(higestOrderDefID))
local commandIdentifier = createIdentifierFromID(id, higestOrderDefID)

local actionSound, actionTime = addSoundPath(getActionSound(id))

--object
local objectSounds, objectTimes = getObjectSounds(location)
end

function createSubject(sound, identifier, time)
	return {sound = sound, identifier = identifier, time = time}
end

function createAction(sound, time)
	return {sound = sound, time = time}
end

function createObject(sounds, times)
	local result={}
	for i=1,#sounds do
		result[#result+1] = {sound = sounds[i], time = times[i]}
	end
	return result
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
		location =getCommandTarget(x,y)
		Spring.Echo("Left clicked on location", location )
		buildSoundCommand(selctedUnits, location)
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

	if currentComSet.action.time > 0 then
	Spring.Echo("ComChatter:".. currentComSet.action.sound )
		local totalTime = currentComSet.action.time 
		commandStack[currentComSetIndex].action.time = 0
		return true, frame + totalTime
	end

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


