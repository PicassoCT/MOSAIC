    #version 150 compatibility
    #line 20002
    const vec3 vMinima = vec3(-300000.0, 0, -300000.0);
    const vec3 vMaxima = vec3( 300000.0, 4096.0,  300000.0);
    //Fragmentshader
    // Set the precision for data types used in this shader
    //CONSTANTS
    #define PI 3.1415926535897932384626433832795
    #define PI_HALF (PI*0.5)
    #define MAX_DEPTH_RESOLUTION 20.0
    #define E_CONST 2.718281828459045235360287471352
    #define NONE vec4(0.0,0.0,0.0,0.0)
    #define RED vec4(1.0, 0.0, 0.0, 0.95)
    #define GREEN vec4(0.0, 1.0, 0.0, 0.95)
    #define BLUE vec4(0.0, 0.0, 1.0, 0.95)
    #define BLACK vec4(0.0, 0.0, 0.0, 0.95)
    #define IDENTITY vec4(1.0,1.0,1.0,1.0)
    #define DMAX /4096.

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
    uniform vec3 eyePos;
    uniform vec3 eyeDir;
    uniform vec2 viewPortSize;
    uniform mat4 viewProjectionInv;
    uniform mat4 viewProjection;
    uniform mat4 projection;
    uniform mat4 viewInv;
    uniform mat4 viewMatrix;
    uniform int unitID;
    uniform int typeDefID;
    // Varyings passed from the vertex shader
    in Data {

      vec3 vPixelPositionWorld;
      vec3 normal;
      vec3 sphericalNormal;
      vec2 orgColUv;
      vec3 viewDirection;
      vec4 fragWorldPos;
    };

    // Interior room count (width, height, depth)
    const vec3 asian_interior = vec3(5.0f, 5.0f, 1.0f);
    const vec3 arab_interior = vec3(5.0f, 5.0f, 1.0f);
    const vec3 western_interior = vec3(5.0f, 5.0f, 1.0f);


    struct Ray 
    {
        vec3 Origin;
        vec3 Dir;
    };
    struct AABB {
        vec3 Min;
        vec3 Max;
    };
    //Global Variables          //////////////////////////////////////////////////////////

    vec2 uv;
    vec3 worldPos;
    vec4 mapDepth;
    vec4 depthAtPixel;
    vec4 modelDepth;  
    vec3 pixelDir;
    vec4 depthAtPixel;
    vec4 modelDepth;

    //Global Variables          //////////////////////////////////////////////////////////

    vec4 colToBW(vec4 col) {
      float avg = sqrt(col.r * col.r + col.g * col.g + col.b * col.b);
      return vec4(vec3(avg), col.a);
    }

    float absinthTime()
    {
        return abs(sin(time));
    }

    vec4 hslToRgb(float h, float s, float l) {
  
      vec4 rgba = vec4(0, 0, 0, 1.0);
      float c = (1.0f - abs(2.0f * l - 1.0f)) * s; // Chroma
      float x = c * (1.0f - abs(mod(h / 60.0f, 2) - 1.0f));
      float m = l - c / 2.0f;

      float r1, g1, b1;

      if (h >= 0 && h < 60) {
        r1 = c;
        g1 = x;
        b1 = 0;
      } else if (h >= 60 && h < 120) {
        r1 = x;
        g1 = c;
        b1 = 0;
      } else if (h >= 120 && h < 180) {
        r1 = 0;
        g1 = c;
        b1 = x;
      } else if (h >= 180 && h < 240) {
        r1 = 0;
        g1 = x;
        b1 = c;
      } else if (h >= 240 && h < 300) {
        r1 = x;
        g1 = 0;
        b1 = c;
      } else {
        r1 = c;
        g1 = 0;
        b1 = x;
      }

      rgba.r = (r1 + m);
      rgba.g = (g1 + m);
      rgba.b = (b1 + m);
      return rgba;
    }

    bool isInRectangle(vec4 rec, vec2 tUv) {
      vec2 start = vec2(rec.rg / 4096.0);
      if (!(tUv.x >= start.x && tUv.y >= start.y)) return false;
      vec2 end = vec2(rec.ba / 4096.0);
      if (!(tUv.x <= end.x && tUv.y <= end.y)) return false;
      return true;
    }

    bool modulator(int value, int max, int truth)
    {
        return mod(value, max) == truth;
    }


    float rand(float v) {
      return fract(sin(v * 30.11));
    }

    vec3 Lerp(vec3 start_value, vec3 end_value, float pct) {
      return (start_value + (end_value - start_value) * pct);
    }

    bool mmodulator(int roomID, int sizeMax, int expected){
      return int(mod(roomID, sizeMax)) == expected;
    }

    float getPseudoRandom(float startHash) {
      return fract(sin(dot(vec2(startHash), vec2(12.9898, 4.1414)))) * 43758.5453;
    }

    vec2 applyOffset(vec3 scaleOffset, vec2 orgUv)
    {
        float scale = scaleOffset.r / 4096.0;
        vec2 proportionalOffset = scaleOffset.gb;
        orgUv -= proportionalOffset;
        return orgUv * (1./scale);
    }

    vec4 mapUvToSubUvSquareFetchTex(vec2 tUv, vec4 startend) {
        float texSizeCubed = 4096.0;

        // Normalize the start and end points of the sub-rectangle
        vec2 start = startend.rg / texSizeCubed;  // bottom-left corner
        vec2 end = startend.ba / texSizeCubed;    // top-right corner
        vec2 subUvSize = end - start;
        tUv = fract(tUv);
        vec2 scaledUVs = start + tUv * subUvSize;
        return texture(tex1, scaledUVs);
    }

