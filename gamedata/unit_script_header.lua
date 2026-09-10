-- Author: Tobi Vollebregt

-- This is prepended before each actual unitscript, so certain functions and
-- variables can be localized, without copy pasting this into every file.

-- Do not overuse this:
-- there is a limit of 200 locals and 60 upvalues per Lua function!

local unitID = unitID
local unitDefID = unitDefID
local unitDef = UnitDefs[unitDefID]
local teamID = Spring.GetUnitTeam(unitID)

local UnitScript = Spring.UnitScript

local EmitSfx = UnitScript.EmitSfx
local Explode = UnitScript.Explode
local GetUnitValue = UnitScript.GetUnitValue
local SetUnitValue = UnitScript.SetUnitValue
local Hide = UnitScript.Hide
local Show = UnitScript.Show

-- Keep these helpers local to each compiled unit-script chunk.  The old
-- lib_UnitScript versions stored pieceMap globally and could overwrite the
-- script environment while another thread was using it.
local function hideAll(id)
    local targetID = id or unitID
    local pieceMap = Spring.GetUnitPieceMap(targetID)
    if not pieceMap then return end

    for _, pieceID in pairs(pieceMap) do
        Hide(pieceID)
    end
end

local function showAll(id)
    local targetID = id or unitID
    local pieceMap = Spring.GetUnitPieceMap(targetID)
    if not pieceMap then return end

    for _, pieceID in pairs(pieceMap) do
        Show(pieceID)
    end
end

local Move = UnitScript.Move
local Turn = UnitScript.Turn
local Spin = UnitScript.Spin
local StopSpin = UnitScript.StopSpin

local StartThread = UnitScript.StartThread
local Signal = UnitScript.Signal
local SetSignalMask = UnitScript.SetSignalMask
local Sleep = UnitScript.Sleep
local WaitForMove = UnitScript.WaitForMove
local WaitForTurn = UnitScript.WaitForTurn

local x_axis = 1
local y_axis = 3
local z_axis = 2


local EMPTY = {}
