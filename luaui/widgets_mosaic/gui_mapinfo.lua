local versionNumber = "0.6"

function widget:GetInfo()
  return {
    name      = "Map Info",
    desc      = versionNumber .." Draws map info on the bottom left of the map.  Toggle vertical position with /mapinfo_floor",
    author    = "Floris",
    date      = "20 May 2015",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

--/mapinfo_floor		-- toggles placement at ground-height, or map floor

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local scale					= 1
local offset				= 5
local stickToFloor			= false
local thickness				= 6
local fadeStartHeight		= 800
local fadeEndHeight			= 4800
local dlistAmount			= 20		-- amount of dlists created, one for each opacity value

local fontfile = LUAUI_DIRNAME .. "fonts/" .. Spring.GetConfigString("bar_font", "Poppins-Regular.otf")
local vsx,vsy = Spring.GetViewGeometry()
local fontfileScale = (0.5 + (vsx*vsy / 5700000))
local fontfileSize = 25
local fontfileOutlineSize = 5
local fontfileOutlineStrength = 1.1
local font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)


--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local spGetCameraPosition	= Spring.GetCameraPosition
local spGetGroundHeight		= Spring.GetGroundHeight
local spIsAABBInView		= Spring.IsAABBInView
--local spGetCameraState		= Spring.GetCameraState

local glColor           = gl.Color
local glScale           = gl.Scale
local glText            = gl.Text
local glPushMatrix      = gl.PushMatrix
local glPopMatrix       = gl.PopMatrix
local glTranslate       = gl.Translate
local glBeginEnd        = gl.BeginEnd
local glVertex          = gl.Vertex
local glGetTextWidth	= gl.GetTextWidth
local glBlending		= gl.Blending
local glCallList		= gl.CallList
local glDeleteList		= gl.DeleteList

local glDepthTest       = gl.DepthTest
local glAlphaTest       = gl.AlphaTest
local glTexture         = gl.Texture
local glRotate          = gl.Rotate

local mapInfo = {}
local mapInfoWidth = 400	-- minimum width
local mapinfoList = {}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function widget:ViewResize(n_vsx,n_vsy)
	vsx,vsy = Spring.GetViewGeometry()
	local newFontfileScale = (0.5 + (vsx*vsy / 5700000))
	if (fontfileScale ~= newFontfileScale) then
		fontfileScale = newFontfileScale
		gl.DeleteFont(font)
		font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)
	end
	for opacity, list in pairs(mapinfoList) do
		glDeleteList(list)
		mapinfoList[opacity] = nil
	end
end

