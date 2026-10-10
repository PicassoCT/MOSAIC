function widget:GetInfo()
    return {name='City roads',desc='Faint blue street orientation; roads fade close up, names remain',author='MOSAIC contributors',license='GPL3',layer=0,enabled=true}
end
-- The map copy lives in widgets_map. The game copy yields to it, so the two
-- supported widget directories never create duplicate renderers/settings.
if not CITY_ROADS_MAP_WIDGET and VFS.FileExists('luaui/widgets_map/gui_city_roads.lua',VFS.MAP) then return end
local roads=VFS.Include('scripts/lib_city_roads.lua')
local network, mesh, sectorMesh, revision, elapsed=nil,nil,nil,nil,1
local function clear()
    if mesh then gl.DeleteList(mesh); mesh=nil end
    if sectorMesh then gl.DeleteList(sectorMesh); sectorMesh=nil end
end
local function curve(points,width)
    local out={points[1]}
    for i=2,#points-1 do
        local a,b,c=points[i-1],points[i],points[i+1]
        local l=math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2)
        local m=math.sqrt((c[1]-b[1])^2+(c[2]-b[2])^2)
        local radius=math.min(width/2,l/4,m/4)
        local u={b[1]+(a[1]-b[1])*radius/l,b[2]+(a[2]-b[2])*radius/l}
        local v={b[1]+(c[1]-b[1])*radius/m,b[2]+(c[2]-b[2])*radius/m}
        out[#out+1]=u
        for k=1,6 do
            local t=k/6;local q=1-t
            out[#out+1]={q*q*u[1]+2*q*t*b[1]+t*t*v[1],q*q*u[2]+2*q*t*b[2]+t*t*v[2]}
        end
    end
    out[#out+1]=points[#points];return out
end
local function surface()
    for _,r in ipairs(network.roads) do
        local points=curve(r.points,r.width)
        for i=2,#points do
            local a,b=points[i-1],points[i]; local dx,dz=b[1]-a[1],b[2]-a[2]
            local length=math.sqrt(dx*dx+dz*dz);local nx,nz=-dz/length*r.width/2,dx/length*r.width/2
            local steps=math.ceil(length/64)
            for k=0,steps-1 do
                local t,u=k/steps,(k+1)/steps
                local x,z=a[1]+dx*t,a[2]+dz*t;local xx,zz=a[1]+dx*u,a[2]+dz*u
                if Spring.GetGroundHeight((x+xx)/2,(z+zz)/2)>0 then
                    for _,p in ipairs({{x+nx,z+nz},{xx+nx,zz+nz},{xx-nx,zz-nz},{x-nx,z-nz}}) do
                        local px=math.max(0,math.min(Game.mapSizeX,p[1]));local pz=math.max(0,math.min(Game.mapSizeZ,p[2]))
                        gl.Vertex(px,Spring.GetGroundHeight(px,pz)+1,pz)
                    end
                end
            end
        end
    end
end
local function sectors()
    local size=roads.SECTOR_SIZE
    local function dash(x,z,dx,dz)
        for offset=0,size-1,160 do
            for _,t in ipairs({offset,math.min(size,offset+32)}) do
                local px,pz=x+dx*t,z+dz*t
                if px<=Game.mapSizeX and pz<=Game.mapSizeZ then gl.Vertex(px,Spring.GetGroundHeight(px,pz)+2,pz) end
            end
        end
    end
    for x=size,Game.mapSizeX-1,size do for z=0,Game.mapSizeZ-1,size do dash(x,z,0,1) end end
    for z=size,Game.mapSizeZ-1,size do for x=0,Game.mapSizeX-1,size do dash(x,z,1,0) end end
end
function widget:Initialize()
    WG.CityOrientation={SectorAt=function(x,z) return roads.sector(x,z,Game.mapSizeX,Game.mapSizeZ) end,
        StreetAt=function(x,z) local n=network and roads.nearest(network,x,z);return n and n.road.name end}
end
function widget:Update(dt)
    elapsed=elapsed+dt; if elapsed<0.5 then return end; elapsed=0
    local v=Spring.GetGameRulesParam('city_roads_revision'); if not v or v==revision then return end
    local n=Spring.GetGameRulesParam('city_roads_chunks'); if not n or n<1 or n>2048 then return end
    local chunks={}
    for i=1,n do local s=Spring.GetGameRulesParam('city_roads_chunk_'..i);if type(s)~='string' then return end;chunks[i]=s end
    local ok,result=pcall(roads.decode,table.concat(chunks)); if not ok then return end
    clear();network=result;revision=v
    mesh=gl.CreateList(function() gl.BeginEnd(GL.QUADS,surface) end)
    sectorMesh=gl.CreateList(function() gl.BeginEnd(GL.LINES,sectors) end)
end
local function zoom()
    if not Spring.GetCameraPosition then return 1 end
    local x,y,z=Spring.GetCameraPosition()
    local height=y-Spring.GetGroundHeight(x,z)
    local t=math.max(0,math.min(1,(height-650)/1800))
    return t*t*(3-2*t)
end
function widget:DrawWorld()
    if not mesh then return end
    local fade=zoom();if fade<=0 then return end
    gl.DepthTest(true);gl.DepthMask(false);gl.PolygonOffset(-2,-2)
    gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
    gl.Color(0.22,0.58,0.82,0.25*fade);gl.CallList(mesh)
    if gl.LineWidth then gl.LineWidth(1) end
    gl.Color(0.22,0.58,0.82,0.06*fade);gl.CallList(sectorMesh)
    gl.Color(1,1,1,1);gl.PolygonOffset(false);gl.DepthTest(false);gl.DepthMask(false)
end
function widget:DrawScreen()
    if not network then return end
    local sx,sy=gl.GetViewSizes();local boxes,shown={},{}
    local count=0
    for _,r in ipairs(network.roads) do
        if r.name~='' and not shown[r.name] then
            -- Pick the visible segment nearest the screen centre, so long
            -- streets retain a label while their global midpoint is offscreen.
            local best
            for i=2,#r.points do
                local a,b=r.points[i-1],r.points[i]
                local length=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2)
                local samples=math.max(1,math.ceil(length/512))
                for k=1,samples do
                local t=(k-0.5)/samples;local x,z=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t
                local y=Spring.GetGroundHeight(x,z)+3
                if y>3 and Spring.IsSphereInView(x,y,z,16) then
                    local px,py,pz=Spring.WorldToScreenCoords(x,y,z)
                    if pz and pz>=0 and pz<=1 and px>20 and px<sx-20 and py>20 and py<sy-20 then
                        local d=(px-sx/2)^2+(py-sy/2)^2
                        if not best or d<best.d then best={x=px,y=py,d=d} end
                    end
                end
                end
            end
            if best then
                local width=gl.GetTextWidth(r.name)*11+12
                local box={best.x-width/2,best.y-10,best.x+width/2,best.y+10};local overlap=false
                for _,b in ipairs(boxes) do if box[1]<b[3] and box[3]>b[1] and box[2]<b[4] and box[4]>b[2] then overlap=true;break end end
                if not overlap then
                    gl.Color(0.48,0.70,0.82,0.62-0.22*zoom());gl.Text(r.name,best.x,best.y,11,'c')
                    boxes[#boxes+1]=box;shown[r.name]=true;count=count+1
                    if count>=math.floor(36-20*zoom()) then break end
                end
            end
        end
    end
    -- Sector tags reserve the same collision boxes as street labels. Streets
    -- get first priority; no text grid appears at close range.
    local fade=zoom()
    if fade>0.05 then
        local size=roads.SECTOR_SIZE
        for z=size/2,Game.mapSizeZ,size do for x=size/2,Game.mapSizeX,size do
            local y=Spring.GetGroundHeight(x,z)+3
            if Spring.IsSphereInView(x,y,z,16) then
                local px,py,pz=Spring.WorldToScreenCoords(x,y,z)
                if pz and pz>=0 and pz<=1 and px>20 and px<sx-20 and py>20 and py<sy-20 then
                    local overlap=false
                    for _,b in ipairs(boxes) do if px>b[1]-20 and px<b[3]+20 and py>b[2]-14 and py<b[4]+14 then overlap=true;break end end
                    if not overlap then
                        gl.Color(0.42,0.66,0.80,0.32*fade);gl.Text(roads.sector(x,z,Game.mapSizeX,Game.mapSizeZ),px,py,11,'c')
                        boxes[#boxes+1]={px-20,py-10,px+20,py+10}
                    end
                end
            end
        end end
    end
    -- A tiny fixed readout helps translate a cursor/ping location into speech.
    if Spring.GetMouseState and Spring.TraceScreenRay then
        local mx,my=Spring.GetMouseState();local kind,pos=Spring.TraceScreenRay(mx,my,true)
        if kind=='ground' and type(pos)=='table' then
            local text='Sector '..roads.sector(pos[1],pos[3],Game.mapSizeX,Game.mapSizeZ)
            gl.Color(0.48,0.70,0.82,0.6);gl.Text(text,sx/2,sy-28,11,'c')
        end
    end
    gl.Color(1,1,1,1)
end
function widget:Shutdown() clear();if WG then WG.CityOrientation=nil end end
