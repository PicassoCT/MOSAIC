    #version 150 compatibility
    #line 20002
    //Fragmentshader
    // Set the precision for data types used in this shader
    #define RED vec4(1.0, 0.0,0.0, 0.5)
    #define GREEN vec4(0.0, 1.0,0.0, 0.5)
    #define BLUE vec4(0.0, 0.0,1.0, 0.5)
    #define NONE vec4(0.)
    #define PI 3.14159f

    //////////////////////    //////////////////////    //////////////////////    //////////////////////
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

    //GLOBAL VARIABLES/////    //////////////////////    //////////////////////    //////////////////////

    float radius = 16.0;
    vec2 pixelCoord;

    //////////////////////    //////////////////////    //////////////////////    //////////////////////

    float getLightPercentageFactorByTime()
    {
        return mix(0.35, 0.75,(1 + sin(timepercent * 2 * PI)) * 0.5);
    }
        
    float getSineWave(float posOffset, float posOffsetScale, float time, float timeSpeedScale)
    {
        return sin((posOffset* posOffsetScale) +time * timeSpeedScale);
    }
    
    float getCosineWave(float posOffset, float posOffsetScale, float time, float timeSpeedScale)
    {
        return cos((posOffset* posOffsetScale) +time * timeSpeedScale);
    }

    float cubicTransparency(vec2 position) 
    {
        float cubeSize= 2.0;
        if (mod(position.x, cubeSize) < 0.5 || 
            mod(position.y, cubeSize) < 0.5 )
        {         
            return abs(0.35 + abs(sin(time)) * 0.5) * getLightPercentageFactorByTime();         
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

    float GetHologramTransparency() 
    { 
        float sfactor = 4.0; //scaling factor position
        float hologramTransparency = 0.0;
        float baseInterferenceRipples   =   max(min(0.35 + sin(time)*0.1, 0.75), //0.25
                                        0.5 
                                        +  abs(0.3 * getSineWave(vPixelPositionWorld.y * sfactor, 0.10,  time * 6.0,  0.10))
                                        - abs(  getSineWave(vPixelPositionWorld.y * sfactor, 1.0,  time,  0.2))
                                        + 0.4 * abs(  getSineWave(vPixelPositionWorld.y * sfactor, 0.5,  time,  0.3))
                                        - 0.15 * abs(  getCosineWave(vPixelPositionWorld.y * sfactor, 0.75,  time,  0.5))
                                        + 0.15 * getCosineWave(vPixelPositionWorld.y * sfactor, 0.5,  time,  2.0)
                                        ); 

        if (typeDefID == 1) //casino
        {
           vec3 normedSphericalUvs = normalize(vSphericalUVs);
           float sphericalUVsValue = (normedSphericalUvs.x+ normedSphericalUvs.y)/2.0;
           
           hologramTransparency = mix(mod(sphericalUVsValue +baseInterferenceRipples, 1.0), cubicTransparency(vSphericalUVs), 0.9);;
        }
        if (typeDefID == 2 || typeDefID == 4) //brothel || asian buisness
        {
            hologramTransparency = mix(baseInterferenceRipples , (2 + sin(time)) * 0.5, 0.5);
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
        
        colWithBorderGlow.rgb *= getLightPercentageFactorByTime();
        if (typeDefID == 1 || typeDefID == 4) //casino
        {
            colWithBorderGlow.rgb = mix(colWithBorderGlow.rgb, vSphericalUVs.rgb, abs(sin(time))/10.0);
        }
        if (typeDefID == 2) //brothel
        {
            float colHighLights = (-0.5 + ((abs(vSphericalUVs.x) + abs(vSphericalUVs.y))/2.0))/10.0;
            colWithBorderGlow.rgb += colHighLights;
        }
        gl_FragColor = colWithBorderGlow;
        
        //This gives the holograms a sort of "afterglow", leaving behind a trail of fading previous pictures
        //similar to a very bright lightsource shining on retina leaving afterimages
        //Is storing for pieces anyway TODO find out write to framebuffer object syntax
        //sampler2D(afterglowbuffertex, gl_FragCoord, gl_FragColor);
        
            
	}

