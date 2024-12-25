--minimum viable lua script
function script.Create() 	
	Spring.SetUnitBlocking(unitID,false)
end


function script.Killed(recentDamage, _) return 1;end


