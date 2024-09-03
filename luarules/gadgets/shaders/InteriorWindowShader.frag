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

    uniform int unitID;
    // Varyings passed from the vertex shader
    in Data {

        vec3 vPixelPositionWorld;
        vec3 normal;
        vec3 sphericalNormal;
        vec2 orgColUv;
        };

vec4 colToBW(vec4 col)
{
    float avg = sqrt(col.r * col.r + col.g *col.g + col.b * col.b);
    return vec4(vec3(avg), col.a);
}

vec4 hslToRgb(vec3 hsl) {
    float h = hsl.r;
    float s = hsl.g;
    float l = hsl.b;
    vec4 rgba = vec4(0,0,0, 1.0);
    float c = (1.0f - abs(2.0f * l - 1.0f)) * s; // Chroma
    float x = c * (1.0f - abs(mod(h / 60.0f, 2) - 1.0f));
    float m = l - c / 2.0f;

    float r1, g1, b1;

    if (h >= 0 && h < 60) {
        r1 = c; g1 = x; b1 = 0;
    } else if (h >= 60 && h < 120) {
        r1 = x; g1 = c; b1 = 0;
    } else if (h >= 120 && h < 180) {
        r1 = 0; g1 = c; b1 = x;
    } else if (h >= 180 && h < 240) {
        r1 = 0; g1 = x; b1 = c;
    } else if (h >= 240 && h < 300) {
        r1 = x; g1 = 0; b1 = c;
    } else {
        r1 = c; g1 = 0; b1 = x;
    }

    rgba.r = (r1 + m) ;
    rgba.g = (g1 + m) ;
    rgba.b = (b1 + m) ;
    return rgba; 
}

    vec4 windowLightColor (unsigned int index)
    {
        vec3  light_colors[] = 
        { 
          vec3(0.04f,  0.9f,  0.93f ),   //Amber / pink
          vec3(0.055f, 0.95f, 0.93f ),   //Slightly brighter amber 
          vec3(0.08f,  0.7f,  0.93f ),   //Very pale amber
          vec3(0.07f,  0.9f,  0.93f ),   //Very pale orange
          vec3(0.1f,   0.9f,  0.85f ),   //Peach
          vec3(0.13f,  0.9f,  0.93f ),   //Pale Yellow
          vec3(0.15f,  0.9f,  0.93f ),   //Yellow
          vec3(0.17f,  1.0f,  0.85f ),   //Saturated Yellow
          vec3(0.55f,  0.9f,  0.93f ),   //Cyan
          vec3(0.55f,  0.9f,  0.93f ),   //Cyan - pale, almost white
          vec3(0.6f,   0.9f,  0.93f ),   //Pale blue
          vec3(0.65f,  0.9f,  0.93f ),   //Pale Blue II, The Palening
          vec3(0.65f,  0.4f,  0.99f ),   //Pure white. Bo-ring.
          vec3(0.65f,  0.0f,  0.8f ),    //Dimmer white.
          vec3(0.65f,  0.0f,  0.6f ),    //Dimmest white.
        }; 

      index = mod(index, 15);
      return hslToRgb (light_colors[index].r, light_colors[index].g, light_colors[index].b);

    }


    float getPseudoRandom(float startHash)
    {
        return fract(sin(dot(vec2(startHash), vec2(12.9898, 4.1414)))) * 43758.5453;
    }

    //Makes all neon-advertisments go uniluminated simultanously over one building
    //Not ideal, should be per piece
    float GetRandomFlickerFactor()
    {
       float detMod = mod(unitID, 150.0);
       float flickerFactor=  mod(time + unitID, detMod);
       if (flickerFactor < 1.0) return flickerFactor;
       return 1.0;
    }
    vec4 projectionWindow(vec2 uv)
    {
        /*
// Interior room count (width, height, depth)
const vec3 interior = vec3(4.0f, 4.0f, 1.0f);

float rand(float v){
    return fract(sin(v * 30.11));
}

vec3 Lerp(vec3 start_value, vec3 end_value, float pct)
{
    return (start_value + (end_value - start_value) * pct);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Pixel position
    vec3 pixel = vec3(uv.x, uv.y, 0.0f);
    // apply tiling
    pixel = fract(pixel * interior);
    
    // Camera position
    //vec3 camera = vec3(1.0f, 1.0f, 1.0f);
    vec3 camera = vec3(0.5f + cos(iTime*0.5f)*0.5f, 0.5f + sin(iTime*0.5f)*0.5f, 1.0f);
    // apply tiling offset
    camera.xy -= (uv - pixel.xy);
    
    // Up vector
    vec3 up = vec3(0.0f, 1.0f, 0.0f);
    
    // Right vector
    vec3 right = vec3(1.0f, 0.0f, 0.0f);
    
    // View direction
    vec3 viewDir = pixel - camera;

    // Floor position
    vec3 floor;
    floor.y = 0.0f;
    floor.z = ((pixel.y/camera.y)*camera.z) / (1.0f-(pixel.y/camera.y));
    floor.x = (pixel.x-camera.x + (camera.z/(camera.z+floor.z))*camera.x) / (camera.z/(camera.z+floor.z));

    // Ceiling position
    vec3 ceiling;
    ceiling.y = 1.0f;
    ceiling.z = ((1.0f - pixel.y)/(1.0f-camera.y))*camera.z / (1.0f-((1.0f - pixel.y)/(1.0f-camera.y)));
    ceiling.x = camera.x + (pixel.x-camera.x)*(ceiling.z+camera.z)/camera.z;
    
    // Left Wall position
    vec3 leftWall;
    leftWall.x = 0.0f;
    leftWall.z = ((pixel.x/camera.x)*camera.z) / (1.0f-(pixel.x/camera.x));
    leftWall.y = (pixel.y - (leftWall.z/(leftWall.z+camera.z))*camera.y) / (1.0f-leftWall.z/(leftWall.z+camera.z)); 
    
    // Right Wall position
    vec3 rightWall;
    rightWall.x = 1.0f;
    rightWall.z = (((1.0f-pixel.x)/(1.0f-camera.x))*camera.z) / (1.0f-(1.0f-pixel.x)/(1.0f-camera.x));
    rightWall.y = (pixel.y - (rightWall.z/(rightWall.z+camera.z))*camera.y) / (1.0f-rightWall.z/(rightWall.z+camera.z));;
    
    // Back Wall position
    vec3 backWall;
    backWall.z = interior.z;
    backWall.x = (pixel.x-camera.x)*(camera.z+interior.z)/(camera.z) + camera.x;
    backWall.y = (pixel.y-camera.y)*(camera.z+interior.z)/(camera.z) + camera.y;
    
    // Compute intersecting plane
    bool isCeiling = dot(viewDir, up) > 0.0f;
    bool isRightWall = dot(viewDir, right) > 0.0f;
    
    float leftRightWallsDepth = isRightWall? rightWall.z : leftWall.z;
    float floorCeilingDepth = isCeiling? ceiling.z : floor.z;
     
    bool isWallsClosest = leftRightWallsDepth < floorCeilingDepth;
    float closestHit = isWallsClosest? leftRightWallsDepth : floorCeilingDepth; 
    
    bool isBackClosest = interior.z < closestHit;
     
    // Sample texture
    if(isBackClosest)
    {
        fragColor = texture(iChannel2, backWall.xy);
    }
    else if(isWallsClosest)   
    {
        if(isRightWall)
        {
            fragColor = texture(iChannel1, rightWall.zy);
        }
        else
        {
            fragColor = texture(iChannel1, leftWall.zy);
        }
    }
    else
    {
        if(isCeiling)
        {
            fragColor = texture(iChannel0, ceiling.xz);
        }
        else
        {
            fragColor = texture(iChannel0, floor.xz);
        }
    }
    
        
    // Chair Layer position
    vec3 chairLayer;
    chairLayer.z = interior.z * 0.5f;
    chairLayer.x = (pixel.x-camera.x)*(camera.z+interior.z*0.5f)/(camera.z) + camera.x;
    chairLayer.y = (pixel.y-camera.y)*(camera.z+interior.z*0.5f)/(camera.z) + camera.y;
    bool isChairClosest = interior.z * 0.5f< closestHit;
    
    if(isChairClosest)
    {
        //borrowed from https://www.shadertoy.com/view/XfBfDW
        float p = 0.05; // Percition
        float a = mod(iTime, 3.0); // Amplitude
        float i = iTime;
        vec3 col = vec3(step(abs(0.5*sin(-i+uv.x)-uv.y*a), p), 
        step(abs(0.5*sin(i+uv.x)-uv.y*a), p), 
        step(abs(0.5*sin(i+uv.x)+0.5*sin(-i+uv.x)-uv.y*a), p));

    
        chairLayer.x = chairLayer.x+ sin(iTime);
        vec4 chairTexture = texture(iChannel3, chairLayer.xy);
        chairTexture.a = col.r;
        fragColor = mix(fragColor, chairTexture, chairTexture.a);
    }

    // random "lighting" per room
    vec2 room = ceil(uv * interior.xy);
    float roomID = room.y * interior.x + room.x;
    float slowShift = (iTime/100.0);
    fragColor.rgb *= mix(0.5f, 1.5f, rand(roomID + slowShift));
    
}
        */
    }

    void main() 
	{	
    
		//our original texcoord for this fragment
		vec2 uv =  gl_FragCoord.xy / viewPortSize;    

        vec4 orgCol = texture(tex1, orgColUv); 
        vec4 selIluCol = texture(tex2, orgColUv);
        selfIluCol.a = 1.0; 
        if (selIluCol.r > 0 ) //self-ilumination is active
        {
            gl_FragColor = selIluCol;
            return; //TODO Debug
            if (selIluCol.b > 0) //window 
            {           
                //stable over time
                int windowID = getPseudoRandom(uv.x + uv.y);

                //flickers over time 
                isCurrentlyIluminated = mod(getPseudoRandom(windowID + timepercent* 4.0));
                float currentlyIluminatedFactor = 1.0;
                if (!isCurrentlyIluminated) currentlyIluminatedFactor = 1.0/(mod(float(windowID), 5.0));


                //Get window color similar to shamus young algo
                vec4 windowTintColor = windowLightColor(unitID) ;

                //projection windows
                vec4 projWindow = projectionWindow();
                //project window ala spiderman
                vec4 windowColor = windowTintColor *colToBW(selIluCol);
                gl_FragColor = windowColor*currentlyIluminatedFactor;
                return;
            }
            float randoFlickerFactor = GetRandomFlickerFactor();
            //rando Advertisement Flicker
            selfIluCol.rgb *= randoFlickerFactor;
            gl_FragColor = selIluCol;
            return 
        }        
	}
//https://www.shadertoy.com/view/XcBfR1
