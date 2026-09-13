#version 150 compatibility
layout(triangles) in;
layout(triangle_strip, max_vertices=12) out;
in float vertexHeight[];
in vec4 vertexColor[];
out float worldHeight;
uniform vec2 heightRange;
uniform vec2 atlasSize;
// Orthographic capture only. Clip to the height band BEFORE expanding so a
// tall sign contributes only its portion intersecting this band.
vec4 p[6];
float h[6];
int count;
void clipHeight(float plane, bool lower)
{
    vec4 q[6]; float heights[6]; int n=0;
    for(int i=0;i<6;++i) {
        if(i>=count) break;
        int j=(i+1)%count;
        bool a=lower ? h[i]>=plane : h[i]<plane;
        bool b=lower ? h[j]>=plane : h[j]<plane;
        if(a) { q[n]=p[i]; heights[n++]=h[i]; }
        if(a!=b) {
            float t=(plane-h[i])/(h[j]-h[i]);
            q[n]=mix(p[i],p[j],t); heights[n++]=plane;
        }
    }
    count=n;
    for(int i=0;i<6;++i) { if(i>=n) break; p[i]=q[i]; h[i]=heights[i]; }
}
void emitPosition(vec4 position)
{
    gl_Position=position;
    // Height membership has already been clipped, including upper exclusivity.
    worldHeight=(heightRange.x+heightRange.y)*0.5;
    gl_FrontColor=vertexColor[0];
    EmitVertex();
}
void main()
{
    count=3;
    for(int i=0;i<3;++i) { p[i]=gl_in[i].gl_Position; h[i]=vertexHeight[i]; }
    clipHeight(heightRange.x,true);
    if(count<3) return;
    clipHeight(heightRange.y,false);
    if(count<3) return;
    vec2 pixel[6]; float longest=0.0; vec2 axis=vec2(1,0);
    for(int i=0;i<6;++i) {
        if(i>=count) break;
        pixel[i]=p[i].xy/p[i].w*atlasSize*0.5;
    }
    for(int i=0;i<6;++i) for(int j=i+1;j<6;++j) {
        if(i>=count || j>=count) continue;
        vec2 d=pixel[j]-pixel[i]; float len=length(d);
        if(len>longest) { longest=len; axis=d/len; }
    }
    vec2 normal=vec2(-axis.y,axis.x);
    vec2 lo=vec2(1e20),hi=vec2(-1e20);
    for(int i=0;i<6;++i) {
        if(i>=count) break;
        vec2 v=vec2(dot(pixel[i],axis),dot(pixel[i],normal));
        lo=min(lo,v); hi=max(hi,v);
    }
    if(hi.y-lo.y>=2.0) {
        // Broad surfaces retain their original footprint, not a bounding box.
        for(int i=1;i<5;++i) {
            if(i>=count-1) break;
            emitPosition(p[0]); emitPosition(p[i]); emitPosition(p[i+1]); EndPrimitive();
        }
        return;
    }
    // Edge-on/subpixel triangles get a two-texel ribbon. This bounded dilation
    // also survives the 1024 -> 512 resolve; it does not add emission intensity.
    vec2 mid=(lo+hi)*0.5;
    vec2 halfSize=max((hi-lo)*0.5,vec2(1.0));
    for(int i=0;i<4;++i) {
        vec2 s=vec2((i%2)==0 ? -1.0 : 1.0,i<2 ? -1.0 : 1.0);
        vec2 v=mid+s*halfSize;
        vec4 position=p[0];
        position.xy=(axis*v.x+normal*v.y)*2.0/atlasSize*position.w;
        emitPosition(position);
    }
    EndPrimitive();
}
