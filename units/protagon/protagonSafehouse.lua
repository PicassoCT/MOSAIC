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
  workerTime =    0.4,
  buildDistance =    1,
  terraformSpeed =    1,
  YardMap =   "oooo oooo oooo oooo ",
  MaxSlope =         50,
  buildingMask =    8,
  footprintX =    4,
  footprintZ =    4,

  buildCostEnergy =        2000,
  buildCostMetal =         2000,

  EnergyStorage =    0,
  EnergyUse =    0,
  MetalStorage =    2500,

  MetalUse =    1,
  EnergyMake =    0,
  MakesMetal =    0,
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