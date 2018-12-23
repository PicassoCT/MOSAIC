--[[
This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

]] --

include "lib_UnitScript.lua"
include "lib_type.lua"

IkChain = {
    ikID = getUniqueID(),
    vSpeed = Vector:new(0, 0, 0),
    vGoal = Vector:new(0, 0, 0),
    base = Vector:new(0, 0, 0),
    segments = {}
jacobiMatrice = {},
boolGoalChanged = false,
boolIsWorldCoordinate = boolIsWorldCoordinate,
boolAktive = true,
boolCounterUnitRotation = boolCounterUnitRotation,
resolution = timeResolution,
boolDeleteIkChain = false
}

IkChain.__index = IkChain



function IkChain:isValidIKPiece(self, PieceID) --TODO Test
    if #self.segments < 1 then return false end

    for k, v in pairs(self.segments) do
        if v.pieceID == PieceID then return true end
    end
    return false
end

function IkChain:SetTransformation(self, valX, valY, valZ) --TODO Test
    for i = 0, i < 3 * #self.segments, 1 do
        -- apply the change to the theta angle
        self.segments[math.floor(i / 3)].apply_angle_change(valX, self.segments[math.floor(i / 3)].get_right());
        -- apply the change to the phi angle
        self.segments[math.floor(i / 3)].apply_angle_change(valY, self.segments[math.floor(i / 3)].get_up());
        -- apply the change to the z angle
        self.segments[math.floor(i / 3)].apply_angle_change(valZ, self.segments[math.floor(i / 3)].get_z());
    end
end

function IkChain:solveIK(self, frames)

    -- prev and curr are for use of halving
    --  last is making sure the iteration gets a better solution than the last iteration,
    --  otherwise revert changes
    local goal_point = self.goalPoint
    local current_point = Vector:new(0, 0, 0)
    prev_err, curr_err, last_err = math.huge, math.huge, math.huge
    max_iterations = 200;
    ItterationCount = 0;
    local err_margin = 0.01;

    goal_point - = self.base;
    if (goal_point.norm() > self.getMaxLength()) then
        Spring.Echo("Goal Point out of reachable sphere! Normalied to" .. self.getMaxLength())
        goal_point = (self.goalPoint.normalized() * self.getMaxLength())
    end

    current_point = self.calculate_end_effector();
    -- printPoint("Base Point:",base);
    -- printPoint("Start Point:",current_point);
    -- printPoint("Goal  Point:",goal_point);
    -- save the first err
    prev_err = (goal_point - current_point).norm()
    curr_err = prev_err
    last_err = curr_err

    --while the current point is close enough, stop iterating
    while (curr_err > err_margin) do
        -- calculate the difference between the goal_point and current_point
        local dP = goal_point - current_point;

        -- create the jacovian
        segment_size = #self.segments

        -- build the transpose matrix (easier for eigen matrix construction)
        jac_t = matrix:new(3 * segment_size, 3);
        for ( i = 1, i < 3 * segment_size, 3) do
        selector = math.floor(i / 3)
        row_theta = compute_jacovian_segment(selector, goal_point, self.segments[selector].get_right());
        row_phi = compute_jacovian_segment(selector, goal_point, self.segments[selector].get_up());
        row_z = compute_jacovian_segment(selector, goal_point, self.segments[selector].get_z());

        jac_t.setRow(i, row_theta)

        jac_t.setRow(i + 1, row_phi)

        jac_t.setRow(i + 2, row_z)
    end

        -- compute the final jacovian
        jac = jac_t.transpose()
        pinv_jac = Matrix:new(3 * segment_size, 3)
        pinv_jac = getPseudoInverse(jac)

        changes = pinv_jac * dP

        for i = 1, i < 3 * segment_size, 3 do
            selector = math.floor(i / 3)
            -- save the current transformation on the segments
            self.segments[selector].save_transformation();

            -- apply the change to the theta angle
            self.segments[selector].apply_angle_change(changes[i], segments[selector].get_right())
            -- apply the change to the phi angle
            self.segments[selector].apply_angle_change(changes[i + 1], self.segments[selector].get_up())

            -- apply the change to the z angle
            self.segments[selector].apply_angle_change(changes[i + 2], self.segments[selector].get_up())
        end

        -- compute current_point after making changes
        current_point = self.calculate_end_effector()

        --cout << "current_point: " << vectorString(current_point) << endl;
        --cout << "goal_point: " << vectorString(goal_point) << endl;

        prev_err = curr_err;
        curr_err = (goal_point - current_point).norm();

        halving_count = 0;

        -- make sure we aren't iterating past the solution
        while (curr_err > last_err) do
            -- undo changes
            for int i = 1, segment_size, 1 do
            -- unapply the change to the saved angle
            self.segments[i].load_transformation();
        end

            current_point = self.calculate_end_effector();
            changes = changes / 2;
            -- reapply halved changes
            for i = 1, 3 * segment_size, 3 do
                selector = i / 3
                -- save the current transformation on the segments
                -- segments[selector].save_transformation();

                -- apply the change to the theta angle
                self.segments[selector].apply_angle_change(changes[i], self.segments[selector].get_right());
                -- apply the change to the phi angle
                self.segments[selector].apply_angle_change(changes[i + 1], self.segments[selector].get_up());
                -- apply the change to the z angle
                self.segments[selector].apply_angle_change(changes[i + 2], self.segments[selector].get_z());
            end

            -- compute the end_effector and measure error
            current_point = self.calculate_end_effector();
            prev_err = curr_err;
            curr_err = (goal_point - current_point).norm();

            halving_count + +;
            if (halving_count > 100) then
                break
            end
        end

        if (curr_err > last_err) then
            -- undo changes
            for ( int i = 1, segment_size, i + +) do
            -- unapply the change to the saved angle
            self.segments[i].load_last_transformation();
        end
            current_point = self.calculate_end_effector();
            curr_err = (goal_point - current_point).norm();
            break
        end

        for i = 1, segment_size do
            -- unapply the change to the saved angle
            self.segments[i].save_last_transformation();
        end
        last_err = curr_err;


        -- make sure we don't infinite loop
        ItterationCount = ItterationCount + 1
        if (ItterationCount > max_iterations) then
            break
        end
    end

    self.applyIkTransformation("OVERRIDE");
