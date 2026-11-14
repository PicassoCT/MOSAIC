function gadget:GetInfo()
    return {
        name = 'House icon holograms',
        desc = 'Voxel silhouettes of residential houses at strategic zoom',
        author = 'MOSAIC contributors', license = 'GPL3', layer = 0, enabled = true,
    }
end

local hostRule = 'house_icon_host_'
if gadgetHandler:IsSyncedCode() then
    -- Store the link on each owning player with private visibility. A rule on
    -- the neutral house or even on the occupant could be read by allied teams.
    local links, published = {}, {}
    local dirty = true
    local function setHost(occupant, house)
        links[occupant] = house
        dirty = true
    end
    function gadget:Initialize()
        if not Spring.SetPlayerRulesParam then return end
        GG.SetHouseIconHost = setHost
        for house, occupant in pairs(GG.houseHasSafeHouseTable or {}) do
            if Spring.ValidUnitID(house) and Spring.ValidUnitID(occupant) then setHost(occupant, house) end
        end
    end
    function gadget:UnitDestroyed(id)
        if links[id] then links[id] = nil; dirty = true end
        for occupant, house in pairs(links) do
            if house == id then links[occupant] = nil; dirty = true end
        end
    end
    function gadget:UnitGiven(id) if links[id] then dirty = true end end
    function gadget:GameFrame(frame)
        if not Spring.SetPlayerRulesParam or (not dirty and frame % 30 ~= 0) then return end
        dirty = false
        -- Recheck the player roster for joins, team switches and spectating.
        for _, player in ipairs(Spring.GetPlayerList()) do
            local _, _, spectator, team = Spring.GetPlayerInfo(player, false)
            local previous = published[player] or {}
            for id, house in pairs(previous) do
                if spectator or links[id] ~= house or Spring.GetUnitTeam(id) ~= team then
                    Spring.SetPlayerRulesParam(player, hostRule .. id, nil)
                    previous[id] = nil
                end
            end
            if not spectator then
                for id, house in pairs(links) do
                    if Spring.GetUnitTeam(id) == team and previous[id] ~= house then
                        Spring.SetPlayerRulesParam(player, hostRule .. id, house, {private=true})
                        previous[id] = house
                    end
                end
            end
            published[player] = previous
        end
    end
    function gadget:Shutdown()
        GG.SetHouseIconHost = nil
        for player, previous in pairs(published) do
            for id in pairs(previous) do Spring.SetPlayerRulesParam(player, hostRule .. id, nil) end
        end
    end
    return
end

local mesh = VFS.Include('luarules/gadgets/include/house_icon_mesh.lua')
local bodies = VFS.Include('luarules/gadgets/include/house_icon_bodies.lua')
local shaderDir = 'luarules/gadgets/shaders/house_icon/'
local shader, contourShader, timeUniform, selectedUniform, keyUniform, originUniform
local maskPassUniform
local maskTexture, depthTexture, maskFBO
local viewWidth, viewHeight, viewX, viewY = 0,0,0,0
local failedWidth, failedHeight
local houses, suppressed, cached, visible = {}, {}, {}, {}
local bases = {house_asian0=true, house_western0=true, house_arab0=true}
local houseDefs, standalone = {}, {}
for id, def in pairs(UnitDefs) do
    local cp = def.customParams or {}
    standalone[id] = def.name:match('^house_asian[1-4]$') ~= nil
    houseDefs[id] = bases[def.name] or standalone[id] or bases[cp.house_asian_base]
        or bases[cp.house_western_base] or bases[cp.house_arab_base] or cp.house_icon_hologram == '1'
end

local function restore(id)
    if suppressed[id] then
        if Spring.ValidUnitID(id) then Spring.UnitIconSetDraw(id, true) end
        suppressed[id] = nil
    end
end

local function forget(id)
    if cached[id] then gl.DeleteList(cached[id].list); cached[id] = nil end
end

local function releaseTargets()
    if maskFBO then gl.DeleteFBO(maskFBO); maskFBO = nil end
    if maskTexture then gl.DeleteTexture(maskTexture); maskTexture = nil end
    if depthTexture then gl.DeleteTexture(depthTexture); depthTexture = nil end
