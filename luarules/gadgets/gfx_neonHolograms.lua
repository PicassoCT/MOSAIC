function gadget:GetInfo()
    return {
        name = "Neon Hologram Rendering ",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 0,
        version = 1,
        enabled = Spring.Utilities.IsCurrentVersionNewerThan(105, 500),
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
            echo(HEAD().."registering holo unit")
            local drawMask = SO_OPAQUE_FLAG + SO_ALPHAF_FLAG + SO_REFLEC_FLAG  + SO_REFRAC_FLAG + SO_DRICON_FLAG 
            if engineVersion > 105.0 and  Spring.SetUnitEngineDrawMask then
                Spring.SetUnitEngineDrawMask(unitID, drawMask)
            end
            local emptyTable = {}
            local stringToSend = ""
            SendToUnsynced("setUnitNeonLuaDraw", unitID, stringToSend)             
            allNeonUnits[#allNeonUnits + 1]= unitID
           -- Spring.Echo("Hologram Type " .. UnitDefs[unitDefID].name .. " created")
           -- SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

    function gadget:GameFrame(frame)
		if frame > frameGameStart then
            if count(neonUnitDataTransfer) > 0 then
                echo(HEAD().."Visible Units:"..toString(neonUnitDataTransfer))
                local VisibleUnitPieces = GG.VisibleUnitPieces
                SendToUnsynced("resetUnitNeonLuaDraw")       
    			for id, value in pairs(neonUnitDataTransfer) do
                    echo(HEAD().."Sending Neon Hologram unit data:"..toString(VisibleUnitPieces[id] ))
    				if id and value and VisibleUnitPieces[id] then
                        local serializedStringToSend = serializePiecesTableTostring(VisibleUnitPieces[value])
                        Spring.Echo("setUnitNeonLuaDraw:"..unitID..":"..serializedStringToSend)
    					SendToUnsynced("setUnitNeonLuaDraw", id, serializedStringToSend )                
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
                echo("Neon Hologram unit has entered LOS of myTeam")
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

-----------------------------------------------------------------------------------------------------------------------------------------------
else -- unsynced ------------------------------------------------------------------------------------------------------------------------------

    local LuaShader = VFS.Include("LuaRules/Gadgets/Include/LuaShader.lua")
    local spGetVisibleUnits = Spring.GetVisibleUnits
    local spGetTeamColor = Spring.GetTeamColor
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitPosition = Spring.GetUnitPosition

    local glGetSun = gl.GetSun
    local glDepthTest = gl.DepthTest
    local glCulling = gl.Culling
    local glBlending = gl.Blending

    local GL_SRC_ALPHA           = GL.SRC_ALPHA
    local GL_ONE                 = GL.ONE
    local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA     
    local GL_BACK  = GL.BACK
    local GL_FRONT = GL.FRONT

    local glPushPopMatrix = gl.PushPopMatrix
    local glPushMatrix = gl.PushMatrix
    local glPopMatrix = gl.PopMatrix
    local glUnitMultMatrix = gl.UnitMultMatrix
    local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix
    local glUnitPiece = gl.UnitPiece
    local glTexture = gl.Texture
    local glUnitShapeTextures = gl.UnitShapeTextures
    local glCopyToTexture = gl.CopyToTexture
    local glUnitShapeTextures = gl.UnitShapeTextures
-------Shader--FirstPass -----------------------------------------------------------
    local neoVertexShaderFirstPass  = VFS.LoadFile ("LuaRules/Gadgets/shaders/neonHologramShader.vert")
    local neoFragmenShaderFirstPass = VFS.LoadFile("LuaRules/Gadgets/shaders/neonHologramShader.frag")
    local neonHologramShader
    local screenTex 
    local vsx, vsy,vpx,vpy
    local sunChanged = false
    local neonUnitTables = {}
-------------------------------------------------------------------------------------

-------Shader--2ndPass -----------------------------------------------------------
--Glow Reflection etc.
--Execution of the shader
    function gadget:ViewResize(viewSizeX, viewSizeY) --TODO test/assert
    	vsx, vsy = viewSizeX, viewSizeY

        screenTex= gl.CreateTexture(vsx,vsy, {
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

        screenTex= gl.CreateTexture(vsx,vsy, {
            target = target,
            min_filter = GL.LINEAR,
            mag_filter = GL.LINEAR,
            wrap_s   = GL.CLAMP_TO_EDGE,
            wrap_t   = GL.CLAMP_TO_EDGE,
          })

    end

    local defaultVertexShader = 
    [[
       #version 430 compatibility
       #line 100249

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
        #version 430 compatibility
        #line 200265
        
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
            vertex = defaultVertexShader, --neoVertexShaderFirstPass,
            fragment =  defaultTestFragmentShader , --neoFragmenShaderFirstPass,
            textures = {
                    [0] = tex1,
                    [1] = tex2,
                    [2] = normalTex,
                    [3] = reflectTex,
                    [4] = screenTex
                },            
            uniformInt = {
                tex1 = 0,
                tex2 = 1,
                reflectTex = 2,
                screenTex= 3
            },
            uniformFloat = {
                --viewPosX = 0,
                --viewPosY = 0,
                --time = Spring.GetGameSeconds(),           
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
 
    local boolDoesCompile = false
    local function RenderNeonUnits()

        if counterNeonUnits ~= oldCounterNeonUnits  and counterNeonUnits then
            oldCounterNeonUnits= counterNeonUnits
            Spring.Echo("Rendering no Neon Units with n-units "..counterNeonUnits)
        end

        if counterNeonUnits == 0 or not boolActivated then
            return
        end   

        glTexture(0, "$tex1")
        glTexture(1, "$tex2")
        glTexture(2, "$reflection") 
        glDepthTest(true)  

        neonHologramShader:ActivateWith(
        function()   
                --neonHologramShader:SetUniformFloat("viewPosX", vsx)
                --neonHologramShader:SetUniformFloat("viewPosY", vsy)
                --neonHologramShader:SetUniformFloat("time", Spring.GetGameSeconds() )
                glBlending(GL_SRC_ALPHA, GL_ONE)
                --variables
                for i = 1, #neonUnitTables do
                    local unitID = neonUnitTables[i].id
                    local neonHoloDef = spGetUnitDefID(unitID)
                    local px,py,pz = spGetUnitPosition(unitID)
                    local unitCenterPosition = {px,py, pz}
                    --neonHologramShader:SetUniformFloatArray("unitCenterPosition", unitCenterPosition)
                   
                    --local neonHoloParts = neonUnitTables[i].pieces
                    local neonHoloParts = Spring.GetUnitPieceList(unitID)
                    glUnitShapeTextures(neonHoloDef, true)
                    --glTexture(2, normalMaps[unitDefID])
                  
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
            end

            glTexture(0, false)
            glTexture(1, false)
            glTexture(2, false)
            glTexture(3, false)
        )

        glDepthTest(false)
        glCulling(false)
    end

    function gadget:DrawWorld()
        RenderNeonUnits()
    end


    function gadget:Shutdown()
        Spring.Echo("NeonShader:: shutting down gadget")
        neonHologramShader:Finalize()
        gadgetHandler.RemoveSyncAction("setUnitNeonLuaDraw")
        gadgetHandler.RemoveSyncAction("resetUnitNeonLuaDraw")
    end
end
