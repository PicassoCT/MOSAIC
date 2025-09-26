function gadget:GetInfo()
    return {
        name = "Neon Hologram Rendering ",
        desc = "Renders transparent holograms ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = -12,
        version = 2,
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
    local boolDebugActive = false

    -- TODO: Add bloomstage - write to low level aphabitmask
    -- Texture back to resolution
    -- read back and add_alpha to texture

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
    local neonHologramTypeNames = getHologramTypeNames(UnitDefs)
    local engineVersion = getEngineVersion()

    -- set minimun engine version
    local unsupportedEngine = true
    local enabled = false
    local minEngineVersionTitle = '104.0.1-1455'
    if ( 104.0 < engineVersion  and engineVersion >= 105)  then
        unsupportedEngine = false
        enabled = true
    end

    function reRegisterAllAlreadyExistingUnits()
        local allUnits = Spring.GetAllUnits()
        for _,id in pairs(allUnits) do
            unitDefID = Spring.GetUnitDefID(id) 
            if neonHologramTypeTable[unitDefID] then
                registerUnitIfHolo(id, unitDefID)
            end
        end
    end

    function gadget:Initialize()
        if not GG.VisibleUnitPieces then GG.VisibleUnitPieces = {} end
        if not GG.VisibleUnitPieceUpateStates then GG.VisibleUnitPieceUpateStates = {} end

        if Spring.GetMyTeamID then
            myTeam = Spring.GetMyTeamID () 
        end
       reRegisterAllAlreadyExistingUnits()
    end

    local allNeonUnits= {}
    local neonUnitDataTransfer = {}
    function registerUnitIfHolo(unitID, unitDefID)
         if neonHologramTypeTable[unitDefID] then
            Spring.SetUnitNoDraw(unitID, true)     

            allNeonUnits[#allNeonUnits + 1]= unitID
            neonUnitDataTransfer[unitID] = unitDefID
            --conditionalEcho(boolDebugActive, "Registering neon unit "..unitID.. " of type "..neonHologramTypeNames[unitDefID])
           SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

    local function printUnitPiecesVisible(id, piecesTable)
        local stringResult = "Debug: gfx_neonHologram: Unit:"..id
        local pieceNameMap = Spring.GetUnitPieceList(id)
        for i=1, #piecesTable do
            stringResult = stringResult .. "|" .. pieceNameMap[piecesTable[i]]
        end
        conditionalEcho(boolDebugActive, stringResult)
    end

    local function sparse_len(t)
        local max = 0
        for k, _ in pairs(t) do
            if type(k) == "number" and k > max then
                max = k
            end
        end
        return max
    end

    local spCallAsUnit = Spring.UnitScript.CallAsUnit
    function callEnvironmentForUpdate(id)
        local env = Spring.UnitScript.GetScriptEnv(id)
        if env and env.updateCheckCache then
          spCallAsUnit(id, env.updateCheckCache)
        end
    end

    function updateDataFromEnvironments()
        local visibleUnitNeedingUpdates =  GG.VisibleUnitPieceUpateStates
        for unitID, request in pairs(visibleUnitNeedingUpdates) do
            if request then
                callEnvironmentForUpdate(unitID)
                visibleUnitNeedingUpdates[unitID] = false --Request consumed
            end
        end
        GG.VisibleUnitPieceUpateStates = visibleUnitNeedingUpdates
    end

    local cachedUnitPieces = {}

    function gadget:GameFrame(frame)
		if frame > frameGameStart then  
            updateDataFromEnvironments()         
            if count(neonUnitDataTransfer) > 0 then
                --echo("gadget:GameFrame:gfx_neonHolograms.lua "..frame)
                local VisibleUnitPieces = GG.VisibleUnitPieces   
                if VisibleUnitPieces then
        			for id, defID in pairs(neonUnitDataTransfer) do     
                        local thisVisibleUnitPieces = VisibleUnitPieces[id]

        				if id and defID and thisVisibleUnitPieces and thisVisibleUnitPieces ~= cachedUnitPieces[id] then
                            cachedUnitPieces[id] = thisVisibleUnitPieces
                            --conditionalEcho(boolDebugActive, HEAD().." Start:Sending Neon Hologram unit "..neonHologramTypeNames[defID].." data:"..toString(thisVisibleUnitPieces).. " - ")
        					SendToUnsynced("updateUnitNeonLuaDraw", id, unpack(thisVisibleUnitPieces))                                 
        				end
        			end 
                end   
            end
		end
    end

    function gadget:UnitCreated(unitID, unitDefID)        
       registerUnitIfHolo(unitID, unitDefID)
    end

   function gadget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
        if neonHologramTypeTable[unitDefID] then

            neonUnitDataTransfer[unitID] = unitDefID
        end
    end

    function gadget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            neonUnitDataTransfer[unitID] = nil
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            neonUnitDataTransfer[unitID] = nil
            for i=#allNeonUnits, 1, -1 do
                if allNeonUnits[i] == unitID then
                    table.remove(allNeonUnits, i)
                end
            end
        end
    end

else -- unsynced
    local DAYLENGTH                 = 28800
    local LuaShader                 = VFS.Include("luarules/gadgets/include/LuaShader.lua")
    local neoVertexShaderFirstPass  = VFS.LoadFile ("luarules/gadgets/shaders/neonHologramShader.vert")
    local neoFragmentShaderFirstPass = VFS.LoadFile("luarules/gadgets/shaders/neonHologramShader.frag")

    local spGetVisibleUnits         = Spring.GetVisibleUnits
    local spGetTeamColor            = Spring.GetTeamColor

    local glGetSun                  = gl.GetSun
    local glDepthTest               = gl.DepthTest
    local glDepthMask               = gl.DepthMask
    local glCulling                 = gl.Culling
    local glBlending                = gl.Blending
    local blurtex1
    local screencopy
    local blurtex2
    
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
    local canRTT    = (gl.RenderToTexture ~= nil)
    local canCTT    = (gl.CopyToTexture ~= nil)
    local canShader = (gl.CreateShader ~= nil)
    local canFBO    = (gl.DeleteTextureFBO ~= nil)
    local NON_POWER_OF_TWO = gl.HasExtension("GL_ARB_texture_non_power_of_two")
    local quality = 1.0


-------Shader--FirstPass -----------------------------------------------------------

    local neonHologramShader
    local blurShader
    local blurFsShader
    local vsx, vsy,vpx,vpy
    local sunChanged = false
    local spGetUnitDefID = Spring.GetUnitDefID
    local spGetUnitPosition = Spring.GetUnitPosition
    local spIsUnitInView = Spring.IsUnitInView
    local screentex = nil
    local afterglowbuffertex = nil
    local UnitUnitDefIDMap = {}
    local rainPercent = 0.0
    local boolRainyArea = false
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

local function getDetermenisticHash()
  local accumulated = 0
  local mapName = Game.mapName
  local mapNameLength = string.len(mapName)

  for i=1, mapNameLength do
    accumulated = accumulated + string.byte(mapName,i)
  end

  accumulated = accumulated + Game.mapSizeX
  accumulated = accumulated + Game.mapSizeZ
  return accumulated
end

local function isRainyArea()
    return getDetermenisticHash() % 2 == 0 or boolIsMapNameOverride 
end

local function getDayTime()
    local morningOffset = (DAYLENGTH / 2)
    local Frame = (Spring.GetGameFrame() + morningOffset) % DAYLENGTH
    local percent = Frame / DAYLENGTH
    local hours = math.floor((Frame / DAYLENGTH) * 24)
    local minutes = math.ceil((((Frame / DAYLENGTH) * 24) - hours) * 60)
    local seconds = 60 - ((24 * 60 * 60 - (hours * 60 * 60) - (minutes * 60)) % 60)
    return hours, minutes, seconds, percent
end

local function isRaining()   

    if boolRainyArea == nil then
        boolRainyArea = isRainyArea()        
--        Spring.Echo("Is rainy area:"..tostring(boolRainyArea))
    end

    if boolRainyArea == false then
        return false
    end

    local gameFrames = Spring.GetGameFrame()
    local dayNr = gameFrames / DAYLENGTH

    return dayNr % 3 < 1.0 and (hours > 18 or hours < 7)
end

local function CanDoBloom()
  if (not canCTT) then
    Spring.Echo("blur api: your hardware is missing the necessary CopyToTexture feature")
    return false
  end

  if (not canRTT) then
    Spring.Echo("blur api: your hardware is missing the necessary RenderToTexture feature")
    return false
  end

  if (not canShader) then
    Spring.Echo("blur api: your hardware does not support shaders")
    return false
  end

  if (not canFBO) then
    Spring.Echo("blur api: your hardware does not fbo textures")
    return false
  end

  if (not NON_POWER_OF_TWO) then
    Spring.Echo("blur api: your hardware does not non-2^n-textures")
    return false
  end

  return true
end

-------Shader--2ndPass -----------------------------------------------------------
--Glow Reflection etc.
--Execution of the shader
    function gadget:ViewResize() --TODO test/assert
        Spring.Echo("View Resize event")
    	vsx, vsy, vpx, vpy = Spring.GetViewGeometry()
        if screentex ~= nil then 
            glDeleteTexture(screentex)
        end
        if afterglowbuffertex ~= nil then
            glDeleteTexture(afterglowbuffertex)
        end

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

    local counterNeonUnits = 0
    local neonHoloParts= {}

    local function setUnitNeonLuaDraw(callname, unitID, unitDefID)
        Spring.UnitRendering.SetUnitLuaDraw(unitID, false) 
        UnitUnitDefIDMap[unitID] = unitDefID
        counterNeonUnits = counterNeonUnits + 1     
        neonUnitTables[unitID] = {}
    end
    local function updateUnitNeonLuaDraw(callname, unitID, ...)
        local piecesTable = {...}
        --Spring.Echo("Drawing Unit with Lua Neonshader "..unitID.. " of type"..UnitDefs[unitDefID].name)
        neonUnitTables[unitID] =  piecesTable       
    end	

    local function unsetUnitNeonLuaDraw(callname, unitID)
        neonUnitTables[unitID] = nil
        UnitUnitDefIDMap[unitID] = nil
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

    local str_blurShader_part1 = 
    [[
       #version 150 compatibility      
    
        void main() {
          vec2 texCoord = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
        }
    ]]

    local blurShader = 
    [[
      uniform sampler2D tex0;
     
      void main(void)
      {

        vec2 texCoord = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);

        gl_FragColor = vec4(0.0,0.0,0.0,1.0);
        gl_FragColor.rgb += 1.0/16.0 * texture2D(tex0, texCoord + vec2(-0.0017, -0.0017)).rgb;
        gl_FragColor.rgb += 2.0/16.0 * texture2D(tex0, texCoord + vec2(-0.0017,  0.0)).rgb;
        gl_FragColor.rgb += 1.0/16.0 * texture2D(tex0, texCoord + vec2(-0.0017,  0.0017)).rgb;
        gl_FragColor.rgb += 2.0/16.0 * texture2D(tex0, texCoord + vec2( 0.0,    -0.0017)).rgb;
        gl_FragColor.rgb += 5.0/16.0 * texture2D(tex0, texCoord + vec2( 0.0,     0.0)).rgb;
        gl_FragColor.rgb += 2.0/16.0 * texture2D(tex0, texCoord + vec2( 0.0,     0.0017)).rgb;
        gl_FragColor.rgb += 1.0/16.0 * texture2D(tex0, texCoord + vec2( 0.0017, -0.0017)).rgb;
        gl_FragColor.rgb += 2.0/16.0 * texture2D(tex0, texCoord + vec2( 0.0017,  0.0)).rgb;
        gl_FragColor.rgb += 1.0/16.0 * texture2D(tex0, texCoord + vec2( 0.0017,  0.0017)).rgb;
      }
  ]]

    local function updateRainPercent()
        if isRaining() == true   then--isRaining() then
            rainPercent = math.min(1.0, rainPercent + 0.0002)
            --Spring.Echo("Rainvalue:".. rainPercent)
        else
            rainPercent = math.max(0.0, rainPercent - 0.0001)
            --Spring.Echo("Rainvalue:".. rainPercent)
        end
        rainPercent = 1.0

    end

    function gadget:GameFrame(frame)
        if Script.LuaUI('RecieveAllNeonUnitsPieces') then
            local message = Script.LuaUI.RecieveAllNeonUnitsPieces(neonUnitTables)
        end
        updateRainPercent()
    end
 
    local boolActivated = false
    function gadget:Initialize() 
		InitializeTextures()
		gadget:ViewResize(vsx, vsy)
        gadgetHandler:AddSyncAction("setUnitNeonLuaDraw", setUnitNeonLuaDraw)
        gadgetHandler:AddSyncAction("updateUnitNeonLuaDraw", updateUnitNeonLuaDraw)
        gadgetHandler:AddSyncAction("unsetUnitNeonLuaDraw", unsetUnitNeonLuaDraw) --TODO debug
		frameGameStart = Spring.GetGameFrame()+1

        if blurtex ~= nil then glDeleteTexture(blurtex) end
        if blurtex2 ~= nil then glDeleteTexture(blurtex2) end
        if screencopy ~= nil then glDeleteTexture(screencopy) end


        neonHologramShader = LuaShader({
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
                timepercent = 0.5,
                rainPercent= 0
            },     
            uniformInt = {
                tex1 = 0,
                tex2 = 1,
                normaltex = 2,
                reflecttex = 3,
                screentex = 4,
                typeDefID = 5
            },
            uniformFloat = {
              viewPortSize = {vsx, vsy},                 
              unitCenterPosition = {0,0,0},
              --vCamPositionWorld = {0,0,0}
            },
        }, "Neon Hologram Shader")

        boolActivated = neonHologramShader:Initialize()
        if not boolActivated then 
                Spring.Echo("NeonShader:: did not compile")
                gadgetHandler:RemoveGadget(self)
                return 
        end

        if not CanDoBloom() then
            gadgetHandler:RemoveGadget(self)
            return 
        end

       Spring.Echo("NeonShader:: did compile")
    end

    local holoDefIDTypeIDMap = {}
    holoNameTypeIDMap = {
        ["house_western_hologram_casino"]   =   1,
        ["house_western_hologram_brothel"]  =   2,
        ["house_western_hologram_buisness"] =   3,
        ["house_asian_hologram_buisness"] =     4,
        ["advertising_blimp_hologram"] =        3,

    }

    local holoDefID = nil
    for i=1,#UnitDefs do
        if holoNameTypeIDMap[UnitDefs[i].name] ~= nil then
            holoDefIDTypeIDMap[UnitDefs[i].id] = holoNameTypeIDMap[UnitDefs[i].name] 
            --Spring.Echo("gfx_neonHolograms.lua: Defined hologram types for "..UnitDefs[i].name.." as ".. holoNameTypeIDMap[UnitDefs[i].name] )
        end
    end       

    local function RenderAllNeonUnitsDrawWorld()

        if counterNeonUnits == 0 or not boolActivated then
            return
        end 

        glDepthTest(true)
        glDepthMask(false)
        glCulling(GL_BACK)

        neonHologramShader:ActivateWith(
            function()  
                glTexture(2, "$normal") 
                glTexture(3, "$reflection") 
                glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy) -- the depth texture

               -- neonHologramShader:SetUniformMatrix("viewInvMat", "viewinverse")
               --neonHologramShader:SetUniformFloatArray("vCamPositionWorld", {cx,cy,cz} )
                neonHologramShader:SetUniformFloat("viewPortSize", vsx, vsy )
                neonHologramShader:SetUniformFloat("rainPercent", rainPercent)
                local cx,cy,cz  = Spring.GetCameraPosition()
                local timeSeconds = Spring.GetGameSeconds()
                local _,_,_, timepercent = getDayTime()
 

                glBlending(GL_SRC_ALPHA, GL_ONE)
                --variables

                for unitID, neonHoloParts in pairs(neonUnitTables) do
                    if spIsUnitInView(unitID) then --draw only visible units
                        local x,y,z = spGetUnitPosition(unitID)
                        local unitDefID = UnitUnitDefIDMap[unitID]
                        local timePercentOffset = (timepercent + (unitID/DAYLENGTH))%1.0
                        --local distToCam = math.sqrt((cx-x)^2 * (cy -y)^2 + (cz-z)^2)
                        --if distToCam < 3000 then
                            glTexture(0, string.format("%%%d:0", unitDefID))
                            glTexture(1, string.format("%%%d:1", unitDefID))
                            neonHologramShader:SetUniformInt("typeDefID",  holoDefIDTypeIDMap[unitDefID])                        
                            neonHologramShader:SetUniformFloat("unitCenterPosition", x, y, z)                       
                            neonHologramShader:SetUniformFloat("timepercent",  timePercentOffset)
                            neonHologramShader:SetUniformFloat("time", timeSeconds + unitID)
                    
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
                        --[[else --do a traditional unshaded transparent draw for units in the distance
                            glDepthMask(false)
                                glBlending(GL_SRC_ALPHA, GL_ONE)
                                glUnitRaw(unitID, true)
                                glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
                           glDepthMask(true)
                        end]]
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

    --TODO: Draw Texture Rectangle for glowy shine around the drawn pieces + afterglowbuffertex
    --Shader does not apply to it


    local function RenderBlurApplyBlur()
        
        gl.CopyToTexture(screencopy, 0, 0, 0, 0, vsx, vsy)
        gl.Texture(screencopy)
        gl.RenderToTexture(blurtex, gl.TexRect, -1,1,1,-1)
        gl.UseShader(blurShader)

        gl.Texture(blurtex)
        gl.RenderToTexture(blurtex2, gl.TexRect, -1,1,1,-1)
        gl.Texture(blurtex2)
        gl.RenderToTexture(blurtex, gl.TexRect, -1,1,1,-1)

        gl.Texture(blurtex)
        gl.TexRect(0,vsy,vsx,0)

        gl.Texture(false)
        gl.UseShader(0)

    --apply alpha
    
    end

    --function gadget:DrawWorld(deferredPass, drawReflection, drawRefraction)
    function gadget:DrawWorld()
        RenderAllNeonUnitsDrawWorld()
        --RenderBlurApplyBlur()
    end

    function gadget:Shutdown()
        Spring.Echo("NeonShader:: shutting down gadget")
        neonHologramShader:Finalize()
        if (gl.DeleteTextureFBO) then
            gl.DeleteTextureFBO(blurtex)
            gl.DeleteTextureFBO(blurtex2)
        end
        gl.DeleteTexture(screencopy or 0)

        gadgetHandler.RemoveSyncAction("setUnitNeonLuaDraw")
        gadgetHandler.RemoveSyncAction("updateUnitNeonLuaDraw")
        gadgetHandler.RemoveSyncAction("unsetUnitNeonLuaDraw")
    end
end
