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


effectUnitDefs = {}


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