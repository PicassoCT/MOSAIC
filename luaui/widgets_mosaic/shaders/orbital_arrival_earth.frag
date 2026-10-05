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
    for (int i = 0; i < 4; i++) {
        result += noise(p) * weight;
        p = mat2(1.6, -1.2, 1.2, 1.6) * p + 13.7;
        weight *= 0.5;
    }
    return result;
}

void main() {
    vec2 uv = gl_TexCoord[0].st;
    vec2 screen = (uv - 0.5) * vec2(aspect, 1.0);
    // Low orbit: most of Earth lies outside the frame, with a curved blue limb.
    // Growing this screen-space sphere supplies the entire apparent zoom.
    float dive = smoothstep(0.10, 0.50, descent);
    float radius = mix(1.68, 6.0, dive);
    vec2 p = (screen - vec2(0.0, -1.07 + 0.72 * dive)) / radius;
    float rr = dot(p, p);
    float edge = 1.0 - smoothstep(0.995, 1.005, rr);
    float z = sqrt(max(0.0, 1.0 - rr));
    vec3 normal = normalize(vec3(p, max(z, 0.001)));
    float sun = max(0.0, dot(normal, normalize(vec3(-0.6, 0.8, 0.9))));
    vec2 surface = p * 6.0 / (0.32 + z) + vec2(2.4, 0.0);
    // Regional coast and terrain, deliberately cinematic rather than a globe atlas.
    float land = smoothstep(0.43, 0.49, fbm(surface));
    float terrain = fbm(surface * 7.0);
    vec3 ground = mix(vec3(0.012, 0.09, 0.18),
                      mix(vec3(0.15, 0.19, 0.11), vec3(0.56, 0.43, 0.27), terrain), land);
    float surfaceCloud = smoothstep(0.48, 0.75, fbm(surface * 3.0 + vec2(elapsed * 0.001, 0.0)));
    ground = mix(ground, vec3(0.83, 0.88, 0.93), surfaceCloud * 0.9);
    ground *= 0.15 + sun * 0.94;
    float rim = pow(1.0 - z, 5.0);
    ground += vec3(0.09, 0.37, 0.70) * rim;
    vec3 space = vec3(0.003, 0.007, 0.018);
    float star = step(0.9985, hash(floor(uv * vec2(900.0, 500.0))));
    space += vec3(star * 0.4);
    float halo = exp(-abs(rr - 1.0) * 95.0) * (1.0 - edge);
    vec3 earth = mix(space, ground, edge) + vec3(0.08, 0.30, 0.62) * halo;

    // Layered clouds expand away from the point of entry. The middle is fully
    // opaque so unrelated projections can switch invisibly underneath it.
    float scale = mix(7.0, 0.85, smoothstep(0.25, 0.85, descent));
    float cloudNoise = fbm(screen * scale + vec2(4.7, 8.2));
    float enter = smoothstep(0.22, 0.42, descent);
    float leave = 1.0 - smoothstep(0.56, 1.0, descent);
    float opaque = 1.0 - smoothstep(0.56, 0.68, descent);
    float strands = smoothstep(0.20, 0.68, cloudNoise);
    float cover = enter * leave * mix(strands, 1.0, opaque);
    // RGB holds Earth, alpha holds cloud opacity for the full-resolution pass.
    vec3 cloudColor = vec3(0.74, 0.80, 0.86) + cloudNoise * 0.13;
    gl_FragColor = vec4(mix(earth, cloudColor, smoothstep(0.35, 0.42, descent)), cover);
}
