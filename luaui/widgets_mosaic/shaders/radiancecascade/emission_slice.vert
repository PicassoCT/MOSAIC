#version 150 compatibility
varying float worldHeight;
void main()
{
    // Capture pass modelview rotates world X/Z into atlas X/Y, so -Z is height.
    worldHeight=-(gl_ModelViewMatrix*gl_Vertex).z;
    gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;
    gl_FrontColor=gl_Color;
}
