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
    local nextWander = 10000
    local goalX, goalZ = x, z
    local vx, vz = fleeX*2, fleeZ*2
    local cruiseHeight = math.max(floor+180,y)
    for step=1,900 do
        if milliSeconds < 10000 then
            x,z = x+fleeX*2,z+fleeZ*2
            y = math.max(floor + math.min(180,step*0.8), Spring.GetGroundHeight(x,z)+40)
            Spring.MoveCtrl.SetPosition(unitID,x,y,z)
        else
            -- These visual swarms have ground-unit movement definitions. Giving
            -- control back to the engine here snaps their altitude to terrain.
            -- Keep the same wandering destinations/cadence, steering in flight.
            if milliSeconds >= nextWander then
                goalX,goalZ = sx+math.random(-250,250),sz+math.random(-250,250)
                nextWander = nextWander + 5000
            end
            local dx,dz = goalX-x,goalZ-z
            local distance = math.sqrt(dx*dx+dz*dz)
            local speed = math.min(2,distance/30) * math.min(1,(900-step)*33/2000)
            local desiredX,desiredZ = 0,0
            if distance > 0.001 then desiredX,desiredZ = dx/distance*speed,dz/distance*speed end
            vx,vz = vx+(desiredX-vx)*0.08,vz+(desiredZ-vz)*0.08
            x,z = x+vx,z+vz
            local altitude = math.max(cruiseHeight,Spring.GetGroundHeight(x,z)+40)
            y = y+(altitude-y)*0.05
            Spring.MoveCtrl.SetPosition(unitID,x,y,z)
        end        
        milliSeconds = milliSeconds + 33
        Sleep(33)
    end
    local gh = Spring.GetGroundHeight(x,z) + (12 * 3) --buildingheight
    -- Ease into and out of descent, keeping the original perch clearance and
    -- a maximum descent rate of about 30 units/second. The independent expiry
    -- thread still bounds exceptionally tall rooftop launches to 60 seconds.
    local steps = math.max(45,math.ceil(math.abs(y-gh)*1.5/0.99))
    for step=1,steps do
        local t = step/steps
        local eased = t*t*(3-2*t)
        Spring.MoveCtrl.SetPosition(unitID,x,y+(gh-y)*eased,z)
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
