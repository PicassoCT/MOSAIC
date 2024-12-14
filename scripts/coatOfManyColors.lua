-- Configuration for the trench coat bones

function getNeighbors(TableOfPieceGroups, pieceNr, coatstripeMaxNr)
    leftNeighbor = TableOfPieceGroups[piceNr - coatstripeMaxNr]
    rightNeighbor =  TableOfPieceGroups[piceNr + coatstripeMaxNr]
    return leftNeighbor, rightNeighbor
end

local posVelocDict  = {}
function setupCoat(parentT)
    hierarchy, root = getPieceHierarchy(unitID)

    coatMap = {}
    for num,parent in pairs(parentT) do 
        coatMap[#coatMap +1] = {parent = parent, children = hierarchy[parent], }
        for i=1, #hierarchy[parent] do
            child = hierarchy[parent][i]
            posVelocDict[child] = { localPos = {x = 0, y = 0, z = 0}, velocity = {x = 0, y = 0, z = 0}}
    end

    
    return coatBoneParents
end

function composeForces(constantForces, temporaryForces)
    local globalForce = {x = 0, y= 0, z= 0 }
        -- Apply gravity and wind
        for i=1, #constantForces do   
            globalForce.x = globalForce.x + constantForces[i].x,
            globalForce.y = globalForce.y + constantForces[i].y,
            globalForce.z = globalForce.z + constantForces[i].z,
        end

        for i=1, #temporaryForces do   
            globalForce.x = globalForce.x + temporaryForces[i].x,
            globalForce.y = globalForce.y + temporaryForces[i].y,
            globalForce.z = globalForce.z + temporaryForces[i].z,
        end
    return globalForce
end
-- Physics parameters
local damping = 0.9
local stiffness = 5.0
local neighborStiffness = 2.0
local deltaTime = 1 / 60 -- Assume 60 FPS

-- External forces (e.g., wind)
local temporaryForces = {{x = 0.5, y = 0, z = 0}} --wind
local constantForces = {{x = 0, y = -9.81, z = 0}} --gravity


function addNeighborAsForce(globalForce, worldPos, neighbor )
      if not neighbor then return globalForce end
      
      local neighborWorldPos =  getBoneWorldPosition(unitID, neighbor) 

        if neighborWorldPos then
            local toNeighbor = {
                x = neighborWorldPos.x - worldPos.x,
                y = neighborWorldPos.y - worldPos.y,
                z = neighborWorldPos.z - worldPos.z,
            }
            local length = math.sqrt(neighborWorldPos.x^2 + neighborWorldPos.y^2 + neighborWorldPos.z^2)
            if length > 0 then
                local norm = {x = toNeighbor.x / length, y = toNeighbor.y / length, z = toNeighbor.z / length}
                globalForce.x = globalForce.x + norm.x * (length - 1) * neighborStiffness -- Assuming 1 unit is the rest length
                globalForce.y = globalForce.y + norm.y * (length - 1) * neighborStiffness
                globalForce.z = globalForce.z + norm.z * (length - 1) * neighborStiffness
            end
        end

return globalForce
end

-- Function to simulate coat physics
function updateCloth(unitID, constantForces, temporaryForces, perPieceForces)

    local globalForces = composeForces(constantForces, temporaryForces)
    --from the middle out apply towards the outside of the parent hierarchy- with one neighbor defined
    for coatStrip = 1, #coatMap do
        local coatStripe = coatMap[i]
    for i=1, #coatStripe.children do
        local bone = coatStripe.children[i]
        local parent = (i > 1) and coatStripe.children[i-1] or coatStripe.parent
        -- Get the current world position of the bone and parent bone
        local worldPos = getBoneWorldPosition(unitID, bone)
 
        local posVelocity= posVelocDict[bone]

        globalForce = addNeighborAsForce(globalForce, worldPos, coatStripe.parent)
        leftNeighbor, rightNeighbor = getNeighbors(TableOfPieceGroups, pieceNr, coatstripeMaxNr)
        globalForce = addNeighborAsForce(globalForce, worldPos,leftNeighbor)
        globalForce = addNeighborAsForce(globalForce, worldPos,rightNeighbor)
       

        -- Apply spring force to maintain connectivity with the parent
        
        velocity = {}
        localPos = {}

        -- Update velocity with damping
        posVelocity.velocity.x = (posVelocity.velocity.x + globalForce.x * deltaTime) * damping
        posVelocity.velocity.y = (posVelocity.velocity.y + globalForce.y * deltaTime) * damping
        posVelocity.velocity.z = (posVelocity.velocity.z + globalForce.z * deltaTime) * damping

        -- Update position
        posVelocity.localPos.x = posVelocity.localPos.x + posVelocity.velocity.x * deltaTime
        posVelocity.localPos.y = posVelocity.localPos.y + posVelocity.velocity.y * deltaTime
        posVelocity.localPos.z = posVelocity.localPos.z + posVelocity.velocity.z * deltaTime
        
        posVelocDict[bone] = posVelocity
        -- Apply the position in local space (relative to parent bone)
        setBoneLocalPosition(unitID, bone, posVelocity)
    end
end

function maxValue(a, b)
    return math.max(math.abs(a),math.abs(b))
end

-- Utility functions (to be implemented based on your engine)
function getBoneWorldPosition(unitID, bone)
    x,y,z, dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, boneName)
    -- Return the world position of the bone
    return x,y,z
end

function setBoneLocalPosition(unitID, length, bone, parent, targetPos, velocity)
    px, py, pz = Spring.GetUnitPiecePosDir(unitId, parent)
    cx, cy, cz = Spring.GetUnitPiecePosDir(unitId, bone)

    -- Derive the bone position from the local Pos
    tx,ty,tz = cx - px, cy- py, cz - targetPos.z
    norm=maxValue(tx,maxValue(ty,tz))
    tx,ty,tz = tx /norm, ty /norm, tz /norm
    -- the position of the bone relative to its parent
    Turn(parent,x_axis,tx, velocity.x )
    Turn(parent,y_axis,ty, velocity.y )
    Turn(parent,z_axis,tz, velocity.z )
end
