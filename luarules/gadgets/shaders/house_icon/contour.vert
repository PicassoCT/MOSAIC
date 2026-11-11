#version 150 compatibility
void main() {
    // Clip-space quad; independent of the current world camera matrices.
    gl_Position = gl_Vertex;
}
