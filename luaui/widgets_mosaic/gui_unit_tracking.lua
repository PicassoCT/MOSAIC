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
        name = "Put Track Marks Selected Units",
        desc = "Highlights tracked Units",
        author = "Floris (original: zwzsg, from trepan HighlightUnit)",
        date = "Apr 24, 2009",
        license = "GNU GPL, v2 or later",
        layer = -8,
        enabled = true
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

local GL_LINE_LOOP = GL.LINE_LOOP
local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN
local glBeginEnd = gl.BeginEnd
local glColor = gl.Color
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList
local glDepthTest = gl.DepthTest
local glDrawListAtUnit = gl.DrawListAtUnit
local glLineWidth = gl.LineWidth
local glPolygonOffset = gl.PolygonOffset
local glVertex = gl.Vertex
local spGetUnitBasePosition  = Spring.GetUnitBasePosition
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local yellowColorOuter = {1.0, 0.647, 0.18, 0.65}
local yellowColorInner = {1.0, 0.768, 0.18, 0.85}
local houseTypeTable = {}
local circleLines = 0
local circleDivs = 32
local circleOffset = 50
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupCommandColors(state)
    local alpha = state and 1 or 0
    local f = io.open("cmdcolors.tmp", "w+")
    if (f) then
        f:write("unitBox  0 1 0 " .. alpha)
        f:close()
        Spring.SendCommands({"cmdcolors cmdcolors.tmp"})
    end
    os.remove("cmdcolors.tmp")
end

local realRadii = {}

local function GetUnitDefRealRadius(udid)
    local radius = realRadii[udid]
    if (radius) then
        return radius
    end

    local ud = UnitDefs[udid]
    if (ud == nil) then
        return nil
    end

    local dims = spGetUnitDefDimensions(udid)
    if (dims == nil) then
        return nil
    end

    local scale = ud.hitSphereScale -- missing in 0.76b1+
    scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
    radius = dims.radius / scale
    realRadii[udid] = radius
    return radius
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
    circleLines =
        glCreateList(
        function()
            glBeginEnd(
                GL_LINE_LOOP,
                function()
                    local radstep = (2.0 * math.pi) / circleDivs
                    for i = 1, circleDivs do
                        local a = (i * radstep)
                        glVertex(math.sin(a), circleOffset, math.cos(a))
                    end
                end
            )
        end
    )

    for k, v in pairs(UnitDefs) do
        if string.find(v.name, "house_arab0") or string.find(v.name, "house_western0") then
            houseTypeTable[k] = k
        end
    end
    WG["highlightselunits"] = {}
    WG["highlightselunits"].getOpacity = function()
        return highlightAlpha
    end
    WG["highlightselunits"].setOpacity = function(value)
        highlightAlpha = value
        CreateHighlightShader()
    end
    WG["highlightselunits"].getShader = function()
        return useHighlightShader
    end
    WG["highlightselunits"].setShader = function(value)
        if value and (Spring.GetConfigInt("LuaShaders") or 1) ~= 1 then
            Spring.SetConfigInt("LuaShaders", 1)
            Spring.Echo("enabled lua shaders")
        end
        useHighlightShader = value
        CreateHighlightShader()
    end
    WG["highlightselunits"].getTeamcolor = function()
        return useTeamcolor
    end
    WG["highlightselunits"].setTeamcolor = function(value)
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
    if WG["teamplatter"] == nil and WG["fancyselectedunits"] == nil then
        SetupCommandColors(true)
    end
    WG["highlightselunits"] = nil
end

--------------------------------------------------------------------------------

local selectedUnits = Spring.GetSelectedUnits()
local selectedUnitsCount = Spring.GetSelectedUnitsCount()
local trackedUnits = {}
local trackKey = 111 --'O'
local untrackKey = 127 --'DELETE'

function widget:RecvLuaMsg(msg, playerID)
    if msg:sub(1, 18) == "LobbyOverlayActive" then
        chobbyInterface = (msg:sub(1, 19) == "LobbyOverlayActive1")
    end
end

function widget:KeyRelease(key)
    if (key == trackKey) then
        local mouseX, mouseZ = Spring.GetMouseState()
        local targType, unitID = Spring.TraceScreenRay(mouseX, mouseZ)
        if targType == "unit" and not houseTypeTable[spGetUnitDefID(unitID)] then
            trackedUnits[#trackedUnits + 1] = unitID
        end
    end
    if (key == untrackKey) then
        trackedUnits = {}
    end
end

local unitCache = {}
function widget:DrawWorld()
    if chobbyInterface then
        return
    end
    if not trackedUnits or Spring.IsGUIHidden() then
        return
    end

    gl.DepthTest(true)
    gl.PolygonOffset(-0.5, -0.5)
    gl.Blending(GL.SRC_ALPHA, GL.ONE)

    --local selectedUnits = Spring.GetSelectedUnits()
    if useHighlightShader and shader and #trackedUnits < maxShaderUnits then
        gl.UseShader(shader)
    end
    local teamID, prevTeamID, r, g, b
    glColor(yellowColorOuter)
    for i = 1, #trackedUnits do
        local unitID = trackedUnits[i]
   --[[       local udid = 0
            if unitCache[unitID] then
                udid = unitCache[unitID].defID
            else
                udid = spGetUnitDefID(unitID)
                if not unitCache[unitID] then
                    unitCache[unitID] = {}
                end
                unitCache[unitID].defID = udid
            end

            local radius = GetUnitDefRealRadius(udid)
            glLineWidth(12.0)
            glColor(yellowColorOuter)
            glDrawListAtUnit(unitID, circleLines, false, radius, 1.0, radius)
            glColor(yellowColorOuter)
             glLineWidth(24.0)
            glDrawListAtUnit(unitID, circleLines, false, radius*1.41, 1.05, radius*1.41)
            glLineWidth(4.0)
            glColor(yellowColorInner)
            glDrawListAtUnit(unitID, circleLines, false, radius, 1.001, radius)--]]
        if not spIsUnitIcon(unitID) and spIsUnitInView(unitID) then
             local health,maxHealth,paralyzeDamage,captureProgress,buildProgress=Spring.GetUnitHealth(unitID)
        end
        --TODO: Draw Circular Deco at Unit
    end

    if useHighlightShader and shader and #trackedUnits < maxShaderUnits then
        gl.UseShader(0)
    end

    --glColor(1, 1, 1, alpha)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    gl.PolygonOffset(false)
    gl.DepthTest(false)
end

widget.DrawWorldReflection = widget.DrawWorld

widget.DrawWorldRefraction = widget.DrawWorld

function widget:GetConfigData()
    return {highlightAlpha = highlightAlpha, useHighlightShader = useHighlightShader, useTeamcolor = useTeamcolor}
end

function widget:SetConfigData(data)
    if data.useHighlightShader ~= nil then
        highlightAlpha = data.highlightAlpha
    end
    if data.useHighlightShader ~= nil then
        useHighlightShader = data.useHighlightShader
    end
    if data.useHighlightShader ~= nil then
        useTeamcolor = data.useTeamcolor
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
