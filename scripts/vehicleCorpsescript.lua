include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"

include "lib_Build.lua"
include "lib_mosaic.lua"


center = piece "center"
emitfire = piece "emitfire"
glass = piece"glass"
teamID = Spring.GetGaiaTeamID()



local spCEG = Spring.SpawnCEG

explo = {}
for i = 1, 7, 1 do
    explo[i] = {}
    Emiters = "explo" .. i
    explo[i] = piece(Emiters)
end


SIG_DEATH = 32
stmax = 20

-- "custom:330rlexplode",1024
-- "custom:flames",
-- "custom:glowsmoke",
-- "custom:blackerThenSmoke",
-- "custom:LightUponSmoke",
-- "custom:vortflames",--1029
-- "custom:volcanolightsmall",--1030
-- "custom:cburningwreckage",--1031


function onFire(times, endtimes)
    Time = math.ceil(math.random(100, 160))
    StartThread(dustCloudPostExplosion, unitID, 1, Time, 50, 0, 1, 0)

    for i = 1, 3 do
        EmitSfx(emitfire, 1024)
        Sleep(90)
    end
    x, y, z = Spring.GetUnitPiecePosDir(unitID, emitfire)
    for i = 1, times, 1 do
        if i < endtimes then


            EmitSfx(emitfire, 1025)
            EmitSfx(emitfire, 1028)
            EmitSfx(emitfire, 1026)
            randpiece = math.random(1, #explo)
            EmitSfx(explo[randpiece], 1031)
        else
            EmitSfx(emitfire, 1028)
        end

        Sleep(200)
    end
end


function script.Create()
		Spring.SetUnitNeutral(unitID, true)
		Spring.SetUnitAlwaysVisible(unitID, true)
    if getUnitGroundHeigth(unitID) > -5 then
        if math.random(0, 1) == 1 then

            for i = 1, #explo, 1 do
                Explode(explo[i], SFX.FIRE + SFX.FALL)
                --StartThread(PseudoPhysix,explo[i],empty[i], math.random(5,10), nil)
                Hide(explo[i])
            end

        else
            for i = 1, #explo, 1 do
                Hide(explo[i])
            end
        end
		Hide(emitfire)
		Explode(glass, SFX.SHATTER)

        x = math.random(0, 360)
        EmitSfx(emitfire, 1024)

        fireTime = math.random(40, 360)
        endTimes = math.random(0, 500)
        StartThread(onFire, fireTime, endTimes)
    end

    StartThread(lifeTime, unitID, GG.GameConfig.Wreckage.lifeTime)

end



function script.Killed()

    return 1
end