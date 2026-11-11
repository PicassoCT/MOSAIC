#version 150 compatibility
uniform sampler2D buildingMask;
uniform vec2 viewportOrigin;
out vec4 fragColor;
const ivec2 directions[8] = ivec2[8](
    ivec2(1,0), ivec2(-1,0), ivec2(0,1), ivec2(0,-1),
    ivec2(1,1), ivec2(-1,1), ivec2(1,-1), ivec2(-1,-1));
void main() {
    ivec2 p = ivec2(gl_FragCoord.xy - viewportOrigin);
    ivec2 limit = textureSize(buildingMask, 0) - ivec2(1);
    vec4 center = texelFetch(buildingMask, p, 0);
    if (all(lessThan(center.rgb, vec3(0.5 / 255.0)))) discard;

    float selected = step(0.5, center.a);
    float nearest = 5.0;
    for (int radius = 1; radius <= 4; ++radius) {
        for (int i = 0; i < 8; ++i) {
            ivec2 offset = directions[i] * radius;
            vec3 neighbour = texelFetch(buildingMask, clamp(p + offset, ivec2(0), limit), 0).rgb;
            if (any(greaterThan(abs(neighbour - center.rgb), vec3(0.5 / 255.0)))) {
                nearest = min(nearest, length(vec2(offset)) - 0.5);
            }
        }
    }
    // Draw inward from the visible union boundary. No halo can spill over
    // foreground terrain/units, and no piece or voxel boundary creates a rim.
    float core = 1.0 - smoothstep(mix(1.6, 2.1, selected), mix(3.1, 3.7, selected), nearest);
    float glow = 1.0 - smoothstep(1.5, 4.0, nearest);
    vec3 face = mix(vec3(0.10,0.65,0.85), vec3(1.0,0.62,0.16), selected) * 0.65;
    vec3 rim = mix(vec3(0.25,0.92,1.0), vec3(1.0,0.79,0.30), selected);
    float detail = center.a - selected * 0.5;
    fragColor = vec4(mix(face, rim, core), min(0.98, detail + 0.80 * core + 0.10 * glow));
}
