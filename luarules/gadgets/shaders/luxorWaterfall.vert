#version 150 compatibility

uniform mat4 viewInverse;
out vec3 worldPosition;
out vec3 worldNormal;
out vec2 materialUV;

void main()
{
    vec4 viewPosition = gl_ModelViewMatrix * gl_Vertex;
    worldPosition = (viewInverse * viewPosition).xyz;
    worldNormal = normalize(mat3(viewInverse) * gl_NormalMatrix * gl_Normal);
    materialUV = gl_MultiTexCoord0.xy;
    gl_Position = gl_ProjectionMatrix * viewPosition;
}
