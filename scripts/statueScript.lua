include "lib_UnitScript.lua"


function script.Create()
    hideAll(unitID)

    hash = getDeterministicUnitHash(unitID)
    defID = Spring.GetUnitDefID(unitID)
    if not GG.StatueSelectorTable then GG.StatueSelectorTable = {} end
    if not GG.StatueSelectorTable[defID] then 
        local allPieces = Spring.GetUnitPieceList(unitID)      
        for k,v in pairs(allPieces) do
            allPieces[k]= 0
        end
        GG.StatueSelectorTable[defID] = allPieces
    end

    key, value= getNthDictElement(GG.StatueSelectorTable[defID], hash % count(GG.StatueSelectorTable[defID]) +1)
    Show(key)
    GG.StatueSelectorTable[defID][key] = GG.StatueSelectorTable[defID][key] +1

    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
end


function script.Killed(recentDamage, _)
    return 1
end
