#version 150 compatibility
uniform sampler2D previewTex;
uniform float exposure;
void main()
{
    vec3 value=max(texture2D(previewTex,gl_TexCoord[0].st).rgb,vec3(0.0));
    gl_FragColor=vec4(vec3(1.0)-exp(-value*exposure),1.0);
}
