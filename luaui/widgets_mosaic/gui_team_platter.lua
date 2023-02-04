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
    name      = "TeamPlatter",
    desc      = "Shows a team color platter above all visible units",
    author    = "trepan cuddled by picasso",
    date      = "Apr 16, 2007",
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

local GetGaiaTeamID = Spring.GetGaiaTeamID () --+++
function widget:PlayerChanged() --+++
	GetGaiaTeamID = Spring.GetGaiaTeamID () --+++
end --+++

local function SetupCommandColors(state)
  local alpha = state and 1 or 0
  local f = io.open('cmdcolors.tmp', 'w+')
  if (f) then
    f:write('unitBox  0 1 0 ' .. alpha)
    f:close()
    spSendCommands({'cmdcolors cmdcolors.tmp'})
  end
  os.remove('cmdcolors.tmp')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local teamColors = {}

local trackSlope = true

local circleLines  = 0
local circlePolys  = 0
local circleDivs   = 32
local circleOffset = 0

local startTimer = spGetTimer()
local ignoredUnitDefs = {
[UnitDefNames["tree_arab0"].id]= true,
[UnitDefNames["tree_arab1"].id]= true,
[UnitDefNames["marketstand_arab"].id]= true,
[UnitDefNames["truckpayloadrefugee"].id]= true,
[UnitDefNames["truckpayload"].id]= true,
[UnitDefNames["doubleagent"].id]= true,
[UnitDefNames["interrogationicon"].id]= true,
[UnitDefNames["stealvehicleicon"].id]= true,
[UnitDefNames["raidicon"].id]= true,
[UnitDefNames["snipeicon"].id]= true,
[UnitDefNames["objectiveicon"].id]= true,
[UnitDefNames["bribeicon"].id]= true,
[UnitDefNames["socialengineeringicon"].id]= true,
[UnitDefNames["blackouticon"].id]= true,
[UnitDefNames["ecmicon"].id]= true,
[UnitDefNames["recruitcivilian"].id]= true,
[UnitDefNames["cybercrimeicon"].id]= true,
[UnitDefNames["innercitydeco_inter1"].id]= true,
[UnitDefNames["innercitydeco_inter2"].id]= true,
[UnitDefNames["innercitydeco_inter3"].id]= true,
[UnitDefNames["innercitydeco_inter4"].id]= true,
[UnitDefNames["innercitydeco_arab"].id]= true,
[UnitDefNames["innercitydeco_asian"].id]= true,
[UnitDefNames["innercitydeco_western"].id]= true,
[UnitDefNames["vehiclecorpse"].id]= true,
[UnitDefNames["tankcorpse"].id]= true,
[UnitDefNames["greenhouse"].id]= true,
[UnitDefNames["satelliteshrapnell"].id]= true,
[UnitDefNames["civilianloot"].id]= true,
[UnitDefNames["gcscrapheap"].id]= true,
[UnitDefNames["destroyedobjectiveicon"].id]= true,
[UnitDefNames["house_arab0"].id]= true,
[UnitDefNames["air_parachut"].id]= true,
[UnitDefNames["house_western0"].id]= true,
[UnitDefNames["closecombatarena"].id]= true,
[UnitDefNames["raidiconbaseplate"].id]= true,
[UnitDefNames["teargascloud"].id]= true,
[UnitDefNames["trashbin"].id]= true,
[UnitDefNames["civilian_orgy_pair"].id]= true,
[UnitDefNames["house_western_hologram_casino"].id]= true,
[UnitDefNames["house_western_hologram_brothel"].id]= true,
[UnitDefNames["house_western_hologram_buisness"].id]= true,
[UnitDefNames["advertising_blimp_hologram"].id]= true,
[UnitDefNames["house_vtol"].id]= true,
[UnitDefNames["house_spinner"].id]= true,
}

if UnitDefNames["caesareagle"] then ignoredUnitDefs[UnitDefNames["caesareagle"].id]= true end
if UnitDefNames["decobuilding"] then ignoredUnitDefs[UnitDefNames["decobuilding"].id]= true end
if UnitDefNames["decoboat"] then ignoredUnitDefs[UnitDefNames["decoboat"].id]= true end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  circleLines = glCreateList(function()
    glBeginEnd(GL_LINE_LOOP, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        glVertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
  end)

  circlePolys = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
      local radstep = (2.0 * math.pi) / circleDivs
      for i = 1, circleDivs do
        local a = (i * radstep)
        glVertex(math.sin(a), circleOffset, math.cos(a))
      end
    end)
  end)

  SetupCommandColors(false)
end


function widget:Shutdown()
  glDeleteList(circleLines)
  glDeleteList(circlePolys)

  SetupCommandColors(true)
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

--Table: UnitSelectedBy : [unitID] -> playerID
if not WG.UnitSelectedBy then WG.UnitSelectedBy={} end

function GetUnitLastSelectedBy(unitID, selectedUnits)
	for k,_unitID in ipairs(selectedUnits) do
		if _unitID== unitID then
			playerID=Spring.GetMyPlayerID()
			WG.UnitSelectedBy[unitID]=playerID
		return playerID
		end
	end
	
