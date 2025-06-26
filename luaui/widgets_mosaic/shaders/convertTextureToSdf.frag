#version 300 es
precision highp float;

in vec2 v_uv; // Pass in from vertex shader (UV coords)
out float outSDF; // Output single-channel distance value

uniform sampler2D u_glowTexture;
uniform vec2 u_texSize;     // Texture size in pixels
uniform float u_threshold;  // Intensity threshold to consider "inside" glow
uniform float u_maxDist;    // Max distance in pixels to search

void main() {
    vec2 texelSize = 1.0 / u_texSize;

    float centerValue = texture(u_glowTexture, v_uv).r;
    bool inside = centerValue > u_threshold;

    float minDist = u_maxDist;

    // Convert maxDist from pixels to texture space
    int maxSteps = int(u_maxDist);

    for (int dx = -maxSteps; dx <= maxSteps; ++dx) {
        for (int dy = -maxSteps; dy <= maxSteps; ++dy) {
            vec2 offset = vec2(float(dx), float(dy)) * texelSize;
            vec2 sampleUV = v_uv + offset;

            // Clamp UV to prevent sampling outside
            if (sampleUV.x < 0.0 || sampleUV.y < 0.0 || sampleUV.x > 1.0 || sampleUV.y > 1.0) continue;

            float sample = texture(u_glowTexture, sampleUV).r;
            bool sampleInside = sample > u_threshold;

            if (sampleInside != inside) {
                float dist = length(offset * u_texSize); // Back to pixel units
                if (dist < minDist) {
                    minDist = dist;
                }
            }
        }
    }

    // Signed distance
    float signedDist = inside ? -minDist : minDist;

    // Optional: normalize for storage (e.g., map [-u_maxDist, +u_maxDist] → [0, 1])
    outSDF = 0.5 + signedDist / (2.0 * u_maxDist);
}
