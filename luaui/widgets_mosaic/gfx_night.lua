local versionNumber = "v1.5.4"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Night",
    desc      = versionNumber .. " Makes map appear as nighttime and gives units searchlights.\n"
                              .. "toggles: /luaui [night_preunit | night_beam | night_cycle] \n"
                              .. "searchlight strength: /luaui night_setsearchlight [number]; base type: /luaui night_basetype [0-2]",
    author    = "Evil4Zerggin; based on jK's darkening widget, maimed by pica",
    date      = "28 September 2008",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------

local nightColorMap        = {{0.4, 0.5, 0.6}, --midnight
                              {0.4, 0.5, 0.6},
                              {0.4, 0.5, 0.6},
                              
                              {1, 0.8, 0.6},
                              {1, 1, 1},
                              {1, 1, 1},
                              
                              {1, 1, 1}, --noon
                              {1, 1, 1},
                              {1, 1, 1},
                              
                              {1, 0.8, 0.6},
                              {0.4, 0.5, 0.6},
                              {0.4, 0.5, 0.6}}
                              
local searchlightBeamColor = {1, 1, 0.75, 0.05}  --searchlight beam color
local searchlightStrength  = 0.6                 --searchlight strength; <= 0 to turn off
local searchlightHeightOffset = 0.5              --raises searchlight above unit's middle by this multiple of the unit's radius
local preUnit              = true                --if true, night is applied pre-unit
local drawBeam             = true                --if true, will draw the searchlight beam
local baseType             = 2               --0: off, 1: simple, 2: full

local searchlightVertexCount       = 16          --roughly many vertices to use

local searchlightAirLeadTime       = 2           --roughly how many seconds ahead the searchlight aims
local searchlightGroundLeadTime    = 1           --roughly how many seconds ahead the searchlight aims

local dayNightCycle        = true                --enables day/night cycle
local startDayTime         = 0                   --start time, between 0 and 1; 0 = midnight, 0.5 = noon
local secondsPerDay        = 960                --seconds per day

local function getDayTime()
    local DAYLENGTH = 28800
    local morningOffset = (DAYLENGTH / 2)
    Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end
--------------------------------------------------------------------------------
--other vars
--------------------------------------------------------------------------------

local currColor, currColorInverse

local hoursPerDay = #nightColorMap

local currDayTime

local searchlightVertexIncrement = (math.pi * 2) / searchlightVertexCount

local searchlightBuildingAngle = 0

local lightList = {}

local vsx, vsy

--------------------------------------------------------------------------------
-- speedups and constants
--------------------------------------------------------------------------------

local GetMapDrawMode = Spring.GetMapDrawMode
local GetVisibleUnits = Spring.GetVisibleUnits
local GetUnitPosition = Spring.GetUnitPosition
local GetUnitHeight = Spring.GetUnitHeight
local GetGroundHeight = Spring.GetGroundHeight
local GetUnitHeading = Spring.GetUnitHeading
local GetUnitDefID = Spring.GetUnitDefID
local GetUnitVelocity = Spring.GetUnitVelocity
local GetUnitIsCloaked = Spring.GetUnitIsCloaked
local GetUnitHealth = Spring.GetUnitHealth
local GetUnitRadius = Spring.GetUnitRadius
local GetGameSpeed = Spring.GetGameSpeed
local GetCameraPosition = Spring.GetCameraPosition
local GetUnitTransporter = Spring.GetUnitTransporter
local SendMessage = Spring.SendMessage

local glMatrixMode = gl.MatrixMode
local glLoadIdentity = gl.LoadIdentity
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glColor = gl.Color
local glRect = gl.Rect
local glTranslate = gl.Translate
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glPolygonMode = gl.PolygonMode
local glDepthTest = gl.DepthTest
local glBlending = gl.Blending

local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN
local GL_PROJECTION = GL.PROJECTION
local GL_MODELVIEW = GL.MODELVIEW
local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_FILL = GL.FILL
local GL_POLYGON = GL.POLYGON
local GL_SRC_COLOR = GL.SRC_COLOR
local GL_DST_COLOR = GL.DST_COLOR
local GL_SRC_ALPHA = GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_ONE = GL.ONE
local GL_ZERO = GL.ZERO

