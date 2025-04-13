local unitName = "transportedassembly"
local unitDef = {
    name = "Mobile Assembly",
    Description = "",
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
    buildoptions = {
        --air
        "air_copter_mg", "air_copter_antiarmor", "air_copter_ssied",        
        "air_plane_sniper", "air_plane_rocket","air_copter_scoutlett",
        --ground    
        "ground_turret_mg", "ground_turret_antiarmor", "ground_turret_ssied",
        "ground_walker_mg", "ground_walker_grenade", "brehmerwall",
        "ground_turret_cm_airstrike", "ground_turret_cm_transport", "ground_turret_cm_antiarmor"
    },
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
