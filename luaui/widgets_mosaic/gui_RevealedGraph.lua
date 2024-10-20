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
local glPushMatrix     = gl.PushMatrix
local glPopMatrix      = gl.PopMatrix


local spGetGroundNormal      = Spring.GetGroundNormal
local spGetGroundHeight      = Spring.GetGroundHeight
local spGetTeamColor         = Spring.GetTeamColor
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitBasePosition  = Spring.GetUnitBasePosition
local spGetUnitDefDimensions = Spring.GetUnitDefDimensions
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
local countryPhoneNr = "0"

local function deserializeStringToTable(str)
  local f
  local msg = "no message"
  f, msg= loadstring(str)
  if not f then 
    --Spring.Echo("Error deserializing:"..msg) 
  end
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
    local y = spGetGroundHeight(x, z) + offsetY

    glVertex(x,y,z)
  end
end

local oldLocationData = ""
function RevealedGraphChanged(newLocationData)
  if newLocationData and newLocationData ~= oldLocationData then
      --Spring.Echo("RevealedGraphChanged:"..(newLocationData ))
      oldLocationData = newLocationData
  end
  
  if newLocationData then
    Locations = deserializeStringToTable(newLocationData)
  end
end

local function getDetermenisticHash()
  local accumulated = 0
  local mapName = Game.mapName
  local mapNameLength = string.len(mapName)

  for i=1, mapNameLength do
    accumulated = accumulated + string.byte(mapName,i)
  end

  accumulated = accumulated + Game.mapSizeX
  accumulated = accumulated + Game.mapSizeZ
  return accumulated
end

