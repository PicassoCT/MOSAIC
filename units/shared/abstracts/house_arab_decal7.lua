local unitName = "house_arab_decal7"

local unitDef = {
    name = "house_arab_decal",
    Description = "ThereForTheDecal",
    objectName = "emptyObjectIsEmpty.s3o",
    script = "decalScript.lua",
    buildPic = "placeholder.png",
    --cost
    buildCostMetal = 0,
    buildCostEnergy = 0,
    buildTime = 1,
    --Health
    maxDamage = 1200,
    idleAutoHeal = 0,
    --Movement

    FootprintX = 1,
    FootprintZ = 1,
    MaxSlope = 5,
    --MaxVelocity = 0.5,
    MaxWaterDepth = 0,
    --MovementClass = "Default2x2",--

    sightDistance = 300,
    reclaimable = true,
    Builder = true,
    CanAttack = false,
    CanGuard = false,
    CanMove = false,
    CanPatrol = false,
    CanStop = false,
    LeaveTracks = false,
    YardMap = "y",
    -- Building
    levelGround = false,
    workerTime = 1,
    usebuildinggrounddecal = true,
    buildinggrounddecaldecayspeed = 0.00000002,
    buildinggrounddecalsizex = 40,
    buildinggrounddecalsizey = 40,
    buildinggrounddecaltype = "decal_arab/HouseDecal7_arab_rural.png",
    Category = [[LAND]],
    customParams = {},
    sfxtypes = {
        explosiongenerators = {}
    }
}

return lowerkeys({[unitName] = unitDef})
