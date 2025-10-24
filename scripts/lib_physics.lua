-- ======================================================================================
-- Section: Physics 
-- ======================================================================================
-- > jerks a unitPiece to a diffrent rotation Value, slowly returning it to its old Position
function shakeUnitPieceRelative(id, pieceName, axis, offset, speed)
    env = Spring.UnitScript.GetScriptEnv(id)
    DirT = {}
    DirT[1], DirT[2], DirT[3] = env.GetPieceRotation(pieceName)
    ValueToReturn = select(axis, DirT)
    env.Turn(pieceName, axis, ValueToReturn + math.rad(offset), 0, true)
    env.Turn(pieceName, axis, ValueToReturn, speed, true)

end
-- > spins a units piece along its smallest axis
function SpinAlongSmallestAxis(unitID, piecename, degree, speed)
    if not piecename then return end
    vx, vy, vz = Spring.GetUnitPieceCollisionVolumeData(unitID, piecename)
    areax, areay, areaz = 0, 0, 0
    if vx and vy and vz then
        areax, areay, areaz = vy * vz, vx * vz, vy * vx
    else
        return
    end

    if holdsForAll(areax, " <= ", areay, areaz) then
        Spin(piecename, x_axis, math.rad(degree), speed)
        return
    end
    if holdsForAll(areay, " <= ", areaz, areax) then
        Spin(piecename, y_axis, math.rad(degree), speed)
        return
    end
    if holdsForAll(areaz, " <= ", areay, areax) then
        Spin(piecename, z_axis, math.rad(degree), speed)
        return
    end
end

function LayFlatOnGround(unitID, piecename, speeds)
    speed = speeds or 0
    if not piecename then return end
    vx, vy, vz = Spring.GetUnitPieceCollisionVolumeData(unitID, piecename)
    areax, areay, areaz = 0, 0, 0
    if vx and vy and vz then areax, areay, areaz = vy * vz, vx * vz, vy * vx end

    if holdsForAll(areax, " >= ", areay, areaz) then
        tP(piecename, 0, 90, 90, speed)
        return
    end
    if holdsForAll(areay, " >= ", areaz, areax) then
        tP(piecename, 90, 0, 90, speed)
        return
    end
    if holdsForAll(areaz, " >= ", areay, areax) then
        tP(piecename, 0, 0, 0, speed)
        return
    end
end

-- This code is a adapted Version of the NeHe-Rope Tutorial. All Respect towards those guys.
-- RopePieceTable by Convention contains (SegmentBegin)----(SegmentEnd)(SegmentBegin)----(SegmentEnd) 
-- RopeConnectionPiece PieceID-->ContainsMass,ColRadius |

-- ForceFunction --> forceHead(objX,objY,objZ,worldX,worldY,worldZ,objectname,mass)

function ropePhysix(RopePieceTable, MassLengthPerPiece, forceFunctionTable,
                    SpringConstant, boolDebug)

    -- SpeedUps
    assert(RopePieceTable, "RopePieceTable not provided")
    assert(MassLengthPerPiece, "MassLengthPerPiece not provided")

    assert(forceFunctionTable, "forceFunctionTable not provided")
    assert(SpringConstant, "SpringConstant not provided")

    local spGPos = Spring.GetUnitPiecePosDir
    local spGGH = Spring.GetGroundHeight
    local spGN = Spring.GetGroundNormal
    local spGUPP = Spring.GetUnitPiecePosition
    local spGUP = Spring.GetUnitPosition
    local ffT = forceFunctionTable
    local groundHeight = function(piece)
        x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, piece)
        return Spring.GetGroundHeight(x, z)
    end
    -- Each Particle Has A Weight Of 50 Grams

end

