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

--================================================================================================================
-- Animation Functions
--================================================================================================================
-- aproximates a object having mass fand feathering after a turn to give the ilusion of physicality
function turnHeavy(mass, pieceN, axis,  startdeg, targetdeg, speed, featherConst)
if featherConst >= 1.0 then featherConst = 0.999999999 end
WTurn(pieceN, axis, math.rad(targetdeg),speed)
beschleunigung= mass/speed
weg = (beschleunigung/1000)*featherConst
while (math.abs(weg)> 0.001) do
	WTurn(pieceN, axis, math.rad(targetdeg+weg),speed)
	weg= weg*featherConst*-1
end

WTurn(pieceN, axis, math.rad(targetdeg),speed)
end

function MoveUnitToUnit(id, targetId, speed, ox,oy,oz)
	tx,ty,tz = Spring.GetUnitPosition(targetId)
	MoveUnit(id,tx,ty,tz,speed,ox,oy,oz)
end


-->Move Unit to Position
function MoveUnit(id, px,py,pz, speed,ox,oy,oz )
ox,oy,oz = ox or 0,oy or 0,oz or 0

if not speed or speed == 0 then 
	Spring.SetUnitPosition(id,px + ox,py +oy,pz + oz)
	return
end

Spring.MoveCtrl.Enable(id,true)
u={}
p={x=px,y=py,z=pz}
u.x,u.y,u.z = Spring.GetUnitPosition(id)

dist= distance(p,u)
timeInMsSecond = dist/speed
timeInto = 0
while distance(p,u) > 0.1 do

	u.x,u.y,u.z = Spring.GetUnitPosition(id)
	v= mix(p,u,timeInto/timeInMsSecond)
	Spring.MoveCtrl.SetPosition(id, v.x+ ox, v.y + oy, v.z +oz)
	timeInto= math.min(timeInMsSecond,timeInto+1)
	Sleep(1)
end

Spring.MoveCtrl.Disable(id,true)
end

-->CombinedWaitForMove
function WMove(lib_piece, lib_axis, lib_distance, lib_speed)
	assertAxis(lib_axis)
    Move(lib_piece, lib_axis, lib_distance, lib_speed)
    WaitForMove(lib_piece, lib_axis)
end


-->Performs a Animation while a Piece Is in Turn
function whileInTurn(pname,axis, functionToPerform, ...)
	while true == Spring.UnitScript.IsInTurn(pname,axis) do
		functionToPerform(...)
		Sleep(1)
	end

end

-->Performs a Animation while a Piece Is in Turn
function whileInMove(pname,axis, functionToPerform, ...)
	while true == Spring.UnitScript.IsInMove(pname,axis) do
		functionToPerform(...)
		Sleep(1)
	end
end

-->CombinedWaitTurn
function WTurn(lib_piece, lib_axis, lib_distance, lib_speed)
    Turn(lib_piece, lib_axis, lib_distance, lib_speed)
    WaitForTurn(lib_piece, lib_axis)
end

  function pack(...)
      return { ... }, select("#", ...)
    end 

-->Waits for anyTurnToComplete
function WaitForTurns(...)
	local arg = arg
	if (not arg) then arg = {...}; arg.n = #arg end
   if not arg then echo("No arguments for WaitForTurns");   return   end

   typeArg = type(arg)

    if typeArg == "table" then

        for k, v in pairs(arg) do
            if type(v) == "number" then
                WaitForTurn(v, x_axis)
                WaitForTurn(v, y_axis)
                WaitForTurn(v, z_axis)
            end
        end
        return
    elseif typeArg == "number" then
        WaitForTurn(arg, x_axis)
        WaitForTurn(arg, y_axis)
        WaitForTurn(arg, z_axis)
    end
end

-->Wait for a Table of Pieces to finnish theire Turns
function WaitForTurnT(T)
        for k, v in pairs(T) do
            if type(v) == "number" then
                WaitForTurn(v, x_axis)
                WaitForTurn(v, y_axis)
                WaitForTurn(v, z_axis)
            end
        end
end

-->Waits for anyTurnToComplete
function WaitForMoves(...)
	local arg = arg
	if (not arg) then arg = {...}; arg.n = #arg end
   if not arg then  echo("No arguments for WaitForMoves");   return   end

   typeArg = type(arg)

    if typeArg == "table" then

        for k, v in pairs(arg) do
            if type(v) == "number" then

                WaitForMove(v, x_axis)

                WaitForMove(v, y_axis)

                WaitForMove(v, z_axis)
            end
        end
        return
    elseif typeArg == "number" then
        WaitForMove(arg, x_axis)
        WaitForMove(arg, y_axis)
        WaitForMove(arg, z_axis)
    end
end

-->Waits for anyTurnToComplete
function WaitForMoveAllAxis(arg)
	
        WaitForMove(arg, x_axis)
        WaitForMove(arg, y_axis)
        WaitForMove(arg, z_axis)
 
end

function movePieceToPieceWorld(unitID,name, pieceheigth, target, speed)
bx,by,bz= Spring.GetUnitBasePosition(unitID)
wx,wy,wz = Spring.GetUnitPiecePosDir(unitID,target)
MovePieceToPos(name, -1*(bx-wx),-1*(by-wy)-pieceheigth,-1*(bz-wz),0)

end

-->Turn a piece towards a random direction
function turnPieceRandDir(piecename, speed, LIMUPX, LIMLOWX, LIMUPY, LIMLOWY, LIMUPZ, LIMLOWZ)
    if not LIMUPX then
        Turn(piecename, x_axis, math.rad(math.random(-360, 360)), speed)
        Turn(piecename, y_axis, math.rad(math.random(-360, 360)), speed)
        Turn(piecename, z_axis, math.rad(math.random(-360, 360)), speed)
    else

        Turn(piecename, x_axis, math.rad(math.random(LIMLOWX, LIMUPX)), speed)
        Turn(piecename, y_axis, math.rad(math.random(LIMLOWY, LIMUPY)), speed)
        Turn(piecename, z_axis, math.rad(math.random(LIMLOWZ, LIMUPZ)), speed)
    end
end


function turnPieceRandDirStep(piecename, speed, stepsize)
	parts= 360/stepsize
	
        Turn(piecename, x_axis, math.rad(math.random(1,parts)*stepsize), speed)
        Turn(piecename, y_axis, math.rad(math.random(1,parts)*stepsize), speed)
        Turn(piecename, z_axis, math.rad(math.random(1,parts)*stepsize), speed)
 
end

-->Move a piece towards a random direction
function movePieceRandDir(piecename, speed, LIMUPX, LIMLOWX, LIMUPY, LIMLOWY, LIMUPZ, LIMLOWZ)
    if not LIMUPX then
        return
    else
        Move(piecename, x_axis, math.rad(math.random(LIMLOWX, LIMUPX)), speed)
        Move(piecename, y_axis, math.rad(math.random(LIMLOWY, LIMUPY)), speed)
        Move(piecename, z_axis, math.rad(math.random(LIMLOWZ, LIMUPZ)), speed)
    end
end

-->generic AmphibMovementThread: Threaded Creates with the given pieces and animations a Unit that auto changes its animation
-- between land and water
function AmphibMoveThread(unitid, PivotPoints, pieces, updateCycle, moveRatio, nlswimAnimation, nlstopSwimAnimation, nloutOfWaterAnimation, nlbackIntoWaterAnimation, nlwalkAnimation, nlstopWalkAnimation)

    local swimAnimation = nlswimAnimation
    local stopSwimAnimation = nlstopSwimAnimation
    local outOfWaterAnimation = nloutOfWaterAnimation
    local backIntoWaterAnimation = nlbackIntoWaterAnimation
    local walkAnimation = nlwalkAnimation
    local stopWalkAnimation = nlstopWalkAnimation
    local spGetUnitPosition = Spring.GetUnitPosition

    boolInWater = function()
        x, y, z = spGetUnitPosition(unitID)
        h = Spring.GetGroundHeight(x, z)
        if h > 0 then return false else return true end
    end

    boolMoving = function(ox, oy, oz)
        x, y, z = spGetUnitPosition(unitID)
        return math.abs(ox - x) + math.abs(oz - z) + math.abs(oy - y) > 0
    end


    while true do
        while boolInWater() == true do
            ox, oy, oz = spGetUnitPosition(unitID)
            Sleep(math.floor(updateCycle / 2))
            if boolMoving(ox, oy, oz) == true then
                swimAnimation(PivotPoints, pieces)
            else
                Sleep(math.floor(updateCycle / 2))
                stopSwimAnimation(PivotPoints, pieces)
            end
            Sleep(math.ceil(updateCycle / 2))
        end

        outOfWaterAnimation(PivotPoints, pieces)
        while boolInWater() == false do
            ox, oy, oz = spGetUnitPosition(unitID)
            Sleep(math.floor(updateCycle / 2))
            if boolMoving(ox, oy, oz) == true then
                walkAnimation(PivotPoints, pieces)
            else
                Sleep(math.floor(updateCycle / 2))
                stopWalkAnimation(PivotPoints, pieces)
            end
            Sleep(math.ceil(updateCycle / 2))
        end
        backIntoWaterAnimation(PivotPoints, pieces)
        Sleep(50)
    end
end

-->Executes a function every n-times during a move
function whileMovingDo(PIECE, axis, times, fuoonction)
    totalTime = 0
    while (true == Spring.UnitScript.IsInMove(PIECE, axis)) do
        fuoonction(totalTime)
        Sleep(times)
        totalTime = totalTime + times
    end
end


-->Reset a Piece at speed
function reset(piecename, lspeed, boolWaitForIT)
    if not piecename then return end
    speed = lspeed or 0

    Turn(piecename, x_axis, 0, speed)
    Turn(piecename, y_axis, 0, speed)
    Turn(piecename, z_axis, 0, speed)

    Move(piecename, x_axis, 0, speed)
    Move(piecename, y_axis, 0, speed)
    Move(piecename, z_axis, 0, speed, true)
    if boolWaitForIT and boolWaitForIT == true then
        WaitForTurn(piecename, x_axis)
        WaitForTurn(piecename, y_axis)
        WaitForTurn(piecename, z_axis)
    end
end


-->idle Animation Loop
function idleLoop(Body, axis, FrontLeg, RearLeg, degree, BodyBackDeg, speed, Time, boolNoDown)

    Turn(Body, axis, math.rad(degree), speed)
    for i = 1, #FrontLeg, 1 do
        Turn(FrontLeg[i].Up, axis, math.rad(-degree), speed)
        if boolNoDown == false then
            Turn(FrontLeg[i].Down, axis, math.rad(0), speed)
        end
    end

    for i = 1, #RearLeg, 1 do
        Turn(RearLeg[i].Up, axis, math.rad(-degree), speed)
        if boolNoDown == false then
            Turn(RearLeg[i].Down, axis, math.rad(0), speed)
        end
    end

    for i = 1, #FrontLeg, 1 do
        WaitForTurns(FrontLeg[i].Up)
        if boolNoDown == false then
            WaitForTurns(FrontLeg[i].Down)
        end
    end

    for i = 1, #RearLeg, 1 do
        WaitForTurns(RearLeg[i].Up)
        if boolNoDown == false then
            WaitForTurns(RearLeg[i].Down)
        end
    end
    WaitForTurn(Body, axis)
    Sleep(Time)

    Turn(Body, axis, math.rad(BodyBackDeg), speed)
    for i = 1, #FrontLeg, 1 do
        Turn(FrontLeg[i].Up, axis, math.rad(-BodyBackDeg), speed)
        if boolNoDown == false then
            Turn(FrontLeg[i].Down, axis, math.rad(0), speed)
        end
    end

    for i = 1, #RearLeg, 1 do
        Turn(RearLeg[i].Up, axis, math.rad(-BodyBackDeg), speed)
        if boolNoDown == false then
            Turn(RearLeg[i].Down, axis, math.rad(0), speed)
        end
    end
    for i = 1, #FrontLeg, 1 do
        WaitForTurns(FrontLeg[i].Up)
        if boolNoDown == false then
            WaitForTurns(FrontLeg[i].Down)
        end
    end

    for i = 1, #RearLeg, 1 do
        WaitForTurns(RearLeg[i].Up)
        if boolNoDown == false then
            WaitForTurns(RearLeg[i].Down)
        end
    end
    WaitForTurn(Body, axis)
    Sleep(Time)
