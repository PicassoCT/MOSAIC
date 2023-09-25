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
    local engineVersion = 104 -- just filled this in here incorrectly but old engines arent used anyway
    if Engine and Engine.version then
        local function Split(s, separator)
            local results = {}
            for part in s:gmatch("[^" .. separator .. "]+") do
                results[#results + 1] = part
            end
            return results
        end
        engineVersion = Split(Engine.version, '-')
        if engineVersion[2] ~= nil and engineVersion[3] ~= nil then
            engineVersion = tonumber(string.gsub(engineVersion[1], '%.', '') ..
                                         engineVersion[2])
        else
            engineVersion = tonumber(Engine.version)
        end
    end

    -- set minimun engine version
    local unsupportedEngine = true
    local enabled = false
    local minEngineVersionTitle = '104.0.1-1455'
    if ( 104.0 < engineVersion  and engineVersion >= 105)  then
        unsupportedEngine = false
        enabled = true
        Spring.Echo("gadget Neon Hologram Rendering is enabled")
    end



    VFS.Include("scripts/lib_mosaic.lua")
    local neonHologramTypeTable = getHologramTypes(UnitDefs)

    function gadget:UnitCreated(unitID, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            Spring.Echo("Hologram Type " .. UnitDefs[unitDefID].namge .. " created")
            SendToUnsynced("setUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

    function gadget:UnitDestroyed(unitID, unitDefID)
        if neonHologramTypeTable[unitDefID] then
            Spring.Echo("Hologram Type " .. UnitDefs[unitDefID].namge .. " created")
            SendToUnsynced("unsetUnitNeonLuaDraw", unitID, unitDefID)
        end
    end

else -- unsynced

    local LuaShader = VFS.Include("LuaRules/Gadgets/Include/LuaShader.lua")
    local spGetVisibleUnits = Spring.GetVisibleUnits
    local spGetTeamColor = Spring.GetTeamColor

    local glGetSun = gl.GetSun

    local glDepthTest = gl.DepthTest
    local glCulling = gl.Culling
    local glBlending = gl.Blending

    local glPushPopMatrix = gl.PushPopMatrix
    local glPushMatrix = gl.PushMatrix
    local glPopMatrix = gl.PopMatrix
    local glUnitMultMatrix = gl.UnitMultMatrix
    local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix
    local glUnitPiece = gl.UnitPiece
    local glTexture = gl.Texture
    local glUnitShapeTextures = gl.UnitShapeTextures

    local GL_BACK  = GL.BACK
    local GL_FRONT = GL.FRONT
    local neonUnitTables = {}

-------Shader--FirstPass -----------------------------------------------------------
local neoFragmenShaderFirstPass= [[

mat4 screenView;
    mat4 screenProj;
    mat4 screenViewProj;

    mat4 cameraView;
    mat4 cameraProj;
    mat4 cameraViewProj;
    mat4 cameraBillboardView;

    mat4 cameraViewInv;
    mat4 cameraProjInv;
    mat4 cameraViewProjInv;

    mat4 shadowView;
    mat4 shadowProj;
    mat4 shadowViewProj;

    mat4 orthoProj01;

    // transforms for [0] := Draw, [1] := DrawInMiniMap, [2] := Lua DrawInMiniMap
    mat4 mmDrawView; //world to MM
    mat4 mmDrawProj; //world to MM
    mat4 mmDrawViewProj; //world to MM

    mat4 mmDrawIMMView; //heightmap to MM
    mat4 mmDrawIMMProj; //heightmap to MM
    mat4 mmDrawIMMViewProj; //heightmap to MM

    mat4 mmDrawDimView; //mm dims
    mat4 mmDrawDimProj; //mm dims
    mat4 mmDrawDimViewProj; //mm dims

#version 150 compatibility
// Set the precision for data types used in this shader
precision highp float;
precision highp int;


// Default THREE.js uniforms available to both fragment and vertex shader
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix = cameraView* modelMatrix;
uniform mat4 projectionMatrix = modelMatrix*cameraViewProj;
uniform mat3 normalMatrix = cameraView * transpose(inverse(modelMatrix));;

// Default uniforms provided by ShaderFrog.
uniform float time;
//declare uniforms
uniform sampler2D screencopy;
uniform float resolution;
uniform float radius;
uniform vec2 dir;


// A uniform unique to this shader. You can modify it to the using the form
// below the shader preview. Any uniform you add is automatically given a form
uniform vec3 color;
uniform vec3 lightPosition;

// Example varyings passed from the vertex shader
varying vec3 vPositionWorld;
varying vec3 vNormal;

varying vec2 vUv;
varying vec2 vUv2;
varying vec2 vTexCoord;

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
           vec4 col =   texture2D(screencopy, point);
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
            //screencopy[int(pixelCoord.x)][int(pixelCoord.z)] =
            getGlowColorBorderPixel(lightSourceColor, texture2D( screencopy,  pixelCoord), dist, 16.0);
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

void main() {
      
      //this will be our RGBA sumt
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
        
        sum += texture2D(screencopy, vec2(tc.x - 4.0*blur*hstep, tc.y - 4.0*blur*vstep)) * 0.0162162162;

 	
 	     float averageShadow = (vNormal.x*vNormal.x+vNormal.y*vNormal.y+vNormal.z+vNormal.z)/4.0;	
    	 
    	 //Transparency 
    	 float hologramTransparency =   max(mod(sin(time), 0.75), //0.25
    	                                0.5 
    	                                +  abs(0.3*getSineWave(vPositionWorld.y, 0.10,  time*6.0,  0.10))
    	                                - abs(  getSineWave(vPositionWorld.y, 1.0,  time,  0.2))
    	                                + 0.4*abs(  getSineWave(vPositionWorld.y, 0.5,  time,  0.3))
    	                                - 0.15*abs(  getCosineWave(vPositionWorld.y, 0.75,  time,  0.5))
    	                                + 0.15*  getCosineWave(vPositionWorld.y, 0.5,  time,  2.0)
    	                                ); 

    	gl_FragColor= vec4((color.xyz + color* (1.0-averageShadow)).xyz, max((1.0 - averageShadow) , color.z * hologramTransparency)) ;
    	vec4 sampleBLurColor = gl_FragColor;
    	sampleBLurColor += texture2D( screencopy, ( vec2(gl_FragCoord)+vec2(1.3846153846, 0.0) )/256.0 ) * 0.3162162162;
	    sampleBLurColor += texture2D( screencopy, ( vec2(gl_FragCoord)-vec2(1.3846153846, 0.0) )/256.0 ) * 0.3162162162;
	    sampleBLurColor += texture2D( screencopy, ( vec2(gl_FragCoord)+vec2(3.230769230, 0.0) )/256.0 ) * 0.0702702703;
	    sampleBLurColor += texture2D( screencopy, ( vec2(gl_FragCoord)-vec2(3.230769230, 0.0) )/256.0 ) * 0.0702702703;
	    gl_FragColor = addBorderGlowToColor(sampleBLurColor* gl_FragColor, averageShadow);
        
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	     
    	 
}
]]

local neoVertexShaderFirstPass = [[
#version 150 compatibility

// Set the precision for data types used in this shader
precision highp float;
precision highp int;

// Default THREE.js uniforms available to both fragment and vertex shader
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;

// Default uniforms provided by ShaderFrog.
uniform float time;

// Default attributes provided by THREE.js. Attributes are only available in the
// vertex shader. You can pass them to the fragment shader using varyings
attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;
attribute vec2 uv2;

// Examples of variables passed from vertex to fragment shader
varying vec3 vPositionWorld;
varying vec3 vNormal;
varying vec2 vUv;
varying vec2 vUv2;
varying vec2 vTexCoord;

float scaleTimeFullHalf(){
    return (2.0 +sin(time))/2.0;
}

float shiver(float posy, float scalar, float size) {
    if (sin(posy + time) < size)
    { return 1.0;};
    
    float renormalizedTime = sin(posy +time);
    
    return scalar*((renormalizedTime-(1.0 + (size/2.0)))/ (size/2.0));
}

void main() {
    
    // To pass variables to the fragment shader, you assign them here in the
    // main function. Traditionally you name the varying with vAttributeName
    vNormal = normal;
    vUv = uv;
    vUv2 = uv2;
    vec4 pos =(  modelMatrix * vec4(position,0));
    vPositionWorld =  pos.xyz;
    vTexCoord.xy= position.xy;
    vNormal = normalMatrix * normal;
    vec3 posCopy = position;
	posCopy.xz = posCopy.xz - 0.15 * (shiver(posCopy.y, 0.16, 0.95));
    gl_Position = projectionMatrix * modelViewMatrix * vec4(posCopy, 1.0);
	//	gl_Position.xz = gl_Position.xz* ((8.0 - sin(gl_Position.y + time * (1.0 +abs(cos(time)))))/8.0);
    
    gl_Position = position;
}]]
local neonHologramShader
local glowReflectHologramShader
local vsx, vsy
local SO_NODRAW_FLAG = 0
local SO_OPAQUE_FLAG = 1
local SO_ALPHAF_FLAG = 2
local SO_REFLEC_FLAG = 4
local SO_REFRAC_FLAG = 8
local SO_SHOPAQ_FLAG = 16
local SO_SHTRAN_FLAG = 32
local SO_DRICON_FLAG = 128
local sunChanged = false
-------------------------------------------------------------------------------------

-------Shader--2ndPass -----------------------------------------------------------
--Glow Reflection etc.
--Execution of the shader
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
        local drawMask = SO_OPAQUE_FLAG + SO_ALPHAF_FLAG + SO_REFLEC_FLAG  + SO_REFRAC_FLAG + SO_DRICON_FLAG 
        Spring.SetUnitEngineDrawMask(unitID, drawMask)
        counterNeonUnits= counterNeonUnits +1
    end	

    function gadget:Initialize() 
		vsx, vsy = gadgetHandler:GetViewSizes()
		gadget:ViewResize(vsx, vsy)

        gadgetHandler:AddSyncAction("setUnitNeonLuaDraw", setUnitNeonLuaDraw)
        gadgetHandler:AddSyncAction("unsetUnitNeonLuaDraw", unsetUnitNeonLuaDraw)

        neonHologramShader = LuaShader({
            vertex = neoVertexShaderFirstPass,
            fragment = neoFragmenShaderFirstPass,
            uniformInt = {
                tex1 = 0,
                tex2 = 1,
                normalTex = 2,
                reflectTex = 3,
            },
            uniformFloat = {
            },
        }, "Neon Hologram Shader")

--[[uniform float time;
//declare uniforms
uniform sampler2D screencopy;
uniform float resolution;
uniform float radius;
uniform vec2 dir;


// A uniform unique to this shader. You can modify it to the using the form
// below the shader preview. Any uniform you add is automatically given a form
uniform vec3 color;
uniform vec3 lightPosition;

// Example varyings passed from the vertex shader
varying vec3 vPositionWorld;
varying vec3 vNormal;

varying vec2 vUv;
varying vec2 vUv2;
varying vec2 vTexCoord;
]]

        neonHologramShader:Initialize()

 --[[       glowReflectHologramShader = LuaShader({
            vertex = glowReflectVertexShader,
            fragment = glowReflectFragmentShader,
            uniformInt = {
                tex1 = 0,
                tex2 = 1,
                normalTex = 2,
                reflectTex = 3,
            },
            uniformFloat = {
            },
        }, "Glow Reflect Shader")     
        glowReflectHologramShader:Initialize()--]]
 
    end


    local function RenderNeonUnits()
        if counterNeonUnits == 0 then
            return
        end

        if sunChanged then
                glassShader:SetUniformFloatArrayAlways("pbrParams", {
                Spring.GetConfigFloat("tonemapA", 4.8),
                Spring.GetConfigFloat("tonemapB", 0.8),
                Spring.GetConfigFloat("tonemapC", 3.35),
                Spring.GetConfigFloat("tonemapD", 1.0),
                Spring.GetConfigFloat("tonemapE", 1.15),
                Spring.GetConfigFloat("envAmbient", 0.3),
                Spring.GetConfigFloat("unitSunMult", 1.35),
                Spring.GetConfigFloat("unitExposureMult", 1.0),
            })
            sunChanged = false
        end

        glDepthTest(true)

        neonHologramShader:ActivateWith(
        function()     
            for id, typeDefID in pairs(neonUnitTables) do
                local unitID = id            
                local unitDefID = typeDefID
            end
        end)

        glDepthTest(false)
        glCulling(false)
    end

    function gadget:DrawWorld()
        RenderNeonUnits()
    end

    function gadget:Shutdown()
        neonHologramShader:Finalize()
        gadgetHandler.RemoveSyncAction("setUnitNeonLuaDraw")
        gadgetHandler:RemoveChatAction("unsetUnitNeonLuaDraw")
    end
end
