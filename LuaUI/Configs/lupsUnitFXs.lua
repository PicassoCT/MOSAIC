-- note that the order of the MergeTable args matters for nested tables (such as colormaps)!
function randSign()
if math.random(0,1)==1 then return -1 else return 1 end
end

function randomStar(posmin,posmax, sizemin,sizemax)
return	{class='ShieldSphere', options={life=math.huge, 
pos={math.random(posmin,posmax)*randSign(),math.random(posmin,posmax),math.random(posmin,posmax)*randSign()},size=math.random(sizemin,sizemax), 
colormap2 = {{0.9, 0.5, 0.01, 1}},
  colormap1 = {{0.95, 0.2, 0.01	, 1}}, 
  repeatEffect=true}}
	

end

local presets = {
	commandAuraRed = {
		{class='StaticParticles', options=commandCoronaRed},
			{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
		colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},
	},
	commandAuraOrange = {
		{class='StaticParticles', options=commandCoronaOrange},
			{class='GroundFlash', options=MergeTable(groundFlashOrange, {radiusFactor=3.5,mobile=true,life=math.huge,
		colormap={ {0.8, 0, 0.2, 1},{0.8, 0, 0.2, 0.85},{0.8, 0, 0.2, 1} }})},
	},
	commandAuraGreen = {
		{class='StaticParticles', options=commandCoronaGreen},
			{class='GroundFlash', options=MergeTable(groundFlashGreen, {radiusFactor=3.5,mobile=true,life=math.huge,
		colormap={ {0.2, 1, 0.2, 1},{0.2, 1, 0.2, 0.85},{0.2, 1, 0.2, 1} }})},
	},
	commandAuraBlue = {
		{class='StaticParticles', options=commandCoronaBlue},
			{class='GroundFlash', options=MergeTable(groundFlashBlue, {radiusFactor=3.5,mobile=true,life=math.huge,
		colormap={ {0.2, 0.2, 1, 1},{0.2, 0.2, 1, 0.85},{0.2, 0.2, 1, 1} }})},
	},	
	commandAuraViolet = {
		{class='StaticParticles', options=commandCoronaViolet},
			{class='GroundFlash', options=MergeTable(groundFlashViolet, {radiusFactor=3.5,mobile=true,life=math.huge,
		colormap={ {0.8, 0, 0.8, 1},{0.8, 0, 0.8, 0.85},{0.8, 0, 0.8, 1} }})},
	},	
	
	commAreaShield = {
		{class='ShieldJitter', options={delay=0, life=math.huge, heightFactor = 0.75, size=350, strength = .001, precision=50, repeatEffect=true, quality=4}},
	},
	
	commandShieldRed = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{1, 0.1, 0.1, 0.6}}, colormap2 = {{1, 0.1, 0.1, 0.15}}}, commandShieldSphere)},
		--		{class='StaticParticles', options=commandCoronaRed},
			--		{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
		--			colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},	
	},
	commandShieldOrange = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.8, 0.3, 0.1, 0.6}}, colormap2 = {{0.8, 0.3, 0.1, 0.15}}}, commandShieldSphere)},
	},	
	commandShieldGreen = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 1, 0.1, 0.6}}, colormap2 = {{0.1, 1, 0.1, 0.15}}}, commandShieldSphere)},
	},
	commandShieldBlue= {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 0.1, 0.8, 0.6}}, colormap2 = {{0.1, 0.1, 1, 0.15}}}, commandShieldSphere)},
	},	
	commandShieldViolet = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.6, 0.1, 0.75, 0.6}}, colormap2 = {{0.6, 0.1, 0.75, 0.15}}}, commandShieldSphere)},
	},	
}


