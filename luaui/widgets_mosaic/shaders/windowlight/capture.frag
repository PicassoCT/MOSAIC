#version 150 compatibility
uniform sampler2D sourceTex;
uniform sampler2D materialTex;
uniform vec2 captureDirection;
in vec3 worldPosition;
in vec3 worldNormal;
in vec2 sourceUV;
void main() {
    vec2 dx=dFdx(sourceUV),dy=dFdy(sourceUV);
    vec3 emission=vec3(0);float coverage=0.0;
    for(int y=0;y<4;++y) for(int x=0;x<4;++x) {
        vec2 uv=sourceUV+dx*((float(x)+0.5)/4.0-0.5)+dy*((float(y)+0.5)/4.0-0.5);
        vec4 m=textureGrad(materialTex,uv,dx/4.0,dy/4.0);
        emission+=textureGrad(sourceTex,uv,dx/4.0,dy/4.0).rgb*m.r*m.a;
        coverage+=m.a;
    }
    if(coverage/16.0<0.5) discard;
    vec3 n=normalize(worldNormal);
    // Assign each facade to ONE view. Other faces still write opaque depth.
    vec2 facing=abs(n.x)>=abs(n.z) ? vec2(sign(n.x),0) : vec2(0,sign(n.z));
    if(abs(n.y)>0.8 || dot(facing,captureDirection)<0.5) emission=vec3(0);
    float area=length(cross(dFdx(worldPosition),dFdy(worldPosition)));
    gl_FragData[0]=vec4(emission/16.0,area);
    gl_FragData[1]=vec4(worldPosition,atan(n.z,n.x));
}