end

local function ensureTargets()
    if not contourShader then return false end
    local width,height,x,y = Spring.GetViewGeometry()
    viewX,viewY = x or 0,y or 0
    if width <= 0 or height <= 0 then return false end
    if maskFBO and width == viewWidth and height == viewHeight then return true end
    if width == failedWidth and height == failedHeight then return false end
    releaseTargets()
    viewWidth,viewHeight = width,height
    -- One shared ID mask for all visible houses, not one texture per house.
    maskTexture = gl.CreateTexture(width,height, {
        format=GL.RGBA8, min_filter=GL.NEAREST, mag_filter=GL.NEAREST,
        wrap_s=GL.CLAMP_TO_EDGE, wrap_t=GL.CLAMP_TO_EDGE,
    })
    depthTexture = gl.CreateTexture(width,height, {
        format=GL.DEPTH_COMPONENT24, min_filter=GL.NEAREST, mag_filter=GL.NEAREST,
        wrap_s=GL.CLAMP_TO_EDGE, wrap_t=GL.CLAMP_TO_EDGE,
    })
    if maskTexture and depthTexture then
        maskFBO = gl.CreateFBO({color0=maskTexture, depth=depthTexture})
    end
    if not maskFBO or not gl.IsValidFBO(maskFBO) then
        releaseTargets()
        failedWidth,failedHeight = width,height
        Spring.Echo('[House icon holograms] Contour framebuffer unavailable; retaining the original hologram material.')
        return false
    end
    failedWidth,failedHeight = nil,nil
    return true
end

function gadget:ViewResize()
    releaseTargets()
    failedWidth,failedHeight = nil,nil
end

local function emit(x0,y0,z0, x1,y1,z1, x2,y2,z2, x3,y3,z3)
    gl.TexCoord(0,0); gl.Vertex(x0,y0,z0)
    gl.TexCoord(0,1); gl.Vertex(x1,y1,z1)
    gl.TexCoord(1,1); gl.Vertex(x2,y2,z2)
    gl.TexCoord(1,0); gl.Vertex(x3,y3,z3)
end

