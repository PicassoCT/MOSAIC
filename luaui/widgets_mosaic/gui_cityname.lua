local versionNumber = "0.6"
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
    name      = "Display Cityname",
    desc      = "Displays the cityname at startup ",
    author    = "picasso",
    date      = "Apr 16, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local startFrame = Spring.GetGameFrame()
local endFrame = startFrame + (20*30)
local displayStaticFrame = endFrame
local displayStaticFrameIntervallLength = endFrame
local vsx,vsy = Spring.GetViewGeometry()
local anchorx, anchory
local glColor           = gl.Color
local glText            = gl.Text
local fontSize          = 32
local scale            = 1

local function setAnchorsRelative(nvx, nvy)
  anchorx, anchory = nvx*0.9,nvy*0.15 
end

function widget:Initialize()
   startFrame = Spring.GetGameFrame()
   endFrame = startFrame + (10*30)
   displayStaticFrameIntervallLength = math.ceil(0.5*(endFrame - startFrame))
   displayStaticFrame = startFrame+ displayStaticFrameIntervallLength
   vsx,vsy = Spring.GetViewGeometry()
   setAnchorsRelative(vsx,vsy)
end

function widget:Shutdown()
end

local function getRollingString(original, nrOfLetters, frames)
  local lengthOfString = string.len(original)
  if nrOfLetters > lengthOfString then return original end

  local concat = ""

    concat = string.sub(original, math.max(1,lengthOfString-nrOfLetters),nrOfLetters)..concat


  if math.ceil(frames/15)% 2 == 0 then
    return "█"..concat
  else
    return " |"..concat
  end
end

function widget:ViewResize(n_vsx,n_vsy)
  scale = vsx*vsz/ (n_vsx*n_vsy) 
  vsx,vsz = n_vsx,n_vsy
  setAnchorsRelative(vsx,vsy)
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

local function getHashDate(startYear)
    local hash = getDetermenisticHash()
    local year = startYear + (hash % 25)
    local month = hash % 12
    local day = hash % 31
    return day.."/"..month.."/"..year
  end

local function getDayTimeString()
    local DAYLENGTH = 28800
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = (math.floor((Frame / DAYLENGTH) * 24))..""
     if string.len(hours) == 1 then hours= " "..hours end

    local minutes = (math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60))..""
    if string.len(minutes) == 1 then minutes= " "..minutes end
     
    local seconds = (math.ceil((24 * 60 * 60)*percent) % 60)..""
    if string.len(seconds) == 1 then seconds= " "..seconds end

    return ""..hours.." : "..minutes.." : "..seconds.. " / ".. getHashDate(2025)
end

local function getProvinceNamBy(culture, hash)
local provinces ={
    ["arabic"] = {



    }
}

local function getProvinceNamBy(culture, hash)
local provinces ={
    ["arabic"] = {


      
    }
}

  return provinces[culture][math.random(1, #provinces[culture])]
end


function widget:DrawScreenEffects(vsx, vsy)
  local currentFrame = Spring.GetGameFrame()
    if currentFrame >= startFrame and currentFrame < endFrame then 
      local longestString = 15 
      local timestepFramesPerString = displayStaticFrameIntervallLength/longestString
      local timeStep = (currentFrame - startFrame)/timestepFramesPerString

        local timeStamp = getRollingString(getDayTimeString(), timeStep, currentFrame)
        local citypart = getRollingString("citypart", timeStep, currentFrame)
        local cityname = getRollingString("Cityname", timeStep, currentFrame)
        local province = getRollingString("Province", timeStep, currentFrame)
        local country = getRollingString("Country", timeStep, currentFrame)
      

        local textCol = {0, 200/255, 255/255, 0.5}
        local screenX, screenY = anchorx, anchory
        local lineOffset = 50*scale
        local lineIndex = 0
        local FontSize = fontSize *scale

        gl.Color(textCol[1],textCol[2],textCol[3],textCol[4])

        glText(country, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1      

        glText(province, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1         

        glText(cityname, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1      
  

        glText(citypart, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1      

        glText(timeStamp, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        gl.Color(1,1,1,1)


    end
end

