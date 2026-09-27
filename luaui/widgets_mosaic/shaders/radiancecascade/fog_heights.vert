#version 150 compatibility
out vec2 worldXZ;
void main() {
    worldXZ=gl_MultiTexCoord0.st;
    gl_Position=gl_Vertex;
}
