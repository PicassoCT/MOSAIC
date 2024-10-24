
backdropAxis = x_axis
spindropAxis = y_axis
function randomFLickerLetters(allLetters, posLetters)
    --echo("syncToFrontLetters with "..toString(allLetters))
    errorDrift = math.random(2,7)
    flickerIntervall = math.ceil(1000/25)
    if (hours > 17 or hours < 7) then
        for i=1,(3000/flickerIntervall) do
            if i % 2 == 0 then      
               showTReg(allLetters) 
            else
                hideTReg(allLetters) 
            end

            foreach(allLetters,
            function(id)
                for a=1,3 do
                    Move(id, a, posLetters[id][a] + math.random(-1*errorDrift,errorDrift), 100)
                end
            end)
            WaitForMoves(allLetters)
            Sleep(flickerIntervall)
        end
        hideTReg(allLetters)  
        foreach(allLetters,
            function(id)
                for a=1,3 do
                    Move(id, a, posLetters[id][a], 15)
                end                
                ShowReg(id)
            end)
    end        
end


function resetSpinDrop(allLetters)

         foreach(allLetters,
        function(id)   
                StopSpin(id, spindropAxis, math.rad(0), 0)      
                Turn(id, 1, math.rad(0), 0)    
                Turn(id, 2, math.rad(0), 0)    
                Turn(id, 3, math.rad(0), 0)    
        end)
end

function waitAllLetters(allLetters)
    foreach(allLetters,
            function(id)
                WaitForMove(id, spindropAxis)
            end)
end


function consoleLetters(allLetters, posLetters)
    if not posLetters.boolUpright then
       --echo("consoleLetters with "..toString(allLetters))
        foreach(allLetters,
        function(id)
          reset(id,0)
          HideReg(id)
        end)

        foreach(allLetters,
        function(id)
                for axis=1,3 do
                    Move(id, axis, posLetters[id][axis], 150)
                end            
            ShowReg(id)
        end)
        Sleep(100)
        WaitForMoves(allLetters)
        Sleep(10000)
    end
end

function matrixTextFx(allLetters, posLetters)
    if posLetters.boolUpright then
        foreach(allLetters,
            function(id)
                reset(id)
                ShowReg(id)
                Move(posLetters,spindropAxis, posLetters[id][spindropAxis], 100)
            end)

         foreach(allLetters,
            function(id)
                WaitForMove(posLetters)
            end)
         Sleep(1000)
        
    end
end

function dnaHelix(allLetters, posLetters)
circumference = 7 * sizeSpacingLetter 
    length = string.len(posLetters.myMessage)
    radius = circumference / (2 * math.pi)
    radiant = (math.pi)/(7 )
    hideTReg(allLetters)

    i = 0
    spiralIncrease = sizeDownLetter
    foreach(allLetters,
        function(pID)
            reset(pID, 0)
            if i < length/2 then
             
                radiantVal = radiant*i
                ShowReg(pID)
                local xr = radius * math.cos(radiantVal)
                local zr = radius * math.sin(radiantVal)

                Move(pID,x_axis, xr, math.abs(xr)/2.0)
                Move(pID,z_axis, zr, math.abs(zr)/2.0)
                Move(pID,spindropAxis, i * spiralIncrease, 0)
                Turn(pID,spindropAxis, math.pi + radiantVal, 0)
             
            else
                reset(pID, 0)
                radiantVal = radiant* ((i- (length/2))+ 3)
                ShowReg(pID)
                local xr = radius * math.cos(radiantVal)
                local zr = radius * math.sin(radiantVal)

                Move(pID,x_axis, xr, math.abs(xr)/2.0)
                Move(pID,z_axis, zr, math.abs(zr)/2.0)
                Move(pID,spindropAxis, (i- (length/2)) * spiralIncrease, 0)
                Turn(pID,spindropAxis, math.pi + radiantVal, 0)
            end
               i = i +1
                if posLetters.spacing[i + 1] == " " then
                    i = i + 1
                end
    end)
    Sleep(15000)
    hideTReg(allLetters) 
end



