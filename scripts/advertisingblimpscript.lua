include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
GameConfig = getGameConfig()
BrothelSpin= piece("BrothelSpin")
CasinoSpin= piece("CasinoSpin")
Joy = piece("Joy")
JoyRide = piece("JoyRide")

advertisingJingles = 
{
"lonely? Try NEXT DOOR™ from OmegaSoft. Let AI recreate your friends and family, in the room NEXT DOOR",
"stressed? Let the Ettu™ Robobutler give you a massage. Relax, your worries are behind you",
"boring? AIvid enriches your personality void with unique content. Be famous - with AIvid",
"a new live awaits you Offworld. Leave earth for the edison protectorate on mars",
"does fallout grow on you? Use Thanatol to neutralize environment caused cancers. Stay alive, with Thanatol",
"feeling down? Try uForia, the drug recommended by the UN-DEA. Smile, its a good day",
"generational debt to corporate got you down? Participate in the planetary lottery. Win freedom for your family",
"nature is gone, but in the metaverse it lives on. Join today, for a VR-Getaway",
"tune out the burning horizon with Armageddon Augmented Reality. Unseeing is believing",
"shareholders of AirBoing, today the Mono DAO offers you 300 ether per share. Check your portfolio and stay in the green",
"its a tough world, but your kids will be tougher. Prepare them with RNA-Vector treatments. Harder, smarter, make them stronger",
"OceansideFoods™ famous Algae ramen are now back in several brand new flavors. Try chili bubblegum today! <fast>No microplatics, unlike our competitors</fast>",
"Pollution is everywhere! But not in your home. Thanks to PolAirLock. PolAirLock, trust is good, but a over-pressure home is better",
"everyone loves gamble Donkey. The massive multiplayer, snowball game, were the last one standing, becomes a billionaire. Its all in on red",
"block traumatizing work-memories with Memblock, the only working selective memory blocker. Work hard, forget for today, Play hard anyway. <fast> Recommended by the PanASEA-Directorate</fast>",
"buy Full-Organ-Life insurance. Harvested from healthy, young donors. Your organs may give up, but FOLI never does",
"when love grows cold, load your lovers personality from the MetaCrypt, directly into the heating blanket. Keep them at your side.",
"afraid of death? Allow MetaCrypt to reconstruct you for a afterlife. Join the DigitalSouls program, free of charge",
"have your loved ones AddViral Braindamage from NeuralCon Join the Class Action lawsuit. You cant get them back, but you can get back at them.Get compensated now ",
"dislike adds, install the NeuralCon AddBlocker. Become the Buddha, let them starve for attention",
"want to be a genius, leave your signature on the planet? Join the Houston hivemind. Artists, Scientists, Visionarys united. From our hands flows cornucopia",
"shy, anxious, in a dog eats dog world? Buy the Negotiator AI- become the social animal. A ToughBreak™ Softwarehive product",
"[Comment: Failing AI Generated awkward Jingle, should still sound confident]:",
"emulate more successful society members, who prefer beautiful, sexy, drink named soyLala. Get limited supply or miss out"
}



local civilianWalkingTypeTable = getCultureUnitModelTypes(  GameConfig.instance.culture, 
                                                            "civilian", UnitDefs)
function script.HitByWeapon(x, z, weaponDefID, damage) end

function showOne(T, bNotDelayd)
    if not T then return end
    dice = math.random(1, count(T))
    c = 0
    for k, v in pairs(T) do
        if k and v then c = c + 1 end
        if c == dice then            
            Show(v)            
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

function script.Create()
    --echo(UnitDefs[myDefID].name.."has placeholder script called")
    Spring.SetUnitAlwaysVisible(unitID, true)
    Spring.SetUnitCOBValue(unitID, COB.ACTIVATION, 1)
   -- Spring.SetUnitNoSelect(unitID, true)
     TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
     hideT(TablesOfPiecesGroups["Blimp"])
     showOne(TablesOfPiecesGroups["Blimp"])
     StartThread(Advertising)
     StartThread(LightsBlink)
     StartThread(flyTowardsPerson)
     StartThread(HoloGrams)
     StartThread(advertisingLoop)
     Hide(BrothelSpin)
     Hide(CasinoSpin)
end

function advertisingLoop()
    Sleep(20000)
    while true do
        soundFile = "sounds/advertising/advertisement"..math.random(1,23)..".ogg"
        StartThread(PlaySoundByUnitDefID, myDefID, soundFile, 1.0, 20000, 2)
        minimum, maximum = 5*60*1000, 10*60*1000
        restTime = math.random(minimum,maximum)
        Sleep(restTime)
    end

end

