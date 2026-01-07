include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

TablesOfPiecesGroups = {}
function script.HitByWeapon(x, z, weaponDefID, damage) end

restTime = (60*1000)/20
LightOn = piece("LightOn")
LightOff = piece("LightOff")

y_axis = 2
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
local function animateGasCloud(pieces, radius)
 
    for i = 1, #pieces do
        local p = pieces[i]

        local angle = randf(0, 2*math.pi)
        local dist  = randf(radius * 0.2, radius)

        local x = math.cos(angle) * dist
        local z = math.sin(angle) * dist
        local y = randf(150, radius)
        piecePos[i] = {x, y, z}
        Show(p)

        -- fast outward bloom
        Move(p, 1, x, randf(120, 260))
        Move(p, 3, z, randf(120, 260))
        Move(p, 2, y, randf(160, 320))


        -- turbulent rotation
        spinRand(p, -60, 60, randf(18, 32))
    end
    Sleep(5000)
end

local function driftCloud(stem, dirX, dirZ, timeMs)
    local steps = math.floor(timeMs / 250)
    local speed = 18

    for i = 1, steps do

        Move(SmokeStem, 1, dirX * speed, 80)
        Move(SmokeStem, 3, dirZ * speed, 80)
        Move(stem, 1, dirX * speed, 80)
        Move(stem, 3, dirZ * speed, 80)
    end

end

local function collapseAndFade(pieces)
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
Flame = piece("Flame1")
function flameSpin()
    Signal(SIG_FLAME)
    SetSignalMask(SIG_FLAME)
    Flames = {unpack(TablesOfPiecesGroups["Flame"], 2, #TablesOfPiecesGroups["Flame"])}

    while true do
        Show(Flame)
        spinRand(Flame, -60, 60, randf(18, 32))
        for k,fire in pairs(TablesOfPiecesGroups["Flame"]) do
            if maRa() then
                spinRand(fire, -60, 60, randf(18, 32))
            end
            Spin(fire, 2, math.rad(42) * randSign(), math.pi)
        end
        rVal = math.random(150,500)
        Sleep(rVal)
        hideT(Flames)
        resetT(Flames)  
        Hide(Flame)
        reset(Flame)

    end
end

piecePos = {}
local function stationaryCloud(smoke)
 
    for i = 1, #smoke do
        local p = smoke[i]
        local pos = piecePos[i]
        if p and pos  and pos[1] then
         -- fast outward bloom
            Move(p, 1, pos[1], 0)
            Move(p, 3, pos[3], 0)
            Move(p, 2, pos[2], 0)
            Show(p)
    
            -- turbulent rotation
            spinRand(p, -60, 60, randf(18, 32))
        end
    end
    Sleep(5000)
end

function explosionLoop()
    Sleep(100)
    explosionTable = {unpack(TablesOfPiecesGroups["Explosion"], 2, #TablesOfPiecesGroups["Explosion"])} 
    explosionStem  = TablesOfPiecesGroups["Explosion"][1]
    cloudRadius = 750
    driftTimeInMs = 3000
    hideT(TablesOfPiecesGroups["Flame"])
    Hide(SmokeStem)
    while true do 
        hideT(explosionTable)
        Hide(explosionStem)
        StartThread(flameSpin)
    

        resetT(explosionTable, 0)
   
        reset(explosionStem, 0)

        local dirX, _, dirZ = Spring.GetWind()

        Show(explosionStem)

        -- vertical ignition plume
        Move(explosionStem, 2, 1250, 250)
        Move(SmokeStem, 2, 1250, 250)

        -- gas cloud bloom
        animateGasCloud(explosionTable, cloudRadius)


        -- drift phase
        for i = 1, #TablesOfPiecesGroups["Smoke"] do        
            Hide( TablesOfPiecesGroups["Smoke"][i])
            reset(TablesOfPiecesGroups["Smoke"][i])
            Sleep(50)
        end
      
        driftCloud(explosionStem, dirX, dirZ, driftTimeInMs)
    
        StartThread(stationaryCloud, TablesOfPiecesGroups["Smoke"])
        Signal(SIG_FLAME)
        hideT(TablesOfPiecesGroups["Flame"])
        -- collapse + fade
        collapseAndFade(explosionTable)

        Hide(explosionStem)
        Sleep(2000)
    end
end


function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(blinkLoop,LigthOn, LightOff, restTime)
    StartThread(explosionLoop)
    Spring.SetUnitBlocking(unitID, false)
end

function script.Killed(recentDamage, _)
    return 1
end

function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
