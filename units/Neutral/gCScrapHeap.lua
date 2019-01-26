local unitName = "gCScrapHeap"

local unitDef = {
name = "gCScrapHeap",
Description = "Where towers in ruins lie",
objectName = "gCScrapHeap.s3o",
script = "gCScrapHeap.lua",
buildPic = "placeholder.png",
--cost
buildCostMetal = 200,
buildCostEnergy = 50,
buildTime =1,
--Health
maxDamage = 6666,
idleAutoHeal = 0,
--Movement

FootprintX = 5,
FootprintZ = 5,

--MaxVelocity = 0.5,
MaxWaterDepth =400,
--MovementClass = "Default2x2",--


sightDistance = 50,

reclaimable=true,
Builder = true,
CanAttack = false,
CanGuard = false,
CanMove = false,
CanPatrol = false,
CanStop = false,



-- Building	
	





    
   

Category = [[NOTARGET]],

EnergyStorage = 0,
	EnergyUse = 75,
	MetalStorage = 0,
	EnergyMake = 0, 
	MakesMetal = 16, 
	MetalMake = 0,	
  acceleration           = 0,
  

   -- bmcode                 = [[0]],
	
	--


  --extractsMetal          = 0.005,
  --floater                = false,



  levelGround            = false,
  mass                   = 9900,
  



  


 -- TEDClass               = [[METAL]],
  
   customParams = {},
 sfxtypes = {
				explosiongenerators = {
				   "custom:factory_explosion",
	   		       "custom:flames",
				   "custom:glowsmoke",
				   "custom:blackerthensmoke",
				   "custom:LightUponSmoke",
				  
				   --
				    --Bulletof The Cannon
				},

},


}
return lowerkeys({ [unitName] = unitDef })