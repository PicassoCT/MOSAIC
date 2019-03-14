unitDef = {
  unitname            = [[origod]],
  name                = [[origod]],
  description         = [[origod]],
  script         		= [[origodscript.lua]],
  acceleration        = 0.36,
  brakeRate           = 0.205,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken.png]],
  buildTime           = 25,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[SWIM]],

  customParams        = {
  },
  objectName          = [[OriGod.dae]],
  explodeAs           = [[NOWEAPON]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[chicken]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 270,
  maxSlope            = 36,
  maxVelocity         = 2.9,
  minCloakDistance    = 75,
  
  movementClass       = [[BHOVER3]],
  noAutoFire          = false,

  power               = 100,

  sfxtypes            = {

    explosiongenerators = {  }, 
	},
  sightDistance       = 256,
  sonarDistance       = 200,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 18,
  turnRate            = 806,
  upright             = false,
  waterline           = 16,
  workerTime          = 0,

 
  }



return lowerkeys({ origod = unitDef })
