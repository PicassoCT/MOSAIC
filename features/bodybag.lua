
local bodyBagDefs = 
   {
["bodybag"] =	{
	name = "bodybag",
	description =" the body of a person",
	blocking = false,
	flammable = true,
	upright = false,
	category = [[GROUND]],
	energy = 50,
	damage = 500,
	metal = 0,
	object = "bodybag.dae",
	

     reclaimTime = 1500,
     mass        = 20,
     drawType    = 0,

     collisionVolumeTest = 0,
     collisionvolumescales ="5 3 2",
     collisionvolumetype = "Box",
        customParams = {
            nohealthbars = true,
        },
     }
}




return lowerkeys( bodyBagDefs )

