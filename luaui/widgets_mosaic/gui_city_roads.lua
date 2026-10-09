function widget:GetInfo()
    return {name='City roads',desc='Half-transparent road surfaces and decluttered street names',author='MOSAIC contributors',license='GPL3',layer=0,enabled=true}
end
-- The map copy lives in widgets_map. The game copy yields to it, so the two
-- supported widget directories never create duplicate renderers/settings.
if not CITY_ROADS_MAP_WIDGET and VFS.FileExists('luaui/widgets_map/gui_city_roads.lua',VFS.MAP) then return end
local roads=VFS.Include('scripts/lib_city_roads.lua')
local network, mesh, revision, elapsed=nil,nil,nil,1
local function clear()
    if mesh then gl.DeleteList(mesh); mesh=nil end
end
local function surface()
    for _,r in ipairs(network.roads) do
        for i=2,#r.points do
            local a,b=r.points[i-1],r.points[i]; local dx,dz=b[1]-a[1],b[2]-a[2]
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
function widget:Update(dt)
    elapsed=elapsed+dt; if elapsed<0.5 then return end; elapsed=0
    local v=Spring.GetGameRulesParam('city_roads_revision'); if not v or v==revision then return end
    local n=Spring.GetGameRulesParam('city_roads_chunks'); if not n or n<1 or n>2048 then return end
    local chunks={}
    for i=1,n do local s=Spring.GetGameRulesParam('city_roads_chunk_'..i);if type(s)~='string' then return end;chunks[i]=s end
    local ok,result=pcall(roads.decode,table.concat(chunks)); if not ok then return end
    clear();network=result;revision=v
    mesh=gl.CreateList(function() gl.BeginEnd(GL.QUADS,surface) end)
end
function widget:DrawWorld()
    if not mesh then return end
    gl.DepthTest(true);gl.DepthMask(false);gl.PolygonOffset(-2,-2)
    gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
    gl.Color(0.35,0.55,0.65,0.5);gl.CallList(mesh)
    gl.Color(1,1,1,1);gl.PolygonOffset(false);gl.DepthTest(false);gl.DepthMask(false)
end
function widget:DrawScreen()
    if not network then return end
    local sx,sy=gl.GetViewSizes();local boxes,shown={},{}
    local count=0
    for _,r in ipairs(network.roads) do
        if not shown[r.name] then
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
                local width=gl.GetTextWidth(r.name)*13+12
                local box={best.x-width/2,best.y-10,best.x+width/2,best.y+10};local overlap=false
                for _,b in ipairs(boxes) do if box[1]<b[3] and box[3]>b[1] and box[2]<b[4] and box[4]>b[2] then overlap=true;break end end
                if not overlap then
                    gl.Color(1,1,1,0.9);gl.Text(r.name,best.x,best.y,13,'oc')
                    boxes[#boxes+1]=box;shown[r.name]=true;count=count+1
                    if count>=80 then break end
                end
            end
        end
    end
    gl.Color(1,1,1,1)
end
function widget:Shutdown() clear() end