-- forceFunctionTable Example
function hitByExplosionAtCenter(objX, objY, objZ, worldX, worldY, worldZ,
                                objectname, mass, dirX, dirY, dirZ)
    objX, objY, objZ = objX - worldX, objY - worldY, objZ - worldZ
    distanceToCenter = (objX ^ 2 + objY ^ 2 + objZ ^ 2) ^ 0.5
    blastRadius = 350
    Force = 4000000000000
    factor = blastRadius / (2 ^ distanceToCenter)
    if distanceToCenter > blastRadius then factor = 0 end
    normalIsDasNicht = math.max(math.abs(objX),
                                math.max(math.abs(objY), math.abs(objZ)))

    objX, objY, objZ = objX / normalIsDasNicht, objY / normalIsDasNicht,
                       objZ / normalIsDasNicht
    -- density of Air in kg/m^3 -- area
    airdrag = 0.5 * 1.1455 * ((normalIsDasNicht * factor * Force) / mass) ^ 2 *
                  15 * 0.47

    if math.abs(objX) == 1 then
        return objX * factor * Force - airdrag, objY * factor * Force,
               objZ * factor * Force
    elseif math.abs(objY) == 1 then

        return objX * factor * Force, objY * factor * Forceairdrag,
               objZ * factor * Force
    else

        return objX * factor * Force, objY * factor * Force,
               objZ * factor * Forceairdrag
    end
end

