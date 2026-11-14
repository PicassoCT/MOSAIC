-- Rates belong to the effect coroutine, never to the whole unit. Weak keys
-- prevent interrupted/killed threads retaining speed state indefinitely.
local textFxRates = setmetatable({}, {__mode="k"})
local textFxMainThread = {}
function GetHologramTextFxSpeed()
    return textFxRates[coroutine.running() or textFxMainThread] or 1
end

function runHologramTextFx(effect, allLetters, posLetters, groups, multiplier)
    multiplier = multiplier or math.random(100,300)/100
    if type(multiplier)~="number" or multiplier~=multiplier then multiplier=1 end
    multiplier=math.max(1,math.min(3,multiplier))
    local thread=coroutine.running() or textFxMainThread
    local previous=textFxRates[thread]
    textFxRates[thread]=multiplier
    effect(allLetters,posLetters,groups)
    textFxRates[thread]=previous
    -- Effects may resume the caller's parent spin while accelerated. Restore
    -- its actual requested speed after leaving the effect's timing context.
    if posLetters.spinnerSpeed and posLetters.spinnerSpeed~=0 then
        Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0)
    end
    return multiplier
end

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
function transitionHologramText(allLetters, posLetters, appearing, duration, timeout)
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
    if timeout then
        if not waitHologramTextCleanup(allLetters,nil,timeout) then
            -- Cleanup retired stalled targets while hidden. Restore the exact
            -- phrase instead of leaving the preview thread waiting forever.
            for _,id in ipairs(allLetters) do
                for axis=1,3 do
                    local target=posLetters[id][axis]
                    Move(id,axis,target,1);Move(id,axis,target,0)
                end
                if appearing then ShowReg(id) end
            end
            if posLetters.debugTextFx then posLetters.debugTextFx('text transition timed out; phrase restored') end
        end
    else
        for _, id in ipairs(allLetters) do WaitForMove(id, backdropAxis) end
    end
    if not appearing then hideTReg(allLetters) end
end

function hardResetHologramLetters(letters)
    if #letters == 0 then return end
    hideTReg(letters)
    for _,id in ipairs(letters) do
        for axis=1,3 do
            StopSpin(id,axis,0)
            -- Replace queued animation destinations before snapping. A plain
            -- speed-zero reset leaves the old engine animations alive.
            Move(id,axis,0,1);Move(id,axis,0,0)
            Turn(id,axis,0,1);Turn(id,axis,0,0)
        end
    end
    -- Let the engine retire those zero-distance commands while still hidden,
    -- before any new layout can be pulled back toward their reset targets.
    Sleep(34)
end

