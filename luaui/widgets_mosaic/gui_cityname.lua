local versionNumber = "0.6"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_team_platter.lua
--  brief:   team colored platter for all visible units, teamcolour altered depending on player who last ordered them
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Display Location and Time at Gamestart",
    desc      = "Displays the cityname at startup ",
    author    = "picasso",
    date      = "Apr 16, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local startFrame = Spring.GetGameFrame()
local totalLifetimeInSeconds = 35
local endFrame = startFrame + (totalLifetimeInSeconds*30)
local displayStaticFrame = endFrame
local displayStaticFrameIntervallLength = endFrame
local vsx,vsy = Spring.GetViewGeometry()
local anchorx, anchory
local glColor           = gl.Color
local glText            = gl.Text
local fontSize          = 32
local scale            = 1
local fadeOutPhaseFrames = 30*5
local cache = {}

local function setAnchorsRelative(nvx, nvy)
  anchorx, anchory = nvx*0.9,nvy*0.15 
end

function widget:Initialize()
   startFrame = Spring.GetGameFrame() + 100
   endFrame = startFrame + (15*30)
   displayStaticFrameIntervallLength = math.ceil(0.3*(endFrame - startFrame))
   displayStaticFrame = startFrame+ displayStaticFrameIntervallLength
   vsx,vsy = Spring.GetViewGeometry()
   setAnchorsRelative(vsx,vsy)
end

function widget:Shutdown()
end

local function getRollingString(original, nrOfLetters, frames)
  local lengthOfString = string.len(original)
  if nrOfLetters > lengthOfString then return original end

  local concat = ""

    concat = string.sub(original, math.max(1,lengthOfString-nrOfLetters),nrOfLetters)..concat


  if math.ceil(frames/15)% 2 == 0 then
    return "█"..concat
  else
    return " |"..concat
  end
end

function widget:ViewResize(n_vsx,n_vsy)
  scale = vsx*vsz/ (n_vsx*n_vsy) 
  vsx,vsz = n_vsx,n_vsy
  setAnchorsRelative(vsx,vsy)
end

local function getDetermenisticHash()
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

local function getHashDate(startYear)
    local hash = getDetermenisticHash()
    local year = startYear + (hash % 25)
    local month = hash % 12
    local day = hash % 31
    return day.."/"..month.."/"..year
  end

local function getDayTimeString()
    local DAYLENGTH = 28800
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = (math.floor((Frame / DAYLENGTH) * 24))..""
     if string.len(hours) == 1 then hours= " "..hours end

    local minutes = (math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60))..""
    if string.len(minutes) == 1 then minutes= " "..minutes end
     
    local seconds = (math.ceil((24 * 60 * 60)*percent) % 60)..""
    if string.len(seconds) == 1 then seconds= " "..seconds end

    return ""..hours.." : "..minutes.." : "..seconds.. " / ".. getHashDate(2025)
end

local function getCacheBy(identifier)
  if cache[identifier] then return cache[identifier] end
end

local function setCacheBy(identifier, value)
   cache[identifier] = value
end



local function getNeighbourhoodName(culture, hash)
  if getCacheBy("neighbourhood") then return "District: "..getCacheBy("neighbourhood") end

