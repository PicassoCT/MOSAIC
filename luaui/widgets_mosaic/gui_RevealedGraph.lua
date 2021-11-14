--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_team_platter.lua
--  brief:   team colored platter for all visible units, teamcolour altered depending on player who last ordered them
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "highlightRevealedUnitGraph",
    desc      = "Highlights all revealed Units and the respective Locations",
    author    = "picasso",
    date      = "Year 2021 after Spring Died (A.S.D)",
    license   = "GNU GPL, v2 or later",
    layer     = 15,
    enabled   = true,
    handler = true,
    hidden = true
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local glBeginEnd             = gl.BeginEnd
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glDrawListAtUnit       = gl.DrawListAtUnit
local glLineWidth            = gl.LineWidth
local glPolygonOffset        = gl.PolygonOffset
local glVertex               = gl.Vertex
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glRect           = gl.Rect
local glTranslate      = gl.Translate
local glRotate         = gl.Rotate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
local glPushMatrix =gl.PushMatrix
local glPopMatrix =gl.PopMatrix


local spDiffTimers           = Spring.DiffTimers
local spGetAllUnits          = Spring.GetAllUnits
local spGetGroundNormal      = Spring.GetGroundNormal
local spGetGroundHeight      = Spring.GetGroundHeight
local spGetSelectedUnits     = Spring.GetSelectedUnits
local spGetTeamColor         = Spring.GetTeamColor
local spGetTimer             = Spring.GetTimer
local spGetUnitBasePosition  = Spring.GetUnitBasePosition
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitRadius        = Spring.GetUnitRadius
local spGetUnitTeam          = Spring.GetUnitTeam
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsUnitSelected       = Spring.IsUnitSelected
local spIsUnitVisible        = Spring.IsUnitVisible
local spSendCommands         = Spring.SendCommands
local spGetGameFrame         = Spring.GetGameFrame

local Locations = {
  --contains with key unitID (x,y,z, teamID, endFrame, radius and  revealedUnits as table[unitID] -> {defID = unitDefID, boolIsParent }
  --if all revealed Units are no more, a location ceases to be relevant
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local iconsizeX = 60
local iconsizeZ = 20
local textSize = 5
local suspectCol = {0.0, 1.0, 0.0, 0.95}
local baseWhite = {1.0, 1.0, 1.0, 0.35}
local baseBlack = {0.0, 0.0, 0.0, 1.0}

local function deserializeStringToTable(str)
  local f
  local msg = "no message"
  f, msg= loadstring(str)
  if not f then Spring.Echo("Error deserializing:"..msg) end
  return f()
end


local gaiaTeamID = Spring.GetGaiaTeamID () --+++
function widget:PlayerChanged() --+++
  gaiaTeamID = Spring.GetGaiaTeamID () --+++
end --+++


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}
local locationLines  = 0
local locationPolys  = 0
local circleDivs   = 32
local circleOffset = 300
local heightOffset = 0

local startTimer = spGetTimer()
local Polygon = { }
local maxHeightIcon = 500
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

local function DrawLine(polyToDraw, offsetY)
  local n = #polyToDraw
  for i = 1, n do
    local x = polyToDraw[i][1]
    local z = polyToDraw[i][3]
    local y = Spring.GetGroundHeight(x, z) + offsetY
    glVertex(x,y,z)
  end
end

local function DrawTriangle( Locx, Locz, radius, offsetY)
  local gh = spGetGroundHeight(Locx, Locz) 
  local x = Locx - radius
  local z = Locz 

  glVertex(x,gh + offsetY, z)

  local x = Locx - radius*2
  local z = Locz - radius
  glVertex(x,gh + offsetY,z)

  local x = Locx 
  local z = Locz -radius
  glVertex(x,gh + offsetY,z)

  local x = Locx - radius
  local z = Locz 
  glVertex(x,gh + offsetY,z)

  local x = Locx 
  local z = Locz 
  glVertex(x,gh +offsetY,z)

  local x = Locx 
  local z = Locz 
  glVertex(x,gh,z)
end

local function DrawCircle( Locx, Locz, radius, offsetY)
  local gh = spGetGroundHeight(Locx, Locz) 

  local radstep = (2.0 * math.pi) / 12
  for i = 1, circleDivs do
    local a = (i * radstep)
    glVertex(Locx + math.sin(a) * radius, gh + offsetY, Locz + math.cos(a) * radius)
  end

  local x = Locx 
  local z = Locz 
  glVertex(x,gh +offsetY,z)

  local x = Locx 
  local z = Locz 
  glVertex(x,gh,z)
end

function RevealedGraphChanged(newLocationData)
  if newLocationData then
    Locations = deserializeStringToTable(newLocationData)
  end
end

local startFrame  = 1
function widget:Initialize()
  widgetHandler:RegisterGlobal(widget, 'RevealedGraphChanged', RevealedGraphChanged)
  startFrame  = Spring.GetGameFrame()
  locationLines = glCreateList(function()
    glBeginEnd(GL_LINE_LOOP, function()
      local Triangle={
              [1]={x=-1,y=0},
              [2]={x=0,y=1},
              [3]={x=1,y=0},
            }
      for i = 1, 3 do
       glVertex(Triangle[1].x, heightOffset, Triangle[1].y)
      end
    end)
  end)
end

function widget:Shutdown()
     widgetHandler:DeregisterGlobal('RevealedGraphChanged')
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local realRadii = {}

local function GetUnitDefRealRadius(udid)
  local radius = realRadii[udid]
  if (radius) then
    return radius
  end

  local ud = UnitDefs[udid]
  if (ud == nil) then return nil end

  local dims = spGetUnitDefDimensions(udid)
  if (dims == nil) then return nil end

  local scale = ud.hitSphereScale -- missing in 0.76b1+
  scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
  radius = dims.radius / scale
  realRadii[udid] = radius
  return radius
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}

