
function widget:GetInfo()
	return {
		name      = "Capture Invalid build commands",
		desc      = "^title)",
		author    = "Pica",
		version   = "v1.1",
		date      = "Jul 18, 2009",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

---------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------
local fadeRate = 3.0 -- Alpha reduces at fadeRate per second
local conLineAlpha = 0.1 -- Alpha of connecting line when drawing loop

---------------------------------------------------------------------------
-- Globals
---------------------------------------------------------------------------
local dragging = false -- Obvious
local sNodes = {} -- Loop nodes
local fNodes = {} -- Fading nodes
local fAlpha = 0 -- Fade alpha
local sx, sy, sz -- Start pos
local lx, ly, lz -- Last added pos

---------------------------------------------------------------------------
-- Speedups

local spGetMouseState = Spring.GetMouseState
local spGetActiveCommand = Spring.GetActiveCommand
local spGetDefaultCommand = Spring.GetDefaultCommand
local spGetModKeyState = Spring.GetModKeyState
local spGetSpecState = Spring.GetSpectatingState
local spGetMyTeamID = Spring.GetMyTeamID
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetUnitPos = Spring.GetUnitPosition
local spTraceScreenRay = Spring.TraceScreenRay
local spGetSelUnits = Spring.GetSelectedUnits
local spSelUnitArray = Spring.SelectUnitArray

local tremove = table.remove

---------------------------------------------------------------------------
-- Code
---------------------------------------------------------------------------



function widget:MouseRelease(mx, my, mButton)
	
	-- Add final node (If different)
	local _, pos = spTraceScreenRay(mx, my, true)

end

---------------------------------------------------------------------------
