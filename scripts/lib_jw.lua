--===================================================================================================================
-- Game Configuration
function getGameConfig()
	return {
		MaxDrillTreeHeigth=420,
		Version= 130,
	}
end

--===================================================================================================================
--Journeywar specific functions 
--> creates a table from names to check unittypes against
function getUnitDefNames(UnitDefs)
	local UnitDefNames = {}
	for defID,v in pairs(UnitDefs) do
		UnitDefNames[v.name]=v
	end
	return UnitDefNames
end


function getTypeTable(UnitDefNames, StringTable)
	local Stringtable = StringTable
	retVal = {}
	for i = 1, #Stringtable do
		assert(UnitDefNames[Stringtable[i]], "Error: Unitdef of Unittype " .. Stringtable[i] .. " does not exists")
		retVal[UnitDefNames[Stringtable[i]].id] = true
	end
	return retVal
end

function getWeaponTypeTable(WeaponDefNames, StringTable)
	local Stringtable = StringTable
	retVal = {}
	for i = 1, #Stringtable do
		assert(WeaponDefNames[Stringtable[i]], "Error: Weapondef of Weapontype " .. Stringtable[i] .. " does not exists")
		retVal[WeaponDefNames[Stringtable[i]].id] = true
	end
	return retVal
end

function getJourneyBuildingTypeTable()
	JourneyBuildingTypes = tableToDict(getUnitCanBuild("beanstalk"))
	return JourneyBuildingTypes
end

function getCentrailBuildingTypeTable()
	CentrailBuildingTypes = tableToDict(getUnitCanBuild("citadell"))
	return CentrailBuildingTypes
end

function getAllBuildingTypes()
	return mergeDict(getJourneyBuildingTypeTable(),getCentrailBuildingTypeTable())
end

function getMainBuildingTypeTable()
	return {
		[UnitDefNames["citadell"].id] = true,
		[UnitDefNames["beanstalk"].id] = true
	}
end
--> JW specific function returning the factorys of the game
function getFactoryTypeTable(UnitDefNames, IWant)
	FactoryTypes = {}
	
	
	if IWant == "c" then
		FactoryTypes[UnitDefNames["cfclvl1"].id] = true
		FactoryTypes[UnitDefNames["cfclvl2"].id] = true
		FactoryTypes[UnitDefNames["condepot"].id] = true
		return FactoryTypes
	end
	
	if IWant == "j" then
		FactoryTypes[UnitDefNames["jtrafactory"].id] = true
		FactoryTypes[UnitDefNames["jtransportedeggstack"].id] = true
		FactoryTypes[UnitDefNames["jmovingfac1"].id] = true
		return FactoryTypes
	end
	
	--I want it all
	FactoryTypes[UnitDefNames["jtrafactory"].id] = true
	FactoryTypes[UnitDefNames["jtransportedeggstack"].id] = true
	FactoryTypes[UnitDefNames["jmovingfac1"].id] = true
	FactoryTypes[UnitDefNames["cfclvl1"].id] = true
	FactoryTypes[UnitDefNames["cfclvl2"].id] = true
	FactoryTypes[UnitDefNames["condepot"].id] = true
	return FactoryTypes
end

function getDefenseBuildingTypeTable(UnitDefNames)
	typeTable={
		"csentry",
		"crailgun",
		"cbonker",
		"chopper",
		"jfireflower",
		"jbonsai",
		"jdragongrass",
		"jbeehive",
		"jrefugeetrap",
		"ggluemine",
		"jpoisonhive"
	}
	return getTypeTable(UnitDefNames, typeTable)
end

function getCyberiziableUnitTypes()
	
	typeTable={
		"cspc",
		"campro",
		"csniper",
		"crestrictor",
		"chunter",
		"cadvisor",
		"cstrider",
		"beherith",
		"gseastar",
		"zombie",
		"gzombiehorse",
		"jhivewulf",
		"jhoneypot",
		"jbugcreeper",
		"jconcaterpillar",
		"jconroach",
		"jfiredancer",
		"jsungodcattle",
		"jswiftspear",
		"jhunter"		
	}
	
	ImplantableUnits= {}
	
	for k,v in pairs(typeTable) do
		for i=1, #UnitDefs do
			if UnitDef[i].name== v then
				ImplantableUnits[UnitDef[i].id] = true
			end
		end
	end
	
	return ImplantableUnits
	
end
function getCentrailOverworldGateUnitTypeTable()
	typeTable={
		"cauterizer",
		"cit3",
		"campro",
		"cspc",
		"csniper",
		"crestrictor",
		"chunter",
		"cadvisor"
	}
	return getTypeTable(UnitDefNames, typeTable)
	
end

function getImuneToFaceFuckTypeTable(UnitDefs)
	local UnitDefNames = UnitDefNames or getUnitDefNames(UnitDefs) 
	
	typeTable={
		"ccomender",
		"jswiftspear",
		"jbeherith",
	}
	return getTypeTable(UnitDefNames, typeTable)
	
end

function getArtilleryTypes(UnitDefs)
	local UnitDefNames = UnitDefNames or getUnitDefNames(UnitDefs) 
	
	typeTable={
		"art",
		"jantart",
		"ccomender",
		"campro",
		"jglowworms",
		"csuborbital"
	}
	return getTypeTable(UnitDefNames, typeTable)
end

