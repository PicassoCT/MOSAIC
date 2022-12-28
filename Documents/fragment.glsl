/**
* Example Fragment Shader
* Sets the color and alpha of the pixel by setting gl_FragColor
*/

// Set the precision for data types used in this shader
precision highp float;
precision highp int;

// Default THREE.js uniforms available to both fragment and vertex shader
uniform mat4 modelMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat3 normalMatrix;

// Default uniforms provided by ShaderFrog.
uniform vec3 cameraPosition;
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
	     
    	 
}