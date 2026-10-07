#version 150 compatibility
uniform float descent;
uniform float elapsed;
uniform float aspect;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
    float result = 0.0, weight = 0.5;
    for (int i = 0; i < 5; i++) {
        result += noise(p) * weight;
        p = mat2(1.6, -1.2, 1.2, 1.6) * p + 13.7;
        weight *= 0.5;
    }
    return result;
}

void main() {
    vec2 uv = gl_TexCoord[0].st;
    vec2 screen = (uv - 0.5) * vec2(aspect, 1.0);

    // Keep the horizon orientation fixed throughout the dive. Only apparent
    // altitude/scale changes; this avoids the old "camera flip" impression.
    // Planet diameter expands roughly 26x as the view descends.
    // Center the optical axis on one coastline throughout the approach.
    float radius = 1.62 * exp2(4.7 * descent);
    vec2 center = vec2(0.0, -1.02);
    vec2 p = (screen - center) / radius;
    float rr = dot(p, p);
    float edge = 1.0 - smoothstep(0.994, 1.006, rr);
    float z = sqrt(max(0.0, 1.0 - rr));
    vec3 normal = normalize(vec3(p, max(z, 0.001)));

    vec3 sunDir = normalize(vec3(-0.72, 0.54, 0.82));
    float ndl = dot(normal, sunDir);
    float daylight = smoothstep(-0.08, 0.20, ndl);
    float sun = max(0.0, ndl);
    float night = 1.0 - smoothstep(-0.18, 0.06, ndl);

    // Stable regional projection: scale changes in snaps, but the surface never
    // rotates or mirrors underneath the viewer.
    vec2 focal = vec2(0.0, 1.02 / radius);
    vec2 surface = (p - focal) * 7.0 / (0.34 + z) + vec2(2.0, -0.5);
    float continental = fbm(surface * 0.72);
    float land = smoothstep(0.43, 0.50, continental);
    float terrain = fbm(surface * 6.5);
    float fineTerrain = fbm(surface * (22.0 + 70.0 * descent));

    vec3 ocean = mix(vec3(0.004, 0.030, 0.070), vec3(0.012, 0.115, 0.205), sun);
    vec3 soil = mix(vec3(0.10, 0.13, 0.075), vec3(0.52, 0.39, 0.22), terrain);
    soil *= 0.72 + fineTerrain * 0.35;
    vec3 ground = mix(ocean, soil, land);
    // Ground details become distinguishable as optical scale increases.
    float roadsX = abs(sin(surface.x * 31.0));
    float roadsY = abs(sin(surface.y * 29.0));
    float roads = exp(-20.0 * min(roadsX, roadsY));
    float urban = smoothstep(0.47, 0.63,
        fbm(surface * 2.5 + vec2(8.0, 1.7)));
    ground += vec3(0.08, 0.07, 0.045) * urban * land * roads
        * smoothstep(0.12, 0.34, descent);

    // Water catches a narrow solar glint from low orbit.
    vec3 viewDir = normalize(vec3(-p, max(z, 0.001)));
    vec3 halfVec = normalize(sunDir + viewDir);
    float spec = pow(max(0.0, dot(normal, halfVec)), 90.0) * (1.0 - land) * daylight;
    ground += vec3(1.0, 0.88, 0.63) * spec * 0.75;

    // High cloud field and a displaced shadow field. The offset makes clouds
    // visibly float above the surface instead of looking painted onto it.
    vec2 wind = vec2(elapsed * 0.009, elapsed * 0.003);
    float cloudBase = fbm(surface * 2.55 + wind);
    float cloudFine = fbm(surface * 8.0 - wind * 1.7);
    float clouds = smoothstep(0.52, 0.73, cloudBase + cloudFine * 0.16);
    vec2 shadowOffset = vec2(-sunDir.x, -sunDir.y) * 0.11;
    float cloudShadow = smoothstep(0.52, 0.73,
        fbm((surface + shadowOffset) * 2.55 + wind));
    ground *= 1.0 - cloudShadow * daylight * 0.34;

    // Sparse settlement lights on the night side, constrained to land and to
    // broad population corridors. They disappear naturally under cloud.
    float corridor = smoothstep(0.56, 0.76, fbm(surface * 3.2 + vec2(8.0, 1.7)));
    float cells = step(0.92, hash(floor(surface * 62.0)));
    float cityLights = land * corridor * cells * night * (1.0 - clouds * 0.82);
    vec3 litSurface = ground * mix(0.11, 1.0, daylight);
    litSurface += vec3(1.00, 0.56, 0.18) * cityLights * 2.5;

    vec3 cloudColor = mix(vec3(0.44, 0.49, 0.54), vec3(0.91, 0.94, 0.97), daylight);
    cloudColor *= 0.72 + sun * 0.45;
    litSurface = mix(litSurface, cloudColor, clouds * 0.88);

    // Atmospheric limb and twilight band.
    float horizon = pow(max(0.0, 1.0 - z), 4.2);
    float twilight = exp(-abs(ndl) * 12.0) * edge;
    litSurface += vec3(0.05, 0.24, 0.60) * horizon * 0.92;
    litSurface += vec3(0.34, 0.17, 0.08) * twilight * 0.34;

    vec3 space = vec3(0.002, 0.004, 0.012);
    float star = step(0.9987, hash(floor(uv * vec2(1100.0, 650.0))));
    space += vec3(star * 0.34);
    float halo = exp(-abs(rr - 1.0) * 92.0) * (1.0 - edge);
    vec3 earth = mix(space, litSurface, edge) + vec3(0.06, 0.24, 0.60) * halo;

    // During atmospheric transit, clouds become a separate near-camera layer.
    // Their scale changes at the same staged beats as the descent, revealing
    // progressively finer detail instead of one long rubber-band zoom.
    // Moving cloud parallax scales along with the ground projection.
    // It becomes opaque across the Earth -> live-city geometry boundary,
    // then disperses continuously as the real city grows underneath.
    float transitScale = exp2(mix(4.6, -0.15, descent));
    vec2 transitUV = screen * transitScale;
    vec2 flow = wind * (0.45 + descent * 2.5);
    float transitLarge = fbm(transitUV + vec2(4.7, 8.2) + flow);
    float transitFine = fbm(transitUV * 3.6 - flow * 1.8);
    float transitNoise = transitLarge * 0.78 + transitFine * 0.22;
    float sunlitEdge = fbm(transitUV + vec2(4.9, 8.0) + flow);
    float relief = clamp(0.55 + (transitNoise - sunlitEdge) * 5.0, 0.0, 1.0);
    vec3 transitCloud = mix(vec3(0.37, 0.50, 0.63),
                            vec3(0.97, 0.98, 1.0), relief);
    transitCloud *= 0.76 + transitNoise * 0.36;
    // 0.43-0.55 stays fully opaque to conceal the projection handoff.
    float cover = smoothstep(0.23, 0.39, descent)
                * (1.0 - smoothstep(0.55, 0.98, descent));
    float cloudScene = smoothstep(0.25, 0.40, descent);
    gl_FragColor = vec4(mix(earth, transitCloud, cloudScene), cover);
}
