--lib debug

function marker(String)
    if not GG.MarkerEnumeration then GG.MarkerEnumeration = {} end
    if not GG.MarkerEnumeration[String] then GG.MarkerEnumeration[String] = 0 end
    GG.MarkerEnumeration[String] = GG.MarkerEnumeration[String] + 1
    echo(String .. "::" .. GG.MarkerEnumeration[String])
end

function stats(...)
    local arg = arg;
    if (not arg) then
        arg = {...};
        arg.n = #arg
    end
    for i = 1, #arg, 2 do echo(arg[i] .. " is " .. toString(arg[i + 1])) end
end

function recursiveCheckTable(Tables, maxNrEntry, boolListEntryNr)
    local count = 0
    for key, entry in pairs(Tables) do
        local subElementCount = 0
        if key and entry and type(entry) == "table" then
            subElementCount  = recursiveCheckTable(entry, maxNrEntry, boolListEntryNr )
            if boolListEntryNr == true then 
                echo(key.." -> "..subElementCount.." entries")
            end
            assert(subElementCount < maxNrEntry, "Table key"..key.." violates entry limits: "..subElementCount.." > "..maxNrEntry)
            count = count + subElementCount
        elseif key and entry then
            count = count + 1
        end
        assert(count < maxNrEntry, "Total entry nr exceeds limits at"..key.." : "..count.." > "..maxNrEntry)     
    end
    return count
end

function recursiveGetTableSize(Tables)
    local size = 0
    for key, entry in pairs(Tables) do
        if key and type(entry) == "table" then
            subElementCount  = recursiveCheckTable(entry, maxNrEntry, boolListEntryNr )
            if boolListEntryNr then 
                echo(key.." -> "..subElementCount.." entries")
            end
            assert(subElementCount < maxNrEntry, "Table key"..key.." violates entry limits: "..subElementCount.." > "..maxNrEntry)
            count = count + subElementCount
        end
        assert(count < maxNrEntry, "Total entry nr exceeds limits at"..key.." : "..subElementCount.." > "..maxNrEntry)     
    end
    return count
end

function todoAssert(object, functionToPass, todoCheckNext)
    if functionToPass(object) == true then return end
    echo("Error:Todo:" .. todoCheckNext)
end