function getBeanstalkShieldConvertibleWeaponTypes()
	typeTable= {
		"crabshell"
		,"cadvisoraa"
		,"cantimatter"
		,"cartdarkmat"
		,"cautsuicide"
		,"cbgrenade"
		,"cmtwgrenade"
		,"cchoperrocket"
		,"ceater"
		,"comendsniper"
		,"cnukegrenadelvl1"
		,"cnukegrenadelvl2"
		,"cnukegrenadelvl3"
		,"crailgun"
		,"slicergun"
		,"csuborbitalstrike"
		,"cwaterbombs"
		,"glavaweapon"
		,"gluemineweapon"
		,"hcprojectile"
		,"headlaunch"
		,"jacidants"
		,"jbeanstalkphoenix"
		,"jfacehugger"
		,"jfiredancerproj"
		,"jflyingfish"
		,"jglowproj"
		,"jgluegun"
		,"jinfectants"
		,"jresrpg"
		,"greenseer"
		,"varyfoospear"
		,"jvaryjump"
		,"jvaryspear"
		,"jplanktoneraa"
		,"lavabomb"
		,"razordrone"
		,"birdrocket"
		,"sniperweapon"
	}
	
	return getWeaponTypeTable(WeaponDefNames, typeTable)
end

function getUnAttractiveTypesTable()
	typeTable={
		"ccomender",
		"jswiftspear",
		"jbeherith",
	}
	return getTypeTable(UnitDefNames, typeTable)
	
	
end

--> Units imune to deadly Fungi
function getFungiImuneUnitTypeTable()
	local UnitDefNames = UnitDefNames or getUnitDefNames(UnitDefs) 
	
	retTab = {}
	retTab[UnitDefNames["jstealthdrone"].id] = true
	retTab[UnitDefNames["jconcaterpillar"].id] = true
	retTab[UnitDefNames["jconroach"].id] = true
	retTab[UnitDefNames["contrain"].id] = true
	retTab[UnitDefNames["jfungiforrest"].id] = true
	retTab[UnitDefNames["jtreel"].id] = true
	retTab[UnitDefNames["jvort"].id] = true
	retTab[UnitDefNames["cgamagardener"].id] = true
	retTab[UnitDefNames["beanstalk"].id] = true
	retTab[UnitDefNames["citadell"].id] = true
	retTab[UnitDefNames["ccomender"].id] = true
	retTab[UnitDefNames["jvaryfoo"].id] = true
	retTab[UnitDefNames["jspore"].id] = true
	retTab[UnitDefNames["jgoldspore"].id] = true
	
	for i = 1, 9 do
		retTab[UnitDefNames["jtree4" .. i].id] = true
	end
	
	return retTab
end

--> Units imune to deadly Fungi
function getTransformableByFungiTypesTable(UnitDefs)
	local UnitDefNames = UnitDefNames or getUnitDefNames(UnitDefs) 
	return {
		[UnitDefNames["jantart"].id] = true
	}
	
	
end



function getExemptFromLethalEffectsUnitTypeTable(UnitDefNamesL)
	if not UnitDefNames then UnitDefNames = UnitDefNamesL end
	retTab = {
		[UnitDefNames["ccomender"].id] = true,
		[UnitDefNames["beanstalk"].id] = true,
		[UnitDefNames["citadell"].id] = true,
		[UnitDefNames["gvolcano"].id] = true,
		[UnitDefNames["gproceduralfeature"].id] = true,
		[UnitDefNames["jabyss"].id] = true,
		[UnitDefNames["jvaryavatara"].id] = true,
		[UnitDefNames["jsungodcattle"].id] = true
		
	}
	
	return retTab
end
function getEggTypeTable(UnitDefNames)
	retTab = {
		[UnitDefNames["jskineggnogg"].id]=true,
		[UnitDefNames["jtigeggnogg"].id ]=true,
		[UnitDefNames["jdevoureregg"].id]=true,
		[UnitDefNames["jsuneggnogg"].id]=true
	}
	return retTab
end

function getScrapYardFeatures(FeatureDefNames)
	assert(FeatureDefNames)
	return {
		[FeatureDefNames["cinfantrycorpse"].id]=true,
		[FeatureDefNames["jbiocorpse"].id]=true,
		[FeatureDefNames["bug"].id]=true,
		[FeatureDefNames["honeypot"].id]=true,
		[FeatureDefNames["jinfantrycorpse"].id]=true,
		[FeatureDefNames["exconroach"].id]=true,
		[FeatureDefNames["jskincorpse"].id]=true,
		[FeatureDefNames["bgcorpse"].id]=true
	}
	
end

function getDreamTreeTransformUnitTypeTable(UnitDefNames)
	retTab = {
		[UnitDefNames["cit"].id] = UnitDefNames["jskineggnogg"].id,
		[UnitDefNames["cit2"].id] = UnitDefNames["jtigeggnogg"].id,
		[UnitDefNames["cit3"].id] = UnitDefNames["jtigeggnogg"].id,
		[UnitDefNames["ccrabsynth"].id] = UnitDefNames["jcrabcreeper"].id,
		[UnitDefNames["cgunship"].id] = UnitDefNames["jwatchbird"].id,
		[UnitDefNames["css"].id] = UnitDefNames["jfiredancer"].id,
		[UnitDefNames["cadvisor"].id] = UnitDefNames["jghostdancer"].id,
		[UnitDefNames["zombie"].id] = UnitDefNames["gcivillian"].id,
		[UnitDefNames["chunter"].id] = UnitDefNames["jhunter"].id,
		[UnitDefNames["gzombiehorse"].id] = UnitDefNames["ghohymen"].id,
		[UnitDefNames["gseastar"].id] = UnitDefNames["gnewsdrone"].id,
		[UnitDefNames["gcar"].id] = UnitDefNames["gull"].id
	}
	
	return retTab
end

