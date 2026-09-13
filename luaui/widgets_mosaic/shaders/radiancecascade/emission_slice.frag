#version 150 compatibility
varying float worldHeight;
uniform vec2 heightRange;
void main()
{
    if(worldHeight<heightRange.x || worldHeight>=heightRange.y) discard;
    gl_FragColor=gl_Color;
}
