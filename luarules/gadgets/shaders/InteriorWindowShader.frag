    #version 150 compatibility
    #line 20002
    //Fragmentshader
    // Set the precision for data types used in this shader
    #define RED vec4(1.0, 0.0, 0.0, 0.5)
    #define GREEN vec4(0.0, 1.0, 0.0, 0.5)
    #define BLUE vec4(0.0, 0.0, 1.0, 0.5)
    #define NONE vec4(0.)
    #define PI 3.14159 f

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
    uniform int typeDefID;
    // Varyings passed from the vertex shader
    in Data {

      vec3 vPixelPositionWorld;
      vec3 normal;
      vec3 sphericalNormal;
      vec2 orgColUv;
    };

    vec4 colToBW(vec4 col) {
      float avg = sqrt(col.r * col.r + col.g * col.g + col.b * col.b);
      return vec4(vec3(avg), col.a);
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

    float rand(float v) {
      return fract(sin(v * 30.11));
    }

    vec3 Lerp(vec3 start_value, vec3 end_value, float pct) {
      return (start_value + (end_value - start_value) * pct);
    }

    float getPseudoRandom(float startHash) {
      return fract(sin(dot(vec2(startHash), vec2(12.9898, 4.1414)))) * 43758.5453;
    }

    //Makes all neon-advertisments go uniluminated simultanously over one building
    //Not ideal, should be per piece
    float GetRandomFlickerFactor() {
      float detMod = mod(unitID, 150.0);
      float flickerFactor = mod(time + unitID, detMod);
      if (flickerFactor < 1.0) return flickerFactor;
      return 1.0;
    }

    // Interior room count (width, height, depth)
    const vec3 asian_interior = vec3(50.0 f, 50.0 f, 1.0 f);
    const vec3 arab_interior = vec3(5.0 f, 5.0 f, 1.0 f);
    const vec3 western_interior = vec3(5.0 f, 5.0 f, 1.0 f);


    vec4 getBackWallTexture(vec2 uv)
    {
        if (typeDefID == 0)
        { //Asian Building
            return mapUvToSubUvSquare(uv,
                vec2(2810.0/4096.0, 1466.0/4096.0),
                vec2(3167.0/4096.0, 1724.0/4096.0));
        }

        if (typeDefID==  1)
        {//house western texture
            return mapUvToSubUvSquare(uv,
                vec2(1555.0/4096.0, 5.0/4096.0),
                vec2(2188.0/4096.0, 370.0/4096.0));
            /*
           return mapUvToSubUvSquare(uv,
                vec2(1561.0/4096.0, 371.0/4096.0),
                vec2(2074.0/4096.0, 733.0/4096.0));
         
            return mapUvToSubUvSquare(uv,
                vec2(1540.0/4096.0, 732.0/4096.0),
                vec2(2166.0/4096.0, 1016.0/4096.0));
         
            */
        }

        if (typeDefID ==  2)
        {
         //house middle east texture

        }

        return vec4(1.0, 0, 0, 1.0);
    }


    vec4 getCeilingTexture(vec2 uv)
    {
        if (typeDefID == 0)
        { //Asian Building
             return mapUvToSubUvSquare(uv,
                vec2(2050.0/4096.0, 3592.0/4096.0),
                vec2(2564.0/4096.0, 4096.0/4096.0));
        }

        if (typeDefID==  1)
        {
         //house western texture
            return mapUvToSubUvSquare(uv,
                vec2(1424.0/4096.0, 3588.0/4096.0),
                vec2(1647.0/4096.0, 3806.0/4096.0));
         
        }

        if (typeDefID ==  2)
        {
         //house middle east texture

        }

        return vec4(1.0, 1.0, 1.0, 1.0);
    }

    vec4 getFloorTexture(vec2 uv)
    {
        if (typeDefID == 0)
        { //Asian Building
            return mapUvToSubUvSquare(uv,
                vec2(3436.0/4096.0, 2458.0/4096.0),
                vec2(4082.0/4096.0, 2810.0/4096.0));
        }

        if (typeDefID==  1)
        {
         //house western texture
           return mapUvToSubUvSquare(uv,
                vec2(1851.0/4096.0, 3792.0/4096.0),
                vec2(2048.0/4096.0, 3990.0/4096.0));
        

        }

        if (typeDefID ==  2)
        {
         //house middle east texture

        }

        return vec4(0.0, 1.0, 0, 1.0);
    }


     vec4 getLeftWallTexture(vec2 uv)
    {
        if (typeDefID == 0)
        { //Asian Building
            return mapUvToSubUvSquare(uv,
                vec2(1546.0/4096.0, 3097.0/4096.0),
                vec2(1856.0/4096.0, 3567.0/4096.0));
        
        }

        if (typeDefID==  1)
        {
         //house western texture
            return mapUvToSubUvSquare(uv,
                vec2(1555.0/4096.0, 5.0/4096.0),
                vec2(2188.0/4096.0, 370.0/4096.0));
            /*
           return mapUvToSubUvSquare(uv,
                vec2(1561.0/4096.0, 371.0/4096.0),
                vec2(2074.0/4096.0, 733.0/4096.0));
         
            return mapUvToSubUvSquare(uv,
                vec2(1540.0/4096.0, 732.0/4096.0),
                vec2(2166.0/4096.0, 1016.0/4096.0));
         
            */
        }

        if (typeDefID ==  2)
        {
         //house middle east texture

        }

        return vec4(0.0, 0.0, 1.0, 1.0);
    }


    vec4 getRightWallTexture(vec2 uv)
    {
        if (typeDefID == 0)
        { //Asian Building
          return mapUvToSubUvSquare(uv,
                vec2(1546.0/4096.0, 3097.0/4096.0),
                vec2(1856.0/4096.0, 3567.0/4096.0));
        }

        if (typeDefID==  1)
        {
         //house western texture
            return mapUvToSubUvSquare(uv,
                vec2(1555.0/4096.0, 5.0/4096.0),
                vec2(2188.0/4096.0, 370.0/4096.0));
            /*
           return mapUvToSubUvSquare(uv,
                vec2(1561.0/4096.0, 371.0/4096.0),
                vec2(2074.0/4096.0, 733.0/4096.0));
         
            return mapUvToSubUvSquare(uv,
                vec2(1540.0/4096.0, 732.0/4096.0),
                vec2(2166.0/4096.0, 1016.0/4096.0));
         
            */
        }

        if (typeDefID ==  2)
        {
         //house middle east texture

        }

        return vec4(1.0, 0.0, 1.0, 1.0);
    }

    vec4 getFurniturePeopleTexture(vec2 uv)
    {
        if (typeDefID == 0)
        { //Asian Building
            //TODO Create Silouttes and Furniture map and add to tex2
            return vec4(0,0,0,0);
        }

        if (typeDefID==  1)
        {
         //house western texture
            //TODO
            return vec4(0,0,0,0);
        }

        if (typeDefID ==  2)
        {
         //house middle east texture

        }

        return vec4(0.5, 0.5, 0.5, 1.0);
    }

    vec2 mapUvToSubUvSquare( vec2 uv, vec2 start, vec2 end)
    {
        vec2 scaledUVs = abs(start-end);
        scaledUVs = mod(scaledUVs * uv, dimension);
        return texture(tex1, scaledUVs);
    }


    vec4 projectionWindow(vec2 uv) {

      vec4 PixelColResult = new v4(0, 0, 0, 0);

      // Pixel position
      vec3 pixel = vec3(uv.x, uv.y, 0.0 f);
      // apply tiling
      pixel = fract(pixel * interior);

      // Camera position
      //vec3 camera = vec3(1.0f, 1.0f, 1.0f);
      vec3 camera = vec3(0.5 f + cos(iTime * 0.5 f) * 0.5 f, 0.5 f + sin(iTime * 0.5 f) * 0.5 f, 1.0 f);
      // apply tiling offset
      camera.xy -= (uv - pixel.xy);

      // Up vector
      vec3 up = vec3(0.0 f, 1.0 f, 0.0 f);

      // Right vector
      vec3 right = vec3(1.0 f, 0.0 f, 0.0 f);

      // View direction
      vec3 viewDir = pixel - camera;

      // Floor position
      vec3 floor;
      floor.y = 0.0 f;
      floor.z = ((pixel.y / camera.y) * camera.z) / (1.0 f - (pixel.y / camera.y));
      floor.x = (pixel.x - camera.x + (camera.z / (camera.z + floor.z)) * camera.x) / (camera.z / (camera.z + floor.z));

      // Ceiling position
      vec3 ceiling;
      ceiling.y = 1.0 f;
      ceiling.z = ((1.0 f - pixel.y) / (1.0 f - camera.y)) * camera.z / (1.0 f - ((1.0 f - pixel.y) / (1.0 f - camera.y)));
      ceiling.x = camera.x + (pixel.x - camera.x) * (ceiling.z + camera.z) / camera.z;

      // Left Wall position
      vec3 leftWall;
      leftWall.x = 0.0 f;
      leftWall.z = ((pixel.x / camera.x) * camera.z) / (1.0 f - (pixel.x / camera.x));
      leftWall.y = (pixel.y - (leftWall.z / (leftWall.z + camera.z)) * camera.y) / (1.0 f - leftWall.z / (leftWall.z + camera.z));

      // Right Wall position
      vec3 rightWall;
      rightWall.x = 1.0 f;
      rightWall.z = (((1.0 f - pixel.x) / (1.0 f - camera.x)) * camera.z) / (1.0 f - (1.0 f - pixel.x) / (1.0 f - camera.x));
      rightWall.y = (pixel.y - (rightWall.z / (rightWall.z + camera.z)) * camera.y) / (1.0 f - rightWall.z / (rightWall.z + camera.z));;

      // Back Wall position
      vec3 backWall;
      backWall.z = interior.z;
      backWall.x = (pixel.x - camera.x) * (camera.z + interior.z) / (camera.z) + camera.x;
      backWall.y = (pixel.y - camera.y) * (camera.z + interior.z) / (camera.z) + camera.y;

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
        PixelColResult = getBackWallTexture(backWall.xy);
      } else if (isWallsClosest) {
        if (isRightWall) {
          PixelColResult = getRightWallTexture(rightWall.zy);
        } else {
          PixelColResult = getLeftWallTexture(leftWall.zy);
        }
      } else {
        if (isCeiling) {
          PixelColResult = getCeilingTexture(ceiling.xz);
        } else {
          PixelColResult = getFloorTexture(floor.xz);
        }
      }

      // Chair Layer position
      vec3 chairLayer;
      chairLayer.z = interior.z * 0.5 f;
      chairLayer.x = (pixel.x - camera.x) * (camera.z + interior.z * 0.5 f) / (camera.z) + camera.x;
      chairLayer.y = (pixel.y - camera.y) * (camera.z + interior.z * 0.5 f) / (camera.z) + camera.y;
      bool isChairClosest = interior.z * 0.5 f < closestHit;

      if (isChairClosest) {
        //borrowed from https://www.shadertoy.com/view/XfBfDW
        float p = 0.05; // Percition
        float a = mod(iTime, 3.0); // Amplitude
        float i = iTime;
        vec3 col = vec3(step(abs(0.5 * sin(-i + uv.x) - uv.y * a), p),
          step(abs(0.5 * sin(i + uv.x) - uv.y * a), p),
          step(abs(0.5 * sin(i + uv.x) + 0.5 * sin(-i + uv.x) - uv.y * a), p));

        chairLayer.x = chairLayer.x + sin(iTime);
        vec4 chairTexture = getFurniturePeopleTexture(chairLayer.xy);
        chairTexture.a = col.r;
        PixelColResult = mix(PixelColResult, chairTexture, chairTexture.a);
      }

      // random "lighting" per room
      vec2 room = ceil(uv * interior.xy);
      float roomID = room.y * interior.x + room.x;
      float slowShift = (iTime / 1000.0);
      PixelColResult.rgb *= mix(0.5 f, 1.5 f, rand(roomID + slowShift));
      return PixelColResult;

    }

    void main() {

      //our original texcoord for this fragment
      vec2 uv = gl_FragCoord.xy / viewPortSize;

      vec4 orgCol = texture(tex1, orgColUv);
      vec4 selIluCol = texture(tex2, orgColUv);
      selfIluCol.a = 1.0;
      if (selIluCol.r > 0) //self-ilumination is active
      {
        gl_FragColor = selIluCol;
        return; //TODO Debug
        if (selIluCol.b > 0) //window 
        {
          //stable over time
          int windowID = getPseudoRandom(uv.x + uv.y);

          //flickers over time 
          isCurrentlyIluminated = mod(getPseudoRandom(windowID + timepercent * 4.0));
          float currentlyIluminatedFactor = 1.0;
          if (!isCurrentlyIluminated) currentlyIluminatedFactor = 1.0 / (mod(float(windowID), 5.0));

          //Get window color similar to shamus young algo
          vec4 windowTintColor = windowLightColor(unitID);

          //projection windows
          vec4 projWindow = projectionWindow();
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