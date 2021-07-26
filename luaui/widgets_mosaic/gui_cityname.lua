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
    name      = "Display Cityname",
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
local endFrame = startFrame + (20*30)
local displayStaticFrame = endFrame
local displayStaticFrameIntervallLength = endFrame
local vsx,vsy = Spring.GetViewGeometry()
local anchorx, anchory
local glColor           = gl.Color
local glText            = gl.Text
local fontSize          = 32
local scale            = 1

local function setAnchorsRelative(nvx, nvy)
  anchorx, anchory = nvx*0.9,nvy*0.15 
end

function widget:Initialize()
   startFrame = Spring.GetGameFrame()
   endFrame = startFrame + (15*30)
   displayStaticFrameIntervallLength = math.ceil(0.4*(endFrame - startFrame))
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

local function getNeighbourhoodName(culture, hash)
local Neighbourhoods ={
    ["arabic"] = {
    "Suk","Burgazada","Heybeliada","Kınalıada","Maden","Nizam","Anadolu","İmrahor","İslambey","Merkez","Yavuzselim","Atatürk","Bahşayış","Boğazköy Atatürk","Boğazköy İstiklal","Boğazköy Merkez","Bolluca","Deliklikaya","Dursunköy","Durusu Cami","Durusu Zafer","Hastane","İstasyon","Sazlıbosna","Nakkaş","Karlıbayır","Haraççı","Hicret","Mavigöl","Nenehatun","Ömerli","Taşoluk","Taşoluk Adnan Menderes","Taşoluk Çilingir","Taşoluk","Taşoluk M. Fevzi Çakmak","Taşoluk Mehmet Akif ErsoyAşıkveysel","Atatürk","Barbaros","Esatpaşa","Ferhatpaşa","Fetih","İçerenköy","İnönü","Kayışdağı","Küçükbakkalköy","Mevlana","Mimarsinan","Mustafa Kemal","Örnek","Yeniçamlıca","Yenişehir","Yenisahra","Ambarlı","Cihangir","Denizköşkler","Firuzköy","Gümüşpala","Merkez","Mustafa Kemal Paşa","Tahtakale","Üniversite","Yeşilkent","Bağlar","Barbaros","Çınar","Demirkapı","Evren","Fevzi Çakmak","Göztepe","Güneşli","Hürriyet","İnönü","Kâzım Karabekir","Kemalpaşa","Kirazlı","Mahmutbey","Merkez","Sancaktepe","Yavuzselim","Yenigün","Yenimahalle","Yıldıztepe","Yüzyıl","Cumhuriyet","Çobançeşme","Fevzi Çakmak","Hürriyet","Kocasinan","Siyavuşpaşa","Soğanlı","Şirinevler","Yenibosna","Zafer","Ataköy 1. kısım","Ataköy 2-5-6. kısım","Ataköy 3-4-11. kısım","Ataköy 7-8-9-10. kısım","Basınköy","Cevizlik","Kartaltepe","Osmaniye","Sakızağacı","Şenlikköy","Yenimahalle","YeşilköyYeşilyurtZeytinlik","Zuhuratbaba","Altınşehir","Başak","Güvercintepe","Kayabaşı","Şahintepe","Ziya Gökalp","Altıntepsi","Cevatpaşa","İsmetpaşa","Kartaltepe","Kocatepe","Muratpaşa","Orta","Terazidere","Vatan","Yenidoğan","Yıldırım","","Beşiktaş","Abbasağa","Akatlar","Balmumcu","Bebek","Cihannüma","Dikilitaş","Etiler","Gayrettepe","Konaklar","Kuruçeşme","Kültür","Levazım","Levent","Mecidiye","Muradiye","Nisbetiye","Ortaköy","Sinanpaşa","Türkali","Ulus","Vişnezade","YıldızAcarlar","Anadoluhisarı","Anadolukavağı","Baklacı","Çamlıbahçe","Çengeldere","Çiftlik","Çiğdem","Çubuklu","Göksu","Göztepe","Gümüşsuyu","İncirköy","Kanlıca","Kavacık","Merkez","Ortaçeşme","Paşabahçe","Rüzgarlıbahçe","Soğuksu","Tokatköy","Yalıköy","Yavuz Selim","Yenimahalle","Barış","Büyükşehir","Cumhuriyet","Dereağzı","Gürpınar","Kavaklı","Marmara","Sahil","Yakuplu","Arapcami","Asmalımescit","Bedrettin","Bereketzade","Bostan","Bülbül","Camiikebir","CihangirÇatmamescit","Çukur","Emekyemez","Evliya Çelebi","Fetihtepe","Firuzağa","Gümüşsuyu","Hacıahmet","Hacımimi","Halıcıoğlu","Hüseyinağa","İstiklal","Kadı Mehmet Efendi","Kamerhatun","Kalyoncukulluğu","Kaptanpaşa","Katip Mustafa Çelebi","Keçecipiri","Kemankeş Kara Mustafa Paşa","Kılıçalipaşa","Kocatepe","Kulaksız","Kuloğlu","Küçükpiyale","Müeyyetzade","Ömeravni","Örnektepe","Piripaşa","Piyalepaşa","Pürtelaş","Sururi","Sütlüce","Şahkulu","Şehit Muhtar","Tomtom","Yahya Kahya","Yenişehir","19 Mayıs","Ahmediye","Alkent","Atatürk","Batıköy","Celaliye","Cumhuriyet","Çakmaklı","Dizdariye","Güzelce","Hürriyet","Kamiloba","Karaağaç","Kumburgaz Merkez","Mimarsinan","Muratbey","Muratçeşme","Pınartepe","Türkoba","Ulus","Yenimahalle","Binkılıç","Çakıl","Çiftlikköy","Ferhatpaşa","İzettin","Kaleiçi","Karacaköy","Ovayenice","Alemdağ","Aydınlar","Cumhuriyet","Çamlık","Çatalmeşe","Ekşioğlu","Güngören","Hamidiye","Kirazlıdere","Mehmet Akif","Merkez","Mimar Sinan","Nişantepe","Ömerli","Soğukpınar","Sultançiftliği","Taşdelen","Birlik","Çiftehavuzlar","Davutpaşa","","Fevzi Çakmak","Havaalanı","Kâzım Karabekir","Kemer","Menderes","Mimarsinan","Namık Kemal","Nenehatun","Oruçreis","Tuna","Turgutreis","Yavuz Selim","Ardıçlıevler","Atatürk","Cumhuriyet","Çakmaklı","Esenkent","Güzelyurt (Haramidere)","İncirtepe","İnönü","İstiklal","Mehterçeşme","Merkez","Namik Kemal","Örnek","Pınar","Saadetdere","Sanayii","Talatpasa","Yenikent","Yeşilkent","Akşemsettin","Alibeyköy","Çırçır","Defterdar","Düğmeciler","Emniyettepe","Esentepe","Merkez","Göktürk","Güzeltepe","İslambey","Karadolap","Mimarsinan","Mithatpaşa","Nişanca","Rami Cuma","Rami Yeni","Sakarya","Silahtarağa","Topçular","Yeşilpınar","Aksaray","Akşemsettin","Alemdar","Ali Kuşçu","Atikali","Ayvansaray","Balabanağa","Balat","Beyazıt","Binbirdirek","Cankurtaran","Cerrahpaşa","Cibali","Demirtaş","Derviş Ali","Eminsinan","Hacıkadın","Hasekisultan","Hırkaişerif","Hobyar","Hoca Giyasettin","Hocapaşa","İskenderpaşa","Kalenderhane","Karagümrük","Katip Kasım","Kemalpaşa","Kocamustafapaşa","Küçükayasofya","Mercan","Mesihpaşa","Mevlanakapı","Mimar Hayrettin","Mimar Kemalettin","Mollafenari","Mollagürani","Mollahüsrev","Muhsinehatun","Nişanca","Rüstempaşa","Saraçishak","Sarıdemir","Seyyid Ömer","Silivrikapı","Sultanahmet","Sururi","Süleymaniye","Sümbülefendi","Şehremini","Şehsuvarbey","Tahtakale","Tayahatun","Topkapı","Yavuzsinan","Yavuz Sultan Selim","Yedikule","Zeyrek","Abbas Abad","Afsariyeh","Aghdasieh","Ajudanieh","Almahdi","Amir Abad","Bagh Feiz","Bahar","Baharestan","City Park","Darabad","Darakeh","Darband","Dardasht","Darrous","Davoodiyeh14","Doulat","Ekbatan","Ekhtiarieh","Elahieh","Evin","Farahzad","Farmanieh","Gheytarieh","Gholhak","Gisha","Gomrok","HaftHoz","Jamaran","Jannat Abad","Javadiyeh","Javan Mard-e Ghassab Tomb","Kamranieh","Khavaran","Lavizan","Mahmoodieh","Mehran","Narmak","Navvab","Nazi Abad","Nelson Mandela Boulevard","","Niavaran","Pasdaran","Piroozi","Punak","Ray","Iran","Resalat","Sa'adat Abad","Sadeghiyeh","Sarsabz","Seyed Khandan","Shahr-e No","Shahr-e ziba","Shahrak-e Gharb","Shahran","","Shahrara","Shemiran","Sohrevardi","Surena Street","Tajrish","Tarasht","pars","sar","Toopkhaneh","Town of Masoudieh","Vanak","Velenjak","Yaft Abad","Yusef Abad","Zafaraniyeh"
    }
}
return "Area: "..Neighbourhoods[culture][(hash % #Neighbourhoods[culture])+1 ]
end

local function getCityNameBy(culture, hash)
local city ={
    ["arabic"] = {
    "Abu El Matamir",
    "Abu Hummus",
    "Abu Tesht",
    "Akhmim",
    "Al Khankah",
    "Alexandria",
    "Arish",
    "Ashmoun",
    "Aswan",
    "Asyut",
    "Awsim",
    }
    }

      return "City: "..city[culture][(hash % #city[culture])+1 ] or "Cityname"
end

local function getProvinceNameBy(culture, hash)
local provinces ={
    ["arabic"] = {
      "Alborz","Ardabil","Azerbaijan","Bushehr","Chahar","Fars","Gilan","Golestan","Gorgan","Hamadan","Hormozgān","Ilam","Isfahan","Semnan","Kerman","Kermanshah","Khorasan","Khuzestan","Kohgiluyeh","Kurdistan","Lorestan","Markazi","Mazandaran","Qazvin","Qom","Semnan","Sistan","Tehran","Yazd","Zanjan","adakhshan","Badghis","Baghlan","Balkh","Bamyan","Daykundi","Farah","Faryab","Ghazni","Ghor","Helmand","Herat","Jowzjan","Kabul","Kandahar","Kapisa","Khost","Kunar","Kunduz","Laghman","Logar","Nangarhar","Nimruz","Nuristan","Paktia","Paktika","Panjshir","Parwan","Samangan","Sar-e Pol","Takhar","Uruzgan","Maidan Wardak","Zabul","Azad Jammu Kashmir","Balochistan","Gilgit-Baltistan","Islamabad Capital Territory","Khyber Pakhtunkhwa","Punjab","Sindh","Barisal","Chittagong","Dhaka","Khulna","Mymensingh","Rajshahi","Nawabganj","Rangpur","Rangpur","Sylhet","","Indoensia","Aceh","Bali","Denpasar","Bangka Belitung","Pangkal Pinang","Banten","Serang","Bengkulu","Central Java","Semarang","Palangka Raya","Palu","Surabaya","Samarinda","Kupang","Gorontalo","Jakarta","Jambi","Bandar Lampung","Ambon","Tanjung Selor","Sofif","Manado","Medan","Jayapura","Pekanbaru","Tanjung Pinang","Kendari","Banjarmasin","Makassar","Palembang","Bandung","Pontianak","Mataram","Manokwari","Mamuju","Padang","Yogyakarta","Hejaz","Najd","Eastern Arabia","Asir Region","Jizan Region","Hejaz","Najd","Hejaz","Najd Ha'il","Najran Region","Badiah Al-Jawf Region","Hejaz Al-Bahah Region","Al Ḥudud ash Shamaliyah","Irbid","Ajloun","Jerash","Mafraq","North Region","Central Region","Balqa","Amman","Zarqa","Madaba","South Region","Karak","Tafilah","Ma'an","Aqaba","Aleppo Governorate","Raqqa Governorate","As-Suwayda Governorate","Damascus Governorate","Daraa Governorate","Deir ez-Zor Governorate","Hama Governorate","Hasaka Governorate","Homs Governorate","Idlib Governorate","Latakia Governorate","Quneitra Governorate","Rif Dimashq Governorate","Tartus Governorate","Ad-Daqahiyah","Ajā","Al-Jamāliyah","Al-Kurdy","Al-Manṣūrah","Al-Manṣūrah","Al-Manṣūrah","Al-Manzilah","Al-Maṭariyah","As-Sinbillāwayn","Banī Ubayd","Bilqās","Dikirnis","Jamaṣah","Maḥallat Damanah","Minyat an-Naṣr","Mīt Ghamr","Mīt Ghamr","Mīt Salsīl","Nabarūh","Shirbīn","Ṭalkhā","Timay al-Imdīd",
      "Al-Baḥral-Aḥmar","Al-Ghurdaqah","Al-Ghurdaqah","Al-Quṣayr","Ash-Shalātīn","Ḥalāyib","Marsā 'Alam","Ras Ghārib","Safājā","Al-Buḥayrah","Abū al-Maṭāmīr","Abū Ḥummuṣ","Ad-Dilinjāt","Al-Maḥmūdiyah","Ar-Raḥmāniyah","Badr","Damanhūr","Gharb an-Nūbāriyah","Ḥawsh 'Īsā","Idkū","Ityāy al-Bārūd","Kafr ad-Dawwār","Kawm Ḥamādah","Rashīd","Shubrākhīt","Wadi an-Natrun","Al-Fayyūm","Ibshawāy","Iṭsā","Madīnat al-Fayyūm al-Jadīdah","Sinnūris","Ṭāmiyah","Yūsuf aṣ-Ṣiddīq","Al-Gharbiyah","Al-Maḥallah al-Kubrā","As-Sanṭah","Basyūn","Kafr az-Zayyāt","Quṭūr","Samannūd","Ṭanṭā","Ziftā","Al-Iskandariyah","Ādārh Shurṭah Mīnā' al-Iskandariyah","Ad-Dukhaylah","Al-'Āmriyah","Al-'Aṭṭārīn","Al-Jumruk","Al-Labān","Al-Manshiyah","Al-Muntazah","Ar-Raml","As-Sāḥal ash-Shamāli","Bāb Sharqi","Burj al-'Arab","Karmūz","Madīnat Burj al-'Arab al-Jadīdah","Mīnā al-Baṣal","Muḥarram Bik","Sīdi Jābir","Al-Ismā'īliyah","Abū Ṣuwīr","Al-Ismā'īliyah","Al-Ismā'īliyah","Al-Qanṭarah","Al-Qanṭarah Sharq","Al-Qaṣāṣīn al-Jadīdah","At-Tall al-Kabīr","Fa'id","Al-Jīzah","Ad-Duqqī","Al-Ahrām","Al-'Ajūzah","Al-'Ayyāṭ","Al-Badrashayn","Al-Ḥawāmidiyah","Al-Jīza","Al-'Umrāniyah","Al-Wāḥāt al-Baḥariyah","Al-Warrāq","Ash-Shaykh Zāyid","Aṣ-Ṣaff","Aṭfīḥ","Aṭ-Ṭālbīah","Awsīm","Būlāq al-Dakrūr","Imbābah","Kirdāsah","Madīnat Sittah Uktūbar","Al-Minūfiyah","Al-Bājūr","Ashmūn","Ash-Shuhadā'","Birkat as-Sab'","Madīnat as-Sādāt","Minūf","Quwaysinā","Shibīn al-Kawm","Shibīn al-Kawm","Sirs al-Layyānah","Talā","Al-Minyā","Abū Qurqās","Al-'Idwah","Al-Minyā","Banī Mazār","Dayr Mawās","Madīnat al-Minyā al-Jadīdah","Maghāghah","Malawiṭ Gharb","Mallawī","Maṭāy","Samālūṭ","Al-Qāhirah","Māyū","'Ābidīn","Ad-Darb al-Aḥmar","'Ain Schams","Al-Amīriīah","Al-Azbakiyah","Al-Basātīn","Al-Jamāliyah","Al-Khalīfah","Al-Ma'ādī","Al-Marj","Al-Ma'ṣarah","Al-Maṭariyah","Al-Muqaṭṭam","Al-Mūskī","Al-Qāhirah al-Jadīdah","Al-Waylī","An-Nuzhah","Ash-Sharābiyah","Ash-Shurūq","As-Salām","As-Sayyidah Zaynab","At-Tibbīn","Aẓ-Ẓāhir","Az-Zamālik","Az-Zāwiyah al-Ḥamrā'","Az-Zaytūn","Bāb ash-Sha'riyah","Būlāq","Hada'iq al-Qubbah","Ḥulwān","Madīnat an-Naṣr","Madīnat Badr","Heliopolis","Miṣr al-Qadīmah","Munsha'āt Nāṣr","Qaṣr an-Nīl","Rūd al-Faraj","Shubrā","Al-Qalyūbyah","Al-Khānkah","Al-'Ubūr","Shubrā al-Khaymah","Sibīn al-Qanāṭir","Ṭūkh","Al-Uqṣur","arkaz","New Valley","Al-Wāḥāt al-Khārijah","alāṭ","Markaz","Shurṭah Bārīs","Abū Ḥammād","Abū Kabīr","Al-Ḥusayniyah","Al-Ibrāhīmiyah","Al-Qanāyāt","Al-Qurayn","Aṣ-Ṣaliḥiyah al-Jadīdah","Awlād Ṣaqr","Az-Zaqāzīq","Bilbays","Diyarb Najm","Fāqūs","Fāqūs","Hihyā","Kafr Ṣaqr","Madīnat 'Ashirh min-Ramaḍān","Mashtūl as-Sūq","Minyā al-Qamḥ","Munshāh Abū 'Umar","Ṣān al-Ḥajar","As-Suways","Al-Arba'īn","Al-Janāyin","As-Suways","'Atāqah","Fayṣal","Idārah Shurṭah Mīnā' as-Suways","Aswān","Abū Sunbul","Aswān","Daraw","Idfū","Kawm Umbū","Madīnat Aswān al-Jadīdah","Naṣr","Asyūt","Abnūb","Abū Tīj","Al-Badārī","Al-Fatḥ","Al-Ghanāyim","Al-Qūṣiyah","Asyūṭ","Dayrūṭ","Madīnat Asyūṭ al-Jadīdah","Manfalūṭ","Sāḥīl Salim","Ṣidfa","Banī Suwayf","Al-Fashn","Al-Wāsiṭā","Banī Suwayf","Bibā","Ihnāsiyā","Madīnat Banī Suwayf al-Jadīdah","Nāṣir","Sumusṭā al-Waqf","Būr Sa'īd","Aḍ-Ḍawāḥy","Al-'Arab","Al-Janūb","Al-Manākh","Al-Manāṣrah","Ash-Sharq","Az-Zuhūr","Būr Fuād","Idārah Shurṭah Mīnā' Būr Sa'īd","Mubārak","Dumyāṭ","Az-Zarqā'","Fāraskūr","Kafr al-Baṭṭīkh","Kafr Sa'd","Madīnat Dumyāṭ al-Jadīdah","Ra's al-Bar","Kafr ash-Shaykh","Al-Burulus","Al-Ḥāmūl","Ar-Riyād","Biyalā","Biyalā","Disūq","Fuwah","Kafr ash-Shaykh","Muṭūbis","Qallīn","Sīdī Sālim","Maṭrūḥ","Aḍ-Ḍab'ah","Al-'Alamayn","Al-Ḥammām","An-Najīlah","As-Sāḥal ash-Shamāli","As-Sallūm","Marsā Maṭrūḥ","Sīdī Barrānī","Sīwa","Qinā","Abū Ṭisht","Al-Waqf","Dishnā","Farshūṭ","Madīnat Qinā al-Jadīdah","Naj' Ḥammādī","Naqādah","Qifṭ","Qinā","Qinā","Qūṣ","Sawhāj","Akhmīm","Al-Balyanā","Al-Kawthar","Al-Marāghah","Al-Munsha'āh","Al-'Usayrāt","Dar as-Salām","Jirjā","Juhaynah al-Gharbiyah","Madīnat Akhmīm al-Jadīdah","Madīnat Sawhāj al-Jadīdah","Sāqultah","Sawhāj","Ṭahṭā","Ṭahṭā","Ṭimā","Sīnā' al-Janūbiyah","Abū Radīs","Aṭ-Ṭūr","Dahab","Nuwaybi'a","Ras Sidr","Sānt Kātirīn","Sharm ash-Shaykh","Shurṭah Ṭābā","Sīnā' ash-Shamāliyah","Al-'Arīsh","Al-Ḥasanah","Ash-Shaykh Zuwayd","B'īr al-'Abd","Nakhl","Rafaḥ","Shurṭah al-Qasīmah","Shurṭah Rumānah","Miṣr","Al Butnan","Darnah","Al Jabal al Akhdar","Al Marj","Banghazi","Al Wahat","Al Kufrah","Surt","Misratah","Marqab","Tarabulus","Al Jafarah","Az Zawiyah","An Nuqat al Khams","Al Jabal al Gharbi","Nalut","Al Jufrah","Wadi ash Shati'","Sabha","Wadi al Hayat","Ghat","Murzuq","","Chaouia - Ouardigha","Doukkala - Abda","Fès - Boulemane","Gharb - Chrarda - Béni Hssen","Grand Casablanca","Guelmim - Es-Semara","Laâyoune - Boujdour","Marrakech - Tensift","Meknès - Tafilalet","Oriental","Oued Ed-Dahab - Lagouira","Rabat - Salé - Zemmour","Souss - Massa - Draâ","Tadla - Azilal","Tanger - Tétouan","Taza - Al Hoceima - Taounate","Adrar","Chlef","Laghouat","Oum El Bouaghi","Batna","Béjaïa","Biskra","Béchar","Blida","Bouïra","Tamanrasset","Tébessa","Tlemcen","Tiaret","Tizi Ouzou","Alger","Djelfa","Jijel","Sétif","Saïda","Skikda","Sidi Bel Abbès","Annaba","Guelma","Constantine","Médéa","Mostaganem","M'Sila","Mascara","Ouargla","Oran","El Bayadh","Illizi","Bordj Bou Arréridj","Boumerdès","El Tarf","Tindouf","Tissemsilt","El Oued","Khenchela","Souk Ahras","Tipaza","Mila","Aïn Defla","Naâma","Aïn Témouchent","Ghardaïa","Relizane","El M'ghair","El Menia","Ouled Djellal","Bordj Baji Mokhtar","Béni Abbès","Timimoun","Touggourt","Djanet","In Salah","In Guezzam",  
    }
}

  return "Province: "..provinces[culture][(hash % #provinces[culture])+1 ] or "province"
end


function widget:DrawScreenEffects(vsx, vsy)
  local currentFrame = Spring.GetGameFrame()
    if currentFrame >= startFrame and currentFrame < endFrame then 
      local longestString = 15 
      local hash = getDetermenisticHash()
      local timestepFramesPerString = displayStaticFrameIntervallLength/longestString
      local timeStep = (currentFrame - startFrame)/timestepFramesPerString

        local timeStamp = getRollingString(getDayTimeString(), timeStep, currentFrame)
        local citypart = getRollingString(getNeighbourhoodName("arabic",hash), timeStep, currentFrame)
        local cityname = getRollingString(getCityNameBy("arabic", hash), timeStep, currentFrame)
        local province = getRollingString(getProvinceNameBy("arabic",hash), timeStep, currentFrame)
        local country = getRollingString("Country: Placeholdistan", timeStep, currentFrame)
      

        local textCol = {0, 200/255, 255/255, 0.9}
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

