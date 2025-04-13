-- ===================================================================================================================
-- Game Configuration
 GG.unitFactor = 0.80
 GameVersion = "Alpha: 0.921"  
 function setUnitFactor(modOptions)
    GG.unitFactor = modOptions.unitfactor or 0.8
 end

function  getMapCultureMap(mapName)
    mapName = string.lower(mapName)
    mapToCultureDictionary = {
      ["mosaic_lastdayofdubai_v"] = GG.AllCultures.international, 
      ["dsdr 3.99"] = GG.AllCultures.international   
    }

    for name, culture in pairs(mapToCultureDictionary)do
        if string.find(mapName, name ) then return culture end
    end
    return nil
end

function GetRegionByHash(mapHash)
  allRegions = 9
  result = mapHash % allRegions
  resultMap = {
    [0] = "City States",
    [1] = "Middle East",
    [2] = "Central Asia",
    [3] = "Africa",
    [4] = "Europe",
    [5] = "North America",
    [6] = "South America",
    [7] = "South East Asia",
    [8] = "Central Asia",
      }

      return resultMap[result]
  end

  function GetRegionCulturePercentages(region)
      resultMap = {}
      resultMap["City States"] = {
        arabic = 0.04,
        international= 0.5,
        western = 0.23, 
        asian = 0.23
         }
      resultMap["Middle East"] = {arabic = 0.75, international= 0.10, western = 0.10, asian = 0.05}
      resultMap["Central Asia"] = {arabic = 0.35, international= 0.05, western = 0.10, asian = 0.50}
      resultMap["Africa"] = {arabic = 0.50, international= 0.30, western = 0.10, asian = 0.10}
      resultMap["Europe"] = {arabic = 0.00, international= 0.5, western = 0.50, asian = 0.00}
      resultMap["North America"] = {arabic = 0.05, international= 0.15, western = 0.70, asian = 0.10}
      resultMap["South America"] = {arabic = 0.15, international= 0.55, western = 0.15, asian = 0.15}
      resultMap["South East Asia"] = {arabic = 0.05, international= 0.20, western = 0.05, asian = 0.7}
      resultMap["Central Asia"] = {arabic = 0.50, international= 0.20, western = 0.05, asian = 0.25}
      return resultMap[region]
  end



  function getLocation()
        location = GG.Location
        if location then
            return location.region, location.country, location.province, location.cityname, location.citypart
        else
            return "location.region", "location.country"," location.province"," location.cityname"," location.citypart"
        end
  end


  function getCultureByRegionOrDefault(hash, percentages)
      dice = getDeterministicRandom(hash, 100)
      sumedUp= 0
      for culture, likelihood in pairs(percentages) do
          if ((dice >= sumedUp * 100) and (dice <= (sumedUp + likelihood) * 100)) then
            echo("GetCultureByRegion:" .. culture)
            return culture
          else
              sumedUp = sumedUp + likelihood
          end
      end

      echo("defaulting to random non deterministic culture")
      return randDict(percentages)
  end

function getDetermenisticMapHash(Game)
    assert(Game)
    local accumulated = 0
    local mapName = Game.mapName
    local mapNameLength = string.len(mapName)

    for i=1, mapNameLength do
        accumulated = accumulated + string.byte(mapName,i)
    end

    accumulated = accumulated + Game.mapSizeX
    accumulated = accumulated + Game.mapSizeZ
    return accumulated
end


function GetCultureByRegion(Game)
    mapHash = getDetermenisticMapHash(Game)
    region = GetRegionByHash(mapHash)
    percentages = GetRegionCulturePercentages(region)

    return getCultureByRegionOrDefault(mapHash, percentages)
end



function getInstanceCultureOrDefaultToo() 
    if GG.InstanceCulture then return GG.InstanceCulture end
    
    mapDependentCulture = getMapCultureMap(Game.mapName)  
    if mapDependentCulture then  
        GG.InstanceCulture = mapDependentCulture
    else 
        GG.InstanceCulture =  GetCultureByRegion(Game)
    end
    
    return GG.InstanceCulture
end

function getModOptionCulture()
    modOptions = Spring.GetModOptions()
    setUnitFactor(modOptions)

    return modOptions.culture
end

function getGameConfig()
    return {
        instance = {
            culture = getInstanceCultureOrDefaultToo(), -- "international", "western", "asian", "arabic"
            Version = GameVersion
        },

        visuals = {
            falloutParticlesMax = 128
        },

        numberOfBuildings = math.ceil(150 * GG.unitFactor),
        numberOfVehicles = math.ceil(60 * GG.unitFactor),
        numberOfPersons = math.ceil(75 * GG.unitFactor),
        nightCivilianReductionFactor = 0.125,
        anarchyCarReductionFactor = 0.25,
        MegaBuildingMax= 12,

        LoadDistributionMax = 5,

        --truck
        truckBreakTimeMinSec= 60,
        truckBreakTimeMaxSec= 5*60,
        truckHonkLoudness = 0.25,
        chanceOfCivilianSpawningFromTruck = 0.65,
		emergencyLocationTimeMs = 20 *1000,
		
        houseSizeX = 256,
        houseSizeY = 64,
        houseSizeZ = 256,
        innerCitySize = 2048,
        innerCityNeonStreet = 512,
        houseNumberOfSameRoofIDGroupsPerCity= 4,
        
        minimalMoveDistanceElseStuck = 140,
  
        allyWaySizeX = 25,
        allyWaySizeZ = 25,
        bonusFirstUnitMoney_S = 12,
        maxParallelIdleAnimations = 20,
        SniperAttachMaxDistance = 128,
        agentConfig = {
            recruitmentRange = 60,
            raidWeaponDownTimeInSeconds = 60,
            raidComRange = 1500,
            raidBonusFactorSatellite = 2.5
        },
        SnipeMiniGame = {
            Aggressor = {StartPoints = 4},
            Defender = {StartPoints = 4}
                        },

        -- ObjectiveRewardRate

        Objectives = {
            RewardCyle = 30 * 60, -- /30 frames = 1 seconds
            Reward = 20
        },
        maxNrExplosionSoundFiles = 14,
        -- civilianbehaviour
        civilian = {
          GatheringBehaviourIntervalFrames = 3 * 60 * 30,
          PanicRadius = 900,
          FleeDistance = 1200,
          MaxFlightTimeMS = 300000,
          InterestRadius = 350, 
          MaxWalkingDistance = 3000,
        },

        civilianGatheringBehaviourIntervalFrames = 3 * 60 * 30,
        civilianPanicRadius = 900,
        civilianFleeDistance = 1200,
        civilianMaxFlightTimeMS = 300000,
        civilianInterestRadius = 350,

        generalInteractionDistance = 35,
        minConversationLengthFrames = 15 * 30,
        maxConversationLengthFrames = 120 * 30,
        groupChatDistance = 150,
        inHundredChanceOfInterestInDisaster = 35,
        inHundredChanceOfDisasterWailing = 75,
        mainStreetModulo = 4,
        maxIterationSteps = 2048,
        chanceCivilianArmsItselfInHundred = 50,
        demonstrationMarchRadius = 50,

        Police = {
          maxNr = 8,
          maxDispatchTime = 2000,
          minSpawnDistance = 2200,
        },

        teargasRadius = 200,

        maxSirenSoundFiles = 7,

        --soundIntervall
        actionIntervallFrames = math.ceil(2.5*60*30),
        peaceIntervallFrames =  math.ceil(4*60*30),

        -- safehouseConfig
        buildSafeHouseRange = 80,
        safeHousePieceName = "center",
        delayTillSafeHouseEstablished = 15000,
        safeHouseLiftimeUnattached = 500,

        -- all buildings
        buildingLiftimeUnattached = 10000,

        -- propagandaserver
        propandaServerFactor = 0.1,

        --cybercrime
        RewardCyberCrime = 300,
        rewardWaitTimeCyberCrimeSeconds = 30,

        --closecombat
        closeCombatHealthLosPerSecond = 10,

        --groundTurretDroneProjectileIntercept
        groundTurretDroneInterceptRate = 256,
        groundTurretDroneMaxInterceptPerSecond = 7,

        --Parachute
        parachuteHeight = 150,
        -- doubleAgentHeight
        doubleAgentHeight = 64,

        -- Dayproperties
        daylength = 28800, -- in frames

        --Loot 
        lootCollectionReward = 200,

        -- Interrogation
        InterrogationTimeInSeconds = 20,
        InterrogationTimeInFrames = 20 * 30,
        InterrogationDistance = 185,
        RaidDistance = 250,

        --operatives
        investigatorCloakedSpeedReduction = 0.35,
        operativeShotFiredWaitTimeToRecloak_MS = 10000,
        OperativeDropHeigthOffset = 900,

        --motorBike
        motorBikeSurvivalStandaloneMS = 15 * 1000,

        -- checkpoint
        checkPointRevealRange = 125,
        checkPointPropagandaCost = 75,

        raid = {
            maxTimeToWait = 3 * 60 * 1000,
            maxRoundLength = 15 * 1000,
            interrogationPropagandaPrice = 1000,
			revealGraphLifeTimeFrames = 5 * 60 * 30,
        },

        warzoneValueNormalized = 0.25,
        -- asset
        assetCloakedSpeedReduction = 0.175,
        assetSpeedRunning = 1.0,
        assetSpeedWalking = 0.6,
        assetShotFiredWaitTimeToRecloak_MS = 6000,
        assetMaxRunTimeInSeconds = 15,

        Wreckage = {lifeTime = 7 * 60 * 1000},

        -- Launcher
        PreLaunchLeakSteps = 4, --after 5fth step
        LaunchReadySteps = 7,
        LauncherInterceptTimeSeconds = 20,
        LauncherMaxHeight = 3000,
        --Payloads
        bioWeaponPayloadKillRadius = 1700,
		PayloadDefusedReward = 5000,
        payloadDestructionRange = 420,
		
        -- CruiseMissiles
        CruiseMissile = {
        heightOverGround = 42,
        antiArmorDroplettRange = 1200,
        chanceOfInterceptOneIn = 25,
        reloadTimeMS = 5*60*1000,            
        },
        vtolInAirMax = 6,

        
        -- Game States
        GameState = {
            normal = "normal",
            launchleak = "launchleak",
            anarchy = "anarchy",
            postlaunch = "postlaunch",
            gameover = "gameover",
            pacification = "pacification"
        },
        --Molotov FireDamage
        fireDamagePerFrame = 3,

        anarchySexCouplesEveryNSeconds = 3 * 60,
        LifeTimeRiotPoliceSeconds = 35,
        TimeForInterceptionInFrames = 30 * 10,
        TimeForPanicSpreadInFrames = 15 * 30,
        TimeForPacification = 30 * 90,
        TimeForScrapHeapDisappearanceInMs = 5 * 60 * 1000, -- 3 Minutes off line

        costs = {
            DestroyedHousePropanda = 5000,
        RecruitingTruck = 500},

        -- startenergymetal
        energyStartVolume = 10000,
        energyStart = 5000,
        metalStartVolume = 10000,
        metalStart = 5000,

        -- Icons
        socialEngineeringRange = 256,
        socialEngineerLifetimeMs = 3*60*1000,
        LifeTimeBribeIcon = 2*60 * 1000,
        iconGroundOffset = 50,        
        iconHoverGroundOffset = 125,
        iconBlackHoleComDeactivateRange = 630,
        LifeTimeBlackOutIcon = 5* 60 * 1000,
        HedgeHog =
        {
            ShotgunRange = 75,
            ShotgunDamage = 200,
            ExplodingRange = 150,
            ExplodingDamage = 900
        },
        Satellite = {
            iconDistance = 150,
            shrapnellDistance = 450,
            shrapnellLifeTime = 7 * 60 * 1000,
            shrapnellDamagePerSecond = 1000,
            uploadTimesMs = 8000,
            GodRodDropDistance = 50,
            GodRodReloadTimeInMs = 10000,
            GodRodTimeToImpactInMs= 10000,
            SatteliteHijackTimeMs = 15000
        },        

        -- Hiveminds & AiCores
        integrationRadius = 75,
        maxNumberIntegratedIntoHive = 300,
        addSlowMoTimeInMsPerCitizen = 150,

        -- Aerosols
        Aerosols = {
            sprayRange = 250,
            orgyanyl = {
                sprayTimePerUnitInMs = 2 * 60 * 1000, -- 2mins
                VictimLifetime = 1 * 60 * 1000
            },
            wanderlost = {
                sprayTimePerUnitInMs = 2 * 60 * 1000,
                VictimLiftime = 3 * 60 * 1000,
                reinfectRange= 50,
            }, -- 2mins
            tollwutox = {
                sprayTimePerUnitInMs = 2 * 60 * 1000,
                VictimLiftime = 7 * 60 * 1000
            }, -- 2mins
            depressol = {
                sprayTimePerUnitInMs = 2 * 60 * 1000,
                VictimLiftime = 3 * 60 * 1000
            } -- 2mins

        },
        -- Defusal Time 
        Warhead= {
                DefusalTimeMs = 30*1000,
                DefusalStartDistance = 75,
                DefusalPunishment = -500,
                automationPayloadStunTimeSeconds = 60,
        },

        minutMS     = 60*1000,
        hourMS      = 60*60*1000,
        secondMS    = 1000,
    }
    end

   function getAllCultures()
	return {
		arabic = "arabic",
		international = "international",
		western = "western",
		asian = "asian"		}
   end

    Cultures =  getAllCultures()
    GG.AllCultures = getAllCultures()
    GG.GameConfig = getGameConfig()
    _G.GameConfig = getGameConfig()    
  

    -- ===================================================================================================================
    function getCultureName()
        if not GG.GameConfig then  GG.GameConfig = getGameConfig() end
        return GG.GameConfig.instance.culture
    end
    -- ===================================================================================================================
    function getChemTrailTypes()
        return {
            ["orgyanyl"] = "orgyanyl",
            ["wanderlost"] = "wanderlost",
            ["tollwutox"] = "tollwutox",
            ["depressol"] = "depressol"
        }
    end

    function stringToHash(hashString)
        totalValue = 0
        for i = 1, string.len(hashString) do
            local c = hashString:sub(i, i)
            totalValue = totalValue + string.byte(c, 1)
        end

        return totalValue
    end

function detectMapControlledPlacementComplete()
    if Spring.GetGameFrame() < 1 then return false end
    if GG.MapCompletedBuildingPlacement and GG.MapCompletedBuildingPlacement == true then return GG.MapCompletedBuildingPlacement end

    allUnits = Spring.GetTeamUnitsByDefs(gaiaTeamID, UnitDefNames["map_placements_complete"].id)
    if allUnits and #allUnits > 1 then
        foreach(allUnits,
                function (id)
                    Spring.DestroyUnit(id, true, false)
                end)
            GG.MapCompletedBuildingPlacement = true
    end
end

function isMapControlledBuildingPlacement()
    return getManualCivilianBuildingMaps(Game.mapName)
