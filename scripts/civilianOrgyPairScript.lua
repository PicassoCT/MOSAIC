include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

TablesOfPiecesGroups = {}
local Animations = include('orgy_couple_ref_movement.lua')

 --local orgy_pair = piece("orgy_pair")
 local center = piece("center")
 local p1_l_body = piece("p1_l_body")
 local p1_right_u_leg = piece("p1_right_u_leg")
 local p1_right_l_leg = piece("p1_right_l_leg")
 local p1_left_u_leg = piece("p1_left_u_leg")
 local p1_left_l_leg = piece("p1_left_l_leg")
 local p1_penis = piece("p1_penis")
 local p1_u_body = piece("p1_u_body")
 local p1_right_arm = piece("p1_right_arm")
 local p1_right_l_arm = piece("p1_right_l_arm")
 local p1_left_u_arm = piece("p1_left_u_arm")
 local p1_left_l_arm = piece("p1_left_l_arm")
 local p1_head = piece("p1_head")
 local p2_l_body = piece("p2_l_body")
 local p2_u_body001 = piece("p2_u_body001")
 local p2_right_u_arm = piece("p2_right_u_arm")
 local p2_right_l_arm = piece("p2_right_l_arm")
 local p2_head = piece("p2_head")
 local eye_L001 = piece("eye_L001")
 local eye_L = piece("eye_L")
 local p2_left_u_arm = piece("p2_left_u_arm")
 local p2_left_l_arm = piece("p2_left_l_arm")
 local p2_right_u_leg001 = piece("p2_right_u_leg001")
 local p2_right_l_leg001 = piece("p2_right_l_leg001")
 local p2_right_u_leg = piece("p2_right_u_leg")
 local p2_right_l_leg = piece("p2_right_l_leg")

-- center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID, true)
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	
	-- setupAnimation()

	-- Spring.MoveCtrl.Enable(unitID,true)
	-- x,y,z =Spring.GetUnitPosition(unitID)
	-- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
	StartThread(AnimationTest)
end

function setupAnimation()
    local map = Spring.GetUnitPieceMap(unitID);
	local switchAxis = function(axis) 
		if axis == z_axis then return y_axis end
		if axis == y_axis then return z_axis end
		return axis
	end

    local offsets = constructSkeleton(unitID, map.center, {0,0,0});
    
    for a,anim in pairs(Animations) do
	if type(anim) == "table" then
        for i,keyframe in pairs(anim) do
            local commands = keyframe.commands;
            for k,command in pairs(commands) do
				assert(command.p)
				if command.p and type(command.p)== "string" then
					command.p = map[command.p]
				end
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                if (command.c == "move") then
                    local adjusted =  command.t - (offsets[command.p][command.a]);
                    Animations[a][i]['commands'][k].t = command.t - (offsets[command.p][command.a]);
                end
				
			   -- Animations[a][i]['commands'][k].a = switchAxis(command.a)	
            end
        end
    end
    end
end

local animCmd = {['turn']=Turn,['move']=Move};

local axisSign ={
	[x_axis]=1,
	[y_axis]=1,
	[z_axis]=1,
}

function PlayAnimation(animname, piecesToFilterOutTable, speed)
	local speedFactor = speed or 1.0
	if not piecesToFilterOutTable then piecesToFilterOutTable ={} end
	assert(animname, "animation name is nil")
	assert(type(animname)=="string", "Animname is not string "..toString(animname))
	assert(Animations[animname], "No animation with name ")
	
	
    local anim = Animations[animname];
	local randoffset 
    for i = 1, #anim do
        local commands = anim[i].commands;
        for j = 1,#commands do
            local cmd = commands[j];
			randoffset = 0.0
			if cmd.r then
				randVal = cmd.r* 100
				randoffset = math.random(-randVal, randVal)/100
			end
			
			if cmd.ru or cmd.rl then
				randUpVal=	( cmd.ru or 0.01)*100
				randLowVal=	( cmd.rl or 0	)*100
				randoffset = math.random(randLowVal, randUpVal)/100
			end
			
			if cmd.p and not piecesToFilterOutTable[cmd.p] then	
				animCmd[cmd.c](cmd.p, cmd.a, axisSign[cmd.a] * (cmd.t + randoffset) ,cmd.s*speedFactor)
				
			end
        end
        if(i < #anim) then
            local t = anim[i+1]['time'] - anim[i]['time'];
            Sleep(t*33* math.abs(1/speedFactor)); -- sleep works on milliseconds
        end
    end
end

function constructSkeleton(unit, piece, offset)
    if (offset == nil) then
        offset = {0,0,0};
    end
	
    local bones = {};

    local info = Spring.GetUnitPieceInfo(unit,piece);

    for i=1,3 do
        info.offset[i] = offset[i]+info.offset[i];
    end 

    bones[piece] = info.offset;
    local map = Spring.GetUnitPieceMap(unit);
    local children = info.children;

    if (children) then
        for i, childName in pairs(children) do
            local childId = map[childName];
            local childBones = constructSkeleton(unit, childId, info.offset);
            for cid, cinfo in pairs(childBones) do
                bones[cid] = cinfo;
            end
        end
    end        
    return bones;
end

function AnimationTest()
setupAnimation()
while true do
	resetAll(unitID)
	Sleep(1000)
	PlayAnimation("REF_MOVEMENT",10)
	Sleep(9000)
	echo("Animation Test loop")
	end
end

function script.Killed(recentDamage, _)

    --createCorpseCUnitGeneric(recentDamage)
    return 1
end



function script.Activate()

    return 1
end

function script.Deactivate()

    return 0
end

-- function script.QueryBuildInfo()
    -- return center
-- end

-- Spring.SetUnitNanoPieces(unitID, { center })

