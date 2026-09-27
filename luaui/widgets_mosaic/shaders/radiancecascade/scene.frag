#version 150 compatibility
uniform sampler2D radianceTex;
uniform sampler2D occupancyTex;
uniform sampler2D mapDepthTex;
uniform sampler2D modelDepthTex;
uniform sampler2D mapNormalTex;
uniform sampler2D modelNormalTex;
uniform sampler2D mapDiffuseTex;
uniform sampler2D modelDiffuseTex;
uniform mat4 inverseProjection;
uniform mat4 inverseView;
uniform vec2 mapSize;
uniform vec2 heightRange;
uniform int clipZeroToOne;
uniform int deferred;
uniform float strength;
uniform float nightIntensity;
uniform float headlightIntensity;
uniform int smoothing;
uniform int localActive;
uniform sampler2D localRadianceTex;
uniform sampler2D localOccupancyTex;
uniform vec2 localOrigin;
uniform float localSpan;
uniform sampler2D headlightTex;
uniform sampler2D headlightLocalTex;
uniform int headlightActive;
uniform int headlightLocalActive;
uniform vec2 headlightOrigin;
uniform float headlightSpan;
uniform sampler2D windowTex;
uniform sampler2D windowGroundTex;
uniform int windowActive;
// Finite 3D cones for objective floodlights/searchlights. These share the scene
// depth and normals; no extra framebuffer, model shader or engine setting.
const int MAX_OBJECTIVE_LIGHTS=24;
uniform int objectiveLightCount=0;
uniform vec4 objectivePosRange[MAX_OBJECTIVE_LIGHTS];
uniform vec4 objectiveDirCos[MAX_OBJECTIVE_LIGHTS];
uniform vec4 objectiveColorGain[MAX_OBJECTIVE_LIGHTS];
float objectiveVisibility(vec3 lamp,vec3 world)
{
    float cell=max(mapSize.x,mapSize.y)/float(textureSize(occupancyTex,0).x);
    float endT=max(0.0,1.0-cell*1.5/max(length(world-lamp),1.0));
    for(int j=0;j<16;++j) {
        vec3 p=mix(lamp,world,endT*(float(j)+0.5)/16.0);
        // The coarse source cell may contain the tower below its roof lamp.
        // Start testing beyond that cell, and stop before the receiver's face.
        if(length(p-lamp)>cell*1.5 && p.y>=heightRange.x && p.y<heightRange.y &&
           all(greaterThanEqual(p.xz,vec2(0))) && all(lessThan(p.xz,mapSize)) &&
           texture2D(occupancyTex,p.xz/mapSize).r>0.5) return 0.0;
    }
    return 1.0;
}
vec3 objectiveLighting(vec3 world,vec3 normal)
{
    vec3 light=vec3(0);
    for(int i=0;i<MAX_OBJECTIVE_LIGHTS;++i) {
        if(i>=objectiveLightCount) break;
        vec3 delta=world-objectivePosRange[i].xyz;
        float distance2=dot(delta,delta),range=objectivePosRange[i].w;
        if(distance2>=range*range || distance2<0.000001) continue;
        float distance=sqrt(distance2);
        vec3 ray=delta/distance;
        float outer=objectiveDirCos[i].w;
        float cone=smoothstep(outer,mix(outer,1.0,0.4),dot(ray,objectiveDirCos[i].xyz));
        float incidence=max(0.0,dot(normal,-ray));
        if(cone*incidence<0.001) continue;
        float fade=1.0-smoothstep(range*0.65,range,distance);
        float energy=cone*incidence*fade/(1.0+12.0*distance*distance/(range*range));
        light+=objectiveColorGain[i].rgb*objectiveColorGain[i].a*energy*
            objectiveVisibility(objectivePosRange[i].xyz,world);
    }
    return light;
}
vec3 filteredLight(sampler2D field,sampler2D occupancy,vec2 uv)
{
    if(any(lessThan(uv,vec2(0))) || any(greaterThanEqual(uv,vec2(1)))) return vec3(0);
    if(texture2D(occupancy,uv).r>0.5) return vec3(0);
    if(smoothing==0) return max(texture2D(field,uv).rgb,vec3(0));
    ivec2 size=textureSize(field,0);
    vec2 p=uv*vec2(size)-0.5, weight=fract(p);
    ivec2 base=ivec2(floor(p));
    vec3 sum=vec3(0);float total=0.0;
    for(int y=0;y<2;++y) for(int x=0;x<2;++x) {
        ivec2 tap=clamp(base+ivec2(x,y),ivec2(0),size-ivec2(1));
        vec2 target=(vec2(tap)+0.5)/vec2(size);
        bool visible=texture2D(occupancy,target).r<=0.5;
        float distance=length((target-uv)*vec2(textureSize(occupancy,0)));
        int steps=min(8,max(1,int(ceil(distance*2.0))));
        for(int i=0;i<8;++i) {
            if(i>=steps || !visible) break;
            visible=texture2D(occupancy,mix(uv,target,(float(i)+0.5)/float(steps))).r<=0.5;
        }
        if(visible) {
            float w=(x==0 ? 1.0-weight.x : weight.x)*(y==0 ? 1.0-weight.y : weight.y);
            sum+=max(texelFetch(field,tap,0).rgb,vec3(0))*w;total+=w;
        }
    }
    return total>0.00001 ? sum/total : vec3(0);
}
vec3 worldPosition(vec2 uv,float depth)
{
    float z=clipZeroToOne!=0 ? depth : depth*2.0-1.0;
    vec4 view=inverseProjection*vec4(uv*2.0-1.0,z,1.0);
    view/=view.w;
    return (inverseView*view).xyz;
}
void main()
{
    vec2 uv=gl_TexCoord[0].st;
    float depth=texture2D(mapDepthTex,uv).r;
    bool model=false;
    if(deferred!=0) {
        float modelDepth=texture2D(modelDepthTex,uv).r;
        model=modelDepth<depth;
        if(model) depth=modelDepth;
    }
    if(depth>=0.999999) discard; // sky/cleared buffer
    vec3 world=worldPosition(uv,depth);
    bool cascadeBand=world.y>=max(0.0,heightRange.x) && world.y<heightRange.y;
    if(!cascadeBand && windowActive==0 && objectiveLightCount==0)discard;
    vec3 normal,albedo;
    if(deferred!=0) {
        vec3 encoded=model ? texture2D(modelNormalTex,uv).rgb : texture2D(mapNormalTex,uv).rgb;
        if(length(encoded)<0.2) discard;
        normal=normalize(encoded*2.0-1.0);
        albedo=model ? texture2D(modelDiffuseTex,uv).rgb : texture2D(mapDiffuseTex,uv).rgb;
    } else {
        // Depth-copy fallback: no material buffers or second colour copy.
        vec3 dx=dFdx(world),dy=dFdy(world);
        vec3 n=cross(dx,dy);
        if(dot(n,n)<1e-12) discard;
        normal=normalize(n);
        vec3 camera=(inverseView*vec4(0,0,0,1)).xyz;
        if(dot(normal,camera-world)<0.0) normal=-normal;
        albedo=vec3(0.5);
    }
    // Sample the exterior of a wall rather than its occupied column. Never
    // interpolate a bright sample from the opposite side of an occupied cell.
    vec2 cell=mapSize/vec2(textureSize(occupancyTex,0));
    vec2 sampleUV=(world.xz+normal.xz*cell*1.25)/mapSize;
    if(any(lessThan(world.xz,vec2(0))) || any(greaterThanEqual(world.xz,mapSize))) discard;
    if(any(lessThan(sampleUV,vec2(0))) || any(greaterThanEqual(sampleUV,vec2(1)))) discard;
    vec3 light=filteredLight(radianceTex,occupancyTex,sampleUV);
    if(localActive!=0) {
        vec2 localCell=vec2(localSpan)/vec2(textureSize(localOccupancyTex,0));
        vec2 localUV=(world.xz+normal.xz*localCell*1.25-localOrigin)/localSpan;
        float edge=min(min(localUV.x,localUV.y),min(1.0-localUV.x,1.0-localUV.y));
        float blend=smoothstep(0.0,0.18,edge);
        if(blend>0.0) {
            vec3 detail=filteredLight(localRadianceTex,localOccupancyTex,localUV);
            light=mix(light,detail,blend);
        }
    }
    if(headlightActive!=0) {
        vec3 direct=vec3(0);
        // Cone emission has already been ray-clipped against building occupancy.
        if(texture2D(occupancyTex,sampleUV).r<=0.5)
            direct=max(texture2D(headlightTex,sampleUV).rgb,vec3(0));
        if(headlightLocalActive!=0) {
            vec2 hu=(world.xz+normal.xz*cell*1.25-headlightOrigin)/headlightSpan;
            float edge=min(min(hu.x,hu.y),min(1.0-hu.x,1.0-hu.y));
            float blend=smoothstep(0.0,0.18,edge);
            if(blend>0.0 && texture2D(occupancyTex,sampleUV).r<=0.5)
                direct=mix(direct,max(texture2D(headlightLocalTex,hu).rgb,vec3(0)),blend);
        }
        // Slow vehicle emission is only 8% spill. Max, rather than addition,
        // preserves full direct intensity without counting it twice.
        light=max(light,direct*headlightIntensity);
    }
    if(!cascadeBand)light=vec3(0);
    light+=objectiveLighting(world,normal);
    // Direct facade light joins only here. It is NEVER a cascade emission input
    // or a fog source, and must not be projected onto roofs above the ground.
    if(windowActive!=0 && !model && normal.y>0.25 && world.y>=0.0){
        float ground=texture2D(windowGroundTex,world.xz/mapSize).r;
        float tolerance=max(4.0,2.0*max(abs(dFdx(world.y)),abs(dFdy(world.y))));
        if(abs(world.y-ground)<tolerance)
            light+=max(texture2D(windowTex,world.xz/mapSize).rgb,vec3(0));
    }
    // Emission carries per-source intensity. Apply scene gain once,
    // after bounded artistic gain. Preview exposure does not enter this pass.
    vec3 added=(vec3(1)-exp(-light*strength))*clamp(nightIntensity,0.0,1.0)*clamp(albedo,0.0,1.0);
    gl_FragColor=vec4(added,0.0);
}
