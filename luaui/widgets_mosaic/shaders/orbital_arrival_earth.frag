#version 150 compatibility
uniform float descent;
uniform float cloudDescent;
uniform vec2 regionOffset; // selected once for this match; weather never uses time
uniform float aspect;

// Integer lattice noise is stable at every optical scale and avoids the
// precision bands of large-coordinate sin hashes. Filter each octave against
// its pixel footprint so fine cloud detail cannot sparkle at the horizon.
vec4 lattice(vec2 p) {
    uvec2 cell = uvec2(ivec2(p));
    uvec4 x = uvec4(cell.x, cell.x + 1u, cell.x, cell.x + 1u);
    uvec4 y = uvec4(cell.y, cell.y, cell.y + 1u, cell.y + 1u);
    uvec4 h = x * 374761393u + y * 668265263u;
    h = (h ^ (h >> 13u)) * 1274126177u;
    return vec4(h ^ (h >> 16u)) * (1.0 / 4294967295.0);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    vec4 n = lattice(i);
    return mix(mix(n.x, n.y, f.x), mix(n.z, n.w, f.x), f.y);
}
float fractal(vec2 p, int octaves) {
    float footprint = max(length(dFdx(p)), length(dFdy(p)));
    float result = 0.5, weight = 0.5;
    for (int i = 0; i < 6; ++i) {
        if (i >= octaves) break;
        // Higher octaves only grow this footprint. Once one contributes
        // nothing, all following hashes are invisible work as well.
        if (footprint >= 1.10) break;
        float visible = 1.0 - smoothstep(0.35, 1.10, footprint);
        result += (noise(p) - 0.5) * weight * visible;
        p = mat2(1.63, -1.19, 1.19, 1.63) * p + vec2(17.3, 9.2);
        footprint *= 2.018;
        weight *= 0.5;
    }
    return result;
}
float fbm(vec2 p) { return fractal(p, 5); }
float clamp01(float x) { return clamp(x, 0.0, 1.0); }

// Exact noise slopes avoid the 2x2 derivative-quad pattern in lit billows.
// Height and normals share lattice samples, with shorter wavelengths given
// less normal weight to preserve soft cloud tops instead of sharp wrinkles.
vec3 noiseGradient(vec2 p) {
    vec2 i = floor(p), t = fract(p);
    vec2 f = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    vec2 df = 30.0 * t * t * (t * (t - 2.0) + 1.0);
    vec4 n = lattice(i);
    return vec3(mix(mix(n.x, n.y, f.x), mix(n.z, n.w, f.x), f.y),
        mix(n.y - n.x, n.w - n.z, f.y) * df.x,
        mix(n.z - n.x, n.w - n.y, f.x) * df.y);
}
vec3 fractalGradient(vec2 p, int octaves) {
    float footprint = max(length(dFdx(p)), length(dFdy(p)));
    vec3 result = vec3(0.5, 0.0, 0.0);
    float weight = 0.5;
    float slopeWeight = 0.5;
    mat2 transform = mat2(1.0);
    mat2 octaveTransform = mat2(1.63, -1.19, 1.19, 1.63);
    for (int i = 0; i < 6; ++i) {
        if (i >= octaves || footprint >= 1.10) break;
        float visible = 1.0 - smoothstep(0.35, 1.10, footprint);
        vec3 sampleValue = noiseGradient(p);
        result.x += (sampleValue.x - 0.5) * weight * visible;
        // Slopes need more filtering than color; a subpixel bump must not
        // become a full-contrast bright or dark normal-map pixel.
        float slopeVisible = 1.0 - smoothstep(0.18, 0.55, footprint);
        result.yz += transpose(transform) * sampleValue.yz * slopeWeight * slopeVisible;
        p = octaveTransform * p + vec2(17.3, 9.2);
        transform = octaveTransform * transform;
        footprint *= 2.018;
        weight *= 0.5;
        slopeWeight *= 0.25;
    }
    return result;
}
float smoothSlope(float x, float low, float high) {
    float t = clamp01((x - low) / (high - low));
    return 6.0 * t * (1.0 - t) / (high - low);
}

