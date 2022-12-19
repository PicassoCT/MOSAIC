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
        varying vec3 vNormal;
		varying vec3 vPosition;
		varying vec4 vColor;
		attribute vec3 normal;
        uniform mat3 normalMatrix;

        void main() {
            gl_Position = gl_Vertex;
			vPosition´= gl_Position;
            //fNormal = normalize(normalMatrix * normal);
        }
    ]]
	
--[[//---------------------------------------------------------------------------
#version 420 core
// fragment shader
//https://stackoverflow.com/questions/64837705/opengl-blurring
//"in" attributes from our vertex shader
varying vec4 vColor;
varying vec2 vTexCoord;
varying vec3 vPosition;

//declare uniforms
uniform sampler2D u_texture;
uniform float resolution;
uniform float radius;
uniform vec2 dir;

void main() {
    //this will be our RGBA sum
    vec4 sum = vec4(0.0);
    
    //our original texcoord for this fragment
    vec2 tc = vTexCoord;
    
    //the amount to blur, i.e. how far off center to sample from 
    //1.0 -> blur by one pixel
    //2.0 -> blur by two pixels, etc.
    float blur = radius/resolution; 
    
    //the direction of our blur
    //(1.0, 0.0) -> x-axis blur
    //(0.0, 1.0) -> y-axis blur
    float hstep = dir.x;
    float vstep = dir.y;
    
    //apply blurring, using a 9-tap filter with predefined gaussian weights
    
    sum += texture2D(u_texture, vec2(tc.x - 4.0*blur*hstep, tc.y - 4.0*blur*vstep)) * 0.0162162162;
    sum += texture2D(u_texture, vec2(tc.x - 3.0*blur*hstep, tc.y - 3.0*blur*vstep)) * 0.0540540541;
    sum += texture2D(u_texture, vec2(tc.x - 2.0*blur*hstep, tc.y - 2.0*blur*vstep)) * 0.1216216216;
    sum += texture2D(u_texture, vec2(tc.x - 1.0*blur*hstep, tc.y - 1.0*blur*vstep)) * 0.1945945946;
    
    sum += texture2D(u_texture, vec2(tc.x, tc.y)) * 0.2270270270;
    
    sum += texture2D(u_texture, vec2(tc.x + 1.0*blur*hstep, tc.y + 1.0*blur*vstep)) * 0.1945945946;
    sum += texture2D(u_texture, vec2(tc.x + 2.0*blur*hstep, tc.y + 2.0*blur*vstep)) * 0.1216216216;
    sum += texture2D(u_texture, vec2(tc.x + 3.0*blur*hstep, tc.y + 3.0*blur*vstep)) * 0.0540540541;
    sum += texture2D(u_texture, vec2(tc.x + 4.0*blur*hstep, tc.y + 4.0*blur*vstep)) * 0.0162162162;

    gl_FragColor = vColor * sum;
	//Transparency 
	 float hologramTransparency = 0.5 - sin(time + vPosition.z) * 0.25 - sin(2*time)*0.1;
	 vec4((gl_FragColor * (1.0-averageShadow)).xyz, gl_FragColor.z * hologramTransparency);
	 
}
//---------------------------------------------------------------------------]]


    fragmentshader = [[
	uniform sampler2D screencopy;
    uniform float resx;
    uniform float resy;
    varying vec3 fNormal;

    void main() {
		//vec2 texCoord = vec2(pixelx * int(gl_TexCoord[0].x / pixelx), pixely * int(gl_TexCoord[0].y / pixely));
		//vec4 origColor = texture2D(screencopy, texCoord);
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
	
	local resxLocation = nil
	local resyLocation = nil
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
