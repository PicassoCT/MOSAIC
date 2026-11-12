#version 150 compatibility
uniform sampler2D buildingMask;
uniform sampler2D resolvedDepth;
uniform vec2 viewportOrigin;
out vec4 fragColor;
const ivec2 directions[8] = ivec2[8](
    ivec2(1,0), ivec2(-1,0), ivec2(0,1), ivec2(0,-1),
    ivec2(1,1), ivec2(-1,1), ivec2(1,-1), ivec2(-1,-1));
void main() {
    ivec2 p = ivec2(gl_FragCoord.xy - viewportOrigin);
    ivec2 limit = textureSize(buildingMask, 0) - ivec2(1);
    vec4 center = texelFetch(buildingMask, p, 0);
    bool inside = any(greaterThan(center.rgb, vec3(0.5 / 255.0)));
    float sceneDepth = inside ? 0.0 : texelFetch(resolvedDepth, p, 0).r;

    float selected = step(0.5, center.a);
    float nearest = 7.0;
    for (int radius = 1; radius <= 6; ++radius) {
        for (int i = 0; i < 8; ++i) {
            ivec2 offset = directions[i] * radius;
            ivec2 q = clamp(p + offset, ivec2(0), limit);
            vec4 neighbour = texelFetch(buildingMask, q, 0);
            float distance = length(vec2(offset)) - 0.5;
            if (inside) {
                if (any(greaterThan(abs(neighbour.rgb - center.rgb), vec3(0.5 / 255.0)))) {
                    nearest = min(nearest, distance);
                }
            } else if (distance < nearest && any(greaterThan(neighbour.rgb, vec3(0.5 / 255.0)))) {
                // Empty mask pixels retain scene depth. Permit the outer halo
                // only in front of that scene, never over nearer foreground.
                if (texelFetch(resolvedDepth, q, 0).r <= sceneDepth) {
                    nearest = distance;
                    selected = step(0.5, neighbour.a);
                }
            }
        }
    }
    // The bright core remains inside the combined silhouette; a softer halo
    // spreads around it. Piece and voxel boundaries never create an extra rim.
    float core = inside ? 1.0 - smoothstep(mix(1.6, 2.1, selected), mix(3.1, 3.7, selected), nearest) : 0.0;
    float glow = 1.0 - smoothstep(1.5, 6.0, nearest);
    vec3 rim = mix(vec3(0.25,0.92,1.0), vec3(1.0,0.79,0.30), selected);
    // Add only the whole-building rim/glow over the unchanged wireframe.
    // Interior pixels away from the contour contribute nothing.
    fragColor = vec4(rim, min(0.98, 0.70 * core + (inside ? 0.28 : 0.32) * glow));
}
