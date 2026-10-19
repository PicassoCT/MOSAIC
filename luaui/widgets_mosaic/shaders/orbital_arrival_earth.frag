#version 150 compatibility
uniform float descent;
uniform float cloudDescent;
uniform vec2 regionOffset; // fixed per match; weather has no time input
uniform float aspect;
uniform sampler2D surveyTex;
uniform int hasSurvey;

float clamp01(float x) { return clamp(x, 0.0, 1.0); }
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
    for (int i = 0; i < 5; ++i) {
        if (i >= octaves || footprint >= 1.10) break;
        result += (noise(p) - 0.5) * weight
            * (1.0 - smoothstep(0.35, 1.10, footprint));
        p = mat2(1.63, -1.19, 1.19, 1.63) * p + vec2(17.3, 9.2);
        footprint *= 2.018;
        weight *= 0.5;
    }
    return result;
}
float fbm(vec2 p) { return fractal(p, 5); }
float volumeNoise(vec3 p) {
    float slice = floor(p.z), f = fract(p.z);
    f = f * f * (3.0 - 2.0 * f);
    return mix(noise(p.xy + slice * vec2(17.71, 9.13)),
        noise(p.xy + (slice + 1.0) * vec2(17.71, 9.13)), f);
}
vec3 displayColor(vec3 linearColor) {
    vec3 c = max(linearColor, vec3(0.0));
    vec3 mapped = (c * (2.51 * c + 0.03)) / (c * (2.43 * c + 0.59) + 0.14);
    return pow(clamp(mapped, 0.0, 1.0), vec3(1.0 / 2.2));
}

// Weather is organized into broad fronts and detached banks. Its high-frequency
// shape changes density inside a volume, never a surface normal. This replaces
// the old derivative-lit height sheet whose wrinkles looked like white terrain.
float weatherCover(vec2 world) {
    vec2 bend = vec2(noise(world * 0.65 + 3.1), noise(world * 0.65 + 17.6)) - 0.5;
    vec2 front = mat2(0.91, -0.41, 0.41, 0.91) * (world + bend * 0.72);
    float banks = noise(front * vec2(1.10, 1.85) + vec2(12.3, 7.8));
    float regional = noise(world * 0.33 + vec2(5.9, 19.2));
    return banks * 0.71 + regional * 0.29;
}
// Continuous density merges billows into banks instead of exposing a regular
// array of ellipsoids. Coarse towers vary vertical depth; the two filtered
// erosion scales only roughen their volume, never a lit surface normal.
float cloudDensity(vec3 p, float weather, float footprint) {
    float body = volumeNoise(vec3(p.xy * 6.1, p.z * 2.65));
    float towers = volumeNoise(vec3(p.xy * 2.9 + 13.2, p.z * 1.8));
    float erosion = volumeNoise(vec3(p.xy * 28.0 + 6.4, p.z * 4.1));
    float wisps = volumeNoise(vec3(p.xy * 59.0 + 17.2, p.z * 5.7));
    erosion = mix(erosion, 0.5, smoothstep(0.18, 0.65, footprint * 28.0));
    wisps = mix(wisps, 0.5, smoothstep(0.18, 0.65, footprint * 59.0));
    float cap = 0.34 * pow(abs(p.z * 2.0 - 1.0), 1.65);
    float density = weather - 0.51 + (body - 0.5) * 0.43
        + (towers - 0.5) * 0.12 + (erosion - 0.5) * 0.16
        + (wisps - 0.5) * 0.045 - cap;
    return max(density, 0.0) * 8.0;
}
// Premultiplied radiance and opacity from twelve static density slices. At
// local noon the direct light traverses the short vertical cloud column; its
// extinction darkens interiors while low-order multiple scattering keeps
// undersides soft. Empty regional columns skip the integration completely.
vec4 cloudVolume(vec2 world, vec2 localSurface, vec2 viewSlant,
                 float footprint, float transit) {
    float weatherBase = weatherCover(world);
    float weatherTop = weatherCover(world + viewSlant);
    float destinationOpening = exp(-dot(localSurface * vec2(1.0, 1.18),
                                       localSurface * vec2(1.0, 1.18)) / 0.105);
    float opening = destinationOpening * (0.27 * (1.0 - transit));
    weatherBase += transit * 0.15 - opening;
    weatherTop += transit * 0.15 - opening;
    if (max(weatherBase, weatherTop) < 0.385) return vec4(0.0);
    float transmittance = 1.0;
    vec3 radiance = vec3(0.0);
    for (int i = 0; i < 12; ++i) {
        float h = 1.0 - (float(i) + 0.5) / 12.0;
        vec2 q = world + viewSlant * h;
        float weather = mix(weatherBase, weatherTop, h);
        float d = cloudDensity(vec3(q, h), weather, footprint);
        if (d <= 0.001) continue;
        // Two short overhead probes follow the sun. Local billows shade
        // one another rather than sharing a flat tint.
        float sunNear = cloudDensity(vec3(q, h + 0.08), weather, footprint);
        float sunFar = cloudDensity(vec3(q, h + 0.24), weather, footprint);
        float above = sunNear * 0.95 + sunFar * 1.4;
        float direct = exp(-above * 1.15);
        float multiScatter = 0.33 + 0.32 * exp(-above * 0.45);
        // Amber is concentrated in illuminated tops; the shaded body keeps
        // a deeper neutral/slate color instead of inheriting a sepia wash.
        vec3 light = vec3(0.035, 0.052, 0.058) * multiScatter
            + vec3(0.67, 0.485, 0.250) * direct;
        float opacity = 1.0 - exp(-d * 0.47);
        radiance += transmittance * opacity * light;
        transmittance *= 1.0 - opacity;
        if (transmittance < 0.018) break;
    }
    return vec4(radiance, 1.0 - transmittance);
}

