include "createCorpse.lua"
include "lib_OS.lua"
include "lib_UnitScript.lua"
include "lib_Animation.lua"
include "lib_Build.lua"
include "lib_mosaic.lua"


TablesOfPiecesGroups = {}

-- local Scene = piece("Scene")
local center = piece("center")
local p1_head = piece("p1_head")
local p1_l_body = piece("p1_l_body")
local p1_left_l_arm = piece("p1_left_l_arm")
local p1_left_l_leg = piece("p1_left_l_leg")
local p1_left_u_arm = piece("p1_left_u_arm")
local p1_left_u_leg = piece("p1_left_u_leg")
local p1_penis = piece("p1_penis")
local p1_right_l_arm = piece("p1_right_l_arm")
local p1_right_l_leg = piece("p1_right_l_leg")
local p1_right_u_arm = piece("p1_right_u_arm")
local p1_right_u_leg = piece("p1_right_u_leg")
local p1_u_body = piece("p1_u_body")
local p2_head = piece("p2_head")
local p2_l_body = piece("p2_l_body")
local p2_left_l_arm = piece("p2_left_l_arm")
local p2_left_l_leg = piece("p2_left_l_leg")
local p2_left_u_arm = piece("p2_left_u_arm")
local p2_left_u_leg = piece("p2_left_u_leg")
local p2_right_l_arm = piece("p2_right_l_arm")
local p2_right_l_leg = piece("p2_right_l_leg")
local p2_right_u_arm = piece("p2_right_u_arm")
local p2_right_u_leg = piece("p2_right_u_leg")
local p2_u_body = piece("p2_u_body")
local scriptEnv = {
    -- Scene = Scene,
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
    z_axis = z_axis
}

local allPieces = {
    -- Scene = Scene,
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
}

-->Moves a Piece to a Position on the Ground in UnitSpace
function moveUnitPieceToGroundPose(unitID, piecename, X, Z, speed, offset)
    if not piecename then  error("No piecename given by "..UnitDefNames[Spring.GetUnitDefID(unitID)].name); return end
    if not X or not Z then return end
    loffset = offset or 0
    x, globalHeightUnit, z = Spring.GetUnitPosition(unitID)
    x, y, z, _, _, _ = Spring.GetUnitPiecePosDir(unitID, piecename)
    if not x then return end
    myHeight = Spring.GetGroundHeight(x, z)
    heightdifference = math.abs(globalHeightUnit - myHeight)
    if myHeight < globalHeightUnit then heightdifference = -heightdifference end
    Move(piecename, z_axis, heightdifference + loffset, speed, true)
end


function getRotation(piecename)
x,y,z=Spring.UnitScript.GetPieceRotation(piecename)
return {x=x,y=y,z=z}
end
function getLowestPiecePoint()
lowest = math.huge

	for k,v in pairs(allPieces) do
	x,y,z  = Spring.GetUnitPiecePosDir(unitID, v)
	if y < lowest then lowest = y end

	end

return lowest - getUnitGroundHeigth(unitID)
end

local Tieferlegen = 50
function allTheWayDown()
while true do
	h = getLowestPiecePoint(allPieces)
	moveUnitPieceToGroundPose(unitID, center, 0, 0, math.abs(h) + 1, -h -Tieferlegen)
	Sleep(250)
end

end
function recursiveTurn(element, timeInMs)
	if element.pId then 
	 tSyncIn(element.pId, element.xr, element.yr, element.zr ,timeInMs, Spring.UnitScript)
	else
		for k,v in pairs(element) do
			if type(v)== "table" then
			recursiveTurn(v, timeInMs)
			end
		end
	end
end

function recursiveHideShow(element, boolShow)
	if element.pId then 
		if boolShow == true then
			Show(element.pId)
		else
			Hide(element.pId)
		end
	else
		for k,v in pairs(element) do
			if type(v)== "table" then
			recursiveHideShow(v)
			end
		end
	end
end

function limitLowLeg(val)
return math.max(-175,math.min(0, val))
end

