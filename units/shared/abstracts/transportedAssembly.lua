local unitName = "transportedassembly"
local doctrine = VFS.Include("luarules/configs/mobile_assembly_doctrine.lua")
local buildOptions = {}
for _, group in ipairs({"common", "protagon", "antagon"}) do
    for _, name in ipairs(doctrine[group]) do
        buildOptions[#buildOptions + 1] = name
    end
end
local unitDef = {
    name = "Mobile Assembly",
    Description = "Mobile production follows the owning faction; aircraft campaigns require an army base",
    objectName = "mobile_assembly.dae",

    script = "transportedassemblyscript.lua",
    buildPic = "truck_assembly.png",
    iconType = "truck_assembly",
    --cost
    buildCostMetal = 2500,
    buildCostEnergy = 1250,
    buildTime = 60,
    CanReclaim = false,
    buildDistance = 200,
    onoffable = true,
    acitvateonstart = false,
    --Health
    maxDamage = 2500,
    idleAutoHeal = 3,
    --Movement
    MovementClass = "VEHICLE",
    FootprintX = 1,
    FootprintZ = 1,
    MaxSlope = 5,
    --MaxVelocity = 0.5,
    MaxWaterDepth = 0,
    TurnRate = 200,
    isMetalExtractor = false,
    sightDistance = 300,
    reclaimable = false,
    Builder = true,
    CanAttack = true,
    CanGuard = true,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    LeaveTracks = false,
    YardMap = "o",
    -- Building

    ShowNanoSpray = true,
    CanBeAssisted = true,
    workerTime = 0.54,
    buildoptions = buildOptions,
    usebuildinggrounddecal = false,
    Category = [[NOTARGET]],
    EnergyStorage = 0,
    EnergyUse = 75,
    MetalStorage = 0,
    EnergyMake = 16,
    MakesMetal = 0,
    MetalMake = 0,
    acceleration = 0,
    nanocolor = [[0.20 0.411 0.611]],
    levelGround = false,
    mass = 9990,
    maxSlope = 255,
    noAutoFire = false,
    smoothAnim = true,
    customParams = {
                normaltex = "unittextures/component_atlas_normal.dds"
                    },
    sfxtypes = {
        explosiongenerators = {}
    }
}

return lowerkeys({[unitName] = unitDef})
