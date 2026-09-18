// Included before rainShader.frag main. Existing rain masks supply drop coverage.
uniform sampler2D rainRadianceTex;
uniform sampler2D rainOccupancyTex;
uniform sampler2D rainLocalRadianceTex;
uniform sampler2D rainLocalOccupancyTex;
uniform float rainLightActive;
uniform float rainLocalActive;
uniform vec2 rainMapSize;
uniform vec2 rainLightHeight;
uniform vec2 rainLocalOrigin;
uniform float rainLocalSpan;
uniform float rainLightIntensity;
uniform float rainLightStrength;
uniform float glitterTime;

vec3 rainLocalLight(vec3 p) {
    if (p.y < rainLightHeight.x || p.y >= rainLightHeight.y) return vec3(0);
    vec2 at = p.xz / rainMapSize;
    if (any(lessThan(at, vec2(0))) || any(greaterThanEqual(at, vec2(1)))) return vec3(0);
    vec3 light;
    vec2 localUV = (p.xz - rainLocalOrigin) / max(rainLocalSpan, 1.0);
    // Choose one field, not both. Two texture samples per illuminated drop layer.
    if (rainLocalActive > 0.5 && all(greaterThan(localUV, vec2(0.15))) &&
        all(lessThan(localUV, vec2(0.85)))) {
        if (texture2D(rainLocalOccupancyTex, localUV).r > 0.5) return vec3(0);
        light = texture2D(rainLocalRadianceTex, localUV).rgb;
    } else {
        if (texture2D(rainOccupancyTex, at).r > 0.5) return vec3(0);
        light = texture2D(rainRadianceTex, at).rgb;
    }
    return (vec3(1) - exp(-max(light, vec3(0)) * rainLightStrength)) * rainLightIntensity;
}
vec3 rainDropGlitter(vec3 surface, float mask, float distanceFromSurface) {
    if (rainLightActive < 0.5 || mask < 0.08) return vec3(0);
    vec3 toEye = eyePos - surface;
    float distanceToEye = length(toEye);
    if (distanceToEye < 0.001) return vec3(0);
    // Two representative layers in front of the visible surface. Never sample
    // behind a wall or beyond the camera; this is not a volumetric light march.
    vec3 drop = surface + toEye / distanceToEye * min(distanceFromSurface, distanceToEye * 0.5);
    vec3 light = rainLocalLight(drop);
    vec3 q = fract(floor(drop * 0.25) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    float seed = fract((q.x + q.y) * q.z);
    float pulse = 0.5 + 0.5 * sin(glitterTime * 5.0 + seed * 31.0);
    float glint = smoothstep(0.55, 0.95, pulse);
    return light * smoothstep(0.08, 0.6, mask) * (0.15 + glint * 0.7);
}
