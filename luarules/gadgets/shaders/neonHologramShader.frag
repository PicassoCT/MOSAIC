    #version 150 compatibility
    #line 20002
    //Fragmentshader
    // Set the precision for data types used in this shader
    #define RED vec4(1.0, 0.0,0.0, 0.5)
    #define GREEN vec4(0.0, 1.0,0.0, 0.5)
    #define BLUE vec4(0.0, 0.0,1.0, 0.5)
    #define NONE vec4(0.)
    #define PI 3.14159f
    #define Y_NORMAL_CUTOFFVALUE 0.995

    #define CASINO 1
    #define BROTHEL 2
    #define BUISNESS 3
    #define ASIAN 4

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
    uniform float rainPercent;
    uniform vec2 viewPortSize;

    uniform vec3 unitCenterPosition;
   // uniform vec3 vCamPositionWorld;

    uniform int typeDefID;
    // Varyings passed from the vertex shader
    in Data {
        vec2 vSphericalUVs;
        vec3 vPixelPositionWorld;
        vec3 normal;
        vec3 sphericalNormal;
        vec2 orgColUv;
        vec3 vVertexPos;
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

        if (typeDefID == CASINO) //casino
        {
           vec3 normedSphericalUvs = normalize(sphericalNormal);
           float sphericalUVsValue = (normedSphericalUvs.x + normedSphericalUvs.y)/2.0;           
           hologramTransparency = mix(mod(sphericalUVsValue + baseInterferenceRipples, 1.0), cubicTransparency(vSphericalUVs), 0.9);
        }
        if (typeDefID == BROTHEL || typeDefID == ASIAN) //brothel || asian buisness
        {
            float averageShadow = (sphericalNormal.x*sphericalNormal.x+sphericalNormal.y*sphericalNormal.y+sphericalNormal.z+sphericalNormal.z)/4.0;    
            hologramTransparency = max(0.2, mix(baseInterferenceRipples , (2 + sin(time)) * 0.55, 0.5) + averageShadow);
        }

        if (typeDefID == BUISNESS) //buisness 
        {
            hologramTransparency = baseInterferenceRipples;
        }
        return hologramTransparency;
    }

    vec3 applyColorAberation(vec3 col)
    {
        if (typeDefID == CASINO || typeDefID == ASIAN) //casino
        {
            return mix(col, sphericalNormal, max(sin(time), 0.0)/10.0);
        }
        if (typeDefID == BROTHEL) //brothel
        {
            float colHighLights = (-0.5 + ((abs(sphericalNormal.x) + abs(sphericalNormal.z))/2.0))/10.0;
            return col + colHighLights;
        }

        if (typeDefID == BUISNESS) 
        {
            if (timepercent < 0.25 && mod(time, 60) < 0.1)
            {
                return sphericalNormal; //glitchy
            }          
        }

        return col;
    }

    float random(float x) 
    {    
        return fract(sin(x * 12.9898) * 43758.5453);
    }

    // Generates a soft glowing line
    float lineGlow(float y, float center, float width)
    {
        float d = abs(y - center);
        return exp(-d * width);
    }


    // Sparkle effect (twinkle over time)
    float sparkle(float y, float dropY, float t)
    {
        float dist = abs(y - dropY);
        float pulse = sin(t * 40.0 + dropY * 10.0) * 0.5 + 0.5;
        return exp(-dist * 60.0) * pulse;
    }


    void main() 
	{	
    
		//our original texcoord for this fragment
		vec2 uv =  gl_FragCoord.xy;    
		
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

        colWithBorderGlow.rgb = applyColorAberation(colWithBorderGlow.rgb);

        gl_FragColor = colWithBorderGlow;
        //This gives the holograms a sort of "afterglow", leaving behind a trail of fading previous pictures
        //similar to a very bright lightsource shining on retina leaving afterimages
        gl_FragColor = RED;
        if (true)//(rainPercent < 0.80)
        {
            //a sort of matrix rain effect with a brightly shining raindrop and a dark trail of "blocked light"
            float pixelPillarSize = 100.0;
            vec3 uvw = mod(vVertexPos.xyz / pixelPillarSize, 1.0);
            uvw.y = 1.0 - uvw.y;

            //we are talking about a pixelpillar- the rooftop, depends on the status beeing above or below- if below
            gl_FragColor.rgb = normal;
            //we calcuates

            return;
            if (normal.g < Y_NORMAL_CUTOFFVALUE )
            {
                gl_FragColor = getPixelRainSideOfColumn(uvw);
            }
            else
            {
                gl_FragColor = getPixelRainTopOfColumn(uvw);
            }            
        }     
	}

    float columwidth= 5.0;
    float halfSize = columwidth*0.5;
    float columns = 80.0;
    float fallSpeed = 4.0;      // Controls vertical speed
    float shimmerFreq = 40.0;   // How fast it sparkles
    float trailFade = 256.0;     // How long the trail glows
    float recoverySpeed = 30.0;  // How fast it fades back

    float GetRainDropWaveAt(float heightValue){
        return sin(time * fallSpeed - heightValue * 10.0 + colOffset * 6.2831);
    }

    vec4 getPixelRainTopOfColumn(vec3 uvw, vec4 originalColor)
    {
        vec2 v_uv = uvw.xz;
        float wave = GetRainDropWaveAt(uv.y);
        float glow = exp(-wave * trailFade);
        //determinate high effect
        float col = floor((uv.x/columwidth) * columns);
        float row = floor((uv.z/columwidth) * columns);
        vec2 u_center = vec2(col * columwidth +  halfSize  , row * columwidth + halfSize);
        vec2 minEdge = u_center - halfSize;
        vec2 maxEdge = u_center + halfSize;

        // Create mask: 1 inside rect, 0 outside
        float inRect = step(minEdge.x, v_uv.x) * step(v_uv.x, maxEdge.x) * step(minEdge.y, v_uv.y) * step(v_uv.y, maxEdge.y);

        fragColor = vec4(originalColor * glow, inRect);  // Render to alpha only
    }

    vec4 getPixelRainSideOfColumn(vec3 uvw, vec4 originalColor)
    {
        vec2 uv = uvw.xy;
        // Config

            // Which column we're in
            float col = floor((uv.x/columwidth) * columns);
            float colOffset = random(floor(uv.x/10.0));

            // float active = step(0.8, random(vVertexPos.z));
            // if (active < 1.0) return;

            // Drop "wave" — sine over time and vertical pos
            float wave = GetRainDropWaveAt(uv.y);

            // Sparkling glow when wave > 0
            float glow = 0.0;
            if (wave > 0.0) {
                float dropGlow = exp(-wave * trailFade);
                float shimmer = sin((time + uv.y * 5.0) * shimmerFreq) * 0.5 + 0.5;
                glow = dropGlow * shimmer;
            }

            // Recovery phase: when wave < 0
            float alphaRecovery = 0.0;
            if (wave < 0.0) {
                alphaRecovery = 1.0 - exp(wave * recoverySpeed);
            }

            // Final alpha: bright when glowing, then fades out, then fades back in
            float alpha = glow  + alphaRecovery * 0.5;

            // Glow color
            vec3 color = originalColor.rgb* glow;

            // Glow intensity
            return vec4(color, min(0.5,alpha));
    }

