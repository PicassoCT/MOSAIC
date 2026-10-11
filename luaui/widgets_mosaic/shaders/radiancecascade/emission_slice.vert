#version 150 compatibility
out float vertexHeight;
out vec4 vertexColor;
out vec2 vertexUV;
uniform int projectToBand = 0;
uniform vec2 heightRange;
void main()
{
    vertexHeight=-(gl_ModelViewMatrix*gl_Vertex).z;
    // The scene field is 2.5D: objective lights project into the receiver band.
    // Keep their actual x/z footprint and animated transforms.
    if(projectToBand!=0) vertexHeight=(heightRange.x+heightRange.y)*0.5;
    gl_Position=gl_ModelViewProjectionMatrix*gl_Vertex;
    vertexColor=gl_Color;
    vertexUV=gl_MultiTexCoord0.st;
}
