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
local glColor               = gl.Color
local glDepthTest           = gl.DepthTest
local glUnitShape			= gl.UnitShape
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glText                = gl.Text
local glTexture             = gl.Texture
local glTexRect             = gl.TexRect
local glBillboard           = gl.Billboard
local glLineWidth 			= gl.LineWidth
local glBeginEnd			= gl.BeginEnd
local glScale				= gl.Scale
local glVertex              = gl.Vertex
local glCallList   			= gl.CallList
local glDrawListAtUnit      = gl.DrawListAtUnit

local GL_LINE_LOOP			= GL.LINE_LOOP

local spec = false
local showGui = false
local playerIsSpec = {}

----------------------------------------------------------------

local scaleMultiplier			= 1.05
local maxAlpha					= 0.45
local hotFadeTime				= 0.25
local lockTeamUnits				= false --disallow selection of units selected by teammates
local showAlly					= true 		--also show allies (besides coop)
local useHotColor				= false --use RED for all hot units, if false use playerColor starting with transparency
local showAsSpectator			= true
local circleDivsCoop			= 32  --nice circle
local circleDivsAlly			= 5  --aka pentagon
local selectPlayerUnits			= true

local hotColor = { 1.0, 0.0, 0.0, 1.0 }

local playerColorPool = {}
playerColorPool[1] = { 0.0, 1.0, 0.0 }
playerColorPool[2] = { 1.0, 1.0, 0.0 }
playerColorPool[3] = { 0.0, 0.0, 1.0 }
playerColorPool[4] = { 0.6, 0.0, 0.0 } --reserve full-red for hot units
playerColorPool[5] = { 0.0, 1.0, 1.0 }
playerColorPool[6] = { 1.0, 0.0, 1.0 }
playerColorPool[7] = { 1.0, 0.0, 0.0 }
playerColorPool[8] = { 1.0, 0.0, 0.0 }

local xRelPos, yRelPos		= 0.835, 0.88	-- (only used here for now)
local vsx, vsy				= gl.GetViewSizes()
local xPos, yPos            = xRelPos*vsx, yRelPos*vsy

local panelWidth = 200;
local panelHeight = 55;

local sizeMultiplier = 1

--Internals------------------------------------------------------
local playerColors = {}
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


selectedUnits= {}

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


