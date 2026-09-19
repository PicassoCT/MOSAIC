// Sparse, analytic impact droplets. No particles, history or additional targets.
// The seed and phase match noise(..., 0.6125), the existing puddle rings.
const float SPLASH_CELL = 8.0 / 3.0;
const float SPLASH_GRAVITY = 64.0;

float splashAge(vec3 seed) {
    return mod(time * 1.225 - (seed.x + seed.y) * 5.0, 2.0 * PI) / 1.225;
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
    float fade = (1.0 - smoothstep(450.0, 1100.0, distanceToSurface));
    fade *= smoothstep(0.8, 0.97, n.y);
    // A bounded neighbourhood cannot cover arbitrarily grazing views. Fade
    // before the expanded shell could reach outside the 3x3 cell neighbourhood.
    fade *= smoothstep(0.65, 0.85, dot(n, -rayDir));
    if (isSky || rainPercent <= 0.0 || depthAtPixel.r >= 0.999999 || fade <= 0.0)
        return NONE;

    vec2 cell = floor(surface.xz / SPLASH_CELL);
    float sumAlpha = 0.0;
    vec3 sumRGB = vec3(0.0);
    for (int z = -1; z <= 1; ++z) for (int x = -1; x <= 1; ++x) {
        vec2 candidate = cell + vec2(x, z);
        vec3 seed = hash3(candidate);
        // Thin the impacts, not their opacity; the compositor applies rain once.
        if (seed.z > 0.45 * clamp(rainPercent, 0.0, 1.0)) continue;
        float age = splashAge(seed);
        if (age <= 0.0 || age >= 0.375) continue;

        vec2 impactXZ = (candidate + seed.xy) * SPLASH_CELL;
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
        if (abs(dot(sourcePosition-impact, sourceN)) > 0.3) continue;
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
            float footprint = clamp(pixelAngle*t, 0.025, 0.6);
            float radius = 0.055;
            float coverage = (1.0-smoothstep(radius, radius+footprint, separation))
                             * radius/(radius+footprint);
            coverage *= fade * smoothstep(0.0, 0.10, height)
                        * smoothstep(0.0, 0.12, sceneDistance-t);
            if (coverage <= 0.0001) continue;
            vec3 tint = mix(sunCol*DAY_RAIN_HIGH_COL.rgb,
                            sunCol*NIGHT_RAIN_HIGH_COL.rgb, getDayPercent());
            tint = max(tint + max(skyCol, vec3(0))*0.15, vec3(0.025));
            if (rainLightActive > 0.5) {
                float glint = smoothstep(0.55, 0.95,
                    0.5+0.5*sin(glitterTime*5.0 + seed.x*31.0 + float(j)));
                tint += rainLocalLight(drop) * (0.15 + glint*0.7);
            }
            sumRGB += tint*coverage;
            sumAlpha += coverage;
        }
    }
    return vec4(sumRGB/max(sumAlpha, 0.00001), min(sumAlpha, 0.45));
}