float lane(float x, float width) {
    float d = abs(fract(x + 0.5) - 0.5);
    float aa = max(fwidth(x), 0.0004);
    return 1.0 - smoothstep(width, width + aa, d);
}
// Compact inset lots: every parcel contains an actual roof footprint surrounded
// by streets/courtyards, rather than coloring entire giant square noise cells.
vec4 buildingAt(vec2 city, float core, float industry) {
    float frequency = mix(188.0, 94.0, step(0.42, industry));
    vec2 p = city * frequency;
    vec2 cell = floor(p);
    vec4 seed = lattice(cell + floor(regionOffset * 13.0));
    vec2 halfSize = mix(vec2(0.23, 0.24), vec2(0.42, 0.41), seed.xy);
    halfSize = mix(halfSize, vec2(0.43, 0.34), industry);
    vec2 lot = abs(fract(p) - 0.5);
    float inside = step(lot.x, halfSize.x) * step(lot.y, halfSize.y);
    float majorStreet = max(lane(city.x * 31.3333, 0.062),
                            lane(city.y * 31.3333, 0.062));
    float occupancy = step(seed.w, 0.56 + core * 0.40 + industry * 0.22);
    float height = 0.0013 + pow(seed.z, 2.0) * (0.0028 + core * 0.020);
    height = mix(height, 0.0020 + seed.z * 0.0012, industry);
    return vec4(height * inside * occupancy * (1.0 - majorStreet),
                seed.z, seed.w, max(lot.x / halfSize.x, lot.y / halfSize.y));
}
vec3 urbanSurface(vec2 localSurface, vec2 world, vec3 base, float density, float surveyMode) {
    vec2 warp = vec2(noise(world * 0.92 + 4.8), noise(world * 0.92 + 18.1)) - 0.5;
    vec2 city = mat2(0.965, -0.262, 0.262, 0.965) * (localSurface + warp * 0.035);
    float core = exp(-dot((localSurface - vec2(0.02, 0.08)) * vec2(3.3, 3.0),
                          (localSurface - vec2(0.02, 0.08)) * vec2(3.3, 3.0)));
    vec2 industrialDistance = (localSurface - vec2(0.28, -0.19)) * vec2(3.4, 6.0);
    float industry = exp(-dot(industrialDistance, industrialDistance));
    float road = max(lane(city.x * 31.3333, 0.062), lane(city.y * 31.3333, 0.062));
    float ring = 1.0 - smoothstep(0.005, 0.011,
        abs(length(localSurface * vec2(1.0, 0.82)) - 0.43));
    float radial = 1.0 - smoothstep(0.005, 0.012,
        abs(localSurface.y - sin(localSurface.x * 2.6) * 0.10 - 0.055));
    float highway = max(ring, radial) * (1.0 - surveyMode);
    vec3 ground = mix(base, vec3(0.025, 0.027, 0.025), max(road, highway) * 0.80);
    float roadMark = max(lane(city.x * 31.3333, 0.008), lane(city.y * 31.3333, 0.008));
    ground += vec3(0.014, 0.012, 0.008) * roadMark;
    // At regional scale roofs filter to dense city fabric. At city scale
    // analytically intersect nearby extruded lots: a finite two-by-eight
    // neighborhood avoids layer stepping, disconnected roof strips and holes.
    float pixel = max(length(dFdx(city)), length(dFdy(city)));
    vec4 lot = buildingAt(city, core, industry);
    vec2 hitCity = city;
    float rayHeight = 0.0;
    float faceShade = 0.32;
    if (descent >= 0.50 && pixel < 0.006 && highway < 0.2) {
        float frequency = mix(188.0, 94.0, step(0.42, industry));
        vec2 cellOrigin = floor(city * frequency);
        vec2 ray = vec2(0.20, -1.65);
        for (int row = 0; row < 8; ++row) {
            for (int column = 0; column < 2; ++column) {
                vec2 cell = cellOrigin + vec2(float(column), -float(row));
                vec4 seed = lattice(cell + floor(regionOffset * 13.0));
                vec2 halfSize = mix(vec2(0.23, 0.24), vec2(0.42, 0.41), seed.xy);
                halfSize = mix(halfSize, vec2(0.43, 0.34), industry);
                vec2 lotCenter = (cell + 0.5) / frequency;
                vec4 geometry = buildingAt(lotCenter, core, industry);
                if (geometry.x <= 0.0001) continue;
                vec2 t0 = (lotCenter - halfSize / frequency - city) / ray;
                vec2 t1 = (lotCenter + halfSize / frequency - city) / ray;
                vec2 entry = min(t0, t1), leave = max(t0, t1);
                float enterHeight = max(0.0, max(entry.x, entry.y));
                float leaveHeight = min(geometry.x, min(leave.x, leave.y));
                if (leaveHeight >= enterHeight && leaveHeight > rayHeight) {
                    rayHeight = leaveHeight;
                    hitCity = city + ray * leaveHeight;
                    lot = geometry;
                    faceShade = leave.x < leave.y ? 0.24 : 0.36;
                }
            }
        }
    }
    float detail = 1.0 - smoothstep(0.0014, 0.0055, pixel);
    float roof = step(0.0002, lot.x) * (1.0 - highway);
    float facade = smoothstep(0.0009, 0.0022, lot.x - rayHeight);
    vec3 concrete = mix(vec3(0.125, 0.110, 0.084), vec3(0.370, 0.340, 0.266), lot.y);
    vec3 glass = mix(vec3(0.027, 0.041, 0.040), vec3(0.065, 0.078, 0.070), lot.z);
    vec3 roofColor = mix(concrete, glass, core * step(0.65, lot.z));
    roofColor = mix(roofColor, vec3(0.24, 0.22, 0.17), industry * 0.46);
    float terrace = step(0.88, fract(lot.y * 37.0 + hitCity.x * 420.0))
        * (1.0 - facade);
    roofColor *= 0.91 + terrace * 0.13;
    float windows = 0.86 + 0.14 * smoothstep(0.45, 0.80,
        sin(rayHeight * 7600.0) * sin(hitCity.x * 2400.0));
    roofColor *= mix(1.0, faceShade * windows, facade);
    float aggregate = 0.62 + (noise(city * 188.0) - 0.5) * 0.23;
    vec3 farFabric = mix(base, vec3(0.125, 0.113, 0.087), aggregate);
    ground = mix(farFabric, ground, detail);
    ground = mix(ground, roofColor, roof * detail);
    return mix(base, ground, density);
}