local function createMapinfoList(opacityMultiplier)
	mapinfoList[opacityMultiplier] = gl.CreateList( function()
		local textOpacity = 0.85
		local textSize = 12
		local textOffsetX = 11
		local textOffsetY = 16
		local usedTextOffsetY = textOffsetY + (offset/2)
		local length = math.max(mapInfoWidth, (font:GetTextWidth(Game.mapDescription)*textSize) + 45)
		
		glDepthTest(true)
		glBlending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	
		if stickToFloor then
			glTranslate(offset, offset, Game.mapSizeZ+0.01)
		else
			glTranslate(offset, mapInfoBoxHeight-offset, Game.mapSizeZ+0.01)
		end
		
		glPushMatrix()
		
		glScale(scale,scale,scale)
		glRotate(90,0,-1,0)
		glRotate(180,1,0,0)
	
		--Spring.Echo(font:GetTextWidth(Game.mapDescription))
		
		local height = 90
		local thickness = -(thickness*scale)
		glBeginEnd(GL.QUADS,function()
			glColor(0.12,0.12,0.12,0.4*opacityMultiplier*opacityMultiplier)
			glVertex( height, 0        , 0);         -- Top Right Of The Quad (Top)
			glVertex( 0     , 0        , 0);         -- Top Left Of The Quad (Top)
			glVertex( 0     , 0        , length);    -- Bottom Left Of The Quad (Top)
			glVertex( height, 0        , length);    -- Bottom Right Of The Quad (Top)
			
			glVertex( height, 0        , length);    -- Top Right Of The Quad (Front)
			glVertex( 0     , 0        , length);    -- Top Left Of The Quad (Front)
			glVertex( 0     ,-thickness, length);    -- Bottom Left Of The Quad (Front)
			glVertex( height,-thickness, length);    -- Bottom Right Of The Quad (Front)
			
			glVertex( height,-thickness, 0);         -- Top Right Of The Quad (Back)
			glVertex( 0     ,-thickness, 0);         -- Top Left Of The Quad (Back)
			glVertex( 0     , 0        , 0);         -- Bottom Left Of The Quad (Back)
			glVertex( height, 0        , 0);         -- Bottom Right Of The Quad (Back)
			
			glVertex( 0     , 0        , length);    -- Top Right Of The Quad (Left)
			glVertex( 0     , 0        , 0);         -- Top Left Of The Quad (Left)
			glVertex( 0     ,-thickness, 0);         -- Bottom Left Of The Quad (Left)
			glVertex( 0     ,-thickness, length);    -- Bottom Right Of The Quad (Left)
			
			glVertex( height, 0        , 0);         -- Top Right Of The Quad (Right)
			glVertex( height, 0        , length);    -- Top Left Of The Quad (Right)
			glVertex( height,-thickness, length);    -- Bottom Left Of The Quad (Right)
			glVertex( height,-thickness, 0);         -- Bottom Right Of The Quad (Right)
			
			
			glColor(0.05,0.05,0.05,0.4*opacityMultiplier*opacityMultiplier)
			glVertex( height,-thickness, length);    -- Top Right Of The Quad (Bottom)
			glVertex( 0     ,-thickness, length);    -- Top Left Of The Quad (Bottom)
			glVertex( 0     ,-thickness, 0);         -- Bottom Left Of The Quad (Bottom)
			glVertex( height,-thickness, 0);         -- Bottom Right Of The Quad (Bottom)
		end)
		
		glRotate(180,1,0,0)
		glRotate(90,0,1,0)
		
		glRotate(90,1,0,0)
		glTranslate(0,3,0)
		
		glRotate(180,1,0,0)
		
		-- map name
		font:Begin()
		local text = Game.mapName
		font:SetTextColor(1,1,1,(textOpacity*1.12)*opacityMultiplier)

		font:Print(text, textOffsetX,-usedTextOffsetY,14,"n")
		font:SetTextColor(0,0,0,textOpacity*0.12*opacityMultiplier)
		font:Print(text, textOffsetX+0.5,-usedTextOffsetY-0.9,14,"n")
		
		--map description
		usedTextOffsetY = usedTextOffsetY+textOffsetY
		text = Game.mapDescription
		font:SetTextColor(1,1,1,textOpacity*0.6*opacityMultiplier)
		font:Print(text, textOffsetX,-usedTextOffsetY,textSize,"n")
		
		--map size
		usedTextOffsetY = usedTextOffsetY+textOffsetY
		text = Game.mapDescription
		font:SetTextColor(1,1,1,textOpacity*0.6*opacityMultiplier)
		font:Print("Size: "..Game.mapX.. " x "..Game.mapY, textOffsetX,-usedTextOffsetY+0.8,textSize,"n")
		font:End()
		
		--[[
			usedTextOffsetY = usedTextOffsetY+textOffsetY
			text = "Waterdamage: "..math.floor(Game.waterDamage)
			glColor(1,1,1,textOpacity*0.6*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY,textSize,"n")
			glColor(0,0,0,textOpacity*0.6*0.17*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY-1,textSize,"n")
				
			textOffsetX = textOffsetX + 120
			text = "Gravity: "..math.floor(Game.gravity)
			glColor(1,1,1,textOpacity*0.6*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY,textSize,"n")
			glColor(0,0,0,textOpacity*0.6*0.17*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY-1,textSize,"n")
			textOffsetX = textOffsetX - 120
			
			textOffsetX = textOffsetX + 210
			text = "Tidal: "..math.floor(Game.tidal)
			glColor(1,1,1,textOpacity*0.6*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY,textSize,"n")
			glColor(0,0,0,textOpacity*0.6*0.17*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY-1,textSize,"n")
			textOffsetX = textOffsetX - 210
			
			-- game name
			usedTextOffsetY = usedTextOffsetY+textOffsetY+textOffsetY+textOffsetY
			text = Game.gameName.."   "..Game.gameVersion
			glColor(1,1,1,textOpacity*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY,textSize,"n")
			glColor(0,0,0,textOpacity*0.17*opacityMultiplier)
			glText(text, textOffsetX,-usedTextOffsetY-1,textSize,"n")
		]]--
		
		glPopMatrix()
		
		if stickToFloor then
			glTranslate(-offset, -offset, -Game.mapSizeZ)
		else
			glTranslate(-offset, -mapInfoBoxHeight-offset, -Game.mapSizeZ)
		end
		glColor(1,1,1,1)
		glScale(1,1,1)
		glDepthTest(false)
	end)