function assertTableExpectated(value, memberNameExpected, Dimension)
  assert(value, " no  table")
  assert(type(value) == "table", memberNameExpected.. " not a table")
  assert(value[memberNameExpected], memberNameExpected .. " no such table")
  assert(#value[memberNameExpected] == Dimension, memberNameExpected.. " below expected size")
end

function PieceLight(unitID, piecename, cegname, delayTime)
    delayTime = delayTime or 250
    while true do
        x, y, z = Spring.GetUnitPiecePosDir(unitID, piecename)
        Spring.SpawnCEG(cegname, x, y + 10, z, 0, 1, 0, 50, 0)
        Sleep(delayTime)
    end
end

function assertFunction(name)
    assert(type(name) == "function",
           "value of type " .. type(name) .. " is not a function")
end

function wrapThreadStart(func)
    assertFunction(func)
    StartThread(func)

end

-- > Prints a 3dLine
function printLine(PosA, PosB, cegname, steps )
    local SpawnCeg = Spring.SpawnCEG
    for i=1, 100, 100/steps do
        MidPos = mixTable(PosA, PosB, i/100)
        SpawnCeg(cegname, MidPos.x, MidPos.y, MidPos.z,0, 1, 0, 50, 0)
    end
end

-- >allows for a script breakpoint via widget :TODO incomplete
function stopScript(name)
    lib_boolOnce = false
    while true do
        Sleep(3000)
        if lib_boolOnce == false then
            lib_boolOnce = true
            Spring.Echo("Script at " .. name .. " has stopped")
        end
    end
end

-- > testUnit for existance - Debugfunction
function testUnit(unitid)
    if not unitid then
        echo("TestUnit no unitid given to testUnit()");
        return
    end
    echo("UnitTested")
    if type(unitid) ~= "number" then
        echo("unitid is not a number-type is " .. type(unitid) ..
                 " with value: " .. unitid);
        return
    end

    validUnit = Spring.ValidUnitID(unitid)
    if validUnit and validUnit == true then
        echo("U" .. unitid .. " :unitid is valid")
    else
        echo("U" .. unitid .. " :unitid is invalid")
        return
    end
    isAlive = Spring.GetUnitIsDead(unitid)
    if isAlive and isAlive == true then
        echo("U" .. unitid .. ":unitid is alive")
    else
        echo("U" .. unitid .. ":unitid is dead")
        return
    end
end

function HideWrap(piecenr)
    if lib_boolDebug == true then
        if type(piecenr) == "string" then
            Spring.Echo("Hide did get a string.." .. piecenr);
            assert(true == false);
        end
        if type(piecenr) == "table" then
            Spring.Echo("PieceNr in hide is a table");
            -- echoT(piecenr)
            assert(true == false);
        end

        if type(piecenr) == "number" then
            PieceMap = Spring.GetUnitPieceList(unitID)
            if not PieceMap[piecenr] then
                Spring.Echo("Piece not a valid Nr" .. piecenr)
                return
            end
            Hide(piecenr)
        end
    else
        Hide(piecenr)
    end
end

function blinkPiece(pieceID, timeTotal, timeInterval)
    for i=0, timeTotal, timeInterval*2 do
        Show(pieceID)
        Sleep(timeInterval)
        Hide(pieceID)
        Sleep(timeInterval)
    end
end


function ShowWrap(piecenr)
    if lib_boolDebug == true then
        if type(piecenr) == "string" then
            Spring.Echo("Hide did get a string.." .. piecenr);
            assert(true == false);
        end
        if type(piecenr) == "table" then
            Spring.Echo("PieceNr in hide is a table");
            -- echoT(piecenr)
            assert(true == false);
        end

        if type(piecenr) == "number" then
            PieceMap = Spring.GetUnitPieceList(unitID)
            if not PieceMap[piecenr] then
                Spring.Echo("Piece not a valid Nr" .. piecenr)
                return
            end
            Hide(piecenr)
        end
    else
        Hide(piecenr)
    end
end

-- > asserts all Elements in Table are of Type
function assertTableType(T, Type)
    for k, v in pairs(T) do
        if type(v) ~= Type then
            Spring.Echo(
                "assertTypeTable::Error: Key " .. k .. " not of type " .. Type ..
                    " got " .. type(v) .. "instead")
            assert(true == false)
        end
    end
end

function killYourselfIfUnitCeases(unitID, testID)
    if doesUnitExistAlive(testID) then Spring.DestroyUnit(unitID, true, true) end
end

-- > checks wether a number value is nan
function isNaN(value) return (value ~= value) end

function assertUnit(id)
    if (Spring.ValidUnitID(id) == true) then
        return
    else
        assert(true == false)
    end
end

function assertAxis(axis)
    axisT = {[1] = true, [2] = true, [3] = true}
    if axisT[axis] then
        return
    else
        assert(true == false)
    end
end

function assertAlive(id)
    if (Spring.GetUnitIsDead(id) == false) then
        return
    else
        assert(true == false)
    end
end
function assertBool(val, message) assert(type(val) == "boolean", message) end

function assertStr(val, message) assert(type(val) == "string", message) end

function assertNum(val, message) assert(type(val) == "number", message) end

function assertTableNotNil(Table)
    for k, v in pairs(Table) do
        if not v then
            echo("asserTable has key " .. k .. " without a value")
        else
            typeV = type(v)
            if typeV == "table" then asserTable(v); end
        end
    end
end

-- expects dimensions and a comperator function or value/string/object={membername= expectedtype}--expects dimensions and a comperator function or value/string/object={membername= expectedtype}
function assertT(ExampleTable, checkTable, checkFunctionTable)

    if type(arg) == "number" then
        echo("assertT:: Not a valid table- recived number " .. arg);
        return false
    end

    for key, value in pairs(ExampleTable) do
        if checkTable[key] then
            valueType = type(value)

            if valueType == "table" then
                if (assertT(value, checkTable[key], checkFunctionTable[key]) ==
                    false) then
                    echo("Assert Table Error: Table " .. value ..
                             " did not contain wellformed subtable for key " ..
                             key)
                    return false
                end
            end

            if checkTable[key] ~= valueType then
                echo("Error: Wrong Type found for key " .. key .. ". Type " ..
                         valueType .. " expected, got " .. type(checkTable[key]) ..
                         " instead ")
            else -- valid type - lets check the value for correctness
                if checkFunctionTable[key] then
                    if checkFunctionTable[key](value) == false then
                        echo( "Error: Value is not fullfilling condition function")
                        return false
                    end
                    return true
                end
                return true
            end
        else

            echo("Assert Table Error: Table " .. value ..
                     " did not contain a value for key :" .. key)
            return false
        end
    end
end

function signalAll(limitUpper) for i = 0, limitUpper do Signal(2 ^ i) end end

function getSizeInByte(Element, maxdepth)
    maxdepth = maxdepth or 12
    if maxdepth == 0 then return 1 end

    typeSize = {
        ["table"] = function(id, maxdep)
            accumulatedSize = 0
            for k, v in pairs(id) do
                accumulatedSize = accumulatedSize + getSizeInByte(k, maxdep) +
                                      getSizeInByte(v, maxdep)
            end
            return accumulatedSize
        end,
        ["number"] = function(id) return 8 end,
        ["boolean"] = function(id) return 1 end,
        ["string"] = function(id) return string.len(id) end,
        ["function"] = function(id) return 1 end--string.len(string.dump(id)) end -- Problematic: Function as string is compactor in opcode and exists only once per name)
    }

    if not Element then return 0 end
    elementType = type(Element)
    if not typeSize[elementType] then
        echo("Undefined type with" .. elementType .. " at ", Element);
        assert(true == false)
    end
    return typeSize[elementType](Element, maxdepth - 1)
end

