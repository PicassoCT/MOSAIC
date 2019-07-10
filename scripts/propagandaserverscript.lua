include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}


Icon = piece "Icon"


function script.Create()
    team = Spring.GetUnitTeam(unitID)
    if not GG.Propgandaservers then  GG.Propgandaservers ={} end
    if not GG.Propgandaservers[team] then  GG.Propgandaservers[team]  =0 end
    GG.Propgandaservers[team] = GG.Propgandaservers[team] +1

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)


    StartThread(propagandaLoop)
    StartThread(delayedSpinStart)
end

function delayedSpinStart()

    for i=1 , 4 do
        factor = math.random(1,15)
        Spin(TablesOfPiecesGroups["Propeller"][i], y_axis, factor,-1*factor)
        randOhm = math.random(250,2500)
        Sleep(randOhm)
    end
end

function script.Killed(recentDamage, _)
    GG.Propgandaservers[team]  = math.max(0,GG.Propgandaservers[team] -1)

    return 1
end

function propagandaLoop()
    Sleep(100)
    local oldSubject, oldAddjective = 1,1
	
    while true do
        if boolLocalCloaked == false then
            hideT(TablesOfPiecesGroups["Screen"])
            hideT(TablesOfPiecesGroups["ADDJ"])
            hideT(TablesOfPiecesGroups["Subject"])
            ScreenDice = math.random(1,#TablesOfPiecesGroups["Screen"])
            AddjDice = math.random(1,#TablesOfPiecesGroups["ADDJ"])
            SubjectDice = math.random(1,#TablesOfPiecesGroups["Subject"])


            Show(TablesOfPiecesGroups["Screen"][ScreenDice])
            showCounter = 0
			if  oldAddjective ~= AddjDice  then
                Show(TablesOfPiecesGroups["ADDJ"][AddjDice])
				showCounter =showCounter +1
			end
				
			if   oldSubject ~= SubjectDice then
                Show(TablesOfPiecesGroups["Subject"][SubjectDice])
				showCounter =showCounter +1
			end
			
			if showCounter ~= 2 then
				Hide(TablesOfPiecesGroups["ADDJ"][AddjDice])
				Hide(TablesOfPiecesGroups["Subject"][SubjectDice])
				
				Show(TablesOfPiecesGroups["ADDJ"][oldAddjective])
				Show(TablesOfPiecesGroups["Subject"][oldSubject])
			end

            oldAddjective = AddjDice
            oldSubject = SubjectDice


            Sleep(3000)
        end
        Sleep(100)
    end
end

boolLocalCloaked = false
function showHideIcon(boolCloaked)
    boolLocalCloaked = boolCloaked
    if  boolCloaked == true then

        hideAll(unitID)
        Show(Icon)
    else
        showAll(unitID)
        Hide(Icon)
    end


end