end


function Init()
	
	if (font:GetTextWidth(Game.mapDescription) * 12) > mapInfoWidth then
		--mapInfoWidth = (font:GetTextWidth(Game.mapDescription) * 12) + 33
	end
	if stickToFloor then
		mapInfoBoxHeight = 0
	else
		mapInfoBoxHeight = spGetGroundHeight(0,Game.mapSizeZ)
	end
	
	-- find the lowest map height
	if not stickToFloor then
		for i=math.floor(offset*scale), math.floor((mapInfoWidth+offset)*scale) do
			if spGetGroundHeight(i,Game.mapSizeZ) < mapInfoBoxHeight then
				mapInfoBoxHeight = spGetGroundHeight(i,Game.mapSizeZ)
			end
		end
	end
end
--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:Initialize()
	Init()
end

function widget:Shutdown()
	for opacity, list in pairs(mapinfoList) do
		glDeleteList(mapinfoList[opacity])
		mapinfoList[opacity] = nil
	end
	gl.DeleteFont(font)
end

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1,18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1,19) == 'LobbyOverlayActive1')
	end
end

function widget:DrawWorld()
	if chobbyInterface then return end
  if Spring.IsGUIHidden() then return end
  
	if spIsAABBInView(offset, mapInfoBoxHeight, Game.mapSizeZ,   mapInfoWidth*scale, mapInfoBoxHeight+(thickness*scale), Game.mapSizeZ) then
		local camX, camY, camZ = spGetCameraPosition()
		local camDistance = math.diag(camX - (mapInfoWidth/2)*scale, camY - mapInfoBoxHeight, camZ - Game.mapSizeZ)
		local opacityMultiplier = (1 - (camDistance-fadeStartHeight) / (fadeEndHeight-fadeStartHeight))
		if opacityMultiplier > 1 then
			opacityMultiplier = 1
		end
		if opacityMultiplier > 0.05 then
			opacityMultiplier = math.floor(opacityMultiplier * dlistAmount)/dlistAmount
			
			if mapinfoList[opacityMultiplier] == nil then
				createMapinfoList(opacityMultiplier)
			end
			glCallList(mapinfoList[opacityMultiplier])
		end
	end
end


function widget:GetConfigData(data)
    savedTable = {}
    savedTable.stickToFloor = stickToFloor
    return savedTable
end

function widget:SetConfigData(data)
    if data.stickToFloor ~= nil 	then  stickToFloor	= data.stickToFloor end
end

function widget:TextCommand(command)
    if (string.find(command, "mapinfo_floor") == 1  and  string.len(command) == 13) then 
		stickToFloor = not stickToFloor
		Init()
	end
end
