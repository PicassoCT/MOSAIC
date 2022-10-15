include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_mosaic.lua"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
gaiaTeamID = Spring.GetGaiaTeamID()
GameConfig = getGameConfig()
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

function script.Create()
    echo(UnitDefs[myDefID].name.."has placeholder script called")
    Spring.SetUnitAlwaysVisible(unitID, true)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    -- Spring.MoveCtrl.Enable(unitID,true)
    -- x,y,z =Spring.GetUnitPosition(unitID)
    -- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
     StartThread(Advertising)
     StartThread(LightsBlink)
     StartThread(flyTowardsPerson)
end

function flyTowardsPerson()
    px,py,pz = Spring.GetUnitPosition(unitID)
     Command(unitID, "go", {
                                x = px + math.random(-20, 20),
                                y = py,
                                z = pz + math.random(-20, 20)
                            }, {})
    Spring.AddUnitImpulse(unitID, 1, 10, 0)
    while true do  
        if maRa() == maRa()then     
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
                Command(unitID, "go", {x = px, y = py, z = pz}, {"shift"})
                Command(unitID, "go", {
                                x = px + math.random(-20, 20),
                                y = py,
                                z = pz + math.random(-20, 20)
                            }, {})
            end
        end
        Sleep(30000)
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
    return 1
end

function script.StartMoving() 
    val = math.random(5, 10)
    turnT(TablesOfPiecesGroups["Control"],x_axis, math.rad(val), 0.5)
end

function script.StopMoving()
    resetT(TablesOfPiecesGroups["Control"], 0.5)
 end

function script.Activate() return 1 end

function script.Deactivate() return 0 end