-- > <Deprecated> a Pseudo Physix Engien in Lua, very expensive, dont use extensive	--> forceHead(objX,objY,objZ,worldX,worldY,worldZ,objectname,mass)
function PseudoPhysix(piecename, pearthTablePiece, nrOfCollissions,
                      forceFunctionTable)

    speed = math.random(1, 4)
    rand = math.random(10, 89)
    Turn(piecename, x_axis, math.rad(rand), speed)
    dir = math.random(-90, 90)
    speed = math.random(1, 3)
    Turn(piecename, y_axis, math.rad(dir), speed)

    -- SpeedUps
    local spGPos = Spring.GetUnitPiecePosDir
    local spGGH = Spring.GetGroundHeight
    local spGN = Spring.GetGroundNormal
    local mirAng = mirrorAngle
    local spGUPP = Spring.GetUnitPiecePosition
    local spGUP = Spring.GetUnitPosition
    local ffT = forceFunctionTable
    posX, posY, posZ, dirX, dirY, dirZ = spGPos(unitID, pearthTablePiece)
    ForceX, ForceY, ForceZ = 0, 0, 0
    oposX, oposY, oposZ = posX, posY, posZ

    mass = 600
    simStep = 75
    gravity = -1 * (Game.gravity) -- in Elmo/s^2 --> Erdbeschleunigung 

    -- tV=-1* 
    terminalVelocity = -1 * (math.abs((2 * mass * gravity)) ^ 0.5)
    ForceGravity = -1 * (mass * Game.gravity) -- kgE/ms^2

    GH = spGGH(posX, posZ) -- GroundHeight
    if oposY < GH then oposY = GH end

    VelocityX, VelocityY, VelocityZ = 0, 0, 0
    factor = (1 / 1000) * simStep

    boolRestless = true

    while boolRestless == true do

        -- reset
        ForceX, ForceY, ForceZ = 0, 0, 0

        -- update
        posX, posY, posZ, dirX, dirY, dirZ = spGPos(unitID, pearthTablePiece)
        _, _, _, dirX, dirY, dirZ = spGPos(unitID, piecename)

        -- normalizing
        normalizer = math.max(math.max(dirX, dirY), dirZ)
        if normalizer == nil or normalizer == 0 then normalizer = 0.001 end
        dirX, dirY, dirZ = dirX / normalizer, dirY / normalizer,
                           dirZ / normalizer

        -- applying gravity and forces 
        ForceY = ForceGravity

        if ffT ~= nil then -- > forceHead(objX,objY,objZ,oDirX,oDirY,oDirZ,objectname,dx,dy,dz)
            bx, by, bz = Spring.spGUP(unitID)
            dx, dy, dz = spGUPP(unitID, piecename)
            dmax = math.sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2)
            dx, dy, dz = dx / dmax, dy / dmax, dz / dmax

            for i = 1, #ffT, 1 do
                f2AddX, f2AddY, f2AddZ =
                    ffT[i](posX, posY, posZ, bx, by, bz, piecename, mass, dx,
                           dy, dz)
                ForceX = ForceX + f2AddX
                ForceY = ForceY + f2AddY
                ForceZ = ForceZ + f2AddZ
            end
        end

        GH = spGGH(posX + VelocityX + (ForceX / mass) * factor,
                   posZ + VelocityZ + (ForceZ / mass) * factor)
        boolCollide = false

        -- GROUNDcollission

        if (posY - GH - 15) < 0 then
            boolCollide = true
            nrOfCollissions = nrOfCollissions - 1

            total = math.abs(VelocityX) + math.abs(VelocityY) +
                        math.abs(VelocityZ)
            -- get Ground Normals

            nX, nY, nZ = spGN(posX, posZ)
            max = math.max(nX, math.max(nY, nZ))
            _, tnY, _ = nX / max, nY / max, nZ / max

            -- if still enough enough Force or stored kinetic energy
            if total > 145.5 or nrOfCollissions > 0 or tnY < 0.5 then
            else
                -- PhysixEndCase
                boolRestless = false
            end

            VelocityX, VelocityY, VelocityZ = 0, 0, 0

            -- could do the whole torque, but this prototype has fullfilled its purpose
            --	up=math.max(math.max((total/mass)%5,4),1)+1

            dirX, dirY, dirZ = mirAng(nX, nY, nZ, dirX, dirY, dirZ)
            speed = math.random(5, 70) / 10
            Turn(piecename, x_axis, dirX, speed)
            speed = math.random(5, 60) / 10
            Turn(piecename, y_axis, dirY, speed)
            speed = math.random(5, 50) / 10
            Turn(piecename, z_axis, dirZ, speed)

            -- we have the original force * constant inverted - Gravity and Ground channcel each other out
            RepulsionForceTotal = ((math.abs(ForceY) + math.abs(ForceZ) +
                                      math.abs(ForceX)) * -0.65)
            ForceY = ForceY + ((dirY * RepulsionForceTotal))

            ForceX = ForceX + ((dirX * RepulsionForceTotal))
            ForceZ = ForceZ + ((dirZ * RepulsionForceTotal))
            VelocityY = math.max(VelocityY + ((ForceY / mass) * factor),
                                 terminalVelocity * factor)

        else

            -- FreeFall		

            VelocityY = math.max(VelocityY + ((ForceY / mass) * factor),
                                 terminalVelocity * factor)
        end

        VelocityX = math.abs(VelocityX + (ForceX / mass) * factor)
        VelocityZ = math.abs(VelocityZ + (ForceZ / mass) * factor)

        -- Extract the Direction from the Force
        xSig = ForceX / math.max(math.abs(ForceX), 0.000001)
        ySig = ForceY / math.max(math.abs(ForceY), 0.000001)
        zSig = ForceZ / math.max(math.abs(ForceZ), 0.000001)

        -- FuturePositions
        fX, fY, fZ = worldPosToLocPos(oposX, oposY, oposZ,
                                      posX + math.abs(VelocityX) * xSig,
                                      posY + math.abs(VelocityY) * ySig,
                                      posZ + math.abs(VelocityZ) * zSig)

        if boolCollide == true or boolRestless == false or (fY - GH - 12 < 0) then
            fY = -1 * oposY + GH
        end
        -- Debugdatadrop

        --	Spring.Echo("ySig",ySig.."	Physix::ComendBonker::fY",fY.."VelocityY::",VelocityY .." 	ForceY::",ForceY .." 	POSVAL:", posY + VelocityY*ySig)

        Move(pearthTablePiece, x_axis, fX,
             VelocityX * 1000 / simStep + 0.000000001)
        Move(pearthTablePiece, y_axis, fY, VelocityY * 1000 / simStep)
        Move(pearthTablePiece, z_axis, fZ,
             VelocityZ * 1000 / simStep + 0.000000001)

        Sleep(simStep)
    end
end

function placePieceOnGround(unitID, pieceID, speeds)
    sx, sy, sz = Spring.GetUnitPosition(unitID)
    globalHeightUnit = Spring.GetGroundHeight(sx, sz)
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, pieceID)
    myHeight = Spring.GetGroundHeight(x, z)
    heightdifference = math.abs(globalHeightUnit - myHeight)
    if myHeight < globalHeightUnit then
        heightdifference = -1 * heightdifference
    end

--    echo("Moving "..getUnitPieceName(unitID, pieceID).." moved to height:".. heightdifference.. " at worldpos :"..x.."/"..z)

    
	Move(pieceID, 2, heightdifference, speeds or 0)
    WaitForMove(pieceID, 2)
    return heightdifference
