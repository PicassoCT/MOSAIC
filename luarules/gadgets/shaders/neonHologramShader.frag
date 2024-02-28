    #version 150 compatibility
    #line 20002
    //Fragmentshader
    // Set the precision for data types used in this shader
    #define RED vec4(1.0, 0.0,0.0, 0.5)
    #define GREEN vec4(0.0, 1.0,0.0, 0.5)
    #define BLUE vec4(0.0, 0.0,1.0, 0.5)
    #define NONE vec4(0.)
    #define PI 3.14159f
    //declare uniforms
    uniform sampler2D tex1;
    uniform sampler2D tex2;
    uniform sampler2D normaltex;
    uniform sampler2D reflecttex;
    uniform sampler2D screentex;
    uniform sampler2D afterglowbuffertex;

    uniform float time;
    uniform float timepercent;
    uniform vec2 viewPortSize;
    uniform vec3 unitCenterPosition;
    uniform vec3 vCamPositionWorld;

    uniform int typeDefID;
    // Varyings passed from the vertex shader
    in Data {
        vec2 vSphericalUVs;
        vec3 vPixelPositionWorld;
        vec3 normal;
        vec3 sphericalNormal;
        vec2 orgColUv;
        };

    //GLOBAL VARIABLES/////

    float radius = 16.0;
    vec2 pixelCoord;

    //////////////////////

    float getLightPercentageFactorByTime()
    {
        //Night
        if (timepercent < 0.25 || timepercent > 0.75) return 0.15;

        //day
        return 0.75;
    }
        
    float getSineWave(float posOffset, float posOffsetScale, float time, float timeSpeedScale)
    {
        return sin((posOffset* posOffsetScale) +time * timeSpeedScale);
    }
    
    float getCosineWave(float posOffset, float posOffsetScale, float time, float timeSpeedScale)
    {
        return cos((posOffset* posOffsetScale) +time * timeSpeedScale);
    }

    float cubicTransparency(vec3 position) 
    {
        float cubeSize= 2.0;
        if (mod(position.x, cubeSize) < 0.5 || mod(position.y, cubeSize) < 0.5 || (position.x, cubeSize) < 0.5)
        {         
            return abs(0.35 + abs(sin(time))*0.5)*getLightPercentageFactorByTime();         
        }
        return getLightPercentageFactorByTime();
    }

    bool isCornerCase(vec2 uvCoord, float effectStart, float effectEnd, float glowSize)
    {
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
        
        if (uvMod.x <  effectStart|| uvMod.x > effectEnd ||
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

    float GetHologramTransparency() 
    { 
        float sfactor = 4.0; //scaling factor position
        float hologramTransparency = 0.0;
        float baseInterferenceRipples   =   max(min(0.35 + sin(time)*0.1, 0.75), //0.25
                                        0.5 
                                        +  abs(0.3*getSineWave(vPixelPositionWorld.y * sfactor, 0.10,  time * 6.0,  0.10))
                                        - abs(  getSineWave(vPixelPositionWorld.y * sfactor, 1.0,  time,  0.2))
                                        + 0.4*abs(  getSineWave(vPixelPositionWorld.y * sfactor, 0.5,  time,  0.3))
                                        - 0.15*abs(  getCosineWave(vPixelPositionWorld.y * sfactor, 0.75,  time,  0.5))
                                        + 0.15*  getCosineWave(vPixelPositionWorld.y * sfactor, 0.5,  time,  2.0)
                                        ); 

        if (typeDefID == 1) //casino
        {
           hologramTransparency = cubicTransparency(vPixelPositionWorld.xyz);
        }
        if (typeDefID == 2) //brothel
        {
           hologramTransparency = mix(hologramTransparency + baseInterferenceRipples, abs(sin(time)), 0.75);
        }

        if (typeDefID == 3) //buisness 
        {
            //unaltered
            hologramTransparency = baseInterferenceRipples;
        }
        return hologramTransparency;
    }


    void main() 
	{	
    
		//our original texcoord for this fragment
		vec2 uv =  gl_FragCoord.xy / viewPortSize;    
		
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
        pixelCoord = gl_FragCoord.xy / viewPortSize;   

        //build hybrid normals
	    vec3 hyNormal = normalize(mix(normalize(normal), sphericalNormal, 0.5));
		float averageShadow = (hyNormal.x*hyNormal.x + hyNormal.y*hyNormal.y + hyNormal.z+hyNormal.z)/PI;   
        
        float hologramTransparency = GetHologramTransparency(); 
        
        vec4 orgCol = texture(tex1, orgColUv); 
        vec4 colWithBorderGlow = vec4(orgCol.rgb + orgCol.rgb * (1.0-averageShadow) , hologramTransparency); //
    
        gl_FragColor = colWithBorderGlow;
        
        /*
        //<DEBUG DELME>
        gl_FragColor = colWithBorderGlow;
        return;
        //</DEBUG DELME>
        
        //Colour is determined - now compute the distance to the camera and dissolve into pixels when to close up
        float distanceTotal= distance(vPixelPositionWorld.xyz, vCamPositionWorld.xyz);
        if (distanceTotal < 1.0)
        {            
            finalColor = dissolveIntoPixel(vec3(finalColor.r, finalColor.g, finalColor.b),  vSphericalUVs, vCamPositionWorld.xyz ,vPixelPositionWorld);
        }
  
		gl_FragColor = finalColor;
        */
        
        //This gives the holograms a sort of "afterglow", leaving behind a trail of fading previous pictures
        //similar to a very bright lightsource shining on retina leaving afterimages
        /*vec4 afterglowbuffercol =  texture2D(afterglowbuffertex, uv) * 0.9;
        if (hyNormal != NONE.rgb) 
        {
            afterglowbuffercol += gl_FragCoord * 0.9;
        }
        gl_FragColor.rgb += afterglowbuffercol;
        //texture2D(afterglowbuffertex, uv) =  afterglowbuffercol;
        */
        gl_FragColor.rgb *=  getLightPercentageFactorByTime();        
	}

