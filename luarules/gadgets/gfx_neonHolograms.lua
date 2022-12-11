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
    VFS.Include("scripts/lib_mosaic.lua")
    local neonTypeTable = getIconTypes(UnitDefs)

    function gadget:UnitCreated(unitID, unitDefID)
        if neonTypeTable[unitDefID] then
            --Spring.Echo("Icon Type " .. UnitDefs[unitDefID].namge .. " created")
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
        #version 150 compatibility
        varying vec3 fNormal;
        attribute vec3 normal;
        uniform mat3 normalMatrix;

        void main() {
            gl_Position = gl_Vertex;
            //fNormal = normalize(normalMatrix * normal);
        }
    ]]

    fragmentshader = [[
    uniform float resx;
    uniform float resy;
    varying vec3 fNormal;

    void main() {
      //float averageShadow = (fNormal.x*fNormal.x+fNormal.y*fNormal.y+fNormal.z+fNormal.z)/3.25;
      //gl_FragColor = vec4(gl_FragColor * (1.0-averageShadow));
      gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
    ]]

    local uniformInt = {
          resx = vsx,
          resy = vsy
        }


    local shaderTable = {
        --vertex = vertexShader,
      fragment = fragmentshader,
      uniformInt = uniformInt,
      uniformFloat = {resx,resy}
    }

    

    local function setUnitNeonLuaDraw(callname, unitID, typeDefID)
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
            Spring.Echo("<Neon Shader>: GLSL not supported.")
        end

        if gl and gl.GetShaderLog then
            Spring.Log(gadget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
        end
      
        if not shaderProgram and gl and gl.GetShaderLog then
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
        if drawMode == 1 and neonUnitTables[unitID] then --normalDraw
            glUseShader(shaderProgram)
            glBlending(GL_SRC_ALPHA, GL_ONE)
            glUnitRaw(unitID, true)
            glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
            glUseShader(0)
            return true
        end       
    end

    function gadget:Shutdown()
        if shaderProgram then
            gl.DeleteShader(shaderProgram)
        end
    end
end