end




function IkChain:SetUnitIKGoal(self, boolIsWorldCoordinate, vTarget)
    self.boolIsWorldCoordinate = boolIsWorldCoordinate
    self.vGoal = vTarget
end

function IkChain:SetUnitIKSpeed(self)
end

function IkChain:SetUnitIKPieceLimits(self, pieceNumber, vLimX, vLimY, vLimZ)
end


function IkChain:getPseudoInverse(jac)


    ----------------------------------------------------------------------
    -- Template for the pseudo Inverse
    ----------------------------------------------------------------------
    -- template<typename _Matrix_Type_>
    -- _Matrix_Type_ pseudoInverse(const _Matrix_Type_ &a, double epsilon =
    -- std::numeric_limits<double>::epsilon())
    -- {
    -- Eigen::JacobiSVD< _Matrix_Type_ > svd(a ,Eigen::ComputeThinU |
    -- Eigen::ComputeThinV);

    -- double tolerance =  epsilon * std::max(a.cols(), a.rows()) *svd.singularValues().array().abs()(0);
    -- return svd.matrixV() *  (svd.singularValues().array().abs() >
    -- tolerance).select(svd.singularValues().array().inverse(),
    -- 0).matrix().asDiagonal() * svd.matrixU().adjoint();
    -- }
    ----------------------------------------------------------------------
end


--Returns the Negated Accumulated Rotation
function IkChain:GetBoneBaseRotation(self) -- Point3f IkChain::GetBoneBaseRotation()

    accumulatedRotation = Vector:new(0, 0, 0)
    modelRot = Vector:new(0, 0, 0)
    self.LocalModelPiece * parent = segments[0].piece
    --if the goalPoint is a world coordinate, we need the units rotation out of the picture

    -- while (parent != NULL)then
    -- modelRot= parent->GetRotation();
    -- accumulatedRotation[0] -= modelRot.x;
    -- accumulatedRotation[1] -= modelRot.y;
    -- accumulatedRotation[2] -= modelRot.z;

    -- parent = (parent->parent != NULL? parent->parent: NULL);

    -- }

    --add unit rotation on top
    -- if (isWorldCoordinate)then
    -- const CMatrix44f& matrix = unit->GetTransformMatrix(true);
    -- assert(matrix.IsOrthoNormal());
    -- const float3 angles = matrix.GetEulerAnglesLftHand();

    -- accumulatedRotation(0,0) += angles.x;
    -- accumulatedRotation(1,0) += angles.y;
    -- accumulatedRotation(2,0) += angles.z;
    -- }

    -- return accumulatedRotation;
    -- }
end



function IkChain:compute_jacovian_segment(segmentNum, vGoalPoint, vAngle)
    --returns a Point (1 Column, 3 Rows)
    --Returns a Jacovian Segment a row of 3 Elements
    -- Matrix<float, 1, 3>  IkChain::compute_jacovian_segment(int seg_num, Vector3f  goalPoint, Point3f angle) 

    -- Segment *s = &(segments.at(seg_num));
    -- mini is the amount of angle you go in the direction for numerical calculation
    -- float mini = 0.0005;

    -- Point3f transformed_goal = goalPoint;
    -- for(int i=segments.size()-1; i>seg_num; i--) then
    -- transform the goal point to relevence to this segment
    -- by removing all the transformations the segments afterwards
    -- apply on the current segment
    -- transformed_goal -= segments[i].get_end_point();
    -- }

    -- Point3f my_end_effector = calculate_end_effector(seg_num);

    -- transform them both to the origin
    -- if (seg_num-1 >= 0) then
    -- my_end_effector -= calculate_end_effector(seg_num-1);
    -- transformed_goal -= calculate_end_effector(seg_num-1);
    -- }

    -- original end_effector
    -- Point3f original_ee = calculate_end_effector();

    -- angle input is the one you rotate around
    -- remove all the rotations from the previous segments by applying them
    -- AngleAxisf t = AngleAxisf(mini, angle);

    -- transform the segment by some delta(theta)
    -- s->transform(t);
    -- new end_effector
    -- Point3f new_ee = calculate_end_effector();

    -- reverse the transformation afterwards
    -- s->transform(t.inverse());

    -- difference between the end_effectors
    -- since mini is very small, it's an approximation of
    -- the derivative when divided by mini
    -- Vector3f  diff = new_ee - original_ee;

    -- return the row of dx/dtheta, dy/dtheta, dz/dtheta
    -- Matrix<float, 1, 3> ret;
    -- ret << diff[0]/mini, diff[1]/mini, diff[2]/mini;
    -- return ret;
    -- }