local function GetTeamColorSet(teamID)
  if teamID == Spring.GetGaiaTeamID() then
  r,g,b = 27/255, 197/255, 184/255
  dr,dg,db = 255/255, 191/255, 13/255
    colors = {{ r, g, b, 0.5 }, --night
              { r, g, b, 0.75 },
              { dr, dg, db, 0.5 }, --day
              { dr, dg, db, 0.75 }
              }
  return colors  
  end
  
  local colors = teamColors[teamID]
  if (colors) then
    return colors
  end
  local r,g,b = spGetTeamColor(teamID)
  
  colors = {{ r, g, b, 0.5 },
            { r, g, b, 0.6 },
            { r, g, b, 0.5 },
            { r, g, b, 0.6 }
            }
  teamColors[teamID] = colors
  return colors
end

function clamp(val,min,max)
  if val < min then return min end
  if val > max then return max end
  return val
end

function randSign()
  if math.random(0,1)==1 then return -1 else return 1 end
end

--Table contains shifted TeamColors 
-- -> [teamid][playerid]  = color
-- -> [teamid][playername]  = color
local teamColorPlayers={}
uniqueString=""
uniqueNumber=100

--generates a Teamcolour slightly shifted by PlayerName 
function computeTeamColorOffsetByPlayer(teamID,hashUpper)
  if teamColorPlayers[teamID]== nil then teamColorPlayers[teamID]= {} end
  if not teamColors[teamID] then GetTeamColorSet(teamID) end
  
  playerList=Spring.GetPlayerList(teamID)
    if table.getn(playerList)==1 then 
      teamColorPlayers[playerList[1]]=teamColors[teamID]
      return
    end
  
  --compute for every player a unique offset
  for index,player in ipairs(playerList) do
    uniqueNumber=uniqueNumber+1
    name= Spring.GetPlayerInfo(player)
    name=name..uniqueString..uniqueNumber
    uniqueString=uniqueString..name..uniqueNumber
    
    length=math.floor(string.len(uniqueString)/3)
    accColOffset={[1]=0,[2]=0,[3]=0}
    acoIndex=1
    accValue=0
    
      for acc=1,string.len(uniqueString), 1 do
          if acc % length == 0 then
            accColOffset[acoIndex]=accValue
            accValue=0  
            acoIndex=acoIndex+1
          end
        accValue=accValue+string.byte(uniqueString,acc)
      end
    
    rhash = randSign()*accColOffset[1]%hashUpper
    ghash = randSign()*accColOffset[2]%hashUpper
    bhash = randSign()*accColOffset[3]%hashUpper
    
    local colors=teamColors[teamID]
    colors[1].r = clamp(colors[1].r+rhash,1,255)
    colors[1].g = clamp(colors[1].g+ghash,1,255)
    colors[1].b =   clamp(colors[1].b+bhash,1,255)
    colors[2].r = clamp(colors[2].r+rhash,1,255)
    colors[2].g = clamp(colors[2].g+ghash,1,255)
    colors[2].b=  clamp(colors[2].b+bhash,1,255)
    teamColorPlayers[teamID][player]=colors
    teamColorPlayers[teamID][name]=colors
  end
