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
    
    VFS.Include("scripts/lib_mosaic.lua")    
    VFS.Include("scripts/lib_UnitScript.lua")    

    local frameGameStart = Spring.GetGameFrame()     
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


    local allNeonUnits= {}
    local neonUnitDataTransfer = {}
    function registerUnitIfHolo(unitID, unitDefID)
         if neonHologramTypeTable[unitDefID] then
            echo(HEAD().."start registering holo unit")
            Spring.SetUnitNoDraw(unitID, true)
            if engineVersion >= 105.0 and  Spring.SetUnitEngineDrawMask then
               -- local drawMask = SO_OPAQUE_FLAG + SO_ALPHAF_FLAG + SO_REFLEC_FLAG  + SO_REFRAC_FLAG + SO_DRICON_FLAG 
               -- Spring.SetUnitEngineDrawMask(unitID, drawMask)
                echo(HEAD().." Setting unit engine drawMask")
            end
            local emptyTable = {}
            local stringToSend = ""

   
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
    local function serializePiecesTableTostring(t)
        result = ""
        for i=1, #t do
            result = result.."|"..t[i]
        end
        return result
    end
    local cachedUnitPieces = {}
    local oldneonUnitDataTransfer = {}
    function gadget:GameFrame(frame)
		if frame > frameGameStart then           
            if count(neonUnitDataTransfer) > 0 then            
                local VisibleUnitPieces = GG.VisibleUnitPieces   
                if VisibleUnitPieces then
        			for id, value in pairs(neonUnitDataTransfer) do
                        -- echo(HEAD().." Start:Sending Neon Hologram unit data:"..toString(VisibleUnitPieces[id] ))
        				if id and value and VisibleUnitPieces[id] and VisibleUnitPieces[id] ~= cachedUnitPieces[id]then
                            local serializedStringToSend = serializePiecesTableTostring(VisibleUnitPieces[value])
                            cachedUnitPieces[id] = VisibleUnitPieces[value]
        					SendToUnsynced("setUnitNeonLuaDraw", id, serializedStringToSend )              
        				end
        			end 
                    for id, value in pairs(oldneonUnitDataTransfer) do
                        if not neonUnitDataTransfer[id] then
                            SendToUnsynced("unsetUnitNeonLuaDraw", id)       
                        end
                    end
                    oldneonUnitDataTransfer = neonUnitDataTransfer      
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
    local DAYLENGTH = 28800
    local LuaShader                 = VFS.Include("luarules/gadgets/include/LuaShader.lua")
    local neoVertexShaderFirstPass  = VFS.LoadFile ("luarules/gadgets/shaders/neonHologramShader.vert")
    local neoFragmenShaderFirstPass = VFS.LoadFile("luarules/gadgets/shaders/neonHologramShader.frag")

    local spGetVisibleUnits         = Spring.GetVisibleUnits
    local spGetTeamColor            = Spring.GetTeamColor

    local glGetSun                  = gl.GetSun
    local glDepthTest               = gl.DepthTest
    local glDepthMask               = gl.DepthMask
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
local function getDayTime()
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end

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
            local pieceID =  tonumber(e)
            table.insert(t, pieceID )            
        end
        return t
    end

    local function setUnitNeonLuaDraw(callname, unitID, listOfVisibleUnitPiecesString)
        --Spring.Echo("setUnitNeonLuaDraw:"..unitID..":"..listOfVisibleUnitPiecesString)
        Spring.UnitRendering.SetUnitLuaDraw(unitID, false)

        local piecesTable = splitToNumberedArray(listOfVisibleUnitPiecesString)
        neonUnitTables[unitID] =  piecesTable
        counterNeonUnits= counterNeonUnits + 1
    end	

    local function unsetUnitNeonLuaDraw(callname, unitID)
        neonUnitTables[unitID] = nil
        counterNeonUnits= counterNeonUnits - 1
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
            fbo = true,
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
        uniform float timepercent;
        uniform mat4 viewInvMat;
        //uniform vec3 unitCenterPosition;
        //uniform vec2 viewPortSize;
        uniform sampler2D tex1;
        //uniform sampler2D tex2;
        //uniform sampler2D normaltex;
        //uniform sampler2D reflecttex;
        //uniform sampler2D screentex;
        //uniform sampler2D normalunittex;
        //uniform sampler2D afterglowbuffertex; 
        out Data {
            vec2 uv;
        };
        void main() {
            vec4 posCopy = gl_Vertex;
            uv = gl_MultiTexCoord0.xy;
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        }
    ]]

    local defaultFragmentShader = 
    [[
        #version 150 compatibility
        uniform float time;
        uniform float timepercent;
        in Data {
            vec2 uv;
        };

        float getLightAmp()
        {
            if (timepercent < 0.25 || timepercent > 0.75) return 0.9;

            return 0.75;
        }

        uniform mat4 viewInvMat;
        //uniform vec3 unitCenterPosition;
        //uniform vec2 viewPortSize;
        uniform sampler2D tex1;
        //uniform sampler2D tex2;
        //uniform sampler2D normaltex;
        //uniform sampler2D reflecttex;
        //uniform sampler2D screentex;
        //uniform sampler2D normalunittex;
        //uniform sampler2D afterglowbuffertex;

        void main() 
        {
            vec4 tex1Color = texture(tex1, uv);
            gl_FragColor = vec4( tex1Color.rgb  , 1.0);
            //gl_FragColor = vec4( tex1Color.rgb * getLightAmp() , 0.5);
        }
    ]]
 
    local boolActivated = false
    function gadget:Initialize() 
		InitializeTextures()
		gadget:ViewResize(vsx, vsy)
        gadgetHandler:AddSyncAction("setUnitNeonLuaDraw", setUnitNeonLuaDraw)
        gadgetHandler:AddSyncAction("unsetUnitNeonLuaDraw", resetUnitNeonLuaDraw)
		frameGameStart = Spring.GetGameFrame()+1

        neonHologramShader = LuaShader({
            vertex =   neoVertexShaderFirstPass, --defaultVertexShader
            fragment = neoFragmenShaderFirstPass,--defaultFragmentShader
            textures = {
                    [0] = tex1,
                    [1] = tex2,
                    [2] = normaltex,
                    [3] = reflecttex,
                    [4] = screentex,
                    [5] = afterglowbuffertex
                },       
            uniform = {
                time =  Spring.GetGameSeconds(),
                timepercent = 0.5
            },     
            uniformInt = {
                tex1 = 0,
                tex2 = 1,
                normaltex = 2,
                reflecttex = 3,
                screentex = 4
            },
            uniformFloat = {
               viewPortSize = {vsx, vsy},                 
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
    local holoDefID = nil
    for i=1,#UnitDefs do
        if UnitDefs[i].name == "house_western_hologram" then
            holoDefID =  UnitDefs[i].id
        end
    end       

    local function RenderAllNeonUnits()

        if counterNeonUnits == 0 or not boolActivated then
            Spring.Echo("Rendering no Neon Units cause no units")
            return
        end 

        glTexture(2, "$normal") 
        glTexture(3, "$reflection") 
       
        glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy) -- the depth texture
        glDepthTest(true)
        glDepthMask(false)
        glCulling(GL_BACK)


        neonHologramShader:ActivateWith(
            function()  
                neonHologramShader:SetUniformMatrix("viewInvMat", "viewinverse")
                neonHologramShader:SetUniformFloat("timepercent",  timepercent)
                neonHologramShader:SetUniformFloat("time",  Spring.GetGameSeconds() )
                neonHologramShader:SetUniformFloatArray("vCamPositionWorld", Spring.GetCameraPosition() )
                neonHologramShader:SetUniformFloatArray("viewPortSize", {vsx, vsy} )

                glBlending(GL_SRC_ALPHA, GL_ONE)
                --variables
                glTexture(0, "unittextures/house_europe_diffuse.dds")
                glTexture(1, "unittextures/house_europe_normal.dds")

                for unitID, neonHoloParts in pairs(neonUnitTables) do

                    local unitDefID = spGetUnitDefID(unitID)

                    local x,y,z = spGetUnitPosition(unitID)
                    neonHologramShader:SetUniformFloatArray("unitCenterPosition", {x,y,z})

                    glCulling(GL_FRONT)
                    for  _, pieceID in ipairs(neonHoloParts)do

                      glPushPopMatrix( function()
                            glUnitMultMatrix(unitID)
                            glUnitPieceMultMatrix(unitID, pieceID)
                            glUnitPiece(unitID, pieceID)
                        end)
                    end
                       
                    glCulling(GL_BACK)
                    for _,pieceID in ipairs(neonHoloParts)do
                      glPushPopMatrix( function()
                            glUnitMultMatrix(unitID)
                            glUnitPieceMultMatrix(unitID, pieceID)
                            glUnitPiece(unitID, pieceID)
                        end)
                    end
                end  

                glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)    
                --Cleanup
                glTexture(0, false)
                glTexture(1, false)
                glTexture(2, false)
                glTexture(3, false)        
                glTexture(4, false)        
                glDepthTest(false)
            end         
        )
    end

    --function gadget:DrawWorld(deferredPass, drawReflection, drawRefraction)
    function gadget:DrawWorld()
        RenderAllNeonUnits()
    end

    function gadget:Shutdown()
        Spring.Echo("NeonShader:: shutting down gadget")
        neonHologramShader:Finalize()
        gadgetHandler.RemoveSyncAction("setUnitNeonLuaDraw")
        gadgetHandler.RemoveSyncAction("unsetUnitNeonLuaDraw")
    end
end
