--lib static string

function getFirstShopName(firstName)
   -- Get the first letter of the first name
    local firstLetter = firstName:sub(1, 1):upper()
    local secondLetter = firstName:sub(2, 2):upper()

    -- Example more generic products for each letter
    products = {
        A = "Art",
        B = "Bakery",
        C = "Crafts",    
        D = "Designer",
        E = "Essentials",
        F = "Fashion",
        G = "Goods",
        H = "Housewares",
        I = "Items",
        J = "Jewelry",
        K = "Knick-knacks",
        L = "Luxury",
        M = "Meats",
        N = "NAS-TEA",
        O = "Outfits",
        P = "Pets",
        Q = "Quality",
        R = "Rituals",
        S = "Supplies",
        T = "Toys",
        U = "Used Goods",
        V = "Vegetables",
        W = "Wares",
        X = "Xtras",
        Y = "Yarns",
        Z = "Zest"
    }
    if products[secondLetter] then
        products.D = "Designer " .. products[secondLetter]
    else
        key, val = randDict(products)
        products.D = "Designer ".. val
    end

    broducts = {       
        A = {"Adult Entertainment", "Appsassins", "Anal Toyz", "Artificial Animals", "Augment Surgeons"},
        B = {"Bunkers", "Bombs", "BDSM", "BadBets", "Blacklight Bazaar", "Biohackers Anonymous"},
        C = {"Corpse Dispossal", "Cannibalist", "Cybernetics", "Cryo Coffins", "Clone Customizers"},
        D = {"Drones", "Disinformation", "Dildos", "Dream Dealers", "Dead Drop Safes"},
        E = {"Energy Cells", "Emergency Rations", "Exoskeletons", "Euphoria Injectors"},
        F = {"Fuel", "Fire Insurrance", "Flesh Weavers", "Fission Pods"},
        G = {"Gadgets", "Gangbangs", "Gangstaswag", "Grave Roboticists", "Genetic Hackers"},
        H = {"Hazmat Suits", "Hentai", "Hackz", "Hollow Happiness", "Hyperdrugs"},
        I = {"Infotrade", "Infernal Orgies", "Illegal Implants", "Insomnia Clinics", "Identity Changers"},
        J = {"Jewel Surgery", "Jaded", "Juvenation Chambers", "Junkyards"},
        K = {"Kinetic Weapons", "Killer4Hire", "Kryostasis Modules", "Knife Emporiums"},
        L = {"Life Extensions", "Lingerie", "Lottery", "Limbsmiths", "Liquid Shadows"},
        M = {"Methamphetamins", "Memory Markets", "Mind Augmentation Labs"},
        N = {"NeuralKink Install", "NanoTechs", "Nightmare Busters"},
        O = {"Oxygen", "Orchidsap", "Organ Forges", "Overdrive Enhancers", "Oldworld Archives"},
        P = {"Protective Gear", "Penetraitors", "Plasma Blades", "Psychotropic Vendors"},
        Q = {"Quarantine Tests", "Quantum Encryptors", "Quick Kill Armory"},
        R = {"Radiation Mitigation", "Robo-Pets", "Reactor Repairs", "Rapture Pods"},
        S = {"Skinjobs", "Slaves", "Synthetic Skins", "Silicon Sanctuaries"},
        T = {"Tactical Tools", "Toxin Filters", "Time Dilation Dealers"},
        U = {"Underwear", "Universal Basic Income", "Underground Labs", "Untraceable Couriers"},
        V = {"Vaccine Serums", "Virtual Reality Escapes", "Void Traders"},
        W = {"Water Purifiers", "Weaponized Drones", "Wasteland Gear"},
        X = {"Xtreme Sports", "Xeno Adoptions", "X-Ray Mods"},
        Y = {"YouPorn Emporium", "Yield Modifiers", "Yakuza Services"},
        Z = {"Zero Neuro Pearls", "Ziggurat Architects", "Zenith Solutions"}
    }
    
    -- Get the product corresponding to the first letter
    local product = products[firstLetter] or "Products"
    if maRa() then
        assert(secondLetter)
        assert(firstLetter)
        assert(firstLetter)
        assert(broducts)
        if not broducts[firstLetter] then return "NoName Shop" end
        index = (string.byte(secondLetter) % (#broducts[firstLetter])) +1
        assert(broducts[firstLetter][index])
        product = broducts[firstLetter][index] 
    end
    -- Concatenate the first name and the product with the shop name
    local shopName = firstName .. "'s " .. product
    
    return shopName
end

function getHouseShopName(id,  buisnessNamesTable, UnitDefs)
	hash = getDeterministicStationaryUnitHash(id) % 100 
    houseHasShop = hash > 75   
	if houseHasShop then
        x,y, z = Spring.GetUnitPosition(id)
        local houseStreetDim = {}
        local gameConfig = GG.GameConfig
        houseStreetDim.x, houseStreetDim.y, houseStreetDim.z = gameConfig.houseSizeX + gameConfig.allyWaySizeX, gameConfig.houseSizeY, gameConfig.houseSizeZ + gameConfig.allyWaySizeZ
        isLocalShop = (hash % 3 == 0) and not isNearCityCenter(x * houseStreetDim.x, z* houseStreetDim.z, gameConfig)
		if isLocalShop then
            --ownerId = 
            first, sur =  getDeterministicCultureNames(id+ math.random(1,3000), UnitDefs, gameConfig.instance.culture, true)
		    if maRa() then
                return getFirstShopName(first)
            else
                return getFirstShopName(sur)
            end
        else            
            return buisnessNamesTable[(id +  (hash% #buisnessNamesTable)) +1]
        end
	end
end

function setHouseStreetNameTooltip(id, detailXHash, detailZHash, Game, boolInnerCityBlock, UnitDefs, buisnessNamesTable)
    detailXHash = math.floor(detailXHash)
    detailZHash = math.floor(detailZHash)

    region = getRegionByCulture(GG.GameConfig.instance.culture, getDetermenisticMapHash(Game))
    assert(region)
    if not GG.UsedStreetNameCounterDict then
        GG.UsedStreetNameCounterDict = {}
    end

    addition = addition or ""
    if not GG.Streetnames then
        playername = getRandomPlayerName()
        Highway = "Highway" .. math.random(1, 20)
        Doctorstreet = "Dr." .. playername .. " street"
        GG.Streetnames = {
            NorthAmerica = {
                "Freedomstr",
                "Suburbialley",
                "Veteranstreet",
                "Plaza da Revoluzion",
                "Mainstreet",
                "Pinestreet",
                "Cedarstreet",
                "Cypressstreet",
                "Vistaroad",
                "Lakestr",
                "First Street",
                "Second Street",
                "Third Street",
                "Parkstr",
                "Ninthstr",
                "Washingtonstr",
                "High Street",
                "Station Street",
                "Main Street",
                "Grand Canal Way",
                "MacMansion Road",
                "Woolworth alley",
                "Buy N Large Ring",
                "Wallmartstreet",
                },
            Europe = {
                "Deichstraße",
                "Prinzregentenstraße",
                "Tauentzienstraße",
                "Karl-Liebknecht-Straße",
                "Turmstraße",
                "Ludwigstrasse",
                "Voßstraße",
                "Leipziger Straße",
                "Ebertstraße",
                "Frankfurter Allee",
                "Brienner Straße",
                "Frauenbruennl Straße",
                "Schönhauser Allee",
                "Wilhelmstraße",
                "Raiffeisenstraße",
                "Rathausgasse",
                Doctorstreet,
                "Hauptstraße",
                "Schulstraße",
                "Dorfstraße",
                "Bahnhofstraße",
                "Feldgasse",
                "Champs-Élysées",
                "Avenue Victor Hugo",
                "Avenue Montaigne",
                "Rue de Rivoli",
                "Rue Saint-Rustique",
                "Rue Saint-Dominique",
                "Rue Vieille du Temple",
                "Rue Sainte-Catherine",
                "Rue de l'Eglise",
                "Place de l'Eglise",
                "Grande Rue",
                "Kerkstraat",
                "Molenstraat",
                "Schoolstraat",
                "Zahradní",
                "Krátká",
                "Nádražní",
                "Lærkevej",
                "Birkevej",
                "Vinkelvej",
                "Rantatie",
                "Kirkkotie",
                "Koulutie",
                "Petőfi Sándor utca",
                "Kossuth Lajos utca",
                "Rákóczi utca",
                "Via Roma",
                "Via Garibaldi",
                "Via Marconi",
                "Liepų",
                "Miško",
                "Beržų",
                "Rue de l’Église",
                "Rue des Champs",
                "Rue des Prés",
                "Центральная улица",
                "Молодёжная улица",
                "Школьная Улица",
                "Školská",
                "Hlavná",
                "Nová",
                "calle Mayor",
                "calle Iglesia",
                "calle Real",
                "Kifissias Avenue",
                "Peiraios Street",
                "Voukourestiou Street"
            },
            Africa = {
                "Muizz Street",
                "Saliba Street",
                "Talaat Harb Street",
                "Qasr El Nil Street",
                "Mohammed Mazhar Street",
                "Chemin poirson Lot",
                "Rue Colonel Othmane",
                "Boulevard Hassan",
                "jbal jloud ",
                "Rue Chabane El Bhouri",
                "Ave Ali Belhouane",
                "Ave Ouled Hafouz",
                "Jan Smuts Avenue",
                "Beyers Naudé Drive",
                "Bloemfontein Ring Road",
                "Adderley Street",
                "Long Street",
                "Strand Street",
                "Louis Botha Avenue",
                "Malibongwe Drive",
                "Polokwane Ring Road",
                "Kinshasa Highway",
                "Mbarara–Kisangani Road",
                "Avenue kimpika",
                "Salongo",
                "Ngwiziani",
                "Avenue du 30 juin",
                "Avenue Manenga",
                "Avenue Kemba",
                "Avenue Diwaz",
                "Broad Street",
                "Allen Avenue",
                "Toyin Street",
                "Ademola Adetokunbo Street",
                "Ozumba Mbadiwe Avenue",
                "Adeola Odeku Street",
                "Ogunlana Drive",
                "Adeniran Ogunsanya Street",
                "Cameroon Street",
                "Kazanchis",
                "Equatorial Guinea street",
                "Gabon street",
                "kenyatta avenue",
                "kimathi street",
                "muindi mbingu",
                "koinange street",
                "wabera street",
                "biashara street",
                "tom mboya street",
                "moi avenue",
                "Jidka Sodonka",
                "W21ka Nofeembar",
                "Jidka Waxaracadde",
                Doctorstreet
            },
            MiddleEast = {
                "Tunisiastreet",
                "Libyastreet",
                "Sudanstreet",
                "Syriaring",
                "Saudi Arabia street",
                "Jordanstreet",
                "Kuwait street",
                "Bruneistreet",
                "Algeriastreet",
                "Turkeystreet",
                "Iran road",
                "Lebanonstreet",
                "Qatarstreet",
                "West Bankstreet",
                "United Arab Emiratesstreet",
                "Israelplaza",
                "Bahrainstreet",
                "Gaza Stripstreet",
                "Armeniastreet",
                "Iraqroad",
                "Omanstreet",
                "Yemenstreet",
                "Egyptstreet",
                "Moroccostreet",
                "Pakistanstreet",
                "Mauritaniastreet",
                "Ain El Remmaneh",
                "Badaro",
                "Escalier de l'Art",
                "Avenue des Français",
                "Avenue General de Gaulle",
                "Rue Gouraud",
                "Hamra Street",
                "Rue Huvelin",
                "Rue Jeanne d'Arc",
                "Rue Maarad",
                "Mar Mikhaël",
                "Avenue de Paris",
                "Rue de Phénicie",
                "Rue George Post",
                "Sassine Square",
                "Rue Spears",
                "Rue Sursock",
                "Rue Van Dyck",
                "Rue Verdun",
                "Rue Weygand",
                "Allenby Street",
                "Ben Yehuda Street",
                "Dizengoff Street",
                "HaArba'a Street",
                "HaMasger Street",
                "HaYarkon Street",
                Highway,
                Doctorstreet,
                "Ibn Gabirol Street",
                "Jerusalem Boulevard",
                "Kaplan Street",
                "King George Street",
                "Rothschild Boulevard",
                "Yefet Street",
                "Al-Amarah",
                "Bab al-Saghir",
                "Baghdad Street ",
                "Straight Street",
                "Falastin Street",
                "Haifa Street",
                "Mutanabbi Street",
                "Al Rasheed Street",
                "Aghdasieh",
                "Azadi Avenue",
                " Damavand Street",
                "Doulat",
                "Enqelab Street",
                "Farmanieh",
                "Ferdowsi Street",
                "Imam Hossein Square",
                "Jomhuri",
                "Kargar Street",
                "Keshavarz Boulevard",
                "Khayyam Street",
                "Laleh-Zar Street",
                "Mirdamad Boulevard",
                "Nelson Mandela Boulevard ",
                "Nimr Baqir al-Nimr Street",
                "Pasdaranroad",
                "Pasteur Street",
                "Rah Ahan Square",
                "Seoul Street",
                "Shush Street",
                "Si-e Tir street",
                "Sohrevardi Street",
                "Surena Street",
                "Tohid avenue",
                "Valiasr Street",
                "Happiness Street",
                "Alserkal Avenue",
                "Al Meydan Road",
                "Sheikh Mohammed bin Rashid Boulevard",
                "The Palm Jumeirah",
                "2nd December Street",
                "Jumeirah Street",
                "King Salman bin Abdulaziz Al Saud Street",
                "Admiralty Way",
                "Anchor Cir",
                "Beam Dr",
                "Bounty Ave",
                "Cabana Cir",
                "İstiklal Caddesi",
                "Bağdat Caddesi",
                "Abdi İpekçi Caddesi",
                "Nispetiye Caddesi",
                "Nuruosmaniye Caddesi",
                "Gaser Ahmed Road",
                "Rue Abou El Kacem Chebbi",
                "Rue El Fell",
                "Tripoli Street"
            },
            CentralAsia = {
                "Bhutanstr",
                "Thimphustr",
                "Tajikistanstr",
                "Dushanbestr",
                "Teheranstr",
                "Iranstr",
                "Georgiastr",
                "Nepalstr",
                "Azerbaijanstr",
                "Russiastr",
                "Kyrgyzstanstr",
                "Kabulstr",
                "Afghanistanstr",
                "Turkmenistanstr",
                "Pakistanstr",
                "Hyderabadstr",
                "Uzbekistanstr",
                "Mongoliastr",
                "Kazakhstanstr"
            },
            SouthAmerica = {
                "Jirón de la Unión",
                "9 de Julio Avenue",
                "R Gen. Carneiro",
                "Avenida Jose Larco",
                "Córdoba Street",
                "Paseo de la Catedral",
                "Florida Street",
                "Paseo Mercaderes",
                "Oceanic Avenue",
                "Via Costeira",
                "Avenue Bernard O Higgins",
                "Avenue Prestes Maia",
                "Avenue Radial Leste-oeste",
                "Avenida Leandro N. Alem",
                "Caminito",
                "Avenida Rivadavia",
                "Avenida Alvear",
                "Avenida Raúl Scalabrini Ortiz",
                "Avenida Corrientes",
                "Bandeirantes Avenue",
                "Avenida del Libertador",
                "Brigadeiro Faria Lima Avenue",
                "Avenida de Mayo",
                "Engenheiro Luís Carlos Berrini Avenue",
                "Avenida Presidente Vargas",
                "Rua Oscar Freire",
                "Avenida Coronel Díaz",
                "Gonçalo de Carvalho Street",
                "Avenida Figueroa Alcorta",
                "Avenida General Paz",
                "Avenida Pueyrredón",
                "Paseo de la Republica",
                "Avenida Roque Sáenz Peña",
                "Avenida Santa Fe",
                Doctorstreet
            },
            SouthEastAsia = {
                "Jianshe Road",
                "Minzhu Road",
                "Renmin Road",
                "Xinghua Road",
                "Wenhua Road",
                "Huayuan Road",
                "Binghe Road",
                "Youai Road",
                "Huzhu Road",
                "Zhongyuan Road",
                Doctorstreet
            },
            International = {
                "Main Street",
                "Elm Street",
                "Maple Avenue",
                "Oak Lane",
                "Pine Street",
                "Willow Road",
                "Cedar Avenue",
                "Park Avenue",
                "River Street",
                "Sunset Boulevard",
                "Forest Drive",
                "Meadow Lane",
                "Lakeview Terrace",
                "Valley Road",
                "Mountain Avenue",
                "Sunrise Avenue",
                "Central Avenue",
                "High Street",
                "Broad Avenue",
                "Green Street", 
                Doctorstreet
            }
        }
    end
    local Streetnames = GG.Streetnames

    name = "DropTable Adress;404.Haxxorstreet"
    if not Streetnames[region] then
        Spring.Echo("Error:Region not defined:" .. region .. ". Defaulting to us")
        region = "NorthAmerica"
    end

    if isCrossway((detailXHash%4)+1, (detailZHash %4) +1, boolInnerCityBlock) then
       
        name = Streetnames[region][(detailXHash % (#Streetnames[region])) + 1]

        --name ="(Querstrasse:x="..detailXHash.."/z="..detailZHash..")"
    else
       
        name = Streetnames[region][(detailZHash % (#Streetnames[region])) + 1] 
        --name ="(Laengstrasse:x="..detailXHash.."/z="..detailZHash..")"
    end

    if nil == GG.UsedStreetNameCounterDict[name] then
        GG.UsedStreetNameCounterDict[name] = 0
    end
    GG.UsedStreetNameCounterDict[name] = GG.UsedStreetNameCounterDict[name] + 1
    Spring.SetUnitTooltip(id, HouseDescriptor(id, detailXHash + detailZHash, UnitDefs,buisnessNamesTable).." - "..name .. "." .. GG.UsedStreetNameCounterDict[name].. " "..addition)
end


function HouseDescriptor(id, hash,UnitDefs, buisnessNamesTable)
    
    if hash % 2 == 0 then
        houseShopName = getHouseShopName(id,  buisnessNamesTable, UnitDefs)
        if houseShopName then return houseShopName end
    end

    blockType = {
        "Housing Block",
        "PreWar House",
        "Breshnevka",        
        "Khrushovka",
        "Belle Epoche Building",
        "Oligarchy Era House",
        "PreCollapse House",
        "CivilWarReconstruction",
        "AutoFabricated Housing",
        "Restorated Building",
        "Retro Reprint",
	    "Social Housing",
	    "TerraFoam",
	    "Abandoned Investment",
        "Leasehold",
        "Privat Property",
        "[Data Entry Removed]",
        "[GovDB]ResidenceLookUp failed: No such Building",
        "PreFlood Replica",
        "Prefabricated Housing"
    }
    
    return blockType[(hash % #blockType) +1]
end

function getShizoBabbleRant(lines)
    local worries = {
      "financial stability",
      "losing a job",
      "not having enough savings",
      "retirement planning",
      "paying off debt",
      "affording healthcare",
      "cost of education",
      "housing costs",
      "unexpected expenses",
      "inflation and rising prices",
      "personal health issues",
      "the health of family members",
      "developing chronic illness",
      "mental health struggles",
      "weight and body image",
      "aging and losing independence",
      "accidents or injuries",
      "access to proper healthcare",
      "pandemic or epidemic outbreaks",
      "sleep problems",
      "relationship conflicts",
      "marriage stability",
      "divorce or breakup",
      "loneliness",
      "family expectations",
      "children’s future",
      "parenting struggles",
      "social rejection",
      "friendships fading",
      "not finding a partner",
      "career growth",
      "job performance",
      "lack of recognition at work",
      "work–life balance",
      "office politics",
      "changing careers",
      "not being skilled enough",
      "public speaking",
      "meeting deadlines",
      "job interviews",
      "safety and crime",
      "natural disasters",
      "political instability",
      "war or terrorism",
      "climate change",
      "losing important documents",
      "travel safety",
      "online privacy and data theft",
      "technology replacing jobs",
      "the uncertainty of the future"
    }

    local theories = {
      "the Illuminati quietly steering world events",
      "a looming New World Order",
      "chemtrails tweaking the populace",
      "5G towers whispering mind-control signals",
      "HAARP nudging the weather like a thermostat",
      "the Earth being flat and maps being lies",
      "the moon landing staged on a soundstage",
      "reptilian shapeshifters smiling on TV",
      "engineered storms disguised as ‘natural’ disasters",
      "crisis actors choreographing the nightly news",
      "a shadowy Deep State pulling the strings",
      "the Mandela Effect rewriting our memories",
      "time travelers patching the timeline on weekends",
      "the Philadelphia Experiment tearing little rips in space",
      "CERN opening portals to who-knows-where",
      "a hollow Earth with VIP parking inside",
      "a Bigfoot cover-up bigger than Bigfoot",
      "UFO reverse-engineering hidden in plain sight",
      "ancient aliens building all the monuments",
      "suppressed free energy gathering dust in a vault",
      "fluoridation as a compliance cocktail",
      "microchips lurking in everyday jabs and gadgets",
      "a planned global currency reset by a cabal",
      "MK-inspired media psyops on loop",
      "psychic warfare and remote viewing think tanks",
      "Bermuda Triangle field tests gone wrong",
      "UFOs rebranded as weather balloons (again)",
      "pharma burying simple natural cures",
      "Templar-level secret societies swapping passwords",
      "numerology codes steering the stock market",
      "crop circles as memo pads from beyond",
      "staged pandemics as levers of control",
      "leaders replaced by deepfake doubles",
      "a creeping global social credit grid",
      "smart fridges moonlighting as spies",
      "a simulation run by bored elites",
      "an AI overlord already calling the shots",
      "ancient underground cities beneath our feet",
      "food additives tuned for docility",
      "mind-reading satellites orbiting overhead",
      "archaeology timelines quietly airbrushed",
      "secret bases on the far side of the Moon",
      "Antarctica cordoned off for hidden stuff",
      "weather insurance schemes profiting on storms",
      "‘ghost frequencies’ nudging public mood",
      "celebrity occult parties with odd dress codes",
      "tunnels under cities connecting everything",
      "lottery numbers being gently steered",
      "cloud seeding as a cash machine",
      "directed-energy beams starting suspicious fires"
    }

    -- Utility: shallow copy + Fisher–Yates shuffle
    local function shuffled(t)
      local c = {}
      for i = 1, #t do c[i] = t[i] end
      for i = #c, 2, 1 do
        local j = math.random(i)
        c[i], c[j] = c[j], c[i]
      end
      return c
    end

    local openers = {
      "Listen, it all connects:",
      "You ever notice the pattern?",
      "Okay, so here’s what they don’t want you to map out:",
      "Call me wild, but the dots line up:",
      "I did the math on a napkin and—boom—",
      "They might call me crazy but -"
    }

    local links = {
      "which obviously loops back to",
      "and that’s precisely why it’s tied to",
      "and if you trace the paperwork, you hit",
      "which the headlines ‘forget’ to mention is part of",
      "and the timing always exposes",
      "and every breadcrumb points straight at",
      "so of course it intersects with",
      "and the pattern screams",
      "is obviously in on it with",
      "and did you ever notice how that rhymes with"
    }

    local pivots = {
      "Then it gets weirder:",
      "But wait—there’s a twist:",
      "Here’s the kicker:",
      "And just when you think you’ve got it:",
      "Naturally, the rabbit hole deepens:"
    }

    -- Create shuffled copies so every run feels fresh
    local W = shuffled(worries)
    local T = shuffled(theories)

    -- Builder
    local parts = {}
    parts[#parts+1] = openers[math.random(#openers)] .. " "

    -- Start with the first pair
    parts[#parts+1] = ("I’m worried about %s, %s %s. "):format(
      W[1],
      links[math.random(#links)],
      T[1]
    )

    -- Chain the rest, weaving previous -> next
    for i = 2, math.min(#W, #T) do
      -- sprinkle pivots occasionally
      if i % 5 == 0 then
        parts[#parts+1] = pivots[math.random(#pivots)] .. " "
      end
      parts[#parts+1] = ("Then %s connects to %s, %s %s.  "):format(
        W[i-1],
        W[i],
        links[math.random(#links)],
        T[i]
      )
    end
    parts = {unpack(parts, 1, math.min(lines, #parts))}
    -- Grand “ta-da”
    parts[#parts+1] = ("So yeah, by the time you zoom out - its all connected."):format(math.min(#W, #T))

    return parts
end

function setIndividualCivilianName(id, culture, UnitDefs)
    name, family = getDeterministicCultureNames( id,UnitDefs , culture )
    fullName = ""
    if culture == "western" or culture == "arabic" or culture == "international" then
        fullName =  name .." ".. family
    else
        fullName =  family .." ".. name
    end
    GG.LastAssignedName =fullName
    description = "Civilian : ".. fullName .. " <colateral>"
    Spring.SetUnitTooltip(id, description)
   return description
end


function getCivilianSex(id, UnitDefs)
    defID  = Spring.GetUnitDefID(id)
    if not defID or not UnitDefs[defID] then return "male" end
    assert(UnitDefs[defID], id.." has no UnitDef")
    name = UnitDefs[defID].name

    mapping_male = {
            ["civilian_arab1"] = true,
            ["civilian_arab2"] = true,
            ["civilian_western0"] = true,
            ["civilian_western3"] = true,
    }
    if mapping_male[name] then return "male" end

    mapping_female = {  
                ["civilian_arab0"] = true,
                ["civilian_arab3"] = true,
                ["civilian_arab5"] = true,
                ["civilian_western1"] = true,
                ["civilian_western2"] = true,
                ["civilian_western4"] = true,
                ["civilian_western5"] = true
            }
     if mapping_female[name] then return "female" end

     if id % 2 == 0 then
        return "male"
    else
        return "female"
    end
end


 function getDeterministicCultureNames( id, UnitDefs, culture, boolIDOverride, boolNoUnknown)
      
        if not culture then 
            culture = getInstanceCultureOrDefaultToo() 
        end

        sex = "male"
        if boolIDOverride then
            if maRa() then
                sex = "female"
            end
        else
            sex = getCivilianSex(id, UnitDefs)
        end

            names = {
                arabic = {
                    surf = {
                         "Fateha", "Nada", "Um", "Sahar", "Khowla", "Marwa", "Tabarek", "Safia", "Nujah", "Najia",
                            "Manal", "Mahroosa", "Valentina", "Samar", "Nadia", "Zeena", "Zainab", "Khairiah", "Duaa",
                            "Sa'la", "Wadhar", "Safa", "Sena", "Rana", "Maria", "Salma", "Lana", "Miriam", "Lava",
                            "Salma", "Noor", "Nora", "Khansa", "Dana", "Lamiya", "Hanna", "Hamsa"},
                    surm = {
                            "Jalal", "Hashim", "Ibrahim", "Ahmed", "Sufian", "Abdullah", "Ahmad", "Omran", "Samad",
                            "Faris", "Saif", "Qassem", "Thamer", "Haytham", "Arkan", "Walid", "Hilal", "Mohammad",
                            "Mustafa", "Hassan", "Ammar", "Wissam", "Dr.Ihab", "Kamaran", "Alaa-eddin", "Bashir",
                            "Mohammed", "Said", "Sami", "Tareq", "Taras", "Jose", "Vatche", "James", "Nicolas",
                            "Edmund", "Wael", "Abdul", "Ali", "Abu", "Haithem", "Muhammed", "Rashid", "Ghassan",
                            "Uday", "Salman", "Waleed", "Tuamer", "Hussein", "Sa'aleh", "Ghanam", "Raeed", "Daoud"
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
                        "al Jumaili ", "Amar ", " Qais ", "al Rifaai"
                    }},
                 western = {
                        surm = {
                            "Stephan", "Chris", 
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
                           
                        },
                        surf={
                            "Kerstin", "Annah", "Amelia", "Ajla", "Melisa", "Amelija", " Klea", "Sara", "Kejsi", "Noemi", "Alesia", "Leandra",
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
					asian= {
					family ={"Tanaka","Wong","Patel","Kim","Gupta","Nakamura","Li","Sharma","Nguyen","Yamamoto","Desai","Tan","Chen","Singh","Chen",
                           "Nakamura","Rahman","Patel","Park","Choudhury","Shah","Takahashi","Rahman","Suzuki","Kapoor"},
                    surf = {
                             "Aiko",  "Akira",  "Amara",  "Anika",  "Ayla",  "Chia",  "Daiyu",  "Eiko",  "Hana",  "Harumi",  "Jia",  "Kaida",  "Keiko",  "Kimiko",
                            "Kumiko",  "Mai",  "Mei",  "Miko",  "Naomi",  "Ren",  "Sakura",  "Sana",  "Suki",  "Yoko",  "Yumi" ,"Mei Ling", },
                    surm ={"Kai","Raj","Ji-Yeon","Aarav","Jia","Rohan","Hana","Kazuki","Leela","Hiroshi","Ying","Arjun","Ying Yue","Haruki","Zara","Aditi","Sora","Ravi","Meera","Tatsuya","Aisha","Yuki","Rahul"}
					}
                    }
		
	         --merge all name types for international into superset
          if culture == "international" then
            if not GG.NameCacheInternational then
              GG.NameCacheInternational ={}
              GG.NameCacheInternational.surm = {}
              GG.NameCacheInternational.surf = {}
              GG.NameCacheInternational.family = {}
    		  for culture, data in pairs(names) do
                for i=1, #data.surm do
                    GG.NameCacheInternational.surm[#GG.NameCacheInternational.surm+1] = data.surm[i]  
                end   
                for i=1, #data.surf do
                    GG.NameCacheInternational.surf[#GG.NameCacheInternational.surf+1] = data.surf[i]  
                end
                for i=1, #data.family do
                    GG.NameCacheInternational.family[#GG.NameCacheInternational.family+1] = data.family[i]  
                end
    		  end
            end
            names.international = GG.NameCacheInternational
          end

    if id % 100 == 12 and not boolNoUnknown then return "[Illegal ID]", "DB:Inconsistency error" end

    surName = "[Illegal ID]"
    if boolNoUnknown then
        surName = "John"
    end

    if sex == "male" then
        surHash =  (id % #names[culture].surm) + 1
        surName = names[culture].surm[surHash]
    end

    if sex == "female" then
        surHash =  (id % #names[culture].surf) + 1
        surName = names[culture].surf[surHash]
    end
    
    familyHash =  (id % #names[culture].family) + 1
    familyName =  names[culture].family[familyHash]

    return surName, familyName
end

-- Function to generate random sentences from provided options
local function random_sentence(options)
    return options[math.random(#options)]
end

-- Function to generate detailed conversations
local function generate_conversation(idA, idB, groupName)
    firstName1, lastName1 = getDeterministicCultureNames( idA, UnitDefs, GG.GameConfig.instance.culture)
    firstName2, lastName2 = getDeterministicCultureNames( idB, UnitDefs, GG.GameConfig.instance.culture)
    -- Conversational roles
    local calmPerson = firstName1 .. " " .. lastName1..":"
    local panickyPerson = firstName2 .. " " .. lastName2..":"

    -- Stage Zero: Mundane activity
    local mundaneActivities = {
        "Hey, I'm making breakfast. Want to join?",
        "I'm thinking of grabbing a beer. Care to join?",
        "I'm about to have lunch. Want to come over?",
        "I'm about to start my prayer. Would you like to join me?",
        "Long life ".. groupName,
        "Swordfish ?"
    }
    name, family = getDeterministicCultureNames( idA+idB, UnitDefs, GG.GameConfig.instance.culture)
    traitor = name.." sold us out. Never should have trusted a ".. family.." ! Fuck!"
    -- Conversation topics and sentences
    local coverBlown = {
        traitor,
        "Our cover was blown by a agent. They infiltrated our network.",
        "Someone tipped off the authorities. They're closing in on us.",
        "A surveillance breach revealed our operations. We have to move fast.",
        "A traitor exposed our cell to the enemy. Trust no one.",
        "They know! They know! They know about ".. groupName        
    }

    local shredDocuments = {
        "Shred all documents and data devices now. No evidence left behind.",
        "Destroy all sensitive materials immediately. Burn everything if you have to.",
        "Get rid of all the evidence, quickly. We can't afford any mistakes.",
        "Erase everything, don't leave any trace. Move!",
    }

    local stayGuard = {
        "Stay on guard. Watch out for any suspicious activity. They're out there.",
        "We need to be vigilant. Eyes open, everyone. Trust no one.",
        "Keep watch. Don't let anyone near our safehouse. We can't let them find us.",
        "Maintain a perimeter. No one gets in or out unnoticed. We have to survive this.", 
        "Just look at the cameras. And arm the dead-man-switch. Blow it up."
    }

   
    killInstruction = name.." needs to be taken care off. The ".. family .." needs to learn a lesson. Im sorry you have to do it."
    killInstructionAlt = name.." needs to be taken care off. Yes, all of them. We need to send a message."
    local eliminateTraitors = {
        "Eliminate any traitors within our ranks. They know too much.",
        killInstruction,
        killInstructionAlt,
        "Deal with the betrayers swiftly and quietly. No mercy.",
        "Handle the traitors. No one can be trusted.",
        "Remove the traitors from our midst. Do it now. No hesitation.",
        "I will be over shortly if im not trailed and take care of them.",
        "Just keep them busy. If they are tipped off, take them out.",
        "Dose them, i will come over and do the cleanup.",
    }

    local interludes = {
        "Stay calm. We need to stick to the plan. For the greater good.",
        "Remember why we're doing this. For the greater cause.",
        "Our loved ones are counting on us. Stay focused. We can't let them down.",
        "Defecting is not an option. We have to see this through. No turning back.",
        "The cause is all that matters. Be strong.",
        "Take a derma-patch from the box. You need to be calm for this."
    }

    local backgroundNoise = {        
        "(Music plays, soft moans) <Echo Analysis: Room is "..math.random(7,42).." m²>",
        "(Plates clanking) <Echo Analysis: Room is 15 m²>",
        "(cars honking in the background)  <Echo Analysis: Room is 10 m² at street level>",
        "Daddy, mummy, the special phone from uncle bob is ringing. <Echo Analysis: Room is 20 m²>",
        "Yeah? Speak up man, barely can hear you! <Echo Analysis: Room is unknown m²>"
    }

    -- Generating conversation
    local conversation = {}
    -- Add environmental detail at the start
    table.insert(conversation, random_sentence(environmentalDetails))

    -- Add Stage Zero: Mundane activity
    table.insert(conversation, panickyPerson .. random_sentence(mundaneActivities))
    table.insert(conversation, calmPerson .. "I can't. Something urgent has come up. We need to talk. Now")

    -- Step 1: Informing about the cover being blown
    table.insert(conversation, calmPerson .. random_sentence(coverBlown))
    table.insert(conversation, panickyPerson .. "This can't be happening! How did they find out about us? What do we do now?")
    table.insert(conversation, calmPerson .. random_sentence(interludes))

    -- Step 2: Shred documents and data devices
    table.insert(conversation, calmPerson .. random_sentence(shredDocuments))
    table.insert(conversation, panickyPerson .. "I'm doing it, but I'm terrified. What if they come for us next?")
    table.insert(conversation, calmPerson .. random_sentence(interludes))

    -- Step 3: Stay guard and watch out
    table.insert(conversation, calmPerson .. random_sentence(stayGuard))
    table.insert(conversation, panickyPerson .. "I'll try, but I'm not sure I can handle this. It's all too much.")
    table.insert(conversation, calmPerson .. random_sentence(interludes))

    -- Step 4: Eliminate traitors
    table.insert(conversation, calmPerson .. random_sentence(eliminateTraitors))
    table.insert(conversation, panickyPerson .. "Eliminate them? Are you serious? This is insane!")
    table.insert(conversation, calmPerson .. random_sentence(interludes))

    return conversation
end

function GetBadGuysGroupNames(hash)
    hash = hash + getDetermenisticMapHash(Game)
    badGuys= {"Mr.RogerSendro", "Children of Elon", "GreenWar", "TaliBanned","SwissStabilityDefenseGroup",
     "Isil", "AlNusra", "HareKrishnaSupremacy", "BrasilFirsters", "GliderGunDAOists", "CentralIntelligenceAgencyIregulars", "AlaskaPatriotIrregulars","CheckaRemnants",
      "Xi-DynastyInExile", "ChaosAdventists", "MokshaSleepers", "Loop Worshipper", "Axiom Ascendants", "The Veilkeepers", "GospelOfJose","TantricHives",
      "Realists", "EpicGeneticsCells", "HiveUnalive", "UmarTemplar", "SudoSims", "PuritySpiralists", "RetroStalinist" , "NeoRomans"}
    return badGuys[(hash % #badGuys) + 1]
end

function GetShoutByIdeology(unitID)
    _, agencyName = GetBadGuysGroupNames(Spring.GetUnitTeam(unitID))
    slogansPerFaction = {}
    return slogansPerFaction[agencyName][ unitID % #slogansPerFaction[agencyName] + 1]
end

function getSafeHouseTeamToolTip(teamID)
    teamName = string.lower(getTeamSideString(teamID))
    boolIsProtagon = (teamName == "protagon")
    if boolIsProtagon then
        agencyName = GetGoodGuysGroupName(teamID)
        return agencyName.." base of operation <recruits Agents/ builds upgrades>", agencyName
    else
        agencyName = GetBadGuysGroupNames(teamID)
        return agencyName.." base of operation <recruits Agents/ builds upgrades>", agencyName
    end

    echo("Unknown team in getSafeHouseTeamToolTip: "..teamName)
end




function setSafeHouseTeamName(unitID)
    teamID = Spring.GetUnitTeam(unitID)
    newToolTip = getSafeHouseTeamToolTip(teamID)
    if newToolTip then 
        Spring.SetUnitTooltip(unitID, newToolTip)
    end
end

function getDeadDropLastWords(unitID, killerId )
    teamName, isAntagon = getTeamNameIsAntagon(unitID)
    civilianId = getCivilianIdFromAgent(unitID)  or unitID
    agentName, SurName = getDeterministicCultureNames( id, UnitDefs, GG.GameConfig.instance.culture)

    lastWords = {
        "We were brothers, "..agentName
        "You ? But i thought you.."
        "Why? Its #### that gave me up, eh ?",
        "Its glorious to die for " .. teamName,
        "History shall avenge me..",
        "Mr."..agentName.." i presume",
        teamName.. " sends its regards", 
        "Its all in the game ",
        "Long live ".. teamName,
        "Hey ".. SurName,
        "Et tu brute ? Et tu "..agentName,
        "The ".. teamName.. " sends there regards"
    }
    local DeadDropLastWords =lastWords[math.random(1,#lastWords)]
    echo(DeadDropLastWords.." at ".. locationstring(unitID))
    return DeadDropLastWords, agentName, SurName
end

function GetGoodGuysGroupName(hash)
    hash = hash + getDetermenisticMapHash(Game)
    threeLetterAgency= ""
    for i=1, 2 do
       threeLetterAgency= threeLetterAgency.. string.char(65 + ((hash %90)%65))
    end
    if hash % 2 == 0 then
        return threeLetterAgency.."A"
    else
        return threeLetterAgency.."I"
    end
end

function getTeamNameIsAntagon(id)
    teamName = ""
    teamID, leader, isDead, isAiTeam, side, allyTeam, incomeMultiplier, customTeamKeys = Spring.GetTeamInfo ( teamID )
    if string.lower(side) == "antagon" then
        return  GetGoodGuysGroupName(teamID), true
    else
        return GetBadGuysGroupNames(teamID), false  
    end
end

function startRevealedUnitsChatEventStream(idA, idB)
    boolValidConversation = false
    if not GG.DiscoveredUnitConversationPartners then GG.DiscoveredUnitConversationPartners = {}end
    if not GG.DiscoveredUnitConversationPartners[idA] then 
        GG.DiscoveredUnitConversationPartners[idA] = {}
        boolValidConversation= true
    end
    if not GG.DiscoveredUnitConversationPartners[idA][idB] then 
        GG.DiscoveredUnitConversationPartners[idA][idB]= true
        boolValidConversation= true
    end

    if not boolValidConversation then return end
    

    teamName = getTeamNameIsAntagon(idA)


    local conversationHash = idA + idB
    local persPack =  {
        idA = idA, 
        idB = idB, 
        startFrame = Spring.GetGameFrame(),
        rate = 3 * 30,
        conversation = generate_conversation(idA, idB, teamName),
        gaiaTeamID = Spring.GetGaiaTeamID()
        }

    local action =  function(id, frame, persPack)
                        local idA = persPack.idA
                        local idB = persPack.idB
                        if not doesUnitExistAlive(persPack.idA) then
                            GG.DiscoveredUnitConversationPartners[idA] = nil
                            return nil, persPack
                        end 
                        if not doesUnitExistAlive(persPack.idB)then
                            GG.DiscoveredUnitConversationPartners[idA][idB] = nil
                            return nil, persPack
                        end

                        timeLine = math.ceil((Spring.GetGameFrame() - persPack.startFrame)/ persPack.rate)

                        if not persPack.conversation[timeLine] then   
                         return nil, persPack 
                        end

                        if timeLine % 2 == 0 then --operator
                            SendToUnsynced("DisplaytAtUnit", idA, persPack.gaiaTeamID, persPack.conversation[timeLine], 0.75, 0.75, 0.75, 0.25)
                        else 
                            SendToUnsynced("DisplaytAtUnit", idB, persPack.gaiaTeamID, persPack.conversation[timeLine], 0.75, 0.75, 0.75, 0.25)
                        end

                        return Spring.GetGameFrame() + persPack.rate, persPack
                    end
     GG.EventStream:CreateEvent( action, persPack, startFrame)
end

function gossipGenerator(gossipyID, oppossingPartnerID, UnitDefs)
    --Spring.Echo("Running Gossip generator")
    -- Define the subjects, actions, and objects
    questions = {"Why", "Where", "What", "How", "With", "Who"}
    space = " "
    
    subjects = {
    "Me", "I", "You", "Us", "We", "They", "All of us", "Mum", "Dad","Society","Family"}
    
    emoShorts = {
        "I Love you", "Hate you",  "Oh my god", "So fetch",    "I hate you",    "I'm sorry",    "I miss you",    "I'm proud of you",
        "You hurt me", "I'm so happy",   "I feel lost",    "You inspire me",    "I'm disappointed",    "I need you",    "I forgive you",
        "I can't stop thinking about you",    "I'm so angry",    "You complete me",    "I'm scared",    "I trust you",
        "You betrayed me",    "I'm excited",    "I feel alone" 
    } 

    filler = {  "we are","I swear","um", "uh", "like", "you know", "fat", "freaking", "fuck yeah", "because", "feel me", "so", 
    "actually", "basically", "literally", "I mean", "well", "right", "okay", "you see", "sort of", "kind of", "I guess", " know what I mean", 
    "to be honest", "frankly", "seriously", "for real", "no duh", "not okay", "seriously", "yadaya", "catch my drift", "right on", "mkay", "fuck",
     "then", "in", "hardcore", "far out man", "i swear", "my hand to god", "gods my wittnes", "get me", "yo", "otherwise"}

    conversationShift = {
        "where", "which",  "and","or", "with", "but not", "but"
    }

    actions = {
        "agree", "like", "is so", "told", "loved", "dated", "owned", "hated", "life", "laughed", "talked", "mobbed", "networked", 
    "worked", "stabbed", "fucked", "angered", "bought", "sold out", "murdered", "kicked", "rolled up", "fled", "yelled", "used", "cheat", 
    "abused", "knows someone who", "promoted", "blew", "got rich", "knew", "sucked up", "blame"}

    property = {
        "weird", "sad", "horrific", "outrageous", "disgusting", "funny", "ruthless", "nice", "cheap", "rare", 
        "plenty", "slutty", "wealthy", "small", "big", "hard", "soft", "stupid", "clever", "better", "beautiful", 
        "worse", "jerky", "stoned", "hardcore", "dilapidated", "polluted", "corrupt", "violent", "desperate", 
        "oppressive", "chaotic", "filthy", "dark", "overcrowded", "deprived", "dangerous", "exploited", "isolated", 
        "contaminated", "squalid", "malnourished", "hacked", "paranoid", "parasitic", "synthetic", "decaying", 
        "enslaved", "dehumanized", "totalitarian", "controlled", "desensitized", "scavenged", "illicit", 
        "underground", "rebellious", "manipulated", "forgotten", "abandoned", "subversive", "gritty", "lawless", 
        "grim", "disconnected", "trapped", "sterile", "heartless", "ruthless", "merciless", "barren", "bleak", 
        "desolate", "forsaken", "impoverished", "ransacked", "pregnant", "shitty","favourite","beauty"
    }

    objects = {
        "family", "me", "situation", "car", "house", "city", "money", "expenses", "government", "faith", "lipstick", "arcology",
        "mother", "father", "bread", "veggies", "meat", "beer", "market",    "drugs", "booze", "problem", "flat", "jawhe", "allah",
        "gambler", "ghetto", "community", "highrise", "family", "crime", "hope", "implants",     "drone", "music", "zion", "ganja",
        "party", "gang", "market", "shop", "truck", "weather", "sunset", "streets", "gun", "suka", "blyat", "motherfucker", 
        "bastard",  "prison", "promotion", "career", "job", "office", "restaurant", "sneakers", "brand", "camera", "organs",
        "doctor", "lawyer", "secretary", "salaryslave", "master", "ceo", "boss", "a.i.", "company", "choom", "roller", "baller", "pornstar", "shit", "start", "end",
        "conspiracy", "secret society", "cells", "agents", "foreign agents", "secret service", "mukbarat", "safehouse", "skyrise",
         "arms race", "icbm", "rocket", "aerosol", "end of the world", "boobs", "bike", "limo", "truck"}
    
    techBabble = {"[CENSORED]", "[PROFANITY]", "[GCR]","[Generated Content removed]","...", "[AI Autonegotiation]","[NOT TRANSLATEABLE]", "[UNINTELIGABLE]", "[Sound of Breathing]", "[REDACTED]", "[ENCRYPTED]", "[VIRUS]", "[TranslatorError]", "BURP", "[sobs]", " -"}
    
    explainer = {"because of the", "for the", "of course the", "due to the", "well obviously the", 
                 "cause of that", "in that", "unblievable", "thorough by", "by the"}

   if gossipyID then
        name, family = getDeterministicCultureNames(gossipyID, UnitDefs)
        conversation = name..": "
        table.insert(subjects, family)
    end

    if oppossingPartnerID then 
        oname, ofamily = getDeterministicCultureNames(oppossingPartnerID, UnitDefs)
        table.insert(subjects, ofamily)
        table.insert(subjects, oname)
    end

    isConsumerBragging = randChance(10)
    if isConsumerBragging  then
        ConsumerStarter = {"Today i bought a %s, best quality", "You wont believe the bargain i made with the %s ", "It was on sale and it was only 99$ for %s!",
        "They do not make %s like they used too ", "%s was a total steal", "I can buy a %s for you too.", "Honey, we do not have the money, but i bought a %s!"}
        consumerItem = {"Bread", "Meat", "Salad", "sausage", "shirt", "skirt", "trouser", "implant", "medicine", "fruit", "soylentils", "coat", 
        "shoes", "gun", "knife", "injector", "car", "game", "stimsim", "heroin", "speed", "booze", "slave", "heart", "liver", "concubine"}

        conversation = conversation..string.format(ConsumerStarter[math.random(1,#ConsumerStarter)], consumerItem[math.random(1,#consumerItem)])
        return conversation
    end

    isEmoShort = randChance(5)
    if isEmoShort then
        return conversation.. emoShorts[math.random(1,#emoShorts)]
    end

    isParanoid = randChance(1)
    if isParanoid then
        paranoidRantTable = getShizoBabbleRant(math.random(3,42))
        return conversation..table.concat(paranoidRantTable, "\n", 1, #paranoidRantTable)
    end


    isQuestion = randChance(10)
    if (isQuestion) then
        conversation = conversation .. questions[math.random(1, #questions)]..space
    end

    space = " "   
    conversationalRecursionDepth = math.random(1,3)
    subject = subjects[math.random(1, #subjects)]

    if isQuestion then subject = string.lower(subject) end

    conversation =  conversation .. subject
    conversation = conversation ..space.. actions[math.random(1,#actions)]
    linebreak = 1
    repeat 
        if string.len(conversation) > linebreak * 32 then
            conversation = conversation .. "\r"
            linebreak = linebreak +1
        end

        if maRa() then
            if randChance(25) then -- filler
                conversation = conversation ..space.. filler[math.random(1,#filler)]
                if maRa() then
                    conversation = conversation ..space.. property[math.random(1,#property)]
                end
            else -- topic shift
                conversation = conversation ..space.. conversationShift[math.random(1,#conversationShift)]
                conversation = conversation ..space.. property[math.random(1,#property)]
                conversation = conversation ..space.. objects[math.random(1,#objects)]
                addendum = {"is", "is not", "can", "can't", "however"}
                conversation = conversation .. space .. addendum[math.random(1, # addendum)]
            end
        end
        
        if randChance(10) then
            conversation = conversation ..space..techBabble[math.random(1,#techBabble)]
        end
        if randChance(15) then
            conversation = conversation ..space.. actions[math.random(1,#actions)] 
            if randChance(25) then
                conversation = conversation ..space.. property[math.random(1,#property)]
            end
            conversation = conversation .. space.. explainer[math.random(1,#explainer)] ..space.. objects[math.random(1,#objects)]
        end

        conversationalRecursionDepth = conversationalRecursionDepth -1
    until (conversationalRecursionDepth < 0) 

    optionalEndElement = ""

    if randChance(35) then
        optionalEndElement = space..explainer[math.random(1,#explainer)].. space ..objects[math.random(1,#objects)]
    end 

    conversation = conversation .. optionalEndElement 
    if isQuestion == true then
        conversation = conversation .. "?"
    else
        if maRa() then
            conversation = conversation .. "."
        else
            conversation = conversation .. "!"
        end
    end

    return conversation
end

function loremGibson()
return 
"systema singularity range-rover refrigerator network 3D-printed euro-pop crypto- motion boy faded fetishism assassin boy. euro-pop tanto Tokyo realism advert plastic media kanji San Francisco towards drone modem boat geodesic car. tank-traps denim face forwards film shanty town dome film woman marketing tower pre- uplink RAF sentient euro-pop. girl shoes hotdog uplink alcohol crypto- wristwatch tanto futurity free-market realism 8-bit media camera boat. systemic semiotics rebar gang tiger-team carbon refrigerator 3D-printed face forwards tank-traps assault realism industrial grade media silent. sunglasses dead nodality footage BASE jump grenade Shibuya tanto alcohol footage Tokyo claymore mine tiger-team alcohol San Francisco. futurity meta- motion industrial grade drugs voodoo god tube lights table rifle BASE jump man geodesic BASE jump math-. garage drone Tokyo post- footage disposable vehicle RAF face forwards beef noodles papier-mache neon geodesic modem lights. rain geodesic pistol drugs claymore mine modem fetishism industrial grade tank-traps carbon rain savant franchise -ware urban."..
"knife towards disposable camera sensory pre- jeans face forwards saturation point lights kanji skyscraper car long-chain hydrocarbons advert. RAF corrupted tiger-team network voodoo god alcohol hacker euro-pop jeans smart- faded concrete A.I. faded nodal point. jeans geodesic hotdog chrome geodesic computer narrative plastic decay soul-delay tube euro-pop Legba katana shrine. nodality courier silent carbon media corporation media dolphin camera tanto weathered car knife gang alcohol. neural cyber- nodal point digital dead spook table engine knife pistol Tokyo girl dolphin soul-delay neon. 3D-printed cartel alcohol footage fetishism BASE jump A.I. assault Chiba A.I. digital San Francisco neon free-market pen. neon long-chain hydrocarbons DIY artisanal realism neural vinyl claymore mine military-grade weathered rifle concrete table sub-orbital tanto. modem tanto human pre- render-farm receding bicycle wristwatch 3D-printed tanto carbon boat Tokyo cartel camera. range-rover grenade neon youtube motion A.I. shanty town neon boy augmented reality wristwatch smart- geodesic digital boy."..
"j-pop saturation point cartel sprawl gang savant courier footage post- savant 8-bit warehouse j-pop alcohol footage. bicycle Chiba plastic neural chrome shanty town numinous apophenia San Francisco motion computer alcohol into knife wristwatch. chrome youtube drugs Kowloon carbon tank-traps market bridge fetishism silent futurity face forwards uplink neon carbon. digital savant hotdog assault market face forwards otaku footage A.I. meta- 3D-printed plastic jeans pistol bridge. otaku advert engine film jeans towards convenience store city garage nano- augmented reality dome denim Kowloon shoes. sunglasses bomb assault digital skyscraper footage nodality neural girl sub-orbital refrigerator warehouse singularity construct franchise. motion apophenia advert tanto drone Tokyo free-market semiotics motion industrial grade hacker nodality ablative long-chain hydrocarbons sub-orbital. fluidity hotdog knife pre- lights plastic concrete Chiba dolphin drugs papier-mache computer hotdog j-pop man. assassin grenade meta- singularity artisanal market dome post- girl human tower lights cyber- Chiba wonton soup."..
"faded geodesic DIY 3D-printed towards towards Kowloon boy man franchise artisanal uplink semiotics marketing assassin. hotdog gang wonton soup weathered physical tower cyber- urban Shibuya girl grenade wonton soup hacker futurity Legba. uplink free-market shoes refrigerator receding sprawl knife futurity kanji hacker girl tiger-team tank-traps table assassin. otaku media math- lights city beef noodles tattoo long-chain hydrocarbons neural pre- math- network bridge pre- bicycle. table smart- towards film futurity dead corporation film engine boat cardboard digital film systemic receding. youtube long-chain hydrocarbons rebar augmented reality San Francisco bridge paranoid alcohol camera sub-orbital -ware military-grade towards sign rebar. narrative jeans marketing city savant denim dolphin modem A.I. tank-traps refrigerator tower gang papier-mache stimulate. Tokyo A.I. geodesic cartel BASE jump hotdog 8-bit fluidity otaku augmented reality geodesic vinyl cardboard film camera. Chiba DIY sub-orbital pen RAF sentient knife grenade spook gang sentient hotdog grenade singularity systema. "
end

function getDetThreeLetterAgency(hash)
    first = (hash % 16)
    second = ((hash +16) % 20)
    third = {"s", "a", "i", "b", "f"}

    return string.upper(string.char(65+first)..string.char(65+second)..third[(hash%#third)+1])
end
