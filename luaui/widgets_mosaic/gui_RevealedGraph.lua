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
    name      = "Revealed Units Highlighting",
    desc      = "Highlights all revealed Units and the respective Locations",
    author    = "picasso",
    date      = "Year 2021 after Spring Died (A.S.D)",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true
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
local spDiffTimers           = Spring.DiffTimers
local spGetAllUnits          = Spring.GetAllUnits
local spGetGroundNormal      = Spring.GetGroundNormal
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


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gaiaTeamID = Spring.GetGaiaTeamID () --+++
function widget:PlayerChanged() --+++
  gaiaTeamID = Spring.GetGaiaTeamID () --+++
end --+++

local Locations = {
  --contains with key unitID (x,y,z, teamID, radius and  revealedUnits as table[unitID] -> {defID = unitDefID, boolIsParent }
  --if all revealed Units are no more, a location ceases to be relevant
}

-- > Counts the number of elements in a dictionary
function count(T)
    if not T then return 0 end
    local index = 0
    for k, v in pairs(T) do if v then index = index + 1 end end
    return index
end 

-- >Retrieves a random element from a Dictionary
function randDict(Dict)
    if not Dict then return end
    if lib_boolDebug == true then assert(type(Dict) == "table") end

    countDict = count(Dict)
    randElement = 1
    if countDict > 1 then randElement = math.random(1, count(Dict)) end

    index = 1
    anyKey = 1
    for k, v in pairs(Dict) do
        anyKey = k
        if index == randElement and k and v then return k, v end
        index = inc(index)
    end
    
    return anyKey, Dict[anyKey]
end


function addTestLocation()
  local allUnits = Spring.GetAllUnits()
  local locationID = allUnits[math.random(1,#allUnits)]
  local x,y,z = spGetUnitBasePosition(locationID)
  local revealedUnits = {}
  
  for i=1, i < math.random(3,6) do
    dependent = randDict(allUnits)
    revealedUnits[dependent]={
    defID = spGetUnitDefID(dependent),
    boolIsParent = math.random(0,1)==1
    }
  end

  Locations[locationID]  = {
    x=x,
    y=y,
    z=z,
    teamID = spGetUnitTeam(locationID),
    revealedUnits = revealedUnits
  }

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}


local locationLines  = 0
local locationPolys  = 0
local circleDivs   = 32
local circleOffset = 0
local heightOffset = 50

local revealedLines = 0
local revealedPolys = 0

local startTimer = spGetTimer()
local Polygon = { }
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function newPolygon(x,y,z)
 local Polygon = {}
 addLineSegment(x,y,z)
end

function addLineSegment(x,y,z)
  local pos = {[1]=x,[2]=y,[3]=z}
  Polygon[#Polygon+1] = pos
end

local polygonToDraw = {}


local function DrawLine(offsetY)
  for i = 1, #polygonToDraw do
    local x = polygonToDraw[i][1]
    local z = polygonToDraw[i][3]
    local y = Spring.GetGroundHeight(x, z) + offsetY
    gl.Vertex(x,y,z)
  end
end

local function DrawRectangle( Locx, Locz, radius, offsetY)
  local x = Locx - radius
  local z = Locz + radius
  local gh = Spring.GetGroundHeight(x, z) + offsetY
  gl.Vertex(x,gh,z)

  local x = Locx + radius
  local z = Locz + radius
  local gh = Spring.GetGroundHeight(x, z) + offsetY
  gl.Vertex(x,gh,z)

  local x = Locx + radius
  local z = Locz - radius
  local gh = Spring.GetGroundHeight(x, z) + offsetY
  gl.Vertex(x,gh,z)

  local x = Locx - radius
  local z = Locz - radius
  local gh = Spring.GetGroundHeight(x, z) + offsetY
  gl.Vertex(x,gh,z)
end

function widget:GameFrame(n)
    if n == startFrame + 60 then
      for id,_ in pairs(Spring.GetAllUnits()) do
          if math.random(0,1)== 1 then


          end

      end

    end
  end

local startFrame  = Spring.GetGameFrame()
function widget:Initialize()
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
  
  --TODO Replace with Quadrants(Locations) and Triangles (Revealed Units)
  locationPolys = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
   local     Triangle={
              [1]={x=-1,y=0},
              [2]={x=0,y=1},
              [3]={x=1,y=0},
            }

      for i = 1, 3 do
        glVertex(Triangle[1].x, heightOffset,Triangle[1].y)
      end
    end)
  end)


  revealedLines = glCreateList(function()
    glBeginEnd(GL_LINE_LOOP, function()
       local  Quad={
              [1]={x=-1,y=0},
              [2]={x=0,y=1},
              [3]={x=1,y=0},
              [4]={x=0,y=-1},
          }
    for i = 1, 4 do
        glVertex(Quad[1].x, heightOffset , Quad[1].y)
      end
    end)
  end)
  
  --TODO Replace with Quadrants(Locations) and Triangles (Revealed Units)
  revealedPolys = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
 local       Quad={
    [1]={x=-1,y=0},
    [2]={x=0,y=1},
    [3]={x=1,y=0},
    [4]={x=0,y=-1},
}
      for i = 1, 4 do
        glVertex(Quad[1].x, heightOffset, Quad[1].y)
      end
    end)
  end)