function getAirUnitTypeTable(UnitDefNamesContext)
	if not UnitDefNames then UnitDefNames = UnitDefNamesContext end
	local retTab = {}
	retTab[UnitDefNames["cauterizer"].id] = true
	retTab[UnitDefNames["callygator"].id] = true
	retTab[UnitDefNames["conair"].id] = true
	retTab[UnitDefNames["citconair"].id] = true
	retTab[UnitDefNames["chunterchopper"].id] = true
	retTab[UnitDefNames["csuborbital"].id] = true
	retTab[UnitDefNames["cgunship"].id] = true
	
	retTab[UnitDefNames["gnewsdrone"].id] = true
	
	retTab[UnitDefNames["jsunshipfire"].id] = true
	retTab[UnitDefNames["jsunshipwater"].id] = true
	retTab[UnitDefNames["jmotherofmercy"].id] = true
	retTab[UnitDefNames["jsempresequoia"].id] = true
	retTab[UnitDefNames["jrecycler"].id] = true
	retTab[UnitDefNames["beanstalk"].id] = true
	retTab[UnitDefNames["jatlantai"].id] = true
	retTab[UnitDefNames["jwatchbird"].id] = true
	
	return retTab
end

function getPyroProofUnitTypeTable(UnitDefNamesContext)
	if not UnitDefNames then UnitDefNames = UnitDefNamesContext end
	
	local FireProofTypes = {}
	FireProofTypes[UnitDefNames["jsunshipfire"].id] = true
	FireProofTypes[UnitDefNames["css"].id] = true
	FireProofTypes[UnitDefNames["jfireflower"].id] = true
	FireProofTypes[UnitDefNames["citadell"].id] = true
	FireProofTypes[UnitDefNames["beanstalk"].id] = true
	FireProofTypes[UnitDefNames["jsungodcattle"].id] = true
	FireProofTypes[UnitDefNames["jtree3"].id] = true
	FireProofTypes[UnitDefNames["gpillar"].id] = true
	FireProofTypes[UnitDefNames["glava"].id] = true
	FireProofTypes[UnitDefNames["gvolcano"].id] = true
	FireProofTypes[UnitDefNames["jhoneypot"].id] = true
	return FireProofTypes
end

function getTreeTypeTable(UnitDefNames)
	FactoryTypes = {}
	FactoryTypes[UnitDefNames["jscrapheap_tree"].id] = true
	FactoryTypes[UnitDefNames["jtree2"].id] = true
	FactoryTypes[UnitDefNames["jtree2activate"].id] = true
	FactoryTypes[UnitDefNames["jtree3"].id] = true
	FactoryTypes[UnitDefNames["jtree41"].id] = true
	FactoryTypes[UnitDefNames["jtree42"].id] = true
	FactoryTypes[UnitDefNames["jtree43"].id] = true
	FactoryTypes[UnitDefNames["jtree44"].id] = true
	FactoryTypes[UnitDefNames["jtree45"].id] = true
	FactoryTypes[UnitDefNames["jtree46"].id] = true
	FactoryTypes[UnitDefNames["jtree47"].id] = true
	FactoryTypes[UnitDefNames["jtree48"].id] = true
	FactoryTypes[UnitDefNames["jtree1"].id] = true
	FactoryTypes[UnitDefNames["jtree5"].id] = true
	return FactoryTypes
end


function getInfantryTypeTable()
	if not UnitDefNames then UnitDefNames = getUnitDefNames(UnitDefs) end
	Infantry = {}
	Infantry[UnitDefNames["cit"].id] = true
	Infantry[UnitDefNames["cit2"].id] = true
	Infantry[UnitDefNames["cit3"].id] = true
	Infantry[UnitDefNames["jtiglil"].id] = true
	Infantry[UnitDefNames["jskinfantry"].id] = true
	Infantry[UnitDefNames["jhivewulf"].id] = true
	Infantry[UnitDefNames["jvort"].id] = true
	Infantry[UnitDefNames["css"].id] = true
	return Infantry
end

function getNeutralTypeTable()
	TypeTable = {}
	TypeTable[UnitDefNames["ggluemine"].id] = true
	TypeTable[UnitDefNames["ghohymen"].id] = true
	TypeTable[UnitDefNames["gcar"].id] = true
	TypeTable[UnitDefNames["jmadmax"].id] = true
	return TypeTable
end

function getConstructionUnitTypeTable()
	return getTypeTable(UnitDefNames, { 
		"contrain", 
		"contruck",
		"conair", 
		"citadell",
		"jconroach",
		"jconcaterpillar",
		"jstealthdrone",
		"beanstalk"				
	})
	
end

function getZombieTypeTable()
	Creep = {}
	Creep[UnitDefNames["gzombiehorse"].id] = true
	Creep[UnitDefNames["zombie"].id] = true
	Creep[UnitDefNames["hc"].id] = true
	return Creep
end

function getJourneyCorpseTypeTable()
	TypeTable = {}
	TypeTable[UnitDefNames["gjbigbiowaste"].id] = true
	TypeTable[UnitDefNames["gjmeatballs"].id] = true
	TypeTable[UnitDefNames["gjmedbiogwaste"].id] = true
	return TypeTable
end

function getCentrailCorpseTypeTable()
	TypeTable = {}
	TypeTable[UnitDefNames["gcvehiccorpse"].id] = true
	TypeTable[UnitDefNames["gcvehiccorpsemini"].id] = true
	return TypeTable
end

function getCorpseTypeTable()
	CorpseTable = getJourneyCorpseTypeTable()
	CentCorpseTable= getCentrailCorpseTypeTable()
	for key, v in pairs(CentCorpseTable) do
		CorpseTable[key] = true
	end
	return CorpseTable
