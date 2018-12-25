--//=============================================================================
VFS.Include(CHILI_DIRNAME .. "headers/borderline.lua", nil, VFS.RAW_FIRST)
VFS.Include(CHILI_DIRNAME .. "headers/util.lua", nil, VFS.RAW_FIRST)
--- HabaneroButton module

--- HabaneroButton fields.
-- Inherits from Control.
-- @see control.Control
-- @table HabaneroButton
-- @string[opt="HabaneroButton"] caption caption to be displayed
HabaneroButton = Control:Inherit{
	classname= "HabaneroButton",
	caption = 'HabaneroButton', 
	--local Coordinates
	defaultWidth = 70,
	width= 0,
	defaultHeight = 20,
	heigth = 0,
	xMin= 0,
	xMax = 1,
	yMin = 0,
	yMax = 1,
	midPointX=0,
	midPointY=0,
	boolInFocus=false,
	boolRelativePixelSize = false,
	cmdID = 0,
	numberOfStates= 3,
	currentState = 1,
	boolSelectable= false,
	boolSelected = false,

	currentColor = {0,0,0,1},
	selectedTextColor ={1,1,1,1},
	unselectedTextColor ={0,0,0,1},
	stateColors={
				[1]={245/255,64/255,9/255, 0.6},
				[2]={24/255,238/255,191/255, 0.6},
				[3]={27/255,234/255,31/255, 0.6}
				},
	stateOffset = 0,
	
	borderline ={},
	boolBorder= false,
	borderColor = { 0, 0, 0.1, 1},
	borderType = "static",

	--focusColor
	--activeColor
	--backgroundColor
	--stateTriColor[3]
	
	--Points in Order, Clockwise in local Coordinates - last coordinate is a Copy of the first
	--triStrip should not be self-intersecting or incomplete
	triStrip ={}
}

local this = HabaneroButton
local inherited = this.inherited

--//=============================================================================

--- Sets the caption of the HabaneroButton
-- @string caption new caption of the HabaneroButton
function HabaneroButton:SetCaption(caption)
	if (self.caption == caption) then return end
	self.caption = caption
	self:Invalidate()
end

function HabaneroButton:FlipState(cmd)
	if (self.boolSelectable == true) then self.boolSelectable = false else self.boolSelectable = true end
end

function HabaneroButton:SetSelectable( bActive )
	self.boolSelectable = bActive	
	self:setCurrentColorByState()
	self:Invalidate()
end
function HabaneroButton:SetSelected( bActive )
	self.boolSelected = bActive	
	self:setCurrentColorByState()
	self:Invalidate()
end

function boolToNumber(bool)
if type(bool) ~= "boolean" then return bool end
if bool == true then return 1;else return 0 ;end
end

function HabaneroButton:SetState( State, StateMax )
	State = boolToNumber(State) + self.stateOffset

	self.numberOfStates = StateMax
	self.currentState = ((State - 1 ) % self.numberOfStates)+1
	
	self:setCurrentColorByState()
	self:Invalidate()
end

--//=============================================================================


--//=============================================================================

function HabaneroButton:DrawControl()
	--// gets overriden by the skin/theme
end

--//=============================================================================
function getZeroScreen(this)
	while this.parent do 	this = this.parent;	end
	
	return this
end


function HabaneroButton:mixByStateFactor(self, factor, smallestStep)
	if #self.stateColors < 2 then return self.stateColors[1]end

	lowerStep= math.max(1,math.floor((factor*self.numberOfStates)/smallestStep))
	upperStep= math.min(math.ceil((factor*self.numberOfStates)/smallestStep), self.numberOfStates)

	return mixTable(self.stateColors[lowerStep],self.stateColors[upperStep], (factor-(lowerStep*smallestStep)/smallestStep))
end