end

-->counterturns a piece pair
function equiTurn(p1, p2, axis, degv, speed)
    Turn(p1, axis, math.rad(degv), speed)
    Turn(p2, axis, math.rad(-1 * degv), speed)
end-->counterturns a piece pair

function equiTurnIn(p1, p2, axis, degv, times)
    x_rad, y_rad, z_rad = UnitScript.GetPieceRotation(p1)	
	turnInTime(p1, axis, degv, times,math.deg(x_rad), math.deg(y_rad), math.deg(z_rad))
	 x_rad, y_rad, z_rad = UnitScript.GetPieceRotation(p2)	
	turnInTime(p2, axis, degv*-1, times,math.deg(x_rad), math.deg(y_rad), math.deg(z_rad))

end

function breath(p1, p2, axis, degv, speed, itteration, speedreduce,finalfunction)
    for i = 1, itteration do
        equiTurn(p1, p2, axis, degv, speed)
        WaitForTurns(p1, p2)
        equiTurn(p1, p2, axis, degv * -1, speed)
        WaitForTurns(p1, p2)
        speed = speed - speedreduce
    end
	if finalfunction then
		finalfunction(p1,p2)
	end
end

--> Turns a piece in all 3 axis and waits for it
function tP(piecename, x_val, y_val, z_val, speed, boolWaitForIT)
    if piecename == nil then echo("libAnimation::tP got nil piece " .. x_val, y_val) end
    Turn(piecename, x_axis, math.rad(x_val), speed)
    Turn(piecename, y_axis, math.rad(y_val), speed)
    Turn(piecename, z_axis, math.rad(z_val), speed)
    if boolWaitForIT then
        WaitForTurn(piecename, x_axis)
        WaitForTurn(piecename, y_axis)
        WaitForTurn(piecename, z_axis)
    end
end

-->Turns a piece with radiants
function tPrad(piecename, xval, yval, zval, speed)

    Turn(piecename, 1, xval, speed)
    Turn(piecename, 2, yval, speed)
    Turn(piecename, 3, zval, speed)
end

--> synTurns a Piece to arrive at times on all axis
function syncTurn(unitID, piecename, x_val, y_val, z_val, speed)
    speed = math.max(speed, 0.0001)
    maxv = math.max(math.abs(x_val), math.max(math.abs(z_val), math.abs(y_val)))
    if maxv == 0 then
        x_deg, y_deg, z_deg = Spring.GetUnitPieceDirection(unitID, piecename)
        turnSyncInSpeed(piecename, x_val, y_val, z_val, speed, x_deg, y_deg, z_deg)
        return
    end
    times = math.abs(maxv / speed)

    Turn(piecename, x_axis, math.rad(x_val), (times / x_val) * speed)
    Turn(piecename, y_axis, math.rad(y_val), (times / y_val) * speed)
    Turn(piecename, z_axis, math.rad(z_val), (times / z_val) * speed)
end


function swing(Table, axis, value,reducefactor, endfactor)
factor= 1.0
	while (factor > endfactor) do
	turnT(Table,axis, factor*value, (factor*value)/10)
	WaitForTurnT(Table)
	value= value*reducefactor
	turnT(Table,axis, factor*value*-1, (factor*value)/10)
	WaitForTurnT(Table)
	Sleep(1) --Safety Sleep
	end


end
-----------------------------------------
-- >turns a Piece syncInTime working with a Table of Move Commands
function turnSyncInTimeT(Table, times, x_deg, y_deg, z_deg)

    for piece, v in pairs(Table) do
        turnInTime(v.piecenr, v.axis, v.deg, times, x_deg, y_deg, z_deg, false)
    end
end

function checkPiece(unitID, piecenameOrNumber)
    pieceList = Spring.GetUnitPieceList(unitID)
    return pieceList[piecenameOrNumber] ~= nil, pieceList
end

--> move a Piece to all 3 axis at once 
function mP(piecename, x_val, y_val, z_val, speed, boolWait)
    if boolWait then
        Move(piecename, x_axis, x_val, speed)
        Move(piecename, y_axis, y_val, speed)
        Move(piecename, z_axis, z_val, speed)
        WaitForMoves(piecename)
    else
        Move(piecename, x_axis, x_val, speed)
        Move(piecename, y_axis, y_val, speed)
        Move(piecename, z_axis, z_val, speed)
    end
end



-->Turns a Piece on all given axis, snychronously
function turnSyncInSpeed(piecename, x, y, z, speed, x_deg, y_deg, z_deg)
    if not piecename then return end
    if speed == 0 then
        tP(piecename, x, y, z, speed)
        return
    end

    tx = (absDistance(x, x_deg) + 0.01 )% 180
    ty = (absDistance(y, y_deg) + 0.01 )% 180
    tz = (absDistance(z, z_deg) + 0.01 )% 180

    xtime = tx / speed
    ytime = ty / speed
    ztime = tz / speed
    maxtime = math.max(xtime, math.max(ytime, ztime))
    if maxtime == 0 then maxtime = 0.1 end

    Turn(piecename, x_axis, math.rad(x), (xtime / maxtime) * speed)
    Turn(piecename, y_axis, math.rad(y), (ytime / maxtime) * speed)
    Turn(piecename, z_axis, math.rad(z), (ztime / maxtime) * speed)
end


--returns the minimum absolute Distance to traverse to get to another degree
function minimalAbsoluteDistance(goalDeg, startDeg)
	local gDeg, sDeg = goalDeg, startDeg

	modulatedGoalValue= (gDeg % 360.0) + 360.0 -- 330
	modulatedStartValue= (sDeg % 360.0) + 360.0 --382,5

	absDist =  absDistance(modulatedGoalValue,modulatedStartValue)
	
	if absDist > 180 then return 360 - absDist end
	
	return absDist
end

-->Turns a piece in the speed necessary to arrive after x Milliseconds 
--> overrirdes the spring shortes path turns
function turnInTime(piecename, taxis, goalDeg, timeInMs, x_startdeg, y_startdeg, z_startdeg, boolWait)
    assert(z_startdeg)

    --Gets the absolute Biggest Rotation
	 startDeg= math.ceil(selectAxisValue( taxis, x_startdeg, y_startdeg, z_startdeg))
	
    absoluteDeg = math.ceil(minimalAbsoluteDistance(goalDeg, startDeg))
	 
    timeInMs = (timeInMs + 1) / 1000
    Speed = math.rad(math.abs(absoluteDeg) / (math.abs(timeInMs))) --9.3

    if absoluteDeg < 0.0001 then return end

    if lib_boolDebug == true then
		echo("turn in Time:: start Deg: "..startDeg)
		echo("turn in Time:: goal Deg:"..goalDeg)
		echo("turn in Time::  absolute distance:"..absoluteDeg.. " -> in Speed "..Speed)
    end

    if absoluteDeg <= 180 then

        Turn(piecename, taxis, math.rad(goalDeg), Speed)
        if boolWait and boolWait == true then WaitForTurn(piecename, taxis) end

    else
        OverTurnDirection(piecename, taxis, goalDeg, Speed,  startDeg)
        if boolWait and boolWait == true then Sleep(10); WaitForTurn(piecename, taxis) end
    end
end
function selectAxisValue( taxis, x_deg, y_deg, z_deg)
	if taxis == x_axis then return x_deg end
	if taxis == y_axis  then return y_deg end
	if taxis == z_axis  then return z_deg end
	echo("Error: selectAxisValue - Axis not defined")
end
function proportionToSignum(start,goal)
	if goal >= start then return -1 end
	
	return 1 
end

-->Turns along a direction, ignoring the spring shortest way implementation
function OverTurnDirection(piecename, axis, goalDeg, speed,  startDeg)
	dirSign = proportionToSignum(startDeg, goalDeg)

	
	asyncTurn = function()
					value = startDeg + 180 * dirSign
					Turn(piecename, axis, math.rad(value), speed)
					WaitForTurn(piecename, axis)
					echo("Turn 180 °")
					Turn(piecename, axis, math.rad(goalDeg), speed)
					WaitForTurn(piecename, axis)
					echo("Turn Final")
				end
	 StartThread(asyncTurn)
end

--> turns sync in time no matter what kind of orientation the piece currently holds
function tSyncIn(piecename, x_val, y_val, z_val, timeMS, lUnitScript)
	if  not timeMS then echo(x_val..","..y_val..","..z_val) end
	if not UnitScript and lUnitScript then UnitScript = lUnitScript end
    x_rad, y_rad, z_rad = UnitScript.GetPieceRotation(piecename)		
    syncTurnInTime(piecename, x_val, y_val, z_val, timeMS, math.deg(x_rad), math.deg(y_rad), math.deg(z_rad))
end

-->Turns a piece on every axis in times 
function syncTurnInTime(piecename, x_goaldeg, y_goaldeg, z_goaldeg, timeMS, x_curdeg, y_curdeg, z_curdeg)

    if lib_boolDebug == true then
        --Spring.Echo("times for syncTurnInTime:"..times)
    end
	timeMS = math.ceil(timeMS)
	
	if x_goaldeg ~= x_curdeg then
		turnInTime(piecename, 1, (x_goaldeg), timeMS, x_curdeg, y_curdeg, z_curdeg, false)
	end
	if y_goaldeg ~= y_curdeg then
		turnInTime(piecename, 2, (y_goaldeg), timeMS, x_curdeg, y_curdeg, z_curdeg, false)
	end
	if z_goaldeg ~= z_curdeg then
		turnInTime(piecename, 3, (z_goaldeg), timeMS, x_curdeg, y_curdeg, z_curdeg, false)
	end
	
	
end

--> shortCut for SyncMovIn
function mSyncIn(piecename, x_val, y_val, z_val, times)
	syncMoveInTime(piecename, x_val, y_val, z_val, times)
end
--> Move a piece so that it arrives at all axis on the given times
function syncMoveInTime(piecename, x_val, y_val, z_val, times)
    times = (math.abs(times)+1)/1000 
	mx,my,mz =  UnitScript.GetPieceTranslation(piecename)	
	xd,yd,zd = absDistance(mx,x_val),absDistance(my,y_val),absDistance(mz,z_val)
	
    Move(piecename, 1, x_val, 	xd/times )
    Move(piecename, 2, y_val,	 yd/times)
    Move(piecename, 3, z_val,	zd/times)
end

function unZero(val)
	if val== 0 then return 0.00001 end
return val
end
--> Move a piece so that it arrives at the same times on all axis
function syncMove(piecename, x_val, y_val, z_val, speed)
    maxs = math.max(math.abs(x_val), math.max(math.abs(z_val), math.abs(y_val)))
    if maxs < 1  then maxs = 1 end

    --ratio = 1/(val/max)*times => max*times / val
	speedX = ( maxs/unZero(x_val) ) * speed
	speedY = ( maxs/unZero(y_val) ) * speed
	speedZ = ( maxs/unZero(z_val) ) * speed
	
	Move(piecename, x_axis, (x_val), math.abs(speedX))
    Move(piecename, y_axis, (y_val), math.abs(speedY))
    Move(piecename, z_axis, (z_val), math.abs(speedZ))
end


-->Turns a piece in wind direction with offset
function TurnTowardsWind(piecename, speed, offset)
    offSet = offset or 0
    dx, dy, dz = Spring.GetWind()
    headRad = math.atan2(dx, dz)
    Turn(piecename, y_axis, headRad + offSet, speed)
    return headRad
end

function spinRand(p, intervallLow,intervallUp,startspeed)
	for i=1,3 do
		val=math.random(intervallLow,intervallUp)
		Spin(p,i,math.rad(val),startspeed or 0)
	end
end

-->Spins a Table
function spinT(Table, axis, speed, rdeg, degup)
	if type(Table) == "number" then val = math.random(rdeg,rdeg+degup);Spin(Table,axis,math.rad(val),speed) end

    if not degup then
        for k, v in pairs(Table) do
            if v then
                Spin(v, axis, math.rad(rdeg), speed)
            end
        end
    else
        for k, v in pairs(Table) do
            if v then
                Spin(v, axis, math.rad(math.random(rdeg, degup)), speed)
            end
        end
    end
end

--> Stops Spinning Table
function stopSpinT(Table, axis, speed)
    for i = 1, #Table do
        StopSpin(Table[i], axis, speed)
    end
end

