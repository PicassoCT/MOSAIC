function gadget:GetInfo()
    return {
        name = "RocketSience with projectiles",
        desc = "SetProjectileTarget etc",
        author = "knorke",
        date = "Mar 2014",
        license = "later horses dont be mean.",
        layer = 0,
        enabled = true, --      loaded by default?
    }
end

if (not gadgetHandler:IsSyncedCode()) then return end

local redirectProjectiles = {} -- [frame][projectileID] = table with .targetType .targetX .targetY .targetZ .targetID

function gadget:GameFrame(frame)
  
    if redirectProjectiles[frame] then
        for projectileID, _ in pairs(redirectProjectiles[frame]) do
            if (Spring.GetProjectileType(projectileID)) then
                setTargetTable(projectileID, redirectProjectiles[frame][projectileID])
            end
        end
        redirectProjectiles[frame] = nil
    end
end

GG.AddCodeByType = {}

function AddExampleRocketCode(proID, proOwnerID)
    -- local originalTarget = getTargetTable(proID)
    -- local tx, ty, tz = getProjectileTargetXYZ(proID)
    -- local x, y, z = Spring.GetUnitPosition(proOwnerID)

    -- ex, ey, ez = 0, 0, 0
    -- if originalTarget.targetX then
        -- ex, ey, ez = originalTarget.targetX, originalTarget.targetY, originalTarget.targetZ

    -- else
        -- ex, ey, ez = Spring.GetUnitPosition(originalTarget.targetID)
    -- end

    -- dx, dy, dz = tx - ex, ty - ey, tz - ez


    -- percenTage = 0.25
    -- addProjectileRedirect(proID, {
        -- bar = true,
        -- foo = function(proID)
            -- Spring.SetProjectilePosition(proID,
                -- tx + percenTage * dx + math.random(-25, 25),
                -- ty + math.random(5, 10),
                -- tz + percenTage * dz + math.random(-25, 25))
        -- end
    -- }, 100)
    -- addProjectileRedirect(proID, originalTarget, 101)


    -- percenTage = 0.5
    -- addProjectileRedirect(proID, {
        -- bar = true,
        -- foo = function(proID)
            -- Spring.SetProjectilePosition(proID,
                -- tx + percenTage * dx + math.random(-25, 25),
                -- ty + math.random(10, 35),
                -- tz + percenTage * dz + math.random(-25, 25))
        -- end
    -- }, 200)
    -- addProjectileRedirect(proID, originalTarget, 201)


    -- percenTage = 0.75
    -- addProjectileRedirect(proID, {
        -- bar = true,
        -- foo = function(proID)
            -- Spring.SetProjectilePosition(proID,
                -- tx + percenTage * dx + math.random(-25, 25),
                -- ty + math.random(10, 35),
                -- tz + percenTage * dz + math.random(-25, 25))
        -- end
    -- }, 300)
    -- addProjectileRedirect(proID, originalTarget, 301)


    return true
end

--makes the projectile go ninja style - jumping from place to place 
-- GG.AddCodeByType[WeaponDefNames["jvaryjump"].id] = AddExampleRocketCode

function getProjectileTargetXYZ(proID)
    local targetTypeInt, target = Spring.GetProjectileTarget(proID)
    if targetTypeInt == string.byte('g') then
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

function addProjectileRedirect(proID, targetTable, delay)
    local f = Spring.GetGameFrame() + delay
    if type(targetTable) == 'function' then
        redirectProjectiles[f][proID] = targetTable
    else
        if not redirectProjectiles[f] then redirectProjectiles[f] = {} end
        redirectProjectiles[f][proID] = targetTable
    end
end

function makeTargetTable(x, y, z)
    return { targetType = string.byte('g'), targetX = x, targetY = y, targetZ = z }
end

function getTargetTable(proID)
    local targetTable = {}
    local targetTypeInt, target = Spring.GetProjectileTarget(proID)
    if targetTypeInt == string.byte('g') then --target is position on ground
        targetTable = { targetType = targetTypeInt, targetX = target[1], targetY = target[2], targetZ = target[3], }
    else --target is unit,feature or projectile
        targetTable = { targetType = targetTypeInt, targetID = target, }
    end
    return targetTable
end

function setTargetTable(proID, targetTable)
    if targetTable.bar and targetTable.bar == true then
        targetTable.foo(proID)
    elseif targetTable.targetType == string.byte('g') then
        Spring.SetProjectileTarget(proID, targetTable.targetX, targetTable.targetY, targetTable.targetZ)
    else
        Spring.SetProjectileTarget(proID, targetTable.targetID, targetTable.targetType)
    end
end