function spiralProject(allLetters, posLetters)
    circumference = 7 * sizeSpacingLetter 
    radius = circumference / (2 * math.pi)
    radiant = (math.pi)/(7 )
    hideTReg(allLetters)

    i = 0
    spiralIncrease = sizeDownLetter
    foreach(allLetters,
        function(pID)

        reset(pID, 0)
        radiantVal = radiant*i
        ShowReg(pID)
        local xr = radius * math.cos(radiantVal)
        local zr = radius * math.sin(radiantVal)

        Move(pID,x_axis, xr, math.abs(xr)/2.0)
        Move(pID,z_axis, zr, math.abs(zr)/2.0)
        Move(pID,spindropAxis, i * spiralIncrease, 0)
        Turn(pID,spindropAxis, math.pi + radiantVal, 0)
        i = i +1
        if posLetters.spacing[i + 1] == " " then
            i = i + 1
        end
        end)
    Sleep(15000)
    hideTReg(allLetters) 
end




function fireWorksProjectTextFx(allLetters, posLetters)
    lowPoint = -5000
    highPoint = 1000
    foreach(allLetters,
        function(id)
            Move(id, spindropAxis, lowPoint , 0)
        end)
    waitAllLetters(allLetters)
    showTReg(allLetters)
    foreach(allLetters,
    function(id)
        Move(id, spindropAxis, highPoint, 1000)
    end)
    waitAllLetters(allLetters)
    -- for downwards outwards circle
    for i= 100, 250, 50 do
        fallFactor = math.ceil(i/25)
        circleProject(allLetters, posLetters, i, true, true)
        foreach(allLetters,
            function(id)
                Move(id, spindropAxis, highPoint - fallFactor * sizeDownLetter , 150)
            end)
        Sleep(1000)
    end
    waitAllLetters(allLetters)
    hideTReg(allLetters)
end

function waitAllLetters(allLetters)
    foreach(allLetters,
            function(id)
                WaitForMove(id, spindropAxis)
            end)
end



--Produces a Holographic Sign made of several letters that shiver into different directions 
function achromaticShivering(allLetters, posLetters)
    if posLetters.IsThreeLetter then
        usedLetters = {}
        timeOut = math.random(10,25) * 1000
        while timeOut > 0 do
              letterIndex = 0
              foreach(message,
                function(letter)
                    usedLetters[letter] = letter
                    letterIndex= letterIndex +1
                        if letter and posLetters.IsThreeLetter[letter] then                                 
                            for ax=1,3 do
                                for n = 1, #posLetters.IsThreeLetter[letter] do
                                    letterSub = osLetters.IsThreeLetter[letter][n]
                                    if (not usedLetters[letterSub]) then
                                        WMove(letterSub, ax, posLetters[letter][ax], 0)
                                        ShowReg(letterSub)
                                        shiverIntervall = math.random(50, 250)* randSign()
                                        Move(letterSub, ax, posLetters[letter][ax]+ shiverIntervall, 250)
                                    end
                                end
                                WMove(letter, ax, posLetters[letter][ax], 0)
                                shiverIntervall = math.random(50, 250)* randSign()
                                Move(letter, ax, posLetters[letter][ax]+ shiverIntervall, 250)
                            end
                        end    
                    end
                )  
    
            Sleep(250)
            timeOut = timeOut - 250
        end
        hideResetAllLetters()
    end
end

function ringProject(allLetters, posLetters)
    circumference = count(allLetters) * sizeDownLetter + 10* sizeDownLetter

    radius = circumference / (2 * math.pi)
    radiant = (math.pi *2)/(count(allLetters)*2.0)
    hideTReg(allLetters)

    i=0
    foreach(allLetters,
        function(pID)
            reset(pID, 0)
        
        radiantVal = radiant*i
        ShowReg(pID)
        local xr = radius * math.cos(radiantVal)
        local yr = radius * math.sin(radiantVal)
        Spin(pID, spindropAxis, math.rad(42),0)
        Move(pID,x_axis, xr, math.abs(xr)/2.0)
        Move(pID,y_axis, yr, math.abs(yr)/2.0)
        tP(pID,0,  radiantVal, 0, 0)
        i = i +1
        if posLetters.spacing[i + 1] == " " then
            i = i + 1
        end
        end)
    
        Sleep(15000)    
    hideTReg(allLetters)
end


function circleProject(allLetters, posLetters, extRadius, boolDoNotRest, boolDoNotReset)
    circumference = string.len(posLetters.myMessage) * sizeSpacingLetter *2.0
    radius = circumference / (2 * math.pi)

    if extRadius  ~= nil then      
        radius = extRadius  
        circumference = extRadius * (2 * math.pi)
    end 
    radiant = (math.pi *2)/(count(allLetters)*2.0)
    hideTReg(allLetters)

    i=0
    foreach(allLetters,
        function(pID)
        if not boolDoNotReset then
            reset(pID, 0)
        end
        radiantVal = radiant*i
        ShowReg(pID)
        local xr = radius * math.cos(radiantVal)
        local zr = radius * math.sin(radiantVal)

        Move(pID,x_axis, xr, 10)
        Move(pID,z_axis, zr,    10)
        Turn(pID,y_axis, math.pi + radiantVal, 0)
        i = i +1
        if posLetters.spacing[i + 1] == " " then
            i = i + 1
        end
        end)    
    if not boolDoNotRest then
        Sleep(15000)
    end
    hideTReg(allLetters) 
