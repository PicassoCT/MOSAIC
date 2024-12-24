
if addon.InGetInfo then
	return {
		name    = "Music",
		desc    = "plays music",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------

Spring.SetSoundStreamVolume(1)

function getDeterministicRandom(hash, maximum)
    return hash % maximum
end

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

function setupSequence()
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
            ["6FName-11.ogg"] = 1170,["MName-17.ogg"] = 850,["MName-21.ogg"] = 900,["MName-20.ogg"] = 990,["MName-07.ogg"] = 930,
            ["MName-09.ogg"] = 840,["MName-23.ogg"] = 740,["MName-05.ogg"] = 750,["MName-15.ogg"] = 810,["MName-25.ogg"] = 1120,
            ["MName-19.ogg"] = 680,["MName-10.ogg"] = 720,["MName-01.ogg"] = 880,["MName-13.ogg"] = 880,["MName-04.ogg"] = 960,
            ["MName-16.ogg"] = 990,["MName-12.ogg"] = 770,["MName-24.ogg"] = 730,["MName-14.ogg"] = 930,["MName-11.ogg"] = 710,
            ["MName-18.ogg"] = 880,["MName-06.ogg"] = 950,["MName-02.ogg"] = 740,["MName-22.ogg"] = 720,["MName-08.ogg"] = 830,
            ["MName-03.ogg"] = 1040,["10MediaType-05.ogg"] = 1130,["10MediaType-04.ogg"] = 1130,["10MediaType-02.ogg"] = 1130,
            ["10MediaType-01.ogg"] = 1170,["10MediaType-03.ogg"] = 1020,["10MediaType-07.ogg"] = 1310,["10MediaType-06.ogg"] = 1180,
            ["4MSurNam-09.ogg"] = 1000,["4MSurNam-01.ogg"] = 990,["4MSurNam-13.ogg"] = 830,["4MSurNam-25.ogg"] = 1030,
            ["4MSurNam-21.ogg"] = 990,["4MSurNam-15.ogg"] = 970,["4MSurNam-06.ogg"] = 1020,["4MSurNam-11.ogg"] = 1040,
            ["4MSurNam-10.ogg"] = 1030,["4MSurNam-02.ogg"] = 1050,["4MSurNam-19.ogg"] = 890,["4MSurNam-04.ogg"] = 1150,
            ["4MSurNam-24.ogg"] = 740,["4MSurNam-23.ogg"] = 980,["4MSurNam-20.ogg"] = 1040,["4MSurNam-08.ogg"] = 890,
            ["4MSurNam-18.ogg"] = 1090,["4MSurNam-26.ogg"] = 1020,["4MSurNam-17.ogg"] = 850,["4MSurNam-03.ogg"] = 850,
            ["4MSurNam-05.ogg"] = 980,["4MSurNam-07.ogg"] = 1020,["4MSurNam-22.ogg"] = 1130,["4MSurNam-16.ogg"] = 990,
            ["4MSurNam-14.ogg"] = 890,["4MSurNam-12.ogg"] = 990,["2Superlative-18.ogg"] = 1040,["2Superlative-17.ogg"] = 980,
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
            ["1Superlative-21.ogg"] = 1530,["1Superlative-08.ogg"] = 1370
        }

    if not GG.DeterministicCounterAdvertisement then  GG.DeterministicCounterAdvertisement  = 0 end
    GG.DeterministicCounterAdvertisement  = (GG.DeterministicCounterAdvertisement % 22) +1 

    local thisAdvertisementIndex = GG.DeterministicCounterAdvertisement 
    local rootPath = "sounds/marketing/media"
    
    debugConcat = ""

    soundFileType_NameTime_Map= {}
    for i=1, #identifierList do
        local wordPosIdentifier = identifierList[i]
        elements = {}
        pathDirectory = rootPath .."/".. wordPosIdentifier
        local allFilesInPath = VFS.DirList(pathDirectory, "")
        for f=1, #allFilesInPath do
            elements[#elements +1] = {
                path = allFilesInPath[f], 
                time = ListOfMediaAdvertisementFileLength[allFilesInPath[f]]/30
                }
        end
        soundFileType_NameTime_Map[wordPosIdentifier] = elements
    end

 
end

function playForFrame()
   for i=1, #identifierList do
        local wordPosIdentifier = identifierList[i]
        if wordPosIdentifier == "5Binding" and 
            getDeterministicRandom(hash, math.abs(hash - GG.DeterministicCounterAdvertisement)) > math.ceil(hash * 0.25) then
            wordPosIdentifier = "8Starring"
            i = 8
        end 
        deterministicIndex = ((hash + thisAdvertisementIndex + i) % count(soundFileType_NameTime_Map[wordPosIdentifier])) + 1
        for k,element in pairs(soundFileType_NameTime_Map[wordPosIdentifier]) do
            deterministicIndex = deterministicIndex -1 
            if deterministicIndex == 0 then
                Spring.PlaySoundStream(element.path, 1.0)
                echo("Playing generated advertising part :" ..element.path)
                Sleep(element.time)       
               break 
            end
        end       
    end
end


local musicFiles = VFS.DirList("sounds/music/briefing/", "*.ogg")
local advertisementFiles = VFS.DirList("sounds/music/advertising/", "*.ogg")
function playMusicFile()
	if (#musicfiles > 0) then
		index=math.random(1,#musicfiles)
		Spring.PlaySoundStream(musicfiles[ index ], 1)
		Spring.SetSoundStreamVolume(1)
	end
end

function playAdvertisementFile()
	if math.random(0, 100)	 > 50 then
		if (#advertisementFiles > 0) then
			index=math.random(1,#advertisementFiles)
			Spring.PlaySoundStream(advertisementFiles[ index ], 1)
			Spring.SetSoundStreamVolume(1)
		end
	else
		buildRunDeterministicAdvertisement()
	end
end

loadProgressStep = 0
function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()
	if loadProgress > loadProgressStep then
		loadProgressStep = loadProgressStep + 0.10
		if math.random(0, 100) > 50 then
			playMusicFile()
		else
			playAdvertisementFile()
		end
	end
end


function addon.Shutdown()
	Spring.StopSoundStream()
	Spring.SetSoundStreamVolume(1)
end
