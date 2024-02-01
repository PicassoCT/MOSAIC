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
            registerUnitIfHolo(id, unitDefID)
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
            if engineVersion > 105.0 and  Spring.SetUnitEngineDrawMask then
                Spring.SetUnitEngineDrawMask(unitID, drawMask)
            end
            local emptyTable = {}
            local stringToSend = ""
            SendToUnsynced("setUnitNeonLuaDraw", unitID, stringToSend)             
            allNeonUnits[#allNeonUnits + 1]= unitID
            echo(" Registering Hologram Type " .. UnitDefs[unitDefID].name .. " completed")
           -- SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

    local function transferDynamicLights(unitIDTable)
        local totalMessage = ""
        for i=1, #unitIDTable do
            local x,y,z = Spring.GetUnitPosition(unitIDTable[i])
            ---pos.xyz, light.rgb, light strength TODO missing
            totalMessage = totalMessage..x.."/"..y.."/"..z.."/"
        end
        Spring.SetGameRulesParam("dynamic_lights", totalMessage)
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

    local LuaShader                 = VFS.Include("LuaRules/Gadgets/Include/LuaShader.lua")
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
    local GL_DEPTH_BITS = 0x0D56
    local GL_DEPTH_COMPONENT   = 0x1902
    local GL_DEPTH_COMPONENT16 = 0x81A5
    local GL_DEPTH_COMPONENT24 = 0x81A6
    local GL_DEPTH_COMPONENT32 = 0x81A7
    local GL_RGB8_SNORM = 0x8F96
    local GL_RGBA8 = 0x8058
    local GL_FUNC_ADD = 0x8006
    local GL_FUNC_REVERSE_SUBTRACT = 0x800B
    
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
-------Shader--FirstPass -----------------------------------------------------------
    local neoVertexShaderFirstPass  = VFS.LoadFile ("LuaRules/Gadgets/shaders/neonHologramShader.vert")
    local neoFragmenShaderFirstPass = VFS.LoadFile("LuaRules/Gadgets/shaders/neonHologramShader.frag")
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

    end

    local counterNeonUnits = 0
    local oldCounterNeonUnits = 0
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
        Spring.UnitRendering.SetUnitLuaDraw(unitID)   
        local piecesTable = splitToNumberedArray(listOfVisibleUnitPiecesString)
        neonUnitTables[#neonUnitTables +1] = {id = unitID, pieces = piecesTable} 
        counterNeonUnits= counterNeonUnits + 1
    end	

   local function resetUnitNeonLuaDraw(callname)
        neonUnitTables = {} 
        counterNeonUnits= 0
    end 
    

    local function InitializeTextures()
        vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

        if (screentex ~= nil  ) then
            glDeleteTexture(screentex)
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

    local commonTexOpts = {
        target = GL_TEXTURE_2D,
        border = false,
        min_filter = GL.NEAREST,
        mag_filter = GL.NEAREST,

        wrap_s = GL.CLAMP_TO_EDGE,
        wrap_t = GL.CLAMP_TO_EDGE,
    }
    commonTexOpts.format = GL_RGB8_SNORM

    normalunittex = glCreateTexture(vsx, vsy, commonTexOpts)

    end

    local defaultVertexShader = 
    [[
       #version 150 compatibility
        uniform float time;
        uniform vec3 unitCenterPosition;
        uniform float viewPosX;
        uniform float viewPosY;

        void main() {
            vec4 posCopy = gl_Vertex;
            posCopy.z = sin(time)*posCopy.z;
            gl_Position = posCopy;
        }
    ]]

    local defaultTestFragmentShader = 
    [[
        #version 150 compatibility
        uniform float time;
        uniform vec3 unitCenterPosition;
        uniform float viewPosX;
        uniform float viewPosY;

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
                    [2] = normaltex,
                    [3] = reflecttex,
                    [4] = screentex,
                    [5] = normalunittex,
                    [6] = afterglowbuffertex,
                },            
            uniformInt = {
                tex1 = 0,
                tex2 = 1,
                normaltex = 2,
                reflecttex = 3,
                screentex= 4,
                normalunittex= 5,
                afterglowbuffer=6
            },
            uniformFloat = {
                viewPortSize = {vsx, vsy},
                --viewPosY = 0,
                time = Spring.GetGameSeconds(),           
                unitCenterPosition = {0,0,0}
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

local function RenderNeonUnits()

        if counterNeonUnits ~= oldCounterNeonUnits  and counterNeonUnits then
            oldCounterNeonUnits= counterNeonUnits
            Spring.Echo("Rendering no Neon Units with n-units "..counterNeonUnits)
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

        neonHologramShader:SetUniformFloat("time",  Spring.GetGameSeconds() )
        neonHologramShader:SetUniformFloatArray("viewPortSize", {vsx, vsy} )
        glCopyToTexture()
        glDepthTest(true)  

        neonHologramShader:ActivateWith(
        function()   

                glBlending(GL_SRC_ALPHA, GL_ONE)
                --variables
                for i = 1, #neonUnitTables do
                    local unitID = neonUnitTables[i].id
                    local neonHoloDef = spGetUnitDefID(unitID)

                    neonHologramShader:SetUniformFloatArray("unitCenterPosition", spGetUnitPosition(unitID))
                   
                    --local neonHoloParts = neonUnitTables[i].pieces
                    local neonHoloParts = Spring.GetUnitPieceList(unitID)
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
                end
            glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)    
            glTexture(0, false)
            glTexture(1, false)
            glTexture(2, false)
            glTexture(3, false)        
            glTexture(4, false)        
            glTexture(5, false)        
   
            end         
        )

        glDepthTest(false)
        glCulling(false)
    end

    function gadget:DrawOpaqueUnitsLua(deferredPass, drawReflection, drawRefraction)
        RenderNeonUnits()
    end

    function gadget:Shutdown()
        Spring.Echo("NeonShader:: shutting down gadget")
        neonHologramShader:Finalize()
        gadgetHandler.RemoveSyncAction("setUnitNeonLuaDraw")
        gadgetHandler.RemoveSyncAction("resetUnitNeonLuaDraw")
    end
end