end
   
    function  getManualCivilianBuildingMaps(mapName)
        mapName = string.lower(mapName)
        ManualCivilianBuildingPlacement = {
          ["mosaic_lastdayofdubai"] = true
        }
        
        for name, value in pairs(ManualCivilianBuildingPlacement)do
            if string.find(mapName, name ) then return true end
        end

        return false
   end

   function getPayloadTypes(UnitDefs)
    local UnitDefNames = getUnitDefNames(UnitDefs)

    typeTable = {
        "biopayload",
        "physicspayload",
        "informationpayload",
        "potemkinpayload"
        }
    return getTypeTable(UnitDefNames, typeTable)
    end

 function getLoudLongRangeWeaponTypes(WeaponDefs)
    assert(WeaponDefs)
     nameOfGun={
        "javelinrocket",
	"mortar",
	"orbitalrailgun",
	"railgun",
	"sniperrifle ",
	"tankcannon"
	}
    longRangeLoudWeaponTypes ={}
	for defId,def in pairs(WeaponDefs) do
	   if nameOfGun[def.name] then
		longRangeLoudWeaponTypes[defId] = def.name
	   end
	end
	return longRangeLoudWeaponTypes
 end

  function getLaunchablePayloadTypes(UnitDefs)
    local UnitDefNames = getUnitDefNames(UnitDefs)

    typeTable = {
        "biopayload",
        "physicspayload",
        "informationpayload"
        }
    return getTypeTable(UnitDefNames, typeTable)
    end


    function getVictoryStillPossibleTypeSets(UnitDefs)
    local UnitDefNames = getUnitDefNames(UnitDefs)

    operator = {
        "operativeinvestigator",
        "operativepropagator"
        }

    safehouse = {
        "antagonsafehouse",
        "protagonsafehouse"
        }

    gameenders = {
        "physicspayload",
        "biopayload",
        "informationpayload",
        "launcher",
        }


    return {
            getTypeTable(UnitDefNames, operator), 
            getTypeTable(UnitDefNames, safehouse),
            getTypeTable(UnitDefNames, gameenders), 
            getLaunchablePayloadTypes(UnitDefs)
            }
    end



    function getChemTrailInfluencedTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)

        typeTable = {"civilianagent"}
        typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(),
        "civilian", UnitDefs))

        return getTypeTable(UnitDefNames, typeTable)
    end

    function getIndividualCulturalNamedTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)

        typeTable = {"civilianagent"}
        typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(),
        "civilian", UnitDefs))

        return getTypeTable(UnitDefNames, typeTable)
    end

    function getBuildingScrapHeapTypeTable(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = {
                    "gcscrapheap"                   
                }
                
        return getTypeTable(UnitDefNames, typeTable)          
    end
    
    function getScrapheapTypeTable(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = {
                    "gcscrapheap",
                    "vehiclecorpse", 
                    "tankcorpse"
                }
        return getTypeTable(UnitDefNames, typeTable)        
    end    

    function getBombTypeTable(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = {
                    "ground_turret_ssied",
                    "air_copter_ssied", 
                    "ground_truck_ssied"

                }
        return getTypeTable(UnitDefNames, typeTable)        
    end
	
	function registerEmergency(x, z)
		if not GG.EmergencyPositions then GG.EmergencyPositions = {} end
		GG.EmergencyPositions[#GG.EmergencyPositions+1] = {x=x, z=z}
	 end

    function getPoliceTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["policetruck"].id] = true,
            [UnitDefNames["ground_tank_night"].id] = true,
            [UnitDefNames["house_spinner"].id] = true
        }
    end 

    function getShowHideIconTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["aicore"].id] = true,
            [UnitDefNames["protagonassembly"].id] = true,
            [UnitDefNames["antagonassembly"].id] = true,
            [UnitDefNames["hivemind"].id] = true,
            [UnitDefNames["propagandaserver"].id] = true,
            [UnitDefNames["antagonsafehouse"].id] = true,
            [UnitDefNames["protagonsafehouse"].id] = true,
            [UnitDefNames["launcher"].id] = true,
            [UnitDefNames["nimrod"].id] = true,
            [UnitDefNames["warheadfactory"].id] = true,
            [UnitDefNames["satellitescan"].id] = true,
            [UnitDefNames["satelliteanti"].id] = true,
            [UnitDefNames["satellitegodrod"].id] = true,
            [UnitDefNames["operativeasset"].id] = true,
            [UnitDefNames["operativeinvestigator"].id] = true           
        }
    end

   function getCloseCombatAbleTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["operativeasset"].id] = true,
            [UnitDefNames["operativepropagator"].id] = true,
            [UnitDefNames["operativeinvestigator"].id] = true
        }
    end

    function getTurnCoatFactoryType(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["protagonassembly"].id] = true,
            [UnitDefNames["antagonassembly"].id] = true,
            [UnitDefNames["nimrod"].id] = true
        }
    end

    function getObjectiveTypes(UnitDefs)
        assert(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["objective_military_gyland"].id] = "water",
            [UnitDefNames["objective_refugeegyland"].id] = "water",
            [UnitDefNames["objective_factoryship"].id] = "water",
            [UnitDefNames["objective_spaceport"].id] = "water",
            [UnitDefNames["objective_refugeecamp"].id] = "land",
            [UnitDefNames["objective_powerplant"].id] = "land",
            [UnitDefNames["objective_geoengineering"].id] = "land",
            [UnitDefNames["objective_westhemhq"].id] = "land",
            [UnitDefNames["objective_artificialglacier"].id] = "land",
            [UnitDefNames["objective_combatoutpost"].id] = "land",
            [UnitDefNames["objective_transrapid"].id] = "land",
            [UnitDefNames["objective_airport"].id] = "land",
            [UnitDefNames["objective_pumpstation"].id] = "land"
        }
    end

    function getECMIconTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["icon_bribe"].id] = true,
            [UnitDefNames["icon_socialengineering"].id] = true,
            [UnitDefNames["icon_cybercrime"].id] = true,       
            [UnitDefNames["deaddropicon"].id] = true,
            [UnitDefNames["icon_blackout"].id] = true,
            [UnitDefNames["icon_hijacksatellite"].id] = true,
            [UnitDefNames["icon_emc"].id] = true,
        }
    end      

    function getECMSpecialSFXIconTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["icon_emc"].id] = true,
            [UnitDefNames["icon_bribe"].id] = true,
            
        }
    end  

    function getIconTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["icon_raid"].id] = true,
            [UnitDefNames["doubleagent"].id] = true,
            [UnitDefNames["interrogationicon"].id] = true,
            [UnitDefNames["recruitcivilian"].id] = true,
            [UnitDefNames["icon_bribe"].id] = true,
            [UnitDefNames["icon_socialengineering"].id] = true,
            [UnitDefNames["icon_cybercrime"].id] = true,
            [UnitDefNames["launcherstep"].id] = true,
            [UnitDefNames["destroyedobjectiveicon"].id] = true,
            [UnitDefNames["biopayload"].id] = true,
            [UnitDefNames["informationpayload"].id] = true,
            [UnitDefNames["potemkinpayload"].id] = true,
            [UnitDefNames["physicspayload"].id] = true,
            [UnitDefNames["deaddropicon"].id] = true,
            [UnitDefNames["stealvehicleicon"].id] = true,
            [UnitDefNames["icon_blackout"].id] = true,
            [UnitDefNames["icon_hijacksatellite"].id] = true,
            [UnitDefNames["icon_emc"].id] = true,
          --[[  [UnitDefNames["advertising_blimp_hologram"].id] = true,           
            [UnitDefNames["house_western_hologram_buisness"].id] = true,           
            [UnitDefNames["house_western_hologram_casino"].id] = true,           
            [UnitDefNames["house_western_hologram_brothel"].id] = true,           --]]
        }
    end  

    function getCivilianVTOLTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
                    [UnitDefNames["house_vtol"].id] = true     
                }
    end  
    function getWindowBuildingTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
                    [UnitDefNames["house_western0"].id] = true,           
                    [UnitDefNames["house_asian0"].id] = true,           
                    [UnitDefNames["house_asian1"].id] = true,           
                    [UnitDefNames["house_arab0"].id] = true       
                }
    end  
    function getHologramTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
                    [UnitDefNames["advertising_blimp_hologram"].id] = true,           
                    [UnitDefNames["house_western_hologram_buisness"].id] = true,           
                    [UnitDefNames["house_western_hologram_casino"].id] = true,           
                    [UnitDefNames["house_western_hologram_brothel"].id] = true,           
                    [UnitDefNames["house_asian_hologram_buisness"].id] = true,           
                }
    end  

    function attachHologramToUnitPiece(unitID, holoDefID, pieceID)
        id = createUnitAtUnit(Spring.GetUnitTeam(unitID), holoDefID, unitID)
        Spring.UnitAttach(id,unitID, pieceID)
        Spring.SetUnitAlwaysVisible(id, true)
        Spring.SetUnitNeutral(id, true)
        Spring.SetUnitNoSelect(id, true)
        isblocking = false
        isSolidObjectCollidable = false
        isProjectileCollidable = false
        isRaySegmentCollidable = false
        crushable = false
        blockEnemyPushing = false
        blockHeightChanges = false
        Spring.SetUnitBlocking(id, isblocking, isSolidObjectCollidable, isProjectileCollidable, isRaySegmentCollidable , crushable, blockEnemyPushing, blockHeightChanges ) 
        Spring.SetUnitBlocking(unitID, isblocking, isSolidObjectCollidable, isProjectileCollidable, isRaySegmentCollidable, crushable, blockEnemyPushing, blockHeightChanges ) 
        
        return id
    end
    
    
    function moveCtrlHologramToUnitPiece(parentID, holoDefID, pieceID, orientation, heightOffset)
        orientation =math.rad(orientation)

        assert(pieceID)
        Sleep(10)
   
        WaitForMoves(pieceID)
