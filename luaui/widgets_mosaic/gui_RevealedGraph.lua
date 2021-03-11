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
    enabled   = true  --  loaded by default?
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}


local locationLines  = 0
local locationPolys  = 0
local circleDivs   = 32
local circleOffset = 0
local revealedHeighthOffset = 50

local revealedLines = 0
local revealedPolys = 0

local startTimer = spGetTimer()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
    Triangle={
    [1]={x=-1,y=0},
    [2]={x=0,y=1},
    [3]={x=1,y=0},
  locationLines = glCreateList(function()
    glBeginEnd(GL_LINE_LOOP, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        glVertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
  end)
  
  --TODO Replace with Quadrants(Locations) and Triangles (Revealed Units)
  locationPolys = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        glVertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
  end)

  Quad={
    [1]={x=-1,y=0},
    [2]={x=0,y=1},
    [3]={x=1,y=0},
    [4]={x=0,y=-1},
}
  revealedLines = glCreateList(function()
    glBeginEnd(GL_LINE_LOOP, function()
      for i = 1, 4 do
        glVertex(Quad[1].x, revealedHeighthOffset,Quad[1].y)
      end
    end)
  end)
  
  --TODO Replace with Quadrants(Locations) and Triangles (Revealed Units)
  revealedPolys = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
      for i = 1, 4 do
        glVertex(Quad[1].x, revealedHeighthOffset,Quad[1].y)
      end
    end)
  end)


end


function widget:Shutdown()
  glDeleteList(locationLines)
  glDeleteList(locationPolys) 

--[[  glDeleteList(revealedLines)
  glDeleteList(revealedPolys)--]]
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

  local selectedUnits=spGetSelectedUnits()
  
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
      
       --[[ glColor(colorSet[1])
        glDrawAtLocation(Loc.x, Loc.y + IconOffSet, Loc.z, locationPolys, false, radius, 1.0, radius)
        glColor(colorSet[2])
        glDrawAtLocation(Loc.x, Loc.y + IconOffSet, Loc.z, locationLines, false, radius, 1.0, radius)
        --]]

        for id, defID in ipairs(Loc.revealedUnits) do
        local radius = GetUnitDefRealRadius(id)
          glColor(colorSet[1])
          glDrawListAtUnit(id, revealedPolys, false, radius, 1.0, radius)
          glColor(colorSet[2])
          glDrawListAtUnit(id, revealedLines, false, radius, 1.0, radius)
          
          --drawStripe from Location to Unit
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
    if frame % 10 == 0 then
        if GG.RevealedLocations then
        Locations = GG.RevealedLocations
        end 
    end
end

