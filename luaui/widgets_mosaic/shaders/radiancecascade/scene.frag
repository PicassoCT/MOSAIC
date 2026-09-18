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
    if(world.y<max(0.0,heightRange.x) || world.y>=heightRange.y) discard;
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
        light=max(light,direct);
    }
    // Propagation supplies UNIT intensity. Day/night is applied exactly once,
    // after bounded artistic gain. Preview exposure does not enter this pass.
    vec3 added=(vec3(1)-exp(-light*strength))*clamp(nightIntensity,0.0,1.0)*clamp(albedo,0.0,1.0);
    gl_FragColor=vec4(added,0.0);
}