end

function personalProject(allLetters, posLetters)
    local spGetUnitDefID = Spring.GetUnitDefID
    civiliansNearby = foreach(getAllNearUnit(unitID, 300),
                            function(id)
                                defID = spGetUnitDefID(id)
                                if civilianTypeTable[defID] then
                                    return id
                                end
                            end
                            )

    if #civiliansNearby > 0 then
        restoreMessageOriginalPosition(allLetters, posLetters)
        StopSpin(textSpinner, spindropAxis, 0)
        civilian = getSafeRandom(civiliansNearby, civiliansNearby[1])
      
        timeCounter= math.random(10, 20) * 1000

        while timeCounter > 0 and doesUnitExistAlive(civilianID) do
            tx,ty,tz= Spring.GetUnitPosition(civilian)
            ux,uy,uz = Spring.GetUnitPosition(unitID)
            direction = getAngleFromCoordinates(tx-ux, tz- uz)
            Turn(textSpinner, spindropAxis, direction, 0)
            Sleep(1000)
            timeCounter = timeCounter- 1000
        end
    end
end

function archProject(allLetters, posLetters)
    if posLetters.boolUpright then
        restoreMessageOriginalPosition(allLetters, posLetters)
        stringlength = #allLetters
        for i=1, stringlength do
            letterName = allLetters[i]
            val = -(stringlength-i) * (90/stringlength)
            Turn(letterName, 2, math.rad(val), 0)
            Move(letterName, 1, (stringlength-i) *sizeSpacingLetter, 0)
            ShowReg(letterName)
        end
        Sleep(35000)
    end
end



