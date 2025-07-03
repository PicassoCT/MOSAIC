#version 150 compatibility


uniform sampler2D depthTex;
uniform sampler2D neonLightTex;

uniform vec2 viewPortSize;
uniform mat4 invProjView;
uniform vec2 worldMin;
uniform vec2 worldMax;


#define RED vec4(1.0,0,0,1.0)



void main() {
    float depth = texture(depthTex, gl_FragCoord.xy).r;

    // Reconstruct world position:
    vec4 ndc = vec4(gl_FragCoord * 2.0 - 1.0, s * 2.0 - 1.0, 1.0);
    vec4 worldPos4 = invProjView * ndc;
    vec3 worldPos = worldPos4.xyz / worldPos4.w;

    // Map world XZ into neon light UV:
    vec2 lightUV;
    lightUV.x = (worldPos.x - worldMin.x) / (worldMax.x - worldMin.x);
    lightUV.y = (worldPos.z - worldMin.y) / (worldMax.y - worldMin.y);

    vec4 lightColor =  texture(lightUV,lightUV);

    // Combine with scene color — here simply output light:
    gl_FragColor = lightColor;
    gl_FragColor = RED;
}