local Neighbourhoods ={
    ["arabic"] = {
    "Suk","Burgazada","Heybeliada","Kınalıada","Maden","Nizam","Anadolu","İmrahor","İslambey","Merkez","Yavuzselim",
    "Atatürk","Bahşayış","Boğazköy Atatürk","Boğazköy İstiklal","Boğazköy Merkez","Bolluca","Deliklikaya","Dursunköy",
    "Durusu Cami","Durusu Zafer","Hastane","İstasyon","Sazlıbosna","Nakkaş","Karlıbayır","Haraççı","Hicret","Mavigöl",
    "Nenehatun","Ömerli","Taşoluk","Taşoluk Adnan Menderes","Taşoluk Çilingir","Taşoluk","Taşoluk M. Fevzi Çakmak",
    "Taşoluk Mehmet Akif ErsoyAşıkveysel","Atatürk","Barbaros","Esatpaşa","Ferhatpaşa","Fetih","İçerenköy","İnönü",
    "Kayışdağı","Küçükbakkalköy","Mevlana","Mimarsinan","Mustafa Kemal","Örnek","Yeniçamlıca","Yenişehir","Yenisahra",
    "Ambarlı","Cihangir","Denizköşkler","Firuzköy","Gümüşpala","Merkez","Mustafa Kemal Paşa","Tahtakale","Üniversite",
    "Yeşilkent","Bağlar","Barbaros","Çınar","Demirkapı","Evren","Fevzi Çakmak","Göztepe","Güneşli","Hürriyet","İnönü",
    "Kâzım Karabekir","Kemalpaşa","Kirazlı","Mahmutbey","Merkez","Sancaktepe","Yavuzselim","Yenigün","Yenimahalle",
    "Yıldıztepe","Yüzyıl","Cumhuriyet","Çobançeşme","Fevzi Çakmak","Hürriyet","Kocasinan","Siyavuşpaşa","Soğanlı",
    "Şirinevler","Yenibosna","Zafer","Ataköy 1. kısım","Ataköy 2-5-6. kısım","Ataköy 3-4-11. kısım",
    "Ataköy 7-8-9-10. kısım","Basınköy","Cevizlik","Kartaltepe","Osmaniye","Sakızağacı","Şenlikköy","Yenimahalle",
    "YeşilköyYeşilyurtZeytinlik","Zuhuratbaba","Altınşehir","Başak","Güvercintepe","Kayabaşı","Şahintepe","Ziya Gökalp",
    "Altıntepsi","Cevatpaşa","İsmetpaşa","Kartaltepe","Kocatepe","Muratpaşa","Orta","Terazidere","Vatan","Yenidoğan",
    "Yıldırım","","Beşiktaş","Abbasağa","Akatlar","Balmumcu","Bebek","Cihannüma","Dikilitaş","Etiler","Gayrettepe",
    "Konaklar","Kuruçeşme","Kültür","Levazım","Levent","Mecidiye","Muradiye","Nisbetiye","Ortaköy","Sinanpaşa","Türkali",
    "Ulus","Vişnezade","YıldızAcarlar","Anadoluhisarı","Anadolukavağı","Baklacı","Çamlıbahçe","Çengeldere","Çiftlik",
    "Çiğdem","Çubuklu","Göksu","Göztepe","Gümüşsuyu","İncirköy","Kanlıca","Kavacık","Merkez","Ortaçeşme","Paşabahçe",
    "Rüzgarlıbahçe","Soğuksu","Tokatköy","Yalıköy","Yavuz Selim","Yenimahalle","Barış","Büyükşehir","Cumhuriyet",
    "Dereağzı","Gürpınar","Kavaklı","Marmara","Sahil","Yakuplu","Arapcami","Asmalımescit","Bedrettin","Bereketzade",
    "Bostan","Bülbül","Camiikebir","CihangirÇatmamescit","Çukur","Emekyemez","Evliya Çelebi","Fetihtepe","Firuzağa",
    "Gümüşsuyu","Hacıahmet","Hacımimi","Halıcıoğlu","Hüseyinağa","İstiklal","Kadı Mehmet Efendi","Kamerhatun",
    "Kalyoncukulluğu","Kaptanpaşa","Katip Mustafa Çelebi","Keçecipiri","Kemankeş Kara Mustafa Paşa","Kılıçalipaşa",
    "Kocatepe","Kulaksız","Kuloğlu","Küçükpiyale","Müeyyetzade","Ömeravni","Örnektepe","Piripaşa","Piyalepaşa","Pürtelaş",
    "Sururi","Sütlüce","Şahkulu","Şehit Muhtar","Tomtom","Yahya Kahya","Yenişehir","19 Mayıs","Ahmediye","Alkent","Atatürk",
    "Batıköy","Celaliye","Cumhuriyet","Çakmaklı","Dizdariye","Güzelce","Hürriyet","Kamiloba","Karaağaç","Kumburgaz Merkez",
    "Mimarsinan","Muratbey","Muratçeşme","Pınartepe","Türkoba","Ulus","Yenimahalle","Binkılıç","Çakıl","Çiftlikköy",
    "Ferhatpaşa","İzettin","Kaleiçi","Karacaköy","Ovayenice","Alemdağ","Aydınlar","Cumhuriyet","Çamlık","Çatalmeşe",
    "Ekşioğlu","Güngören","Hamidiye","Kirazlıdere","Mehmet Akif","Merkez","Mimar Sinan","Nişantepe","Ömerli","Soğukpınar",
    "Sultançiftliği","Taşdelen","Birlik","Çiftehavuzlar","Davutpaşa","","Fevzi Çakmak","Havaalanı","Kâzım Karabekir",
    "Kemer","Menderes","Mimarsinan","Namık Kemal","Nenehatun","Oruçreis","Tuna","Turgutreis","Yavuz Selim","Ardıçlıevler",
    "Atatürk","Cumhuriyet","Çakmaklı","Esenkent","Güzelyurt (Haramidere)","İncirtepe","İnönü","İstiklal","Mehterçeşme",
    "Merkez","Namik Kemal","Örnek","Pınar","Saadetdere","Sanayii","Talatpasa","Yenikent","Yeşilkent","Akşemsettin",
    "Alibeyköy","Çırçır","Defterdar","Düğmeciler","Emniyettepe","Esentepe","Merkez","Göktürk","Güzeltepe","İslambey",
    "Karadolap","Mimarsinan","Mithatpaşa","Nişanca","Rami Cuma","Rami Yeni","Sakarya","Silahtarağa","Topçular","Yeşilpınar",
    "Aksaray","Akşemsettin","Alemdar","Ali Kuşçu","Atikali","Ayvansaray","Balabanağa","Balat","Beyazıt","Binbirdirek",
    "Cankurtaran","Cerrahpaşa","Cibali","Demirtaş","Derviş Ali","Eminsinan","Hacıkadın","Hasekisultan","Hırkaişerif","Hobyar",
    "Hoca Giyasettin","Hocapaşa","İskenderpaşa","Kalenderhane","Karagümrük","Katip Kasım","Kemalpaşa","Kocamustafapaşa",
    "Küçükayasofya","Mercan","Mesihpaşa","Mevlanakapı","Mimar Hayrettin","Mimar Kemalettin","Mollafenari","Mollagürani",
    "Mollahüsrev","Muhsinehatun","Nişanca","Rüstempaşa","Saraçishak","Sarıdemir","Seyyid Ömer","Silivrikapı","Sultanahmet",
    "Sururi","Süleymaniye","Sümbülefendi","Şehremini","Şehsuvarbey","Tahtakale","Tayahatun","Topkapı","Yavuzsinan",
    "Yavuz Sultan Selim","Yedikule","Zeyrek","Abbas Abad","Afsariyeh","Aghdasieh","Ajudanieh","Almahdi","Amir Abad",
    "Bagh Feiz","Bahar","Baharestan","City Park","Darabad","Darakeh","Darband","Dardasht","Darrous","Davoodiyeh14","Doulat",
    "Ekbatan","Ekhtiarieh","Elahieh","Evin","Farahzad","Farmanieh","Gheytarieh","Gholhak","Gisha","Gomrok","HaftHoz",
    "Jamaran","Jannat Abad","Javadiyeh","Javan Mard-e Ghassab Tomb","Kamranieh","Khavaran","Lavizan","Mahmoodieh","Mehran",
    "Narmak","Navvab","Nazi Abad","Nelson Mandela Boulevard","","Niavaran","Pasdaran","Piroozi","Punak","Ray","Iran",
    "Resalat","Sa'adat Abad","Sadeghiyeh","Sarsabz","Seyed Khandan","Shahr-e No","Shahr-e ziba","Shahrak-e Gharb","Shahran",
    "Shahrara","Shemiran","Sohrevardi","Surena Street","Tajrish","Tarasht","pars","sar","Toopkhaneh","Town of Masoudieh",
    "Vanak","Velenjak","Yaft Abad","Yusef Abad","Zafaraniyeh","Abbassia","Ain Shams","Azbakeya","Bab al-Louq","Boulaq",
    "Coptic ","Daher","Downtown "," El Manial","El Marg","El Matareya","El Qobbah","El Rehab","El Sahel","El Sakkakini",
    "Ezbet El Haggana","Ezbet El Nakhl","Faggala","Fifth Settlement","Fustat","Garden City","Gezira","Heliopolis","Maadi",
    "Oldtown","Roda Island","Shubra ","Shubra El Kheima","Wagh El Birket","Zamalek","Zeitoun"


    }
}