end

function calculateEndEffector(self, pSgementNumber)

    --  computes end_effector up to certain number of segments

    local vecReti = self.base()

    for i = 1; #self.segments do
        vecReti = vecReti + self.segments[i].get_end_point()
    end

    -- return calculated end effector
    return vecReti
end




function todoGetUnitMatrice()
end


-- /******************************************************************************/
function IkChain:transformGoalToUnitSpace(self, vecGoal) --TODO test
    matrice = todoGetUnitMatrice()

    vTemp = { [1] = vecGoal.x, [2] = vecGoal.y, [3] = vecGoal.z, [4] = 1 }
    vGoal = { [1] = vecGoal.x, [2] = vecGoal.y, [3] = vecGoal.z, [4] = 1 }
    for y = 1, 4 do
        sum = 0
        for idx = 1, 4 do
            sum = sum + matrice[y][idx] * vecGoal[idx]
        end
        vGoal[y] = sum
    end

    --normalize it
    for y = 1, 4 do
        vGoal[y] = vGoal[y] / vGoal[4]
    end

    return vecGoal
end

function IkChain:getMaxLength(self) --TODO test
    totalLength = 0
    for k, segment in pairs(self.segments) do
        totalLength = totalLength + segment.magnitude
    end
    return totalLength
end

function IkChain:printIkChain(self)
    for k, segment in pairs(self.segments) do
        segment:printSelf()
    end
end

function IkChain:createJacobiMatrice(self)
    --TODO implement
end

function IkChain:applyTransformation(motionBlendMethod)
    -- GoalChanged=false;
    --The Rotation the Pieces accumulate, so each piece can roate as if in world
    -- Point3f pAccRotation= GetBoneBaseRotation();
    -- pAccRotation= Point3f(0,0,0);

    --Get the Unitscript for the Unit that holds the segment
    -- for (auto seg = segments.begin(); seg !=  segments.end(); ++seg) then
    -- seg->alteredInSolve = true;

    -- Point3f velocity = seg->velocity;
    -- Point3f rotation = seg->get_rotation();

    -- rotation -= pAccRotation;
    -- pAccRotation+= rotation;

    -- unit->script->AddAnim(   CUnitScript::ATurn,
    -- (int)(seg->pieceID),  --pieceID 
    -- xAxis,--axis  
    -- 1.0,--velocity(0,0),-- speed
    -- rotation[0], --TODO jointclamp this
    -- 0.0f --acceleration
    -- );

    -- unit->script->AddAnim( CUnitScript::ATurn,
    -- (int)(seg->pieceID),  --pieceID 
    -- yAxis,--axis  
    -- 1.0,--,-- speed
    -- rotation[1], --TODO jointclamp this
    -- 0.0f --acceleration
    -- );

    -- unit->script->AddAnim(  CUnitScript::ATurn,
    -- (int)(seg->pieceID),  --pieceID 
    -- zAxis,--axis  
    -- 1.0,-- speed
    -- rotation[2], --TODO jointclamp this
    -- 0.0f --acceleration
    -- );
    -- }
end

function get_end_point(self) echo("Todo") end

function set_LimitJoint(self) echo("Todo") end

function clampJoint(self) echo("Todo") end

function get_Rotation(self) echo("Todo") end

function get_right(self) echo("Todo") end

function get_up(self) echo("Todo") end

function get_z(self) echo("Todo") end

function get_T(self) echo("Todo") end

function get_Magnitude(self) echo("Todo") end

function save_transformation(self) echo("Todo") end

function load_transformation(self) echo("Todo") end

function save_last_transformation(self) echo("Todo") end

function load_last_transformation(self) echo("Todo") end

function apply_angle_change(self) echo("Todo") end

function resetSegment(self) echo("Todo") end

function randomizeSegment(self) echo("Todo") end

function transformSegment(self) echo("Todo") end