end

function fallingPhysPieces(pName, ivec, ovec)

    Show(pName)
    spinRand(pName, 10, 42, 5)
    local tx, ty, tz = math.random(-60, 60), math.random(40, 90),
                       math.random(-60, 60)
    local offVec = {x = 0, y = 0, z = 0}

    if ovec then offVec = ovec end

    if ivec then tx, ty, tz = ivec.x, ivec.y, ivec.z end

    mSyncIn(pName, tx, ty, tz, 1000)
    WaitForMoves(pName)
    local reducefactor = 1
    local t = 700
    spawnCegAtPiece(unitID, pName, "dirt")

    while reducefactor > 0.001 and t > 5 do
        local groundHug = placePieceOnGround(unitID, pName)
        mSyncIn(pName, tx + tx * reducefactor - offVec.x, groundHug - offVec.y,
                tz + tz * reducefactor - offVec.z, t)

        t = math.ceil((ty * reducefactor)) * 10

        tx, tz = tx + tx * reducefactor, tz + tz * reducefactor
        reducefactor = reducefactor / math.pi
        WaitForMoves(pName)
        spawnCegAtPiece(unitID, pName, "dirt", 5)

        mSyncIn(pName, tx + tx * reducefactor - offVec.x, math.min(
                    ty * reducefactor, groundHug + ty * reducefactor) - offVec.y,
                tz + tz * reducefactor - offVec.z, t)

        tx, tz = tx + tx * reducefactor, tz + tz * reducefactor
        WaitForMoves(pName)
        Sleep(1)
    end

    mSyncIn(pName, tx + tx * reducefactor - offVec.x,
            groundHugDay(pName) - offVec.y, tz + tz * reducefactor - offVec.z, t)
    stopSpins(pName)
end

function setupGarbageSim(pieceParams)
    boolAtLeastOne = false
    for k,p in ipairs(pieceParams.pieces) do
      local pieceID = piece(p.name)

      if maRa() then
          Show(pieceID)
          boolAtLeastOne = true
      end
      p.piece = pieceID
      if p.typ == "can" then
          p.rotator = piece(p.rotator)
      end
      p.pos = { 
        math.random(pieceParams.params.BOUND.minX,  pieceParams.params.BOUND.maxX),
        0,  
        math.random(pieceParams.params.BOUND.minZ, pieceParams.params.BOUND.maxZ)}
      p.vel = {math.random()*0.1-0.05, 0, math.random()*0.1-0.05}
      p.rot = {math.random()*360, math.random()*360, math.random()*360}
      p.spin = {math.random()*2-1, math.random()*2-1, math.random()*2-1}
      pieceParams.pieces[k] = p
    end

    if boolAtLeastOne then 
        return  pieceParams
    end
end

function getSetPhysicsSimToken()
    if not GG.PlaceablePhysicsTokenFreeNextFrame then  GG.PlaceablePhysicsTokenFreeNextFrame = -90 end 
    currentFrame = Spring.GetGameFrame()
    if currentFrame >=  GG.PlaceablePhysicsTokenFreeNextFrame then
        physicsIntervallSeconds = math.random(5, 25)
        physicsIntervallMs = SecToMs(physicsIntervallSeconds)
        frames = MsToFrame(physicsIntervallMs)
        GG.PlaceablePhysicsTokenFreeNextFrame = currentFrame + frames
        return physicsIntervallSeconds
    end
    return nil
end

