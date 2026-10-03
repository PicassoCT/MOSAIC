#version 150 compatibility
out vec3 lightWorld;
void main() {
    lightWorld=gl_Vertex.xyz;
    gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;
}
