#version 150 compatibility
uniform sampler2D previousTex;
uniform sampler2D maskTex;
uniform float previousTime;
uniform float lineWidth;
in vec2 worldXZ;
// SHORE_COMMON
void main() {
    vec2 uv=gl_TexCoord[0].st;vec4 mask=texture2D(maskTex,uv);
    if(mask.a<0.5 || mask.g<0.001) {gl_FragColor=vec4(0);return;}
    float previous=texture2D(previousTex,uv).r*exp2(-max(0.0,shoreTime-previousTime)/halfLife);
    float fresh=shoreDeposit(worldXZ,mask,previousTime,lineWidth)*step(0.001,intensity);
    gl_FragColor=vec4(max(previous,fresh)*mask.a,0,0,1);
}
