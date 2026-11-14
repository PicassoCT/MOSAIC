include "lib_UnitScript.lua"
include "lib_OS.lua"

local center = piece "center"
local angle = math.random() * 2 * math.pi
local fleeX, fleeZ = math.cos(angle), math.sin(angle)
local launchHeight
local MAX_LIFETIME_MS = 60000

local function expire()
    -- Bound the descent too, even when launched from a very tall building.
    Sleep(MAX_LIFETIME_MS)
    Spring.DestroyUnit(unitID,false,true)
end

function setShotNearby(args)
    local x,y,z = Spring.GetUnitPosition(unitID)
    local dx,dz = x-(args.x or x), z-(args.z or z)
    local length = math.sqrt(dx*dx+dz*dz)
    if length > 0.001 then fleeX,fleeZ = dx/length,dz/length end
    launchHeight = args.height or y
end

local function flight()
    -- Allow the spawning gadget to provide the roof height and shot direction.
    Sleep(33)
    Spring.MoveCtrl.Enable(unitID)
    local x,y,z = Spring.GetUnitPosition(unitID)
    local sx,sz = x,z
    local floor = launchHeight or y
    local milliSeconds = 0
    local wandering, nextWander = false, 10000
    for step=1,900 do
        if milliSeconds < 10000 then
            x,z = x+fleeX*2,z+fleeZ*2
            y = math.max(floor + math.min(180,step*0.8), Spring.GetGroundHeight(x,z)+40)
            Spring.MoveCtrl.SetPosition(unitID,x,y,z)
        else
            if not wandering then
                Spring.MoveCtrl.Disable(unitID)
                wandering = true
            end
            if milliSeconds >= nextWander then
                Spring.SetUnitMoveGoal(unitID, sx+math.random(-250,250), y, sz+math.random(-250,250))
                nextWander = nextWander + 5000
            end
        end        
        milliSeconds = milliSeconds + 33
        Sleep(33)
    end
    Spring.MoveCtrl.Enable(unitID)
    x,y,z = Spring.GetUnitPosition(unitID)
    local gh = Spring.GetGroundHeight(x,z) + (12 * 3) --buildingheight
    for h = y, gh , -1 do
        Spring.MoveCtrl.SetPosition(unitID,x, h,z)
        Sleep(33)
    end
    
    Spring.DestroyUnit(unitID,false,true)
end

function script.Create()
    local groups = getPieceTableByNameGroups(false,true)
    for _,name in ipairs({"Gull","Raven"}) do
        for _,p in pairs(groups[name] or {}) do Hide(p) end
    end
    Hide(center)
    local name = UnitDefs[unitDefID].name == "gullswarm" and "Gull" or "Raven"
    local first = true
    for k,p in ipairs(groups[name] or {}) do
        Spin(p,y_axis,math.rad(22)*(-1)^k)
        if first or math.random(0,1)==1 then Show(p); first=false end
    end
    Spring.SetUnitAlwaysVisible(unitID,true)
    Spring.SetUnitNoSelect(unitID,true)
    Spring.SetUnitBlocking(unitID,false)
    local x,y,z = Spring.GetUnitPosition(unitID)
    Spring.PlaySoundFile("sounds/animals/birdsFleeing.ogg",1,x,y,z)
    StartThread(expire)
    StartThread(flight)
end
function script.Killed() end
