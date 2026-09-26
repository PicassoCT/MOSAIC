// Sparse, analytic impact droplets. No particles, history or additional targets.
// One selected small ripple per coarse cell keeps the gather at 3x3 even as
// ripple diameters shrink. The selected ring and splash share seed and phase.
const float SPLASH_CELL = 3.0 / RAIN_RIPPLE_SCALE;
const float SPLASH_GRAVITY = 64.0;

float splashAge(vec3 seed) {
    float speed = RAIN_RIPPLE_SPEED * 2.0;
    return mod(time * speed - (seed.x + seed.y) * 5.0, 2.0 * PI) / speed;
}

vec3 splashOffset(vec3 normal, vec3 tangent, float age, float speed) {
    return (normal * speed + tangent * 1.5) * age
           - vec3(0.0, 0.5 * SPLASH_GRAVITY * age * age, 0.0);
}

vec4 drawRainSplashback(vec3 surface, vec3 encodedNormal, vec3 rayDir,
                       float sceneDistance, bool isSky) {
    // Derivatives must be evaluated before divergent candidate tests.
    float pixelAngle = max(length(dFdx(rayDir)), length(dFdy(rayDir)));
    vec3 n = encodedNormal * 2.0 - 1.0;
    n /= max(length(n), 0.00001);
    float distanceToSurface = length(surface - eyePos);
    float fade = (1.0 - smoothstep(1200.0, 2600.0, distanceToSurface));
    fade *= smoothstep(0.8, 0.97, n.y);
    // A bounded neighbourhood cannot cover arbitrarily grazing views. Fade
    // before the expanded shell could reach outside the 3x3 cell neighbourhood.
    float facing = dot(n, -rayDir);
    fade *= smoothstep(0.3, 0.5, facing);
    fade *= 1.0-smoothstep(1.0,2.0,pixelAngle*distanceToSurface);
    if (isSky || rainPercent <= 0.0 || depthAtPixel.r >= 0.999999 || fade <= 0.0)
        return NONE;

    // Centre the gather below the middle of the airborne shell. Looking at a
    // 45-degree roof must not miss droplets simply because they project uphill.
    vec3 shellBase = surface - rayDir*(0.56/max(facing,0.3)) - n*0.56;
    vec2 cell = floor(shellBase.xz / SPLASH_CELL);
    float sumAlpha = 0.0;
    vec3 sumRGB = vec3(0.0);
    for (int z = -1; z <= 1; ++z) for (int x = -1; x <= 1; ++x) {
        vec2 candidate = cell + vec2(x, z);
        vec2 rippleCell = candidate*3.0 + floor(hash3(candidate+vec2(17,43)).xy*3.0);
        vec3 seed = hash3(rippleCell);
        // Thin the impacts, not their opacity; the compositor applies rain once.
        if (seed.z > 0.85 * clamp(rainPercent, 0.0, 1.0)) continue;
        float age = splashAge(seed);
        if (age <= 0.0 || age >= 0.375) continue;

        vec2 impactXZ = (rippleCell + seed.xy) / RAIN_RIPPLE_SCALE;
        vec3 impact = vec3(impactXZ.x,
            surface.y - dot(impactXZ - surface.xz, n.xz) / n.y, impactXZ.y);
        vec4 projected = viewProjection * vec4(impact, 1.0);
        if (projected.w <= 0.00001) continue;
        vec3 ndc = projected.xyz / projected.w;
        vec2 sourceUV = ndc.xy * 0.5 + 0.5;
        vec2 margin = 1.5 / viewPortSize;
        if (any(lessThan(sourceUV, margin)) || any(greaterThan(sourceUV, 1.0-margin)) ||
            ndc.z < mix(-1.0, 0.0, clipZeroToOne) || ndc.z > 1.0) continue;
        float sourceDepth = texture2D(dephtCopyTex, sourceUV).r;
        if (sourceDepth >= 0.999999) continue;
        bool ground, unit, puddle, sky;
        vec3 sourceN = GetGroundVertexNormal(sourceUV, ground, unit, puddle, sky)*2.0-1.0;
        sourceN /= max(length(sourceN), 0.00001);
        if (sky || sourceN.y < 0.8 || dot(n, sourceN) < 0.95) continue;
        vec3 sourcePosition = GetWorldPosAtUV(sourceUV, sourceDepth);
        // Plane distance tolerates pixel quantisation on slopes, but rejects a
        // hidden floor/roof or a foreground edge. Never expand an unseen surface.
        float planeTolerance = 0.3 + min(pixelAngle*distanceToSurface,0.5);
        if (abs(dot(sourcePosition-impact, sourceN)) > planeTolerance) continue;
        impact.y = sourcePosition.y - dot(impactXZ-sourcePosition.xz, sourceN.xz)/sourceN.y;
        vec3 tangentX = normalize(vec3(sourceN.y, -sourceN.x, 0.0));
        vec3 tangentZ = cross(sourceN, tangentX);
        for (int j = -1; j < 6; ++j) {
            float angle = seed.z * 31.0 + float(j) * (2.0*PI/3.0);
            vec3 tangent = tangentX*cos(angle) + tangentZ*sin(angle);
            // -1: brief impact core; 0: rebound bead; 1..5: fine outward spray.
            float speed = j == 0 ? 11.0 : 6.0+4.0*fract(seed.x+float(j)*0.37);
            vec3 offset = splashOffset(sourceN, tangent*(j == 0 ? 0.1 : 1.5), age, speed);
            if(j == -1) offset=sourceN*0.06;
            float stage = j == -1 ? 1.0-smoothstep(0.015,0.085,age) : 1.0;
            if(stage<=0.0) continue;
            float height = dot(offset, sourceN);
            if (height <= 0.0) continue;
            vec3 drop = impact + offset;
            // A short water column pinches off into the rebound bead.
            // Closest ray/segment point keeps the jet three-dimensional.
            if(j == 0 && age < 0.11) {
                vec3 base=impact+sourceN*0.04;
                vec3 axis=drop-base;
                vec3 origin=eyePos-base;
                float ar=dot(axis,rayDir);
                float q=clamp((dot(axis,origin)-ar*dot(rayDir,origin)) /
                              max(dot(axis,axis)-ar*ar,0.00001),0.0,1.0);
                drop=mix(base,drop,q);
            }
            float t = dot(drop-eyePos, rayDir);
            if (t <= 0.0 || t >= sceneDistance) continue;
            float separation = length(eyePos + rayDir*t - drop);
            float footprint = clamp(pixelAngle*t, 0.025, 0.8);
            float radius = j == -1 ? 0.22 : (j == 0 ? 0.13 : 0.055+0.035*fract(seed.y+float(j)*0.41));
            float coverage = (1.0-smoothstep(radius, radius+footprint, separation))
                             * radius/(radius+footprint);
            coverage *= 1.8 * fade * stage * (j == -1 ? 1.0 : smoothstep(0.0, 0.10, height))
                        * smoothstep(0.0, 0.12, sceneDistance-t);
            if (coverage <= 0.0001) continue;
            vec3 tint = mix(sunCol*DAY_RAIN_HIGH_COL.rgb,
                            sunCol*NIGHT_RAIN_HIGH_COL.rgb, getDayPercent());
            tint = max(tint,vec3(0)) + max(skyCol,vec3(0))*0.35;
            // Raise visibility without a per-channel grey floor bleaching the
            // atmosphere's blue night/orange day tint. Zero light stays black.
            float brightness = dot(tint,vec3(0.2126,0.7152,0.0722));
            tint *= max(1.0,0.18/max(brightness,0.0001));
            if (rainLightActive > 0.5) {
                float glint = smoothstep(0.55, 0.95,
                    0.5+0.5*sin(glitterTime*5.0 + seed.x*31.0 + float(j)));
                tint += rainLocalLight(drop) * (0.15 + glint*0.7);
            }
            // Transparent body with a reflective rim, rather than a filled dot.
            float rim=clamp(separation/(radius+footprint*0.25),0.0,1.0);
            float facing=sqrt(max(1.0-rim*rim,0.0));
            float fresnel=0.02+0.98*pow(1.0-facing,5.0);
            sumRGB += tint*coverage*(j == -1 ? 2.0 : 0.16+0.44*fresnel);
            sumAlpha += coverage*(j == -1 ? 0.12 : 0.18+0.25*fresnel);
        }
    }
    return vec4(sumRGB/max(sumAlpha, 0.00001), min(sumAlpha, 0.22));
}

