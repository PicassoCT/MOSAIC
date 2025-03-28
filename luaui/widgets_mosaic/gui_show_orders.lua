
function widget:GetInfo()
	return {
		name      = "Show Orders",
		desc      = "Hold shift+meta to show allied units orders",
		author    = "Niobium",
		date      = "date",
		version   = 1.0,
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local fontfile = LUAUI_DIRNAME .. "fonts/" .. Spring.GetConfigString("bar_font", "Poppins-Regular.otf")
local vsx,vsy = Spring.GetViewGeometry()
local fontfileScale = (0.5 + (vsx*vsy / 5700000))
local fontfileSize = 25
local fontfileOutlineSize = 6
local fontfileOutlineStrength = 1.4
local font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)

-----------------------------------------------------
-- Config
-----------------------------------------------------
local borderWidth = 2
local iconSize = 40
local maxColumns = 4
local maxRows = 2
local fontSize = 16

-----------------------------------------------------
-- Globals
-----------------------------------------------------
local isFactory = {}
local GaiaTeamID  = Spring.GetGaiaTeamID() 		-- set to -1 to include Gaia units

-----------------------------------------------------
-- Speedup
-----------------------------------------------------
local floor = math.floor

local spGetModKeyState = Spring.GetModKeyState
local spDrawUnitCommands = Spring.DrawUnitCommands
local spGetFactoryCommands = Spring.GetFactoryCommands
local spGetSpecState = Spring.GetSpectatingState
local spGetAllUnits = Spring.GetAllUnits
local spGetTeamList = Spring.GetTeamList
local spGetTeamUnits = Spring.GetTeamUnits
local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spWorldToScreenCoords	= Spring.WorldToScreenCoords
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitStates = Spring.GetUnitStates

local glColor			= gl.Color
local glTexture			= gl.Texture
local glTexRect			= gl.TexRect
local glText			= gl.Text
local glRect			= gl.Rect

-----------------------------------------------------
-- Code
-----------------------------------------------------

function widget:ViewResize(n_vsx,n_vsy)
	vsx,vsy = Spring.GetViewGeometry()
	widgetScale = (0.5 + (vsx*vsy / 5700000))
  local newFontfileScale = (0.5 + (vsx*vsy / 5700000))
  if (fontfileScale ~= newFontfileScale) then
    fontfileScale = newFontfileScale
    gl.DeleteFont(font)
    font = gl.LoadFont(fontfile, fontfileSize*fontfileScale, fontfileOutlineSize*fontfileScale, fontfileOutlineStrength)
  end
end

local function GetAlliedTeams()
	
	local _, fullView, _ = spGetSpecState()
	if fullView then
		return spGetTeamList()
	else
		return spGetTeamList(spGetMyAllyTeamID())
	end
end

function widget:Initialize()
	
	for uDefID, uDef in pairs(UnitDefs) do
		if uDef.isFactory then
			isFactory[uDefID] = true
		end
	end
end

function widget:DrawWorld()
	if chobbyInterface then return end
	
	local alt, control, meta, shift = spGetModKeyState()
	if not (shift and meta) then return end
	
	local alliedTeams = GetAlliedTeams()
	for t = 1, #alliedTeams do
		if alliedTeams[t] ~= GaiaTeamID then
			spDrawUnitCommands(spGetTeamUnits(alliedTeams[t]))
		end
	end
end

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1,18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1,19) == 'LobbyOverlayActive1')
	end
end

function widget:DrawScreen()
	if chobbyInterface then return end
	
	local alt, control, meta, shift = spGetModKeyState()
	if not (shift and meta) then return end
	
	local alliedTeams = GetAlliedTeams()
	for t = 1, #alliedTeams do
		
		if alliedTeams[t] ~= GaiaTeamID then
			local teamUnits = spGetTeamUnits(alliedTeams[t])
			for u = 1, #teamUnits do
				
				local uID = teamUnits[u]
				local uDefID = spGetUnitDefID(uID)
				
				if uDefID and isFactory[uDefID] then
					
					local ux, uy, uz = spGetUnitPosition(uID)
					local sx, sy = spWorldToScreenCoords(ux, uy, uz)
					local _, _, _, _, buildProg = spGetUnitHealth(uID)
					local uCmds = spGetFactoryCommands(uID,-1)
					
					local cells = {}
					
					if (buildProg < 1.0) then
						cells[1] = { texture = "#" .. uDefID, text = floor(buildProg * 100) .. "%" }
					else
						if (#uCmds == 0) then
							cells[1] = { texture = "#" .. uDefID, text = "IDLE" }
						end
					end
					
					if (#uCmds > 0) then
						
						local uCount = 0
						local prevID = -1000
						
						for c = 1, #uCmds do
							
							local cDefID = -uCmds[c].id
							
							if (cDefID == prevID) then
								uCount = uCount + 1
							else
								if (prevID > 0) then
									cells[#cells + 1] = { texture = "#" .. prevID, text = (uCount ~= 0) and uCount + 1 }
								end
								uCount = 0
							end
							
							prevID = cDefID
						end
						
						if (prevID > 0) then
							cells[#cells + 1] = { texture = "#" .. prevID, text = (uCount ~= 0) and uCount + 1 }
						end
					end
					
					for r = 0, maxRows - 1 do
						for c = 1, maxColumns do
							
							local cell = cells[maxColumns * r + c]
							if not cell then break end
							
							local cx = sx + (c - 1) * (iconSize + borderWidth)
							local cy = sy - r * (iconSize + borderWidth)
							
							if select(4,spGetUnitStates(uID,false,true)) then	-- 4=repeat
								glColor(0.0, 0.0, 0.5, 1.0)
							else
								glColor(0.0, 0.0, 0.0, 1.0)
							end
							glRect(cx, cy, cx + iconSize + 2 * borderWidth, cy - iconSize - 2 * borderWidth)
							
							glColor(1.0, 1.0, 1.0, 1.0)
							glTexture(cell.texture)
							glTexRect(cx + borderWidth, cy - iconSize - borderWidth, cx + iconSize + borderWidth, cy - borderWidth)
							glTexture(false)
							
							if (cell.text) then

								font:Begin()
								font:Print(cell.text, cx + borderWidth + 2, cy - iconSize, fontSize, 'ob')
								font:End()
							end
						end -- columns
					end -- rows
				end -- isFactory
			end -- teamUnits
		end
	end -- alliedTeams
end -- DrawScreen

function widget:Shutdown()
	gl.DeleteFont(font)
end