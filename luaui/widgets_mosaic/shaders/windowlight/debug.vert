#version 150 compatibility
uniform mat4 inverseView;
out vec3 worldPosition;
out vec3 worldNormal;
out vec2 sourceUV;
void main(){
    worldPosition=(inverseView*gl_ModelViewMatrix*gl_Vertex).xyz;
    worldNormal=mat3(inverseView)*gl_NormalMatrix*gl_Normal;
    sourceUV=gl_MultiTexCoord0.st;
    gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;
}
