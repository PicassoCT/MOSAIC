include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
--include "lib_Build.lua"

local TablesOfPiecesGroups = {}

length_axis = x_axis
side_axis = z_axis
height_axis = y_axis
container_dim_length = 13.5
container_dim_width = 2

function script.Create()

    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)

    StartThread(AnimationTest)
end

speed = 10
function AnimationTest()

    StartThread(pickPlaceJob, TablesOfPiecesGroups["Slider"][1],
                TablesOfPiecesGroups["Elevator"][1],
                TablesOfPiecesGroups["ContainerX"][1], 6)

    StartThread(pickPlaceJob, TablesOfPiecesGroups["Slider"][2],
                TablesOfPiecesGroups["Elevator"][2],
                TablesOfPiecesGroups["ContainerX"][2], 3)
end

function script.Killed(recentDamage, _)
    for k, v in pairs(TablesOfPiecesGroups) do
        if maRa() == true then
            explodeT(v, SFX.SHATTER)
        else
            explodeT(v, SFX.FALL)
        end
        hideT(v)
    end
    return 1
end

function pickPlaceJob(SliderPart, CranePart, Container, range)
    Hide(Container)
    while true do
        if maRa() == true then -- PlaceJob

            WMove(SliderPart, length_axis, 0, speed)
            Show(Container)
            Length_Location = math.floor(math.random(0, range)) *
                                  container_dim_length
            WMove(SliderPart, length_axis, Length_Location, speed)
            WMove(CranePart, side_axis,
                  math.random(-7, 7) * container_dim_width, speed)
            WMove(CranePart, height_axis, -container_dim_width * 5, speed)
            Hide(Container)
            WMove(CranePart, height_axis, 0, speed)
            WMove(CranePart, side_axis, 0, speed)
        else
            Length_Location = math.floor(math.random(0, range)) *
                                  container_dim_length
            WMove(SliderPart, length_axis, Length_Location, speed * 2)
            WMove(CranePart, side_axis,
                  math.random(-7, 7) * container_dim_width, speed)
            WMove(CranePart, height_axis, -container_dim_width * 5, speed)
            Show(Container)
            WMove(CranePart, height_axis, 0, speed)
            Move(CranePart, side_axis, 0, speed)
            WMove(SliderPart, length_axis, 0, speed)
            Hide(Container)
        end
        Sleep(500)
    end
end
