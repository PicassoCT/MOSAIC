#version 150 compatibility
in vec2 faceUV;
in float localHeight;
uniform float time;
uniform float height;
uniform float selected;
out vec4 fragColor;
void main() {
    // Derivatives keep the border approximately one pixel wide at any zoom.
    vec2 d = min(faceUV, 1.0 - faceUV);
    vec2 aa = max(fwidth(faceUV), vec2(0.0001));
    float edge = 1.0 - smoothstep(0.65, 1.8, min(d.x / aa.x, d.y / aa.y));
    float h = localHeight * height;
    float phase = h / 10.0 - time * 0.18;
    float width = max(fwidth(phase), 0.03);
    float scan = 1.0 - smoothstep(0.06, 0.06 + width, abs(fract(phase) - 0.5));
    vec3 cyan = mix(vec3(0.10, 0.65, 0.85), vec3(1.0, 0.62, 0.16), selected);
    fragColor = vec4(cyan * (0.65 + 0.35 * edge), 0.07 + 0.55 * edge + 0.09 * scan);
}
