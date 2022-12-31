function gadget:GetInfo()
    return {
        name = "Neon Hologram Rendering ",
        desc = " ",
        author = "Picasso",
        date = "3rd of May 2010",
        license = "GPL3",
        layer = 0,
        version = 1,
        enabled = false
    }
end

if (gadgetHandler:IsSyncedCode()) then
    VFS.Include("scripts/lib_mosaic.lua")
    local neonHologramTypeTable = getHologramTypes(UnitDefs)

    function gadget:UnitCreated(unitID, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            --Spring.Echo("Icon Type " .. UnitDefs[unitDefID].namge .. " created")
            SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            --Spring.Echo("Icon Type " .. UnitDefs[unitDefID].namge .. " created")
            SendToUnsynced("unsetUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

else -- unsynced
    local glUseShader = gl.UseShader
    local glUniform = gl.Uniform
    local glUniformArray = gl.UniformArray
    local glCopyToTexture = gl.CopyToTexture
    local glTexture = gl.Texture
    local glTexRect = gl.TexRect
    local glUseShader = gl.UseShader
    local glGetUniformLocation = gl.GetUniformLocation
    local GL_DEPTH_COMPONENT24 = 0x81A6
    local glUnitRaw = gl.UnitRaw
    local glBlending = gl.Blending
    local glScale = gl.Scale
    local startTimer = Spring.GetTimer()
    local shaderFirstPass = {}
    local shaderSecondPass = {}
    local vsx, vsy = 1600, 1200
    local screentex
    local depthtex
    local diffTime = 0

    local GL_SRC_ALPHA           = GL.SRC_ALPHA
    local GL_ONE                 = GL.ONE
    local GL_ZERO                = GL.ZERO
    local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
    local resxLocation = nil
    local resyLocation = nil
    local neonUnitTables = {}
    local vertexShaderFirstPass = 
    [[
        #version 150 compatibility
        varying vec3 vPositionWorld;
        varying vec3 vNormal;

		uniform sampler2D screentex;
     
        uniform vec2 dir;
        uniform float time;

        float scaleTimeFullHalf()
        {
            return (2.0 +sin(time))/2.0;
        }

        float shiver(float posy, float scalar, float size) 
        {
            if (sin(posy + time) < size)
            { return 1.0;};
            
            float renormalizedTime = sin(posy +time);
            
            return scalar*((renormalizedTime-(1.0 + (size/2.0)))/ (size/2.0));
        }

        void main() 
        {
            // To pass variables to the fragment shader, you assign them here in the
            // main function. Traditionally you name the varying with vAttributeName
            vNormal = normal;
            vUv = uv;
            vUv2 = uv2;
            vec4 pos =(  modelMatrix * vec4(position,0));
            vPositionWorld =  pos.xyz;
     
            vNormal = normalMatrix * normal;
            vec3 posCopy = position;
            posCopy.xz = posCopy.xz - 0.15 * (shiver(posCopy.y, 0.16, 0.95));
            gl_Position = projectionMatrix * modelViewMatrix * vec4(posCopy, 1.0);           
        }
    ]]
	
fragmentShaderFirstPass =[[
    //---------------------------------------------------------------------------
    #version 150 compatibility
    // fragment shader
    //https://stackoverflow.com/questions/64837705/opengl-blurring
    //"in" attributes from our vertex shader
    varying vec3 vPosition;
    varying vec3 vNormal;

    //declare uniforms
    uniform sampler2D screentex;
    uniform sampler2D depthtex;
    uniform vec2 dir;
    uniform float time;

    float getSineWave(float posOffset, float posOffsetScale, float time, float timeSpeedScale)
    {
        return sin((posOffset* posOffsetScale) +time * timeSpeedScale);
    }

    float getCosineWave(float posOffset, float posOffsetScale, float time, float timeSpeedScale)
    {
        return cos((posOffset* posOffsetScale) +time * timeSpeedScale);
    }

    void writeLightRaysToTexture(vec2 originPoint, vec4 color, float pixelDistance, float intensityFactor, vec2 maxResolution)
    {
        int indexX= int( originPoint.x - pixelDistance < 0.0 ?   0.0 : originPoint.x - pixelDistance);
        int endx= int(originPoint.x + pixelDistance > maxResolution.x ?   maxResolution.x : originPoint.x + pixelDistance);
        int indexZ= int(originPoint.y - pixelDistance < 0.0 ?   0.0 : originPoint.y - pixelDistance);
        int endz= int( originPoint.y + pixelDistance > maxResolution.y ?   maxResolution.y : originPoint.y + pixelDistance);

        for (int ix = -16; ix < 16; ix++) 
        {
             for (int iz = -16; iz < 16; iz++) 
             {
               vec2 point = vec2(indexX + ix, indexZ + iz);
               float distFactor = distance(originPoint, point )/pixelDistance;
               vec4 col =   texture2D(screentex, point);
               col += (color*distFactor* intensityFactor); 
            }
        }
    }

    vec4 getGlowColorBorderPixel(vec4 lightSourceColor, vec4 pixelColor, float dist, float maxRes){
        float factor = 1.0/(dist-(1.0/float(maxRes)));
        return mix(lightSourceColor, pixelColor, factor);
    }

    void writeLightRayToTexture(vec4 lightSourceColor){
        for (int x = -16; x < 16; x++)
        {
            for (int z = -16; z < 16; z++)
            {
                vec2 pixelCoord = vec2(gl_FragCoord) + vec2(x,z);
                float dist = length(vec2(x,z));
                //screentex[int(pixelCoord.x)][int(pixelCoord.z)] =
                getGlowColorBorderPixel(lightSourceColor, texture2D( screentex,  pixelCoord), dist, 16.0);
            }
        }
    }
        
    vec4 addBorderGlowToColor(vec4 color, float averageShadow){
        float rim = smoothstep(0.4, 1.0, 1.0 - averageShadow)*2.0;
        vec4 overlayAlpha = vec4( clamp(rim, 0.0, 1.0)  * vec3(1.0, 1.0, 1.0), 1.0 );
        color.xyz =  color.xyz + overlayAlpha.xyz;
        
        if (overlayAlpha.x > 0.5){
              color.a = mix(color.a, overlayAlpha.a, color.x );
        }

        return color;
    }    

    vec4 getBluredColor(vec4 sampleBlurColor)
    {
        sampleBlurColor += texture2D( screentex, ( vec2(gl_FragCoord)+vec2(1.3846153846, 0.0) )/256.0 ) * 0.3162162162;
        sampleBlurColor += texture2D( screentex, ( vec2(gl_FragCoord)-vec2(1.3846153846, 0.0) )/256.0 ) * 0.3162162162;
        sampleBlurColor += texture2D( screentex, ( vec2(gl_FragCoord)+vec2(3.230769230, 0.0) )/256.0 ) * 0.0702702703;
        sampleBLurColor += texture2D( screentex, ( vec2(gl_FragCoord)-vec2(3.230769230, 0.0) )/256.0 ) * 0.0702702703;
        return sampleBlurColor
    }

    void main() {      
            float averageShadow = (vNormal.x*vNormal.x+vNormal.y*vNormal.y+vNormal.z+vNormal.z)/4.0;   
             
            //Transparency 
            float hologramTransparency =   max(mod(sin(time), 0.75), //0.25
                                            0.5 
                                            + abs(0.3 * getSineWave(vPositionWorld.y, 0.10,  time*6.0,  0.10))
                                            - abs(getSineWave(vPositionWorld.y, 1.0,  time,  0.2))
                                            + 0.4 * abs(getSineWave(vPositionWorld.y, 0.5,  time,  0.3))
                                            - 0.15 *abs(getCosineWave(vPositionWorld.y, 0.75,  time,  0.5))
                                            + 0.15 * getCosineWave(vPositionWorld.y, 0.5,  time,  2.0)
                                            ); 

            gl_FragColor= vec4((color.xyz + color* (1.0-averageShadow)).xyz, max((1.0 - averageShadow) , color.z * hologramTransparency)) ;
            vec4 sampleBlurColor = getBluredColor(gl_FragColor);
            gl_FragColor = addBorderGlowToColor(sampleBlurColor* gl_FragColor, averageShadow);
            gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
             
    }
    //---------------------------------------------------------------------------
    ]]
    local uniformInt = {
          screentex = 0
        }
	local uniformFloat = {
         resx = vsx,
         resy = vsy
        }

          --TODO make z depth depending
	local uniformTable ={
		dir ={0, 0}--TODO
	}

    local shaderDataFirstPass = {
      vertex        = vertexShaderFirstPass,
      fragment      = fragmentShaderFirstPass,
      uniformInt    = uniformInt,
      uniformFloat  = uniformFloat,
	  uniforms      = uniformTable
    }   

    function gadget:ViewResize(viewSizeX, viewSizeY) --TODO test/assert
    	vsx, vsy = viewSizeX, viewSizeY

    depthtex = gl.CreateTexture(vsx,vsy, {
        border = false,
        format = GL_DEPTH_COMPONENT24,
        min_filter = GL.NEAREST,
        mag_filter = GL.NEAREST,
    })

    screentex = gl.CreateTexture(vsx, vsy, {
        border = false,
        min_filter = GL.NEAREST,
        mag_filter = GL.NEAREST,
    	})
    end
    local counterNeonUnits = 0
    local function unsetUnitNeonLuaDraw(callname, unitID, typeDefID)
        neonUnitTables[unitID] = nil
        counterNeonUnits= counterNeonUnits -1
    end


    local function setUnitNeonLuaDraw(callname, unitID, typeDefID)
        neonUnitTables[unitID] = typeDefID
        Spring.UnitRendering.SetUnitLuaDraw(unitID, true)
        counterNeonUnits= counterNeonUnits +1
    end	

    function gadget:Initialize() 
		vsx, vsy = gadgetHandler:GetViewSizes()
		gadget:ViewResize(vsx, vsy)

		screentex = gl.CreateTexture(vsx, vsy, {
			border = false,
			min_filter = GL.NEAREST,
			mag_filter = GL.NEAREST,
			})
        
        depthtex = gl.CreateTexture(vsx,vsy, {
            border = false,
            format = GL_DEPTH_COMPONENT24,
            min_filter = GL.NEAREST,
            mag_filter = GL.NEAREST,
        })
		
        gadgetHandler:AddSyncAction("setUnitNeonLuaDraw", setUnitNeonLuaDraw)
        gadgetHandler:AddSyncAction("unsetUnitNeonLuaDraw", unsetUnitNeonLuaDraw)

        if not gl.CreateShader then Spring.Echo("No gl.CreateShader existing") end
        
        if gl.CreateShader then     
            shaderFirstPass = gl.CreateShader(shaderDataFirstPass)
            if shaderFirstPass then
                resxLocation = glGetUniformLocation(shaderFirstPass, "resx")
                resyLocation = glGetUniformLocation(shaderFirstPass, "resy")
                resolution = glGetUniformLocation(shaderFirstPass, "resolution")
            end

            --shaderSecondPass = gl.CreateShader(shaderDataSecondPass)
            --if shaderSecondPass then
            --    resxLocation = glGetUniformLocation(shaderSecondPass, "resx")
            --    resyLocation = glGetUniformLocation(shaderSecondPass, "resy")
            --end
        else
            Spring.Echo("<Neon Shader>: GLSL not supported.")
        end
      
        if not shaderFirstPass and gl and gl.GetShaderLog then
            Spring.Log(gadget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
        end
    end

    local perFrameCounterCopy = 0
    function gadget:DrawScreenEffects()
        perFrameCounterCopy = counterNeonUnits
        glCopyToTexture(screentex, 0, 0, 0, 0, vsx, vsy)
        --glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy)
        glTexture(0, screentex)
        --glTexture(1, depthtex)

        resxLocation = glGetUniformLocation(shaderFirstPass, "resx")
        resyLocation = glGetUniformLocation(shaderFirstPass, "resy")

        radius = glGetUniformLocation(shaderFirstPass, "radius")       
    end

    function gadget:DrawUnit(unitID, drawMode)        
        if drawMode == 1 and neonUnitTables[unitID] then --normalDraw 
            perFrameCounterCopy = perFrameCounterCopy -1
            glUseShader(shaderFirstPass)
            glBlending(GL_SRC_ALPHA, GL_ONE)            
            glUnitRaw(unitID, true)
            glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
            glUseShader(0)     
            if perFrameCounterCopy == 0 then
                glUseShader(shaderSecondPass)
                --glTexRect(0,vsy,vsx,0)
                --glTexRect(1,vsy,vsx,0)
                --glTexture(0, false)
                --glTexture(1, false)
                glUseShader(0)
            end
        end       
    end

    function gadget:Shutdown()
        if shaderFirstPass then
            gl.DeleteShader(shaderFirstPass)
        end
    end
end