--> Stops Spinning Table
function stopSpins(arg,speed)
        StopSpin(arg, 1, speed)
        StopSpin(arg, 2, speed)
        StopSpin(arg, 3, speed)
end

--> Stops Spinning Table
function stopSpinsT(arg,speed)
	for i=1,#arg do
			StopSpin(arg[i], 1, speed)
			StopSpin(arg[i], 2, speed)
			StopSpin(arg[i], 3, speed)
	end
end

-->Moves a UnitPiece to Position in Unitspace at speed
function MovePieceToPos(piecename, X, Y, Z, speed, boolWaitForIt)

    Move(piecename, x_axis, X, speed)
    Move(piecename, y_axis, Y, speed)
    Move(piecename, z_axis, Z, speed, true)

    if nil == boolWaitForIt or boolWaitForIt == true then
        WaitForMoves(piecename)
    end
end

-->Helperfunction of recursiveAddTable -> builds a bonesubsystem
function buildBone(parent, piecetable)

    PieceInfo = Spring.GetUnitPieceInfo(unitID, parent)
    children = tableToDict(PieceInfo.children)

    SubBoneTables = {}
    if children then
        for key, piecenumber in pairs(piecetable) do

            if children[key] then
                SubSubBoneTable = {}
                SubSubBoneTable = buildBone(key, piecetable)
                SubBoneTables[key] = SubSubBoneTable
            end
        end
    end

    return SubBoneTables
end

-->function traverses a bonetable, getting all elements in depth Steps
function getElementsNStepsDown(Steps, Value)
    if Steps == 0 then return Value end

    if Steps > 0 and type(Value) == "table" then
        Tables = {}
        for i = 1, #Value do
            foundIt = getElementsNStepsDown(Steps - 1, Value[i])
            if foundIt then
                table.insert(Tables, foundIt)
            end
        end
        return Tables
    end
end

--Dictionary of pieces --> with accumulated Weight in every Node
--> Every Node also holds a bendLimits which defaults to ux=-45 x=45, uy=-180 y=180,uz=-45 z=45
function buildSkeleton(rootpiecename, keyPieceNrtable)

    Bones = {}
    SubPieces = {}
    for key, piecenumber in pairs(keyPieceNrtable) do
        --not rootpiece and 		
        PieceInfo = Spring.GetUnitPieceInfo(unitID, key)
        parent = PieceInfo.parent

        if parent and parent == rootpiecename then
            SubPieces[key] = {}
        end
    end

    Bones[rootpiecename] = SubPieces

    for key, v in pairs(Bones[rootpiecename]) do
        subBoneTables = buildBone(key, keyPieceNrtable)
        if subBoneTables then
            table.insert(Bones[rootpiecename][key], subBoneTables)
        end
    end
end


--> Ripped from Zero-k
function GetPitchYawRoll(front, top) --This allow compatibility with Spring 91
	--NOTE:
	--angle measurement and direction setting is based on right-hand coordinate system, but Spring might rely on left-hand coordinate system.
	--So, input for math.sin and math.cos, or positive/negative sign, or math.atan2 might be swapped with respect to the usual whenever convenient.

	--1) Processing FRONT's vector to get Pitch and Yaw
	local x, y, z = front[1], front[2], front[3]
	local xz = math.sqrt(x*x + z*z) --hypothenus
	local yaw = math.atan2 (x/xz, z/xz) --So facing south is 0-radian, and west is negative radian, and east is positive radian
	local pitch = math.atan2 (y, xz) --So facing upward is positive radian, and downward is negative radian
	
	--2) Processing TOP's vector to get Roll
	x, y, z = top[1], top[2], top[3]
	--rotate coordinate around Y-axis until Yaw value is 0 (a reset) 
	local newX = x* math.cos (-yaw) + z*  math.sin (-yaw)
	local newY = y
	local newZ = z* math.cos (-yaw) - x* math.sin (-yaw)
	x, y, z = newX, newY, newZ
	--rotate coordinate around X-axis until Pitch value is 0 (a reset) 
	newX = x 
	newY = y* math.cos (-pitch) + z* math.sin (-pitch)
	newZ = z* math.cos (-pitch) - y* math.sin (-pitch)
	x, y, z = newX, newY, newZ
	local roll =  math.atan2 (x, y) --So lifting right wing is positive radian, and lowering right wing is negative radian
	
	return pitch, yaw, roll
end

-->Moves a UnitPiece to a UnitPiece at speed
function AlignPieceToPiece(unitID, pieceToAlign, PieceToAlignTo, speed, boolWaitForIt, boolDebug, GlowPoints)

    if not pieceToAlign or not PieceToAlignTo then return end

    --We use existing function to move the piece to the other pieces center
    movePieceToPiece(unitID, pieceToAlign, PieceToAlignTo, speed)
	WaitForMoves(pieceToAlign)

    --Get the Data of the Piece we want to align to

    dx,dy,dz = Spring.UnitScript.GetPieceRotation(PieceToAlignTo)

	
	tP(pieceToAlign,math.deg(dx),math.deg(dy),math.deg(dz),speed)
	WaitForTurns(pieceToAlign)
	
end

function sigN(num)
    if num < 0 then return -1 end
    return 1
end

function echoMove(name, x, y, z)
    Spring.Echo("Moving Piece " .. name .. " to x:" .. x .. " ,y:" .. y .. " , z:" .. z)
end

-->moves Piece by a exponential Decreasing or Increasing Speed to target
function moveExpPiece(piece, axis, targetPos, startPos, increaseval, startspeed, endspeed, speedUpSlowDown)
    speed = startspeed
    for i = startPos, targetPos, 1 do
        if speedUpSlowDown == true then
            speed = math.min(endspeed, speed + increaseval ^ 2)
        else
            speed = math.max(endspeed, speed - increaseval ^ 2)
        end
        Move(piece, axis, i, speed)
        WaitForMove(piece, axis)
    end
end

function relDist(pos, target)
	rDist = 0 
	-- pos + target +
	if pos > 0 and target > 0 then
	--pos > target
	rDist = math.abs(target - pos)
	if pos > target then rDist = rDist*-1 end
	end
 
	-- pos - target -
 	if pos < 0 and target < 0 then
	--pos > target
	rDist = math.abs(math.abs(target) - math.abs(pos))
	if pos < target then rDist = rDist*-1 end
	end
	
	-- pos - target +
	if pos < 0 and target > 0 then
   rDist= math.abs(pos)+target
   end
   
   -- pos - target +
	if pos > 0 and target < 0 then
   rDist= (math.abs(target)+pos)*-1
   end   

    return rDist
end



function getOrgPosPiece(unitID, pieceName)
	resultTable= Spring.GetUnitPieceInfo(unitID,pieceName)
	
	return resultTable.offset[1],resultTable.offset[2],resultTable.offset[3]
end

-->Moves a UnitPiece to a UnitPiece at speed
function movePieceToPieceNoReset(unitID, piecename, pieceDest, speed, offset)
    speed = speed or 0
	 offset = offset or {x= 0, y= 0, z= 0}
	
    if not pieceDest or not piecename then return end
    orgx, orgy, orgz = getOrgPosPiece(unitID, piecename) --TODO rework
   -- echo("piecepos:", orgx, orgy, orgz)

    gox, goy, goz = Spring.GetUnitPiecePosition(unitID, pieceDest)
  --  echo("PieceDestPos:", gox, goy, goz)
    diffx, diffy, diffz = relDist(orgx, gox), relDist(orgy, goy), relDist(orgz, goz)
   -- echo("Diff:", -1*diffx,  diffy, diffz)


   syncMove(piecename, -1* diffx +offset.x,  diffy + offset.y,  diffz+ offset.z, speed)

   WaitForMoves(piecename)
end

-->Moves a UnitPiece to a UnitPiece at speed
function movePieceToPiece(unitID, piecename, pieceDest, speed, offset, forceUpdate, boolWaitForIT)
    reset(piecename, 0) --last changeset

    speed = speed or 0

    if not pieceDest or not piecename then return end

    ox, oy, oz = Spring.GetUnitPiecePosition(unitID, pieceDest)
    assert(ox)
    orx, ory, orz = Spring.GetUnitPiecePosition(unitID, piecename)
    assert(orx)
    ox, oy, oz = ox - orx, oy - ory, oz - orz

    ox = ox * -1
    if offset then
        ox = ox + (offset.x)
        oy = oy + offset.y
        oz = oz + offset.z
    end

    --	echoMove(piecename, ox,oy,oz)
    Move(piecename, x_axis, ox, speed)
    Move(piecename, y_axis, oy, speed)
    Move(piecename, z_axis, oz, speed, forceUpdate or true)

	if nil == boolWaitForIT or boolWaitForIT== true then
		WaitForMove(piecename, x_axis); WaitForMove(piecename, z_axis); WaitForMove(piecename, y_axis);
	end
end

-->Moves a UnitPiece to a UnitPiece at speed
function movePieceFromPieceToPiece(unitID, piecename, pieceDest, pieceStart, speed, offset, forceUpdate)
    reset(piecename, 0) --last changeset

    speed = speed or 0

    if not pieceDest or not piecename then return end

    ox, oy, oz = Spring.GetUnitPiecePosition(unitID, pieceDest)
    sx, sy, sz = Spring.GetUnitPiecePosition(unitID, pieceStart)
	dx,dy,dz= ox-sx,oy-sy,oz-sz
	
    orx, ory, orz = Spring.GetUnitPiecePosition(unitID, piecename)

    ox, oy, oz = ox - orx, oy - ory, oz - orz

    ox = ox * -1
    if offset then
        ox = ox + (offset.x)
        oy = oy + offset.y
        oz = oz + offset.z
    end
    Move(piecename, x_axis, ox+dx, 0)
    Move(piecename, y_axis, oy-dy, 0)
    Move(piecename, z_axis, oz-dz, 0,  true)
	WaitForMoves(piecename)
	
    --	echoMove(piecename, ox,oy,oz)
    Move(piecename, x_axis, ox, speed)
    Move(piecename, y_axis, oy, speed)
    Move(piecename, z_axis, oz, speed, forceUpdate or true)


    WaitForMove(piecename, x_axis); WaitForMove(piecename, z_axis); WaitForMove(piecename, y_axis);
end
 

-->Moves a Piece to a Position on the Ground in UnitSpace
function moveUnitPieceToGroundPos(unitID, piecename, X, Z, speed, offset)
    if not piecename then  error("No piecename given by "..UnitDefNames[Spring.GetUnitDefID(unitID)].name); return end
    if not X or not Z then return end
    loffset = offset or 0
    x, globalHeightUnit, z = Spring.GetUnitPosition(unitID)
    Move(piecename, x_axis, X, 0)
    Move(piecename, z_axis, Z, 0, true)
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, piecename)
    if not x then return end
    myHeight = Spring.GetGroundHeight(x, z)
    heightdifference = math.abs(globalHeightUnit - myHeight)
    if myHeight < globalHeightUnit then heightdifference = -heightdifference end
    Move(piecename, y_axis, heightdifference + loffset, speed, true)
end

-->Moves a Piece to WaterLevel on the Ground in UnitSpace
function KeepPieceAfloat(unitID, piecename, speed, randoValLow, randoValUp)
    if not piecename then return error("No piecename given") end
    randoVal = math.random(randoValLow or -1, randoValUp or 0)

    --unitspace
    px, py, pz, _, _, _ = Spring.GetUnitPiecePosition(unitID, piecename)
    --worldspace
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, piecename)
    pieceInfoTable = Spring.GetUnitPieceInfo(unitID, piecename)
    sizeOfPiece, offsetOfPiece = pieceInfoTable.max[2], pieceInfoTable.offset[2]

    if y > 0 then
        WMove(piecename, y_axis, py - y - offsetOfPiece + randoVal, speed)
    else
        WMove(piecename, y_axis, py - y - offsetOfPiece + randoVal, speed)
    end

    px, py, pz, _, _, _ = Spring.GetUnitPiecePosition(unitID, piecename)
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, piecename)
end



function stableConditon(legNr, q)
    return GG.MovementOS_Table ~= nil and
            GG.MovementOS_Table[unitID].stability > 0.5 and GG.MovementOS_Table[unitID].quadrantMap[math.max(math.min(4, q), 1)] > 0 or GG.MovementOS_Table[unitID].quadrantMap[math.max(math.min(4, legNr % 2), 1)] and GG.MovementOS_Table[unitID].quadrantMap[math.max(math.min(4, legNr % 2), 1)] > 0
