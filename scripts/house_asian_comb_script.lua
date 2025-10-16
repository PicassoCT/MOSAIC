include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

TablesOfPieceGroups = {}
GameConfig = getGameConfig()
function script.HitByWeapon(x, z, weaponDefID, damage) end
x,y,z = nil, nil, nil
boolDoneShowing = false
RoofTopPieces = {}
base = nil
ToShowTable = {}
Icon =piece("Icon")

-- Returns a random integer between min and max (inclusive)
local function random_range(min, max)
    min = min or 0
    max = max or 1
    return math.floor(math.random() * (max - min + 1)) + min
end

function addToShowTables(tables)
    for i=1,#tables do
        addToShowTable(tables[i])
    end
    return tables
end

function addToShowTable(pieceID)
    ToShowTable[#ToShowTable +1]= pieceID
    return pieceID
end

function showSeveral(T)
    if not T then return end
    ToShow= {}
    for num, val in pairs(T) do 
        if random_range() == 1 then
           ToShow[#ToShow +1] = val
        end
    end

    for i=1, #ToShow do
        ToShowTable[#ToShowTable +1] = ToShow[i]
        Show(ToShow[i])
    end
    return ToShow
end
if not GG.CombsIndex then GG.CombIndex = 1 end
function showOne(T, bNotDelayd)
    if not T then return end
    dice = (GG.CombIndex  % 3) +1
    GG.CombIndex = dice
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
            ToShowTable[#ToShowTable + 1] = v
            if bNotDelayd and bNotDelayd == true then
                Show(v)
            end
            return v
        end
    end
end

function buildHouse()
    resetAll(unitID)
    hideAll(unitID)
    Sleep(1)
    buildBuilding()
end

function buildAnimation()
    Show(Icon)
    while not boolDoneShowing do
        Sleep(1000)
    end
    Hide(Icon)
    waterPlateName = "PlateWater"
    StartThread(waterFalls, TablesOfPieceGroups[waterPlateName])
    waterBaseName = chasingWaterfalls[base]
    if chasingWaterfalls[base] and TablesOfPieceGroups[waterBaseName] then
        StartThread(waterFalls, TablesOfPieceGroups[waterBaseName])
    end
    showHouse()
end

boolHasWaterFalls = false
function waterFalls(waterfallT)
    while waterfallT do
        foreach(waterfallT,
            function (water)
                Show(water)
                val = math.random(0,1)*180
                Turn(water, x_axis, math.rad(randSign()*val),0)
                val = math.random(0,1)*180
                Turn(water, z_axis, math.rad(randSign()*val),0)
            end
            )
    Sleep(35)
    end
end

base1 = piece("base1")
base2 = piece("base2")
base3 = piece("base3")
Plate = piece("Plate")
chasingWaterfalls  = {
    [base1] = "base1Water",
    [base2] = "base2Water",
    [base3] = "base3Water",
    [Plate] = "PlateWater"
}

function buildBuilding()
    StartThread(buildAnimation)
    Sleep(1000)
    addToShowTable(Plate)
    base = addToShowTable(showOne(TablesOfPieceGroups["base"], true))
    showTSubSpins(base, TablesOfPieceGroups)
    if base == base1 then  
        showSeveral(TablesOfPieceGroups["ShowCombe"])   
        RoofTopPieces = TablesOfPieceGroups["RoofTopCircle"]
    end

    if base == base2 then RoofTopPieces = TablesOfPieceGroups["RoofTopSquare"] end
    if base == base3 then RoofTopPieces = TablesOfPieceGroups["RoofTopUpright"] end
    boolDoneShowing = true
end

function script.Create()
    TablesOfPieceGroups = getPieceTableByNameGroups(false, true)
    x, y, z = Spring.GetUnitPosition(unitID)
    StartThread(removeFeaturesInCircle,x,z, GameConfig.houseSizeZ/2) 
    math.randomseed(x + y + z)
    StartThread(buildHouse)
    StartThread(addGroundPlaceables)
end

function addGroundPlaceables()
    Sleep(500)
    x,y,z = Spring.GetUnitPosition(unitID)
    globalHeightUnit = Spring.GetGroundHeight(x, z)
    placeAbles =  TablesOfPieceGroups["Placeable"]
    if not GG.SimPlaceableCounter then GG.SimPlaceableCounter = 0 end
    if placeAbles and count(placeAbles) > 0 then
        groundPiecesToPlace= math.random(1,5)
        randPlaceAbleID = ""
        while groundPiecesToPlace > 0 do
            randPlaceAbleID = getSafeRandom(placeAbles)     

            if randPlaceAbleID  then
                opx= math.random(cubeDim.length * 4, cubeDim.length * 7) * randSign()
                opz= math.random(cubeDim.length * 4, cubeDim.length * 7) * randSign()

                if garbageSimPlaceable[randPlaceAbleID] and GG.SimPlaceableCounter < 1 then
                    GG.SimPlaceableCounter = GG.SimPlaceableCounter +1
                    StartThread(runGarbageSim, opx, opz)
                end
                WMove(randPlaceAbleID,x_axis, opz, 0)
                WMove(randPlaceAbleID,z_axis, opx, 0)
                Sleep(1)
                x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, randPlaceAbleID)
                myHeight = Spring.GetGroundHeight(x, z)
                if myHeight > 0 then
                    heightdifference =  myHeight -globalHeightUnit
                    WMove(randPlaceAbleID,y_axis, heightdifference, 0)
                    showSubs(pieceNr_pieceName[randPlaceAbleID])   
                    addToShowTable(randPlaceAbleID)
                    Show(randPlaceAbleID)    
                end
            end
            groundPiecesToPlace = groundPiecesToPlace - 1
        end 
    end
end

local GRAVITY = -0.15
local FLOOR_Y = 0
local BOUND = {minX=-50, maxX=50, minY=0, maxY=10, minZ=-50, maxZ=50}


function PhysicsTick(dt, pieces)
 _, _, _, _, wx, wy, wz = Spring.GetWind()
 local WIND = {wx, wy, wz}
 for _,p in ipairs(pieces) do
    local vx,vy,vz = p.vel[1], p.vel[2], p.vel[3]

    -- forces
    vy = vy + GRAVITY * dt
    vx = vx + WIND[1] * dt / p.mass
    vz = vz + WIND[3] * dt / p.mass

    -- drag
    vx,vy,vz = vx * p.drag, vy * p.drag, vz * p.drag
    if p.lift then vy = vy + p.lift * WIND[1] * dt end

    -- integrate
    local x = p.pos[1] + vx
    local y = p.pos[2] + vy
    local z = p.pos[3] + vz

    -- collisions with cube boundary
    local bounce = 0.4
    if x < BOUND.minX then x = BOUND.minX; vx = -vx * bounce end
    if x > BOUND.maxX then x = BOUND.maxX; vx = -vx * bounce end
    if y < BOUND.minY then y = BOUND.minY; vy = -vy * bounce end
    if y > BOUND.maxY then y = BOUND.maxY; vy = -vy * bounce end
    if z < BOUND.minZ then z = BOUND.minZ; vz = -vz * bounce end
    if z > BOUND.maxZ then z = BOUND.maxZ; vz = -vz * bounce end

    -- update
    p.pos = {x,y,z}
    p.vel = {vx,vy,vz}

    -- spin decay
    p.spin[1] = p.spin[1] * 0.98
    p.spin[2] = p.spin[2] * 0.98
    p.spin[3] = p.spin[3] * 0.98

    -- integrate rotation
    p.rot[1] = (p.rot[1] + p.spin[1]*dt) % 360
    p.rot[2] = (p.rot[2] + p.spin[2]*dt) % 360
    p.rot[3] = (p.rot[3] + p.spin[3]*dt) % 360

    -- apply to pieces
    Move(p.piece, x_axis, x, 0)
    Move(p.piece, y_axis, y, 0)
    Move(p.piece, z_axis, z, 0)
    Turn(p.piece, x_axis, math.rad(p.rot[1]), 0)
    Turn(p.piece, y_axis, math.rad(p.rot[2]), 0)
    Turn(p.piece, z_axis, math.rad(p.rot[3]), 0)
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
-- 
function runGarbageSim(opx, opz)
     local pieces = {
      {name="SimCan1",  mass=1.0, drag=0.9},
      {name="SimCan2",  mass=1.0, drag=0.9},
      {name="SimBox1",  mass=2.5, drag=0.85},
      {name="SimPaper", mass=0.2, drag=0.95, lift=0.1}
    }

    PlaceableSimPos = piece("PlaceableSimPos")
    WMove(PlaceableSimPos, x_axis, opx, 0)
    WMove(PlaceableSimPos, z_axis, opz, 0)
    -- runtime state

    x,y,z = Spring.GetUnitPiecePosDir(unitID, pieceID)
    for _,p in ipairs(pieces) do
      local pieceID = piece(p.name)
      if maRa() then
          Show(pieceID)
      end
      p.piece = pieceID
      p.pos = {0,  0, 0}
      p.vel = {math.random()*0.1-0.05, 0, math.random()*0.1-0.05}
      p.rot = {math.random()*360, math.random()*360, math.random()*360}
      p.spin = {math.random()*2-1, math.random()*2-1, math.random()*2-1}
    end

    while true do
        physicsDurationSeconds = getSetPhysicsSimToken()
        if physicsDurationSeconds then
            for i= 1, physicsDurationSeconds do
                PhysicsTick(1, pieces)  -- or use dt = Spring.GetLastUpdateSeconds()
                Sleep(1000)
            end
        end
        randoSleep = math.random(1,32)*100 --backoffstrategy
        Sleep(randSleep)
    end
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

function showHouse() boolHouseHidden = false; showT(ToShowTable) end

function hideHouse() boolHouseHidden = true; hideT(ToShowTable) end

boolDoneShowing = false
boolHouseHidden = false

function traceRayRooftop( vector_position, vector_direction)
    return GetRayIntersectPiecesPosition(unitID, RoofTop, vector_position, vector_direction)
end
 