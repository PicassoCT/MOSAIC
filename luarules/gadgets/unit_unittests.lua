function gadget:GetInfo()
    return {
        name = "UnitUnitTestFramework",
        desc = "A simple Unittest framework using eventstreams",
        author = "My silly Pony Incooperated",
        date = "Dez. 2020",
        license = "GNU GPL, v2 or later",
        layer = 0,
        enabled = false,
    }
end

GaiaTeamID = Spring.GetGaiaTeamID
Tests= {
    index = 0
}
function insertTest(Test)
Test.boolComplete= false
Test.boolSuccessfull = false
table.insert(Tests,Test)
end

AttackTest ={
    setup = function(testEnv)

    unitsToSpawn= {
        --teamID
            [GaiaTeamID]= {   
                  -- id -- amount
                  ["civilian_arab0"] = 1
        },

            [GaiaTeamID +1]= { ["operativepropagator"] = 1
            }

         }

         return testEnv, unitsToSpawn
     end,

    execution = function (testEnv, teamUnitTableByDefID)
            boolDone = false
            Spring.GiveOrderToUnit(teamUnitTableByDefID[GaiaTeamID + 1][1], CMD.ATTACK,{teamUnitTableByDefID[GaiaTeamID +1][1]},{"shift"})

            testEnv.boolExecutionComplete = true
            return testEnv, boolDone
            end
        },

    result = function (testEnv)
                if testEnv.boolExecutionComplete == true then
                    assertEquals(true, false, )
                end

            return testEnv
            end
    }
insertTest(AttackTest)

--Convert Test into EvenStream and Execute
function executeTest(PersPack)
    GG.EventStream:CreateEvent()
end

function assertEquals(statementExpected, statementActual, messageOnFail)
    if (statementA ~= statementB) then
        Spring.Echo("Error: Assert equals: Expected:".. statementExpected .."  | Actual: "..statementActual)
        assert(true,false, messageOnFail)
    end 
end

currentTest = getNewTest()

if (gadgetHandler:IsSyncedCode()) then
    function getNewTest()
        Tests.index = math.min(Tests.index +1, #Tests)
        if Tests[Tests.index].boolComplete == false then
            return Tests[Tests.index]
        end
    end

    function gadget:GameFrame(frame)
        if frame > 100 and frame % 100 == 0 then
            if  currentTest.boolComplete == true then 
                currentTest = getNewTest()
            elseif currentTest then
                executeTest(currentTest)
            end       
        end
     end
end