function HoloGrams()
 
    
    local brothelFlickerGroup = TablesOfPiecesGroups["BrothelFlicker"]
    local CasinoflickerGroup = TablesOfPiecesGroups["CasinoFlicker"]
    local JoyFlickerGroup = TablesOfPiecesGroups["JoySpin"]
    JoyFlickerGroup[#JoyFlickerGroup+1] = Joy
    JoyFlickerGroup[#JoyFlickerGroup+1] = JoyRide
    hideT(brothelFlickerGroup)
    hideT(CasinoflickerGroup)
    hideT(JoyFlickerGroup)

    Sleep(15000)
    --sexxxy time
    px,py,pz = Spring.GetUnitPosition(unitID)
    if maRa() then
        StartThread(flickerScript, brothelFlickerGroup, 5, 250, 4, true)
    else
        StartThread(JoyFlickerGroup, brothelFlickerGroup, 5, 250, 4, true)
        StartThread(JoyAnimation)
    end
    val = math.random(5, 12)*randSign()
    Spin(BrothelSpin, z_axis, math.rad(val), 0.1)
    StartThread(flickerScript, CasinoflickerGroup, 5, 250, 4, true)
    val = math.random(5, 12)*randSign()
    Spin(CasinoSpin, z_axis,  math.rad(val), 0.1)
end

function JoyAnimation()
    val = math.random(5, 12)*randSign()
    Spin(TablesOfPiecesGroups["JoySpin"], z_axis, math.rad(val), 0.1)
    while true do
        Show(TablesOfPiecesGroups["JoySpin"][1])
        Sleep(2500)
        for i=2, #TablesOfPiecesGroups["JoySpin"] do
            Show(TablesOfPiecesGroups["JoySpin"][i])
            offsetValue = 50
            offset = i* offsetValue
            turnVal= (-1) * 15
            animStepTime = 3
            Move(TablesOfPiecesGroups["JoySpin"][1],y_axis, -offset, speed(offset, animStepTime))
            Move(TablesOfPiecesGroups["JoySpin"][i],y_axis, offsetValue, speed(offsetValue, animStepTime))
            Turn(TablesOfPiecesGroups["JoySpin"][i],y_axis, math.rad(turnVal), speed(turnVal, animStepTime))

            WaitForTurns(TablesOfPiecesGroups["JoySpin"][1])
            WaitForTurns(TablesOfPiecesGroups["JoySpin"][i])
            WaitForMoves(TablesOfPiecesGroups["JoySpin"][1])
        end
        Sleep(1000)
        hideT(TablesOfPiecesGroups["JoySpin"])
        resetT(TablesOfPiecesGroups["JoySpin"])
    end
end


function flickerScript(flickerGroup,  errorDrift, timeoutMs, maxInterval, boolDayLightSavings)
    assert(flickerGroup)
    local fGroup = flickerGroup

    flickerIntervall = math.ceil(1000/25)
    
    while true do
        hideT(fGroup)
        --assertRangeConsistency(fGroup, "flickerGroup")
        Sleep(500)
        hours, minutes, seconds, percent = getDayTime()
        if (hours > 17 or hours < 7) then
            theOneToShowT= {}
            for x=1,math.random(1,3) do
                theOneToShowT[#theOneToShowT+1] = fGroup[math.random(1,#fGroup)]
            end

            for i=1,(3000/flickerIntervall) do
                if i % 2 == 0 then  showT(theOneToShowT) else hideT(theOneToShowT) end
                if maRa()==maRa() then showT(theOneToShowT) end 
                for ax=1,3 do
                    moveT(fGroup, ax, math.random(-1*errorDrift,errorDrift),100)
                end
                Sleep(flickerIntervall)
            end
            hideT(theOneToShowT)
        end
        breakTime = math.random(1,maxInterval)*timeoutMs
        Sleep(breakTime)
    end
end

function flyTowardsPerson()
    Spring.AddUnitImpulse(unitID, 1, 10, 0)
    while true do  
            T= foreach(Spring.GetTeamUnits(gaiaTeamID),
                function(id)
                    defID = Spring.GetUnitDefID(id)
                    if civilianWalkingTypeTable[defID] then
                        return id
                    end
                end
             )
            if #T > 1 then

                id = T[math.random(1,#T)]
                px,py,pz = Spring.GetUnitPosition(id)
                Spring.SetUnitMoveGoal(unitID, px,py+100,pz)
                Command(unitID, "go", {x = px, y = py, z = pz}, {})
                Command(unitID, "guard", {id}, {"shift"})
                Command(unitID, "go", {
                                x = px + math.random(-20, 20),
                                y = py,
                                z = pz + math.random(-20, 20)
                            }, {})

            end
        Sleep(10000)
    end
end

function LightsBlink()
    while true do
        hideT(TablesOfPiecesGroups["LightOn"])
        showT(TablesOfPiecesGroups["LightOff"])
        Sleep(3000)
        hideT(TablesOfPiecesGroups["LightOff"])
        showT(TablesOfPiecesGroups["LightOn"])
        Sleep(6000)
    end
end

function Advertising()
    seperator = 19
    while true do
        hideT(TablesOfPiecesGroups["Screen"])
        dice = math.random(1,seperator)
        Show(TablesOfPiecesGroups["Screen"][dice])
        if TablesOfPiecesGroups["Screen"][seperator + dice] then
            Show(TablesOfPiecesGroups["Screen"][seperator + dice])
        end
        hideT(TablesOfPiecesGroups["Deco"])
        showOneOrNone(TablesOfPiecesGroups["Deco"])
        showOneOrNone(TablesOfPiecesGroups["Deco"])
        Sleep(10000)
    end
end

function script.Killed(recentDamage, _)
    Spring.SetUnitCrashing ( unitID, true) 
    return 1
end

function script.StartMoving() 
    val = math.random(5, 10)
    StartThread(turnT,TablesOfPiecesGroups["Control"],x_axis, math.rad(val), 3)
end

function script.StopMoving()
    StartThread(resetT,TablesOfPiecesGroups["Control"], 0.5)
 end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