////</TOOLING >//////////////////////////////////////////////////////////////////////////////////////
    vec4 getWallTexture(vec2 tUv, int roomID) 
    {
        if (typeDefID == 0) //Asian Building
        { 
            int sizeMax = 64;
            int modResult = int(mod(roomID, sizeMax));
            switch(modResult){
            case 0: return mapUvToSubUvSquareFetchTex(tUv, vec4(1546.0, 3097.0, 1856.0, 3567.0));
            case 1:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1425.0, 3588.0, 1645.0, 3806.0));
            case 2:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1651., 3586., 1841., 3793.));
            case 3:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1840., 3586., 2042., 3786.));
            case 4:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1850., 3791., 2048., 3985.));
            case 5:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1838., 3933., 2055., 4096.));
            case 6:  return mapUvToSubUvSquareFetchTex(tUv, vec4(3080., 2305., 3414., 2575.));
            case 7: return mapUvToSubUvSquareFetchTex(tUv, vec4(248.0, 3652.0, 383.0, 3759.0));
            case 8: return mapUvToSubUvSquareFetchTex(tUv, vec4(0.0, 3661.0, 237.0, 3831.0));
            case 9: return mapUvToSubUvSquareFetchTex(tUv, vec4(0.0, 3940.0, 79.0, 4000.0));
            case 10: return mapUvToSubUvSquareFetchTex(tUv, vec4(664.0, 3586.0, 1016.0, 3764.0));
            case 11: return mapUvToSubUvSquareFetchTex(tUv, vec4(810.0, 3804.0, 972.0, 4056.0));
            case 12: return mapUvToSubUvSquareFetchTex(tUv, vec4(1042.0, 3094.0, 1486.0, 3322.0));
            case 13: return mapUvToSubUvSquareFetchTex(tUv, vec4(1530.0, 1725.0, 2010.0, 2076.0));
            case 14: return mapUvToSubUvSquareFetchTex(tUv, vec4(2817.0, 1469.0, 3162.0, 1730.0));
            case 15: return mapUvToSubUvSquareFetchTex(tUv, vec4(2811.0, 1145.0, 3282.0, 1451.0));
            case 16: return mapUvToSubUvSquareFetchTex(tUv, vec4(2809.0, 1017.0, 3073.0, 1135.0));
            case 17: return mapUvToSubUvSquareFetchTex(tUv, vec4(2408.0, 215.0, 2798.0, 491.0));
            case 18: return mapUvToSubUvSquareFetchTex(tUv, vec4(2015.0, 267.0, 2393.0, 525.0));
            case 19: return mapUvToSubUvSquareFetchTex(tUv, vec4(1539.0, 543.0, 1989.0, 603.0));
            case 20: return mapUvToSubUvSquareFetchTex(tUv, vec4(1773.0, 282.0, 1989.0, 507.0));
            case 21: return mapUvToSubUvSquareFetchTex(tUv, vec4(1521.0, 3.0, 1869.0, 228.0));
            case 22: return mapUvToSubUvSquareFetchTex(tUv, vec4(2105.0, 10.0, 2399.0, 246.0));
            case 23: return mapUvToSubUvSquareFetchTex(tUv, vec4(3437.0, 284.0, 3791.0, 584.0));
            case 24: return mapUvToSubUvSquareFetchTex(tUv, vec4(3830.0, 425.0, 4067.0, 614.0));
            case 25: return mapUvToSubUvSquareFetchTex(tUv, vec4(3662.0, 204.0, 3854.0, 345.0));
            case 26: return mapUvToSubUvSquareFetchTex(tUv, vec4(3854.0, 1656.0, 4094.0, 1926.0));
            case 27: return mapUvToSubUvSquareFetchTex(tUv, vec4(3731.0, 1940.0, 4096.0, 2081.0));
            case 28: return mapUvToSubUvSquareFetchTex(tUv, vec4(3596.0, 2862.0, 3839.0, 3096.0));
            case 29: return mapUvToSubUvSquareFetchTex(tUv, vec4(3596.0, 3101.0, 3830.0, 3335.0));
            case 30: return mapUvToSubUvSquareFetchTex(tUv, vec4(3353.0, 3338.0, 3590.0, 3548.0));
            case 31: return mapUvToSubUvSquareFetchTex(tUv, vec4(3386.0, 3612.0, 3662.0, 3840.0));
            case 32: return mapUvToSubUvSquareFetchTex(tUv, vec4(3384.0, 3857.0, 3669.0, 4096.0));
            case 33: return mapUvToSubUvSquareFetchTex(tUv, vec4(3615.0, 3620.0, 3852.0, 3851.0));
            case 34: return mapUvToSubUvSquareFetchTex(tUv, vec4(1043.0, 3323.0, 1541.0, 3578.0));
            case 35: return mapUvToSubUvSquareFetchTex(tUv, vec4(504.0, 3098.0, 1024.0, 3574.0));
            case 36: return mapUvToSubUvSquareFetchTex(tUv, vec4(0.0, 2816.0, 460.0, 3048.0));
            case 37: return mapUvToSubUvSquareFetchTex(tUv, vec4(184.0, 2384.0, 492.0, 2560.0));
            case 38: return mapUvToSubUvSquareFetchTex(tUv, vec4(2544.0, 1301.0, 2700.0, 1471.0));
            case 39: return mapUvToSubUvSquareFetchTex(tUv, vec4(2584.0, 799.0, 2824.0, 1013.0));
            case 40: return mapUvToSubUvSquareFetchTex(tUv, vec4(149.0, 3912.0, 237.0, 4012.0));
            case 41: return mapUvToSubUvSquareFetchTex(tUv, vec4(3082.0, 2873.0, 3290.0, 3063.0));
          
            default: return mapUvToSubUvSquareFetchTex(tUv, vec4(552.0, 2330.0, 772.0, 2470.0));
            }
        }

        if (typeDefID == 1) //house western texture
        {   
            int sizeMax = 3; 

            if (mmodulator(roomID, sizeMax, 0)) return mapUvToSubUvSquareFetchTex(tUv, vec4(1555.0, 5.0,  2188.0, 370.0));
            if (mmodulator(roomID, sizeMax, 1)) return mapUvToSubUvSquareFetchTex(tUv, vec4(1561.0, 371.0, 2074.0, 733.0));
            if (mmodulator(roomID, sizeMax, 2)) return mapUvToSubUvSquareFetchTex(tUv, vec4(1540.0, 732.0, 2166.0, 1016.0));
        }

        if (typeDefID == 2) //house middle east texture
        {
            return GREEN;
        }

      return RED * absinthTime();
    }

    vec2 applyTextureLocationWindowScaleAndOffset(vec2 tUv) {
      if (typeDefID == 0) { //Asian Building
            if (isInRectangle(vec4(2410.,0.,2814.,200.), tUv)) return applyOffset(vec3(200.0, 2410.,0.),tUv);
            if (isInRectangle(vec4(1997.,537.,2394.,761.), tUv)) return applyOffset(vec3(192.0, 1997.,537.),tUv);
            if (isInRectangle(vec4(2824.,798.,2976.,1010.), tUv)) return applyOffset(vec3(220.0, 2824.,798.),tUv);
            if (isInRectangle(vec4(1530.,242.,1730.,372.), tUv)) return applyOffset(vec3(60.0, 1530.,242.),tUv);
            if (isInRectangle(vec4(1534.,616.,1982.,996.), tUv)) return applyOffset(vec3(60.0, 1534.,616.),tUv);
            if (isInRectangle(vec4(1070., 2420., 2140., 2739.), tUv)) return applyOffset(vec3(160.,1070., 2420.),tUv);
            if (isInRectangle(vec4(2808.,1016.,3276.,1136.), tUv)) return applyOffset(vec3(120.0, 2808.,1016.),tUv);
            if (isInRectangle(vec4(3300.,1007.,4096.,1616.), tUv)) return applyOffset(vec3(120.0, 3300.,1007.),tUv);
            if (isInRectangle(vec4(3796.,594.,4096.,930.), tUv)) return applyOffset(vec3(50.0, 3796.,594.),tUv);
            if (isInRectangle(vec4(2450.,1016.,2798.,1196.), tUv)) return applyOffset(vec3(75.0, 2450.,1016.),tUv);
            if (isInRectangle(vec4(1970., 1016., 2440.,1492.), tUv)) return applyOffset(vec3(20.,1970.,1016.),tUv);
            if (isInRectangle(vec4(1530., 1225., 1968., 1450.), tUv)) return applyOffset(vec3(26.,1534.,1225.),tUv);
            if (isInRectangle(vec4(1530., 1015., 1882., 1083.), tUv)) return applyOffset(vec3(60.,1530.,1015.),tUv);
            if (isInRectangle(vec4(1530., 1075., 1607., 1224.), tUv)) return applyOffset(vec3(40.,1530.,1075.),tUv);
            if (isInRectangle(vec4(1530., 1454., 1860., 1714.), tUv)) return applyOffset(vec3(50.,1530., 1454.),tUv);
            if (isInRectangle(vec4(1865., 1515., 2079., 1714.), tUv)) return applyOffset(vec3(35.,1865., 1515.),tUv);
            if (isInRectangle(vec4(2813., 1742., 3173., 2081.), tUv)) return applyOffset(vec3(55.,2813., 1742.),tUv);
        }

      if (typeDefID == 1) { //western
        if (isInRectangle(vec4(1540., 1029., 2811., 2043.), tUv)) return applyOffset(vec3(325., 1540., 1029.), tUv);
        if (isInRectangle(vec4(1839., 2049., 3540., 2325.), tUv)) return applyOffset(vec3(432., 1839., 2049.), tUv);
        if (isInRectangle(vec4(1989., 2583., 3558., 2871.), tUv)) return applyOffset(vec3(408., 1989., 2583.), tUv);
         }

      if (typeDefID == 2) { //arab
        if (isInRectangle(vec4(1852.,2048.,3558.,2858.), tUv)) return applyOffset(vec3(300.0,1852.,2048.), tUv);
      }

      return applyOffset(vec3(4096./25.0, 0, 0), tUv);
    }

    vec4 windowLightColor(int index) {
      vec3 light_colors[] = {
        vec3(0.04f, 0.9f, 0.93f), //Amber / pink
        vec3(0.055f, 0.95f, 0.93f), //Slightly brighter amber 
        vec3(0.08f, 0.7f, 0.93f), //Very pale amber
        vec3(0.07f, 0.9f, 0.93f), //Very pale orange
        vec3(0.1f, 0.9f, 0.85f), //Peach
        vec3(0.13f, 0.9f, 0.93f), //Pale Yellow
        vec3(0.15f, 0.9f, 0.93f), //Yellow
        vec3(0.17f, 1.0f, 0.85f), //Saturated Yellow
        vec3(0.55f, 0.9f, 0.93f), //Cyan
        vec3(0.55f, 0.9f, 0.93f), //Cyan - pale, almost white
        vec3(0.6f, 0.9f, 0.93f), //Pale blue
        vec3(0.65f, 0.9f, 0.93f), //Pale Blue II, The Palening
        vec3(0.65f, 0.4f, 0.99f), //Pure white. Bo-ring.
        vec3(0.65f, 0.0f, 0.8f), //Dimmer white.
        vec3(0.65f, 0.0f, 0.6f), //Dimmest white.
      };

      index = int( mod(index, 15));
      return hslToRgb(light_colors[index].r, light_colors[index].g, light_colors[index].b);

    }

    //Makes all neon-advertisments go uniluminated simultanously over one building
    //Not ideal, should be per piece
    float GetRandomFlickerFactor() {
      float detMod = mod(unitID, 150.0);
      float flickerFactor = mod(time + unitID, detMod);
      if (flickerFactor < 1.0) return flickerFactor;
      return 1.0;
    }


    vec4 getBackWallTexture(vec2 tUv, int roomID) {
      if (typeDefID == 0) { //Asian Building
        int sizeMax = 64;
        int index = int(mod(roomID, sizeMax));
        switch(index)
        {
            case 0:  return mapUvToSubUvSquareFetchTex(tUv, vec4(2810.0, 1466.0, 3167.0, 1724.0));
            case 1:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1547.0, 3102.0, 2039.0, 3477.0));
            case 2:  return mapUvToSubUvSquareFetchTex(tUv, vec4(2046.0, 810.0, 2282.0, 990.0));
            case 3:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1035.0, 2051.0, 1452.0, 2297.0));
            case 4:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1463.0, 2088.0, 1991.0, 2292.0));
            case 5:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1200.0, 2424.0, 1452.0, 2571.0));
            case 6:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1260.0, 2577.0, 1503.0, 2736.0));
            case 7:  return mapUvToSubUvSquareFetchTex(tUv, vec4(1260.0, 2577.0, 1503.0, 2736.0));
            case 8:  return mapUvToSubUvSquareFetchTex(tUv, vec4(2565.0, 2294.0, 2793.0, 2447.0));
            case 9:  return mapUvToSubUvSquareFetchTex(tUv, vec4(2115.0, 1514.0, 2352.0, 1703.0));
            case 10: return mapUvToSubUvSquareFetchTex(tUv, vec4(2466.0, 1481.0, 2742.0, 1655.0));
            case 11: return mapUvToSubUvSquareFetchTex(tUv, vec4(3175.0, 3691.0, 3301.0, 3773.0));
            case 12: return mapUvToSubUvSquareFetchTex(tUv, vec4(3169.0, 3587.0, 3319.0, 3699.0));
            case 13: return mapUvToSubUvSquareFetchTex(tUv, vec4(3725.0, 2082.0, 4096.0, 2337.0));
            case 14: return mapUvToSubUvSquareFetchTex(tUv, vec4(2987.0, 1554.0, 3161.0, 1725.0));
            case 15: return mapUvToSubUvSquareFetchTex(tUv, vec4(0.0, 2123.0, 191.0, 2348.0));
            case 16: return mapUvToSubUvSquareFetchTex(tUv, vec4(0.0, 827.0, 332.0, 1136.0));
            case 17: return mapUvToSubUvSquareFetchTex(tUv, vec4(710.0, 0.0, 957.0, 105.0));
            case 18: return mapUvToSubUvSquareFetchTex(tUv, vec4(2706.0, 3071.0, 3129.0, 3332.0));
            case 19: return mapUvToSubUvSquareFetchTex(tUv, vec4(2105.0, 1867.0, 2291.0, 1923.0));
            case 20: return mapUvToSubUvSquareFetchTex(tUv, vec4(2107.0, 1925.0, 2287.0, 2080.0));
            case 21: return mapUvToSubUvSquareFetchTex(tUv, vec4(2304.0, 2518.0, 2624.0, 2742.0));
            case 22: return  mapUvToSubUvSquareFetchTex(tUv, vec4(3560.0, 1172.0, 3748.0, 1316.0));
            case 23: return mapUvToSubUvSquareFetchTex(tUv, vec4(3753.0, 1022.0, 3915.0, 1220.0));
            case 24: return mapUvToSubUvSquareFetchTex(tUv, vec4(2667.0, 2667.0, 2895.0, 2868.0));
            case 25: return mapUvToSubUvSquareFetchTex(tUv, vec4(1527.0, 1727.0, 2001.0, 2081.0));
            case 26: return mapUvToSubUvSquareFetchTex(tUv, vec4(437.0, 144.0, 741.0, 269.0));
            case 27: return mapUvToSubUvSquareFetchTex(tUv, vec4(3126.0, 232.0, 3245.0, 307.0));
            case 28: return  mapUvToSubUvSquareFetchTex(tUv, vec4(3186.0, 592.0, 3322.0, 748.0));
            case 29: return mapUvToSubUvSquareFetchTex(tUv, vec4(2150.0, 443.0, 2399.0, 755.0));
            case 30: return mapUvToSubUvSquareFetchTex(tUv, vec4(1761.0, 237.0, 1992.0, 609.0));
            case 31: return mapUvToSubUvSquareFetchTex(tUv, vec4(215.0, 3513.0, 345.0, 3593.0));
            case 32: return mapUvToSubUvSquareFetchTex(tUv, vec4(3622.0, 3615.0, 3851.0, 3848.0));
            default : return getWallTexture(tUv, roomID);
        }
      }

      if (typeDefID == 1) { //house western texture
         int sizeMax = 4;
         if (mmodulator(roomID, sizeMax, 0)) return mapUvToSubUvSquareFetchTex(tUv,  vec4(1555.0, 5.0,   2188.0, 370.0));
         if (mmodulator(roomID, sizeMax, 1)) return mapUvToSubUvSquareFetchTex(tUv,  vec4(1561.0, 371.0,  2074.0, 733.0));
         if (mmodulator(roomID, sizeMax, 2))  return mapUvToSubUvSquareFetchTex(tUv, vec4(1540.0, 732.0,  2166.0, 1016.0));
         if (mmodulator(roomID, sizeMax, 3)) return getWallTexture(tUv, roomID);

      }

      if (typeDefID == 2) {
        //house middle east texture

      }

      return vec4(1.0, 0, 0, 1.0);
    }

    vec4 getCeilingTexture(vec2 tUv, int roomID) 
    {
      if (typeDefID == 0)  //Asian Building
      {
        int sizeMax = 5;
        int index = int(mod(roomID, sizeMax));
        switch(index){
         case 0:return mapUvToSubUvSquareFetchTex(tUv, vec4(2050.0, 3592.0, 2564.0, 4096.0));
         case 1:return mapUvToSubUvSquareFetchTex(tUv, vec4(1922.0, 242.0, 1994.0, 310.0));
         case 2:return mapUvToSubUvSquareFetchTex(tUv, vec4(2443.0, 1204.0, 2672.0, 1436.0));
         case 3:return mapUvToSubUvSquareFetchTex(tUv, vec4(1542.0, 544.0, 1974.0, 610.0));
         case 4:return mapUvToSubUvSquareFetchTex(tUv, vec4(2407.0, 276.0, 2791.0, 422.0));
         case 5: return mapUvToSubUvSquareFetchTex(tUv, vec4(187.0, 1653.0, 321.0, 1797.0));
         default: return mapUvToSubUvSquareFetchTex(tUv, vec4(1767.0, 244.0, 1992.0, 532.0));
          }
    }

      if (typeDefID == 1)  //house western texture
      {       
        return mapUvToSubUvSquareFetchTex(tUv, vec4(1424.0, 3588.0, 1647.0, 3806.0));
      }

      if (typeDefID == 2)        //house middle east texture
      {
        return GREEN;
      }

      return RED;
    }

    vec4 getFloorTexture(vec2 tUv, int roomID)
    {
      if (typeDefID == 0) //Asian Building
      {
        int sizeMax = 32;
        int index = int(mod(roomID, sizeMax));
        switch(index){
            case 0: return mapUvToSubUvSquareFetchTex(tUv, vec4(1425.0, 3588.0, 1645.0, 3806.0));    
            case 1: return mapUvToSubUvSquareFetchTex(tUv, vec4(1651., 3586., 1841., 3793.));
            case 2: return mapUvToSubUvSquareFetchTex(tUv, vec4(   1840., 3586., 2042., 3786.));
            case 3: return mapUvToSubUvSquareFetchTex(tUv, vec4(   1850., 3791., 2048., 3985.));
            case 4: return mapUvToSubUvSquareFetchTex(tUv, vec4(241.0, 3758.0, 377.0, 3900.0));
            case 5: return mapUvToSubUvSquareFetchTex(tUv, vec4(3386.0, 3612.0, 3662.0, 3840.0));
            case 6: return mapUvToSubUvSquareFetchTex(tUv, vec4(3384.0, 3857.0, 3669.0, 4096.0));
            case 7: return mapUvToSubUvSquareFetchTex(tUv, vec4(3615.0, 3620.0, 3852.0, 3851.0));
            case 8: return mapUvToSubUvSquareFetchTex(tUv, vec4(2544.0, 1301.0, 2700.0, 1471.0));
            case 9:return mapUvToSubUvSquareFetchTex(tUv, vec4(3099.0, 0.0, 3415.0, 220.0));
            case 10:return mapUvToSubUvSquareFetchTex(tUv, vec4(3527.0, 1319.0, 3779.0, 1571.0));
            case 11: return mapUvToSubUvSquareFetchTex(tUv, vec4(3698.0, 3705.0, 4004.0, 4011.0));
            case 12: return mapUvToSubUvSquareFetchTex(tUv, vec4(3680.0, 2858.0, 4076.0, 3155.0));
            case 13: return mapUvToSubUvSquareFetchTex(tUv, vec4(1359.0, 3814.0, 1497.0, 3948.0));
            case 14:return mapUvToSubUvSquareFetchTex(tUv, vec4(5.0, 3760.0, 233.0, 3926.0));
            case 15: return mapUvToSubUvSquareFetchTex(tUv, vec4(394.0, 3663.0, 615.0, 3879.0));
            case 16: return mapUvToSubUvSquareFetchTex(tUv, vec4(246.0, 3767.0, 379.0, 3899.0));
            case 17: return mapUvToSubUvSquareFetchTex(tUv, vec4(3456.0, 2258.0, 3714.0, 2429.0));
            case 18: return mapUvToSubUvSquareFetchTex(tUv, vec4(3432.0, 2453.0, 3720.0, 2840.0));
            case 19: return mapUvToSubUvSquareFetchTex(tUv, vec4(2072.0, 3098.0, 2534.0, 3566.0));
            case 20: return mapUvToSubUvSquareFetchTex(tUv, vec4(2072.0, 3098.0, 2534.0, 3566.0));
            case 21: return mapUvToSubUvSquareFetchTex(tUv, vec4(3335.0, 3568.0, 3601.0, 3820.0));
        default: return mapUvToSubUvSquareFetchTex(tUv,   vec4(3436.0, 2458.0,  4082.0, 2810.0));
      }
      }

      if (typeDefID == 1)  //house western texture
       {      
        return mapUvToSubUvSquareFetchTex(tUv,  vec4(1851.0, 3792.0, 2048.0, 3990.0));
      }

      if (typeDefID == 2) //house middle east texture
       {
       return BLUE;
      }

      return BLACK;
    }


    vec4 getFurniturePeopleTexture(vec2 tUv) {
      if (typeDefID == 0) { //Asian Building
        //TODO Create Silouttes and Furniture map and add to tex2
        return vec4(0, 0, 0, 0);
      }

      if (typeDefID == 1) {
        //house western texture
        //TODO
        return vec4(0, 0, 0, 0);
      }

      if (typeDefID == 2) {
        //house middle east texture

      }

      return vec4(0.5, 0.5, 0.5, 1.0);
    }