local RADIANS_PER_COBANGLE = math.pi / 32768

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function UpdateColors()
  local currHour = math.floor(currDayTime * hoursPerDay) + 1
  local currHourPart = currDayTime * hoursPerDay - currHour + 1
  local startColor = nightColorMap[currHour]
  local endColor
  if (currHour == hoursPerDay) then 
    endColor = nightColorMap[1] 
  else 
    endColor = nightColorMap[currHour+1]
  end
  
  currColor = {(1 - currHourPart) * startColor[1] + currHourPart * endColor[1],
               (1 - currHourPart) * startColor[2] + currHourPart * endColor[2],
               (1 - currHourPart) * startColor[3] + currHourPart * endColor[3],
               1}
  currColorInverse = {(1 / currColor[1] - 1) * searchlightStrength, 
                      (1 / currColor[2] - 1) * searchlightStrength, 
                      (1 / currColor[3] - 1) * searchlightStrength, 
                       1}
end

local function BaseVertices(baseX, baseZ, radius, ecc, heading)
  local theta = heading
  while theta < heading + 2 * math.pi do
    local denom = (1 - ecc * math.cos(theta - heading))
    local vx = baseX + radius * math.cos(theta) / denom
    local vz = baseZ + radius * math.sin(theta) / denom
    local vy = math.max(GetGroundHeight(vx, vz), 0)
    glVertex(vx, vy, vz)
    theta = theta + searchlightVertexIncrement * denom 
  end
  local denom = 1 - ecc
  local vx = baseX + radius * math.cos(heading) / denom
  local vz = baseZ + radius * math.sin(heading) / denom
  local vy = math.max(GetGroundHeight(vx, vz), 0)
  glVertex(vx, vy, vz)
end

local function ConeVertices(baseX, baseZ, radius, ecc, heading, cx, cy, cz)
  local groundy = math.max(GetGroundHeight(baseX, baseZ), 0)
  local dx = cx - baseX
  local dy = cy - groundy
  local dz = cz - baseZ
  local mult = radius / math.sqrt(dx*dx + dy*dy + dz*dz)
  dx = dx * mult
  dy = dy * mult
  dz = dz * mult
  glVertex(baseX + dx, groundy + dy, baseZ + dz)
  BaseVertices(baseX, baseZ, radius, ecc, heading)
end

local function BeamVertices(baseX, baseZ, radius, ecc, heading, px, py, pz)
  glVertex(px, py, pz)
  BaseVertices(baseX, baseZ, radius, ecc, heading)
end

local function DrawNight()
  glBlending(GL_ZERO, GL_SRC_COLOR)
  
  glMatrixMode(GL_PROJECTION)
  glPushMatrix()
  glLoadIdentity()
  glMatrixMode(GL_MODELVIEW)
  glPushMatrix()
  glLoadIdentity()

  glColor(currColor)
  glRect(-1,1,1,-1)

  glMatrixMode(GL_PROJECTION)
  glPopMatrix()
  glMatrixMode(GL_MODELVIEW)
  glPopMatrix()
  
  glColor(1, 1, 1, 1)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