--        echo(holoDefID.." has rotation "..toString(orientation))
        Sleep(500)
  
        id = createUnitAtUnit(Spring.GetUnitTeam(parentID), holoDefID, parentID, 0,0,0,0)
    
        Spring.MoveCtrl.Enable(id, true)
        px, py, pz = Spring.GetUnitPiecePosDir(parentID, pieceID)
        if minHeight then
            py = py + heightOffset
        end
        --echo("Moving hologram "..id.." to ("..px.."/"..py.."/"..pz..")")
        Spring.MoveCtrl.SetRotation(id, 0,  orientation, 0)
        Spring.MoveCtrl.SetPosition(id, px, py, pz)

        Spring.SetUnitAlwaysVisible(id, true)
        Spring.SetUnitNeutral(id, true)
        Spring.SetUnitNoSelect(id, true)
        isblocking= false
        isSolidObjectCollidable=false
        isProjectileCollidable= false
        isRaySegmentCollidable = false
        crushable = false
        blockEnemyPushing= false
        blockHeightChanges = false
        Spring.SetUnitBlocking(id, isblocking, isSolidObjectCollidable, isProjectileCollidable, isRaySegmentCollidable , crushable, blockEnemyPushing, blockHeightChanges ) 
    
        return id
    end




    function getManualObjectiveSpawnMapNames(mapName)
        mapName = string.lower(mapName)
        ManualBuildingPlacement = {        
            ["mosaic_lastdayofdubai_v"] = true
        }

          for name, value in pairs(ManualBuildingPlacement)do
            if string.find(mapName, name ) then return true end
        end
        return false
    end

    function getDeadObjectiveType(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["destroyedobjectiveicon"].id] = true,
        }
    end

    -- Mosaic specific functions
    -- > creates a table from names to check unittypes against
    function getUnitDefNames(UnitDefs)
        local UnitDefNames = {}
        if UnitDefs == nil then return nil end

        for defID, v in pairs(UnitDefs) do UnitDefNames[v.name] = v end
    return UnitDefNames
    end

    function getTypeTable(UnitDefNames, StringTable)
        local Stringtable = StringTable
        retVal = {}
        for i = 1, #Stringtable do
            if not UnitDefNames[Stringtable[i]] then
                Spring.Echo("Error: Unitdef of Unittype " .. Stringtable[i] .." does not exists")
            else
                retVal[UnitDefNames[Stringtable[i]].id] = true
            end
        end
        return retVal
    end

    function getAerosolUnitDefIDs(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        AerosolTypes = getChemTrailTypes()
        return {
            [UnitDefNames["air_copter_aerosol_orgyanyl"].id] = AerosolTypes.orgyanyl,
            [UnitDefNames["air_copter_aerosol_wanderlost"].id] = AerosolTypes.wanderlost,
            [UnitDefNames["air_copter_aerosol_tollwutox"].id] = AerosolTypes.tollwutox,
            [UnitDefNames["air_copter_aerosol_depressol"].id] = AerosolTypes.depressol
        }
    end
	
    function isNearCityCenter(x,z, GameConfig)
        if not x or not GG.innerCityCenter or not GG.innerCityCenter.x then return false, math.huge, math.huge end
        distanceToCityCenter = distance(x, 0, z, GG.innerCityCenter.x, 0,  GG.innerCityCenter.z) 
        return distanceToCityCenter < GameConfig.innerCitySize, distanceToCityCenter, distanceToCityCenter/GameConfig.innerCitySize
    end

    function getDeterministicRotationOffsetForDistrict(districtID, cultureDeviation, xDiv1000, zDiv1000)
	    if not GG.DistrictRotationDeterministic then GG.DistrictRotationDeterministic = {} end
        x,z = math.ceil(xDiv1000/10) , math.ceil(zDiv1000/10)
        if not GG.DistrictRotationDeterministic[x] then GG.DistrictRotationDeterministic[x] = {} end
        if not GG.DistrictRotationDeterministic[x][z] then GG.DistrictRotationDeterministic[x][z] = {} end	
        if not GG.DistrictRotationDeterministic[x][z][districtID] then GG.DistrictRotationDeterministic[x][z][districtID]  = math.random(0,9)*45 end
        return GG.DistrictRotationDeterministic[x][z][districtID] + math.random(0,cultureDeviation)* randSign()
    end

    function getCultureHash()
        return  stringToHash(getCultureName())
    end

    function getMapNameHash(Game)
       return stringToHash(Game.mapName)
    end

    function getCultureMapNameHash(Game)   
        return getMapNameHash(Game) + getCultureHash()
    end

    function getLocationBuildingHash(x, z, maxs)
        maxs = maxs or 4
        return (((x + z) % maxs) + 1)
    end

    function getBuildingTypeHash(unitID, maxType)
        x, y, z = Spring.GetUnitPosition(unitID)
        x, z = math.ceil(x / 1000), math.ceil(z / 1000)
        nice = getLocationBuildingHash(x,z, maxType)
        return nice, x,y,z
    end

    function getDeterministicCityOfSin(culture, Game)
        mapOverrideSinCity = mapOverideSinCity() 
        if mapOverideSinCity == true then return true end

        chash = getCultureMapNameHash(Game)
        if culture == Cultures.arabic then  --2/10
            return chash % 10 < 2
        end

        if culture == Cultures.western then -- 5/10
            return chash % 10 < 5
        end

        if culture == Cultures.asian then   
            return chash % 10 < 8
        end

        if culture == Cultures.international then   
            return chash % 10 < 10
        end
    end

    function getCultureDependantRandomOffsets(culture, loc)
        districtOffset = getLocationBuildingHash(math.ceil(loc.x / 1000), math.ceil(loc.z / 1000), 4)
          if culture == Cultures.asian then
            rotDegOffset= getDeterministicRotationOffsetForDistrict(getLocationBuildingHash(loc.x,loc.z), 5, math.ceil(loc.x / 1000), math.ceil(loc.z / 1000))
            return {
                xRandOffset = 50,
                zRandOffset = 50,
                districtOffset = districtOffset,
                districtRotationDeg = rotDegOffset
            }
        end
		if culture == Cultures.arabic then
            rotDegOffset= getDeterministicRotationOffsetForDistrict(getLocationBuildingHash(loc.x,loc.z), 5, math.ceil(loc.x / 1000), math.ceil(loc.z / 1000))
            return {
                xRandOffset = 20,
                zRandOffset = 20,
                districtOffset = districtOffset,
                districtRotationDeg = rotDegOffset
            }
        end
        if culture == Cultures.western then  
            --rotDegOffset= getDeterministicRotationOffsetForDistrict(getLocationBuildingHash(loc.x,loc.z), 1, math.ceil(loc.x / 1000), math.ceil(loc.z / 1000))
            return {
                xRandOffset = 3,
                zRandOffset = 3,
                districtOffset = districtOffset,
                districtRotationDeg = 0
            }
        end
          if culture == Cultures.international then  
            --rotDegOffset= getDeterministicRotationOffsetForDistrict(getLocationBuildingHash(loc.x,loc.z), 1, math.ceil(loc.x / 1000), math.ceil(loc.z / 1000))
            return {
                xRandOffset = 3,
                zRandOffset = 3,
                districtOffset = districtOffset,
                districtRotationDeg = 0
            }
        end
    end

    function getWeaponTypeTable(WeaponDefs, StringTable)
        retVal = {}
        for i = 1, #StringTable do
            for defID, def in pairs(WeaponDefs) do
                if def.name == StringTable[i] then
                    retVal[defID] = StringTable[i]
                end
            end
        end
        return retVal
    end

        function getOrbitalTypes(UnitDefs)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            typeTable = {
                "satelliteanti", 
                "satellitescan", 
                "satellitegodrod",
                "satelliteshrapnell"
            }
            return getTypeTable(UnitDefNames, typeTable)
        end    

        function getSatteliteTypes(UnitDefs)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            typeTable = {
                "satelliteanti", "satellitescan", "satellitegodrod"
            }
            return getTypeTable(UnitDefNames, typeTable)
        end  

        function getExemptFromRefundTypes(UnitDefs)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            typeTable = {"satelliteshrapnell"}

            resultTypeTable = mergeTables(getObjectiveTypes(UnitDefs), getTypeTable(UnitDefNames, typeTable))
      
            return resultTypeTable
        end

        function getAutomationPayloadDisabledType(UnitDefs)
             local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = {
                    "truck_arab1",
                    "truck_arab2",
                    "truck_arab3",
                    "truck_arab4",
                    "truck_arab5",
                    "truck_arab6",
                    "truck_arab7",
                    "ground_walker_mg",
                    "ground_walker_grenade",
                    "ground_turret_ssied",
                    "ground_turret_dronegrenade",
                    "ground_turret_mg",
                    "objective_powerplant"
                }
                return mergeTables(getTypeTable(UnitDefNames, typeTable),  getCivilianTypeTable(UnitDefs))
        end


      function getAutomationPayloadDestroyedType(UnitDefs)
             local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = {
                    "propagandaserver",
                    "protagonassembly",
                    "antagonassembly",
                    "objective_airport",
                    "ground_turret_cm_airstrike",
                    "ground_turret_cm_transport",
                    "ground_turret_cm_antiarmor",
                    "ground_turret_cm_airtransport",
                    "air_copter_ssied",
                    "air_plane_sniper",
                    "air_plane_rocket",
                    "air_copter_mg",
                    "air_copter_mg",
                }
                return getTypeTable(UnitDefNames, typeTable)
        end

        function getStunnedInBlackOutUnitTypes(UnitDefs)
                typeTable = {    
                    "ground_turret_ssied",       
                    "ground_turret_mg",       
                    "ground_turret_sniper",       
                    "ground_walker_mg",       
                    "ground_walker_grenade",       
                    "air_copter_antiarmor",       
                    "air_copter_scoutlett",
                }
            return getTypeTable( getUnitDefNames(UnitDefs), typeTable)
        end


        function getMilitarySpawnExitTypes(UnitDefs)
                typeTable = {           
                    
                    "objective_westhemhq"  ,
                    "objective_combatoutpost" ,
                    "objective_pumpstation"

                }
            return getTypeTable( getUnitDefNames(UnitDefs), typeTable)
        end

        function getRefugeeSpawnExitTypes(Unitdefs)
                typeTable = {           
                    "objective_refugeecamp"  ,
                    "objective_transrapid"

                }
            return getTypeTable( getUnitDefNames(UnitDefs), typeTable)
        end

        function getInterceptableAirDroneTypes(UnitDefs)
                typeTable = {           
                    "air_copter_ssied",
                    "air_copter_mg",
                    "air_parachut_dropdrone",
                    "air_copter_scoutlett",
                    "air_copter_antiarmor"
                }
            return getTypeTable( getUnitDefNames(UnitDefs), typeTable)
        end

        function getRocketTransportableTypes(UnitDefs)
             local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = {
                    "operativeasset",
                    "operativepropagator",
                    "operativeinvestigator",
                    "ground_walker_mg",
                    "ground_walker_grenade",
                    "ground_turret_ssied",
                    "ground_turret_dronegrenade",
                    "ground_turret_mg",
                    "air_copter_ssied",
                    "physicspayload",
                    "biopayload",
                    "informationpayload",
                    "potemkinpayload"
                }
                return getTypeTable(UnitDefNames, typeTable)
        end

        function getMotorBikeLoadableTypes(UnitDefs)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)

            typeTable = {
                "operativeasset",
                "operativepropagator",
                "operativeinvestigator"
            }
            return getTypeTable(UnitDefNames, typeTable)
        end

        function getMotorBikeTypeTable(UnitDefs)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)

            typeTable = {
                "truck_arab9",
                "truck_western4"
            }
            return getTypeTable(UnitDefNames, typeTable)
        end

        function getLoadAbleTruckTypes(UnitDefs, culture)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            if culture == Cultures.arabic  then
                typeTable = {
                    "truck_arab6",
                    "truck_arab7",
                    "truck_arab8"
                }

                return getTypeTable(UnitDefNames, typeTable)
            end

            if culture == Cultures.international then
                    return mergeDictionarys(
                        getLoadAbleTruckTypes(UnitDefs, Cultures.arabic),
                        getLoadAbleTruckTypes(UnitDefs, Cultures.western),                        
                        getLoadAbleTruckTypes(UnitDefs, Cultures.asian))
            end

            return {}
        end

        function getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, culture)
            assert(UnitDefs)
                    typeTable = {
                    "truck_arab1",
                    "truck_arab2",
                    "truck_arab3",
                    "truck_arab4",
                    "truck_arab5",
                    "truck_arab6",
                    "truck_arab7"
                }
                arabicTruckTypeTable = getTypeTable(UnitDefNames, typeTable)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            if culture == Cultures.arabic then
                return arabicTruckTypeTable
            end

            if culture == Cultures.international then
                    return mergeDictionarys(
                        arabicTruckTypeTable,
                        getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.western),                        
                        getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.asian))
            end

            if culture == Cultures.asian then
                return mergeDictionarys(arabicTruckTypeTable,
                   getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.asian))
            end
            if culture == Cultures.western then
                return mergeDictionarys(arabicTruckTypeTable,
                   getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.western))
            end

            return {}
        end

        function getRuralAreaFeatureUnitsNameTable(culture, housesNearby)
            if culture == Cultures.arabic then
                if housesNearby < 2 then
                    return {"tree_arab0", "tree_arab1", "greenhouse"}
                else
                    return {"tree_arab0", "tree_arab1"}
                end
            end

            if culture == Cultures.western then
                return   getRuralAreaFeatureUnitsNameTable(UnitDefs, TruckTypeTable, Cultures.western)
            end

            if culture == Cultures.asian then
                return   getRuralAreaFeatureUnitsNameTable(UnitDefs, TruckTypeTable, Cultures.asian)
            end

            if culture == Cultures.international then
                return mergeTables(
                    getRuralAreaFeatureUnitsNameTable( Cultures.arabic, housesNearby),
                    getRuralAreaFeatureUnitsNameTable( Cultures.western, housesNearby),
                    getRuralAreaFeatureUnitsNameTable( Cultures.asian, housesNearby))
            end

            return {}
        end

        --TODO Rewrite to make international all encompassing
        function getTranslation(cultureName)

            translation = {
                ["arabic"] = {
                    ["house"] = {name = "house_arab", range = 0},
                    ["civilian"] = {name = "civilian_arab", range = 4},
                    ["truck"] = {name = "truck_arab", range = 9}},
                ["western"] = {
                    ["house"] = {name = "house_western", range = 0},
                    ["civilian"] = {name = "civilian_western", range = 2},
                    ["truck"] = {name = "truck_western", range = 4}},        
                ["asian"] = {
                    ["house"] = {name = "house_asian", range = 1},
                    ["civilian"] = {name = "civilian_arab", range = 4},
                    ["truck"] = {name = "truck_western", range = 4}}
                }
                assert(translation[cultureName], "no translation for "..cultureName)
                return translation[cultureName]
            end

            function getCultureUnitModelTypes(cultureName, typeName, UnitDefs)
                UnitDefNames = getUnitDefNames(UnitDefs)
                allNames = getCultureUnitModelNames_Dict_DefIDName(cultureName, typeName, UnitDefs)
                result = {}

                for num, name in pairs(allNames) do
                    result[UnitDefNames[name].id] = UnitDefNames[name].id
                end

                return result
            end

            function getHouseTypeLimitations(UnitDefs)
                UnitDefNames = getUnitDefNames(UnitDefs)
                LimitedHouseTypes = {
                    [UnitDefNames["house_asian1"].id] = 10
                }
                return LimitedHouseTypes
            end

            function getWesternUnitTypeMap(typeName, UnitDefs)
                return getCultureUnitModelTypes("western", typeName, UnitDefs)
            end

            function getCultureUnitModelNames_Dict_DefIDName(cultureName, typeName, UnitDefs)
                if cultureName == nil then 
                    cultureName = getCultureName()
                    assert(cultureName)
                end

                local translation = {}
                if cultureName == Cultures.international then
                    translationWestern = getTranslation(Cultures.western)                    
                    translationArabic = getTranslation(Cultures.arabic)
                    translationAsian = getTranslation(Cultures.asian)

                    --translationAsian = getTranslation(Cultures.asian)
                    DicAsianNameDefID = expandNameSubSet_Dict_NameDefID(translationAsian[typeName], UnitDefs)
                    assertNameTypeInTable(DicAsianNameDefID, typeName == "house" , "house_asian0")
                    assertNameTypeInTable(DicAsianNameDefID, typeName == "house" , "house_asian1")

                    DicWesternNameDefID = expandNameSubSet_Dict_NameDefID(translationWestern[typeName], UnitDefs)
                    assertNameTypeInTable(DicWesternNameDefID, typeName == "civilian" , "civilian_western0")
  

                    DictArabNameDefID = expandNameSubSet_Dict_NameDefID(translationArabic[typeName], UnitDefs)
                    assertNameTypeInTable(DictArabNameDefID, typeName == "civilian" , "civilian_arab0")            

                    local fullTable = {}
                    for name,defID in pairs(DicAsianNameDefID) do                       
                        fullTable[defID]= name
                    end
                    for name,defID in pairs(DicWesternNameDefID) do
                        fullTable[defID]= name
                    end
                     for name,defID in  pairs(DictArabNameDefID) do
                        fullTable[defID]= name
                    end
                    return fullTable--, translationAsian
                else
                    assert(cultureName)
                    translation = getTranslation(cultureName)
                    assert(translation , "No translation for "..typeName.." in culture "..cultureName)
                    assert(translation[typeName] ~= nil , "No translation for "..typeName.." in culture "..cultureName)

                    DictDefIDNames = expandNameSubSet_Dict_NameDefID(translation[typeName], UnitDefs)
                    --assert(count(expandedNamesTable) > 0, typeName .." --> ".. cultureName)
                    local fullTable = {}
                    for name,defID in pairs(DictDefIDNames) do
                        fullTable[defID] = name
                    end
                    return fullTable
                end            
            end

            function getRPGCarryingCivilianTypes(UnitDefs, culture)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                local culturename = culture or getCultureName()
                if culturename == Cultures.arabic then
                    typeTable = {
                        "civilian_arab0", "civilian_arab2"
                    }

                    return getTypeTable(UnitDefNames, typeTable)
                end
                
                if culturename == Cultures.western then
                        typeTable = {
                            "civilian_western0"
                        }

                    return getTypeTable(UnitDefNames, typeTable)
                end

                if culturename == Cultures.international or culturename == Cultures.asian then
                   return mergeTables(
                        getRPGCarryingCivilianTypes(UnitDefs, Cultures.arabic),
                        getRPGCarryingCivilianTypes(UnitDefs, Cultures.western)
                        )
                end
            end


            function getTypeUnitNameTable(culturename, typeDesignation, UnitDefs)
                assert(UnitDefs)
                defID_Name_Map = {}
                if culturename == Cultures.international then
                    defID_Name_Map = mergeDictionarys(
                        getCultureUnitModelNames_Dict_DefIDName(Cultures.arabic, typeDesignation, UnitDefs),
                        getCultureUnitModelNames_Dict_DefIDName(Cultures.western, typeDesignation, UnitDefs),
                        getCultureUnitModelNames_Dict_DefIDName(Cultures.asian, typeDesignation, UnitDefs)
                        )
                    --echo(getCultureUnitModelNames_Dict_DefIDName(Cultures.arabic, typeDesignation, UnitDefs))
                    --echo(getCultureUnitModelNames_Dict_DefIDName(Cultures.western, typeDesignation, UnitDefs))
                    --echo(getCultureUnitModelNames_Dict_DefIDName(Cultures.asian, typeDesignation, UnitDefs))
                    --echo("getTypeUnitNameTable:")
                    --echo(nr_ID_Map)
                else
                    defID_Name_Map = getCultureUnitModelNames_Dict_DefIDName(culturename, typeDesignation, UnitDefs)
                end

                results = {}
                for DefID,name in pairs(defID_Name_Map) do 
                    results[#results +1 ] = name
                end

                return results
            end

            function expandNameSubSet_Dict_NameDefID(SubsetTable, UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)

                local expandedDictNameID = {}
                local i = 0
                while i <= SubsetTable.range do
                    local key = SubsetTable.name..i
                    if UnitDefNames[key] then
                        --echo("adding "..SubsetTable.name..i)
                        --assert(UnitDefNames[key].id, SubsetTable.name..i)
                        expandedDictNameID[key] = UnitDefNames[key].id
                    end
                    i = i + 1
                end

                return expandedDictNameID
            end

            --TODO do a culture based merge
            function getUnitType_BaseTypeMap(UnitDefs, culture)
                truckTypes = getTypeUnitNameTable(culture, "truck", UnitDefs)
                houseTypes = getTypeUnitNameTable(culture, "house", UnitDefs)
                civilianTypes = getTypeUnitNameTable(culture, "civilian", UnitDefs)
                results = {}

                -- echo("trucktypes:",truckTypes)
                for num, name in pairs(truckTypes) do results[name] = "truck" end

                for num, name in pairs(houseTypes) do results[name] = "house" end

                for num, name in pairs(civilianTypes) do results[name] = "civilian" end

                return results
            end

            function getBaseTypeName(name)
                if name:match("house") then return "house" end
                if name:match("civilian") then return "civilian" end
                if name:match("truck") then return "truck" end

            end

            function getRaidStates()
                return {
                    ["Aborted"] = 0,
                    ["OnGoing"] = 1,
                    ["WaitingForUplink"] = 2,
                    ["UplinkCompleted"] = 3,
                    ["VictoryStateSet"] = 4
                }
            end

            function getRaidResultStates()
                return {
                    ["Unknown"] = 10,
                    ["DefenderWins"] = 11,
                    ["AggressorWins"] = 12,
                    ["HouseEmpty"] = 13,
                }
            end

            function getTruckLoadOutTypeTable()
                mapping = {

                    ["civilian_truck_mg"] = "ground_turret_mg",
                    ["civilian_truck_ssied"] = "ground_turret_ssied",
                    ["civilian_truck_mortar"] = "ground_turret_mortar",

                    ["ground_truck_mg"] = "ground_turret_mg",                   
                    ["ground_truck_mortar"] = "ground_turret_mortar",
                    ["ground_truck_ssied"] = "ground_turret_ssied",
                    ["ground_truck_antiarmor"] = "ground_turret_antiarmor",
                    ["ground_truck_rocket"] = "ground_turret_rocket"

                }
                typeDefMappingTable = {}

                for k, v in pairs(mapping) do
                    if UnitDefNames[v] and UnitDefNames[k] then
                        typeDefMappingTable[UnitDefNames[k].id] = UnitDefNames[v].id
                    else
                        if not UnitDefNames[v] then
                            echo("getTruckLoadOutTypeTable " .. v .. " is undefined")
                        end
                        if not UnitDefNames[k] then
                            echo("getTruckLoadOutTypeTable " .. k .. " is undefined")
                        end
                    end
                end

                return typeDefMappingTable
            end

            function assingCivilianTruckRegistration(unitID, Game, culture)
                idhash = unitID % 24
                hash = getDetermenisticMapHash(Game)
                country = getCountryByCulture(culture, hash + math.random(0,1)*randSign())
                nrLetters = (hashString(country) % 3) + 1 
                CityOrigin = string.upper(string.char(65 +idhash))
                plate = "Plate: "..string.upper(country:sub(1,nrLetters))..":"..CityOrigin..unitID.." <vehicle>"
                Spring.SetUnitTooltip(unitID,plate)
                return plate
            end


            function getTruckTypeTable(UnitDefs)
                return getCultureUnitModelTypes(GG.GameConfig.instance.culture or getCultureName(), "truck", UnitDefs)
            end

            function getNotTruckLoadableTypeTable(UnitDefs)

                return mergeTables(getTruckTypeTable(UnitDefs))

            end

            function getOperatorSex(UnitDefs, defID)
                local name = UnitDefs[defID].name

                if name == "operativepropagator" then
                    return "male"
                end

                if name == "operativeinvestigator" then
                    return "female"
                end

                if name == "operativeassset" then
                    return "male"
                end

                if math.random(0, 1) == 1 then
                    return "male"
                else
                    return "female"
                end
            end

            function isTrackedPerson(id)
                if doesUnitExistAlive(id) then
                    return GG.TrackedPersons and GG.TrackedPersons[id]
                end
            end

        function isMapNameRainyOverride(mapName)
            mapName = string.lower(mapName)
            ManualBuildingPlacement = {        
                ["mosaic_lastdayofdubai_v"] = true
            }

              for name, value in pairs(ManualBuildingPlacement)do
                if string.find(mapName, name ) then return true end
            end
            return false

        end
            function isRaining(hour)
                if GG.boolRainyArea == nil then
                    GG.boolRainyArea = getDetermenisticHash() % 2 == 0  or isMapNameRainyOverride(Game.mapName) 
                  --  GG.boolRainyArea = true
                  --  echo("DELME Debug Setting override isRaining()")
                    echo("Is a Rainy area: "..toString( GG.boolRainyArea))             
                end
                if not GG.boolRainyArea then return false end

                 if not GG.RainDirection then
                        GG.RainDirection = {
                                         x = math.random(1,15) * randSign(),
                                         z = math.random(1,15) * randSign()
                                         }
                end

                if not hour then hour = getDayTime() end
                dayLengthFrames = GG.GameConfig.daylength
                frames = Spring.GetGameFrame()

                dayNr = frames/ dayLengthFrames

                return dayNr % 3 < 1.0 and (hours > 18 or hours < 7)
            end

            function isANormalDay()
                --DEBUG DELME
                --echo("DELME Debug Setting override isANormalDay()")
                --if true then return true end
                return GG.GlobalGameState == GG.GameConfig.GameState.normal
            end


            function getCivlianDisguiseBySexTypeTable(UnitDefs, sex)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {}

                if GameConfig.instance.culture == "arabic" then
                    if sex == "male" then
                        typeTable = {
                            "civilian_arab1",
                            "civilian_arab2"
                        }
                    else
                        typeTable = {
                            "civilian_arab0",
                            "civilian_arab3"
                        }
                    end
                end

                if GameConfig.instance.culture == "western" then
                    if sex == "male" then
                        typeTable = {
                            "civilian_western0"
                        }
                    else
                        typeTable = {
                          "civilian_western1",
                          "civilian_western2"
                        }
                    end
                end        

                if GameConfig.instance.culture == "international" then  
                    if sex == "male" then
                        typeTable = {
                            "civilian_arab1",
                            "civilian_arab2",
                            "civilian_western0"
                        }
                    else
                        typeTable = {
                            "civilian_arab0",
                            "civilian_arab3",
                            "civilian_western1",
                            "civilian_western2"
                        }
                    end

                end      
                if GameConfig.instance.culture == "asian" then  
                    if sex == "male" then
                        typeTable = {
                            "civilian_arab1",
                            "civilian_arab2",
                            "civilian_western0"
                        }
                    else
                        typeTable = {
                            "civilian_arab0",
                            "civilian_arab3",
                            "civilian_western1",
                            "civilian_western2"
                        }
                    end

                end      

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getWildLifeTypes(UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                return {
                    [UnitDefNames["gullswarm"].id] = "air",
                    [UnitDefNames["ravenswarm"].id] = "air"
                }            
            end

            function getMobileCivilianDefIDTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = getTypeUnitNameTable(GameConfig.instance.culture, "truck",
                UnitDefs)
                typeTable = mergeTables(typeTable, getTypeUnitNameTable(
                    GameConfig.instance.culture, "civilian",
                UnitDefs))

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getPanicableCiviliansTypeTable(UnitDefs)
                assert(UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = {}
                typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(),
                "civilian", UnitDefs))

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getCloakIconTypes(UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "antagonsafehouse",
                    "protagonsafehouse",
                    "propagandaserver",
                    "protagonassembly",
                    "antagonassembly",
                    "hivemind",
                    "launcher",
                    "launcherstep",
                    "warheadfactory",
                    "nimrod",
                    "operativepropagator",
                    "operativeinvestigator",
                    "operativeasset",
                    "blacksite",
                    "doubleagent"
                }

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getSafeHouseUpgradeTypeTable(UnitDefs, myDefID)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {}
                if not myDefID then
                    typeTable = {"nimrod", "propagandaserver", "protagonassembly",  "warheadfactory"}

                else

                    if myDefID == UnitDefNames["antagonsafehouse"].id then
                        typeTable = {
                            "nimrod", "propagandaserver", "antagonassembly", "launcher", "hivemind", "warheadfactory", "blacksite"
                        }
                    else
                        typeTable = {
                            "nimrod", "propagandaserver", "protagonassembly", "aicore"
                        }
                    end
                end

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getSafeHouseTypeTable(UnitDefs)

                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {"protagonsafehouse", "antagonsafehouse"}

                return getTypeTable(UnitDefNames, typeTable)
            end

            function 
                getInterrogateAbleTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                operatorTypeTable = {
                    "civilianagent", "operativeasset", "operativepropagator",
                    "operativeinvestigator", "antagonsafehouse", "protagonsafehouse",
                    "propagandaserver", "protagonassembly", "antagonassembly", "launcher", "hivemind", "aicore"
                }
                assert(GameConfig.instance.culture)
                typeTable = mergeTables(operatorTypeTable, getTypeUnitNameTable(
                    GameConfig.instance.culture, "civilian",
                UnitDefs))
                UnitDefNames = getUnitDefNames(UnitDefs)
                resultTypeTable = getTypeTable(UnitDefNames, typeTable)
                assert(resultTypeTable[UnitDefNames["operativeinvestigator"].id])
                return resultTypeTable
            end

            function getMobileInterrogateAbleTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                InterrogatableOperativeNamesTypeTable = {
                    "civilianagent", "operativeasset", "operativepropagator",
                    "operativeinvestigator"
                }

                civilianTypeNamesTable = getTypeUnitNameTable( GameConfig.instance.culture, "civilian", UnitDefs)
                assert(count(civilianTypeNamesTable)> 0)
                --echo(civilianTypeNamesTable)
                interrogationNamesTable = mergeTables(InterrogatableOperativeNamesTypeTable, civilianTypeNamesTable )  
                
                resultTypeTable = getTypeTable(UnitDefNames, interrogationNamesTable)
                assert(resultTypeTable[UnitDefNames["operativeinvestigator"].id])
                if GG.GameConfig.instance.culture == Cultures.arabic then
                    assert(resultTypeTable[UnitDefNames["civilian_arab0"].id])
                end
                return resultTypeTable
            end

            function getRaidIconTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {"icon_raid", "snipeicon", "objectiveicon","raidiconbaseplate"}

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getRaidAbleTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "antagonsafehouse",
                    "protagonsafehouse",
                    "nimrod", 
                    "propagandaserver", 
                    "protagonassembly", 
                    "antagonassembly", 
                    "launcher", 
                    "hivemind", 
                    "warheadfactory"
                }

                typeTable = mergeTables(typeTable, getTypeUnitNameTable(
                    GameConfig.instance.culture, "house",
                UnitDefs))

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getHouseTypeTable(UnitDefs, culturename)
                assert(UnitDefs)
                return getCultureUnitModelNames_Dict_DefIDName(culturename, "house", UnitDefs)
            end

            function getClimbableHouseTypeTable(UnitDefs)

                UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "house_western0", "house_arab0"
                }

                return getTypeTable(UnitDefNames, typeTable)
            end


            function getOperativeTypeTable(UnitDefs)

                UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "civilianagent", 
                    "operativeasset", 
                    "operativepropagator",
                    "operativeinvestigator"
                }

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getAnimalTypeNumbers(UnitDefs)
                UnitDefNames = getUnitDefNames(UnitDefs)
                return {
         --           [UnitDefNames["birdswarm"].id] = 3
                }
            end

            function getAnimalTypeTables(UnitDefs)
                UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                            "gullswarm",
                            "raveswarm"
                            }

                return getTypeTable(UnitDefNames, typeTable)
            
            end

            function getDefusalCapableTypeTable(UnitDefs)

                UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                            "civilianagent", "operativeasset", "operativepropagator", "operativeinvestigator"
                             }

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getStreetDecorationTypeTable(UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "tree_arab0",
                    "tree_arab1",
                    "innercitydeco_inter1",
                    "innercitydeco_inter2",
                    "innercitydeco_inter3",
                    "innercitydeco_arab",
                    "innercitydeco_western",
                    "innercitydeco_arab",

                }

                return getTypeTable(UnitDefNames, typeTable)
            end

            function setMaxHeightPosition(unitID)
                window = 2048 / 2
                x, _, z = (Game.mapSizeX / 100) * math.random(10, 90), 0, (Game.mapSizeZ / 100) * math.random(10, 90)
                mins, maxs = getExtremasInArea(math.max(0, x - window), math.max(0, z - window), x + window, z + window, 128)
                Spring.MoveCtrl.Enable(unitID, true)
                Spring.MoveCtrl.SetPosition(unitID, maxs.x, Spring.GetGroundHeight(maxs.x, maxs.z), maxs.z)
                Spring.MoveCtrl.Enable(unitID, false)
            end

            function createSetMaxHeight(defID, team)
                id = Spring.CreateUnit(defID, 1, 1, 1, 1, team)
                setMaxHeightPosition(id)
            end

            function getMonumentAmountDecorationTypeTable(UnitDefs, culture)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                if culture == "arabic" then
                    return {
                    [UnitDefNames["innercitydeco_inter4"].id] = {maxNr = 1, locationFunc = createSetMaxHeight}

                        }
                end

                if culture == "international" then
                    return {
                    [UnitDefNames["innercitydeco_inter4"].id] = {maxNr = 2, locationFunc = createSetMaxHeight}}
                end

                return {}
            end

            function getCivilianTypeTable(UnitDefs)
                assert(UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                GameConfig = getGameConfig()
                typeTable = getTypeUnitNameTable(GameConfig.instance.culture, "truck",
                UnitDefs)
                typeTable = mergeTables(typeTable, getTypeUnitNameTable(
                GameConfig.instance.culture, "house", UnitDefs))
                typeTable = mergeTables(typeTable, getTypeUnitNameTable(
                    GameConfig.instance.culture, "civilian",
                UnitDefs))

                local retTable = {}
                for _, defs in pairs(UnitDefs) do
                    for num, k in pairs(typeTable) do

                        if defs.name == k then retTable[k] = defs.id end

                    end
                end

                return getTypeTable(UnitDefNames, typeTable), retTable
            end

            function getAersolAffectableUnits(UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)

                typeTable = mergeTables({}, getTypeUnitNameTable(getCultureName(), "truck",
                UnitDefs))
                typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(),
                "civilian", UnitDefs))

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getAllLetters(TableOfPiecesGroups)
                local result = {}
                local allLetters = "ABCDEFGHIKLMNOPQRSTUVXYZ"
                for i=1, string.len(allLetters) do
                    local letter = string.sub(allLetters, i, i)
                    if TableOfPiecesGroups[letter] then
                        result[letter] = TableOfPiecesGroups[letter]
                    end
                end
                return result
            end

            function genericCallUnitFunctionPassArgs(unitID, NameOfFunction, arg)
                env = Spring.UnitScript.GetScriptEnv(unitID)
                if env and env[NameOfFunction] then
                    Spring.UnitScript.CallAsUnit(unitID, env[NameOfFunction], arg)
                    return true
                end
                return false
            end


            function setAerosolCivilianBehaviour(unitID, TypeOfBehaviour)
                env = Spring.UnitScript.GetScriptEnv(unitID)
                if env and env.startAerosolBehaviour then
                    Spring.UnitScript.CallAsUnit(unitID,
                        env.startAerosolBehaviour,
                    TypeOfBehaviour)
                    return true
                end
                return false
            end

            function setAssemblyProducedUnitsToTeam(assemblyID, teamToTurnOverID)
                env = Spring.UnitScript.GetScriptEnv(assemblyID)
                if env and env.TurnProducedUnitsOverToTeam then
                    Spring.UnitScript.CallAsUnit(assemblyID,
                        env.TurnProducedUnitsOverToTeam,
                    teamToTurnOverID)
                    return true
                end
                return false
            end

            function getCivilianAnimationStates()
                return {
                    -- Upper Body States
                    fighting = "STATE_FIGHTING", 
                    slaved = "STATE_SLAVED", -- do nothing
                    idle = "STATE_IDLE",
                    filming = "STATE_FILMING",
                    phone = "STATE_PHONE",
                    wailing = "STATE_WAILING",
                    talking = "STATE_TALKING",
                    handsup = "STATE_HANDSUP",
                    protest = "STATE_PROTEST",

                    --coupled cycles
                    standing = "STATE_STANDING",
                    aiming = "STATE_AIMING",
                    hit = "STATE_HIT",
                    death = "STATE_DEATH",
                    transported = "STATE_TRANSPORTED",
                    catatonic = "STATE_CATATONIC",
                    -- self ending Cycles
                    trolley = "STATE_PULL",
                    walking = "STATE_WALKING",
                    running = "STATE_RUNNING",
                    coverwalk = "STATE_COVERWALK",
                    wounded = "STATE_WOUNDED",
                    riding = "STATE_RIDING"
                }

            end
            framesPerSecond = 30

            function getSatelliteTimeOutTable(UnitDefs) -- per Frame
                local UnitDefNames = getUnitDefNames(UnitDefs)

                valuetable = {
                    [UnitDefNames["satelliteanti"].id] = 2 * 90 * framesPerSecond,
                    [UnitDefNames["satellitegodrod"].id] = 3 * 90 * framesPerSecond,
                    [UnitDefNames["satellitescan"].id] = 90 * framesPerSecond,
                    [UnitDefNames["satelliteshrapnell"].id] = 1
                }

                return valuetable
            end

            function getSatelliteTypesSpeedTable(UnitDefs) -- per Frame
                local UnitDefNames = getUnitDefNames(UnitDefs)

                valuetable = {
                    [UnitDefNames["satellitegodrod"].id] = 30 / framesPerSecond,
                    [UnitDefNames["satelliteanti"].id] = 30 / framesPerSecond,
                    [UnitDefNames["satellitescan"].id] = 90 / framesPerSecond,
                    [UnitDefNames["satelliteshrapnell"].id] = 120 / framesPerSecond
                }

                return valuetable
            end

            function getSatelliteAltitudeTable(UnitDefs) -- per Frame
                local UnitDefNames = getUnitDefNames(UnitDefs)

                valuetable = {
                    [UnitDefNames["satellitegodrod"].id] = 1450,
                    [UnitDefNames["satelliteanti"].id] = 1550,
                    [UnitDefNames["satellitescan"].id] = 1500,
                    [UnitDefNames["satelliteshrapnell"].id] = 1500
                }

                return valuetable
            end

            function getInternationalCityDecorationTypes(UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)
                return {
                    [UnitDefNames["innercitydeco_inter1"].id] = true,
                    [UnitDefNames["innercitydeco_inter2"].id] = true,
                    [UnitDefNames["innercitydeco_inter3"].id] = true,
                    --[UnitDefNames["innercitydeco_arab"].id] = true,
                    --[UnitDefNames["innercitydeco_western"].id] = true,
                    --[UnitDefNames["innercitydeco_asian"].id] = true,
                }
            end

            function getUnitScaleTable(UnitDefNames)
                local defaultScaleTable = {}
                realScaleTable = {
                    ["house"] = 1.0,
                    ["antagonsafehouse"] = 1.0,
                    ["protagonsafehouse"] = 1.0,
                    ["nimrod"] = 1.0,
                    ["assembly"] = 1.0,
                    ["propagandaserver"] = 1.0,
                    ["launcher"] = 1.0,
                    ["ground_truck_mg"] = 1.0,
                    ["ground_turret_mg"] = 1.0
                }

                for name, v in pairs(UnitDefNames) do
                    factor = 0.3
                    if realScaleTable[name] then factor = realScaleTable[name] end
                    defaultScaleTable[v.id] = {realScale = factor, tacticalScale = 1.0}
                end

                return defaultScaleTable
            end

            function unitCanBuild(unitDefID)

                if unitDefID and UnitDefs[unitDefID] then
                    return UnitDefs[unitDefID].buildOptions
                end
                return {}
            end

            function getUnitDefIDFro3MName(name)
                for i = 1, #UnitDefs do
                    if name == UnitDefs[i].name then return UnitDefs[i].id end
                end

            end

            function getGroundTurretMGInterceptableProjectileTypes(WeaponDefs)
                TypeTable = {
                    "smartminedrone",
                    "cm_airstrike",
                    "cm_transport",
                    "cm_antiarmor",
                    "cm_airtransport",
                    }
                return getWeaponTypeTable(WeaponDefs, TypeTable)
            end 

            function getCruiseMissileProjectileTypes(WeaponDefs)
                TypeTable = {
                    "cm_airstrike",
                    "cm_transport",
                    "cm_antiarmor",
                    "cm_airtransport",
                }
                return getWeaponTypeTable(WeaponDefs, TypeTable)
            end

            -- computates a map of all unittypes buildable by a unit (detects loops)
            -- > getUnitBuildAbleMap
            function getUnitCanBuildList(unitDefID, closedTableExtern, root)
                if not unitDefID then return {} end
                if not root then root = true end
                Result = {}
                assert(type(unitDefID) == "number")
                boolCanBuildSomething = false

                local openTable = unitCanBuild(unitDefID) or {}
                if lib_boolDebug == true then
                    assert(UnitDefs)
                    assert(unitDefID)
                    assert(UnitDefs[unitDefID], unitDefID)
                    assert(UnitDefs[unitDefID].name)
                end
                closedTable = closedTableExtern or {}
                local CanBuildList = unitCanBuild(unitDefID)
                closedTable[unitDefID] = true
                assert(CanBuildList)
                for num, unitName in pairs(CanBuildList) do
                    defID = getUnitDefIDFro3MName(unitName)
                    boolCanBuildSomething = true

                    if defID and not closedTable[defID] then
                        Result[defID] = defID

                        unitsToIntegrate, closedTable =
                        getUnitCanBuildList(defID, closedTable, false)
                        if unitsToIntegrate then
                            for id, _ in pairs(unitsToIntegrate) do

                                if lib_boolDebug == true then
                                    --Spring.Echo("+ " .. UnitDefs[id].name)
                                end

                                Result[id] = id
                            end
                        end
                    end
                end
                if boolCanBuildSometing == true then
                    if root == true then
                        --Spring.Echo("Unit " .. UnitDefs[unitDefID].name .. " can built:")
                    end
                end

                return Result, closedTable
            end

            ProtagonUnitTypeList = getUnitCanBuildList(UnitDefNames["protagonsafehouse"].id)
            AntagonUnitTypeList = getUnitCanBuildList(UnitDefNames["antagonsafehouse"].id)

            function getUnitSideString(unitID)
                defID = Spring.GetUnitDefID(unitID)
                if ProtagonUnitTypeList[defID] then return "protagon" end
                if AntagonUnitTypeList[defID] then return "antagon" end
                return "protagon"
            end

             function getTeamSideString(teamID)
                teamID, leader, isDead, isAiTeam, side, allyTeam, incomeMultiplier = Spring.GetTeamInfo(teamID)
                return side
            end

            function getDecalMap(culture)
                if culture == "arabic" then
                    return {
                        ["house"] = {
                            rural = {
                                "house_arab_decal8", "house_arab_decal7",
                                "house_arab_decal4", "house_arab_decal10",
                                "house_arab_decal11", "house_arab_decal12",
                                "house_arab_decal13", "house_arab_decal14",
                                "house_arab_decal15", "house_arab_decal18"
                            },
                            urban = {
                                "house_arab_decal1", "house_arab_decal2",
                                "house_arab_decal3", "house_arab_decal5",
                                "house_arab_decal6", "house_arab_decal9",
                                "house_arab_decal16", "house_arab_decal17",
                                "house_arab_decal19"
                            }}}
                end

                if culture == "western" then
                    return {
                        ["house"] = {
                            rural = {
                                "house_western_decal3",
                                "house_western_decal4", 
                                "house_western_decal9",
                                "house_western_decal11",
                                "house_western_decal10",
                            },
                            urban = {
                                "house_western_decal1",
                                "house_western_decal2",
                                "house_western_decal5",
                                "house_western_decal6",
                                "house_western_decal7",
                                "house_western_decal8",
                                "house_western_decal9",
                                "house_western_decal10",
                                "house_western_decal12",
                                "house_western_decal13",
                                "house_western_decal14",
                                "house_western_decal15",   
                                                   
                            }}}
                end
            
                if culture == "international" then
                    return {
                        ["house"] = {
                            rural = {
                                "house_western_decal9",
                                "house_western_decal11",
                                "house_western_decal3",
                                "house_western_decal4",  
                                "house_western_decal10",
                            },
                            urban = {
                                "house_western_decal1",
                                "house_western_decal2",
                                "house_western_decal5",
                                "house_western_decal6",
                                "house_western_decal7",
                                "house_western_decal8",
                                "house_western_decal14",
                                "house_western_decal12",
                                "house_western_decal13",
                                "house_western_decal10",                           
                                "house_western_decal15",   
                                "house_western_decal9", 
                                "house_arab_decal1", 
                                "house_arab_decal2",
                                "house_arab_decal3", 
                                "house_arab_decal5",
                                "house_arab_decal6", 
                                "house_arab_decal9",
                                "house_arab_decal16", 
                                "house_arab_decal17",
                                "house_arab_decal19"                       
                            }}
                            }
                end
				
				if culture == "asian" then
                    return {
                        ["house"] = {
                        rural = {
                                "house_western_decal9",
                                "house_western_decal11",
                                "house_western_decal3",
                                "house_western_decal4",  
                                "house_western_decal10",
                                "house_western_decal16",
                                "house_arab_decal19" 
                            },
                        urban = {
                                "house_western_decal1",
                                "house_western_decal2",
                                "house_western_decal5",
                                "house_western_decal6",
                                "house_western_decal7",
                                "house_western_decal8",
                                "house_western_decal14",
                                "house_western_decal12",
                                "house_western_decal13",
                                "house_western_decal10",                           
                                "house_western_decal16",   
                                "house_western_decal15",   
                                "house_western_decal9"                
                            }}
                            }
                end

            end
			
			function isNight()
                hours, minutes, seconds, percent = getDayTime()			
				return hours > 19 and hours < 6
			end
			
			

                    function isPrayerTime()
                        hours, minutes, seconds, percent = getDayTime()
                        return GG.GameConfig.instance.culture == Cultures.arabic and equal(percent, 0.25, 0.025) or equal(percent, 0.75, 0.025)
                    end

                    function getDayTime()
                        local DAYLENGTH = GG.GameConfig.daylength
                        morningOffset = (DAYLENGTH / 2)
                        Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
                        percent = Frame / DAYLENGTH
                        hours = math.floor((Frame / DAYLENGTH) * 24)
                        minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
                        seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
                        return hours, minutes, seconds, percent --= getDayTime()
                    end

                    function isRushHour()
                        hours, minutes, seconds, percent = getDayTime()

                        if hours > 6 and hours < 9 or
                            hours > 12 and hours < 14 or
                            hours > 16 and hours < 20 then
                            return true
                        end
                    end

                    -- > Creates a Eventstream Event bound to a Unit
                    function createStreamEvent(unitID, func, framerate, persPack)
                        persPack.unitID = unitID
                        persPack.startFrame = Spring.GetGameFrame() + 1
                        persPack.functionToCall = func
                        -- echo("Creating Stream Event")

                        eventFunction = function(id, frame, persPack)
                            nextFrame = frame + framerate
                            if persPack then
                                if persPack.unitID then
                                    boolDead = Spring.GetUnitIsDead(persPack.unitID)

                                    if boolDead and boolDead == true then
                                        echo("Aborting eventstream cause unit has died")
                                        return nil, nil
                                    end

                                    if not persPack.startFrame then
                                        persPack.startFrame = frame + 1

                                    end

                                    nextFrame = frame + framerate
                                end
                            end

                            boolDoneFor, persPack = persPack.functionToCall(persPack)
                            if boolDoneFor and boolDoneFor == true then
                                --echo("Aborting eventstream cause function signalled completness")
                                return nil
                            end

                            return nextFrame, persPack
                        end

                        GG.EventStream:CreateEvent(eventFunction, persPack,
                        Spring.GetGameFrame() + 1)
                    end

                        -- > Creates a Eventstream Event bound to a Projectile
                    function createStreamEventProjectile(projectileID, func, framerate, persPack)
                        persPack.projectileID = projectileID
                        persPack.startFrame = Spring.GetGameFrame() + 1
                        persPack.functionToCall = func
                        -- echo("Creating Stream Event")

                        eventFunction = function(id, frame, persPack)
                            nextFrame = frame + framerate
                            if persPack then
                                if projectileID then
                                    targetType = Spring.GetProjectileDefID(projectileID)

                                    if not targetType then
                                        --echo("Aborting eventstream cause projectile has died")
                                        return nil, nil
                                    end

                                    if not persPack.startFrame then
                                        persPack.startFrame = frame + 1

                                    end

                                    nextFrame = frame + framerate
                                end
                            end

                            boolDoneFor, persPack = persPack.functionToCall(persPack)
                            if boolDoneFor and boolDoneFor == true then
                           --     echo("Aborting eventstream cause function signalled completness")
                                return nil
                            end

                            return nextFrame, persPack
                        end

                        GG.EventStream:CreateEvent(eventFunction, persPack,
                        Spring.GetGameFrame() + 1)
                    end

                    function attachDoubleAgentToUnit(traitorID, teamToTurnTo, boolRecursive)
                       -- attachingTo = traitorID.." a "..UnitDefs[Spring.GetUnitDefID(traitorID)].name.." of team "..Spring.GetUnitTeam(traitorID).." is now a double agent for team "..teamToTurnTo
                       -- echo(attachingTo)
                        if not GG.DoubleAgents then GG.DoubleAgents = {} end

                        hoverAboveFunc = function(persPack)
                            boolContinue = false
                            boolEndFunction = true

                            --There can only ever be one
                            if GG.DoubleAgents[persPack.traitorID] and
                                GG.DoubleAgents[persPack.traitorID] ~= persPack.iconID then
                                return boolEndFunction, nil
                            end

                            if persPack.boolDoneFor then return boolEndFunction, persPack end

                            if doesUnitExistAlive(persPack.traitorID) == false then
                               -- echo("Double Agent died "..persPack.traitorID)
                                destroyUnitConditional(persPack.iconID, false, true)
                                GG.DoubleAgents[persPack.traitorID] = nil
                                return boolEndFunction, nil
                            end

                            --wait till traitor is complete
                            if isUnitComplete(persPack.traitorID) == false then
                                return boolContinue, persPack
                            end

                            x, y, z = Spring.GetUnitPosition(persPack.traitorID)

                            if doesUnitExistAlive(persPack.iconID) == false then