end


function widget:Shutdown()
  glDeleteList(locationLines)
  glDeleteList(locationPolys) 

  glDeleteList(revealedLines)
  glDeleteList(revealedPolys)
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
  r,g,b = 122/255, 250/255, 255/255
    colors = {{ r, g, b, 0.4 },
        { r, g, b, 0.7 }}
  return colors  
  end
  
  local colors = teamColors[teamID]
  if (colors) then
    return colors
  end
  local r,g,b = spGetTeamColor(teamID)
  
  colors = {{ r, g, b, 0.4 },
            { r, g, b, 0.7 }}
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

function isLocationOnScreen(x,y,z)
--TODO
return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--UnitID -> defID, canFly
local unitCache={}
local colorCache={}



function widget:DrawWorld()
  glLineWidth(3.0)
  glDepthTest(true)
  glPolygonOffset(-50, -2)

  --local Locations = {
  --contains with key unitID (x,y,z, teamID, radius and  revealedUnits as table[unitID] -> unitDefID
  for unitID, LocationData in ipairs(Locations) do
    local Loc = LocationData
    if isLocationOnScreen(Loc.x, Loc.y, Loc.z) == true then
      local teamID = Loc.teamID
      if teamID then
        local radius = Loc.radius or 15
        local colorSet  = colorCache[teamID]
        if not colorSet then 
          colorSet= GetTeamColorSet(teamID)
          colorCache[teamID]=colorSet
        end
        --if there doesent exist yet a shifted teamcolourtable - compute it
        if not teamColorPlayers[teamID] then
          computeTeamColorOffsetByPlayer(teamID,25)
        end

        glColor(colorSet[1])
        gl.LineWidth(6.0)
        gl.BeginEnd(GL.LINE_STRIP, DrawRectangle, Loc.x, Loc.z, radius, heightOffset)
        gl.LineWidth(1.0)
        gl.Color(1, 1, 1, 1)

        for id, defID in ipairs(Loc.revealedUnits) do
        local radius = GetUnitDefRealRadius(id)
          glColor(colorSet[1])
          glDrawListAtUnit(id, revealedPolys, false, radius, 1.0, radius)
          glColor(colorSet[2])
          glDrawListAtUnit(id, revealedLines, false, radius, 1.0, radius)
          
          --drawStripe from Location to Unit
          newPolygon(Loc.x, Loc.y, Loc.z)
          ux,uy,uz = spGetUnitBasePosition(id)
          addLineSegment(ux,uy,uz)
          gl.LineWidth(3.0)
          gl.Color(colorSet[1].r,colorSet[1].g, colorSet[1].b, 0.25)
          gl.BeginEnd(GL.LINE_STRIP, DrawLine, heightOffset)
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

function widget:GameFrame(n)
    if n % 10 == 0 then
       addTestLocation()
        if GG.RevealedLocations then
          -- Locations = GG.RevealedLocations
        end 
    end

end

