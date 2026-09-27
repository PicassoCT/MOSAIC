#version 150 compatibility
uniform sampler2D materialTex;
in vec3 worldPosition;
in vec3 worldNormal;
in vec2 sourceUV;
// WINDOW_CLASSIFY
void main(){
    vec4 m=texture2D(materialTex,sourceUV);vec3 n=normalize(worldNormal);
    if(m.r<0.05 || m.a<0.5 || abs(n.y)>0.8)discard;
    bool exterior=exteriorWindow(worldPosition,normalize(n.xz));
    gl_FragColor=vec4(exterior?vec3(0.05,1,0.12):vec3(1,0.04,0.03),0.85);
}