function cubeProject(allLetters, posLetters)
    cubeSize = math.ceil(math.sqrt(#allLetters))
    index = 1

        for x=1, cubeSize do
            for z=1, cubeSize do
                if allLetters[index] then
                    pID = allLetters[index]
                    Move(pID,x_axis, x*sizeSpacingLetter, 0)
                    Move(pID,z_axis, z* sizeSpacingLetter, 0)
                    ShowReg(pID)
                end
                index = index +1
            end            
        end
    

    foreach(allLetters,
        function(id)
            for i=1,3 do
                Move(id,i, posLetters[id][i], 100)
            end
            Sleep(150)
        end)
    Sleep(15000)
    hideTReg(allLetters) 
end

function SpiralUpwards(allLetters, posLetters)
   --echo("SpiralUpwards with "..toString(allLetters))
    hideTReg(allLetters)
    foreach(allLetters,
        function(id)
                Move(id, 3, posLetters[id][3] - 5000, 0)     
                Spin(id, spindropAxis, math.rad(42), 15)     
        end)
    Sleep(1000)

    foreach(allLetters,
        function(id)
            ShowReg(id)
                Move(id,3, posLetters[id][3], 2500)
            Sleep(250)
        end)
    WaitForMoves(allLetters)
    Sleep(5000) 
end

function SwarmLetters(allLetters, posLetters)
   --echo("SwarmLetters with "..toString(allLetters))
    foreach(allLetters,
        function(id)
                for i=1,3 do
                    Move(id, i, posLetters[id][i] + math.random(50,1000)*randSign(), 0)
                end                   
        end)
    Sleep(1000)

    foreach(allLetters,
        function(id)
            for i=1,3 do
                Move(id, i, posLetters[id][i], 350)            
            end
            
            ShowReg(id)
        end)
    WaitForMoves(allLetters)
    Sleep(2000)
end


function SpinLetters(allLetters, posLetters)
   --echo("SpinLetters with "..toString(allLetters))
   foreach(allLetters,
    function(id)
        for i=1,3 do
            Move(id, i, posLetters[id][i] + math.random(500,1000)*randSign(), 0)
        end    
        rval = math.random(-360,360)
        Spin(id, spindropAxis, math.rad(rval), 15)   
        ShowReg(id)
    end)

    foreach(allLetters,
        function(id)
            for i=1,3 do
                Move(id, i, posLetters[id][i], 100)
            end 
        end)
    Sleep(3000)
        foreach(allLetters,
        function(id)
            rval = math.random(-360,360)
            StopSpin(id, spindropAxis,0.1)       
            WTurn(id, spindropAxis, 0, 1.0) 
        end)
    Sleep(10000)
    hideTReg(allLetters)
end

function HideLetters(allLetters, posLetters)
   --echo("HideLetters with "..toString(allLetters))
    direction =  randSign()
    --Setup
     for j=1, #allLetters do
            HideReg(allLetters[j])
            WMove(allLetters[j],backdropAxis, 150, 300)
            ShowReg(allLetters[j])
            Move(allLetters[j],backdropAxis, posLetters[allLetters[j]][backdropAxis], 600)                
     end

    rest = math.random(4, 16)*500
    Sleep(rest)
end

function SinusLetter(allLetters, posLetters)
   --echo("SinusLetter with "..toString(allLetters))
    showTReg(allLetters)
    oldValue = {}
    for i=1, 10 do
        timeStep = (i /#allLetters)*math.pi* (#allLetters/20)
        for j=1, #allLetters do
            pieceID = allLetters[j]
            if not oldValue[pieceID] then oldValue[pieceID] = posLetters[pieceID][backdropAxis] end
            timefactor = 500 * math.sin(Spring.GetGameSeconds()/10.0 + timeStep*j)
            moveToValue=  posLetters[pieceID][backdropAxis] + timefactor
            speedValue = math.abs(oldValue[pieceID] - moveToValue)
            Move(pieceID, backdropAxis, moveToValue, speedValue)
            oldValue[pieceID]=moveToValue
        end
        for j=1, #allLetters do
            WaitForMoves(allLetters[j])
        end
        Sleep(50)
    end
    rest = math.random(4, 16)*500
    Sleep(rest)
    for j=1, #allLetters do
        Move(allLetters[j],backdropAxis, posLetters[allLetters[j]][backdropAxis], 500)
    end
    Sleep(10000)
    WaitForMoves(allLetters)
end

function CrossLetters(allLetters, posLetters)
   --echo("CrossLetters with "..toString(allLetters))
    direction =  randSign()
    -- Reset
    for i=1, #allLetters do
        id =allLetters[i]
        axis = math.random(1,3)
        Move(id, axis, posLetters[id][axis] + math.random(250,500)*direction, 0)
        HideReg(id)
    end
    for i=1, #allLetters do
        id =allLetters[i]
        for a=1,3 do
             Move(id, a, posLetters[id][a], 1600)
        end
        ShowReg(id)
        WaitForMoves(id)
    end

    rest = math.random(4, 16)*500
    Sleep(rest)
end



function syncToFrontLetters(allLetters)
    --echo("syncToFrontLetters with "..toString(allLetters))
    direction =  randSign()
    hideTReg(allLetters)
    --Setup
    for j=1, #allLetters do
        WMove(allLetters[j],backdropAxis, -500 + math.sin((j/#allLetters)*(math.pi/2))*50, 0)            
    end    
    showTReg(allLetters)
    for j=1, #allLetters do
        WMove(allLetters[j],backdropAxis, 150 + math.cos((j/#allLetters)*(math.pi/2))*50, 250)            
    end
    for j=1, #allLetters do
        WMove(allLetters[j],backdropAxis,0, 150)            
    end

    WaitForMoves(allLetters)
    rest = math.random(4, 16)*500
    Sleep(rest)
end
--matrix like textfx


function getAllTextFx()
return {
        ["SinusLetter"]   = SinusLetter, 
        ["CrossLetters"]  =  CrossLetters, 
        ["HideLetters"]   = HideLetters,
        ["SpinLetters"]   = SpinLetters, 
        ["SwarmLetters"]  =  SwarmLetters, 
        ["SpiralUpwards"] =   SpiralUpwards, 
        ["randomFLickerLetters"] =   randomFLickerLetters, 
        ["syncToFrontLetters"]=    syncToFrontLetters, 
        ["consoleLetters"] =   consoleLetters, 
        ["dnaHelix"]   = dnaHelix, 
        ["circleProject"]  =  circleProject,
        ["ringProject"]  =  ringProject,
        ["cubeProject"]  =  cubeProject,
        ["spiralProject"]  =  spiralProject,
        ["matrixTextFx"]  =  matrixTextFx,
        ["fireWorksProjectTextFx"] = fireWorksProjectTextFx,
        ["waterFallProject"] = waterFallProject,
        ["personalProject"] = personalProject,
        ["archProject"] = archProject,
        ["achromaticShivering"] = achromaticShivering

        }
end