function IkChain:new(unitID, startPiece, endPiece, timeResolution, boolIsWorldCoordinate, boolCounterUnitRotation)
    boolStartPieceValid, _ = checkPiece(unitID, startPiece)
    boolEndPieceValid, PiecList = checkPiece(unitID, endPiece)
    if not boolStartPieceValid or not boolEndPieceValid then return nil, false end
    --forge IK-Chain

    pieceHierarchy = getPieceHierarchy(unitID, piece)
    pieceChain = getPieceChain(pieceHierarchy, startPiece, endPiece)

    for i = 1, table.getn(pieceChain) do
        ikChain.segments[i] = {
            pieceID = pieceChain[i],
            Transformation = AngleAxis:new(0, 0),
            savedTransformation = AngleAxis:new(0, 0),
            lastTransformation = AngleAxis:new(0, 0),
            savedAngle = Vector:new(0, 0, 0),
            pUnitNextPieceBasePoint = Vector:new(0, 0, 0),
            pUnitPieceBasePoint = Vector:new(0, 0, 0),
            magnitude = 0.0,
            vOrgDirVec = Vector:new(0, 0, 0),
        }
        setmetatable(ikChain.segments[i], get_end_point)
        setmetatable(ikChain.segments[i], set_LimitJoint)
        setmetatable(ikChain.segments[i], clampJoint)
        setmetatable(ikChain.segments[i], get_Rotation)
        setmetatable(ikChain.segments[i], get_right)
        setmetatable(ikChain.segments[i], get_up)
        setmetatable(ikChain.segments[i], get_z)
        setmetatable(ikChain.segments[i], get_T)
        setmetatable(ikChain.segments[i], get_Magnitude)
        setmetatable(ikChain.segments[i], save_transformation)
        setmetatable(ikChain.segments[i], load_transformation)
        setmetatable(ikChain.segments[i], save_last_transformation)
        setmetatable(ikChain.segments[i], load_last_transformation)
        setmetatable(ikChain.segments[i], apply_angle_change)
        setmetatable(ikChain.segments[i], resetSegment)
        setmetatable(ikChain.segments[i], randomizeSegment)
        setmetatable(ikChain.segments[i], transformSegment)
    end


    ikChain = initIkChain(ikChain)
    ikChain.jacobiMatrice = createJacobiMatrice(ikChain)



    StartThread(ikLoop, ikChain)
    return ikChain, ikChain.ikID
end

function IkChain:ikLoop(self)
    while self.boolDeleteIkChain == false do
        Sleep(self.resolution)
        while self.boolAktive == true do
            self:solveIK()
            Sleep(self.resolution)
        end
    end
end

setmetatable(IkChain, { __call = function(_, ...) return IkChain.new(...) end })	

--[[
/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#ifndef IKCHAIN
#define IKCHAIN

#include <vector>
#include "Segment.h"
#include "point3f.h"

using namespace Eigen;

class LocalModelPiece;
class LocalModel;
class CUnit;


typedef enum {
	OVERRIDE,
	BLENDIN
} MotionBlend;


///Class Ikchain- represents a Inverse Kinmatik Chain
class IkChain
{

public:
	enum AnimType {ANone = -1, ATurn = 0, ASpin = 1, AMove = 2};
	
	
	enum Axis {xAxis = 0, yAxis = 1, zAxis =2 };
	///Constructors 
	IkChain();
	
	//Create the segments
	IkChain(int id, CUnit* unit, LocalModelPiece* startPiece, unsigned int startPieceID, unsigned int endPieceID);

	//Was the Goal altered
	bool GoalChanged=true;

	//is the GoalPoint a World Coordinate?
	bool isWorldCoordinate =false;

	//Helper Function to inialize the Path recursive
	bool recPiecePathExplore(LocalModelPiece* parentLocalModel, unsigned int parentPiece, unsigned int endPieceNumber, int depth);
	bool initializePiecePath(LocalModelPiece* startPiece, unsigned int startPieceID, unsigned int endPieceID);
	
	//Checks wether a Piece is part of this chain
	bool isValidIKPiece(float pieceID);

	//Transfers a global Worldspace coordinate into a unitspace coordinate
	Point3f TransformGoalToUnitspace(Point3f goal);

	//IK is active or paused
	bool IKActive ;

	//Setter
	void SetActive (bool isActive);

	//Solves the Inverse Kinematik Chain for a new goal point
	//Returns wether a ik-solution could be found
	void solve(float frames );
	//apply the resolved Kinematics to the actual Model
	void applyIkTransformation(MotionBlend motionBlendMethod);

	//Set Piece Limitations

	//Get the Next PieceNumber while building the chain
	int GetNextPieceNumber(float PieceNumber);


	//Creates a Jacobi Matrice
	Matrix<float,1,3> compute_jacovian_segment(int seg_num, Point3f goal_point, Vector3f  angle);

	// computes end_effector up to certain number of segments
	Point3f calculate_end_effector(int segment_num = -1);

	//Gets the basic bone rotation for the piece 
	//TODO it would be a great performance saviour if there was a flag 
	Point3f GetBoneBaseRotation(void);

	//unit this IKChain belongs too
	CUnit* unit;

	//Identifier of the Kinematik Chain
	float IkChainID;

	//The baseposition in WorldCoordinats
	Point3f base;

	//Set the Anglke for the Transformation matrice
	void SetTransformation(float valX, float valY, float valZ);

	// the goal Point also in World Coordinats
	Point3f goalPoint;

	//Vector containing the Segments
	std::vector <Segment> segments;
	
	// determinates the initial direction of the  ik-system
	void determinateInitialDirection(void);
	
	//First Segment
	bool bFirstSegment = true;
	
	//Initial Default direction of the Kinematik system
	Point3f vecDefaultlDirection;

	//Size of Segment
	//int segment_size ;

	//Plots the whole IK-Chain
	void print();
	
	//Debug function
	void printPoint( const char* name, float x, float y, float z);
	void printPoint( const char* name, Point3f point);
	//Destructor
	~IkChain();
private:

	//TODO find out what this one does
	Point3f calculateEndEffector(int Segment = -1);

	//Get the max Lenfgth of the IK Chain
	float getMaxLength();
};

#endif // IKCHAIN

]]

