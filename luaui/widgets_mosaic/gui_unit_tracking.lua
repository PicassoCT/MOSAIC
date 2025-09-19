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
    layer     = math.huge,
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
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitToolTip = Spring.GetUnitTooltip 
local houseTypeTable = {}

local glLineWidth      = gl.LineWidth
local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glColor          = gl.Color
local glRect           = gl.Rect
local glTranslate      = gl.Translate
local glRotate         = gl.Rotate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local scale         = 1
local offset        = 5
local stickToFloor      = false
local thickness       = 6
local fadeStartHeight   = 800
local fadeEndHeight     = 4800
local dlistAmount     = 20    -- amount of dlists created, one for each opacity value
local iconoffset = 20

local fontfile = LUAUI_DIRNAME .. "fonts/" .. Spring.GetConfigString("bar_font", "Poppins-Regular.otf")
local vsx,vsy = Spring.GetViewGeometry()
local fontfileScale = (0.5 + (vsx*vsy / 5700000))
local fontfileSize = 25
local fontfileOutlineSize = 5
local fontfileOutlineStrength = 1.1
local font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)
local iconHeighth = 100
local Polygon = { }


function widget:ViewResize(n_vsx,n_vsy)
  vsx,vsy = Spring.GetViewGeometry()
  local newFontfileScale = (0.5 + (vsx*vsy / 5700000))
  if (fontfileScale ~= newFontfileScale) then
    fontfileScale = newFontfileScale
    gl.DeleteFont(font)
    font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)
  end
end

---------------------------------------------------------------------------------------------------------------------------


local function DrawLine(polyToDraw, offsetY)
  local n = #polyToDraw
  for i = 1, n do
    local x = polyToDraw[i][1]
    local z = polyToDraw[i][3]
    local y = Spring.GetGroundHeight(x, z) + offsetY
    gl.Vertex(x,y,z)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function addLineSegment(x,y,z)
  local pos = {[1]=x,[2]=y,[3]=z}
  Polygon[#Polygon+1] = pos
end

local function newPolygon(x,y,z)
    Polygon = {}
    addLineSegment(x,y,z)
end
--------------------------------------------------------------------------------
function widget:Initialize()

   for k, v in pairs(UnitDefs) do
        if string.find(v.name,"house_arab0") or string.find(v.name,"house_western0") then
            houseTypeTable[k] = k
        end
    end

    for unitDefID, ud in pairs(UnitDefs) do
      unitHeights[unitDefID] = ud.height + iconoffset
    end

end


function widget:Shutdown()
end

--------------------------------------------------------------------------------

local selectedUnits = Spring.GetSelectedUnits()
local selectedUnitsCount = Spring.GetSelectedUnitsCount()
local trackedUnits = {}
local trackKey = 111 --'O'
local untrackKey = 127 --'DELETE'

local function setTrackedUnit(id)
--  Spring.Echo("Setting tracked "..id)
  local setTrackedMessage = "SET_TRACKED:".. id
  Spring.SendLuaRulesMsg(setTrackedMessage)
end

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1,18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1,19) == 'LobbyOverlayActive1')
	end

  if msg:find("SEND_TRACKED:") then
    Spring.Echo("TODO: Confirm working sending tracked "..msg)
    local rawNumber = msg:gsub("SEND_TRACKED:", "")
    if rawNumber ~= nil then
      local trackedId = string.tonumber(rawNumber)
      setTrackedUnit(trackedId)
    end
  end
end

local function setUntrackedUnit(id)
  local setUntrackedMessage = "SET_UNTRACKED:".. id
  Spring.SendLuaRulesMsg (setUntrackedMessage)
end

local trackedUnitsCount = 0
function widget:KeyRelease(key)
  if (key == trackKey) then
    local mouseX, mouseZ = Spring.GetMouseState ( )
    local targType, unitID = Spring.TraceScreenRay(mouseX, mouseZ)
    if targType == "unit" then
      local defID = spGetUnitDefID(unitID)
      if not houseTypeTable[defID] then
        if trackedUnits[unitID] then
          trackedUnits[unitID] = nil
          setUntrackedUnit(unitID)
        else
          setTrackedUnit(unitID)
          trackedUnits[unitID] = {}
          trackedUnits[unitID].marker ="SUSPECT "..trackedUnitsCount
          trackedUnits[unitID].name  = spGetUnitToolTip(unitID)
          if string.find(trackedUnits[unitID].name,"<") then
          trackedUnits[unitID].name  = string.sub(trackedUnits[unitID].name ,1, string.find(trackedUnits[unitID].name,"<")-1)
          end
          trackedUnits[unitID].unitDefID  = defID

          
          trackedUnitsCount = trackedUnitsCount +1
        end
      end
    end
  end
  if (key == untrackKey) then
   trackedUnits = {}
   trackedUnitsCount = 0
  end		
end

local iconsizeX = 60
local iconsizeZ = 20
local textSize = 5
local suspectCol = {0.0, 1.0, 0.0, 0.95}
local baseWhite = {1.0, 1.0, 1.0, 0.35}
local baseBlack = {0.0, 0.0, 0.0, 1.0}

local function DrawSuspectMarker(yshift, designator, name)

  local maxstringlength = math.max(math.max(string.len(designator),string.len(name)),iconsizeX)*2
  glColor(baseWhite)
  glRect(-1, maxstringlength+ iconsizeX/2, 1, 0)
  glTranslate(0,yshift,0)
  glRotate(0,0,90.0,0)
  --Draw Base Plate
  glColor(baseBlack)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, -iconsizeZ)
  glColor(suspectCol)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, 0)
  glColor(baseBlack)
  gl.BeginText ( ) 
  glColor(baseBlack)
  gl.Text ("\255\0\0\0◪ "..string.upper(designator), -iconsizeX+2, iconsizeZ*0.9, textSize*3.75 , "lto" ) 
  glColor(suspectCol)
  gl.Text ("\255\0\255\0⧉⬚ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lto" ) 
  gl.EndText()
end



function widget:DrawWorld()
	if chobbyInterface then return end
  if not trackedUnits or Spring.IsGUIHidden() then return end

  gl.DepthTest(true)
  gl.PolygonOffset(-0.5, -0.5)
 
  if  trackedUnitsCount > 0 then
  
    for unitID,texData in pairs(trackedUnits) do
      glDrawFuncAtUnit(unitID, false, DrawSuspectMarker, unitHeights[texData.unitDefID] + iconHeighth, trackedUnits[unitID].marker, trackedUnits[unitID].name)
    end   
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