local function bodyParts(id, names)
    local parts = {}
    for piece in tostring(names):gmatch('%d+') do
        local index = tonumber(piece)
        local info = Spring.GetUnitPieceInfo(id,index)
        local encoded = info and bodies[info.name:lower()]
        if encoded then
            local matrix = {Spring.GetUnitPieceMatrix(id,index)}
            local grid = mesh.body(encoded,info)
            if grid and #matrix == 16 then
                parts[#parts+1] = {grid=grid, matrix=matrix}
            end
        end
    end
    return parts
end

local function buildList(id, source, isBody)
    local parts = isBody and bodyParts(id,source) or {{grid=source}}
    if #parts == 0 or #parts[1].grid.columns == 0 then return end
    return gl.CreateList(function()
        for _, part in ipairs(parts) do
            -- Bake piece transforms into positions. Scanlines then follow
            -- model height even when the mesh's authored up axis is rotated.
            local m = part.matrix
            local writer = emit
            if m then
                local function transform(x,y,z)
                    return m[1]*x+m[5]*y+m[9]*z+m[13], m[2]*x+m[6]*y+m[10]*z+m[14],
                           m[3]*x+m[7]*y+m[11]*z+m[15]
                end
                local det = m[1]*(m[6]*m[11]-m[7]*m[10])-m[5]*(m[2]*m[11]-m[3]*m[10])+m[9]*(m[2]*m[7]-m[3]*m[6])
                writer = function(x0,y0,z0,x1,y1,z1,x2,y2,z2,x3,y3,z3)
                    x0,y0,z0 = transform(x0,y0,z0); x1,y1,z1 = transform(x1,y1,z1)
                    x2,y2,z2 = transform(x2,y2,z2); x3,y3,z3 = transform(x3,y3,z3)
                    if det < 0 then emit(x3,y3,z3,x2,y2,z2,x1,y1,z1,x0,y0,z0)
                    else emit(x0,y0,z0,x1,y1,z1,x2,y2,z2,x3,y3,z3) end
                end
            end
            gl.BeginEnd(GL.QUADS, mesh.surface, part.grid, writer)
        end
    end)
end

function gadget:UnitCreated(id, defID)
    if houseDefs[defID] then houses[id] = defID end
end
function gadget:UnitEnteredLos(id, team, allyTeam, defID)
    self:UnitCreated(id, defID or Spring.GetUnitDefID(id))
end
function gadget:UnitDestroyed(id)
    restore(id); forget(id); houses[id] = nil
end
function gadget:UnitLeftLos(id) restore(id) end

function gadget:Initialize()
    if not (gl.CreateShader and Spring.UnitIconSetDraw and Spring.IsUnitIcon) then
        Spring.Echo('[House icon holograms] Disabled: requires gl.CreateShader, Spring.UnitIconSetDraw and Spring.IsUnitIcon')
        gadgetHandler:RemoveGadget(self); return
    end
    shader = gl.CreateShader({
        vertex = VFS.LoadFile(shaderDir .. 'house.vert'),
        fragment = VFS.LoadFile(shaderDir .. 'house.frag'),
    })
    if not shader then
        Spring.Echo('[House icon holograms] Shader failed:', gl.GetShaderLog() or '')
        gadgetHandler:RemoveGadget(self); return
    end
    -- The contour is an enhancement: its shader or framebuffer support must
    -- never disable the existing wireframe and scanline material.
    if gl.CreateFBO and gl.ActiveFBO and gl.CopyToTexture and gl.IsValidFBO
        and gl.CreateTexture and gl.DeleteFBO and gl.DeleteTexture and Spring.GetViewGeometry then
        contourShader = gl.CreateShader({
            vertex = VFS.LoadFile(shaderDir .. 'contour.vert'),
            fragment = VFS.LoadFile(shaderDir .. 'contour.frag'),
            uniformInt = {buildingMask=0, resolvedDepth=1},
        })
        if not contourShader then
            Spring.Echo('[House icon holograms] Contour shader failed; retaining the original hologram material:', gl.GetShaderLog() or '')
        end
    else
        Spring.Echo('[House icon holograms] Contour APIs unavailable; retaining the original hologram material.')
    end
    timeUniform = gl.GetUniformLocation(shader,'time')
    selectedUniform = gl.GetUniformLocation(shader,'selected')
    keyUniform = gl.GetUniformLocation(shader,'buildingKey')
    maskPassUniform = gl.GetUniformLocation(shader,'maskPass')
    if contourShader then originUniform = gl.GetUniformLocation(contourShader,'viewportOrigin') end
    for _, id in ipairs(Spring.GetAllUnits()) do self:UnitCreated(id, Spring.GetUnitDefID(id)) end
end

local function selectedHosts()
    local hosts = {}
    if Spring.GetSpectatingState() or not Spring.GetPlayerRulesParam then return hosts end
    local player = Spring.GetMyPlayerID()
    local team = Spring.GetMyTeamID()
    for _, id in ipairs(Spring.GetSelectedUnits()) do
        if Spring.GetUnitTeam(id) == team then
            local host = Spring.GetPlayerRulesParam(player,hostRule .. id)
            if host then hosts[host] = true end
        end
    end
    return hosts
end

function gadget:DrawWorldPreUnit()
    visible = {}
    if not shader or Spring.GetConfigInt('MosaicHouseHolograms',1) == 0 or Spring.IsGUIHidden() then
        for id in pairs(suppressed) do restore(id) end
        return
    end
    local _, fullView = Spring.GetSpectatingState()
    local allyTeam, active = Spring.GetMyAllyTeamID(), {}
    local grids = GG.HouseIconShadowGrids or {}
    local buildBudget = 3
    for id, defID in pairs(houses) do
        if not Spring.ValidUnitID(id) then
            self:UnitDestroyed(id)
        elseif Spring.IsUnitIcon(id) and Spring.IsUnitInView(id) and
            not Spring.GetUnitIsCloaked(id) and not Spring.GetUnitNoDraw(id) then
            local los = Spring.GetUnitLosState(id, allyTeam)
            if fullView or (los and los.los) then
                local isBody = standalone[defID]
                local source = grids[id]
                if isBody then source = Spring.GetUnitRulesParam(id,'house_icon_bodies') end
                local entry = cached[id]
                if entry and entry.source ~= source then forget(id); entry = nil end
                if not entry and source and (isBody or #source.columns > 0) and buildBudget > 0 then
                    buildBudget = buildBudget - 1
                    local list = buildList(id, source, isBody)
                    if list and list ~= 0 then entry = {source=source, list=list}; cached[id] = entry end
                end
                if entry then
                    active[id] = true
                    visible[#visible+1] = id
                    if not suppressed[id] then
                        Spring.UnitIconSetDraw(id,false); suppressed[id] = true
                    end
                end
            end
        end
    end
    if #visible > 0 then ensureTargets() end
    for id in pairs(suppressed) do if not active[id] then restore(id) end end
end

local function drawGeometry(selected, maskPass)
    gl.UseShader(shader)
    gl.Uniform(timeUniform,Spring.GetGameSeconds())
    gl.Uniform(maskPassUniform,maskPass)
    for _, id in ipairs(visible) do
        local x,y,z = Spring.GetUnitBasePosition(id)
        local front,up,right = Spring.GetUnitVectors(id)
        local entry = cached[id]
        if entry and x and front and up and right then
            gl.Uniform(selectedUniform,selected[id] and 1 or 0)
            -- RGB8 exactly stores a 24-bit identity. Every piece uses the same
            -- key, so even overlapping standalone bodies have one contour.
            local key = id + 1
            gl.Uniform(keyUniform,(key % 256)/255,(math.floor(key/256) % 256)/255,
                (math.floor(key/65536) % 256)/255)
            gl.PushMatrix()
            gl.MultMatrix(-right[1],-right[2],-right[3],0, up[1],up[2],up[3],0,
                front[1],front[2],front[3],0, x,y,z,1)
            gl.CallList(entry.list)
            gl.PopMatrix()
        end
    end
end

local function drawMask(selected)
    gl.DepthTest(GL.LEQUAL); gl.DepthMask(true); gl.Culling(GL.BACK)
    gl.Blending(false); gl.AlphaTest(false); gl.ColorMask(true,true,true,true)
    gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0)
    drawGeometry(selected,1)
end

function gadget:DrawWorld()
    if #visible == 0 then return end
    gl.PushAttrib(GL.ALL_ATTRIB_BITS)
    gl.Scissor(false)
    -- Keep the main framebuffer's depth untouched. This private copy both
    -- hides houses behind the scene and resolves occlusion among their pieces.
    local selected = selectedHosts()
    if maskFBO then
        gl.CopyToTexture(depthTexture,0,0,viewX,viewY,viewWidth,viewHeight)
        gl.Texture(false)
        gl.ActiveFBO(maskFBO,drawMask,selected)
    end
    -- Restore the original translucent wireframe, including overlapping
    -- internal edges. Only the private mask resolves self-occlusion.
    gl.DepthTest(GL.LEQUAL); gl.DepthMask(false); gl.Culling(GL.BACK)
    gl.Blending(GL.SRC_ALPHA,GL.ONE)
    drawGeometry(selected,0)
    if maskFBO then
        gl.DepthTest(false); gl.DepthMask(false); gl.Culling(false)
        gl.Blending(GL.SRC_ALPHA,GL.ONE)
        gl.UseShader(contourShader)
        gl.Uniform(originUniform,viewX,viewY)
        gl.Texture(0,maskTexture)
        gl.Texture(1,depthTexture)
        gl.TexRect(-1,-1,1,1)
        gl.Texture(1,false)
        gl.Texture(0,false)
    end
    gl.UseShader(0); gl.PopAttrib()
end
function gadget:Shutdown()
    for id in pairs(suppressed) do restore(id) end
    for id in pairs(cached) do forget(id) end
    releaseTargets()
    if shader then gl.DeleteShader(shader); shader=nil end
    if contourShader then gl.DeleteShader(contourShader); contourShader=nil end
end
