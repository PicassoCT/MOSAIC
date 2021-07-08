local ProtagonSafeHouse =    Building:New{
  corpse =       "",
  maxDamage =              1000,
  mass =                   500,

  buildTime =    15,
  explodeAs =      "none",
  name =    "Safehouse",
  description =   " base of operation <recruits Agents/ builds upgrades>",
	buildPic = "protagonsafehouse.png",
	iconType = "protagonsafehouse",
  Builder =    true,
  nanocolor =  [[0 0 0]], --
  CanReclaim =  false,
  workerTime =    1,
  buildDistance =    1,
  terraformSpeed =    1,
  YardMap =[[ oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo]],
  MaxSlope =         100,
  buildingMask =    8,
  footprintX =    8,
  footprintZ =    8,

  buildCostEnergy =        2000,
  buildCostMetal =         2000,

  EnergyStorage = 1000,
  EnergyUse =    0,
  MetalStorage =    1000,

  MetalUse =    0,
  EnergyMake =    1.00,
  MakesMetal =    1.0,
  MetalMake =    0,

  canCloak =   true,
  cloakCost =  0.0001,
  ActivateWhenBuilt =  1,
  cloakCostMoving =   0.0001,
  minCloakDistance =    0,
  onoffable =  true,
  initCloaked =    true,
  decloakOnFire =    true,
  cloakTimeout =    5,
  showNanoFrame= true,
  script =       "safehousescript.lua",
  objectName =            "safehouse.dae",
  fireState=1,
  selfDestructCountdown = 3*60,

  customparams =    {
  		normaltex = "unittextures/safehouse_normal.dds",
    helptext =     "Civilian Building",
    baseclass =     "Building", -- TODO: hacks
  },

  buildoptions =  {
    "operativeasset",
    "operativeinvestigator",
    "civilianagent",

    "nimrod",
    "propagandaserver",
	 "aicore",
    "assembly",
	 "blacksite"
  },

  category =  [[GROUND BUILDING RAIDABLE]],
}


return lowerkeys({
  ["protagonsafehouse"] =    ProtagonSafeHouse:New()
})