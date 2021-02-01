include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
Irrigation1 = piece"Irrigation1"
GameConfig = getGameConfig()
gaiaTeamID = Spring.GetGaiaTeamID()
local houseTypeTable = getCultureUnitModelNames(GameConfig.instance.culture, "house", UnitDefs)

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    resetAll(unitID)
    Spin(piece("Logo"),z_axis,math.rad(42),0) 

    StartThread(deployPipes)
    
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][4], x_axis, math.rad(-120), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][3], x_axis, math.rad(145), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(-189), 1)
    WTurn(TablesOfPiecesGroups["Solar"][2], z_axis, math.rad(-145), 1)
    
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(181), 1)
    WTurn(TablesOfPiecesGroups["Solar"][1], z_axis, math.rad(230), 1)  
end



function script.Killed(recentDamage, _)
    return 1
end

function outsideMap(pieces)
    assert(pieces)
    x,y,z = Spring.GetUnitPiecePosDir(unitID, pieces)
    if x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ then 
        return true 
    end
    return false
end

function deployPipes()
    forInterval(1, #TablesOfPiecesGroups["HyperLoop"], Irrigation1, 1)  
end

takenValues={}

function forInterval(start,stop, irrigation, nr)
    offset = 5
    discoverSign= randSign()
    rotationValue = (math.random(-8*nr, 8*nr)+nr)*45
    attempts= 0
    boolAtLeastOnce= false
    while(boolAtLeastOnce == false or outsideMap(irrigation)== true or takenValues[rotationValue] and attempts < 10) do
       WTurn(TablesOfPiecesGroups["HyperLoop"][start], y_axis, math.rad(rotationValue), 0)
       rotationValue= rotationValue + 45 * discoverSign
       attempts = attempts + 1
       Sleep(1)
       x,y,z = Spring.GetUnitPiecePosDir(unitID, irrigation)
        Result=	process(getAllInCircle(x, z, 700),
     			 function(id)
		       		if houseTypeTable[Spring.GetUnitDefID(id)] then
		       			return id
		       		end
      		 	end
       			)

     boolAtLeastOnce= #Result == 0 
    end
    
    takenValues[rotationValue] = true

     accumulateddeg= 0
     showTable={}
     for i = start, stop do
            if i ~= stop and TablesOfPiecesGroups["HyperLoop"][i+1]then
                nextElement= TablesOfPiecesGroups["HyperLoop"][i+1]
            else
                nextElement = irrigation
            end

            boolIsAboveGround = false
            val= 0
            counter = 0
                while boolIsAboveGround == false and counter < 25 do
                    x,y,z= Spring.GetUnitPiecePosDir(unitID, nextElement)
                    gh =Spring.GetGroundHeight(x,z)
                    counter = counter +1

                    if y  > gh  + offset then
                        val = val - 1
                        accumulateddeg = accumulateddeg -1
                    elseif y  < gh + offset   then
                        val = val + 1
                        accumulateddeg = accumulateddeg + 1
                    end

                    if (x < 0 or x > Game.mapSizeX or z < 0 or z > Game.mapSizeZ) == false then
                        showTable[#showTable+1] = nextElement
                    end

                   WTurn(TablesOfPiecesGroups["HyperLoop"][i], x_axis, math.rad(val), 0)
                end
        end
   
    accumulateddeg = accumulateddeg *-1
    WTurn(irrigation, x_axis, math.rad(accumulateddeg), 0)
    showT(showTable)
    x,y,z = Spring.GetUnitPiecePosDir(unitID, Irrigation1)
    GG.UnitsToSpawn:PushCreateUnit("objective_irrigationfarming", x,y,z, math.random(1,4) , gaiaTeamID)    
    hideSensors(1)
end

function hideSensors(nr)
    Rotator = piece("Rotator"..nr)
    Sprinkler = piece("Sprinkler"..nr)
    Sensor = piece("Sensor"..nr)
    Hide(Rotator)
    Hide(Sprinkler)
    Hide(Sensor)
    Hide(Irrigation1)
end