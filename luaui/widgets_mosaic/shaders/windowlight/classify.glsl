uniform sampler2D exteriorTex;
uniform vec2 maskOrigin;
uniform float maskSpan;
uniform vec2 buildingY;
int wallBand(float y){return clamp(int(floor((y-buildingY.x)/(buildingY.y-buildingY.x)*4.0)),0,3);}
bool exteriorWindow(vec3 p,vec2 normal){
    vec2 uv=(p.xz+normal*(1.75*maskSpan/float(textureSize(exteriorTex,0).x))-maskOrigin)/maskSpan;
    if(any(lessThan(uv,vec2(0))) || any(greaterThanEqual(uv,vec2(1))))return false;
    return texture2D(exteriorTex,uv)[wallBand(p.y)]>0.5;
}
