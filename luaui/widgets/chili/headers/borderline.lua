VFS.Include(CHILI_DIRNAME .. "headers/util.lua", nil, VFS.RAW_FIRST)

Borderline = Object:Inherit{
	classname= "Borderline",
	borderType = "static",
	borderColor = {0, 0, 0.1, 0.1},
	borderDistance = 0,
	borderDiameter = 7 ,
	button = "nil",
	--Points in Order, Clockwise in local Coordinates - last coordinate is a Copy of the first
	--triStrip should not be self-intersecting or incomplete
	triStrip ={},
}

local this = Borderline
local inherited = this.inherited

function distance(x, y, z, xa, ya, za)
	if type(x)== "table" then
		return distance(x.x, x.y, x.z, y.x, y.y, y.z)
	end
	
	if xa ~= nil and ya ~= nil and za ~= nil then
		return math.sqrt((x - xa) ^ 2 + (y - ya) ^ 2 + (z - za) ^ 2)
	elseif x ~= nil and y ~= nil and z ~= nil then
		return math.sqrt(x * x + y * y + z * z)
	else
		return math.sqrt((x - y) ^ 2)
	end
end

function Borderline:DrawSpiral(startPointA, startPointB, CenterPoint, Degree, reduceFactor, Resolution)
	local strip = {}
	totalReducePerStep= (1-reduceFactor)/Resolution
	degPerRes = Degree/Resolution
	
	Rotate = function (x, z, Rad)
				if not Rad then return end
				sinus = math.sin(Rad)
				cosinus = math.cos(Rad)
				
				return x * cosinus + z * -sinus, x * sinus + z * cosinus
			end
	
	
	for i=1,Resolution do
		--make a copy and 	--scale the new points
		local copyPointA,copyPointB = startPointA, startPointB
		copyPointA.x,copyPointA.y=(1-totalReducePerStep)* (copyPointA.x-CenterPoint.x),(1-totalReducePerStep)* (copyPointA.y-CenterPoint.y)
		copyPointB.x,copyPointB.y=(1-totalReducePerStep)* (copyPointB.x-CenterPoint.x),(1-totalReducePerStep)* (copyPointB.y-CenterPoint.y)
		-- rotate the Points 
		copyPointA.x,copyPointA.y= Rotate(copyPointA.x,copyPointA.y,math.rad(degPerRes))
		copyPointB.x,copyPointB.y= Rotate(copyPointB.x,copyPointB.y,math.rad(degPerRes))
		-- move back into position
		copyPointA.x,copyPointA.y=copyPointA.x +CenterPoint.x,copyPointA.y +CenterPoint.y
		---draw two triangles into the strip
		strip[#strip+1] = {x=startPointA.x ,y=startPointA.y}
		strip[#strip+1] = {x=startPointB.x ,y=startPointB.y}
		strip[#strip+1] = {x=copyPointA.x ,y=copyPointA.y}
		strip[#strip+1] = {x=copyPointA.x ,y=copyPointA.y}
	end
	return strip
end



function addScaledPointPair(copyPoint, normal, borderDistance, diameter)
normal ={x= 0.5, y = 0.5} --TODO Remove&Replace Having a fixed noraml aint normal - but on crytallized math it is

	local PointT = copyPoint
	if PointT.x  == 0 then PointT.x = 1 end
	if PointT.z  == 0 then PointT.z = 1 end

	orgdist =math.sqrt(PointT.x^2+ PointT.y^2) 
	
	return  { 
			x = PointT.x + (normal.x* borderDistance), 
			y = PointT.y + ((normal.y) * borderDistance)
			}, 
			{ 
			x = PointT.x + (normal.x* ( borderDistance + diameter)),
 			y = PointT.y + (normal.y) * ( borderDistance + diameter)
			}
end

function convexhull(points)
    local p = #points

    local cross = function(p, q, r)
        return (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    end

    table.sort(points, function(a, b)
        return a.x == b.x and a.y > b.y or a.x > b.x
    end)

    local lower = {}
    for i = 1, p do
        while (#lower >= 2 and cross(lower[#lower - 1], lower[#lower], points[i]) <= 0) do
            table.remove(lower, #lower)
        end

        table.insert(lower, points[i])
    end

    local upper = {}
    for i = p, 1, -1 do
        while (#upper >= 2 and cross(upper[#upper - 1], upper[#upper], points[i]) <= 0) do
            table.remove(upper, #upper)
        end

        table.insert(upper, points[i])
    end

    table.remove(upper, #upper)
    table.remove(lower, #lower)
    for _, point in ipairs(lower) do
        table.insert(upper, point)
    end

    return upper
end

function b2CrossVectVect( a, b )
        return a.x * b.y - a.y * b.x;
end

function getNormal(predecessorP, Point, succesorP)
vec1,vec2 ={},{}
vec1.x =  Point.x  - predecessorP.x 
vec1.y =  Point.y  - predecessorP.y 

vec2.x = succesorP.x - Point.x 
vec2.y = succesorP.y - Point.y 

return b2CrossVectVect(vec1,vec2)
end

function calculateNormal(i, triStripCopy)	
	predecessor = i-1
	succesor =i+1
	if predecessor < 1 then predecessor = #triStripCopy end
	if succesor > #triStripCopy then succesor = 1 end
	
	return getNormal(triStripCopy[predecessor],triStripCopy[i],triStripCopy[succesor])
end

function Borderline:generateStaticBorder()

	assert(self.button ~= "nil")
	local orgTriStripCopy = self.button.triStrip
	local triStripCopy = convexhull(orgTriStripCopy)
	
	
	for i=1,#triStripCopy do
		index= #self.triStrip

		self.triStrip[index+1],self.triStrip[index+2]= addScaledPointPair(triStripCopy[i], calculateNormal(i,triStripCopy), self.borderDistance, self.borderDiameter)
	end

	
end





function getCenterPoint(triStrip)
	totalPoints= #triStrip
	midPoint= {x=0,y=0}
		for i=1,totalPoints do
			midPoint.x = midPoint.x + triStrip[i].x
			midPoint.y = midPoint.y + triStrip[i].y
		end
	midPoint.x = midPoint.x/totalPoints
	midPoint.y = midPoint.y /totalPoints
	return midPoint
end
function organicExpandTriStrip(triStrip, resolution, shiftformula, centerpoint)
expandedStrip={}
buttonStrip={}

	
	for i=1,#triStrip do
		predecessor,succesor = i-1, i+1
		if predecessor < 1 then predecessor = 1 end
		if succesor > #triStrip then succesor = #triStrip  end
		
		if predecessor ~= succesor then
			for r=1, resolution do
			
				percentage= r/resolution
				orgpoint = mixTable(triStrip[predecessor],triStrip[succesor], percentage, r)
				innerP, outerP = shiftformula(orgpoint, percentage, centerpoint, 5 , r)
				expandedStrip[#expandedStrip + 1] = innerP
				buttonStrip[#buttonStrip + 1] = innerP
				expandedStrip[#expandedStrip + 1] = outerP
			end
		end
	end
				
	return expandedStrip, buttonStrip
end
function Borderline:generateOrganicBorder()
	local triStripCopy = self.button.triStrip --convexhull(self.button.triStrip)
	

	triStripCopy = convexhull(triStripCopy)

	centerP = getCenterPoint( triStripCopy)
	
	shiftformula= function(point, factor, centerpoint,  distanceoutpx, index)
					
					local	vector = {
							x=   point.x - centerpoint.x,
							y=   point.y - centerpoint.y
						}
						
						distancecenter = math.sqrt(vector.x^2 + vector.y^2)
						borderscrolloutfactor=  (distanceoutpx/distancecenter)
						distortionfactor =  math.sin( factor * math.pi)/4 + 0.75
											
						borderscrolloutfactor = borderscrolloutfactor +1
											--determinate the vector from the center
																local	outpoint ={}

						outpoint.x = vector.x * distortionfactor *  borderscrolloutfactor + centerpoint.x						
						outpoint.y = vector.y * distortionfactor *  borderscrolloutfactor + centerpoint.y			
								
						vector.x = vector.x * distortionfactor + centerpoint.x
						vector.y = vector.y * distortionfactor + centerpoint.y
						
						return  vector, outpoint
					
					end
	

	self.triStrip, _ = organicExpandTriStrip( triStripCopy,  16, shiftformula, centerP)
	--self.button.triStrip = convexhull(self.triStrip)
	self.button:Invalidate()
	--self.button.triStrip = convexhull(self.button.triStrip)
	-- slightly transparent white tree


		-- get Points on Borderline
	-- get CenterPoint
	-- Add Edge Point
		-- Add Circle point After 1/math.random( of the border line)
		-- generate TriStrip
		-- Ad Outside Line in 1 2 3 5 7 5 3 2 1 Pattern
		
		-- thread
		-- On Mouse Closeness, cause Bloom - leaves, flowers, bulbs
		-- slowly wither on distance, back to basic form - or small spiral


end

function Borderline:Init()	
	if  not self.borderType or self.borderType == "static" then
	
		 self:generateStaticBorder()
	else
		Spring.Echo("Initialization Organic Borderline 1")
		self:generateOrganicBorder()
	end
end

function Borderline:Update(frame)

end


function Borderline:HitTest(x,y)	
	return self:BruteForceTriStripTest(x,y)	
end

