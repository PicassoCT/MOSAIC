-- Select complete phrases when possible, retaining the full source pool as fallback.
function selectHologramMessage(messages, groups)
    local eligible = {}
    for _, message in ipairs(messages) do
        local used, fits = {}, true
        for glyph in message:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            local ch = glyph:upper()
            if not ch:match("%s") then
                used[ch] = (used[ch] or 0) + 1
                if not groups[ch] or not groups[ch][used[ch]] then fits = false end
            end
        end
        if fits then eligible[#eligible + 1] = message end
    end
    local pool = #eligible > 0 and eligible or messages
    if #pool == 0 then return "" end
    return pool[math.random(1, #pool)]
end

-- Logical slots include unavailable glyphs and whitespace; physical pieces never repeat.
function allocateHologramSlots(message, groups)
    local slots, used, leases = {}, {}, {}
    for glyph in message:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local ch = glyph:upper()
        used[ch] = (used[ch] or 0) + 1
        local pieces = groups[ch]
        local id = pieces and pieces[used[ch]]
        slots[#slots + 1] = id or " "
        if pieces and #pieces > 0 then
            local donor = id or pieces[((used[ch] - 1) % #pieces) + 1]
            leases[donor] = leases[donor] or {}
            leases[donor][#leases[donor] + 1] = #slots
        end
    end
    return slots, leases
end

-- Only the text owner calls this during readable holds. No competing worker can
-- overwrite another effect's moves; one slot is lit for 500 ms before teleporting.
function holdHologramText(allLetters, posLetters, duration)
    local phase = 0
    while duration > 0 do
        for _, id in ipairs(allLetters) do
            local destinations = posLetters.leases and posLetters.leases[id]
            if destinations and #destinations > 1 then
                local slot = destinations[(phase % #destinations) + 1]
                HideReg(id)
                for axis = 1, 3 do Move(id, axis, posLetters.slotPositions[slot][axis], 0) end
                ShowReg(id)
            end
        end
        local step = math.min(500, duration)
        Sleep(step)
        duration, phase = duration - step, phase + 1
    end
    for _, id in ipairs(allLetters) do
        local destinations = posLetters.leases and posLetters.leases[id]
        if destinations and #destinations > 1 then
            HideReg(id)
            for axis = 1, 3 do Move(id, axis, posLetters[id][axis], 0) end
            ShowReg(id)
        end
    end
end

local function textSlot(posLetters, id, fallback)
    return posLetters.slotByPiece and posLetters.slotByPiece[id] and posLetters.slotByPiece[id] - 1 or fallback
end

-- Unit-script Show/Hide has no opacity control. Use engine-interpolated motion
-- for text arrivals instead of a pop; no polling thread or per-frame Lua work.
function transitionHologramText(allLetters, posLetters, appearing, duration)
    if #allLetters == 0 then return end
    duration = math.max(1, duration or 400)
    local distance = sizeSpacingLetter * 0.35
    local speed = distance * 1000 / duration
    for _, id in ipairs(allLetters) do
        local target = posLetters[id][backdropAxis]
        if appearing then
            HideReg(id)
            Move(id, backdropAxis, target + distance, 0)
            ShowReg(id)
            Move(id, backdropAxis, target, speed)
        else
            Move(id, backdropAxis, target + distance, speed)
        end
    end
    for _, id in ipairs(allLetters) do WaitForMove(id, backdropAxis) end
    if not appearing then hideTReg(allLetters) end
end

local function waitTextMoves(letters)
    for _, id in ipairs(letters) do
        for axis = 1, 3 do WaitForMove(id, axis) end
    end
end


backdropAxis = x_axis
spindropAxis = y_axis
function randomFLickerLetters(allLetters, posLetters)
    if #allLetters == 0 then return end
    local errorDrift, flickerIntervall
    --echo("syncToFrontLetters with "..toString(allLetters))
    errorDrift = math.random(2,7)
    flickerIntervall = math.ceil(1000/25)
    local hour = getDayTime()
    if (hour > 17 or hour < 7) then
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
            waitTextMoves(allLetters)
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
    if #allLetters == 0 then return end

         foreach(allLetters,
        function(id)   
                StopSpin(id, spindropAxis, 0)
                Turn(id, 1, math.rad(0), 0)    
                Turn(id, 2, math.rad(0), 0)    
                Turn(id, 3, math.rad(0), 0)    
        end)
end

function waitAllLetters(allLetters)
    if #allLetters == 0 then return end
    foreach(allLetters,
            function(id)
                WaitForMove(id, spindropAxis)
            end)
end


function consoleLetters(allLetters, posLetters)
    if #allLetters == 0 then return end
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
        waitTextMoves(allLetters)
        Sleep(10000)
    end
end

function matrixTextFx(allLetters, posLetters)
    if #allLetters == 0 then return end
    if posLetters.boolUpright then
        foreach(allLetters,
            function(id)
                reset(id)
                HideReg(id)
                for axis = 1, 3 do Move(id, axis, posLetters[id][axis], 0) end
                Move(id, spindropAxis, posLetters[id][spindropAxis] + sizeDownLetter * 4, 0)
                ShowReg(id)
                Move(id,spindropAxis, posLetters[id][spindropAxis], 1400)
            end)

         foreach(allLetters,
            function(id)
                WaitForMove(id, spindropAxis)
            end)
         Sleep(1000)
        
    end
end

function dnaHelix(allLetters, posLetters)
    if #allLetters == 0 then return end
    local circumference, i, length, radiant, radiantVal, radius, spiralIncrease
circumference = 7 * sizeSpacingLetter 
    length = #posLetters.spacing
    radius = circumference / (2 * math.pi)
    radiant = (math.pi)/(7 )
    hideTReg(allLetters)

    i = 0
    spiralIncrease = sizeDownLetter
    foreach(allLetters,
        function(pID)
            reset(pID, 0)
            i = textSlot(posLetters, pID, i)
            if i < length/2 then
             
                radiantVal = radiant*textSlot(posLetters, pID, i)
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
    if #allLetters == 0 then return end
    local circumference, i, radiant, radiantVal, radius, spiralIncrease
    circumference = 7 * sizeSpacingLetter 
    radius = circumference / (2 * math.pi)
    radiant = (math.pi)/(7 )
    hideTReg(allLetters)

    i = 0
    spiralIncrease = sizeDownLetter
    foreach(allLetters,
        function(pID)

        reset(pID, 0)
        i = textSlot(posLetters, pID, i)
        radiantVal = radiant*textSlot(posLetters, pID, i)
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
    if #allLetters == 0 then return end
    local fallFactor, highPoint, lowPoint
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
        circleProject(allLetters, posLetters, i/100, true, true)
        foreach(allLetters,
            function(id)
                Move(id, spindropAxis, highPoint - fallFactor * sizeDownLetter , 150)
            end)
        Sleep(1000)
    end
    waitAllLetters(allLetters)
    hideTReg(allLetters)
end

function messageUniqueLettered( posLetters)
    local bucket, letter
    bucket= {}
    for glyph in posLetters.myMessage:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        letter = glyph:upper()
        if letter:match("%s") then
            -- Whitespace does not consume a physical glyph.
        elseif not bucket[letter] then
            bucket[letter]= true 
        else
            return false
        end
    end
    return true
end

--Produces a Holographic Sign made of several letters that shiver into different directions 
function achromaticShivering(allLetters, posLetters, TableOfPiecesGroups)
    if #allLetters == 0 then return end
    local dim, letter, letterSub, shiverIntervallX, shiverIntervallY, shiverIntervallZ, timeOut
    if messageUniqueLettered(posLetters) == false then return end
    timeOut = math.random(10,25) * 1000
    dim = math.random(5, 50)
    while timeOut > 0 do

        shiverIntervallY = (math.random(0, dim)/100)*sizeSpacingLetter* randSign()
        shiverIntervallX = 0
        shiverIntervallZ = (math.random(0, dim)/100)*sizeSpacingLetter* randSign()
        local i = 0
        for glyph in posLetters.myMessage:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            i = i + 1
            letter = glyph:upper()
            if posLetters.TriLetters[letter] then    
            for n = 1, #posLetters.TriLetters[letter] do
                letterSub = posLetters.TriLetters[letter][n]        
                ShowReg(letterSub)         
                WMove(letterSub, 2, (i* sizeSpacingLetter)+ shiverIntervallY, 0)                       
                if n> 1 then
                    WMove(letterSub, 1, shiverIntervallX, 0)                              
                    WMove(letterSub, 3, shiverIntervallZ, 0)   
                end
            end                                                       
            end                                                       
        end                            
    Sleep(250)
    timeOut = timeOut - 250
    end
    Sleep(math.max(0, timeOut))
    hideResetAllLetters()    
end

function ringProject(allLetters, posLetters)
    if #allLetters == 0 then return end
    local circumference, i, radiant, radiantVal, radius
    circumference = count(allLetters) * sizeDownLetter + 10* sizeDownLetter

    radius = circumference / (2 * math.pi)
    radiant = (math.pi *2)/(math.max(1, #posLetters.spacing)*2.0)
    hideTReg(allLetters)

    i=0
    foreach(allLetters,
        function(pID)
            reset(pID, 0)
        
        radiantVal = radiant*textSlot(posLetters, pID, i)
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


function circleProject(allLetters, posLetters, extRadiusFactor, boolDoNotRest, boolDoNotReset)
    if #allLetters == 0 then return end
    local circumference, i, radiant, radiantVal, radius
    circumference = #posLetters.spacing * sizeSpacingLetter *2.0
    radius = circumference / (2 * math.pi)

    if type(extRadiusFactor) == "number" then
        radius = radius * extRadiusFactor
        circumference = radius * (2 * math.pi)
    end 
    radiant = (math.pi *2)/(math.max(1, #posLetters.spacing)*2.0)
    hideTReg(allLetters)

    i=0
    foreach(allLetters,
        function(pID)
        if not boolDoNotReset then
            reset(pID, 0)
        end
        radiantVal = radiant*textSlot(posLetters, pID, i)
        ShowReg(pID)
        local xr = radius * math.cos(radiantVal)
        local zr = radius * math.sin(radiantVal)

        Move(pID,x_axis, xr, 100)
        Move(pID,z_axis, zr, 100)
        Turn(pID,y_axis, math.pi + radiantVal, 0)
        i = i +1
        if posLetters.spacing[i + 1] == " " then
            i = i + 1
        end
        end)

        foreach(allLetters,  
        function(id)
            WaitForMoves(id)
        end)

        if not boolDoNotRest then
            Sleep(15000)
            hideTReg(allLetters)
        end
end

function   personalProject(allLetters, posLetters)
    if #allLetters == 0 then return end
    local civilian, civilianTypeTable, civiliansNearby, defID, direction, timeCounter, tx, ty, tz, ux, uy, uz
    local spGetUnitDefID = Spring.GetUnitDefID
    civilianTypeTable = getCivilianTypeTable(UnitDefs)
    civiliansNearby = foreach(getAllNearUnit(posLetters.unitID, 900),
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
        ux,uy,uz = Spring.GetUnitPosition(posLetters.unitID)
        while timeCounter > 0 and doesUnitExistAlive(civilian) do
            tx,ty,tz= Spring.GetUnitPosition(civilian)           
            direction = getAngleFromCoordinates(tx-ux, tz- uz)
            Turn(textSpinner, spindropAxis, direction, 0)
            Sleep(1000)
            timeCounter = timeCounter- 1000
        end
    end
end

function archProject(allLetters, posLetters)
    if #allLetters == 0 then return end
    local letterName, stringlength, val
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

function getSpiral()
    local helix_points = {}
    local num_turns = 5        -- Number of loops
    local step = 0.1           -- Angular step size
    local radius = 10          -- Radius of the helix
    local height_per_turn = 2  -- Height gain per full loop

    for theta = 0, num_turns * math.pi * 2, step do
        local x = radius * math.cos(theta)
        local y = radius * math.sin(theta)
        local z = height_per_turn * theta / (2 * math.pi)  -- Height proportional to angle
        table.insert(helix_points, {x = x, y = y, z = z})
    end
    return helix_points
end

function cubeProject(allLetters, posLetters)
    if #allLetters == 0 then return end
    local cubeSize, index, localX, pID, z
    cubeSize  = #allLetters*0.5
    index = 1
       
        for x=1, 2*cubeSize do
            z=1
            localX=x
            if allLetters[index] then
                pID = allLetters[index]
                  if x > cubeSize then
                    z = x - cubeSize
                    localX = cubeSize
                    Turn(pID, y_axis, math.rad(90), 0)
                  end
                Move(pID,x_axis, localX*sizeSpacingLetter, 0)
                Move(pID,z_axis, z* sizeSpacingLetter, 0)
                ShowReg(pID)
            end
            index = index +1
        end
    Sleep(35000)
    hideTReg(allLetters) 
end

function SpiralUpwards(allLetters, posLetters)
    if #allLetters == 0 then return end
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
    waitTextMoves(allLetters)
    Sleep(5000) 
end

function SwarmLetters(allLetters, posLetters)
    if #allLetters == 0 then return end
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
    Sleep(35000)
end


function SpinLetters(allLetters, posLetters)
    if #allLetters == 0 then return end
    local rval
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
    if #allLetters == 0 then return end
    local direction, rest
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
    if #allLetters == 0 then return end
    local moveToValue, oldValue, pieceID, rest, speedValue, timeStep, timefactor
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
    waitTextMoves(allLetters)
end

function CrossLetters(allLetters, posLetters)
    if #allLetters == 0 then return end
    local axis, direction, id, rest
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
    if #allLetters == 0 then return end
    local direction, rest
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

    waitTextMoves(allLetters)
    rest = math.random(4, 16)*500
    Sleep(rest)
end
--matrix like textfx


local function textDot(a, b) return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] end
local function textCross(a, b)
    return {a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1]}
end

-- Build a world -> script Move conversion once per selected effect. The parent
-- matrix includes imported DAE axes/scale; the glyph's own rotation is excluded.
function hologramWorldMover(owner, id, base, pieceMap)
    local info = Spring.GetUnitPieceInfo(owner, id)
    if not info then return end
    local parent = type(info.parent) == "number" and info.parent or pieceMap[info.parent]
    local m = parent and {Spring.GetUnitPieceMatrix(owner, parent)} or
        {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
    local own = {Spring.GetUnitPieceMatrix(owner, id)}
    local front, up, right = Spring.GetUnitVectors(owner)
    local ux, uy, uz = Spring.GetUnitPosition(owner)
    if not m[16] or not own[16] or not front or not ux then return end
    local function world(x, y, z)
        return {-right[1]*x+up[1]*y+front[1]*z,
                -right[2]*x+up[2]*y+front[2]*z,
                -right[3]*x+up[3]*y+front[3]*z}
    end
    local basis = {world(m[1],m[2],m[3]), world(m[5],m[6],m[7]), world(m[9],m[10],m[11])}
    local cof = {textCross(basis[2],basis[3]), textCross(basis[3],basis[1]), textCross(basis[1],basis[2])}
    local det = textDot(basis[1], cof[1])
    if math.abs(det) < 1e-9 then return end
    local origin = world(own[13],own[14],own[15])
    origin[1], origin[2], origin[3] = origin[1]+ux, origin[2]+uy, origin[3]+uz
    local previous = {base[1],base[2],base[3]}
    return function(x,y,z,seconds)
        local delta = {x-origin[1],y-origin[2],z-origin[3]}
        for axis = 1, 3 do
            local target = base[axis] + textDot(delta,cof[axis])/det
            Move(id, axis, target, math.abs(target-previous[axis])/seconds)
            previous[axis] = target
        end
    end
end

function civilianCongaText(allLetters, posLetters)
    if #allLetters == 0 then return end
    local owner = posLetters.unitID
    local types = getCivilianTypeTable(UnitDefs)
    local civilian
    for _, candidate in ipairs(getAllNearUnit(owner, 650) or {}) do
        if types[Spring.GetUnitDefID(candidate)] and doesUnitExistAlive(candidate) then
            civilian = candidate
            break
        end
    end
    if not civilian then return end
    StopSpin(textSpinner, spindropAxis, 0)
    for axis = 1, 3 do Turn(textSpinner, axis, 0, 0) end
    restoreMessageOriginalPosition(allLetters, posLetters)
    resetSpinDrop(allLetters)
    local movers, pieceMap = {}, Spring.GetUnitPieceMap(owner)
    for _, id in ipairs(allLetters) do
        movers[id] = hologramWorldMover(owner, id, posLetters[id], pieceMap)
        if not movers[id] then
            restoreMessageOriginalPosition(allLetters, posLetters)
            if posLetters.spinnerSpeed then Spin(textSpinner,spindropAxis,posLetters.spinnerSpeed,0) end
            return
        end
    end
    local ox, _, oz = Spring.GetUnitPosition(owner)
    local previousX, previousZ
    local spacing = 8
    local bounds = Spring.GetUnitPieceInfo(owner, allLetters[1])
    local matrix = {Spring.GetUnitPieceMatrix(owner, allLetters[1])}
    if bounds and bounds.min and bounds.max and matrix[16] then
        for axis = 1, 3 do
            local k = (axis-1)*4+1
            local scale = math.sqrt(matrix[k]^2+matrix[k+1]^2+matrix[k+2]^2)
            spacing = math.max(spacing, (bounds.max[axis]-bounds.min[axis])*scale*1.15)
        end
    end
    local trail = {}
    -- 5 Hz for at most 16 seconds; engine interpolation fills the gaps. Keep a
    -- bounded path history so the conga follows corners instead of cutting them.
    for tick = 0, 79 do
        if not doesUnitExistAlive(civilian) then break end
        local x, _, z = Spring.GetUnitPosition(civilian)
        if not x or (x-ox)^2+(z-oz)^2 > 750^2 then break end
        local front = Spring.GetUnitVectors(civilian)
        local dx, dz = x-(previousX or x), z-(previousZ or z)
        if dx*dx+dz*dz < 0.01 then dx,dz = front[1],front[3] end
        local length = math.sqrt(dx*dx+dz*dz)
        dx,dz = dx/math.max(0.001,length),dz/math.max(0.001,length)
        if #trail == 0 then
            for i=159,1,-1 do trail[#trail+1] = {x-dx*i*spacing,z-dz*i*spacing} end
        end
        trail[#trail+1] = {x,z}
        if #trail > 160 then table.remove(trail,1) end
        previousX,previousZ = x,z
        for index,id in ipairs(allLetters) do
            local slots = posLetters.leases and posLetters.leases[id]
            local slot = slots and slots[(math.floor(tick*200/500) % #slots)+1] or index
            local distance, targetX, targetZ = spacing*1.5+(slot-1)*spacing, x,z
            for j=#trail,2,-1 do
                local a,b=trail[j],trail[j-1]
                local sx,sz=a[1]-b[1],a[2]-b[2]
                local span=math.sqrt(sx*sx+sz*sz)
                if span > 0 and distance <= span then
                    dx,dz=sx/span,sz/span
                    targetX,targetZ=a[1]-dx*distance,a[2]-dz*distance
                    break
                end
                distance=distance-span
                targetX,targetZ=b[1],b[2]
            end
            local phase=tick*0.9-slot*0.65
            local sway=math.sin(phase)*spacing*0.3
            targetX,targetZ=targetX+dz*sway,targetZ-dx*sway
            local height=Spring.GetGroundHeight(targetX,targetZ)+spacing*0.6+math.abs(math.sin(phase))*spacing*0.3
            movers[id](targetX,height,targetZ,tick == 0 and 0.8 or 0.2)
            Turn(id,x_axis,math.sin(phase)*0.18,1.8)
            ShowReg(id)
        end
        Sleep(tick == 0 and 800 or 200)
    end
    resetSpinDrop(allLetters)
    restoreMessageOriginalPosition(allLetters, posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,spindropAxis,posLetters.spinnerSpeed,0) end
end

-- Two advertisements compete for the same physical alphabet. Private letters
-- remain visible; shared letters switch owners on a 500-ms clock.
function hostileTakeoverText(allLetters, posLetters, groups)
    if #allLetters == 0 then return end
    local alternatives = {}
    for _, message in ipairs(posLetters.messages or {}) do
        if message ~= posLetters.myMessage then alternatives[#alternatives+1] = message end
    end
    if #alternatives == 0 then return end
    local rival = selectHologramMessage(alternatives, groups)
    local slots, leases = allocateHologramSlots(rival, groups)
    local rivalPositions, used, pieces = {}, {}, {}
    local floor = 0
    for _, id in ipairs(allLetters) do floor = math.min(floor, posLetters[id][3]) end
    local row, column = 0, 0
    local i = 0
    for glyph in rival:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        i = i + 1
        rivalPositions[i] = {0,-column*sizeSpacingLetter,floor-(row+2)*sizeDownLetter}
        if slots[i] ~= " " then
            used[slots[i]] = true
        end
        if glyph:match("%s") and column > 12 then column,row=0,row+1 else column=column+1 end
    end
    for _, id in ipairs(allLetters) do used[id] = true end
    for id in pairs(used) do pieces[#pieces+1] = id end
    table.sort(pieces)
    StopSpin(textSpinner, spindropAxis, 0)
    resetSpinDrop(pieces)
    local current = {}
    for phase = 0, 23 do
        local shots = {}
        for index, id in ipairs(pieces) do
            local original = posLetters.leases and posLetters.leases[id]
            local invading = leases[id]
            local destinations, positions = original, posLetters.slotPositions
            local visit = math.floor(phase/2)
            -- Opposing donors start on opposite sides, producing crossfire.
            if invading and (not original or (phase+index-1) % 2 == 1) then
                destinations, positions = invading, rivalPositions
            end
            if destinations then
                local slot = destinations[(visit % #destinations)+1]
                local target = positions[slot]
                if original and invading and current[id] then
                    local from = current[id]
                    local midpoint = {}
                    for axis=1,3 do midpoint[axis]=(from[axis]+target[axis])*0.5 end
                    midpoint[3]=midpoint[3]+sizeDownLetter*0.5
                    for axis=1,3 do
                        Move(id,axis,midpoint[axis],math.abs(midpoint[axis]-from[axis])/0.12)
                    end
                    Turn(id,x_axis,((phase+index)%2==0 and 1 or -1)*0.35,3)
                    shots[#shots+1]={id=id,target=target,midpoint=midpoint}
                elseif not current[id] then
                    HideReg(id)
                    for axis=1,3 do Move(id,axis,target[axis],0) end
                    ShowReg(id)
                else
                    -- Private letters stay in formation and kick like gunmen.
                    Turn(id,x_axis,(phase%2==0 and 1 or -1)*0.08,1)
                end
                current[id]=target
            end
        end
        if #shots > 0 then
            Sleep(120)
            for _,shot in ipairs(shots) do
                for axis=1,3 do
                    Move(shot.id,axis,shot.target[axis],math.abs(shot.target[axis]-shot.midpoint[axis])/0.13)
                end
                Turn(shot.id,x_axis,0,3)
            end
            Sleep(130)
            Sleep(250)
        else
            Sleep(500)
        end
    end
    hideTReg(pieces)
    resetSpinDrop(pieces)
    restoreMessageOriginalPosition(allLetters,posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,spindropAxis,posLetters.spinnerSpeed,0) end
end

function getAllTextFx()
return {
        ["civilianCongaText"] = civilianCongaText,
        ["hostileTakeoverText"] = hostileTakeoverText,
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
        --["splineShapeFollowing"] = splineShapeFollowing

        }
end
