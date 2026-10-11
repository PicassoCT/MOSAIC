#version 150 compatibility
uniform sampler2D historyTex;
uniform sampler2D maskTex;
uniform float historyTime;
uniform float lineWidth;
uniform float gain;
uniform int capture;
uniform vec2 heightRange;
in vec2 worldXZ;
// SHORE_COMMON
void main() {
    vec2 uv=gl_TexCoord[0].st;vec4 mask=texture2D(maskTex,uv);
    float h=max(mask.b,0.0);
    if(mask.a<0.5 || mask.g<0.001 || (capture!=0 && (h<heightRange.x || h>=heightRange.y))) discard;
    float width=max(lineWidth,fwidth(mask.r));
    float front=shoreFront(worldXZ,mask,width);
    float trail=texture2D(historyTex,uv).r*exp2(-max(0.0,shoreTime-historyTime)/halfLife);
    float value=(front+0.8*trail)*intensity*gain;
    if(value<0.0001) discard;
    // Cool blue with a greener core, no white blanket or alpha darkening.
    vec3 color=mix(vec3(0.015,0.36,0.8),vec3(0.025,0.95,0.7),clamp(front+0.8*trail,0.0,1.0));
    gl_FragColor=vec4(color*value,0.0);
}