end

--Controlls One Feet- Relies on a Central Thread running and regular updates of each feet on his status
function feetThread(quadrant, degOffSet, turnDeg, nr, FirstAxisPoint, KneeT, SensorPoint, Weight, Force, LiftFunction, LegMax, WiggleFunc, ScriptEnviroment, SensorT)
    LMax = LegMax or 5
    oldHeading = 0
    Sleep(500)

    stabilize(quadrant,
        degOffSet,
        turnDeg,
        nr,
        FirstAxisPoint,
        KneeT,
        SensorPoint,
        Weight,
        Force,
        LiftFunction,
        ScriptEnviroment,
        SensorT)

    while true do
        while GG.MovementOS_Table[unitID].boolmoving == true do
            echo("lib_UnitScript::adaptiveAnimation::MovingTrue")
            --while GG.MovementOS_Table[unitID].boolmoving==true and stableConditon(nr,quadrant) do

            --feet go over knees if FeetLiftForce > totalWeight of Leg

            liftFeedForward(quadrant,
                degOffSet,
                turnDeg,
                nr,
                FirstAxisPoint,
                KneeT,
                SensorPoint,
                Weight,
                Force,
                LiftFunction,
                ScriptEnviroment)
            Sleep(100)
            stabilize(quadrant,
                degOffSet,
                turnDeg,
                nr,
                FirstAxisPoint,
                KneeT,
                SensorPoint,
                Weight,
                Force,
                LiftFunction,
                SensorT)
            Sleep(100)
            pushBody(quadrant,
                degOffSet,
                turnDeg,
                nr,
                FirstAxisPoint,
                KneeT,
                SensorPoint,
                Weight,
                Force,
                nr,
                ScriptEnviroment)

            Sleep(100)
            stabilize(quadrant,
                degOffSet,
                turnDeg,
                nr,
                FirstAxisPoint,
                KneeT,
                SensorPoint,
                Weight,
                Force,
                LiftFunction,
                ScriptEnviroment,
                SensorT)
            Sleep(100)
        end

        stabilize(quadrant,
            degOffSet,
            turnDeg,
            nr,
            FirstAxisPoint,
            KneeT,
            SensorPoint,
            Weight,
            Force,
            LiftFunction,
            ScriptEnviroment,
            SensorT)
        Sleep(100)
    end
end

--return Feet into origin position and push body above ground
function pushBody(quadrant, degOffSet, turnDeg, nr, FirstAxisPoint, KneeT, SensorPoint, Weight, Force, nr, ScriptEnviroment)
    if lib_boolDebug == true then Spring.Echo("lib_UnitScript::pushBody") end
    Turn(FirstAxisPoint, y_axis, math.rad(degOffSet), 0.3)
    xp, yp, zp = Spring.GetUnitPiecePosDir(unitID, SensorPoint)
    dif = yp - Spring.GetGroundHeight(xp, zp)

    Time = 0

    WaitForTurn(FirstAxisPoint, y_axis)
end

