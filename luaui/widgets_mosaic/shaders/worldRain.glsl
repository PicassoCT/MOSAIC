// Camera-independent procedural rain. DDA visits world cells, not uniform
// density samples: one analytic finite streak per occupied cell, no particles.
// Cell identities advect with time, never with camera position or orientation.
const float RAIN_CELL = 64.0;
const float RAIN_RANGE = 1400.0;
const int RAIN_CELL_LIMIT = 48; // > sqrt(3)*RAIN_RANGE/RAIN_CELL + 3
const vec3 RAIN_VELOCITY = vec3(8.0, -160.0, 3.0);

vec3 rainCellSeed(vec3 cell) {
    vec3 q = fract(cell * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yxz + 33.33);
    return fract((q.xxy + q.yzz) * q.zyx);
}

// Schlick approximation for an air/water interface (F0 approximately 2%).
float rainWaterFresnel(float facing) {
    return 0.02+0.98*pow(1.0-clamp(facing,0.0,1.0),5.0);
}

vec4 drawWorldRain(vec3 direction, float sceneDistance) {
    // Evaluate derivatives before divergent branches/loops.
    float pixelAngle = max(length(dFdx(direction)), length(dFdy(direction)));
    float nearT = 0.0;
    float farT = sceneDistance;
    if (abs(direction.y) > 0.000001) {
        float a = (MIN_HEIGHT_RAIN - eyePos.y) / direction.y;
        float b = (MAX_HEIGTH_RAIN - eyePos.y) / direction.y;
        nearT = max(nearT, min(a,b));
        farT = min(farT, max(a,b));
    } else if (eyePos.y < MIN_HEIGHT_RAIN || eyePos.y > MAX_HEIGTH_RAIN) {
        return NONE;
    }
    // Bound distance from volume entry, so zooming above the rain slab still
    // shows rain over the city. Fade out before the traversal limit.
    farT = min(farT, nearT + RAIN_RANGE);
    if (farT <= nearT) return NONE;
    vec3 drift = RAIN_VELOCITY * time;
    vec3 origin = eyePos - drift;
    vec3 cell = floor((origin + direction * (nearT + 0.0001)) / RAIN_CELL);
    vec3 stepDir = step(vec3(0), direction) * 2.0 - 1.0;
    vec3 invDir = stepDir / max(abs(direction), vec3(0.0000001));
    vec3 nextT = ((cell + step(vec3(0), direction)) * RAIN_CELL - origin) * invDir;
    vec3 deltaT = RAIN_CELL * abs(invDir);
    vec3 axis = -normalize(RAIN_VELOCITY);
    float parallel = dot(direction, axis);
    vec3 sumRGB = vec3(0);
    float sumAlpha = 0.0;
    float cellEntry = nearT;
    vec3 atmosphere = max(mix(sunCol * DAY_RAIN_HIGH_COL.rgb,
                         sunCol * NIGHT_RAIN_HIGH_COL.rgb, getDayPercent()),vec3(0));
    atmosphere += max(skyCol,vec3(0))*0.5;
    // Preserve atmosphere hue; don't turn blue skylight into a grey RGB floor.
    float brightness = dot(atmosphere,vec3(0.2126,0.7152,0.0722));
    atmosphere *= max(1.0,0.35/max(brightness,0.0001));
    atmosphere /= 1.0+dot(atmosphere,vec3(0.2126,0.7152,0.0722));
    for (int i = 0; i < RAIN_CELL_LIMIT; ++i) {
        if (cellEntry >= farT) break;
        float cellExit = min(farT, min(nextT.x, min(nextT.y, nextT.z)));
        // Two independent streaks per visited cell improve foreground coverage
        // without adding DDA steps or texture reads for empty pixels.
        for (int streak = 0; streak < 2; ++streak) {
            vec3 seed = rainCellSeed(cell + vec3(19,37,53)*float(streak));
            if (seed.z < 0.65) {
                // Keep the complete streak and its AA footprint inside its cell.
                vec3 centre = (cell + 0.25 + seed * 0.5) * RAIN_CELL + drift;
                vec3 offset = eyePos - centre;
                float alongRay = dot(offset, direction);
                float alongStreak = dot(offset, axis);
                float halfLength = 4.0 + seed.y * 3.0;
                float t = (parallel * alongStreak - alongRay) /
                          max(1.0 - parallel * parallel, 0.00001);
                float s = clamp(alongStreak + parallel*t, -halfLength, halfLength);
                t = clamp(parallel*s - alongRay, cellEntry, cellExit);
                s = clamp(alongStreak + parallel*t, -halfLength, halfLength);
                vec3 drop = centre + axis*s;
                float separation = length(eyePos + direction*t - drop);
                float footprint = clamp(pixelAngle * t, 0.08, 2.0);
                float radius = 0.13;
                float coverage = (1.0-smoothstep(radius, radius+footprint, separation))
                                 * radius / (radius+footprint);
                coverage *= 1.0-smoothstep(0.45,1.0,abs(s)/halfLength);
                coverage *= smoothstep(0.0, 6.0, t);
                coverage *= 1.0-smoothstep(RAIN_RANGE*0.8, RAIN_RANGE, t-nearT);
                coverage *= smoothstep(0.0, 1.0, sceneDistance-t);
                if (coverage > 0.0001 && drop.y >= MIN_HEIGHT_RAIN && drop.y <= MAX_HEIGTH_RAIN) {
                    // Same atmosphere/day-night palette; local radiance is sampled
                    // at the actual streak, not at an offset from the ground.
                    vec3 light = vec3(0);
                    if (rainLightActive > 0.5) light = rainLocalLight(drop);
                    float pulse = smoothstep(0.55,0.95,
                        0.5+0.5*sin(glitterTime*5.0 + seed.x*31.0));
                    vec3 dropLight=atmosphere+light*(0.15+pulse*0.7);
                    float opacity=1.0;
                    // Resolve a rounded water cross-section only for foreground
                    // streaks; preserve the distant rain's established appearance.
                    float closeDetail=1.0-smoothstep(80.0,240.0,t);
                    if(closeDetail>0.001) {
                        vec3 radial=eyePos+direction*t-drop;
                        float rim=clamp(separation/(radius+footprint*0.25),0.0,1.0);
                        float facing=sqrt(max(1.0-rim*rim,0.0));
                        vec3 waterNormal=normalize(radial/max(separation,0.0001)*rim-direction*max(facing,0.001));
                        float fresnel=rainWaterFresnel(facing);
                        vec3 l=dot(sunPos,sunPos)>0.001 ? normalize(sunPos) : vec3(0,1,0);
                        vec3 h=normalize(l-direction+vec3(0,0.0001,0));
                        float glint=pow(max(dot(waterNormal,h),0.0),64.0);
                        vec3 reflected=(atmosphere+light)*(0.22+0.78*fresnel)+atmosphere*glint*0.5;
                        dropLight=mix(dropLight,reflected,closeDetail);
                        opacity=mix(1.0,0.3+0.7*fresnel,closeDetail);
                    }
                    sumRGB += dropLight*coverage;
                    sumAlpha += coverage*opacity;
                }
            }
        }
        // Advance tied axes together (including exact vertical/horizontal rays).
        vec3 advance = step(nextT, vec3(min(nextT.x,min(nextT.y,nextT.z))+0.00001));
        cell += advance * stepDir;
        nextT += advance * deltaT;
        cellEntry = cellExit;
    }
    float alpha = clamp(sumAlpha,0.0,0.75);
    // Straight-alpha result: the existing fullscreen compositor applies alpha.
    return vec4(sumRGB/max(sumAlpha,0.00001),alpha);
}
