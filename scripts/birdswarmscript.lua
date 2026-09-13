include "lib_UnitScript.lua"
include "lib_OS.lua"

local center = piece "center"
local angle = math.random() * 2 * math.pi
local fleeX, fleeZ = math.cos(angle), math.sin(angle)
local launchHeight

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
    local floor = launchHeight or y
    for step=1,900 do
        x,z = x+fleeX*2,z+fleeZ*2
        y = math.max(floor + math.min(180,step*0.8), Spring.GetGroundHeight(x,z)+40)
        Spring.MoveCtrl.SetPosition(unitID,x,y,z)
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
    StartThread(flight)
end
function script.Killed() end
