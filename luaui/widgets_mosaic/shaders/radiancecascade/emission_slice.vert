#version 150 compatibility
out float vertexHeight;
out vec4 vertexColor;
void main()
{
    vertexHeight=-(gl_ModelViewMatrix*gl_Vertex).z;
    gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;
    vertexColor=gl_Color;
}
