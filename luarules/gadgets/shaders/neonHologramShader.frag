    #version 150 compatibility
    //Fragmentshader
    // Set the precision for data types used in this shader

    //declare uniforms
    uniform sampler2D tex1;
    uniform sampler2D tex2;
    uniform sampler2D normalTex;
    uniform sampler2D reflectTex;
    uniform sampler2D screenTex;
    uniform sampler2D depthTex;

    uniform float time;
    uniform float viewPosX;
    uniform float viewPosY;
    uniform float unitCenterPosition[3];

    //uniform mat4 modelMatrix;
    uniform mat4 viewMat;
    uniform mat4 projectionMatrix;
    uniform mat3 normalMatrix;
    uniform mat4 viewInvMat;    
 
    float radius = 16.0;
    float DISTANCE_VISIBILITY_PIXEL_WORLD = 100.0;

    // Varyings passed from the vertex shader
    in Data {
        vec3 vViewCameraDir;
        vec3 vWorldNormal;
        vec2 vSphericalUVs;
        vec3 vPixelPositionWorld;
        vec2 vTexCoord;
        vec4 vCamPositionWorld;
        };
        
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
            vec4 col =   texture2D(screenTex, point);
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
                //screenTex[int(pixelCoord.x)][int(pixelCoord.z)] =
                getGlowColorBorderPixel(lightSourceColor, texture2D( screenTex,  pixelCoord), dist, 16.0);
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

	
	float getPixelColumnFactor(vec3 camWorldCoordinates, vec3 worldCoordinates, float columAlpha)
	{
        //if its to far away no pixels are visible
        float distanceToCam = distance(camWorldCoordinates, worldCoordinates);
        if (distanceToCam > DISTANCE_VISIBILITY_PIXEL_WORLD) { return 0.0; }

        return 1.0 - ( distanceToCam/ DISTANCE_VISIBILITY_PIXEL_WORLD);
	}

bool isCornerCase(vec2 uvCoord, float effectStart, float effectEnd, float glowSize){
    if (uvCoord.x > effectStart && uvCoord.x < effectStart + glowSize &&
       uvCoord.y > effectStart && uvCoord.y < effectStart + glowSize )   { return true;}
      
    if (uvCoord.x > effectEnd -glowSize && uvCoord.x < effectEnd  &&
       uvCoord.y > effectStart && uvCoord.y < effectStart + glowSize )   { return true;}
      
    if (uvCoord.x > effectEnd -glowSize && uvCoord.x < effectEnd  &&
       uvCoord.y >  effectEnd -glowSize && uvCoord.y < effectEnd )   { return true;}

    if (uvCoord.x > effectStart && uvCoord.x < effectStart + glowSize &&
       uvCoord.y >  effectEnd -glowSize && uvCoord.y < effectEnd )   { return true;}
    return false;
}

