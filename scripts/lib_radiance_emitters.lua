-- Visibility helpers for ordinary model pieces which should contribute to the
-- radiance cascade without being drawn by the hologram shader.
function SetRadiancePiece(pieceID, visible, mode, preset)
    if not pieceID then return end
    if GG and GG.SetObjectiveRadiancePieceVisible then
        GG.SetObjectiveRadiancePieceVisible(unitID, pieceID, visible, mode, preset)
    end
end

function ShowRadiancePiece(pieceID, mode, preset)
    if not pieceID then return end
    Show(pieceID)
    SetRadiancePiece(pieceID, true, mode, preset)
end

function HideRadiancePiece(pieceID)
    if not pieceID then return end
    Hide(pieceID)
    if GG and GG.SetObjectiveRadiancePieceVisible then
        GG.SetObjectiveRadiancePieceVisible(unitID, pieceID, false)
    end
end

function ShowRadiancePieces(pieces, mode, preset)
    if not pieces then return end
    for _, pieceID in pairs(pieces) do ShowRadiancePiece(pieceID, mode, preset) end
end

-- Only selected, actually shown street furniture participates. Children inherit
-- their parent placeable's size test; a small lamp on a large kiosk still counts.
function SetRadiancePlaceables(pieces, visible)
    local names = Spring.GetUnitPieceList(unitID)
    local map = Spring.GetUnitPieceMap(unitID)
    for _, pieceID in pairs(pieces or {}) do
        local parentName = (names[pieceID] or ''):match('^(Placeable%d+)')
        local parent = parentName and map[parentName]
        if parent then
            SetRadiancePiece(pieceID, visible, 'material', 'placeable:'..parent)
        end
    end
end

function HideRadiancePieces(pieces)
    if not pieces then return end
    for _, pieceID in pairs(pieces) do HideRadiancePiece(pieceID) end
end
