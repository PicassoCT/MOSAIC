
-- TODO: fix parting Code for 16 pieces -- also distribute maploading over same period --integrate mapparts created



--- - file: Land_Lord.lua
-- brief: spawns start unit and sets storage levels
-- author: Andrea Piras
--
-- Copyright (C) 2010,2011.
-- Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
    return {
        name = "LandLord ",
        desc = "Recives the terraFormInformation. applies the actuall terraforming, informs Units about the currentWaterLevelOffset",
        author = "PicassoCT",
        date = "7 b.Creation",
        license = "GNU GPL, v2 its goes in all fields",
        layer = 0,
        enabled = true -- loaded by default?
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- synced only
if (gadgetHandler:IsSyncedCode()) then
    VFS.Include('scripts/lib_UnitScript.lua', nil, VFSMODE)

    GG.boolForceLandLordUpdate = false
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    -- TODO Function that allows the insertion of various terraindeformations




    --various Tools
    function isWithinCircle(squareSideDimension, circleRange, xCoord, zCoord)

        local LifeHalf = (squareSideDimension / 2)

        local newCubic = 0.7071067811865475 * (circleRange - LifeHalf)

        negCircleRange = (-1 * circleRange) + LifeHalf

        --checking the most comon cases |Coords Outside the Circlebox
        if xCoord > circleRange + LifeHalf or xCoord < negCircleRange then
            return false
        end

        if zCoord > circleRange + LifeHalf or zCoord < negCircleRange then
            return false
        end

        negNewCubic = -1 * newCubic + LifeHalf


        --checking everything within the circle box
        if (xCoord < newCubic and xCoord > negNewCubic) and (zCoord < newCubic and zCoord > negNewCubic) then
            return true
        end


        -- very few cases make it here.. to the classic, bad old range compare
        distDance = math.sqrt((xCoord - LifeHalf) ^ 2 + (zCoord - LifeHalf) ^ 2)

        if distDance < circleRange - LifeHalf then
            return true

        else
            return false
        end
    end

    --gets the sum of all values surrounding the center
    function getNine(valTab, i, j)
        comonVal = 0
        for k = -1, 1, 1 do
            if valTab[i + k] and valTab[i + k][j - 1] then comonVal = comonVal + valTab[i + k][j - 1] end
            if k ~= 0 and valTab[i + k] and valTab[i + k][j] then comonVal = comonVal + valTab[i + k][j] end
            if valTab[i + k] and valTab[i + k][j + 1] then comonVal = comonVal + valTab[i + k][j + 1] end
            return (valTab[i][j] + comonVal) / 9
        end
    end

    --Nevar forget to add a boundary Check- gruesome death awaits those who dare fate
    function getFilterFunction(FilterName)

        if FilterName == "none" then
            --	Spring.Echo("JW:FilterFunc:None")
            return function(boolinBounds, anyVal, rateOfBlur)
                assert(anyVal, "JW:FilterFunc:TableEmpty")
                return anyVal
            end
        end

        if FilterName == "borderblur" then
            --	Spring.Echo("JW:FilterFunc:borderblur")
            return function(boolinBounds, anyVal, rateOfBlur)
                if not anyVal then Spring.Echo(" FilterFunction: Borderblur: Did not recive any Value to work on"); return anyVale; end
                rateOfBlur = math.max(1, (rateOfBlur or 1))

                local lgetNine = getNine
                for rB = 1, rateOfBlur, 1 do
                    for outIndex, outerTable in pairs(anyVal) do
                        for inIndex, innerTable in pairs(outerTable) do
                            if innerTable == 0 then
                                anyVal[outIndex][inIndex] = lgetNine(anyVal, outIndex, inIndex)
                            end
                        end
                    end
                end
                return anyVal
            end
        end
        --default case
        Spring.Echo("JW:FilterFunc:" .. FilterName .. " undefined")
        return function(boolinBounds, anyVal)
            return anyVal
        end
    end

    function getNormalizedGroundHeigth(vi, vj)
        h1 = Spring.GetGroundHeight(vi * 8, vj * 8)
        h2 = Spring.GetGroundHeight(vi * 8 + 100, vj * 8)
        h3 = Spring.GetGroundHeight(vi * 8 - 100, vj * 8)
        h4 = Spring.GetGroundHeight(vi * 8, vj * 8 + 100)
        h5 = Spring.GetGroundHeight(vi * 8, vj * 8 - 100)
        h6 = Spring.GetGroundHeight(vi * 8 - 100, vj * 8 + 100)
        h7 = Spring.GetGroundHeight(vi * 8 - 100, vj * 8 - 100)
        h8 = Spring.GetGroundHeight(vi * 8 + 100, vj * 8 + 100)
        h9 = Spring.GetGroundHeight(vi * 8 + 100, vj * 8 - 100)
        return (h1 + h2 + h3 + h4 + h5 + h6 + h7 + h8 + h9) / 9
    end

    function getBlendFunction(BlendName)
        --blindly adds or subs the value
        if BlendName == "melt" then return function(anyTable, vi, vj, wStartX, wStartZ) return anyTable end end
        --adds subs the value to
        if BlendName == "add" then
            return function(anyTable, vi, vj, wStartX, wStartZ)
                if not anyTable then Spring.Echo(" BlendFunction: add: Did not recive any Value to work on"); return anyTable; end

                h = getNormalizedGroundHeigth(vi, vj)
                for i = 1, #anyTable, 1 do
                    if boundCheck("x", i) == true then
                        for j = 1, #anyTable, 1 do
                            if boundCheck("z", j) == true then
                                orgTerrainValue = orgTerrainMap[wStartX + i][wStartZ + j]
                                --if orgTerrainValue then
                                --if orgTerrainValue > h + anyTable[i][j] then
                                --	anyTable[i][j]=0
                                --else
                                --	anyTable[i][j]= getGroundHeigthDistance(orgTerrainValue,h)+  anyTable[i][j]
                                --end
                                --end
                            end
                        end
                    end
                end
                return anyTable
            end
        end

        if BlendName == "sub" then
            return
                ------------- sub----------------------
            function(anyTable, vi, vj, wStartX, wStartZ)

                h = getNormalizedGroundHeigth(vi, vj)
                for i = 1, #anyTable, 1 do
                    if boundCheck("x", i) == true then
                        for j = 1, #anyTable, 1 do
                            if boundCheck("z", j) == true then
                                if orgTerrainMap[i][j] then
                                    if orgTerrainMap[i][j] < h + anyTable[i][j] then
                                        anyTable[i][j] = 0
                                    else
                                        anyTable[i][j] = (orgTerrainMap[i][j] - (h + anyTable[i][j]) - math.max(orgTerrainMap[i][j] - h, 0)) * -1
                                    end
                                end
                            end
                        end
                    end
                end

                return anyTable
            end
        end
        -----------------------------------


        --------------- relative--------------------
        if BlendName == "relative" then
            return function(anyTable, vi, vj, wStartX, wStartZ)
                local bcheck = boundCheck
                h = getNormalizedGroundHeigth(vi, vj)
                for i = 1, #anyTable, 1 do
                    if bcheck("x", i) == true then
                        for j = 1, #anyTable, 1 do
                            if bcheck("z", j) == true then

                                if orgTerrainMap[i][j] - h < anyTable[i][j] then
                                    orgTerrainMap[i][j] = orgTerrainMap[i][j] + math.abs(orgTerrainMap[i][j] - h) + anyTable[i][j]
                                else
                                    orgTerrainMap[i][j] = orgTerrainMap[i][j] + math.abs(orgTerrainMap[i][j] - h) - anyTable[i][j]
                                end
                            end
                        end
                    end
                end
                --Spring.Echo("JW_LANDLORD:SUB-----------------------")
                --print2DMap(anyTable)
                return anyTable
            end
        end

        --------------- normal standard absolute add or substract value--------------------

        return
        function(anyTable, vi, vj)

            local bcheck = boundCheck
            h = getNormalizedGroundHeigth(vi, vj)
            for i = 1, #anyTable, 1 do
                if bcheck("x", i) == true then
                    for j = 1, #anyTable, 1 do
                        if bcheck("z", j) == true then
                            if orgTerrainMap[i][j] then
                                orgTerrainMap[i][j] = orgTerrainMap[i][j] + anyTable[i][j]
                            end
                        end
                    end
                end
            end
            --Spring.Echo("JW_LANDLORD:SUB-----------------------")
            --print2DMap(anyTable)
            return anyTable
        end
    end

    --by Convention a dynamic Deformation Map is a Piece of HeightmapOffsets, pushed to
    --GG.DynDefMap and it contains {x,z, Size, Table,blendType,filterType}
    --blendTypes
    --melt
    --subtotal
    --addtotal

    --filterTypes::

    MSX = Game.mapSizeX / 8
    MSZ = Game.mapSizeZ / 8
    function insertDynamicDeformationMaps()
        --Spring.Echo("JW::LandLord::insertDynamicDeformationMaps")
        if GG.DynDefMap == nil then GG.DynDefMap = {} end
        if GG.DynRefMap == nil then GG.DynRefMap = {} end

        for key, value in pairs(GG.DynDefMap) do
            --Spring.Echo(value)
            --	print2DMap(GG.DynRefMap[key])
            local x, z = math.ceil(value.x), math.ceil(value.z)
            halfSize = value.Size / 2
            --<Blend&FilterFunc>

            filterFunction = getFilterFunction(value.filterType or "none")
            assert(filterFunction, "JW_LANDLORD::WithinBounds::filterFunctionInit")

            blendFunction = getBlendFunction(value.blendType or "melt")
            assert(blendFunction, "JW_LANDLORD::WithinBounds::blendFunctionInit")


            --</Blend&FilterFunc>
            --y=Spring.GetGroundHeight(x*8,z*8)

            --if the value is within bounds, we can avoid expensive nilChecking

            if x - halfSize > 0 and x + halfSize < MSX and z - halfSize > 0 and z + halfSize < MSZ then
                --	Spring.Echo("JW::LandLord::insertDynamicDeformationMaps-2")
                withinBounds(x, z, key, halfSize, blendFunction, filterFunction, value.creator or "")
            else
                --Spring.Echo("JW::LandLord::insertDynamicDeformationMaps-3")
                debugVAL = withoutBounds(x, z, key, halfSize, blendFunction, filterFunction)
                if debugVAL and debugVAL == false then Spring.Echo("Error>LandLord>>insertDynamicDeformationMaps" .. x .. " | " .. z .. " | " .. i) end
            end
        end
        GG.DynDefMap = nil
        GG.DynRefMap = nil
    end

    function withinBounds(x, z, Nr, halfSize, blendFunction, filterFunction, creator)
			boolOnce=false
        startx, endx = x - halfSize, x + halfSize
        startz, endz = z - halfSize, z + halfSize
        --assert(GG.DynRefMap[Nr],"JW:WhatTheHell"..Nr)
        tempTable = filterFunction(true, GG.DynRefMap[Nr], 3, startx, startz)
			if not tempTable then echo("LandLord:Error: No deform Table given after filterfunction"); return end
        tempTable = blendFunction(tempTable, x, z, startx, startz)
			if not tempTable then echo("LandLord:Error: No deform Table given after blendfunction"); return end
        for o = startx, endx, 1 do
            for i = startz, endz, 1 do
				if  tempTable[math.max(1, o - startx)] and  tempTable[math.max(1, o - startx)][math.max(1, i - startz)] then
					orgTerrainMap[o][i] = orgTerrainMap[o][i] + tempTable[math.max(1, o - startx)][math.max(1, i - startz)]
				elseif boolOnce == false then
					boolOnce = true
					
					echo("LandLord: No terrain defined in dynampic Map for "..creator.." at x:"..math.max(1, o - startx).." and z: "..math.max(1, i - startz))
				end
            end
        end
    end

    function withoutBounds(x, z, Nr, halfSize, blendFunction, filterFunction)

        local bcheck = boundCheck
        startx, endx = x - halfSize, x + halfSize
        startz, endz = z - halfSize, z + halfSize
        --boundCheck
        tempTable = filterFunction(false, GG.DynRefMap[Nr], 3, startx, startz)
        assert(tempTable, "JW_LANDLORD::Without bounds::filterFunction flawed")
        tempTable = blendFunction(tempTable, x, z, startx, startz)


        for o = startx, endx, 1 do
            if bcheck("x", o) == true then
                for i = startz, endz, 1 do
                    if bcheck("z", i) == true then
                        --DEBUG
                        if not orgTerrainMap[o][i] or not tempTable[math.max(1, o - startx)][math.max(1, i - startz)] then return false end

                        orgTerrainMap[o][i] = orgTerrainMap[o][i] + tempTable[math.max(1, o - startx)][math.max(1, i - startz)]
                    end
                end
            end
        end
    end

    function boundCheck(T, val)
        if T == "z" then
            if val < 1 then
                return false
            elseif val > MSZ then
                return false
            else
                return true
            end
        end

        if T == "x" then
            if val < 1 then return false elseif val > MSX then return false else return true end
        end
    end



    function getHeightGradient(inRange, outRange, xCoord, zCoord, StartHeight, EndHeight, squareSideDimension)
        halfLife = squareSideDimension / 2
        totalRange = outRange - inRange

        return math.abs(((((math.ceil(math.sqrt((xCoord - halfLife) ^ 2 + (zCoord - halfLife) ^ 2)) - (inRange - halfLife)) * -1) + totalRange) * ((EndHeight - StartHeight) / totalRange))) + StartHeight
    end

    function modULater(val)
        if val <= 100 then
            return val
        end

        if val > 100 then
            return val - (val % 100)
        end
    end

    --creates the Future Terrainmap
    function createFutureMap(squareSideDimension)

        heightDifference = 100
        sixFeetUnder = 33
        fourTeenParts = (squareSideDimension / 18)
        aPart = fourTeenParts * 2
        local lisWithinCircle = isWithinCircle
        -----------------------------------------------
        terrainMap = {}
        --create outerZone 7 with zero.. the original terrain goes here
        for x = 1, squareSideDimension + 1, 1 do
            terrainMap[x] = {}
            for z = 1, squareSideDimension + 1, 1 do
                terrainMap[x][z] = {}
                terrainMap[x][z] = 0
            end
        end
        --ToDOHERE
        local lgetHeightGradient = getHeightGradient

        --create the first inner zone, heightgradient 6
        for x = 1, squareSideDimension + 1, 1 do
            for z = 1, squareSideDimension + 1, 1 do
                if lisWithinCircle(squareSideDimension, squareSideDimension, x, z) == true and lisWithinCircle(squareSideDimension, squareSideDimension - fourTeenParts, x, z) == false then
                    --(inRange,outRange, xCoord, zCoord, StartHeight,EndHeight,squareSideDimension)
                    --getHeightGradient( inRange ,outRange ,xCoord, zCoord, StartHeight,EndHeight,squareSideDimension)
                    terrainMap[x][z] = lgetHeightGradient(squareSideDimension - fourTeenParts, squareSideDimension, x, z, 0, sixFeetUnder, squareSideDimension)
                end
            end
        end
        --create the first inner zone, heightgradient 5
        --assert(terrainMap)
        --- -Spring.Echo("JWL_--create the first inner zone, heightgradient 6",terrainMap[35][35])
        for x = 1, squareSideDimension + 1, 1 do
            for z = 1, squareSideDimension + 1, 1 do
                if lisWithinCircle(squareSideDimension, squareSideDimension - fourTeenParts, x, z) == true and lisWithinCircle(squareSideDimension, squareSideDimension - (fourTeenParts + aPart), x, z) == false then
                    terrainMap[x][z] = 33
                end
            end
        end

        --create the first inner zone, heightgradient 4
        for x = 1, squareSideDimension + 1, 1 do

            for z = 1, squareSideDimension + 1, 1 do
                if lisWithinCircle(squareSideDimension, squareSideDimension - (fourTeenParts + aPart), x, z) == true and lisWithinCircle(squareSideDimension, squareSideDimension - (2 * aPart), x, z) == false then

                    terrainMap[x][z] = lgetHeightGradient(squareSideDimension - (2 * aPart), squareSideDimension - (fourTeenParts + aPart), x, z, sixFeetUnder, sixFeetUnder * 2, squareSideDimension)
                end
            end
        end

        --create the first inner zone, heightgradient 3

        for x = 1, squareSideDimension, 1 do
            for z = 1, squareSideDimension, 1 do
                if lisWithinCircle(squareSideDimension, squareSideDimension - (2 * aPart), x, z) == true and lisWithinCircle(squareSideDimension, squareSideDimension - (4 * aPart), x, z) == false then

                    terrainMap[x][z] = 66
                end
            end
        end

        --create the first inner zone, heightgradient 2
        for x = 1, squareSideDimension + 1, 1 do
            for z = 1, squareSideDimension + 1, 1 do
                --	if lisWithinCircle(squareSideDimension,squareSideDimension-(4*aPart),x,z)==true and lisWithinCircle(squareSideDimension,squareSideDimension-((4*aPart)+fourTeenParts),x,z)==false then
                if lisWithinCircle(squareSideDimension, squareSideDimension - (3 * aPart), x, z) == true and lisWithinCircle(squareSideDimension, squareSideDimension - ((4 * aPart)), x, z) == false then

                    terrainMap[x][z] = modULater(lgetHeightGradient(squareSideDimension - ((3 * aPart) + fourTeenParts), squareSideDimension - (3 * aPart), x, z, 2 * sixFeetUnder, 3 * sixFeetUnder, squareSideDimension))
                end
            end
        end


        --center And done
        for x = 1, squareSideDimension + 1, 1 do

            for z = 1, squareSideDimension + 1, 1 do
                if lisWithinCircle(squareSideDimension, squareSideDimension - (4 * aPart), x, z) == true then

                    terrainMap[x][z] = 99
                end
            end
        end

        --print2DMap(terrainMap,squareSideDimension)
        return terrainMap
    end






    --function validates Unit Table
    function validateUnitTable(tableToValidate)
        local spUnitIsDead = Spring.GetUnitIsDead
        x = table.getn(tableToValidate)
        for i = 1, x, 1 do

            if spUnitIsDead((tableToValidate[i][1])) == true then

                table.remove(tableToValidate, i)
                x = x - 1
                if i ~= 1 then i = i - 1 end
            end
        end
        return tableToValidate
    end

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------


    local gWaterOffSet = 0 --global WaterOffset
    local UPDATE_FREQUNECY = 4200
    local increaseRate = 0.01 --reSetMe to 0.001
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    boolFirst = true

    --Table contains all the WaterLevelChanging Units
    local WaterLevelChangingUnitsTable = {}
    --Table contains all Units who perform Terraforming - and thus need to be informed of rising waterLevels
    local LandLordTable = {}

    orgTerrainMap = {}
    GroundDeformation = {}
    futureMapSize = 54


    GG.addWaterLevel = 0
    GG.subWaterLevel = 0
    if GG.Extrema == nil then
        GG.Extrema = {}
        min, max = Spring.GetGroundExtremes()
        GG.Extrema = max + math.abs(min) + math.ceil(math.random(10, 100))
    end
    --function collects the stored changedate from the WaterLevelingUnits
    function getGlobalOffset()
        returnVal = (GG.addWaterLevel * -1) + GG.subWaterLevel
        GG.addWaterLevel = 0
        GG.subWaterLevel = 0
        return returnVal
    end

    function unNeg(val)
        if val < 0 then
            return val * -1
        else
            return val
        end
    end


    extremataGlobal = 1
    boolFirstBlood = true
    function updateMaxima()

        extremataDown, extremataUp = Spring.GetGroundExtremes()
        --assert(extremataDown)
        --assert(extremataUp)
        extremataDown = math.abs(extremataDown)

        if boolFirstBlood == true and (extremataDown ~= nil and extremataUp ~= nil) then
            boolFirstBlood = false

            extremataGlobal = math.max(extremataDown, extremataUp)



            GG.Extrema = extremataGlobal
            --delMe
        else


            --/delMe
        end
    end


    --Every unit signs up, is checked for its UnitdefId beeing that of a WaterAdder or a WaterSubstractor
 

    function caselessAmmonition(sizeMattersZ)
        --All the ugly cases


        --first out =1

        local spGetGroundHeight = Spring.GetGroundHeight

        --second




        RetTable = {}


        for i = 1, sizeMattersZ, 1 do
            --startCaseExtra
            if i == 1 then
                RetTable[i] = {}
                RetTable[i] = spGetGroundHeight(2, i)
            end
            RetTable[i + 1] = {}
            RetTable[i + 1] = spGetGroundHeight(16, i * 8)
        end


        return RetTable
    end

    --Creates the original TerrainTable
    local MapSizeX = Game.mapSizeX / 8
    local MapSizeZ = Game.mapSizeZ / 8
    sizeMattersX = (Game.mapSizeX) / 8
    sizeMattersZ = (Game.mapSizeZ) / 8

    function forgeFirstTerrainMap() --rewritten

        local spGetGroundHeight = Spring.GetGroundHeight



        --Spring.Echo(Game.mapSizeX)
        --Spring.Echo(MapSizeX)
        --Spring.Echo(Game.mapSizeZ)
        --Spring.Echo(MapSizeZ)



        for out = 1, sizeMattersX, 1 do
            SubTable = {}


            for i = 1, sizeMattersZ, 1 do
                --startCaseExtra
                if i ~= 1 and out ~= 1 then
                    SubTable[i + 1] = spGetGroundHeight(out * 8, i * 8)
                elseif i == 1 and out ~= 1 then
                    SubTable[1] = spGetGroundHeight(out * 8, 1)
                    SubTable[2] = spGetGroundHeight(out * 8, 8)
                elseif out == 1 and i ~= 1 then
                    SubTable[i + 1] = spGetGroundHeight(1, i * 8)
                else
                    SubTable[i] = spGetGroundHeight(1, 1)
                end
            end

            if out ~= 1 then
                orgTerrainMap[out + 1] = SubTable
            else
                orgTerrainMap[1] = SubTable
                orgTerrainMap[2] = caselessAmmonition(sizeMattersZ)
            end
        end



        --Spring.Echo("JWL_------------LANDLORD--------------------------Printing Out orgTerrainMap")
        --	print2DMap(orgTerrainMap)
    end





    function determinateTileNrZ(tileNr) --rewritten
        if tileNr > 0 and tileNr < 9 then
            return 1
        elseif tileNr > 8 and tileNr < 17 then
            return 2
        elseif tileNr > 16 and tileNr < 25 then
            return 3
        elseif tileNr > 24 and tileNr < 33 then
            return 4
        elseif tileNr > 32 and tileNr < 41 then
            return 5
        elseif tileNr > 40 and tileNr < 49 then
            return 6
        elseif tileNr > 48 and tileNr < 57 then
            return 7
        else
            return 8
        end
    end

    -- function round

    tileSizeX = (MapSizeX) / 8
    tileSizeZ = (MapSizeZ) / 8

    function throwTantrum(message, value)
        --Spring.Echo(message.."at: "..value)
    end

    MapSizeXDiv8 = math.floor(MapSizeX) / 8
    MapSizeZDiv8 = math.floor(MapSizeZ) / 8



    function clamp(Value, boolIsX) --rewritten

        --Spring.Echo("JWL_MapSizeXDiv8",MapSizeXDiv8)
        --Spring.Echo("JWL_MapSizeZDiv8",MapSizeZDiv8)
        if Value < 0 then return 1 end

        if boolIsX == true then
            if Value <= MapSizeX then return Value
            else
                return MapSizeX
            end
        else
            if Value <= MapSizeZ then return Value
            else
                return MapSizeZ
            end
        end
    end


    -- subTable[1]=unitID
    -- subTable[2]=unitDefID
    -- subTable[3]=unitTeam
    -- subTable[4]=unNeg(y) 			--the StartHeight Value
    -- subTable[5]=0.001 				--scalar stores how much
    -- subTable[6]=x
    -- subTable[7]=z
    --This function adds the GroundDeformation Table at the position of the Unit into the
    function TerraInFormTable()
        if LandLordTable ~= nil and table.getn(LandLordTable) ~= 0 then

            local ME = {}

            local FMS = futureMapSize
            local incRate = increaseRate
            local GetGroundHeight = Spring.GetGroundHeight

            for i = 1, #LandLordTable, 1 do
                --increment the Percentage
                LandLordTable[i][5] = LandLordTable[i][5] + incRate

                --determinate coordinates

                startx = LandLordTable[i][6] - FMS / 2
                endx = startx + FMS
                startz = LandLordTable[i][7] - FMS / 2
                endz = startz + FMS

                oldstartx = startx
                startx = clamp(startx, true)
                offsetstartx = math.abs(startx - oldstartx) --the distance

                --oldendx=endx
                endx = clamp(endx, true)

                oldstartz = startz
                startz = clamp(startz, false)
                offsetstartz = math.abs(startz - oldstartz)
                --oldendz=endz
                endz = clamp(endz, false)



                --determinate
                upDown = 1

                if LandLordTable[i][2] == UnitDefNames["mdiggmex"].id then upDown = -1 end
                --Spring.Echo("UpDown", upDown)
                --by UnitType

                for z = startz, endz, 1 do
                    for x = startx, endx, 1 do

                        if orgTerrainMap[x][z] and GroundDeformation[((x - startx) + 1 + offsetstartx)][((z - startz) + 1 + offsetstartz)] ~= 0 then

                            --	if the mining unit is new, equalize the terrain, til 0.15 percent is reached
                            if LandLordTable[i][5] <= 0.15 then
                                y = GetGroundHeight(LandLordTable[i][6] * 8, LandLordTable[i][7] * 8)


                                orgTerrainMap[x][z] = (((orgTerrainMap[x][z] * 2) + y) / 3) + upDown
                                --then start to dig down/up
                            elseif LandLordTable[i][5] > 0.15 and LandLordTable[i][5] < 0.5 then
                                orgTerrainMap[x][z] = orgTerrainMap[x][z] + (((GroundDeformation[(x - startx + offsetstartx) + 1][(z - startz + offsetstartz) + 1]) / ((0.5 - 0.15) / incRate)) * upDown)
                            else --finally go into overdrive and dig
                                orgTerrainMap[x][z] = orgTerrainMap[x][z] + ((upDown * ((GroundDeformation[(x - startx + offsetstartx) + 1][(z - startz + offsetstartz) + 1]) / 100) * extremataGlobal) / (0.5 / incRate))
                            end
                        end

                        if orgTerrainMap[x][z] == nil then
                            Spring.Echo("JWL_JWLandLord orgTerrain undefined at:", x .. " and z:", z)
                        end
                    end
                end
            end
            --Spring.Echo("JWL_-----------/LANDLORD--------------------------")
        end
    end


    --rewritten
    LDtileSizeX = (MapSizeX)
    LDtileSizeZ = (MapSizeZ)
    function loadDistributor(tileNr, WaterOffset)
        --1
        --preparations
        tileCoordX = tileNr % 8 --from 1 to 64
        if tileCoordX == 0 then tileCoordX = 8 end

        --tileCoordX=1

        tileCoordZ = determinateTileNrZ(tileNr)
        --tileCoordZ=1

        --secondstage
        startVarX = ((tileCoordX - 1) * LDtileSizeX) + 1
        endVarX = startVarX + LDtileSizeX - 1
        --endVarX=127
        startVarZ = ((tileCoordZ - 1) * LDtileSizeZ) + 1
        endVarZ = startVarZ + LDtileSizeZ - 1
        --endVarZ=127
        ------------------------------------ TestEchos---------------------
        local cceil = math.ceil
        if (endVarZ >= MapSizeZ * 8) then
            throwTantrum("Index Out of bounds Exception", endVarZ)
            endVarZ = MapSizeZ * 8 - 1
        end
        if (endVarX >= MapSizeX * 8) then
            throwTantrum("Index Out of bounds Exception", endVarX)
            endVarX = MapSizeX * 8 - 1
        end

        --
        local spSetHeightMapFunc = Spring.SetHeightMapFunc
        ------------------------------------ /TestEchos---------------------
        -- the actuall loop


        spSetHeightMapFunc(function()
            local spSetHeightMap = Spring.SetHeightMap
            local wOffset = WaterOffset
            --1, 127
            for z = startVarZ, endVarZ, 8 do
                boolPulledOff = false
                for x = startVarX, endVarX, 8 do --changed to 8 as the wizzard zwzsg said i should ;

                    if orgTerrainMap[cceil(x / 8)] and orgTerrainMap[cceil(x / 8)][cceil(z / 8)] then
                        spSetHeightMap(x, z, orgTerrainMap[cceil(x / 8)][cceil(z / 8)] + wOffset)
                        boolPulledOff = true
                    end
                end
            end
        end)
    end


    local boolForceUpdateFlag = false
    local WaterOffsetMain = 0
    local boolOneAndOnly = true
    function gadget:GameFrame(f)

        --Check wether this one Enforces a Update or not
        if f % 15 == 0 and GG.boolForceLandLordUpdate == true then
            GG.boolForceLandLordUpdate = false
            boolForceUpdateFlag = true
        end


        if f % UPDATE_FREQUNECY == 0 or boolForceUpdateFlag == true or boolOneAndOnly == true then
            boolForceUpdateFlag = false
            --update the MapExtremas
            updateMaxima()
            if boolOneAndOnly == true then
                boolOneAndOnly = false

                forgeFirstTerrainMap()

                GroundDeformation = createFutureMap(futureMapSize)
            end
            --add the Dynamic Deformations
            insertDynamicDeformationMaps()

            --validate the units
            validateUnitTable(LandLordTable)
            TerraInFormTable()

            WaterOffsetMain = getGlobalOffset()

        end

        --by now we have the global HeightMap stored in the TerrainMapWorkingCopy
        if f % UPDATE_FREQUNECY > 0 and f % UPDATE_FREQUNECY < 66 then
            loadDistributor(((f % UPDATE_FREQUNECY)), WaterOffsetMain)
        end
    end
end