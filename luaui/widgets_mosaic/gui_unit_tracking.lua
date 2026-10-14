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
  WG.ObservedCivilianUnits = nil
end

--------------------------------------------------------------------------------

local selectedUnits = Spring.GetSelectedUnits()
local selectedUnitsCount = Spring.GetSelectedUnitsCount()
local trackedUnits = {}
local worldDialogueCache = {}
WG.ObservedCivilianUnits = trackedUnits
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
      local trackedId = tonumber(rawNumber)
      if trackedId then setTrackedUnit(trackedId) end
    end
  end
end

local function setUntrackedUnit(id)
  local setUntrackedMessage = "SET_UNTRACKED:".. id
  Spring.SendLuaRulesMsg (setUntrackedMessage)
end

local trackedUnitsCount = 0
local nextTrackMarker = 0
function widget:KeyRelease(key)
  if (key == trackKey) then
    local mouseX, mouseZ = Spring.GetMouseState ( )
    local targType, unitID = Spring.TraceScreenRay(mouseX, mouseZ)
    if targType == "unit" then
      local defID = spGetUnitDefID(unitID)
      if not houseTypeTable[defID] then
        if trackedUnits[unitID] then
          trackedUnits[unitID] = nil
          worldDialogueCache[unitID] = nil
          trackedUnitsCount = math.max(0,trackedUnitsCount-1)
          setUntrackedUnit(unitID)
        else
          setTrackedUnit(unitID)
          trackedUnits[unitID] = {}
          trackedUnits[unitID].marker ="SUSPECT "..nextTrackMarker
          nextTrackMarker = nextTrackMarker + 1
          trackedUnits[unitID].name  = spGetUnitToolTip(unitID) or "Civilian"
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
   for id in pairs(trackedUnits) do setUntrackedUnit(id) end
   trackedUnits = {}
   worldDialogueCache = {}
   WG.ObservedCivilianUnits = trackedUnits
   trackedUnitsCount = 0
  end		
end

function widget:UnitDestroyed(id)
  if trackedUnits[id] then
    trackedUnits[id]=nil
    worldDialogueCache[id]=nil
    trackedUnitsCount=math.max(0,trackedUnitsCount-1)
  end
end

local iconsizeX = 60
local iconsizeZ = 20
local textSize = 5
local suspectCol = {0.0, 1.0, 0.0, 0.95}
local baseWhite = {1.0, 1.0, 1.0, 0.35}
local baseBlack = {0.0, 0.0, 0.0, 1.0}

-- These are world-space units in the same plane as the Observe marker. Both
-- dimensions of the dialogue box are bounded by twice the marker's dimensions.
local dialogueAlpha = 0.75 -- 25% transparent, NOT 25% opaque
local dialoguePadding = 6
local dialogueGap = 6
local dialogueSize = textSize * 1.5
local dialogueLineHeight = dialogueSize * 1.4

local function textWidth(s)
  return gl.GetTextWidth(s) * dialogueSize
end

local function wrapWorldText(s, limit)
  local rows, current = {}, ""
  for word in tostring(s):gmatch("%S+") do
    local candidate = current == "" and word or current .. " " .. word
    if textWidth(candidate) <= limit then
      current = candidate
    else
      if current ~= "" then rows[#rows+1] = current; current = "" end
      if textWidth(word) <= limit then
        current = word
      else
        -- Split an oversized single word at UTF-8 character boundaries. Text
        -- must never overrun the width cap, even for long generated tokens.
        local pos = 1
        while pos <= #word do
          local byte = word:byte(pos)
          local count = byte < 128 and 1 or byte < 224 and 2 or byte < 240 and 3 or 4
          local glyph = word:sub(pos, pos + count - 1)
          pos = pos + count
          if current ~= "" and textWidth(current .. glyph) > limit then
            rows[#rows+1] = current; current = ""
          end
          current = current .. glyph
        end
      end
    end
  end
  if current ~= "" then rows[#rows+1] = current end
  return rows
end

local function layoutDialogue(unitID, markerWidth, markerHeight, lines, first, last, revision)
  local cached = worldDialogueCache[unitID]
  if cached and cached.revision == revision and cached.first == first and
      cached.last == last and cached.markerWidth == markerWidth then
    return cached
  end

  local maxWidth = 2 * markerWidth
  local maxHeight = 2 * markerHeight
  local innerWidth = maxWidth - 2 * dialoguePadding
  local maxRows = math.max(1, math.floor((maxHeight - 2 * dialoguePadding) / dialogueLineHeight))
  local selected = {}
  -- Keep the latest utterance intact whenever it fits, adding older turns
  -- above it only while there is room. The full transcript is never modified.
  for i = last, first, -1 do
    local line = lines[i]
    local content = tostring(line.name or "Civilian") .. ": " .. tostring(line.text or "")
    local parts = wrapWorldText(content, innerWidth)
    if #parts > maxRows then
      if #selected == 0 then
        for j = 1, maxRows do selected[j] = parts[j] end
        local tail = selected[maxRows]
        while #tail > 0 and textWidth(tail .. "...") > innerWidth do
          tail = tail:sub(1, -2)
        end
        selected[maxRows] = tail .. "..."
      end
      break
    end
    if #selected + #parts > maxRows then break end
    for j = #parts, 1, -1 do table.insert(selected, 1, parts[j]) end
  end
  cached = {revision=revision, first=first, last=last, markerWidth=markerWidth,
    width=maxWidth, height=2*dialoguePadding+#selected*dialogueLineHeight, rows=selected}
  worldDialogueCache[unitID] = cached
  return cached
end

local function DrawWorldDialogue(unitID, markerWidth, markerHeight)
  local api = WG.CivilianConversationWorld
  if not api or not api.GetRecentLines then return end
  local lines, first, last, revision = api.GetRecentLines(unitID)
  if not lines or not first or not last then return end
  local layout = layoutDialogue(unitID, markerWidth, markerHeight, lines, first, last, revision)
  if #layout.rows == 0 then return end
  local centreX = (markerWidth - 2*iconsizeX) * 0.5
  local x0 = centreX - layout.width * 0.5
  local top = -iconsizeZ - dialogueGap
  glColor(0.035, 0.05, 0.05, dialogueAlpha)
  glRect(x0, top-layout.height, x0+layout.width, top)
  glColor(0.18, 0.64, 0.49, dialogueAlpha)
  glRect(x0, top-1.5, x0+layout.width, top)

  glColor(0.88, 0.95, 0.91, 1)
  local y = top - dialoguePadding - dialogueSize
  for _, row in ipairs(layout.rows) do
    gl.Text(row, x0+dialoguePadding, y, dialogueSize, "lo")
    y = y - dialogueLineHeight
  end
end

local function DrawSuspectMarker(yshift, designator, name, unitID)

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
  -- Use the same translated billboard so speech stays attached beneath this
  -- marker as the civilian moves and as the camera zooms/rotates.
  DrawWorldDialogue(unitID, maxstringlength + iconsizeX, iconsizeZ * 2)
end



function widget:DrawWorld()
	if chobbyInterface then return end
  if not trackedUnits or Spring.IsGUIHidden() then return end

  gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
  gl.DepthTest(true)
  gl.PolygonOffset(-0.5, -0.5)
 
  if  trackedUnitsCount > 0 then
  
    for unitID,texData in pairs(trackedUnits) do
      glDrawFuncAtUnit(unitID, false, DrawSuspectMarker, unitHeights[texData.unitDefID] + iconHeighth, texData.marker, texData.name, unitID)
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

