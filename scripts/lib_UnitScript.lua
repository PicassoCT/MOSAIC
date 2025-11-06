VFS.Include("scripts/lib_type.lua", nil, VFS.RAW_FIRST)

--[[
Section: Team Information Getters/Setters 
Section: Unit Information Getters/Setters 
Section: Initializing Functions
Section: Landscape/Pathing Getter/Setters
Section: Syntax additions and Tableoperations
Section: Geometry/Math functions
Section: Code Generation 
Section: String Operations
Section: Debug Tools 
Section: Random 
Section: Physics 
Section: Sound
Section: Ressources
Section: Unit Commands
Section: Sfx Operations
]]
--[[
This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.


]]

-------------- DEBUG HEADER
-- Central Debug Header Controlled in UnitScript
-------------- DEBUG HEADER
lib_boolDebug = false --
if GG then GG.BoolDebug = lib_boolDebug end
-- ======================================================================================
-- Section: Team Information Getters/Setters 
-- ======================================================================================
-- > get all EnemyTeams of a teamID 
function getAllEnemyTeams(teamID, boolIncludeGaia)
    gaiaTeamID = Spring.GetGaiaTeamID()

    return foreach(Spring.GetTeamList(), function(tid)
        if Spring.AreTeamsAllied(tid, teamID) == false and boolIncludeGaia ==
            true or boolIncludeGaia == false and tid ~= gaiaTeamID then
            return tid
        end
    end) or {}
end




function hasFunding(teamID, amount, types)
    if types == "m" then types = "metal"end
    if types == "e" then types = "energy"end
    currentLevel, storage =  Spring.GetTeamResources (teamID, types )
    return currentLevel >= amount
end


