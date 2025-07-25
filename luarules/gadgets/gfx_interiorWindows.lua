function gadget:GetInfo()
    return {
        name = "Building Windows Rendering ",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = -13,
        version = 1,
        enabled = false,
        hidden = true,
    }
end


if (gadgetHandler:IsSyncedCode()) then
    
    VFS.Include("scripts/lib_mosaic.lua")    
    VFS.Include("scripts/lib_UnitScript.lua")    
    GG.ManualRenderedBuildingWithWindowsVisiblePieces = {}
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
        return "Building Windows Rendering: "
    end


    local interiorWindowTypeTable = getWindowBuildingTypes(UnitDefs)
    local engineVersion = getEngineVersion()

    -- set minimun engine version
    local unsupportedEngine = true
    local enabled = false
    local minEngineVersionTitle = '104.0.1-1455'
    if ( 104.0 < engineVersion  and engineVersion >= 105)  then
        unsupportedEngine = false
        enabled = true
    end

    function gadget:Initialize()
        myAllyTeamID = 0--Spring.GetMyAllyTeamID()
        if Spring.GetMyTeamID then
            myTeam = Spring.GetMyTeamID () 
        end
        allUnits = Spring.GetAllUnits()
        for _,id in pairs(allUnits) do
            unitDefID = Spring.GetUnitDefID(id) 
            if interiorWindowTypeTable[unitDefID] then
                registerUnitIfWindowed(id, unitDefID)
            end
        end
    end


    local allWindowUnits= {}
    local WindowUnitDataTransfer = {}
    function registerUnitIfWindowed(unitID, unitDefID)
         if interiorWindowTypeTable[unitDefID] then
            Spring.SetUnitNoDraw(unitID, true)
            if engineVersion >= 105.0 and  Spring.SetUnitEngineDrawMask then
               -- local drawMask = SO_OPAQUE_FLAG + SO_ALPHAF_FLAG + SO_REFLEC_FLAG  + SO_REFRAC_FLAG + SO_DRICON_FLAG 
               -- Spring.SetUnitEngineDrawMask(unitID, drawMask)
            end
            local emptyTable = {}
            local stringToSend = ""

   
            allWindowUnits[#allWindowUnits + 1]= unitID
           -- SendToUnsynced("setUnitWindowLuaDraw", unitID, unitDefID)
        end
    end

    local cachedUnitPieces = {}
    function gadget:GameFrame(frame)
		if frame > frameGameStart then           
            if count(WindowUnitDataTransfer) > 0 then
                local VisibleUnitPieces = GG.ManualRenderedBuildingWithWindowsVisiblePieces   
                if VisibleUnitPieces then
        			for id, value in pairs(WindowUnitDataTransfer) do
        				if id and value and VisibleUnitPieces[id] and VisibleUnitPieces[id] ~= cachedUnitPieces[id] then
                            cachedUnitPieces[id] = VisibleUnitPieces[value]
        					SendToUnsynced("setUnitWindowLuaDraw", id, spGetUnitDefID(id), unpack(VisibleUnitPieces[id]))              
        				end
        			end 
                end      
            end
		end
    end

    function gadget:UnitCreated(unitID, unitDefID)        
       registerUnitIfWindowed(unitID, unitDefID)
    end

   function gadget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    assert(unitDefID)
    assert(UnitDefs[unitDefID])
        if interiorWindowTypeTable[unitDefID] then
           -- if boolOverride or  myTeam and CallAsTeam(myTeam, Spring.IsUnitVisible, unitID, nil, false) then
                WindowUnitDataTransfer[unitID] = unitID
           -- end
        end
    end

    function gadget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
        if interiorWindowTypeTable[unitDefID] then
            --if  boolOverride or  (myTeam and not CallAsTeam(myTeam, Spring.IsUnitVisible, unitID, nil, false)) then
                    WindowUnitDataTransfer[unitID] = nil
           -- end
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if interiorWindowTypeTable[unitDefID] then
            for i=#allWindowUnits, 1, -1 do
                if allWindowUnits[i] == unitID then
                    table.remove(allWindowUnits, i)
                end
            end
        end
    end

else -- unsynced
    local DAYLENGTH                 = 28800
    local LuaShader                 = VFS.Include("luarules/gadgets/include/LuaShader.lua")
    local neoVertexShaderFirstPass  = VFS.LoadFile ("luarules/gadgets/shaders/InteriorWindowShader.vert")
    local neoFragmentShaderFirstPass = VFS.LoadFile("luarules/gadgets/shaders/InteriorWindowShader.frag")

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

    local timePercentLoc
    local rainPercentLoc
    local rainPercent = 0.0
    local timePercent = 0
    local hours = 12
    local minutes = 0
    local seconds = 0

    local sunCol = {0,0,0}
    local skyCol = {0,0,0}
    local sunPos = {0.0,0.0, 1.0}

    local uniformSunColor
    local uniformSkyColor
    local uniformSunPos
    local uniformEyePos
    local uniformEyeDir
    local uniformProjection
    local uniformTime
    local uniformViewPortSize
    local uniformViewPrjInv
    local uniformViewInv
    local uniformViewProjection
    
    local unitTex1Index             =  0
    local startIndex = unitTex1Index
    local unitTex2Index             =  1
    local modelDepthTexIndex        =  2
    local mapDepthTexIndex          =  3
    local normaltexIndex            =  4
    local normalunittexIndex        =  5
    local noisetexIndex             =  6
    local dephtCopyTexIndex         =  7
    local emitmaptexIndex           =  8
    local emitunittexIndex          =  9
    local endIndex = emitunittexIndex
    
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
    local WindowUnitTables            = {}
    local UnitDefIDMap            = {}
    local glUnitShapeTextures       = gl.UnitShapeTextures
    local glGetUniformLocation      = gl.GetUniformLocation
    local glUnit                    = gl.Unit
-------Shader--FirstPass -----------------------------------------------------------

    local WindowShader
    local glowReflectShader
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
    function gadget:ViewResize() --TODO test/assert
    	vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

        screentex= glCreateTexture(vsx,vsy, {
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
            })
    end

    local counterWindowUnits = 0
    local WindowHoloParts= {}

    local function splitToNumberedArray(msg)
        local message = msg..'|'
        local t = {}
        for e in string.gmatch(message,'([^%|]+)%|') do
            local pieceID =  tonumber(e)
            table.insert(t, pieceID )            
        end
        return t
    end

    local function setUnitWindowLuaDraw(callname, unitID, typeDefId, listOfVisibleUnitPiecesString)

        Spring.UnitRendering.SetUnitLuaDraw(unitID, false)

        local piecesTable = splitToNumberedArray(listOfVisibleUnitPiecesString)
        WindowUnitTables[unitID] =  piecesTable
        UnitDefIDMap[unitID]= typeDefId
        counterWindowUnits= counterWindowUnits + 1
    end	

    local function unsetUnitWindowLuaDraw(callname, unitID)
        WindowUnitTables[unitID] = nil
          UnitDefIDMap[unitID]= nil
        counterWindowUnits= counterWindowUnits - 1
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


    local boolActivated = false
    function gadget:Initialize() 
		InitializeTextures()
		gadget:ViewResize(vsx, vsy)
        gadgetHandler:AddSyncAction("setUnitWindowLuaDraw", setUnitWindowLuaDraw)
        gadgetHandler:AddSyncAction("unsetUnitWindowLuaDraw", resetUnitWindowLuaDraw)
		frameGameStart = Spring.GetGameFrame()+1

        WindowShader = LuaShader({
            vertex =   neoVertexShaderFirstPass, --defaultVertexShader
            fragment = neoFragmentShaderFirstPass,--defaultFragmentShader
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
                tex1 = unitTex1Index,
                tex2 = unitTex2Index,      
                modelDepthTex = modelDepthTexIndex,
                mapDepthTex = mapDepthTexIndex,
                normaltex = normaltexIndex,
                normalunittex= normalunittexIndex,      
                noisetex = noisetexIndex,
                unitID = 0,
                typeDefID = 0
            },
            uniformFloat = {
              viewPortSize = {vsx, vsy},                 
              unitCenterPosition = {0,0,0},
              --vCamPositionWorld = {0,0,0}
            },
        }, "Window  Shader")

        boolActivated = WindowShader:Initialize()
        if not boolActivated then 
                Spring.Echo("WindowShader:: did not compile")
                gadgetHandler:RemoveGadget(self)
                return 
        end

       Spring.Echo("WindowShader:: did compile")

        timePercentLoc                  = glGetUniformLocation(WindowShader, "timePercent")
        rainPercentLoc                  = glGetUniformLocation(WindowShader, "rainPercent")
        uniformViewPortSize             = glGetUniformLocation(WindowShader, "viewPortSize")
        cityCenterLoc                   = glGetUniformLocation(WindowShader, "cityCenter")
        uniformTime                     = glGetUniformLocation(WindowShader, "time")
        uniformEyePos                   = glGetUniformLocation(WindowShader, "eyePos")
        uniformEyeDir                    = glGetUniformLocation(WindowShader, "eyeDir")

        uniformViewPrjInv               = glGetUniformLocation(WindowShader, 'viewProjectionInv')
        uniformViewInv                  = glGetUniformLocation(WindowShader, 'viewInv')
        uniformViewMatrix               = glGetUniformLocation(WindowShader, 'viewMatrix')
        uniformViewProjection           = glGetUniformLocation(WindowShader, 'viewProjection')
        uniformProjection               = glGetUniformLocation(WindowShader, 'projection')
        uniformSunColor                 = glGetUniformLocation(WindowShader, 'sunCol')
        uniformSkyColor                 = glGetUniformLocation(WindowShader, 'skyCol')
        uniformSunPos                   = glGetUniformLocation(WindowShader, 'sunPos')
    end

    local windowDefIDTypeIDMap = {}
    windowNameTypeIDMap = {
        ["house_asian0"]   =   0,
        ["house_western0"]   =   1,
        ["house_arab0"]  =   2, 
    }

    local windowDefID = nil
    for i=1,#UnitDefs do
        if windowNameTypeIDMap[UnitDefs[i].name] ~= nil then
            windowDefIDTypeIDMap[UnitDefs[i].id] = windowNameTypeIDMap[UnitDefs[i].name] 
            Spring.Echo("gfx_Windows.lua: Defined  types for "..UnitDefs[i].name.." as ".. windowNameTypeIDMap[UnitDefs[i].name] )
        end
    end       

    local function RenderAllWindowUnits()
        if counterWindowUnits == 0 or not boolActivated then
            return
        end 

        glDepthTest(true)
        glDepthMask(false)
        glCulling(GL_BACK)

        WindowShader:ActivateWith(
            function()  
                local _,_,_, timepercent = getDayTime()
                if timepercent > 0.25 and timepercent < 0.75 then return end
                glTexture(2, "$normal") 
                glTexture(3, "$reflection") 
                glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy) -- the depth texture

               -- WindowShader:SetUniformMatrix("viewInvMat", "viewinverse")
               --WindowShader:SetUniformFloatArray("vCamPositionWorld", {cx,cy,cz} )
                WindowShader:SetUniformFloatArray("viewPortSize", {vsx, vsy} )

                local cx,cy,cz  = Spring.GetCameraPosition()
                local timeSeconds = Spring.GetGameSeconds()
     

                glBlending(GL_SRC_ALPHA, GL_ONE)
                --variables

                for unitID, WindowwindowParts in pairs(WindowUnitTables) do
                    
                    local typeDefID = spGetUnitDefID(unitID)
                    glTexture(unitTex1Index, string.format("%%%d:0", unitDefID))
                    glTexture(unitTex2Index, string.format("%%%d:1", unitDefID))
                    WindowShader:SetUniformInt("unitID",  unitID)
                    WindowShader:SetUniformInt("typeDefID",   UnitDefIDMap[unitID] )
                    local x,y,z = spGetUnitPosition(unitID)
                    WindowShader:SetUniformFloatArray("unitCenterPosition", {x, y, z})
                     local timePercentOffset = (timepercent + (unitID/DAYLENGTH))%1.0
                    WindowShader:SetUniformFloat("timepercent",  timePercentOffset)
                    WindowShader:SetUniformFloat("time", timeSeconds + unitID)

                    glCulling(GL_FRONT)
                    for  _, pieceID in ipairs(WindowHoloParts)do

                      glPushPopMatrix( function()
                            glUnitMultMatrix(unitID)
                            glUnitPieceMultMatrix(unitID, pieceID)
                            glUnitPiece(unitID, pieceID)
                        end)
                    end
            
                end  

                --Cleanup
                for i= startIndex, endIndex do
                    glTexture(i, false)
                end
                
                        
                        
                glDepthTest(false)
            end         
        )
    end

    local function prepareTextures()
        glTexture(modelDepthTexIndex,"$model_gbuffer_zvaltex")
        glTexture(mapDepthTexIndex,"$map_gbuffer_zvaltex")
        glTexture(normaltexIndex,"$map_gbuffer_normtex")
        glTexture(normalunittexIndex,"$model_gbuffer_normtex")
        glTexture(noisetexIndex, noisetextureFilePath);
    end

    local function updateUniforms()
        diffTime = Spring.DiffTimers(lastFrametime, startTimer) 
        diffTime = diffTime - pausedTime
        --Spring.Echo("Time passed:"..diffTime)
        glUniform(rainPercentLoc, rainPercent)
        glUniform(timePercentLoc, timePercent)
        glUniform(uniformViewPortSize, vsx, vsy )
        glUniform(uniformTime, diffTime )
        local eyePos = {spGetCameraPosition()}
        glUniform(uniformEyePos,eyePos[1],eyePos[2], eyePos[3] )
        local eyeDir = {spGetCameraDirection()}
        glUniform(uniformEyeDir,eyeDir[1], eyeDir[2], eyeDir[3] )


        glUniform(uniformSunColor, sunCol[1], sunCol[2], sunCol[3]);
        glUniform(uniformSkyColor, skyCol[1], skyCol[2], skyCol[3]);
        glUniform(uniformSunPos, sunPos[1], sunPos[2], sunPos[3]);

        glUniformMatrix(uniformViewPrjInv     , "viewprojectioninverse")
        glUniformMatrix(uniformViewInv        , "viewinverse")
        glUniformMatrix(uniformViewProjection , "viewprojection")
        glUniformMatrix(uniformViewMatrix     , "view")
        glUniformMatrix(uniformProjection     , "projection")
    end

    --TODO: Draw Texture Rectangle for glowy shine around the drawn pieces + afterglowbuffertex
    --Shader does not apply to it


    --function gadget:DrawWorld(deferredPass, drawReflection, drawRefraction)
    function gadget:DrawWorld()
        updateUniforms()
        RenderAllWindowUnits()
    end

    function gadget:Shutdown()
        Spring.Echo("WindowShader:: shutting down gadget")
        WindowShader:Finalize()
        gadgetHandler.RemoveSyncAction("setUnitWindowLuaDraw")
        gadgetHandler.RemoveSyncAction("unsetUnitWindowLuaDraw")
    end
end
