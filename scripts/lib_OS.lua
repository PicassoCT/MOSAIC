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

]] --
-- >Plays a Soundscape
-- > Expects: a path, a table containing :
-- a Table of openers, containing "Name"
-- Numbers and Time to play
-- a similar table for the backgrounds
-- a similar table for the single sound solos
-- a Table of closers, containing "Name"
-- Numbers and Time to play
function playSoundScape_OS(path, dataTable, restIntervallMin, restIntervallMax,
                           loudness, unitID)
    unitdef = Spring.GetUnitDefID(unitID)

    if GG.UnitDefSoundLock == nil then GG.UnitDefSoundLock = {} end
    if GG.UnitDefSoundLock[unitdef] == nil then
        GG.UnitDefSoundLock[unitdef] = 0
    end
    timeTable = {soloGo = 0, backgroundGo = 0}

    while true do
        T = Spring.GetSelectedUnits()
        boolSelected = false
        foreach(T, function(id)
            if id == unitID then boolSelected = true end
        end)

        if boolSelected == true then
            if GG.UnitDefSoundLock[unitdef] <= 0 then
                GG.UnitDefSoundLock[unitdef] = 1
                openerIndex = iRand(1, #dataTable.opener)
                otime = dataTable.opener[openerIndex]
                -- opening
                Spring.PlaySoundFile(path .. "opener/opener" .. openerIndex ..
                                         ".ogg", loudness)
                Sleep(otime)
                -- work out solos

                soloNumber = iRand(1, dataTable.soloNumber)
                if dataTable.storyBoard then
                    storyBoardIndex = dataTable.storyBoard.Index + 1
                    soloNumber = dataTable.storyBoard[storyBoardIndex]
                end
                while soloNumber > 0 do
                    if timeTable.backgroundGo <= 0 then
                        backgroundIndx = iRand(1, #dataTable.background)
                        Spring.PlaySoundFile(
                            path .. "background/background" .. backgroundIndx ..
                                ".ogg", loudness)
                        timeTable.backgroundGo =
                            dataTable.background[backgroundIndx]
                    end
                    -- if there is no storyboard randomize
                    currentSolo = iRand(1, #dataTable.solo)
                    if dataTable.storyBoard then
                        currentSolo = dataTable.storyBoard[dataTable.storyBoard
                                          .index]
                        dataTable.storyBoard.index =
                            dataTable.storyBoard.index + 1
                    end

                    if timeTable.soloGo <= 0 then
                        soloIndx = iRand(1, #dataTable.solo)
                        Spring.PlaySoundFile(
                            path .. "single/single" .. soloIndx .. ".ogg",
                            loudness)
                        timeTable.soloGo = dataTable.solo[soloIndx]
                    end
                    maxRestTime = math.min(timeTable.soloGo,
                                           timeTable.backgroundGo)
                    Sleep(maxRestTime)
                    timeTable.soloGo, timeTable.backgroundGo =
                        timeTable.soloGo - maxRestTime,
                        timeTable.backgroundGo - maxRestTime

                    soloNumber = soloNumber - 1
                end
                remainTime = math.max(math.abs(timeTable.backgroundGo) - 500, 1)
                Sleep(remainTime)
                -- play Closer
                currentCloser = iRand(1, #dataTable.closer)
                Spring.PlaySoundFile(
                    path .. "closer/closer" .. currentCloser .. ".ogg", loudness)
                Sleep(dataTable.closer[currentCloser])

                -- release lock
                GG.UnitDefSoundLock[unitdef] = 0
            else
                Sleep(500)
            end
        end

        rest = iRand(restIntervallMin, restIntervallMax)
        Sleep(rest)
    end
end

-- >pulsates a UnitsSpeed
-- >Gets a CurveFunction, a UnitID, and a Maxtime
function pulsateMovement(unitID, Maxtime, curveFunction, resolution)
    resolution = resolution or 1000
    times = 0
    while times < Maxtime do
        factor = curveFunction(times)
        factor = math.min(1.0, math.max(0.00001, factor))
        setSpeedEnv(unitID, factor)
        Sleep(resolution)
        times = times + resolution
    end

    return true
end

function luaAttach(transporteeID, transporterID, offx, offy, offz, resolution)
    ux, uy, uz = Spring.GetUnitPosition(transporterID)
    tx, ty, tz = Spring.GetUnitPosition(transporteeID)
    tx, ty, tz = tx - ux, ty - uz, tz - uz
    tx, ty, tz = tx + ox, ty + oy, tz + oz
    rX, rY, rZ = Spring.GetUnitDirection(transporterID)
    Spring.MoveCtrl.Enable(transporteeID, true)

    while (Spring.GetUnitIsDead(transporteeID) == false and
        Spring.GetUnitIsDead(transporterID) == false) do
        -- Transformation
        ox, oy, oz = Spring.GetUnitPosition(transporterID)
        ox, oy, oz = ux - ox, uy - oy, uz - oz
        NewPosition = {tx + ox, ty + oy, tz + oz}

        -- Rotation
        nX, nY, nZ = Spring.GetUnitDirection(transporterID)
        dX, dY, dZ = rX - nX, rY - nZ, rZ - nZ
        Spring.Echo("TODO- Apply Rotation")
        MoveCtrl.SetPosition(transporteeID, NewPosition.x + offx,
                             NewPosition.y + offy, NewPosition.z + offz)
        --
        Sleep(resolution)
    end

    Spring.MoveCtrl.Disable(transporteeID, true)
end

function delayTillComplete(unitID)
    _, _, _, _, bP = Spring.GetUnitHealth(unitID)
    if bP == nil then return false end
    while bP < 1.0 do
        Sleep(100)
        _, _, _, _, bP = Spring.GetUnitHealth(unitID)
    end
    return true
end

-- > Plays a DescriptorTable in Order reciving Signals for a global soundOrderTable	
function playSoundInOrder(soundInOrderTable, name)

    for i = 1, #soundInOrderTable, 1 do
        if soundInOrderTable[i].boolOnce == true then
            if soundInOrderTable[i].predelay then
                Sleep(soundInOrderTable[i].predelay)
            end
            Spring.PlaySoundFile(soundInOrderTable[i].sound, 1.0)
            if soundInOrderTable[i].postdelay then
                Sleep(soundInOrderTable[i].postdelay)
            end

        else
            if name then
                if GG.soundInOrderTable == nil then
                    GG.soundInOrderTable = {}
                end

                if GG.soundInOrderTable[name] == nil then
                    GG.soundInOrderTable[name] = {}
                end
                if GG.soundInOrderTable[name].signal == nil then
                    GG.soundInOrderTable[name].signal = true
                end

                while GG.soundInOrderTable[name].signal == true do
                    if soundInOrderTable[i].predelay then
                        Sleep(soundInOrderTable[i].predelay)
                    end
                    if type(soundInOrderTable[i].sound) == "table" then
                        dice = math.floor(
                                   math.random(1, #soundInOrderTable[i].sound))
                        Spring.PlaySoundFile(soundInOrderTable[i].sound[dice],
                                             1.0)
                    else
                        Spring.PlaySoundFile(soundInOrderTable[i].sound, 1.0)
                    end
                    if soundInOrderTable[i].postdelay then
                        Sleep(soundInOrderTable[i].postdelay)
                    end
                end

                GG.soundInOrderTable[name].signal = true
            end
        end
    end
end

-- This Section contains standalone functions to be executed as independent systems monitoring and handling lua-stuff
-- mini OS Threads

-- > Unit Statemachine
function stateMachine(unitid, sleepTime, State, stateT)
    local Time = 0
    local StateMachine = stateT
    local stateStorage = {}
    while true do

        if not stateStorage[State] then stateStorage[State] = {} end

        State, stateStorage = StateMachine[State](unitid, Time, stateStorage)
        Sleep(sleepTime)
        Time = Time + sleepTime
    end
end

-- > Gadget:missionScript expects frame, the missionTable, which contains per missionstep the following functions
-- e.g. [1]= {situationFunction(frame,TABLE,nr), continuecondtion(frame,TABLE,nr,boolsuccess), continuecondtion(frame,TABLE,nr,boolsuccess)}
-- in Addition every Functions Table contains a MissionMap which consists basically of a statediagramm starting at one
-- MissionMap={[1]=> {2,5},[2] => {1,5},[3]=>{5},[4]=>{5},[5]=>{1,5}}
function missionHandler(frame, TABLE, nr)
    -- wethere the mission is continuing to the next nr
    boolContinue = false
    -- wether the mission has a Outcome at all
    boolSituationOutcome = TABLE[nr].situationFunction(frame, TABLE, nr)

    -- we return nil if the situation has no defined outcome
    if not boolSituationOutcome then return end

    if not TABLE[nr].continuecondtion then
        boolContinue = true
    elseif type(TABLE[nr].continuecondtion) == 'number' then
        if frame > TABLE[nr].continuecondtion then boolsuccess = true end
    elseif type(TABLE[nr].continuecondtion) == 'function' then
        boolContinue = TABLE[nr].continuecondtion(frame, TABLE, nr, boolsuccess)
    end

    if boolContinue == true then
        return TABLE[nr].continuecondtion(frame, TABLE, nr, boolsuccess)
    else
        return nr
    end
end

-- > jobfunc header jobFunction(unitID,x,y,z, Previousoutcome) --> checkFuncHeader checkFunction(unitID,x,y,z,outcome)
function getJobDone(unitID, dataTable, jobFunction, checkFunction, rest)
    local dataT = dataTable
    local spGetUnitPosition = Spring.GetUnitPosition
    x, y, z = spGetUnitPosition(unitID)
    outcome = false

    while checkFunction(unitID, dataT, x, y, z, outcome) == false do
        x, y, z = spGetUnitPosition(unitID)
        outcome = jobFunction(unitID, dataT, x, y, z, outcome)
        Sleep(rest)
    end
end

-- >pumpOS shows a circularMovingObject
function circulOS(TableOfPieces, CircleCenter, axis, speed, arcStart, arcEnd,
                  osKey)
    if not GG.OsKeys then GG.OsKeys = {} end
    if not GG.OsKeys[osKey] then GG.OsKeys[osKey] = true end

    start, ending = arcStart, arcEnd

    hideT(TableOfPieces)
    PieceLength = (2 * math.pi) / #TableOfPieces

    dirSign = -1
    if speed <= 0 then dirSign = 1 end
    reset(CircleCenter)

    accumulatedTurn = 0
    modulatedTurn = 0

    Spin(CircleCenter, axis, math.rad(speed), 0)
    while GG.OsKeys[osKey] == true do
        hideT(TableOfPieces)
        i = start
        if i > #TableOfPieces then i = 1 end
        if i < 1 then i = #TableOfPieces end

        while i ~= ending do

            Show(TableOfPieces[i])

            i = i + dirSign

            if i > #TableOfPieces then i = 1 end
            if i < 1 then i = #TableOfPieces end
        end

        if math.abs(modulatedTurn - math.abs(accumulatedTurn)) > PieceLength then
            start = start + dirSign
            if start > #TableOfPieces then start = 1 end
            if start < 1 then start = #TableOfPieces end

            ending = ending + dirSign
            if ending > #TableOfPieces then ending = 1 end
            if ending < 1 then ending = #TableOfPieces end
            modulatedTurn = modulatedTurn + PieceLength
        end

        accumulatedTurn = accumulatedTurn + math.abs(math.rad(speed) / 10)
        Sleep(100)
    end

    while start ~= ending do
        hideT(TableOfPieces)
        i = start
        if i > #TableOfPieces then i = 1 end
        if i < 1 then i = #TableOfPieces end

        while i ~= ending do

            Show(TableOfPieces[i])

            i = i + dirSign

            if i > #TableOfPieces then i = 1 end
            if i < 1 then i = #TableOfPieces end
        end

        if math.abs(modulatedTurn - math.abs(accumulatedTurn)) > PieceLength then
            start = start + dirSign
            if start > #TableOfPieces then start = 1 end
            if start < 1 then start = #TableOfPieces end

            modulatedTurn = modulatedTurn + PieceLength
        end

        accumulatedTurn = accumulatedTurn + math.abs(math.rad(speed) / 10)
        Sleep(100)
    end
    hideT(TableOfPieces)
    GG.OsKeys[osKey] = nil
end

function portalOS(piecesTable, center, pieceLength, axis, moveDistance, speed,
                  prePostShow, SleepTime)
    while true do
        hideT(piecesTable)
        Move(center, axis, 0, 0)
        for i = 1, #piecesTable, 1 do
            Move(center, axis, pieceLength * i, speed)
            if prePostShow == true then Show(piecesTable[i]) end
            WaitForMove(center, axis)
            if prePostShow == false then Show(piecesTable[i]) end
        end
        Sleep(SleepTime)
    end
end

-- > genericOS 
function genericOS(unitID, dataTable, jobFunctionTable, checkFunctionTable, rest)
    local checkFunctionT = checkFunctionTable
    local jobFunctionT = jobFunctionTable
    local dataT = dataTable
    local spGetUnitPosition = Spring.GetUnitPosition

    x, y, z = spGetUnitPosition(unitID)

    outcomeTable = makeTable(false, #jobFunctionT)
    boolAtLeastOneNotDone = true
    while boolAtLeastOneNotDone == true do
        x, y, z = spGetUnitPosition(unitID)
        for i = 1, #jobFunctionT do
            outcomeTable[i] = jobFunctionT[i](unitID, x, y, z, outcomeTable[i],
                                              dataT)
            Sleep(rest)
        end
        boolAtLeastOneNotDone = true
        for i = 1, #checkFunctionT do
            boolAtLeastOneNotDone = checkFunction(unitID, x, y, z,
                                                  outcomeTable[i]) and
                                        boolAtLeastOneNotDone
            Sleep(rest)
        end
    end
end

-- >encapsulates a function, stores arguments given, chooses upon returned nil, 
--	the most often chosen argument
function heuristicDefault(fooNction, fname, teamID, ...)

    if not GG[fname] then GG[fname] = {} end
    if not GG[fname][teamID] then GG[fname][teamID] = {} end

    local heuraTable = GG[fname][teamID]
    ArgumentCounter = 1
    for k, v in pairs(arg) do
        if not heuraTable[ArgumentCounter] then
            heuraTable[ArgumentCounter] = {}
        end
        if not heuraTable[ArgumentCounter][v] then
            heuraTable[ArgumentCounter][v] = 1
        else
            heuraTable[v] = heuraTable[ArgumentCounter][v] + 1
        end
        ArgumentCounter = ArgumentCounter + 1
    end

    results = fooNction(args)

    if not results then
        -- devalue current Arguments
        ArgumentCounter = 1
        for k, v in pairs(arg) do
            heuraTable[ArgumentCounter][v] = heuraTable[ArgumentCounter][v] - 1
            ArgumentCounter = ArgumentCounter + 1
        end

        -- call the function with the most likely arguments
        newWorkingSet = {}
        ArgumentCounter = 1
        for k, v in pairs(arg) do
            highestVal, highestCount = 0, 0
            for i, j in pairs(heuraTable[ArgumentCounter]) do
                if heuraTable[ArgumentCounter][v] > highestCount then
                    highestCount = heuraTable[ArgumentCounter][v]
                    highestVal = v
                end
            end
            table.insert(newWorkingSet, highestVal)
            ArgumentCounter = ArgumentCounter + 1
        end
        results = fooNction(newWorkingSet)
        Spring.Echo("FallBack::Heuristic Default")
        assert(results,
               "Heuristic Default has inssuficient working samples.Returns Nil")
        GG[fname][teamID] = heuraTable
        return results
    else
        GG[fname][teamID] = heuraTable
        return results
    end
end



function hoverAboveGround(unitID, distanceToHover, step, boolTurnTowardsGoal, boolInMove)
if not step then step = 0.1 end
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
Spring.MoveCtrl.Enable(unitID, true)
Spring.MoveCtrl.SetRotation(unitID, 0,0,0)

	while true do
		x,y,z = spGetUnitPosition(unitID)
        boolInMove = false
        orgx, orgz = x,z
        CommandTable = Spring.GetUnitCommands(unitID, 1)
        if CommandTable and CommandTable[1] and CommandTable[1].id ==  CMD.MOVE then
            cmd = CommandTable[1]
              if math.abs(cmd.params[1] - x) > 10 then
                        if cmd.params[1] < x then
                            x = x -step
                        elseif cmd.params[1] > x then
                             x = x +step
                        end
                        boolInMove= true
              end
              if math.abs(cmd.params[3] - z) > 10 then
                        if cmd.params[3] < z then
                            z = z -step
                        elseif cmd.params[3] > z then
                             z = z +step
                        end
                        boolInMove= true
              end
        end

        if boolTurnTowardsGoal then
            _,orgRot,_ = Spring.GetUnitRotation(unitID) 
            rot = math.atan2(orgx-x, -(orgz-z))
            rot = mix(rot, orgRot, 0.95)
            Spring.MoveCtrl.SetRotation(unitID, 0,rot,0)
        end
        if x then
		  gh = spGetGroundHeight(x,z)
		  Spring.MoveCtrl.SetPosition(unitID, x, math.max(0,gh) + distanceToHover, z)
        end
		Sleep(29)
	end
end

function scaleOfChange(a, b, trigger) val = math.abs(a - b) end

-- ==============================================Eventstream Jobs
-- action(id,frame, StreamUnits[id].persPack)

-- >Expects in the Package {updaterate, Pos, DefID, hitpoints, assignedSubAI, buildid}
function buildJob(id, frame, Package)

    -- check if we are there yet

    -- if we are grab for the building

    -- else move it

    -- if the job is completed return yourself to the unitpool
    -- GG.UnitPool:Return(id,teamid,assignedSubAI,father)
    return nextFrame, Package
end

-- >Expects in the Package {updaterate, Pos, DefID, hitpoints, assignedSubAI, guardid}
function guardJob(id, frame, Package)

    -- check if we are there yet

    -- if we are grab for the building

    -- else move it

    -- if the job is completed return yourself to the unitpool
    -- GG.UnitPool:Return(id,teamid,assignedSubAI,father)

    return nextFrame, Package
end

-- >Expects in the Package {updaterate, Pos, DefID, hitpoints, assignedSubAI, teamMembers}
function exploreJob(id, frame, Package)

    -- check if we are there yet

    -- if we are grab for the building

    -- else move it

    -- if the job is completed return yourself to the unitpool
    -- GG.UnitPool:Return(id,teamid,assignedSubAI,father)
    return nextFrame, Package
end

-- >Turn Piece into various diretions within range
function randomRotate(Piecename, axis, speed, rangeStart, rangeEnd)
    while true do
        Turn(Piecename, axis, math.rad(math.random(rangeStart, rangeEnd)), speed)
        WaitForTurn(Piecename, axis)
        Sleep(1000)
    end
end

function wiggleOS(piecename, xDown, xUp, yDown, yUp, zDown, zUp, speed)
    while true do
        tP(piecename, math.random(xDown, xUp), math.random(yDown, yUp),
           math.random(zDown, zUp), speed)
        WaitForTurns(piecename)
    end

end

function shiverOS(piecename, xDown, xUp, yDown, yUp, zDown, zUp, speed)
    while true do
        mP(piecename, math.random(xDown, xUp), math.random(yDown, yUp),
           math.random(zDown, zUp), speed)
        WaitForMoves(piecename)
    end

end

-- > breath 
function breathOS(body, lowDist, upDist, LegTable, LegNumber, degree, Time,
                  count)
    leglength = upDist / 2

    bLoop = true
    frames = 30
    lcount = count or 1
    if count and count > 0 then bLoop = false end

    if lowDist > upDist then return end

    while bLoop == true or lcount > 0 do

        dist = math.random(lowDist, upDist)
        percentage = dist / upDist

        degreeC = percentage * degree
        -- downDeg=math.asin(leglength*dist)
        -- upDeg= math.asin()

        -- speedDeg= 0.5
        degHalf = degreeC / 9 + 0.001
        degHalfMins = degHalf * -1.3
        degreeMinus = degreeC * -1.7

        mSyncIn(body, 0, -dist, 0, Time)
        for i = 1, LegNumber, 1 do
            tSyncIn(LegTable[i].up, degreeC, 0, 0, Time)
            tSyncIn(LegTable[i].down, degreeMinus, 0, 0, Time)

        end

        WaitForMove(body, y_axis)
        Sleep(100)
        mSyncIn(body, 0, 0, 0, Time)
        for i = 1, LegNumber do
            tSyncIn(LegTable[i].up, degHalf, 0, 0, Time)
            tSyncIn(LegTable[i].down, degHalfMins, 0, 0, Time)
        end
        WaitForMove(body, y_axis)
        Sleep(100)
        lcount = lcount - 1
    end
end

function mortallyDependant(id, LiveGiver, checkTime, boolSelfDestruct,
                           boolReclaimed)

    while LiveGiver ~= nil and not Spring.GetUnitIsDead(LiveGiver) do
        Sleep(checkTime)
    end
    Spring.DestroyUnit(id, boolSelfDestruct, boolReclaimed)
end

-- >plays the sounds handed over in a table 
function playSoundByUnitTypOS(unitID, loudness, SoundNameTimeT)
    local SoundNameTimeTable = SoundNameTimeT
    unitdef = Spring.GetUnitDefID(unitID)

    while true do
        dice = 1
        if #SoundNameTimeTable > 1 then
            dice = math.random(1, #SoundNameTimeTable)
        end

        PlaySoundByUnitDefID(unitdef, SoundNameTimeTable[dice].name, loudness,
                             SoundNameTimeTable[dice].Time, 1)
        Sleep(1000)
    end
end

-- >partOfShipPartOfCrew binds a creature to a piece
function partOfShipPartOfCrew(point, VaryFooID, motherID)
    Spring.SetUnitNeutral(VaryFooID, true)
    Spring.UnitScript.UnitAttach(point, VaryFooID)
    Spring.MoveCtrl.Enable(VaryFooID, true)

    while GG.BuildCompleteAvatara[motherID] == false do
        tx, ty, tz = spGetUnitPiecePosDir(unitID, VaryFooID)
        roX, roY, roZ = roX + math.random(-100, 100) / 1000,
                        roY + math.random(-100, 100) / 1000,
                        roZ + math.random(-100, 100) / 1000
        Spring.MoveCtrl.SetRotation(VaryFooID, roX, roY, roZ)
        Sleep(500)
    end

    if GG.BuildCompleteAvatara[motherID] == true then
        Spring.SetUnitAlwaysVisible(VaryFooID, false)
        Spring.DestroyUnit(VaryFooID, false, true)
    else
        Spring.UnitScript.DropUnit(VaryFooID)
        Spring.MoveCtrl.Disable(VaryFooID)
    end
end

function lifeTime(unitID, timeToRest, boolReclaimed, boolSelfdestroyed,
                  finalizeFunction)
    boolReclaimed, boolSelfdestroyed = boolReclaimed or false,
                                       boolSelfdestroyed or false
    Sleep(timeToRest)
    if finalizeFunction then finalizeFunction() end
    Spring.DestroyUnit(unitID, boolReclaimed, boolSelfdestroyed)
end


-- ================================================================================================================
-- OS Support Functionality

-- > Sorts Pieces By Height in Model
function sortPiecesByHeight(listOfPieces)
    local bucketSortList = {}
    pieceHeigthMap = {}
    lowestValue = math.huge
    heighestValue = -math.huge

    for num, pieceNum in ipairs(listOfPieces) do
        px, py, pz = Spring.GetUnitPiecePosition(unitID, pieceNum)
        pieceHeigthMap[pieceNum] = math.ceil(py)
        bucketSortList[math.ceil(py)] = {}
        if py < lowestValue then lowestValue = math.ceil(py) end
        if py > heighestValue then heighestValue = math.ceil(py) end
    end

    for pieceNum, Heigth in pairs(pieceHeigthMap) do
        bucketSortList[Heigth][#bucketSortList[Heigth] + 1] = pieceNum
    end

    return bucketSortList, lowestValue, heighestValue
end

-- >Transformer OS: Assembles from SubUnits in Team a bigger Unit
function assemble(center, unitid, udefSub, CubeLenghtSub, nrNeeded, range,
                  AttachPoints)
    -- Move UnderGround

    createGlobalTableFromAcessString("InfoTable[" .. unitid "].boolBuildEnded",
                                     true)

    piecesTable = Spring.GetUnitPieceList(unitid)
    for i = 1, #piecesTable do piecesTable[i] = piece(piecesTable[i]) end
    hideT(piecesTable)
    if AttachPoints then
        AttachPoints = sortPiecesByHeight(AttachPoints)
    else
        AttachPoints = sortPiecesByHeight(piecesTable)
    end
    indexP = 1
    hx, hy, hz = spGetUnitPiecePosDir(untid, AttachPoints[indexP])
    base = Spring.GetGroundHeight(hx, hz)
    DistanceDown = base - hy
    Move(center, y_axis, DistanceDown, 0)

    createGlobalTableFromAcessString("BoundToThee")

    oldHP = Spring.GetUnitHealth(unitid)
    newHP = oldHP

    while nrAdded < nrNeeded and Spring.GetUnitIsDead(unitid) == false do
        Move(center, y_axis, DistanceDown * (nrAdded / nrNeeded), 1.5)
        -- check VaryFoos around you
        allSub = {}
        -- check wether we are under Siege and send the Underlings not allready buildin
        newHP = Spring.GetUnitHealth(unitid)
        boolUnderAttack = oldHP > newHP
        oldHP = newHP
        if GG.InfoTable[unitid].boolUnderAttack == true then
            -- defend moma
            ax, ay, az = Spring.GetUnitNearestEnemy(untid)
            for i = 1, #allSub do
                if not GG.BoundToThee[allSub[i]] then
                    Spring.SetUnitMoveGoal(allSub[i], ax, ay, az)
                end
            end

        else -- build on
            -- get nextPiece above ground
            attachP = AttachPoints[math.min(indexP, #AttachPoints)]
            indexP = indexP + 1

            x, y, z = Spring.GetUnitPiecePosDir(untid, attachP)
            for i = 1, #allSub do

                ux, uy, uz = Spring.GetUnitPosition(allSub[i])
                if (ux - x) * (uy - y) * (uz - z) < 50 then -- integrate it into the Avatara
                    if not GG.BoundToThee[allSub[i]] then
                        StartThread(partOfShipPartOfCrew, attachP, allSub[i],
                                    unitid)
                    end
                else
                    Spring.SetUnitMoveGoal(allSub[i], x, y, z)
                end
            end
        end
    end

    GG.BoundToThee[unitid] = nil
    MoveCtrl.Enable(unitID, false)
    GG.InfoTable[unitid].boolBuildEnded = true
    boolComplete = true
    Move(center, y_axis, 0, 12)
    showT(piecesTable)
    return true
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

function GetSetSharedOneTimeResult(key, calcDataFunction)
 if not GG.SharedResult then SetSharedOneTimeResult(key, calcDataFunction()) end
 if not GG.SharedResult[key] then SetSharedOneTimeResult(key, calcDataFunction()) end
 return GG.SharedResult[key]
end
-- > shared Computation
function sharedComputationResult(key, func, data, frameInterval, GameConfig)
    if not GG.SharedComputationResult then GG.SharedComputationResult = {} end
    if not GG.SharedComputationResult[key] then
        GG.SharedComputationResult[key] =
            {frame = Spring.GetGameFrame(), result = func(data, GameConfig)}
    end

    currentFrame = Spring.GetGameFrame()

    -- recomputate sharedResults
    if GG.SharedComputationResult[key].frame + frameInterval < currentFrame then
        GG.SharedComputationResult[key].result = func(data, GameConfig)
        GG.SharedComputationResult[key].frame = currentFrame
    end

    return GG.SharedComputationResult[key].result

end

function onDeCloakNeverRecloak(unitID)
    local spGetUnitIsCloaked = Spring.GetUnitIsCloaked

    Sleep(100)
    waitTillComplete(unitID)
    Sleep(100)

    Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
    SetUnitValue(COB.WANT_CLOAK, 1)
    SetUnitValue(COB.CLOAKED, 1)
    while (spGetUnitIsCloaked(unitID) == false) do Sleep(100) end

    boolCloaked = spGetUnitIsCloaked(unitID)
    while true do
        boolCloaked = spGetUnitIsCloaked(unitID)
        Sleep(100)

        if boolCloaked == false and boolDeCloaked == false then
            boolDeCloaked = true
        end

        if boolCloaked == true and boolDeCloaked == true then
            SetUnitValue(COB.WANT_CLOAK, 0)
            SetUnitValue(COB.CLOAKED, 0)
        end

        Sleep(100)
    end
end

function debugAimLoop(sleepMS, weaponID)
    restTime = sleepMS or 1
    while true do
        angleGood, loaded, reloadFrame, salvoLeft, numStockpiled =
            Spring.GetUnitWeaponState(unitID, weaponID)
        if angleGood then
            echo("Weapon: Anglegood->" .. toString(angleGood) .. " Loaded->" ..
                     toString(loaded) .. " reloadFrame->" ..
                     toString(reloadFrame))
        end

        px, py, pz, dx, dy, dz = Spring.GetUnitWeaponVectors(unitID, weaponID)
        if px then echo("Weapon: Vector ->", {px, py, pz, dx, dy, dz}) end
        commands = Spring.GetUnitCommands(unitID, weaponID)

        if commands and type(commands) == "table" and commands[1] and
            commands[1].id and commands[1].id == CMD.ATTACK then
            attackedID = commands[1].params[1]

            boolWeaponCanFire = Spring.GetUnitWeaponCanFire(unitID, weaponID)
            echo("Units Weapon can fire: " .. toString(boolWeaponCanFire))

            resultType, tID = Spring.GetUnitWeaponTarget(unitID, weaponID)
            if resultType == 1 and uID then
                echo("Target is Unit ->" .. tID)
            end

            if attackedID then
                bSucces = Spring.GetUnitWeaponHaveFreeLineOfFire(unitID,
                                                                 weaponID)
                if bSucces then
                    echo("Raytrace reaches Goal:" .. toString(bSucces))
                end

                boolTargetInRange = Spring.GetUnitWeaponTestRange(unitID,
                                                                  weaponID,
                                                                  attackedID)
                if boolTargetInRange then
                    echo("Target is in Range: " .. toString(boolTargetInRange))
                end
            end
        end
        Sleep(restTime)
    end
end

function vtolLoop(unitID, plane, restTimeMs, timeBetweenFlightsMs, factor)
    fact = factor or 1.0
    padX, padY, padZ = Spring.GetUnitPosition(unitID)
    GameConfig = getGameConfig()
    if GG.VTOLFlightPads == nil then
     GG.VTOLFlightPads = {Lock = nil} 
    end

    while GG.VTOLFlightPads.Lock ~= unitID do
        while (GG.VTOLFlightPads.Lock ~= nil) do 
            Sleep(100) 
        end        
        GG.VTOLFlightPads.Lock = unitID
        if GG.VTOLFlightPads.Lock and GG.VTOLFlightPads.Lock == unitID then       break end
        Sleep(100)
    end
    myPosition = #GG.VTOLFlightPads +1
    GG.VTOLFlightPads[myPosition] = {x = padX, y = padY, z = padZ, unitID= unitID, plane = plane}       
    GG.VTOLFlightPads.Lock = nil

    --echo(GG.VTOLFlightPads)

    while #GG.VTOLFlightPads < 2 do
        Sleep(1000)
       -- echo(" Waiting for second")
    end

    function showHidePlane(boolShow, plane)
        if boolShow == true then
            Show(plane)
        else
            Hide(plane)
        end
    end

    function getRandomPostionNotMine(myPosition)
        targetDice = math.random(1, #GG.VTOLFlightPads)
        while targetDice == myPosition and type(GG.VTOLFlightPads[targetDice]) ~= "table" do
            Sleep(100)
            targetDice = math.random(1, #GG.VTOLFlightPads)
        end

        return targetDice
    end

    function startPlaneFromLocation(unitID, plane, locationIndex) 

        Hide(plane)
        location = GG.VTOLFlightPads[locationIndex]
        gaiaTeamID = Spring.GetGaiaTeamID()
        vtolTypes = getCivilianVTOLTypes(UnitDefs)
        planeID = Spring.CreateUnit( randDict(vtolTypes), location.x, location.y, location.z, 1, gaiaTeamID)
        if planeID then
            Spring.SetUnitAlwaysVisible(planeID, true)
            Spring.SetUnitNeutral(planeID, true)
            Spring.SetUnitNoSelect(planeID, true)
        end
        return planeID
    end

    function movePlaneToLocation(planeID, locationIndex, v)    
        location = GG.VTOLFlightPads[locationIndex]
        while doesUnitExistAlive(planeID) do
            Command(planeID, "go", location)           
            x,y,z = Spring.GetUnitPosition(planeID)
            assert(location)
            if distance({x=x,y=y,z=z },location) < 200 then
                Spring.MoveCtrl.Enable(planeID, true)
                for i=1, 1000,5 do
                    targetPos = mixTable({x= location.x, y= location.y, z= location.z }, 
                        {x=x,y=y,z=z },
                         i/1000)
                    Spring.MoveCtrl.SetPosition(planeID, targetPos.x, targetPos.y, targetPos.z)
                    Sleep(30)
                end
                Spring.DestroyUnit(planeID, true, false)
                return true
            end   
            Sleep(1000)         
        end
        return false
    end

    boolStartRemote = maRa()
    if boolStartRemote == true then 
        showHidePlane(false, plane)
    end
    lastValue = math.random(-180,180)
    Turn(plane,y_axis,math.rad(lastValue),0)
    Sleep(15000)
    targetDice = getRandomPostionNotMine(myPosition)
    if not GG.VTOLCounter then GG.VTOLCounter= 0 end
    while true do       
        targetDice = getRandomPostionNotMine(myPosition)
        randSleep= (math.random(1,5)*1000) + restTimeMs

        Sleep(randSleep)
        reset(plane,0)          
        --echo("Flying  At Home")
        targetValue = math.random(0,90)*randSign()
        Turn(plane,y_axis,math.rad(targetValue), 0)
        Sleep(200)        

        while GG.VTOLCounter > GameConfig.vtolInAirMax do
            Sleep(1000)
        end   
        GG.VTOLCounter = GG.VTOLCounter + 1
        planeID = startPlaneFromLocation(unitID, plane, myPosition) 

        movePlaneToLocation(planeID, targetDice) 
        GG.VTOLCounter = GG.VTOLCounter - 1
        showHidePlane(false, plane)
        boolStartRemote = true
        randSleep= (math.random(1,5)*1000) + timeBetweenFlightsMs
        Sleep(randSleep)
    end
end

function headingChangeDetector(unitID,  boolTurnLeft, boolTurning, boolDebugPrintDiff)
    assert(unitID)
    TurnCount = 0
    headingOfOld = Spring.GetUnitHeading(unitID)
    while true do
        Sleep(250)
 
        tempHead = Spring.GetUnitHeading(unitID)
        if boolDebugPrintDiff then Spring.Echo("Current Heading"..tempHead) end
        if tempHead ~= headingOfOld then
            TurnCount = TurnCount + 1
            if TurnCount > 3 then
                boolTurning = true
            end
        else
            TurnCount = 0
            boolTurning = false
        end
        if tempHead ~= nil then
            boolTurnLeft = headingOfOld > tempHead
            headingOfOld = tempHead
        end
    end
end



function spawnCegCyclicAtUnitPiece(unitID, pieceID, cegname, delay)
    while true do
        Sleep(delay)
        spawnCegAtPiece(unitID, pieceID, cegname, 150)
        Sleep(1)
    end
end

function displayPercentages(TableOfPieces, timeToCountUp)
    hideT(TableOfPieces)
    totalNrOfPieces = #TableOfPieces
    timeSliceMs = math.ceil(timeToCountUp/math.max(1,totalNrOfPieces))
    accumulated = 0
    index= 1
    while accumulated <= timeToCountUp do
        Sleep(timeSliceMs)
        showT(TableOfPieces,1,index)
        index = index + 1
        accumulated = accumulated + timeSliceMs
    end
end


function hidePercentages(TableOfPieces, timeToCountUp)
    showT(TableOfPieces)
    totalNrOfPieces = #TableOfPieces
    timeSliceMs = math.ceil(timeToCountUp/math.max(1,totalNrOfPieces))
    accumulated = 0
    index= 1
    while accumulated <= timeToCountUp do
        Sleep(timeSliceMs)
        hideT(TableOfPieces,1,index)
        index = index + 1
        accumulated = accumulated + timeSliceMs
    end
end