return WG.UnitSelectedBy[unitID] or nil 
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

local unitLastCommandGivenByPlayer={}
--Table contains shifted TeamColors 
-- -> [teamid][playerid] 	= color
-- -> [teamid][playername] 	= color
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
		name=	Spring.GetPlayerInfo(player)
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
		
		rhash	=	randSign()*accColOffset[1]%hashUpper
		ghash	=	randSign()*accColOffset[2]%hashUpper
		bhash	=	randSign()*accColOffset[3]%hashUpper
		
		local colors=teamColors[teamID]

    if not colors[1].r then 
      colors[1] = {r=255,g = 255, b=255}
    end

    if not colors[2].r then 
      colors[2] = colors[1]
    end

		colors[1].r	=	clamp(colors[1].r+rhash,1,255)
		colors[1].g	=	clamp(colors[1].g+ghash,1,255)
		colors[1].b	= 	clamp(colors[1].b+bhash,1,255)
		colors[2].r	=	clamp(colors[2].r+rhash,1,255)
		colors[2].g	=	clamp(colors[2].g+ghash,1,255)
		colors[2].b=	clamp(colors[2].b+bhash,1,255)
		teamColorPlayers[teamID][player]=colors
		teamColorPlayers[teamID][name]=colors
	end

end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--UnitID -> defID, canFly
local unitCache={}
local colorCache={}
local gaiaTeamID=Spring.GetGaiaTeamID()

function widget:DrawWorldPreUnit()
  glLineWidth(3.0)

  glDepthTest(true)
  
  glPolygonOffset(-50, -2)

	local selectedUnits=spGetSelectedUnits()

  for _,unitID in ipairs(spGetAllUnits()) do
    if (spIsUnitVisible(unitID)) then
      local teamID = spGetUnitTeam(unitID)
      if (teamID ) then	
		
        local udid = 0
		if unitCache[unitID] then
			udid=	unitCache[unitID].defID
		else
			udid=	spGetUnitDefID(unitID)
				if not unitCache[unitID] then 
					unitCache[unitID]={} 
				end
			unitCache[unitID].defID=udid
		end

    if not ignoredUnitDefs[udid] then
	
        local radius = GetUnitDefRealRadius(udid)
        if (radius) then
          local colorSet  = colorCache[teamID]
			if not colorSet then 
				colorSet= GetTeamColorSet(teamID)
				colorCache[teamID]=colorSet
			end
		 
		--if there doesent exist yet a shifted teamcolourtable - compute it
			if not teamColorPlayers[teamID] then
				computeTeamColorOffsetByPlayer(teamID,25)
			end
			
		local	playerID= GetUnitLastSelectedBy(teamID,selectedUnits)
			
			if  playerID and teamColorPlayers[teamID][playerID] then
				colorSet=teamColorPlayers[teamID][playerID] 
			end
			
          if (trackSlope and (not UnitDefs[udid].canFly)) then
            local x, y, z = spGetUnitBasePosition(unitID)
            local gx, gy, gz = spGetGroundNormal(x, z)
            local degrot = math.acos(gy) * 180 / math.pi
            glColor(colorSet[1])
            glDrawListAtUnit(unitID, circlePolys, false,
                             radius, 1.0, radius,
                             degrot, gz, 0, -gx)
            glColor(colorSet[2])
            glDrawListAtUnit(unitID, circleLines, false,
                             radius, 1.0, radius,
                             degrot, gz, 0, -gx)
          else
            glColor(colorSet[1])
            glDrawListAtUnit(unitID, circlePolys, false,
                             radius, 1.0, radius)
            glColor(colorSet[2])
            glDrawListAtUnit(unitID, circleLines, false,
                             radius, 1.0, radius)
          end
        end
      end
      end
    end
  end

  glPolygonOffset(false)

  --
  -- Mark selected units 
  --

  glDepthTest(false)

  local alpha = 0.3
  glColor(1, 1, 1, alpha)

  for _,unitID in ipairs(selectedUnits) do
   local udid = 0
			if unitCache[unitID]then
				udid = 	unitCache[unitID].defID
			else
				udid = Spring.GetUnitDefID(unitID)
			end
			if not udid then break end
			
    local radius = GetUnitDefRealRadius(udid)
    if (radius) then
      if (trackSlope and (not UnitDefs[udid].canFly)) then
        local x, y, z = spGetUnitBasePosition(unitID)
		assert(x,z, UnitDefs[udid].name.." has no valid base position")
        local gx, gy, gz = spGetGroundNormal(x, z)
        local degrot = math.acos(gy) * 180 / math.pi
        glDrawListAtUnit(unitID, circlePolys, false,
                         radius, 1.0, radius,
                          degrot, gz, 0, -gx)
      else
        glDrawListAtUnit(unitID, circlePolys, false,
                         radius, 1.0, radius)
      end
    end
  end

  glLineWidth(1.0)
end
              

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