local function DrawSearchlights()
  if (searchlightVertexCount < 2) then return end
  
  local visibleUnits = GetVisibleUnits(-1, 30, false)
  local cx, cy, cz = GetCameraPosition()
  local timeFromNoon = math.abs(currDayTime - 0.5)
  
  glTranslate(0, 0, 0)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  
  for _, unitID in pairs(visibleUnits) do
    local _, _, _, _, buildProgress = GetUnitHealth(unitID)
    local unitRadius = GetUnitRadius(unitID)
    local px, py, pz = GetUnitPosition(unitID)
    py = py + searchlightHeightOffset * unitRadius
    local groundy = math.max(GetGroundHeight(px, pz), 0)
    local height = py - groundy
    local unitDefID = GetUnitDefID(unitID)
    local unitDef = UnitDefs[unitDefID]
    local speed = unitDef.speed
    
    if (height > 0
        and (not buildProgress or buildProgress >= 1)
        and  lightList[unitDefID]
        and timeFromNoon > (0.25 + ((unitID * 97) % 256) / 8192)
        and not GetUnitIsCloaked(unitID)
        and not GetUnitTransporter(unitID)
        ) then
      local leadDistance
      local radius
      local ecc
      local heading
      local baseX, baseZ
      
      if (not speed or speed == 0) then
        heading = searchlightBuildingAngle * (0.5 + ((unitID * 137) % 256) / 512)
        leadDistance = unitRadius * 2
        radius = unitRadius
      elseif (unitDef.canFly) then
        heading = -GetUnitHeading(unitID) * RADIANS_PER_COBANGLE + math.pi / 2
        local range = math.max(unitDef.buildDistance, unitDef.maxWeaponRange)
        leadDistance = math.sqrt(math.max(range * range - unitDef.wantedHeight * unitDef.wantedHeight, 0)) * 0.8
        radius = unitRadius * 2
      else
        heading = -GetUnitHeading(unitID) * RADIANS_PER_COBANGLE + math.pi / 2
        leadDistance = searchlightGroundLeadTime * speed
        radius = unitRadius
      end
      
      baseX = px + leadDistance * math.cos(heading)
      baseZ = pz + leadDistance * math.sin(heading)
      ecc = math.min(1 - 2 / (leadDistance / height + 2), 0.75)
      
      --base
      glBlending(GL_DST_COLOR, GL_ONE)
      glColor(currColorInverse)
      
      if (baseType == 2) then
        glDepthTest(true)
        glBeginEnd(GL_TRIANGLE_FAN, ConeVertices, baseX, baseZ, radius, ecc, heading, cx, cy, cz, groundy)
      elseif (baseType == 1) then
        glDepthTest(false)
        glBeginEnd(GL_POLYGON, BaseVertices, baseX, baseZ, radius, ecc, heading)
      end
      
      --beam
      glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      
      if (drawBeam) then
        glColor(searchlightBeamColor)
        glDepthTest(true)
        glBeginEnd(GL_TRIANGLE_FAN, BeamVertices, baseX, baseZ, radius, ecc, heading, px, py, pz)
      end
      
      glColor(1, 1, 1, 1)
      glDepthTest(false)
      
    end
  end
  
end

local function TogglePreUnit()
  preUnit = not preUnit
  if (preUnit) then
    SendMessage("Night preunit turned on.")
  else
    SendMessage("Night preunit turned off.")
  end
end

local function SetBaseType(_,_,words)
  baseType = tonumber(words[1]) or 0
  if (baseType == 2) then
    SendMessage("Full searchlight bases.")
  elseif (baseType == 1) then
    SendMessage("Simple searchlight bases.")
  else
    SendMessage("No searchlight bases.")
  end
end

local function ToggleBeam()
  drawBeam = not drawBeam
  if (drawBeam) then
    SendMessage("Night beams turned on.")
  else
    SendMessage("Night beams turned off.")
  end
end

local function SetSearchlightStrength(_,_,words)
  searchlightStrength = tonumber(words[1])
  UpdateColors()
end

local function ToggleDayNightCycle()
  dayNightCycle = not dayNightCycle
  if (dayNightCycle) then
    SendMessage("Day/night cycle turned on.")
  else
    SendMessage("Day/night cycle turned off.")
  end
end

--------------------------------------------------------------------------------
--callins
--------------------------------------------------------------------------------

function widget:Initialize()
  currDayTime = startDayTime
  UpdateColors()
  vsx, vsy = widgetHandler:GetViewSizes()
  
  for unitDefID, unitDef in pairs(UnitDefs) do
    if (   string.find(unitDef.name, "truck")) and not string.find(unitDef.name, "payload")then
      lightList[unitDefID] = true
    end
  end
  
  widgetHandler:AddAction("night_preunit", TogglePreUnit, nil, "t")
  widgetHandler:AddAction("night_basetype", SetBaseType, nil, "t")
  widgetHandler:AddAction("night_beam", ToggleBeam, nil, "t")
  widgetHandler:AddAction("night_setsearchlight", SetSearchlightStrength, nil, "t")
  widgetHandler:AddAction("night_cycle", ToggleDayNightCycle, nil, "t")
end

function widget:Shutdown()
  widgetHandler:RemoveAction("night_preunit")
  widgetHandler:RemoveAction("night_basetype")
  widgetHandler:RemoveAction("night_beam")
  widgetHandler:RemoveAction("night_setsearchlight")
  widgetHandler:RemoveAction("night_cycle")
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

local hours = 0
function widget:Update(dt)
  hours = getDayTime()  
  local _, speedFactor, paused = GetGameSpeed()
  if (not paused) then
  end
end

function widget:DrawWorld()
--[[  if (not preUnit) then
    DrawNight()
  end--]]
 
  if (searchlightStrength > 0 and (hours  < 7 or hours > 19)) then
    DrawSearchlights()
  end
end