vec4 dissolveIntoPixel(vec3 col, vec2 uvCoord, vec3 camPos, vec3 worldPosition)
{      
    float distanceTotal= distance(worldPosition, camPos);
    float distFactor = min(1.0, max(distanceTotal, 0.001));
    
    float empyAreaScale = distFactor;//max(0.01, min(1.0, distanceToCam/100.0));
    float minTransparency = 0.7;
    float maxTransparency = 0.1;
    
    float dynamicBorderSize = 0.250;
    float UnitSize = 0.015;
    float UnitHalf = UnitSize * 0.5;
    vec2 uvMod = vec2(mod(uvCoord.x, UnitSize), mod(uvCoord.y, UnitSize));
        
    float pixelSize = UnitSize* 0.5;
    float pixelHalf = pixelSize *0.5;
    float glowBorderSize = ((UnitSize - pixelSize)/2.0)*empyAreaScale;
    float EffectFullSize = pixelSize + 2.0 *glowBorderSize;
    
    float effectStart = (UnitSize - EffectFullSize)* 0.5;
    float pixelStart = UnitHalf - pixelSize;
    float effectEnd = (UnitSize - effectStart);
    float pixelEnd =  UnitHalf + pixelSize;
    
    if (uvMod.x <  effectStart|| uvMod.x > effectEnd||
        uvMod.y <  effectStart|| uvMod.y > effectEnd
    )
    {            
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    
    if (isCornerCase(uvMod,  effectStart, effectEnd, glowBorderSize) == true)
    {
        return vec4 (col.rgb*distFactor, distFactor);
    }
    
    
    if (uvMod.x >= (UnitHalf - pixelHalf) && uvMod.x <= (UnitHalf + pixelHalf) &&
        uvMod.y >=( UnitHalf - pixelHalf) && uvMod.y <= (UnitHalf + pixelHalf) 
    )
    {
        return vec4 (col.rgb, minTransparency);
    }    

    if (uvMod.x >= effectStart && uvMod.x <= effectStart +  glowBorderSize 
    &&     uvMod.y > pixelStart && uvMod.y < pixelEnd
    )
    {
        float willItBlend = (uvMod.x -effectStart)/glowBorderSize;
        return vec4 (col.rgb, mix( maxTransparency, minTransparency, willItBlend));
    }
    
    if (uvMod.x >= UnitHalf + pixelHalf && uvMod.x <= effectEnd &&
       uvMod.y > pixelStart && uvMod.y < pixelEnd
    )
    {
        float willItBlend = abs(uvMod.x -(effectEnd - glowBorderSize))/glowBorderSize;
        return vec4 (col.rgb,  mix( minTransparency, maxTransparency, willItBlend));
    }
    
    if (uvMod.y >= effectStart && uvMod.y <= effectStart +  glowBorderSize &&
      uvMod.x > pixelStart && uvMod.x < pixelEnd
    )
    {
        float willItBlend = abs(uvMod.y -effectStart)/glowBorderSize;
        return vec4 (col.rgb,  mix( maxTransparency,minTransparency, willItBlend));
    }
    
    if (uvMod.y >= UnitHalf + pixelHalf && uvMod.y <= effectEnd &&
      uvMod.x > pixelStart && uvMod.x < pixelEnd
    )
    {
        float willItBlend = abs(uvMod.y -(effectEnd - glowBorderSize))/glowBorderSize;
        return vec4 (col.rgb, mix( minTransparency,maxTransparency, willItBlend));      
    }
    
return vec4(0.0, 0.0, 0.0, 0.0);
}

    void main() 
	{	
		//this will be our RGBA sumt
		vec4 sum = vec4(0.0);
		
		//our original texcoord for this fragment
		vec2 tc = vTexCoord;
		
		//the amount to blur, i.e. how far off center to sample from 
		//1.0 -> blur by one pixel
		//2.0 -> blur by two pixels, etc.
		float blur = radius/1024.0; 
		
		//the direction of our blur
		//(1.0, 0.0) -> x-axis blur
		//(0.0, 1.0) -> y-axis blur
		float hstep = 0.1;
		float vstep = 1.0;
			
		//apply blurring, using a 9-tap filter with predefined gaussian weights
		
		sum += texture2D(screenTex, vec2(tc.x - 4.0*blur*hstep, tc.y - 4.0*blur*vstep)) * 0.0162162162;

	
		float averageShadow = (vWorldNormal.x*vWorldNormal.x+vWorldNormal.y*vWorldNormal.y+vWorldNormal.z+vWorldNormal.z)/4.0;   
		
		//Transparency 
		float hologramTransparency =   max(mod(sin(time), 0.75), //0.25
										0.5 
										+  abs(0.3*getSineWave(vPixelPositionWorld.y, 0.10,  time*6.0,  0.10))
										- abs(  getSineWave(vPixelPositionWorld.y, 1.0,  time,  0.2))
										+ 0.4*abs(  getSineWave(vPixelPositionWorld.y, 0.5,  time,  0.3))
										- 0.15*abs(  getCosineWave(vPixelPositionWorld.y, 0.75,  time,  0.5))
										+ 0.15*  getCosineWave(vPixelPositionWorld.y, 0.5,  time,  2.0)
										); 


        vec4 rgbaColCopy = vec4((gl_FragColor + gl_FragColor * (1.0-averageShadow)).rgb , hologramTransparency);
        
		vec4 sampleBLurColor = rgbaColCopy.rgba;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)+vec2(1.3846153846, 0.0) ) /256.0 ) * 0.3162162162;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)-vec2(1.3846153846, 0.0) ) /256.0 ) * 0.3162162162;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)+vec2(3.230769230, 0.0) )  /256.0 ) * 0.0702702703;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)-vec2(3.230769230, 0.0) )  /256.0 ) * 0.0702702703;
        vec4 borderGlowColor = addBorderGlowToColor(sampleBLurColor* rgbaColCopy, averageShadow);
        vec4 finalColor = borderGlowColor;
        finalColor.a = 1.0;

        float distanceTotal= distance(vPixelPositionWorld, vCamPositionWorld.xyz);
        if (distanceTotal  < 1.0)
        {            
            finalColor = dissolveIntoPixel(vec3(finalColor.r, finalColor.g, finalColor.b),  vSphericalUVs, vCamPositionWorld.xyz ,vPixelPositionWorld);
        }

		gl_FragColor.rgb = finalColor.rgb;		
	}