--[[
#include "IkChain.h"
#include "Unit.h"
//#include "point3f.h"
#include "Rendering/Models/3DModel.h"
#include "Sim/Units/Scripts/UnitScript.h"
#include <iostream>

// See end of source for member bindings
//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////


//checks wether a IK-Chain contains a piece 
bool IkChain::isValidIKPiece(float pieceID){
		if (segments.empty()) {return false;}

		for (auto seg = segments.begin(); seg !=  segments.end(); ++seg) 
		{
		  if ((*seg).pieceID == pieceID) return true;
		}

return false;
}

void IkChain::SetActive(bool isActive)
{
	IKActive  = isActive;
}

void IkChain::SetTransformation(float valX, float valY, float valZ)
{
		//Initiator
	    for(int i=0; i<3*segments.size(); i+=3) {
			// apply the change to the theta angle
		    segments[i/3].apply_angle_change(valX ,segments[i/3].get_right());
			// apply the change to the phi angle
			segments[i/3].apply_angle_change(valY, segments[i/3].get_up());
			// apply the change to the z angle
		    segments[i/3].apply_angle_change(valZ, segments[i/3].get_z());
		}	
	
}

void IkChain::determinateInitialDirection(void){
	bFirstSegment = false;
	
	vecDefaultlDirection =  segments[1].get_end_point() - segments[0].get_end_point();
	}
	

//recursive explore the model and find the end of the IK-Chain
bool IkChain::recPiecePathExplore(  LocalModelPiece* parentLocalModelPiece, 
									unsigned int parentPiece,
									unsigned int endPieceNumber, 
									int depth){
										
									
	//Get DecendantsNumber
	for (auto piece = (*parentLocalModelPiece).children.begin(); piece !=  (*parentLocalModelPiece).children.end(); ++piece) 
		{
		   //we found the last piece of the kinematikChain --unsigned int compared with
			if ((*piece)->scriptPieceIndex ==  endPieceNumber){
			//	std::cout<<"Piece at :"<< depth << " piecnr - > "<<((*piece))->scriptPieceIndex <<std::endl;

				//lets gets size as a float3
				float3 scale = (*piece)->GetCollisionVolume()->GetScales();
				
				segments.resize(depth+1);
				assert(!segments.empty() && (segments.size() == (depth+1)));
				segments[depth] = Segment((*piece)->scriptPieceIndex, (*piece), scale.y, BALLJOINT);

				return true;
			}
			
			//if one of the pieces children is the endpiece backtrack
			if (recPiecePathExplore((*piece), 
									(*piece)->scriptPieceIndex , 
									endPieceNumber, 
									depth+1 ) == true)
			{
			//   std::cout<<"Piece at :"<< depth << " piecnr - > "<<((*piece))->scriptPieceIndex <<std::endl;
					
					//we assume correctness and determinate the initial armconfig
			if (bFirstSegment)  determinateInitialDirection()
	
				
				
				//Get the magnitude of the bone - extract the startPoint of the successor
				float3 posBase = segments[depth+1].piece->GetAbsolutePos();

				Point3f pUnitNextPieceBasePointOffset= Point3f(posBase.x,posBase.y,posBase.z);

				assert(!segments.empty() );
				segments[depth] =Segment((*piece)->scriptPieceIndex, (*piece), pUnitNextPieceBasePointOffset, BALLJOINT);

				return true;		
			}
		}
return false;
}

bool IkChain::initializePiecePath(LocalModelPiece* startPiece, unsigned int startPieceID,unsigned int endPieceID){
	bool initializationComplete=false;
	//Check for 
	if ( startPieceID < 1 || endPieceID < 1 ) return initializationComplete;

	initializationComplete = recPiecePathExplore(startPiece, startPieceID, endPieceID, 0);
	
	//Lets correct the direction of the last piece 
	segments[segments.size()].orgDirVec = segments[segments.size()-1].orgDirVec.normalized() * segments[segments.size()].mag;
	
	
	return initializationComplete;
}

IkChain::IkChain(int id, CUnit* unit, LocalModelPiece* startPiece, unsigned int startPieceID, unsigned int endPieceID )
{
	this->unit= unit;
	//segment_size=0;
	//std::cout<< "start,endpiece"<<startPieceID <<" / " <<endPieceID <<std::endl;
	  if( initializePiecePath(startPiece, (unsigned int) startPieceID, (unsigned int) endPieceID) == false) {
		std::cout<<"Startpiece is beneath Endpiece - Endpiece could not be found"<<std::endl;
	  }
	 
	// pre initialize all the Points - and the 
	float3 piecePos= startPiece->GetAbsolutePos();
	base		= Point3f(piecePos.x,piecePos.y,piecePos.z);
	goalPoint   = Point3f(0,0,0);

	IKActive= false;
	IkChainID = id;
	
	SetTransformation(0,0,0);
	
}
void IkChain::printPoint( const char* name, Point3f point)
{
	printPoint(name, point[0], point[1], point[2]);
}


void IkChain::printPoint( const char* name, float x, float y, float z)
{
	std::cout << "	<<--------------------------------"<<std::endl;
	std::cout << "	"<<name<< "=	X: ("<<x<<") "<<" Y: ("<<y<<") "<<" Z: ("<<z<<") "<<std::endl;
	std::cout << "	---------------------------------->> "<<std::endl;
}


void IkChain::print()
{
	
	Point3f transformed;
	transformed = goalPoint.normalized() * getMaxLength();

	std::cout<<  "============================================== "<<std::endl;
	std::cout<<  " IkChain = "<<std::endl;
	std::cout<<  "	[[ "<<std::endl;
	printPoint("GoalPoint:", goalPoint(0,0),goalPoint(1,0),goalPoint(2,0));
	printPoint("Clamped Goal:", transformed[0],transformed[1],transformed[2]);
	printPoint("Base:", base(0,0),base(1,0),base(2,0));
	std::cout<<"MaxLength: "<< getMaxLength()<<std::endl;
	std::cout<<"isWorldCoordinate: "<<isWorldCoordinate <<std::endl;

		for (auto seg = segments.begin(); seg != segments.end(); ++seg) 
		{
			seg->print();
		}
	std::cout<< "	]] "<<std::endl;
	std::cout<<  "============================================== "<<std::endl;

}

IkChain::~IkChain()
{
	//Release the Pieces
}
//////////////////////////////////////////////////////////////////////
// Template for the pseudo Inverse
//////////////////////////////////////////////////////////////////////
template<typename _Matrix_Type_>
_Matrix_Type_ pseudoInverse(const _Matrix_Type_ &a, double epsilon =
std::numeric_limits<double>::epsilon())
{
	Eigen::JacobiSVD< _Matrix_Type_ > svd(a ,Eigen::ComputeThinU |
	Eigen::ComputeThinV);

	double tolerance =  epsilon * std::max(a.cols(), a.rows()) *svd.singularValues().array().abs()(0);
	return svd.matrixV() *  (svd.singularValues().array().abs() >
	tolerance).select(svd.singularValues().array().inverse(),
	0).matrix().asDiagonal() * svd.matrixU().adjoint();
}
//////////////////////////////////////////////////////////////////////
float IkChain::getMaxLength(){
	float totalDistance=0.0001;
  //Get DecendantsNumber
	for (auto seg = segments.begin(); seg != segments.end(); ++seg) 
	{
		totalDistance += seg->get_mag();
	}
		
return totalDistance;
}

Point3f IkChain::TransformGoalToUnitspace(Point3f goal){
	float3 fGoal= float3(goal(0,0),goal(1,0),goal(2,0));
	float3 unitPoint =unit->GetTransformMatrix()*fGoal;
	return Point3f(unitPoint.x ,unitPoint.y,unitPoint.z);
}

void IkChain::solve( float  life_count) 
{
	// prev and curr are for use of halving
	// last is making sure the iteration gets a better solution than the last iteration,
	// otherwise revert changes
	Point3f goal_point;
	goal_point = this->goalPoint;
    float prev_err, curr_err, last_err = 9999;
    Point3f current_point;
    int max_iterations = 200;
    int count = 0;
    float err_margin = 0.01;

    goal_point -= base;
    if (goal_point.norm() > this->getMaxLength()) {
		std::cout<<"Goal Point out of reachable sphere! Normalied to" << this->getMaxLength()<<std::endl;
	    goal_point =  ( this->goalPoint.normalized() * this->getMaxLength());
	}
	
    current_point = calculate_end_effector();
	printPoint("Base Point:",base);
	printPoint("Start Point:",current_point);
	printPoint("Goal  Point:",goal_point);
	// save the first err
    prev_err = (goal_point - current_point).norm();
    curr_err = prev_err;
    last_err = curr_err;

	// while the current point is close enough, stop iterating
    while (curr_err > err_margin) {
		// calculate the difference between the goal_point and current_point
	    Vector3f dP = goal_point - current_point;

		// create the jacovian
	    int segment_size = segments.size();

		// build the transpose matrix (easier for eigen matrix construction)
	    MatrixXf jac_t(3*segment_size, 3);
	    for(int i=0; i<3*segment_size; i+=3) {
		    Matrix<float, 1, 3> row_theta =compute_jacovian_segment(i/3, goal_point, segments[i/3].get_right());
		    Matrix<float, 1, 3> row_phi = compute_jacovian_segment(i/3, goal_point, segments[i/3].get_up());
		    Matrix<float, 1, 3> row_z = compute_jacovian_segment(i/3, goal_point, segments[i/3].get_z());

		    jac_t(i, 0) = row_theta(0, 0);
		    jac_t(i, 1) = row_theta(0, 1);
		    jac_t(i, 2) = row_theta(0, 2);

		    jac_t(i+1, 0) = row_phi(0, 0);
		    jac_t(i+1, 1) = row_phi(0, 1);
		    jac_t(i+1, 2) = row_phi(0, 2);

		    jac_t(i+2, 0) = row_z(0, 0);
		    jac_t(i+2, 1) = row_z(0, 1);
		    jac_t(i+2, 2) = row_z(0, 2);
		}

		// compute the final jacovian
	    MatrixXf jac(3, 3*segment_size);
	    jac = jac_t.transpose();

	    Matrix<float, Dynamic, Dynamic> pseudo_ijac;
	    MatrixXf pinv_jac(3*segment_size, 3);
	    pinv_jac = pseudoInverse(jac);

	    Matrix<float, Dynamic, 1> changes = pinv_jac * dP;


	    for(int i=0; i<3*segment_size; i+=3) {
			// save the current transformation on the segments
		    segments[i/3].save_transformation();

			// apply the change to the theta angle
		    segments[i/3].apply_angle_change(changes[i], segments[i/3].get_right());
			// apply the change to the phi angle
			//segments[i/3].apply_angle_change(3.1415/3, segments[i/3].get_up());
			segments[i/3].apply_angle_change(changes[i+1], segments[i/3].get_up());
			// apply the change to the z angle
		    segments[i/3].apply_angle_change(changes[i+2], segments[i/3].get_z());
		}

		// compute current_point after making changes
	    current_point = calculate_end_effector();

		//cout << "current_point: " << vectorString(current_point) << endl;
		//cout << "goal_point: " << vectorString(goal_point) << endl;

	    prev_err = curr_err;
	    curr_err = (goal_point - current_point).norm();

	    int halving_count = 0;

		// make sure we aren't iterating past the solution
	    while (curr_err > last_err) {
			// undo changes
		    for(int i=0; i<segment_size; i++) {
				// unapply the change to the saved angle
			    segments[i].load_transformation();
			}
		    current_point = calculate_end_effector();
		    changes *= 0.5;
			// reapply halved changes
		    for(int i=0; i<3*segment_size; i+=3) {
				// save the current transformation on the segments
			    segments[i/3].save_transformation();

				// apply the change to the theta angle
			   // segments[i/3].apply_angle_change(3.1415/8, segments[i/3].get_right());
				segments[i/3].apply_angle_change(changes[i], segments[i/3].get_right());
				// apply the change to the phi angle
			    segments[i/3].apply_angle_change(changes[i+1], segments[i/3].get_up());
				// apply the change to the z angle
			    segments[i/3].apply_angle_change(changes[i+2], segments[i/3].get_z());
			}

			// compute the end_effector and measure error
		    current_point = calculate_end_effector();
		    prev_err = curr_err;
		    curr_err = (goal_point - current_point).norm();

		    halving_count++;
		    if (halving_count > 100)
			    break;
		}

	    if (curr_err > last_err) {
			// undo changes
		    for(int i=0; i<segment_size; i++) {
				// unapply the change to the saved angle
			    segments[i].load_last_transformation();
			}
		    current_point = calculate_end_effector();
		    curr_err = (goal_point - current_point).norm();
		    break;
		}
	    for(int i=0; i<segment_size; i++) {
			// unapply the change to the saved angle
		    segments[i].save_last_transformation();
		}
	    last_err = curr_err;


		// make sure we don't infinite loop
	    count++;
	    if (count > max_iterations) {
		    break;
		}
	}

	applyIkTransformation(OVERRIDE);
   }

//Returns the Negated Accumulated Rotation
Point3f IkChain::GetBoneBaseRotation()
{
	Point3f accumulatedRotation = Point3f(0,0,0);
	float3  modelRot;
	LocalModelPiece * parent = segments[0].piece;
	//if the goalPoint is a world coordinate, we need the units rotation out of the picture
  
	while (parent != NULL){
		modelRot= parent->GetRotation();
		accumulatedRotation[0] -= modelRot.x;
		accumulatedRotation[1] -= modelRot.y;
		accumulatedRotation[2] -= modelRot.z;
		
		parent = (parent->parent != NULL? parent->parent: NULL);
			
	}

	//add unit rotation on top
	if (isWorldCoordinate){
		const CMatrix44f& matrix = unit->GetTransformMatrix(true);
		assert(matrix.IsOrthoNormal());
		const float3 angles = matrix.GetEulerAnglesLftHand();

		accumulatedRotation(0,0) += angles.x;
		accumulatedRotation(1,0) += angles.y;
		accumulatedRotation(2,0) += angles.z;
	}
	
return accumulatedRotation;
}
	
void IkChain::applyIkTransformation(MotionBlend motionBlendMethod){

	GoalChanged=false;


	//The Rotation the Pieces accumulate, so each piece can roate as if in world
	Point3f pAccRotation= GetBoneBaseRotation();
	pAccRotation= Point3f(0,0,0);
	
		//Get the Unitscript for the Unit that holds the segment
		for (auto seg = segments.begin(); seg !=  segments.end(); ++seg) {
			seg->alteredInSolve = true;

			Point3f velocity = seg->velocity;
			Point3f rotation = seg->get_rotation();

			rotation -= pAccRotation;
			pAccRotation+= rotation;

			unit->script->AddAnim(   CUnitScript::ATurn,
									(int)(seg->pieceID),  //pieceID 
									xAxis,//axis  
									1.0,//velocity(0,0),// speed
									rotation[0], //TODO jointclamp this
									0.0f //acceleration
									);

			unit->script->AddAnim( CUnitScript::ATurn,
									(int)(seg->pieceID),  //pieceID 
									yAxis,//axis  
									1.0,//,// speed
									rotation[1], //TODO jointclamp this
									0.0f //acceleration
									);

			unit->script->AddAnim(  CUnitScript::ATurn,
									(int)(seg->pieceID),  //pieceID 
									zAxis,//axis  
									1.0,// speed
									rotation[2], //TODO jointclamp this
									0.0f //acceleration
									);
		}
}


// computes end_effector up to certain number of segments
Point3f IkChain::calculate_end_effector(int segment_num /* = -1 */) {
	Point3f reti;

	int segment_num_to_calc = segment_num;
	// if default value, compute total end effector
	if (segment_num == -1) {
		segment_num_to_calc = segments.size() - 1;
	}
	// else don't mess with it

	// start with base
	reti = base;
	for(int i=0; i<=segment_num_to_calc; i++) {
		// add each segments end point vector to the base
		reti += segments[i].get_end_point();
	}
	// return calculated end effector
	return reti ;
}


//Returns a Jacovian Segment a row of 3 Elements
Matrix<float, 1, 3>  IkChain::compute_jacovian_segment(int seg_num, Vector3f  goalPoint, Point3f angle) 
{
	Segment *s = &(segments.at(seg_num));
	// mini is the amount of angle you go in the direction for numerical calculation
	float mini = 0.0005;

	Point3f transformed_goal = goalPoint;
	for(int i=segments.size()-1; i>seg_num; i--) {
		// transform the goal point to relevence to this segment
		// by removing all the transformations the segments afterwards
		// apply on the current segment
		transformed_goal -= segments[i].get_end_point();
	}

	Point3f my_end_effector = calculate_end_effector(seg_num);

	// transform them both to the origin
	if (seg_num-1 >= 0) {
		my_end_effector -= calculate_end_effector(seg_num-1);
		transformed_goal -= calculate_end_effector(seg_num-1);
	}

	// original end_effector
	Point3f original_ee = calculate_end_effector();

	// angle input is the one you rotate around
	// remove all the rotations from the previous segments by applying them
	AngleAxisf t = AngleAxisf(mini, angle);

	// transform the segment by some delta(theta)
	s->transform(t);
	// new end_effector
	Point3f new_ee = calculate_end_effector();
	
	// reverse the transformation afterwards
	s->transform(t.inverse());

		// difference between the end_effectors
	// since mini is very small, it's an approximation of
	// the derivative when divided by mini
	Vector3f  diff = new_ee - original_ee;

	// return the row of dx/dtheta, dy/dtheta, dz/dtheta
	Matrix<float, 1, 3> ret;
	ret << diff[0]/mini, diff[1]/mini, diff[2]/mini;
	return ret;
}

// computes end_effector up to certain number of segments
Point3f IkChain::calculateEndEffector(int segment_num /* = -1 */) {
	Point3f ret;

	int segment_num_to_calc = segment_num;
	// if default value, compute total end effector
	if (segment_num == -1) {
		segment_num_to_calc = segments.size() - 1;
	}
	// else don't mess with it

	// start with base
	ret = base;
	for(int i=0; i<=segment_num_to_calc; i++) {
		// add each segments end point vector to the base
		ret += segments[i].get_end_point();
	}
	// return calculated end effector
	return ret;
}
]]