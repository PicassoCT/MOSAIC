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
    author    = "Floris (original: zwzsg, from trepan HighlightUnit)",
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

local spIsUnitIcon = Spring.IsUnitIcon
local spIsUnitInView = Spring.IsUnitInView
local spGetTeamColor = Spring.GetTeamColor
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local houseTypeTable = {}
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


function CreateHighlightShader()
  if shader then
    gl.DeleteShader(shader)
  end
  if gl.CreateShader ~= nil then
    shader = gl.CreateShader({

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
--------------------------------------------------------------------------------

function widget:Initialize()
   for k, v in pairs(UnitDefs) do
        if string.find(v.name,"house_arab0") or string.find(v.name,"house_western0") then
            houseTypeTable[k] = k
        end
    end
  WG['highlightselunits'] = {}
  WG['highlightselunits'].getOpacity = function()
    return highlightAlpha
  end
  WG['highlightselunits'].setOpacity = function(value)
    highlightAlpha = value
    CreateHighlightShader()
  end
  WG['highlightselunits'].getShader = function()
    return useHighlightShader
  end
  WG['highlightselunits'].setShader = function(value)
    if value and (Spring.GetConfigInt("LuaShaders") or 1) ~= 1 then
      Spring.SetConfigInt("LuaShaders",1)
      Spring.Echo('enabled lua shaders')
    end
    useHighlightShader = value
    CreateHighlightShader()
  end
  WG['highlightselunits'].getTeamcolor = function()
    return useTeamcolor
  end
  WG['highlightselunits'].setTeamcolor = function(value)
    useTeamcolor = value
    CreateHighlightShader()
  end
  
  SetupCommandColors(false)
  CreateHighlightShader()
end


function widget:Shutdown()
  if shader then
    gl.DeleteShader(shader)
  end
  if WG['teamplatter'] == nil and WG['fancyselectedunits'] == nil then
    SetupCommandColors(true)
  end
  WG['highlightselunits'] = nil
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

function widget:KeyRelease(key)
  if (key == trackKey) then
    local mouseX, mouseZ = Spring.GetMouseState ( )
    local targType, unitID = Spring.TraceScreenRay(mouseX, mouseZ)
    if targType == "unit" and not houseTypeTable[spGetUnitDefID(unitID)] then
      trackedUnits[#trackedUnits + 1] = unitID
    end
  end
  if (key == untrackKey) then
   trackedUnits = {}
  end		
end


function widget:DrawWorld()
	if chobbyInterface then return end
  if not trackedUnits or Spring.IsGUIHidden() then return end

  gl.DepthTest(true)
  gl.PolygonOffset(-0.5, -0.5)
  gl.Blending(GL.SRC_ALPHA, GL.ONE)

  --local selectedUnits = Spring.GetSelectedUnits()
  if useHighlightShader and shader and #trackedUnits < maxShaderUnits then
    gl.UseShader(shader)
  end
  local teamID, prevTeamID, r,g,b
  for i=1,#trackedUnits do
    local unitID = trackedUnits[i]
    if not spIsUnitIcon(unitID) and spIsUnitInView(unitID) then
      local health,maxHealth,paralyzeDamage,captureProgress,buildProgress=Spring.GetUnitHealth(unitID)
      if maxHealth ~= nil then
        if useTeamcolor then
          teamID = spGetUnitTeam(unitID)
          if teamID ~= prevTeamID then
            r,g,b = spGetTeamColor(teamID)
          end
          prevTeamID = teamID
          gl.Color(r,g,b,highlightAlpha)
        else
          gl.Color(
            health>maxHealth/2 and 2-2*health/maxHealth or 1, -- red
            health>maxHealth/2 and 1 or 2*health/maxHealth, -- green
            0, -- blue
            highlightAlpha
          )
        end
        gl.Unit(unitID, true)
      end
    end
  end

  if useHighlightShader and shader and #selectedUnits < maxShaderUnits then
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
