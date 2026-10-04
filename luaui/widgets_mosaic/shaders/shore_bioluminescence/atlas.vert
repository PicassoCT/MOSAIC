#version 150 compatibility
out vec2 worldXZ;
void main() {
    gl_Position=gl_Vertex;
    gl_TexCoord[0]=gl_MultiTexCoord0;
    worldXZ=gl_MultiTexCoord1.xy;
}