function HabaneroButton:setCurrentColorByState()
	self.font.color = self.unselectedTextColor
	self.currentColor = self.backgroundColor
		
	if self.boolSelectable == true then
		self.font.color = self.selectedTextColor	
		self.currentColor = mixTable(self.activeColor, self.backgroundColor,0.5)	
	end
	
	if self.boolInFocus == true and self.boolSelectable == true  then	
		self.currentColor = self.focusColor
	end
	
	if self.boolSelected == true then
		self.currentColor = self.activeColor
	end

	if string.find(self.name, 'statebutton') and self.boolSelectable == true then
		index = math.max(1, math.min(self.numberOfStates,self.currentState))
		factor= index/self.numberOfStates
		
		self.currentColor = self:mixByStateFactor(self, factor, #self.stateColors/self.numberOfStates)
	end
end

function getRecursivePixelDimensions(this)
	if this.parent then
		if this.parent.width and this.parent.height then
			typeWidth, typeHeight = type(this.parent.width) , type(this.parent.height)
			
			if typeWidth == "string" and typeHeight == "string" then
				factorWidth = 100/tonumber(string.sub(this.parent.width,'%%',''))
				factorHeigth = 100/tonumber(string.sub(this.parent.heigth,'%%',''))
				px,py = getRecursivePixelDimensions(this.parent)
				return factorWidth* px, factorHeigth * py
			else
				return this.parent.width, this.parent.height
			end
		end
	end
	
	return this.width, this.height
end

--> gets the parents of the handed objects absolut size in pixel, and the gridslotdimensions
function getParentTotalSizePixel(self)
	--debugging
	zeroScreen = getZeroScreen(self)
	
	--no parent
	if not self.parent then error("No parent existing for HabaneroButton "..self.caption); return end
	
	--self is root
	if self == zeroScreen then
		return zeroScreen.width, zeroScreen.height	
	end
	
	typeX,typeY=type(self.parent.width),type(self.parent.height)
	rows,columns = self.parent.rows or 1 , self.parent.columns or 1
	
	if typeX == "string" and typeY == "string" then
		px,py = getRecursivePixelDimensions(self.parent)
		return px, py, rows, columns
	else
		return self.parent.width, self.parent.height, rows, columns
	end
	
end



--> generates a trianglestrip from a outline
function convertOutlineToTriStrip(outline)
	midPoint={x=0,y=0}
	for i=1,#outline do
		midPoint.x,midPoint.y = midPoint.x + outline[i].x,midPoint.y + outline[i].y
	end
	midPoint.x,midPoint.y= midPoint.x/#outline , midPoint.y/#outline
	
	ltriStrip={}
	for i=1,#outline do
		ltriStrip[3*(i-1)+1] = {x=outline[i].x,y=outline[i].y}
		ltriStrip[3*(i-1)+2]= {x=midPoint.x, y=midPoint.y}
		ltriStrip[3*(i-1)+3]= {x=outline[i+1].x,y=outline[i+1].y}		
	end
	--close the triangle strip
	ltriStrip[#ltriStrip+1] = {x=outline[#outline].x,y=outline[#outline].y}
	ltriStrip[#ltriStrip+1]= {x=midPoint.x, y=midPoint.y}
	ltriStrip[#ltriStrip+1]= {x=outline[1].x,y=outline[1].y}		
end

function HabaneroButton:getTriStripMaxDimensions()
	minx,miny,maxx,maxy = math.huge,math.huge,-math.huge,-math.huge
	
	for i=1,table.getn(self.triStrip) do
		local point= self.triStrip[i]	
		
		minx = math.min(minx,point.x)
		miny = math.min(miny,point.y)
		maxx = math.max(maxx,point.x)
		maxy = math.max(maxy,point.y)
	end
	
	return maxx - minx, maxy - miny
end

function scaleTriStrip(self, factorWidth, factorHeigth)
	for i=1,table.getn(self.triStrip) do
		local point= self.triStrip[i]		
		point.x= point.x*factorWidth
		point.y= point.y * factorHeigth
		self.triStrip[i] = point		
	end
end

function generateEarlyOutBox(self)
	for i=1,table.getn(self.triStrip) do
		local point= self.triStrip[i]		
		self.xMin = math.min(self.xMin ,point.x)
		self.xMax = math.max(self.xMax ,point.x)
		self.yMin = math.min(self.yMin ,point.y)
		self.yMax = math.max(self.yMax ,point.y)
		self.midPointX= self.midPointX + point.x
		self.midPointY= self.midPointY + point.y
	end		
	self.midPointX= self.midPointX/ #self.triStrip
	self.midPointY= self.midPointY/ #self.triStrip
	
	xWidth = math.abs( self.xMax )+ math.abs(self.xMin )
	yHeigth = math.abs(self.yMax )+ math.abs(self.yMin )	
	
	self.defaultWidth = xWidth
	self.defaultHeight =yHeigth
	
end


function HabaneroButton:Init(bRelativePixelSize)
	--Handle outline
	if bRelativePixelSize then boolRelativePixelSize = bRelativePixelSize end
	
	if self.outline then
		self.triStrip = convertOutlineToTriStrip(self.outline)		
	end
	
	self.xMin ,self.xMax =0,1
	self.yMin ,self.yMax =0,1	
	
	totalPixelsX,totalPixelsY, rows, columns = getParentTotalSizePixel(self) 
	
	if boolRelativePixelSize == true then	
		
		buttonTotalX, buttonTotalY = self:getTriStripMaxDimensions(self.triStrip)
		--Calculate the factors to scale the pixelvalues of the habanero
		buttonFactorX, buttonFactorY = ((totalPixelsX/columns)/buttonTotalX), ((totalPixelsY/rows)/buttonTotalY)
		scaleTriStrip(self, buttonFactorX, buttonFactorY)
		
		buttonTotalX, buttonTotalY = self:getTriStripMaxDimensions(self.triStrip)
		
	end
	
	if  self.boolBorder and self.boolBorder == true then
	
		self.borderline = Borderline:New{
							borderType = self.borderType,
							button = self,
							borderColor = self.borderColor
						}
						
					
		self.borderline:Init()
	end
	
	--computate the early out box
	generateEarlyOutBox(self)
	self:SetSelectable(false)
	self:setCurrentColorByState()
end
--//=============================================================================
--//=============================================================================
function CrossProduct(v1, v2)
	return {x=v1.x*v2.x, y= v1.y *v2.y}
end

function DotProduct(v1,v2)
	return v1.x*v2.x + v1.y *v2.y
end

function SameSide(pPoint,pPointA, pPointB, pPointC)
	bMinusA={}	
	bMinusA.x=pPointC.x-pPointB.x
	bMinusA.y=pPointC.y-pPointB.y
	
	p1MinusA={}
	p1MinusA.x=pPoint.x-pPointB.x
	p1MinusA.y=pPoint.y-pPointB.y
	p2MinusA={}	
	p2MinusA.x=pPointA.x-pPointB.x
	p2MinusA.y=pPointA.y-pPointB.y
	
	cp1 = CrossProduct(bMinusA, p1MinusA)
	cp2 = CrossProduct(bMinusA, p2MinusA)
	if DotProduct(cp1, cp2) >= 0 then 
		return true
	else 
		return false 
	end
end
-->Rather unelegant tests for every triangle wether the point is inside
function PointInTriangle(pPoint, pPointA,pPointB,pPointC)
	
	if 	SameSide(pPoint,pPointA, pPointB,pPointC) ==true and
	SameSide(pPoint,pPointB, pPointA,pPointC) ==true and
	SameSide(pPoint,pPointC, pPointA,pPointB) ==true 
	then 
		return true
	else 
		return false
	end
end


-->Rather unelegant tests for every triangle wether the point is inside for all points
function HabaneroButton:BruteForceTriStripTest(x,y)
	
	point= {x=x, y= y}
	
	for i=3, #self.triStrip, 1 do
		
		if PointInTriangle(	point,
		self.triStrip[i],
		self.triStrip[i-1],
		self.triStrip[i-2] ) == true then 
			
			return self 
		end
	end 
	
	return false
end


--//=============================================================================


function HabaneroButton:HitTest(x,y)	
	return self:BruteForceTriStripTest(x,y)	
end

function HabaneroButton:MouseDown(...)
	self.state.pressed = true
	inherited.MouseDown(self, ...)
	self:Invalidate()
	return self
end

function HabaneroButton:MouseOver(...)	
	
	self.boolInFocus = true
	self:setCurrentColorByState()
	self:Invalidate()
end

function HabaneroButton:MouseOut(...)
	self.boolInFocus = false
	self:setCurrentColorByState()
	self:Invalidate()
end

function HabaneroButton:MouseUp(...)
	if (self.state.pressed) then
		self.state.pressed = false
		inherited.MouseUp(self, ...)
		self:Invalidate()	
		return self
	end
end

--//=============================================================================