end

function getRadiationResistantUnitTypeTable(lUnitDefNames)
	UnitDefNames = UnitDefNames or lUnitDefNames
	Resistance = {}
	Resistance[UnitDefNames["jvaryfoo"].id] = true
	Resistance[UnitDefNames["jtree2"].id] = true
	Resistance[UnitDefNames["jtree2activate"].id] = true
	Resistance[UnitDefNames["jdrilltree"].id] = true
	Resistance[UnitDefNames["cgamagardener"].id] = true
	return Resistance
end

function getJourneyCreeperTypeTable()
	Creep = {}
	Creep[UnitDefNames["jhoneypot"].id] = true
	Creep[UnitDefNames["jbugcreeper"].id] = true
	Creep[UnitDefNames["jcrabcreeper"].id] = true
	Creep[UnitDefNames["jsungodcattle"].id] = true
	return Creep
end

function getCentrailCreeperTypeTable()
	Creep = {}
	Creep[UnitDefNames["gzombiehorse"].id] = true
	Creep[UnitDefNames["zombie"].id] = true
	Creep[UnitDefNames["hc"].id] = true
	return Creep
end

function getCreeperTypeTable()
	return mergeDict( getJourneyCreeperTypeTable(),getCentrailCreeperTypeTable())
end

function getScrapYardDecalNames() 
	return {
		"battlefieldscrapdeca1",
		"battlefieldscrapdeca2",
	}
	
end

function getAbstractTypes(UnitDefNamesContext)
	if not UnitDefNames then UnitDefNames = UnitDefNamesContext end
	AbstractTypes = {
		[UnitDefNames["csuborbexplo"].id] = true,
		[UnitDefNames["actionzone"].id] = true,
		[UnitDefNames["reservoirzone"].id] = true,
		[UnitDefNames["triggerzone"].id] = true,
		[UnitDefNames["ccomendernuke"].id] = true,
		[UnitDefNames["ccomendernukelvl3"].id] = true,
		[UnitDefNames["cawilduniverseappears"].id] = true,
		[UnitDefNames["jtrafactory"].id] = true,
		[UnitDefNames["jtrafactory2"].id] = true,
		[UnitDefNames["jmirrorbubble"].id] = true,
		--TODO add all abstract types
	}
	
	return AbstractTypes
end

function getRecycleableUnitTypeTable()
	TransportTable = {
		[UnitDefNames["gjbigbiowaste"].id] = true,
		[UnitDefNames["gjmedbiogwaste"].id] = true,
		[UnitDefNames["gcvehiccorpse"].id] = true,
		[UnitDefNames["gcvehiccorpsemini"].id] = true,
		[UnitDefNames["gjmeatballs"].id] = true,
		[UnitDefNames["ghohymen"].id] = true,
		[UnitDefNames["zombie"].id] = true,
		[UnitDefNames["gseastar"].id] = true,
		[UnitDefNames["gshit"].id] = true
	}
	
	return TransportTable
end

function getDevourableUnitTypeTable()
	TransportTable = {
		[UnitDefNames["gjbigbiowaste"].id] = true,
		[UnitDefNames["gjmedbiogwaste"].id] = true,
		[UnitDefNames["gcvehiccorpse"].id] = true,
		[UnitDefNames["gcvehiccorpsemini"].id] = true,
		[UnitDefNames["gjmeatballs"].id] = true,
		[UnitDefNames["gshit"].id] = true,
		[UnitDefNames["jmeathivewulf"].id] = true
		
	}
	
	return TransportTable
end



function getGravityChangeReistantUnitTypeTable(UnitDefNames)
	TransportTable = {
		[UnitDefNames["jtree5"].id] = true,
		[UnitDefNames["jvort"].id] = true,
		[UnitDefNames["jtiglil"].id] = true,
		[UnitDefNames["jghostdancer"].id] = true
	}
	
	return mergeDict(TransportTable,getAbstractTypes())
end
--> Units are Transformed in a circle of types in the same team
function getMirrorBubbleTransformationTable(UnitDefNames)
	
	--the unitcycles are interleaving - meaning every tear2 can morph into 
	UnitCycleCentrail={
		
		--level 1 circle
		["cgamagardener"] = "cspc",
		["cspc"] = "cit3",
		["cit3"] = "css",
		["cit2"] = "cit3",
		["cit"] = "cit3",
		["css"] = "campro",
		["campro"] = "crestrictor",
		["crestrictor"] = "csniper",
		["csniper"] = "cadvisor",
		["cadvisor"] = "jtiglil",
		
		--level 2 circle
		["cwallbuilder"] = "coperatrans",
		["coperatrans"]	= "cwallbuilder", 
		["cwallbuilder"] = "art",	
		["cart"] = "csentrynell",
		["csentrynell"] = "cheadlauncher",
		["cheadlauncher"] = "jhoneypot",
		
		--level 3 circle
		["cpaxcentrail"]= "cgatefort",
		["cgatefort"]= "cnanorecon",
		["cnanorecon"]= "strider",
		["strider"] = "ccrabsynth",
		["ccrabsynth"] = "chunter",
		[ "chunter"] = "jmotherofmercy"
	}
	
	UnitCycleJourneyman={
		
		--level1 change cycle
		["jtiglil"]="jskinfantry",
		["jskinfantry"]="jtiglil",
		["jghostdancer"]="jhivewulfmoma",
		["jhivewulfmoma"]= "jvort",
		["jvort"]= "jantart", 
		["jantart"]="jhunter",
		["jhunter"]= "cgamagardener",
		
		--level2 change cycle
		["jhoneypot"]= "jviralfac",	
		["jviralfac"]= "jglowworms", 
		["jglowworms"]= "jbeherith",
		["jbeherith"]= "jeliah",
		["jeliah"]= "jshroudshrike",
		["jshroudshrike"]= "jswiftspear",
		["jswiftspear"]="cwallbuilder",
		
		--level 3
		
		[ "jmotherofmercy"]= "jsempresequoia",
		[ "jsempresequoia"]= "jrecycler",
		[ "jrecycler"]= "jsunshipwater",
		[ "jsunshipwater"]= "cpaxcentrail"
	}
	return mergeDict(UnitCycleCentrail,UnitCycleJourneyman)
