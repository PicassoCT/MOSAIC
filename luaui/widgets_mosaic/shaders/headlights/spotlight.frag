#version 150 compatibility
uniform sampler2D depthTex;
uniform sampler2D occupancyTex;
uniform mat4 inverseProjection;
uniform mat4 inverseView;
uniform vec2 viewport;
uniform vec2 viewportOrigin;
uniform vec2 mapSize;
uniform vec3 lampLeft;
uniform vec3 lampRight;
uniform vec3 forward;
uniform vec3 right;
uniform vec3 up;
uniform float lightRange;
uniform float intensity;
uniform float wetness;
uniform int clipZeroToOne;
uniform int occlusionActive;
uniform vec2 occlusionHeight;

vec3 worldPosition(vec2 uv, float depth) {
    vec4 p = inverseProjection * vec4(uv * 2.0 - 1.0,
        clipZeroToOne != 0 ? depth : depth * 2.0 - 1.0, 1.0);
    return (inverseView * (p / p.w)).xyz;
}
float visibility(vec3 lamp, vec3 world) {
    if (occlusionActive == 0) return 1.0;
    // The atlas contains buildings, never the emitting car. Stop short of
    // the receiver so the exterior face of an occupied wall can be lit.
    float cell = max(mapSize.x, mapSize.y) / float(textureSize(occupancyTex, 0).x);
    float distance = length(world - lamp);
    float endT = max(0.0, 1.0 - cell * 1.5 / max(distance, 1.0));
    for (int i = 0; i < 32; ++i) {
        vec3 p = mix(lamp, world, endT * (float(i) + 0.5) / 32.0);
        vec2 uv = p.xz / mapSize;
        if (p.y >= occlusionHeight.x && p.y < occlusionHeight.y &&
            all(greaterThanEqual(uv, vec2(0))) && all(lessThan(uv, vec2(1))) &&
            texture2D(occupancyTex, uv).r > 0.5) return 0.0;
    }
    return 1.0;
}
vec3 spotlight(vec3 lamp, vec3 world, vec3 normal, vec3 viewDir) {
    vec3 delta = world - lamp;
    float along = dot(delta, forward);
    if (along <= 0.0 || along >= lightRange) return vec3(0);
    float horizontal = dot(delta, right) / max(along, 1.0);
    float vertical = dot(delta, up) / max(along, 1.0);
    // Wide road coverage, a bright centre and a dipped upper cutoff.
    float cone = (1.0 - smoothstep(0.22, 0.52, abs(horizontal))) *
        smoothstep(-0.85, -0.25, vertical) * (1.0 - smoothstep(-0.015, 0.09, vertical));
    float core = exp(-horizontal * horizontal * 42.0);
    float rangeFade = 1.0 - smoothstep(lightRange * 0.65, lightRange, along);
    float distance2 = dot(delta, delta);
    float energy = cone * rangeFade * (0.45 + 0.55 * core) / (1.0 + distance2 / 2200.0);
    if (energy < 0.001) return vec3(0);
    vec3 L = -delta / max(sqrt(distance2), 0.001);
    float diffuse = max(dot(normal, L), 0.0);
    vec3 H = L + viewDir;
    H /= max(length(H), 0.001);
    float fresnel = 0.04 + 0.96 * pow(1.0 - max(dot(normal, viewDir), 0.0), 5.0);
    // Wet highlights only on upward-facing surfaces; no invented reflections
    // of the whole vehicle and no full-screen bloom pass.
    float specular = wetness * smoothstep(0.55, 0.95, normal.y) *
        pow(max(dot(normal, H), 0.0), 48.0) * (0.4 + fresnel * 2.0);
    return vec3(1.0, 0.91, 0.76) * energy * (diffuse * 0.85 + specular * 2.0) * visibility(lamp, world);
}
void main() {
    vec2 uv = (gl_FragCoord.xy - viewportOrigin) / viewport;
    float depth = texture2D(depthTex, uv).r;
    if (depth >= 0.999999) discard;
    vec3 world = worldPosition(uv, depth);
    vec3 camera = (inverseView * vec4(0, 0, 0, 1)).xyz;
    vec3 viewDir = normalize(camera - world);
    // Reconstruct the surface normal from depth. This works with both the
    // legacy forward renderer and Recoil without enabling model shaders.
    vec3 n = cross(dFdx(world), dFdy(world));
    if (dot(n, n) < 1e-12) discard;
    vec3 normal = normalize(n);
    if (dot(normal, viewDir) < 0.0) normal = -normal;
    vec3 light = spotlight(lampLeft, world, normal, viewDir) + spotlight(lampRight, world, normal, viewDir);
    gl_FragColor = vec4((vec3(1.0) - exp(-light * 2.0)) * intensity, 0.0);
}
