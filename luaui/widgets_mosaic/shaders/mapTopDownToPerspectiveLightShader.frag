#version 150 compatibility

uniform sampler2D neonLightTex;
uniform sampler2D depthTex;

uniform vec2 worldMin;
uniform vec2 worldMax;
uniform mat4 invProjView;

in vec2 screenUV;

out vec4 fragColor;

void main() {
    float depth = texture(depthTex, screenUV).r;

    // Reconstruct world position:
    vec4 ndc = vec4(screenUV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 worldPos4 = invProjView * ndc;
    vec3 worldPos = worldPos4.xyz / worldPos4.w;

    // Map world XZ into neon light UV:
    vec2 lightUV;
    lightUV.x = (worldPos.x - worldMin.x) / (worldMax.x - worldMin.x);
    lightUV.y = (worldPos.z - worldMin.y) / (worldMax.y - worldMin.y);

    vec4 lightColor = texture(neonLightTex, lightUV);

    // Combine with scene color — here simply output light:
    fragColor = lightColor;
}
