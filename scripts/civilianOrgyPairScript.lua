include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"

include "lib_mosaic.lua"
TablesOfPiecesGroups = {}

local Scene = piece('Scene');
local center = piece('center');
local p1_head = piece('p1_head');
local p1_l_body = piece('p1_l_body');
local p1_left_l_arm = piece('p1_left_l_arm');
local p1_left_l_leg = piece('p1_left_l_leg');
local p1_left_u_arm = piece('p1_left_u_arm');
local p1_left_u_leg = piece('p1_left_u_leg');
local p1_penis = piece('p1_penis');
local p1_right_l_arm = piece('p1_right_l_arm');
local p1_right_l_leg = piece('p1_right_l_leg');
local p1_right_u_arm = piece('p1_right_u_arm');
local p1_right_u_leg = piece('p1_right_u_leg');
local p1_u_body = piece('p1_u_body');
local p2_head = piece('p2_head');
local p2_l_body = piece('p2_l_body');
local p2_left_l_arm = piece('p2_left_l_arm');
local p2_left_l_leg = piece('p2_left_l_leg');
local p2_left_u_arm = piece('p2_left_u_arm');
local p2_left_u_leg = piece('p2_left_u_leg');
local p2_right_l_arm = piece('p2_right_l_arm');
local p2_right_l_leg = piece('p2_right_l_leg');
local p2_right_u_arm = piece('p2_right_u_arm');
local p2_right_u_leg = piece('p2_right_u_leg');
local p2_u_body = piece('p2_u_body');
local scriptEnv = {	
	Scene = Scene,
	center = center,
	p1_head = p1_head,
	p1_l_body = p1_l_body,
	p1_left_l_arm = p1_left_l_arm,
	p1_left_l_leg = p1_left_l_leg,
	p1_left_u_arm = p1_left_u_arm,
	p1_left_u_leg = p1_left_u_leg,
	p1_penis = p1_penis,
	p1_right_l_arm = p1_right_l_arm,
	p1_right_l_leg = p1_right_l_leg,
	p1_right_u_arm = p1_right_u_arm,
	p1_right_u_leg = p1_right_u_leg,
	p1_u_body = p1_u_body,
	p2_head = p2_head,
	p2_l_body = p2_l_body,
	p2_left_l_arm = p2_left_l_arm,
	p2_left_l_leg = p2_left_l_leg,
	p2_left_u_arm = p2_left_u_arm,
	p2_left_u_leg = p2_left_u_leg,
	p2_right_l_arm = p2_right_l_arm,
	p2_right_l_leg = p2_right_l_leg,
	p2_right_u_arm = p2_right_u_arm,
	p2_right_u_leg = p2_right_u_leg,
	p2_u_body = p2_u_body,
	x_axis = x_axis,
	y_axis = y_axis,
	z_axis = z_axis,
}

local Animations = include('orgy_couple_ref_movement.lua')
assert(Animations["REF_MOVEMENT"])
assert(Animations["REF_MOVEMENT"][1])
assert(Animations["REF_MOVEMENT"][1].time)
assert(Animations["REF_MOVEMENT"][1].time == 1)
assert(Animations["REF_MOVEMENT"][1].commands)
assert(Animations["REF_MOVEMENT"][1].commands[1].c)
assert(Animations["REF_MOVEMENT"][1].commands[1].p)
assert(Animations["REF_MOVEMENT"][1].commands[1].a)
assert(Animations["REF_MOVEMENT"][1].commands[1].t)
assert(Animations["REF_MOVEMENT"][1].commands[1].s)


-- center = piece "center"
-- left = piece "left"
-- right = piece "right"
-- aimpiece = piece "aimpiece"
if not center then echo("Unit of type"..UnitDefs[Spring.GetUnitDefID(unitID)].name .. " has no center") end

function script.Create()
    -- generatepiecesTableAndArrayCode(unitID, true)

	setupAnimation()
	Hide(p1_penis)

	-- Spring.MoveCtrl.Enable(unitID,true)
	-- x,y,z =Spring.GetUnitPosition(unitID)
	-- Spring.MoveCtrl.SetPosition(unitID, x,y+500,z)
	StartThread(AnimationTest)
end


local animCmd = {['turn']=Turn,['move']=Move};

local axisSign ={
	[x_axis]=1,
	[y_axis]=1,
	[z_axis]=1,
}


function constructSkeleton(unit, piece, offset)
	echo("Enter constructSkeleton")
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
	echo("Leave constructSkeleton")
    return bones;
end

function setupAnimation()
	echo("setupAnimation")
	
	local switchAxis = function(axis) 
		if axis == z_axis then return y_axis end
		if axis == y_axis then return z_axis end
		return axis
	end
	
	assert(Spring.GetUnitPieceMap)
    local map = Spring.GetUnitPieceMap(unitID);
	assert(map)
    local offsets = constructSkeleton(unitID, map.Scene, {0,0,0});
    
    for a,anim in pairs(Animations) do
        for i,keyframe in pairs(anim) do
            local commands = keyframe.commands;
			assert(commands)
            for k,command in pairs(commands) do
			if command.p then
                -- commands are described in (c)ommand,(p)iece,(a)xis,(t)arget,(s)peed format
                -- the t attribute needs to be adjusted for move commands from blender's absolute values
                if (command.c == "move") then
                    local adjusted =  command.t - (offsets[command.p][command.a]);
                    Animations[a][i]['commands'][k].t = command.t - (offsets[command.p][command.a]);
                end
				
				if type(command.p) == "string" then
				 Animations[a][i]['commands'][k].p = piece(command.p)
				end
				
				Animations[a][i]['commands'][k].a = switchAxis(command.a)	
				
            end
            end
        end
   end
   echo("Leave setupAnimation")
end
            
local animCmd = {['turn']=Spring.UnitScript.Turn,['move']= Spring.UnitScript.Move};
function PlayAnimation(animname)
    local anim = Animations[animname];
	assert(anim)
	assert(#anim>0)
    for i = 1, #anim do
        local commands = anim[i].commands;
		assert(commands)
        for j = 1,#commands do
            local cmd = commands[j];
			assert(cmd)
			if cmd.c and cmd.p then
				echo("Playing Animation")
				if not animCmd[cmd.c] then echo("Animation has no command "..cmd.c) end
				animCmd[cmd.c](cmd.p,cmd.a,cmd.t,cmd.s);
			end
        end
        if(i < #anim) then
            local t = anim[i+1]['time'] - anim[i]['time'];
            Sleep(t*33); -- sleep works on milliseconds
        end
    end
end
--doggy
--doggystanding
        
function FuckFest()
resetAll(unitID)
allKeys = {}
for k,v in pairs(Animations) do
	allKeys[#allKeys+1] = k
end


while true do
	randTime = math.random(5,150)
	Sleep(randTime)
	Hide(center)
	
	PlayAnimation(allKeys[random(1,#allKeys)])
	WaitForTurns(scriptEnv)
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

