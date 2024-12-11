-- Configuration for the trench coat bones

function getNeighbors(TableOfPieceGroups, pieceNr, coatstripeMaxNr)
    leftNeighbor = TableOfPieceGroups[piceNr - coatstripeMaxNr]
    rightNeighbor =  TableOfPieceGroups[piceNr + coatstripeMaxNr]
    return leftNeighbor, rightNeighbor
end

function setupCoat(parentT)
    hierarchy, root = getPieceHierarchy(unitID)
    coatMap = {}
    for parent,p in pairs(parentT) do 
        coatMap[#coatMap +1] = {bone = parent,  children = hierarchy[parent],  localPos = {x = 0, y = 0, z = 0}, velocity = {x = 0, y = 0, z = 0}}
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

-- Function to simulate coat physics
function updateCloth(character, constantForces, temporaryForces, perPieceForces )

    local globalForces = composeForces(constantForces, temporaryForces)
    --from the middle out apply towards the outside of the parent hierarchy- with one neighbor defined
    for coatStrip = 1, #coatMap do
        local coatStripe = coatMap[i]
    for i=1, #coatStripe.children do
        local bone = coatStripe.children[i]
        local parent = (i > 1) and coatStripe.children[i-1] or coatStripe.parent
        -- Get the current world position of the bone and parent bone
        local worldPos = getBoneWorldPosition(character, bone)
        local parentWorldPos =  getBoneWorldPosition(character, coatStripe.parent) 
       

        -- Apply spring force to maintain connectivity with the parent
        if parentWorldPos then
            local toParent = {
                x = parentWorldPos.x - worldPos.x,
                y = parentWorldPos.y - worldPos.y,
                z = parentWorldPos.z - worldPos.z,
            }
            local length = math.sqrt(toParent.x^2 + toParent.y^2 + toParent.z^2)
            if length > 0 then
                local norm = {x = toParent.x / length, y = toParent.y / length, z = toParent.z / length}
                globalForce.x = globalForce.x + norm.x * (length - 1) * neighborStiffness -- Assuming 1 unit is the rest length
                globalForce.y = globalForce.y + norm.y * (length - 1) * neighborStiffness
                globalForce.z = globalForce.z + norm.z * (length - 1) * neighborStiffness
            end
        end

        -- Update velocity with damping
        bone.velocity.x = (bone.velocity.x + globalForce.x * deltaTime) * damping
        bone.velocity.y = (bone.velocity.y + globalForce.y * deltaTime) * damping
        bone.velocity.z = (bone.velocity.z + globalForce.z * deltaTime) * damping

        -- Update position
        bone.localPos.x = bone.localPos.x + bone.velocity.x * deltaTime
        bone.localPos.y = bone.localPos.y + bone.velocity.y * deltaTime
        bone.localPos.z = bone.localPos.z + bone.velocity.z * deltaTime

        -- Apply the position in local space (relative to parent bone)
        setBoneLocalPosition(character, bone.boneName, bone.localPos)
    end
end

-- Utility functions (to be implemented based on your engine)
function getBoneWorldPosition(character, boneName)
    -- Return the world position of the bone
end

function setBoneLocalPosition(character, boneName, localPos)
    -- Derive the bone position from the local Pos

     the position of the bone relative to its parent

    -- Set only bone rotation 
end