vec3 orbitalEarth(vec2 screen) {
    // Four optical snapshots share one world point and a fixed high-noon sun.
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
    vec3 sunDir = normalize(vec3(focal, focalZ));
    float ndl = dot(normal, sunDir);
    float sun = max(0.0, ndl);
    float daylight = smoothstep(-0.08, 0.20, ndl);
    float night = 1.0 - smoothstep(-0.18, 0.06, ndl);
    vec2 localSurface = (p - focal) * 7.0 / (0.34 + z);
    vec2 world = localSurface + vec2(2.0, -0.5) + regionOffset;
    float targetRadius = length(localSurface * vec2(0.92, 1.08));
    float metroEnvelope = exp(-targetRadius * targetRadius * 3.4);

    vec2 terrainWarp = vec2(fractal(world * 0.43, 3),
                            fractal(world * 0.43 + vec2(7.4, 3.2), 3)) - 0.5;
    float continent = fbm(world * 0.38 + terrainWarp * 1.2);
    continent += exp(-targetRadius * targetRadius * 1.6) * 0.20;
    float land = smoothstep(0.49, 0.515, continent);
    float shallows = smoothstep(0.45, 0.505, continent) * (1.0 - land);
    float terrain = fbm(world * 5.4);
    float ridge = 1.0 - abs(2.0 * fbm(world * 19.0 + terrainWarp) - 1.0);
    float relief = fractal(world * 110.0, 4);
    float moisture = fbm(world * 1.7 + vec2(12.1, 4.6));
    vec3 dry = mix(vec3(0.065, 0.045, 0.028), vec3(0.205, 0.164, 0.104), terrain);
    vec3 vegetation = mix(vec3(0.027, 0.034, 0.023), vec3(0.089, 0.090, 0.052), terrain);
    vec3 soil = mix(dry, vegetation, smoothstep(0.45, 0.64, moisture));
    soil *= 0.72 + ridge * 0.24 + relief * 0.13;
    vec3 ocean = mix(vec3(0.005, 0.023, 0.039), vec3(0.014, 0.083, 0.094), shallows);
    vec3 ground = mix(ocean, soil, land);
    float surveyPresent = hasSurvey != 0
        ? step(0.01, texture2D(surveyTex, vec2(0.5)).a) : 0.0;
    // An urban basin and river establish a region on maps without a survey.
    // A valid survey supplies the river geography instead; invented arteries
    // must not run into its boundary in a different direction.
    float riverDistance = abs(localSurface.x + 0.17
        - 0.085 * sin(localSurface.y * 3.8) - 0.025 * sin(localSurface.y * 10.5));
    float river = (1.0 - smoothstep(0.019, 0.034, riverDistance))
        * metroEnvelope * (1.0 - surveyPresent);
    ground = mix(ground, ocean * 1.8, river);
    float settlements = smoothstep(0.54, 0.70, fbm(world * 3.2 + vec2(8.0, 1.7)));
    float population = max(settlements * 0.64, metroEnvelope);
    float urban = land * population * (1.0 - river);
    if (descent >= 0.18) ground = urbanSurface(localSurface, world, ground, urban, surveyPresent);
    else ground = mix(ground, vec3(0.105, 0.092, 0.065), urban * 0.45);

    // A clean map survey is the actual geographic base. Coordinates use the
    // same exponential magnification as target telemetry and end at exact
    // screen UVs. Blue/teal water and dark road corridors retain their layout;
    // only bright land parcels receive roof-scale relief.
    vec2 uv = screen / vec2(aspect, 1.0) + 0.5;
    vec2 surveyUV = (uv - 0.5) * exp2(3.28 * (1.0 - descent)) + 0.5;
    float surveyWeight = 0.0;
    if (hasSurvey != 0 && all(greaterThanEqual(surveyUV, vec2(0.0)))
                       && all(lessThanEqual(surveyUV, vec2(1.0)))) {
        vec4 sampleMap = texture2D(surveyTex, surveyUV);
        float mapEdge = min(min(surveyUV.x, 1.0 - surveyUV.x),
                            min(surveyUV.y, 1.0 - surveyUV.y));
        surveyWeight = sampleMap.a * smoothstep(0.0, 0.045, mapEdge)
            * smoothstep(0.18, 0.58, descent);
        vec3 survey = pow(max(sampleMap.rgb, vec3(0.0)), vec3(2.2));
        float mapLuma = dot(survey, vec3(0.299, 0.587, 0.114));
        float water = smoothstep(0.005, 0.06, survey.g - survey.r)
            * smoothstep(0.002, 0.04, survey.b - survey.r);
        // Warm/tan ground is buildable too. A neutral-grey test incorrectly
        // rejected this destination's sand-colored urban parcels, and green
        // relative to the red/blue mean confused ochre with vegetation.
        float park = smoothstep(0.018, 0.075, survey.g - survey.r)
            * (1.0 - water);
        float buildable = smoothstep(0.038, 0.15, mapLuma)
            * (1.0 - water) * (1.0 - park);
        // The same analytic city treatment now inhabits the real map. Its
        // coordinates come from surveyUV, so roofs magnify with actual roads;
        // dark corridors, water and parks cannot receive invented buildings.
        vec2 surveyLocal = (surveyUV - 0.5) * vec2(aspect, 1.0) * 0.30;
        survey = mix(survey, vec3(mapLuma), 0.16);
        survey *= mix(0.40, 0.58, water);
        survey = urbanSurface(surveyLocal, surveyLocal + regionOffset + vec2(2.0, -0.5),
                              survey, buildable, 1.0);
        float boundaryHaze = sampleMap.a * (1.0 - sampleMap.a) * 4.0;
        survey = mix(survey, vec3(0.125, 0.117, 0.093), boundaryHaze * 0.24);
        ground = mix(ground, survey, surveyWeight);
        land = mix(land, 1.0 - water, surveyWeight);
        urban = max(urban, surveyWeight * buildable);
    }

    // Sun direction never changes with scale, weather, region, or transit.
    vec3 halfVec = normalize(sunDir + vec3(0.0, 0.0, 1.0));
    float glint = pow(max(dot(normal, halfVec), 0.0), 95.0) * (1.0 - land) * daylight;
    ground *= mix(0.10, 0.72 + sun * 0.28, daylight);
    ground *= mix(vec3(0.86, 1.0, 1.12), vec3(1.06, 0.95, 0.78), land);
    ground += vec3(0.50, 0.32, 0.115) * glint * 0.34;

    float footprint = max(length(dFdx(world)), length(dFdy(world)));
    vec2 lightTangent = sunDir.xy - normal.xy * ndl;
    float shadowWeather = weatherCover(world - lightTangent * 0.035);
    float cloudShadow = smoothstep(0.51, 0.78, shadowWeather)
        * (1.0 - exp(-targetRadius * targetRadius / 0.12));
    ground *= 1.0 - cloudShadow * daylight * 0.42;

    // Retain deterministic smoke, dust and ash incidents. Their source and
    // downwind direction belong to the region, not the animation clock.
    float incidentSeed = noise(floor(regionOffset * 0.37 + vec2(11.0, 29.0)));
    float angle = 6.2831853 * noise(floor(regionOffset.yx * 0.29 + vec2(5.0, 17.0)));
    vec2 incidentSource = vec2(
        mix(-0.29, 0.28, noise(floor(regionOffset + vec2(31.0, 7.0)))),
        mix(-0.22, 0.24, noise(floor(regionOffset + vec2(13.0, 43.0)))));
    vec2 iq = mat2(cos(angle), -sin(angle), sin(angle), cos(angle))
        * (localSurface - incidentSource);
    float downwind = smoothstep(-0.022, 0.04, iq.x)
        * (1.0 - smoothstep(0.27, 0.85, iq.x));
    float width = 0.012 + max(iq.x, 0.0) * 0.13;
    float smoke = exp(-iq.y * iq.y / max(width * width, 0.0001)) * downwind;
    smoke *= smoothstep(0.23, 0.67, fbm(world * 28.0 + incidentSeed * 17.0));
    smoke *= land * smoothstep(0.12, 0.58, descent);
    vec3 smokeColor = incidentSeed < 0.66 ? vec3(0.065, 0.057, 0.044)
                                         : vec3(0.040, 0.042, 0.038);
    ground = mix(ground, smokeColor, smoke * 0.72);
    float hotSource = exp(-dot(localSurface - incidentSource, localSurface - incidentSource) * 62000.0);
    ground += vec3(0.42, 0.09, 0.007) * hotSource * step(0.68, incidentSeed)
        * land * smoothstep(0.30, 0.70, descent);

    vec4 clouds = cloudVolume(world, localSurface,
        vec2(p.x, -0.75 - p.y * 0.2) * 0.42, footprint, 0.0);
    vec3 lit = ground * (1.0 - clouds.a) + clouds.rgb;
    // Thin high cirrus and industrial aerosol remain separate from billowing
    // weather so the region retains more than one atmospheric scale/type.
    float cirrus = smoothstep(0.69, 0.86, fractal(world * vec2(2.3, 8.4) + 21.2, 3));
    lit = mix(lit, vec3(0.22, 0.177, 0.115), cirrus * 0.075);
    float aerosol = (0.022 + urban * 0.060) * (0.62 + fbm(world * 1.2 + 6.0))
        * mix(0.20, 1.0, land);
    lit = mix(lit, vec3(0.19, 0.133, 0.067), aerosol);
    // Settlement light variation is preserved; the fixed noon day factor
    // suppresses artificial night lights for this arrival.
    float cells = step(0.96, noise(floor(world * 162.0)));
    lit += vec3(1.0, 0.46, 0.12) * land * population * cells * night
        * (1.0 - clouds.a) * 2.5;
    float luma = dot(lit, vec3(0.299, 0.587, 0.114));
    lit = mix(lit, vec3(luma), 0.10);
    // Warm, dusty atmospheric depth is established in the very first frame.
    // A restrained cold outer edge remains above the aerosol limb.
    float airMass = pow(1.0 - z, 3.4);
    lit = mix(lit, vec3(0.13, 0.104, 0.069), airMass * 0.54);
    float innerRim = exp(-max(1.0 - rr, 0.0) * 110.0) * edge;
    lit += vec3(0.27, 0.170, 0.068) * innerRim;
    float outerRim = exp(-max(rr - 1.0, 0.0) * 185.0) * (1.0 - edge);
    vec3 space = vec3(0.0004, 0.0007, 0.0009);
    vec3 scene = mix(space, lit, edge) + vec3(0.060, 0.070, 0.066) * outerRim;
    return displayColor(scene * 0.90);
}

