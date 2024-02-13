function gadget:GetInfo()
    return {
        name = "Neon Hologram Rendering ",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 0,
        version = 1,
        enabled = true,
        hidden = true,
    }
end

if (gadgetHandler:IsSyncedCode()) then
    local frameGameStart = math.huge      
    local myAllyTeamID = 0
    local myTeam = nil
	local SO_NODRAW_FLAG = 0
	local SO_OPAQUE_FLAG = 1
	local SO_ALPHAF_FLAG = 2
	local SO_REFLEC_FLAG = 4
	local SO_REFRAC_FLAG = 8
	local SO_SHOPAQ_FLAG = 16
	local SO_SHTRAN_FLAG = 32
	local SO_DRICON_FLAG = 128
    local boolOverride = true


    VFS.Include("scripts/lib_mosaic.lua")    
    VFS.Include("scripts/lib_UnitScript.lua")    
    
    function gadget:PlayerChanged(playerID)
        if Spring.GetMyAllyTeamID then
            myAllyTeamID = Spring.GetMyAllyTeamID()
        end
        if Spring.GetMyTeamID then
            myTeam = Spring.GetMyTeamID()
        end
    end

    function HEAD()
        return "Neon Hologram Rendering: "
    end


    local neonHologramTypeTable = getHologramTypes(UnitDefs)
    assert(neonHologramTypeTable)
    local engineVersion = getEngineVersion()
    echo(HEAD().." have engine version: "..engineVersion)
    -- set minimun engine version
    local unsupportedEngine = true
    local enabled = false
    local minEngineVersionTitle = '104.0.1-1455'
    if ( 104.0 < engineVersion  and engineVersion >= 105)  then
        unsupportedEngine = false
        enabled = true
        echo(HEAD().."is enabled")
    end

    function gadget:Initialize()
        myAllyTeamID = 0--Spring.GetMyAllyTeamID()
        if Spring.GetMyTeamID then
            myTeam = Spring.GetMyTeamID () 
        end
        allUnits = Spring.GetAllUnits()
        for _,id in pairs(allUnits) do
            unitDefID = Spring.GetUnitDefID(id) 
            if neonHologramTypeTable[unitDefID] then
                registerUnitIfHolo(id, unitDefID)
            end
        end
    end

    local function serializePiecesTableTostring(t)
        local result = ""
        for i=1, #t do
            result = result.."|"..t
        end
        return result
    end

    local allNeonUnits= {}
    local neonUnitDataTransfer = {}
    function registerUnitIfHolo(unitID, unitDefID)
         if neonHologramTypeTable[unitDefID] then
            echo(HEAD().."start registering holo unit")
            local drawMask = SO_OPAQUE_FLAG + SO_ALPHAF_FLAG + SO_REFLEC_FLAG  + SO_REFRAC_FLAG + SO_DRICON_FLAG 
            if engineVersion >= 105.0 and  Spring.SetUnitEngineDrawMask then
                Spring.SetUnitEngineDrawMask(unitID, drawMask)
                echo(HEAD().." Setting unit engine drawMask")
            end
            local emptyTable = {}
            local stringToSend = ""
            Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
            SendToUnsynced("setUnitNeonLuaDraw", unitID, stringToSend)             
            allNeonUnits[#allNeonUnits + 1]= unitID
            echo(HEAD().." Registering Hologram Type " .. UnitDefs[unitDefID].name .. " completed")
           -- SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

    local function transferDynamicLights(unitIDTable)
        local totalMessage = ""
        for i=1, #unitIDTable do
            local x,y,z = Spring.GetUnitPosition(unitIDTable[i])
            if x ~= nil then
            ---pos.xyz, light.rgb, light strength TODO missing
            local full = 1.0
            local empty = 0.0
            totalMessage = x.."/"..y.."/"..z.."/"..full.."/"..empty.."/"..empty.."/5.0"
            Spring.SetGameRulesParam("dynamic_lights", totalMessage)
            end
        end
      
    end

    function gadget:GameFrame(frame)
		if frame > frameGameStart then
            if count(neonUnitDataTransfer) > 0 then
                local UnitsDynGlow = {}
                local VisibleUnitPieces = GG.VisibleUnitPieces
                SendToUnsynced("resetUnitNeonLuaDraw")       
    			for id, value in pairs(neonUnitDataTransfer) do
                    table.insert(UnitsDynGlow, id)
                    echo(HEAD().." Start:Sending Neon Hologram unit data:"..toString(VisibleUnitPieces[id] ))
    				if id and value and VisibleUnitPieces[id] then
                        local serializedStringToSend = serializePiecesTableTostring(VisibleUnitPieces[value])
    					SendToUnsynced("setUnitNeonLuaDraw", id, serializedStringToSend )       
                        echo(HEAD().."Complete:setUnitNeonLuaDraw:"..unitID..":"..serializedStringToSend)         
    				end
    			end                
            end
		end
    end

    function gadget:UnitCreated(unitID, unitDefID)        
       registerUnitIfHolo(unitID, unitDefID)
    end

   function gadget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    assert(unitDefID)
    assert(UnitDefs[unitDefID])
        if neonHologramTypeTable[unitDefID] then
            echo(HEAD().."Neon Hologram unit has entered LOS")
            if boolOverride or  myTeam and CallAsTeam(myTeam, Spring.IsUnitVisible, unitID, nil, false) then
                echo(HEAD().."Neon Hologram unit has entered LOS of myTeam")
                neonUnitDataTransfer[unitID] = unitID
            end
        end
    end

    function gadget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            echo(HEAD().."Neon Hologram unit has left LOS")
            if  boolOverride or  (myTeam and not CallAsTeam(myTeam, Spring.IsUnitVisible, unitID, nil, false)) then
                    neonUnitDataTransfer[unitID] = nil
            end
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            echo(HEAD().."Neon Hologram unit has entered LOS")
            for i=#allNeonUnits, 1, -1 do
                if allNeonUnits[i] == unitID then
                    table.remove(allNeonUnits, i)
                end
            end
        end
    end

else -- unsynced

    local LuaShader                 = VFS.Include("luarules/gadgets/include/LuaShader.lua")
    local neoVertexShaderFirstPass  = VFS.LoadFile ("luarules/gadgets/shaders/neonHologramShader.vert")
    local neoFragmenShaderFirstPass = VFS.LoadFile("luarules/gadgets/shaders/neonHologramShader.frag")

    local spGetVisibleUnits         = Spring.GetVisibleUnits
    local spGetTeamColor            = Spring.GetTeamColor

    local glGetSun                  = gl.GetSun
    local glDepthTest               = gl.DepthTest
    local glCulling                 = gl.Culling
    local glBlending                = gl.Blending
    
    local GL_SRC_ALPHA              = GL.SRC_ALPHA
    local GL_ONE                    = GL.ONE
    local GL_ONE_MINUS_SRC_ALPHA    = GL.ONE_MINUS_SRC_ALPHA     
    local GL_BACK                   = GL.BACK
    local GL_FRONT                  = GL.FRONT
    local uniformViewPortSize 
    local uniformTime
    local GL_DEPTH_BITS             = 0x0D56
    local GL_DEPTH_COMPONENT        = 0x1902
    local GL_DEPTH_COMPONENT16      = 0x81A5
    local GL_DEPTH_COMPONENT24      = 0x81A6
    local GL_DEPTH_COMPONENT32      = 0x81A7
    local GL_RGB8_SNORM             = 0x8F96
    local GL_RGBA8                  = 0x8058
    local GL_FUNC_ADD               = 0x8006
    local GL_FUNC_REVERSE_SUBTRACT  = 0x800B
    
    local glPushPopMatrix           = gl.PushPopMatrix
    local glPushMatrix              = gl.PushMatrix
    local glPopMatrix               = gl.PopMatrix
    local glUnitMultMatrix          = gl.UnitMultMatrix
    local glUnitPieceMultMatrix     = gl.UnitPieceMultMatrix
    local glUnitPiece               = gl.UnitPiece
    local glTexture                 = gl.Texture
    local glUnitShapeTextures       = gl.UnitShapeTextures
    local glCopyToTexture           = gl.CopyToTexture
    local glCreateTexture           = gl.CreateTexture
    local glDeleteTexture           = gl.DeleteTexture
    local neonUnitTables            = {}
    local glUnitShapeTextures       = gl.UnitShapeTextures
    local glGetUniformLocation      = gl.GetUniformLocation
    local glUnit                    = gl.Unit
-------Shader--FirstPass -----------------------------------------------------------

    local neonHologramShader
    local glowReflectHologramShader
    local vsx, vsy,vpx,vpy
    local sunChanged = false
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitPosition = Spring.GetUnitPosition
    local screentex = nil
    local afterglowbuffertex = nil

-------------------------------------------------------------------------------------

-------Shader--2ndPass -----------------------------------------------------------
--Glow Reflection etc.
--Execution of the shader
    function gadget:ViewResize(viewSizeX, viewSizeY) --TODO test/assert
    	vsx, vsy = viewSizeX, viewSizeY

        screentex= gl.CreateTexture(vsx,vsy, {
            target = target,
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s   = GL.CLAMP_TO_EDGE,
            wrap_t   = GL.CLAMP_TO_EDGE,
          })

        afterglowbuffertex = glCreateTexture(vsx,vsy,
            {
            min_filter = GL.LINEAR, 
            mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE, 
            wrap_t = GL.CLAMP_TO_EDGE,
            })

    end

    local counterNeonUnits = 0
    local neonHoloParts= {}

    local function splitToNumberedArray(msg)
        local message = msg..'|'
        local t = {}
        for e in string.gmatch(message,'([^%|]+)%|') do
            t[#t+1] = tonumber(e)
        end
        return t
    end

    local function setUnitNeonLuaDraw(callname, unitID, listOfVisibleUnitPiecesString)
        Spring.Echo("setUnitNeonLuaDraw:"..unitID..":"..listOfVisibleUnitPiecesString)
        local piecesTable = splitToNumberedArray(listOfVisibleUnitPiecesString)
        neonUnitTables[unitID] = {id = unitID, pieces = piecesTable} 
        counterNeonUnits= counterNeonUnits + 1
    end	

    local function resetUnitNeonLuaDraw(callname)
        neonUnitTables = {} 
        counterNeonUnits= 0
    end    

    local function InitializeTextures()
        vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

        if (screentex ~= nil) then
            glDeleteTexture(screentex)
        end  

        if (afterglowbuffertex ~= nil) then
            glDeleteTexture(afterglowbuffertex)
        end  

        screentex= glCreateTexture(vsx,vsy, 
            {
            target = target,
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s   = GL.CLAMP_TO_EDGE,
            wrap_t   = GL.CLAMP_TO_EDGE,
            })

        afterglowbuffertex = glCreateTexture(vsx,vsy,
            {
            min_filter = GL.LINEAR, 
            mag_filter = GL.LINEAR,
            wrap_s = GL.CLAMP_TO_EDGE, 
            wrap_t = GL.CLAMP_TO_EDGE,
            }
        )

    end

    local defaultVertexShader = 
    [[
       #version 150 compatibility
        uniform float time;
        //uniform vec3 unitCenterPosition;
        //uniform vec2 viewPortSize;
        //uniform sampler2D tex1;
        //uniform sampler2D tex2;
        //uniform sampler2D normaltex;
        //uniform sampler2D reflecttex;
        //uniform sampler2D screentex;
        //uniform sampler2D normalunittex;
        //uniform sampler2D afterglowbuffertex; 
        
        void main() {
            vec4 posCopy = gl_Vertex;
            posCopy.xz = 3*sin(time)*posCopy.xz;
            gl_Position = posCopy;
        }
    ]]

    local defaultTestFragmentShader = 
    [[
        #version 150 compatibility
        uniform float time;
        //uniform vec3 unitCenterPosition;
        //uniform vec2 viewPortSize;
        //uniform sampler2D tex1;
        //uniform sampler2D tex2;
        //uniform sampler2D normaltex;
        //uniform sampler2D reflecttex;
        //uniform sampler2D screentex;
        //uniform sampler2D normalunittex;
        //uniform sampler2D afterglowbuffertex;

        void main() 
        {
            gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5);
        }
    ]]
 
    local boolActivated = false
    function gadget:Initialize() 
		InitializeTextures()
		gadget:ViewResize(vsx, vsy)
        gadgetHandler:AddSyncAction("setUnitNeonLuaDraw", setUnitNeonLuaDraw)
        gadgetHandler:AddSyncAction("resetUnitNeonLuaDraw", resetUnitNeonLuaDraw)
		frameGameStart = Spring.GetGameFrame()+1

        neonHologramShader = LuaShader({
            vertex =  defaultVertexShader, --neoVertexShaderFirstPass,
            fragment = defaultTestFragmentShader,-- neoFragmenShaderFirstPass,
            textures = {
                    [0] = tex1,
                    [1] = tex2,
                    [2] = reflecttex,
                    [3] = screentex,
                    [4] = normalunittex,
                    [5] = afterglowbuffertex
                },       
            uniform = {
                time =  Spring.GetGameSeconds(),
            },     
            uniformInt = {
                tex1            = 0,
                tex2            = 1,
                reflecttex      = 2,
                screentex       = 3,
                afterglowbuffer = 4,
                normalunittex   = 5

            },
            uniformFloat = {
              --[[  viewPortSize = {vsx, vsy},                 
                unitCenterPosition = {0,0,0}--]]
            },
        }, "Neon Hologram Shader")

        boolActivated = neonHologramShader:Initialize()
        if not boolActivated then 
                Spring.Echo("NeonShader:: did not compile")
                gadgetHandler:RemoveGadget(self)
                return 
        end

       Spring.Echo("NeonShader:: did compile")
    end

    local function RenderAllNeonUnits()

        if counterNeonUnits ~= oldCounterNeonUnits and counterNeonUnits then
            oldCounterNeonUnits= counterNeonUnits
            Spring.Echo("Rendering new Neon Units with n-units ".. counterNeonUnits)
        end

        if counterNeonUnits == 0 or not boolActivated then
            Spring.Echo("Rendering no Neon Units cause no units")
            return
        end   

        glTexture(0, "$tex1")
        glTexture(1, "$tex2")
        glTexture(2, "$normal") 
        glTexture(3, "$reflection") 
        glTexture(5, "$model_gbuffer_normtex") 
       
        glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy) -- the depth texture
        glDepthTest(true)  
        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

        neonHologramShader:ActivateWith(
        function()   
                neonHologramShader:SetUniformFloat("time",  Spring.GetGameSeconds() )
                neonHologramShader:SetUniformFloatArray("viewPortSize", {vsx, vsy} )

                --variables
                Spring.Echo("Start drawing units")
                for _, data in pairs(neonUnitTables) do
                    local unitID = data.id
                    local neonHoloDef = spGetUnitDefID(unitID)
                    local x,y,z = spGetUnitPosition(unitID)
                    neonHologramShader:SetUniformFloatArray("unitCenterPosition", {x,y,z })

                    --local neonHoloParts = neonUnitTables[i].pieces
                    local neonHoloParts = data.pieces 
                    glUnitShapeTextures(neonHoloDef, true)
                
                    glCulling(GL_FRONT)
                    for j = 1, #neonHoloParts do
                        local pieceID = neonHoloParts[j]
                        glPushMatrix()
                            glUnitMultMatrix(unitID)
                            glUnitPieceMultMatrix(unitID, pieceID)
                            glUnitPiece(unitID, pieceID)
                        glPopMatrix()
                    end

                    glCulling(GL_BACK)
                    for j = 1, #neonHoloParts do
                        local pieceID = neonHoloParts[j]
                        glPushMatrix()
                            glUnitMultMatrix(unitID)
                            glUnitPieceMultMatrix(unitID, pieceID)
                            glUnitPiece(unitID, pieceID)
                        glPopMatrix()
                    end   
                    glUnitShapeTextures(neonHoloDef, false)
                end    
            end         
        )
        glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)    
        glTexture(0, false)
        glTexture(1, false)
        glTexture(2, false)
        glTexture(3, false)        
        glTexture(4, false)        
        glTexture(5, false)   
        glDepthTest(false)
        glCulling(false)
    end

    --function gadget:DrawWorld(deferredPass, drawReflection, drawRefraction)
    function gadget:.DrawUnitsPostDeferred()
        RenderAllNeonUnits()
    end

    function gadget:Shutdown()
        Spring.Echo("NeonShader:: shutting down gadget")
        neonHologramShader:Finalize()
        gadgetHandler.RemoveSyncAction("setUnitNeonLuaDraw")
        gadgetHandler.RemoveSyncAction("resetUnitNeonLuaDraw")
    end
end
