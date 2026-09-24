#version 150 compatibility
in float worldHeight;
in vec2 sourceUV;
flat in vec3 ribbonColor;
flat in int ribbon;
uniform vec2 heightRange;
uniform sampler2D sourceTex;
uniform sampler2D materialTex;
uniform int textured;
uniform int materialMasked = 0;
uniform float emissionStrength = 1.0;
void main()
{
    if(worldHeight<heightRange.x || worldHeight>=heightRange.y) discard;
    vec3 color=vec3(1.0);
    if(textured!=0) color=ribbon!=0 ? ribbonColor : texture2D(sourceTex,sourceUV).rgb;
    // Spring texture 2: red self-illumination, alpha model coverage. For thin
    // projected faces the geometry shader already averaged masked samples.
    if(materialMasked!=0 && ribbon==0) {
        vec4 material=texture2D(materialTex,sourceUV);
        color*=material.r*material.a;
    }
    // Hologram diffuse alpha is not an emission mask (the hologram shader also
    // uses RGB). Black texels emit nothing; visible-piece registration is kept.
    color=max(color*gl_Color.rgb*emissionStrength,vec3(0.0));
    if(max(color.r,max(color.g,color.b))<=0.001) discard;
    gl_FragColor=vec4(color,1.0);
}