end

local function getDayTime()
    local DAYLENGTH = 28800
    local morningOffset = (DAYLENGTH / 2)
    Frame = (spGetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end

local function mirrorValue(val)
    if val < 0.5 then
      return val * 2    
    else
      return (0.5 - math.abs( val - 0.5))*2    
    end
end

local function getDayTimeDependentColor(colSet)
    local _,_,_, percent = getDayTime()
    percent = 1-mirrorValue(percent)

    local blendedColor = {}
    blendedColor[1]={}

    blendedColor[1][1] = (1-percent)* colSet[1][1] + (percent)* colSet[3][1]
    blendedColor[1][2] = (1-percent)* colSet[1][2] + (percent)* colSet[3][2]
    blendedColor[1][3] = (1-percent)* colSet[1][3] + (percent)* colSet[3][3]
    blendedColor[1][4] = 0.5 
       
    blendedColor[2]={}  
    blendedColor[2][1] = (1-percent)* colSet[2][1] + (percent)* colSet[4][1]
    blendedColor[2][2] = (1-percent)* colSet[2][2] + (percent)* colSet[4][2]
    blendedColor[2][3] = (1-percent)* colSet[2][3] + (percent)* colSet[4][3]
    blendedColor[2][4] = 0.75
      
  return blendedColor
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--UnitID -> defID, canFly
local colorCache={}
local revealColour = {50/255, 244/255, 253/255, 1.0}

local function DrawSafeHouseMarker(Loc,  yshift, designator, name)
  local maxstringlength = math.max(math.max(string.len(designator),string.len(name)),iconsizeX)*2
  glPushMatrix()
  glTranslate(Loc.x, Loc.y, Loc.z)
  glColor(baseWhite)
  glLineWidth(3.0)
  local gh = spGetGroundHeight(Loc.x, Loc.z)
  yshift = yshift + gh
  glRect(-1, yshift, 1, 0)

  glTranslate(0,yshift,0)
  --Draw Base Plate
  glColor(baseBlack)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, -iconsizeZ)
  glColor(revealColour)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, 0)
  glColor(baseBlack)
  gl.BeginText ( ) 
  glColor(baseBlack)
  gl.Text ("\255\0\0\0 ◉"..string.upper(designator), -iconsizeX+2, iconsizeZ*0.9, textSize*3.75 , "lt" ) 
  glColor(revealColour)
  gl.Text ("\255\50\244\253 ◸♜ "..string.upper(name).." ☰", -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" ) 
  gl.EndText()
  glPopMatrix()
end

local parentColour = {1.0,34/255,12/255, 1.0}
local function DrawRevealedMarkerParent(Loc,  yshift, designator, name)
  local maxstringlength = math.max(math.max(string.len(designator),string.len(name)),iconsizeX)*2
  glPushMatrix()
  glTranslate(Loc.x, Loc.y, Loc.z)
  glColor(baseWhite)
  glLineWidth(3.0)
  local gh = spGetGroundHeight(Loc.x, Loc.z)
  yshift = yshift + gh
  glRect(-1, yshift, 1, 0)

  glTranslate(0,yshift,0)
  --Draw Base Plate
  glColor(baseBlack)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, -iconsizeZ)
  glColor(parentColour)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, 0)
  glColor(baseBlack)
  gl.BeginText ( ) 
  glColor(baseBlack)
  gl.Text ("\255\0\0\0 ◈ "..string.upper(designator), -iconsizeX+2, iconsizeZ*0.9, textSize*3.75 , "lt" ) 
  glColor(parentColour)
  gl.Text ("\255\255\34\12 ◤♞⚔ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" ) 
  gl.EndText()
  glPopMatrix()
end