effectUnitDefs = {
	--centrail
	
	css =		{
		{class='Ribbon', options={color={.9,.4,0.1,1}, width=1.5, piece="jet2", onActive=false}},
		{class='Ribbon', options={color={.9,.4,0.1,1}, width=1.5, piece="jet1", onActive=false}}				
	},	
	cvictory =		{
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,600,0}, size=125, precision=22, strength = 0.25, repeatEffect=true}}
	},
	cawilduniverseappears= {
	
		{class='ShieldSphere', options={life=math.huge, pos={0,0,0}, size=103,  colormap1 = {{1/255, 1/255, 50/255, 1.0}},colormap2 = {{150/255, 125/255, 230/255, 0.5}}, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=108, precision=22, strength = 0.013, repeatEffect=true}},
	},
	
	
	citadell= {
		
		{class='ShieldSphere', options={life=math.huge, pos={0,496,0}, size=1000, onActive=true, colormap1 = {{0.2, 0.8, 0.9, 0.8}}, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,496,0}, size=1024,onActive=true, precision=22, strength = 0.042, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,503,0}, size=5, precision=22, strength = 0.015, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,613,0}, size=100, precision=22, strength = 0.005, repeatEffect=true}},
	},
	
	
	cwallbuilder={
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,-25,0}, size=55, precision=22, strength = 0.015, repeatEffect=true}}, 
	},
	cairbase= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=42, precision=22, strength = 0.001, repeatEffect=true}},
	},
	
	cfclvl1= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,35,10}, size=42, precision=22, strength = 0.003, repeatEffect=true}},
	},
	cwaterextractor= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,116,0}, size=25, precision=22, strength = 0.015, repeatEffect=true}},
		
	},
	cadvisor ={
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=2, size= 32, piece="flare1", onActive=false}}	,
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=2, size= 32, piece="flare2", onActive=false}}	,
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=2, size= 32, piece="flare3", onActive=false}}	,
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=2, size= 32, piece="flare4", onActive=false}}	,
	},	
	cbbind= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,10,0}, size=96, precision=22, strength = 0.003, repeatEffect=true}},
	},
	cbuibaicity1= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,64,0}, size=80, precision=22, strength = 0.005, repeatEffect=true}}, 
	},
	
	cgunship= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={-2,5,-31}, size=20, precision=22, strength = 0.015, repeatEffect=true}}, 
	},
	
	cmdigg= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,24,-20}, size=30, precision=22, strength = 0.005, repeatEffect=true}}, 
	}, 
	cdefusordart= {
		{class='Ribbon', options={color={.9,.1,0.1,1}, width=6.5, size= 32, piece="dart", onActive=false}},
	}, 
	
	--journeyman
	jpoisonracedart= {
		{class='Ribbon', options={color={.7,.9,0.1,1}, width=6.5, size= 32, piece="RaceDrone", onActive=false}},
	},
	ggluemine= {
		{class='ShieldSphere', options={life=math.huge, pos={0,0,0}, size=10, colormap1 = {{0.36, 0.36, 0.9, 0.8}}, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=10.5, precision=22, strength = 0.005, repeatEffect=true}}
		},
	jracedart= {
		{class='ShieldSphere', options={life=math.huge, pos={0,0,0}, size=5, colormap1 = {{0.62, 0.9, 0.09, 0.8}}, repeatEffect=true}},
		{class='Ribbon', options={color={.2,.8,0.9,1}, width=6.5, size= 32, piece="RaceDrone", onActive=false}},
	},
	jhoneypot= {
		{class='Ribbon', options={color={.9,.4,0.1,1}, width=12.5, size= 32, piece="jhoney", onActive=false}},
	},
	jmotherofmercy ={
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=8, size= 32, piece="thrustemit", onActive=true}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=8, size= 32, piece="eye1", onActive=true}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=8, size= 32, piece="eye2", onActive=true}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=4, size= 32, piece="Kreis13", onActive=true}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=4, size= 32, piece="Kreis06", onActive=true}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=4, size= 32, piece="Kreis16", onActive=true}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=4, size= 32, piece="Kreis15", onActive=true}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=4, size= 32, piece="Kreis14", onActive=true}},
	},	
	jstealthdrone ={
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare1", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare2", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare3", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare4", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare5", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare6", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare7", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=4, size= 32, piece="flare8", onActive=true}},
		{class='Ribbon', options={color={.1,.4,0.9,1}, width=22.5, size= 10, piece="nanoemit", onActive=false}}		
	},	
	jrecycler ={
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit1", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit2", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit3", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit4", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit5", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit6", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit7", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit8", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit9", onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit10",onActive=false}},
		{class='Ribbon', options={color={.6,.9,0.0,1}, width=2, size= 32, piece="emit11",onActive=false}},
		{class='Ribbon', options={color={.4,.9,.9,1}, width=4, size= 32, piece="emit12",onActive=false}}	
	},
	jsunshipwater ={
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=325, precision=22, strength = 0.00125, repeatEffect=true}}
		
	},	
	jmeconverter ={
		{class='ShieldSphere', options={life=math.huge, pos={0,35,0}, size=18, colormap1 = {{0.3, 0.9, 0.06, 0.8}}, repeatEffect=true}},
		{class='ShieldJitter', options={life=math.huge, pos={0,35,0}, size=19.5, precision=22, strength = 0.001125, repeatEffect=true}},
		
	},
	jtiglil ={
		{class='Ribbon', options={color={.1,.8,0.9,1}, width=3.5, piece="tlhairup", onActive=false}},
	},
	jghostdancer ={
		{class='Ribbon', options={color={.1,.8,0.9,1}, width=3.5, piece="Tail05", onActive=false}},
	},
	
	
	
	jsunshipfire= {
		{class='ShieldSphere', options={life=math.huge, pos={0,0,0},size=220,onActive=true,   colormap2 = {{0.9, 0.5, 0.01, 0.9}},colormap1 = {{0.95, 0.2, 0.01	, 0.9}}, repeatEffect=true}},
	
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=1000, precision=22, strength = 0.005, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=225, precision=22, strength = 0.005, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=250, precision=22, strength = 0.029, repeatEffect=true}},
	},
	
	
	jshroudshrike={
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,15,0}, size=90, precision=22, strength = 0.015, repeatEffect=true}}, 
	},
	

	jmirrorbubble={
	-- Sun	
	{class='ShieldSphere', options={ onActive=true, life=math.huge, pos={math.random(-5,5),115,math.random(-5,5)}, size=math.random(30,35), colormap1 = {{0.2, 0.5, 0.9, 0.1}},colormap2 = {{0.2, 0.9, 0.3	, 0.6}},		repeatEffect=true}},			
	-- Planets
	{class='ShieldSphere', options={ onActive=true,life=math.huge, pos={math.random(-120,120),95, math.random(-120,120)}, size=math.random(2,10), colormap2 = {{0.2, 0.5, 0.9, 0.1}},colormap1 = {{0.2, 0.9, 0.3	, 0.3}},		repeatEffect=true}},			
	{class='ShieldSphere', options={ onActive=true,  life=math.huge, pos={math.random(-120,120),110, math.random(-120,120)}, size=math.random(5,8), colormap2 = {{0.2, 0.5, 0.9, 0.1}},colormap1 = {{0.2, 0.9, 0.3	, 0.3}},		repeatEffect=true}},			
	{class='ShieldSphere', options={ onActive=true,  life=math.huge, pos={math.random(-80,80),130, math.random(-80,80)}, size=math.random(2,10), 	colormap2 = {{0.2, 0.5, 0.9, 0.1}},colormap1 = {{0.2, 0.9, 0.3	, 0.3}},		repeatEffect=true}},			
	{class='ShieldSphere', options={ onActive=true,  life=math.huge, pos={math.random(-200,200),90, math.random(-200,200)}, size=math.random(5,15), colormap2 = {{0.2, 0.5, 0.9, 0.1}},colormap1 = {{0.2, 0.9, 0.3	, 0.3}},		repeatEffect=true}},			
	{class='ShieldSphere', options={ onActive=true,  life=math.huge, pos={math.random(-80,80),120, math.random(-80,80)}, size=math.random(5,15), 	colormap2 = {{0.2, 0.5, 0.9, 0.1}},colormap1 = {{0.2, 0.9, 0.3	, 0.3}},		repeatEffect=true}},			
	{class='ShieldSphere', options={ onActive=true,  life=math.huge, pos={math.random(180,250)*-1,115, math.random(180,250)*-1}, size=math.random(15,22), 	colormap2 = {{0.2, 0.5, 0.9, 0.1}},colormap1 = {{0.2, 0.9, 0.3	, 0.3}},		repeatEffect=true}},			
	
	{class='ShieldSphere', options={life=math.huge, pos={0,0,0},size=750, onActive=true, colormap2 = {{0.2, 0.5, 0.9, 0.014}},colormap1 = {{0.2, 0.9, 0.3	, 0.3}}, repeatEffect=true}},
	{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=780,  precision=22, strength = 0.00035, repeatEffect=true}},
		},
	
	
	gvolcano= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,70,0}, size=150, precision=22, strength = 0.01, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,1200,0}, size=250, precision=22, strength = 0.005, repeatEffect=true}},
		-- 	{class='SphereDistortion', options={layer=1, worldspace = true, life=math.huge, pos={0,496,0}, growth=135.5, strength=0.15, repeatEffect=true, dieGameFrame = math.huge}},--size=1000 precision=22,piece="cishadersp"
	}, 
	
	glava= {
		{class='ShieldSphere', options={  life=math.huge, pos={0,-5 ,0}, size=35, 
		colormap2 = {{0.9, 0.3, 0.0, 0.4}, {1, 0.3, 0, 0.0}},
		colormap1 = {{0.5, 0.3, 0.0, 0.0}, {1, 0.3, 0, 0.0}},
		repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=42, precision=22, strength = 0.007, repeatEffect=true}},
	},
	
	
	jwatergate= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,45,0}, size=20, precision=22, strength = 0.015, repeatEffect=true}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,15,0}, size=20, precision=28, strength = 0.007, repeatEffect=true}},
	},
	jharbour= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,35,0}, size=60, precision=28, strength = 0.007, repeatEffect=true}},
	},
	
	cegtest= {
		{class='ShieldSphere', options={  life=math.huge, pos={0,30.1,0}, size=50, 
		colormap2 = {{0.9, 0.3, 0.0, 0.4}, {1, 0.3, 0, 0.0}},
		colormap1 = {{0.5, 0.3, 0.0, 0.0}, {1, 0.3, 0, 0.0}},
		repeatEffect=true}}	
	},
	
	beanstalk= {

		{class='Ribbon', options={color={.7,1,0.1,0.5}, width=12.5, piece="seed"}},
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,20,0}, size=55, precision=22, strength = 0.005, repeatEffect=true}},
		--	outer ShieldSFX
		{class='ShieldSphere', options={ onActive=true, life=math.huge, pos={0,30.1,0}, size=600, 
		colormap1 = {{227/255, 227/255, 125/255, 0.15}},
		colormap2 = {{227/255, 250/255, 125/255, 0.15}},
		repeatEffect=true}},			
		{class='ShieldSphere', options={ onActive=true, life=math.huge, pos={0,30.2,0}, size=605, 
		colormap1 = {{125/255, 250/255, 125/255, 0.15}}, --g
		colormap2 = {{125/255, 227/255, 125/255, 0.15}},  --gb
		repeatEffect=true}},		
		{class='ShieldSphere', options={ onActive=true, life=math.huge, pos={0,30.3,0}, size=615, 
		colormap1 = {{125/255, 227/255, 225/255, 0.15}}, --gb
		colormap2 = {{125/255, 125/255, 250/255, 0.15}},  --b
		repeatEffect=true}},	
		{class='ShieldSphere', 	options={ onActive=true,  life=math.huge, pos={0,30.4,0}, size=625, 
		colormap1 = {{250/255, 125/255, 125/255, 0.25}}, --r
		colormap2 = {{0.62, 0.9, 0.09,  0.45}},			--g
		}, repeatEffect=true},
		
		{class='ShieldJitter', options={ onActive=true, delay=0,life=math.huge, pos={0,25,0}, size=655, precision=0.1, strength = 0.0035, repeatEffect=true}},

		},
	
	jestorage= {
		{class='ShieldSphere', options={life=math.huge, pos={0,18,2.3}, size=13.57, colormap1 = {{0.9, 0.6, 0.09, 0.8}}, repeatEffect=true}}
	},	
	
	jglowworms= {
		{class='Ribbon', options={color={.8,0.9,0,1}, width=5.5, piece="Glow2", onActive=false}},
		{class='Ribbon', options={color={.8,0.9,0,1}, width=5.5, piece="Glow6", onActive=false}},
	},
	
	
	gcvehiccorpsemini= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=5, precision=12, strength = 0.005, repeatEffect=true}}, 
	},
	
	gcvehiccorpse= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,0,0}, size=9, precision=22, strength = 0.005, repeatEffect=true}}, 
	},
	
	
	--{class='ShieldJitter', options={layer=-16, life=math.huge, pos={0,58.9,0}, size=100, precision=22, strength = 0.001, repeatEffect=true}},
	jbeefeater= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,36,-12.5}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,36,-56 }, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,36,-92}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
	},
	
	jbeefeatertail= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,18,44}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,18,22}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
	},
	jsempresequoia =		{
		{class='Ribbon', options={color={.4,.9,0.1,1},length=50, width=5.5, piece="truster1", onActive=false}},
		{class='Ribbon', options={color={.4,.9,0.1,1},length=50, width=5.5, piece="truster2", onActive=false}},				
		{class='Ribbon', options={color={.4,.9,0.1,1},length=50, width=5.5, piece="truster3", onActive=false}},				
		{class='Ribbon', options={color={.4,.9,0.1,1},length=50, width=5.5, piece="truster4", onActive=false}}				
	},		
	
	jbeefeatermiddle= {
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,37,57}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,37,92}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,37,124}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,37,-37}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,37,-69}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
		{class='ShieldJitter', options={delay=0,life=math.huge, pos={0,37,-101}, size=25, precision=22, strength = 0.015, repeatEffect=true}}, 
	},
	
	
	
	
}


effectUnitDefsXmas = {}

local levelScale = {
	1,
	1.1,
	1.2,
	1.25,
	1.3,
}

-- load presets from unitdefs
for i=1,#UnitDefs do
	local unitDef = UnitDefs[i]
	
	if unitDef.customParams and unitDef.customParams.commtype then
	end
	
	if unitDef.customParams then
		local fxTableStr = unitDef.customParams.lups_unit_fxs
		if fxTableStr then
			local fxTableFunc = loadstring("return "..fxTableStr)
			local fxTable = fxTableFunc()
			effectUnitDefs[unitDef.name] = effectUnitDefs[unitDef.name] or {}
			for i=1,#fxTable do	-- for each item in preset table
				local toAdd = presets[fxTable[i]]
				for i=1,#toAdd do
					table.insert(effectUnitDefs[unitDef.name],toAdd[i])	-- append to unit's lupsFX table
				end
			end
		end
	end
end