end

-->Units equivalent - if a opposite side must be created
function getEquivalentMirrorTransformTypeTable(UnitDefNames)
	local UnitDefNames = UnitDefNames or getUnitDefNames(UnitDefs) 
	TransformationTable = {
		[UnitDefNames["cit"].id] = UnitDefNames["jskinfantry"].id,
		[UnitDefNames["cit2"].id] = UnitDefNames["jskinfantry"].id,
		[UnitDefNames["cit3"].id] = UnitDefNames["jskinfantry"].id,
		[UnitDefNames["css"].id] = UnitDefNames["jtiglil"].id,
		[UnitDefNames["cadvisor"].id] = UnitDefNames["jtiglil"].id,
		
	}
	
	return TransformationTable
end



function getRewardTable()
	Rewards = {
		[UnitDefNames["gjmeatballs"].id] = {
			ereward = 1000,
			mreward = 500
		},
		[UnitDefNames["gjmedbiogwaste"].id] = {
			ereward = 1000,
			mreward = 500
		},
		[UnitDefNames["jtiglil"].id] = {
			ereward = 100,
			mreward = 100
		},
		[UnitDefNames["jskinfantry"].id] = {
			ereward = 100,
			mreward = 100
		},
		[UnitDefNames["gjbigbiowaste"].id] = {
			ereward = 2000,
			mreward = 1000
		},
		[UnitDefNames["jvort"].id] = {},
		[UnitDefNames["jscrapheap_tree"].id] = {},
		[UnitDefNames["gcvehiccorpsemini"].id] = {
			mreward = 1000,
			ereward = 500
		},
		[UnitDefNames["gcvehiccorpse"].id] = {
			mreward = 2000,
			ereward = 1000
		},
		[UnitDefNames["gzombiehorse"].id] = {
			mreward = 2000,
			ereward = 1000
		},
		[UnitDefNames["ghohymen"].id] = {
			mreward = 2000,
			ereward = 1000
		},
		[UnitDefNames["cit"].id] = {
			ereward = 100,
			mreward = 100
		},
		[UnitDefNames["cit2"].id] = {
			ereward = 100,
			mreward = 100
		},	
		[UnitDefNames["cit3"].id] = {
			ereward = 100,
			mreward = 100
		},
		[UnitDefNames["css"].id] = {
			ereward = 100,
			mreward = 100
		}
	}
	return Rewards
end


function unitCanBuild(unitDefID)
	
	if unitDefID and UnitDefs[unitDefID] then		
		return UnitDefs[unitDefID].buildOptions 	
	end
	return {}
end

function getUnitDefIDFromName(name)
	for i=1,#UnitDefs do
		if name == UnitDefs[i].name then return UnitDefs[i].id end
	end
	
end

--computates a map of all unittypes buildable by a unit (detects loops)
--> getUnitBuildAbleMap
function getUnitCanBuildList(unitDefID, closedTableExtern, root)
	if not root then root = true end
	Result = {}
	assert(type(unitDefID)=="number")
	boolCanBuildSomething= false
	
	local openTable = unitCanBuild(unitDefID) or {}
	if lib_boolDebug == true then	
		assert(UnitDefs)
		assert(unitDefID)
		assert(UnitDefs[unitDefID],unitDefID)
		assert(UnitDefs[unitDefID].name)		
	end
	closedTable = closedTableExtern or {}
	local CanBuildList = unitCanBuild(unitDefID)
	closedTable[unitDefID] = true 
	
	for num, unitName in pairs(CanBuildList) do		
		defID = getUnitDefIDFromName(unitName)
		boolCanBuildSomething = true
		
		if defID and not closedTable[defID] then
			Result[defID] =defID	
			
			unitsToIntegrate, closedTable = getUnitCanBuildList(defID, closedTable, false)
			if unitsToIntegrate then
				for id,_ in pairs(unitsToIntegrate) do
					
					if lib_boolDebug == true then	
						Spring.Echo("+ "..UnitDefs[id].name)
					end
					
					Result[id] = id
				end
			end
		end
	end
	if boolCanBuildSometing == true then
		if root == true then
			Spring.Echo("Unit "..UnitDefs[unitDefID].name.." can built:")
		end
	end
	
	return Result,closedTable
end



CentrailUnitTypeList = getUnitCanBuildList(UnitDefNames["citadell"].id)
JourneyUnitTypeList = getUnitCanBuildList(UnitDefNames["beanstalk"].id)

function getUnitSide(unitID)
	defID= Spring.GetUnitDefID(unitID)
	if CentrailUnitTypeList[defID] then return "centrail"end
	if JourneyUnitTypeList[defID] then return "journeyman"end
	return "gaia"
end


function setDenial(key)
	if not GG.jw_denyCommunication then GG.jw_denyCommunication = {} end
	if not GG.jw_denyCommunication[key] then GG.jw_denyCommunication[key] = true end
end

