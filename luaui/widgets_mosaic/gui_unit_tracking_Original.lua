--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_highlight_unit.lua
--  brief:   highlights the unit/feature under the cursor
--  author:  Dave Rodgers, modified by zwzsg
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Put Track Marks Selected Units",
    desc      = "Highlights tracked Units",
    author    = "(Floris (original: zwzsg, from trepan HighlightUnit)) horribly maimed by Picasso",
    date      = "Apr 24, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = -8,
    enabled   = true
  }
end

local useTeamcolor = true
local highlightAlpha = 0.1
local useHighlightShader = true
local maxShaderUnits = 150
local edgeExponent = 3
local unitHeights  = {}

local spIsUnitIcon = Spring.IsUnitIcon
local spIsUnitInView = Spring.IsUnitInView
local spGetTeamColor = Spring.GetTeamColor
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitToolTip = Spring.GetUnitTooltip 
local houseTypeTable = {}

local glLineWidth      = gl.LineWidth
local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glColor          = gl.Color
local glRect        = gl.Rect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function SetupCommandColors(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    Spring.SendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end


function CreateUnitHighlightShader()
  if unitHighlightShader then
    gl.DeleteShader(unitHighlightShader)
  end
  if gl.CreateShader ~= nil then
    unitHighlightShader = gl.CreateShader({

      uniform = {
        edgeExponent = edgeExponent/(0.8+highlightAlpha),
        plainAlpha = highlightAlpha*0.8,
      },

      vertex = [[
		#version 150 compatibility
        // Application to vertex shader
        varying vec3 normal;
        varying vec3 eyeVec;
        varying vec3 color;
        uniform mat4 camera;
        uniform mat4 caminv;

        void main()
        {
          vec4 P = gl_ModelViewMatrix * gl_Vertex;

          eyeVec = P.xyz;

          normal  = gl_NormalMatrix * gl_Normal;

          color = gl_Color.rgb;

          gl_Position = gl_ProjectionMatrix * P;
        }
      ]],

      fragment = [[
		#version 150 compatibility
        varying vec3 normal;
        varying vec3 eyeVec;
        varying vec3 color;

        uniform float edgeExponent;
        uniform float plainAlpha;

        void main()
        {
          float opac = dot(normalize(normal), normalize(eyeVec));
          opac = 1.0 - abs(opac);
          opac = pow(opac, edgeExponent)*0.45;

          gl_FragColor.g = 0.0;
          gl_FragColor.b = 0.0;
          gl_FragColor.r = 1.0;
          gl_FragColor.a = 1.0;
        }
      ]],
    })
  end
end

local yMarkerDistanceUp = 25
--------------------------------------------------------------------------------
local markerLines
function widget:Initialize()
  markerLines = glCreateList(function()
    glBeginEnd(GL_LINE_LOOP, function()
      glVertex(0, 0, 0)
      glVertex(0, yMarkerDistanceUp, 0)
    end)
  end)

   for k, v in pairs(UnitDefs) do
        if string.find(v.name,"house_arab0") or string.find(v.name,"house_western0") then
            houseTypeTable[k] = k
        end
    end

    for unitDefID, ud in pairs(UnitDefs) do
      ud.power_xp_coeffient  = ((ud.power / 1000) ^ -0.2) / 6  -- dark magic
      unitPowerXpCoeffient[unitDefID] = ud.power_xp_coeffient
      unitHeights[unitDefID] = ud.height + iconoffset
    end
   
  SetupCommandColors(false)
  CreateUnitHighlightShader()
end


function widget:Shutdown()
  if shader then
    gl.DeleteShader(unitHighlightShader)
  end
 
end



--------------------------------------------------------------------------------

local selectedUnits = Spring.GetSelectedUnits()
local selectedUnitsCount = Spring.GetSelectedUnitsCount()
local trackedUnits = {}
local trackKey = 111 --'O'
local untrackKey = 127 --'DELETE'



function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1,18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1,19) == 'LobbyOverlayActive1')
	end
end
local trackedUnitsCount = 0
function widget:KeyRelease(key)
  if (key == trackKey) then
    local mouseX, mouseZ = Spring.GetMouseState ( )
    local targType, unitID = Spring.TraceScreenRay(mouseX, mouseZ)
    if targType == "unit" and not houseTypeTable[spGetUnitDefID(unitID)] then
      if trackedUnits[unitID] then
        trackedUnits[unitID] = nil
        trackedUnitsCount= trackedUnitsCount-1
      else
        trackedUnits[unitID] = {}
        trackedUnits[unitID].marker ="SUSPECT "..trackedUnitsCount
        trackedUnits[unitID].name  = spGetUnitToolTip(unitID)
        
        trackedUnitsCount = trackedUnitsCount +1
      end
    end
  end
  if (key == untrackKey) then
   trackedUnits = {}
   trackedUnitsCount = 0
  end		
end

local iconsizeX = 10
local iconsizeZ = 20
local textSize = 5
local suspectCol = {0.0, 1.0, 0.0, 0.95}
local baseWhite = {1.0, 1.0, 1.0, 0.75}
local baseBlack = {0.0, 0.0, 0.0, 1.0}
local function DrawSuspectMarker(yshift, text, name)
  glTranslate(0,yshift,0)
  --Draw Base Plate
  glColor(baseBlack)
  glRect(-iconsizeX, iconsizeZ, iconsizeX, -iconsizeZ)
  glColor(suspectCol)
  glRect(-iconsizeX, iconsizeZ, iconsizeX, 0)
  glColor(baseBlack)
  gl.Text (string.upper(text), -iconsizeX, iconsizeZ/2, textSize , "cto" ) 
  glColor(suspectCol)
  gl.Text (string.upper(name), -iconsizeX, -iconsizeZ/2, textSize-1 , "cto" ) 
end



function widget:DrawWorld()
	if chobbyInterface then return end
  if not trackedUnits or Spring.IsGUIHidden() then return end

  gl.DepthTest(true)
  gl.PolygonOffset(-0.5, -0.5)

 
  if useHighlightShader and unitHighlightShader and trackedUnitsCount >0 then
  gl.UseShader(unitHighlightShader)
  
    for unitID,texData in pairs(trackedUnits) do
      glColor(baseWhite)
      glDrawListAtUnit(unitID, markerLines, true,
      1.0, 1.0, 1.0,
      0, 0, 0, 0)
      glDrawFuncAtUnit(unitID, false, DrawSuspectMarker, unitHeights[unitDefID], trackedUnits[unitID].marker, trackedUnits[unitID].name)

      
    end   
  end

  if useHighlightShader and unitHighlightShader and trackedUnitsCount >0 then
    gl.UseShader(0)
  end

  gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
  gl.PolygonOffset(false)
  gl.DepthTest(false)
end

widget.DrawWorldReflection = widget.DrawWorld

widget.DrawWorldRefraction = widget.DrawWorld



function widget:GetConfigData()
	return {highlightAlpha=highlightAlpha, useHighlightShader=useHighlightShader, useTeamcolor=useTeamcolor}
end

function widget:SetConfigData(data)
  if data.useHighlightShader ~= nil then highlightAlpha = data.highlightAlpha end
  if data.useHighlightShader ~= nil then useHighlightShader = data.useHighlightShader end
  if data.useHighlightShader ~= nil then useTeamcolor = data.useTeamcolor end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
