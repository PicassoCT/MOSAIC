include "lib_UnitScript.lua"

local TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage)
end
Frame = piece("Frame")
function script.Create()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitNoSelect(unitID, true)
    Spring.SetUnitBlocking(unitID, false)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    Show(Frame)

    StartThread(flickerAnimation)
end

snippetStarts= {
[1] = { endsat= 70,  jumpsto = {35, 400}},
[70] = { endsat= 140,  jumpsto = {105, 125, 1}},
[140] = { endsat= 175,  jumpsto = {140, 155, 70}},
[175] = { endsat= 175 + 35,  jumpsto = {175, 140}},
[210] = { endsat= 210 + 35,  jumpsto = {210, 175}},
[245] = { endsat= 245 + 35,  jumpsto = {245, 210, 175}},
[280] = { endsat= 280 + 35,  jumpsto = {245, 210, 175}},
[315] = { endsat= 315 + 35,  jumpsto = {245, 280, 315}},
[350] = { endsat= 350 + 35,  jumpsto = {245, 280, 315, 1}},
[385] = { endsat= 385 + 5,  jumpsto = {385, 1}},
[390] = { endsat= 390 + 5,  jumpsto = {390, 1}},
[395] = { endsat= 395 + 5,  jumpsto = {395, 1}},
[400] = { endsat= 400 + 5,  jumpsto = {400, 1}},
[405] = { endsat= 405 + 409,  jumpsto = {405, 1}},
}

endIndex= 1
jumpsto = {1}
function flickerAnimation()
    index = 1
    lastPiece = TablesOfPiecesGroups["Flicker"][index]
    currentPiece = TablesOfPiecesGroups["Flicker"][index]
    Show(currentPiece)
    Sleep(125)
    while true do
        currentPiece = TablesOfPiecesGroups["Flicker"][index]
        Hide(currentPiece)
        index = loopsReptitionsJumps(index)
        currentPiece = TablesOfPiecesGroups["Flicker"][index]
        Show(currentPiece)
        varSpeed= math.random(40, 160)
        Sleep(varSpeed)
    end
end

function loopsReptitionsJumps(index)
    newIndex = (index % #TablesOfPiecesGroups["Flicker"]) +1
    if index == endIndex then
        if maRa() then
           if maRa() then Sleep(3000) end
           newIndex = getSafeRandom(jumpsto, jumpsto[1])
           if snippetStarts[newIndex] then 
                jumpsto = snippetStarts[newIndex].jumpsto
                endIndex = snippetStarts[newIndex].endsat
                return newIndex
           end          
        end
    end

    if snippetStarts[newIndex] then 
        jumpsto = snippetStarts[newIndex].jumpsto
        endIndex = snippetStarts[newIndex].endsat
    end
    return newIndex
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() 
end

function script.StopMoving()
end

function script.Activate()
 return 1 
end

function script.Deactivate() 
 return 0 
end

