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
    if(texture2D(occupancyTex,sampleUV).r>0.5) discard;
    vec3 light=max(texture2D(radianceTex,sampleUV).rgb,vec3(0));
    // Propagation supplies UNIT intensity. Day/night is applied exactly once,
    // after bounded artistic gain. Preview exposure does not enter this pass.
    vec3 added=(vec3(1)-exp(-light*strength))*clamp(nightIntensity,0.0,1.0)*clamp(albedo,0.0,1.0);
    gl_FragColor=vec4(added,0.0);
}