local function getCountryByCulture()
  local culture =  Spring.GetGameRulesParam ("culture") 
  if not culture then return "Atlantian" end
  local hash = getDetermenisticHash()
  local region_countryMap = {}
  region_countryMap ={
    Africa = {"Chad","Central African Republic","Senegal","Lesotho","Congo","Ghana","Botswana","Togo","Swaziland","South Africa","Eritrea","Zimbabwe","Algeria","Malawi","Sierra Leone","Liberia","Zambia","Kenya","Ethiopia","Guinea","Djibouti","Burkina Faso","Nigeria","Uganda","Comoros","Saint Helena","Guinea-Bissau","Namibia","Gambia","Benin","Gabon","Trinidad And Tobago","Niger","Cameroon","Angola","Cabo Verde","Burundi","Somalia","Mali","Tanzania","Rwanda","Mozambique","Côte D’Ivoire","Madagascar","Saint Martin"},
    MiddleEast = {"Tunisia","Libya","Sudan","Syria","Saudi Arabia","Jordan","Kuwait","Brunei","Algeria","Turkey","Iran","Lebanon","Qatar","West Bank","United Arab Emirates","Israel","Bahrain","Gaza Strip","Armenia","Iraq","Oman","Yemen","Egypt","Morocco","Pakistan", "Western Sahara", "Mauritania"},
    CentralAsia = {"Bhutan","Tajikistan","Iran","Georgia","Nepal","Azerbaijan","Russia","Kyrgyzstan","Afghanistan","Turkmenistan","Pakistan","Uzbekistan","Mongolia","Kazakhstan"},
    Europe = {"Cyprus","Belarus","Slovakia","Greece","Hungary","Montenegro","Macedonia","Kosovo","Sweden","Luxembourg","Belgium","Slovenia","Albania","Turkey","Serbia","Ukraine","France","Liechtenstein","United Kingdom","Iceland","Italy","Czechia","Andorra","Poland","Netherlands","Croatia","Russia","Malta","Germany","Ireland","Portugal","Monaco","Norway","Vatican City","Finland","Bulgaria","Moldova","Estonia","Lithuania","Latvia", "Switzerland","Romania","San Marino","Isle Of Man","Spain","Denmark","Austria","Gibraltar","Bosnia And Herzegovina"},
    NorthAmerica = {"United States","Panama","Canada","Greenland","Jersey","Village of Islands","El Salvador","Mexico",},
    SouthAmerica = {"Belize","Jamaica","Venezuela","Guyana","Equatorial Guinea","Argentina","Brazil","Peru","Ecuador","Honduras","Nicaragua","Bermuda","Bolivia","Cuba","Puerto Rico","Cayman Islands","Chile","Uruguay","Dominican Republic","Costa Rica","French Guiana","Sint Maarten","Mauritius","Saint Lucia","New Caledonia","Paraguay","Guatemala","Barbados","Colombia","French Polynesia",},
    SouthEastAsia = {"Bangladesh","Papua New Guinea","Myanmar","Cambodia","Australia","Thailand","Korea","China","Vietnam","New Zealand","Sri Lanka","Guadeloupe","Taiwan","Malaysia","Macau", "Wallis And Futuna","Grenada","Laos","Anguilla","Christmas Island","Pitcairn Islands","Guam","Singapore","Hong Kong","Japan","Philippines","Indonesia" }
  }

  if culture == "arabic" then
    if hash % 3 == 0 then
      return region_countryMap.MiddleEast[((hash*69) % #region_countryMap.MiddleEast) +1 ]
    end
    if hash % 3 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ]
    end
    if hash % 3 == 2 then
      return region_countryMap.Africa[((hash*69) % #region_countryMap.Africa) +1 ]
    end
  end

  if culture == "western" then 
    if hash % 3 == 0 then
      return region_countryMap.Europe[((hash*69) % #region_countryMap.Europe) +1 ]
    end
    if hash % 3 == 1 then
      return region_countryMap.NorthAmerica[((hash*69) % #region_countryMap.NorthAmerica) +1 ]
    end
    if hash % 3 == 2 then
      return region_countryMap.SouthAmerica[((hash*69) % #region_countryMap.SouthAmerica) +1 ]
    end
  end

  if culture == "asian" then
    if hash % 2 == 0 then
      return region_countryMap.SouthEastAsia[((hash*69) % #region_countryMap.SouthEastAsia) +1 ]
    end
    if hash % 2 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ]
    end
  end

  if culture == "international" then
    local internationalCityStates = {"Dubai", "Singapore", "Monaco"}
    return internationalCityStates[((hash*69) % #internationalCityStates) +1]
  end
end

function stringToHash(hashString)
    totalValue = 0
    for i = 1, string.len(hashString) do
        local c = hashString:sub(i, i)
        totalValue = totalValue + string.byte(c, 1)
    end

    return totalValue
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
  countryPhoneNr = "+0"
  local country = getCountryByCulture()
  if not county then  countryPhoneNr = ""; return end
  local hash = stringToHash(country)
  countryPhoneNr = countryPhoneNr..(hash % 170).."-"
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

local phoneCache = {}
local function getCacheBy(identifier)
  if phoneCache[identifier] then return phoneCache[identifier] end
end

local function setCacheBy(identifier, value)
  phoneCache[identifier] = value
end


local function getPhoneNr( id)
    if getCacheBy(id) then return getCacheBy(id) end
    local cityPhoneNr = getDetermenisticHash() + math.random(-5,5)
    local phoneNr = countryPhoneNr..cityPhoneNr.."/"..((9999 % id)+ math.abs( id -9999))
    setCacheBy(id, phoneNr)
    return getCacheBy(id) 
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

local function DrawSafeHouseMarker( Loc,  yshift, designator, name)
  local maxstringlength = math.max(math.max(string.len(designator),string.len(name)),iconsizeX)*3 
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
  glRect(-iconsizeX, iconsizeZ, maxstringlength, -iconsizeZ )
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
--\255\145\0\255
local parentColour = {145/255,0/255, 255/255, 255/255}
local function DrawRevealedMarkerParent(id, Loc,  yshift, designator, name, isCivilian)
  local maxstringlength = math.max(math.max(string.len(designator),string.len(name)),iconsizeX)*3
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
  glRect(-iconsizeX, iconsizeZ, maxstringlength + 10, -iconsizeZ)
  glColor(parentColour)
  glRect(-iconsizeX, iconsizeZ, maxstringlength + 10, 0)
  glColor(baseBlack)
  gl.BeginText ( ) 
  glColor(baseBlack)
  gl.Text ("\255\0\0\0 ◈ "..string.upper(designator), -iconsizeX+2, iconsizeZ*0.9, textSize*3.75 , "lt" ) 
  glColor(parentColour)
  if isCivilian == true then
    gl.Text ("\255\145\0\255 ◤⚛⚖"..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" ) 
  else
    gl.Text ("\255\145\0\255 ◤♚⛁ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" ) 
  end
  gl.EndText()
  glPopMatrix()
end

local function getDetermenisticChessSymbol(hash)

    return symbol
end

local childcolour =  {1.0,72/255,0, 1.0}
local function DrawRevealedMarkerChild(id, Loc,  yshift, designator, name)
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
  glRect(-iconsizeX, iconsizeZ, maxstringlength + 10, -iconsizeZ)
  glColor(childcolour)
  glRect(-iconsizeX, iconsizeZ, maxstringlength + 10, 0)
  glColor(baseBlack)
  gl.BeginText ( ) 
  glColor(baseBlack)
  gl.Text ("\255\0\0\0 ♦ "..string.upper(designator), -iconsizeX+2, iconsizeZ*0.9, textSize*3.75 , "lt" ) 
  glColor(childcolour)
  local chessSymbol = getDetermenisticChessSymbol(id)

  local rand = (id % 6) + 1 
  if rand == 1 then
    gl.Text ("\255\255\72\0 ◤♙⚔ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" )
  elseif rand == 2 then 
    gl.Text ("\255\255\72\0 ◤♘⚔ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" )
  elseif rand == 3 then
    gl.Text ("\255\255\72\0 ◤♖⚔ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" )
  elseif rand == 4 then
    gl.Text ("\255\255\72\0 ◤♗⚔ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" )  
  elseif rand == 5 then
    gl.Text ("\255\255\72\0 ◤♞⚔ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" )  
  elseif rand == 6 then
    gl.Text ("\255\255\72\0 ◤♟⚔ "..string.upper(name), -iconsizeX+2, -iconsizeZ*0.3, textSize*1.5 , "lt" )
  end
  gl.EndText()
    glPopMatrix()
end

local unitLocations = {}

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
        local runtimeInSeconds = math.ceil((Loc.endFrame -  spGetGameFrame())/30)
        DrawSafeHouseMarker(Loc,  
							maxHeightIcon,
							"SOURCE:"..string.char(65 + (i % 24))..i, 
							"Location: ("..math.floor(Loc.x).."/"..math.floor(Loc.z)..") ETD: Secs "..runtimeInSeconds)

        gl.LineWidth(1.0)
        gl.Color(1, 1, 1, 1)

        local revealedUnits = Loc.revealedUnits
        for id, data in pairs(revealedUnits) do
          if id and not Spring.GetUnitIsDead(id) then          
          local px, py, pz = 0,0,0
          x, y, z = data.pos.x, data.pos.y, data.pos.z

          local radius = GetUnitDefRealRadius(id) or 50
          --Problem with context not recalling variable
          local gx, gy, gz = spGetGroundNormal(x, z)
          local degrot = math.acos(gy) * 180 / math.pi
          local designation =  data.name or "---"
          
            if data.boolIsParent then
              glColor(dayTimeDependentColorSet[2])
              gl.LineWidth(3.0)
              gl.LineWidth(1.0)
              gl.Color(1, 1, 1, 1)
              DrawRevealedMarkerParent(
                      id,
                      {x=x,y=y,z=z}, 
  										maxHeightIcon, 
  										"ROOT: "..id, 
  										"TYPE:"..designation.." ☎:"..getPhoneNr( id))
             
            else
              glColor(dayTimeDependentColorSet[2])
              gl.LineWidth(3.0)
              gl.LineWidth(1.0)
              gl.Color(1, 1, 1, 1)
              DrawRevealedMarkerChild(
                    id,
                    {x=x,y=y,z=z},
  									maxHeightIcon,
  									"TARGET: "..id,
  									"TYPE:"..designation.." ☎:"..getPhoneNr( id))
            end
               
          --drawStripe from Location to Unit
          newPolygon(Loc.x, Loc.y, Loc.z)
          --ux,uy,uz = spGetUnitBasePosition(id)
          addLineSegment(x,y,z)
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

