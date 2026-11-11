#version 150 compatibility
in vec2 faceUV;
in float localHeight;
uniform float time;
uniform float selected;
uniform vec3 buildingKey;
out vec4 fragColor;
void main() {
    // Store one identity for every piece of this building. The screen pass
    // finds its combined contour; face borders are only faint interior detail.
    vec2 d = min(faceUV, 1.0 - faceUV);
    vec2 aa = max(fwidth(faceUV), vec2(0.0001));
    float pixels = min(d.x / aa.x, d.y / aa.y);
    float edge = 1.0 - smoothstep(0.4, 1.3, pixels);
    float h = localHeight;
    float phase = h / 10.0 - time * 0.18;
    float width = max(fwidth(phase), 0.03);
    float scan = 1.0 - smoothstep(0.06, 0.06 + width, abs(fract(phase) - 0.5));
    // Reserve half the alpha range for the local selection flag.
    fragColor = vec4(buildingKey, selected * 0.5 + 0.055 + 0.12 * edge + 0.04 * scan);
}
