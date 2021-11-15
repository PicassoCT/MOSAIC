-- ===================================================================================================================
-- Game Configuration
unitFactor = 0.80

function  getMapCultureMap(mapName)
    mapName = string.lower(mapName)
    mapToCultureDictionary = {
      ["mosaic_lastdayofdubai_v1"] = GG.AllCultures.international   
    }

    if mapToCultureDictionary[mapName] then return mapToCultureDictionary[mapName]  end
 end

 function getInstanceCultureOrDefaultToo(defaultCulture) 
    if GG.InstanceCulture then return GG.InstanceCulture end
    
    mapDependentCulture = getMapCultureMap(Game.mapName)    
    GG.InstanceCulture =  mapDependentCulture or defaultCulture
    
    return GG.InstanceCulture
end

function getModOptionCulture()
    modOptions = Spring.GetModOptions()

    return modOptions.culture
end

function getGameConfig()
    return {
        instance = {
            culture = getInstanceCultureOrDefaultToo(getModOptionCulture() or GG.AllCultures.arabic), -- "international", "western", "asia", "arabic"
            Version = "Alpha: 0.800" 
        },

        numberOfBuildings = math.ceil(100 * unitFactor),
        numberOfVehicles = math.ceil(60 * unitFactor),
        numberOfPersons = math.ceil(75 * unitFactor),
        nightCivilianReductionFactor = 0.125,
        LoadDistributionMax = 5,

        --truck
        truckBreakTimeMinSec= 60,
        truckBreakTimeMaxSec= 360,
	
		
        houseSizeX = 256,
        houseSizeY = 16,
        houseSizeZ = 256,
        innerCitySize = 1024,
  
        allyWaySizeX = 25,
        allyWaySizeZ = 25,
        bonusFirstUnitMoney_S = 12,
        maxParallelIdleAnimations = 20,

        agentConfig = {
            recruitmentRange = 60,
            raidWeaponDownTimeInSeconds = 60,
            raidComRange = 1200,
            raidBonusFactorSatellite = 2.5
        },
        SnipeMiniGame = {

            Aggressor = {StartPoints = 4},
        Defender = {StartPoints = 4}},

        -- ObjectiveRewardRate

        Objectives = {
            RewardCyle = 30 * 60, -- /30 frames = 1 seconds
            Reward = 20
        },
        -- civilianbehaviour
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
        civilianMaxWalkingDistance = 3000,
		

        maxNrPolice = 8,
        policeMaxDispatchTime = 2000,
        policeSpawnMinDistance = 2200, -- preferably at houses
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

        --groundTurretDroneProjectileIntercept
        groundTurretDroneInterceptRate = 256,
        groundTurretDroneMaxInterceptPerSecond = 7,

        --Parachute
        parachuteHeight = 150,
        -- doubleAgentHeight
        doubleAgentHeight = 64,

        -- Dayproperties
        daylength = 28800, -- in frames

        -- Interrogation
        InterrogationTimeInSeconds = 20,
        InterrogationTimeInFrames = 20 * 30,
        InterrogationDistance = 256,

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
            maxRoundLength = 20 * 1000,
            interrogationPropagandaPrice = 50,
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
        PreLaunchLeakSteps = 3, --after 4fth step
        LaunchReadySteps = 7,
        LauncherInterceptTimeSeconds = 20,
        LauncherMaxHeight = 3000,

        -- CruiseMissiles
        CruiseMissilesHeightOverGround = 22,
        cruiseMissileAntiArmorDroplettRange = 1200,
        cruiseMissileChanceOfInterceptOneIn= 25,
        cruiseMissileReloadTimeMS = 5*60*1000,
        
        -- Game States
        GameState = {
            normal = "normal",
            launchleak = "launchleak",
            anarchy = "anarchy",
            postlaunch = "postlaunch",
            gameover = "gameover",
            pacification = "pacification"
        },
        anarchySexCouplesEveryNSeconds = 3 * 60,

        TimeForInterceptionInFrames = 30 * 10,
        TimeForPanicSpreadInFrames = 15 * 30,
        TimeForPacification = 30 * 90,
        TimeForScrapHeapDisappearanceInMs = 3 * 60 * 30, -- 3 Minutes off line

        costs = {
            DestroyedHousePropanda = 5000,
        RecruitingTruck = 500},

        -- startenergymetal
        energyStartVolume = 10000,
        energyStart = 5000,
        metalStartVolume = 10000,
        metalStart = 5000,

        -- Icons
            --Icons
        socialEngineeringRange = 256,
        socialEngineerLifetimeMs = 3*60*1000,
        
        iconGroundOffset = 50,
        iconHoverGroundOffset = 125,
        SatelliteIconDistance = 150,
        SatelliteShrapnellDistance = 450,
        SatelliteShrapnellLifeTime = 7 * 60 * 1000,
        SatelliteShrapnellDamagePerSecond = 1000,
        SatelliteUploadTimesMs = 8000,
        LifeTimeBribeIcon = 60 * 1000,

        -- Hiveminds & AiCores
        integrationRadius = 75,
        maxTimeForSlowMotionRealTimeSeconds = 10,
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
                VictimLiftime = 3 * 60 * 1000
            }, -- 2mins
            tollwutox = {
                sprayTimePerUnitInMs = 2 * 60 * 1000,
                VictimLiftime = 7 * 60 * 1000
            }, -- 2mins
            depressol = {
                sprayTimePerUnitInMs = 2 * 60 * 1000,
                VictimLiftime = 3 * 60 * 1000
            } -- 2mins

        }}
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
   