local childcolour =  {1.0,72/255,0, 1.0}
local function DrawRevealedMarkerChild(Loc,  yshift, designator, name)
  local maxstringlength = math.max(math.max(string.len(designator),string.len(name)),iconsizeX)*2
  glPushMatrix()
  glTranslate(Loc.x, Loc.y, Loc.z)
  glColor(baseWhite)
  glLineWidth(3.0)
  local gh = spGetGroundHeight(Loc.x, Loc.z)
  yshift = yshift + gh
  glRect(-1, yshift, 1, 0)

  glTranslate(0,yshift,0)
  --Draw Base Plate
  glColor(baseBlack)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, -iconsizeZ)
  glColor(childcolour)
  glRect(-iconsizeX, iconsizeZ, maxstringlength, 0)
  glColor(baseBlack)
  gl.BeginText ( ) 
  glColor(baseBlack)
  gl.Text ("\255\0\0\0 ◈ "..string.upper(designator), -iconsizeX+2, iconsizeZ*0.9, textSize*3.75 , "lt" ) 
  glColor(childcolour)
  gl.Text ("\255\255\72\0 ◤♚⛁ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" ) 
  gl.EndText()
    glPopMatrix()
end

--Draw Revealed master  
function widget:DrawWorld()
  glLineWidth(1.0)
  glDepthTest(true)
  glPolygonOffset(-50, -2)

  for i=1, #Locations do
  local Loc = Locations[i]
      local teamID = Loc.teamID
      if teamID then
        local radius = Loc.radius 
        local colorSet  = colorCache[teamID]
        if not colorSet then 
          colorSet= GetTeamColorSet(teamID)
          colorCache[teamID]=colorSet
        end
        --if there doesent exist yet a shifted teamcolourtable - compute it
        if not teamColorPlayers[teamID] then
          computeTeamColorOffsetByPlayer(teamID, 25)
        end

        local dayTimeDependentColorSet = getDayTimeDependentColor(colorSet)
        glColor(dayTimeDependentColorSet[1])
        gl.LineWidth(3.0)
        local runtimeInSeconds = math.ceil(Loc.endFrame -  spGetGameFrame())/30
        DrawSafeHouseMarker(Loc,  
							maxHeightIcon,
							"SOURCE:"..string.char(65 + (i % 24))..i, 
							"Location: ("..Loc.x.."/"..Loc.z..") TIME:"..runtimeInSeconds.."s")

        gl.LineWidth(1.0)
        gl.Color(1, 1, 1, 1)

        local revealedUnits = Loc.revealedUnits
        for id, defID in pairs(revealedUnits) do
          if  Spring.GetUnitIsDead(id) == false then 
          local x, y, z = spGetUnitBasePosition(id)
          local radius = GetUnitDefRealRadius(id) or 50
          local gx, gy, gz = spGetGroundNormal(x, z)
          local degrot = math.acos(gy) * 180 / math.pi
		  local ud = UnitDefs[defID] 
          local designation =  string.sub(ud.tooltip,string.find(ud.tooltip,"<"), string.find(ud.tooltip,">"))
          if Loc.boolIsParent then
            glColor(dayTimeDependentColorSet[2])
            gl.LineWidth(3.0)
            gl.LineWidth(1.0)
            gl.Color(1, 1, 1, 1)
            DrawRevealedMarkerParent({x=x,y=y,z=z}, 
										maxHeightIcon, 
										"ROOT: "..id, 
										"TYPE:"..designation )
          else
            glColor(dayTimeDependentColorSet[2])
            gl.LineWidth(3.0)
            gl.LineWidth(1.0)
            gl.Color(1, 1, 1, 1)
            DrawRevealedMarkerChild({x=x,y=y,z=z},
									maxHeightIcon,
									"TARGET: "..id,
									"TYPE:"..designation)
          end
        
          --drawStripe from Location to Unit
          newPolygon(Loc.x, Loc.y, Loc.z)
          ux,uy,uz = spGetUnitBasePosition(id)
          addLineSegment(ux,uy,uz)
          gl.LineWidth(2.0)
          glColor(dayTimeDependentColorSet[1])
          gl.BeginEnd(GL.LINE_STRIP, DrawLine, Polygon ,maxHeightIcon-50)
          --reset
          gl.LineWidth(1.0)
          gl.Color(1, 1, 1, 1)
          end   
        end   
      end
  end

  glPolygonOffset(false)
  glDepthTest(false)
  local alpha = 0.3
  glColor(1, 1, 1, alpha)
  glLineWidth(1.0)
end