vec3 passingClouds(vec2 screen) {
    // The camera advances through a frozen volume. No animated noise offsets
    // or weather morphs: scale alone changes as the optical path approaches.
    float scale = exp2(mix(1.0, -0.75, cloudDescent));
    vec2 world = screen * scale + vec2(4.7, 8.2) + regionOffset;
    float footprint = max(length(dFdx(world)), length(dFdy(world)));
    vec4 volume = cloudVolume(world, vec2(4.0), vec2(0.30, -0.92), footprint, 1.0);
    float broad = noise(world * 0.73 + 12.7);
    vec3 atmosphere = mix(vec3(0.041, 0.045, 0.042), vec3(0.13, 0.113, 0.080), broad);
    vec3 color = atmosphere * (1.0 - volume.a) + volume.rgb;
    return displayColor(color);
}

void main() {
    vec2 screen = (gl_TexCoord[0].st - 0.5) * vec2(aspect, 1.0);
    float cloudScene = smoothstep(0.25, 0.40, cloudDescent);
    vec3 scene;
    if (cloudScene >= 1.0) {
        scene = passingClouds(screen);
    } else {
        scene = orbitalEarth(screen);
        if (cloudScene > 0.0) scene = mix(scene, passingClouds(screen), cloudScene);
    }
    // This alpha is the compositor's projection cover, not planetary clouds.
    // Preserve its fully opaque handoff until the shared compositor advances.
    float cover = smoothstep(0.23, 0.39, cloudDescent)
                * (1.0 - smoothstep(0.55, 0.98, cloudDescent));
    gl_FragColor = vec4(scene, cover);
}
