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

    name = "TODO_PLACEHOLDERSTR"
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


function setIndividualCivilianName(id, culture)
    sur, name = getDeterministicCultureNames( id, culture)
    fullName =  sur .." ".. name
    GG.LastAssignedName =fullName
    description = "Civilian : ".. fullName .. " <colateral>"
    Spring.SetUnitTooltip(id, description)
   return description
end

 function getDeterministicCultureNames( id, culture)
    assert(id)
        if not culture then culture = getInstanceCultureOrDefaultToo() end
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
                            "Stephan", "Chris", "Kerstin", "Annah",
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
					asian= {
					sur ={"Tanaka","Wong","Patel","Kim","Gupta","Nakamura","Li","Sharma","Nguyen","Yamamoto","Desai","Tan","Chen","Singh","Chen","Nakamura","Rahman","Patel","Park","Choudhury","Shah","Takahashi","Rahman","Suzuki","Kapoor"},
					family = {"Kai","Mei Ling","Raj","Ji-Yeon","Aarav","Sakura","Jia","Rohan","Hana","Kazuki","Leela","Hiroshi","Ying","Arjun","Ying Yue","Haruki","Zara","Aditi","Sora","Ravi","Meera","Tatsuya","Aisha","Yuki","Rahul","DB:Error:404"}
					}
                    }
		
	         --merge all name types for international into superset
          if culture == "international" then
            if not GG.NameCacheInternational then
              GG.NameCacheInternational ={}
              GG.NameCacheInternational.sur = {}
              GG.NameCacheInternational.family = {}
    		  for culture, data in pairs(names) do
                for i=1, #data.sur do
                    GG.NameCacheInternational.sur[#GG.NameCacheInternational.sur+1] = data.sur[i]  
                end
                for i=1, #data.family do
                    GG.NameCacheInternational.family[#GG.NameCacheInternational.family+1] = data.family[i]  
                end
    		  end
            end
            names.international = GG.NameCacheInternational
          end

    if math.random(1,100) == 42 then return "PWNED", "byHaxxor"end

    surHash =  (id % #names[culture].sur) + 1
    familyHash =  ((id + 32416190071)% #names[culture].sur) + 1
    return names[culture].sur[surHash], names[culture].family[familyHash]
end

function gossipGenerator(gossipyID, oppossingPartnerID)
    -- Define the subjects, actions, and objects
    subjects = {"Me", "I", "We", "They", "All of us", "Society", "Your moma", "Motherfugger"}
    filler = {"were", "and","or", "I swear","um", "uh", "like", "you know", "with", "fat", "freaking", "fuckyeah", "because", "feel me", "so", 
    "actually", "basically", "literally", "I mean", "well", "right", "okay", "you see", "sort of", "kind of", "I guess", " know what I mean", 
    "to be honest", "frankly", "seriously", "for real", "no duh", "not okay", "seriously", "yadaya", "catch my drift", "right on"}
    actions = {"agree", "like", "is so", "love", "date", "owned", "hate", "life", "laugh", "talked", "mobbed", "networked", 
    "worked", "stabbed", "fucked", "angered", "bought", "sold out", "murdered", "kicked", "rolled up", "fled", "yelled", "used", "cheat", "abused",
     "knows someone who", "promoted", "blew", "got rich", "knew", "sucked up"}

    property = {
        "weird", "sad", "horrific", "outrageous", "disgusting", "funny", "ruthless", "nice", "cheap", "rare", 
        "plenty", "slutty", "wealthy", "small", "big", "hard", "soft", "stupid", "clever", "better", "beautiful", 
        "worse", "jerky", "stoned", "hardcore", "dilapidated", "polluted", "corrupt", "violent", "desperate", 
        "oppressive", "chaotic", "filthy", "dark", "overcrowded", "deprived", "dangerous", "exploited", "isolated", 
        "contaminated", "squalid", "malnourished", "hacked", "paranoid", "parasitic", "synthetic", "decaying", 
        "enslaved", "dehumanized", "totalitarian", "controlled", "desensitized", "scavenged", "illicit", 
        "underground", "rebellious", "manipulated", "forgotten", "abandoned", "subversive", "gritty", "lawless", 
        "grim", "disconnected", "trapped", "sterile", "heartless", "ruthless", "merciless", "barren", "bleak", 
        "desolate", "forsaken", "impoverished", "ransacked"
    }
    objects = {
        "family", "me", "situation", "car", "house", "kids","city", "money", "expenses", "government", "faith", 
        "mother", "father", "bread", "vegetables", "meat", "beer", "market",    "drugs", "booze", "problem", "flat", 
        "gambling", "ghetto", "community", "highrise", "family", "crime", "hope", "implants",     "drone", "music", 
        "party", "gang", "market", "shop", "truck", "weather", "sunset", "streets", "gun", "suka", "BLYAT", "motherfucker", 
        "bastard", "beauty", "prison", "promotion", "career", "job", "office", "restaurant", "sneakers", "brand", "camera", "organs",
        "doctor", "lawyer", "secretary", "salaryslave", "master", "ceo", "boss", "a.i.", "favourite", "company", "choom", "roller", "baller"}
    techBabble = {"[CENSORED]", "[Profanity]", "...", "[NOT TRANSLATEABLE]", "[REDACTED]", "[TranslatorError]", "BURP", "[sobs]", ","}
    if gossipyID then
        sur, name = getDeterministicCultureNames(gossipyID)
        table.insert(subjects, sur)
        table.insert(subjects, name)
    end
    if oppossingPartnerID then 
        sur, name = getDeterministicCultureNames(oppossingPartnerID)
        table.insert(subjects, sur)
        table.insert(subjects, name)
    end

    space = " "

    conversationalRecursionDepth = math.random(1,9)
    conversation = subjects[math.random(1, #subjects)]
    conversation = conversation ..space.. actions[math.random(1,#actions)]
    linebreak = 1
    repeat 

        if maRa() then
            conversation = conversation ..space.. filler[math.random(1,#filler)]
            if maRa() then
            conversation = conversation ..space.. property[math.random(1,#property)]
            end
        end
        
        if randChance(10) then
            conversation = conversation ..space..techBabble[math.random(1,#techBabble)]
        end
        if randChance(15) then
            conversation = conversation ..space.. actions[math.random(1,#actions)] 
            conversation = conversation .. " the ".. objects[math.random(1,#objects)]
        end
        conversationalRecursionDepth = conversationalRecursionDepth -1
        if string.len(conversation) > linebreak * 15 then
            conversation =conversation .. "\n"
            linebreak = linebreak +1
        end
    until (conversationalRecursionDepth < 0) 
    optionalEndElement = ""

    if randChance(25) then
        optionalEndElement = " for the ".. objects[math.random(1,#objects)]
    end

    return conversation .. optionalEndElement 
end