-->denies a tree - withdraw percentage of health of the invested resources
function deactivateAndReturnCosts(key, UnitDef, ratio, delay)
	local lratio = ratior or 1
	ldelay = delay or 2000
	
	Sleep(ldelay)
	if not GG.jw_denyCommunication then GG.jw_denyCommunication = {} end
	GG.jw_denyCommunication[key] = false
	local boolThreadEnded = false
	
	while boolThreadEnded == false do
		
		if GG.jw_denyCommunication[key] == true then
			
			-- metalMake, metalUse, energyMake, energyUse=Spring.GetUnitResources(unitID)
			
			defID = Spring.GetUnitDefID(unitID)
			if not defID then return end
			health, maxhealth = Spring.GetUnitHealth(unitID)
			if not health then return end
			ecosts = UnitDef[defID].energyMake * (health / maxhealth)
			mcosts = UnitDef[defID].metalMake * (health / maxhealth)
			
			teamID = Spring.GetUnitTeam(key)
			if not teamID then return end
			
			Spring.AddTeamResource(teamID, "m", math.abs(mcosts * lratio))
			Spring.AddTeamResource(teamID, "e", math.abs(ecosts * lratio))
			x, y, z = Spring.GetUnitPosition(unitID)
			
			Spring.SetUnitResourcing(key, "ume", 0)
			Spring.SetUnitResourcing(key, "umm", 0)
			Spring.SetUnitResourcing(key, "uue", 1)
			
			x, y, z = Spring.GetUnitPosition(key)
			Spring.SpawnCEG("jtreedenial", x, y + 150, z, 0, 1, 0, 50, 0)
			Spring.PlaySoundFile("sounds/jtree/denial.ogg", 1.0)
			boolThreadEnded = true
		end
		Sleep(250)
	end
end

--
-->StartThread(dustCloudPostExplosion,unitID,1,600,50,0,1,0)
--Draws a long lasting DustCloud
function dustCloudPostExplosion(unitID, Density, totalTime, SpawnDelay, dirx, diry, dirz)
	x, y, z = Spring.GetUnitPosition(unitID)
	y = y + 15
	firstTime = true
	for j = 1, totalTime, SpawnDelay do
		for i = 1, Density do
			Spring.SpawnCEG("lightuponsmoke", x, y, z, dirx, diry, dirz)
		end
		
		
		Sleep(SpawnDelay)
	end
	Sleep(550 - totalTime)
	
	if math.random(0, 1) == 1 then
		Spring.SpawnCEG("earcexplosion", x, y + 30, z, 0, -1, 0)
	end
end

function getBuiLuxSoundScapeDefinition()
	
	soundScapeDefinition = {}
	soundScapeDefinition.opener = {
		[1] = 1000,
		[2] = 1000,
		[3] = 1000,
		[4] = 1000
	}
	
	soundScapeDefinition.closer = {
		[1] = 1000,
		[2] = 1000
	}
	
	soundScapeDefinition.background = {
		[1] = 10000,
		[2] = 10000,
		[3] = 10000,
		[4] = 10000,
		[5] = 10000,
		[6] = 10000
	}
	--1sec9_2sec12_4sec21_8sec22_10sec25_16sec26
	soundScapeDefinition.solo = {}
	for i = 1, 27, 1 do
		
		soundScapeDefinition.solo[i] = 1
		if i >= 9 then soundScapeDefinition.solo[i] = 2 end
		if i >= 12 then soundScapeDefinition.solo[i] = 4 end
		if i >= 21 then soundScapeDefinition.solo[i] = 8 end
		if i >= 22 then soundScapeDefinition.solo[i] = 16 end
		if i >= 25 then soundScapeDefinition.solo[i] = 20 end
		soundScapeDefinition.solo[i] = soundScapeDefinition.solo[i] * 1000
	end
	
	return soundScapeDefinition
end

function spawnFlareCircle(unitID)
	spiralcenter = piece "spiralcenter"
	fireFx = piece "fireFx"
	x, y, z = Spring.GetUnitPosition(unitID)
	local spSpawnCEG = Spring.SpawnCEG
	
	
	temp = 25
	max = 600
	allReadyImpulsed = {}
	while (temp < 350) do
		Move(fireFx, x_axis, temp, 0)
		temp = temp + 18.4
		for i = 1, 360, 1 do
			holyRandoma = math.random(0, 1)
			if holyRandoma == 1 then
				Turn(spiralcenter, y_axis, math.rad(i), 0, true)
				x, y, z = Spring.GetUnitPiecePosDir(unitID, fireFx)
				if y < 0 then y = 1 end
				
				if math.random(0, 4) == 2 then
					spSpawnCEG("csuborbscrap", x, y, z, 0, 1, 0, 0)
				else
					spSpawnCEG("portalflares", x, y, z, 0, 1, 0, 0)
				end
			end
		end
		
		Units = Spring.GetUnitsInCylinder(x, z, temp)
		table.remove(Units, unitID)
		if Units then
			for i = 1, #Units do
				if Units[i] ~= unitID and not allReadyImpulsed[Units[i]] then
					allReadyImpulsed[Units[i]] = true
					defID = Spring.GetUnitDefID(Units[i])
					mass = UnitDefs[defID].mass
					if mass < 500 then
						
						Spring.AddUnitImpulse(Units[i], 0, mass / 100, 0)
					end
				end
			end
		end
		
		Turn(spiralcenter, y_axis, math.rad(0), 0, true)
		Sleep(2)
	end
end

