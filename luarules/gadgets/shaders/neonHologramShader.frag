    #version 150 compatibility
    //Fragmentshader
    // Set the precision for data types used in this shader


    uniform mat4 modelMatrix;
    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;
    uniform mat3 normalMatrix;
    uniform mat4 viewInvMat;

    // Default uniforms provided by ShaderFrog.
    uniform float time;
    //declare uniforms
    uniform sampler2D tex1;
    uniform sampler2D tex2;
    uniform sampler2D normalTex;
    uniform sampler2D reflectTex;
    uniform sampler2D screenTex;
    uniform sampler2D depthTex;
    
    uniform float viewPosX;
    uniform float viewPosY;
    float radius = 16.0;

    // Varyings passed from the vertex shader
    in Data {
        vec3 vViewCameraDir;
        vec3 vPositionWorld;
        vec3 vWorldNormal;
        vec2 vTexCoord;
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
	
	float fBorderFactor= 0.95f;
	float getBorderGradient(float x){
		if (x >= 0.0 && x < (1.0-fBorderFactor)){
			return x*1.0;
		}
		if (x > fBorderFactor && x <= 1.0){
			return (x-1.0)*-1.0;
		}
		return 1.0;
	}
	
	float getPixelAlphaFactor(vec2 coord)
	{
		float xScale= getBorderGradient(coord.x);
		float yScale= getBorderGradient(coord.y);
		return (xScale+yScale)/2.0;		
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
										+  abs(0.3*getSineWave(vPositionWorld.y, 0.10,  time*6.0,  0.10))
										- abs(  getSineWave(vPositionWorld.y, 1.0,  time,  0.2))
										+ 0.4*abs(  getSineWave(vPositionWorld.y, 0.5,  time,  0.3))
										- 0.15*abs(  getCosineWave(vPositionWorld.y, 0.75,  time,  0.5))
										+ 0.15*  getCosineWave(vPositionWorld.y, 0.5,  time,  2.0)
										); 

		vec4 rgbaColCopy = vec4((gl_FragColor + gl_FragColor* (1.0-averageShadow)).rgb , 
                                hologramTransparency * getPixelAlphaFactor(vec2(gl_FragCoord)));
		vec4 sampleBLurColor = rgbaColCopy.rgba;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)+vec2(1.3846153846, 0.0) )/256.0 ) * 0.3162162162;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)-vec2(1.3846153846, 0.0) )/256.0 ) * 0.3162162162;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)+vec2(3.230769230, 0.0) )/256.0 ) * 0.0702702703;
		sampleBLurColor += texture2D( screenTex, ( vec2(gl_FragCoord)-vec2(3.230769230, 0.0) )/256.0 ) * 0.0702702703;
		gl_FragColor.rgb = addBorderGlowToColor(sampleBLurColor* rgbaColCopy, averageShadow).rgb;
		
	}
