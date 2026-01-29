include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

restTime = (60*1000)/20
LightOn = piece("LightOn")
LightOff = piece("LightOff")

x_axis=1
y_axis = 2
z_axis= 3
randf = math.random
function unfoldPiece(pID)
    val = math.random(50, 500)
    Sleep(val)
    StopSpin(pID, 1, 5)
    StopSpin(pID, 2, 5)
    StopSpin(pID, 3, 5)
    reset(pID, 2.5)
    val = math.random(-360, 360)
    Turn(pID, y_axis, math.rad(val), 5)
end
SmokeStem = piece("SmokeStem")
local function animateGasCloud(pieces)
 
    for i = 1, #pieces do
        local p = pieces[i]
        if p then
            piecePos[i] = {
                    randf(180, 325),
                    randf(180, 325),
                    randf(180, 325)
                }
                Show(p)
    
                -- fast outward bloom
                Move(p, 1, piecePos[i][1] *randSign(), math.random(40,128))
                Move(p, 2, piecePos[i][2]*randSign(), math.random(40,128))
                Move(p, 3, piecePos[i][3]*randSign(), math.random(40,128))
    
    
            -- turbulent rotation
            spinRand(p, -5, 5, randf(18, 32))
        end
    end
    Sleep(5000)
end


local function driftCloud(stem, dirX, dirZ, timeMs)
    SetSignalMask(SIG_WIND)
    Signal(SIG_WIND)
    local steps = math.floor(timeMs / 250)
    local speed = 20
    valX= dirX
    valZ= dirZ
    while timeMs > 0 do
        valX =  valX + dirX * speed
        valZ =  valZ + dirZ * speed
        Move(stem, 1, valX, math.abs(dirX * speed))
        Move(stem, 3, valX, math.abs(dirZ * speed))
        
        Sleep(1000)
        timeMs = timeMs - 1000
    end
end

local function collapseAndFade(pieces)
    hideT(TablesOfPiecesGroups["FireRotor"])
    for i = 1, #pieces do
        local p = pieces[i]

        -- stop spinning
        StopSpin(p, x_axis)
        StopSpin(p, y_axis)
        StopSpin(p, z_axis)

        -- pull inward & downward
        reset(p, 500)
    end

    Sleep(800)
    hideT(pieces)
end

SIG_FLAME = 2
SIG_WIND = 4
local function resetZ(t, speed)
    for i=1,#t do
        Move(t[i], 3, 0, speed)
    end
end


Flame = piece("Flame1")
FlameT = {}
FlameTips = {}


function reignition()
 

    -- collapse
    for i=1,#FlameT do
        Move(FlameT[i], 3, -FLAME_HEIGHT, 0)
    end
       showT(FlameTips)
    showFlames()
    Move(FlameT[1], 3, 0, 0)
    Sleep(100)    
    -- grow upward
    for i=2,#FlameT do
        Move(FlameT[i], 3, FLAME_HEIGHT + math.random(0,30)*randSign(), FLAME_HEIGHT)
    end

    Sleep(400)
end

function flameOut()
    hideT(FlameTips)

    -- column collapses
    for i=1,#FlameT do
        Move(FlameT[i], 3, -FLAME_HEIGHT, 140)
    end

    -- base drifts away
    local dx = math.random(-20,20)
    local dz = math.random(-20,20)

    Move(Flame, 1, dx, 10)
    Move(Flame, 2, dz, 10)
    WaitForMoves(FlameT)
    Sleep(600)
    hideT(TablesOfPiecesGroups["FlameA"])
    Sleep(300)
    hideT(TablesOfPiecesGroups["FlameB"])
    Sleep(200)
    hideT(TablesOfPiecesGroups["FlameC"])
    resetT(FlameT)
end