// Short ballistic spray at concentrated runoff entering the shoreline.
// Bounded close-view gather, independent of the ordinary rain-impact droplets.
vec4 drawRunoffSpray(vec3 surface,vec3 encodedNormal,vec3 rayDir,
                     float sceneDistance,bool groundPixel) {
    float pixelAngle=max(length(dFdx(rayDir)),length(dFdy(rayDir)));
    vec3 n=normalize(encodedNormal*2.0-1.0);
    float facing=dot(n,-rayDir);
    float distanceToSurface=length(surface-eyePos);
    float fade=(1.0-smoothstep(500.0,1100.0,distanceToSurface))
        *(1.0-smoothstep(0.5,1.5,pixelAngle*distanceToSurface))
        *smoothstep(0.35,0.6,facing);
    if(!groundPixel || terrainWetness<0.7 || n.y<0.25 || fade<=0.0
       || surface.y < -1.0 || surface.y>8.0) return NONE;
    vec3 shellBase=surface-rayDir*(0.25/max(facing,0.35))-n*0.25;
    vec2 cell=floor(shellBase.xz/2.0);
    float alpha=0.0;
    vec3 colour=vec3(0);
    for(int z=-1;z<=1;++z) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,z);
        vec3 seed=hash3(id+vec2(231,719));
        float age=fract(terrainFlowTime*(0.8+seed.x*0.3)+seed.y)/ (0.8+seed.x*0.3);
        if(age>0.22) continue;
        vec2 xz=(id+seed.xy)*2.0;
        vec3 impact=vec3(xz.x,surface.y-dot(xz-surface.xz,n.xz)/n.y,xz.y);
        vec4 projected=viewProjection*vec4(impact,1);
        if(projected.w<=0.0) continue;
        vec2 at=projected.xy/projected.w*0.5+0.5;
        vec2 margin=2.0/viewPortSize;
        if(any(lessThan(at,margin)) || any(greaterThan(at,1.0-margin))) continue;
        bool g,u,w,s;
        vec3 sourceEncoded=GetGroundVertexNormal(at,g,u,w,s);
        if(!g || u || s) continue;
        float depth=texture2D(mapDepthTex,at).r;
        if(depth<=0.0 || depth>=0.999999) continue;
        vec3 source=GetWorldPosAtUV(at,depth);
        vec3 sourceN=rainGeometryNormal(at,false,normalize(sourceEncoded*2.0-1.0));
        if(sourceN.y<0.25 || dot(n,sourceN)<0.9) continue;
        if(abs(dot(source-impact,sourceN))>0.45) continue;
        vec3 visible=GetWorldPosAtUV(at,texture2D(dephtCopyTex,at).r);
        if(length(visible-eyePos)+0.6<length(source-eyePos)) continue;
        impact.y=source.y-dot(xz-source.xz,sourceN.xz)/sourceN.y;
        float strength=terrainRunoffSpray(impact,sourceN);
        if(strength<0.03) continue;
        vec3 downhill=normalize(vec3(0,-1,0)+sourceN*sourceN.y);
        vec3 across=normalize(cross(sourceN,downhill));
        for(int j=0;j<3;++j) {
            float side=fract(seed.z+float(j)*0.381)*2.0-1.0;
            vec3 offset=(sourceN*(4.0+2.0*seed.x)+downhill*2.0+across*side*2.0)*age
                -vec3(0,32.0*age*age,0);
            if(dot(offset,sourceN)<=0.0) continue;
            vec3 drop=impact+offset;
            float along=dot(drop-eyePos,rayDir);
            if(along<=0.0 || along>=sceneDistance) continue;
            float separation=length(eyePos+rayDir*along-drop);
            float footprint=max(pixelAngle*along,0.02);
            float radius=0.035+0.025*fract(seed.y+float(j)*0.29);
            float a=(1.0-smoothstep(radius,radius+footprint,separation))
                *radius/(radius+footprint)*strength*fade
                *smoothstep(0.0,0.025,age)*(1.0-smoothstep(0.16,0.22,age));
            vec3 light=max(sunCol,vec3(0))*0.65+max(skyCol,vec3(0))*0.7;
            if(rainLightActive>0.5) light+=rainLocalLight(drop);
            colour+=a*light/(vec3(1)+light);
            alpha+=a;
        }
    }
    return vec4(colour/max(alpha,0.00001),min(alpha,0.4));
}
