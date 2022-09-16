local antagonDefs = {
   	antagonsafehouse = {
		{
			into = 'propagandaserver',
			metal = 1000,
			energy = 1000,
			time = 30,
			name = 'Propagandaserver',
			text = 'Creates currency and ressources for your side',
			facing = true,
		},	
		{
			into = 'nimrod',
			metal = 1500,
			energy = 3500,
			time = 60,
			name = 'Nimrod',
			text = 'Orbital Railgun to deploy micro-sattelites',
			facing = true,
		},		
		{
			into = 'assembly',
			metal = 2500,
			energy = 5000,
			time = 60,
			name = 'Automatic Assembly',
			text = 'Builds automated units',
			facing = true,
		},	
		{
			into = 'launcher',
			metal = 5000,
			energy = 5000,
			time = 5*60,
			name = 'ICBM Launcher',
			text = 'Ends the game with a exponential tech warhead one a ICBM',
			facing = true,
		},	
		{
			into = 'warheadfactory',
			metal = 5000,
			energy = 2500,
			time = 7*60,
			name = 'Warhead factory',
			text = 'Produces exponential tech warhead',
			facing = true,
		},

			{
			into = 'hivemind',
			metal = 5000,
			energy = 2500,
			time = 7*60,
			name = 'Hivemind Supra Intelligence',
			text = "Provides information warfare once assembled",
			facing = true,
		},
	},
	


}

return antagonDefs
