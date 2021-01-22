function waitForIt()
    Spring.SetUnitAlwaysVisible(unitID, true)
    Sleep(1)
    Spring.DestroyUnit(unitID, false, true)
end

function script.Create() StartThread(waitForIt) end

function script.Killed() return 0 end