-- >prints a numeric table in steps
function printT(tab, size, step)
    maxdigit = getDigits(tab[size / 2][size / 2])
    step = step or (size / 12)
    Spring.Echo(stringBuilder(size, "_") .. "\n")
    for i = 1, size, step do
        seperator = "|"
        str = ""

        for j = 1, size, step do
            str = str .. seperator ..
                      math.floor(tab[math.ceil(i)][math.ceil(j)])
            if getDigits(math.floor(tab[math.ceil(i)][math.ceil(j)])) < maxdigit then
                for i = 1, maxdigit -
                    getDigits(math.floor(tab[math.ceil(i)][math.ceil(j)])), 1 do
                    str = str .. " "
                end
            end
        end
        Spring.Echo(str)
    end
    Spring.Echo(stringBuilder(size, "_") .. "\n")
end

-- > Takes a line of code and displays it with values
function Debug(LineOfCode)
    tokkens = stringSplit(LineOfCode)
    conCatResult = ""
    local langKeyWords = {
        ["and"] = true,
        ["break"] = true,
        ["do"] = true,
        ["else"] = true,
        ["elseif"] = true,
        ["end"] = true,
        ["false"] = true,
        ["for"] = true,
        ["function"] = true,
        ["if"] = true,
        ["in"] = true,
        ["local"] = true,
        ["nil"] = true,
        ["not"] = true,
        ["or"] = true,
        ["repeat"] = true,
        ["return"] = true,
        ["then"] = true,
        ["true"] = true,
        ["until"] = true,
        ["while"] = true,
        [">"] = true,
        ["<"] = true,
        [">="] = true,
        ["<="] = true,
        ["=="] = true,
        ["=~"] = true,
        ["+"] = true,
        ["-"] = true,
        ["/"] = true,
        ["*"] = true,
        ["%"] = true,
        ["]"] = true,
        ["["] = true,
        [")"] = true,
        ["("] = true
    }

    for i = 1, #tokkens do
        local tokken = tokkens[i]
        if langKeyWords[tokken] then
            conCatResult = conCatResult .. " " .. tokken
        else
            local evaluateTokkenFunction = loadstring(tokken)
            if evaluateTokkenFunction then
                conCatResult = conCatResult .. " " .. tokken .. ":" ..
                                   evaluateTokkenFunction()
            end
        end
    end
    echo(conCatResult)
end