function randT(Table)
    return Table[math.random(1, #Table)]
end

function showExplosions()
    foreach(TablesOfPiecesGroups["FireRotor"],
        function(id)
            if maRa() then
                spinRand(id, math.random(-420,-1), math.random(0,420))
                Show(id)
            end
        end)
    end

function showFlames()
    resetT(TablesOfPiecesGroups["FlameA"])
    resetT(TablesOfPiecesGroups["FlameB"])
    resetT(TablesOfPiecesGroups["FlameC"])
    a = randT(TablesOfPiecesGroups["FlameA"])
    b = randT(TablesOfPiecesGroups["FlameB"])
    c = randT(TablesOfPiecesGroups["FlameC"])

res = {
     a,
     b, 
     c
    }

     foreach(res,
        function(id)
            Show(id)
            --Spin(id, 2, math.rad(42)*randSign(), 0) 
        end
        )
     return res
end

FLAME_HEIGHT = 128
FireRotor = piece("FireRotor")
BaseFlame = piece("Flame1")
function burning()
    flameTongue = showFlames()
    Show(Flame)
    BurnAxis = 3
    SWAY_MAX = 80
    FLICKER = 15

    reset(Flame)
    resetT(FlameT)
    WIND_MAX = Game.windMax  -Game.windMin
    
    while true do
         dx, dy, dz, strength = Spring.GetWind()
        local headRad =  math.abs(math.atan2(dx, dz)%(2 * math.pi))
        sway = SWAY_MAX * (strength/WIND_MAX)
        Turn(FireRotor, 3, headRad, math.pi)  
        -- column collapses
        Turn(BaseFlame, 2, math.rad(sway), math.pi)
        gf = Spring.GetGameFrame()
        for i=2,#FlameT do
            Move(FlameT[i], BurnAxis, FLAME_HEIGHT + math.random(0,30)*randSign(), FLAME_HEIGHT)
            factor = (gf/30) + i*math.pi * 0.5
            Turn(FlameT[i], 1, math.rad(math.sin(factor)*18), 1)
        end


        local flameTip = showOnePiece(FlameTips, math.random(0,15))   
        spinRand(flameTip, -FLICKER, FLICKER, 20)

       if math.random() < 0.02 then
           Hide(flameTip)
           return         
       end
        Sleep(1)
        WaitForMoves(FlameT)
        gf = Spring.GetGameFrame()
        -- grow upward
        for i=2,#FlameT do
            Move(FlameT[i], BurnAxis, FLAME_HEIGHT*0.25*randSign() , FLAME_HEIGHT*0.5)
            factor = (gf/30) + i*math.pi * 0.5
            Turn(FlameT[i], 1, math.rad(math.sin(factor)*18), 1)
        end
       -- reset(flameTip, 10)
        Sleep(1)
        WaitForMoves(FlameT)
        hideT(flameTongue)
        flameTongue = showFlames()
        Hide(flameTip)
        stopSpins(flameTip, 0)  
    end
end

function flameController()
    Signal(SIG_FLAME)
    SetSignalMask(SIG_FLAME)

   
end

function flameSpin()
    Signal(SIG_FLAME)
    SetSignalMask(SIG_FLAME)

    while true do
        reignition()
        burning()

        flameOut()
        Sleep(math.random(800,1500))
       
    end
end

piecePos = {}
local function flicker(t)
    while true do
        spinRand(t, -10, 10, 1)
        Sleep(250)
        reset(t)
    end     
end



Igniter  = piece("Igniter")
explosionStem  = piece("ExplosionStem")
function explosionLoop()
    Sleep(100)
    Show(Igniter)
    StartThread(flicker, Igniter)
    explosionTable = TablesOfPiecesGroups["Explosion"]
    cloudRadius = 750
    driftTimeInMs = 3000
    hideT(TablesOfPiecesGroups["Flame"])
    Hide(SmokeStem)
 

    while true do 
        for i =  #TablesOfPiecesGroups["Smoke"], 1, -1 do      
            reset(TablesOfPiecesGroups["Smoke"][i], 100)        
        end
        for i =  #TablesOfPiecesGroups["Smoke"], 1, -1 do      
            WaitForMoves(TablesOfPiecesGroups["Smoke"][i])
            Hide( TablesOfPiecesGroups["Smoke"][i])       
        end
        
        Signal(SIG_WIND)
        hideT(explosionTable)
        Hide(explosionStem)
        resetT(explosionTable, 0)   
        reset(explosionStem, 0)
        StartThread(flameSpin)
        while maRa() do
            Sleep(500)            
            WMove(explosionStem, 2, -200, 400)
            Show(SmokeStem)

            WMove(explosionStem, 2, 0, 40)
        end    

        local dirX, _, dirZ = Spring.GetWind()
        showExplosions()
        Show(explosionStem)

        -- vertical ignition plume

        Move(explosionStem, 2, 2000, 750)
        spinRand(explosionStem, -3, 3, randf(8, 16))
        -- gas cloud bloom
        StartThread(animateGasCloud, explosionTable)
        StartThread(    animateGasCloud, TablesOfPiecesGroups["Smoke"])  
        WMove(explosionStem, 2, 2000, 450)
        StartThread(driftCloud, explosionStem, dirX, dirZ, driftTimeInMs)   


        -- drift phase
        stopSpins(explosionStem,  0.1)
        tP(explosionStem, 0, 0, 0, 0.3) 
  
        Sleep(3000)
        Signal(SIG_FLAME)
        resetHide(TablesOfPiecesGroups["FlameA"])
        resetHide(TablesOfPiecesGroups["FlameB"])
        resetHide(TablesOfPiecesGroups["FlameC"])
        resetHide(TablesOfPiecesGroups["Flame"])
        resetHide(TablesOfPiecesGroups["Flames"])
        -- collapse + fade
        collapseAndFade(explosionTable)
        hideT(TablesOfPiecesGroups["FireRotor"])
        Hide(explosionStem)
        Sleep(15000)

    end
end

function resetHide(T)
    hideT(T)
    resetT(T)
end

function nightLight()
    nightlight = piece("nightlight")
    Hide(nightLight)
    
    while true do
        waitTillNight()
        Show(nightLight)
        waitTillDay()
        Hide(nightLight)
        Sleep(100)
    end
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    FlameT = TablesOfPiecesGroups["Flame"]
    FlameTips = TablesOfPiecesGroups["Flames"]
    hideT(TablesOfPiecesGroups["FireRotor"])
    Hide(explosionStem)
    Hide(LightOn)
    StartThread(nightLightsLoop,LightOn, LightOff, restTime)
    StartThread(explosionLoop)
    StartThread(nightLight)
    Spring.SetUnitBlocking(unitID, false)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