function PhysicsTick(dt, pieceParams, phase)
 local params = pieceParams.params
 local BOUND = params.BOUND
  dx, dy,dz_, _, wx, wy, wz = Spring.GetWind()
  local WIND = {wx, wy, wz}
  scale = 15


 local function addSpinImpulse(p, s)
   p.spin[1]=p.spin[1]+(math.random()-0.5)*s
   p.spin[2]=p.spin[2]+(math.random()-0.5)*s
   p.spin[3]=p.spin[3]+(math.random()-0.5)*s
 end

 for index,p in ipairs(pieceParams.pieces) do
    local vx,vy,vz = p.vel[1], p.vel[2], p.vel[3]

    -- forces
    vy = vy + params.GRAVITY * dt* scale 
    vx = vx + ( WIND[1] * dt* scale) / p.mass * phase
    vz = vz + ( WIND[3] * dt* scale) / p.mass * phase

    -- drag
     vx = vx * (p.drag * phase + (1-phase)*0.95)
     vy=  vy * (p.drag * phase + (1-phase)*0.95)
     vz =  vz * (p.drag * phase + (1-phase)*0.95)
    if p.lift then vy = vy + p.lift * WIND[1] * dt * scale end

    -- integrate
    local x = p.pos[1] + vx
    local y = p.pos[2] + vy
    local z = p.pos[3] + vz

    -- collisions with cube boundary
    local bounce = 0.4
    if x < BOUND.minX then x = BOUND.minX; vx = -vx * bounce; addSpinImpulse(p,5) end
    if x > BOUND.maxX then x = BOUND.maxX; vx = -vx * bounce; addSpinImpulse(p,5) end
    if y < BOUND.minY then y = BOUND.minY; vy = -vy * bounce; addSpinImpulse(p,8) end
    if y > BOUND.maxY then y = BOUND.maxY; vy = -vy * bounce; addSpinImpulse(p,3) end
    if z < BOUND.minZ then z = BOUND.minZ; vz = -vz * bounce; addSpinImpulse(p,5) end
    if z > BOUND.maxZ then z = BOUND.maxZ; vz = -vz * bounce; addSpinImpulse(p,5) end

    -- update
    oldPos = p.pos 
    p.pos = {x,y,z}
    p.vel = {vx,vy,vz}

    -- spin decay
    p.spin[1] = p.spin[1] * 0.98
    p.spin[2] = p.spin[2] * 0.98
    p.spin[3] = p.spin[3] * 0.98

    -- integrate rotation
    local oldRot = p.rot
    p.rot[1] = (p.rot[1] + p.spin[1]*dt) % 360
    p.rot[2] = (p.rot[2] + p.spin[2]*dt) % 360
    p.rot[3] = (p.rot[3] + p.spin[3]*dt) % 360

    -- After applying wind or bounce
    local windEnergy = math.abs(WIND[1]*vx + WIND[3]*vz)
    if math.random() < 0.2 then
      p.spin[1] = p.spin[1] + (math.random()-0.5) * windEnergy * 50
      p.spin[2] = p.spin[2] + (math.random()-0.5) * windEnergy * 50
    end

    --only if box or paper
    if p.typ == "can" then
        movePosInTime(p.rotator, oldPos, p.pos, dt)
        windDir = math.atan2(wx, wz) + math.pi/2
        Turn(p.piece, y_axis, windDir, math.pi)
        Spin(p.piece, z_axis, math.rad(p.spin[1]), math.pi)
    else
        movePosInTime(p.piece, oldPos, p.pos, dt)
        for ax=1, 3 do
          turnInTime(p.piece, ax,  p.rot[ax],  dt * 1000, oldRot[1], oldRot[2], oldRot[3], false)
        end
    end
  end
end

function runGarbageSim(pieceParams, opx, opz, heightoffset)
    local heightoffset = heightoffset or 100
    local pieceParams = setupGarbageSim(pieceParams)
    if not pieceParams then return end
    WMove(pieceParams.PlaceableSimPos, x_axis, -opx, 0)
    WMove(pieceParams.PlaceableSimPos, y_axis, heightoffset, 0)
    WMove(pieceParams.PlaceableSimPos, z_axis, -opz, 0)
    -- runtime state

    while true do
        local physicsDurationSeconds = getSetPhysicsSimToken()
        local rollOutDuration = 3 -- seconds
        local phase = 1.0
        if physicsDurationSeconds then
            local startRollout = physicsDurationSeconds - rollOutDuration
            echo("PhysicsSim running at "..locationstring(unitID).. " for "..physicsDurationSeconds.. " seconds")
            for i= 1, physicsDurationSeconds do
                if i >= startRollout then
                    local t = (i - startRollout) / rollOutDuration
                    phase = math.max(0, 1 - t)
                end
                PhysicsTick(1, pieceParams, phase)  -- or use dt = Spring.GetLastUpdateSeconds()
                Sleep(1000)
            end
        end
        Sleep(5)
    end
end