// Recover a surface-space slope from screen derivatives. This shares the
// actual density field with the lighting instead of inventing unrelated
// shadow noise, and keeps relief strength independent of render resolution.
vec2 surfaceGradient(float value, vec2 p) {
    vec2 dx = dFdx(p), dy = dFdy(p);
    float vx = dFdx(value), vy = dFdy(value);
    float determinant = dx.x * dy.y - dx.y * dy.x;
    float safeDet = sign(determinant) * max(abs(determinant), 1e-10);
    if (abs(determinant) < 1e-10) return vec2(0.0);
    return vec2(vx * dy.y - vy * dx.y, vy * dx.x - vx * dy.x) / safeDet;
}

// R: cloud coverage; G: raised cloud top; B: fine billows; A: thin cirrus.
// All frequencies are fixed world frequencies. Zoom reveals finer detail by
// changing the pixel footprint, never by regenerating the weather pattern.
vec4 cloudField(vec2 world, out vec2 topSlope) {
    vec2 warp = vec2(fractal(world * 0.48 + vec2(4.1, 7.8), 3),
                     fractal(world * 0.48 + vec2(13.7, 2.6), 3)) - 0.5;
    vec2 p = world + warp * 1.0;
    float weather = fractal(p * 0.26 + vec2(11.2, 6.4), 3);
    vec2 curl = vec2(fractal(p * 0.86 + vec2(3.2, 6.5), 3),
                     fractal(p * 0.86 + vec2(8.6, 1.9), 3)) - 0.5;
    // Regional bends change the local direction of each front. Moderate
    // anisotropy creates coherent sheets without parallel painted stripes.
    vec2 alongFront = mat2(0.86, -0.51, 0.51, 0.86) * p + curl * 0.55;
    float sheets = fbm(alongFront * vec2(2.2, 3.8));
    vec3 towerSample = fractalGradient(p * 7.5 + vec2(2.8, 9.1), 5);
    vec3 billowSample = fractalGradient(p * 38.0, 5);
    vec3 fineSample = fractalGradient(p * 145.0 + vec2(5.3, 1.4), 3);
    float towers = towerSample.x, billows = billowSample.x, fine = fineSample.x;
    float sheetCover = smoothstep(0.41, 0.63,
        sheets + (weather - 0.5) * 0.42);
    float brokenCover = smoothstep(0.48, 0.66,
        towers + (weather - 0.5) * 0.30 + (billows - 0.5) * 0.14);
    float billowForm = smoothstep(0.28, 0.73, billows);
    float fineForm = smoothstep(0.30, 0.71, fine);
    // Dense sheets keep a granular optical depth instead of washing out
    // all small cumulus forms under a fully opaque white slab.
    float coverage = max(sheetCover * (0.58 + billowForm * 0.42), brokenCover);
    coverage = clamp01(coverage - (1.0 - billows) * (1.0 - coverage) * 0.25);
    float height = 0.15 + towers * 0.32 + billowForm * 0.45 + fineForm * 0.04;
    float top = coverage * height;
    vec2 heightSlope = towerSample.yz * (7.5 * 0.32)
        + billowSample.yz * (38.0 * 0.45 * smoothSlope(billows, 0.28, 0.73))
        + fineSample.yz * (145.0 * 0.04 * smoothSlope(fine, 0.30, 0.71));
    topSlope = surfaceGradient(coverage, world) * height + coverage * (
        surfaceGradient(p.x, world) * heightSlope.x
        + surfaceGradient(p.y, world) * heightSlope.y);
    float cavities = clamp01(0.5 + (billows - 0.5) * 2.3 + (fine - 0.5) * 0.65);
    float cirrus = smoothstep(0.59, 0.75,
        fractal(alongFront * vec2(4.5, 18.0) + curl * 8.0, 4));
    cirrus *= smoothstep(0.42, 0.63, towers) * (1.0 - coverage * 0.65);
    return vec4(coverage, top, cavities, cirrus * 0.16);
}

