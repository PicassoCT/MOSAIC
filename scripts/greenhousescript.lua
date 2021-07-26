--most simple unit script
--allows the unit to be created & killed

include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"
include "lib_mosaic.lua"

center = piece"centers"
Windmill = piece"Windmill"
WindmillHead = piece"WindmillHead"
WindMillRotor = piece"WindMillRotor"
Solar = piece"Solar"
TablesOfPiecesGroups = {}
GameConfig = getGameConfig()
offset = 0
function script.Create()
	TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitBlocking(unitID,false)
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
	val = math.random(1,32)*45
	offset= val
	Turn(center,y_axis, math.rad(val),0)
	Turn(Windmill,y_axis, math.rad(-val),0)
	bodyBuild()
end

function bodyBuild()
	Hide(Solar)
	Hide(Windmill)
	Hide(WindmillHead)
	Hide(WindMillRotor )
	hideT(TablesOfPiecesGroups["Deco"])

	for i=1,#TablesOfPiecesGroups["Deco"] do
		if maRa()==true then 
			Show(TablesOfPiecesGroups["Deco"][i])
		end
	end

	if maRa()== true then
		StartThread(solar)
	end

	if maRa()== true then
		StartThread(wind)
	end

end

function timeOfDay()

    WholeDay = GameConfig.daylength
    timeFrame = Spring.GetGameFrame() + (WholeDay * 0.25)
    -- echo(getDayTime(timeFrame%WholeDay, WholeDay))
    return ((timeFrame % (WholeDay)) / (WholeDay))
end

function solar()
	Show(Solar)
   while true do
        Sleep(1000)
        percentage = timeOfDay()
        if percentage > 0.25 and percentage < 0.75 then
            percentage = (percentage - 0.25) / 0.5
            degree = (percentage * 180) + math.random(-10, 10)
            Turn(Solar, z_axis, math.rad(-offset + degree), math.pi / 100)
        end
        WaitForTurns(Solar)
   end
end

function wind()
	Show(Windmill)
	Show(WindmillHead)
	Show(WindMillRotor )
	Spin(WindMillRotor,z_axis,math.rad(42),0)
   while true do
        Sleep(1000)
        TurnTowardsWind(WindmillHead, math.pi / 100, math.random(-10, 10))
        WaitForTurns(WindmillHead)
    end
  end


function script.Killed(recentDamage, maxHealth)	
end