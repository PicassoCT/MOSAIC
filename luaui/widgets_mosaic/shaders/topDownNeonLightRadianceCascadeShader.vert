#version 150 compatibility


uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;
uniform samplerCube radianceCascade;

out vec3 vWorldPos;
out vec3 vNormal;
out vec2 vUV;

void main() {
    vec4 worldPos = uModel * vec4(aPosition, 1.0);
    vWorldPos = worldPos.xyz;
    vNormal = mat3(uModel) * aNormal;
    vUV = aUV;
}
