    #version 150 compatibility
    #line 20002
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

    struct Ray 
    {
        vec3 Origin;
        vec3 Dir;
    };
    struct AABB {
        vec3 Min;
        vec3 Max;
    };

    vec2 uv;

    vec4 colToBW(vec4 col) {
      float avg = sqrt(col.r * col.r + col.g * col.g + col.b * col.b);
      return vec4(vec3(avg), col.a);
    }

    float absinthTime()
    {
        return abs(sin(time));
    }

    vec4 hslToRgb(vec3 hsl) {
      float h = hsl.r;
      float s = hsl.g;
      float l = hsl.b;
      vec4 rgba = vec4(0, 0, 0, 1.0);
      float c = (1.0 f - abs(2.0 f * l - 1.0 f)) * s; // Chroma
      float x = c * (1.0 f - abs(mod(h / 60.0 f, 2) - 1.0 f));
      float m = l - c / 2.0 f;

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

////</TOOLING >//////////////////////////////////////////////////////////////////////////////////////
  
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

    vec4 windowLightColor(unsigned int index) {
      vec3 light_colors[] = {
        vec3(0.04 f, 0.9 f, 0.93 f), //Amber / pink
        vec3(0.055 f, 0.95 f, 0.93 f), //Slightly brighter amber 
        vec3(0.08 f, 0.7 f, 0.93 f), //Very pale amber
        vec3(0.07 f, 0.9 f, 0.93 f), //Very pale orange
        vec3(0.1 f, 0.9 f, 0.85 f), //Peach
        vec3(0.13 f, 0.9 f, 0.93 f), //Pale Yellow
        vec3(0.15 f, 0.9 f, 0.93 f), //Yellow
        vec3(0.17 f, 1.0 f, 0.85 f), //Saturated Yellow
        vec3(0.55 f, 0.9 f, 0.93 f), //Cyan
        vec3(0.55 f, 0.9 f, 0.93 f), //Cyan - pale, almost white
        vec3(0.6 f, 0.9 f, 0.93 f), //Pale blue
        vec3(0.65 f, 0.9 f, 0.93 f), //Pale Blue II, The Palening
        vec3(0.65 f, 0.4 f, 0.99 f), //Pure white. Bo-ring.
        vec3(0.65 f, 0.0 f, 0.8 f), //Dimmer white.
        vec3(0.65 f, 0.0 f, 0.6 f), //Dimmest white.
      };

      index = mod(index, 15);
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
        return mapUvToSubUvSquare(tUv,
          vec4(2810.0, 1466.0,
            3167.0, 1724.0));
      }

      if (typeDefID == 1) { //house western texture
         if (mmodulator(roomID, 2, 0)) return mapUvToSubUvSquare(tUv,  vec4(1555.0, 5.0,   2188.0, 370.0));
         if (mmodulator(roomID, 2, 1)) return mapUvToSubUvSquare(tUv,  vec4(   1561.0, 371.0,  2074.0, 733.0));
         if (mmodulator(roomID, 2, 2))  return mapUvToSubUvSquare(tUv, vec4(1540.0, 732.0,  2166.0, 1016.0));

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
        return mapUvToSubUvSquare(tUv, vec4(2050.0, 3592.0, 2564.0, 4096.0));
      }

      if (typeDefID == 1)  //house western texture
      {       
        return mapUvToSubUvSquare(tUv, vec4(1424.0, 3588.0, 1647.0, 3806.0));
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
        return mapUvToSubUvSquare(tUv,   vec4(3436.0, 2458.0,  4082.0, 2810.0));
      }

      if (typeDefID == 1)  //house western texture
       {      
        return mapUvToSubUvSquare(tUv,  vec4(1851.0, 3792.0, 2048.0, 3990.0));
      }

      if (typeDefID == 2) //house middle east texture
       {
       return BLUE;
      }

      return BLACK;
    }

    vec4 getWallTexture(vec2 tUv, int roomID) 
    {
        if (typeDefID == 0) //Asian Building
        { 
            return mapUvToSubUvSquare(tUv, vec4(1546.0, 3097.0, 1856.0, 3567.0));
        }

        if (typeDefID == 1) //house western texture
        {            
            if (mmodulator(roomID, 2, 0)) return mapUvToSubUvSquare(tUv, vec4(1555.0, 5.0,  2188.0, 370.0));
            if (mmodulator(roomID, 2, 1)) return mapUvToSubUvSquare(tUv, vec4(1561.0, 371.0, 2074.0, 733.0));
            if (mmodulator(roomID, 2, 2)) return mapUvToSubUvSquare(tUv, vec4(1540.0, 732.0, 2166.0, 1016.0)
        }

        if (typeDefID == 2) //house middle east texture
        {
            return GREEN;
        }

      return RED * absinthTime();
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

    vec2 mapUvToSubUvSquare(vec2 tUv, vec4 startend) {
      vec2 start = vec2(startend.rg / 4096.0);
      vec2 end = vec2(startend.ba / 4096.0);
      vec2 scaledUVs = abs(start - end);
      scaledUVs = mod(scaledUVs * tUv, dimension);
      return texture(tex1, scaledUVs);
    }

    vec4 projectionWindow(vec2 tuv, int roomID) 
    {
      
      vec4 PixelColResult = new v4(0, 0, 0, 0);

      // Pixel position
      vec3 pixel = vec3(tuv.x, tuv.y, 0.0 f);
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
      vec3 up = vec3(0.0 f, 1.0 f, 0.0 f);

      // Right vector
      vec3 right = vec3(1.0 f, 0.0 f, 0.0 f);

      // View direction
      vec3 viewDir = pixel - eyePos;

      // Floor position
      vec3 floor;
      floor.y = 0.0 f;
      floor.z = ((pixel.y / eyePos.y) * eyePos.z) / (1.0 f - (pixel.y / eyePos.y));
      floor.x = (pixel.x - eyePos.x + (eyePos.z / (eyePos.z + floor.z)) * eyePos.x) / (eyePos.z / (eyePos.z + floor.z));

      // Ceiling position
      vec3 ceiling;
      ceiling.y = 1.0 f;
      ceiling.z = ((1.0 f - pixel.y) / (1.0 f - eyePos.y)) * eyePos.z / (1.0 f - ((1.0 f - pixel.y) / (1.0 f - eyePos.y)));
      ceiling.x = eyePos.x + (pixel.x - eyePos.x) * (ceiling.z + eyePos.z) / eyePos.z;

      // Left Wall position
      vec3 leftWall;
      leftWall.x = 0.0 f;
      leftWall.z = ((pixel.x / eyePos.x) * eyePos.z) / (1.0 f - (pixel.x / eyePos.x));
      leftWall.y = (pixel.y - (leftWall.z / (leftWall.z + eyePos.z)) * eyePos.y) / (1.0 f - leftWall.z / (leftWall.z + eyePos.z));

      // Right Wall position
      vec3 rightWall;
      rightWall.x = 1.0 f;
      rightWall.z = (((1.0 f - pixel.x) / (1.0 f - eyePos.x)) * eyePos.z) / (1.0 f - (1.0 f - pixel.x) / (1.0 f - eyePos.x));
      rightWall.y = (pixel.y - (rightWall.z / (rightWall.z + eyePos.z)) * eyePos.y) / (1.0 f - rightWall.z / (rightWall.z + eyePos.z));;

      // Back Wall position
      vec3 backWall;
      backWall.z = interior.z;
      backWall.x = (pixel.x - eyePos.x) * (eyePos.z + interior.z) / (eyePos.z) + eyePos.x;
      backWall.y = (pixel.y - eyePos.y) * (eyePos.z + interior.z) / (eyePos.z) + eyePos.y;

      // Compute intersecting plane
      bool isCeiling = dot(viewDir, up) > 0.0 f;
      bool isRightWall = dot(viewDir, right) > 0.0 f;

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
      chairLayer.z = interior.z * 0.5 f;
      chairLayer.x = (pixel.x - eyePos.x) * (eyePos.z + interior.z * 0.5 f) / (eyePos.z) + eyePos.x;
      chairLayer.y = (pixel.y - eyePos.y) * (eyePos.z + interior.z * 0.5 f) / (eyePos.z) + eyePos.y;
      bool isChairClosest = interior.z * 0.5 f < closestHit;

      if (isChairClosest) {
        //borrowed from https://www.shadertoy.com/view/XfBfDW
        float p = 0.05; // Percition
        float a = mod(iTime, 3.0); // Amplitude
        float i = iTime;
        vec3 col = vec3(step(abs(0.5 * sin(-i + wUv.x) - wUv.y * a), p),
          step(abs(0.5 * sin(i + wUv.x) - wUv.y * a), p),
          step(abs(0.5 * sin(i + wUv.x) + 0.5 * sin(-i + wUv.x) - wUv.y * a), p));

        chairLayer.x = chairLayer.x + sin(iTime);
        vec4 chairTexture = getFurniturePeopleTexture(chairLayer.xy);
        chairTexture.a = col.r;
        PixelColResult = mix(PixelColResult, chairTexture, chairTexture.a);
      }

      // random "lighting" per room
      vec2 room = ceil(wUv * interior.xy);
      float roomID = room.y * interior.x + room.x;
      float slowShift = (iTime / 1000.0);
      PixelColResult.rgb *= mix(0.5 f, 1.5 f, rand(roomID + slowShift));
      return PixelColResult;

    }

    void main() {

      //our original texcoord for this fragment
      uv = gl_FragCoord.xy / viewPortSize;

      vec4 orgCol = texture(tex1, uv);
      vec4 selIluCol = texture(tex2, uv);
      selfIluCol.a = 1.0;
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
          isCurrentlyIluminated = mod(getPseudoRandom(windowID + timepercent * 4.0));
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