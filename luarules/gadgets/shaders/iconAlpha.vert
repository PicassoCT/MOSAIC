#version 150 compatibility

out vec2 iconUV;

void main()
{
    iconUV = gl_MultiTexCoord0.st;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
