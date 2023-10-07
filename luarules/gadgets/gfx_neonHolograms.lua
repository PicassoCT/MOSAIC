function gadget:GetInfo()
    return {
        name = "Neon Hologram Rendering ",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 0,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
	local SO_NODRAW_FLAG = 0
	local SO_OPAQUE_FLAG = 1
	local SO_ALPHAF_FLAG = 2
	local SO_REFLEC_FLAG = 4
	local SO_REFRAC_FLAG = 8
	local SO_SHOPAQ_FLAG = 16
	local SO_SHTRAN_FLAG = 32
	local SO_DRICON_FLAG = 128

    VFS.Include("scripts/lib_mosaic.lua")    
    VFS.Include("scripts/lib_UnitScript.lua")    
    local neonHologramTypeTable = getHologramTypes(UnitDefs)
    assert(neonHologramTypeTable)
    local engineVersion = getEngineVersion()

    -- set minimun engine version
    local unsupportedEngine = true
    local enabled = false
    local minEngineVersionTitle = '104.0.1-1455'
    if ( 104.0 < engineVersion  and engineVersion >= 105)  then
        unsupportedEngine = false
        enabled = true
        Spring.Echo("gadget Neon Hologram Rendering is enabled")
    end

    function gadget:Initialize()
        allUnits = Spring.GetAllUnits()
        for _,id in pairs(allUnits) do
            unitDefID = Spring.GetUnitDefID(id)
            registerUnitIfHolo(id, unitDefID)
        end
    end

    function registerUnitIfHolo(unitID, unitDefID)
         if neonHologramTypeTable[unitDefID] then
            local drawMask = SO_OPAQUE_FLAG + SO_ALPHAF_FLAG + SO_REFLEC_FLAG  + SO_REFRAC_FLAG + SO_DRICON_FLAG 
            if engineVersion > 105.0 then
                Spring.SetUnitEngineDrawMask(unitID, drawMask)
            end
            Spring.Echo("Hologram Type " .. UnitDefs[unitDefID].name .. " created")
            SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

    function gadget:UnitCreated(unitID, unitDefID)        
       registerUnitIfHolo(unitID, unitDefID)
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            Spring.Echo("Hologram Type " .. UnitDefs[unitDefID].name .. " created")
            SendToUnsynced("unsetUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

else -- unsynced

    local LuaShader = VFS.Include("LuaRules/Gadgets/Include/LuaShader.lua")
    local spGetVisibleUnits = Spring.GetVisibleUnits
    local spGetTeamColor = Spring.GetTeamColor
    local screencopy
    local depthtex

    local glGetSun = gl.GetSun
    local glDepthTest = gl.DepthTest
    local glCulling = gl.Culling
    local glBlending = gl.Blending

    local glPushPopMatrix = gl.PushPopMatrix
    local glPushMatrix = gl.PushMatrix
    local glPopMatrix = gl.PopMatrix
    local glUnitMultMatrix = gl.UnitMultMatrix
    local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix
    local glUnitPiece = gl.UnitPiece
    local glTexture = gl.Texture
    local glUnitShapeTextures = gl.UnitShapeTextures
    local glCopyToTexture = gl.CopyToTexture

    local GL_BACK  = GL.BACK
    local GL_FRONT = GL.FRONT
    local neonUnitTables = {}

-------Shader--FirstPass -----------------------------------------------------------
local neoVertexShaderFirstPass = VFS.LoadFile ("LuaRules/Gadgets/shaders/neonHologramShader.vert")
local neoFragmenShaderFirstPass=  VFS.LoadFile("LuaRules/Gadgets/shaders/neonHologramShader.frag")
local neonHologramShader
local glowReflectHologramShader
local vsx, vsy,vpx,vpy
local sunChanged = false
-------------------------------------------------------------------------------------

-------Shader--2ndPass -----------------------------------------------------------
--Glow Reflection etc.
--Execution of the shader
    function gadget:ViewResize(viewSizeX, viewSizeY) --TODO test/assert
    	vsx, vsy = viewSizeX, viewSizeY
        depthtex = gl.CreateTexture(vsx,vsy, {
            border = false,
            format = GL_DEPTH_COMPONENT24,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST,
        })

        screencopy= gl.CreateTexture(vsx,vsy, {
            target = target,
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s   = GL.CLAMP_TO_EDGE,
            wrap_t   = GL.CLAMP_TO_EDGE,
          })

    end

    local counterNeonUnits = 0
    local function unsetUnitNeonLuaDraw(callname, unitID, typeDefID)
        neonUnitTables[unitID] = nil
        counterNeonUnits= counterNeonUnits - 1
    end

    local function setUnitNeonLuaDraw(callname, unitID, typeDefID)
        neonUnitTables[unitID] = typeDefID
        Spring.UnitRendering.SetUnitLuaDraw(unitID, true)       
        counterNeonUnits= counterNeonUnits + 1
    end	

    local function InitializeTextures()
        vsx, vsy, vpx, vpy = Spring.GetViewGeometry()
        depthtex = gl.CreateTexture(vsx,vsy, {
            border = false,
            format = GL_DEPTH_COMPONENT24,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST,
        })

        screencopy= gl.CreateTexture(vsx,vsy, {
            target = target,
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s   = GL.CLAMP_TO_EDGE,
            wrap_t   = GL.CLAMP_TO_EDGE,
          })

    end

local fragmentShader = 
[[

void main() 
{
    gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5);
}
]]


    function gadget:Initialize() 
		InitializeTextures()
		gadget:ViewResize(vsx, vsy)
        gadgetHandler:AddSyncAction("setUnitNeonLuaDraw", setUnitNeonLuaDraw)
        gadgetHandler:AddSyncAction("unsetUnitNeonLuaDraw", unsetUnitNeonLuaDraw)

        neonHologramShader = LuaShader({
            vertex = neoVertexShaderFirstPass,
            fragment =  fragmentShader,--neoFragmenShaderFirstPass,
            textures = {
                    [0] = tex1,
                    [1] = tex2,
                    [2] = normalTex,
                    [3] = reflectTex,
                    [4] = screenTex,
                    [5] = depthTex
                },            
            uniformInt = {
                tex1 = 0,
                tex2 = 1,
                normalTex = 2,
                reflectTex = 3,
                screenTex= 4,
                depthTex= 5
            },

            uniformFloat = {
                time = Spring.GetGameFrame()/30.0,
                vPositionWorld = {0.0,0.0,0.0},
                uv = {0.0,0.0},                
            },
        }, "Neon Hologram Shader")

        compileResult = neonHologramShader:Initialize()
        Spring.Echo(compileResult)
    end

    local boolActivated = false

    local function RenderNeonUnits()
        if counterNeonUnits == 0 or not boolDoesCompile then
            return
        end

        if not boolActivated then
            local boolDoesCompile = true
            boolDoesCompile = neonHologramShader:Initialize()
            if not boolDoesCompile then return end
            boolActivated= true
        end

        glCopyToTexture(screencopy, 0, 0, vpx, vpy, vsx, vsy)

        if sunChanged then
                neonHologramShader:SetUniformFloatArrayAlways("pbrParams", {
                Spring.GetConfigFloat("tonemapA", 4.8),
                Spring.GetConfigFloat("tonemapB", 0.8),
                Spring.GetConfigFloat("tonemapC", 3.35),
                Spring.GetConfigFloat("tonemapD", 1.0),
                Spring.GetConfigFloat("tonemapE", 1.15),
                Spring.GetConfigFloat("envAmbient", 0.3),
                Spring.GetConfigFloat("unitSunMult", 1.35),
                Spring.GetConfigFloat("unitExposureMult", 1.0),
            })
            sunChanged = false
        end

        glDepthTest(true)

        neonHologramShader:ActivateWith(
        function()    
            for id, typeDefID in pairs(neonUnitTables) do
                local unitID = id            
                local unitDefID = typeDefID
            end
        end)
        neonHologramShader:SetUniformFloat("time", Spring.GetGameFrame()/30.0)
        neonHologramShader:Deactivate()
        glDepthTest(false)
        glCulling(false)
    end


    function gadget:DrawWorld()
        RenderNeonUnits()
    end

    function gadget:Shutdown()
        neonHologramShader:Finalize()
        gadgetHandler.RemoveSyncAction("setUnitNeonLuaDraw")
        gadgetHandler:RemoveChatAction("unsetUnitNeonLuaDraw")
    end
end
