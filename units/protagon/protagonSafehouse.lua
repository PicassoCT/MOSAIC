local ProtagonSafeHouse =    Building:New{
  corpse =       "",
  maxDamage =              1000,
  mass =                   5000,

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
  YardMap =[[oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo
        oooooooo]],
  buildingMask =    8,
  footprintX =    8,
  footprintZ =    8,
  maxSlope = 50.0,
  levelGround = false,
  blocking =false,

  buildCostEnergy =        2000,
  buildCostMetal =         2000,

	EnergyStorage = 1000,
	EnergyUse = 0,
	MetalStorage = 1000,
	MetalUse = 0,
	EnergyMake = 2.0, 
	MakesMetal = 0, 
	MetalMake = 2.0,	

  canCloak =   true,
  cloakCost =  0.0001,
  ActivateWhenBuilt =  1,
  cloakCostMoving =   0.0001,
  minCloakDistance =    -1,
  onoffable =  true,
  initCloaked =    true,
  decloakOnFire =    false,
  cloakTimeout =    5,
  showNanoFrame= true,
  script =       "safehousescript.lua",
  objectName =            "safehouse.dae",
  fireState=1,
  selfDestructCountdown = 3*60,

  usepiececollisionvolumes = false,
  collisionVolumeType = "box",
  collisionvolumescales = "100 70 100",
  collisionVolumeOffsets  = {0.0, 30.0,  0.0},

  customparams =    {
  		normaltex = "unittextures/safehouse_normal.dds",
    helptext =     "Civilian Building",
    baseclass =     "Building", -- TODO: hacks
  },

  buildoptions =  {
    "operativeasset",
    "operativeinvestigator",
    "civilianagent",
--[[
    "nimrod",
    "propagandaserver",
	 --"aicore",
    "assembly",
	 "blacksite"--]]
  },

  category =  [[GROUND BUILDING RAIDABLE]],
}


return lowerkeys({
  ["protagonsafehouse"] =    ProtagonSafeHouse:New()
})