vec3 displayColor(vec3 linearColor) {
    vec3 c = max(linearColor, vec3(0.0));
    vec3 mapped = (c * (2.51 * c + 0.03)) / (c * (2.43 * c + 0.59) + 0.14);
    return pow(clamp(mapped, 0.0, 1.0), vec3(1.0 / 2.2));
}

vec3 orbitalEarth(vec2 screen) {
    // Low Earth orbit framing, held at four optical scales. The same surface
    // point and horizon orientation remain under the optical axis throughout.
    float radius = 3.36 * exp2(3.28 * descent);
    vec2 center = vec2(0.0, -0.90 * radius);
    vec2 p = (screen - center) / radius;
    float rr = dot(p, p);
    float z = sqrt(max(0.0, 1.0 - rr));
    vec3 normal = normalize(vec3(p, max(z, 0.001)));
    float edgeWidth = max(fwidth(rr), 0.00035);
    float edge = 1.0 - smoothstep(1.0 - edgeWidth, 1.0 + edgeWidth, rr);

    vec2 focal = -center / radius;
    float focalZ = sqrt(1.0 - dot(focal, focal));
    // The destination is at local high noon in every match. Moving to a
    // different generated region cannot rotate the sun or introduce sunset.
    vec3 sunDir = normalize(vec3(focal, focalZ));
    float ndl = dot(normal, sunDir);
    float sun = max(0.0, ndl);
    float daylight = smoothstep(-0.08, 0.20, ndl);
    float night = 1.0 - smoothstep(-0.18, 0.06, ndl);
    vec2 localSurface = (p - focal) * 7.0 / (0.34 + z);
    vec2 world = localSurface + vec2(2.0, -0.5) + regionOffset;

    // Coherent land masses, coastal shallows, ridged terrain and small relief.
    // A single generated region is sampled at every stop in the descent.
    vec2 terrainWarp = vec2(fractal(world * 0.43, 3),
                            fractal(world * 0.43 + vec2(7.4, 3.2), 3)) - 0.5;
    float continent = fbm(world * 0.38 + terrainWarp * 1.2);
    // The optical axis is always aimed at a city. At the wide orbital stop the
    // underlying continent remains essentially untouched; during the later
    // cuts a broad, noise-softened land bias guarantees that the selected
    // metropolitan patch does not accidentally resolve into open ocean.
    float targetRadius = length(localSurface * vec2(0.92, 1.08));
    float targetLand = exp(-targetRadius * targetRadius * 0.72)
        * smoothstep(0.12, 0.58, descent);
    continent += targetLand * (0.15 + 0.07 * fbm(world * 0.91 + vec2(21.4, 5.7)));
    float land = smoothstep(0.49, 0.515, continent);
    float shallows = smoothstep(0.45, 0.505, continent) * (1.0 - land);
    float terrain = fbm(world * 5.4);
    float ridge = 1.0 - abs(2.0 * fbm(world * 19.0 + terrainWarp) - 1.0);
    float fineTerrain = fractal(world * 110.0, 4);
    float moisture = fbm(world * 1.7 + vec2(12.1, 4.6));
    vec3 drySoil = mix(vec3(0.065, 0.043, 0.023), vec3(0.29, 0.22, 0.12), terrain);
    vec3 vegetation = mix(vec3(0.019, 0.038, 0.019), vec3(0.075, 0.105, 0.045), terrain);
    vec3 soil = mix(drySoil, vegetation, smoothstep(0.45, 0.64, moisture));
    soil *= 0.82 + ridge * 0.16 + fineTerrain * 0.13;
    vec3 ocean = mix(vec3(0.003, 0.014, 0.031),
                     vec3(0.008, 0.077, 0.084), shallows * 0.75);
    vec3 ground = mix(ocean, soil, land);

    // A deliberately generic city grows under the optical axis as scale
    // collapses. It is not supposed to encode a real-world street plan: the
    // job of these middle shots is to read immediately as "metropolitan" and
    // then hand the eye to the real Recoil map.
    float authoredPopulation = smoothstep(0.55, 0.73,
        fbm(world * 3.2 + vec2(8.0, 1.7)));
    float metroReveal = smoothstep(0.17, 0.50, descent);
    float detailReveal = smoothstep(0.48, 0.92, descent);
    float metroEnvelope = exp(-targetRadius * targetRadius * 1.35);
    float population = max(authoredPopulation * 0.72,
        metroEnvelope * metroReveal);

    float arterialA = abs(sin(world.x * 12.7 + world.y * 2.1));
    float arterialB = abs(sin(world.y * 11.3 - world.x * 1.7));
    float localA = abs(sin(world.x * 43.0 + world.y * 5.2));
    float localB = abs(sin(world.y * 39.0 - world.x * 4.4));
    float arterials = exp(-17.0 * min(arterialA, arterialB));
    float streets = exp(-33.0 * min(localA, localB)) * detailReveal;
    float roads = max(arterials, streets);

    float urbanMask = land * population * metroReveal;
    vec3 urbanFabric = mix(vec3(0.105, 0.095, 0.078),
                           vec3(0.185, 0.165, 0.132), terrain);
    ground = mix(ground, urbanFabric, urbanMask * 0.72);
    ground += vec3(0.080, 0.078, 0.071) * urbanMask * roads;

    // Parcel-scale roof variation only appears once the city fills most of
    // the frame. This keeps the regional shot from turning into noisy pixels.
    float parcels = noise(floor(world * 92.0 + vec2(17.0, 31.0)));
    float roofs = smoothstep(0.56, 0.82, parcels)
        * (1.0 - smoothstep(0.42, 0.86, roads)) * detailReveal;
    ground += mix(vec3(0.018, 0.016, 0.014), vec3(0.070, 0.060, 0.047), parcels)
        * urbanMask * roofs;

    // White midday reflection, with stronger grazing-angle reflectance.
    // No warm sunset grading or moving light source.
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 halfVec = normalize(sunDir + viewDir);
    float fresnel = 0.025 + 0.20 * pow(1.0 - z, 5.0);
    float glint = pow(max(dot(normal, halfVec), 0.0), 110.0)
        * (1.0 - land) * daylight;
    ground = ground * mix(0.11, 0.74 + sun * 0.26, daylight);
    ground += vec3(0.80, 0.88, 0.96) * glint * fresnel * 1.6;

    vec2 cloudSlope;
    vec4 cloud = cloudField(world, cloudSlope);
    vec2 coverageSlope = surfaceGradient(cloud.r, world);
    // At noon shadows lie almost directly beneath their cloud tops. The
    // small offset toward the limb follows the same density field.
    vec2 lightTangent = sunDir.xy - normal.xy * ndl;
    vec2 shadowOffset = -lightTangent * 0.028;
    float shadow = clamp01(cloud.r + dot(coverageSlope, shadowOffset));
    ground *= 1.0 - shadow * daylight * 0.32;
    vec3 topNormal = normalize(vec3(-cloudSlope * 0.028, 1.0));
    vec3 localLight = normalize(vec3(lightTangent * 1.8, max(sun, 0.25)));
    float relief = max(dot(topNormal, localLight), 0.0);
    // Zenith sunlight lights raised tops while the multiscale slopes and
    // cavities remain legible after the display curve. These are neutral
    // noon whites, with only the ambient light in cavities tinted by sky.
    float selfOcclusion = 0.46 + cloud.b * 0.54;
    float directLight = pow(relief, 1.2) * selfOcclusion;
    vec3 cloudColor = vec3(0.075, 0.105, 0.145)
        + vec3(0.91, 0.93, 0.96) * directLight;
    float cloudOpacity = (1.0 - exp(-cloud.r * 3.8));

    // Hide the procedural city's outer join behind an irregular cloud belt.
    // The center clears as we descend, while the borders stay optically busy;
    // the player therefore reads one continuous dive into a city rather than
    // getting a clean frame in which to compare synthetic regional geography
    // against the final authored map.
    float viewRadius = length(vec2(screen.x / max(aspect, 0.001), screen.y) * 2.0);
    float veilNoise = fbm(world * 0.73 + vec2(37.0, 11.0));
    float veilRadius = viewRadius + (veilNoise - 0.5) * 0.26;
    float veilStrength = smoothstep(0.20, 0.68, descent);
    float borderVeil = smoothstep(0.56, 1.03, veilRadius) * veilStrength;
    float centerWindow = (1.0 - smoothstep(0.22, 0.62, viewRadius))
        * smoothstep(0.28, 0.72, descent);
    cloudOpacity *= 1.0 - centerWindow * 0.62;
    cloudOpacity = max(cloudOpacity, borderVeil * (0.72 + 0.28 * cloud.b));

    vec3 litSurface = mix(ground, cloudColor, cloudOpacity);
    litSurface = mix(litSurface, vec3(0.70, 0.80, 0.92), cloud.a * 0.36);

    // Keep the authored settlement population/lights. The fixed noon sun
    // makes their night factor zero in this daylight arrival.
    float cells = step(0.96, noise(floor(world * 62.0)));
    litSurface += vec3(1.0, 0.56, 0.18) * land * population * cells * night
        * (1.0 - cloudOpacity) * 2.5;

    // Atmospheric depth is concentrated near the limb: a thin cyan edge
    // above subdued blue haze, with a dark sky at daylight exposure.
    float airMass = pow(1.0 - z, 3.4);
    litSurface = mix(litSurface, vec3(0.045, 0.12, 0.23), airMass * 0.52);
    float innerRim = exp(-max(1.0 - rr, 0.0) * 130.0) * edge;
    litSurface += vec3(0.022, 0.082, 0.19) * innerRim;
    float outerRim = exp(-max(rr - 1.0, 0.0) * 220.0) * (1.0 - edge);
    vec3 space = vec3(0.00045, 0.00065, 0.0011);
    vec3 scene = mix(space, litSurface, edge)
        + vec3(0.015, 0.061, 0.15) * outerRim;
    return displayColor(scene);
}

