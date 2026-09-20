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
        for (int j = 0; j < 3; ++j) {
            float angle = seed.z * 31.0 + float(j) * (2.0*PI/3.0);
            vec3 tangent = tangentX*cos(angle) + tangentZ*sin(angle);
            float speed = 10.0 + 2.0*fract(seed.x + float(j)*0.37);
            vec3 offset = splashOffset(sourceN, tangent, age, speed);
            float height = dot(offset, sourceN);
            if (height <= 0.0) continue;
            vec3 drop = impact + offset;
            float t = dot(drop-eyePos, rayDir);
            if (t <= 0.0 || t >= sceneDistance) continue;
            float separation = length(eyePos + rayDir*t - drop);
            float footprint = clamp(pixelAngle*t, 0.025, 0.8);
            float radius = 0.14;
            float coverage = (1.0-smoothstep(radius, radius+footprint, separation))
                             * radius/(radius+footprint);
            coverage *= 1.8 * fade * smoothstep(0.0, 0.10, height)
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
            sumRGB += tint*coverage*(0.16+0.44*fresnel);
            sumAlpha += coverage*(0.25+0.3*fresnel);
        }
    }
    return vec4(sumRGB/max(sumAlpha, 0.00001), min(sumAlpha, 0.22));
}
