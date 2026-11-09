#version 150 compatibility
out vec2 faceUV;
out float localHeight;
void main() {
    faceUV = gl_MultiTexCoord0.xy;
    localHeight = gl_Vertex.y;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
