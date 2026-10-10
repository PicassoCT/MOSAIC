--lib static string

function getFirstShopName(firstName)
   -- Get the first letter of the first name
    local firstLetter = firstName:sub(1, 1):upper()
    local secondLetter = firstName:sub(2, 2):upper()

    -- Example more generic products for each letter
    local products = {
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
        products.D = "Designer Goods"
    end

    local broducts = {
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
    if (#firstName % 2) == 0 then
        assert(secondLetter)
        assert(firstLetter)
        assert(firstLetter)
        assert(broducts)
        if not broducts[firstLetter] then return "NoName Shop" end
        local index = ((string.byte(secondLetter) or 0) % (#broducts[firstLetter])) +1
        assert(broducts[firstLetter][index])
        product = broducts[firstLetter][index] 
    end
    -- Concatenate the first name and the product with the shop name
    local shopName = firstName .. "'s " .. product
    
    return shopName
end

function getHouseShopName(id, buisnessNamesTable, UnitDefs)
    local p = GG.BuildingTable and GG.BuildingTable[id]
    local x, _, z = Spring.GetUnitPosition(id)
    x, z = p and p.x or x, p and p.z or z
    local hash = VFS.Include("scripts/lib_city_roads.lua").hash(tostring(math.floor(x+0.5))..":"..tostring(math.floor(z+0.5)))
    if hash % 100 <= 75 then return end
    local config = GG.GameConfig or getGameConfig()
    if hash % 3 == 0 and not isNearCityCenter(x, z, config) then
        local owners = {western={"Alex","Sam","Morgan","Taylor"},arabic={"Noor","Amal","Salma","Karim"},asian={"Hana","Kai","Mei","Ren"},international={"Alex","Noor","Hana","Sam"}}
        local pool = owners[config.game.culture] or owners.international
        return getFirstShopName(pool[(hash % #pool)+1])
    end
    if buisnessNamesTable and #buisnessNamesTable > 0 then
        return buisnessNamesTable[(hash % #buisnessNamesTable)+1]
    end
end

function setHouseStreetNameTooltip(id, detailXHash, detailZHash, Game, boolInnerCityBlock, UnitDefs, buisnessNamesTable)
    -- Coordinates in older callers mixed half-grid indices and world units.
    -- The service reads the original world plot from GG.BuildingTable instead.
    assert(GG.CityAddressService, "City address service was not initialized")
    return GG.CityAddressService.Register(id, buisnessNamesTable)
end


function HouseDescriptor(id, hash,UnitDefs, buisnessNamesTable)
    
    if hash % 2 == 0 then
        local houseShopName = getHouseShopName(id,  buisnessNamesTable, UnitDefs)
        if houseShopName then return houseShopName end
    end

    local blockType = {
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

local civilianConspiracy
function getShizoBabbleRant(lines)
    civilianConspiracy = civilianConspiracy or VFS.Include("scripts/lib_civilian_conspiracy.lua")
    return civilianConspiracy.legacyRant(lines)
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
    firstName1, lastName1 = getDeterministicCultureNames( idA, UnitDefs, GG.GameConfig.game.culture)
    firstName2, lastName2 = getDeterministicCultureNames( idB, UnitDefs, GG.GameConfig.game.culture)
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
    name, family = getDeterministicCultureNames( idA+idB, UnitDefs, GG.GameConfig.game.culture)
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
        "Daddy, mummy, the special phone from uncle steves is ringing. <Echo Analysis: Room is 20 m²>",
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
    local agencyName = GetBadGuysGroupNames(Spring.GetUnitTeam(unitID))

    maxSamples = 56
    sampleHash = (hashString(agencyName) % maxSamples) + 1
   
    soundPath = "sounds/civilian/bomberman/bomberman"

    return soundPath..sampleHash..".ogg"
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
    agentName, SurName = getDeterministicCultureNames(civilianId, UnitDefs, GG.GameConfig.game.culture)

    lastWords = {
        "We were brothers, "..agentName,
        "You? But I thought you...",
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
    local teamID = Spring.GetUnitTeam(id)
    local _, _, _, _, side = Spring.GetTeamInfo(teamID)
    if string.lower(side or "") == "antagon" then
        return GetBadGuysGroupNames(teamID), true
    else
        return GetGoodGuysGroupName(teamID), false
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
        rate = 5 * 30,
        index = 1,
        -- Most intercepted calls remain operational chatter. Occasionally the
        -- listener catches a civilian-style conspiracy rant instead. Generate it
        -- once here so the entire intercepted stream stays internally consistent.
        conversation = ((conversationHash % 100) < 12)
            and getShizoBabbleRant(18)
            or generate_conversation(idA, idB, teamName),
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
                            if GG.DiscoveredUnitConversationPartners[idA] then GG.DiscoveredUnitConversationPartners[idA][idB] = nil end
                            return nil, persPack
                        end

                        local timeLine = persPack.index

                        if not persPack.conversation[timeLine] then   
                         return nil, persPack 
                        end

                        if timeLine % 2 == 0 then --operator
                            SendToUnsynced("CivilianConversation", idA, idB, persPack.conversation[timeLine], persPack.rate)
                        else 
                            SendToUnsynced("CivilianConversation", idB, idA, persPack.conversation[timeLine], persPack.rate)
                        end

                        persPack.index = timeLine + 1
                        return Spring.GetGameFrame() + persPack.rate, persPack
                    end
     GG.EventStream:CreateEvent(action, persPack, persPack.startFrame + 1)
end

local civilianDialogue = VFS.Include("scripts/lib_civilian_dialogue.lua")
function gossipGenerator(gossipyID, opposingPartnerID, UnitDefs)
    local frame = Spring.GetGameFrame()
    local seed = ((gossipyID or 0) * 131 + (opposingPartnerID or 0) * 17 + frame) % 2147483647
    local person = GG.CivilianLife and GG.CivilianLife.people[gossipyID]
    local memory = person and person.memories[#person.memories]
    local lines,kind = civilianDialogue.build(seed, memory)
    if kind == "conspiracy" then return table.concat(lines, "\n") end
    return lines[1]
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