--The things we do for love
 function genericSexPos() 
	local itterationMax = 25
	local iterrations = math.random(5,itterationMax)
	local grindDir =  math.random(0,1)*180	
	local grindPos = 0;if math.random(1,4) > 3 then 	grindPos = 180	end
	local sideLines = 0;	if math.random(1,4) > 3 then sideLines = 90*randSign() end
	rVal= math.random(-50,50)/15
	Spin(center,y_axis, math.rad(rVal), 0.1)
	local hisPosition = math.random(-90,130)
	if maRa()==true then 
		hisPosition = math.max(-90, math.random(-200,0))
	else
		hisPosition = math.min(110, math.random(0,200))
	end


	if sideLines ~=0 then
		downValue = -500
	else
		xs= math.min(1.0, math.abs(hisPosition/100))		 
		downValue= xs*-420
	end		
	
	Move(center,z_axis, downValue, math.abs(downValue*2))

	local sidesign=-1
	local grindSign= 1;	if grindDir == 180 then grindSign= -1 end
	local hisArm= math.random(15,	45)
	local hisLeg= math.random(5,45)
	
	local herArmValue = math.random(35,	60)
	local herLegAngleOrg =  math.random(0,120)
	local herLegInwardRot=  math.random(-70,70) 
	if sideLines ~=0 then herLegAngleOrg= math.random(0,20); herLegInwardRot = math.random(-20,20) end
	if herLegAngleOrg > 70 then herLegInwardRot = math.random(-30,30) end
	
	