-- >Generate a Description Text for a Unit
function unitDescriptionGenerator(Unit, UnitDefNames)
    local ud = UnitDefNames[Unit]
    stringBuilder = ""
    lB = "\n"

    function unitDefToStr(ud)
        str = "normal"
        if ud.reclaimable == true then str = str .. ", reclaimable" end
        if ud.capturable == true then str = str .. ", capturable" end
        if ud.repairable == true then str = str .. ", repairable" end
        return str
    end

    function reStr(val, str1, str2)
        str2 = str2 or ""
        if str2 ~= "" then str2 = str2 .. lB end

        if not val then return str1 .. lB end
        return str2
    end

    function cStr(bool, str, alt)
        alt = alt or ""
        if alt ~= "" then alt = alt .. lB end

        if bool and bool == true then
            return str .. lB
        else
            return alt
        end
        return ""
    end

    utype = generateTypeString(ud)
    ud.utype = generateTypeString(ud)
    Uname = trim(string.lower(name))
    ud.Uname = string.upper(string.sub(Uname, 1, 2)) ..
                   string.sub(Uname, 2, #Uname)
    ud.lB = lB
    ud.ustatus = generateStatusString(ud)
    stringBuilder = {}

    stringBuilder[#stringBuilder + 1] =
        "" .. "=== Unit: " .. ud.name .. " ===" .. ud.lB .. "The unit " ..
            ud.name .. " is a " .. ud.utype .. " unit." ..
            "Internally also described as " .. ud.description .. ", the " ..
            ud.name .. " has " .. ud.maxDamage .. " Hitpoints." .. "To build a " ..
            ud.name .. " costs " .. ud.buildCostMetal .. " metal and " ..
            ud.buildCostEnergy .. " energy." .. "The " .. ud.name .. " is a " ..
            ud.ustatus .. " unit." .. reStr(ud.harvestStorage,
                                            "This harvester can store " ..
                                                ud.harvestStorage ..
                                                " in internal holds.") ..
            reStr(ud.metalStorage,
                  "The " .. ud.name .. "s storage contributes " ..
                      ud.metalStorage .. " to the teams metal storage.") ..
            reStr(ud.metalStorage,
                  "The " .. ud.name .. "s storage contributes " ..
                      ud.energyStorage .. " to the teams energy storage.") ..
            reStr(ud.extractsMetal, "The " .. ud.name .. " extracts " ..
                      ud.extractsMetal .. " from the ground.") ..
            reStr(ud.windGenerator,
                  "It is able to convert gas-currents into energy at a rate of " ..
                      ud.windGenerator) .. reStr(ud.tidalGenerator,
                                                 "Tidal forces can be converted to energy up too " ..
                                                     ud.tidalGenerator ..
                                                     " per Unit.") ..
            reStr(ud.metalUse,
                  "The unit uses up to " .. ud.metalUse .. " metal.") ..
            reStr(ud.metalUpkeep,
                  metalUpkeep .. " is used once the" .. ud.name ..
                      " is activated.") .. reStr(ud.energyUse,
                                                 energyUse ..
                                                     " units of energy are used once the" ..
                                                     ud.name .. " is activated.") ..
            reStr(ud.metalMake,
                  " The " .. ud.name .. " generates " .. ud.metalMake ..
                      " uncoditionally every gametick.") .. reStr(ud.energyMake,
                                                                  " Further the " ..
                                                                      ud.name ..
                                                                      " is constantly generating " ..
                                                                      ud.energyMake ..
                                                                      " of energy.") ..
            reStr(ud.makesMetal,
                  " In Addition the " .. ud.name .. " cpmverts " ..
                      ud.makesMetal .. " units of energy into metal.") ..
            reStr(ud.onOffable,
                  "A " .. ud.name .. " special abilitys can " ..
                      trueStr(onOffable) ..
                      " be toggled via GUI. By default the special Ability is " ..
                      trueStr(activateWhenBuilt) .. " active.")
    stringBuilder[#stringBuilder + 1] = "" .. reStr(ud.sightDistance,
                                                    "The " .. ud.name ..
                                                        " can, depending on terrain, see as far as " ..
                                                        ud.sightDistance ..
                                                        " at day and night.") ..
                                            reStr(ud.airSightDistance,
                                                  "The " .. ud.name ..
                                                      " can set Air Units as far as " ..
                                                      ud.airSightDistance .. ".") ..
                                            reStr(ud.losEmitHeight, "" ..
                                                      ud.name ..
                                                      " viewpoint is " ..
                                                      ud.losEmitHeight ..
                                                      " over ground.") ..
                                            reStr(ud.radarEmitHeight,
                                                  " Radar is emitted at " ..
                                                      ud.radarEmitHeight ..
                                                      " over ground with a distance of " ..
                                                      ud.radarDistance ..
                                                      "by the " .. ud.name) ..
                                            reStr(ud.radarDistanceJam,
                                                  " Radar is jammed in a range of " ..
                                                      ud.radarDistanceJam ..
                                                      " elmos.") ..
                                            reStr(ud.sonarDistance,
                                                  "" .. ud.name ..
                                                      " detects Submarines/Ships in a Range of " ..
                                                      ud.sonarDistance ..
                                                      " around itself.") ..
                                            reStr(ud.sonarDistanceJam,
                                                  " Other ships sonar is d Submarines/Ships in a Range of " ..
                                                      ud.sonarDistance ..
                                                      " around itself.") ..
                                            reStr(ud.stealth,
                                                  "The " .. ud.name ..
                                                      " s a stealth unit.") ..
                                            reStr(ud.sonarStealth,
                                                  "Capable of hidding from Sonarunits.") ..
                                            reStr(ud.seismicDistance,
                                                  "And able to detect enemys via seismic Signatures at a distance of " ..
                                                      ud.seismicDistance .. " .") ..
                                            reStr(ud.seismicSignature,
                                                  "The " .. ud.name ..
                                                      " itself emits a seismic signature detectable up to " ..
                                                      ud.seismicSignature * 15 ..
                                                      " elmos.") ..
                                            reStr(ud.canCloak,
                                                  "The " .. ud.name ..
                                                      " is clokable with costs of " ..
                                                      ud.cloakCost ..
                                                      " per second to uphold and " ..
                                                      reStr(ud.cloakCostMoving,
                                                            " and additional costs of " ..
                                                                ud.cloakCostMoving ..
                                                                " while moving." ..
                                                                reStr(
                                                                    ud.initCloaked,
                                                                    " The " ..
                                                                        ud.name ..
                                                                        " is cloaked from the start."))) ..
                                            reStr(ud.canCloak,
                                                  "The " .. ud.name ..
                                                      " is clokable with costs of " ..
                                                      ud.cloakCost ..
                                                      " per second to uphold and " ..
                                                      reStr(ud.cloakCostMoving,
                                                            " and additional costs of " ..
                                                                ud.cloakCostMoving ..
                                                                " while moving." ..
                                                                reStr(
                                                                    ud.initCloaked,
                                                                    " The " ..
                                                                        ud.name ..
                                                                        " is cloaked from the start."))) ..
                                            reStr(ud.decloakOnFire,
                                                  "If the " .. ud.name ..
                                                      " fires its weapon, it will " ..
                                                      trueStr(ud.decloakOnFire) ..
                                                      "decloak.")
    stringBuilder[#stringBuilder + 1] = "" .. reStr(ud.cloakTimeout,
                                                    "To recloak the " .. ud.name ..
                                                        " will have to wait for " ..
                                                        ud.cloakTimeout ..
                                                        " seconds.") ..
                                            "Among the commands for the Unit are" ..
                                            cStr(ud.canMove, " move,") ..
                                            cStr(ud.canAttack, " attack,") ..
                                            cStr(ud.canFight, " fight,") ..
                                            cStr(ud.canPatrol, " patrol,") ..
                                            cStr(ud.canGuard, " guard,") ..
                                            cStr(ud.canCloak, " cloak,") ..
                                            " and " ..
                                            cStr(ud.canRepeat, " repeat ") ..
                                            "." .. "In Addition the " .. ud.name ..
                                            " can be orders to " ..
                                            cStr(ud.canSelfDestruct,
                                                 " selfdestruct,") ..
                                            cStr(ud.moveState ~= -1,
                                                 " switch between move states,") ..
                                            cStr(ud.noAutoFire,
                                                 " switch between the fire state,") ..
                                            cStr(ud.fireState ~= -1, " with " ..
                                                     ud.fireState ..
                                                     " as default ") ..
                                            cStr(ud.canManualFire,
                                                 " and the order to manfual fire ") ..
                                            "." ..
                                            cStr(ud.builder, name ..
                                                     " is a builder that can be orders to ") ..
                                            cStr(ud.canRestore, " restore ") ..
                                            cStr(ud.canRepair, " repair ") ..
                                            cStr(ud.canReclaim, " relcaim") ..
                                            cStr(ud.canResurrect,
                                                 " and ressurect ") ..
                                            cStr(ud.canCapture, " or capture. ") ..
                                            "other units." .. "The " .. ud.name ..
                                            " can built up to a distance of " ..
                                            cStr(ud.buildDistance) .. " away " ..
                                            cStr(ud.buildRange3D, "in 3D") ..
                                            "." .. cStr(ud.workerTime > 0,
                                                        " A busy little beaver,the " ..
                                                            ud.name ..
                                                            " has a workerTime of: " ..
                                                            ud.workerTime ..
                                                            " .") ..
                                            cStr(ud.repairSpeed > 0,
                                                 ud.Uname ..
                                                     " can repair its companions with a rate of " ..
                                                     ud.repairSpeed .. " .") ..
                                            cStr(ud.reclaimSpeed > 0,
                                                 "Hungry as a " .. ud.name ..
                                                     " as they say, this unit can consume at a rate of " ..
                                                     ud.reclaimSpeed ..
                                                     " what remained of the maimed.") ..
                                            cStr(ud.resurrectSpeed > 0,
                                                 "With a resurectionSpeed of " ..
                                                     ud.resurrectSpeed ..
                                                     " the " .. ud.name ..
                                                     " is a great pal to be around, when disaster strikes.") ..
                                            cStr(ud.captureSpeed > 0,
                                                 "With a capture Speed of " ..
                                                     ud.captureSpeed .. " the " ..
                                                     ud.name ..
                                                     " is able to turn envitorys.") ..
                                            cStr(ud.terraformSpeed > 0,
                                                 ud.Uname ..
                                                     "s are great scapers of land with a terraformSpeed of " ..
                                                     ud.terraformSpeed .. ".")
    stringBuilder[#stringBuilder + 1] = "" .. cStr(ud.canAssist, ud.Uname ..
                                                       "s will help guarded units to archieve there build targets.") ..
                                            cStr(ud.canBeAssisted, ud.Uname ..
                                                     "s can accept help from other builders.") ..
                                            cStr(ud.canSelfRepair,
                                                 "Help thyself, so good shall help, seems to be " ..
                                                     ud.Uname ..
                                                     "s family motto.") ..
                                            cStr(ud.showNanoSpray,
                                                 "During the buildforeach- nanospray might be visible.") ..
                                            cStr(ud.levelGround,
                                                 "To start construction, the ground has to be leveld for a " ..
                                                     ud.name .. ".") ..
                                            cStr(ud.fullHealthFactory,
                                                 ud.Uname ..
                                                     " is a full health factory, nothing leaves Nanos-kitchen, before it is not 100 % fit.",
                                                 ud.Uname ..
                                                     " is a normal factory shipping in various stages of disrepair.") ..
                                            cStr(ud.isAirbase, ud.Uname ..
                                                     " In Addition serves as a airbase for air Units.") ..
                                            cStr(ud.isAirbase, ud.Uname ..
                                                     " In Addition serves as a airbase for air Units.") ..
                                            lB .. "The " .. ud.Uname ..
                                            " has a Footprint of " .. ud.footprX ..
                                            " in X and " .. ud.footprZ ..
                                            " in Z." .. cStr(ud.movementClass,
                                                             "The " .. ud.Uname ..
                                                                 " is of the following movement class :" ..
                                                                 ud.movementClass ..
                                                                 ". ") ..
                                            cStr(ud.canHover,
                                                 ud.Uname .. "s can hover.") ..
                                            cStr(ud.floater, ud.Uname ..
                                                     "s is floating on the surface.",
                                                 ud.Uname ..
                                                     "s craw along the seafloor.") ..
                                            cStr(ud.upright, ud.Uname ..
                                                     "s is a upright walker with a maxslope of " ..
                                                     ud.maxSlope, ud.Uname ..
                                                     " is a ground hugger with a maxslope of " ..
                                                     ud.maxSlope) ..
                                            cStr(ud.minWaterDepth,
                                                 "The " .. ud.Uname ..
                                                     " needs at least a waterdepth of " ..
                                                     ud.minWaterDepth .. ".") ..
                                            cStr(ud.maxWaterDepth,
                                                 "The " .. ud.Uname ..
                                                     " needs at least a waterdepth of " ..
                                                     ud.minWaterDepth .. ".") ..
                                            cStr(ud.waterline > 0.0, "A " ..
                                                     ud.name .. " is " ..
                                                     ud.waterline ..
                                                     " submerged beneath the waves.") ..
                                            cStr(ud.minCollisionSpeed,
                                                 "When at " ..
                                                     ud.minCollisionSpeed ..
                                                     " the " .. ud.name ..
                                                     " will suffer damage on collission.") ..
                                            cStr(ud.pushResistant,
                                                 "This unit is pushed around.",
                                                 "This unit is push resistant.")
    stringBuilder[#stringBuilder + 1] = "" .. cStr(ud.maxVelocity > 0.0,
                                                   ud.Uname ..
                                                       "s maximum speed is " ..
                                                       ud.maxVelocity ..
                                                       " attained at " ..
                                                       cStr(ud.acceleration > 0,
                                                            acceleration)) ..
                                            cStr(ud.maxReverseVelocity > 0.0,
                                                 "The reverse velocity is" ..
                                                     ud.maxReverseVelocity) ..
                                            cStr(ud.brakeRate,
                                                 "The " .. ud.name ..
                                                     " brakes with a rate of " ..
                                                     ud.brakeRate .. ".") ..
                                            cStr(ud.myGravity,
                                                 "As a aircraft-unit the " ..
                                                     ud.name ..
                                                     " has a custom gravity of " ..
                                                     ud.myGravity) ..
                                            cStr(ud.turnRate,
                                                 ud.Uname .. " turns " ..
                                                     cStr(ud.turnInPlace,
                                                          " in place ") ..
                                                     "with a speed of " ..
                                                     ud.turnRate ..
                                                     " degrees per second") ..
                                            cStr(ud.turnInPlaceSpeedLimit,
                                                 "When turning in place the " ..
                                                     ud.name ..
                                                     " is bound by a speedlimit of " ..
                                                     ud.turnInPlaceSpeedLimit ..
                                                     ".") ..
                                            cStr(ud.turnInPlaceAngleLimit,
                                                 "It can bank during turn by " ..
                                                     ud.turnInPlaceAngleLimit ..
                                                     " degrees.") ..
                                            cStr(ud.blocking,
                                                 "The " .. ud.Uname ..
                                                     " blocks the movement of other Units.") ..
                                            cStr(ud.crushResistance,
                                                 "Crush resistant up to" ..
                                                     ud.curshResistance .. ".") ..
                                            cStr(ud.myGravity,
                                                 "As a aircraft-unit the " ..
                                                     ud.name ..
                                                     " has a custom gravity of " ..
                                                     ud.myGravity) ..
                                            cStr(ud.blocking,
                                                 "The " .. ud.Uname ..
                                                     " blocks the movement of other Units.") ..
                                            cStr(ud.Flanking,
                                                 "When Flanking the " .. ud.name ..
                                                     "s bonus is " ..
                                                     ud.selStr(Flanking, {
                "no flanking bonus",
                "a build up of the ability to move over time, and swings to face attacks",
                "also can swing, but moves with the unit as it turns",
                "stays with the unit as it turns and otherwise doesn't move"
            })) .. cStr(ud.flankingBonusMax,
                        "The Bonus applied to the armor main direction is " ..
                            ud.flankingBonusMax) .. cStr(ud.flankingBonusMin,
                                                         "The Bonus applied to the armor minimal directions is " ..
                                                             ud.flankingBonusMin) ..
                                            cStr(ud.canFly,
                                                 ud.Uname .. " is a aircraft.") ..
                                            cStr(ud.canSubmerge, ud.Uname ..
                                                     " can submerge itself beneath water.") ..
                                            cStr(ud.factoryHeadingTakeoff,
                                                 ud.Uname ..
                                                     " will lift off from a runway.",
                                                 Uname ..
                                                     " will lift off straigth up - VTOL style.") ..
                                            cStr(ud.collide,
                                                 "The " .. ud.name ..
                                                     " will collide with air-units.",
                                                 "The " .. ud.name ..
                                                     " has collission turned off.") ..
                                            cStr(ud.hoverAttack,
                                                 "Enemys will be attacked while attacked hovering in place by " ..
                                                     ud.name .. ".",
                                                 "Enemys will be attacked with approach and flight over by " ..
                                                     ud.name .. ".") ..
                                            cStr(
                                                ud.airStrafe and ud.hoverAttack,
                                                "Enemy fire is avoided with strafing motion")
    stringBuilder[#stringBuilder + 1] = "" .. cStr(ud.cruiseAlt,
                                                   "Default cruise height is " ..
                                                       ud.cruiseAlt ..
                                                       " in elmos for the " ..
                                                       ud.name .. ".") ..
                                            cStr(ud.airHoverFactor < 0,
                                                 "It is capable of landing.",
                                                 "It will hover on the spot moving about " ..
                                                     ud.airHoverFactor .. ".") ..
                                            cStr(ud.bankingAllowed,
                                                 "When turning the unit banks.",
                                                 "It cant bank worth a damn.") ..
                                            cStr(ud.maxBank, "At max the " ..
                                                     ud.name .. " will bank by " ..
                                                     ud.maxBank) ..
                                            cStr(ud.maxPitch,
                                                 "The maxpitch before loosing lift is " ..
                                                     ud.maxPitch .. " .") ..
                                            cStr(ud.useSmoothMesh, "The " ..
                                                     ud.name ..
                                                     " follows a smooth out heigthmap during fleigth.",
                                                 "The " .. ud.name ..
                                                     " uses the actual heigthmap to navigate.") ..
                                            cStr(ud.maxFuel,
                                                 "The " .. ud.name ..
                                                     " has a muxfuel of " ..
                                                     ud.maxFuel) ..
                                            cStr(ud.refuelTime, "It takes " ..
                                                     ud.refuelTime ..
                                                     " seconds to fill this baby up - with fuel.") ..
                                            cStr(ud.canLoopbackAttack, "A " ..
                                                     ud.name ..
                                                     " can perform a Immelmann turn.") ..
                                            cStr(ud.wingDrag,
                                                 "The wings of " .. ud.name ..
                                                     " have a drag due to the wingdrag of " ..
                                                     ud.wingDrag .. ".") ..
                                            cStr(ud.wingAngle,
                                                 "The wings of " .. ud.name ..
                                                     " have a angle of" ..
                                                     ud.wingAngle .. ".") ..
                                            cStr(ud.frontToSpeed,
                                                 ud.Uname ..
                                                     "s lineup speed and front of plane with a speed of" ..
                                                     ud.frontToSpeed) ..
                                            cStr(ud.crashDrag,
                                                 ud.Uname ..
                                                     "s have a air-resistance of " ..
                                                     ud.crashDrag ..
                                                     " when going down for good.") ..
                                            cStr(ud.turnRadius,
                                                 "The unit has a turnradius of " ..
                                                     ud.turnRadius ..
                                                     " in elmo.") ..
                                            cStr(ud.verticalSpeed,
                                                 "The " .. ud.name ..
                                                     " has a vertical speed of " ..
                                                     ud.verticalSpeed ..
                                                     " taking off.") ..
                                            cStr(ud.maxAileron,
                                                 "Z-Axis turnspeed maximum of a " ..
                                                     ud.name .. " is " ..
                                                     ud.maxAileron .. ".") ..
                                            cStr(ud.maxElevator,
                                                 "Y-Axis turnspeed maximum of a " ..
                                                     ud.name .. " is " ..
                                                     ud.maxAileron .. ".") ..
                                            cStr(ud.maxRudder,
                                                 "X-Axis turnspeed maximum of a " ..
                                                     ud.name .. " is " ..
                                                     ud.maxAileron .. ".") ..
                                            cStr(ud.maxAcc,
                                                 "The maximum Acceleration of a " ..
                                                     ud.name .. " aircraft.") ..
                                            cStr(ud.Flares,
                                                 "Under fire by rockets, the " ..
                                                     ud.name .. " drops flares.") ..
                                            cStr(ud.flareReload,
                                                 "Reloading these flares costs " ..
                                                     ud.flareReload ..
                                                     " seconds time.") ..
                                            cStr(ud.flareDelay,
                                                 " Fired flares are delayed by a factor of " ..
                                                     ud.flareDelay ..
                                                     " * random(1,16).") ..
                                            cStr(ud.flareEfficiency,
                                                 " Enemy missiles will be distracted by the flare with a chance of " ..
                                                     ud.flareEfficiency .. ".")
    stringBuilder[#stringBuilder + 1] = "" .. cStr(ud.lifetime,
                                                   " A dropped flare will burn for " ..
                                                       (ud.flareTime / 30) ..
                                                       " seconds.") ..
                                            cStr(ud.flareSalvoSize,
                                                 " One salvo contains " ..
                                                     ud.flareSalvoSize ..
                                                     " flares.") ..
                                            cStr(ud.flareSalvoDelay,
                                                 " Each flare of a salvo is delayed by " ..
                                                     (ud.flareSalvoDelay / 30) ..
                                                     " seconds.") ..
                                            cStr(ud.transportSize > 0,
                                                 ud.Uname .. " can carry up to " ..
                                                     ud.transportSize ..
                                                     " passengers.") ..
                                            cStr(
                                                ud.mransportSize and
                                                    ud.transportCapacity,
                                                "Any picked up unit, must be between " ..
                                                    ud.mransportSize .. " and " ..
                                                    ud.transportCapacity /
                                                    ud.transportSize) ..
                                            cStr(
                                                ud.mransportMass and
                                                    ud.transportMass,
                                                "Any picked up mass, must be between " ..
                                                    ud.mransportMass .. " and " ..
                                                    ud.transportMass) ..
                                            cStr(ud.loadingRadius,
                                                 "A " .. ud.name ..
                                                     " will load in a radius of " ..
                                                     ud.loadingRadius ..
                                                     " around itself.") ..
                                            cStr(ud.unloadSpread,
                                                 "When the passengers are unloaded a distance of" ..
                                                     ud.unloadSpread ..
                                                     " times passengersize is kept.") ..
                                            cStr(ud.isFirePlatform,
                                                 " All loaded units can fire on there designated targets from there docking position.") ..
                                            cStr(ud.holdSteady,
                                                 "Passengerdirection is slaved to the transport piece.",
                                                 "Passengerdirection is slaved to the transport direction.") ..
                                            cStr(ud.releaseHeld,
                                                 "On death the " .. ud.name ..
                                                     " releases its transported units.",
                                                 "On death the " .. ud.name ..
                                                     " makes the final ferryman for its passengers.") ..
                                            cStr(ud.transportByEnemy,
                                                 ud.Uname ..
                                                     "s regularly are refused transportation service for non-discrimination reasons.") ..
                                            cStr(ud.cantBeTransported,
                                                 ud.Uname ..
                                                     "s can be taken for a ride by enemy transport.") ..
                                            selStr(ud.transportUnloadMethod, {
            [0] = " Land to unload individually",
            [1] = "Flyover drop (i.e. Parachute)",
            [2] = "Land and flood unload all passengers."
        }) .. cStr(ud.fallSpeed,
                   "Deployed Paratroopers will fall with a speed of " ..
                       ud.fallSpeed) .. cStr(ud.category, "The " .. ud.name ..
                                                 " belongs to the following categories:" ..
                                                 ud.category) ..
                                            cStr(ud.noChaseCategory,
                                                 "It will not chase targets of category: " ..
                                                     ud.noChaseCategory .. ".") ..
                                            cStr(ud.leaveTracks,
                                                 "Recognizeable tracks called " ..
                                                     ud.trackType ..
                                                     " show wherever " ..
                                                     ud.name .. " went.") ..
                                            cStr(
                                                ud.trackWidth and ud.trackOffset,
                                                "Said tracks are " ..
                                                    ud.trackWidth ..
                                                    " in width and " ..
                                                    ud.trackOffset ..
                                                    " in length.") ..
                                            cStr(ud.trackStrength,
                                                 "Tracks will be " ..
                                                     ud.trackStrength ..
                                                     " persistent and visible.") ..
                                            cStr(
                                                ud.useBuildingGroundDecal ~= nil and
                                                    ud.buildingGroundDecalType ~=
                                                    nil, Uname ..
                                                    "s have a Grounddecal called: " ..
                                                    ud.buildingGroundDecalType) ..
                                            cStr(ud.buildingGroundDecalSizeX,
                                                 "This Grounddecal is " ..
                                                     ud.buildingGroundDecalSizeX ..
                                                     " x " ..
                                                     ud.buildingGroundDecalSizeY ..
                                                     " in size and decays with a factor of " ..
                                                     ud.buildingGroundDecalDecaySpeed)
    stringBuilder[#stringBuilder + 1] = "" .. cStr(ud.highTrajectory,
                                                   "Trajectory weapons are fired in " ..
                                                       selStr(ud.highTrajectory,
                                                              {
            [0] = "a high trajectory.",
            [1] = " a low trajectory.",
            [2] = "in the user selected mode (high/low)."
        })) .. cStr(ud.kamikaze, " Good to know is also, that " .. ud.name ..
                        "is a kamikaze unit, sacrificing it all for the greater good.") ..
                                            cStr(ud.kamikazeDistance,
                                                 "To get to heaven, a " ..
                                                     ud.name ..
                                                     " needs to get as close as " ..
                                                     ud.kamikazeDistance ..
                                                     " virgins, side by side.") ..
                                            cStr(ud.kamikaze,
                                                 cStr(ud.kamikazeUseLOS,
                                                      "Only eye-contact prevents a kamikaze attack from beeing perceived as impersonal.",
                                                      "Shrapnell contact for a first kamikaze impression is close enough.")) ..
                                            cStr(ud.strafeToAttack,
                                                 "When not finding the target in range, a " ..
                                                     ud.name ..
                                                     " will move until it is.") ..
                                            cStr(ud.selfDestructCountdown,
                                                 ud.selfDestructCountdown ..
                                                     " seconds is all it takes before a " ..
                                                     ud.name ..
                                                     " self-destructs once the command has been issued.") ..
                                            cStr(ud.decoyFor, Uname ..
                                                     " is a decoy for " ..
                                                     UnitDefs[ud.decoyFor].name ..
                                                     ".") ..
                                            cSTr(ud.damageModifier,
                                                 "Should the " .. ud.name ..
                                                     " raise its amour, a modifier of " ..
                                                     ud.damageModifier ..
                                                     " is applied to all recived damage.") ..
                                            cStr(ud.isTargetingUpgrade,
                                                 ud.Uname ..
                                                     " is a targetting facility, enhancing other units out-of-los accuracy.") ..
                                            cStr(ud.isFeature,
                                                 " This unit turns into a feature upon creation.") ..
                                            cStr(ud.hideDamage, " Damage a " ..
                                                     ud.name ..
                                                     " recives is hidden from the enemys eyes.") ..
                                            cStr(ud.showPlayerName, "The " ..
                                                     ud.name ..
                                                     " is the players avatara.") ..
                                            cStr(ud.showNanoFrame,
                                                 " During the buildforeach a classic OTA Nanoframe is shown") ..
                                            cStr(ud.unitRestricted,
                                                 " The Unit " .. ud.name ..
                                                     " is restricted to maximal " ..
                                                     ud.unitRestricted ..
                                                     " total.") ..
                                            cStr(ud.power, ud.Uname ..
                                                     ": This unit relative power is " ..
                                                     ud.power .. ".")
    OfTheString = ""
    for i = 1, #stringBuilder do
        OfTheString = OfTheString .. stringBuilder[i]
    end

    return OfTheString
end
