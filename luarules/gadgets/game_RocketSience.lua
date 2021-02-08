function gadget:GetInfo()
    return {
        name = "RocketSience with projectiles",
        desc = "SetProjectileTarget etc",
        author = "the one, the only, the awesomek norke",
        date = "Mar 2014",
        license = "later horses dont be mean.",
        layer = 0,
        enabled = false, --      loaded by default?
    }
end

if (not gadgetHandler:IsSyncedCode()) then return end

local redirectProjectiles = {} -- [frame][projectileID] = table with .targetType .targetX .targetY .targetZ .targetID
local spGetProjectileType = Spring.GetProjectileType
function gadget:GameFrame(frame)
  
    if redirectProjectiles[frame] then
        for projectileID, _ in pairs(redirectProjectiles[frame]) do
            if (spGetProjectileType(projectileID)) then
                setTargetTable(projectileID, redirectProjectiles[frame][projectileID])
            end
        end
        redirectProjectiles[frame] = nil
    end
end

--makes the projectile go ninja style - jumping from place to place 

function getProjectileTargetXYZ(proID)
    local targetTypeInt, target = Spring.GetProjectileTarget(proID)
    if targetTypeInt == GROUND then
        return target[1], target[2], target[3]
    end
    if targetTypeInt == string.byte('u') then
        return Spring.GetUnitPosition(target)
    end
    if targetTypeInt == string.byte('f') then
        return Spring.GetFeaturePosition(target)
    end
    if targetTypeInt == string.byte('p') then
        return Spring.GetProjectilePosition(target)
    end
end

local spGetGameFrame = Spring.GetGameFrame
function addProjectileRedirect(proID, targetTable, delay)
    local f = spGetGameFrame() + delay
    if type(targetTable) == 'function' then
        redirectProjectiles[f][proID] = targetTable
    else
        if not redirectProjectiles[f] then redirectProjectiles[f] = {} end
        redirectProjectiles[f][proID] = targetTable
    end
end

function makeTargetTable(x, y, z)
    return { targetType = GROUND, targetX = x, targetY = y, targetZ = z }
end

local GROUND = string.byte('g')
local spGetProjectileTarget = Spring.GetProjectileTarget
function getTargetTable(proID)
    local targetTable = {}
    local targetTypeInt, target = spGetProjectileTarget(proID)
    if targetTypeInt == GROUND then --target is position on ground
        targetTable = { targetType = targetTypeInt, targetX = target[1], targetY = target[2], targetZ = target[3], }
    else --target is unit,feature or projectile
        targetTable = { targetType = targetTypeInt, targetID = target, }
    end
    return targetTable
end

local spSetProjectileTarget = Spring.SetProjectileTarget
function setTargetTable(proID, targetTable)
    if targetTable.bar and targetTable.bar == true then
        targetTable.foo(proID)
    elseif targetTable.targetType == GROUND then
       spSetProjectileTarget(proID, targetTable.targetX, targetTable.targetY, targetTable.targetZ)
    else
        spSetProjectileTarget(proID, targetTable.targetID, targetTable.targetType)
    end
end
