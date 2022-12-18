function gadget:GetInfo()
    return {
        name = "Neon Hologram Rendering ",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 1,
        version = 1,
        enabled = true
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_mosaic.lua")
    local neonTypeTable = getNeonTypes(UnitDefs)

    function gadget:UnitCreated(unitID, unitDefID)
        --Spring.Echo("UNit Type " .. UnitDefs[unitDefID].name .. " created")
        if neonTypeTable[unitDefID] then
            Spring.Echo("Neon Type " .. UnitDefs[unitDefID].name .. " created")
            SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

else -- unsynced
    local neonUnitTables = {}
    local glUseShader = gl.UseShader
    local glUniform = gl.Uniform
    local startTimer = Spring.GetTimer()
    local shaderProgram = {}
    local glGetUniformLocation = gl.GetUniformLocation
    local diffTime = 0

    local vertexShader = 
    [[
        varying vec3 fNormal;
        //uniform mat3 normalMatrix;

        void main() {
            vNormal = vec3((gl_NormalMatrix * gl_Normal).xyz); 
            gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vec4( position, 1.0 );
                 
        }
    ]]

    fragmentshader = [[
    //uniform float resx;
    //uniform float resy;
    varying vec3 vNormal;

    void main() {
      float averageShadow = (vNormal.x * vNormal.x + vNormal.y * vNormal.y + vNormal.z + vNormal.z)/3.25;
      gl_FragColor = vec4(gl_FragColor * (1.0-averageShadow));
      --gl_FragColor = vec4(1.0, 0.0, 0.0, 1.00);
    }
    ]]

    local uniformInt = {         
        }
    local uniformFloat = {         
        }



    local shaderTable = {
      vertex = vertexShader,
      fragment = fragmentshader,
      uniformInt = uniformInt,
      uniformFloat = uniformFloat
    }

    
    local boolShaderActive = true
    local function setUnitNeonLuaDraw(callname, unitID, typeDefID)
        Spring.Echo("NeonUnit registered")
        neonUnitTables[unitID] = typeDefID
        Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
    end

    function gadget:Initialize()        
        gadgetHandler:AddSyncAction("setUnitNeonLuaDraw", setUnitNeonLuaDraw)

        if not gl.CreateShader then Spring.Echo("No gl.CreateShader existing") end
        
        if gl.CreateShader then     
            shaderProgram = gl.CreateShader(shaderTable)
            if shaderProgram then
                resxLocation = glGetUniformLocation(shaderProgram, "resx")
                resyLocation = glGetUniformLocation(shaderProgram, "resy")
            end
        else
            boolShaderActive = false
            Spring.Echo("<Neon Shader>: GLSL not supported.")
        end

        if gl and gl.GetShaderLog then
            Spring.Log(gadget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
        end
      
        if not shaderProgram and gl and gl.GetShaderLog then
            boolShaderActive = false
            Spring.Log(gadget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
        end
    end

    local glUnitRaw = gl.UnitRaw
    local glBlending = gl.Blending
    local glScale = gl.Scale
    local glUseShader = gl.UseShader
    local GL_SRC_ALPHA           = GL.SRC_ALPHA
    local GL_ONE                 = GL.ONE
    local GL_ZERO                = GL.ZERO
    local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA

    function gadget:DrawUnit(unitID, drawMode)
        if boolShaderActive and neonUnitTables[unitID] then -- drawMode == 1 and 
            glUseShader(shaderProgram)
            --glBlending(GL_SRC_ALPHA, GL_ONE)
            glUnitRaw(unitID, true)
            --glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
            glUseShader(0)
        end       
    end

    function gadget:Shutdown()
        if shaderProgram then
            gl.DeleteShader(shaderProgram)
        end
    end
end
