#version 150 compatibility
in vec2 faceUV;
in float localHeight;
uniform float time;
uniform float selected;
out vec4 fragColor;
void main() {
    // Pixel-sized borders keep the voxel silhouette readable at strategic zoom.
    // The selected host gets a slightly wider core with the same quiet face fill.
    vec2 d = min(faceUV, 1.0 - faceUV);
    vec2 aa = max(fwidth(faceUV), vec2(0.0001));
    float pixels = min(d.x / aa.x, d.y / aa.y);
    float coreWidth = mix(1.15, 1.65, selected);
    float edge = 1.0 - smoothstep(coreWidth, coreWidth + 1.35, pixels);
    float glow = 1.0 - smoothstep(coreWidth, coreWidth + 3.5, pixels);
    float h = localHeight;
    float phase = h / 10.0 - time * 0.18;
    float width = max(fwidth(phase), 0.03);
    float scan = 1.0 - smoothstep(0.06, 0.06 + width, abs(fract(phase) - 0.5));
    vec3 cyan = mix(vec3(0.10, 0.65, 0.85), vec3(1.0, 0.62, 0.16), selected);
    vec3 rim = mix(vec3(0.25, 0.92, 1.0), vec3(1.0, 0.79, 0.30), selected);
    vec3 color = mix(cyan * 0.65, rim, edge);
    float alpha = 0.07 + 0.78 * edge + 0.12 * glow + 0.09 * scan * (1.0 - edge);
    fragColor = vec4(color, min(alpha, 1.0));
}
