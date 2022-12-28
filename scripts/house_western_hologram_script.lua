include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

myDefID = Spring.GetUnitDefID(unitID)
boolIsCasino= UnitDefNames["house_western_hologram_casino"].id == myDefID
boolIsBrothel= UnitDefNames["house_western_hologram_brothel"].id == myDefID
boolIsBuisness= UnitDefNames["house_western_hologram_buisness"].id == myDefID 

local _x_axis = 1
local _y_axis = 2
local _z_axis = 3


GameConfig = getGameConfig()

function timeOfDay()
    WholeDay = GameConfig.daylength
    timeFrame = Spring.GetGameFrame() + (WholeDay * 0.25)
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    StartThread(HoloGrams)
end

function HoloGrams()
    Sleep(15000)
    
    local flickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    hideT(flickerGroup)
    hideT(CasinoflickerGroup)
    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
    if getDeterministicCityOfSin(getCultureName(), Game)== true and isNearCityCenter(px,pz, GameConfig) == true or mapOverideSinCity() then
        if boolIsBrothel then
            StartThread(flickerScript, flickerGroup, function() return maRa()==maRa(); end, 5, 250, 4, true)
        end
  
        if  boolIsCasino then 
            StartThread(flickerScript, flickerGroup, function() return maRa()==maRa(); end, 5, 250, 4, true)
        end
    end

    if boolIsBuisness then 
        logo = showOne(TablesOfPiecesGroups["Office_Roof_Deco7Spin"])
        Spin(logo,_z_axis, math.rad(5),0)
        if maRa()== true then
            StartThread(flickerScript, {logo}, function() return math.random(1,100) > 25; end, 0.5, 30, 2, false)
        else
            Show(logo)
        end
    end
end

function flickerScript(flickerGroup,  NoErrorFunction, errorDrift, timeoutMs, maxInterval, boolDayLightSavings)
    assert(flickerGroup)
    local fGroup = flickerGroup

    flickerIntervall = math.ceil(1000/25)

    while true do
        hideT(fGroup)
        assertRangeConsistency(fGroup, "flickerGroup")
        Sleep(500)
        hours, minutes, seconds, percent = getDayTime()
        if not boolDayLightSavings or ( boolDayLightSavings == true and (hours > 17 or hours < 7)) then
            if boolHouseHidden == false then
                theOneToShowT= {}
                for x=1,math.random(1,3) do
                    theOneToShowT[#theOneToShowT+1] = fGroup[math.random(1,#fGroup)]
                end

                for i=1,(3000/flickerIntervall) do
                    if i % 2 == 0 then         showT(theOneToShowT) else hideT(theOneToShowT) end
                    if NoErrorFunction() == true then showT(theOneToShowT) end
                    for ax=1,3 do
                        moveT(fGroup, ax, math.random(-1*errorDrift,errorDrift),100)
                    end
                    Sleep(flickerIntervall)
                end
                hideT(theOneToShowT)
            end
        end
        breakTime = math.random(1,maxInterval)*timeoutMs
        Sleep(breakTime)
    end
end

function showOne(T, bNotDelayd)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then
            if bNotDelayd and bNotDelayd == true then
                Show(v)
            else
                ToShowTable[#ToShowTable + 1] = v
            end
            return v
        end
    end
end

function showOneOrNone(T)
    if not T then return end
    if math.random(1, 100) > 50 then
        return showOne(T, true)
    else
        return
    end
end

function showOneOrAll(T)
    if not T then return end
    
    if chancesAre(10) > 0.5 then
        return showOne(T)
    else
        for num, val in pairs(T) do 
            ToShowTable[#ToShowTable + 1] = val end
        return
    end
end