-->Uses the LiftAnimation Function to Lift the Feed
function liftFeedForward(quadrant, degOffSet, turnDeg, nr, FirstAxisPoint, KneeT, SensorPoint, Weight, Force, LiftFunction)
    if lib_boolDebug == true then Spring.Echo("lib_UnitScript::liftFeedForward") end
    GG.MovementOS_Table[unitID].quadrantMap[quadrant % 4 + 1] = GG.MovementOS_Table[unitID].quadrantMap[quadrant % 4 + 1] - 1
    speed = clamp(Force / (#KneeT * Weight), 0.15, 0.25)
    withOffset = sanitizeRandom(0, turnDeg)
    if withOffset > 180 then withOffset = withOffset * -1 end
    Turn(FirstAxisPoint, y_axis, math.rad(degOffSet + withOffset), speed)
    --lifts Feed from the ground 	
    LiftFunction(KneeT, Force / (#KneeT * Weight))

    --Turn foot forward and upward
    WaitForTurn(FirstAxisPoint, y_axis)
    Sleep(500)
    Turn(FirstAxisPoint, y_axis, math.rad(degOffSet), speed)
    for i = 1, #KneeT, 1 do
        Turn(KneeT[i], x_axis, math.rad(-2), speed)
    end
    WaitForTurn(FirstAxisPoint, y_axis)
end


function convertToNeg(val)
    if val < 0 then return 360 - (360 + val) end
    return val
end


-->Stabilizes the Feet above ground and rest
function stabilize(quadrant, degOffSet, turnDeg, nr, FirstAxisPoint, KneeT, SensorPoint, Weight, Force, LiftFunction, ScriptEnviroment, SensorT)

    xp, yp, zp = Spring.GetUnitPiecePosDir(unitID, SensorPoint)
    dif = yp - Spring.GetGroundHeight(xp, zp)
    degToGo = 0
    counter = 0
    olddif = 0
    WaitForTurn(FirstAxisPoint, y_axis)
    Turn(FirstAxisPoint, y_axis, math.rad(degOffSet), 0.15)
    assert(ScriptEnviroment.GetPieceRotation)
    assert(SensorT)

    unitHeigth = GG.MovementOS_Table[unitID].stability * Height
    propagatedCounterChange = 0

    for i = #KneeT, 1, -1 do
        measureIndex = clamp(i, 1, #KneeT)
        boolUnderground = true


        x, y, z = Spring.GetUnitPiecePosDir(unitID, SensorT[measureIndex])
        xdeg, y_deg, z_deg = ScriptEnviroment.GetPieceRotation(KneeT[i])
        tDeg = math.deg(xdeg)

        GroundHeight = Spring.GetGroundHeight(x, z)
        --	if lib_boolDebug == true then	Spring.Echo("lib_UnitScript::stabilize::PieceHeigth".. ( y -35 -unitHeigth ).." < "..GroundHeight.." ::GroundHeight") end

        if y - GroundHeight > 20 then --Go down		
            if y - GroundHeight < 5 then break end

            tDeg = clamp(tDeg + 0.25 + propagatedCounterChange, -75, math.max((1 / i) * 75, 25))
            tDeg = convertToNeg(tDeg)
            propagatedCounterChange = propagatedCounterChange - 0.25
            Turn(KneeT[i], x_axis, math.rad(tDeg), 0.0175)
        else --Go up	faster					
            boolUnderground = true

            tDeg = clamp(tDeg - 1.15 + propagatedCounterChange, -75, math.max((1 / i) * 75, 25))
            tDeg = convertToNeg(tDeg)
            propagatedCounterChange = propagatedCounterChange + 1.15
            Turn(KneeT[i], x_axis, math.rad(tDeg), 0.135)
        end
    end
    WaitForTurns(KneeT)
end


-->Paint a Piece Pattern 
function paintPatternPieces(ListOfPieces, ListOfCoords, sx, sy, sz)
    prevx, prevy, prevz = sx, sy, sz

    MovePieceToPos(ListOfPieces[1], ListOfCoords[1].x, ListOfCoords[1].y, ListOfCoords[i].z)
    TurnPieceTowards(ListOfPieces[1], sx, sy, sz, 0)
    prevx, prevy, prevz = ListOfCoords[1].x, ListOfCoords[1].y, ListOfCoords[i].z


    for i = 2, #ListOfCoords - 1 do
        MovePieceToPos(ListOfPieces[i], ListOfCoords[i].x, ListOfCoords[i].y, ListOfCoords[i].z)
        TurnPieceTowardsPiece(ListOfPieces[i], ListOfPieces[i - 1], 0)
    end
end

-->Detects a Turning
function turnDetector(resolutinInMs)
	 if not resolutinInMs then resolutinInMs =500 end
    local spGetUnitHeading = Spring.GetUnitHeading
    oldHeading = spGetUnitHeading(unitID)
    Sleep(resolutinInMs)
    newHeading = oldHeading

    while true do
        newHeading = spGetUnitHeading(unitID)

        if math.abs(newHeading - oldHeading) > 1400 then
            boolTurning = true
            if newHeading - oldHeading < 0 then 
				boolTurnLeft = true 
			else 
				boolTurnLeft = false 
			end
        else
            boolTurning = false
        end
        Sleep(resolutinInMs)
        oldHeading = newHeading
    end
end



-->Moves a Piece to a Position on the Ground in Worldspace
function moveUnitPieceToRelativeWorldPos(unitID, piecename, relX, relZ, speed, loffset)
    offset = loffset or 0
    x, globalHeightUnit, z = Spring.GetUnitPosition(unitID)
    x, z = relX - x, relZ - z
    Move(piecename, x_axis, x, 0, true)
    Move(piecename, z_axis, z, 0, true)
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, piecename)
    myHeight = Spring.GetGroundHeight(x, z)
    heightdifference = math.abs(globalHeightUnit - myHeight)
    if myHeight < globalHeightUnit then heightdifference = -heightdifference end
    Move(piecename, y_axis, heightdifference + offset, speed, true)
end

--> Move with a speed Curve
function moveSpeedCurve(piecename, axis, NumberOfArgs, now, timeTotal, distToGo, Offset, ...)
    local arg = arg; if (not arg) then arg = { ... }; arg.n = #arg end
    --!TODO calcSpeedUpId from functionkeys,check calculations for repetitons and store that key in to often as result in GG
    --should handle all sort of equations of the type 0.3*x^2+0.1*x^1+offset
    -- in our case that would be [2]=0.3 ,[1]=0.1 and so forth

    ArgFactorTable = {}
    NrCopy = NumberOfArgs
    for _, factor in pairs(arg) do
        ArgFactorTable[NrCopy] = factor
        NrCopy = NrCopy - 1
    end

    --init tangent table
    tangentTable = { n = #ArgFactorTable - 1 }


    --first derivative 
    --http://en.wikipedia.org/wiki/Derivative
    for i = table.getn(tangentTable), 1, -1 do
        tangentTable[i] = (i + 1) * ArgFactorTable[i + 1]
    end

    Totalspeed = Offset
    for i = 1, NumberOfArgs - 1 do
        Totalspeed = Totalspeed + tangentTable[i] * (now ^ i)
    end

    Move(piecename, axis, distToGo, Totalspeed)
end


function stuckInPlaceAvoidance(unitID, times, intervall)
    impulsfactor = 6
    x, y, z = Spring.GetUnitPosition(unitID)
    oP, newPos = { x = x, y = y, z = z }, { x = x, y = y, z = z }

    while true do
        x, y, z = Spring.GetUnitPosition(unitID)
        intervallCounter = 0
        nP = { x = x, y = y, z = z }
        if math.abs(oP.x - nP.x) < 1 or math.abs(oP.z - nP.z) < 1 then
            intervallCounter = intervallCounter + 1
        else
            intervallCounter = 0
        end
        oldPos = newPos

        if intervallCounter > intervall then
            dx, dy, dz = Spring.GetUnitDirection(unitID)
            Spring.AddUnitImpulse(unitID, dx * impulsfactor, dy * impulsfactor, dz * impulsfactor)
        end
        Sleep(times)
    end
end

--> Drops a piece to the ground
function DropPieceToGround(unitID, piecename, speed, boolWait, boolHide, ExplodeFunction, SFXCOMBO)
    x, y, z = Spring.GetUnitPiecePosition(unitID, piecename)
    moveUnitPieceToGroundPos(unitID, piecename, x, z, speed, 5)

    if boolWait then WaitForMove(piecename, y_axis) end

    if boolHide then Hide(piecename) end

    if ExplodeFunction then ExplodeFunction(piecename, SFXCOMBO) end
end




function generateSknakeOnAPlaneDefaults(cPceDescLst)
  for iNumerated, arm in ipairs(PceDescLst) do

        if not arm.Piece then echo("libAnimation::snakeOnAPlane - No Valid Piece in Arm"); return end

        armTcX, _, armTcZ,  armTdX, _,armTdZ = Spring.GetUnitPiecePosDir(unitID, arm.Piece)
        --initialise the arm direction
        if not arm.cx then arm.cX, arm.cZ = armTcX, armTcZ; end
        if not arm.dirX then arm.dirX, arm.dirZ = armTdX, armTdZ end

        --length of the piece
        successorPiece = FirstSensor
        if PceDescLst[iNumerated + 1] and PceDescLst[iNumerated + 1].Piece then successorPiece = PceDescLst[iNumerated + 1].Piece end

        sucTcX, _, sucTcZ = Spring.GetUnitPiecePosDir(unitID, successorPiece)

        --default arm length per piece
        if not arm.lx then
            arm.lx, arm.lz= absDistance(armTcX, sucTcX), absDistance(armTcX, sucTcZ)
        end

        --set default axis
        if not arm.ax then
            if iNumerated ~= 1 then
                arm.ax, arm.az = true, false
            else
                arm.ax, arm.az  = false, true
            end
        end

        if not arm.piecelength then
            if arm.ax == true then arm.piecelength = arm.lx end
            if arm.az == true then arm.piecelength = arm.lz end
        end


        if not arm.lastPointIndex then arm.lastPointIndex = 0 end
    end
return cPceDescLst
end
-->Takes a List of Pieces forming a kinematik System and guides them through points on a Plane
-- ListPiece={
--ArmCenterOffset={ox = 0, oy=0}
--[1]={ 
-- Piece = pieceName,			
--CenterPoint - used for a Offset of the Arm to UnitCenter
-- cX=0, 
-- cY=0,
-- cZ=0, 		
--current setting allowed
-- length of piece 
-- lX = 25,
-- lY = 25,


-- dirX,
-- dirY,

--active axis
-- ax =false, 
-- ay=true,
-- az=true, 
-- lastPointIndex
-- piecelength

-- } --Active Axis for this piece

-- }

-- Window={ x,y -- Worldspace Coordinates
-- vx,vy --VoluminaCube

-- }
--> solves a kinetic 2D system snaking through goal windows of limited size
function snakeOnAPlane(unitID, cPceDescLst, FirstSensor, WindowDescriptorList, axis, speed, tolerance, boolPartStepExecution, boolWait)
    local PceDescLst = cPceDescLst --{Piece_Pos_Deg_Length_PointIndex_boolGateCrossed_}List

    --early error out
    if not PceDescLst then 
		echo("libAnimation::snakeOnAPlane - No Valid PieceCegTable"); return 
	end
	
    if WindowDescriptorList == nil then 
		echo("libAnimation::snakeOnAPlane - No Valid Goals to move"); return 
	end

    --Working Defaults
    --if not defined ArmCenter - define Arm as centered in UnitSpace
    if not PceDescLst.ArmCenterOffset then PceDescLst.ArmCenterOffset = { ox = 0, oz = 0 } end

    for iNumerated, arm in ipairs(PceDescLst) do
        --TODO
    end
    --total Length arm
    --Preparations and Default Initialisations
	PceDescLst = generateSknakeOnAPlaneDefaults(PceDescLst)
	
    --local copy of the ArmTable
    local ArmTable = {}
    for i = 1, #PceDescLst do ArmTable[i] = PceDescLst[i].Piece end

    --get StartPosition and Move First Piece Into the Cube
    boolResolved = false
    if not WindowDescriptorList then echo("snakeOnAPlane:: Not WindowDescriptorList delivered"); return end

    LastInsertedPoint = WindowDescriptorList[1]
    Sensor = FirstSensor

    vOrg = {};
    vOrg.x, vOrg.y, vOrg.z = WindowDescriptorList[1].vx, 0, WindowDescriptorList[1].vz
    echoT(PceDescLst)
	
    for i = 1, #WindowDescriptorList do
		
    end
    --func

    --Preparations Completed

	


    --Turn the axis towards the goal
    --getPointPlane(point, -degAroundAxis)

    TurnPieceTowardsPoint(cPceDescLst[1].Piece, vOrg.x, vOrg.y, vOrg.z, 0.5)
    WaitForTurns(cPceDescLst[1].Piece)


    while boolResolved == false do

        boolAlgoRun = false
        while boolAlgoRun == false do
            hypoModel = PceDescLst
            GlobalIndex = #PceDescLst   

            for Index = #PceDescLst, 1, -1 do

                local nextGoal = PceDescLst[Index].PointIndex
                x, y, z, dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, PceDescLst[Index].Piece)

                local PieceStartPoint = makeVector(x, y, z)
                px, py, pz, pdx, pdy, pdz = Spring.GetUnitPiecePosDir(unitID, PceDescLst[math.min(Index + 1, #PceDescLst)].Piece)
                local PieceEndPoint = makeVector(px, py, pz)

                ppx, ppy, ppz, ppdx, ppdy, ppdz = Spring.GetUnitPiecePosDir(unitID, PceDescLst[math.min(Index + 1, #PceDescLst)].Piece)
                local PrevGatePoint = makeVector(ppx, ppy, ppz)


                --CheckCenterPastPoint_PointIndex 
                boolPastCenterPoint = checkCenterPastPoint(midVector(PieceStartPoint, PieceEndPoint),
                    WindowDescriptorList[nextGoal],
                    PrevGatePoint)

                -->if pointIndex is beyond Last Point this piece is far beyond 
                if nextGoal > #SnakePoint then
                    -- align yourself counterVectorwise from the last Point you crossed
                end

                -->True && boolGateCrossed =false
                if boolPastCenterPoint == true and PceDescLst[Index].boolGateCrossed == false then

                    --TurnPieceTowardstNextPoint(PrevPieceIndex) hypoModel
                    --WaitForTurns(ArmTable)
                    counterTurnDeg = 0
                    for BackTrackIndex = Index, #PceDescLst, 1 do
                        --ReAlign Piece Goal
                    end
                    --
                    PceDescLst[Index].boolGateCrossed = checkCenterPastPoint(midVector(PieceStartPoint, PieceEndPoint),
                        WindowDescriptorList[nextGoal],
                        PrevGatePoint)

                    if PceDescLst[Index].boolGateCrossed == true then
                        PceDescLst[Index].PointIndex = PceDescLst[Index].PointIndex + 1
                    end
                    --boolGateCrossed=True 
                    --IncPointIndex
                    --CheckCenterPastPoint_PrevPiece() && boolGateCrossed != true
                    --> True
                    --Index =PrevPointIndex

                    --SubIndex

                    -->True && boolGateCrossed =true
                elseif boolPastCenterPoint == true and PceDescLst[Index].boolGateCrossed == true then

                    if boolPartStepExecution == true then
                        --Execute from top down to index, moves in order
                        --+-boolWait
                    else
                    end
                    --SubIndex

                elseif boolPastCenterPoint == false then
                    -->False
                    --TurnPieceTowardstPoint(PieceIndex) hypoModel
                    --WaitForTurns(ArmTable)
                    --CounterTurnPrevPiece hypoModel
                end


                if Index == 1 then boolAlgoRun = true; break end
            end
        end
        applyChangesAsTurns(PceDescLst)
        --WaitForTurns(ArmTable)
        boolResolved = isSnakeAtMax(PceDescLst)
    end
    --]]
end

function isSnakeAtMax(PceDescLst, SnakePoints)
    --if every point from the base point out is aligned towards its next goal
    for i = 1, #PceDescLst do
        px, py, pz, dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, PceDescLst[i].Piece)
        pgx, pgy, pgz, dgx, dgy, dgz = Spring.GetUnitPiecePosDir(unitID, SnakePoints[PceDescLst[Index].PointIndex])
        vec = norm2Vector(makeVector(px - pgx, py - pgy, pz - pgz))
        if eqVec(makeVector(dx, dy, dz), vec) == false then return false end
    end

    return true
end

function mulVectorS4Mat(mat, vec)
    enVec = { [1] = vec.x, [2] = vec.y, [3] = vec.z, [4] = 1 }
    resVec = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }

    for u = 0, 3, 1 do
        sum = 0
        for v = 1, 4, 1 do
            sum = sum + (enVec[v] * mat[u * 4 + v])
        end

        resVec[u + 1] = sum
    end

    return { x = resVec[1], y = resVec[2], z = resVec[3], w = resVec[4] }
end

-->hangs a Piece towards gravity + offset
function hang(pieceName, offSetVec, speed)
    diVec = makeVector(0, 0, 0)
    mat = {}
    hx, hy = Spring.GetUnitPosition(unitID)
    dx, dy, dz = Spring.GetGroundNormal(hx, hy)
    dv = makeVector(dx, dy, dz)
    upv = makeVector(0, 1, 0)
    dv = subVector(upv, dv)

    tPVector(pieceName, dv, speed)
end


function TurnPieceList(ScriptEnviroment, PieceList, boolTurnInOrder, boolWaitForTurn, boolSync)

    for i = 1, table.getn(PieceList), 5 do

        if boolSync == false then
            tP(PieceList[i], PieceList[i + 1], PieceList[i + 2], PieceList[i + 3], PieceList[i + 4], boolTurnInOrder)
        else
            if not PieceList[i] then
                echo("TurnPieceList piece " .. i .. " missing")
            else
                x_deg, y_deg, z_deg = ScriptEnviroment.GetPieceRotation(PieceList[i])

                turnSyncInSpeed(PieceList[i], PieceList[i + 1], PieceList[i + 2], PieceList[i + 3], PieceList[i + 4], math.deg(x_deg), math.deg(y_deg), math.deg(z_deg))
            end
        end
    end

    if boolWaitForTurn == true and boolTurnInOrder == false then
        for i = 1, table.getn(PieceList), 5 do
            WaitForTurns(PieceList[i])
        end
    end
end

--> Turn a Table towards local T
function moveT(t, axis, dist, speed, boolInstantUpdate)
    if boolInstantUpdate then
        for i = 1, #t, 1 do
            Move(t[i], axis, dist, 0, true)
        end
        return
    end

    if not speed or speed == 0 then
        for i = 1, #t, 1 do
            Move(t[i], axis, dist, 0)
        end
    else
        for i = 1, #t, 1 do
            Move(t[i], axis, dist, speed)
        end
    end
    return
end

function turnTableRand(t, taxis, uparg, downarg, speed, boolInstantUpdate)
    axis = taxis or 2 --y_axis as default
    down = downarg or math.random(-50, 0)
    up = uparg or math.random(0, 50)
    if down > up then down = down * -1 - 1 end

    if boolInstantUpdate then
        for i = 1, #t, 1 do
            Turn(t[i], axis, math.rad(math.random(down, up)), 0, true)
        end
        return
    end

    if not speed or speed == 0 then
        for i = 1, #t, 1 do
            Turn(t[i], axis, math.rad(math.random(down, up)), 0)
        end
    else
        for i = 1, #t, 1 do
            Turn(t[i], axis, math.rad(math.random(down, up)), speed)
        end
    end
    return
end


function unfoldAnimation(ListOfPieces, specialeffectsfunction, unitID, maxSpeed)
    --sort them BySize --samesizes by closeness to ground

    PieceIDSizeTable = {}
    PieceIDHeightTable = {}
    AllreadyVisiblePieces = {}
    hideT(ListOfPieces)
    for k, v in pairs(ListOfPieces) do
        x, y, z = Spring.GetUnitPieceCollisionVolumeData(unitID, v)
        min = math.floor(math.min(x, math.min(y, z)))
        PieceIDSizeTable[v] = min
        _, y_ = Spring.GetUnitPiecePosDir(unitID, v)
        PieceIDHeightTable[v] = y
    end
    --sortBySize
    SizeSortedTable = {}
    HeightSortedTable = {}

    for k, v in pairs(ListOfPieces) do
        SizeSortedTable = binaryInsertTable(SizeSortedTable, PieceIDSizeTable[v], v, k)
        HeightSortedTable = binaryInsertTable(HeightSortedTable, PieceIDHeightTable[v], v, k)
    end

    ClosedTable = {}
    AllreadyVisiblePieces[SizeSortedTable[#SizeSortedTable].key] = PieceIDSizeTable[SizeSortedTable[#SizeSortedTable].key]
    Show(AllreadyVisiblePieces[1])
    ClosedTable[AllreadyVisiblePieces[1]] = true
    local StartPiece = AllreadyVisiblePieces[1]

    --we now have Table of Pieces Sorted by size and height in the building
    -- we itterate over the lower table - and pick by size 

    for i = 1, #HeightSortedTable, 1 do
        if HeightSortedTable[i].value ~= StartPiece then
            --find a StartPiece
            local mySize = PieceIDSizeTable[HeightSortedTable[i].value]
            PieceBiggerThenMe = StartPiece
            for k, v in pairs(AllreadyVisiblePieces) do
                if v > mySize then
                    PieceBiggerThenMe = k
                    if math.random(0, 2) == 1 then break end
                end
            end

            movePieceToPiece(unitID, HeightSortedTable[i].value, PieceBiggerThenMe, 0)
            Show(HeightSortedTable[i].value)
            --get Element Bigger in Table 
            Move(HeightSortedTable[i].value, 0, x_axis, speed)
            Move(HeightSortedTable[i].value, 0, z_axis, speed)
            WaitForMove(HeightSortedTable[i].value, z_axis)
            WaitForMove(HeightSortedTable[i].value, x_axis)
            Move(HeightSortedTable[i].value, 0, y_axis, speed)
            WaitForMove(HeightSortedTable[i].value, y_axis)
            AllreadyVisiblePieces[HeightSortedTable[i].value] = PieceIDSizeTable[HeightSortedTable[i].value]
            --ShowTheBiggest
        end
    end
    -- Move through the showedList, from a randomPoint find a piece that has a fitting size
end

-->Drops a unitpiece towards the ground
function dropPieceTillStop(unitID, piece, speedPerSecond, VspeedMax, lbounceNr, boolSpinWhileYouDrop, bounceConstant, driftFunc)
    if not unitID or not piece or not speedPerSecond or not VspeedMax then return end
    x, globalHeightUnit, z = Spring.GetUnitPosition(unitID)

    speed = speedPerSecond or 9.81
    speedMax = VspeedMax or 9.81
    bounceNr = lbounceNr or 12
    times = 1000
    factorT = times / 1000

    if boolSpinWhileYouDrop and boolSpinWhileYouDrop == true then
        SpinAlongSmallestAxis(unitID, piece, math.random(-25, 25), 2)
    end

    dirX, dirY, dirZ = Spring.GetUnitPiecePosition(unitID, piece)
    bdirX, bdirY, bdirZ = Spring.GetUnitPiecePosition(unitID, piece)
    dirX, dirZ = bdirX - dirX, bdirZ - dirZ

    --Spring.Echo("Spring.GetUnitWeaponVectors(unitID,1)"..dirX.. " z:"..dirZ)
    norm = math.sqrt(dirX * dirX + dirZ * dirZ)
    dirX, dirZ = (dirX / norm), (dirZ / norm)
    dirX, dirZ = -0.5 * randSign(), -0.5 * randSign()
    vec = { vx = dirX, vy = 0.4, vz = dirZ, x = 0, y = 17, z = 0, }




    gh = Spring.GetGroundHeight(x, z)
    bump = 0
    force = 16

    while bump < bounceNr do
        --accelerate by vector +gravity 
        vec.y = vec.y + clampMaxSign(vec.vy * force % (speed * factorT) - 1 * speed, factorT * speedMax)
        vec.x = vec.x + clampMaxSign(vec.vx * force % (speed * factorT), factorT * speedMax)
        vec.z = vec.z + clampMaxSign(vec.vz * force % (speed * factorT), factorT * speedMax)


        mP(piece, vec.x, vec.y, vec.z, factorT * speed)

        --shrink vec with sqrt as a approximation for air resistance
        vec.vx = clampMaxSign(math.sqrt((math.abs(vec.vx) ^ 1.414)) * Signum(vec.vx), 1)
        vec.vz = clampMaxSign(math.sqrt((math.abs(vec.vz) ^ 1.414)) * Signum(vec.vz), 1)

        --apply a approximation for the decay of movement
        vec.vy = clampMaxSign(1 - (1 / (force + 0.0001)) * (vec.vy), 1)
        WaitForMove(piece, y_axis)
        Sleep(10)
        --Spring.Echo("Looping Physics")
        x, y, z = Spring.GetUnitPiecePosDir(unitID, piece)
        gh = Spring.GetGroundHeight(x, z)

        if gh - y > 5 then
            bump = bump + 1
            force = math.sqrt(force)
            --not realistic but a start we take the ground normal as new vector 
            --reset Position
            x, y, z = Spring.GetUnitPiecePosDir(unitID, piece)

            moveUnitPieceToGroundPos(unitID, piece, x, z, 0, 0)
            dx, dy, dz, slope = Spring.GetGroundNormal(x, z)

            --Spring.Echo("X>"..vec.x .. " Y> ".. vec.y .. " Z>" .. vec.z) 
            --Spring.Echo("VX>"..vec.vx .. " VY> ".. vec.vy .. " VZ>" .. vec.vz) 
            --Spring.Echo("DX>"..dx .. " DZ>" .. dz) 
            if math.abs(dy) > 0.5 and force < 1 then
                StopSpin(piece, x_axis, 0.5)
                StopSpin(piece, y_axis, 0.5)
                StopSpin(piece, z_axis, 0.5)
                LayFlatOnGround(piece)
                x, y, z = Spring.GetUnitPiecePosDir(unitID, piece)
                moveUnitPieceToGroundPos(unitID, piece, x, z, 0, 0)

                return
            else
                force = force * 2
            end
            px, py, pz = Spring.GetUnitPiecePosition(unitID, piece)
            vec.vx, vec.vy, vec.vz = (clampMaxSign(dx * 0.5, 1)), vec.vy * -0.75, (clampMaxSign(dz * 0.5, 1))

            vec.y = vec.y + clampMaxSign(vec.vy * force ^ 2, factorT * speedMax)
            vec.x = vec.x + clampMaxSign(vec.vx * force ^ 2, factorT * speedMax)
            vec.z = vec.z + clampMaxSign(vec.vz * force ^ 2, factorT * speedMax)
            mP(piece, vec.x, vec.y, vec.z, factorT * speed)
            WaitForMove(piece, y_axis)
            Sleep(10)
        end
    end
end

--> Move all Elements of a Table to Zero
function resetMT(t)
    for i = 1, #t, 1 do
        Move(t[i], y_axis, 0, 0)
        Move(t[i], z_axis, 0, 0)
        Move(t[i], z_axis, 0, 0)
    end
end

--> Turn a Table towards local T
function turnT(t, axis, deg, speed, boolInstantUpdate, boolWait)
    if boolInstantUpdate then
        for i = 1, #t, 1 do
            Turn(t[i], axis, math.rad(deg), 0, true)
        end
        return
    end

    if not speed or speed == 0 then
        for i = 1, #t, 1 do
            Turn(t[i], axis, math.rad(deg), 0)
        end

    else
        for i = 1, #t, 1 do
            Turn(t[i], axis, math.rad(deg), speed)
        end
        if boolWait then for i = 1, #t, 1 do WaitForTurn(t[i], axis) end end
    end
    return
end

--> compares Heading
function compareHeading(currentHead, headingOld, waitTime, headChangeTolerance)

    waitTime = waitTime or 100
    headChangeTolerance = headChangeTolerance or 100
    boolTurnLeft = false

    while (headingOfOld == nil) do
        Sleep(waitTime)
        headingOfOld = Spring.GetUnitHeading(unitID)
    end

    while (currentHead == nil) do
        currentHeading = Spring.GetUnitHeading(unitID)
        Sleep(waitTime)
    end

    headingOld = headingOld
    currentHead = currentHead


    headChange = math.abs(currentHead) - math.abs(headingOld)
    --unneg the headChange

    headChange = math.abs(headChange)

    if headChange > headChangeTolerance then --or currentHeading < headingOfOld*negativeTolerance

        return true, currentHead - headingOld < 0
    else
        return false, boolTurnLeft
    end
end

function wiggle(piecename, xval,yval,zval,timetotal, timeMin,timeMax, overshootfactor)


	timeSnippet= math.random(timeMin,timeMax)
	x,y,z=math.random(0,xval)*randSign(),math.random(0,yval)*randSign(),math.random(0,zval)*randSign()
	tSyncIn(piecename,x,y,z,timeSnippet)
	WaitForTurns(piecename)
	timetotal=timetotal-timeSnippet

	copy=overshootfactor
	sigN= 1
		for i=1,4 do
			tSyncIn(piecename,x+x*copy,y+y*copy,z+z*copy,math.ceil(math.abs(timeSnippet)))
				timetotal=timetotal-math.ceil(math.abs(timeSnippet))
			WaitForTurns(piecename)
			copy= math.abs(copy*copy)*sigN
			sigN= sigN*-1
		end



end

--unitID,centerNode,centerNodes, nrofLegs, FeetTable={firstAxisTable, KneeTable[nrOfLegs]},SensorTable,frameRate, FeetLiftForce
--> Trys to create a animation using every piece there is as Legs.. 
function adaptiveAnimation(configTable, inPeace, id, ScriptEnviroment)
    local spGetUnitPosition = Spring.GetUnitPosition
    local infoT = configTable
    pieceMap = {}
    oldHeading = (Spring.GetUnitHeading(unitID) / 32768) * 3.14159
    pieceMap[infoT.centerNode] = {}
    pieceMap = recursiveAddTable(pieceMap, infoT.centerNode, infoT.centerNode, inPeace)

    if not GG.MovementOS_Table then GG.MovementOS_Table = {} end
    quadrantMap = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
    tx, ty, tz = spGetUnitPosition(unitID)
    GG.MovementOS_Table[unitID] = { quadrantMap = quadrantMap, boolmoving = false, stability = 1, tx = tx, ty = ty, tz = tz, ForwardVector = { x = 0, z = 0 } }

    maxDeg = math.random(12, 32)
    turnOffset = 360 / #infoT.feetTable.Knees

    for i = 1, infoT.nr do

        StartThread(feetThread,
            math.floor(math.min(math.max(0, (i * turnOffset) / 360), 1) * 4),
            (-190 + (85) * i),
            maxDeg,
            i,
            infoT.feetTable.firstAxis[i],
            infoT.feetTable.Knees[i],
            infoT.sensorTable[i],
            infoT.ElementWeight or 10,
            infoT.FeetLiftForce or 2,
            infoT.LiftFunction,
            infoT.Height,
            infoT.WiggleFunc,
            ScriptEnviroment,
            infoT.tipTable[i])
    end


    local MotionDetect = function(ox, oz)
        x, y, z = Spring.GetUnitPosition(unitID)
        return math.abs(ox - x) + math.abs(oz - z) < 15, x, z
    end


    Sleep(100)

    ox, oy, oz = spGetUnitPosition(unitID)
    boolMoving = false
    Height = infoT.Height
    while true do
        --find out whether we are moving
        ux, uz = ox, oz
        boolMoving, ox, oz = MotionDetect(ox, oz)
        GG.MovementOS_Table[unitID].tx = ox
        GG.MovementOS_Table[unitID].tz = oz


        GG.MovementOS_Table[unitID].ForwardVector = { x = ox - ux, z = oz - uz }

        local one, three = GG.MovementOS_Table[unitID].quadrantMap[1], GG.MovementOS_Table[unitID].quadrantMap[3]
        local two, four = GG.MovementOS_Table[unitID].quadrantMap[2], GG.MovementOS_Table[unitID].quadrantMap[4]
        total = one + two + three + four
        one, two, three, four = one > 0, two > 0, three > 0, four > 0
        --		//stabilityfactor
        BoolStable = ((one and two and (three or four))) or
                ((two and four) and (three or one)) or
                ((four and three) and (one or two)) or
                ((three and one) and (four or two))

        if BoolStable == false then
            GG.MovementOS_Table[unitID].stability = math.min(1, (1 / total) * GG.MovementOS_Table[unitID].stability)
        else
            GG.MovementOS_Table[unitID].stability = 1
        end

        Move(infoT.centerNode, y_axis, GG.MovementOS_Table[unitID].stability * Height, 3)

        Heading = (Spring.GetUnitHeading(unitID) / 32768) * 3.14159
        boolTurning = math.abs(Heading - oldHeading) > 1


        for i = 1, infoT.nr, 1 do
            degOffSet = (-190 + (85) * i)
            RelHeading = (((degOffSet + 360) - (Heading + 360)) - 360) % 360
            if (RelHeading < 0) then RelHeading = (RelHeading + 360) * -1 end

            if boolTurning == true then
                speed = math.random(5, 15) / 100
                Turn(infoT.feetTable.firstAxis[i], y_axis, math.rad(degOffSet + clamp(RelHeading, -25, 25) * -1), speed)
                turnT(infoT.feetTable.Knees[i], y_axis, clamp(RelHeading, -10, 10) * -1, speed, false, true)
            else
                infoT.WiggleFunc(infoT.feetTable.firstAxis[i], degOffSet)
            end
        end
        Sleep(400)
    end
end


-->Moves a UnitPiece to a UnitPiece at speed
function MovePieceToPiece(unitID, piecename, piecenameB, speed, waitForIt)

    if not piecenameB or not piecename then return end
    bx, by, bz = Spring.GetUnitPiecePosition(unitID, piecenameB)
    bx = -1 * bx

    Move(piecename, x_axis, bx, speed)
    Move(piecename, y_axis, by, speed)
    Move(piecename, z_axis, bz, speed, true)
    if waitForIt == true then
        WaitForMove(piecename, x_axis)
        WaitForMove(piecename, y_axis)
        WaitForTurn(piecename, y_axis)
    end
end

-->Turns a Piece towards a position in unitspace 
function TurnPieceTowards(piecename, x, y, z, speed)

    Turn(piecename, x_axis, math.rad(x), speed)
    Turn(piecename, y_axis, math.rad(y), speed)
    Turn(piecename, z_axis, math.rad(z), speed, true)
end

-->Turn a Piece towards another Piece 
function TurnPieceTowardsPiece(piecename, pieceB, speed)
    ax, ay, az = Spring.GetUnitPiecePosition(unitID, piecename)
    assert(ax)
    px, py, pz = Spring.GetUnitPiecePosition(unitID, pieceB)
    assert(px)
    px, py, pz = ax - px, ay - py, az - pz
    dx = math.deg(math.atan2(px, pz))
    dy = math.deg(math.atan2(px, pz))
    dz = math.deg(math.atan2(py, px))

    echo("Turntoards point")
    TurnPieceTowards(piecename, dx, dy, dz, speed)
end

function getRandomAxis()
    axis = math.random(0, 3)
    return axis
end

function TurnPieceTowardsUnit(piecename, unitToTurnToo, Speed, overrideVec)
    x, y, z = Spring.GetUnitPosition(unitToTurnToo)
    TurnPieceTowardsPoint(piecename, x, y, z, Speed, overrideVec.x, overrideVec.y, overrideVec.z)
end
--> movePiece to Vector

function mPV(piecename, vector, speed, boolWait)
mP(piecename, vector.x, vector.y, vector.z, speed, boolWait)
end

--> Turns a Piece into the Direction of the coords given (can take allready existing piececoords for a speedup
function TurnPieceTowardsPoint(piecename, x, y, z, Speed, lox, loy, loz, limVec)
    pvec = { x = 0, y = 0, z = 0 }
    lox = lox or 0
    loy = loy or 0
    loz = loz or 0
    ox, oy, oz = math.rad(loy), math.rad(lox), math.rad(loz)
	  limVec = limVec or {x=1, y=1, z=1} --limit or identity


    px, py, pz, pvec.x, pvec.y, pvec.z = Spring.GetUnitPiecePosDir(unitID, piecename)
    pvec = normVector(pvec)

    vec = {}
    vec.x, vec.y, vec.z = x - px, y - py, z - pz
    vec = normVector(vec)
    vec = subVector(vec, pvec)
    vec = normVector(vec)

    tPrad(piecename,  limVec.x * (math.atan2(vec.y, vec.z) + ox), 
						limVec.y * (math.atan2(vec.x, vec.z) + oy), 
						limVec.z * (math.atan2(vec.x, vec.y) + oz),
						Speed)
end

function tPVector(piece, vec, speed)
    x = math.atan2(vec.y, vec.z)
    y = math.atan2(vec.x, vec.z)
    z = math.atan2(vec.x, vec.y)
    tPrad(piece, x, y, z, speed)
end

--> Moves a Piece to a WorldPosition relative to the Units Position
function MovePieceToRelativeWorldPos(id, piecename, relX, relY, relZ, speed)
    x, y, z = Spring.GetUnitPosition(id)
    x, y, z = relX - x, y - relY, relZ - z
    Move(piecename, x_axis, x, speed)
    Move(piecename, y_axis, y, speed)
    Move(piecename, z_axis, z, speed, true)
end


function resetDir(piecename, speed)
    Turn(piecename, x_axis, 0, speed)
    Turn(piecename, y_axis, 0, speed)
    Turn(piecename, z_axis, 0, speed)
end

--> calcSpeedThroughDegByTime
function GetSpeed(timeInSeconds, degree)
    degRad = math.rad(degree)
    return (degRad / timeInSeconds)
end

function spasm(id,speed, modfactor)
pieceMap= Spring.GetUnitPieceMap(id)
	
	for name,number in pairs(pieceMap) do
		if number % modfactor == 0 then
			turnPieceRandDir(number, speed, 22, -22, 22, -22, 22, -22)	
		end	
	end
end

function resetAll(unitID)
 pieceMap = Spring.GetUnitPieceMap(unitID)
 for k,v in pairs(pieceMap) do

	reset(v)
	WaitForTurns(v)
	WaitForMoves(v)
 end
end
-->Reset a Table of Pieces at speed

function resetT(tableName, speed, boolShowAll, boolWait, boolIstantUpdate, interValStart, interValEnd)
    lboolWait = boolWait or false
    lspeed = speed or 0
	interValStart= interValStart or 1
	interValEnd = interValEnd or #tableName

    assert(tableName, "libAnimation::resetT: No valid Table")

    for i = interValStart, interValEnd do

        reset(tableName[i], lspeed, false, boolIstantUpdate or true)
        if boolShowAll and tableName[i] then
            Show(tableName[i])
        end
    end

    if lboolWait == true then
        WaitForTurns(tableName)
    end
end


--> applys a physics function to a detached  Piece from a Unit @EventStreamFunction
function unitRipAPieceOut(unitID, rootPiece, shotVector, factor, parabelLength, boolSurvivorHeCanTakeIt)
	-- shotVector.x= shotVector.x*-1
	-- shotVector.y= shotVector.y*-1
	-- shotVector.z= shotVector.z*-1
	pFunction= function(strName)
		map= Spring.GetUnitPieceMap(unitID)
		return map[strName]
	end

	
	pieceFunction=piece or pFunction
	LimbMap= getPiecesBelow(unitID, rootPiece, pieceFunction)
	stunUnit(unitID, 64)
	env = Spring.UnitScript.GetScriptEnv(unitID)
	if env and env.script.Explode and env.script.Hide  then
				 Spring.UnitScript.CallAsUnit(unitID, env.script.Hide, rootPiece)
				Spring.UnitScript.CallAsUnit(unitID, env.script.Explode, rootPiece, env.SFX.FALL + env.SFX.NO_HEATCLOUD)
		
			for k,piecenumber in pairs(LimbMap) do
				Spring.UnitScript.CallAsUnit(unitID, env.script.Hide, piecenumber)

			end
	end

end
-- riplpling show and Hide effect
function rippleHide(array,startIndex, endIndex, Sleeptime)
	Sleeptime= Sleeptime or 600
	for i= startIndex,endIndex do
	Hide(array[i])
	Sleep(Sleeptime)
		if array[i-1] then
			Show(array[i-1])
		end
	end
end
function movePieceInParabel(unitID, pieceName, yDegreeOffset, xDegreeOffset, valueToGo, valueStart, offsetY, steepness, env, speed)
	px, py, pz=Spring.GetUnitPiecePosDir(unitID, pieceName)
	
	y = -1* (steepness * math.min(valueStart, valueToGo)^2 ) + offSetY
	y = Rotate(0, y, xDegreeOffset) 	
	x = Rotate(0, valueToGo, yDegreeOffset)
	
	env.MovePieceToPos(unitID, pieceName, x, y, z)
	
	--TODO rotation matric on result Values
	return px, py + y, pz
end


-->Recursively Resets Tables
function recResetT(Table, speed)
    if type(Table) == "table" then
        for k, v in pairs(Table) do
            recResetT(v, speed)
        end
    elseif type(Table) == "number" then
        reset(Table, speed)
    end
end

--> Resets a piece
function reset(piecename, speed, boolWaitForIT, boolIstantUpdate)
    if not piecename then return end
    if type(piecename) ~= "number" then 
		Spring.Echo("libAnimation::reset:Invalid piecename-got " .. piecename .. " of type " .. type(piecename) .. " instead"); 
		assert(true == false); 
		end
    bIstantUpdate = boolIstantUpdate or true
    StopSpin(piecename, x_axis, 0, speed)
    StopSpin(piecename, y_axis, 0, speed)
    StopSpin(piecename, z_axis, 0, speed)
	
    Turn(piecename, x_axis, 0, speed)
    Turn(piecename, y_axis, 0, speed)
    Turn(piecename, z_axis, 0, speed)

    Move(piecename, x_axis, 0, speed)
    Move(piecename, y_axis, 0, speed)
    Move(piecename, z_axis, 0, speed, bIstantUpdate)
    if boolWaitForIT then
        WaitForTurn(piecename, 1)
        WaitForTurn(piecename, 2)
        WaitForTurn(piecename, 3)
    end
end

function showAllPieces(unitID)
    List = Spring.GetUnitPieceMap(unitID)

    for k, v in pairs(List) do
        Show(v)
    end
end


-->Shows a Pieces Table
function showT(tablename, lowLimit, upLimit, delay)
    if not tablename then Spring.Echo("No table given as argument for showT") return end

    if lowLimit and upLimit then
        for i = lowLimit, upLimit, 1 do
            if tablename[i] then
                Show(tablename[i])
            end
            if delay and delay > 0 then Sleep(delay) end
        end

    else
        for i = 1, table.getn(tablename), 1 do
            if tablename[i] then
                Show(tablename[i])
            end
        end
    end
end

--> Hides a PiecesTable, 
function hideT(tablename, lowLimit, upLimit, delay)
    if not tablename then return end
    boolDebugActive = (lib_boolDebug == true and lowLimit and type(lowLimit) ~= "string")

    if lowLimit and upLimit then
        for i = upLimit, lowLimit, -1 do
            if tablename[i] then
                Hide(tablename[i])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. lowLimit .. " contains a empty entry")
            end

            if delay and delay > 0 then Sleep(delay) end
        end

    else
        for i = 1, table.getn(tablename), 1 do
            if tablename[i] then
                Hide(tablename[i])
            elseif boolDebugActive == true then
                echo("In HideT, table " .. lowLimit .. " contains a empty entry")
            end
        end
    end
end


function objectFalling(objectname, weight, step, OVect, term)
    Terminal = term or -9.81
    weight = 1 / weight
    dx, dy, dz = Spring.GetUnitDirection(unitID)
    ObjectVector = OVec or { x = 0, y = 0, z = 0 }
    sizeX, sizeY, sizeZ = Spring.GetUnitPieceCollisionVolumeData(unitID, objectname)
    size = math.sqrt(sizeX * sizeX + sizeY * sizeY + sizeZ * sizeZ)

    --Here be pseudo physics :)
    while true do
        oPosX, oPosY, oPosZ = Spring.GetUnitPiecePosDir(unitID, objectname)

        --ApplyGravity
        OVec.y = math.max(math.max(OVec.y ^ 2, 1.7) * -1, term)

        --CheckCollission
        if OPosY - size < Spring.GetGroundHeight(oPosX, oPosZ) then
            groundX, groundY, groundZ = Spring.GetGroundNormal(oPosX, oPosY)
            OVec.x, OVec.y, Ovec.z = groundX + OVec.x, (OVec.y * -1) * weight + groundY, OVec.z + groundZ
        end

        --MoveObject
        MaxVal = math.abs(Ovec.y) / (1000 / step)

        --Normalisieren des ObjectVectors
        normV = normVector(OVec)
        normV = mulVector(normV, TotalEnergy)

        speed = 3.141
        stepTimesVec = 1

        Move(objectname, x_axis, Ovec.x * stepTimesVec, speed)
        Move(objectname, y_axis, Ovec.y * stepTimesVec, speed)
        Move(objectname, z_axis, Ovec.z * stepTimesVec, speed)

        Sleep(step)
    end
end

--> Turns a Pieces table according to a function provided
function waveATable(Table, axis, lfoonction, lsignum, lspeed, lfuncscale, ltotalscale, boolContra, offset)

    if type(Table) ~= "table" then return end

    func = lfoonction or function(x) return x end
    signum = lsignum or 1
    speed = lspeed or 1
    totalscale = ltotalscale or (#Table * 3.14159)
    funcscale = lfuncscale or 3.14159
    boolCounter = boolContra or false
    offset = offset or 0
    scalar = signum * (totalscale)
    nr = table.getn(Table)
    pscale = funcscale / nr
    total = 0

    for i = 1, nr do
        val = scalar * func(offset + i * pscale)

        if type(Table[i]) == "table" then
            waveATable(Table[i], axis, func, signum, speed, funcscale, totalscale, boolContra, offset)
        else

            if boolCounter == true then

                Turn(Table[i], axis, math.rad(total + val), speed)

                total = total + val
            else
                Turn(Table[i], axis, math.rad(val), speed)
            end
        end
    end
end

--> creates a table of Accessors 
function getTableAccessor(xDepth, zDepth, boolRandomize)
    halfX = math.ceil(math.abs((xDepth / 2))) * -1
    halfZ = math.ceil(math.abs((zDepth / 2))) * -1
    resulT = {}
    --Spring.Echo("getTableAccessor::", halfX, halfZ)
    for x = halfX, math.abs(halfX) do
        for z = halfZ, math.abs(halfZ) do
            resulT[#resulT + 1] = { x = x, z = z }
        end
    end
    if boolRandomize == true then
        return shuffleT(resulT)
    else
        return resulT
    end
end

--> get a Piece to follow a Path made of Pieces 
function followPath(unitID, pieceName, pathTable, speed, delay, boolWaitForMove, boolDirectional, offset)
	boolWaitForMove = boolWaitForMove or false
	boolDirectional = boolDirectional or false
	
	offset = offset or {x=0,y=0,z=0}
	
	for i = 1, #pathTable do
		pieceNum= pathTable[i]
			if boolDirectional == true then
				dx,dy,dz=  UnitScript.GetPieceRotation(pieceNum)		
				tP(pieceName,dx,dy,dz, speed)		
			end
        movePieceFromPieceToPiece(unitID, pieceName, pieceNum, pathTable[math.max(i-1,1)] , speed, offset)
			
		if boolWaitForMove == true then
			WaitForMoves(pieceName)
		end
        Sleep(delay)
    end
end


function equiTurnAboveGround(turnPiece, 
							counterPiece, 
							SensorPiece, 
							targetY,
							eqStart,
							eqMin, 
							eqMax, 
							speed, 
							resolution,
							axis
							)
Turn(turnPiece,y_axis,math.rad(targetY),speed)
	while true == Spring.UnitScript.IsInTurn(turnPiece,y_axis) do
		inc= -1
		if isPieceAboveGround(unitID,SensorPiece) then inc= 1 end
		eqStart= math.max(eqMin,math.min(eqMax,eqStart + inc))
		equiTurn(turnPiece, counterPiece, axis, eqStart,speed )
		Sleep(resolution)
	end
end
--> Keeps a piece system hovering upright at a HoverPoint
function hoverSegway(SystemPiece,
					 PivotPiece,
					 PowerPiece, 
					 HoverPiece,
					 Resolution, 
					 rotOffsetPivotPiece,
					 rotOffsetPowerPiece,
					 axis, 
					 rotationValueFunction, 
					 activeFunction, 
					 speed,
					 restoreSpeed
					 )
			 
rotOffsetPivotPiece= math.rad(rotOffsetPivotPiece)
rotOffsetPowerPiece= math.rad(rotOffsetPowerPiece)

PivotPos = getPiecePosDir(unitID, PivotPiece)
PowerPos =  getPiecePosDir(unitID, PowerPiece)
HoverPos =getPiecePosDir(unitID,HoverPiece)

speedPerMs=  (speed/1000)
restoreSpeedPerMs=  (restoreSpeed/1000)
cx,cy,cz= Spring.UnitScript.GetPieceRotation(PivotPiece)
	--update PiecePosition (asuming )
	Diff= {x=PivotPos.x - PowerPos.x, y= PivotPos.y - PowerPos.y, z= PivotPos.z - PowerPos.z}
	--echo("PowerPos",PowerPos.x)
	--echo("PivotPos",PivotPos.y)
	--echo("Diff",Diff)
		if Diff.y > 1 then
		
		Turn(PivotPiece,axis,select(axis,cx,cy,cz)  + 3 ,speed/2)
		Turn(PowerPiece,axis,-rotOffsetPivotPiece -rotOffsetPowerPiece-math.random(5,12) ,speed/3)
		--movePieceToPiece(SystemPiece,HoverPiece,speed)
		else
		Turn(PivotPiece,axis, select(axis,cx,cy,cz)  - 3 ,speed/2)
		Turn(PowerPiece,axis, -rotOffsetPivotPiece - rotOffsetPowerPiece + math.random(5,12) ,speed/3)
		--mP(SystemPiece,0,0,0,speed)
		end
	
	Sleep(Resolution)

end



--================================================================================================================
--====================================Little Flying Cars  Clockworkanimation======================================


------------------------------------------------------------------------------------------------------------------------------------------------
function stillMoving(personNr,dramatisPersona3d)
		assert(dramatisPersona3d)
    if (true == Spring.UnitScript.IsInMove(dramatisPersona3d[personNr][2], z_axis) or true == Spring.UnitScript.IsInTurn(dramatisPersona3d[personNr][1], y_axis)) then
        return true

    else
        return false
    end
end

function typeDependedDriveAnimation(personNr, dramatisPersona3d)
    --Enum: Woman(NoSkirt)=1, woman(Skirt)=2, woman(halfSkirt)=3, advisor=4, thinman=5, man=6, womanwithfuckdoll= 7, testbrick=8

    while stillMoving(personNr, dramatisPersona3d) == true do
        Turn(dramatisPersona3d[personNr][2], x_axis, math.rad(0.5), 0.02)
        WaitForTurn(dramatisPersona3d[personNr][2], x_axis)
        Turn(dramatisPersona3d[personNr][2], x_axis, math.rad(-0.25), 0.02)
        WaitForTurn(dramatisPersona3d[personNr][2], x_axis)
    end
    Turn(dramatisPersona3d[personNr][2], x_axis, math.rad(0), 2)

end

function carSenderJobFunc(dramatisPersona3d, personNr)

    targetDist = 500
    NtargetDist = -500
    targetdegree = 90
    Ntargetdegree = 0
    targetHeight = 120
    luckOne = 0
    if math.random(0, 1) == 1 then
        luckOne = math.random(12, 50)/10
    end
    tempDirAction = 1
    tempSpeed = dramatisPersona3d[personNr][10]
    --if car views inside
    if dramatisPersona3d[personNr][6] == 1 then
        --move it through the center move along center axis -lower Axis
        Turn(dramatisPersona3d[personNr][2], y_axis, math.rad(0), 4)
        WaitForTurn(dramatisPersona3d[personNr][2], y_axis)

        dramatisPersona3d[personNr][5] = targetDist

        Move(dramatisPersona3d[personNr][2], z_axis, targetDist, (tempSpeed * 6) + luckOne)
        tempDirAction = 8


    elseif dramatisPersona3d[personNr][6] == 2 then
        --if car views outside beeing high, turn right, turn along radiant via SwingCenter - +down

        Turn(dramatisPersona3d[personNr][2], y_axis, math.rad(270), 4) --FixMe90
        WaitForTurn(dramatisPersona3d[personNr][2], y_axis)

        dramatisPersona3d[personNr][4] = targetdegree
        Move(dramatisPersona3d[personNr][2], y_axis, 0, tempSpeed * 1.4)
        dramatisPersona3d[personNr][13] = 0
        Turn(dramatisPersona3d[personNr][1], y_axis, math.rad(targetdegree), ((dramatisPersona3d[personNr][10]) / 100) + 0.1) --0.3
        tempDirAction = 1

    elseif dramatisPersona3d[personNr][6] == 4 then

        --if car turned right nach innen drehen, move along the uper axis

        Turn(dramatisPersona3d[personNr][2], y_axis, math.rad(180), 4)
        WaitForTurn(dramatisPersona3d[personNr][2], y_axis)
        dramatisPersona3d[personNr][5] = NtargetDist
        Move(dramatisPersona3d[personNr][2], z_axis, NtargetDist, (tempSpeed * 6) + luckOne)
        tempDirAction = 2
    elseif dramatisPersona3d[personNr][6] == 8 then

        Turn(dramatisPersona3d[personNr][2], y_axis, math.rad(-90), 4) --FixMe270
        WaitForTurn(dramatisPersona3d[personNr][2], y_axis)
        dramatisPersona3d[personNr][4] = Ntargetdegree
        Move(dramatisPersona3d[personNr][2], y_axis, targetHeight, tempSpeed * 1.4)
        dramatisPersona3d[personNr][13] = targetHeight
        Turn(dramatisPersona3d[personNr][1], y_axis, math.rad(Ntargetdegree), ((dramatisPersona3d[personNr][10]) / 100) + 0.1) --0.3
        tempDirAction = 4
    end

    dramatisPersona3d[personNr][6] = tempDirAction
    Sleep(1000)
    --if car views outside beeing beeing low turn turn left

    --Enum: inside is 1,
    --		outside is 2,
    --		clockwise is 4,
    -- counterclockwise its 8
    --Person turned into the direction it is going to walk

    --send the person on its way.
    typeDependedDriveAnimation(personNr, dramatisPersona3d)

    --now we update the current position

    if personNr ~= 11 and personNr ~= 1 and personNr ~= 2 and personNr ~= 3 then
        dramatisPersona3d[personNr][10] = math.random(7.9, 22)
    end

    -- we turn the persona into a random direction
    --randomTurn=math.random(0,360)
    --Turn(dramatisPersona3d[personNr][1],y_axis,math.rad(randomTurn),dramatisPersona3d[personNr][10])

    -- now we need a Time, and a idleanimation so the person arriving at the ways end, doesent just stands around

    -- we return the random direction

    --finally we set the unit back into jobless mode, so the partymanager can grab it again, and send it on its way
    dramatisPersona3d[personNr][9] = false
end

function carStarterKid(dramatisPersona3d)
    for i = 1, #dramatisPersona3d, 1 do
        dramatisPersona3d[i][9] = false
        sleeper = math.random(2000, 25000)
        Sleep(sleeper)
        Show((dramatisPersona3d[i][2]))
    end
end

--This is the PartyManager - this function decides were everyone goes
function littleFlyingCars(nrOfCars, ldramatisPersona3d)
dramatisPersona3d = ldramatisPersona3d or initFlyingCars(nrOfCars) 

    for i = 1, nrOfCars, 1 do
        dramatisPersona3d[i][9] = true
        Hide((dramatisPersona3d[i][2]))
    end

    --FixMe
    StartThread(carStarterKid,dramatisPersona3d)


    while (true) do
        for i = 1, nrOfCars, 1 do

            if dramatisPersona3d[i][9] == false then --else the piece is a standaloner on the neverending party allready busy
                dramatisPersona3d[i][9] = true

                moveInOut = 1
                degreeRand = 2 --0*360 in 45 degree Steps

                StartThread(carSenderJobFunc, dramatisPersona3d, i)
            end
        end

        Sleep(120)
    end
end

function initFlyingCars(numberOfActors)
dramatisPersona3d = {}


for i=1, numberOfActors do
	--personObjects
	person = {}

	--traditional pieces hiearchy, swingCenter beeing the Center
	centerString= "swingCenter"..i
	person[1] = piece(centerString) --swingCenter always atfirstPlace 1
	pieceString= "car"..i

	person[2] = piece(pieceString)
	-- a person is defined by the following values: 
	-- its position in degree and distance 

	person[4] = 0--degree
	person[5] = 0--dist
	person[6] = 2


	person[7] = false

	-- the type of char (a intvalue that represents the diffrent purposes 
	--Enum: Woman(NoSkirt)=1, woman(Skirt)=2, woman(halfSkirt)=3, advisor=4, thinman=5, man=6, aircar= 7, airtruck=8
	person[8] = 7
	--boolean on its way (has a thread, even if it is just to idle 
	person[9] = false
	-- speedvalue of the the person

	person[10] =  math.random(1.9, 8)
	--numberOfPieces
	person[11] = 1
	person[12] = 1
	--its height in the 3dmatrixgrid
	person[13] = 0

	dramatisPersona3d[#dramatisPersona3d+1] = person

end
return dramatisPersona3d
end



--================================================================================================================
--================================================================================================================