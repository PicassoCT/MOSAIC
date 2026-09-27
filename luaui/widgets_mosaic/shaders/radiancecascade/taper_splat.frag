#version 150 compatibility
flat in vec3 emitted;
void main()
{
    gl_FragColor = vec4(emitted, 0.0);
}
