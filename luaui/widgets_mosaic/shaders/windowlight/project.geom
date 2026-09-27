#version 150 compatibility
layout(points) in;
layout(triangle_strip,max_vertices=4) out;
in vec4 sourceEmission[];
in vec4 sourcePosition[];
flat out vec3 patchPower;
flat out vec3 patchPosition;
flat out vec2 patchNormal;
flat out float patchRadius;
uniform vec2 fieldOrigin;
uniform float fieldSpan;
uniform float maxRange;
uniform float cutoff;
// WINDOW_CLASSIFY
void main(){
    vec4 e=sourceEmission[0],p=sourcePosition[0];
    if(e.a<=0.0 || max(e.r,max(e.g,e.b))<=0.0)return;
    vec2 n=vec2(cos(p.w),sin(p.w));
    if(!exteriorWindow(p.xyz,n))return;
    patchPower=e.rgb*e.a;
    patchRadius=min(maxRange,sqrt(max(patchPower.r,max(patchPower.g,patchPower.b))/max(cutoff,1e-12)));
    if(patchRadius<1.0)return;
    patchPosition=p.xyz;patchNormal=n;
    for(int i=0;i<4;++i){
        vec2 corner=vec2(i%2==0?-1:1,i<2?-1:1);
        vec2 uv=(p.xz+corner*patchRadius-fieldOrigin)/fieldSpan;
        gl_Position=vec4(uv*2.0-1.0,0.5,1);EmitVertex();
    }
    EndPrimitive();
}