vec3 passingClouds(vec2 screen) {
    // A frozen cloud field approached by the camera. Only optical scale
    // changes; there is no wind, scrolling texture or time-dependent morph.
    float scale = exp2(mix(4.6, -0.15, cloudDescent));
    vec2 p = screen * scale + vec2(4.7, 8.2) + regionOffset;
    float broad = fbm(p);
    float billows = fbm(p * 4.0 + vec2(3.6, 8.1));
    float fine = fractal(p * 23.0, 4);
    float height = broad * 0.68 + billows * 0.32;
    vec2 slope = surfaceGradient(height, p);
    float relief = inversesqrt(1.0 + dot(slope, slope) * 0.04);
    vec3 color = mix(vec3(0.22, 0.32, 0.43), vec3(0.92, 0.96, 1.0),
        clamp01(relief * 0.70 + height * 0.30));
    color *= 0.80 + fine * 0.22;
    return displayColor(color);
}

void main() {
    vec2 screen = (gl_TexCoord[0].st - 0.5) * vec2(aspect, 1.0);
    float cloudScene = smoothstep(0.25, 0.40, cloudDescent);
    // Uniform branches: static snapshots do no transit work; the opaque
    // cloud passage does no expensive planetary/terrain/cloud-field work.
    vec3 scene;
    if (cloudScene >= 1.0) {
        scene = passingClouds(screen);
    } else {
        scene = orbitalEarth(screen);
        if (cloudScene > 0.0) {
            scene = mix(scene, passingClouds(screen), cloudScene);
        }
    }
    // Preserve the existing opaque handoff and exact final city composite.
    float cover = smoothstep(0.23, 0.39, cloudDescent)
                * (1.0 - smoothstep(0.55, 0.98, cloudDescent));
    gl_FragColor = vec4(scene, cover);
}
