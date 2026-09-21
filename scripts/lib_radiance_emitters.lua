-- Visibility helpers for ordinary model pieces which should contribute to the
-- radiance cascade without being drawn by the hologram shader.
function ShowRadiancePiece(pieceID)
    if not pieceID then return end
    Show(pieceID)
    if GG and GG.SetObjectiveRadiancePieceVisible then
        GG.SetObjectiveRadiancePieceVisible(unitID, pieceID, true)
    end
end

function HideRadiancePiece(pieceID)
    if not pieceID then return end
    Hide(pieceID)
    if GG and GG.SetObjectiveRadiancePieceVisible then
        GG.SetObjectiveRadiancePieceVisible(unitID, pieceID, false)
    end
end

function ShowRadiancePieces(pieces)
    if not pieces then return end
    for _, pieceID in pairs(pieces) do ShowRadiancePiece(pieceID) end
end

function HideRadiancePieces(pieces)
    if not pieces then return end
    for _, pieceID in pairs(pieces) do HideRadiancePiece(pieceID) end
end