setCacheBy("neighbourhood", Neighbourhoods[culture][(hash % #Neighbourhoods[culture])+1 ])
return "District: "..getCacheBy("neighbourhood") 
end

local function getCityNameBy(culture, hash)
    if getCacheBy("city") then return "City: "..getCacheBy("city") end

local city ={
    ["arabic"] = {
      "Abu El Matamir","Abu Hummus","Abu Tesht","Akhmim","Al Khankah",
      "Alexandria","Arish","Ashmoun","Aswan","Asyut","Awsim","Badr","Baltim","Banha","Basyoun","Biyala","Belqas","Beni Mazar",
      "Beni Suef","Beni Ebeid","Biba","Bilbeis","Birket El Sab","Borg El Arab","Borg El Burullus","Bush","Cairo","Dahab","Dairut",
      "Damanhur","Damietta","Dar El Salam","Daraw","Deir Mawas","Dekernes","Dendera","Desouk","Dishna","Edfu","Edku","El Alamein",
      "El Arish","El Ayyat","El Badari","El Badrashein","El Bagour","El Balyana","El Basaliya","El Bayadiya","El Dabaa","El Delengat",
      "El Fashn","El Gamaliya","El Ghanayem","El Hamool","El Hamam","El Hawamdeya","El Husseiniya","El Idwa","El Ibrahimiya",
      "El Kanayat","El Kareen","El Mahalla El Kubra","El Mahmoudiyah","El Mansha","El Manzala","El Maragha","El Matareya","El Qantara",
      "El Qanater El Khayreya","El Qoseir","El Qusiya","El Rahmaniya","El Reyad","El Rhoda","El Saff","El Santa","El Sarw","El Sebaiya",
      "El Senbellawein","El Shohada","El Shorouk","El Tor","El Waqf","El Wasta","El Zarqa","Esna","Ezbet El Borg","Faqous","Faraskur",
      "Farshut","Fayed","Faiyum","Fuka","Girga","Giza","Hihya","Hosh Essa","Hurghada","Ibsheway","Ihnasiya","Ismailia","Itay El Barud",
      "Itsa","Juhayna","Kafr El Sheikh","Kafr El Zayat","Kafr El Batikh","Kafr El Dawwar","Kafr Saad","Kafr Saqr","Kafr Shukr",
      "Kafr Zarqan","Kerdasa","Khanka","Kharga","Khusus","Kom Hamada","Kom Ombo","Kotoor","Luxor","Maghagha","Mallawi","Manfalut",
      "Mansoura","Mashtool El Souk","Matai","Menouf","Marsa Alam","Mersa Matruh","Metoubes","Minya","Minyet El Nasr","Mit Abu El Kom",
      "Mit Abu Ghaleb","Mit Adlan","Mit Bera","Mit El Korama","Mit Elwan","Mit Fadala","Mit Ghamr","Mit Kenana","Mit Rahina",
      "Mit Salsil","Mit Sudan","Mit Yazid","Monsha'at El-Qanater","Mut","Nabaroh","Nag Hammadi","Naqada",
      "New Administrative Capital","New Alamein","New Aswan","New Akhmim","New Asyut","New Beni Suef","New Borg El Arab","New Cairo",
      "New Damietta","New Faiyum","New Minya","New Nubariya","New Salhia","New Sohag","New Tiba","New Qena","Obour","Port Said",
      "Qaha","Qallin","Qalyub","Qena","Qift","Quesna","Qus","Rafah","Ras Burqa","Ras El Bar","Ras Gharib","Ras Sedr","Ras Shokeir",
      "Rosetta","Sadat","Safaga","Sahel Selim","Saint Catherine","Samalut","Samanoud","Saqultah","Shubra Khit","Sers El Lyan",
      "Sharm El Sheikh","Sherbin","Sheikh Zuweid","Shibin El Qanater","Shibin El Kom","Shubra El Kheima","Sidi Barrani","Sidi Salem",
      "Sinnuris","Siwa Oasis","Sodfa","Sohag","Suez","Sumusta El Waqf","Tahta","Tala","Talkha","Tamiya","Tanta","Tell El Kebir","Tima",
      "Tukh","Wadi El Natrun","Zagazig","Zefta","Kabul","Kandahar","Herat","Mazar-i-Sharif","Kunduz","Jalalabad","Taloqan",
      "Puli Khumri ","Charikar","Lashkargah","Sheberghan","Ghazni","Khost","Sar-e Pol","Chaghcharan","Mihtarlam","Farah","Puli Alam",
      "Gyumri","Vanadzor","Vagharshapat","Abovyan","Kapan","Hrazdan","Armavir","Artashat","Ijevan","Gavar","Goris","Charentsavan",
      "Ararat","Masis","Artik","Sevan","Ashtarak","Dilijan","Sisian","Alaverdi","Stepanavan","Martuni","Spitak","Vardenis","Yeghvard",
      "Vedi","Byureghavan","Nor Hachn","Metsamor","Berd","Yeghegnadzor","Tashir","Kajaran","Aparan","Vayk","Chambarak","Maralik",
      "Noyemberyan","Talin","Jermuk","Meghri","Ayrum","Akhtala","Tumanyan","Tsaghkadzor","Agdash","Aghjabadi","Agstafa","Agsu",
      "Astara","Aghdara","Babek","Baku","Balakən","Barda","Beylagan","Bilasuvar","Dashkasan","Shabran","Fuzuli","Gadabay","Ganja",
      "Goranboy","Goychay","Goygol","Hajigabul","Imishli","Ismayilli","Jabrayil","Julfa","Kalbajar","Khachmaz","Khankendi","Khojavend",
      "Khirdalan","Kurdamir","Lankaran","Lerik","Masally","Mingachevir","Nakhchivan","Naftalan","Neftchala","Oghuz","Ordubad","Qabala",
      "Qakh","Qazakh","Quba","Qubadli","Qusar","Saatlı ()","Sabirabad","Shahbuz","Shaki","Shamakhi","Shamkir","Sharur","Shirvan",
      "Siyazan","Shusha","Sumgait","Tartar","Tovuz","Ujar","Yardimli","Yevlakh","Zaqatala","Zardab","Zangilan","    Jid Ali","Sanabis",
      "Tubli","Saar","Al Dur","Qudaibiya","Salmabad","Jurdab","Diyar Al Muharraq","Amwaj Island","Hidd","Arad","Busaiteen","Janabiyah",
      "Samaheej","Aldair","Manama","Riffa","Muharraq","Hamad Town","A'ali","Isa Town","Sitra","Budaiya","Jidhafs","Al-Malikiyah","Dhaka",
      "Chittagong","Gazipur","Khulna","Sylhet","Rajshahi","Mymensingh","Barisal","Rangpur","Comilla","Narayanganj","Karaj","Fardis",
      "Kamal Shahr","Nazarabad","Mohammadshahr","Hashtgerd","Mahdasht","Meshkin Dasht","Chaharbagh","Shahr-e Jadid-e Hashtgerd",
      "Eshtehard","Garmdarreh","Golsar","Kuhsar","Taleqan","Asara","Tankaman","Ardabil","Parsabad","Meshginshahr","Khalkhal","Germi",
      "Bileh Savar","Namin","Jafarabad","Kivi","Anbaran","Abi Beyglu","Nir","Hashatjin","Sareyn","Aslan Duz","Eslamabad-e Qadim",
      "Tazeh Kand-e Qadim","Qasabeh","Lahrud","Hir","Kolowr","Razey","Tazeh Kand-e Angut","Fakhrabad","Kuraim","Moradlu","Bushehr",
      "Borazjan","Bandar Ganaveh","Khormoj","Bandar Kangan","Jam","Bandar Deylam","Bandar-e Deyr","Ali Shahr","Choghadak","Ab Pakhsh",
      "Ahram","Vahdatiyeh","Kaki","Bank","Nakhl Taqi","Asaluyeh","Kharg","Dalaki","Sadabad","Shabankareh","Abdan","Bandar Rig","Bardestan",
      "Bord Khun","Delvar","Bandar Siraf","Dowrahak","Baduleh","Tang-e Eram","Abad","Anarestan","Shonbeh","Imam Hassan","Kalameh","Riz",
      "Bushkan","Ardabil","Parsabad","Meshginshahr","Khalkhal","Germi","Bileh Savar","Namin","Jafarabad","Kivi","Anbaran","Abi Beyglu",
      "Nir","Hashatjin","Sareyn","Aslan Duz","Eslamabad-e Qadim","Tazeh Kand-e Qadim","Qasabeh","Lahrud","Hir","Kolowr","Razey",
      "Tazeh Kand-e Angut","Fakhrabad","Kuraim","Moradlu","Shahr-e Kord","Borujen","Farsan","Farrokh Shahr","Lordegan","Hafshejan",
      "Saman","Junqan","Kian","Faradonbeh","Ben","Sureshjan","Babaheydar","Boldaji","Ardal","Naqneh","Pardanjan","Shalamzar","Gahru",
      "Gujan","Sefiddasht","Gandoman","Taqanak","Sardasht","Sudjan","Naghan","Dastana","Cholicheh","Vardanjan","Kaj","Dashtak","Nafech",
      "Mal-e Khalifeh","Chelgard","Aluni","Haruni","Sar Khun","Bazoft","Manj-e Nesa","Samsami","Tabriz","Maragheh","Marand","Ahar","Mianeh",
    "Bonab","Sahand","Sarab","Azarshahr","Hadishahr","Ajab Shir","Sardrud","Malekan","Shabestar","Bostanabad","Hashtrud","Osku","Ilkhchi",
    "Mamqan","Khosrowshah","Basmenj","Gugan","Heris","Yamchi","Kaleybar","Shendabad","Sufian","Jolfa","Koshksaray","Tasuj","Torkamanchay",
    "Kolvanaq","Leylan","Sis","Bakhshayesh","Qarah Aghaj","Mehraban","Teymurlu","Varzaqan","Zarnaq","Hurand","Khajeh","Benab e Marand",
    "Sharabian","Vayqan","Mobarak Shahr","Sharafkhaneh","Kuzeh Kanan","Achachi","Duzduzan","Kharvana","Khamaneh","Tekmeh Dash","Aqkand",
    "Abish Ahmad","Zonuz","Tark","Khomarlu","Kharaju","Siah Rud","Nazarkahrizi","Jowan Qaleh","Malek Kian","Shahriar","Isfahan","Kashan",
    "Khomeyni Shahr","Najafabad","Shahin Shahr","Shahreza","Fuladshahr","Baharestan","Mobarakeh","Aran va Bidgol","Golpayegan","Zarrin Shahr",
    "Dorcheh Piaz","Dowlatabad","Falavarjan","Qahderijan","Khvorzuq","Nain","Semirom","Kelishad va Sudarjan","Goldasht","Gaz","Abrisham",
    "Khansar","Tiran","Daran","Sedeh Lenjan","Dizicheh","Varnamkhast","Dehaqan","Dastgerd","Ardestan","Chamgardan","Badrud","Imanshahr",
    "Natanz","Chermahin","Fereydunshahr","Pir Bakran","Kushk","Varzaneh","Nushabad","Baharan Shahr","Kahriz Sang","Bagh-e Bahadoran","Zibashahr",
    "Chadegan","Talkhuncheh","Golshahr","Buin va Miandasht","Qahjaverestan","Zayandeh Rud","Gorgab","Habibabad","Majlesi","Zavareh","Dehaq","Alavicheh",
    "Zazeran","Manzariyeh","Karkevand","Asgharabad","Khur","Nasrabad","Guged","Harand","Jowzdan","Shadpurabad","Abuzeydabad","Sefidshahr","Meymeh",
    "Barf Anbar","Meshkat","Hana","Rozveh","Komeshcheh","Vazvan","Kuhpayeh","Sin","Golshan","Damaneh","Sagzi","Hasanabad","Nikabad",
    "Mohammadabad","Mahabad","Asgaran","Jandaq","Baghshad","Tudeshk","Jowsheqan va Kamu","Ziar","Qamsar","Afus","Rezvanshahr","Ezhiyeh",
    "Khaledabad","Farrokhi","Kamu va Chugan","Barzok","Tarq","Vanak","Komeh","Neyasar","Bafran","Anarak","Lay Bid","Shiraz","Marvdasht","Jahrom","Fasa","Kazerun","Sadra","Darab","Firuzabad","Lar","Abadeh","Nurabad","Neyriz","Eqlid","Estahban","Gerash","Zarqan","Kavar","Lamerd","Safashahr","Qaemiyeh","Hajjiabad","Farashband","Qir","Evaz","Khonj","Kharameh","Sarvestan","Arsanjan","Saadat Shahr","Qaderabad","Ardakan","Dobiran","Jannat Shahr","Galleh Dar","Soghad","Meymand","Darian","Zahedshahr","Khesht","Surian","Banaruiyeh","Masiri","Lapui","Karzin","Seyyedan","Eshkanan","Shahr-e Pir","Beyram","Bahman","Qotbabad","Juyom","Abadeh Tashk","Khur","Mohr","Beyza","Latifi","Bab Anar","Qarah Bolagh","Ij","Khumeh Zar","Konartakhteh","Miyanshahr","Izadkhast","Emam Shahr","Runiz","Mobarakabad","Sedeh","Sheshdeh","Khavaran","Meshkan","Varavi","Emad Deh","Fadami","Alamarvdasht","Khaneh Zenyan","Baladeh","Nujin","Korehi","Dezhkord","Surmaq","Mazayjan","Dehram","Kuhenjan","Khuzi","Kupon","Now Bandegan","Ahel","Hesami","Khaniman","Do Borji","Qatruyeh","Nowdan","Kamfiruz","Hamashahr","Efzar","Asir","Ramjerd","Hasanabad","Soltan Shahr","Madar-e Soleyman","Baba Monir","Duzeh","Arad","Fishvar","Rasht","Bandar-e Anzali","Lahijan","Langarud","Hashtpar","Astara","Sowme'eh Sara","Astaneh-ye Ashrafiyeh","Rudsar","Fuman","Khomam","Siahkal","Rezvanshahr","Manjil","Amlash","Kiashahr","Rostamabad","Lowshan","Rudbar","Kelachay","Masal","Lasht-e Nesha","Lavandevil","Kuchesfahan","Asalem","Rahimabad","Sangar","Chaf and Chamkhaleh","Chaboksar","Shaft","Pareh Sar","Luleman","Khoshk-e Bijar","Marjaghal","Kumeleh","Shalman","Bazar Jomeh","Chubar","Gurab Zarmikh","Vajargah","Haviq","Rudboneh","Lisar","Jirandeh","Rankuh","Ahmadsargurab","Maklavan","Tutkabon","Barehsar","Otaqvar","Deylaman","Masuleh","Gorgan","Gonbad-e Kavus","Aliabad-e Katul","Bandar Torkaman","Azadshahr","Kordkuy","Kalaleh","Aqqala","Minudasht","Galikash","Bandar-e Gaz","Gomishan","Siminshahr","Fazelabad","Ramian","Khan Bebin","Daland","Neginshahr","Now Kandeh","Sarkhon Kalateh","Jelin-e Olya","Anbar Olum","Maraveh Tappeh","Faraghi","Tatar-e Olya","Sangdevin","Mazraeh","Now Deh Khanduz","Incheh Borun","Ad-Dawr","Afak","Al-Awja","Al Diwaniyah","Al-Faris","Al Hillah","Al Qasim","Al Eskanaria","Al Mehawil","Al Mosayeb","Al-Qa'im","Al Zab","Amarah","Ar Rutba","Erbil","Baghdad","Baghdadi","Baiji","Balad","Baqubah","Basra","Dahuk","Fallujah","Haditha","Hīt","Iskandariya","Karbala","Khanaqin","Kirkuk","Najaf Governorate","Kut","Mosul (ku: Mûsil)","Muqdadiyah","Najaf","Nasiriyah","Ramadi","Samarra","Samawah","Shamia","Sulaymaniyah","Taji","Tal Afar","Tel Keppe","Tikrit","Umm Qasr","Zakho","Zubayr","Halabja","Name","Acre","Afula","Arad","Arraba","Ashdod","Ashkelon","Baqa al-Gharbiyye","Bat Yam","Beersheba","Beit She'an","Beit Shemesh","Bnei Brak","Dimona","Eilat","El'ad","Giv'at Shmuel","Givatayim","Hadera","Haifa","Herzliya","Hod HaSharon","Holon","Jerusalem","Kafr Qasim","Karmiel","Kfar Saba","Kfar Yona","Kiryat Ata","Kiryat Bialik","Kiryat Gat","Kiryat Malakhi","Kiryat Motzkin","Kiryat Ono","Kiryat Shmona","Kiryat Yam","Lod","Ma'alot-Tarshiha","Migdal HaEmek","Modi'in-Maccabim-Re'ut","Nahariya","Nazareth","Nesher","Ness Ziona","Netanya","Netivot","Nof HaGalil","Ofakim","Or Akiva","Or Yehuda","Petah Tikva","Qalansawe","Ra'anana","Rahat","Ramat Gan","Ramat HaSharon","Ramla","Rehovot","Rishon LeZion","Rosh HaAyin","Safed","Sakhnin","Sderot","Shefa-'Amr","Tamra","Tayibe","Tel Aviv-Yafo","Tiberias","Tira","Tirat Carmel","Umm al-Fahm","Yavne","Yehud-Monosson","Yokneam Illit","Beirut","Tripoli","Sidon","Tyre","Jounieh","Byblos","Aley","Nabatieh","Baalbek","Zahle","Zgharta-Ehden","Batroun","Abey - Ain Drafil","Aghmid","Ain trez","Ain Dara","Ain el Remmaneh","Ain el Saydeh","Ain Jedideh","Ain Ksour","Ain Onoub","Ainab","Aley","Aramoun el Ghareb","Baawerta","Badghan","Baissour","Bassatine","Bchamoun","Bdadoun","Bemkine","Bennieh","Bhamdoun el Balda","Bhamdoun el Mhatta","Bkhechtey","Bleibel","Bmahray","Bserrine","Bsouss","Btalloun","Btater","Chanay","Charoun","Chartoun","Chemlan","Choueifat","Deir Koubel","Dfoun","Eitat","Houmal","Kehaleh","Keyfoun","Kfaraamey","Kfar Matta","Kommatyeh","Majdelbaana","Mansourieh - Ain el Marej","Mecherfeh","Mejdlaya","Rajmeh","Ramlieh","Ras el Jabal","Rechmaya","Remhala","Rouaysset el Neeman","Saoufar","Souk el Ghareb","Taazanieh","Ain","Ainata","Arsal","Baalbek","Barka","Bednayel","Bechouat","Beit Chama - Aaqidiyeh","Brital","Btadhi","Bodai","Chaat","Chlifa","Chmestar - Gharbi Baalbeck","Deir el Ahmar","Douriss","Fakiha - Jdeydeh","Fleweh","Hadath Baalbek","Harbata","Hizzine","Hlabta","Hosh Barada","Hosh el Rafika","Hosh Snid","Hosh Tal Safiya","Jabbouleh","Janta","Jebaa (Baalbek)","Kasarnaba","Khodr","Khraibeh","Kneisseh","Iaat","Labweh","Majdloun","Mikna","Nabi Chit","Nabi Othman","Qaa","Qarha","Ram - Jbenniyeh","Ras Baalbek","Ras el Hadis","Saayde","Seriine el Fawka","Seriine el Tahta","Talya","Taraya","Tayba","Temnin el Fawka","Temnin el Tahta","Wadi Faara","Yammouneh","Younine","Karachi","Lahore","Faisalabad","Rawalpindi","Gujranwala","Peshawar","Multan","Hyderabad","Islamabad","Quetta","Bahawalpur","Sargodha","Sialkot","Sukkur","Larkana","Sheikhupura","Rahim Yar Khan","Jhang","Dera Ghazi Khan","Gujrat","Sahiwal","Wah Cantonment","Mardan","Kasur","Okara","Mingora","Nawabshah","Chiniot","Kotri","Kāmoke","Hafizabad","Sadiqabad","Mirpur Khas","Burewala","Kohat","Khanewal","Dera Ismail Khan","Turbat","Muzaffargarh","Abbotabad","Mandi Bahauddin","Shikarpur","Jacobabad","Jhelum","Khanpur","Khairpur","Khuzdar","Pakpattan","Hub","Daska","Gojra","Dadu","Muridke","Bahawalnagar","Samundri","Tando Allahyar","Tando Adam","Jaranwala","Chishtian","Muzaffarabad","Attock","Vehari","Kot Abdul Malik","Ferozwala","Chakwal","Gujranwala Cantonment","Kamalia","Umerkot","Ahmedpur East","Kot Addu","Wazirabad","Mansehra","Layyah","Mirpur","Swabi","Chaman","Taxila","Nowshera","Khushab","Shahdadkot","Mianwali","Kabal","Lodhran","Hasilpur","Charsadda","Bhakkar","Badin","Arif Wala","Ghotki","Sambrial","Jatoi","Haroonabad","Daharki","Narowal","Tando Muhammad Khan","Kamber Ali Khan","Mirpur Mathelo","Kandhkot","Bhalwal","Abu Dhalouf","Abu Hamour","Abu Samra","Ain Khaled","Ain Sinan","Al Aziziya","Baaya","Bani Hajer","Barahat Al Jufairi","Bu Fasseela","Bu Samra","Bu Sidra","Al Bidda","Dahl Al Hamam","Doha International Airport","Doha Port","Duhail","Dukhan","Al Daayen","Al Dafna","Ad Dawhah al Jadidah","Al Ebb","Al Egla","Fuwayrit","Fereej Abdel Aziz","Fereej Bin Durham","Fereej Bin Mahmoud","Fereej Bin Omran","Fereej Kulaib","Fereej Mohammed Bin Jassim","Fereej Al Amir","Fereej Al Asiri","Fereej Al Asmakh","Fereej Al Murra","Fereej Al Manaseer","Fereej Al Nasr","Fereej Al Soudan","Fereej Al Zaeem","Gharrafat Al Rayyan","Al Gharrafa","Al Ghuwariyah","Hamad Medical City","Hazm Al Markhiya","Al Hilal","Industrial Area","Izghawa (Al Rayyan)","Izghawa (Umm Salal)","Jabal Thuaileb","Jelaiah","Jeryan Jenaihat","Jeryan Nejaima","Al Jasrah","Al Jeryan","Khawr al Udayd","Al Karaana","Al Kharrara","Al Kharaitiyat","Al Kharayej","Al Kheesa","Al Khor","Al Khulaifat","Leabaib","Lebday","Lejbailat","Lekhwair","Leqtaifiya (West Bay Lagoon)","Lijmiliya","Luaib","Lusail","Al Luqta","Madinat ash Shamal","Madinat Al Kaaban","Madinat Khalifa North","Madinat Khalifa South","Mebaireek","Mehairja","Mesaieed","Mesaieed Industrial Area","Mesaimeer","Al Messila","Muaither","Muraikh","Mushayrib","Al Mamoura","Al Mansoura","Al Markhiyah","Al Mashaf","Al Masrouhiya","Al Mearad","Al Mirqab","Najma","New Al Hitmi","New Al Mirqab","New Al Rayyan","New Salata","New Fereej Al Ghanim","New Fereej Al Khulaifat","Nu`ayjah","Al Najada","Al Nasraniya","Old Airport","Old Al Ghanim","Old Al Hitmi","Old Al Rayyan","Onaiza","The Pearl","Al Qassar","Ras Abu Aboud","Ras Lafan","Rawdat Al Hamama","Rawdat Al Khail","Rawdat Egdaim","Rawdat Rashed","Rumeilah","Ar Ru'ays","Al Rufaa","Sawda Natheel","Shagra","Simaisma","Al Sadd","As Salatah","Al Sailiya","Al Sakhama","Al Shagub","Al-Shahaniya","Al Souq","Al Seej","Al Tarfa","Al Thakhira","Al Themaid","Al Thumama (Doha)","Al Thumama (Al Wakrah)","Umm Bab","Umm Birka","Umm Ghuwailina","Umm Lekhba","Umm Qarn","Umm Salal Ali","Umm Salal Mohammed","Al Utouriya","Wadi Al Banat","Wadi Al Sail","Wadi Al Wasaah","Wadi Lusail","Al Waab","Al Wajba","Al Wakrah","Al Wukair","Al Zubarah","Abha","Ad-Dilam","Al-Abwa","Al Artaweeiyah","Al Bukayriyah","Badr","Baljurashi","Bisha","Bareq","Buraydah","Al Bahah","Buq a","Dammam","Dhahran","Dhurma","Dahaban","Diriyah","Duba","Dumat Al-Jandal","Dawadmi","Farasan","Gatgat","Gerrha","Ghawiyah","Al-Gwei'iyyah","Hautat Sudair","Habaala","Hajrah","Haql","Al-Hareeq","Harmah","Ha'il","Hotat Bani Tamim","Hofuf","Huraymila","Hafr Al-Batin","Jabal Umm al Ru'us","Jalajil","Jeddah","Jizan","Jizan Economic City","Jubail","Al Jafr","Khafji","Khaybar","King Abdullah Economic City","Khamis Mushait","Al-Saih","Knowledge Economic City, Medina","Khobar","Al-Khutt","Layla","Lihyan","Al Lith","Al Majma'ah","Mastoorah","Al Mikhwah","Al-Mubarraz","Al Mawain","Medina","Mecca","Muzahmiyya","Najran","Al-Namas","Umluj","Al-Omran","Al-Oyoon","Qadeimah","Qatif","Qaisumah","Al Qunfudhah","Qurayyat","Rabigh","Rafha","Ar Rass","Ras Tanura","Riyadh","Riyadh Al-Khabra","Rumailah","Sabt Al Alaya","Sarat Abidah","Saihat","Safwa city","Sakakah","Sharurah","Shaqraa","Shaybah","As Sulayyil","Taif","Tabuk","Tanomah","Tarout","Tayma","Thadiq","Thuwal","Thuqbah","Turaif","Tabarjal","Udhailiyah","Al-'Ula","Um Al-Sahek","Unaizah","Uqair","'Uyayna","Uyun AlJiwa","Wadi Al-Dawasir","Al Wajh","Yanbu","Az Zaimah","Zulfi","Aleppo","Damascus","Daraa","Deir ez-Zor","Hama","Al-Hasakah","Homs","Idlib","Latakia","Quneitra","Raqqa","As-Suwayda","Tartus","Abu Kamal","Afrin","Arihah","Atarib","Ayn al-Arab","Azaz","Al-Bab","Baniyas","Darayya","Dayr Hafir","Douma","Duraykish","Fiq","Al-Haffah","Harem","Izra","Jableh","Jarabulus","Jisr al-Shughur","Maarat al-Numaan","Al-Malikiyah","Manbij","Masyaf","Mayadin","Mhardeh","Al-Mukharram","An-Nabk","Qamishli","Qardaha","Qatana","Qudsaya","Al-Qusayr","Al-Qutayfah","Ras al-Ayn","Al-Rastan","Al-Safira","Safita","Salamiyah","Salkhad","Al-Sanamayn","Salqin","Al-Shaykh Badr","Al-Suqaylabiyah","Tadmur","Tell Abyad","Taldou","Talkalakh","Al-Tall","Al-Thawrah","Yabroud","Zabadani","Tashkent","Samarqand","Fergana","Namangan","Andijan","Nukus","Bukhara","Qarshi","Kokand","Margilan","Dubai","Abu Dhabi","Sharjah","Al Ain","Ajman","RAK City","Fujairah","Umm al-Quwain","Khor Fakkan","Kalba","Jebel Ali","Dibba Al-Fujairah","Madinat Zayed","Ruwais","Liwa Oasis","Dhaid","Ghayathi","Ar-Rams","Dibba Al-Hisn","Hatta","Al Madam","Sana'a","Ta'izz","Al Hudaydah","Aden","Ibb","Dhamar","Mukalla","Seiyun","Zinjibar","Sayyan","Ash Shihr","Sahar","Zabid","Hajjah","Bajil District","Dhi as-Sufal","Rada'a","Socotra","Bait al-Faqih","al-Marawi'a","Yarim","Al Bayda'","'Amran","Lahij","Abs","Harad","Dimnat Chadir","Ataq","al-Mahabischa","Baihan","Marib","Thula","Az Zaydiyah","Mudiyah","Khamir","Hais","ad-Dahi","Mocha","Al Ghaydah","Al Mahwit"
    }
    }

    setCacheBy("city", city[culture][(hash % #city[culture])+1 ])
    return "City: "..getCacheBy("city") 
end

local function getProvinceNameBy(culture, hash)
  if getCacheBy("province") then return "Province: "..getCacheBy("province")  end


local province ={
    ["arabic"] = {
      "Alborz","Ardabil","Azerbaijan","Bushehr","Chahar","Fars","Gilan","Golestan","Gorgan","Hamadan","Hormozgān","Ilam","Isfahan","Semnan","Kerman","Kermanshah","Khorasan","Khuzestan","Kohgiluyeh","Kurdistan","Lorestan","Markazi","Mazandaran","Qazvin","Qom","Semnan","Sistan","Tehran","Yazd","Zanjan","adakhshan","Badghis","Baghlan","Balkh","Bamyan","Daykundi","Farah","Faryab","Ghazni","Ghor","Helmand","Herat","Jowzjan","Kabul","Kandahar","Kapisa","Khost","Kunar","Kunduz","Laghman","Logar","Nangarhar","Nimruz","Nuristan","Paktia","Paktika","Panjshir","Parwan","Samangan","Sar-e Pol","Takhar","Uruzgan","Maidan Wardak","Zabul","Azad Jammu Kashmir","Balochistan","Gilgit-Baltistan","Islamabad Capital Territory","Khyber Pakhtunkhwa","Punjab","Sindh","Barisal","Chittagong","Dhaka","Khulna","Mymensingh","Rajshahi","Nawabganj","Rangpur","Rangpur","Sylhet","","Indoensia","Aceh","Bali","Denpasar","Bangka Belitung","Pangkal Pinang","Banten","Serang","Bengkulu","Central Java","Semarang","Palangka Raya","Palu","Surabaya","Samarinda","Kupang","Gorontalo","Jakarta","Jambi","Bandar Lampung","Ambon","Tanjung Selor","Sofif","Manado","Medan","Jayapura","Pekanbaru","Tanjung Pinang","Kendari","Banjarmasin","Makassar","Palembang","Bandung","Pontianak","Mataram","Manokwari","Mamuju","Padang","Yogyakarta","Hejaz","Najd","Eastern Arabia","Asir Region","Jizan Region","Hejaz","Najd","Hejaz","Najd Ha'il","Najran Region","Badiah Al-Jawf Region","Hejaz Al-Bahah Region","Al Ḥudud ash Shamaliyah","Irbid","Ajloun","Jerash","Mafraq","North Region","Central Region","Balqa","Amman","Zarqa","Madaba","South Region","Karak","Tafilah","Ma'an","Aqaba","Aleppo Governorate","Raqqa Governorate","As-Suwayda Governorate","Damascus Governorate","Daraa Governorate","Deir ez-Zor Governorate","Hama Governorate","Hasaka Governorate","Homs Governorate","Idlib Governorate","Latakia Governorate","Quneitra Governorate","Rif Dimashq Governorate","Tartus Governorate","Ad-Daqahiyah","Ajā","Al-Jamāliyah","Al-Kurdy","Al-Manṣūrah","Al-Manṣūrah","Al-Manṣūrah","Al-Manzilah","Al-Maṭariyah","As-Sinbillāwayn","Banī Ubayd","Bilqās","Dikirnis","Jamaṣah","Maḥallat Damanah","Minyat an-Naṣr","Mīt Ghamr","Mīt Ghamr","Mīt Salsīl","Nabarūh","Shirbīn","Ṭalkhā","Timay al-Imdīd",
      "Al-Baḥral-Aḥmar","Al-Ghurdaqah","Al-Ghurdaqah","Al-Quṣayr","Ash-Shalātīn","Ḥalāyib","Marsā 'Alam","Ras Ghārib","Safājā","Al-Buḥayrah","Abū al-Maṭāmīr","Abū Ḥummuṣ","Ad-Dilinjāt","Al-Maḥmūdiyah","Ar-Raḥmāniyah","Badr","Damanhūr","Gharb an-Nūbāriyah","Ḥawsh 'Īsā","Idkū","Ityāy al-Bārūd","Kafr ad-Dawwār","Kawm Ḥamādah","Rashīd","Shubrākhīt","Wadi an-Natrun","Al-Fayyūm","Ibshawāy","Iṭsā","Madīnat al-Fayyūm al-Jadīdah","Sinnūris","Ṭāmiyah","Yūsuf aṣ-Ṣiddīq","Al-Gharbiyah","Al-Maḥallah al-Kubrā","As-Sanṭah","Basyūn","Kafr az-Zayyāt","Quṭūr","Samannūd","Ṭanṭā","Ziftā","Al-Iskandariyah","Ādārh Shurṭah Mīnā' al-Iskandariyah","Ad-Dukhaylah","Al-'Āmriyah","Al-'Aṭṭārīn","Al-Jumruk","Al-Labān","Al-Manshiyah","Al-Muntazah","Ar-Raml","As-Sāḥal ash-Shamāli","Bāb Sharqi","Burj al-'Arab","Karmūz","Madīnat Burj al-'Arab al-Jadīdah","Mīnā al-Baṣal","Muḥarram Bik","Sīdi Jābir","Al-Ismā'īliyah","Abū Ṣuwīr","Al-Ismā'īliyah","Al-Ismā'īliyah","Al-Qanṭarah","Al-Qanṭarah Sharq","Al-Qaṣāṣīn al-Jadīdah","At-Tall al-Kabīr","Fa'id","Al-Jīzah","Ad-Duqqī","Al-Ahrām","Al-'Ajūzah","Al-'Ayyāṭ","Al-Badrashayn","Al-Ḥawāmidiyah","Al-Jīza","Al-'Umrāniyah","Al-Wāḥāt al-Baḥariyah","Al-Warrāq","Ash-Shaykh Zāyid","Aṣ-Ṣaff","Aṭfīḥ","Aṭ-Ṭālbīah","Awsīm","Būlāq al-Dakrūr","Imbābah","Kirdāsah","Madīnat Sittah Uktūbar","Al-Minūfiyah","Al-Bājūr","Ashmūn","Ash-Shuhadā'","Birkat as-Sab'","Madīnat as-Sādāt","Minūf","Quwaysinā","Shibīn al-Kawm","Shibīn al-Kawm","Sirs al-Layyānah","Talā","Al-Minyā","Abū Qurqās","Al-'Idwah","Al-Minyā","Banī Mazār","Dayr Mawās","Madīnat al-Minyā al-Jadīdah","Maghāghah","Malawiṭ Gharb","Mallawī","Maṭāy","Samālūṭ","Al-Qāhirah","Māyū","'Ābidīn","Ad-Darb al-Aḥmar","'Ain Schams","Al-Amīriīah","Al-Azbakiyah","Al-Basātīn","Al-Jamāliyah","Al-Khalīfah","Al-Ma'ādī","Al-Marj","Al-Ma'ṣarah","Al-Maṭariyah","Al-Muqaṭṭam","Al-Mūskī","Al-Qāhirah al-Jadīdah","Al-Waylī","An-Nuzhah","Ash-Sharābiyah","Ash-Shurūq","As-Salām","As-Sayyidah Zaynab","At-Tibbīn","Aẓ-Ẓāhir","Az-Zamālik","Az-Zāwiyah al-Ḥamrā'","Az-Zaytūn","Bāb ash-Sha'riyah","Būlāq","Hada'iq al-Qubbah","Ḥulwān","Madīnat an-Naṣr","Madīnat Badr","Heliopolis","Miṣr al-Qadīmah","Munsha'āt Nāṣr","Qaṣr an-Nīl","Rūd al-Faraj","Shubrā","Al-Qalyūbyah","Al-Khānkah","Al-'Ubūr","Shubrā al-Khaymah","Sibīn al-Qanāṭir","Ṭūkh","Al-Uqṣur","arkaz","New Valley","Al-Wāḥāt al-Khārijah","alāṭ","Markaz","Shurṭah Bārīs","Abū Ḥammād","Abū Kabīr","Al-Ḥusayniyah","Al-Ibrāhīmiyah","Al-Qanāyāt","Al-Qurayn","Aṣ-Ṣaliḥiyah al-Jadīdah","Awlād Ṣaqr","Az-Zaqāzīq","Bilbays","Diyarb Najm","Fāqūs","Fāqūs","Hihyā","Kafr Ṣaqr","Madīnat 'Ashirh min-Ramaḍān","Mashtūl as-Sūq","Minyā al-Qamḥ","Munshāh Abū 'Umar","Ṣān al-Ḥajar","As-Suways","Al-Arba'īn","Al-Janāyin","As-Suways","'Atāqah","Fayṣal","Idārah Shurṭah Mīnā' as-Suways","Aswān","Abū Sunbul","Aswān","Daraw","Idfū","Kawm Umbū","Madīnat Aswān al-Jadīdah","Naṣr","Asyūt","Abnūb","Abū Tīj","Al-Badārī","Al-Fatḥ","Al-Ghanāyim","Al-Qūṣiyah","Asyūṭ","Dayrūṭ","Madīnat Asyūṭ al-Jadīdah","Manfalūṭ","Sāḥīl Salim","Ṣidfa","Banī Suwayf","Al-Fashn","Al-Wāsiṭā","Banī Suwayf","Bibā","Ihnāsiyā","Madīnat Banī Suwayf al-Jadīdah","Nāṣir","Sumusṭā al-Waqf","Būr Sa'īd","Aḍ-Ḍawāḥy","Al-'Arab","Al-Janūb","Al-Manākh","Al-Manāṣrah","Ash-Sharq","Az-Zuhūr","Būr Fuād","Idārah Shurṭah Mīnā' Būr Sa'īd","Mubārak","Dumyāṭ","Az-Zarqā'","Fāraskūr","Kafr al-Baṭṭīkh","Kafr Sa'd","Madīnat Dumyāṭ al-Jadīdah","Ra's al-Bar","Kafr ash-Shaykh","Al-Burulus","Al-Ḥāmūl","Ar-Riyād","Biyalā","Biyalā","Disūq","Fuwah","Kafr ash-Shaykh","Muṭūbis","Qallīn","Sīdī Sālim","Maṭrūḥ","Aḍ-Ḍab'ah","Al-'Alamayn","Al-Ḥammām","An-Najīlah","As-Sāḥal ash-Shamāli","As-Sallūm","Marsā Maṭrūḥ","Sīdī Barrānī","Sīwa","Qinā","Abū Ṭisht","Al-Waqf","Dishnā","Farshūṭ","Madīnat Qinā al-Jadīdah","Naj' Ḥammādī","Naqādah","Qifṭ","Qinā","Qinā","Qūṣ","Sawhāj","Akhmīm","Al-Balyanā","Al-Kawthar","Al-Marāghah","Al-Munsha'āh","Al-'Usayrāt","Dar as-Salām","Jirjā","Juhaynah al-Gharbiyah","Madīnat Akhmīm al-Jadīdah","Madīnat Sawhāj al-Jadīdah","Sāqultah","Sawhāj","Ṭahṭā","Ṭahṭā","Ṭimā","Sīnā' al-Janūbiyah","Abū Radīs","Aṭ-Ṭūr","Dahab","Nuwaybi'a","Ras Sidr","Sānt Kātirīn","Sharm ash-Shaykh","Shurṭah Ṭābā","Sīnā' ash-Shamāliyah","Al-'Arīsh","Al-Ḥasanah","Ash-Shaykh Zuwayd","B'īr al-'Abd","Nakhl","Rafaḥ","Shurṭah al-Qasīmah","Shurṭah Rumānah","Miṣr","Al Butnan","Darnah","Al Jabal al Akhdar","Al Marj","Banghazi","Al Wahat","Al Kufrah","Surt","Misratah","Marqab","Tarabulus","Al Jafarah","Az Zawiyah","An Nuqat al Khams","Al Jabal al Gharbi","Nalut","Al Jufrah","Wadi ash Shati'","Sabha","Wadi al Hayat","Ghat","Murzuq","","Chaouia - Ouardigha","Doukkala - Abda","Fès - Boulemane","Gharb - Chrarda - Béni Hssen","Grand Casablanca","Guelmim - Es-Semara","Laâyoune - Boujdour","Marrakech - Tensift","Meknès - Tafilalet","Oriental","Oued Ed-Dahab - Lagouira","Rabat - Salé - Zemmour","Souss - Massa - Draâ","Tadla - Azilal","Tanger - Tétouan","Taza - Al Hoceima - Taounate","Adrar","Chlef","Laghouat","Oum El Bouaghi","Batna","Béjaïa","Biskra","Béchar","Blida","Bouïra","Tamanrasset","Tébessa","Tlemcen","Tiaret","Tizi Ouzou","Alger","Djelfa","Jijel","Sétif","Saïda","Skikda","Sidi Bel Abbès","Annaba","Guelma","Constantine","Médéa","Mostaganem","M'Sila","Mascara","Ouargla","Oran","El Bayadh","Illizi","Bordj Bou Arréridj","Boumerdès","El Tarf","Tindouf","Tissemsilt","El Oued","Khenchela","Souk Ahras","Tipaza","Mila","Aïn Defla","Naâma","Aïn Témouchent","Ghardaïa","Relizane","El M'ghair","El Menia","Ouled Djellal","Bordj Baji Mokhtar","Béni Abbès","Timimoun","Touggourt","Djanet","In Salah","In Guezzam",  
    }
}
    setCacheBy("province", province[culture][(hash % #province[culture])+1 ])
    return "Province: "..getCacheBy("province") 
end

local function getRegionByCulture(culture)
  if culture == "arabic" then return "Middle East Asia" end
  if culture == "western" then return "Europa" end
end

local function getCountryNameBy(culture, hash)
  if getCacheBy("country") then return "Country: "..getCacheBy("country")  end

local country ={
    ["arabic"] = {
      "Senegal","Westsahara","Maroko","Mauretania","Algeria","Tunesia","Libya","Chad","Niger","Sudan","Egypt",
     "Eritrea","Ethopia","Kenya","Yemen","Saudi Arabia","Israel","Oman","United Arab Emirates","Qatar","Dubai",
     "Uzbekistan","Xinjiang","Rajasthan","Iran","Armenia","Azerbaijan","Afghanistan","Pakistan","Turkmenistan","Tajikistan Jordan","Lebanon","Syria","Iraq","Kuwait","Bahrain", 
     "Sri Lanka","Bangladesh","Myanmar","Indonesia","Kazakhstan","Mongolia"
      }
  }

   setCacheBy("country", country[culture][(hash % #country[culture])+1 ]..", "..getRegionByCulture(culture))
   return "Country: "..getCacheBy("country") 
end

local boolStartSound = false
local longestString = 2

function widget:DrawScreenEffects(vsx, vsy)
  local currentFrame = Spring.GetGameFrame()
    if currentFrame >= startFrame and currentFrame < endFrame + fadeOutPhaseFrames then 
        local fadeOutFactor = 1.0
        if currentFrame > endFrame then
            fadeOutFactor = (fadeOutPhaseFrames - (currentFrame-endFrame))/fadeOutPhaseFrames 
        end
        local hash = getDetermenisticHash()
        local rawtimeStamp = getDayTimeString()
        local rawcitypart = getNeighbourhoodName("arabic",hash)
        local rawcityname = getCityNameBy("arabic", hash)
        local rawprovince = getProvinceNameBy("arabic",hash)
        local rawcountry = getCountryNameBy("arabic",hash)
        for k, v in pairs(cache) do
            longestString = math.max(longestString, string.len(v))
        end

        local timestepFramesPerString = displayStaticFrameIntervallLength/longestString
        local timeStep = math.floor((currentFrame - startFrame)/timestepFramesPerString)

        local timeStamp = getRollingString(rawtimeStamp, timeStep, currentFrame)
        local citypart = getRollingString(rawcitypart, timeStep, currentFrame)
        local cityname = getRollingString(rawcityname, timeStep, currentFrame)
        local province = getRollingString(rawprovince, timeStep, currentFrame)
        local country = getRollingString(rawcountry, timeStep, currentFrame)
       
        if boolStartSound== false and timeStep == 2  then
          boolStartSound = true
          Spring.PlaySoundFile("LuaUi/sounds/telex.ogg", 0.75, 'ui')
        end

        local timeStamp = getRollingString(getDayTimeString(), timeStep, currentFrame)
        local citypart = getRollingString(getNeighbourhoodName("arabic",hash), timeStep, currentFrame)
        local cityname = getRollingString(getCityNameBy("arabic", hash), timeStep, currentFrame)
        local province = getRollingString(getProvinceNameBy("arabic",hash), timeStep, currentFrame)
        local country = getRollingString(getCountryNameBy("arabic",hash), timeStep, currentFrame)
      

        local textCol = {0.124, 200/255, 255/255, 0.9*fadeOutFactor}
        local screenX, screenY = anchorx, anchory
        local lineOffset = 50*scale
        local lineIndex = 0
        local FontSize = fontSize *scale

        gl.Color(textCol[1],textCol[2],textCol[3],textCol[4])

        glText(country, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1      

        glText(province, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1         

        glText(cityname, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1      
  

        glText(citypart, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        lineIndex = lineIndex + 1      

        glText(timeStamp, screenX, screenY+ lineIndex*lineOffset ,FontSize,"r")
        gl.Color(1,1,1,1)


    end
end