function waitHologramTextCleanup(letters, visible, timeout)
    timeout = timeout or 5000
    local elapsed,resetHidden = 0,{}
    while true do
        local hidden,busy = {},false
        for _,id in ipairs(letters) do
            if visible and not visible[id] then
                if not resetHidden[id] then hidden[#hidden+1]=id;resetHidden[id]=true end
            else
                for axis=1,3 do
                    if Spring.UnitScript.IsInMove(id,axis) or Spring.UnitScript.IsInTurn(id,axis) then busy=true end
                end
            end
        end
        if #hidden>0 then hardResetHologramLetters(hidden) end
        if not busy then return true end
        if elapsed>=timeout then hardResetHologramLetters(letters);return false end
        local step = math.min(33,timeout-elapsed)
        Sleep(step);elapsed=elapsed+step
    end
end

local function waitTextMoves(letters, timeout)
    if timeout then return waitHologramTextCleanup(letters,nil,timeout) end
    for _, id in ipairs(letters) do
        for axis = 1, 3 do WaitForMove(id, axis) end
    end
    return true
end


backdropAxis = x_axis
-- Engine component indices in the exported glyph parent basis. The script
-- header aliases y_axis=3 and z_axis=2; those names are not DAE Y/Z.
-- DAE X/Y span the ground plane, while DAE Z maps to model/world up.
local glyphDepthAxis, glyphBaselineAxis, glyphHeightAxis = 1, 2, 3
-- Keep the parent spinner separate from the letters' local layout axes.
-- Restore the parent Y rotation used before eb6c1863: sharing glyph Z here
-- made the whole upright pillar tip over in game.
textSpinnerAxis = y_axis
spindropAxis = z_axis
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


local function consoleLetterRoll(allLetters, positions, speed, hold)
    for _,id in ipairs(allLetters) do
        reset(id,0)
        HideReg(id)
    end
    for _,id in ipairs(allLetters) do
        for axis=1,3 do Move(id,axis,positions[id][axis],speed) end
        ShowReg(id)
    end
    Sleep(100)
    waitTextMoves(allLetters)
    Sleep(hold)
end

function consoleLetters(allLetters, posLetters)
    if #allLetters == 0 or posLetters.boolUpright then return end
    consoleLetterRoll(allLetters,posLetters,150,10000)
end

function matrixTextFx(allLetters, posLetters)
    if #allLetters == 0 or not posLetters.boolUpright then return end
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local column = {}
    for index,id in ipairs(allLetters) do
        column[id] = {origin[glyphDepthAxis],origin[glyphBaselineAxis],
            origin[glyphHeightAxis]-textSlot(posLetters,id,index-1)*sizeDownLetter}
    end
    -- The same motion as consoleLetters, at eight times its speed, repeated
    -- down a vertical column instead of the old one-off drop.
    for pass=1,3 do consoleLetterRoll(allLetters,column,1200,150) end
end

-- These projections replace either initial text baseline with their own shape.
function canProjectTextFx(name, posLetters)
    if name == "matrixTextFx" then return posLetters.boolUpright == true end
    return not posLetters.boolUpright
        or name == "dnaHelix" or name == "spiralProject" or name == "archProject" or name == "letterTornado"
        or name == "wallImpactText" or name == "smilingFace" or name == "letterPlant" or name == "meteorCraterText" or name == "splineShapeFollowing"
end

function dnaHelix(allLetters, posLetters)
    if #allLetters == 0 then return end
    local radius = 7*sizeSpacingLetter/(2*math.pi)
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local previousSpeed = posLetters.spinnerSpeed
    local speed = previousSpeed and previousSpeed ~= 0 and previousSpeed or math.rad(20)
    hideTReg(allLetters)
    for i,id in ipairs(allLetters) do
        -- Pair consecutive available letters, not two halves of the phrase.
        -- Spaces have no mesh; an odd final letter keeps its own last step.
        local step = math.floor((i-1)/2)
        local angle = step*math.pi/7+((i-1)%2)*math.pi
        reset(id,0)
        Move(id,glyphDepthAxis,origin[glyphDepthAxis]+radius*math.cos(angle),0)
        Move(id,glyphBaselineAxis,origin[glyphBaselineAxis]+radius*math.sin(angle),0)
        Move(id,glyphHeightAxis,origin[glyphHeightAxis]+step*sizeDownLetter,0)
        -- Flip the glyph facing without changing its paired helix position.
        Turn(id,glyphHeightAxis,angle+math.pi,0)
        ShowReg(id)
    end
    -- One engine spinner rotates the staircase rigidly in the ground plane.
    -- Never spin the individual glyphs independently of their positions.
    Spin(textSpinner,textSpinnerAxis,speed,0)
    Sleep(15000)
    hideTReg(allLetters)
    if not previousSpeed or previousSpeed == 0 then
        StopSpin(textSpinner,textSpinnerAxis,0)
        Turn(textSpinner,textSpinnerAxis,0,0)
    end
end



function spiralProject(allLetters, posLetters)
    if #allLetters == 0 then return end
    local circumference, i, radiant, radiantVal, radius, spiralIncrease
    -- Always use the visually verified vertical variant. The script header's
    -- swapped Y/Z names made the old "upright" branch run lengthwise.
    local axialAxis, radialAxis = glyphHeightAxis, glyphBaselineAxis
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
        Move(pID,radialAxis, zr, math.abs(zr)/2.0)
        Move(pID,axialAxis, i * spiralIncrease, 0)
        Turn(pID,axialAxis, math.pi-radiantVal, 0)
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
    hideTReg(allLetters)
    -- Freeze the parent while using cached world-space conversions. The
    -- readable burst must not turn away from the sign's original facing.
    StopSpin(textSpinner,textSpinnerAxis,0)
    local owner = posLetters.unitID
    local pieceMap = Spring.GetUnitPieceMap(owner)
    local movers, anchor, basis = {}
    for _,id in ipairs(allLetters) do
        reset(id,0)
        local move, origin, axes = hologramWorldMover(owner,id,{0,0,0},pieceMap)
        if not move then
            restoreMessageOriginalPosition(allLetters,posLetters)
            if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
            return
        end
        movers[id] = move
        anchor, basis = anchor or origin, basis or axes
    end
    local function length(v) return math.sqrt(v[1]^2+v[2]^2+v[3]^2) end
    local height = sizeDownLetter*length(basis[glyphHeightAxis])
    local spacing = math.max(sizeSpacingLetter*length(basis[glyphBaselineAxis]),height)*1.15
    local dx,dz = -basis[glyphBaselineAxis][1],-basis[glyphBaselineAxis][3]
    local span = math.sqrt(dx*dx+dz*dz)
    if span < 1e-9 then dx,dz,span = 1,0,1 end
    dx,dz = dx/span,dz/span
    local x,z = anchor[1],anchor[3]
    local ground = Spring.GetGroundHeight(x,z)
    local launchY = ground+height*0.5
    local highY = math.max(anchor[2]+height*2,launchY+height*8)
    -- Balanced groups avoid one giant burst or a tiny leftover launch.
    local groupCount = math.ceil(#allLetters/12)
    for groupIndex=1,groupCount do
        local first = math.floor((groupIndex-1)*#allLetters/groupCount)+1
        local last = math.floor(groupIndex*#allLetters/groupCount)
        local firstSlot = textSlot(posLetters,allLetters[first],first-1)
        local slotCount = textSlot(posLetters,allLetters[last],last-1)-firstSlot+1
        local radius = slotCount > 1 and spacing/(2*math.sin(math.pi/slotCount)) or 0
        local peakY = math.max(highY,launchY+radius+height*2)
        local group = {}
        for index=first,last do
            local id = allLetters[index]
            group[#group+1] = id
            movers[id](x,launchY,z,0)
        end
        showTReg(group)
        for _,id in ipairs(group) do movers[id](x,peakY,z,2) end
        if not waitTextMoves(group,5000) then
            if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
            return
        end
        local offsets = {}
        for index,id in ipairs(group) do
            -- A complete circle in the text plane; rotate positions only.
            -- Start at the crown and read clockwise, with all glyphs upright.
            local slot = textSlot(posLetters,id,first+index-2)-firstSlot
            local angle = 2*math.pi*slot/slotCount
            local horizontal,vertical = radius*math.sin(angle),radius*math.cos(angle)
            offsets[id] = {horizontal,vertical}
            movers[id](x+dx*horizontal,peakY+vertical,z+dz*horizontal,1)
        end
        if not waitTextMoves(group,5000) then
            if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
            return
        end
        Sleep(3000)
        -- Preserve the circle/order while it accelerates downward. Each
        -- spark disappears at its own terrain contact, never below ground.
        local landed = {}
        local lowestGround = ground
        for _,id in ipairs(group) do
            local horizontal = offsets[id][1]
            lowestGround = math.min(lowestGround,Spring.GetGroundHeight(x+dx*horizontal,z+dz*horizontal))
        end
        local fallDistance = peakY+radius-lowestGround+height
        for tick=1,20 do
            local drop = fallDistance*(tick/20)^2
            for _,id in ipairs(group) do
                if not landed[id] then
                    local horizontal,vertical = offsets[id][1],offsets[id][2]
                    local tx,tz = x+dx*horizontal,z+dz*horizontal
                    local floor = Spring.GetGroundHeight(tx,tz)+height*0.5
                    local target = peakY+vertical-drop
                    movers[id](tx,math.max(floor,target),tz,0.2)
                    if target <= floor then landed[id] = tick end
                end
            end
            Sleep(200)
            for _,id in ipairs(group) do if landed[id] == tick then HideReg(id) end end
        end
        waitTextMoves(group,5000)
        hideTReg(group)
        if groupIndex < groupCount then Sleep(500) end
    end
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
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
    local slots = math.max(1,#(posLetters.spacing or allLetters))
    local radius = 0
    if slots > 1 then
        -- Retain the authored ring scale, enlarging only when necessary to
        -- keep upright glyphs apart around a full circle (including gaps).
        local spacing = math.max(sizeSpacingLetter,sizeDownLetter)*1.15
        radius = math.max((#allLetters+10)*sizeDownLetter/(2*math.pi),
            spacing/(2*math.sin(math.pi/slots)))
    end
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    hideTReg(allLetters)
    StopSpin(textSpinner,textSpinnerAxis,0)
    for index,id in ipairs(allLetters) do
        local angle = 2*math.pi*textSlot(posLetters,id,index-1)/slots
        local target = {origin[glyphDepthAxis],
            origin[glyphBaselineAxis]-radius*math.sin(angle),
            origin[glyphHeightAxis]+radius+radius*math.cos(angle)}
        reset(id,0)
        for axis=1,3 do Move(id,axis,target[axis],math.abs(target[axis])/2) end
        -- The positions form the ring; glyphs retain the original text facing.
        -- No per-letter spins that turn them edge-on or upside-down.
        ShowReg(id)
    end
    waitTextMoves(allLetters)
    Sleep(15000)
    hideTReg(allLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
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
        local yr = radius * math.sin(radiantVal)

        Move(pID,glyphDepthAxis, xr, 100)
        Move(pID,glyphBaselineAxis, yr, 100)
        Turn(pID,glyphHeightAxis, math.pi + radiantVal, 0)
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

-- Capture the unturned text plane in world space; world compass angles are
-- not script angles once the model import and the unit heading are applied.
local function textFacing(owner)
    local m = {Spring.GetUnitPieceMatrix(owner,textSpinner)}
    local front, up, right = Spring.GetUnitVectors(owner)
    local ux,uy,uz = Spring.GetUnitPosition(owner)
    if not m[16] or not front or not ux then return end
    local function world(x,y,z)
        return {-right[1]*x+up[1]*y+front[1]*z,
                -right[2]*x+up[2]*y+front[2]*z,
                -right[3]*x+up[3]*y+front[3]*z}
    end
    local xAxis, yAxis = world(m[1],m[2],m[3]), world(m[5],m[6],m[7])
    local origin = world(m[13],m[14],m[15])
    origin[1],origin[2],origin[3] = origin[1]+ux,origin[2]+uy,origin[3]+uz
    local function normalize(v)
        local length = math.sqrt(v[1]^2+v[2]^2+v[3]^2)
        if length < 1e-9 then return false end
        for i=1,3 do v[i]=v[i]/length end
        return true
    end
    if not normalize(xAxis) or not normalize(yAxis) then return end
    return function(x,y,z)
        local dx,dy,dz = x-origin[1],y-origin[2],z-origin[3]
        return math.atan2(dx*yAxis[1]+dy*yAxis[2]+dz*yAxis[3],
                          dx*xAxis[1]+dy*xAxis[2]+dz*xAxis[3])
    end
end

function personalProject(allLetters, posLetters)
    if #allLetters == 0 then return end
    local civilian, civilianTypeTable, civiliansNearby, defID, timeCounter, tx, ty, tz
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
        StopSpin(textSpinner, textSpinnerAxis, 0)
        for axis=1,3 do Turn(textSpinner,axis,0,0) end
        local facing = textFacing(posLetters.unitID)
        civilian = getSafeRandom(civiliansNearby, civiliansNearby[1])
      
        timeCounter= math.random(10, 20) * 1000
        while facing and timeCounter > 0 and doesUnitExistAlive(civilian) do
            tx,ty,tz= Spring.GetUnitPosition(civilian)
            if not tx then break end
            Turn(textSpinner, textSpinnerAxis, facing(tx,ty,tz), 0)
            Sleep(1000)
            timeCounter = timeCounter- 1000
        end
        Turn(textSpinner,textSpinnerAxis,0,0)
        if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
    end
end

function archProject(allLetters, posLetters)
    if #allLetters == 0 then return end
    restoreMessageOriginalPosition(allLetters, posLetters)
    resetSpinDrop(allLetters)
    local count = math.max(1, #(posLetters.spacing or allLetters))
    local rows = count > 20 and 2 or 1
    local firstRowCount = math.ceil(count/rows)
    local radius = firstRowCount > 1 and firstRowCount*sizeSpacingLetter/math.pi or 0
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local centerY = origin[glyphBaselineAxis]-radius
    -- Leave a glyph-height gap between the lower arch's crown and the
    -- upper arch's baseline. Long phrases enlarge both arcs, never truncate.
    local rowHeight = radius+sizeDownLetter*1.25
    for i,id in ipairs(allLetters) do
        local slot = textSlot(posLetters,id,i-1)
        local row = slot >= firstRowCount and 1 or 0
        local rowCount = row == 0 and firstRowCount or count-firstRowCount
        local column = slot-row*firstRowCount
        local angle = math.pi*(column+0.5)/rowCount
        -- Apply the 2D rotation matrix [cos -sin; sin cos] to (radius,0).
        -- Equal angular cells give equal arc lengths, including word gaps.
        -- Rotate positions only: glyphs themselves remain unturned.
        local along = radius*math.cos(angle)
        local rise = radius*math.sin(angle)
        Move(id,glyphDepthAxis,origin[glyphDepthAxis],0)
        Move(id,glyphBaselineAxis,centerY+along,0)
        Move(id,glyphHeightAxis,origin[glyphHeightAxis]+(rows-1-row)*rowHeight+rise,0)
        ShowReg(id)
    end
    Sleep(35000)
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
    local count = math.max(1, #(posLetters.spacing or allLetters))
    local rows = count > 20 and 2 or 1
    local firstRowCount = math.ceil(count/rows)
    local side = math.ceil(firstRowCount/4)*sizeSpacingLetter
    local halfSide = side/2
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    for i,id in ipairs(allLetters) do
        local slot = textSlot(posLetters,id,i-1)
        local row = slot >= firstRowCount and 1 or 0
        local rowCount = row == 0 and firstRowCount or count-firstRowCount
        local column = slot-row*firstRowCount
        -- Balance logical slots across all four faces. Cell centres leave
        -- clearance at corners, including when a row is not divisible by four.
        local perFace, extra = math.floor(rowCount/4), rowCount%4
        local face = 0
        local faceCount = perFace+(face < extra and 1 or 0)
        while column >= faceCount do
            column = column-faceCount
            face = face+1
            faceCount = perFace+(face < extra and 1 or 0)
        end
        local along = halfSide-(column+0.5)*side/faceCount
        local angle = -face*math.pi/2
        local cosine, sine = math.cos(angle), math.sin(angle)
        -- Rotate the +X wall around actual glyph Z.
        -- Text reads along -Y on the first face, then around the perimeter.
        reset(id,0)
        Move(id,glyphDepthAxis,origin[glyphDepthAxis]+halfSide*cosine-along*sine,0)
        Move(id,glyphBaselineAxis,origin[glyphBaselineAxis]+halfSide*sine+along*cosine,0)
        Move(id,glyphHeightAxis,origin[glyphHeightAxis]+(rows-1-row)*sizeDownLetter*1.25,0)
        -- Flip the glyph facing without changing its place on the wall.
        Turn(id,glyphHeightAxis,angle+math.pi,0)
        ShowReg(id)
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

function HideLetters(allLetters, posLetters, _, cleanupLimit)
    if #allLetters == 0 then return end
    local direction, rest
    local started = cleanupLimit and Spring.GetGameFrame()
    local function remaining()
        return cleanupLimit - (Spring.GetGameFrame()-started)*1000/30
    end
   --echo("HideLetters with "..toString(allLetters))
    direction =  randSign()
    --Setup
     for j=1, #allLetters do
            if cleanupLimit and remaining()<=34 then hardResetHologramLetters(allLetters);return false end
            HideReg(allLetters[j])
            if cleanupLimit then
                hardResetHologramLetters({allLetters[j]})
                for axis=1,3 do
                    if axis~=backdropAxis then Move(allLetters[j],axis,posLetters[allLetters[j]][axis],0) end
                end
                Move(allLetters[j],backdropAxis,150,300)
                if not waitHologramTextCleanup({allLetters[j]},nil,math.max(0,remaining())) then
                    hardResetHologramLetters(allLetters);return false
                end
            else
                WMove(allLetters[j],backdropAxis, 150, 300)
            end
            ShowReg(allLetters[j])
            Move(allLetters[j],backdropAxis, posLetters[allLetters[j]][backdropAxis], 600)                
     end

    rest = math.random(4, 16)*500
    if cleanupLimit and rest>=remaining() then
        Sleep(math.max(0,remaining()))
        hardResetHologramLetters(allLetters);return false
    end
    Sleep(rest)
    return true
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
    local slots = posLetters.spacing or allLetters
    local count = #slots
    local chars = {}
    for glyph in (posLetters.myMessage or ''):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars+1] = glyph:upper()
    end
    local leftEnd, rightStart = math.floor(count/2),math.floor(count/2)+1
    local splitDistance = math.huge
    for slot=2,count-1 do
        if chars[slot] and chars[slot]:match('%s') and math.abs(slot-(count+1)/2)<splitDistance then
            leftEnd,rightStart,splitDistance = slot-1,slot+1,math.abs(slot-(count+1)/2)
        end
    end
    local leftCross,rightCross,best
    for left=1,leftEnd do
        for right=rightStart,count do
            if chars[left] and not chars[left]:match('%s') and chars[left]==chars[right]
                and (type(slots[left])=='number' or type(slots[right])=='number') then
                local score = math.abs(left-(leftEnd+1)/2)+math.abs(right-(rightStart+count)/2)
                if not best or score<best then leftCross,rightCross,best = left,right,score end
            end
        end
    end
    if not leftCross then
        -- Without a common letter, share the middle existing glyph as the
        -- junction of the two segments; never invent or reorder characters.
        local pivotIndex = math.ceil(#allLetters/2)
        leftCross = textSlot(posLetters,allLetters[pivotIndex],pivotIndex-1)+1
        rightCross,leftEnd,rightStart = leftCross,leftCross,leftCross
    end
    local shared = type(slots[leftCross])=='number' and slots[leftCross] or slots[rightCross]
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local pivotZ = origin[glyphHeightAxis]+(count-rightCross)*sizeDownLetter
    local layout = {slotPositions={},leases=posLetters.leases}
    for slot=1,count do
        if slot<=leftEnd then
            layout.slotPositions[slot] = {origin[glyphDepthAxis],
                origin[glyphBaselineAxis]-(slot-leftCross)*sizeSpacingLetter,pivotZ}
        else
            layout.slotPositions[slot] = {origin[glyphDepthAxis],origin[glyphBaselineAxis],
                pivotZ-(slot-rightCross)*sizeDownLetter}
        end
    end
    hideTReg(allLetters)
    StopSpin(textSpinner,textSpinnerAxis,0)
    local shown = {}
    for index,id in ipairs(allLetters) do
        local slot = textSlot(posLetters,id,index-1)+1
        if (slot~=leftCross and slot~=rightCross) or id==shared then
            local target = layout.slotPositions[slot]
            layout[id] = target
            reset(id,0)
            for axis=1,3 do Move(id,axis,target[axis],math.abs(target[axis])/0.5) end
            ShowReg(id)
            shown[#shown+1] = id
        end
    end
    waitTextMoves(shown)
    holdHologramText(shown,layout,7000)
    restoreMessageOriginalPosition(allLetters,posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
end



local function prepareTextLine(allLetters, posLetters)
    local count = math.max(1,#(posLetters.spacing or allLetters))
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local line = {slotPositions={},leases=posLetters.leases}
    hideTReg(allLetters)
    StopSpin(textSpinner,textSpinnerAxis,0)
    for slot=1,count do
        line.slotPositions[slot] = {origin[glyphDepthAxis],
            origin[glyphBaselineAxis]-(slot-1)*sizeSpacingLetter,origin[glyphHeightAxis]}
    end
    for index,id in ipairs(allLetters) do
        local target = line.slotPositions[textSlot(posLetters,id,index-1)+1]
        line[id] = target
        reset(id,0)
        for axis=1,3 do Move(id,axis,target[axis],0) end
        ShowReg(id)
    end
    return line,origin,count
end

function syncToFrontLetters(allLetters, posLetters)
    if #allLetters == 0 then return end
    local line,origin,count = prepareTextLine(allLetters,posLetters)
    local previous = {}
    for _,id in ipairs(allLetters) do previous[id] = origin[glyphDepthAxis] end
    -- A pressure wave travels behind the line. Its four-slot-wide footprint
    -- pushes neighbours together, then releases them smoothly back in place.
    -- Only depth changes; letters never leave their baseline or word slots.
    local halfWidth, depth = 2,sizeSpacingLetter*0.75
    for tick=0,2*(count-1+2*halfWidth) do
        local center = -halfWidth+tick*0.5
        for index,id in ipairs(allLetters) do
            local distance = math.abs(textSlot(posLetters,id,index-1)-center)
            local weight = distance < halfWidth and math.cos(distance*math.pi/(2*halfWidth))^2 or 0
            local target = origin[glyphDepthAxis]+depth*weight
            Move(id,glyphDepthAxis,target,math.abs(target-previous[id])/0.1)
            previous[id] = target
        end
        Sleep(100)
    end
    waitTextMoves(allLetters)
    holdHologramText(allLetters,line,2000)
    restoreMessageOriginalPosition(allLetters,posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
end

function heartMonitor(allLetters, posLetters)
    if #allLetters == 0 then return end
    local line,origin,count = prepareTextLine(allLetters,posLetters)
    local previous = {}
    local height,amplitude = origin[glyphHeightAxis],sizeDownLetter*1.2
    for _,id in ipairs(allLetters) do previous[id] = height end
    local function bump(distance,center,width)
        return math.exp(-((distance-center)/width)^2)
    end
    -- A recognisable ECG-shaped pulse: small lead-in, dip, sharp spike,
    -- undershoot and recovery. The line stays flat outside its footprint.
    for beat=1,2 do
        for tick=0,4*(count-1+6) do
            local center = -3+tick*0.25
            for index,id in ipairs(allLetters) do
                local distance = textSlot(posLetters,id,index-1)-center
                local pulse = 0
                if math.abs(distance)<3 then
                    pulse = 0.12*bump(distance,1.6,0.45)-0.2*bump(distance,0.5,0.22)
                        +bump(distance,0,0.25)-0.3*bump(distance,-0.45,0.25)
                        +0.22*bump(distance,-1.5,0.55)
                end
                local target = height+amplitude*pulse
                if target~=previous[id] then
                    Move(id,glyphHeightAxis,target,math.abs(target-previous[id])/0.075)
                    previous[id] = target
                end
            end
            Sleep(75)
        end
        waitTextMoves(allLetters)
        if beat==1 then Sleep(600) end
    end
    holdHologramText(allLetters,line,2000)
    restoreMessageOriginalPosition(allLetters,posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
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
    local function moveToWorld(x,y,z,seconds)
        local delta = {x-origin[1],y-origin[2],z-origin[3]}
        local current = previous
        if Spring.UnitScript and Spring.UnitScript.GetPieceTranslation then
            local translation = {Spring.UnitScript.GetPieceTranslation(id)}
            if translation[3] then current = translation end
        end
        for axis = 1, 3 do
            local target = base[axis] + textDot(delta,cof[axis])/det
            -- Move(...,0) teleports but does not cancel the engine's queued
            -- animation. Replace its destination even for a stationary axis.
            local speed = seconds > 0 and math.max(1e-6,math.abs(target-current[axis])/seconds) or 1
            Move(id,axis,target,speed)
            if seconds <= 0 then Move(id,axis,target,0) end
            previous[axis] = target
        end
    end
    return moveToWorld, origin, basis
end

-- Selected house pieces include their imported scale and ancestor transforms.
-- Never use a procedural house's whole model bounds: those contain hidden variants.
local function textUnitVector(v)
    local length=math.sqrt(textDot(v,v))
    if length<1e-9 then return end
    return {v[1]/length,v[2]/length,v[3]/length}
end
local function textWallTarget(owner,anchor,height,spacing,slots)
    if not (Spring.GetUnitsInCylinder and Spring.UnitScript
        and Spring.UnitScript.GetScriptEnv and Spring.UnitScript.CallAsUnit
        and getCivilianHouseTypeTable) then return end
    local types=getCivilianHouseTypeTable(UnitDefs)
    local nearest,best
    local candidates=Spring.GetUnitsInCylinder(anchor[1],anchor[3],900) or {}
    table.sort(candidates)
    for _,target in ipairs(candidates) do
        if target~=owner and types[Spring.GetUnitDefID(target)]
            and not Spring.GetUnitIsDead(target) then
            local env=Spring.UnitScript.GetScriptEnv(target)
            local selected
            if env and env.GetBuildingClearancePieces then
                Spring.UnitScript.CallAsUnit(target,function() selected=env.GetBuildingClearancePieces() end)
            end
            local ux,uy,uz=Spring.GetUnitPosition(target)
            local front,up,right=Spring.GetUnitVectors(target)
            if selected and ux and front and up and right then
                local function vector(x,y,z)
                    return {-right[1]*x+up[1]*y+front[1]*z,
                        -right[2]*x+up[2]*y+front[2]*z,-right[3]*x+up[3]*y+front[3]*z}
                end
                local pieces,seen={},{}
                for _,id in pairs(selected) do
                    if type(id)=='number' and not seen[id] then pieces[#pieces+1]=id;seen[id]=true end
                end
                table.sort(pieces)
                for _,id in ipairs(pieces) do
                    local info=Spring.GetUnitPieceInfo(target,id)
                    local m={Spring.GetUnitPieceMatrix(target,id)}
                    if info and not info.isEmpty and info.min and info.max and m[16] then
                        local axes={vector(m[1],m[2],m[3]),vector(m[5],m[6],m[7]),vector(m[9],m[10],m[11])}
                        local center=vector(m[13],m[14],m[15])
                        center[1],center[2],center[3]=center[1]+ux,center[2]+uy,center[3]+uz
                        local halves={}
                        for a=1,3 do
                            halves[a]=(info.max[a]-info.min[a])*0.5
                            for k=1,3 do center[k]=center[k]+axes[a][k]*(info.max[a]+info.min[a])*0.5 end
                        end
                        for a=1,3 do
                            local b,c=a%3+1,(a+1)%3+1
                            local normal=textUnitVector(textCross(axes[b],axes[c]))
                            if normal and math.abs(normal[2])<0.01 then
                                if textDot(normal,axes[a])<0 then for k=1,3 do normal[k]=-normal[k] end end
                                for _,sign in ipairs({-1,1}) do
                                    local n,face={},{}
                                    for k=1,3 do n[k]=normal[k]*sign;face[k]=center[k]+axes[a][k]*halves[a]*sign end
                                    local toward={anchor[1]-face[1],anchor[2]-face[2],anchor[3]-face[3]}
                                    if textDot(toward,n)>height then
                                        local tangent={n[3],0,-n[1]}
                                        -- Accept rectangular upright faces, excluding sloped roofs.
                                        local bw,cw=math.abs(textDot(axes[b],tangent)),math.abs(textDot(axes[c],tangent))
                                        local bh,ch=math.abs(axes[b][2]),math.abs(axes[c][2])
                                        local aligned=(bw<1e-6 and ch<1e-6) or (cw<1e-6 and bh<1e-6)
                                        local width=2*(bw*halves[b]+cw*halves[c])
                                        local tall=2*(bh*halves[b]+ch*halves[c])
                                        local columns=math.min(slots,math.floor((width-height)/spacing))
                                        if aligned and columns>0 then
                                            local rows=math.ceil(slots/columns)
                                            if (rows+1)*height*1.35<=tall then
                                                local distance=textDot(toward,toward)
                                                if not best or distance<best then
                                                    best=distance
                                                    nearest={unit=target,piece=id,center=face,normal=n,right=tangent,
                                                        columns=columns,rows=rows}
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nearest
end

function wallImpactText(allLetters,posLetters)
    if #allLetters==0 then return end
    StopSpin(textSpinner,textSpinnerAxis,0)
    hardResetHologramLetters(allLetters)
    local function finish()
        hardResetHologramLetters(allLetters)
        restoreMessageOriginalPosition(allLetters,posLetters)
        if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
    end
    local owner=posLetters.unitID
    local pieceMap=Spring.GetUnitPieceMap(owner)
    local movers,anchor,basis={}
    for _,id in ipairs(allLetters) do
        local move,origin,axes=hologramWorldMover(owner,id,{0,0,0},pieceMap)
        if not move then finish();return end
        movers[id]=move;anchor,basis=anchor or origin,basis or axes
    end
    local height=sizeDownLetter*math.sqrt(textDot(basis[glyphHeightAxis],basis[glyphHeightAxis]))
    local spacing=math.max(height,sizeSpacingLetter*math.sqrt(textDot(basis[glyphBaselineAxis],basis[glyphBaselineAxis])))*1.2
    local slots=math.max(1,#(posLetters.spacing or allLetters))
    local wall=textWallTarget(owner,anchor,height,spacing,slots)
    if not wall then
        if posLetters.debugTextFx then posLetters.debugTextFx('wall impact: skipped; no suitable house wall within 900') end
        finish();return
    end
    if posLetters.debugTextFx then posLetters.debugTextFx('wall impact: house '..wall.unit..', piece '..wall.piece) end
    local cof={textCross(basis[2],basis[3]),textCross(basis[3],basis[1]),textCross(basis[1],basis[2])}
    local det=textDot(basis[1],cof[1])
    local function localVector(v) return {textDot(v,cof[1])/det,textDot(v,cof[2])/det,textDot(v,cof[3])/det} end
    -- Glyphs read along -Y and stand along +Z, with their face toward -X.
    local x=textUnitVector(localVector({-wall.normal[1],-wall.normal[2],-wall.normal[3]}))
    local up=localVector({0,1,0})
    local y=textUnitVector(textCross(up,x))
    local z=textCross(x,y)
    local previous={}
    local function orient(id,angle,seconds)
        local c,s=math.cos(angle),math.sin(angle)
        local yy,zz={},{}
        for k=1,3 do yy[k]=y[k]*c+z[k]*s;zz[k]=-y[k]*s+z[k]*c end
        -- Native piece rotation is Y * X * Z. Choose the nearest equivalent
        -- Euler angles so a branch crossing never produces a full extra turn.
        local rx=-math.asin(math.max(-1,math.min(1,zz[2])))
        local ry,rz
        if math.abs(math.cos(rx))<1e-6 then
            ry=math.atan2(-x[3],x[1]);rz=0
        else ry=math.atan2(zz[1],zz[3]);rz=math.atan2(x[2],yy[2]) end
        local angles={rx,ry,rz}
        local old=previous[id] or angles
        for axis=1,3 do
            local value=old[axis]+(angles[axis]-old[axis]+math.pi)%(2*math.pi)-math.pi
            Turn(id,axis,value,seconds>0 and math.max(1e-6,math.abs(value-old[axis])/seconds) or 1)
            if seconds<=0 then Turn(id,axis,value,0) end
            angles[axis]=value
        end
        previous[id]=angles
    end
    local function destination(slot)
        local row=math.floor(slot/wall.columns)
        local count=math.min(wall.columns,slots-row*wall.columns)
        local across=(slot%wall.columns-(count-1)*0.5)*spacing
        local rise=((wall.rows-1)*0.5-row)*height*1.35
        local p={}
        for k=1,3 do p[k]=wall.center[k]+wall.right[k]*across+wall.normal[k]*height*0.04 end
        p[2]=p[2]+rise
        return p
    end
    local flights,last={},0
    for index,id in ipairs(allLetters) do
        local slot=textSlot(posLetters,id,index-1)
        local target=destination(slot)
        local delay=slot*120
        local duration=450+math.random(0,200)
        local reach=height*(9+math.random()*4)
        local across=(math.random()-0.5)*height*6
        local start={}
        for k=1,3 do start[k]=target[k]+wall.normal[k]*reach+wall.right[k]*across end
        start[2]=start[2]+height*(1+math.random()*3)
        flights[id]={start=start,target=target,delay=delay,duration=duration,
            spin=(index%2==0 and -1 or 1)*2*math.pi*(index%3==0 and 0 or 2)}
        last=math.max(last,delay+duration+240)
        movers[id](start[1],start[2],start[3],0);orient(id,0,0)
    end
    local function alive() return Spring.ValidUnitID(wall.unit) and not Spring.GetUnitIsDead(wall.unit) end
    for time=0,last+33,33 do
        if not alive() then finish();return end
        for _,id in ipairs(allLetters) do
            local f=flights[id]
            local age=time-f.delay
            if age>=0 then
                ShowReg(id)
                local t=math.min(1,age/f.duration)
                local p={}
                for k=1,3 do p[k]=f.start[k]+(f.target[k]-f.start[k])*t end
                local settle=math.max(0,age-f.duration)/240
                local wobble=settle<1 and math.sin(settle*math.pi*4)*(1-settle)*0.18 or 0
                movers[id](p[1],p[2],p[3],0.033)
                orient(id,f.spin*t+wobble,0.033)
            end
        end
        Sleep(33)
    end
    for phase=0,7 do
        if not alive() then finish();return end
        for _,id in ipairs(allLetters) do
            local leases=posLetters.leases and posLetters.leases[id]
            if leases and #leases>1 then
                local p=destination(leases[phase%#leases+1]-1)
                HideReg(id);movers[id](p[1],p[2],p[3],0);ShowReg(id)
            end
        end
        Sleep(500)
    end
    finish()
end

function meteorCraterText(allLetters, posLetters)
    if #allLetters == 0 then return end
    StopSpin(textSpinner,textSpinnerAxis,0)
    hardResetHologramLetters(allLetters)
    local function finish()
        hardResetHologramLetters(allLetters)
        restoreMessageOriginalPosition(allLetters,posLetters)
        if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
    end
    local owner = posLetters.unitID
    local pieceMap = Spring.GetUnitPieceMap(owner)
    local movers,anchor,basis = {}
    for _,id in ipairs(allLetters) do
        local move,origin,axes = hologramWorldMover(owner,id,{0,0,0},pieceMap)
        if not move then finish();return end
        movers[id]=move;anchor,basis=anchor or origin,basis or axes
    end
    local function length(v) return math.sqrt(textDot(v,v)) end
    local height = sizeDownLetter*length(basis[glyphHeightAxis])
    local spacing = math.max(sizeSpacingLetter*length(basis[glyphBaselineAxis]),height)*1.15
    local slots = math.max(1,#(posLetters.spacing or allLetters))
    local radius = math.max(spacing*2,slots*spacing/(2*math.pi))
    local dx,dz = -basis[glyphBaselineAxis][1],-basis[glyphBaselineAxis][3]
    local span = math.sqrt(dx*dx+dz*dz)
    if span<1e-9 then dx,dz,span=1,0,1 end
    dx,dz=dx/span,dz/span
    local x,z = anchor[1],anchor[3]
    local ground = Spring.GetGroundHeight(x,z)+height*0.5
    local altitude = math.max(height*12,anchor[2]-ground+height*4)
    local reach = math.max(radius*3,height*10)
    local function place(id,along,rise,across,seconds)
        local tx,tz = x+dx*along+dz*across,z+dz*along-dx*across
        movers[id](tx,Spring.GetGroundHeight(tx,tz)+height*0.5+math.max(0,rise),tz,seconds)
    end
    -- The leading glyph is the meteor core. Later logical slots trail behind
    -- it up the same diagonal wake; acceleration pulls the tail into impact.
    local function incoming(t,seconds)
        local remaining = 1-t*t
        for index,id in ipairs(allLetters) do
            local tail = textSlot(posLetters,id,index-1)*spacing*remaining
            place(id,-reach*remaining-tail,altitude*remaining+tail*0.45,0,seconds)
        end
    end
    incoming(0,0)
    showTReg(allLetters)
    for tick=1,24 do incoming(tick/24,0.1);Sleep(100) end
    if not waitTextMoves(allLetters,1500) then finish();return end
    Sleep(80)
    local debris = {}
    for index,id in ipairs(allLetters) do
        local angle = 2*math.pi*(index-1)/#allLetters + math.random()*0.6
        debris[id]={angle=angle,reach=radius*(1.5+math.random()*1.5),
            loft=height*(2+math.random()*5),spin=(index%2==0 and 1 or -1)*math.pi*4}
    end
    -- Radial ballistic debris, with terrain clearance at each sampled target.
    for tick=1,24 do
        local t=tick/24
        for _,id in ipairs(allLetters) do
            local d=debris[id]
            local along,across=math.sin(d.angle)*d.reach*t,math.cos(d.angle)*d.reach*t
            local clearance=height*0.5*math.abs(math.sin(d.spin*t))
            place(id,along,4*d.loft*t*(1-t)+clearance,across,0.1)
            Turn(id,glyphDepthAxis,d.spin*t,math.abs(d.spin)/2.4)
            Turn(id,glyphHeightAxis,-d.spin*t,math.abs(d.spin)/2.4)
        end
        Sleep(100)
    end
    if not waitTextMoves(allLetters,1500) then finish();return end
    Sleep(350)
    local function ring(id,slot,seconds)
        local angle=2*math.pi*slot/slots
        place(id,radius*math.sin(angle),0,radius*math.cos(angle),seconds)
    end
    -- Gather into source-slot order with a small lift. Word gaps retain cells.
    for tick=1,18 do
        local t=tick/18
        local ease=t*t*(3-2*t)
        for index,id in ipairs(allLetters) do
            local d=debris[id]
            local angle=2*math.pi*textSlot(posLetters,id,index-1)/slots
            local along=(1-ease)*math.sin(d.angle)*d.reach+ease*radius*math.sin(angle)
            local across=(1-ease)*math.cos(d.angle)*d.reach+ease*radius*math.cos(angle)
            place(id,along,height*math.sin(math.pi*t),across,0.1)
            for axis=1,3 do Turn(id,axis,0,math.pi*8) end
        end
        Sleep(100)
    end
    if not waitTextMoves(allLetters,1500) then finish();return end
    -- Lease repeated glyphs on the ring, not at the original sign positions.
    for phase=0,11 do
        for _,id in ipairs(allLetters) do
            local leases=posLetters.leases and posLetters.leases[id]
            if leases and #leases>1 then
                HideReg(id);ring(id,leases[phase%#leases+1]-1,0);ShowReg(id)
            end
        end
        Sleep(500)
    end
    finish()
end

function civilianCongaText(allLetters, posLetters)
    if #allLetters == 0 then return end
    local owner = posLetters.unitID
    local types = getCivilianTypeTable(UnitDefs)
    local function report(message)
        if posLetters.debugTextFx then posLetters.debugTextFx('conga: '..message) end
    end
    local civilian
    for _, candidate in ipairs(getAllNearUnit(owner, 650) or {}) do
        if types[Spring.GetUnitDefID(candidate)] and doesUnitExistAlive(candidate) then
            civilian = candidate
            break
        end
    end
    if not civilian then report('skipped: no eligible target within 650');return end
    local def = UnitDefs[Spring.GetUnitDefID(civilian)]
    report('following unit '..civilian..' ('..(def and def.name or 'unknown type')..')')
    StopSpin(textSpinner, textSpinnerAxis, 0)
    for axis = 1, 3 do Turn(textSpinner, axis, 0, 0) end
    restoreMessageOriginalPosition(allLetters, posLetters)
    resetSpinDrop(allLetters)
    local movers, pieceMap = {}, Spring.GetUnitPieceMap(owner)
    for _, id in ipairs(allLetters) do
        movers[id] = hologramWorldMover(owner, id, posLetters[id], pieceMap)
        if not movers[id] then
            report('stopped: could not convert glyph '..id..' to world coordinates')
            restoreMessageOriginalPosition(allLetters, posLetters)
            if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
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
    local ticks,reason = 0,'completed'
    -- 5 Hz for at most 16 seconds; engine interpolation fills the gaps. Keep a
    -- bounded path history so the conga follows corners instead of cutting them.
    for tick = 0, 79 do
        if not doesUnitExistAlive(civilian) then reason='target disappeared';break end
        local x, _, z = Spring.GetUnitPosition(civilian)
        if not x then reason='target position unavailable';break end
        if (x-ox)^2+(z-oz)^2 > 750^2 then reason='target moved beyond 750';break end
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
        ticks=ticks+1
    end
    -- Finish the last follow/rocking commands before restoring the phrase.
    -- Instant resets alone leave old engine animations running afterward.
    if not waitHologramTextCleanup(allLetters,nil,5000) then reason=reason..'; cleanup hard-reset after 5 seconds' end
    resetSpinDrop(allLetters)
    restoreMessageOriginalPosition(allLetters, posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
    report(reason..' after '..ticks..' follow updates')
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
    StopSpin(textSpinner, textSpinnerAxis, 0)
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
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
end

function smilingFace(allLetters, posLetters, groups)
    if #allLetters == 0 then return end
    local pieces,used = {},{}
    for _,id in ipairs(allLetters) do pieces[#pieces+1]=id;used[id]=true end
    -- Tiny phrases can borrow spare glyph meshes for two eyes and a mouth.
    -- Borrow deterministically and release every extra piece on completion.
    groups = groups or posLetters.TriLetters or {}
    for code=65,90 do
        for _,id in ipairs(groups[string.char(code)] or {}) do
            if #pieces<5 and not used[id] then pieces[#pieces+1]=id;used[id]=true end
        end
    end
    if #pieces<3 then return end
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local mouthCount = #pieces-2
    local radius = math.max(sizeSpacingLetter*1.5,(mouthCount-1)*sizeSpacingLetter/math.pi)
    hideTReg(pieces)
    StopSpin(textSpinner,textSpinnerAxis,0)
    for index,id in ipairs(pieces) do
        local along,rise
        if index<=2 then
            along = (index==1 and 1 or -1)*radius*0.45
            rise = radius+sizeDownLetter*1.25
        else
            local angle = mouthCount==1 and math.pi/2 or math.pi*(index-3)/(mouthCount-1)
            along,rise = radius*math.cos(angle),radius*(1-math.sin(angle))
        end
        local target = {origin[glyphDepthAxis],origin[glyphBaselineAxis]+along,origin[glyphHeightAxis]+rise}
        reset(id,0)
        for axis=1,3 do Move(id,axis,target[axis],math.abs(target[axis])/0.6) end
        ShowReg(id)
    end
    waitTextMoves(pieces)
    Sleep(7000)
    hideTReg(pieces)
    for _,id in ipairs(pieces) do reset(id,0) end
    restoreMessageOriginalPosition(allLetters,posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
end

function letterPlant(allLetters, posLetters)
    if #allLetters == 0 then return end
    hideTReg(allLetters)
    StopSpin(textSpinner,textSpinnerAxis,0)
    local movers,anchor,basis = {}
    local owner = posLetters.unitID
    local pieceMap = Spring.GetUnitPieceMap(owner)
    for _,id in ipairs(allLetters) do
        reset(id,0)
        local move,origin,axes = hologramWorldMover(owner,id,{0,0,0},pieceMap)
        if not move then
            restoreMessageOriginalPosition(allLetters,posLetters)
            if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
            return
        end
        movers[id]=move;anchor,basis=anchor or origin,basis or axes
    end
    local function length(v) return math.sqrt(v[1]^2+v[2]^2+v[3]^2) end
    local height = sizeDownLetter*length(basis[glyphHeightAxis])
    local width = sizeSpacingLetter*length(basis[glyphBaselineAxis])
    local dx,dz = -basis[glyphBaselineAxis][1],-basis[glyphBaselineAxis][3]
    local span = math.sqrt(dx*dx+dz*dz)
    if span<1e-9 then dx,dz,span=1,0,1 end
    dx,dz=dx/span,dz/span
    local x,z = anchor[1],anchor[3]
    local rootY = Spring.GetGroundHeight(x,z)+height*0.5
    local stemCount = math.ceil(#allLetters/2)
    local branchCount = math.ceil((#allLetters-stemCount)/2)
    for index,id in ipairs(allLetters) do
        if index<=stemCount then
            movers[id](x,rootY,z,0)
            ShowReg(id)
            movers[id](x,rootY+(index-1)*height*1.1,z,0.3)
        else
            local leaf = index-stemCount
            local branch = math.ceil(leaf/2)
            local side = leaf%2==1 and -1 or 1
            local attachY = rootY+branch/(branchCount+1)*(stemCount-1)*height*1.1
            local reach = side*width*(1.25+branch*0.15)
            local tx,tz = x+dx*reach,z+dz*reach
            local leafY = math.max(attachY+height*0.5,Spring.GetGroundHeight(tx,tz)+height*0.5)
            movers[id](x,attachY,z,0)
            ShowReg(id)
            movers[id](tx,leafY,tz,0.4)
        end
        -- Grow one part at a time, using engine interpolation for each sprout.
        for axis=1,3 do WaitForMove(id,axis) end
    end
    Sleep(6000)
    restoreMessageOriginalPosition(allLetters,posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
end

function letterTornado(allLetters, posLetters)
    if #allLetters == 0 then return end
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local previousSpeed = posLetters.spinnerSpeed
    local speed = math.max(math.rad(60),math.abs(previousSpeed or 0))
    if previousSpeed and previousSpeed<0 then speed=-speed end
    local cone = {}
    hardResetHologramLetters(allLetters)
    Spin(textSpinner,textSpinnerAxis, -12,  0.01 )
    for index,id in ipairs(allLetters) do
        local slot = textSlot(posLetters,id,index-1)
        -- Eight logical slots per turn; rising letters trace an expanding
        -- cone. Reserve whitespace instead of compressing the phrase.
        local angle = slot*math.pi/4
        local height = slot*sizeDownLetter*0.5
        local radius = sizeSpacingLetter*1.5+height*0.35
        cone[id]={angle=angle,radius=radius}
        local target = {origin[glyphDepthAxis]+radius*math.cos(angle),
            origin[glyphBaselineAxis]+radius*math.sin(angle),
            origin[glyphHeightAxis]+height}
        for axis=1,3 do Move(id,axis,target[axis],math.abs(target[axis])) end
        -- Match the corrected outward-facing glyph orientation of cube/DNA.
        Turn(id,glyphHeightAxis,angle+math.pi,0)
        ShowReg(id)
    end
    if not waitTextMoves(allLetters,2500) then
        StopSpin(textSpinner,textSpinnerAxis,0)
        Turn(textSpinner,textSpinnerAxis,0,1);Turn(textSpinner,textSpinnerAxis,0,0)
        restoreMessageOriginalPosition(allLetters,posLetters)
        if previousSpeed and previousSpeed~=0 then Spin(textSpinner,textSpinnerAxis,previousSpeed,0) end
        if posLetters.debugTextFx then posLetters.debugTextFx('tornado formation timed out; continuing preview') end
        return
    end
    -- Orbit in the glyphs' actual horizontal plane instead of relying on the
    -- imported parent pivot. Facing follows the orbit, keeping the cone intact.
    Sleep(3000)
    hideTReg(allLetters)
    StopSpin(textSpinner,textSpinnerAxis,0)
    Turn(textSpinner,textSpinnerAxis,0,1);Turn(textSpinner,textSpinnerAxis,0,0)
    hardResetHologramLetters(allLetters)
    restoreMessageOriginalPosition(allLetters,posLetters)
    holdHologramText(allLetters,posLetters,3000)
    if previousSpeed and previousSpeed ~= 0 then Spin(textSpinner,textSpinnerAxis,previousSpeed,0) end
end

function oneArmedBandit(allLetters, posLetters, groups)
    if #allLetters == 0 then return end
    groups = groups or posLetters.TriLetters or {}
    local reserved, phraseCharacters, character = {}, {}, {}
    for _,id in ipairs(allLetters) do reserved[id]=true end
    for code=65,90 do
        local ch=string.char(code)
        for _,id in ipairs(groups[ch] or {}) do
            character[id]=ch
            if reserved[id] then phraseCharacters[ch]=true end
        end
    end
    local unrelated, other = {}, {}
    for code=65,90 do
        local ch=string.char(code)
        for _,id in ipairs(groups[ch] or {}) do
            if not reserved[id] then
                reserved[id]=true
                local pool=phraseCharacters[ch] and other or unrelated
                pool[#pool+1]=id
            end
        end
    end
    for _,pool in ipairs({unrelated,other}) do
        for i=#pool,2,-1 do
            local j=math.random(1,i);pool[i],pool[j]=pool[j],pool[i]
        end
    end
    -- Prefer characters absent from the phrase. With a small alphabet, spare
    -- copies of other characters can still dress a reel, never its final glyph.
    local wheels, borrowed, pieces = {}, {}, {}
    for i,id in ipairs(allLetters) do wheels[i]={};pieces[#pieces+1]=id end
    for symbol=1,3 do
        for i,id in ipairs(allLetters) do
            local chosen
            for _,pool in ipairs({unrelated,other}) do
                for index=#pool,1,-1 do
                    if character[pool[index]]~=character[id] then
                        chosen=table.remove(pool,index);break
                    end
                end
                if chosen then break end
            end
            if chosen then
                wheels[i][#wheels[i]+1]=chosen
                borrowed[#borrowed+1]=chosen;pieces[#pieces+1]=chosen
            end
        end
    end
    StopSpin(textSpinner,textSpinnerAxis,0)
    hardResetHologramLetters(pieces)
    local radius, tau = sizeDownLetter*0.85, 2*math.pi
    local previous = {}
    local function place(id, target, angle, seconds)
        local depth=target[glyphDepthAxis]+radius*(math.cos(angle)-1)
        local height=target[glyphHeightAxis]-radius*math.sin(angle)
        local old=previous[id]
        Move(id,glyphBaselineAxis,target[glyphBaselineAxis],0)
        Move(id,glyphDepthAxis,depth,old and seconds>0 and math.abs(depth-old[1])/seconds or 0)
        Move(id,glyphHeightAxis,height,old and seconds>0 and math.abs(height-old[2])/seconds or 0)
        local turnSpeed=old and seconds>0 and math.abs((angle-old[3]+math.pi)%tau-math.pi)/seconds or 0
        Turn(id,glyphBaselineAxis,angle,turnSpeed)
        previous[id]={depth,height,angle}
    end
    for i,wheel in ipairs(wheels) do
        for symbol,id in ipairs(wheel) do
            place(id,posLetters[allLetters[i]],tau*(symbol-1)/#wheel,0)
            ShowReg(id)
        end
    end
    local locked=0
    -- Six full free spins. Unfinished wheels keep rotating throughout every
    -- later stop; only the stopping wheel exchanges a rear symbol for its prize.
    for roll=1,6+#allLetters do
        local stopping=roll>6
        local seconds=0.6+0.3*locked/#allLetters
        local frames=math.max(6,math.floor(seconds*30/GetHologramTextFxSpeed()))
        -- An even count puts the hidden-to-final exchange exactly at the rear.
        frames=frames-frames%2
        local step=seconds/frames
        for frame=1,frames do
            local angle=tau*frame/frames
            for i=locked+1,#allLetters do
                local finalID=allLetters[i]
                local target=posLetters[finalID]
                local wheel=wheels[i]
                local landing=stopping and i==locked+1 and frame>=frames/2
                for symbol,id in ipairs(wheel) do
                    if not (landing and symbol==1) then
                        place(id,target,angle+tau*(symbol-1)/#wheel,step)
                    end
                end
                if landing then
                    if frame==frames/2 then
                        if wheel[1] then HideReg(wheel[1]) end
                        place(finalID,target,angle,0)
                        ShowReg(finalID)
                    else
                        place(finalID,target,angle,step)
                    end
                end
            end
            Sleep(step*1000)
        end
        if stopping then
            locked=locked+1
            hideTReg(wheels[locked])
            local id=allLetters[locked]
            -- Retire interpolated destinations before leaving the prize still.
            for axis=1,3 do
                Move(id,axis,posLetters[id][axis],1);Move(id,axis,posLetters[id][axis],0)
                Turn(id,axis,0,1);Turn(id,axis,0,0)
            end
        end
    end
    hardResetHologramLetters(borrowed)
    -- Lease exhausted repeated glyphs only after the reels have all stopped.
    holdHologramText(allLetters,posLetters,3000)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
end

-- A short cubic Bezier spline, sampled by arc length so glyphs keep a steady
-- pace through bends. Logical slots enter every 300 ms, including whitespace.
function splineShapeFollowing(allLetters, posLetters)
    if #allLetters == 0 then return end
    local origin = posLetters.slotPositions and posLetters.slotPositions[1] or posLetters[allLetters[1]]
    local spacing = math.max(sizeSpacingLetter,sizeDownLetter)*1.15
    local height = sizeDownLetter
    local function point(depth,along,rise)
        return {origin[1]+depth,origin[2]+along,origin[3]+rise}
    end
    local side = math.random(0,1)==0 and -1 or 1
    local controls = {
        point(0,3*spacing,2*height),
        point(side*spacing, -spacing, math.random(4,7)*height),
        point(-side*spacing, -9*spacing, math.random(0,2)*height),
        point(0,-13*spacing,2*height),
    }
    local samples,length = {},0
    for i=0,96 do
        local t=i/96;local u=1-t
        local p={}
        for axis=1,3 do
            p[axis]=u*u*u*controls[1][axis]+3*u*u*t*controls[2][axis]
                +3*u*t*t*controls[3][axis]+t*t*t*controls[4][axis]
        end
        if i>0 then
            local last=samples[#samples].p
            length=length+math.sqrt((p[1]-last[1])^2+(p[2]-last[2])^2+(p[3]-last[3])^2)
        end
        samples[#samples+1]={p=p,d=length}
    end
    local function sample(fraction)
        local distance=math.max(0,math.min(1,fraction))*length
        local lo,hi=1,#samples
        while hi-lo>1 do
            local mid=math.floor((lo+hi)/2)
            if samples[mid].d<distance then lo=mid else hi=mid end
        end
        local a,b=samples[lo],samples[hi]
        local blend=(distance-a.d)/math.max(1e-9,b.d-a.d)
        return {a.p[1]+(b.p[1]-a.p[1])*blend,
                a.p[2]+(b.p[2]-a.p[2])*blend,a.p[3]+(b.p[3]-a.p[3])*blend}
    end
    local step,delay=50,300
    local travel=math.min(12000,math.max(step,math.ceil(length/spacing*delay/step)*step))
    local slots=math.max(1,#(posLetters.spacing or allLetters))
    local duration=travel+(slots-1)*delay
    local current,lastPosition,leaseBeat={},{},{}
    hardResetHologramLetters(allLetters)
    StopSpin(textSpinner,textSpinnerAxis,0)
    for elapsed=0,duration-step,step do
        for index,id in ipairs(allLetters) do
            local leases=posLetters.leases and posLetters.leases[id]
                or {textSlot(posLetters,id,index-1)+1}
            local active={}
            for _,slot in ipairs(leases) do
                local age=elapsed-(slot-1)*delay
                if age>=0 and age<travel then active[#active+1]=slot end
            end
            local slot=current[id]
            local beat=math.floor(elapsed/150)
            local stillActive=false
            for _,candidate in ipairs(active) do if candidate==slot then stillActive=true end end
            if #active==0 then
                if slot then HideReg(id) end
                current[id]=nil
            else
                -- Exhausted meshes take turns at their active logical slots.
                -- Never move a still-visible piece across the intervening path.
                if not stillActive or leaseBeat[id]~=beat then
                    local nextSlot=active[1]
                    for _,candidate in ipairs(active) do
                        if candidate>(slot or 0) then nextSlot=candidate;break end
                    end
                    slot=nextSlot;leaseBeat[id]=beat
                end
                local age=elapsed-(slot-1)*delay
                if current[id]~=slot then
                    HideReg(id)
                    local start=sample(age/travel)
                    for axis=1,3 do Move(id,axis,start[axis],1);Move(id,axis,start[axis],0) end
                    lastPosition[id]=start
                    ShowReg(id)
                end
                local target=sample((age+step)/travel)
                for axis=1,3 do
                    Move(id,axis,target[axis],math.max(1e-6,math.abs(target[axis]-lastPosition[id][axis])/(step/1000)))
                end
                current[id],lastPosition[id]=slot,target
            end
        end
        Sleep(step)
    end
    hardResetHologramLetters(allLetters)
    restoreMessageOriginalPosition(allLetters,posLetters)
    if posLetters.spinnerSpeed then Spin(textSpinner,textSpinnerAxis,posLetters.spinnerSpeed,0) end
end

function getAllTextFx()
return {
        ["splineShapeFollowing"] = splineShapeFollowing,
        ["meteorCraterText"] = meteorCraterText,
        ["wallImpactText"] = wallImpactText,
        ["smilingFace"] = smilingFace,
        ["letterPlant"] = letterPlant,
        ["heartMonitor"] = heartMonitor,
        ["letterTornado"] = letterTornado,
        ["oneArmedBandit"] = oneArmedBandit,
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


        }
end