local orgPos=
	{
	she ={
	head ={
		pId= p2_head,
		xr = math.random(-25,-10),
		yr = 0,
		zr = 0,
	},
	up_body={
		pId= p2_u_body,
		xr=  math.random(-15,-5),
		yr=0,
		zr=0	
	},
arm={
		left={
			up={
				pId= p2_left_u_arm,
				xr=math.random(15,45),
				yr=math.random(35,80),
				zr=25 + herArmValue,
			},
			low={
				pId= p2_left_l_arm,
				xr=math.random(-15,45),
				yr=0,
				zr=herArmValue*-3,
			}	
		},
		right={
			up={
				pId= p2_right_u_arm,
				xr=0,
				yr= math.random(35,85)*sidesign*-1,
				zr=25 + herArmValue *sidesign
			},
			low={
				pId= p2_right_l_arm,
				xr=0,
				yr=0,
				zr=herArmValue*-3*sidesign
			}	
		},	
	},
	low_body = {
		pId= p2_l_body,
		xr =  math.random(-10,10),
		yr = grindPos + math.random(-10,10),
		zr = grindDir,
	},
	
	leg={
		left={
			up={
				pId= p2_left_u_leg,
				xr = herLegAngleOrg*-1,
				yr = math.random(-60,-5),
				zr = herLegInwardRot
			},
			low={
				pId= p2_left_l_leg,
				xr = math.min( herLegAngleOrg* -2, 0) ,
				yr = 0,
				zr = 0,
			}		
		},
		right={
			up={
				pId= p2_right_u_leg,
				xr = herLegAngleOrg*-1,
				yr =  math.random(-60,-5) *sidesign,
				zr = herLegInwardRot*sidesign
			},
			low={
				pId= p2_right_l_leg,
				xr = math.random(0,70),
				yr = 0,
				zr = 0,
			}		
		},
	}	
	},
	he={
	
	head ={
		pId= p1_head,
		xr = math.random(-15,-5),
		yr = 0,
		zr = 0,
	},
	up_body={
		pId= p1_u_body,
		xr=  math.random(-10,10),
		yr=0,
		zr=0	
	},
	arm={
		left={
			up={
				pId= p1_left_u_arm,
				xr=0,
				yr=81.5,
				zr=25 - hisArm,
			},
			low={
				pId= p1_left_l_arm,
				xr=0,
				yr=0,
				zr=hisArm*-3,
			}	
		},
		right={
			up={
				pId= p1_right_u_arm,
				xr=0,
				yr=81.5*sidesign,
				zr=25 + hisArm*sidesign
			},
			low={
				pId= p1_right_l_arm,
				xr=0,
				yr=0,
				zr=hisArm*-3*sidesign
			}	
		},	
	},
	leg={
		left={
			up={
				pId= p1_left_u_leg,
				xr =hisLeg*-1,
				yr = 0,
				zr = 0
			},
			low={
				pId= p1_left_l_leg,
				xr = hisLeg*2 +math.random(-10,10),
				yr = 0,
				zr = 0,
			}		
		},
		right={
			up={
				pId= p1_right_u_leg,
				xr = 0 ,
				yr = 0,
				zr = 0
			},
			low={
				pId= p1_right_l_leg,
				xr = 0, 
				yr = 0,
				zr = 0,
			}		
		},
		},
	low_body={
		pId=p1_l_body,
		xr = hisPosition,
		yr =  sideLines,
		zr = 0, --math.random(-1,1)*90,
		
		}
	}
	}
	
	--She
	--mirror arms	
	if math.random(1,4) < 3  then
		orgPos.she.arm.right.up.xr= orgPos.she.arm.left.up.xr
		orgPos.she.arm.right.up.yr= orgPos.she.arm.left.up.yr*sidesign
		orgPos.she.arm.right.up.zr= orgPos.she.arm.left.up.zr*sidesign 	
		
		orgPos.she.arm.right.low.xr= orgPos.she.arm.left.low.xr
		orgPos.she.arm.right.low.yr= orgPos.she.arm.left.low.yr
		orgPos.she.arm.right.low.zr= orgPos.she.arm.left.low.zr*sidesign 		
	else -- random flailing arm
	
		orgPos.she.arm.right.up.xr=0
		orgPos.she.arm.right.up.yr= math.random(35,85)*sidesign
		orgPos.she.arm.right.up.zr=25 + math.random(-60,	60) *sidesign
	
		orgPos.she.arm.right.low.xrxr=math.random(-10,30)
		orgPos.she.arm.right.low.yryr=0
		orgPos.she.arm.right.low.zrzr= math.random(-60,	60)*-3*sidesign	
	end
	
	
	orgPos.she.leg.left.low.xr = math.min(150, -2*orgPos.she.leg.left.up.xr)
	
	--mirror legs
	if math.random(1,4) < 4  then
		orgPos.she.leg.right.up.xr= orgPos.she.leg.left.up.xr
		orgPos.she.leg.right.up.yr= orgPos.she.leg.left.up.yr* sidesign
		orgPos.she.leg.right.up.zr= orgPos.she.leg.left.up.zr 	*sidesign	

		orgPos.she.leg.right.low.xr=  orgPos.she.leg.left.low.xr
		orgPos.she.leg.right.low.yr= orgPos.she.leg.left.low.yr
		orgPos.she.leg.right.low.zr= orgPos.she.leg.left.low.zr 
	end
	
	local poundPos = deepcopy(orgPos)
	--she
	poundPos.she.up_body.xr =  math.random(10,40)
	poundPos.she.low_body.xr = poundPos.she.low_body.xr +  math.random(0,5)*randSign() 
	poundPos.she.head.xr =  math.random(0,30)
		

	
	--he
	if math.random(1,4)>3 then
		orgPos.he.leg.right.up.xr= orgPos.he.leg.left.up.xr
		orgPos.he.leg.right.up.yr= orgPos.he.leg.left.up.yr* sidesign
		orgPos.he.leg.right.up.zr= orgPos.he.leg.left.up.zr* sidesign	
										  
		orgPos.he.leg.right.low.xr=  orgPos.he.leg.left.low.xr
		orgPos.he.leg.right.low.yr= orgPos.he.leg.left.low.yr
		orgPos.he.leg.right.low.zr= orgPos.he.leg.left.low.zr 
	end
	
	poundPos.he.up_body.xr = poundPos.he.up_body.xr  + math.random(-10,10)
	poundPos.he.head.xr =  math.random(15,35)

	legOffset = math.random(-25,-15)
	poundPos.he.leg.right.up.xr = 	poundPos.he.leg.right.up.xr + legOffset
	poundPos.he.leg.left.up.xr = 	poundPos.he.leg.left.up.xr + legOffset
	poundPos.he.leg.right.low.xr = 	poundPos.he.leg.right.low.xr - 2* legOffset
	poundPos.he.leg.left.low.xr = 	poundPos.he.leg.left.low.xr - 2* legOffset

	for i=1, iterrations do
		--contionous change
		orgPos.she.up_body.xr = orgPos.she.up_body.xr + math.random(-2,2)
			
		legOffset = math.random(5,20)
		poundPos.she.leg.right.up.xr = 	orgPos.she.leg.right.up.xr - legOffset
		poundPos.she.leg.right.low.xr =  limitLowLeg(orgPos.she.leg.right.low.xr + (2* legOffset)*randSign())

		legOffset = math.random(5,20)
		poundPos.she.leg.left.up.xr = 	orgPos.she.leg.left.up.xr - legOffset		
		poundPos.she.leg.left.low.xr = 	 limitLowLeg(orgPos.she.leg.left.low.xr + (2* legOffset)*randSign())
		
		--he
		armOffset = math.random(-20,20)		
		poundPos.he.arm.left.up.zr = orgPos.he.arm.left.up.zr + (armOffset*3)
		poundPos.he.arm.left.low.zr = orgPos.he.arm.left.low.zr - armOffset	
		poundPos.he.arm.left.low.xr = math.random(0,10)*sidesign
				
		armOffset = math.random(-20,20)		
		poundPos.he.arm.right.up.zr = orgPos.he.arm.right.up.zr + (armOffset*sidesign*3)
		poundPos.he.arm.right.low.zr = orgPos.he.arm.right.low.zr - armOffset*sidesign
		
		poundPos.he.arm.left.low.xr = math.random(0,10)
		
		--she
		armOffset= math.random(5,20)
		poundPos.she.arm.right.up.zr = orgPos.she.arm.right.up.zr - armOffset
		poundPos.she.arm.right.low.zr = orgPos.she.arm.right.low.zr - armOffset
		
		armOffset= math.random(5,20)
		poundPos.she.arm.left.up.zr = orgPos.she.arm.left.up.zr + (armOffset)
		poundPos.she.arm.left.low.zr = orgPos.she.arm.left.low.zr - armOffset
		
	
		--Transfer to orgPos
		speed= math.max(25, ((2*itterationMax)/iterrations)*i)
		timeInterval = math.ceil(25/ speed)*1000
		recursiveTurn(orgPos.she, timeInterval)
		recursiveTurn(orgPos.he, timeInterval)
		Move(p2_l_body,y_axis,0, speed)
		WaitForTurns(allPieces)
		WaitForMove(p2_l_body,y_axis)		
	 
		recursiveTurn(poundPos.she, timeInterval)
		recursiveTurn(poundPos.he, timeInterval)
		--transfer to poundPos
		Move(p2_l_body,y_axis,25*grindSign, speed)
		WaitForTurns(allPieces)
		WaitForMove(p2_l_body, y_axis) 		
	end
end



function script.Create()
    TablesOfPiecesGroups = getPieceTableByNameGroups(false, true)
	_,maxHealth = Spring.GetUnitHealth(unitID)
	Spring.SetUnitHealth(unitID, {health= maxHealth})
	StartThread(FuckFest)
	StartThread(lifeTime,unitID, GG.GameConfig.Aerosols.orgyanyl.VictimLifetime, false, true)
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitNoSelect(unitID,true)
end

function FuckFest()
	resetAll(unitID)
	Hide(center)
	-- StartThread(allTheWayDown)
	while true do

		genericSexPos()
	end
end


function script.Killed(recentDamage, _)
    --createCorpseCUnitGeneric(recentDamage)
    return 1
end
