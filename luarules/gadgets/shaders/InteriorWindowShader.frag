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

    void main() 
	{	
    
		//our original texcoord for this fragment
		vec2 uv =  gl_FragCoord.xy / viewPortSize;    

        vec4 orgCol = texture(tex1, orgColUv); 
        vec4 selIluCol = texture(tex2, orgColUv); 
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

                //project window ala spiderman
                vec4 windowColor = windowTintColor *colToBW(selIluCol);
                gl_FragColor = windowColor*currentlyIluminatedFactor;
                return;
            }
        
            //rando Advertisement Flicker
            //rarely von SelfIluminated weg und zurück
            gl_FragColor = selIluCol;
            return 
        }        
	}
//https://www.shadertoy.com/view/XcBfR1
