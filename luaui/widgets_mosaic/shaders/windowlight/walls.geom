#version 150 compatibility
layout(triangles) in;
layout(triangle_strip,max_vertices=16) out;
in vec3 position[];
uniform vec2 maskOrigin;
uniform float maskSpan;
uniform float maskResolution;
uniform vec2 heightRange;
vec3 p[6];int count;
void clipY(float y,bool lower){
    vec3 q[6];int n=0;
    for(int i=0;i<6;++i){
        if(i>=count) break;int j=(i+1)%count;
        bool a=lower?p[i].y>=y:p[i].y<=y,b=lower?p[j].y>=y:p[j].y<=y;
        if(a) q[n++]=p[i];
        if(a!=b) q[n++]=mix(p[i],p[j],(y-p[i].y)/(p[j].y-p[i].y));
    }
    count=n;for(int i=0;i<6;++i){if(i>=n)break;p[i]=q[i];}
}
void emitAt(vec2 xz){gl_Position=vec4(2.0*(xz-maskOrigin)/maskSpan-1.0,0.5,1);EmitVertex();}
void main(){
    vec3 normal=cross(position[1]-position[0],position[2]-position[0]);
    if(length(normal)<0.00001 || abs(normalize(normal).y)>0.8) return;
    count=3;for(int i=0;i<3;++i)p[i]=position[i];
    clipY(heightRange.x,true);if(count<3)return;
    clipY(heightRange.y,false);if(count<3)return;
    float longest=0.0;vec2 a=p[0].xz,b=a;
    for(int i=0;i<6;++i)for(int j=i+1;j<6;++j){
        if(i>=count || j>=count)continue;
        float d=length(p[i].xz-p[j].xz);
        if(d>longest){longest=d;a=p[i].xz;b=p[j].xz;}
    }
    if(longest<0.0001)return;
    // Fill sloping wall projections, and conservatively thicken edge-on walls.
    for(int i=1;i<5;++i){if(i>=count-1)break;emitAt(p[0].xz);emitAt(p[i].xz);emitAt(p[i+1].xz);EndPrimitive();}
    vec2 tangent=(b-a)/longest,side=vec2(-tangent.y,tangent.x)*maskSpan/maskResolution*0.8;
    a-=tangent*maskSpan/maskResolution*0.5;b+=tangent*maskSpan/maskResolution*0.5;
    emitAt(a-side);emitAt(a+side);emitAt(b-side);emitAt(b+side);EndPrimitive();
}