function portalStormWave(unitID)
	local spSpawnCEG = Spring.SpawnCEG
	ax, ay, az = Spring.GetUnitPosition(unitID)
	spSpawnCEG("portalspherespawn", ax, ay + 50, az, 0, 1, 0, 0)
	
	StartThread(spawnFlareCircle, unitID)
	
	for i = 1, 2 do
		Sleep(50 * i)
		spSpawnCEG("portalspherespawn", ax, ay + 50, az, 0, 1, 0, 0)
	end
end

function groupOnFire(DictionaryOfUnits, argtimeToburnMin, argtimeToburnMax)
	
	timeToburnMax = argtimeToburnMax or 1000
	timeToburnMin = argtimeToburnMin or 150
	
	for k, v in pairs(DictionaryOfUnits) do
		setUnitOnFire(k, math.ceil(math.random(timeToburnMin, timeToburnMax)))
	end
end

--> Sets A Unit on Fire
function setUnitOnFire(id, timeOnFire)
	if GG.OnFire == nil then GG.OnFire = {} end
	boolInsertIt = true
	--very bad sollution n-times
	
	for i = 1, table.getn(GG.OnFire), 1 do
		if GG.OnFire[i][1] ~= nil and GG.OnFire[i][1] == id then
			GG.OnFire[i][2] = math.ceil(timeOnFire)
			boolInsertIt = false
		end
	end
	
	if boolInsertIt == true then
		GG.OnFire[#GG.OnFire + 1] = {}
		GG.OnFire[#GG.OnFire][1] = id
		GG.OnFire[#GG.OnFire][2] = math.ceil(timeOnFire)
	end
end

function standingStill(ud, ed, cache)
	x, y, z = Spring.GetUnitPosition(ud)
	boolFullfilled = false
	if not cache.x then cache = { x = x, y = y, z = z }; return boolFullfilled, cache end
	if cache.x == x and cache.y == y and cache.z == z then
		boolFullfilled = true
	end
	cache = { x = x, y = y, z = z }
	return boolFullfilled, cache
end

-->Attack Nearest Non-Gaia Enemy if standing still
function defaultEnemyAttack(unitID, SignalMask, delayTime, condition)
	Signal(SIG_DEFAULT)
	SetSignalMask(SIG_DEFAULT)
	condition = condition or standingStill
	gaiaTeam = Spring.GetGaiaTeamID()
	Sleep(15000)
	delayTime = delayTime or 1500
	times = 0
	lastEd = math.huge
	cache = {}
	while true do
		times = times + delayTime
		Sleep(delayTime)
		ed = Spring.GetUnitNearestEnemy(unitID)
		if not ed then ed = Spring.GetUnitNearestAlly(unitID) or unitID end
		
		if ed == lastEd then ed = Spring.GetUnitNearestAlly(ed) end
		boolFullfilled, cache = condition(unitID, ed, cache)
		
		if boolFullfilled == true and ed and ed ~= lasEd and Spring.GetUnitTeam(ed) ~= gaiaTeam then
			x, y, z = Spring.GetUnitPosition(ed)
			Spring.GiveOrderToUnit(unitID, CMD.MOVE, { x, y, z }, {}) --{"shift"}
		end
		lastEd = ed
	end
end

-->Attack Nearest Non-Gaia Enemy if in a grop of size
function defaultEnemyGroupAttack(unitID, delayTime, range, groupsize)
	
	gaiaTeam = Spring.GetGaiaTeamID()
	delayTime = delayTime or 1500
	
	while true do
		Sleep(delayTime)
		x, y, z = Spring.GetUnitPosition(unitID)
		T = Spring.GetUnitsInCylinder(x, y, range)
		
		if T and table.getn(T) > groupsize then
			ed = Spring.GetUnitNearestEnemy(unitID)
			if ed and Spring.GetUnitTeam(ed) ~= gaiaTeam then
				x, y, z = Spring.GetUnitPosition(ed)
			end
		else
			ad = Spring.GetUnitNearestAlly(unitID)
			x, y, z = Spring.GetUnitPosition(ad)
		end
		Spring.SetUnitMoveGoal(unitID, x, y, z)
	end
end


--=======================================LandscapeTable=============================================================

--=======================================Tech Tree=============================================================

function getCombinNewTechTree()
	return {
		["origin"] = {
			["cupgshield"] = { lvl = 0, unlocks = {}, unlockedBy = "" },
			["cadvisorstalker"] = { lvl = 0, unlocks = {}, unlockedBy = "" },
			["ccontrainheal"] = { lvl = 0, unlocks = {}, unlockedBy = "" },
			["cresthumper"] = { lvl = 0, unlocks = {}, unlockedBy = "" }
		}
	}
end

function getSideNewTechTree(team, side)
	if not GG.orgTechTree then GG.orgTechTree = {} end
	
	if not GG.orgTechTree[team] and side == "centrail" then
		GG.orgTechTree[team] = getCombinNewTechTree()
		flattenTechTree(team)
	end
	
	if not GG.orgTechTree[team] and side == "journeyman" then
		GG.orgTechTree[team] = {}
		flattenTechTree(team)
	end
end

function flattenTechTree(team)
	if not GG.TechTree then GG.TechTree = {} end
	GG.TechTree[team] = {}
	
	local Tree = GG.orgTechTree[team][origin]
	if not Tree then GG.TechTree[team] = {}; return end
	
	for key, values in pairs(Tree) do
		if Tree[values.unlockedBy] and Tree[values.unlockedBy].lvl > 0 then
			GG.TechTree[team][key] = values.lvl
		else
			GG.TechTree[team][key] = 0
		end
	end
	
	return
end

function alterTechTree(team, TechName, funcModifier, boolOverride)
	parent = GG.orgTechTree[team]["origin"][TechName].unlockedBy
	
	if GG.orgTechTree[team]["origin"][parent].lvl > 0 or boolOverride == true then
		GG.orgTechTree[team]["origin"][TechName].lvl = funcModifier(GG.orgTechTree[team]["origin"][TechName])
		flattenTechTree(team)
	end
end


function checkOnTech(team, TechName)
	if not GG.TechTree or not GG.TechTree[team] or not GG.TechTree[team][TechName] then return 0
	else
		return GG.TechTree[team][TechName]
	end
end

function createTechTree(teams)
	for i = 1, #teams do
		--get side
		_, _, _, ai, side = Spring.GetTeamInfo(teams[i])
		--erect new tech tree
		getSideNewTechTree(teams[i], side)
	end
end

function getDayTime()
	DAYLENGTH = 28800
	Frame = (Spring.GetGameFrame() + (DAYLENGTH / 2)) % DAYLENGTH
	
	hours = math.floor((Frame / DAYLENGTH) * 24)
	minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
	seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
	return hours, minutes, seconds
end

--> Creates a Eventstream Event bound to a Unit
function createStreamEvent(unitID, func, framerate, persPack)
	persPack.unitID = unitID
	persPack.startFrame = Spring.GetGameFrame()
	persPack.functionToCall = func
	
	eventFunction = function(id, frame, persPack)
		nextFrame = frame + framerate
		if persPack then
			if persPack.unitID then
				--check
				boolDead = Spring.GetUnitIsDead(persPack.unitID)
				
				if boolDead and boolDead == true then
					return nil, nil
				end
				
				if not persPack.startFrame then
					persPack.startFrame = frame
				end
				
				if persPack.startFrame then
					nextFrame = persPack.startFrame + framerate
					persPack.startFrame = nil
				end 
			end
		end
		
		boolDoneFor, persPack = persPack.functionToCall(persPack)
		if boolDoneFor then
			return nil 
		end
		
		return nextFrame, persPack
	end
	
	GG.EventStream:CreateEvent(eventFunction, persPack, Spring.GetGameFrame() + 1)
end


function createRewardEvent(teamid, returnOfInvestmentM, returnOfInvestmentE)
	
	returnOfInvestmentM = returnOfInvestmentM or 100
	returnOfInvestmentE = returnOfInvestmentE or 100
	
	
	rewarderProcess = function (evtID, frame, persPack, startFrame)
		
		
		Spring.AddTeamResource(	persPack.teamId, 
		"metal", 
		persPack.returnOfInvestmentM/persPack.rewardCycles)
		Spring.AddTeamResource(persPack.teamId, 
		"energy", 
		persPack.returnOfInvestmentE/persPack.rewardCycles)
		
		persPack.rewardCycleIndex= persPack.rewardCycleIndex +1
		if persPack.rewardCycleIndex > persPack.rewardCycles then 
			return nil, nil
		end	
		
		return frame + 1000, persPack
	end
	
	persPack = { 
		teamId= teamid,
		returnOfInvestmentM= returnOfInvestmentM,
		returnOfInvestmentE= returnOfInvestmentE,
		id = unitID,
		rewardCycles= 25, 
		rewardCycleIndex= 0 
	}
	
	GG.EventStream:CreateEvent(
	rewarderProcess,
	persPack,
	Spring.GetGameFrame() + 1)
	
end

function getBlackGuardThougth(homePlanet, homeTown, name)
	homePlanet = homePlanet or "Todoine"
	homeTown = homeTown or "Lazytown"
	name = name or "John Doe"
	
	pStrings={
		--Topics: 
		--Food
		"I hate saline solution, wish i could eat a steak. A real steak. But cows are gone, like my stomache and my mouth-",
		--Sex
		"Wow, that - Thing has a hot ass. Would plow that like a seismic post!",
		--Tourism
		"Definatly worth a visit, the suns remind me so much of "..homePlanet.." moon.",
		--Social with locals
		"Yeah, assholes stop you assholes from going bannana! Watcha gonna do about it, Vort?",
		--Soldiersocialising among themselves
		"Fifth corps is totally loosing it. With that attitude they get the worst assignments.",
		"Overwatch commander, eh! The next time, we have contact, you better watch out-",
		--banned thoughts
		"One day, we should get rid of that mach< CENSORED> < Thought readjustment in progress > ",
		--CityVacation
		"Trooper is currently on extended City shoreleave. Zombie-OS on duty.",
		--Multiple Personalitys
		"Charlie, take the right eye, Liasane your left - watch your sectors. On pattern match, do a distance scan- and report. Yes,Sir!Yes,Sir!Yes,Sir!",
		--Implant Errors
		" Its the damn implant i tell you, everytime i think %'Stooge%' I get a orgasm!",
		-- Sleeping (philosophical zombie)
		"Overwatch soldier is currently resting. Zombie-OS on duty."
	}
	return pStrings[math.random(1,#pStrings)]
end

function getBlackGuardUnderFireThought(homePlanet, homeTown, name)
	homePlanet = homePlanet or "Todoine"
	homeTown = homeTown or "Lazytown"
	name = name or "John Doe"
	
	pStrings={
		"Join the army they said",
		"If you find me, my name was "..name.." and i regret leaving ".. homeTown.." on "..homePlanet,
		"Fuck, fuck, fuck!",
		"Open Up!",
		"Give it all you got!",
		"One giant heap for mankind!",
		"One step forward, 500 Steps/Second back, asshole!",
		"Not today cocksuckers. Im going to see "..homeTown.." again.",
		"Eat high-v darkmatter, its rich in Vitamin H,O,L and E!",
		"Grenade"
		
	}
	return pStrings[math.random(1,#pStrings)]
	
	
end