////</Config >//////////////////////////////////////////////////////////////////////////////////////


    bool IntersectBox(in Ray r, in AABB aabb, out float t0, out float t1)
    {
        vec3 invR = 1.0 / r.Dir;
        vec3 tbot = invR * (aabb.Min - r.Origin);
        vec3 ttop = invR * (aabb.Max - r.Origin);
        vec3 tmin = min(ttop, tbot);
        vec3 tmax = max(ttop, tbot);
        vec2 t = max(tmin.xx, tmin.yz);
        t0 = max(0.,max(t.x, t.y));
        t  = min(tmax.xx, tmax.yz);
        t1 = min(t.x, t.y);
        //return (t0 <= t1) && (t1 >= 0.);
        return (abs(t0) <= t1);
    }



    vec4 projectionWindow(vec2 tuv ) 
    {
      int roomID = int(floor(tuv.x*tuv.y));
      vec4 PixelColResult = vec4(0., 0., 0., 0.);
      vec3 interior;
      switch(typeDefID)
      {
        case 0: //asian
            interior = asian_interior; break;
        case 1: //western
            interior = western_interior;break;
        case 2: // arab
            interior = arab_interior; break;
        default:
            interior = asian_interior; break;
      }

      

      // Pixel position
      vec3 pixel = vec3(tuv.x, tuv.y, 0.0f);
      // apply tiling

      // eyePos position
      AABB box;
      box.Min = vMinima;
      box.Max = vMaxima;
      float t1, t2;   
      Ray r;
      r.Origin = eyePos;
      r.Dir = worldPos - eyePos;  
      if (!IntersectBox(r, box, t1, t2))  
      {
          return vec4(0.);
      }


      t1 = clamp(t1, 0.0, 1.0);
      t2 = clamp(t2, 0.0, 1.0);
      vec3 startPos = r.Dir * t1 + eyePos;
      vec3 endPos   = r.Dir * t2 + eyePos;
      pixelDir = normalize(startPos - endPos);


      // Up vector
      vec3 up = vec3(0.0f, 1.0f, 0.0f);

      // Right vector
      vec3 right = vec3(1.0f, 0.0f, 0.0f);

      // View direction
      vec3 viewDir = pixel - eyePos;

      // Floor position
      vec3 floor;
      floor.y = 0.0f;
      floor.z = ((pixel.y / eyePos.y) * eyePos.z) / (1.0f - (pixel.y / eyePos.y));
      floor.x = (pixel.x - eyePos.x + (eyePos.z / (eyePos.z + floor.z)) * eyePos.x) / (eyePos.z / (eyePos.z + floor.z));

      // Ceiling position
      vec3 ceiling;
      ceiling.y = 1.0f;
      ceiling.z = ((1.0f - pixel.y) / (1.0f - eyePos.y)) * eyePos.z / (1.0f - ((1.0f - pixel.y) / (1.0f - eyePos.y)));
      ceiling.x = eyePos.x + (pixel.x - eyePos.x) * (ceiling.z + eyePos.z) / eyePos.z;

      // Left Wall position
      vec3 leftWall;
      leftWall.x = 0.0f;
      leftWall.z = ((pixel.x / eyePos.x) * eyePos.z) / (1.0f - (pixel.x / eyePos.x));
      leftWall.y = (pixel.y - (leftWall.z / (leftWall.z + eyePos.z)) * eyePos.y) / (1.0f - leftWall.z / (leftWall.z + eyePos.z));

      // Right Wall position
      vec3 rightWall;
      rightWall.x = 1.0f;
      rightWall.z = (((1.0f - pixel.x) / (1.0f - eyePos.x)) * eyePos.z) / (1.0f - (1.0f - pixel.x) / (1.0f - eyePos.x));
      rightWall.y = (pixel.y - (rightWall.z / (rightWall.z + eyePos.z)) * eyePos.y) / (1.0f - rightWall.z / (rightWall.z + eyePos.z));;

      // Back Wall position
      vec3 backWall;
      backWall.z = interior.z;
      backWall.x = (pixel.x - eyePos.x) * (eyePos.z + interior.z) / (eyePos.z) + eyePos.x;
      backWall.y = (pixel.y - eyePos.y) * (eyePos.z + interior.z) / (eyePos.z) + eyePos.y;

      // Compute intersecting plane
      bool isCeiling = dot(viewDir, up) > 0.0f;
      bool isRightWall = dot(viewDir, right) > 0.0f;

      float leftRightWallsDepth = isRightWall ? rightWall.z : leftWall.z;
      float floorCeilingDepth = isCeiling ? ceiling.z : floor.z;

      bool isWallsClosest = leftRightWallsDepth < floorCeilingDepth;
      float closestHit = isWallsClosest ? leftRightWallsDepth : floorCeilingDepth;

      bool isBackClosest = interior.z < closestHit;

      // Sample texture
      if (isBackClosest) {
        PixelColResult = getBackWallTexture(backWall.xy, roomID);
      } else if (isWallsClosest) {
        if (isRightWall) {
          PixelColResult = getWallTexture(rightWall.zy, roomID);
        } else {
          PixelColResult = getWallTexture(leftWall.zy, roomID);
        }
      } else {
        if (isCeiling) {
          PixelColResult = getCeilingTexture(ceiling.xz, roomID);
        } else {
          PixelColResult = getFloorTexture(floor.xz, roomID);
        }
      }

      // Chair Layer position
      vec3 chairLayer;
      chairLayer.z = interior.z * 0.5f;
      chairLayer.x = (pixel.x - eyePos.x) * (eyePos.z + interior.z * 0.5f) / (eyePos.z) + eyePos.x;
      chairLayer.y = (pixel.y - eyePos.y) * (eyePos.z + interior.z * 0.5f) / (eyePos.z) + eyePos.y;
      bool isChairClosest = interior.z * 0.5f < closestHit;

      if (isChairClosest) {
        //borrowed from https://www.shadertoy.com/view/XfBfDW
        float p = 0.05; // Percition
        float a = mod(time, 3.0); // Amplitude
        float i = time;
        vec3 col = vec3(step(abs(0.5 * sin(-i + tuv.x) - tuv.y * a), p),
          step(abs(0.5 * sin(i + tuv.x) - tuv.y * a), p),
          step(abs(0.5 * sin(i + tuv.x) + 0.5 * sin(-i + tuv.x) - tuv.y * a), p));

        chairLayer.x = chairLayer.x + sin(time);
        vec4 chairTexture = getFurniturePeopleTexture(chairLayer.xy);
        chairTexture.a = col.r;
        PixelColResult = mix(PixelColResult, chairTexture, chairTexture.a);
      }

      // random "lighting" per room
      vec2 room = ceil(tuv * interior.xy);
    
      float slowShift = (time / 1000.0);
      PixelColResult.rgb *= mix(0.5f, 1.5f, rand(roomID + slowShift));
      return PixelColResult;

    }

    void main()
    {
      //our original texcoord for this fragment
      uv = gl_FragCoord.xy / viewPortSize;

      vec4 orgCol = texture(tex1, uv);
      vec4 selIluCol = texture(tex2, uv);
      mapDepth = texture2D(mapDepthTex,uv).rrrr;
      modelDepth = texture2D(modelDepthTex,uv).rrrr;
      depthAtPixel =  texture2D(dephtCopyTex, uv);
      worldPos = GetWorldPosAtUV(uv, depthAtPixel.r);
      selIluCol.a = 1.0;

      //Preparation phase end
      if (selIluCol.r > 0) //self-ilumination is active
      {
        gl_FragColor = selIluCol;
        return; //TODO Debug
        if (selIluCol.b > 0) //window 
        {
          //stable over time
          vec2 scaledUvs = applyTextureLocationWindowScaleAndOffset(uv);
          int windowID = getPseudoRandom(uv.x + uv.y);

          //flickers over time 
          bool isCurrentlyIluminated = mod(getPseudoRandom(windowID + timepercent * 4.0), 3.0) == 2.0;
          float currentlyIluminatedFactor = 1.0;
          if (!isCurrentlyIluminated) currentlyIluminatedFactor = 1.0 / (mod(float(windowID), 5.0));

          //Get window color similar to shamus young algo
          vec4 windowTintColor = windowLightColor(unitID);

          //projection windows

          vec4 projWindow = projectionWindow(scaledUVs);
          //project window ala spiderman
          vec4 windowColor = windowTintColor * colToBW(selIluCol);
          gl_FragColor = windowColor * currentlyIluminatedFactor;
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