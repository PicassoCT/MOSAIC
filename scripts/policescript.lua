include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

center = piece"center"
Torso = piece"Torso"
UpLeg2 = piece"UpLeg2"
LowLeg2 = piece"LowLeg2"
UpLeg1 = piece"UpLeg1"
LowLeg1 = piece"LowLeg1"
UpBody = piece"UpBody"
UpArm2 = piece"UpArm2"
LowArm2 = piece"LowArm2"
Hand2 = piece"Hand2"
BeatDown = piece"BeatDown"
UpArm1 = piece"UpArm1"
LowArm1 = piece"LowArm1"
Hand1 = piece"Hand1"
Head = piece"Head"
Shield = piece"Shield"
Visor = piece"Visor"

TablesOfPiecesGroups = {}
myDefID = Spring.GetUnitDefID(unitID)
function script.HitByWeapon(x, z, weaponDefID, damage) end

function showRiotCop()
  Show(Visor)
  Show(BeatDown)
  Show(Shield)
  Turn(Visor,x_axis, math.rad(90), 15)
end

function showCop()
  Show(BeatDown)
end

function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
    hideT(TablesOfPiecesGroups["Riot-Face"])
    showOnePiece(TablesOfPiecesGroups["Riot-Face"], math.random(1,100))
    Hide(RiotShield)
    Hide(center)
    Hide(Visor)
    Hide(BeatDown)
    showRiotCop()

end

function animationTest()
  while true do
    for i=1,3 do
      

    end
    Sleep(1000)
    resetAll(unitID, 1.0)
    WaitForTurns(TablesOfPiecesGroups)
    Sleep(1000)
  end
end


function script.Killed(recentDamage, _)
    return 1
end



function script.StartMoving() end

function script.StopMoving() end

function script.Activate() return 1 end

function script.Deactivate() return 0 end
