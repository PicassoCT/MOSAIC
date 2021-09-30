
decalIndex= 1
SmallDecals = {}
for i=1, 10 do
local Copy = Building:New{
    name = "house_western_decal",
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
    buildinggrounddecalsizex = 20,
    buildinggrounddecalsizey = 20,
    buildinggrounddecaltype = "decal_arab/HouseDecal6_west_city.png",
    Category = [[LAND]],
    customParams = {},
    sfxtypes = {
        explosiongenerators = {}
    }
}
    SmallDecals[i] = Copy
    SmallDecals[i].name = SmallDecals[i].name..decalIndex
    decalIndex= decalIndex +1
end

SmallDecals[1].buildinggrounddecaltype ="decal_arab/HouseDecal6_arab_city.png"
SmallDecals[2].buildinggrounddecaltype ="decal_arab/HouseDecal19_arab_city.png"
SmallDecals[3].buildinggrounddecaltype ="decal_arab/HouseDecal1_arab_city.png"
SmallDecals[4].buildinggrounddecaltype ="decal_arab/HouseDecal3_arab_city.png"

SmallDecals[5].buildinggrounddecaltype ="decal_western/HouseDecal1_west_city.png"
SmallDecals[6].buildinggrounddecaltype ="decal_western/HouseDecal2_west_city.png"
SmallDecals[7].buildinggrounddecaltype ="decal_western/HouseDecal3_west_city.png"
SmallDecals[8].buildinggrounddecaltype ="decal_western/HouseDecal6_west_city.png"
SmallDecals[9].buildinggrounddecaltype ="decal_western/HouseDecal10_west_rural.png"
SmallDecals[10].buildinggrounddecaltype ="decal_western/HouseDecal7_west_rural.png"
SmallDecals[11] = SmallDecals[10]
SmallDecals[11].buildinggrounddecaltype ="decal_western/HouseDecal11_west_city.dds"
SmallDecals[11].name = "house_western_decal15"


BigDecals = {}
for i=1, 5 do
    local Copy = Building:New{
    name = "house_western_decal",
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
    buildinggrounddecaltype = "decal_arab/HouseDecal5_west_city.png",
    Category = [[LAND]],
    customParams = {},
    sfxtypes = {
        explosiongenerators = {}
    }
}
    BigDecals[i] = Copy
    BigDecals[i].name = BigDecals[i].name..decalIndex
    decalIndex= decalIndex +1
end

BigDecals[1].buildinggrounddecaltype ="decal_arab/HouseDecal16_arab_city.png"
BigDecals[2].buildinggrounddecaltype ="decal_arab/HouseDecal5_arab_city.png"
BigDecals[3].buildinggrounddecaltype ="decal_western/HouseDecal5_west_city.png"
BigDecals[4].buildinggrounddecaltype ="decal_western/HouseDecal9_west_city.png"


return lowerkeys({
    --Temp
    ["house_western_decal1"]   = SmallDecals[1],
    ["house_western_decal2"]   = SmallDecals[2],
    ["house_western_decal3"]   = SmallDecals[3],
    ["house_western_decal4"]   = SmallDecals[4],
    ["house_western_decal5"]   = SmallDecals[5],
    ["house_western_decal6"]   = SmallDecals[6],
    ["house_western_decal7"]   = SmallDecals[7],
    ["house_western_decal8"]   = SmallDecals[8],
    ["house_western_decal9"]   = SmallDecals[9],
    ["house_western_decal10"]  = SmallDecals[10],

    ["house_western_decal11"]  = BigDecals[2],
    ["house_western_decal12"]  = BigDecals[3],
    ["house_western_decal13"]  = BigDecals[4], 
    ["house_western_decal14"]  = BigDecals[1],

    ["house_western_decal15"]  = SmallDecals[11],
})