--                                Spring.Echo("createUnitAtUnit ".."lib_mosaic.lua:1741") 
                                persPack.iconID = createUnitAtUnit(persPack.teamToTurnTo, "doubleagent",
                                    persPack.traitorID, x - 1,
                                y + persPack.heightAbove, z)
                                Spring.MoveCtrl.Enable(persPack.iconID)
                                GG.DoubleAgents[persPack.traitorID] = persPack.iconID
                                return boolContinue, persPack
                            end

                            Spring.MoveCtrl.SetPosition(persPack.iconID, x - 1, y + persPack.heightAbove, z)
                            if isUnitComplete(persPack.traitorID) == false then
                                return boolContinue, persPack
                            end

                            --recursive part
                            if persPack.boolRecursive and persPack.boolRecursive == true then
                                if not persPack.ListOfBuildUnits then persPack.ListOfBuildUnits = {} end
                                if not persPack.ListOfCompletedTurnedUnits then persPack.ListOfCompletedTurnedUnits = {} end
                                buildID = Spring.GetUnitIsBuilding(persPack.traitorID)
                                if buildID then
                                    persPack.ListOfBuildUnits[buildID] = buildID

                                    for buildID,_ in pairs(persPack.ListOfBuildUnits) do
                                        if isUnitComplete(buildID) and not persPack.ListOfCompletedTurnedUnits[buildID] then
                                            attachDoubleAgentToUnit(buildID, persPack.teamToTurnTo, persPack.boolRecursive)
                                            persPack.ListOfCompletedTurnedUnits[buildID]= buildID
                                            persPack.ListOfBuildUnits[buildID]= nil
                                        end  
                                    end
                                end
                            end

                            boolUnitIsCloaked = Spring.GetUnitIsCloaked(persPack.iconID)
                            if not persPack.boolCloakedAtLeastOnce then
                                persPack.boolCloakedAtLeastOnce = boolUnitIsCloaked
                            end

                            persPack.boolCloakedAtLeastOnce = persPack.boolCloakedAtLeastOnce or boolUnitIsCloaked

                            if persPack.startFrame + 1 < Spring.GetGameFrame() and
                                persPack.boolCloakedAtLeastOnce == true and
                                boolUnitIsCloaked == false then
                                echo("DoubleAgent teamtransfer")
                                --we copy kill the unit here instead of transfering to another team
                                --to prevent script incosistencies
                                copyUnit(persPack.traitorID, persPack.teamToTurnTo)
                                destroyUnitConditional(persPack.iconID, false, true)
                                Spring.DestroyUnit(persPack.traitorID, false, true)
                                persPack.boolDoneFor = true
                                return boolEndFunction, persPack
                            end

                            return boolContinue, persPack
                        end

                        createStreamEvent(traitorID, hoverAboveFunc, 1, {
                            startFrame = Spring.GetGameFrame(),
                            teamToTurnTo = teamToTurnTo,
                            traitorID = traitorID,
                            heightAbove = GG.GameConfig.doubleAgentHeight,
                            boolRecursive = boolRecursive
                        })
                    end

                    function createRewardEvent(teamid, returnOfInvestmentM, returnOfInvestmentE)

                        returnOfInvestmentM = returnOfInvestmentM or 100
                        returnOfInvestmentE = returnOfInvestmentE or 100

                        rewarderProcess = function(evtID, frame, persPack, startFrame)

                            Spring.AddTeamResource(persPack.teamId, "metal",
                                persPack.returnOfInvestmentM /
                            persPack.rewardCycles)
                            Spring.AddTeamResource(persPack.teamId, "energy",
                                persPack.returnOfInvestmentE /
                            persPack.rewardCycles)

                            persPack.rewardCycleIndex = persPack.rewardCycleIndex + 1
                            if persPack.rewardCycleIndex > persPack.rewardCycles then
                                return nil, nil
                            end

                            return frame + 1000, persPack
                        end

                        persPack = {
                            teamId = teamid,
                            returnOfInvestmentM = returnOfInvestmentM,
                            returnOfInvestmentE = returnOfInvestmentE,
                            id = unitID,
                            rewardCycles = 25,
                            rewardCycleIndex = 0
                        }

                        GG.EventStream:CreateEvent(rewarderProcess, persPack,
                        Spring.GetGameFrame() + 1)

                    end

                    -- EventStream Function
                    function syncDecoyToAgent(evtID, frame, persPack, startFrame)
                        --only apply if Unit is still alive
                        if doesUnitExistAlive(persPack.myID) == false then
                            -- if Unit did not die peacefully - kill the synced unit
                            if not GG.DiedPeacefully[persPack.myID] then
                                Spring.DestroyUnit(persPack.syncedID, false, true)
                            end

                            return nil, persPack
                        end

                        if doesUnitExistAlive(persPack.syncedID) == false then
                            return nil, persPack
                        end

                        -- sync Health
                        transferUnitStatusToUnit(persPack.myID, persPack.syncedID)

                        x, y, z = Spring.GetUnitPosition(persPack.syncedID)
                        mx, my, mz = Spring.GetUnitPosition(persPack.myID)
                        if not x then return nil, persPack end

                        if not persPack.oldSyncedPos then
                            persPack.oldSyncedPos = {x = x, y = y, z = z}
                        end
                        -- Test Synced Unit Stopped
                        agentTransportedByID = Spring.GetUnitTransporter(persPack.syncedID)
                        -- Transported
                        if agentTransportedByID and not persPack.boolTransported then
                            persPack.boolTransported = true
							pieceMap = Spring.GetUnitPieceMap(agentTransportedByID)
                            centerPiece = sampleKeyFromDicct(pieceMap, "center", "anchor")
							Spring.UnitAttach(agentTransportedByID, persPack.myID, centerPiece)		
                            return frame + 5, persPack
                        elseif persPack.boolTransported == true and not agentTransportedByID then
							Spring.UnitDetach(persPack.myID)
                            persPack.boolTransported = false
                        end

                        if distance(persPack.oldSyncedPos.x, persPack.oldSyncedPos.y,
                        persPack.oldSyncedPos.z, x, y, z) < 5 then
                        -- Unit has stopped, test wether we are near it
                        if distance(mx, my, mz, x, y, z) < 25 then
                            Command(persPack.myID, "stop", {}, {})
                            return frame + 30, persPack
                        end
                    end

                    -- update old Pos
                    persPack.oldSyncedPos = {x = x, y = y, z = z}

                    if not persPack.currPos then
                        persPack.currPos = {x = mx, y = my, z = mz}
                        persPack.stuckCounter = 0
                    end

                    if distance(mx, my, mz, persPack.currPos.x, persPack.currPos.y,
                    persPack.currPos.z) < 50 then
                    persPack.stuckCounter = persPack.stuckCounter + 1
                else
                    persPack.currPos = {x = mx, y = my, z = mz}
                    persPack.stuckCounter = 0
                end

                if persPack.stuckCounter > 5 then
                    moveUnitToUnitGrounded(persPack.myID, persPack.syncedID,
                    math.random(-10, 10), 0, math.random(-10, 10))
                end

                --is not a build command
                command = Spring.GetUnitCommands (unitID, 1)
                if command[1] then
                    Command(persPack.myID, "go", {x = x, y = y, z = z})
                end

                return frame + 30, persPack
            end

