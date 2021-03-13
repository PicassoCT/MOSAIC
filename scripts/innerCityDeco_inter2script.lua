include "lib_mosaic.lua"
include "lib_UnitScript.lua"

TablesOfPiecesGroups = {}

function script.Create()
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitBlocking(unitID,false)
	Spring.SetUnitAlwaysVisible(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
	StartThread(bodyBuilder)	
end

function bodyBuilder()
	TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	hideAll(unitID)
	index = math.random(1,#TablesOfPiecesGroups["Well"])
	Show(TablesOfPiecesGroups["Well"][index])
	if TablesOfPiecesGroups["Well"..index.."Blinker"] then
		for i=1, #TablesOfPiecesGroups["Well"..index.."Blinker"] do
		StartThread(blinkerFountain, TablesOfPiecesGroups["Well"..index.."Blinker"][i] )
		end
	end
	
	if TablesOfPiecesGroups["Well"..index.."Spin"] then
		for i=1, #TablesOfPiecesGroups["Well"..index.."Spin"] do
			Spin(TablesOfPiecesGroups["Well"..index.."Spin"][i], y_axis, math.rad(6*randSign()),0)
			Show(TablesOfPiecesGroups["Well"..index.."Spin"][i])
		end
	end
end

function  blinkerFountain(pieceName )
	Spring.Echo("blinkerFountain started")
	Show(pieceName)
	while true do
			val = math.random(0,1)*180 
			Turn(pieceName, x_axis,math.rad(val ),0)
			val = math.random(0,1)*180 
			Turn(pieceName, y_axis,math.rad(val),0)
			val = math.random(0,1)*180 
			Turn(pieceName, z_axis,math.rad(val),0)
		Sleep(100)
	end
end
 
function script.HitByWeapon(x, z, weaponDefID, damage) 
	return damage
end

function script.Killed(recentDamage, maxHealth)
	return 0
end