-- > get all AITeams
function getAITeams()
    teamList = Spring.GetTeamList()
    AiTeams = {}
    for i=1, #teamList do
        teamID = teamList[i]
        _, leader, isDead, isAiTeam, side, allyTeam,  incomeMultiplier, customTeamKeys = Spring.GetTeamInfo(teamID)
        if isAiTeam then
            AiTeams[#AiTeams+1] = teamID
        end

    end

    return AiTeams or {}
end

function getRandomPlayerName()
    T = Spring.GetPlayerList()
    local numberOfPlayers = #T
    result = {}

    for i = 1, numberOfPlayers do
        local name, bActive, spectator, _, _, _, _, _, _ =
            Spring.GetPlayerInfo(T[i])
        if string.len(name) > 1 and bActive == true then
            result[name] = name
        end
    end

    return randDict(result)
end

-- > get all Player Units in a Range around a unit
function isPlayerUnitNearby(unitID, range)
    gaiaTeamID = Spring.GetGaiaTeamID()
    T = getAllNearUnit(unitID, range)
    if T then
        T = foreach(T, function(id)
            if Spring.GetUnitTeam(id) ~= gaiaTeamID then return id end
        end)

        if #T > 0 then return true, T end
    end

    return false
end

function getAllOfTypeNearUnit(unitID, typeTable, range)
    return foreach(getAllNearUnit(unitID, range),
                    function (id)
                        if typeTable[Spring.GetUnitDefID(id)] then
                            return id
                        end
                    end)
end

-- > Grabs every Unit in a circle, filters out the unitid or teamid if given
function getAllInCircle(x, z, Range, unitID, teamid)
    if not x or not z then return {} end
    if not Range then assert(Range) end

    T = {}
    if teamid then
        T = Spring.GetUnitsInCylinder(x, z, Range, teamid)
    else
        T = Spring.GetUnitsInCylinder(x, z, Range)
    end

    if unitID and T and #T > 1 and type(unitID) == 'number' then
        for num, id in pairs(T) do
            if id == unitID then table.remove(T, num) end
        end
    end
    return T
end

-- > Grabs every Unit in a circle, filters out the unitid or teamid if given
function getFeaturesInCircleAroundUnit(id, Range)
    x,y,z = Spring.GetUnitPosition(id)
    if not Range then assert(Range) end
    T = Spring.GetFeaturesInCylinder (  x,  z, Range) 
    return T
end

-- > Grabs every Unit in a circle, filters out the unitid or teamid if given
function getAllInSphere(x, y, z, Range, unitID, teamid)
    if not x or not z then return {} end
    if not Range then assert(Range) end

    T = {}
    if teamid then
        T = Spring.GetUnitsInSphere(x, y, z, Range, teamid)
    else
        T = Spring.GetUnitsInSphere(x, y, z, Range)
    end

    if unitID and T and #T > 1 and type(unitID) == 'number' then
        for num, id in pairs(T) do
            if id == unitID then table.remove(T, num) end
        end
    end
    return T
end

function isUnitEnemy(teamID, id)
    eTeam = Spring.GetUnitTeam(id)
    if eTeam then
        if eTeam ~= Spring.GetGaiaTeamID() and eTeam ~= teamID then
            return true
        else
            return false
        end
    end

end

-- > Removes Units of a Team from a table
function removeUnitsOfTeam(TableOfUnits, teamid)
    returnTable = {}
    for i = 1, #TableOfUnits, 1 do
        tid = Spring.GetUnitTeam(TableOfUnits[i])
        if tid ~= teamid then
            returnTable[#returnTable + 1] = TableOfUnits[i]
        end
    end
    return returnTable
end

-- > Gets one Unit of one Type
function getTeamUnitOfType(teamID, typeID)
    allUnitsOfTeam = Spring.GetTeamUnits(eTeam)
    local spGetUnitDefID = Spring.GetUnitDefID
    for i = 1, #allUnitsOfTeam do
        if spGetUnitDefID(allUnitsOfTeam[i]) == typeID then
            return allUnitsOfTeam[i]
        end
    end

end

function getTeamSide(teamid)
    teamID, leader, isDead, isAiTeam, side, allyTeam, customTeamKeys, incomeMultiplier =
        Spring.GetTeamInfo(teamid)
    return side, teamID, leader, isDead, isAiTeam, allyTeam, customTeamKeys,
           incomeMultiplier
end

-- > Grabs every Feature in a circle, filters out the featureID
function getAllFeatureNearUnit(unitID, Range)
    px, py, pz = Spring.GetUnitPosition(unitID)
    return Spring.GetFeaturesInCylinder(px, pz, Range)
end

-- > Grabs every Unit in a circle, filters out the unitid
function getAllNearPiece(unitID, Piece, Range)
    px, py, pz = Spring.GetUnitPiecePosDir(unitID, Piece)
    return getAllInCircle(px, pz, Range, unitID)
end

-- > Grabs every Unit in a circle, filters out the unitid
function getAllNearUnit(unitID, Range, teamid)
    px, py, pz = Spring.GetUnitPosition(unitID)
    return getAllInCircle(px, pz, Range, unitID, teamid)
end

-- > Grabs every Unit in a circle, filters out the unitid
function getAllNearUnitNotInTeam(unitID, Range, teamid)
    px, py, pz = Spring.GetUnitPosition(unitID)
    return foreach (getAllInCircle(px, pz, Range, unitID),
            function(id)
                if Spring.GetUnitTeam(id) ~= teamid then
                    return id
                end
                end
                )
end

-- > Grabs every Unit in a circle, filters out the unitid
function getAllNearUnitSpherical(unitID, Range)
    px, py, pz = Spring.GetUnitPosition(unitID)
    return getAllInSphere(px, py, pz, Range, unitID)
end
-- ======================================================================================
-- Section: Unit Information Getters/Setters 
-- ======================================================================================

-- > Attaches a Unit to a Piece near a Impact side
function AttachUnitToPieceNearImpact(toAttachUnitID, AttackerID, px, py, pz,
                                     range)
    T = getAllInCircle(px, pz, range)
    boolFirstMatch = false
    foreach(T, function(id)
        if Spring.GetUnitLastAttacker(id) == AttackerID then return id end
    end, function(id)
        if boolFirstMatch == true then return end

        lastAttackedPiece = Spring.GetUnitLastAttackedPiece(id)
        if lastAttackedPiece then
            boolFirstMatch = true
            Spring.UnitAttach(id, toAttachUnitID, lastAttackedPiece)
        end
    end)
end

  function isNotNearOcean(x,z, Size)
    min, avg, max = getGroundHeigthGrid(x,z, Size)
    return not(min <= 0)
  end

  function isOnSteepHill(x,z, Size)
    min, avg, max = getGroundHeigthGrid(x,z, Size)
    return not(min <= avg - 10)
  end

function getGroundHeigthGrid(x,z, Size)
  avg = Spring.GetGroundHeight(x, z)
  min = avg
  max = avg

   for i=1, 4 do
     xOff, zOff = getCircleIndex(i)
     xOff, zOff = xOff*Size, zOff*Size
     gh = Spring.GetGroundHeight(x+xOff, z +zOff)

     if gh < min then min = gh end
     if gh > max then max = gh end
     avg= avg + gh

   end

  return  min, avg/5, max 
end

-- > is a Unit Piece above ground
function isPieceAboveGround(unitID, pieceName, offset)
    offset = offset or 0
    x, y, z = Spring.GetUnitPiecePosDir(unitID, pieceName)
    gh = Spring.GetGroundHeight(x, z) + offset
    if gh < y then return true, x, z, y, gh end
    return false, x, z, y, gh
end



-- > Gets the MaxSpeed Of A unit
function getMaxSpeed(unitID, UnitDefs)
    uDefID = Spring.GetUnitDefID(unitID)
    return UnitDefs[uDefID].speed
end

-- > resets the speed of a unit
function reSetSpeed(unitID) setSpeedEnv(unitID, 1.0) end

-- > returns a Units metal and energycosts
function getUnitCost(id)
    defID = Spring.GetUnitDefID(id)

    return UnitDefs[defID].buildCostMetal, UnitDefs[defID].buildCostEnergy
end

-- > Sets the Speed of a Unit
function setSpeedEnv(k, val)
    val = math.max(0.000000001, math.min(val, 1.0))
    env = Spring.UnitScript.GetScriptEnv(k)

    if env then
        udef = Spring.GetUnitDefID(k)
        Spring.UnitScript.CallAsUnit(k, Spring.UnitScript.SetUnitValue,
                                     COB.MAX_SPEED, math.ceil(
                                         UnitDefs[udef].speed * val * 2184.53))
    end
end


-- > Sets the Speed of a Unit
function setSpeedIntern(k, val)
    val = math.max(0.000000001, math.min(val, 1.0))
        udef = Spring.GetUnitDefID(k)
        SetUnitValue(COB.MAX_SPEED, math.ceil( UnitDefs[udef].speed * val * 2184.53))
end

function isUnitFlying(unitID)
    x, y, z = Spring.GetUnitPosition(unitID)
    h = Spring.GetGroundHeight(x, z)
    return y - 15 > h, y, h

end


function setUnitRotationToPoint(id, x,y,z)
    ux,uy,uz=Spring.GetUnitPosition(id)
    ux, uy, uz = ux- x, uy-y, uz-z
    norm = absNormMax(ux,uz)
    radresult = math.atan2(ux/norm, uz/norm) 
    Spring.SetUnitRotation(id, 0, radresult, 0)
end

function setUnitHeadingFromUnit(id, ad)
    hd = Spring.GetUnitHeading(ad)
    Spring.SetUnitHeading(id, hd)
    x, y, z = Spring.GetUnitRotation(ad)
    Spring.SetUnitRotation(id, x, y, z)
end

-- > Sets the Speed of a Unit
function setUnitValueExternal(k, cobArgh, val)
    env = Spring.UnitScript.GetScriptEnv(k)
    if env then
        Spring.UnitScript.CallAsUnit(k, Spring.UnitScript.SetUnitValue,
                                     COB[cobArgh], val)
    end
end


-- > checks wether a piece is below another piece
function recPieceBelow(hierarchy, currentPiece, endPiece, reTable)
    boolBelow = false

    if not hierarchy[currentPiece] then return nil end
    for k, pieceNumber in pairs(hierarchy[currentPiece]) do
        local retTable = reTable

        if pieceNumber == endPiece then
            retTable[#retTable + 1] = endPiece
            return true, retTable
        end

        retTable[#retTable + 1] = pieceNumber
        boolFound, T = recPieceBelow(hierarchy, pieceNumber, endPiece, retTable)
        if boolFound == true then return true, T end
    end
    return false
end

-- >returns a chain of pieces from startPiece to endPiece going over a hierarchy
function getPieceChain(hierarchy, startPiece, endPiece)
    pieceChain = {}
    pieceChain[1] = startPiece
    boolBelow, pieceChain = recPieceBelow(hierarchy, startPiece, endPiece,
                                          pieceChain)
    return pieceChain
end

function randNVec()
    return math.random(-100, 100)/100
end

function getPiecePosDir(unitID, Peace)
    px, py, pz, dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, Peace)
    return {x = px, y = py, z = pz}, {x = dx, y = dy, z = dz}
end

function getParentPieceMap(unitID)
    local pieceMap = Spring.GetUnitPieceMap ( unitID ) 
    parentPieceMap = {}
    for k,v in pairs(pieceMap) do
        info = Spring.GetUnitPieceInfo(unitID, v)
        if type(info.parent) == "number" then
            parentPieceMap[v] =   info.parent
        end
    end
    return parentPieceMap
end


-- > creates a hierarchical table of pieces, descending from root
function getPieceHierarchy(unitID)
    local pieceMap = Spring.GetUnitPieceMap ( unitID ) 
    rootname, children = getRoot(unitID)
    rootNumber = pieceMap[rootname]
    hierarchy = {}
    hierarchy[rootNumber] = {}
    openTable = {}
    for k, pieceName in pairs(children) do
        hierarchy[rootNumber][#hierarchy[rootNumber] + 1] = pieceMap[pieceName]
        table.insert(openTable, pieceMap[pieceName])
    end

    while table.getn(openTable) > 0 do
        for num, pieceNumber in pairs(openTable) do
            tables = Spring.GetUnitPieceInfo(unitID, pieceNumber)
            if not hierarchy[pieceNumber] then
                hierarchy[pieceNumber] = {}
            end
            if tables and tables.children then
                for num, pieceName in pairs(tables.children) do
                    newPieceNumber = pieceMap[pieceName]
                    hierarchy[pieceNumber][#hierarchy[pieceNumber] + 1] =
                        newPieceNumber
                    table.insert(openTable, pieceMap[pieceName])
                end
                table.remove(openTable, num)
            end
        end
    end

    return hierarchy, rootname
end

-- > returns a skelett table via recursion (Expensive)
function recMapDown(unitID, Result, pieceMap, Name)
    if type(Name) == "number" then Name = getUnitPieceName(unitID, Name) end

    if pieceMap[Name] then
        for _, pieceNumber in pairs(pieceMap[Name]) do
            info = Spring.GetUnitPieceInfo(unitID, pieceNumber)
            Result[#Result + 1] = pieceNumber
            if info and pieceMap[info.name] and info.children then
                Result = recMapDown(unitID, Result, pieceMap, info.name)
            end
        end
    end
    return Result
end

-- >Returns all Pieces in a Hierarchy below the named point
function getPiecesBelow(unitID, PieceName)
    pieceMap = getPieceHierarchy(unitID)
    return recMapDown(unitID, {}, pieceMap, PieceName)
end

-- Hashmap of pieces --> with accumulated Weight in every Node
-- > Every Node also holds a bendLimits which defaults to ux=-45 x=45, uy=-180 y=180,uz=-45 z=45
function recursiveAddTable(T, piecename, parent, piecetable)
    if not piecename then return T, 0 end

    C, max = getPieceChildrenTable(piecename, piecetable)

    if not T[parent] then T[parent] = {} end

    if C and #C > 0 then
        for i = 1, #C do
            T, nr = recursiveAddTable(T, C[i], piecename, piecetable)
        end
        bendLimits = computateBendLimits(piecename, parent)
        T[parent].bendLimits = bendLimits
        T[parent].weight = max[1] * max[2] * max[3]
        T[parent].nr = #C
    else

        if not T[parent][piecename] then T[parent][piecename] = {} end
        computateBendLimits(piecename, parent)
        T[parent].bendLimits = bendLimits
        T[parent][piecename].weight = 1
    end
    return T
end
-- >Helperfunction of recursiveAddTable
function getPieceChildrenTable(pieceNum, piecetable)
    if not pieceNum then return end
    T = Spring.GetUnitPieceInfo(unitID, pieceNum)
    children = T.children
    if children then
        for i = 1, #children do children[i] = piecetable[children[i]] end
    end
    return children, T.max
end

-- > returns the root Piece of a units skeletton
function getRoot(unitID)
    pieceMap = Spring.GetUnitPieceMap(unitID)
    for name, number in pairs(pieceMap) do
        infoTable = Spring.GetUnitPieceInfo(unitID, number)
        if (infoTable.parent == "[null]") then
            return name, infoTable.children
        end
    end
end

function getPieceName(unitID, pieceID)
        pieceInfo = Spring.GetUnitPieceInfo(unitID, pieceID)
        return pieceInfo.name
end

function removeFeaturesInCircle(px, pz, radius)
    foreach(Spring.GetFeaturesInCylinder(px,pz, radius),
        function(id)
            Spring.DestroyFeature (id) 
        end
        )
end

function showTSubs(pieceName, TableOfPiecesGroups, selector, countDown)   
   subSpinPieceName = pieceName.."Sub"    
   if TableOfPiecesGroups[subSpinPieceName] then    
    selectorState = nil         
    for i=1, #TableOfPiecesGroups[subSpinPieceName] do
        selectorResult, selectorState = selector(selectorState)
        if selectorResult then
            subPiece = TableOfPiecesGroups[subSpinPieceName][i]
            Show(subPiece)
            if countDown then
                countDown= countDown -1 
                if countDown <= 0 then return end
            end
        end
    end
   end
end

function showTSpins(pieceName, TableOfPiecesGroups, selector, countDown)
   subSpinPieceName = pieceName.."Spin"    
   if TableOfPiecesGroups[subSpinPieceName] then 
    selectorState = nil          
    for i=1, #TableOfPiecesGroups[subSpinPieceName] do  
        selectorResult, selectorState = selector(selectorState)    
        if selectorResult then  
            spinPiece = TableOfPiecesGroups[subSpinPieceName][i]
            Show(spinPiece)
            Spin(spinPiece,y_axis, math.rad(-42 * randSign()),0)
            if countDown then
                countDown= countDown -1 
                if countDown <= 0 then return end
            end

        end
    end
   end
end

function showTSubSpins(pieceID, TableOfPiecesGroups, selectExt, countDown)
    local pieceName = getUnitPieceName(unitID, pieceID)
    local selector = selectExt or maRa
    if pieceName then
        showTSubs(pieceName, TableOfPiecesGroups, selector, countDown)
        showTSpins(pieceName, TableOfPiecesGroups, selector, countDown)
    end
end

function setNoneCollide(unitId)
    oldCol = getCollideData(unitID)
    col = {}
    col.isBlocking = false
    col.isSolidObjectCollidable = false
    col.isProjectileCollidable= false
    col.isRaySegmentCollidable = true
    col.crushable= false
    col.blockEnemyPushing= false
    col.blockHeightChanges  = false
    restoreCollide(unitID, col)
    return oldCol
end

function restoreCollide(unitID, col)
    Spring.SetUnitBlocking(unitID, col.isBlocking, col.isSolidObjectCollidable, col.isProjectileCollidable, col.isRaySegmentCollidable, col.crushable, col.blockEnemyPushing, col.blockHeightChanges)
end

function getCollideData(unitID)
    col = {}
    col.isBlocking, col.isSolidObjectCollidable, col.isProjectileCollidable, col.isRaySegmentCollidable, col.crushable, col.blockEnemyPushing, col.blockHeightChanges = Spring.GetUnitBlocking(unitID)
    return col
end
-- > kill All Units near Pieces Volume
function killAtPiece(unitID, piecename, selfd, reclaimed, sfxfunction)
    px, py, pz = Spring.GetUnitPieceCollisionVolumeData(unitID, piecename)
    tpx, tpy, tpz = Spring.GetUnitPiecePosDir(unitID, piecename)
    if px and tpx then
        size = square(px, py, pz)
        if size then
            T = getAllInCircle(tpx, tpz, size / 2, unitID)

            if T and #T > 0 then

                if sfxfunction then
                    for i = 1, #T do
                        ux, uy, uz = Spring.GetUnitPosition(T[i])
                        sfxfunction(ux, uz, uz)
                        Spring.DestroyUnit(T[i], selfd, reclaimed)
                    end

                else
                    for i = 1, #T do
                        Spring.DestroyUnit(T[i], selfd, reclaimed)
                    end
                end
            end
        end
    end
end

-- >Returns a Unit from the Game without killing it
function removeFromWorld(unit, offx, offy, offz)
    hideUnit(unit)

    -- TODO - keepStates in general and commandqueu
    pox, poy, poz = Spring.GetUnitPosition(unit)
    Spring.SetUnitAlwaysVisible(unit, false)
    Spring.SetUnitBlocking(unit, false, false, false)
    Spring.SetUnitNoSelect(unit, true)
    Spring.MoveCtrl.Enable(unit, true)
    if offx then Spring.SetUnitPosition(unit, offx, offy, offz) end
end

function getKeyFromValue(t, value)
    for k, v in pairs(t) do if v == t then return k end end
end

-- >Removes a Unit from the Game without killing it
function returnToWorld(unit, px, py, pz)
    showUnit(unit)
    Spring.MoveCtrl.Disable(unit)
    if px then Spring.SetUnitPosition(unit, px, py, pz) end
    Spring.SetUnitAlwaysVisible(unit, true)
    Spring.SetUnitBlocking(unit, true, true, true)
    Spring.SetUnitNoSelect(unit, false)
end

-- > 
function showHide(id, bShow)
    if bShow == true then
        Show(id)
    else
        Hide(id)
    end
end

function showAllSubsSpinsOfPiece(T, pieceGroupName, nr)
    if not nr then 
        return 
    end
    local subName = pieceGroupName .. nr .. "Sub"
    if T[subName] then 
        showT(T[subName])
    end

    local spinName = pieceGroupName .. nr .. "Spin"
    if T[spinName] then
        showT(T[spinName])
        direction = math.random(40,160) * randSign()
        for i=1,#T[spinName] do
            Spin(T[spinName][i] , y_axis, math.rad(direction), math.pi)
        end
    end
end

-- > Shows all Pieces of a a Unit in 
function showAll(id)
    if not unitID then unitID = id end
    pieceMap = Spring.GetUnitPieceMap(unitID)
    for k, v in pairs(pieceMap) do Show(v) end
end

-- > Hide all Pieces of a Unit
function hideAll(id)
    if not unitID then unitID = id end

    pieceMap = Spring.GetUnitPieceMap(unitID)
    for k, v in pairs(pieceMap) do Hide(v) end
end

-- > reveal a Unit 
function showUnit(unit)
    Spring.SetUnitCloak(unit, false, 1)
    Spring.SetUnitLosState(unit, 0, {
        los = true,
        prevLos = true,
        contRadar = true,
        radar = true
    })
end

-- > hide a Unit
function hideUnit(unit)
    Spring.SetUnitCloak(unit, true, 4)
    Spring.SetUnitLosState(unit, 0, {
        los = false,
        prevLos = false,
        contRadar = false,
        radar = false
    })
end

-- > GetDistanceNearestEnemy
function distanceNearestEnemy(id)
    ed = Spring.GetUnitNearestEnemy(id)
    return distanceUnitToUnit(id, ed)
end

-- > returns the gh, the units heigth and wether the unit is underground
function getGroundHeigthAtPiece(uID, pieceName)
    px, py, pz = Spring.GetUnitPiecePosDir(uID, pieceName)
    gh = Spring.GetGroundHeight(px, pz)

    return gh, py, py < gh
end

-- > get the Groundheigth at a Units position
function getUnitGroundHeigth(unitID)
    px, py, pz = Spring.GetUnitPosition(unitID)

    if px then
        h = Spring.GetGroundHeight(px, pz)
        if h then return h end
    end
end

-- > Grabs every Unit in a circle, filters out the unitid
function getInCircle(unitID, Range, teamid)

    x, _, z = Spring.GetUnitBasePosition(unitID)
    return getAllInCircle(x, z, Range, unitID, teamid)

end

-- > Returns the nearest Enemy 
function getNearestGroundEnemy(id, UnitDefs)
    ed = Spring.GetUnitNearestEnemy(id)
    if ed then
        -- early out
        eType = Spring.GetUnitDefID(ed)

        if UnitDefs[eType].isAirUnit == false then return ed end
        eTeam = Spring.GetUnitTeam(ed)
        allUnitsOfTeam = Spring.GetTeamUnits(eTeam)
        mindist = math.huge
        foundUnit = nil
        if Spring.GetUnitIsDead(id) == true or Spring.GetUnitIsDead(ed) == true then
            return nil
        end

        foreach(allUnitsOfTeam, function(ied)
            if ied ~= ed then
                distUnit = distanceUnitToUnit(id, ied)
                if distUnit and distUnit < mindist then
                    if UnitDefs[Spring.GetUnitDefID(ied)].isAirUnit == false then
                        mindist = distUnit
                        foundUnit = ied
                    end
                end
            end
        end)
        if Spring.ValidUnitID(foundUnit) == true then return foundUnit end
    end
end



-- > return the Name of a UnitPiece as String
function getUnitPieceName(unitID, pieceNum)
    pieceList = Spring.GetUnitPieceList(unitID)
    return pieceList[pieceNum] or "No such Piece "..unitID
end

-- > Returns a Map of Pieces and there Position in World Coords
function getPiecePositionMap(id)

    dpiecesTable = Spring.GetUnitPieceMap(id)
    ux, uy, uz = Spring.GetUnitPosition(id)
    tpiecesTable = {}
    i = 1
    for k, v in pairs(dpiecesTable) do
        x, y, z = Spring.GetUnitPiecePosDir(id, v)
        tpiecesTable[i] = {}
        tpiecesTable[i].pid = v
        tpiecesTable[i].x = x or ux
        tpiecesTable[i].y = y or uy
        tpiecesTable[i].z = z or uz
        i = i + 1
    end
    return tpiecesTable
end

-- > returns a table of all unitnames a unit can build
function getUnitCanBuild(unitName, closedT)
    closedTable = closedT or {}
    unitDef = {}
    if type(unitName) == "string" and UnitDefNames then
        unitDef = UnitDefNames[unitName]
    else
        unitDef = UnitDefs[unitName]
    end

    T = {}
    if unitDef.isFactory or unitDef.isBuilder and unitDef.buildOptions then
        for i = 1, #unitDef.buildOptions do
            local buildID = UnitDefs[unitDef.buildOptions[i]].id
            T[#T + 1] = buildID
        end
    end
    closedTable[unitDef.id] = true
    return T, closedTable
end

-- >Stuns a Unit
function stunUnit(k, seconds)
    hp = Spring.GetUnitHealth(k)
    if hp then Spring.SetUnitHealth(k, {paralyze = hp * seconds}) end
end

function transferStates(orgID, targID)
    State = Spring.GetUnitStates(orgID)
    assert(targID)
    if State then
        setFireState(targID, State.firestate)
        setMoveState(targID, State.movestate)
    end
end

-- > Transfer UnitStats
function transferUnitStatusToUnit(id, targetID)
    exP = Spring.GetUnitExperience(id)
    hp, maxHP, para, cap, bP = Spring.GetUnitHealth(id)
    newhp, newmaxHP, _, _, _ = Spring.GetUnitHealth(targetID)
    Spring.SetUnitExperience(targetID, exP)

    factor = (hp / maxHP)
    hp = math.ceil(newmaxHP * factor)

    Spring.SetUnitHealth(targetID, {
        health = hp,
        capture = cap,
        paralyze = para,
        build = bP
    })
    rot={pitch=0,yaw=0,roll=0}
    rot.pitch,rot.yaw,rot.roll = Spring.GetUnitRotation(id)
    Spring.SetUnitRotation(targetID, rot.pitch,rot.yaw,rot.roll)
end

function moveUnitToUnit(id, target, ox, oy, oz)
    ox, oy, oz = ox or 0, oy or 0, oz or 0
    x, y, z = Spring.GetUnitPosition(target)
    if x then
        assert(id)
        Spring.SetUnitPosition(id, x + ox, y + oy, z + oz)
        return true
    end
    return false
end

function turnUnitPieceToUnit(id, p, target, speed)
    ix, iy, iz = Spring.GetUnitPosition(id)
    x, y, z = Spring.GetUnitPosition(target)
    rotation = math.atan2(ix-x, iz-z)
    Turn(p, y_axis, rotation, speed)    
end


function moveCtrlUnitToUnit(id, target)
    Spring.MoveCtrl.Enable(id, true)
    x, y, z = Spring.GetUnitPosition(target)

    if x then
        Spring.MoveCtrl.SetPosition(id, x, y, z)
        return true
    end
    return false
end

function moveUnitToUnitGrounded(id, target, ox, oy, oz)
    ox, oy, oz = ox or 0, oy or 0, oz or 0
    x, y, z = Spring.GetUnitPosition(target)
    if x then
        Spring.SetUnitPosition(id, x + ox, Spring.GetGroundHeight(x, z) + oy,
                               z + oz)
        return true
    end
    return false
end

function moveUnitToUnitPiece(id, target, Name)
    pieceID = Name
    if type(Name) == "string" then
        listOfPieces = Spring.GetUnitPieceMap(target)
        if not listOfPieces[Name] then
            echo("Unit " .. UnitDefs[Spring.GetUnitDefID(target)].name ..
                     " has no piece called " .. Name);
            return false;
        end
        pieceID = listOfPieces[Name]
    end

    x, y, z = Spring.GetUnitPiecePosDir(target, pieceID)
    if x then
        Spring.SetUnitPosition(id, x, y, z)
        return true
    end
    return false
end

function getProjectilesAroundUnit(unitID, dist)
    x,y,z = Spring.GetUnitPosition(unitID)
    return Spring.GetProjectilesInRectangle(x-dist, z-dist, x + dist, z+dist, false, true)
 end

function copyUnit(id, teamID, fatherID)
    ox, oy, oz = ox or 0, oy or 0, oz or 0
    copyID = createUnitAtUnit(teamID, Spring.GetUnitDefID(id), id, ox, oy, oz)
    transferUnitStatusToUnit(id, copyID)
    transferOrders(id, copyID)
    return copyID
end

function transferUnitTeam(id, targetTeam) 
  Spring.TransferUnit(id, targetTeam) 
end

-- > Create a Unit at Piece of another Unit
function createUnitAtPiece(id, typeID, Piece, team)
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(id, Piece)
    teamID = team or Spring.GetUnitTeam(id)
    return Spring.CreateUnit(typeID, x, y, z, math.ceil(math.random(0, 3)),
                             teamID)
end

-- > Create a Unit at another Unit
function createUnitAtUnit(teamID, typeID, otherID, ox, oy, oz, orientation, parentID)
    assert(typeID, " typeID is not of valid type for a unit is nil")
    if not typeID or not teamID then return end
    if doesUnitExistAlive(otherID) == false then return nil end
      ox, oy, oz = ox or 0, oy or 0, oz or 0
    locOrientation = orientation or math.random(0,3)
    if parentID then assert(doesUnitExistAlive(parentID), parentID.. " is not alive") end
    
    x, y, z, _, _, _ = Spring.GetUnitPosition(otherID)

    if parentID then
        return Spring.CreateUnit(typeID, x + ox, y + oy, z + oz, locOrientation, teamID, false, false, parentID)
    else
        return Spring.CreateUnit(typeID, x + ox, y + oy, z + oz, locOrientation, teamID, false, false)
    end
end

function createUnitAtFeature(teamID, typeID, featureID, ox, oy, oz)
    x, y, z, _, _, _ = Spring.GetFeaturePosition(featureID)
    return Spring.CreateUnit(typeID, x + ox, y + oy, z + oz,
                             math.ceil(math.random(0, 3)), teamID)
end

-- > Transforms a selected unit into another type
function transformUnitInto(oldID, unitType, setVel, boolKill, parentID,
                           overWriteID)
    x, y, z = Spring.GetUnitPosition(oldID)
    teamID = Spring.GetUnitTeam(oldID)
    vx, vy, vz, vl = Spring.GetUnitVelocity(oldID)
    rotx, roty, rotz = Spring.GetUnitRotation(oldID)
    currHp, oldMaxHp = Spring.GetUnitHealth(oldID)

    facing = Spring.GetUnitBuildFacing(oldID)
    id = Spring.CreateUnit(unitType, x, y, z, facing, teamID, false, false,
                           overWriteID, parentID)

    if id then
        transferUnitStatusToUnit(oldID, id)
        transferOrders(oldID, id)
        Spring.SetUnitPosition(id, x, y, z)

        if vx and rotx then
            if setVel then
                Spring.SetUnitVelocity(id, vx * vl, vy * vl, vz * vl)
            end
            Spring.SetUnitRotation(id, rotx, roty, rotz)
        end
    end
    if not boolKill or boolKill == true then
        Spring.DestroyUnit(oldID, false, true)
    end

    return id
end

-- > Get Unit Target if a Move.Cmd was issued
function getUnitMoveGoal(unitID, depth)
    local ldepth = depth or 4
    local cmds = Spring.GetCommandQueue(unitID, ldepth)
    local i = #cmds
    for i = #cmds, 1, -1 do
        if cmds[i].id and cmds[i].id == CMD.MOVE and cmds[i].params then
            return cmds[i].params[1], cmds[i].params[2], cmds[i].params[3]
        end
    end
end

function destroyUnitConditional(id, selfd, reclaimed)
    if doesUnitExistAlive(id) == true then
        Spring.DestroyUnit(id, selfd, reclaimed)
    end
end

function doesUnitExistAlive(id)
    local valid = Spring.ValidUnitID(id)
    if valid == nil or valid == false then
     --[[   echo("doesUnitExistAlive::Invalid ID")--]]
        return false
    end

    local dead = Spring.GetUnitIsDead(id)
    if dead == nil or dead == true then
       --[[ echo("doesUnitExistAlive::Dead Unit")--]]
        return false
    end

    return true
end

-- >Unit Verfication
function isUnitAlive(unitid)
    if not unitid then return false end

    isDead = Spring.GetUnitIsDead(unitid)
    if isDead == nil then return true end

    if isDead and isDead == true then return false end

    return true
end

function confirmUnit(id) if doesUnitExistAlive(id) == true then return id end end

function delayedHide(piece, timeT)
    Sleep(timeT)
    Hide(piece)
end

function delayedShow(piece, timeT)
    Sleep(timeT)
    Show(piece)
end

-- > That thing, has a huge thing, and it its cumint towards you..
function getUnitBiggestPiece(unit, cache)
    defID = Spring.GetUnitDefID(unit)
    if cache and cache[defID] then return cache[defID], cache end

    volumeMax = -math.huge
    biggestPieceSoFar = nil
    pieceMap = Spring.GetUnitPieceMap(unit)

    for name, number in pairs(pieceMap) do
        volume = getUnitPieceVolume(unit, number)
        if volume > volumeMax then
            biggestPieceSoFar = number
            volumeMax = volume
        end
    end
    if cache then cache[defID] = biggestPieceSoFar end
    return biggestPieceSoFar, cache or {}
end

function getUnitPieceByName(id, Name)
    pieceMap = Spring.GetUnitPieceMap(id)

    for name, number in pairs(pieceMap) do
        if name == Name then return number end
    end
end

function getUnitPieceVolume(unit, Piece)
    vx, vy, vz = Spring.GetUnitPieceCollisionVolumeD
    if vx then return math.abs(vx * vy * vz) end
    return 0
end

-- > finds GenericNames and Creates Tables with them
function getPieceTableByNameGroups(boolMakePiecesTable, boolSilent)

    boolSilentRun = boolSilent or true
    pieceMap = Spring.GetUnitPieceMap(unitID)
    piecesTable = Spring.GetUnitPieceList(unitID)

    TableByName = {}
    NameAndNumber = {}
    ReturnTable = {}

    for i = 1, #piecesTable, 1 do
        s = string.reverse(piecesTable[i])

        for w in string.gmatch(s, "%d+") do
            if w then
                s = string.sub(s, string.len(w), string.len(s))
                NameAndNumber[i] = {
                    name = string.sub(piecesTable[i], 1, string.len(
                                          piecesTable[i]) - string.len(w)),
                    number = string.reverse(w)
                }

                if TableByName[NameAndNumber[i].name] then
                    TableByName[NameAndNumber[i].name] =
                        TableByName[NameAndNumber[i].name] + 1
                else
                    TableByName[NameAndNumber[i].name] = 1
                end
                break
            end
        end
        if not NameAndNumber[i] then
            NameAndNumber[i] = {name = string.reverse(s)}
        end
    end

    if boolSilentRun == false then
        for k, v in pairs(TableByName) do
            if v > 1 then Spring.Echo(k .. " = {}") end
        end

        for k, v in pairs(NameAndNumber) do

            if v and v.number then
                Spring.Echo(v.name .. v.number .. " = piece\"" .. v.name ..
                                v.number .. "\"")
                Spring.Echo(v.name .. "[" .. v.number .. "]= " .. v.name ..
                                v.number)
            else
                Spring.Echo(v.name .. " = piece(" .. v.name .. ")")
            end
        end

        if boolMakePiecesTable and boolMakePiecesTable == true then
            generatepiecesTableAndArrayCode(unitID)
        end

    else

        -- pack the piecesTables in a UeberTable by Name
        for tableName, _ in pairs(TableByName) do
            local PackedAllNames = {}
            -- Add the Pieces to the Table
            for k, v in pairs(NameAndNumber) do

                if v and v.number and v.name == tableName then
                    piecename = v.name .. v.number
                    if lib_boolDebug == true then
                        if lib_boolDebug == true and pieceMap[piecename] then
                            Spring.Echo(v.name .. "[" .. v.number .. "] = " ..
                                            piecename .. " Piecenumber: " ..
                                            pieceMap[piecename])
                        else
                            Spring.Echo("pieceMap contains no piece named " ..
                                            piecename)
                        end
                    end
                    convertToNumber = tonumber(v.number)
                    PackedAllNames[convertToNumber] = pieceMap[piecename]
                end
            end
            ReturnTable[tableName] = PackedAllNames
        end

        return ReturnTable
    end
end

-- >generates a Pieces List 
function generatepiecesTableAndArrayCode(unitID, boolLoud)
    return getPieceTable(unitID)
end
function getPieceTable(unitID)
    RetT = {}
    piecesTable = Spring.GetUnitPieceMap(unitID)
    for k, v in pairs(piecesTable) do RetT[#RetT + 1] = v end
    return RetT
end

-- >generates a Pieces List Keyed to the PieceName
function getNamePieceNumDict(unitID, piecefunction)

    returnTable = {}
    piecesTable = Spring.GetUnitPieceList(unitID)

    if piecesTable ~= nil then
        for i = 1, #piecesTable, 1 do
            returnTable[piecesTable[i]] = piecefunction(piecesTable[i])
        end
    end
    return returnTable
end


-- >Gets the Height of a Unit
function getUnitHeight(UnitId)
    _, y, _ = Spring.GetUnitPosition(unitID)
    return y
end


-- > Returns a Units side as string
function getUnitSide(unitID)
    teamid = Spring.GetUnitTeam(unitID)
    return select(1, getTeamSide(teamid))
end

function getUnitName(unitID)   
    if not UnitDefs then
        echo("getUnitName: No UnitDefs in context");
        return ""
    end
    return UnitDefs[Spring.GetUnitDefID(unitID)].name
end

function showTypeDependent(unitID, typenNamePiecesTable)
    unitName = getUnitName(unitID)
    showT(typenNamePiecesTable)
end
-- ======================================================================================
-- Section: Initializing Functions
-- ======================================================================================
function getPieceMap(unitID)
    List = Spring.GetUnitPieceMap(unitID)
    return List
end

function isUnitComplete(id)
    if not id then return false end
    if doesUnitExistAlive(id) == false then return false end

    hp, mHp, pD, cP, buildProgress = Spring.GetUnitHealth(id)

    if  buildProgress and buildProgress < 1.0 then return false end

    return true
end

function waitTillComplete(id)
    local spGetUnitHealth = Spring.GetUnitHealth
    if not id then return false end
    if doesUnitExistAlive(id) == false then return false end

    hp, mHp, pD, cP, buildProgress = spGetUnitHealth(id)

    Sleep(1)
    repeat
        hp, mHp, pD, cP, buildProgress = spGetUnitHealth(id)
        Sleep(50)
    until buildProgress or doesUnitExistAlive(id) == false

    if doesUnitExistAlive(id) == false then return false end

    while buildProgress and buildProgress < 1.0 do
        if doesUnitExistAlive(id) == false then return false end
        hp, mHp, pD, cP, buildProgress = spGetUnitHealth(id)

        if not buildProgress then return false end
        Sleep(50)
    end

    return doesUnitExistAlive(id)
end

function createUnit_TerrainTest(uType, x, y, z, orientation, teamID,
                                acceptableIncline)

    loc_acceptableDecline = acceptableIncline or 0.35
    tx, ty, tz, slope = Spring.GetGroundNormal(x, z)

    -- Spring.Echo("createUnit_TerrainTest: slope = "..slope.. " < ".. loc_acceptableDecline )
    if slope < loc_acceptableDecline then

        return Spring.CreateUnit(uType, x, y, z, orientation, teamID)
    end

    Spring.Echo("createUnit_TerrainTest:" .. slope .. " > " ..
                    loc_acceptableDecline)
end

function breakUnitIntoProjectilePieces(id)

    explodeFunction = function()
        T = getPieceTable(id)
        for i = 1, #T do Spring.UnitScript.Explode(T[i], 1 + 128) end
    end

    env = Spring.UnitScript.GetScriptEnv(id)
    if env then Spring.UnitScript.CallAsUnit(id, explodeFunction) end

    Spring.DestroyUnit(id, false, true)
end
-- ======================================================================================
-- Section: Landscape/Pathing Getter/Setters
-- ======================================================================================

function createExtrema()

    emin, emax = Spring.GetGroundExtremes()
    if emin and emax then

        if math.abs(emax) > math.abs(emin) then
            GG.Extrema = emax
        else
            GG.Extrema = emin
        end
    else
        GG.Extrema = 250
    end
end

-- > Does not remove the grass
function removeGrass(startX, endX, startY, endY)

    for x = startX, endX, 16 do
        for z = startY, endY, 16 do Spring.RemoveGrass(x, z) end
    end
end
-- > Gets a List of Geovents + Positions
function getGeoventList()

    features = Spring.GetAllFeatures()
    GeoventList = {}
    for i = 1, #features do
        id = features[i]
        defID = Spring.GetFeatureDefID(id)
        if defID == FeatureDefNames["geovent"].id then
            fx, fy, fz = Spring.GetFeaturePosition(id)
            GeoventList[#GeoventList + 1] = {x = fx, y = fy, z = fz, id = id}
        end
    end
    return GeoventList
end

function getADryWalkAbleSpot()
    smin, smax = Spring.GetGroundExtremes()
    if smax <= 0 then return end
    cond = function(i, j, chunkSizeX, chunkSizeZ)
        h = Spring.GetGroundHeight(i * chunkSizeX, chunkSizeZ * j)
        if h > 0 then
            v = {}
            v.x, v.y, v.z = Spring.GetGroundNormal(i * chunkSizeX,
                                                   chunkSizeZ * j)
            v = normVector(v)
            if v.y > 0.3 or math.abs(v.x) < 0.3 or math.abs(v.z) < 0.3 then
                return math.ceil(i * chunkSizeX), math.ceil(i * chunkSizeZ)
            end
        end
    end
    return getPathPointFullfillingConditions(cond, 64)
end

-- >finds a spot on the map that is dry, and walkable
function getPathPointFullfillingConditions(condition, maxRes, filterTable,
                                           mapSizeX, mapSizeZ)
    if type(condition) ~= "function" then
        echo("getPathPointFullfillingConditions recived not a valid function")
    end

    probeResolution = 4.0
    local spGetGroundHeight = Spring.GetGroundHeight
    assert(Game.mapSizeX)
    assert(Game.mapSizeZ)
    while true do

        local chunkSizeX = (Game.mapSizeX - 1) / probeResolution
        local chunkSizeZ = (Game.mapSizeZ - 1) / probeResolution
        xRand, zRand = math.floor(sanitizeRandom(1, probeResolution - 1)),
                       math.floor(sanitizeRandom(1, probeResolution - 1))

        for i = xRand, probeResolution, 1 do
            for j = zRand, probeResolution, 1 do
                ax, ay, az =
                    condition(i, j, chunkSizeX, chunkSizeZ, filterTable)
                if ax then return ax, ay, az end
            end
        end

        for i = 1, xRand, 1 do
            for j = 1, zRand, 1 do
                ax, ay, az =
                    condition(i, j, chunkSizeX, chunkSizeZ, filterTable)
                if ax then return ax, ay, az end
            end
        end

        probeResolution = probeResolution * 2
        if probeResolution > maxRes then
            if boolDebug == true then
                Spring.Echo("Aborting Due to High Probe Resolution");
            end
            return
        end
    end
end

-- >ConditionFunctions
function GetSpot_condDeepSea(x, y, chunkSizeX, chunkSizeZ, filterTable)
    h = Spring.GetGroundHeight(x * chunkSizeX, y * chunkSizeZ)
    if h < filterTable.minBelow and h > filterTable.maxAbove then
        return x * chunkSizeX, y * chunkSizeZ
    end
end

-- > convert Unit to Heightmap
function UnitToHeightMap(unitID)
    bx, by, bz = Spring.GetUnitBasePosition(unitID)
    unitPieceList = Spring.GetUnitPieceMap(unitID)
    foreachedPieces = {}
    -- TODO add Unit rotation, add Piecerotation
    foreach(unitPieceList, function(pieceNumber)

        resulT = Spring.GetUnitPieceInfo(unitID, pieceNumber)
        px, py, pz = Spring.GetUnitPiecePosition(unitID, pieceNumber)
        size = {x = resulT.max[1], y = resulT.max[2], z = resulT.max[3]}

        foreachedPieces[pieceNumber] = {
            pos = {x = px, y = py, z = pz},
            p1 = vector:new(size.x, py, size.y),
            p2 = vector:new(-size.x, py, size.y),
            p3 = vector:new(-size.x, py, -size.y),
            p4 = vector:new(size.x, py, -size.y)

        }
    end)
end

function todo(task)
    if not GG.Todo then GG.Todo = {} end
    if not GG.Todo[task] then
        GG.Todo[task] = true
        echo("TODO: ".. task)
    end
end

-- > multiplies a deformation map with a factor
function multiplyHeigthmapByFactor(map, factor)
    for o = 1, #map, 1 do
        for i = 1, #map[o], 1 do map[o][i] = map[o][i] * factor end
    end
    return map
end

-- > blend Heigthmap
function blendToValueHeigthmap(map, dimension, blendStartRadius, blendEndRadius,
                               ValueToBlend)
    center = {x = math.ceil(dimension / 2), z = math.ceil(dimension / 2)}
    total = blendEndRadius - blendStartRadius

    for o = 1, dimension, 1 do
        for i = 1, dimension, 1 do
            ldist = distance(center.x, 0, center.z, o, 0, i)
            if ldist > blendStartRadius and ldist < blendEndRadius then
                factor = (ldist - blendStartRadius) / total
                map[o][i] = map[o][i] * (1 - factor) + ValueToBlend * (factor)
            end
        end
    end
    return map
end

-- > takes any given MapTable and nullifys the value outside and inside the circle
function circularClampHeigthmap(map, dimension, radius, boolInside,
                                overWriteValue)
    center = {x = math.ceil(dimension / 2), z = math.ceil(dimension / 2)}
    for o = 1, dimension, 1 do
        for i = 1, dimension, 1 do

            if distance(center.x, 0, center.z, o, 0, i) > radius then -- we are Outside
                if boolInside == false then
                    map[o][i] = overWriteValue
                end
            else
                if boolInside == true then
                    map[o][i] = overWriteValue
                end
            end
        end
    end
    return map
end

-- > creates a heightmap distortion table
function prepareCupTable(size, height, innerdiameter, percentage)
    if not size or not height then return nil end
    cent = math.ceil(size / 2)
    T = {}
    for o = 1, size, 1 do
        T[o] = {}
        for i = 1, size, 1 do
            -- default
            T[o][i] = 0
            distcent = math.sqrt((cent - i) ^ 2 + (cent - o) ^ 2)
            if distcent < cent - 1 then
                T[o][i] = (cent - distcent) * height
                if distcent < innerdiameter then
                    T[o][i] = (cent - distcent) * (height * percentage)

                end
            end
        end
    end

    return T
end

-- > creates a heightmap distortion table
function prepareHalfSphereTable(size, height)
    if not size or not height then return nil end
    cent = math.ceil(size / 2)
    T = {}
    for o = 1, size, 1 do
        T[o] = {}
        for i = 1, size, 1 do
            -- default
            T[o][i] = 0
            distcent = math.sqrt((cent - i) ^ 2 + (cent - o) ^ 2)
            if distcent < cent - 1 then
                T[o][i] = (cent - distcent) * height
            end
        end
    end

    return T
end

-- > creates a heightmap distortion table that averages the height 
function smoothGroundHeigthmap(size, x, z)
    gh = Spring.GetGroundHeight(x, z)
    if not size then return nil end

    T = {}
    for o = 1, size, 1 do
        T[o] = {}
        for i = 1, size, 1 do
            lgh = Spring.GetGroundHeight(x + ((o - (size / 2)) * 8),
                                         z + ((i - (size / 2)) * 8))
            sign = -1
            if lgh < gh then sign = 1 end
            -- default
            T[o][i] = math.abs(gh - lgh) * sign
        end
    end
    return T
end

function isInTransformationRange(x,z, totalWidth, smoothRange)
    if x < smoothRange or x > (totalWidth -  smoothRange) then return true end
    if z < smoothRange or z > (totalWidth -  smoothRange) then return true end
    return false
end

function isInCenter(x,z, totalWidth, smoothRange)
    if ((x > smoothRange and x < (totalWidth -  smoothRange)) and
     (z > smoothRange and z < (totalWidth -  smoothRange))) then return true end
    return false
end

function smoothTerrainAtUnit(id, totalWidth, smoothRange)
    ox,_, oz = Spring.GetUnitPosition(id)
    return smoothTerrainInRange(ox, oz, totalWidth, smoothRange)
end

function smoothTerrainInRange(ox, oz, totalWidth, smoothRange)
  assert(ox <= Game.mapSizeX)
  assert(oz <= Game.mapSizeZ)
  
  local spGetOrigGroundHeight = Spring.GetGroundOrigHeight
  local spGetGroundHeight = Spring.GetGroundHeight
  local refHeigth =  spGetOrigGroundHeight(ox, oz)
  local orgOffsetMap = smoothGroundHeigthmap(totalWidth, ox, oz)
  local oxStart  = math.max(0,ox -totalWidth/2) 
  local ozStart  = math.max(0, oz -totalWidth/2)
  
  local orgTerrainMap = {}
  local diagonal = (totalWidth)*math.sqrt(2)
  for x = 1, totalWidth do
    orgTerrainMap[x] = {}
    for z = 1, totalWidth do
     
      if isInTransformationRange(x, z, totalWidth, smoothRange) == true then

        totalDistance = distance(oxStart,0 ,ozStart, x, 0, z)
        if totalDistance > diagonal then
            maxDistance = totalWidth/2
            InterpolationFactor =  totalDistance/maxDistance

            orgTerrainMap[x][z] =   (refHeigth) * InterpolationFactor + 
                                    spGetOrigGroundHeight(x,z) * (1.0-InterpolationFactor)
            --project was aborted due to misstransformation -> Solution: Copy whatever worked from journeywar
        end
       elseif totalDistance < diagonal then
            orgTerrainMap[x][z] = refHeigth
       else
            orgTerrainMap[x][z] = spGetOrigGroundHeight(x,z)
       end
    end
  end
	
	local startVarX, endVarX = 1, totalWidth
	local startVarZ, endVarZ = 1, totalWidth
	local cceil = math.ceil

  local spSetHeightMapFunc = Spring.SetHeightMapFunc
	 spSetHeightMapFunc( function()
              local spSetHeightMap = Spring.SetHeightMap
              --1, 127
              for z = startVarZ, endVarZ, 8 do
                  boolPulledOff = false
                  for x = startVarX, endVarX, 8 do --changed to 8 as the wizzard zwzsg said i should ;)
                      if  orgTerrainMap[cceil(x / 8)] and  orgTerrainMap[cceil(x / 8)][cceil(z / 8)] then
                          spSetHeightMap(oxStart +x, ozStart+ z, orgTerrainMap[cceil(x / 8)][cceil(z / 8)] )
                      end
                  end
              end
          end	
          )
  end

-- > This function foreach result of Spring.PathRequest() to say whether target is reachable or not
function IsTargetReachable(moveID, ox, oy, oz, tx, ty, tz, radius)
    local result, lastcoordinate, waypoints
    local path = Spring.RequestPath(moveID, ox, oy, oz, tx, ty, tz, radius)
    if path then
        local waypoint = path:GetPathWayPoints() -- get crude waypoint (low chance to hit a 10x10 box). NOTE; if waypoint don't hit the 'dot' is make reachable build queue look like really far away to the GetWorkFor() function.
        local finalCoord = waypoint[#waypoint]
        if finalCoord then -- unknown why sometimes NIL
            local dx, dz = finalCoord[1] - tx, finalCoord[3] - tz
            local dist = math.sqrt(dx * dx + dz * dz)
            if dist <= radius + 20 then -- is within radius?
                result = true
                lastcoordinate = finalCoord
                waypoints = waypoint
            else
                result = false
                lastcoordinate = finalCoord
                waypoints = waypoint
            end
        end
    else
        result = true
        lastcoordinate = nil
        waypoints = nil
    end

    return result, lastcoordinate, waypoints
end

function getExtremasInArea(x1, z1, x2, z2, resolution)
    minHeightSet= {value = math.huge, x=0, z= 0}
    maxHeightSet= {value = math.huge*-1, x=0, z= 0}
    local spGetGroundHeight = Spring.GetGroundHeight
    for x=x1, x2, resolution do
    for z=z1, z2, resolution do
        height = spGetGroundHeight(x,z)
        if height < minHeightSet.value then
            minHeightSet.value = height
            minHeightSet.x = x
            minHeightSet.z = z
        end
        if height > maxHeightSet.value then
            maxHeightSet.value = height
            maxHeightSet.x = x
            maxHeightSet.z = z
        end
    end
    end
    return minHeightSet, maxHeightSet
end

-- >gets the original Mapheight
function getHistoricHeight(UnitId)
    tempX, tempY, tempZ = Spring.GetUnitPosition(UnitId)
    tempY = Spring.GetGroundOrigHeight(tempX, tempZ)
    return tempY
end

-- >Get the Ground Normal, uses a handed over function and returns a corresponding Table
function getGroundMapTable(Resolution, HandedInFunction)
    ReT = {}
    local spGetGroundNormal = Spring.GetGroundNormal
    for x = 1, Game.mapSizeX, Resolution do
        ReT[x] = {}
        for y = 1, Game.mapSizeY, Resolution do
            dx, dy, dz = spGetGroundNormal(x, y)
            ReT[x][y] = Helperfunction(dx, dy, dz)
        end
    end
    return ReT
end

function getRandomArgument(...)
    arg = {...};
    return getSafeRandom(arg, arg[1])
end

-- >Generalized map foreaching Function
-- >Get the Ground Normal, uses all handed over functions for foreaching and returns a corresponding Table
function doForMapPos(Resolution, ...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end

    for k, v in pairs(arg) do
        if type(v) ~= "function" then
            return Spring.Echo(" Argument is not a foreaching function")
        end
    end

    ReT = {}
    for x = 1, Game.mapSizeX, Resolution do
        ReT[x] = {}
        for y = 1, Game.mapSizeY, Resolution do
            res = {}
            for k, v in pairs(arg) do res = arg(x, y, res) end
            ReT[x][y] = res
        end
    end
    return ReT
end

-- ======================================================================================
-- Section: Syntax additions and Tableoperations
-- ======================================================================================
function takeTableSubRange(T, min, max)
    local subT = {}
    for i=min,max do
        subT[#subT+1] = T[i]
    end
    return subT
end

function filterEventsUniqueByTime(filterTable, identifier, timeInFrames)
    boolFilteredOut = false
    if not filterTable[identifier] then
      filterTable[identifier]  = Spring.GetGameFrame()
      return filterTable, boolFilteredOut
    end

    if  filterTable[identifier] + timeInFrames >  Spring.GetGameFrame() then
        return filterTable, true
    end

    return filterTable, boolFilteredOut
end

function delayedExecution(timeToSleep, func, ...)
    Sleep(timeToSleep)
    func(...)
end

function getRandomElementFromTable(Table)
    if #Table == 0 then return nil end
    if #Table == 1 then return Table[1]end
    return Table[math.random(1,#Table)]
end

function toBool(val)
    local t = type(val)
    if (t == 'nil') then
        return false
    elseif (t == 'boolean') then
        return val
    elseif (t == 'number') then
        return (val ~= 0)
    elseif (t == 'string') then
        return ((val ~= '0') and (val ~= 'false'))
    end
    return false
end

function getNthDictElement(Dict, nr)
    index = 0
    for key, value in pairs(Dict) do
        index = index + 1
        if index ==  nr then
            return key, value
        end
    end

    if nr > count(Dict) then
        return getNthDictElement(Dict, nr % count(Dict))
    end     
end     

function axisToString(axis)
    if axis == 1 then return "x" end
    if axis == 2 then return "y" end
    if axis == 3 then return "z" end
end

-- >selects a element from a table
function selStr(index, t)
    if not t[index] then return "" end

    return toString(t[index])
end

-- >Inserts a Value only if it is not found
function TableInsertUnique(Table, Value)
    for i = 1, #Table do if Table[i] == Value then return Table end end
    table.insert(Table, Value)
    return Table
end

-- >Sanitizes a Variable for a table
function sanitizeItterator(Data, Min, Max)
    return math.max(Min, math.min(Max, math.floor(Data)))
end

-- >Splits a Table into Two Tables
function splitTable(T, breakP, breakEnd)
    breakPoint = breakP or math.ceil(#T / 2)
    breakPoint = sanitizeItterator(breakPoint, 1, table.getn(T))
    local T1 = {}

    for i = breakPoint, breakEnd, 1 do T1[#T1 + 1] = T[i] end

    return T1
end

function binaryInsertTable(Table, Value, ToInsert, key)
    i = math.floor(table.getn(Table) / 2)
    upLim, loLim = table.getn(Table), 1
    previousi = 1
    if key then
        ToInsert = {value = ToInsert, key = key}

        while true do
            if Value > Table[i] and Table[i + 1] and Value > Table[i + 1] then
                previousi = i
                i = i + math.floor((upLim - loLim) / 2)
                loLim = previousi
            elseif Value < Table[i] and Table[i - 1] and Value < Table[i - 1] then
                previousi = i
                i = i - math.floor((upLim - loLim) / 2)
                uplim = previousi
            else
                table.insert(Table, ToInsert, i)
                return Table, i
            end
        end
    end
end

-- > check on the Lock Infrastructur
function checkLocks(Lock)
    if Lock then return Lock end

    id = unitID or getUniqueID()
    if not GG.Lock then GG.Lock = {} end
    if not GG.Lock[id] then GG.Lock[id] = {} end
    Lock = Lock or GG.Lock[id]
    return Lock, id
end

-- > getUniqueID
-- > Takes a Table of Locks and locks it if the lock is free 
function TestSetLock(Lock, number)
    Lock, uid = checkLocks(Lock)

    if TestLocks(number) == true then
        Lock[number] = true
        return true, uid
    end
    return false, uid
end

-- >Test a rows of locks up to number
function TestLocks(Lock, number)
    Lock = checkLocks(Lock)

    for i = 1, table.getn(Lock) do
        if number ~= i and Lock[i] == true then return false end
    end
    return true, uid
end

-- > Sets a Lock free
function ReleaseLock(Lock, number)
    Lock, uid = checkLocks(Lock)

    Lock[number] = false
    return Lock[number], uid
end

-- >Get the lowest Value in a table
function getLowest(Table)
    lowest = 0
    val = 0
    for k, v in pairs(Table) do
        if v < val then
            val = v
            lowest = k
        end
    end
end

-- > Sums up all values in a table
function sumTable(Table)
    a = 0
    for i = 1, #Table do a = a + Table[i] end
    return a
end

function sumDict(Table)
    a = 0
    for k, v in pairs(Table) do a = a + v end
    return a
end

function tableToDict(T)
    reT = {}
    if not T then return reT end

    for i = 1, #T do if T[i] then reT[T[i]] = T[i] end end
    return reT
end

function mergeTables(...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    Table = {}
    if not arg then return end

    for _, v in pairs(arg) do
        if v and type(v) == "table" then
            Table = TableMergeTable(Table, v)
        end
    end

    return Table
end

function dictToTable(dict)
    local num = 1
    local T = {}
    for k, v in pairs(dict) do
        if v then
            T[num] = k
            num = num + 1
        end
    end
    return T
end

function TableMergeTable(TA, TB)
    T = {}
    if #TA >= #TB then
        T = tableToDict(TA)

        for i = 1, #TB do if not T[TB[i]] then TA[#TA + 1] = TB[i] end end
        return TA
    else
        T = tableToDict(TB)
        for i = 1, #TA do if not T[TA[i]] then TB[#TB + 1] = TA[i] end end
        return TB
    end
end

function removeDictFromDict(dA, dB)
    returnTable = {}
    for k, v in pairs(dA) do 
        if not dB[k] then 
            returnTable[k] = v 
        end 
    end
    return returnTable
end


function mergeDictionarys(...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    Table = {}
    if not arg then return end

    for _, v in pairs(arg) do
        if v and type(v) == "table" then
            Table = DictionaryMergeDictionary(Table, v)
        end
    end

    return Table
end

function DictionaryMergeDictionary(TA, TB)
    T = {}

    for k,v in pairs(TA) do
        T[k]= v
    end

    for k,v in pairs(TB) do
        T[k]= v
    end    

    return T
end

function pieceToPointT(piecesTable)

    if type(piecesTable) == "number" then
        return {[1] = pieceToPoint(piecesTable)}
    end

    if not piecesTable then
        echo("lib_UnitScript::pieceToPointT: No argument recived")
        return
    end

    reTab = {}

    for i = 1, #piecesTable do
        reTab[i] = {}
        reTab[i].Piece = piecesTable[i]
        x, y, z = Spring.GetUnitPiecePosDir(unitID, piecesTable[i])
        assert(z, "Z not defined for piece" .. piecesTable[i] .. " aka " ..
                   getUnitPieceName(unitID, piecesTable[i]))
        assert(y, "Y not defined for piece" .. piecesTable[i] .. " aka " ..
                   getUnitPieceName(unitID, piecesTable[i]))
        assert(z, "Z not defined for piece" .. piecesTable[i] .. " aka " ..
                   getUnitPieceName(unitID, piecesTable[i]))

        reTab[i].x, reTab[i].y, reTab[i].z = x, y, z
        reTab[i].index = i
    end

    return reTab
end

function getLowestPointOfSet(Table, axis)

    if #Table < 1 then return nil end

    local lowIndex = 1
    y = math.huge
    if axis == "y_axis" then
        for i = 1, #Table do
            if Table[i].y < y then
                y = Table[i].y
                lowIndex = i
            end
        end
    end
    if axis == "z_axis" then
        for i = 1, #Table do
            if Table[i].z < z then
                z = Table[i].z
                lowIndex = i
            end
        end
    end
    if axis == "x_axis" then
        for i = 1, #Table do
            if Table[i].x < x then
                x = Table[i].x
                lowIndex = i
            end
        end
    end
    return Table[lowIndex].x, Table[lowIndex].y, Table[lowIndex].z, index
end

function getHighestPointOfSet(Table, axis)
    if type(Table) ~= "table" then
        echo("getHighestPointOfSet:not a table")
        return nil
    end

    if count(Table) == 0 then
        echo("getHighestPointOfSet:table is empty")
        return nil
    end

    index = 1
    y = -math.huge
    if axis == "y_axis" then
        for i = 1, #Table do
            if Table[i].y > y then
                y = Table[i].y
                index = i
            end
        end
    end
    if axis == "z_axis" then
        for i = 1, #Table do
            if Table[i].z > y then
                y = Table[i].z
                index = i
            end
        end
    end
    if axis == "x_axis" then
        for i = 1, #Table do
            if Table[i].x > y then
                y = Table[i].x
                index = i
            end
        end
    end

    return Table[index].x, Table[index].y, Table[index].z, index
end

function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function inherit(childClass, parent)
    local orig_type = type(parent)
    local copy = parentClass or {}

    for orig_key, orig_value in next, parent, nil do
        copy[deepCopy(orig_key)] = deepCopy(orig_value)
    end
    setmetatable(copy, deepCopy(getmetatable(parent)))
    -- add Operators to unitscript
    return copy
end

function inRange(mins, val, maxs)
    if val >= mins and val <= maxs then return true end

    return false
end

-- > checks wether a value with threshold factor is within range of a second value
function withinRange(value1, value2, treShold)
    if value1 * treShold > value2 or value1 * (1 - treShold) < treShold then
        return true
    else
        return false
    end
end

-- > merges two Dictionary Tables with the first having precedence
function mergeDict(l_dA, l_xdB)
    if l_dA and not l_xdB then return l_dA end
    if l_xdB and not l_dA then return l_xdB end
    local l_dB = l_xdB
    for k, v in pairs(l_dA) do l_dB[k] = v end
    return l_dB
end

-- > returns a subset of Unitdefs by UnitdefID
function selectUnitDefs(l_names)
    local l_retT = {}

    for num, uDefID in pairs(l_names) do l_retT[uDefID] = UnitDefs[uDefID] end
    return l_retT
end

-- > returns a subset of Unitdefs by name as string 
function UnitDefToUnitDefNames(UnitDef)
    local l_retT = UnitDef
    for defID, T in pairs(UnitDef) do l_retT[T.name] = T end
    return l_retT
end

-- > Encapsulates the Show function for easier debugging
function assertShow(l_Num)
    assert(l_Num)
    assertNum(l_Num)

    Show(l_Num)
end

-- > Encapsulates the Hide function for easier debugging
function assertHide(l_Num)
    assert(type(l_Num) == "number")
    Hide(l_Num)
end

function showOnePiece(T, hash)
    if not T then return end
    countNrElments = count(T)
    dice = 1
    if hash then
	dice = (hash % countNrElments) +1
    else		
	dice = math.random(1,countNrElments)
    end
	
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
                Show(v)
                return v, k
        end
    end
end

function showOneOrNonePiece(T)
    if not T then return end
    if maRa() == true then
        return showOnePiece(T, true)
    else
        return
    end
end

function showOneOrAllPiece(T)
    if not T then return end
    
    if math.random(1,10) > 5 then
        return showOnePiece(T)
    else
        for num, val in pairs(T) do 

            Show(val)
        end
        return
    end
end

-- > Encapsulates the hide Table function
function capHideT(l_T)
    for k, v in pairs(l_T) do assertNum(v, v) end
    hideT(l_T)
end

-- > Echos out all the elements of a unitdef Table
function echoUnitDefT(l_defT)
    for k, v in pairs(l_defT) do echo(UnitDefs[v].name) end
end

function randShowHide(...)
    local arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    shownPieces = {}

    for nr, pieces in pairs(arg) do
      if maRa()== true then
        Show(pieces)
        shownPieces[#shownPieces + 1] = pieces
      else
        Hide(pieces)
      end
    end

    return shownPieces
end

-- > Hides a PiecesTable, 
function hideT(l_tableName, l_lowLimit, l_upLimit, l_delay)
    if not l_tableName then return end
    assert( type(l_tableName) == "table" , UnitDefs[Spring.GetUnitDefID(unitID)].name.." has invalid hideT")
    boolDebugActive =  (lib_boolDebug == true and l_lowLimit and type(l_lowLimit) ~= "string")


    if l_lowLimit and l_upLimit then
        for i = l_upLimit, l_lowLimit, -1 do
            if l_tableName[i] then
                Hide(l_tableName[i])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. l_lowLimit ..
                         " contains a empty entry")
            end

            if l_delay and l_delay > 0 then Sleep(l_delay) end
        end

    else
        for i = 1, table.getn(l_tableName), 1 do
            if l_tableName[i] then
                Hide(l_tableName[i])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. l_lowLimit ..
                         " contains a empty entry")
            end
        end
    end
end

function placeElevators(TablesOfPiecesGroups, elevatorHeight, nrLevels, toShowDict)
    foreach(TablesOfPiecesGroups["Cabin"],
        function(id)
            if toShowDict[id] then
                ElevatorCabinName =pieceID_NameMap[id].."Cabin"
                CabinId = TablesOfPiecesGroups[ElevatorCabinName][1]
                if CabinId then 
                    StartThread(GenericElevatorOS, CabinId, id, elevatorHeight, nrLevels, 5.0)
                end
            end
        end
    )

end

-- >Shows a Pieces Table
function showT(l_tableName, l_lowLimit, l_upLimit, l_delay)
    if not l_tableName then
        Spring.Echo("No table given as argument for showT in "..getUnitName(unitID))
        assert(l_tableName)
        return
    end

    if type(l_tableName) ~= "table" then Spring.Echo("Not a valid table in "..getUnitName(unitID)); return end

    if l_lowLimit and l_upLimit then
        for i = l_lowLimit, l_upLimit, 1 do
            if l_tableName[i] then Show(l_tableName[i]) end
            if l_delay and l_delay > 0 then Sleep(l_delay) end
        end

    else
        for k,v in pairs(l_tableName)do
			if v then
				Show(v)
			end
        end
    end
end

function subSetT(T, elementToSelect)
    reT = {}
    for i = 1, #T do
     reT[#reT + 1] = T[i][elementToSelect]
    end
    return reT
end

-- > safeAccessTable a table three layers deep on any key/index
function safeAccessTable(T, a, b, c)
    if a and not T[a] then T[a] = {} end
    if b and not T[a][b] then T[a][b] = {} end
    if c and not T[a][b][c] then T[a][b][c] = {} end
    return T
end

function replaceStr(str, sub, replacement)
    return string.gsub(str, sub, replacement)
end

function stringSplit(String, Seperator)
    if Seperator == nil then sep = "%s" end
    local t = {};
    i = 1
    for str in string.gmatch(String, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- > Creates Global Tables from a access string e.g. 
-- >make a GlobalTableHierarchy From a Set of Arguments - String= Tables, Numbers= Params
-- >Example: "TableContaining[key].TableReamining[key].valueName" or [nr] , valueGG.MyGlobalTable.HasASubTable.WithA[Key].ThatHoldsATable
function createGlobalTableFromAcessString(FormatString, assignedValue, ...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    local PreFix = "GG."
    local formatStringFunction = loadstring(PreFix .. FormatString)

    -- test for allread existing table
    boolAccessSuccessfull = false
    boolTestDone = false
    attempts = 0

    StartThread(function()
        if formatStringFunction() then
            loadstring(PreFix .. FormatString .. " = " ..
                           toString(assignedValue))();
            boolAccessSuccessfull = true
        end
        boolTestDone = false
    end)

    repeat
        Sleep(1)
        attempts = inc(attempts)
    until boolTestDone == true or attempts > 3

    if boolAccessSuccessfull == true then return end

    -- SplitByDot

    local SubTables = stringSplit(FormatString, ".")

    boolAvoidFutureChecks = false
    for i = 1, #SubT do
        local subTableString = SubT[i]
        if SubT[i] ~= "GG" then
            SubT[i] = string.gsub(SubT[i], ".")
            ExtracedIndex = string.match(SubT[i], "[", "]")
            ExtractedTable = string.gsub(SubT[i], ExtracedIndex, "")
            Terminator = "."
            if ExtractedTable then
                if boolAvoidFutureChecks == true or
                    not loadstring(PreFix .. ExtractedTable)() then
                    loadstring(PreFix .. ExtractedTable .. "= {}")
                    boolAvoidFutureChecks = true
                end
            else
                ExtractedTable = "";
                Terminator = ""
            end
            if boolAvoidFutureChecks == true or ExtracedIndex and
                not loadstring(PreFix .. ExtractedTable .. ExtracedIndex)() then
                loadstring(PreFix .. ExtractedTable .. ExtracedIndex .. "={}")()
            end

            PreFix = PreFix .. ExtractedTable .. ExtracedIndex .. Terminator
        end
    end

    loadstring(PreFix .. "=" .. assignedValue)()
    return loadstring(PreFix .. "==" .. asignedValue)()
end

function startsWith(str, start)
   return str:sub(1, #start) == start
end

-- > Creates a Table and initializes it with default value
function makeTable(default, xDimension, yDimension, zDimension,
                   boolNegativeMirror)
    boolNegativeMirror = boolNegativeMirror or false

    xStartIndex = 1
    yStartIndex = 1
    zStartIndex = 1

    if boolNegativeMirror == true then
        xStartIndex = -xDimension
        yStartIndex = -yDimension
        zStartIndex = -zDimension
    end

    local RetTable = {}
    if not xDimension then return default end

    for x = xStartIndex, xDimension, 1 do
        if yDimension then
            RetTable[x] = {}
        elseif xDimension then
            RetTable[x] = default
        else
            return default
        end

        if yDimension then
            for y = yStartIndex, yDimension, 1 do
                if zDimension then
                    RetTable[x][y] = {}
                else
                    RetTable[x][y] = default
                end

                if zDimension then
                    for z = zStartIndex, zDimension, 1 do
                        RetTable[x][y][z] = default
                    end
                end
            end
        end
    end
    return RetTable
end

-- > rotate zero Centric Table
function rotateMap(Map, sizeX, sizeZ, degreeRotation, default)
    local rotateCopy = makeTable(default, sizeX, sizeZ, nil, true)
    for x = -sizeX, sizeX do
        for z = -sizeZ, sizeZ do
            if Map[x][z] ~= default then
                rx, rz = Rotate(x, z, math.rad(degreeRotation))
                rotateCopy[rx][rz] = Map[x][z]
            end
        end
    end

    return rotateCopy
end

-- > shifts a 2d Map by a vector, replaces empty values with default
function shiftMap(Map, sizeX, sizeZ, offX, offZ, default)
    local shiftedMap = makeTable(default, sizeX, sizeZ, nil, true)
    for x = -sizeX, sizeX do
        for z = -sizeZ, sizeZ do
            if Map[x][z] ~= default and shiftedMap[x + offX] and
                shiftedMap[x + offX][z + offZ] then
                shiftedMap[x + offX][z + offZ] = Map[x][z]
            end
        end
    end
    return shiftedMap
end

function removeTrailingNumbersFromName(str)
    for i =  string.len(str), 1, -1 do
        character = string.sub(str, i, i)
        asciiByteValue = string.byte(character)
        if (asciiByteValue > 47 and asciiByteValue <58) == false then
            return string.sub(str, 1, i)
        end
    end
end

-- >Creates a table of piecenamed enumerated strings
function makeTableOfPieceNames(l_name, l_nr, l_startnr, l_piecefoonction)
    local T = {}
    l_start = l_startnr or 1

    for i = l_start, l_nr do
        namecopy = l_name
        namecopy = namecopy .. i
        T[i] = namecopy
    end
    if l_piecefoonction then
        for i = l_start, l_nr do T[i] = l_piecefoonction(T[i]) end
    end
    return T
end

-- > Adds to a Table, argument as keys, subtables
function addTableTables(T, ...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    String = "T"
    boolOneTimeNil = false
    if arg then
        for k, v in pairs(arg) do
            String = String .. "[" .. v .. "]"

            if boolOneTimeNil == false then
                if loadstring(String) ~= nil then
                else
                    boolOneTimeNil = true
                end
            else
                loadstring(String .. "={}")
            end
        end
    end
    return T
end

function movePosInTime(pieceName, oldPos, newPos, timeSec)
    Move(pieceName, x_axis, newPos[1], calcSpeedSec( oldPos[1],  newPos[1],  timeSec ))
    Move(pieceName, y_axis, newPos[2], calcSpeedSec(oldPos[2],   newPos[2],  timeSec ))
    Move(pieceName, z_axis, newPos[3], calcSpeedSec(oldPos[3],   newPos[3],  timeSec ))
end

function calcSpeedSec(a, b, timeSec)
    return math.abs(a-b)/(timeSec)
end

-- >filters out the dead 
function validateUnitTable(T)
    TVeryMuchAlive = {}

    for i = #T, 1, -1 do
        boolUnitDead = Spring.GetUnitIsDead(T[i])
        if boolUnitDead and boolUnitDead == false then
            TVeryMuchAlive[#TVeryMuchAlive + 1] = T[i]
        end
    end

    return TVeryMuchAlive or {}
end

-- >adds a numeric Table to a numeric Table
function TAddT(OrgT, T)
    for i = 1, #T do OrgT[#OrgT + i] = T[i] end
    return OrgT
end

-- > Counts the number of elements in a dictionary
function count(T)
    --if(type(T) ~= "table") then return "debugme" end
    if not T then return 0 end
    local index = 0
    for k, v in pairs(T) do if v then index = index + 1 end end
    return index
end


function compress(T)
    local newTable = {}
    for k,v in pairs(T) do
        if v then
            newTable[k] = v
        end
    end
    return newTable
end

function safeIndex(index, tables)
    return (index % #tables)+1
end

function getNthElementT(T, nth)
    if type(T) ~= "table" then echo(T); return "debugme", "debugme" end
    local index = 0
    for k, v in pairs(T) do
        if v then index = index + 1 end
        if index == nth then return k, v end
    end
end

function getTypeName(unitID)
    defID = Spring.GetUnitDefID(unitID)
    return UnitDefs[defID].name
end

function genFunc(returnStringOnCall)
    val = function() return returnStringOnCall end
    return val
end
-- >Retrieves a random element from a Dictionary
function randDict(Dict)
    if not Dict then return end
    if lib_boolDebug == true then assert(type(Dict) == "table") end

    countDict = count(Dict)
    if countDict == 0 then 
        conditionalEcho(GG.lib_boolDebug ,"Dictionary is empty")
        return genFunc("no Key"), genFunc("no Value")
    end
    randElement = 1
    if countDict > 1 then randElement = math.random(1, countDict) end

    index = 1
    anyKey = 1
  
    for k, v in pairs(Dict) do
        anyKey = k
        if index == randElement and k and v then return k, v end
        index = inc(index)
        if index > countDict then 
            echo("Dictionary index is overshooting")
            return nil 
        end
    end
    
    return anyKey, Dict[anyKey]
end

-- > randomizes Table Entrys
function shuffleT(T)
    local randT = {}
    if not T then
        if GG.BoolDebug == true then
            echo("Shuffle called on empty table")
            assert(T)
        end
        return T or {}
    end

    size = count(T) or 0
    allreadyInserted = {}

    for i = 1, size do
        rIndexStart = math.random(1, size)
        boolFoundSomething = false
        for k = rIndexStart, size do
            if not allreadyInserted[k] then
                key, v = getNthElementT(T, k)
                randT[i] = T[key]
                allreadyInserted[k] = true
                boolFoundSomething = true
            end
        end

        if boolFoundSomething == false then
            for k = 1, rIndexStart do
                if not allreadyInserted[k] then
                    key, v = getNthElementT(T, k)
                    randT[i] = T[key]
                    allreadyInserted[k] = true
                end
            end
        end
    end

    return randT
end

-- >Copys a table
function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function sendMessage(Message, reciverID)
    if not GG.Messages then GG.Messages = {} end
    GG.Messages[reciverID] = Message
end

function recieveMessage(reciverID)
    if not GG.Messages then return end
    return GG.Messages[reciverID]
end

-- > Destroys A Table of Units
function DestroyUnits(T, boolSelfd, boolReclaimed, condFunction, unitID)
    if T then
        for i = 1, #T, 1 do
            if condFunction(T[i]) == true or not condFunction then
                Spring.DestroyUnit(T[i], boolSelfd, boolReclaimed, unitID)
            end
        end
    end
end

function echoNFrames(str, frames)
    if Spring.GetGameFrame() % frames == 0 then echo(str) end
end

-- > Recursively Echo a Table out
function echoT(T, layer)
    local l = layer or 0
    if T then
        if type(T) == 'table' then
            Spring.Echo(stringBuilder(l, "-") .. "[]T:")
            for k, v in pairs(T) do
                Spring.Echo(stringBuilder(l, " ") .. "Key [\"" .. k .. "\"]")
                echoT(T[k], l + string.len(k) + 2)
            end
        else
            local Concated = stringBuilder(math.max(1, l) - 1, " ") .. "|-►"

            local typus = type(T)
            if typus == "number" or typus == "string" then
                Spring.Echo(Concated .. T)
            elseif typus == "boolean" then
                Spring.Echo(Concated .. "boolean" .. ((T == true) and "True"))
            elseif typus == "function" then
                Spring.Echo(Concated .. "function: Result")
                resulT = T()
                if type(resulT) == "table" then
                    echoT(resulT, layer)
                else
                    echo(resulT)
                end
            end
        end
    end
end

-- > debugEchoT(
function getDetermenisticHash()
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


function stringToHash(hashString)
    totalValue = 0
    for i = 1, string.len(hashString) do
        local c = hashString:sub(i, i)
        totalValue = totalValue + string.byte(c, 1)
    end

    return totalValue
end

function reHash(hash, limit)
    return math.ceil(math.sqrt((math.pi^hash)*hash)) % (limit or hash)
end

-- >Generic to String
function toString(element)
    if  element == nil then return "nil" end
    local typeE = type(element)

    if typeE == "nil" then return "nil" end
    if typeE == "boolean" then return boolToString(element) end
    if typeE == "number" then return "" .. element end
    if typeE == "string" then return element end
    if typeE == "table" then return tableToString(element) end
    if typeE == "function" then return "function :" .. elment .. "()" end

    return "Unknown Type in to String for " .. element
end

function echoUnitDefs(unitDefNames)
    for k, v in pairs(unitDefNames) do
        for key, values in pairs(v) do echoT({key, values}) end
    end
end

function tableToString(tab)
    if not tab then return "nil" end
    local PostFix = "}"
    local PreFix = "{"
    local conCat = "" .. PreFix
    for key, value in pairs(tab) do
        if key and value then
            conCat =
                conCat .. "[" .. toString(key) .. "] =" .. toString(value) ..
                    ","
        end
    end

    return conCat .. PostFix
end

-- > Converts a stringserialized table back into a data table
function stringToTable(stringT)
    local foonction = "function() return " .. stringT .. " end"
    return loadstring(foonction)
end

-- > Converts a boolean to a string value
function boolToString(value)
    if value == true then
        return "true"
    else
        return "false"
    end
end

function filterTableByTable(T, T2, compareFunc)
    reTable = {}
    for i = 1, #T do
        if compareFunc(T[i], T2) == true then
            reTable[#reTable + 1] = T[i]
        end
    end
    return reTable
end

function keyTableToTables(T)
    counter = 1
    TableKey = {}
    TableValue = {}
    counter = 1
    for k, v in pairs(T) do
        TableKey[counter] = k
        TableValue[counter + 1] = v
        counter = counter + 2
    end

    return TableKey, TableValue
end

function insertKeysIntoTable(T, T2)
    for i = 1, #T do if not T2[T[i]] then T2[T[i]] = T[i] end end
    return T2
end

-- >itterates over a table, executing a function with a argumentTable
function elementWise(T, fooNction, ArghT)
    reTable = {}

    for k, v in pairs(T) do reTable[k] = fooNction(T[k], ArghT) end

    return reTable
end

-- >recursive itterates over a Keytable, executing a function 
function recElementWise(T, fooNction, ArghT)
    reTable = {}

    for k, v in pairs(T) do
        if type(T[k]) ~= "table" then
            reTable[k] = fooNction(T[k], ArghT)
        else
            reTable[k] = recElementWise(T[k], fooNction, ArghT)
        end
    end

    return reTable
end

-- >count Elements in a Dictionary
function countT(T)
    it = 0
    for k, v in pairs(T) do it = it + 1 end
    return it
end

function sortDictKeysNumeric(T)
    local sorT = {}

    for k, v in pairs(T) do
        for i = 1, #sorT do
            if k > sorT[i] then
                table.insert(sortT, i, k)
                break
            end
        end
    end
    return sortT
end

function inLimit(lowLimit, value, upLimit)
    if value < lowLimit or value > upLimit then return false end
    return true
end

-- > find in intervallTable, returns the lower, upper Entry, a fractionnumber of upper and lower entry
function findInIntervall(T, discreteValue)

    numericSortedKeys = sortDictKeysNumeric(T)
    upperVal = T[numericSortedKeys[#numericSortedKeys]]
    lowerVal = T[numericSortedKeys[1]]

    for i = 1, #numericSortedKeys do
        key, _ = numericSortedKeys[i], T[numericSortedKeys[i]]

        if discreteValue <= key then upperVal = key end

        if discreteValue > key then -- search is done
            lowerVal = key
            disLow, disUp = discreteValue - lowerVal, upperVal - discreteValue
            fraction = disLow / (disLow + disUp)
            return T[lowerVal], T[upperVal],
                   mix(T[lowerVal], T[upperVal], fraction)
        end
    end
end

-- > Join Operation on two tables
join = function(id, argT)
    resulT = {}
    for num, idInTable in pairs(argT) do
        resulT[#resulT + 1] = {id = id, obj = idInTable}
    end
    return resulT
end

-- > Validator
validator = function(id)
    deadOrAlive = Spring.GetUnitIsDead(id)
    if deadOrAlive and deadOrAlive == false then return id end
end

function contains(T, key)
    for index, value in ipairs(T) do
        if value == key then
            return true
        end
    end

    return false
end

-- > takes a Table, and executes Function on it
-- non Function Values are handed to the function following it
-- returning nil removes a element from the foreach chain
function foreach(Table, ...)
    local arg = {...}
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    T = {}
    if Table then
        T = Table
    else
        if lib_boolDebug == true then
            echo("Lua:lib_UnitScript:Process: No Table handed over")
            return
        end
    end
    if not arg then
        echo("No args in foreach")
        return
    end
    if type(arg) == "function" then return elementWise(T, arg) end

    TempArg = {}
    TempFunc = {}
    -- if not arg then return Table end

    for _, f in pairs(arg) do
        if type(f) == "function" then
            T = elementWise(T, f, TempArg)
            TempArg = {}
        else
            TempArg[#TempArg + 1] = f
        end
    end
    return T
end

-- >traverses tables and applys a function to them
function recProcess(Table, ...)
    local arg = {...}
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    T = {}
    if Table then
        T = Table
    else
        echo("Lua:lib_UnitScript:Process: No Table handed over")
        return
    end
    if not arg then
        echo("No args in foreach")
        return
    end
    if type(arg) == "function" then return elementWise(T, arg) end

    TempArg = {}
    TempFunc = {}
    -- if not arg then return Table end

    for _, f in pairs(arg) do
        if type(f) == "function" then
            T = recElementWise(T, f, TempArg)
            TempArg = {}
        else
            TempArg[#TempArg + 1] = f
        end
    end
    return T
end

-- ======================================================================================
-- Section: Geometry/Math functions
-- ======================================================================================
function mapAngleToCube(cubeDim, angle)
    local x, y
    
    -- Convert angle to degrees
    local degrees = angle * 180 / math.pi
    
    -- Normalize angle to [0, 360] degrees
    if degrees < 0 then
        degrees = degrees + 360
    end
    
    -- Determine quadrant
    local quadrant = math.floor(degrees / 90) % 4
    
    if quadrant == 0 then
        x = -1 * cubeDim * math.cos(angle)
        y = -1
    elseif quadrant == 1 then
        x = -1
        y = 1 * cubeDim * math.sin(angle)
    elseif quadrant == 2 then
        x = 1 * (cubeDim - cubeDim * math.cos(angle))
        y = 1
    elseif quadrant == 3 then
        x = 1
        y = -1 * (cubeDim - cubeDim * math.sin(angle))
    end
    
    return x, y
end

function getLocationHash(unitID)
    mx, my, mz = Spring.GetUnitPosition(unitID)
    mx = math.floor(mx /100)
    mz = math.floor(mz /100)
    -- Simple custom hash function
    local prime1 = 73856093
    local prime2 = 19349663
    return math.bit_xor((mx * prime1),(mz * prime2))
end

function getNearestPositionOnCircle(pCenter, Radius, pPos)
    local rPos = {x = 0, y = 0, z = 0}

    rPos.x = pCenter.x + Radius * ((pPos.x - pCenter.x) /
                 math.sqrt((pPos.x - pCenter.x) ^ 2 + (pPos.z - pCenter.z) ^ 2))
    rPos.z = pCenter.z + Radius * ((pPos.z - pCenter.z) /
                 math.sqrt((pPos.x - pCenter.x) ^ 2 + (pPos.z - pCenter.z) ^ 2))
    -- circle equation solved for z: sqrt( -([(pCenter.z -b)/m]- pCenter.x)^2  + Radius) + pCenter.z =   rPos.z
    -- circle equation solved for x: x  = sqrt(Radius - (z -pCenter.z)^2) + 

    return rPos
end

function computateBendLimits(piecename, parent)
    paPosX, paPosY, paPosZ = Spring.GetUnitPiecePosition(unitID, parent)
    cPosX, cPosY, cPosZ = Spring.GetUnitPiecePosition(unitID, piecename)

    -- the offset of the piece in relation to its parentpiece
    v = {}
    v.x, v.y, v.z = cPosX - paPosX, cPosY - paPosY, cPosZ - paPosZ

    pax, pay, paz = Spring.GetUnitPieceCollisionVolumeData(unitID, parent)
    radOfParentSphere = getCubeSphereRad(pax, pay, paz)
    cx, cy, cz = Spring.GetUnitPieceCollisionVolumeData(unitID, piecename)
    radOfPieceSphere = getCubeSphereRad(cx, cy, cz)
    -- rotate the vector so that it aligns with x,y,z origin vectors
    -- computate the orthogonal 
    -- computate the dead degree cube
    wsize = triAngleTwoSided(v.x, v.y)
    -- rotate the computated window inverse to the vector back
    -- voila

    -- Y-Axis 
    -- >TODO:RAGDOLL |_\ -- you approximate the motherpiece with a circle and then do a math.acos( circleradius/distance)
    -- defaulting to a maxturn
    return {ux = -15, x = 15, uy = -180, y = 180, uz = -15, z = 15}
end
function get2DSquareFormationPosition(nr, size, unitsInRow)

    row = math.floor(nr / unitsInRow)
    place = nr % unitsInRow
    return row * size, place * size
end

function getAveragePosT(T)
    ax, ay, az = 0, 0, 0
    counter = 0
    foreach(T, function(id)
        ix, iy, iz = Spring.GetUnitPiecePosDir(unitID, id)
        if ix then
            ax, ay, az = ax + ix, ay + iy, az + iz
            counter = counter + 1
        end
    end)
    return ax / counter, ay / counter, az / counter

end

-- > returns the Midpoint of two given points
function getMidPoint(a, b)
    local a = a
    local b = b
    return (a.x - b.x) / 2 + a.x, (a.y - b.y) / 2 + a.y, (a.z - b.z) / 2 + a.z
end

function swingPointOutFromCenterByFrame(ax, ay, az, frame, swing, totalFrame)
    extend = swing * math.sin(frame / totalFrame) * randSign()
    return ax + math.random(math.min(extend, extend * -1), math.abs(extend)),
           ay + math.random(math.min(extend, extend * -1), math.abs(extend)),
           az + math.random(math.min(extend, extend * -1), math.abs(extend))
end

function square(...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    if not arg then return 0 end
    sum = 0
    for k, v in pairs(arg) do if v then sum = sum + v ^ 2 end end
    return math.sqrt(sum)
end

-- > computes the result of the middleSqreWeylSequence
function middleSquareWeylSequence(itterations)

    s = 0xb5ad4ece
    x = 0
    w = 0

    for i = 1, itterations do

        x = x * x;
        w = w + s;
        x = x + w;
        x = math.bit_or((x / 2 ^ 5), (x * 2 ^ 5));

    end
end

-- > returns a Unique ID - upper limit is 565939020162275221
function getUniqueID()
    if not GG.GUID then GG.GUID = 1 end

    repeat GG.GUID = GG.GUID + 1 until Spring.ValidUnitID(GG.GUID) == false

    return GG.GUID
end

-- > finds the radian in a triangle where only the lenght of two sides are known
function triAngleTwoSided(LowerSide, OpposingSide)
    norm = math.sqrt(LowerSide * LowerSide + OpposingSide * OpposingSide)
    return math.atan2(LowerSide / norm, OpposingSide / norm)
end

function getCubeSphereRad(x, y, z)
    xy, xz, yz = x * y, x * z, y * z

    if xy > xz and xy > yz then return math.sqrt(x * x + y * y) end

    if xz > xy and xz > yz then return math.sqrt(x * x + z * z) end

    if yz > xy and yz > xz then return math.sqrt(y * y + z * z) end
end

function topsideRayTrace(pWorldx, pWorldy, Objects)
    default = -math.huge

    for _, obj in pairs(Objects) do
        if isPointInSquare(obj.pos, obj.p1, obj.p2, obj.p3, obj.p4) == true then
            return obj.pos.py
        end

    end

    return default
end

function getRandomInSet(T)
    return getRandomElementFromTable(T)
end

function isPointInSquare(P, s1, s2, s3, s4)
    return pointWithinTriangle(s1.x, s1.y, s2.x, s2.y, s3.x, s3.y, P.x, P.y) or
            pointWithinTriangle(s3.x, s3.y, s4.x, s4.y, s1.x, s1.y, P.x, P.y)
end


function holdsForAll(Var, fillterConditionString, ...)
    assert(fillterConditionString)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    if arg then
        for k, Val in pairs(arg) do
            if Var and Val then
                condFunction = loadstring(
                                   "return (" .. Var .. fillterConditionString ..
                                       Val .. ")")
                if not condFunction or condFunction() == false then
                    return
                end
            end
        end
        return true
    end
    return true
end
function makeNewAffirmativeMatrice()
    V = {
        [1] = 1,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 1,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 1,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 1
    }
    function V.Mul(other)
        V[1] = 0;
        V[2] = 0;
        V[3] = 0;
        V[4] = 0;
        V[5] = 0;
        V[6] = 0;
        V[7] = 0;
        V[8] = 0;
        V[9] = 0;
        V[10] = 0;
        V[11] = 0;
        V[12] = 0;
        V[13] = 0;
        V[14] = 0;
        V[15] = 0;
        V[16] = 1
    end

    -- TODO
    -- http://springrts.com/phpbb/viewtopic.php?f=21&t=32246
    return V
end

-- > produces a Rotation matrice around axis for a degree in affirmative Coordinates
function makeAffirmativeRotate(axis, deg_)
    V = makeNewAffirmativeMatrice()
    if axis == "x_axis" then
        V[6] = math.cos(-deg_)
        V[7] = -1 * math.sin(-deg_)
        V[10] = math.sin(-deg_)
        V[11] = math.cos(-deg_)

    elseif axis == "y_axis" then
        V[1] = math.cos(-deg_)
        V[3] = math.sin(-deg_)
        V[9] = -1 * math.sin(-deg_)
        V[11] = math.cos(-deg_)
    else
        V[1] = math.cos(-deg_)
        V[5] = math.sin(-deg_)
        V[2] = -1 * math.sin(-deg_)
        V[6] = math.cos(-deg_)
    end
    return V
end
-- >samples over a given Array around Point x,y, with the samplefunction 
function sample(NumericIndex, x, y, sampleFunction, factor)
    quadNumericIndex = {}
    if type(NumericIndex) == "number" then
        for i = -1 * NumericIndex, NumericIndex do
            for j = -1 * NumericIndex, NumericIndex do

                quadNumericIndex[i][j] = {x = i * factor, z = j * factor}
            end
        end
    else
        quadNumericIndex = NumericIndex
    end

    for i = 1, #quadNumericIndex, 1 do
        for j = 1, #quadNumericIndex, 1 do
            quadNumericIndex[i][j] = sampleFunction(
                                         x + quadNumericIndex[i][j].x, y +
                                             (quadNumericIndex[i][j].z or
                                                 quadNumericIndex[i][j].y))
        end
    end
    return quadNumericIndex
end

-- > returns the distance between two heigthvalues
function getGroundHeigthDistance(h1, h2) return distance(h1, 0, 0, h2, 0, 0) end

function pieceToPoint(pieceNumber)
    local reTab = {}

    reTab.x, reTab.y, reTab.z = Spring.GetUnitPiecePosition(unitID, pieceNumber)
    reTab.index = 1
    return reTab
end

-- > Builds the second norm Squareroot over x arguments
function normTwo(...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    sum = 0
    for k, v in pairs(arg) do sum = sum + v * v end
    return math.sqrt(sum)
end

-- > used to symbolically create shadder matrixes in lua.. fill in, calc, optimize, print out
function matrixLab()
    mA = {
        [1] = "cos(z)",
        [2] = "-sin(z)",
        [3] = "0",
        [4] = "sin(z)",
        [5] = "cos(z)",
        [6] = "0",
        [7] = "0",
        [8] = "0",
        [9] = "1"
    }
    mB = {
        [1] = "-1",
        [2] = "0",
        [3] = "0",
        [4] = "0",
        [5] = "cos(x)",
        [6] = "-sin(x)",
        [7] = "0",
        [8] = "sin(x)",
        [9] = "cos(x)"
    }
    mC = {
        [1] = "cos(y)",
        [2] = "0",
        [3] = "sin(y)",
        [4] = "0",
        [5] = "1",
        [6] = "0",
        [7] = "-sin(y)",
        [8] = "0",
        [9] = "cos(y)"
    }

    mD = MatrixBuilder3x3(MatrixBuilder3x3(mA, mB), mC)
    -- echoT(mD)
end

function getCircleIndex(index)
    if index == 1 then return -1, 0 end
    if index == 2 then return 0, 1 end
    if index == 3 then return 1, 0 end
    if index == 4 then return 0, -1 end
    assert(true==false)
end

function getFullCircleIndex(index)
    if index == 1 then return -1, 0 end
    if index == 2 then return -1, 1 end
    if index == 3 then return 0, 1 end
    if index == 4 then return 1, 1 end
    if index == 5 then return 1, 0 end
    if index == 6 then return 1, -1 end
    if index == 7 then return 0, -1 end
    if index == 8 then return -1, -1 end
    assert(true==false)
end

function mirrorMatriceXAxis(x, y, z)
    -- return 360-x,y,z*-1																																							

    x = ((-1 * math.cos(z)) * math.cos(y)) +
            ((-1 * math.sin(z) * -1 * math.sin(x)) * -1 * math.sin(y)) * x +
            ((-1 * math.sin(z) * math.cos(x))) * y +
            ((-1 * math.cos(z)) * math.sin(y)) +
            ((-1 * math.sin(z) * -1 * math.sin(x)) * math.cos(y)) * z

    y = ((-1 * math.sin(z)) * math.cos(y)) +
            ((math.cos(z) * -1 * math.sin(x)) * -1 * math.sin(y)) * x +
            ((math.cos(z) * math.cos(x))) * y +
            ((-1 * math.sin(z)) * math.sin(y)) +
            ((math.cos(z) * -1 * math.sin(x)) * math.cos(y)) * z

    z = ((math.cos(x)) * -1 * math.sin(y)) * x + ((math.sin(x))) * y +
            ((math.cos(x)) * math.cos(y)) * z
    return x, y, z
end

function midVector(PointA, PointB)
    PointA.x, PointA.y, PointA.z = PointA.x + PointB.x, PointA.y + PointB.y,
                                   PointA.z + PointB.z
    return divVector(PointA, 2)
end

function checkCenterPastPoint(MidPoint, GatePoint, PrevGatePoint)

    OrgPoint = subVector(GatePoint, PrevGatePoint)
    assert(OrgPoint)
    MirrorPointV = mulVector(OrgPoint, -1)

    -- if distance to PrevGatePoint < then distance to mirrored Point
    if norm2Vector(subVector(MirrorPointV, MidPoint)) >=
        norm2Vector(subVector(OrgPoint, MidPoint)) then
        return true
    else
        return false
    end
end

function absVec(vec)
    vec.x = math.abs(vec.x)
    vec.y = math.abs(vec.y)
    vec.z = math.abs(vec.z)
    return vec
end

function eqVec(vecA, vecB)
    return vecA.x == vecB.x and vecA.y == vecB.y and vecA.z == vecB.z
end

-- >Counts the digits of a number
function getDigits(number)
    digit = 1
    if number < 0 then digit = 2 end
    while math.abs(number) > 10 do
        number = number / 10
        digit = digit + 1
    end
    return digit
end

-- > Transfers a World Position into Unit Space
function worldPosToLocPos(owpX, owpY, owpZ, wpX, wpY, wpZ)
    return wpX - owpX, wpY - owpY, wpZ - owpZ
end

-- > returns true if point is within range -returns false if it is on the outside
local previousResult
local previousCubic
local rangeOfOld = -1

-- > faster way of finding out wether a point is within a circle
function isWithinCircle(circleRange, xCoord, zCoord)
    newCubic = 0
    if rangeOfOld == circleRange then
        newCubic = previousCubic
    else
        newCubic = 0.7071067811865475 * circleRange
        previousCubic = newCubic
    end

    negCircleRange = -1 * circleRange

    -- checking the most comon cases |Coords Outside the Circlebox
    if xCoord > circleRange or xCoord < negCircleRange then return false end

    if zCoord > circleRange or zCoord < negCircleRange then return false end

    negNewCubic = -1 * newCubic

    -- checking everything within the circle box
    if (xCoord < newCubic and xCoord > negNewCubic) and
        (zCoord < newCubic and zCoord > negNewCubic) then return true end

    -- very few cases make it here.. to the classic, bad old range compare
    if math.sqrt(xCoord ^ 2 + zCoord ^ 2) < circleRange then
        return true
    else
        return false
    end
end

-- >Function estimates the relative Position of a Piece to another by comparing ther Coordinates
function piecePositionComperator(myPos, PiecePos, cubicsize)

    -- [1]=--front
    -- [2]=--rear
    -- [3]=--side left
    -- [4]=	--side right
    -- [5]=	--up
    -- [6]=	--low

    if withinRange(myPos.y, PiecePos.y, cubicsize) == true then

        if withinRange(myPos.x, PiecPos.x, cubicsize) == true then -- Piece is on the side
            if myPos.z > piecePos.z then
                return 3
            else
                return 4
            end
        else -- Piece is either in front or behind
            if myPos.x > piecePos.x then
                return 2
            else
                return 1
            end
        end
    else -- pos is either above or below the layer 
        if myPos.y > PiecePos.y then
            return 6
        else
            return 5
        end
    end
end

-- > Checks wether a Point is within a six sided polygon
function sixPointInsideDetAlgo(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6,
                               xPoint, yPoint)
    detSum = 0
    for i = 0, 6, 1 do
        tempdet = 0.5 *
                      ((x((i + 1) % 7)) * (y((i + 2) % 7)) + (x((i + 2) % 7)) *
                          (y((i + 1) % 7)))
        detSum = detSum + tempdet
    end

    if detSum >= 0 then return false end

    return true
end

-- >Rotates a point around another Point
function rotationMatrix(x, y, zx, zy, degInRad)
    x = x - zx
    y = y - zy
    tempX = (math.cos(degInRad) * x) + ((-1.0 * math.sin(degInRad)) * y)
    y = (math.sin(degInRad) * x + (math.cos(degInRad)) * y)
    x = tempX + zx
    y = y + zy
    return x, y
end

-- >Checks wether a point is within a triangle
function pointWithinTriangle(x1, y1, x2, y2, x3, y3, xt, yt)
    polygon = {
        [1] = {x = x1, y = y1},
        [2] = {x = x2, y = y2},
        [3] = {x = x3, y = y3}
    }

    point = {x = xt, y = yt}

    local oddNodes = false
    local j = #polygon
    for i = 1, #polygon do
        if (polygon[i].y < point.y and polygon[j].y >= point.y or polygon[j].y <
            point.y and polygon[i].y >= point.y) then
            if (polygon[i].x + (point.y - polygon[i].y) /
                (polygon[j].y - polygon[i].y) * (polygon[j].x - polygon[i].x) <
                point.x) then oddNodes = not oddNodes; end
        end
        j = i;
    end

    return oddNodes
end

function distanceToLine(P1, P2, APos)
    return math.abs((P2.y - P1.y) * APos.x - (P2.x - P1.x) * APos.y +
                        (P2.x * P1.y) - (P2.y * P1.x)) /
               math.sqrt((P2.y - P1.y) * (P2.y - P1.y) + (P2.x - P1.x) *
                             (P2.x - P1.x));
end
-- >returns the absolute distance on negative and positive values
function absDistance(valA, valB) 
    if Signum(valA) == Signum(valB) then
        return math.abs(math.abs(valA) - math.abs(valB))
    else
        return math.abs(valA) + math.abs(valB)
    end
end

-- functions
-- >returns the Negated Axis
function mirror(value)
    value = -1 * value
    return value
end

function normalizeVec(pVec)
    avg = math.sqrt(pVec.x ^ 2 + pVec.y ^ 2 + pVec.z ^ 2)
    return {x = pVec.x / avg, y = pVec.y / avg, z = pVec.z / avg}
end

-- >returns the 2 norm of a vector
function distance(x, y, z, xa, ya, za)
    if not x or not y then
        echo("No valid value given to distance")
        return nil
    end

    if not z then
        if x.x then
            return distance(x.x, x.y, x.z, y.x, y.y, y.z)
        else
            return distance(x[1], x[2], x[3], y[1], y[2], y[3])
        end
    end

    if xa ~= nil and ya ~= nil and za ~= nil then
        return math.sqrt((x - xa) ^ 2 + (y - ya) ^ 2 + (z - za) ^ 2)
    elseif x ~= nil and y ~= nil and z ~= nil then
        return math.sqrt(x * x + y * y + z * z)
    else
        return math.sqrt((x - y) ^ 2)
    end
end

function getUnitVariable(unitID, varname)
    env = Spring.UnitScript.GetScriptEnv(unitID)

    if env and env.varname then return env.varname end
end

function setParent(unitID, child)
    env = Spring.UnitScript.GetScriptEnv(child)

    if env then env.parent = unitID end
end

function distanceUnitToPoint(ed, x, y, z)
    ex, ey, ez = Spring.GetUnitPosition(ed)
    if ex then
        return distance(ex, ey, ez, x, y, z)
    else
        return 0
    end

end

-- > distance piece to piece in a unit
function distancePieceToPiece(unitID, pieceA, pieceB)
    ax, ay, az = Spring.GetUnitPiecePosDir(unitID, pieceA)
    ex, ey, ez = Spring.GetUnitPiecePosDir(unitID, pieceB)
    return distance(ex, ey, ez, ax, ay, az)
end

-- > distance from a UnitPiece to another Units Center
function distancePieceToUnit(unitID, Piece, targetID)
    ex, ey, ez = Spring.GetUnitPiecePosDir(unitID, Piece)
    tx, ty, tz = Spring.GetUnitPosition(targetID)
    return distance(ex, ey, ez, tx, ty, tz)
end

-- > get two unit distVector
function vectorUnitToUnit(idA, idB)
    x, y, z = Spring.GetUnitPosition(idA)
    xb, yb, zb = Spring.GetUnitPosition(idB)

    return Vector:new(x - xb, y - yb, z - zb)
end

function distanceOfUnitToPoint(ud, x, y, z)
    if not y and x.x then x, y, z = x.x, x.y, x.z end

    if not ud then return math.huge end

    px, py, pz = Spring.GetUnitPosition(ud)
    ux, uy, uz = px - x, py - y, pz - z
    return math.sqrt(ux ^ 2 + uy ^ 2 + uz ^ 2), px, py, pz
end

-- >returns the Distance between two units
function distancePosToUnit(xa,ya,za , idB)
      xb, yb, zb = Spring.GetUnitPosition(idB)
    return math.sqrt((xa-xb)^2 + (ya-yb)^2 + (za-zb)^2)
end

-- >returns the Distance between two units
function distanceUnitToUnit(idA, idB)

    if lib_boolDebug == true then
        if (not idA or type(idA) ~= "number") then
            echo("Not existing idA or not a number");
            return nil;
        end
        if (not idB or type(idB) ~= "number") then
            echo("Not existing idB or not a number");
            return nil;
        end
        if Spring.ValidUnitID(idA) == false then
            echo("distanceUnitToUnit::idA Not a valid UnitID");
            return nil;
        end
        if Spring.ValidUnitID(idB) == false then
            echo("distanceUnitToUnit::idB Not a valid UnitID");
            return nil;
        end
    end

    xa, ya, za = Spring.GetUnitPosition(idA)
    xb, yb, zb = Spring.GetUnitPosition(idB)

    if not xa then
        return math.huge
    end
    if not xb  then
        return math.huge
    end
    return math.sqrt((xa-xb)^2 + (ya-yb)^2 + (za-zb)^2)
end

-- > gives a close hunch at the distance and avoids expensive sqrt math by using herons Algo
function approxDist(x, y, z, digitsPrecision)
    resultSoFar = x * x + y * y + z * z
    lastResult = resultSoFar
    for i = 1, digitsPrecision do
        lastResult = (lastResult + resultSoFar / lastResult) / 2
    end
    return lastResult
end

-- > increment a value 
function inc(value) return value + 1 end

-- > decrement a value 
function dec(value) return value - 1 end

function equal(valA, valB, treshold)
    return valA < (valB + treshold) and valA > (valB - treshold)
end

function getAngleFromCoordinates(x, z)
    -- Compute the angle
    return math.atan2(z, x) -- Using atan2 to handle all quadrants
end
-- ======================================================================================
-- Section : Code Generation 
-- ======================================================================================
-- > Symbolic multiplication
function eraNonArgMul(A, B)
    if A == "0" or B == "0" or A == "" or B == "" then
        return ""
    else
        return "(" .. A .. "*" .. B .. ")"
    end
end

-- >Symbolic addition
function eraNonArgAdd(A, B)
    if A == "0" or A == "" and B ~= "0" and B ~= "" then return B end
    if B == "0" or B == "" and A ~= "0" and A ~= "" then return A end
    return "(" .. A .. "+" .. B .. ")"
end

-- >Build a symbolic 
function MatrixBuilder3x3(A, B)
    return {
        [1] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[1], B[1]),
                                        eraNonArgMul(A[2], B[4])),
                           eraNonArgMul(A[3], B[7])),
        [2] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[1], B[2]),
                                        eraNonArgMul(A[2], B[5])),
                           eraNonArgMul(A[3], B[8])),
        [3] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[1], B[3]),
                                        eraNonArgMul(A[2], B[6])),
                           eraNonArgMul(A[3], B[9])),
        [4] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[4], B[1]),
                                        eraNonArgMul(A[5], B[4])),
                           eraNonArgMul(A[6], B[7])),
        [5] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[4], B[2]),
                                        eraNonArgMul(A[5], B[5])),
                           eraNonArgMul(A[6], B[8])),
        [6] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[4], B[3]),
                                        eraNonArgMul(A[5], B[6])),
                           eraNonArgMul(A[6], B[9])),
        [7] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[7], B[1]),
                                        eraNonArgMul(A[8], B[4])),
                           eraNonArgMul(A[9], B[7])),
        [8] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[7], B[2]),
                                        eraNonArgMul(A[8], B[5])),
                           eraNonArgMul(A[9], B[8])),
        [9] = eraNonArgAdd(eraNonArgAdd(eraNonArgMul(A[7], B[3]),
                                        eraNonArgMul(A[8], B[6])),
                           eraNonArgMul(A[9], B[9]))
    }
end

-- ======================================================================================
-- Section : String Operations
-- ======================================================================================
function getFileNameFromPath(path)
    return path:match("([^/\\]+)$")
end

-- > Displays Text at UnitPos Thread
-- >> Expects a table with Line "Text", a speaker Name "Text", a DelayByLine "Numeric", a Alpha from wich it will start decaying "Numeric"
function say(LineNameTimeT, timeToShowMs, NameColour, TextColour, OptionString,
             UnitID)
    assert(LineNameTimeT)
    timeToShowFrames = math.ceil((timeToShowMs / 1000) * 30)

    px, py, pz = 0, 0, 0
    if not UnitID or Spring.ValidUnitID(UnitID) == false then
        echo("Im out 1")
        return
    end

    if type(LineNameTimeT) == "string" then
        Tables = {}
        Tables[1] = {
            name = "",
            line = LineNameTimeT,
            DelayByLine = 500,
            Alpha = 1.0
        }
        LineNameTimeT = Tables
    end

    -- catching the case that there is not direct Unit speaking
    if not UnitID or type(UnitID) == "string" then
        Spring.Echo(LineNameTimeT[1].name .. ": " .. LineNameTimeT[i].line)
        if not LineNameTimeT[2].line then return end
        for i = 1, #LineNameTimeT, 1 do
            for j = 1, #LineNameTimeT[i], 1 do
                echo(LineNameTimeT[i][j].line)
            end
        end
        echo("Im out 2")
        return
    end

    local spGetUnitPosition = Spring.GetUnitPosition
    if not GG.Dialog then GG.Dialog = {} end

    lineBuilder = ""
    spaceString = stringBuilder(string.len(LineNameTimeT[1].name .. ": " or 5),
                                " ")

    GG.Dialog[UnitID] = {}
    lineBuilder = lineBuilder .. LineNameTimeT[1].name .. ": " ..
                      LineNameTimeT[1].line .. "\n"

    for i = 2, #LineNameTimeT, 1 do
        lineBuilder = spaceString .. LineNameTimeT[i].line .. "\n"
    end

    -- Sleep Time till next line
    _, unitheigth, _ = Spring.GetUnitCollisionVolumeData(UnitID)
    GG.Dialog[UnitID][#GG.Dialog[UnitID] + 1] =
        {
            frames = timeToShowFrames,
            line = lineBuilder,
            lifetime = timeToShowFrames,
            unitheigth = unitheigth,
            color = TextColour
        }

end

-- sums up a strings byte values
function hashString(str, modulus)
    x = 0
    for i = 1, string.len(str) do x = x + str:byte(i) end
    modulus = modulus or (x + 1)
    return x % modulus
end

function getMapHash(modulus)
    accumulated = 0
    mapName = Game.mapName
    mapNameLength = string.len(mapName)

    for i=1, mapNameLength do
        accumulated = accumulated + string.byte(mapName,i)
    end

  accumulated = accumulated + Game.mapSizeX
  accumulated = accumulated + Game.mapSizeZ
  if not modulus then modulus = accumulated + 1 end
  return math.ceil(accumulated) % modulus
end

function get_line_intersection(p0_x, p0_y, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)

    s1_x = p1_x - p0_x;
    s1_y = p1_y - p0_y;
    s2_x = p3_x - p2_x;
    s2_y = p3_y - p2_y;

    s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) /
            (-s2_x * s1_y + s1_x * s2_y);
    t = (s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) /
            (-s2_x * s1_y + s1_x * s2_y);

    if (s >= 0 and s <= 1 and t >= 0 and t <= 1) then
        -- // Collision detected

        i_x = p0_x + (t * s1_x);
        i_y = p0_y + (t * s1_y);
        return i_x, i_y
    end
    return
    -- return 0; // No collision
end

-- >prepares large speaches for the release to the world
function prepSpeach(Speach, Names, Limits, Alphas, DefaultSleepBylines)
    -- if only Speach 
    if Speach and not Names and not Limits then return {Speach = Speach} end

    Name = Names or "Dramatis Persona"
    Limit = Limits or 42
    Alpha = Alphas or 0.9
    DefaultSleepByline = DefaultSleepBylines or 750

    T = {}
    itterator = 1
    lineend = Limit
    size = string.len(Speach) or #Speach or Limit
    assert(size, "Size does matter")
    assert(Speach and type(Speach) == "string", "Speach not of type string",
           Speach)
    assert(lineend and type(lineend) == "number", "Limit not a number", Limit)
    assert(size and type(size) == "number", "Limit not a number", Limit)

    if string.len(Speach) < Limit then

        subtable = {
            line = Speach,
            alpha = Alpha,
            name = Name,
            DelayByLine = DefaultSleepByline
        }
        retTable = {}
        retTable[1] = subtable
        return retTable
    end

    whitespace = "%s"
    while lineend < size do

        lineend = string.find(Speach, whitespace, itterator + Limit) or
                      string.len(Speach)
        subString = string.sub(Speach, itterator, lineend)
        Spring.Echo(subString)
        if subString then
            T[#T + 1] = {
                line = subString,
                alpha = Alpha,
                name = Name,
                DelayByLine = DefaultSleepByline
            }
        else
            break
        end

        if not lineend then
            break
        else
            itterator = Limit + 1
        end
        assert(lineend)
        assert(size)
    end

    return T, true
end


function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end


function addAscii(str)
    local l_Result = 0
    for i = 1, #str do l_Result = inc(l_Result, string.byte(str, i)) end
    return l_Result
end

-- > creates a table of pieces with name
function makeTableOfNames(name, startnr, endnr)
    T = {}
    for i = startnr, endnr, 1 do T[#T + 1] = name .. i end
    return T
end

-- > chreates from a examplestring a string of length
function stringBuilder(length, sign)
    str = ""
    for i = 1, length do str = str .. sign end
    return str
end

function trim(s) return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)' end


function randHide(T)
    foreach(T, function(id)
        if math.random(0, 1) == 1 then
            Show(id)
        else
            Hide(id)
        end
    end)
end
-- ======================================================================================
-- Section: Debug Tools 
-- ======================================================================================



--> echos out once per frame
function echoBurst(stringToEcho)
if not GG.Burst then GG.Burst = {} end
gameFrame = Spring.GetGameFrame()

if not GG.Burst[gameFrame] then
	if (GG.Burst[gameFrame -1]) then
		echoT(GG.Burst[gameFrame -1])
		GG.Burst[gameFrame -1] = nil
		end
	GG.Burst[gameFrame] = {}
end
GG.Burst[gameFrame][#GG.Burst[gameFrame]+1] = stringToEcho
end

function echoEnter(state)
    Spring.Echo("Enter: "..state)
end


function locationstring(unitID)
    local x,y,z =Spring.GetUnitPosition(unitID)
    return " at( x:"..x.." y:"..y.." z:"..z..")"
end

boolBurst= false
-- > echos out strings
function echo(stringToEcho, ...)
	if boolBurst then
		return echoBurst(stringToEcho, ...)	 
	end
	
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    if stringToEcho then 
		Spring.Echo(toString(stringToEcho));
    end
 
    if arg then
        for k, v in pairs(arg) do
            if k then                
                keyString = "[" .. toString(k) .. "]"
                if type(v) == "table" then
                    Spring.Echo(keyString .. "{")
                    echoT(v)
                    Spring.Echo("}")
                else
                    if (keyString ~= "[n]") then
                        Spring.Echo(keyString .. "»" .. toString(v))                                                
                    end
                end
            end
        end
    end
end

function echoTypeTable(t, UnitDefs)
    tableString = "{"
    for k,v in pairs(t) do
        if UnitDefs[k] then
        pair = UnitDefs[k].name .."->".. k
        tableString = tableString .."\n"..pair
        end
    end
echo(tableString.."\n}")
end

function conditionalEcho(active, message )
    if active then
        echo(message)
    end
end

-- ======================================================================================
-- Section: Tableoperators 
-- ======================================================================================

function isInTable(T, val)
    for i=1, #T do
        if T[i] == val then return true end
    end
    return false
end 

-- ======================================================================================
-- Section: Random 
-- ======================================================================================
function getDeterministicRandom(hash, maximum)
    return hash % maximum
end

function getDermenisticChance(unitID, upperLimit)
    value = getDeterministicUnitHash(unitID)
    return (value % 100) < upperLimit
end

function SetSharedOneTimeResult(key,  data)
    if not GG.SharedResult then GG.SharedResult = {} end
    if not GG.SharedResult[key] then
       GG.SharedResult[key] = data
    end 
end

function GetSharedOneTimeResult(key)
    if not GG.SharedResult then GG.SharedResult = {} end
    return GG.SharedResult[key]
end

function getDeterministicStationaryUnitHash(unitID )
    defID = Spring.GetUnitDefID(unitID)
    x,y,z = Spring.GetUnitPosition(unitID)
    return math.ceil(x) + math.ceil(z) + defID
end

function getDeterministicUnitHash(unitID )
    defID = Spring.GetUnitDefID(unitID)
    key = "UnitDefHash"..defID
    sharedResult = GetSharedOneTimeResult(key)
    if sharedResult then return sharedResult end
    deterministicUnitHash = defID
    for k,v in pairs (UnitDefs[defID]) do
        defMemberType = type(v)
        if defMemberType == "number" then
            deterministicUnitHash = deterministicUnitHash + v
        end
        if defMemberType == "string" then
            deterministicUnitHash = deterministicUnitHash + hashString(v)
        end
    end
    SetSharedOneTimeResult(key, deterministicUnitHash)
    return deterministicUnitHash
end



function getSafeRandom(T, default)
    if not T then 
		return default, nil 
	end 

    if count(T) < 1 then 
		return default, nil 
	end

	--Just one huge WTF to lua, in order to have a working random one needs to permanently copy tables
    local keyset = {}
    for k in pairs(T) do
        table.insert(keyset, k)
    end
	
	if #keyset == 1 then 
		return T[keyset[1]], keyset[1] 
	end
	
-- now you can reliably return a random key
    rkey = keyset[math.random(1,#keyset)]
    return T[rkey], rkey
end

function getRandomElementRing(T)
    dice = sanitizeRandom(1, #T)
    for i = dice, #T do if T[i] then return T[i] end end

    for i = 1, dice do if T[i] then return T[i] end end
    echo("getRandomElementRing: No elements in table")
    assert(not true)
end

function sanitizeRandom(lowerBound, UpperBound)
    if lowerBound >= UpperBound then return lowerBound end

    return math.random(lowerBound, UpperBound)
end

function addInputToSeed(...)
    l_result = 0

    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end

    if not arg then return l_result end

    for _, v in pairs(arg) do
        l_argType = type(v)

        if l_argType == "number" then
            l_result = math.bit_xor(l_result, v)
        end
        if l_argType == "table" then l_result = math.bit_xor(l_result, v) end
        if l_argType == "boolean" then
            if v == true then
                l_result = math.bit_xor(l_result, 1);
            else
                l_result = math.bit_xor(l_result, -1);
            end
        end
        if l_argType == "string" then
            l_result = inc(l_result, addAscii(v))
        end
    end

    return l_result

end

-- > Seed random
function seedRandom()
    seed = 0
    l_playerList = Spring.GetPlayerList()
    for i = 1, #l_playerList do
        name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country, rank, customPlayerKeys =
            Spring.GetPlayerInfo(l_playerList[i])
    end
    seed = math.bit_xor(seed,
                        addInputToSeed(name, active, spectator, teamID,
                                       allyTeamID, pingTime, cpuUsage, country,
                                       rank, customPlayerKeys))

    teamList = Spring.GetTeamList()
    for i = 1, #teamList do
        x, y, z = Spring.GetTeamStartPosition(teamList[i])
        seed = math.bit_xor(seed, x, y, z)
    end

    dirX, dirY, dirZ, strength, normDirX, normDirY, normDirZ = Spring.GetWind()
    seed = math.bit_xor(seed, addInputToSeed(dirX, dirY, dirZ, strength,
                                             normDirX, normDirY, normDirZ))
    seed = math.bit_xor(seed, middleSquareWeylSequence(seed))

    math.randomseed(seed)

end

-- > Execute Random Function in Table
function randTableFunc(Table)
    Table = shuffleT(Table)
    randElement = math.random(1, table.getn(Table))
    return Table[randElement]()
end

function deterministicElement(nr, Table)
    if #Table == 1 then return Table[1] end

    return Table[(nr % #Table) + 1]
end

function randT(Table)
    sizeOf = #Table
    if sizeOf == 0 then
        if count(Table) > 0 then return randDict(Table) end
        return
    end
    
    if sizeOf == 1 then return Table[1] end

    return Table[math.random(1, #Table)]
end

--"Fair" pseudo random, that becomes fair by having a higher chance to roll true the longer you miss
function fairRandom(identifier, diffDistance) -- chance to get true
    if not GG.FairRandom then GG.FairRandom = {} end
    if not GG.FairRandom[identifier] or GG.FairRandom[identifier].numberOfCalls ==
        0 then
        GG.FairRandom[identifier] = {numberOfCalls = 0, pro = 0, contra = 0}
    end

    diff = absDistance(GG.FairRandom[identifier].pro,
                       GG.FairRandom[identifier].contra)
    GG.FairRandom[identifier].numberOfCalls =
        GG.FairRandom[identifier].numberOfCalls + 1

    if diff > diffDistance then
        if GG.FairRandom[identifier].pro <= GG.FairRandom[identifier].contra then
            GG.FairRandom[identifier].pro = GG.FairRandom[identifier].pro + 1
            return true
        else
            GG.FairRandom[identifier].contra =
                GG.FairRandom[identifier].contra + 1
            return false
        end

    else

        minimum = math.min(GG.FairRandom[identifier].contra,
                           GG.FairRandom[identifier].pro)
        maximum = math.max(GG.FairRandom[identifier].contra,
                           GG.FairRandom[identifier].pro)

        if minimum == maximum then

            if math.random(0, 10) > 5 then
                GG.FairRandom[identifier].pro =
                    GG.FairRandom[identifier].pro + 1
                return true
            else
                GG.FairRandom[identifier].contra =
                    GG.FairRandom[identifier].contra + 1
                return false
            end
        end

        bResult = (math.random(0, maximum - minimum)) > diff / 2

        if bResult == true then
            GG.FairRandom[identifier].pro = GG.FairRandom[identifier].pro + 1
            return true
        else
            GG.FairRandom[identifier].contra =
                GG.FairRandom[identifier].contra + 1
            return false
        end
    end
end

-- >a Fairer random Function that selects of a table everyNthElement at least candidatesInInterval Number many elements
function randFairT(T, candidatesInInterval, everyNthElement)
    Ta = {}
    if candidatesInInterval >= everyNthElement then
        echo("randFairT error");
        return {}
    end

    for i = 1, #T, everyNthElement do
        internalCount = 0
        for j = i, i + everyNthElement do
            if randChance((internalCount / candidatesInInterval) * 100) == true then
                Ta[#Ta + 1] = T[j]
                internalCount = internalCount + 1
            end
        end
    end
    return Ta
end

function randChance(likeLihoodInPercent)
    return (math.random(1, 100) <= likeLihoodInPercent)
end

-- > returns a randomized Signum
function randSign()
    if math.random(0, 1) == 1 then
        return 1
    else
        return -1
    end
end

-- >Returns randomized Boolean
function maRa() return math.random(0, 1) == 1 end

-- >Returns trinary logic result
function raNil()
    if math.random(0, 1) == 1 then
        return maRa()
    else
        return
    end
end

-- >Randomizes a Vector
function randVec(boolStayPositive)

    if boolStayPositive and boolStayPositive == true then
        return {
            x = math.random(0, 1000) / 1000,
            y = math.random(0, 1000) / 1000,
            z = math.random(0, 1000) / 1000
        }
    else
        return {
            x = math.random(-1000, 1000) / 1000,
            y = math.random(-1000, 1000) / 1000,
            z = math.random(-1000, 1000) / 1000
        }
    end
end

-- >Sanitizing RandomIntervall -cause brando has electrolytes
function cbrandoVal(LowLimit, UpLimit)
    upLim = UpLimit or LowLimit + 1
    if LowLimit >= upLim then LowLimit = upLim - 1 end
    return math.ceil(math.random(LowLimit, UpLimit))
end

-- >Sanitizing RandomIntervall -cause brando has electrolytes
function brandoVal(LowLimit, UpLimit)
    upLim = UpLimit or LowLimit + 1
    if LowLimit >= upLim then LowLimit = upLim - 1 end
    return math.random(LowLimit, UpLimit)
end

function iRand(start, fin)
    if not fin or fin < start then fin = start + 1 end

    return math.ceil(sanitizeRandom(start, fin))
end

-- > Executes a random Function from a table of functions
function randFunc(...)
    local arg = {...}
    if not arg then return end
    index = sanitizeRandom(1, #arg)
    return arg[index]()
end

-- ======================================================================================
-- Arithmetic operations
-- ======================================================================================

-- >gets Signum of a number
function Signum(val) return math.abs(val) / val end

-- > takes the average over a number of argument
function average(...)
    local arg = table.pack(...)
    if not arg then return nil end
    sum = 0
    it = 0
    for k, v in pairs(arg) do
        sum = sum + v
        it = it + 1
    end
    return sum / it
end

-- > Converts to points, to a degree in Radians
function convPointsToRad(ox, oz, bx, bz)
    if not bx then -- orgin cleaned point
        return math.atan2(ox, oz)
    else
        bx = bx - ox
        bz = bz - oz
        return math.atan2(bx, bz)
    end
end

-- > clamp Disregarding Signum
function clampMaxSign(value, Max)
    if math.abs(value) > Max then
        signum = math.abs(value) / value
        return Max * signum
    else
        return value
    end
end

-- > clamps a value between a lower and a upper value
function clamp(val, low, up)
    if val > up then return up end
    if val < low then return low end
    return val
end

-- > clamps between a lower value and modulu operates on the upper value
function clampMod(val, low, up)
    if val > up then return (val % up) + 1 end
    if val < low then return low end
    return val
end

-- > inverted parrabel from 1 to 0
function Parabel(x, A, B, yOffset, xShift, invert)
    invSign = -1
    xShift = xShift or 0

    if invert == false then invSign = 1 end

    return invSign * (A * ((x + xShift) ^ 2) + B) + yOffset
end

function ANHINEG(value)
    if value < 0 then value = M(value) end
    return value
end

function PP(value)
    value = value + 1
    return value
end

-- Bit Operators -Great Toys for the BigBoys
function SR(value, shift)
    reSulTan = math.bit_bits(value, shift)
    return reSulTan
end

function SL(value, shift)
    reSulTan = math.bit_bits(value, M(shift))
    return reSulTan
end

function AND(value1, value2)
    reSulTan = math.bit_and(value1, value2)
    return reSulTan
end

function OR(value1, value2)
    reSulTan = math.bit_or(value1, value2)
    return reSulTan
end

function XOR(value1, value2)
    reSulTan = math.bit_xor(value1, value2)
    return reSulTan
end

function INV(value)
    reSulTanane = math.bit_inv(value)
    return value
end

-- > increments in a ring
function ringcrement(index, upValue, LowValue)

    if index + 1 > upValue then
        index = LowValue;
        return index
    end

    return index + 1
end

-- > takes a given position and the dir of a surface and calculates the vector by which the vector is reflectd,
-- if fall in angle == escape angle
function mirrorAngle(nX, nY, nZ, dirX, dirY, dirZ)
    max = math.max(dirX, math.max(dirY, dirZ))
    dirX, dirY, dirZ = dirX / max, dirY / max, dirZ / max
    max = math.max(nX, math.max(nY, nZ))
    nX, nY, nZ = nX / max, nY / max, nZ / max

    a = math.atan2(nY, nZ) -- alpha	x_axis
    b = math.atan2(nX, nY) -- beta	z_axis

    ca = math.cos(a)
    cma = math.cos(-1 * a)
    ncma = cma * -1
    sa = math.sin(a)
    sma = math.sin(-1 * a)
    nsma = sma * -1

    cb = math.cos(b)
    cmb = math.cos(-1 * b)
    ncmb = cmb * -1
    sb = math.sin(b)
    smb = math.sin(-1 * b)
    nsmb = smb * -1
    -- -c(a)*c(-a)+s(a)*s(-a)																		|-c(a)-s(-a)+ s(a)*c(-a)																	|0				|0
    -- c(-b)*[(c(b)*s(a)*c(-a)+c(b)*c(a)*s(-a))]+-s(-b)*[(-s(a)*s(b)*c(-a))+(-s(b)*c(a)*s(-a))]		|c(-b)*[c(b)*s(a)*-s(-a) + c(b)*c(a)*c(-a) ]+-s(-b)*[-s(a)*s(b)*-s(-a)+(-s(b)*c(a)*c(-a)]	|-s(b)*s(-b)	|0
    -- s(-b)*[c(b)*s(a)*c(-a)+c(b)*c(a)*s(-a)	]+ c(-b) *[ -s(a)*s(b)*c(-a) + (-s(b)*c(a)*s(-a)]	|s(-b)*[c(b)*s(a)*-s(-a) + c(b)*c(a)*c(-a) ]+c(-b)*[-s(a)*s(b)*-s(-a)+(-s(b)*c(a)*c(-a)]	|-c(b)*c(-b)	|0

    dirX = dirX * ncma * cma + sa * sma + dirY * ncma * -1 * sma + sa * cma
    dirY = dirX * cmb * ((cb * sa * cma + cb * ca * sma)) + -1 * smb *
               ((-1 * sa * sb * cma) + (-1 * sb * ca * sma)) + dirY * cmb *
               (cb * sa * -1 * sma + cb * ca * cma) +
               (-1 * smb * -1 * sa * sb * -1 * sma + -1 * sb * ca * cma) + dirZ *
               -1 * sb * smb
    dirZ = dirX * smb * (cb * sa * cma + cb * ca * sma) + cmb *
               (-1 * sa * sb * cma + (-1 * sb * ca * sma)) + dirY * smb *
               (cb * sa * -1 * sma + cb * ca * cma + cmb * -1 * sa * sb * -1 *
                   sma + (-1 * sb * ca * cma)) + dirZ * -1 * cb * cmb

    return dirX, dirY, dirZ
end

-- >RotationMatrice for allready Normalized Values
function Rotate(x, z, Rad)
    if not Rad then return end
    sinus = math.sin(Rad)
    cosinus = math.cos(Rad)

    return x * cosinus + z * -sinus, x * sinus + z * cosinus
end

-- >multiplies a 3x1 Vector with a 3x3 Matrice
function vec3MulMatrice3x3(vec, Matrice)
    return {
        x = Matrice[1][1] * vec.x + Matrice[1][2] * vec.y,
        Matrice[1][3] * vec.z,
        y = Matrice[2][1] * vec.x + Matrice[2][2] * vec.y,
        Matrice[2][3] * vec.z,
        z = Matrice[3][1] * vec.x + Matrice[3][2] * vec.y,
        Matrice[3][3] * vec.z
    }
end

-- RawMatrice
-- {
-- [1]={[1]=,[2]=,[3]=,},
-- [2]={[1]=,[2]=,[3]=,},
-- [3]={[1]=,[2]=,[3]=,}
-- }
function YRotate(Deg)
    return {
        [1] = {[1] = math.cos(Deg), [2] = 0, [3] = math.sin(Deg) * -1},
        [2] = {[1] = 0, [2] = 1, [3] = 0},
        [3] = {[1] = math.sin(Deg), [2] = 0, [3] = math.cos(Deg)}
    }
end

function XRotate(Deg)
    return {
        [1] = {[1] = 1, [2] = 0, [3] = 0},
        [2] = {[1] = 0, [2] = math.cos(Deg), [3] = math.sin(Deg) * -1},
        [3] = {[1] = 0, [2] = math.sin(Deg), [3] = math.cos(Deg)}
    }
end

function ZRotate(Deg)
    return {
        [1] = {[1] = math.cos(Deg), [2] = math.sin(Deg) * -1, [3] = 0},
        [2] = {[1] = math.sin(Deg), [2] = math.cos(Deg), [3] = 0},
        [3] = {[1] = 0, [2] = 0, [3] = 1}
    }
end

function rotateUnitAroundUnit(centerID, rotatedUnit, degree)
    ax, ay, az = Spring.GetUnitPosition(centerID)
    bx, by, bz = Spring.GetUnitPosition(rotatedUnit)
    vx, vz = bx - ax, bz - az
    vx, vz = Rotate(vx, vz, math.rad(degree))

    Spring.SetUnitPosition(rotatedUnit, ax + vx, az + vz)
end

function rotateVecDegX(vec, DegX)
    tempDegRotY = math.asin(vec.x / (math.sqrt(vec.x ^ 2 + vec.z ^ 2)))

    -- y-axis
    vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotY * -1))

    tempDegRotZ = math.asin(vec.y / math.sqrt(vec.x ^ 2 + vec.z ^ 2))
    -- z-axis
    vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotZ * -1))
    -- actual Rotation around the x-axis
    vec = vec3MulMatrice3x3(vec, XRotate(DegX))

    -- undo z-axis
    vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotZ))

    -- undo y-axis
    vec = vec3MulMatrice3x3(vec, YRotate(tempDegRotY))
    return vec
end

-- >RotationMatrice for allready Normalized Values
function RotateAroundPoint(x, z, Rad, Px, Pz)
    x, z = x - Px, z - Pz
    if not Rad then return end
    sinus = math.sin(Rad)
    cosinus = math.cos(Rad)

    return (x * cosinus + z * -sinus) + Px, (x * sinus + z * cosinus) + Pz
end

function delayedSpin(pieceName, axis, value, speeds, restTime)
    Sleep(restTime)
    Spin(pieceName, axis, value, speeds)
end

-- ======================================================================================
-- Deprecated VectorOperations 
-- for more recent implementations see lib_type

function mix(vA, vB, fac)
    if fac > 1 or fac < 0 then assert(true == false) end
    if type(vA) == "number" and type(vB) == "number" then
        return (fac * vA + (1 - fac) * vB)
    end

    return mixTable(vA, vB, fac)
end

function lerp(a, b, t)
    return a + (b - a) * t
end
function lerpTable(table1, table2, t)
    -- Ensure tables have the same size
    assert(#table1 == #table2, "Tables must be of the same size. Is ".. #table1.. "vs ".. #table2)

    local result = {}

    for i = 1, #table1 do
        result[i] = lerp(table1[i], table2[i], t)
    end

    return result
end


function mixTable(TA, TB, factor)
    assert(count(TA) == count(TB), "Tables must be of the same size. Is ".. count(TA).. "vs ".. count(TB))
    local T = {}
    for k, v in pairs(TA) do 
        T[k] = v * factor + TB[k] * (1 - factor) 
    end
    return T

end

function mixclampTable(TA, TB, factor)
    assert(count(TA) == count(TB), "Tables must be of the same size. Is ".. count(TA).. "vs ".. count(TB))
    local T = {}
    for k, v in pairs(TA) do 
        T[k] = math.min(v, v * factor + TB[k] * (1 - factor))
    end


    return T

end

local countConstAnt = 0
function mulVector(vl, value)
    if not vl then return nil end

    countConstAnt = countConstAnt + 1
    -- if not value or type(value)~='number' and #value == 0 then Spring.Echo("JW::RopePhysix::"..countConstAnt)end 

    if type(vl) == 'number' and type(value) == "number" then
        return vl * value
    end

    if value and type(value) == 'number' then -- Skalar
        return {x = vl.x * value, y = vl.y * value, z = vl.z * value}
    end

    if value.x and vl.x then
        --		Spring.Echo("JW:lib_UnitScript:mulVector"..countConstAnt)
        return {x = vl.x * value.x, y = vl.y * value.y, z = vl.z * value.z}
    end

    return nil
end

function absNormMax(...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    maxVal = -1 * math.huge
    for k, v in pairs(arg) do
        if math.abs(v) > maxVal then maxVal = math.abs(v) end
    end

    return maxVal
end

function norm2Vector(v1, v2)
    if not v1 then return nil end
    if not v1.x then return nil end

    v = subVector(v1, v2) or v1
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

function divVector(v1, val)
    if not v1 or not val then return nil end
    if not v1.x or type(val) ~= "number" then return nil end

    if type(val) == "number" then
        return {x = v1.x / val, y = v1.y / val, z = v1.z / val}
    else
        return {x = v1.x / val.x, y = v1.y / val.y, z = v1.z / val.y}
    end
end

function addVector(v1, val)
    if not v1 or not val then return nil end

    if type(val) == "table" then
        return {x = v1.x + val.x, y = v1.y + val.y, z = v1.z + val.z}
    else
        return {x = v1.x + val, y = v1.y + val, z = v1.z + val}
    end
end

function subVector(v1, v2)
    if not v1 or not v2 then return end

    if type(v1) == "number" then
        Spring.Echo(
            "lib_UnitScript::Error:: Cant substract a Vector from a value!")
        return
    end

    if type(v2) == "number" then
        return {x = v1.x - v2, y = v1.y - v2, z = v1.z - v2}
    else
        return {x = v1.x - v2.x, y = v1.y - v2.y, z = v1.z - v2.z}
    end
end

function applyForce(force, force2) return addVector(force, force2) end

function normVector(v)
    l = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    return {x = v.x / l, y = v.y / l, z = v.z / l}
end

function sumNormVector(v)
    sum = math.abs(v.x) + math.abs(v.y) + math.abs(v.z)
    return {x = v.x / sum, y = v.y / sum, z = v.z / sum}
end

function VDotProduct(V1, V2)
    if not V1 or not V2 then return nil end
    return DotProduct(V1.x, V1.y, V1.z, V2.x, V2.y, V2.z)
end

function Vabs(Vectors) return distance(Vectors.x, Vectors.y, Vectors.z) end

function Vcross(V1, V2)
    if not V1 or not V2 then return nil end

    return (V1.y * V2.z - V1.z * V2.y) - (V1.x * V2.z - V1.z * V2.x) -
               (V1.x * V2.y - V1.y * V2.x)
end

function DotProduct(x, y, z, ax, ay, az) return x * ax + y * ay + az * z end

-- ======================================================================================
-- > gets a Vector from a Piece
function getVectorPieceRelPos(unitID, piece)
    ex, ey, ez = Spring.GetUnitPiecePosition(unitID, piece)
    return Vector:new(ex, ey, ez)
end
-- > gets a Vector from a Piece
function getVectorPieceAbsPos(unitID, piece)
    ex, ey, ez = Spring.GetUnitPiecePosDir(unitID, piece)
    return Vector:new(ex, ey, ez)
end

-- > old Vector constructor- uses lib_type constructor
function makeVector(x, y, z) return {x = x, y = y, z = z} end

function getUnitPositionV(id)
    ix, iy, iz = Spring.GetUnitPosition(id)
    if ix then
        local v = Vector:new(ix, iy, iz)
        return v
    else
        local v = Vector:new(0, 0, 0)
        return v
    end
end

function rangeClampVector(vector, range)
    vector = vector.normalized()
    vector = vector * range
    return vector
end
-- ======================================================================================
-- Filter Functions
-- ======================================================================================

-- >filtersOutUnitsOfType. Uses a Cache, if handed one to return allready Identified Units
function removeUnitsOfTypeInT(T, UnitTypeTable, Cache)
    if type(UnitTypeTable) == "number" then
        copyOfType = UnitTypeTable;
        UnitTypeTable = {}
        UnitTypeTable[copyOfType] = true
    end

    if Cache then
        returnTable = {}
        for num, id in pairs(T) do
            if (Cache[id] and Cache[id] == false) or
                UnitTypeTable[Spring.GetUnitDefID(id)] == nil then
                Cache[id] = false
                returnTable[#returnTable + 1] = id
            else
                Cache[id] = true
            end
        end
        return returnTable, Cache

    else
        local returnTable = {}
        for num, id in pairs(T) do
            defID = Spring.GetUnitDefID(id)
            if not UnitTypeTable[defID] then
                returnTable[#returnTable + 1] = id
            end
        end
        return returnTable
    end
end

-- >filtersOutUnitsOfType. Uses a Cache, if handed one to return allready Identified Units
function getUnitsOfTypeInT(T, UnitTypeTable, Cache)
    if type(UnitTypeTable) == "number" then
        copyOfType = UnitTypeTable;
        UnitTypeTable = {}
        UnitTypeTable[copyOfType] = true
    end

    if Cache then
        returnTable = {}
        for num, id in pairs(T) do
            if Cache[id] and Cache[id] == true or T[id] and
                UnitTypeTable[Spring.GetUnitDefID(id)] then
                Cache[id] = true
                returnTable[#returnTable + 1] = id
            else
                Cache[id] = false
            end
        end
        return returnTable, Cache

    else
        local returnTable = {}
        for num, id in pairs(T) do
            defID = Spring.GetUnitDefID(id)
            if UnitTypeTable[defID] then
                returnTable[#returnTable + 1] = id
            end
        end
        return returnTable
    end
end

function getUnarmedInT(T)
    return getUnitDefIdsWithProperty(T, "canFight")
end

-- >filters Out TransportUnits
function getTransportsInT(T)
    return getUnitDefIdsWithProperty(T, "isTransport")
end

function isTransport(id)
    def = Spring.GetUnitDefID(id)
    return UnitDefs[def].isTransport
end
-- >filters Out Immobile Units
function getImmobileInT(T, UnitDefs)
    return getUnitDefIdsWithProperty(T, "isImmobile")
end

-- >filters Out Immobile Units
function removeImmobileInT(T)
    filterTable =  getUnitDefIdsWithProperty(T, "isImmobile")
    return removeDictFromDict(T, filterTable)
end

function removeBuildingInT(T, UnitDefs)
    returnTable = {}

    for num, id in pairs(T) do
        def = Spring.GetUnitDefID(id)

        if UnitDefs[def] and UnitDefs[def].isBuilding == false then
            returnTable[#returnTable + 1] = id
        end
    end
    return returnTable

end

-- > filters Out Buildings
function getBuildingInT(T, UnitDefs)
    return getUnitDefIdsWithProperty(T, "isBuilding")
end

-- > filters Out Builders
function getBuilderInT(T)
    return getUnitDefIdsWithProperty(T, "isBuilder")
end

-- > filters Out Mobile Builders
function getMobileBuildersInT(T)
    return getUnitDefIdsWithProperty(T, "isMobileBuilder")
end

function getStaticBuildersInT(T)
    return getUnitDefIdsWithProperty(T, "isStaticBuilder")
end

function getFactorysInT(T)
    return getUnitDefIdsWithProperty(T, "isFactory")
end

function getExtractorsInT(T)
    return getUnitDefIdsWithProperty(T, "isExtractor")
end

function getGroundUnitsInT(T)
    return getUnitDefIdsWithProperty(T, "isGroundUnit")
end

function getUnitDefIdsWithProperty(T, propertyName)

    boolFilterOut = lboolFilterOut or false
    returnTable = {}
    for num, id in pairs(T) do
        def = Spring.GetUnitDefID(id)
        if UnitDefs[def][propertyName] then
            returnTable[#returnTable + 1] = id
        end
    end
    return returnTable
end

-- ======================================================================================
-- Section: Sound
-- ======================================================================================
-- > Play a soundfile only by unittype
function PlaySoundByUnitDefID(unitdef, soundfile, loudness, Time,
                              nrOfUnitsParallel, predelay)
    assert(unitdef)
    assert(nrOfUnitsParallel, UnitDefs[unitdef].name)

    if not unitdef then return false end
    if predelay and predelay > 0 then Sleep(predelay) end

    loud = loudness or 1
    if loud == 0 then loud = 1 end

    if GG.UnitDefSoundLock == nil then GG.UnitDefSoundLock = {} end
    if GG.UnitDefSoundLock[unitdef] == nil then
        GG.UnitDefSoundLock[unitdef] = 0
    end

    if GG.UnitDefSoundLock[unitdef] < nrOfUnitsParallel then
        GG.UnitDefSoundLock[unitdef] = GG.UnitDefSoundLock[unitdef] + 1
        Spring.PlaySoundFile(soundfile, loud)
        if Time > 0 then Sleep(Time) end
        GG.UnitDefSoundLock[unitdef] = GG.UnitDefSoundLock[unitdef] - 1
        return true
    end
    return false
end


function PlaySoundAtUnitPieceLocatioin(unitID, pieceID, soundfile, loudness)
    loudness = loudness or 1.0
    px,py,pz = Spring.GetUnitPiecePosDir(unitID, pieceID)
    Spring.PlaySoundFile(soundfile, loudness, px,py,pz)
end
-- ======================================================================================
-- Section: Ressources
-- ======================================================================================

-- > consumes a resource if available 
function consumeAvailableRessource(typeRessource, amount, teamID,
                                   boolConsumeAllAvailable)
    boolConsumeAllAvailable = boolConsumeAllAvailable or false
    typeRessource = string.lower(typeRessource)
    if "m" == typeRessource or "metal" == typeRessource then
        currentLevel = Spring.GetTeamResources(teamID, "metal")
        if amount > currentLevel and boolConsumeAllAvailable == false then
            return false
        end

        if Spring.UseTeamResource(teamID, "metal",
                                  math.min(amount, currentLevel)) then
            return true
        end
    end

    if "energy" == typeRessource or "e" == typeRessource then
        currentLevel = Spring.GetTeamResources(teamID, "energy")
        if amount > currentLevel and boolConsumeAllAvailable == false then
            return false
        end

        if Spring.UseTeamResource(teamID, "energy",
                                  math.min(amount, currentLevel)) then
            return true
        end
    end
    return false
end

-- > consumes a resource if available 
function consumeAvailableRessourceUnit(unitID, typeRessource, amount)
    teamID = Spring.GetUnitTeam(unitID)
    typeRessource = string.lower(typeRessource)
    if "m" == typeRessource or "metal" == typeRessource then
        currentLevel = Spring.GetTeamResources(teamID, "metal")
        if amount > currentLevel then return false end

        if Spring.UseUnitResource(unitID, "m", amount) then return true end
    end

    if "e" == typeRessource or  "energy" == typeRessource then
        currentLevel = Spring.GetTeamResources(teamID, "energy")
        if amount > currentLevel then return false end

        if Spring.UseUnitResource(unitID, "e", amount) then return true end
    end
    return false
end

-- ======================================================================================
-- Section: Unit Commands
-- ======================================================================================
--> Do all damage in circle
function doDamageToAllUnitsInRange(x,z, range, damage, filterFunction)
    return foreach(
            getAllInCircle(x, z, range),
            function(id)
                if not filterFunction or filterFunction(id) then
                    Spring.AddUnitDamage(id, damage)
                    return id
                end
            end
            )
end

function spawnProjectile( weaponDefID,  projectileParams)
    return Spring.SpawnProjectile (  weaponDefID,  projectileParams )
end

--> Set Unit permanent flying
function setUnitNeverLand(unitID, boolNeverLand)
    if boolNeverLand == true then
    Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, {0}, {})
    else
    Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, {1}, {})
    end
end

-- > transfers Order from one Unit to another
function transferOrders(originID, targetID)
    argtype1, argtype2 = type(originID), type(targetID)
    -- echo(argtype1, argtype2) 
    if not originID or not targetID then return end

    CommandTable = Spring.GetUnitCommands(originID, -1)
    first = false
    if CommandTable then
        for _, cmd in pairs(CommandTable) do
            if #CommandTable ~= 0 then
                if first == false then
                    first = true
                    if cmd.id == CMD.MOVE then
                        Spring.GiveOrderToUnit(targetID, cmd.id, cmd.params, {})
                    elseif cmd.id == CMD.STOP then
                        Spring.GiveOrderToUnit(targetID, CMD.STOP, {}, {})
                    end
                else
                    Spring.GiveOrderToUnit(targetID, cmd.id, cmd.params,
                                           {"shift"})
                end
            else
                Spring.GiveOrderToUnit(targetID, CMD.STOP, {}, {})
            end
        end
    end
end

function gotoBuildPosOnceDone(unitID, delayMs)
     Sleep(delayMs)
     if doesUnitExistAlive(unitID) == true then
     hx,hy, hz = Spring.GetUnitPosition(unitID)
     Command(unitID, "go", {
                x = hx,
                y = hy + 25,
                z = hz
            }) 
               
    Command(unitID, "go", {
                x = hx,
                y = hy + 25,
                z = hz
            }, {"shift"})
    end
end

function GetUnitOrFeaturePosition(id)
    if id <= Game.maxUnits then
        return Spring.GetUnitPosition(id)
    else
        return -10,-10,-10
    end
end

function GetCurrentMoveGoal(unitID)
    CommandTable = Spring.GetUnitCommands(unitID, 1)
      if CommandTable and CommandTable[1] then
              gx,_, gz = GetCommandPos(CommandTable[1])             
                  if gx and gx ~= -10 or gz and gz ~= -10 then
                    return gx, gz 
                end
      end
end

function GetMoveGoal(unitID)
    CommandTable = Spring.GetUnitCommands(unitID, 1)
      if CommandTable and CommandTable[1] and  (command.id < 0 or command.id == CMD.MOVE)  then
              gx,_, gz = GetCommandPos(CommandTable[1])             
                  if gx and gx ~= -10 or gz and gz ~= -10 then
                    return gx, gz 
                end
      end
end

function GetCommandPos(command)   --- get the command position
  if command.id < 0 or command.id == CMD.MOVE or command.id == CMD.REPAIR or command.id == CMD.RECLAIM or
  command.id == CMD.RESURRECT or command.id == CMD.DGUN or command.id == CMD.GUARD or
  command.id == CMD.FIGHT or command.id == CMD.ATTACK then
    if table.getn(command.params) >= 3 then
          return command.params[1], command.params[2], command.params[3]            
      elseif table.getn(command.params) >= 1 then
          return GetUnitOrFeaturePosition(command.params[1])
      end   
    end
  return -10,-10,-10
end

function hasNoActiveAttackCommand(unitID)
    CommandTable =Spring.GetUnitCommands(unitID, 1)
    if CommandTable and CommandTable[1] then
        cmd = CommandTable[1].id
        return  cmd ~= CMD.ATTACK and cmd ~= CMD.FIGHT
    end

    return true
end

--> Does not serialize script enviornment state
function serializeUnitToTable(id)
    stat = {pos = {}, h = {}}
    stat.defID = Spring.GetUnitDefID(id)
    stat.unitID = id
    stat.teamID = Spring.GetUnitTeam(id)
    stat.h.health, stat.h.maxHealth, stat.h.paralyzeDamage, stat.h.captureProgress, stat.h.buildProgress = Spring.GetUnitHealth(id)
    stat.pos.x,stat.pos.y,stat.pos.z = Spring.GetUnitPosition(id)

    stat.parent =   getUnitVariableEnv(id, "fatherID") or -1
    stat.exp = Spring.GetUnitExperience(id) or 0
    Spring.DestroyUnit(id, false, true)
    return stat
end

function reconstituteUnitFromTable(stat)
    id = Spring.CreateUnit (
        stat.defID,
        stat.pos.x,
        stat.pos.y, 
        stat.pos.z, -- position 4
        1,            --5
        stat.teamID) --[[,  --6
        true,       --7
        false,       --8
        stat.unitID, 
        stat.parent ) ]]
    if id then
    Spring.SetUnitExperience(id, stat.exp)
    Spring.SetUnitHealth(id, stat.h)
    end
    return id
end

-- > transfers Order from one Unit to another
function transferAttackOrder(originID, targetID)
    CommandTable = Spring.GetUnitCommands(originID, 2)
    if CommandTable and CommandTable[1] then
        cmd = CommandTable[1]
        if cmd.id == CMD.ATTACK or cmd.id == CMD.FIGHT then
            Spring.GiveOrderToUnit(targetID, cmd.id, cmd.params, {})
        elseif cmd.id == CMD.STOP then
            Spring.GiveOrderToUnit(targetID, CMD.STOP, {}, {})
        end
    else
        Spring.GiveOrderToUnit(targetID, CMD.STOP, {}, {})
    end
end

-- > move away from another unit by distance*scalingfactor
function runAwayFrom(id, horrorID, distanceToRun)
    x, y, z = Spring.GetUnitPosition(id)
    hx, hy, hz = Spring.GetUnitPosition(horrorID)

    runAwayFromPlace(id, hx, hy, hz, distanceToRun)
end

-- > move away from another unit by distance*scalingfactor
function runAwayFromPlace(id, px, py, pz, distanceToRun)
    x, y, z = Spring.GetUnitPosition(id)
    hx, hy, hz = px, py, pz

    -- Compute Offset
    hx, hz = (x - hx), (z - hz)
    maX = math.max(math.abs(hx), math.max(hz))
    hx, hz = hx / maX, hz / maX
    hx, hz = (hx * distanceToRun), ( hz * distanceToRun)
    hx, hz = x + hx, z + hz

    Spring.SetUnitMoveGoal ( id, hx, hy, hz)
end

function sampleKeyFromDicct(T, ...)
    local arg = {...}
    arg.n = #arg

    for i = 1, arg.n, 1 do
        if T[arg[i]] then 
            return T[arg[i]]
        end
    end
end

function delayedCommand(id, command, target, option, framesToDelay)
    persPack = {framesToDelay = framesToDelay}
    function delay(evtID, frame, persPack, startFrame)
        if frame >= startFrame + persPack.framesToDelay then
            Command(id, command, target, option)
            return nil, persPack
        end

        return frame + 10, persPack
    end

    GG.EventStream:CreateEvent(delay, persPack,
                               Spring.GetGameFrame() + framesToDelay - 1)

end

function getUnitPosAsTargetTable(id)
  x,y,z = Spring.GetUnitPosition(id)
  return {x=x, y=y, z= z}
end

function isTransported(unitID)
    transporterID = Spring.GetUnitTransporter(unitID)
    return (transporterID ~= nil)
end

-- >Generic Simple Commands
function Command(id, command, tarGet, option)
    assert(id)
    assert(command ~= nil, UnitDefs[Spring.GetUnitDefID(id)].name.." has invalid Command executed on it")
    local target = tarGet

    option = option  or {}
    -- abort previous command

    if command == "build" then
        x, y, z = Spring.GetUnitPosition(id)
        x, y, z = x + 50, y, z + 50
        Spring.SetUnitMoveGoal(id, x, y, z)
        Spring.GiveOrderToUnit(id, -1 * target, {}, {})
    end

    if command == "attack" then
        coords = {}
        targetType = type(target)

        if targetType == "table" then
            if #target == 1 then
                Spring.GiveOrderToUnit(id, CMD.ATTACK, target, option)
                return
            end

            if target.x then
                Spring.GiveOrderToUnit(id, CMD.ATTACK,
                                       {target.x, target.y, target.z}, option)
                return
            else
                Spring.GiveOrderToUnit(id, CMD.ATTACK,
                                       {target[1], target[2], target[3]}, option)
                return
            end
        end

        if targetType == "number" then
            Spring.GiveOrderToUnit(id, CMD.ATTACK, {target}, option)
            return
        end
    end

    if command == "repair" or command == "assist" or command == "guard" then
        targetType = type(target)
        if targetType == "table" then
            Spring.GiveOrderToUnit(id, CMD.GUARD, target, option)
        else
            Spring.GiveOrderToUnit(id, CMD.GUARD, {target}, option)
        end
    end

    if command == "go" then
        targetType = type(target)
        if targetType == "table" then
        	if target.x then
                Spring.GiveOrderToUnit(id, CMD.MOVE, 
                                        {   target.x or target[1], 
                                            target.y or target[2], 
                                            target.z or target[3]
                                        },
                                       option) -- {"shift"}
            else
          		Spring.GiveOrderToUnit(id, CMD.MOVE, 
                                        {   target[1], 
                                             target[2], 
                                             target[3]
                                        },
                                       option)
            end
        end
    end

    if command == "stop" then Spring.GiveOrderToUnit(id, CMD.STOP, {}, {}) end

    if command == "setactive" then
        if type(option) == "number" then
            Spring.GiveOrderToUnit(id, CMD.ONOFF, option, {})
        else
            currentState = GetUnitValue(COB.ACTIVATION)
            if currentState == 0 then
                currentState = 1
            else
                currentState = 0
            end
            SetUnitValue(COB.ACTIVATION, currentState)
        end

    end

    if command == "cloak" then
        currentState = GetUnitValue(COB.ACTIVATION)
        if currentState == 0 then
            currentState = 1
        else
            currentState = 0
        end

        Spring.UnitScript.SetUnitValue(COB.CLOAKED, currentState)
    end
end

function getPieceNrByName(id, name)
    return (Spring.GetUnitPieceMap(id))[name]
end

function getUnitCloaked(unitID)
    return  GetUnitValue(COB.CLOAKED) == 1
end

function getUnitVariableEnv(unitID, ValueName)
    env = Spring.UnitScript.GetScriptEnv(unitID)

    if env and env[ValueName] then
        return env[ValueName] 
    end

end

function getUnitValueEnv(unitID, ValueName)
    env = Spring.UnitScript.GetScriptEnv(unitID)

    if env and env.UnitScript.GetUnitValue then
        local cob = env.UnitScript.COB
        return Spring.UnitScript.CallAsUnit(unitID,
                                            Spring.UnitScript.GetUnitValue,
                                            cob[ValueName])
    end
end

function setUnitValueEnv(unitID, ValueName, value)
    env = Spring.UnitScript.GetScriptEnv(unitID)

    if env and env.UnitScript.GetUnitValue then
        local cob = env.UnitScript.COB
        return Spring.UnitScript.CallAsUnit(unitID,
                                            Spring.UnitScript.SetUnitValue,
                                            cob[ValueName], value)
    end
end

function setFireState(unitID, fireState)
    assert(unitID)
    if type(fireState) == "string" then

        states = {["holdfire"] = 0, ["returnfire"] = 1, ["fireatwill"] = 2}
        fireState = states[string.lower(fireState)] or 0
    end

    Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {fireState}, {})
end

function getFireState(unitID)
    res = Spring.GetUnitStates(unitID)
    return res.firestate
end

function setMoveState(unitID, moveState)
    if type(moveState) == "string" then

        states = {["holdposition"] = 0, ["maneuver"] = 1, ["roam"] = 2}
        moveState = states[string.lower(fireStateStr)] or 0
    end

    Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {moveState}, {})
end

-- ======================================================================================
-- Section: Sfx Operations
-- ======================================================================================
-- > Explodes a Table of Pieces 
function explodeT(TableOfPieces, Conditions, StepSize)
    lStepSize = StepSize or 1
    for i = 1, #TableOfPieces, lStepSize do
        Explode(TableOfPieces[i], Conditions)
    end
end

function explodeTableOfPiecesGroupsExcludeTable(TableOfPiecesGroups,  ExcludePiecesDict, Condition)
    if Condition == nil then
        Condition = SFX.FALL + SFX.FIRE
    end

    for groupName, group in pairs(TableOfPiecesGroups) do
        for num, pieces in pairs(group) do 
            if not ExcludePiecesDict[pieces] then
                Explode(pieces, Condition) 
            end
        end
    end
end

-- > Explodes a Table of Pieces 
function explodeD(TableOfPieces, Conditions)
    lStepSize = StepSize or 1
    for num, pieces in pairs(TableOfPieces) do Explode(pieces, Conditions) end
end

-- > make a CEG CLOUD
function CEG_CLOUD(cegname, size, pos, lifetime, nr, densits, plifetime, swing,
                   speedInFrames)
    local spCEG = Spring.SpawnCEG
    quarter = math.ceil(plifetime / 4)
    it = 1
    pT = {}
    for i = 1, nr do
        pT[i] = {
            x = math.random(-size, size),
            y = math.random(-size, size) * 0.5,
            z = math.random(-size, size)
        }
    end

    while lifetime > 0 do
        frame = Spring.GetGameFrame()

        for i = it, nr, it do
            -- between every particle that isnt first and last
            if i ~= 1 and i ~= nr then
                if i == 1 then
                    fx, fy, fz = getMidPoint(pT[nr], pT[2])
                else
                    fx, fy, fz = getMidPoint(pT[nr - 1], pT[1])
                end
                pT[i].x, pT[i].y, pT[i].z =
                    swingPointOutFromCenterByFrame(fx, fy, fz, frame, swing,
                                                   speedInFrames)
            else
                fx, fy, fz = getMidPoint(pT[i - 1], pT[i + 1])
                pT[i].x, pT[i].y, pT[i].z =
                    swingPointOutFromCenterByFrame(fx, fy, fz, frame, swing,
                                                   speedInFrames)
            end
            spCEG(cegname, pT[i].x, pT[i].y, pT[i].z, math.random(0, 1),
                  math.random(0, 1), math.random(0, 1), 0, 0)
        end
        it = (it % 4) + 1
        lifetime = lifetime - quarter
        Sleep(quarter)
    end
end

function speed(distanceToCover, timeInMs)
    if timeInMs == 0 then return 0 end
    timeInFrames = (timeInMs/1000)*30
    return math.abs(distanceToCover/timeInFrames)
end

-- > create a CEG at the given Piece with direction or piecedirectional Vector
function spawnCegAtPiece(unitID, pieceId, cegname, offset, dx, dy, dz,
                         boolPieceDirectional)
    if not dx then -- default to upvector 
        dx, dy, dz = 0, 1, 0
    end

    boolAdd = offset or 10
    assert(unitID,"lib_UnitScript::Not enough arguments to spawnCegAtPiece")
    if not pieceId then echo("lib_UnitScript::No pieceId argument to spawnCegAtPiece at"..getTypeName(unitID)) return end
    if not cegname then echo("lib_UnitScript::Not enough arguments to spawnCegAtPiece at"..getTypeName(unitID)) return end

    x, y, z, mx, my, mz = Spring.GetUnitPiecePosDir(unitID, pieceId)
    if boolPieceDirectional and boolPieceDirectional == true then
        dx, dy, dz = mx, my, mz
    end

    if y then
        y = y + boolAdd
        Spring.SpawnCEG(cegname, x, y, z, dx, dy, dz, 0, 0)
    end
end


function spawnCegAtPieceGround(unitID, pieceId, cegname, offset, dx, dy, dz)
    if not dx then -- default to upvector 
        dx, dy, dz = 0, 1, 0
    end

    boolAdd = offset or 10

    if not unitID then
        error("lib_UnitScript::Not enough arguments to spawnCegAtPiece")
    end
    if not pieceId then
        error("lib_UnitScript::Not enough arguments to spawnCegAtPiece")
    end
    if not cegname then
        error("lib_UnitScript::Not enough arguments to spawnCegAtPiece")
    end
    x, y, z, mx, my, mz = Spring.GetUnitPiecePosDir(unitID, pieceId)
    y= Spring.GetGroundHeight(x,z)

    if y then
        y = y + boolAdd
        Spring.SpawnCEG(cegname, x, y, z, dx, dy, dz, 0, 0)
    end
end

function spawnCegNearUnitGround(unitID, cegname, ox, oz, oy) 
    dx, dy, dz = 0,1,0
    ox = ox or 0
    oz = oz or 0
    oy = oy or 0
    x, y, z = Spring.GetUnitPosition(unitID)
    y= Spring.GetGroundHeight(x + ox ,z + oz )
    Spring.SpawnCEG(cegname, x +ox   , y +oy , z+oz  , dx, dy, dz, 50, 0)
end

-- >Spawn CEG at unit
function spawnCegAtUnit(unitID, cegname, xoffset, yoffset, zoffset, dx, dy, dz)
    -- if doesUnitExistAlive(unitID) ==false then return end
    dx, dy, dz = dx or 0, dy or 1, dz or 0

    x, y, z = Spring.GetUnitPosition(unitID)
    if xoffset then
        Spring.SpawnCEG(cegname, x + xoffset, y + yoffset, z + zoffset, dx, dy,
                        dz, 50, 0)
    else
        Spring.SpawnCEG(cegname, x, y, z, dx, dy, dz, 50, 0)
    end
end

-- > spawn a ceg on the map above ground
function markPosOnMap(x, y, z, colourname, boolGadget)

    h = Spring.GetGroundHeight(x, z)
    if h > y then y = h end
    for i = 1, 5 do
        Spring.SpawnCEG(colourname, x, y + 10, z, 0, 1, 0, 50, 0)
        if not boolGadget then Sleep(200) end
    end
end


-- > creates a ceg, that traverses following its behavioural function
function cegDevil(cegname, x, y, z, rate, lifetimefunc, endofLifeFunc,
                  boolStrobo, range, damage, behaviour)
    endofLifeFunc = endofLifeFunc or function(x, y, z) end
    boolStrobo = boolStrobo or false
    range = range or 20
    damage = damage or 0
    knallfrosch = function(x, y, z, counter, v)
        if counter % 120 < 60 then -- aufw�rts
            if v then
                return x * v.x, y * v.y, z * v.z, v
            else
                return x, y, z, {
                    x = (math.random(10, 14) / 10) * randSign(),
                    y = math.random(1, 2),
                    z = (math.random(10, 14) / 10) * randSign()
                }
            end
        elseif Spring.GetGroundHeight(x, z) - y < 10 then -- rest
            return x, y, z
        else -- fall down
            if v and v.y < 0 then
                return x * v.x, y * v.y, z * v.z, v
            else
                return x, y, z, {
                    x = (math.random(10, 11) / 10) * randSign(),
                    y = math.random(1, 2),
                    z = (math.random(10, 14) / 10) * randSign()
                }
            end
        end
    end
    functionbehaviour = behaviour or knallfrosch
    Time = 0
    local SpawnCeg = Spring.SpawnCEG
    v = makeVector(0, 0, 0)

    while lifetimefunc(Time) == true do
        x, y, z, v = functionbehaviour(x, y, z, Time, v)

        if boolStrobo == true then
            d = randVec()
            SpawnCeg(cegname, x, y, z, d.x, d.y, d.z, range, damage)
        else
            SpawnCeg(cegname, x, y, z, 0, 1, 0, range, damage)
        end

        Time = Time + rate
        Sleep(rate)
    end
    if endofLifeFunc then endofLifeFunc(x, y, z) end
end

-- New Unsorted code TODO Sortme

function getBelowPow2(value)
    n = 2
    it = 1
    while n < value do
        it = inc(it)
        n = 2 ^ it
    end
    return it, n
end

function arePlayersInSameAllyTeam(playerA, playerB)
    _, _, _, ateamID, aallyTeamID, _, _, _, _, _ = Spring.GetPlayerInfo(playerA)
    _, _, _, bteamID, ballyTeamID, _, _, _, _, _ = Spring.GetPlayerInfo(playerB)

    return ateamID ~= bteamID and aallyTeamID ~= ballyTeamID
end

function getMapCenter(Game)
    assert(Game)
    assert(Game.mapX)
    assert(Game.mapY)
    mapCenter = {x = Game.mapX / 2, z = Game.mapY / 2}
    return mapCenter
end

function frameToMs(frames) return frameToS(frames) * 1000; end

function frameToS(frames) return (frames / 30); end

function SecToMs( seconds)
    assert(seconds)
    return seconds * 1000
end

function MsToFrame(milliseconds)
    return math.ceil((milliseconds/1000) * 30)
end


function assertInDict(T,  Key)
     assert(T[Key], Key.. " not in ".. (toString(T)))                        
end

function deserializeStringToTable(str)
  local f = loadstring(str)
  return f()
end

function getPieceName(unitID, pieceID)
    pieceID_NameMap=Spring.GetUnitPieceList(unitID) 
    return toString(pieceID_NameMap[pieceID])
end

function serializeTableToString(table)
  return "return "..serializeTable(table)
end

function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)
    if name then 
      if not string.match(name, '^[a-zA-z_][a-zA-Z0-9_]*$') then
        name = string.gsub(name, "'", "\\'")
        name = "[".. name .. "]"
      end
      tmp = tmp .. name .. " = "
     end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
        assert(true==false)
    end

    return tmp
end



function setupPrintf(unitID)
    if not GG.DebugPrintF then 
        GG.DebugPrintF = {}
    end

    GG.DebugPrintF[unitID]= 0
end

function printf(unitID, message)
    if not GG.DebugPrintF or not GG.DebugPrintF[unitID] then setupPrintf(unitID) end
    echo("Printf:Debug:"..GG.DebugPrintF[unitID]..":"..(message or " iterration"))
    GG.DebugPrintF[unitID] = GG.DebugPrintF[unitID] + 1
end


function houseAddDestructionTable(OrgT, Level, pID)
if not OrgT[Level] then OrgT[Level] = {}end
OrgT[Level][#OrgT[Level] +1] =  pid
return OrgT
end

function houseDestroyWithDestructionTable(LevelPieces, maxSpeed, id)
	conditionalEcho(GG.lib_boolDebug, "Destroyed house animation") -- TODO find out why scrapheap has vertices going to infinity
	hideAll(id)
	speed= 9.8
    scale = 10
	for i=#LevelPieces, 1, -1 do
		for k= 1, #LevelPieces[i] do
			Show(LevelPieces[i][k])
			Move(LevelPieces[i][k], y_axis, 0, speed * scale)
			turnPieceRandDir(LevelPieces[i][k], 0.1)
		end
		Sleep(i*1000)
        WaitForMoves(LevelPieces[i])
	end
	
	while(speed < maxSpeed)do
		speed = math.min(speed + 9.8, maxSpeed)
		for i=#LevelPieces, 1, -1 do
			for k= 1, #LevelPieces[i] do
				Move(LevelPieces[i][k], y_axis, 0, speed)
			end
		end
		Sleep(1000)
	end
	Sleep(5000)
	for i=#LevelPieces, 1, -1 do
		WaitForMoves(LevelPieces[i])
		hideT(LevelPieces[i])
	end
	echo("End house destruction")
    return 1
end

function getEngineVersion()
     if Engine and Engine.version then
        local function Split(s, separator)
            local results = {}
            for part in s:gmatch("[^" .. separator .. "]+") do
                results[#results + 1] = part
            end
            return results
        end
        local engineVersion = Split(Engine.version, '-')
        if engineVersion[2] ~= nil and engineVersion[3] ~= nil then
            return tonumber(string.gsub(engineVersion[1], '%.', '') ..
                                         engineVersion[2])
        else
            return tonumber(Engine.version)
        end
    end
end

function find_closest_position(positions, vector_start, vector_direction)
    local closest_position = nil
    local min_distance = math.huge

    -- Calculate the direction vector

    for _, position in ipairs(positions) do
        -- Calculate the vector from vector_start to the position
        local position_vector = {
            position[1] - vector_start[1],
            position[2] - vector_start[2],
            position[3] - vector_start[3]
        }

        -- Calculate the dot product to project the position vector onto the direction vector
        local dot_product = position_vector[1] * vector_direction[1] + position_vector[2] * vector_direction[2] + position_vector[3] * vector_direction[3]

        -- Calculate the closest point on the line
        local closest_point = {
            vector_start[1] + (dot_product / (vector_direction[1]^2 + vector_direction[2]^2 + vector_direction[3]^2)) * vector_direction[1],
            vector_start[2] + (dot_product / (vector_direction[1]^2 + vector_direction[2]^2 + vector_direction[3]^2)) * vector_direction[2],
            vector_start[3] + (dot_product / (vector_direction[1]^2 + vector_direction[2]^2 + vector_direction[3]^2)) * vector_direction[3]
        }

        -- Calculate the distance between the position and the closest point on the line
        local distance = math.sqrt((position[1] - closest_point[1])^2 + (position[2] - closest_point[2])^2 + (position[3] - closest_point[3])^2)

        if distance < min_distance then
            min_distance = distance
            closest_position = position
        end
    end

    return closest_position
end

function GetRayIntersectPiecesPosition(unitID, RoofTopPieces, vector_position, vector_direction)
	local RooftopClosestPiece = -1
	local RooftopMinDistance = math.huge
	local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
	positions = {}
	foreach(RoofTopPieces,
			function (pieceID)
				x,y,z = spGetUnitPiecePosDir(unitID, pieceID)
				positions[#positions+1] = {x,y,z, pieceID}
			end
			) 

    resultPos= find_closest_position(positions, vector_position, vector_direction)

	return resultPos[4]
end

function holdsForAllBool(T, state)
    holdsForEach = true
    foreach(T,
            function(id)
                if id ~= state then holdsForEach = false end 
            end)
    return holdsForEach
end