function getRegionByCulture(culture, hash)

  if culture == "arabic" then
    if hash % 3 == 0 then
      return "MiddleEast"
    end
    if hash % 3 == 1 then
      return "CentralAsia"
    end
    if hash % 3 == 2 then
      return "Africa"
    end
  end

  if culture == "western" then 
    if hash % 3 == 0 then
      return "Europe"
    end
    if hash % 3 == 1 then
      return "NorthAmerica"
    end
    if hash % 3 == 2 then
      return "SouthAmerica"
    end
  end

  if culture == "asian" then
    if hash % 2 == 0 then
      return "SouthEastAsia"
    end
    if hash % 2 == 1 then
      return "CentralAsia"
    end
  end

  if culture == "international" then
    return "International"
  end
end

function getRegionDayColorBy(culture, hash)
  Spring.Echo("getRegionDayColor for culture: "..culture)
  if culture == "arabic" then
    if hash % 3 == 0 then
      return makeVector(252, 247, 156)--"MiddleEast"
    end
    if hash % 3 == 1 then
      return makeVector(215, 167, 114)--"CentralAsia"
    end
    if hash % 3 == 2 then
      return makeVector(252,254, 172)--"Africa"
    end
  end

  if culture == "western" then 
    if hash % 3 == 0 then
      return makeVector(154, 201, 206)--"Europe"
    end
    if hash % 3 == 1 then
      return makeVector(220, 230, 255)--"NorthAmerica"
    end
    if hash % 3 == 2 then
      return makeVector(255, 204, 153)--"SouthAmerica"
    end
  end

  if culture == "asian" then
    if hash % 2 == 0 then
      return makeVector(231, 157, 102)--"SouthEastAsia"
    end
    if hash % 2 == 1 then
      return makeVector(215, 167, 114)--"CentralAsia"
    end
  end

  if culture == "international" then
    return makeVector(215, 167, 114) --"International"
  end


  return makeVector(215, 167, 114)
end

function getAzimuthByRegion(culture, hash)
    returnHash= 0
    minimum = 0
    _, region = getCountryByCulture(culture, hash)
    region_azimuthMap ={
        Africa = {min = 60, max= 90, sign= -1},
        MiddleEast = {min= 75, max= 85, sign = randSign()},
        CentralAsia = {min= 60, max= 80, sign = 1},
        Europe = {min = 55, max=75, sign= 1},
        NorthAmerica = {min= 60, max= 80, sign= 1},
        SouthAmerica = {min = 70, max=89, sign = -1},
        SouthEastAsia = { min= 75, max = 90, sign= -1 },
        International = {min= 45, max= 89, sign = randSign()}
        }

    if not region_azimuthMap[region] then
        region = "International"
    end

    minimum = region_azimuthMap[region].min
    maximum = region_azimuthMap[region].max

    return ((hash % maximum)% minimum) + minimum, region_azimuthMap[region].sign
end

