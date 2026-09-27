-- Attached objective lamps and a world-size gate for house street furniture.
-- Keep both attached to the actual piece transform, including imported scale.
local M = {placeableMinSize = 32, maxDirectLights = 24}
local atan2 = math.atan2 or math.atan
local placeableSizes = {}
local function geometry(unitID, pieceID)
    local info = Spring.GetUnitPieceInfo(unitID, pieceID)
    local matrix = {Spring.GetUnitPieceMatrix(unitID, pieceID)}
    if not info or info.isEmpty or not info.min or not info.max or not matrix[16] then return end
    return info, matrix
end

function M.PlaceableEligible(unitID, pieceID)
    local defID = Spring.GetUnitDefID(unitID)
    local key = defID..':'..pieceID
    if placeableSizes[key] then return placeableSizes[key] >= M.placeableMinSize end
    local info, m = geometry(unitID, pieceID)
    if not info then return false end
    local longest = 0
    for axis = 1, 3 do
        local i = (axis - 1) * 4
        local scale = math.sqrt(m[i+1]^2 + m[i+2]^2 + m[i+3]^2)
        longest = math.max(longest, (info.max[axis] - info.min[axis]) * scale)
    end
    placeableSizes[key] = longest
    return longest >= M.placeableMinSize
end

function M.PlaceablesVisible(unitID)
    if Spring.GetUnitNoDraw(unitID) or Spring.GetUnitIsCloaked(unitID) then return false end
    local _, fullView = Spring.GetSpectatingState()
    local los = fullView or Spring.GetUnitLosState(unitID)
    return fullView or (los and los.los) or false
end

function M.DrawLamp(source)
    -- drawNeonPieces uses a top-down world view; do not inherit the unit matrix.
    gl.PushMatrix()
    gl.LoadIdentity()
    gl.Rotate(-90,1,0,0)
    gl.BeginEnd(GL.TRIANGLES, function()
        local x,y,z,r = source.x,source.y,source.z,source.radius
        gl.Vertex(x-r,y,z-r); gl.Vertex(x+r,y,z-r); gl.Vertex(x+r,y,z+r)
        gl.Vertex(x-r,y,z-r); gl.Vertex(x+r,y,z+r); gl.Vertex(x-r,y,z+r)
    end)
    gl.PopMatrix()
end

local function normalize(v)
    local length=math.sqrt(v[1]^2+v[2]^2+v[3]^2)
    if length<0.0001 then return end
    return {v[1]/length,v[2]/length,v[3]/length},length
end

-- Piece bounds are in imported mesh coordinates, not engine/world axes.
local function pieceFrame(unitID,pieceID)
    local info,m=geometry(unitID,pieceID)
    if not info then return end
    local x,y,z=Spring.GetUnitPiecePosDir(unitID,pieceID)
    local front,up,right=Spring.GetUnitVectors(unitID)
    if not x or not front or not up or not right then return end
    local axes,scale={},{}
    for axis=1,3 do
        local i=(axis-1)*4
        axes[axis],scale[axis]=normalize({
            -right[1]*m[i+1]+up[1]*m[i+2]+front[1]*m[i+3],
            -right[2]*m[i+1]+up[2]*m[i+2]+front[2]*m[i+3],
            -right[3]*m[i+1]+up[3]*m[i+2]+front[3]*m[i+3]})
        if not axes[axis] then return end
    end
    local function point(coords)
        local p={x,y,z}
        for a=1,3 do for k=1,3 do p[k]=p[k]+axes[a][k]*scale[a]*coords[a] end end
        return p
    end
    local center,half,vertical={},{},1
    for a=1,3 do
        center[a]=(info.min[a]+info.max[a])*.5
        half[a]=(info.max[a]-info.min[a])*.5*scale[a]
        if math.abs(axes[a][2])>math.abs(axes[vertical][2]) then vertical=a end
    end
    local horizontal={}
    for a=1,3 do if a~=vertical then horizontal[#horizontal+1]=a end end
    return {point=point,center=point(center),axes=axes,half=half,vertical=vertical,horizontal=horizontal}
end

function M.AttachedLights(unitID,pieceID,preset,frame)
    if preset~='palace_facade' and preset~='outpost_searchlight' and preset~='outpost_roof' then return {} end
    if not M.PlaceablesVisible(unitID) then return {} end
    local f=pieceFrame(unitID,pieceID)
    if not f then return {} end
    if preset~='palace_facade' then
        -- Tower roof beside the antenna, measured from CombatOutPost's mesh.
        -- Transform the anchor with the piece, including its DAE import scale.
        local p=f.point({500,-3000,3300})
        local front=Spring.GetUnitVectors(unitID)
        local heading=atan2(front[1],front[3])
        local seconds=(frame or 0)/(Game.gameSpeed or 30)
        local angle=heading+math.sin(seconds*math.pi/8+unitID*.37)*math.rad(65)
        local direction=normalize({math.sin(angle),-.65,math.cos(angle)})
        local ground=Spring.GetGroundHeight(p[1],p[3])
        local range=math.min(900,math.max(240,(p[2]-ground)*3.5))
        return {{x=p[1],y=p[2]+3,z=p[3],direction=direction,range=range,
            outerCos=math.cos(math.rad(12)),color={1,.91,.75},gain=5,
            radius=3,strength=.18,unitID=unitID}}
    end
    local lights={}
    local base=f.center[2]-f.half[f.vertical]
    local height=f.half[f.vertical]*2
    for side=1,2 do
        local a,b=f.horizontal[side],f.horizontal[3-side]
        for sign=-1,1,2 do for _,along in ipairs({-.5,.5}) do
            local distance=math.max(20,math.min(44,f.half[a]*.25))
            local p={f.center[1],base+5,f.center[3]}
            for k=1,3 do
                p[k]=p[k]+f.axes[a][k]*sign*(f.half[a]+distance)+f.axes[b][k]*f.half[b]*along
            end
            local direction=normalize({-f.axes[a][1]*sign*distance,height*.5,-f.axes[a][3]*sign*distance})
            lights[#lights+1]={x=p[1],y=p[2],z=p[3],direction=direction,
                range=math.min(400,math.max(100,height*1.6)),outerCos=math.cos(math.rad(48)),
                color={1,.76,.44},gain=3,radius=5,strength=.45,unitID=unitID}
        end end
    end
    return lights
end

function M.CollectDirect(records,frame)
    local lights={}
    for unitID,pieces in pairs(records) do
        if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(unitID) then
            for _,record in pairs(pieces) do
                if type(record)=='table' and record.mode=='lamp' then
                    for _,light in ipairs(M.AttachedLights(unitID,record.piece,record.preset,frame)) do
                        lights[#lights+1]=light
                    end
                end
            end
        end
    end
    if #lights>M.maxDirectLights then
        local x,y,z=Spring.GetCameraPosition()
        for i,l in ipairs(lights) do l.order=i;l.distance=(l.x-x)^2+(l.y-y)^2+(l.z-z)^2 end
        table.sort(lights,function(a,b)
            if a.distance==b.distance then return a.order<b.order end
            return a.distance<b.distance
        end)
        for i=#lights,M.maxDirectLights+1,-1 do lights[i]=nil end
    end
    return lights
end
return M