function  getManualCivilianBuildingMaps(mapName)
    mapName = string.lower(mapName)
    ManualCivilianBuildingPlacement = {
      ["mosaic_lastdayofdubai_v1"] = true
    }
    
    if ManualCivilianBuildingPlacement[mapName] then return ManualCivilianBuildingPlacement[mapName]  end
   end

    function getChemTrailInfluencedTypes(UnitDefs)
        assert(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)

        typeTable = {"civilianagent"}
        typeTable = mergeTables(typeTable, getTypeUnitNameTable(getCultureName(),
        "civilian", UnitDefs))

        return getTypeTable(UnitDefNames, typeTable)
    end

    function getScrapheapTypeTable(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {[UnitDefNames["gcscrapheap"].id] = UnitDefNames["gcscrapheap"].id}
    end

    function getPoliceTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["policetruck"].id] = true,
            [UnitDefNames["ground_tank_night"].id] = true
        }
    end

    function getTurnCoatFactoryType(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["assembly"].id] = true,
            [UnitDefNames["nimrod"].id] = true
        }
    end

    function getObjectiveTypes(UnitDefs)
        assert(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["objective_refugeegyland"].id] = "water",
            [UnitDefNames["objective_factoryship"].id] = "water",
            [UnitDefNames["objective_refugeecamp"].id] = "land",
            [UnitDefNames["objective_powerplant"].id] = "land",
            [UnitDefNames["objective_geoengineering"].id] = "land",
            [UnitDefNames["objective_westhemhq"].id] = "land",
            [UnitDefNames["objective_artificialglacier"].id] = "land",
            [UnitDefNames["objective_combatoutpost"].id] = "land",
            [UnitDefNames["objective_transrapid"].id] = "land",
            [UnitDefNames["objective_airport"].id] = "land"
        }
    end

    function getIconTypes(UnitDefs)
        local UnitDefNames = getUnitDefNames(UnitDefs)
        return {
            [UnitDefNames["raidicon"].id] = true,
            [UnitDefNames["doubleagent"].id] = true,
            [UnitDefNames["interrogationicon"].id] = true,
            [UnitDefNames["recruitcivilian"].id] = true,
            [UnitDefNames["bribeicon"].id] = true,
            [UnitDefNames["socialengineeringicon"].id] = true,
            [UnitDefNames["cybercrimeicon"].id] = true,
            [UnitDefNames["launcherstep"].id] = true,
            [UnitDefNames["destroyedobjectiveicon"].id] = true,
        }
    end  

    function getManualObjectiveSpawnMapNames()
        return {
            ["mosaic_dubai_v1"] = true
        }
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
                Spring.Echo("Error: Unitdef of Unittype " .. Stringtable[i] ..
                " does not exists")
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
        if not GG.innerCityCenter then return false end
        return distance(x, 0, z, GG.innerCityCenter.x, 0,  GG.innerCityCenter.z) < GameConfig.innerCitySize
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

    function getDetermenisticMapHash(Game)
       accumulated = 0
       mapName = Game.mapName
       mapNameLength = string.len(mapName)

      for i=1, mapNameLength do
        accumulated = accumulated + string.byte(mapName,i)
      end

      accumulated = accumulated + Game.mapSizeX
      accumulated = accumulated + Game.mapSizeZ
      return accumulated
    end


    function getCultureMapNameHash(Game)   
        return getMapNameHash(Game) + getCultureHash()
    end

    function getLocationHash(x,z, maxs)
        return ((x + z) % (maxs or 4) + 1)
    end

    function getBuildingTypeHash(unitID, maxType)
        x, y, z = Spring.GetUnitPosition(unitID)
        x, z = math.ceil(x / 1000), math.ceil(z / 1000)
        nice = getLocationHash(x,z, maxType)
        return nice, x,y,z
    end

    function getDeterministicCityOfSin(culture, Game)
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
        districtOffset = getLocationHash(math.ceil(loc.x / 1000), math.ceil(loc.z / 1000), 4)
        if culture == Cultures.arabic then
            rotDegOffset= getDeterministicRotationOffsetForDistrict(getLocationHash(loc.x,loc.z), 5, math.ceil(loc.x / 1000), math.ceil(loc.z / 1000))
            return {
                xRandOffset = 20,
                zRandOffset = 20,
                districtOffset = districtOffset,
                districtRotationDeg = rotDegOffset
            }
        end
        if culture == Cultures.western then  
            --rotDegOffset= getDeterministicRotationOffsetForDistrict(getLocationHash(loc.x,loc.z), 1, math.ceil(loc.x / 1000), math.ceil(loc.z / 1000))
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

        function getSatteliteTypes(UnitDefs)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            typeTable = {
                "satelliteanti", "satellitescan", "satellitegodrod",
                "satelliteshrapnell"
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

        function getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, culture)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            if culture == Cultures.arabic then
                typeTable = {
                    "truck_arab0",
                    "truck_arab1",
                    "truck_arab2",
                    "truck_arab3",
                    "truck_arab4",
                    "truck_arab5"
                }
                return getTypeTable(UnitDefNames, typeTable)
            end

            if culture == Cultures.international then
                    return mergeTables(
                        getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.arabic),
                        getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.western),   
			            getRefugeeAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.asian)
                        )
            end

            return {}
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
                "motorbike"
            }
            return getTypeTable(UnitDefNames, typeTable)
        end

        function getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, culture)
            assert(UnitDefs)
            local UnitDefNames = getUnitDefNames(UnitDefs)
            if culture == Cultures.arabic then
                typeTable = {
                    "truck_arab6",
                    "truck_arab7",
                    "truck_arab8"
                }
                return getTypeTable(UnitDefNames, typeTable)
            end

            if culture == Cultures.international then
                    return mergeTables(
                        getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.arabic),
                        getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.western),                        
                        getLoadAbleTruckTypes(UnitDefs, TruckTypeTable, Cultures.asian))
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
                    ["truck"] = {name = "truck_arab", range = 8}},
                ["international"] = {
                    ["house"] = {name = "house_int", range = 0},
                    ["civilian"] = {name = "civilian_int", range = 0},
                    ["truck"] = {name = "truck_int", range = 3}},
                ["western"] = {
                    ["house"] = {name = "house_western", range = 0},
                    ["civilian"] = {name = "civilian_arab", range = 4},
                    ["truck"] = {name = "truck_western", range = 2}},        
                ["asian"] = {
                    ["house"] = {name = "house_western", range = -1},
                    ["civilian"] = {name = "civilian_arab", range = 4},
                    ["truck"] = {name = "truck_western", range = -1}}
                }
                return translation[cultureName]
            end

            function getCultureUnitModelTypes(cultureName, typeName, UnitDefs)
                UnitDefNames = getUnitDefNames(UnitDefs)
                allNames = getCultureUnitModelNames(cultureName, typeName, UnitDefs)
                result = {}

                for num, name in pairs(allNames) do
                    result[UnitDefNames[name].id] = UnitDefNames[name].id
                end

                return result
            end

            function getCultureUnitModelNames(cultureName, typeName, UnitDefs)
                local translation = getTranslation(cultureName)
                assert(translation , "No translation for "..typeName.." in culture "..cultureName)
                assert(translation[typeName] ~= nil , "No translation for "..typeName.." in culture "..cultureName)
                return expandNameSubSetTable(translation[typeName], UnitDefs)
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

                if culturename == Cultures.international then
                   return mergeTable(
                        getRPGCarryingCivilianTypes(UnitDefs, Cultures.arabic),
                        getRPGCarryingCivilianTypes(UnitDefs, Cultures.western)
                        )
                end
            end

            function getTypeUnitNameTable(culturename, typeDesignation, UnitDefs)
                assert(UnitDefs)
                ID_Name_Map = {}
                if culturename == Cultures.international then
                    ID_Name_Map = mergeTables(
                        getCultureUnitModelNames(Cultures.arabic, typeDesignation, UnitDefs),
                        getCultureUnitModelNames(Cultures.western, typeDesignation, UnitDefs),
                        getCultureUnitModelNames(Cultures.asian, typeDesignation, UnitDefs)
                        )

                else
                    ID_Name_Map = getCultureUnitModelNames(culturename, typeDesignation, UnitDefs)
                end

                results = {}
                for defID, name in pairs(ID_Name_Map) do table.insert(results, name) end

                return results
            end

            function expandNameSubSetTable(SubsetTable, UnitDefs)
                local UnitDefNames = getUnitDefNames(UnitDefs)

                local expandedDictIdName = {}
                local i = 0
                while i <= SubsetTable.range do
                    local key = SubsetTable.name..i
                    if UnitDefNames[key] then
                        -- echo("adding "..SubsetTable.name..i)
                        --  assert(UnitDefNames[key].id)
                        expandedDictIdName[UnitDefNames[key].id] = key
                    end
                    i = i + 1
                end

                return expandedDictIdName
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
                    ["ground_truck_mg"] = "ground_turret_mg",
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
                return getCultureUnitModelTypes(GG.GameConfig.instance.culture,
                "truck", UnitDefs)
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
                          "civilian_western0"
                        }
                    end
                end                

                return getTypeTable(UnitDefNames, typeTable)
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
                    "assembly",
                    "hivemind",
                    "launcher",
                    "launcherstep",
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
                    typeTable = {"nimrod", "propagandaserver", "assembly"}

                else

                    if myDefID == UnitDefNames["antagonsafehouse"].id then
                        typeTable = {
                            "nimrod", "propagandaserver", "assembly", "launcher", "hivemind"
                        }
                    else
                        typeTable = {
                            "nimrod", "blacksite", "propagandaserver", "assembly", "aicore"
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

            function getInterrogateAbleTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "civilianagent", "operativeasset", "operativepropagator",
                    "operativeinvestigator", "antagonsafehouse", "protagonsafehouse",
                    "propagandaserver", "assembly", "launcher", "hivemind", "aicore"
                }

                typeTable = mergeTables(typeTable, getTypeUnitNameTable(
                    GameConfig.instance.culture, "civilian",
                UnitDefs))

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getMobileInterrogateAbleTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "civilianagent", "operativeasset", "operativepropagator",
                    "operativeinvestigator"
                }

                typeTable = mergeTables(typeTable, getTypeUnitNameTable(
                    GameConfig.instance.culture, "civilian",
                UnitDefs))

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getRaidIconTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {"raidicon", "snipeicon", "objectiveicon"}

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getRaidAbleTypeTable(UnitDefs)
                assert(UnitDefs)
                GameConfig = getGameConfig()
                local UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "civilianagent",
                    "operativeasset",
                    "operativepropagator",
                    "operativeinvestigator"
                }

                typeTable = mergeTables(typeTable, getTypeUnitNameTable(
                    GameConfig.instance.culture, "civilian",
                UnitDefs))

                return getTypeTable(UnitDefNames, typeTable)
            end

            function getHouseTypeTable(UnitDefs, culturename)
                assert(UnitDefs)
                return getCultureUnitModelNames(culturename, "house", UnitDefs)
            end

            function getOperativeTypeTable(UnitDefs)

                UnitDefNames = getUnitDefNames(UnitDefs)
                typeTable = {
                    "civilianagent", "operativeasset", "operativepropagator",
                    "operativeinvestigator"
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
                    "innercitydeco_inter3"
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
                    [UnitDefNames["innercitydeco_inter4"].id] = {maxNr = 1, locationFunc = createSetMaxHeight}}
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
                    [UnitDefNames["innercitydeco_inter3"].id] = true
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

            function getUnitDefIDFromName(name)
                for i = 1, #UnitDefs do
                    if name == UnitDefs[i].name then return UnitDefs[i].id end
                end

            end

            function getGroundTurretMGInterceptableProjectileTypes(WeaponDefs)
                TypeTable = {
                    "smartminedrone",
                    "cm_airstrike",
                    "cm_walker",
                    "cm_antiarmor",
                    "cm_turret_ssied"
                    }
                return getWeaponTypeTable(WeaponDefs, TypeTable)
            end 

            function getCruiseMissileProjectileTypes(WeaponDefs)
                TypeTable = {
                    "cm_airstrike",
                    "cm_walker",
                    "cm_antiarmor",
                    "cm_turret_ssied"
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
                    defID = getUnitDefIDFromName(unitName)
                    boolCanBuildSomething = true

                    if defID and not closedTable[defID] then
                        Result[defID] = defID

                        unitsToIntegrate, closedTable =
                        getUnitCanBuildList(defID, closedTable, false)
                        if unitsToIntegrate then
                            for id, _ in pairs(unitsToIntegrate) do

                                if lib_boolDebug == true then
                                    Spring.Echo("+ " .. UnitDefs[id].name)
                                end

                                Result[id] = id
                            end
                        end
                    end
                end
                if boolCanBuildSometing == true then
                    if root == true then
                        Spring.Echo("Unit " .. UnitDefs[unitDefID].name .. " can built:")
                    end
                end

                return Result, closedTable
            end

            ProtagonUnitTypeList = getUnitCanBuildList(UnitDefNames["protagonsafehouse"].id)
            AntagonUnitTypeList = getUnitCanBuildList(UnitDefNames["antagonsafehouse"].id)

            function getUnitSide(unitID)
                defID = Spring.GetUnitDefID(unitID)
                if ProtagonUnitTypeList[defID] then return "protagon" end
                if AntagonUnitTypeList[defID] then return "antagon" end
                return "gaia"
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
                            }}}
                end
            
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
                        return hours, minutes, seconds, percent
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
                                        --echo("Aborting eventstream cause unit has died")
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

                    function attachDoubleAgentToUnit(traitorID, teamToTurnTo, boolRecursive)
                        attachingTo = traitorID.." a "..UnitDefs[Spring.GetUnitDefID(traitorID)].name.." of team "..Spring.GetUnitTeam(traitorID).." is a double agent for team "..teamToTurnTo
                        echo(attachingTo)
                        if not GG.DoubleAgents then GG.DoubleAgents = {} end

                        hoverAboveFunc = function(persPack)
                            boolContinue = false
                            boolEndFunction = true

                            --There can only be one
                            if GG.DoubleAgents[persPack.traitorID] and
                                GG.DoubleAgents[persPack.traitorID] ~= persPack.iconID then
                                return boolEndFunction, nil
                            end

                            if persPack.boolDoneFor then return boolEndFunction, persPack end

                            if doesUnitExistAlive(persPack.traitorID) == false then
                                destroyUnitConditional(persPack.iconID, false, true)
                                return boolEndFunction, nil
                            end

                            x, y, z = Spring.GetUnitPosition(persPack.traitorID)

                            if doesUnitExistAlive(persPack.iconID) == false then
                                persPack.iconID = createUnitAtUnit(persPack.teamToTurnTo, "doubleagent",
                                    persPack.traitorID, x - 1,
                                y + persPack.heightAbove, z)
                                Spring.MoveCtrl.Enable(persPack.iconID)
                                GG.DoubleAgents[persPack.traitorID] = persPack.iconID
                                return boolContinue, persPack
                            end

                            Spring.MoveCtrl.SetPosition(persPack.iconID, x - 1, y + persPack.heightAbove, z)
                            boolUnitIsCloaked = Spring.GetUnitIsCloaked(persPack.iconID)

                            if isUnitComplete(persPack.traitorID) == false then
                                return boolContinue, persPack
                            end

                            --recursive part
                            if persPack.boolRecursive and persPack.boolRecursive == true then
                                if not persPack.ListOfBuildUnits then persPack.ListOfBuildUnits = {} end
                                buildID = Spring.GetUnitIsBuilding(persPack.traitorID)
                                if buildID and not persPack.ListOfBuildUnits[buildID] then
                                    persPack.ListOfBuildUnits[buildID] = buildID
                                    attachDoubleAgentToUnit(buildID, persPack.teamToTurnTo, persPack.boolRecursive)
                                end
                            end

                            if not persPack.boolCloakedAtLeastOnce then
                                persPack.boolCloakedAtLeastOnce = boolUnitIsCloaked
                            end

                            persPack.boolCloakedAtLeastOnce = persPack.boolCloakedAtLeastOnce or boolUnitIsCloaked

                            if persPack.startFrame + 1 < Spring.GetGameFrame() and
                                persPack.boolCloakedAtLeastOnce == true and
                                boolUnitIsCloaked == false then
                                --we copy kill the unit here instead of transfering to another team
                                --to prevent script incosistencies
                                copyUnit(persPack.traitorID, persPack.teamToTurnTo)
                                Spring.DestroyUnit(persPack.iconID, false, true)
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

                        -- Transported
                        if Spring.GetUnitTransporter(persPack.myID) ~= nil and not persPack.boolTransported then
                            persPack.boolTransported = true
							pieceMap = Spring.GetUnitPieceMap(persPack.myID)
							Spring.UnitAttach(persPack.syncedID, persPack.myID, pieceMap["center"])		
                            return frame + 5, persPack
                        elseif persPack.boolTransported == true then
							Spring.UnitDetach(persPack.syncedID)
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
      return region_countryMap.MiddleEast[((hash*69) % #region_countryMap.MiddleEast) +1 ]
    end
    if hash % 3 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ]
    end
    if hash % 3 == 2 then
      return region_countryMap.Africa[((hash*69) % #region_countryMap.Africa) +1 ]
    end
  end

  if culture == "western" then 
    if hash % 3 == 0 then
      return region_countryMap.Europe[((hash*69) % #region_countryMap.Europe) +1 ]
    end
    if hash % 3 == 1 then
      return region_countryMap.NorthAmerica[((hash*69) % #region_countryMap.NorthAmerica) +1 ]
    end
    if hash % 3 == 2 then
      return region_countryMap.SouthAmerica[((hash*69) % #region_countryMap.SouthAmerica) +1 ]
    end
  end

  if culture == "asian" then
    if hash % 2 == 0 then
      return region_countryMap.SouthEastAsia[((hash*69) % #region_countryMap.SouthEastAsia) +1 ]
    end
    if hash % 2 == 1 then
      return region_countryMap.CentralAsia[((hash*69) % #region_countryMap.CentralAsia) +1 ]
    end
  end

  if culture == "international" then
    internationalCityCountries = {"Dubai", "Hong Kong",
      "United States", "United Kingdom", "Japan"}
    return internationalCityCountries[hash % #internationalCityCountries +1]
  end
end

            function initalizeInheritanceManagement()
                -- GG.InheritanceTable = [teamid] ={ [parent] = {[child] = true}}}
                if not GG.InheritanceTable then
                    GG.InheritanceTable = {}
                    for _, teams in pairs(Spring.GetTeamList()) do
                        GG.InheritanceTable[teams] = {}
                    end
                end
            end

            function registerFather(teamID, parent)
                -- Spring.Echo("register Father of unit")
                if not GG.InheritanceTable[teamID][parent] then
                    GG.InheritanceTable[teamID][parent] = {}
                end
            end

            function registerChild(teamID, parent, childID)
                -- Spring.Echo("register Child child of unit")
                if not GG.InheritanceTable[teamID][parent] then
                    GG.InheritanceTable[teamID][parent] = {}
                end

                GG.InheritanceTable[teamID][parent][childID] = true
            end

            function getChildrenOfUnit(teamID, unit)
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

            function registerRevealedUnitLocation(unitID)
                local Location = {}
                Location.x, Location.y, Location.z = Spring.GetUnitBasePosition(unitID)
                Location.teamID = Spring.GetUnitTeam(unitID)
                Location.radius = GetUnitDefRealRadius(unitID)

                local revealedUnits = {}
                parent = getParentOfUnit(Location.teamID, unitID)
                if parent and doesUnitExistAlive(parent) then
                    revealedUnits[parent] = {defID = Spring.GetUnitDefID(parent), boolIsParent = true}
                end

                children = getChildrenOfUnit(Location.teamID, unitID)

                if children and count(children) > 0 then
                    for childID, _ in pairs(children) do
                        if childID and doesUnitExistAlive(childID) then
                            revealedUnits[childID] = {defID = Spring.GetUnitDefID(childID), boolIsParent = false}
                        end
                    end
                end
                Location.revealedUnits = revealedUnits
				Location.endFrame = Spring.GetGameFrame()+ GG.GameConfig.raid.revealGraphLifeTimeFrames

                if not GG.RevealedLocations then GG.RevealedLocations = {} end
                GG.RevealedLocations[#GG.RevealedLocations + 1] = Location
            end

            function giveParachutToUnit(id, x, y, z)
                if not GG.ParachutPassengers then GG.ParachutPassengers = {} end

                if Spring.GetGameFrame() < 1 then

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
                    parachutID =
                    createUnitAtUnit(Spring.GetUnitTeam(id), "air_parachut", id)

                    GG.ParachutPassengers[parachutID] = {id = id, x = x, y = y, z = z}
                    Spring.SetUnitTooltip(parachutID, id .. "")
                    setUnitValueExternal(id, 'WANT_CLOAK', 0)
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

            function getHouseClusterPoints(UnitDefs, culture)

                houseTypeTable = getHouseTypeTable(UnitDefs, culture)
                local PositionTable = {}

                process(Spring.GetAllUnits(), function(id)
                    defID = Spring.GetUnitDefID(id)
                    if houseTypeTable[defID] then return id end
                end, function(id)
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
                    Spring.Echo("cullPositionCluster: PosTable to small")
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
                        Spring.Echo("Aborting with Points:" .. count(culledPoints))
                        return culledPoints
                    end
                end

                return culledPoints
            end

            function computateClusterNodes(housePosTable, GameConfig)
                timeFactor = math.abs(math.sin(math.pi * Spring.GetGameFrame() /
                GameConfig.civilianGatheringBehaviourIntervalFrames)) -- [0 - 1]

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
                    ["Dieing"] = "Dieing"
                }
            end

            function isOffenceIcon(UnitDefs, defID)
                assert(UnitDefs)
                return UnitDefs[defID].name == "bribeicon" or UnitDefs[defID].name == "cybercrimeicon"
            end

            function getAerosolInfluencedStateMachine(unitID, UnitDefs, typeOfInfluence)
                assert(typeOfInfluence)
                AerosolTypes = getChemTrailTypes()
                assert(AerosolTypes[typeOfInfluence])

                InfStates = getInfluencedStates()
                CivilianTypes = getCivilianTypeTable(UnitDefs)

                InfluenceStateMachines = {
                    [AerosolTypes.orgyanyl] = function(lastState, currentState, unitID)
                        if currentState == AerosolTypes.orgyanyl then
                            currentState = InfStates.Init
                        end

                        -- Init
                        if currentState == InfStates.Init then
                            val = math.random(10, 60) / 1000
                            spinT(Spring.GetUnitPieceMap(unitID), z_axis, val * randSign(),
                            0000015)
                            currentState = InfStates.PreOutbreak
                        end

                        if currentState == InfStates.PreOutbreak then
                            val = math.random(10, 60) / 1000
                            spinT(Spring.GetUnitPieceMap(unitID), z_axis, val * randSign(),
                            0000015)

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
                            for i = 1, 3 do
                                stopSpinT(Spring.GetUnitPieceMap(unitID), i)
                            end

                            showID = createUnitAtUnit(Spring.GetGaiaTeamID(),
                            "civilian_orgy_pair", unitID, 0, 0, 0)
                            myDefID = Spring.GetUnitDefID(showID)
                            process(getAllNearUnit(showID, 100),
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
                                currentState = InfStates.Outbreak
                            end

                            if currentState == InfStates.Outbreak then
                                gf = Spring.GetGameFrame()

                                if gf % 27 == 0 then
                                    randPiece = Spring.GetUnitPieceMap(unitID)
                                    for i = 1, 3 do
                                        val = math.random(5, 35) / 100
                                        spinT(Spring.GetUnitPieceMap(unitID), i, val * -1, val,
                                        0.0015)
                                    end
                                end

                                if gf % 81 == 0 then
                                    for i = 1, 3 do
                                        stopSpinT(Spring.GetUnitPieceMap(unitID), i)
                                    end
                                end

                                x = (unitID * 65533) % Game.mapSizeX
                                z = (unitID * 65533) % Game.mapSizeZ
                                f = (Spring.GetGameFrame() %
                                GG.GameConfig.Aerosols.wanderlost.VictimLiftime) /
                                GG.GameConfig.Aerosols.wanderlost.VictimLiftime
                                -- spiraling in towards nowhere
                                totaldistance = math.max(128, unitID % 900) *
                                math.sin(f * 2 * math.pi)
                                tx, tz = Rotate(totaldistance, 0, f * math.pi * 9)
                                x = x + tx
                                z = z + tz
                                Command(unitID, "go", {x = x, y = 0, z = z}, {})
                            end

                            return currentState
                        end,
                        [AerosolTypes.tollwutox] = function(lastState, currentState, unitID)
                            if currentState == AerosolTypes.tollwutox then
                                StartThread(lifeTime, unitID,
                                    GG.GameConfig.Aerosols.tollwutox.VictimLiftime,
                                false, true)
                                currentState = InfStates.Init
                                if math.random(0, 10) > 7 then
                                    currentState = InfStates.Standalone
                                end
                            end

                            gf = Spring.GetGameFrame()
                            attackDistance = 35
                            -- random shivers
                            if gf % 30 == 0 and maRa() then
                                for i = 1, 3 do
                                    val = (math.random(-100, 100) / 100) * 12
                                    turnT(Spring.GetUnitPieceMap(unitID), i, math.rad(val),
                                    30.125)
                                end
                            end

                            enemyDistance = math.huge
                            allyDistance = math.huge

                            local afflicted = GG.AerosolAffectedCivilians or {}
                            T = process(getAllNearUnit(unitID, 750),
                                function(id)
                                    if afflicted[id] then
                                        return id
                                    end
                                end
                            )

                            ad = Spring.GetUnitNearestAlly(unitID)
                            if T and #T > 1 then
                                ad = T[math.random(1, #T)]
                            end

                            if ad then
                                allyDistance = distanceUnitToUnit(unitID, ad)
                            end
                            ed = Spring.GetUnitNearestEnemy(unitID)
                            if ed then
                                enemyDistance = distanceUnitToUnit(unitID, ed)
                            end
                            Spring.SetUnitNeutral(unitID, false)

                            if ed and (not ad or currentState == InfStates.Standalone) then
                                Command(unitID, "go", getUnitPosAsTargetTable(ed), {})
                                if enemyDistance and enemyDistance < 20 then
                                    process(getAllNearUnit(unitID, attackDistance),
                                        function(id)
                                            Spring.AddUnitDamage(id, 30)
                                        end
                                    )
                                end
                                return currentState
                            end

                            if ad and not ed then
                                Command(unitID, "go", getUnitPosAsTargetTable(ad), {})
                                if enemyDistance and enemyDistance < 20 then
                                    process(getAllNearUnit(unitID, attackDistance),
                                        function(id)
                                            Spring.AddUnitDamage(id, 30)
                                        end
                                    )
                                end
                                return currentState
                            end

                            if ad and ed then
                                if enemyDistance > allyDistance or maRa() == true then
                                    Command(unitID, "go", getUnitPosAsTargetTable(ed), {})
                                    if distance(unitID, ed) < attackDistance then
                                        Spring.AddUnitDamage(ed, 30)
                                    end

                                else
                                    Command(unitID, "go", getUnitPosAsTargetTable(ad), {})
                                end
                            end

                            return currentState
                        end,
                        [AerosolTypes.depressol] = function(lastState, currentState, unitID)
                            if currentState == AerosolTypes.depressol then
                                StartThread(lifeTime, unitID,
                                    GG.GameConfig.Aerosols.depressol.VictimLiftime,
                                false, true)
                                currentState = InfStates.Init
                            end
                            stunUnit(unitID, 2)
                            setOverrideAnimationState(eAnimState.standing, eAnimState.wailing,
                            true, nil, true)

                            return currentState
                        end
                    }

                    assert(InfluenceStateMachines[typeOfInfluence], typeOfInfluence)
                    return InfluenceStateMachines[typeOfInfluence]
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
                process(Spring.GetTeamList(), 
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

        function setIndividualCivilianName(id)
            description = "Civilian : "..getRandomCultureNames(GG.GameConfig.instance.culture) .. " <colateral>"
            Spring.SetUnitTooltip(id, description)
            return description
        end

        function getRandomCultureNames(culture)
            names = {
                arabic = {
                    sur = {
                        "Jalal", "Hashim", "Ibrahim", "Ahmed", "Sufian", "Abdullah", "Ahmad", "Omran", "Fateha",
                        "Nada", "Um", "Sahar", "Khowla", "Samad", "Faris", "Saif", "Marwa", "Tabarek", "Safia", "Qassem", "Thamer", "Nujah",
                        "Najia", "Haytham", "Arkan", "Walid", "Hilal", "Manal", "Mahroosa", "Valentina", "Samar", "Mohammad", "Nadia",
                        "Zeena", "Mustafa", "Zain", "Zainab", "Hassan", "Ammar", "Noor", "Wissam", "Dr.Ihab", "Khairiah", "Kamaran", "Duaa",
                        "Sa'la", "Alaa-eddin", "Wadhar", "Bashir", "Safa", "Sena", "Rana", "Maria", "Salma", "Lana", "Miriam", "Lava", "Salma",
                        "Mohammed", "Said", "Shams", "Sami", "Tareq", "Taras", "Jose", "Vatche", "Hanna", "James", "Nicolas", "Edmund", "Wael",
                        "Noor", "Abdul", "Hamsa", "Ali", "Abu", "Rowand", "Haithem", "Nora", "Arkan", "Khansa", "Muhammed", "Rashid", "Ghassan",
                        "Arkan", "Uday", "Dana", "Lamiya", "Abdullah", "Salman", "Waleed", "Tuamer", "Hussein", "Sa'aleh", "Ghanam", "Raeed", "Daoud"
                    },
                    family = {
                        "al Yussuf", "Kamel Radi", "al Rahal", "al Batayneh", "al Ababneh", " al Enezi", "al Serihaine",
                        "Ghazzi", "Abdallah", "Aqeel-Khalil", "Khalil", "Abdel-Fattah", "Rabai", "El Baur", "Abbas", "Moussa", "Abdel-Wahid",
                        "Abdel-Ridda", "Hussein", "Rafi", "Daif", "Abu Shaker ", "Faraj Silo", "SaadAllah Matti ", "Jarjis ", "Bashar Faraj ",
                        " Hussein ", "Ahmed ", "Kalaf ", "Akram Hamoodi ", " Akram Hamoodi ", "El Abideen Akram Hammodi ",
                        "Akram Hamoody Hamoodi ", "Iyad Hamoodi ", "Muhammad Hamoodi", "Elhuda Saad Hamoodi ", "Abed Hamoodi ",
                        "Abed ", "Mahmoud  ", "Abdurazaq Muhamed ", "Raheem ", "al-Mousai ", " Khazal ", "Handi", "Handi ", "Karim ",
                        "Hassad ", "Hassad ", " Hassa", "Sami ", "Sami ", "Sami ", "Sami ", "Amin ", "Amin ", "Amin ", "Amin ", "Osama  ",
                        "Ayoub ", " Protsyuk", " Couso", " Arslanian ", " Fatah ", " Kachadoorian ", " Kachadoorian ", " Kachadoorian ",
                        " Sabah ", "Sabah ", " Khader ", " Mohammed Omar ", " Ramzi ", " Salam Abdul Gafir ", " Mohammed Suleiman ",
                        " Tamini ", "Tamini ", " David Belu ", " a Thaib ", " al-Barheini ", " Majid ", " Majid ", "Majid ", "al Shimarey ",
                        "Ali ", " Ali ", "Abdul-Majeed al-Sa'doon", " Abu al-Heel ", "Saleh Abdel-Latif", " Abdel Hamid ", " Rashid ",
                        " al Jumaili ", "Amar ", " Qais ", "al Rifaai"
                    }},
                 western = {
                        sur = {
                            "Noel", "Joel", "Mateo", "Ergi", "Luis", "Aron", "Samuel", "Roan", "Roel", "Xhoel",
                            "Marc", "Eric", "Jan", " Daniel", "Enzo", "Ian", " Pol", " Àlex", "Jordi", "Martí",
                            "Lukas", "Maximilian", "Jakob", "David", "Tobias", "Paul", "Jonas", "Felix", "Alexander", "Elias",
                            "Lucas", "Louis", "Noah", "Nathan", "Adam", "Arthur", "Mohamed", " Victor", "Mathis", "Liam",
                            "Nathan", "Hugo", "Louis", "Théo", "Ethan", "Noah", "Lucas", "Gabriel", " Arthur", "Tom",
                            "Adam", "Mohamed", " Rayan", "Gabriel", " Anas", "David", "Lucas", "Yanis", "Nathan", "Ibrahim",
                            "Ahmed", "Daris", "Amar", "Davud", "Adin", "Hamza", "Harun", "Vedad", "Imran", "Tarik",
                            "Luka", "David", "Ivan", "Jakov", "Marko", "Petar", "Filip", "Matej", "Mateo", "Leon",
                            "Jakub", "Jan", " Tomáš", "David", "Adam", "Matyáš", "Filip", "Vojtěch", " Ondřej", "Lukáš",
                            "William", " Noah", "Oscar", "Lucas", "Victor", "Malthe", "Oliver", "Alfred", "Carl", "Valdemar", "Florian",
                            "Oliver", "George", "Noah", "Arthur", "Harry", "Leo", " Muhammad", "Jack", "Charlie", "Oscar",
                            "Leo", " Elias", "Oliver", "Eino", "Väinö", "Eeli", "Noel", "Leevi", "Onni", "Hugo",
                            "Emil", "Liam", "William", " Oliver", "Edvin", "Max", " Hugo", "Benjamin", "Elias", "Leo",
                            "Gabriel", " Louis", "Raphaël", " Jules", "Adam", "Lucas", "Léo", " Hugo", "Arthur", "Nathan",
                            "Ben", " Jonas", "Leon", "Elias", "Finn", "Noah", "Paul", "Luis", "Lukas",
                            "Leonardo", "Francesco", "Alessandro", "Lorenzo", " Mattia", "Andrea", "Gabriele", "Riccardo", "Tommaso", "Edoardo",
                            "William", " Oskar", "Lucas", "Mathias", " Filip", "Oliver", "Jakob/Jacob", " Emil", "Noah", "Aksel", "Hugo", "Daniel",
                            "Martín", "Pablo", "Alejandro", "Lucas", "Álvaro", "Adrián", "Mateo", "David",
                            "Amelia", "Ajla", "Melisa", "Amelija", " Klea", "Sara", "Kejsi", "Noemi", "Alesia", "Leandra",
                            "Anna", "Hannah", "Sophia", "Emma", "Marie", "Lena", "Sarah", "Sophie", "Laura", "Mia",
                            "Emma", "Louise", "Olivia", "Elise", "Alice", "Juliette", "Mila", "Lucie", "Marie", "Camille",
                            "Léa", " Lucie", "Emma", "Zoé", " Louise", "Camille", " Manon", "Chloé", "Alice", "Clara",
                            "Olivia", "Amelia", "Emily", "Isla", "Ava", " Jessica", " Isabella", "Lily", "Ella", "Mia",
                            "Aino", "Aada", "Sofia", "Eevi", "Olivia", "Lilja", "Helmi", "Ellen", "Emilia", "Ella",
                            "Emma", "Louise", "Jade", "Alice", "Chloé", "Lina", "Mila", "Léa", " Manon", "Rose",
                            "Emily", "Ella", "Grace", "Sophie", "Olivia", "Anna", "Amelia", "Aoife", "Lucy", "Ava",
                            "Lucía", "Martina", " María", "Sofía", "Paula", "Daniela", " Valeria", " Alba", "Julia", "Noa",
                            "Mia", " Emma", "Elena", "Sofia", "Lena", "Emilia", "Lara", "Anna", "Laura", "Mila",
                            "Alice", "Lilly", "Maja", "Elsa", "Ella", "Alicia", "Olivia", "Julia", "Ebba", "Wilma"
                        },
                        family = {
                            "Silva", "Garcia", "Murphy", "Hansen", "Johansson", "Korhonen", "Jensen", "De Jong", "Peeters", "Müller", "Rossi", "Borg",
                            "Novák", "Horvath", "Nowak", "Kazlauskas", "Bērziņš", "Ivanov", "Zajac", "Melnyk", "Popa", "Nagy", "Novak", "Horvat", "Petrović",
                            "Hodžić", "Hoxha", "Dimitrov", "Milevski", "Papadopoulos", "Öztürk", "Martin", "Smith"
                        }},
                    }
		
	         --merge all name types for international into superset
		 international = {sur = {}, family = {}}
		  for culture, data in pairs(names) do
		  	for nameType, names in pairs(data) do
			   for i=1, #names do
				international[nameType][#international[nameType]+1] = names[i]	
			   end
			end
		  end

                    return names[culture].sur[math.random(1, #names[culture].sur)] .. " "..names[culture].family[math.random(1, #names[culture].family)]
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
    Spring.Echo("Table getter of name "..name.." is missing")
    assert(true==false)
end

function TODO(task)
    Spring.Echo("TODO:"..task)
    assert(true==false)
end