function getCountryByCulture(culture, hash)

  region_countryMap ={
    Africa = {"Chad","Central African Republic","Senegal","Lesotho","Congo","Ghana","Botswana","Togo","Swaziland","South Africa","Eritrea","Zimbabwe","Algeria","Malawi","Sierra Leone","Liberia","Zambia","Kenya","Ethiopia","Guinea","Djibouti","Burkina Faso","Nigeria","Uganda","Comoros","Saint Helena","Guinea-Bissau","Namibia","Gambia","Benin","Gabon","Trinidad And Tobago","Niger","Cameroon","Angola","Cabo Verde","Burundi","Somalia","Mali","Tanzania","Rwanda","Mozambique","Côte D’Ivoire","Madagascar","Saint Martin"},
    MiddleEast = {"Tunisia","Libya","Sudan","Syria","Saudi Arabia","Jordan","Kuwait","Brunei","Algeria","Turkey","Iran","Lebanon","Qatar","West Bank","United Arab Emirates","Israel","Bahrain","Gaza Strip","Armenia","Iraq","Oman","Yemen","Egypt","Morocco","Pakistan", "Western Sahara", "Mauritania"},
    CentralAsia = {"Bhutan","Tajikistan","Iran","Georgia","Nepal","Azerbaijan","Russia","Kyrgyzstan","Afghanistan","Turkmenistan","Pakistan","Uzbekistan","Mongolia","Kazakhstan"},
    Europe = {"Cyprus","Belarus","Slovakia","Greece","Hungary","Montenegro","Macedonia","Kosovo","Sweden","Luxembourg","Belgium","Slovenia","Albania","Turkey","Serbia","Ukraine","France","Liechtenstein","United Kingdom","Iceland","Italy","Czechia","Andorra","Poland","Netherlands","Croatia","Russia","Malta","Germany","Ireland","Portugal","Monaco","Norway","Vatican City","Finland","Bulgaria","Moldova","Estonia","Lithuania","Latvia", "Switzerland","Romania","San Marino","Isle Of Man","Spain","Denmark","Austria","Gibraltar","Bosnia And Herzegovina"},
    NorthAmerica = {"United States","Panama","Canada","Greenland","Jersey","Village of Islands","El Salvador","Mexico",},
    SouthAmerica = {"Belize","Jamaica","Venezuela","Guyana","Equatorial Guinea","Argentina","Brazil","Peru","Ecuador","Honduras","Nicaragua","Bermuda","Bolivia","Cuba","Puerto Rico","Cayman Islands","Chile","Uruguay","Dominican Republic","Costa Rica","French Guiana","Sint Maarten","Mauritius","Saint Lucia","New Caledonia","Paraguay","Guatemala","Barbados","Colombia","French Polynesia",},
    SouthEastAsia = {"Bangladesh","Papua New Guinea","Myanmar","Cambodia","Australia","Thailand","Korea","China","Vietnam","New Zealand","Sri Lanka","Guadeloupe","Taiwan","Malaysia","Macau", "Wallis And Futuna","Grenada","Laos","Anguilla","Christmas Island","Pitcairn Islands","Guam","Singapore","Hong Kong","Japan","Philippines","Indonesia" }
  }

  if culture == "arabic" then
    if hash % 3 == 0 then
      return region_countryMap.MiddleEast[((hash*69) % #region_countryMap.MiddleEast) +1 ], "MiddleEast"
    end
    if hash % 3 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ], "CentralAsia"
    end
    if hash % 3 == 2 then
      return region_countryMap.Africa[((hash*69) % #region_countryMap.Africa) +1 ], "Africa"
    end
  end

  if culture == "western" then 
    if hash % 3 == 0 then
      return region_countryMap.Europe[((hash*69) % #region_countryMap.Europe) +1 ], "Europe"
    end
    if hash % 3 == 1 then
      return region_countryMap.NorthAmerica[((hash*69) % #region_countryMap.NorthAmerica) +1 ], "NorthAmerica"
    end
    if hash % 3 == 2 then
      return region_countryMap.SouthAmerica[((hash*69) % #region_countryMap.SouthAmerica) +1 ], "SouthAmerica"
    end
  end

  if culture == "asian" then
    if hash % 2 == 0 then
      return region_countryMap.SouthEastAsia[((hash*69) % #region_countryMap.SouthEastAsia) +1 ], "SouthEastAsia"
    end
    if hash % 2 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ],"CentralAsia"
    end
  end

  if culture == "international" then
    internationalCityCountries = {"Dubai", "Hong Kong",
      "United States", "United Kingdom", "Japan"}
    return internationalCityCountries[hash % #internationalCityCountries +1], "International"
  end
end

    function initalizeInheritanceManagement()
        -- GG.InheritanceTable = [teamid] ={ [parent] = {[child] = true}}}
        if not GG.InheritanceTable then
            GG.InheritanceTable = {}
            Teams = Spring.GetTeamList()
            for i=1, #Teams do
                GG.InheritanceTable[Teams[i]] = {}
            end
        end
    end

    function registerParent(teamID, parent)
        if not GG.InheritanceTable then initalizeInheritanceManagement() end
       -- Spring.Echo("register Father of unit")
        if not GG.InheritanceTable[teamID][parent] then
            GG.InheritanceTable[teamID][parent] = {}
        end
    end

    function registerChild(teamID, parent, childID)
        if not GG.InheritanceTable then initalizeInheritanceManagement() end
        --Spring.Echo("register Child child of unit")
        registerParent(teamID, parent)

        GG.InheritanceTable[teamID][parent][childID] = true
    end

    function transferHierarchy(teamID, originalID, copyID)
        if not GG.InheritanceTable then initalizeInheritanceManagement() end

        if  GG.InheritanceTable[teamID][originalID] then
             GG.InheritanceTable[teamID][copyID] = GG.InheritanceTable[teamID][originalID] 
             GG.InheritanceTable[teamID][originalID] = nil 
        end

        for team, dataSet in pairs(GG.InheritanceTable) do
            for parent, children in pairs(dataSet) do
                for child,_ in pairs(children) do
                    if child == originalID then
                        GG.InheritanceTable[team][parent][child] = nil
                        GG.InheritanceTable[team][parent][copyID] = true
                    end
                end
            end
        end        
    end

    function infectWanderlostNearby(GameConfig, AerosolTypes, aerosolAffectableUnits)
        local AerosolAffectedCivilians = GG.AerosolAffectedCivilians 
        for id, AerosolType in pairs (AerosolAffectedCivilians) do
            if AerosolType == AerosolTypes.wanderlost then
                foreach(getAllNearUnit(id, GameConfig.Aerosols.wanderlost.reinfectRange), 
                                    function(id)
                                         if aerosolAffectableUnits[Spring.GetUnitDefID(id)] and
                                                not AerosolAffectedCivilians[id] then -- you can only get infected once
                                            if setAerosolCivilianBehaviour(id,  AerosolTypes.wanderlost) == true then
                                            GG.AerosolAffectedCivilians[id] = AerosolTypes.wanderlost
                                            AerosolAffectedCivilians[id] = AerosolTypes.wanderlost
                                            return id
                                          end
                                        end
                                    end)

            end
        end
    end

    function getChildrenOfUnit(teamID, unit)
        if not GG.InheritanceTable then initalizeInheritanceManagement() end
        -- Spring.Echo("Getting children of unit")
        return GG.InheritanceTable[teamID][unit] or {}
    end

    function getParentOfUnit(teamID, unit)
        -- Spring.Echo("getParentOfUnit")
        for parent, unitTable in pairs(GG.InheritanceTable[teamID]) do
            if unitTable then
                for thisUnit, _ in pairs(unitTable) do
                    if unit == thisUnit then return parent end
                end
            end
        end
    end

     function removeUnit(teamID, unit)
        -- Spring.Echo("removing unit from graph")
        parent = getParentOfUnit(teamID, unit)
        if parent then GG.InheritanceTable[teamID][parent][unit] = nil end
        if GG.InheritanceTable[teamID][unit] then
            GG.InheritanceTable[teamID][unit] = nil
        end
    end



    function GetUnitDefRealRadius(udid)
      if not GG.realRadiusComputated then GG.realRadiusComputated = {} end
      local radius = GG.realRadiusComputated[udid]
      if (radius) then
        return radius
      end

      local ud = UnitDefs[udid]
      if (ud == nil) then return nil end

      local dims = Spring.GetUnitDefDimensions(udid)
      if (dims == nil) then return nil end

      local scale = ud.hitSphereScale -- missing in 0.76b1+
      scale = ((scale == nil) or (scale == 0.0)) and 1.0 or scale
      radius = dims.radius / scale
      GG.realRadiusComputated[udid] = radius
      return radius
    end

    function extractNameFromDescription(unitID)
        tooltip = UnitDefs[Spring.GetUnitDefID(unitID)].humanName
        braceStart=string.find(tooltip,"<")
        if braceStart then 
            return string.upper(string.sub(tooltip, 1, braceStart-1)) or "Target"
        else 
            return string.upper(tooltip) or "Target"
        end
    end

    function registerRevealedUnitLocation(unitID)
        assert(unitID)
        assert(type(unitID) == "number")
        assert(doesUnitExistAlive(unitID))
        --echo("Entered registerRevealedUnitLocation")
        local Location = {}
        Location.x, Location.y, Location.z = Spring.GetUnitBasePosition(unitID)
        Location.teamID = Spring.GetUnitTeam(unitID)
        Location.radius = GetUnitDefRealRadius(unitID) or 50
        Location.revealedUnits = {}
        Location.endFrame = Spring.GetGameFrame() + GG.GameConfig.raid.revealGraphLifeTimeFrames

        local parent = getParentOfUnit(Location.teamID, unitID)
        if parent and doesUnitExistAlive(parent) then
            startRevealedUnitsChatEventStream(unitID, parent)
            Location.revealedUnits[parent] = {}
            x,y,z = Spring.GetUnitPosition(parent)
            Location.revealedUnits[parent].pos = {x=x,y=y,z=z}
            Location.revealedUnits[parent].defID = Spring.GetUnitDefID(parent)
            Location.revealedUnits[parent].boolIsParent = true
            Location.revealedUnits[parent].name = extractNameFromDescription(parent)
            --echo("registerRevealedUnitLocation: revealing parent "..parent)
        else
            --echo("Revealed unit does not have a parent")
        end

        local children = getChildrenOfUnit(Location.teamID, unitID)
        if children and count(children) > 0 then
            for childID, _ in pairs(children) do
                if childID and doesUnitExistAlive(childID) then
                    startRevealedUnitsChatEventStream(unitID, childID)
                    Location.revealedUnits[childID] = {}
                    x,y,z = Spring.GetUnitPosition(childID)
                    Location.revealedUnits[childID].pos = {x=x,y=y,z=z}
                    Location.revealedUnits[childID].defID = Spring.GetUnitDefID(childID)
                    Location.revealedUnits[childID].boolIsParent = false
                    Location.revealedUnits[childID].name = extractNameFromDescription(childID)
                  --  echo("registerRevealedUnitLocation: revealing child"..childID)
                end
            end
        else
            --echo("Revealed unit does not have children")
        end

        if not GG.RevealedLocations then GG.RevealedLocations = {} end
        GG.RevealedLocations[#GG.RevealedLocations + 1] = Location
    end

    function giveParachutToUnit(id, x, y, z, boolDelayed)
        if not GG.ParachutPassengers then GG.ParachutPassengers = {} end

        if Spring.GetGameFrame() < 1 or boolDelayed then

            delayedParachutSpawn = function(evtID, frame, persPack, startFrame)

                if Spring.GetGameFrame() < 1 then
                    return frame + 1, persPack
                end

                parachutID = createUnitAtUnit(Spring.GetUnitTeam(persPack.id),
                "air_parachut", persPack.id)
                GG.ParachutPassengers[parachutID] =
                {
                    id = persPack.id,
                    x = persPack.x,
                    y = persPack.y,
                    z = persPack.z
                }
                Spring.SetUnitTooltip(parachutID, persPack.id .. "")
                -- setUnitValueExternal(persPack.id, 'WANT_CLOAK' , 0)
                -- setUnitValueExternal(persPack.id, 'CLOAKED' , 0)
                return nil, nil
            end

            persPack = {id = id, x = x, y = y, z = z}

            GG.EventStream:CreateEvent(delayedParachutSpawn, persPack,
            Spring.GetGameFrame() + 1)

        else
--            Spring.Echo("createUnitAtUnit ".."lib_mosaic.lua:2204") 
            parachutID =    createUnitAtUnit(Spring.GetUnitTeam(id), "air_parachut", id)

            GG.ParachutPassengers[parachutID] = {id = id, x = x, y = y, z = z}
            Spring.SetUnitTooltip(parachutID, id .. "")
            setUnitValueExternal(id, 'WANT_CLOAK', 0)
        end
    end


    function getSpawnedMilitaryUnitTypeTable()
        return  {"ground_truck_mg", "ground_tank_night","ground_truck_rocket","ground_truck_antiarmor","air_copter_blackhawk"}
    end

    function delayedKillProjectile(id, timeInMS)            

            delayedKill = function(evtID, frame, persPack, startFrame)
                ttl = Spring.GetProjectileTimeToLive ( persPack.id) 
                if not ttl then return end

                if Spring.GetGameFrame() > persPack.endFrame then
                    Spring.DeleteProjectile(persPack.id)
                    return 
                end

                return frame + 5, persPack
            end
            frames = math.ceil(1+(timeInMS/1000)*30)
            persPack = {id = id, endFrame = Spring.GetGameFrame()+ frames}

            GG.EventStream:CreateEvent(delayedKill, persPack,
            Spring.GetGameFrame() + 1)
    end



    function getHouseClusterPoints(UnitDefs, culture)

        houseTypeTable = getHouseTypeTable(UnitDefs, culture)
        local PositionTable = {}

        foreach(Spring.GetAllUnits(),
         function(id)
            defID = Spring.GetUnitDefID(id)
            if houseTypeTable[defID] then return id end
        end, 
        function(id)
            x, y, z = Spring.GetUnitPosition(id)
            PositionTable[#PositionTable + 1] = {x = x, y = y, z = z}
        end)
        assert(#PositionTable > 0)

        -- PositionTable= shuffleT(PositionTable)
        local midPoints = {}
        -- calculate midpoints
        for n = 1, #PositionTable do
            for i = 1, #PositionTable do
                dist = distance(PositionTable[i], PositionTable[n])
                local pos = mixTable(PositionTable[i], PositionTable[n], 0.5)
                _, _, _, slope = Spring.GetGroundNormal(pos.x, pos.z)

                if dist < 1024 and i ~= n and slope < 0.1 then
                    midPoints[#midPoints + 1] = pos
                end
            end
        end

        assert(#midPoints > 0)
        return midPoints
    end

    function cullPositionCluster(PosTable, iterrations)
        if count(PosTable) <= 3 then
            --Spring.Echo("cullPositionCluster: PosTable to small")
            return PosTable
        end

        local culledPoints = PosTable

        for it = 1, iterrations do
            local result = {}
            for i = 1, count(culledPoints) - 1, 2 do
                pos = mixTable(culledPoints[i], culledPoints[i + 1], 0.5)
                _, _, _, slope = Spring.GetGroundNormal(pos.x, pos.z)

                if slope < 0.1 then result[#result + 1] = pos end
            end
            culledPoints = result

            if count(culledPoints) <= 3 then
                --Spring.Echo("Aborting with Points:" .. count(culledPoints))
                return culledPoints
            end
        end

        return culledPoints
    end

            function computateClusterNodes(housePosTable, GameConfig)
                timeFactor = math.abs(math.sin(math.pi * Spring.GetGameFrame() /
                GameConfig.civilian.GatheringBehaviourIntervalFrames)) -- [0 - 1]

                goalIndexMaxDivider = getBelowPow2(GameConfig.numberOfBuildings)
                -- protect against min and max
                goalIndexDivider = math.floor(goalIndexMaxDivider * timeFactor)
                local result = cullPositionCluster(housePosTable, goalIndexDivider)
                return result
            end

            function computeOrgHouseTable(UnitDefs, GameConfig)
                return getHouseClusterPoints(UnitDefs, GameConfig.instance.culture)
            end

            function showHideIconEnv(unitID, arg)
                env = Spring.UnitScript.GetScriptEnv(unitID)
                if env and env.showHideIcon then
                    Spring.UnitScript.CallAsUnit(unitID, env.showHideIcon, arg)
                end
            end

            function getInfluencedStates()
                return {
                    ["Init"] = "Init",
                    ["PreOutbreak"] = "PreOutbreak",
                    ["Outbreak"] = "Outbreak",
                    ["Standalone"] = "Standalone",
                    ["Dieing"] = "Dieing",
                    ["Exit"] = "Exit"
                }
            end

            function getRefugeePoint(index)
                if not GG.CivilianEscapePointTable then  GG.CivilianEscapePointTable = {} end
                if not  GG.CivilianEscapePointTable[index]  then  GG.CivilianEscapePointTable[index] = math.random(1,1000)/1000   end
                if index == 1 then return 25,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
                if index == 2 then return Game.mapSizeX,  GG.CivilianEscapePointTable[index] * Game.mapSizeZ end
                if index == 3 then return GG.CivilianEscapePointTable[index] * Game.mapSizeX, 25 end
                if index == 4 then return GG.CivilianEscapePointTable[index] * Game.mapSizeX, Game.mapSizeZ end
                Spring.Echo("Unknown EscapePoint")
            end

            function isOffenceIcon(UnitDefs, defID)
                assert(UnitDefs)
                return UnitDefs[defID].name == "icon_bribe" or UnitDefs[defID].name == "icon_cybercrime"
            end

            function shiverAllAxis(unitID)
                allPieces = Spring.GetUnitPieceList(unitID)
                for i = 1, 3 do
                    val = math.random(5, 15) 
                     for p=1, #allPieces do
                        Spin(p, i, val * randSign(), val) 
                      end
                end
            end

          
            function stopShiver(unitID)
                allPieces = Spring.GetUnitPieceList(unitID)
                for i = 1, 3 do
                    for p=1, #allPieces do
                        StopSpin(p, i) 
                    end
                end  
            end

            -- Function to get a point on a spiral
            -- cx, cy: Center of the spiral
            -- time: Input time for the spiral's position
            -- a: Initial radius (controls the tightness of the spiral)
            -- b: Growth rate of the spiral
            -- Returns: x, y coordinates of the point
            function spiralPoint(cx, cy, frame, a, b)
                frame = math.abs(900 - (frame % 900))
                local time = frame/30
                -- Calculate the angle and radius based on time
                local angle = time -- Angular position (rad/s, assuming time is in seconds)
                local radius = a + b * time -- Radius grows with time

                -- Convert polar to Cartesian coordinates
                local x = cx + radius * math.cos(angle)
                local y = cy + radius * math.sin(angle)

                return x, y
            end


            function setWanderlostMoveGoal(unitID, gf)
                x, z = getRefugeePoint((unitID% 4)+1)
                if GG.innerCityCenter then 
                    x,z = GG.innerCityCenter.x, GG.innerCityCenter.z 
                end
         

                 sx,sz = spiralPoint(x, z, gf, Game.mapSizeX*0.1, 0.125)
                 Command(unitID, "go", {x=sx, y= 0, z= sz})
            end

            function getAerosolInfluencedStateMachine(unitID, UnitDefs, typeOfInfluence, center, ArmLeft, ArmRight, Head)
                --assert(typeOfInfluence)
                AerosolTypes = getChemTrailTypes()
                --assert(AerosolTypes[typeOfInfluence])

                InfStates = getInfluencedStates()
                CivilianTypes = getCivilianTypeTable(UnitDefs)

                InfluenceStateMachines = {
                    [AerosolTypes.orgyanyl] = 
                    function(lastState, currentState, unitID)
                        if currentState == AerosolTypes.orgyanyl then
                            currentState = InfStates.Init
                        end

                        -- Init
                        if currentState == InfStates.Init then
                            val = math.random(10, 60) / 1000
                            spinT(Spring.GetUnitPieceList(unitID), z_axis, val * randSign(), 0000015)
                            currentState = InfStates.PreOutbreak
                        end

                        if currentState == InfStates.PreOutbreak then
                            val = math.random(10, 60) / 1000
                            spinT(Spring.GetUnitPieceList(unitID), z_axis, val * randSign(), 0000015)

                            al = Spring.GetUnitNearestAlly(unitID)
                            if al and CivilianTypes[Spring.GetUnitDefID(al)] then
                                x, y, z = Spring.GetUnitPosition(al)
                                Command(unitID, "go", {x = x, y = y, z = z}, {})
                                if distanceUnitToUnit(unitID, al) < 50 then
                                    currentState = InfStates.Outbreak
                                end
                            else
                                currentState = InfStates.Outbreak
                            end
                            setOverrideAnimationState(eAnimState.walking,
                            eAnimState.walking, true, nil, true)
                        end

                        if currentState == InfStates.Outbreak then
                            stopShiver(unitID)

                            showID = createUnitAtUnit(Spring.GetGaiaTeamID(),
                            "civilian_orgy_pair", unitID, 0, 0, 0)
                            myDefID = Spring.GetUnitDefID(showID)
                            foreach(getAllNearUnit(showID, 100),
                                function(id) -- get Bystanders
                                    defID = Spring.GetUnitDefID(id)
                                    if CivilianTypes[defID] then
                                        x, y, z = Spring.GetUnitPosition(al)
                                        Command(id, "go", {
                                            x = x + math.random(-10, 10),
                                            y = y,
                                        z = z + math.random(-10, 10)}, {})
                                    end
                                end)
                                Spring.DestroyUnit(unitID, false, true)
                            end

                            return currentState
                        end,
                        [AerosolTypes.wanderlost] = function(lastState, currentState, unitID)
                            if currentState == AerosolTypes.wanderlost then
                                StartThread(lifeTime, unitID,
                                    GG.GameConfig.Aerosols.wanderlost.VictimLiftime,
                                false, true)
                                currentState = InfStates.Init
                            end

                            if currentState == InfStates.Init then
								setSpeedIntern(unitID, 2.0)
                                currentState = InfStates.Outbreak
                            end

                            if currentState == InfStates.Outbreak then
                                infectWanderlostNearby(GG.GameConfig, AerosolTypes, CivilianTypes)
                                gf = Spring.GetGameFrame()					
		
                                if gf % 90 == 0 then
                                   spasm(unitID, math.random(22/90, 90), math.random(1,3))
                                end                                 
                            end

                            return currentState
                        end,                        
                        [AerosolTypes.tollwutox] = function(lastState, currentState, unitID)
                            if currentState == AerosolTypes.tollwutox then
                                StartThread(lifeTime, unitID, GG.GameConfig.Aerosols.tollwutox.VictimLiftime, false, true)
                                if not GG.TollWutoxAfflicted then GG.TollWutoxAfflicted = {} end
                                GG.TollWutoxAfflicted[unitID] = unitID
                                currentState = InfStates.Init
                                if math.random(0, 10) > 7 then
                                    currentState = InfStates.Standalone
                                end
                            end

                            gf = Spring.GetGameFrame()
                            attackDistance = 35
                            -- random shivers
                            if gf % 30 == 0 and gf % 90 ~= 0 and maRa() then
                                allPieces = Spring.GetUnitPieceList(unitID)
                                for i = 1, 3 do
                                    val = (math.random(-100, 100) / 100) * 12
                                    for p=1, #allPieces do
                                        Spin(allPieces[p], i, math.rad(val), 30.125) 
                                    end
                                   
                                end
                            end

                            if gf % 90 == 0 then
                                for i = 1, 3 do
                                    val = (math.random(-100, 100) / 100) * 12
                                    stopSpinT(Spring.GetUnitPieceList(unitID), i, 30.125)
                                end
                            end
                            headVal = math.random(-10, 25)
                            Turn(head,x_axis, math.rad(headVal),3)
                            enemyDistance = math.huge
                            allyDistance = math.huge

                            local afflicted = GG.AerosolAffectedCivilians or {}
                            nearestDistance = math.huge
                            nearestID = nil
                            Tenemy= {}
                            Tally = {}
                            ix,iy,iz = spGetUnitPosition(unitID)
                            foreach(
                                getAllNearUnit(unitID, 750),
                                function(id)
                                    defId = spGetUnitDefID(id)
                                    if civilianWalkingTypeTable[defID] then return id end
                                end,
                                function(id)
                                    if afflicted[id] and GG.TollWutoxAfflicted[id] then
                                        Tally[id] = distanceUnitToUnit(id, unitID)
                                        if Tally[id] < nearestDistance then
                                            nearestDistance = Tally[id]
                                            nearestID = id 
                                        end
                                    else
                                        Tenemy[id] = distanceUnitToUnit(id, unitID)
                                        if Tenemy[id] < nearestDistance then
                                            nearestDistance = Tenemy[id]
                                            nearestID = id 
                                        end
                                    end
                                end
                                )
                            if nearestID then 
                                if Tenemy[nearestID] then
                                    Spring.SetUnitNeutral(unitID, false)
                                    assaultNearby(ed) 
                                else
                                    Command(unitID, "guard", nearestID )
                                end
                            end               
                           
                           return currentState                            
                        end,
                        [AerosolTypes.depressol] = function(lastState, currentState, unitID)
                            if currentState == AerosolTypes.depressol then
                                StartThread(lifeTime, unitID,
                                    GG.GameConfig.Aerosols.depressol.VictimLiftime,
                                false, true)
                                stunUnit(unitID, 2)
                                currentState = InfStates.Init
                            end
                      
                            gf = Spring.GetGameFrame()
                            if gf % 90 == 0 then
                            setOverrideAnimationState(eAnimState.standing, eAnimState.wailing,  true, nil, true)
                                bombTypeTable = getBombTypeTable(UnitDefs)
                                if currentState == InfStates.Init then
                                    bombsNearby = foreach(getAllNearUnit(unitID, 512),
                                                            function(id)
                                                                defID = Spring.GetUnitDefID(id)
                                                                if bombTypeTable[defID] then
                                                                    return id
                                                                end
                                                            end
                                                         )

                                    if #bombsNearby > 0 then 
                                        if distanceUnitToUnit(unitID, bombsNearby[1]) < 50 then
                                            Spring.DestroyUnit(bombsNearby[1], false, true)
                                            Spring.DestroyUnit(unitID, true, false)
                                        end
                                        
                                        ex,ey,ez = spGetUnitPosition(bombsNearby[1])
                                        Command(unitID, "go", {x = ex,y = ey,z = ez }, {"shift"})
                                    end
                                end
                            end
                                return currentState
                            end
                    }

                    assert(InfluenceStateMachines[typeOfInfluence], typeOfInfluence)
                    return InfluenceStateMachines[typeOfInfluence]
                end

                function assaultNearby(aid)
                    enemyDistance = distanceUnitToUnit(aid)
                    if enemyDistance and enemyDistance < 20 then
                        closeCombatAnimation(center, ArmLeft, ArmRight)
                        Spring.AddUnitDamage(aid, 30)
                        spawnCegAtUnit(id, "bloodslay")
                    else                      
                        x,y,z = spGetUnitPosition(aid)
                       Command( aid, "go",{x,y,z}, {"shift"})
                    end
                end

                function headShake(shakeNr, Head)
                    for i=1, shakeNr do
                        val = math.random(5,15)
                        Turn(Head, y_axis, math.rad(val)*randSign(),50)
                        Sleep(150)
                    end
                end

                function closeCombatAnimation(center, ArmLeft, ArmRight, Head)
                    val = math.random(-95,-75)
                    tP(ArmLeft, val,90, 0, 10)
                    val = math.random(-95,-75)
                    tP(ArmRight, val,-90, 0, 10)
                    if maRa() then
                        WTurn(center,x_axis, math.rad(10), 1.75)
                    else
                        Turn(center,x_axis, math.rad(10), 1.75)
                        StartThread(headShake, 5, Head)
                        Rest= 5*150
                        Sleep(Rest)
                    end
                    tP(ArmLeft, -160,90, 0, 10)
                    tP(ArmRight, -160,-90, 0, 10)
                    WTurn(center,x_axis, math.rad(15), 0.75)
                    WaitForTurns(ArmLeft,ArmRight, center)
                    tP(ArmLeft, 0, 90, 0, 10)
                    tP(ArmRight,0, -90, 0, 10)      
                    StartThread(headShake, 3, Head)         
                    WaitForTurns(ArmLeft,ArmRight, center)
                    Turn(center,x_axis, math.rad(0), 45)
                    WaitForTurns(ArmLeft,ArmRight, center)
                    StartThread(headShake, 10, Head)
                    val = math.random(-50,-35)
                    tP(ArmLeft, val,90, 0, 10)
                    val = math.random(-50,-35)
                    tP(ArmRight, -40,-90, 0, 10)
                end

                -- >StartThread(dustCloudPostExplosion,unitID,1,600,50,0,1,0)
                -- Draws a long lasting DustCloud
                function dustCloudPostExplosion(unitID, Density, totalTime, SpawnDelay, dirx,
                diry, dirz)
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

            function fireState()
                return {
                    InheritFromFactory = -1,
                    HoldFire = 0,
                    ReturnFire = 1,
                    FireAtWill = 2,
                    OpenUp = 3
                }
            end

            function getAllTeamsOfType(teamType, UnitDefs)
                UnitDefNames = getUnitDefNames(UnitDefs)
                operativepropagatorDefID = UnitDefNames["operativepropagator"].id
                operativeinvestigatorDefID = UnitDefNames["operativeinvestigator"].id

                gaiaTeamID = Spring.GetGaiaTeamID()
                local returnT = {}
                foreach(Spring.GetTeamList(), 
                    function(tid)
                    teamID, leader, isDead, isAiTeam, side, allyTeam, incomeMultiplier = Spring.GetTeamInfo(tid)

                    --brute force over all teams
                    if side == "" or not side then
                        allUnitsSorted = Spring.GetTeamUnitsSorted (teamID )
                        if allUnitsSorted[operativepropagatorDefID] and #allUnitsSorted[operativepropagatorDefID] > 0 then
                            side = "antagon"
                        end

                        if allUnitsSorted[operativeinvestigatorDefID] and #allUnitsSorted[operativeinvestigatorDefID] > 0 then
                            side = "protagon"
                        end

                        if (string.find(side, teamType) ) then 
                            returnT[tid] = tid
                            return
                        end
                    end

                    if tid ~= gaiaTeamID and false == isDead and
                        (string.find(side, teamType) ) then
                        returnT[tid] = tid
                    end
                end)
                return returnT
            end

            function isTeamAITeam(teamID)
                return select(4, Spring.GetTeamInfo(teamID)) == true
            end

            function transferFromTeamToAllTeamsExceptAtUnit(unit, teamToWithdrawFrom,
            amount, teamsToIgnore)
            local allTeams = Spring.GetTeamList()
            if not unit or not GG.Bank or not allTeams or #allTeams <= 1 then
                return false
            end

            GG.Bank:TransferToTeam(-amount, teamToWithdrawFrom, unit)

            for i = 1, #allTeams, 1 do
                teamID = allTeams[i]
                if teamID ~= teamToWithdrawFrom and not teamsToIgnore[teamID] then
                    GG.Bank:TransferToTeam(amount, teamID, unit)
                end
            end
        end

        function unitTest(UnitDefs, UnitDefNames)
            unitTestTypeTables(UnitDefs, UnitDefNames)
            --TODO
        end

        function unitTestTypeTables(UnitDefs, UnitDefNames)
            civilianTypeTable = getCivilianTypeTable(UnitDefs)
            for id, v in pairs(civilianTypeTable) do
                if UnitDefs[id] then
                    echo("CivilianTypeDef: " .. id .. " -> " .. UnitDefs[id].name)
                end
            end
            assert(civilianTypeTable)
            for i = 0, 3 do
                assert(civilianTypeTable[UnitDefNames["civilian_arab" .. i].id], i)
            end

            for i = 1, 8 do
                assert(civilianTypeTable[UnitDefNames["arab_truck" .. i].id])
            end
        end

        --> Sets A Unit on Fire
        function setUnitOnFire(id, timeOnFire)
            if GG.OnFire == nil then GG.OnFire = {} end
            boolInsertIt = true
            --very bad sollution n-times

            for i = 1, table.getn(GG.OnFire), 1 do
                if GG.OnFire[i][1] ~= nil and GG.OnFire[i][1] == id then
                    GG.OnFire[i][2] = GG.OnFire[i][2] + math.ceil(timeOnFire)
                    boolInsertIt = false
                end
            end

            if boolInsertIt == true then
                GG.OnFire[#GG.OnFire + 1] = {}
                GG.OnFire[#GG.OnFire][1] = id
                GG.OnFire[#GG.OnFire][2] = math.ceil(timeOnFire)
            end
        end

        function getObjectiveAboveGroundOffset(id)
            xb, yb, zb = Spring.GetUnitPosition(id)
            ghb = Spring.GetGroundHeight(xb, zb)
            probeDist = 150
            heighestPoint = ghb
            for x = -1, 1 do
                for z = -1, 1 do
                    heighestPoint = math.max(heighestPoint, Spring.GetGroundHeight(xb + x * probeDist, zb + z * probeDist))
                end
            end

            return heighestPoint - ghb
        end

        function setCivilianUnitInternalStateMode(unitID, State)
            if not GG.CivilianUnitInternalLogicActive then GG.CivilianUnitInternalLogicActive = {} end
            GG.CivilianUnitInternalLogicActive[unitID] = State
        end


        function getMapDependentHouseTypes(mapName)
            if string.find(string.lower(mapName), "dubai") then
                return { "office", "white"}
            end

            return {}
        end

        function mapOverideSinCity()
            cityname = string.lower(Game.mapName)
            if string.find(cityname, "dubai") then
                return true
            end
            if string.find(cityname, "dsdr") then
                return true
            end
            
            return false
        end

     

function getIdleTokken()
    if not GG.CurrentIdleNr then GG.CurrentIdleNr = 0 end

    if GG.CurrentIdleNr < GG.GameConfig.maxParallelIdleAnimations then
      GG.CurrentIdleNr  = GG.CurrentIdleNr + 1
      return true
    end  

    return false
end

function returnIdleTokken()
     GG.CurrentIdleNr  = GG.CurrentIdleNr - 1
end
               
function getTODOTable(name)
    --Spring.Echo("Table getter of name "..name.." is missing")
    assert(true==false)
end

function TODO(task)
    Spring.Echo("TODO:"..task)
    assert(true == false)
end

function isCrossway(detailXHash, detailZHash, boolInnerCityBlock)
    if detailZHash == 3 then
        return true
    end

    if (detailXHash == 2 or detailXHash == 4) and (maRa() and boolInnerCityBlock) then
        return true
    end

    return false
end   

--civilian will follow an operative ocassionally for a short time
function instantParanoia(operative, radius, delayInMs, timeToFollowInMs, civilianWalkingTypeTable)
    Sleep(delayInMs)
    local spGetUnitDefID = Spring.GetUnitDefID
    AllCandidates = foreach(getAllNearUnit(operative, radius, Spring.GetGaiaTeamID()),
                        function(id)
                            defID = spGetUnitDefID(id)
                            if civilianWalkingTypeTable[defID] and not GG.DisguiseCivilianFor[id] then
                                return id
                            end
                        end)
    if AllCandidates and #AllCandidates > 1 then
        follower =  AllCandidates[math.random(1,#AllCandidates )]
        x,y,z = GetCurrentMoveGoal(operative)
        --TODO save move goal
        Command(follower, "stop")
        Command(follower, "guard", operative)
        Sleep(timeToFollowInMs)
        Command(follower, "stop")
        Command(follower, "go",{x,y,z}, {"shift"})
    end   
end

function IsOnPremisesOfBuilding(unitID, houseID, houseSize)
    ux, uy, uz = Spring.GetUnitPosition(unitID)
    local blockSize = houseSize/6
    local halfsize = blockSize/2
    local hx,hy,hz = Spring.GetUnitPosition(houseID)
    local minXLimit, maxXLimit = ux - (2.5*blockSize) ,ux + (2.5*blockSize) 
    local minZLimit, maxZLimit = uz - (2.5*blockSize) ,uz + (2.5*blockSize) 
    if hx > minXLimit - halfsize and hx < minXLimit + halfsize  and
       hz > minZLimit - halfsize and hz < minZLimit + halfsize  then

       if  hx < minXLimit + halfsize and hx > minXLimit - halfsize  and
            hz < minZLimit + halfsize and hz > minZLimit - halfsize  then
            return false
       end
       return true
    end
    return false
end

function buildSoundFilePath(path, fileName, nr)
    return string.format("%s/%s/%s-%02d.ogg", path, fileName, fileName, nr)
end

function buildRunDeterministicAdvertisement()
    local ListOfMediaAdvertisementFileLength = 
        {
            ["9MediaName-07.ogg"] = 2120,["9MediaName-14.ogg"] = 1610,["9MediaName-16.ogg"] = 1790,["9MediaName-37.ogg"] = 1740,
            ["9MediaName-38.ogg"] = 1390,["9MediaName-09.ogg"] = 1790,["9MediaName-46.ogg"] = 1790,["9MediaName-30.ogg"] = 1790,
            ["9MediaName-33.ogg"] = 1770,["9MediaName-40.ogg"] = 1600,["9MediaName-48.ogg"] = 860,["9MediaName-45.ogg"] = 1810,
            ["9MediaName-43.ogg"] = 1660,["9MediaName-18.ogg"] = 1800,["9MediaName-13.ogg"] = 1680,["9MediaName-12.ogg"] = 1530,
            ["9MediaName-20.ogg"] = 1690,["9MediaName-25.ogg"] = 1450,["9MediaName-41.ogg"] = 2070,["9MediaName-32.ogg"] = 1870,
            ["9MediaName-17.ogg"] = 1920,["9MediaName-36.ogg"] = 1910,["9MediaName-39.ogg"] = 1420,["9MediaName-02.ogg"] = 1530,
            ["9MediaName-34.ogg"] = 1760,["9MediaName-21.ogg"] = 1950,["9MediaName-42.ogg"] = 1960,["9MediaName-22.ogg"] = 1750,
            ["9MediaName-08.ogg"] = 1650,["9MediaName-05.ogg"] = 1430,["9MediaName-04.ogg"] = 1790,["9MediaName-28.ogg"] = 1370,
            ["9MediaName-24.ogg"] = 1630,["9MediaName-23.ogg"] = 1770,["9MediaName-35.ogg"] = 1450,["9MediaName-44.ogg"] = 1800,
            ["9MediaName-47.ogg"] = 900,["9MediaName-10.ogg"] = 1680,["9MediaName-01.ogg"] = 1420,["9MediaName-29.ogg"] = 1270,
            ["9MediaName-26.ogg"] = 1830,["9MediaName-31.ogg"] = 1430,["9MediaName-15.ogg"] = 1850,["9MediaName-27.ogg"] = 1550,
            ["9MediaName-03.ogg"] = 1630,["9MediaName-06.ogg"] = 1600,["9MediaName-19.ogg"] = 1700,["9MediaName-11.ogg"] = 1820,
            ["7FSurName-11.ogg"] = 1210,["7FSurName-07.ogg"] = 990,["7FSurName-04.ogg"] = 1160,["7FSurName-17.ogg"] = 850,
            ["7FSurName-15.ogg"] = 930,["7FSurName-16.ogg"] = 1030,["7FSurName-13.ogg"] = 1170,["7FSurName-05.ogg"] = 980,
            ["7FSurName-14.ogg"] = 990,["7FSurName-03.ogg"] = 990,["7FSurName-08.ogg"] = 870,["7FSurName-18.ogg"] = 1050,
            ["7FSurName-10.ogg"] = 950,["7FSurName-09.ogg"] = 1110,["7FSurName-02.ogg"] = 1040,["7FSurName-01.ogg"] = 970,
            ["7FSurName-12.ogg"] = 1140,["7FSurName-19.ogg"] = 1190,["7FSurName-06.ogg"] = 840,["6FName-13.ogg"] = 1070,
            ["6FName-14.ogg"] = 990,["6FName-16.ogg"] = 1090,["6FName-04.ogg"] = 760,["6FName-03.ogg"] = 940,["6FName-12.ogg"] = 1280,
            ["6FName-08.ogg"] = 1140,["6FName-15.ogg"] = 1300,["6FName-10.ogg"] = 1050,["6FName-01.ogg"] = 1130,["6FName-17.ogg"] = 900,
            ["6FName-06.ogg"] = 1080,["6FName-09.ogg"] = 1020,["6FName-07.ogg"] = 1080,["6FName-05.ogg"] = 930,["6FName-02.ogg"] = 990,
            ["6FName-11.ogg"] = 1170,["3MName-17.ogg"] = 850,["3MName-21.ogg"] = 900,["3MName-20.ogg"] = 990,["3MName-07.ogg"] = 930,
            ["3MName-09.ogg"] = 840,["3MName-23.ogg"] = 740,["3MName-05.ogg"] = 750,["3MName-15.ogg"] = 810,["3MName-25.ogg"] = 1120,
            ["3MName-19.ogg"] = 680,["3MName-10.ogg"] = 720,["3MName-01.ogg"] = 880,["3MName-13.ogg"] = 880,["3MName-04.ogg"] = 960,
            ["3MName-16.ogg"] = 990,["3MName-12.ogg"] = 770,["3MName-24.ogg"] = 730,["3MName-14.ogg"] = 930,["3MName-11.ogg"] = 710,
            ["3MName-18.ogg"] = 880,["3MName-06.ogg"] = 950,["3MName-02.ogg"] = 740,["3MName-22.ogg"] = 720,["3MName-08.ogg"] = 830,
            ["3MName-03.ogg"] = 1040,["10MediaType-05.ogg"] = 1130,["10MediaType-04.ogg"] = 1130,["10MediaType-02.ogg"] = 1130,
            ["10MediaType-01.ogg"] = 1170,["10MediaType-03.ogg"] = 1020,["10MediaType-07.ogg"] = 1310,["10MediaType-06.ogg"] = 1180,
            ["4MSurName-09.ogg"] = 1000,["4MSurName-01.ogg"] = 990,["4MSurName-13.ogg"] = 830,["4MSurName-25.ogg"] = 1030,
            ["4MSurName-21.ogg"] = 990,["4MSurName-15.ogg"] = 970,["4MSurName-06.ogg"] = 1020,["4MSurName-11.ogg"] = 1040,
            ["4MSurName-10.ogg"] = 1030,["4MSurName-02.ogg"] = 1050,["4MSurName-19.ogg"] = 890,["4MSurName-04.ogg"] = 1150,
            ["4MSurName-24.ogg"] = 740,["4MSurName-23.ogg"] = 980,["4MSurName-20.ogg"] = 1040,["4MSurName-08.ogg"] = 890,
            ["4MSurName-18.ogg"] = 1090,["4MSurName-26.ogg"] = 1020,["4MSurName-17.ogg"] = 850,["4MSurName-03.ogg"] = 850,
            ["4MSurName-05.ogg"] = 980,["4MSurName-07.ogg"] = 1020,["4MSurName-22.ogg"] = 1130,["4MSurName-16.ogg"] = 990,
            ["4MSurName-14.ogg"] = 890,["4MSurName-12.ogg"] = 990,["2Superlative-18.ogg"] = 1040,["2Superlative-17.ogg"] = 980,
            ["2Superlative-16.ogg"] = 1410,["2Superlative-26.ogg"] = 1200,["2Superlative-27.ogg"] = 1200,["2Superlative-23.ogg"] = 940,
            ["2Superlative-05.ogg"] = 1230,["2Superlative-13.ogg"] = 1220,["2Superlative-28.ogg"] = 1270,["2Superlative-19.ogg"] = 900,
            ["2Superlative-06.ogg"] = 1130,["2Superlative-25.ogg"] = 1290,["2Superlative-10.ogg"] = 1150,["2Superlative-01.ogg"] = 1080,
            ["2Superlative-29.ogg"] = 970,["2Superlative-11.ogg"] = 1430,["2Superlative-04.ogg"] = 1490,["2Superlative-07.ogg"] = 1170,
            ["2Superlative-15.ogg"] = 1320,["2Superlative-22.ogg"] = 1230,["2Superlative-12.ogg"] = 1270,["2Superlative-20.ogg"] = 940,
            ["2Superlative-09.ogg"] = 1140,["2Superlative-02.ogg"] = 1110,["2Superlative-24.ogg"] = 1180,["2Superlative-08.ogg"] = 1230,
            ["2Superlative-14.ogg"] = 1290,["2Superlative-03.ogg"] = 1250,["2Superlative-21.ogg"] = 1040,["11OrderNow-42.ogg"] = 1460,
            ["11OrderNow-24.ogg"] = 1510,["11OrderNow-02.ogg"] = 3170,["11OrderNow-18.ogg"] = 2200,["11OrderNow-06.ogg"] = 1520,
            ["11OrderNow-07.ogg"] = 2100,["11OrderNow-11.ogg"] = 1600,["11OrderNow-15.ogg"] = 1480,["11OrderNow-37.ogg"] = 1580,
            ["11OrderNow-47.ogg"] = 1360,["11OrderNow-17.ogg"] = 1720,["11OrderNow-46.ogg"] = 2100,["11OrderNow-19.ogg"] = 2130,
            ["11OrderNow-10.ogg"] = 1540,["11OrderNow-22.ogg"] = 1980,["11OrderNow-31.ogg"] = 1490,["11OrderNow-45.ogg"] = 1420,
            ["11OrderNow-29.ogg"] = 1670,["11OrderNow-04.ogg"] = 1790,["11OrderNow-05.ogg"] = 1360,["11OrderNow-30.ogg"] = 1790,
            ["11OrderNow-14.ogg"] = 1530,["11OrderNow-21.ogg"] = 1480,["11OrderNow-23.ogg"] = 1620,["11OrderNow-08.ogg"] = 1380,
            ["11OrderNow-28.ogg"] = 1500,["11OrderNow-36.ogg"] = 1440,["11OrderNow-01.ogg"] = 3120,["11OrderNow-35.ogg"] = 1560,
            ["11OrderNow-34.ogg"] = 1630,["11OrderNow-41.ogg"] = 1540,["11OrderNow-12.ogg"] = 1620,["11OrderNow-26.ogg"] = 1630,
            ["11OrderNow-39.ogg"] = 1960,["11OrderNow-16.ogg"] = 1620,["11OrderNow-27.ogg"] = 1560,["11OrderNow-43.ogg"] = 1420,
            ["11OrderNow-32.ogg"] = 1050,["11OrderNow-44.ogg"] = 1750,["11OrderNow-13.ogg"] = 1850,["11OrderNow-25.ogg"] = 1850,
            ["11OrderNow-03.ogg"] = 1860,["11OrderNow-09.ogg"] = 1570,["11OrderNow-48.ogg"] = 1620,["11OrderNow-20.ogg"] = 1710,
            ["11OrderNow-38.ogg"] = 1400,["11OrderNow-40.ogg"] = 1980,["11OrderNow-33.ogg"] = 1830,["8Starring-09.ogg"] = 1400,
            ["8Starring-04.ogg"] = 1040,["8Starring-10.ogg"] = 1190,["8Starring-05.ogg"] = 1000,["8Starring-07.ogg"] = 1070,
            ["8Starring-06.ogg"] = 1020,["8Starring-11.ogg"] = 1320,["8Starring-02.ogg"] = 1800,["8Starring-08.ogg"] = 1290,
            ["8Starring-01.ogg"] = 1790,["8Starring-03.ogg"] = 1630,["1Superlative-10.ogg"] = 1010,["1Superlative-04.ogg"] = 1510,
            ["1Superlative-24.ogg"] = 1430,["1Superlative-23.ogg"] = 1300,["1Superlative-28.ogg"] = 1060,["1Superlative-18.ogg"] = 1600,
            ["1Superlative-27.ogg"] = 1420,["1Superlative-01.ogg"] = 1610,["1Superlative-06.ogg"] = 1170,["1Superlative-09.ogg"] = 1430,
            ["1Superlative-20.ogg"] = 1500,["1Superlative-19.ogg"] = 1640,["1Superlative-14.ogg"] = 1040,["1Superlative-15.ogg"] = 1590,
            ["1Superlative-26.ogg"] = 1210,["1Superlative-07.ogg"] = 1190,["1Superlative-12.ogg"] = 1560,["1Superlative-11.ogg"] = 1020,
            ["1Superlative-05.ogg"] = 1520,["1Superlative-17.ogg"] = 970,["1Superlative-03.ogg"] = 1720,["1Superlative-22.ogg"] = 1070,
            ["1Superlative-16.ogg"] = 1270,["1Superlative-02.ogg"] = 1320,["1Superlative-13.ogg"] = 940,["1Superlative-25.ogg"] = 1450,
            ["1Superlative-21.ogg"] = 1530,["1Superlative-08.ogg"] = 1370,
            ["5Binding-01.ogg"] = 710 ,
            ["5Binding-02.ogg"] = 867 ,
            ["5Binding-03.ogg"] = 1198 ,
            ["5Binding-04.ogg"] = 1269 ,
            ["5Binding-05.ogg"] = 1046 ,
            ["5Binding-06.ogg"] = 867 ,


        }

    hash= getDetermenisticHash()
    assert(hash)
    if not GG.DeterministicCounterAdvertisement then  GG.DeterministicCounterAdvertisement  = 0 end
    GG.DeterministicCounterAdvertisement  = (GG.DeterministicCounterAdvertisement % 22) +1 

    local thisAdvertisementIndex = GG.DeterministicCounterAdvertisement 
    local rootPath = "sounds/advertising/media"
    local identifierList = {
       "1Superlative",
       "2Superlative",
       "3MName",
       "4MSurName",
       "5Binding",
       "6FName",
       "7FSurName", 
       "8Starring",
       "9MediaName",
       "10MediaType",
       "11OrderNow",
    }
    local amountList = {
       ["1Superlative"]=24,
       ["2Superlative"]=29,
       ["3MName"]=25,
       ["4MSurName"]=26,
       ["5Binding"]=6,
       ["6FName"]=17,
       ["7FSurName"]= 19,
       ["8Starring"]=11,
       ["9MediaName"]=48,
       ["10MediaType"]=7,
       ["11OrderNow"]=48,
    }

    --build identifiers
    soundFileType_NameTime_Map= {}
    for i=1, #identifierList do
        local wordPosIdentifier = identifierList[i]
        elements = {}

        for f=1, amountList[wordPosIdentifier] do
            filePath = buildSoundFilePath(rootPath, wordPosIdentifier, f)
            fileName = getFileNameFromPath(filePath)
            if not ListOfMediaAdvertisementFileLength[fileName] then
                echo("File has no sleep:"..fileName)
            end
            elements[#elements +1] = {
                path = filePath,             
                time = ListOfMediaAdvertisementFileLength[fileName] or 900
                }
     
        end
        soundFileType_NameTime_Map[wordPosIdentifier] = elements
    end

    --Resolve Play soundfile
    for i=1, #identifierList do
        local wordPosIdentifier = identifierList[i]
        if wordPosIdentifier == "5Binding" and 
            getDeterministicRandom(hash, math.abs(hash - GG.DeterministicCounterAdvertisement)) > math.ceil(hash * 0.25) then
            wordPosIdentifier = "8Starring"
            i = 8
        end 
        deterministicIndex = ((hash + thisAdvertisementIndex + i) % count(soundFileType_NameTime_Map[wordPosIdentifier])) + 1
        local counter = 0
        for k,element in pairs(soundFileType_NameTime_Map[wordPosIdentifier]) do
            counter = counter +1
            if deterministicIndex == counter then
                Spring.PlaySoundFile(element.path, 1.0)
                Sleep(element.time-100)       
               break 
            end
        end       
    end
end

function shamusYoungCompanyName(hash)

first = {
"i", 
"Green ", 
"Mega",
"Super",
"Omni",
"e",
"Hyper",
"Global ", 
"Vital ", 
"Next ", 
"Pacific ", 
"Metro",
"Unity ", 
"G-",
"Trans",
"Infinity ",  
"Superior ", 
"Monolith ", 
"Best ", 
"Atlantic ", 
"First ", 
"Union ", 
"National"}

second = {
"Biotic",
"Info",
"Data",
"Solar",
"Aerospace",
"Motors",
"Nano",
"Online",
"Circuits",
"Energy",
"Med",
"Robotic",
"Exports",
"Security",
"Systems",
"Financial",
"Industrial",
"Media",
"Materials",
"Foods",
"Networks",
"Shipping",
"Tools",
"Medical",
"Publishing",
"Enterprises",
"Audio",
"Health",
"Bank",
"Imports",
"Apparel",
"Petroleum", 
"Studios"}

third = {
"Corp",
" Inc.",
"Co",
"World",
".Com",
" USA",
" Ltd.",
"Net",
" Tech",
" Labs",
" Mfg.",
" UK",
" Unlimited",
" One",
}

secondHash = reHash(hash)
thirdHash = reHash(secondHash)

firstName = first[(hash % #first)+1] or first[math.random(1,#first)]
secondName = second[(secondHash % #second)+1] or second[math.random(1,#second)]
thirdName = third[(thirdHash % #third)+1] or third[math.random(1,#third)]

return firstName..secondName..thirdName
end


function getCivilianIdFromAgent(idA)
      -- out of time to interrogate
        for disguiseID, agentID in pairs(GG.DisguiseCivilianFor) do
            if idA == agentID then
                return disguiseID
            end
        end
        return nil
end
