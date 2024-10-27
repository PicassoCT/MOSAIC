--lib static string

function setHouseStreetNameTooltip(id, detailXHash, detailZHash, Game, boolInnerCityBlock)
    region = getRegionByCulture(GG.GameConfig.instance.culture, getDetermenisticMapHash(Game))
    if not GG.StreetNameDict then
        GG.StreetNameDict = {}
    end
    if not GG.Streetnames then
        playername = getRandomPlayerName()
        Highway = "Highway" .. math.random(1, 20)
        Doctorstreet = "Dr." .. playername .. "way"
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
                "Wallmartstreet"
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
                "Doctorstreet",
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
                "Jidka Waxaracadde"
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
                "Highway",
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
                "Avenida Santa Fe"
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
                "Zhongyuan Road"
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
                "Green Street"
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
        name = Streetnames[region][(detailXHash % #Streetnames[region]) + 1]
        --name ="(Querstrasse:x="..detailXHash.."/z="..detailZHash..")"
    else
        name = Streetnames[region][(detailZHash % #Streetnames[region]) + 1]
        --name ="(Laengstrasse:x="..detailXHash.."/z="..detailZHash..")"
    end

    if not GG.StreetNameDict[name] then
        GG.StreetNameDict[name] = 0
    end
    GG.StreetNameDict[name] = GG.StreetNameDict[name] + 1
    Spring.SetUnitTooltip(id, "Housing Block - "..name .. "." .. GG.StreetNameDict[name])
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
    }
    if mapping_male[name] then return "male" end

    mapping_female = {  
                ["civilian_arab0"] = true,
                ["civilian_arab3"] = true,
                ["civilian_western1"] = true,
                ["civilian_western2"] = true
            }
     if mapping_female[name] then return "female" end
     return "divers"
end


 function getDeterministicCultureNames( id, UnitDefs, culture)
        assert(id)
        if not culture then 
            culture = getInstanceCultureOrDefaultToo() 
        end

        sex = getCivilianSex(id, UnitDefs)

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

    if id % 100 == 42 then return "[Illegal ID]", "DB:Inconsistency error" end

    surName = "[Illegal ID]"

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
        "Long life ".. groupName
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
     "Isil", "AlNusra", "HareKrishnaSupremacy", "BrasilFirsters", "GliderGunDAOists", "CentralIntelligenceAgencyIregulars", "AmericanPatriotIrregulars","CheckaRemnants"
      "Xi-DynastyInExile", "ChaosAdventists", "Loop Worshipper", "Axiom Ascendants", "The Veilkeepers", "GospelOfJose","TantricHives",
      "Realists", "EpicGeneticsCells", "HiveUnalive", "UmarTemplar", "SudoSims", "PuritySpiralists", "Stalinist" }
    return badGuys[(hash%#badGuys)+1]
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
    
    teamID = Spring.GetUnitTeam(idA)
    teamName = ""
    teamID, leader, isDead, isAiTeam, side, allyTeam, incomeMultiplier, customTeamKeys = Spring.GetTeamInfo ( teamID )
    if string.lower(side) == "antagon" then
        teamName = GetGoodGuysGroupName(teamID)
    else
        teamName = GetBadGuysGroupNames(teamID)    
    end

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
    -- Define the subjects, actions, and objects
    assert(UnitDefs)
    questions = {"Why", "Where", "What", "How", "With", "Who"}
    space = " "
    
    subjects = {
    "Me", "I", "We", "They", "All of us", "Mum", "Dad","Society","Family", "Just", "Oh my god"}
    
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
        "family", "me", "situation", "car", "house", "city", "money", "expenses", "government", "faith", 
        "mother", "father", "bread", "veggies", "meat", "beer", "market",    "drugs", "booze", "problem", "flat", 
        "gambler", "ghetto", "community", "highrise", "family", "crime", "hope", "implants",     "drone", "music", 
        "party", "gang", "market", "shop", "truck", "weather", "sunset", "streets", "gun", "suka", "BLYAT", "motherfucker", 
        "bastard",  "prison", "promotion", "career", "job", "office", "restaurant", "sneakers", "brand", "camera", "organs",
        "doctor", "lawyer", "secretary", "salaryslave", "master", "ceo", "boss", "a.i.",  "company", "choom", "roller", "baller", "pornstar", "shit", "start", "end",
        "conspiracy", "secret society", "cells", "agents", "foreign agents", "secret service", "safehouse", "skyrise", "arms race", "icbm", "rocket", "aerosol", "end of the world", "boobs", "bike", "limo", "truck"}
    
    techBabble = {"[CENSORED]", "[Profanity]", "[GCR]","[Generated Content removed]","...", "[AI Autonegotiation]","[NOT TRANSLATEABLE]", "[UNINTELIGABLE]", "[Sound of Breathing]", "[REDACTED]", "[Encrypted]", "[TranslatorError]", "BURP", "[sobs]", " -"}
    
    explainer = {"because of the", "for the", "of course the", "due to the", "well obviously the", "cause of that", "in that", "unblievable", "thorough by", "by the"}

   if gossipyID then
        name, family = getDeterministicCultureNames(gossipyID, UnitDefs)
        conversation = name..": "
        table.insert(subjects, family)
    end

    isQuestion = randChance(10)
    if (isQuestion) then
        conversation = conversation .. questions[math.random(1, #questions)]..space
    end

    if oppossingPartnerID then 
        name, family = getDeterministicCultureNames(oppossingPartnerID, UnitDefs)
        table.insert(subjects, family)
        table.insert(subjects, name)
    end

    space = " "
   
    conversationalRecursionDepth = math.random(1,5)
    subject = subjects[math.random(1, #subjects)]
    if isQuestion then subject = string.lower(subject) end
    conversation =  conversation .. subject
    conversation = conversation ..space.. actions[math.random(1,#actions)]
    linebreak = 1
    repeat 
        if string.len(conversation) > linebreak * 32 then
            conversation =conversation .. "\r"
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



function setArcologyName(id, boolCorpo)
name= {"Mega Haven"," Skybound Complex","Giga Gardens"," Horizon Sprawl",
"Echelon Tower","Macropolis","Stratos Heights", "Panorama City","Prime Hive",
"Vastara","Infinite Plaza","Titanium Reach"," Grand Nexus","Skyline Citadel",
" Ultra Blocks","Terra Enclave","Nimbus Crown","Omega District","Echo City","Solaris Compound"
"Evergrove Heights","Sunfield Towers","Greenhollow Expanse","Willow Horizon","Eden Nest",
" Cedar Reach"," Maple Spire","Timber Path Haven","Lakeview Pinnacle","Rosemary Stretch"
," Oasis Rise"," Briar Canopy"," Silverleaf Plateau","Fernspire Peaks","Juniper Valley",
"Forest Haven","Mistvale Ridge","Heatherview Crest"," Riverbend Sprawl","Sunbluff Terrace",
"Kowloon 2", "Oz.ean. Views", "Arcos Sancti", "Arcology", "Withering Heights", "Riverside Rebuild"}
if not boolCorpo then
    description =  {
    "Breathe fresh air, indoors only",
    "Vibrant green spaces, at a distance",
    "Sunshine guaranteed, through tinted glass",
    "Nature-inspired, steel-strong and secure",
    "Experience community, in private cubicles",
    "Escape the world, forever",
    "Live freely, in designated zones",
    "Skylights for all, high above",
    "Boundless views, of concrete landscapes",
    "Luxury living, tightly monitored",
    "Eco-friendly concrete and recycled air",
    "Embrace nature, digitally rendered",
    "Your sanctuary, under constant care",
    "Reimagined countryside, vertical and walled",
    "Feel alive, but stay indoors",
    "Green spaces, seen from windows",
    "Open-air feel, indoors and safe",
    "Privacy assured, limited daylight",
    "Thriving community, curated interactions only",
    "Rediscover nature, in holographic parks",
    "Sector 7 lockdown after rogue droids",
    "Neon District curfew extended again",
    "Unlicensed clones found in Sublevel 5",
    "Black Market implants spike in sales",
    "Cyber-hack wave hits Lower Spire",
    "Gang tensions rise in Neon Alley",
    "Firefight erupts over rooftop territories",
    "Unauthorized drones swarm Market Plaza",
    "Police outnumbered in Suburb 13",
    "Data-thefts surge across Core Blocks",
    "Synthetic trade sweeps through Red Zone",
    "Augment gangs clash over power cells",
    "Spire 22 hacked by vigilante groups",
    "Rogue android sightings in Old Metro",
    "Curfew violators flood Checkpoint A",
    "Memory heist reported in Hub Sector",
    "Energy riots spread in West Hive",
    "Biotech labs breached in Sector 9",
    "Illegal VR dens raid gone wrong",
    "Corp enforcers attacked by data thieves",
    "All reports of smog are exaggerated",
    "Unauthorized lights in Sector 12 ‘harmless’",
    "Noise detected in Sublevel? Just machinery!",
    "Power outages ‘routine maintenance only’",
    "Drone sightings completely under control",
    "Safety barriers purely precautionary measures",
    "Reports of android malfunctions unfounded",
    "Spire evacuations part of safety drills",
    "Rising noise is ‘neighborhood vibrancy’",
    "Extended curfew purely ‘for residents’ comfort’",
    "Security patrols increased for community joy",
    "Lower levels’ blackout ‘a festive surprise’",
    "Market lockdown ‘merely crowd control’",
    "Unauthorized shadows ‘just lighting effects’",
    "Drone squads ‘just optimizing airspace’",
    "Heat spikes in alleys ‘routine’",
    "Enhanced surveillance ‘for residents’ safety’",
    "Hologram glitches ‘due to upgrades’",
    "Increased curfews ‘to enhance nightlife’",
    "Bio-lab quarantine ‘a wellness initiative’" }
      Spring.SetUnitTooltip(id, name..":"..description)
  else
    description  = {
        "Live safely, away from the chaos",
        "True peace, beyond the city’s noise",
        "Experience harmony, shielded from disorder",
        "Your sanctuary, far from the unrest",
        "Security guaranteed, beyond urban turmoil",
        "Breathe easy, in our sealed paradise",
        "Escape the streets, live in safety",
        "Perfect harmony, free from outside threats",
        "Your safe haven, isolated and secure",
        "Enjoy life, untouched by outer dangers",
        "Where the air is safe to breathe",
        "Safety you can trust, always enclosed",
        "Your oasis, far from the city’s reach",
        "Stay protected, where chaos can’t touch",
        "The world outside fades away here",
        "Built to last, shielded from everything",
        "Luxury living, safe and sound inside",
        "The refuge you deserve from the outside",
        "An untouched world, within strong walls",
        "Find true serenity, sealed from chaos",
        "Where calm prevails, and walls protect",
        "Enjoy the calm, beyond the outer risks",
        "Feel safe, far from the unpredictable",
        "A guarded paradise amidst a stormy world",
        "Insulated luxury, against outer mayhem",
        "Protected living, away from the unknown",
        "Here, security is our highest standard",
        "Discover safety, without a worry",
        "Built to withstand, sheltering you always",
        "Your escape, fortified and serene",
        "Life uninterrupted, beyond external threats",
        "Embrace safety, with every passing day",
        "A world within a world, just for you",
        "Feel secure, where others can’t reach",
        "Peace and quiet, sealed and protected",
        "Reclaim tranquility, away from the city",
        "Enclosed comfort, outside world-free",
        "Safety-first living, beyond outer borders",
        "Stay worry-free, inside our safe zone",
        "Protected, comfortable, and free of worry"
    }
    Spring.SetUnitTooltip(id, name..":"..description)

  end
end