// Included after the caller's #version. Mobile shapes never enter the static
// occupancy atlas: every test is a finite three-dimensional source/receiver ray.
uniform sampler2D mobileShadowData;
uniform vec2 mobileShadowOrigin;
uniform float mobileShadowSpan;
uniform vec2 mobileShadowHeight;
uniform int mobileShadowCount;
uniform int mobileShadowActive;

const int MOBILE_GRID_SIZE=32;
const int MOBILE_GRID_OFFSET=1280; // 256 records, five RGBA32F texels each
const int MOBILE_GRID_TEXELS=4;    // sixteen record indices per grid cell

vec4 mobileData(int address)
{
    return texelFetch(mobileShadowData,ivec2(address%256,address/256),0);
}

bool mobileClipAxis(float start,float delta,float lower,float upper,
                    inout float entry,inout float exit)
{
    if(abs(delta)<1e-8) return start>=lower && start<=upper;
    float a=(lower-start)/delta,b=(upper-start)/delta;
    entry=max(entry,min(a,b)); exit=min(exit,max(a,b));
    return entry<=exit;
}

bool mobileInside(vec3 point,int shape)
{
    // Strict containment avoids treating a ground/roof point exactly on the
    // proxy boundary as a receiver buried inside an oversized approximation.
    return shape==2 ? dot(point,point)<0.99999 : all(lessThan(abs(point),vec3(0.99999)));
}

bool mobileProxyBlocks(int record,vec3 source,vec3 receiver,float ownerID)
{
    int address=record*5;
    vec4 center=mobileData(address);
    vec4 x=mobileData(address+1),y=mobileData(address+2),z=mobileData(address+3);
    vec3 halfSize=vec3(x.w,y.w,z.w);
    if(any(lessThanEqual(halfSize,vec3(0.0)))) return false;
    vec3 from=source-center.xyz,to=receiver-center.xyz;
    vec3 a=vec3(dot(from,x.xyz),dot(from,y.xyz),dot(from,z.xyz))/halfSize;
    vec3 b=vec3(dot(to,x.xyz),dot(to,y.xyz),dot(to,z.xyz))/halfSize;
    int shape=int(center.w+0.5);
    // Approximate proxy volume may contain a visible piece of its own unit.
    // Omit only that volume; nearby units remain eligible to shadow it.
    if(mobileInside(b,shape)) return false;
    if(ownerID>=0.0 && mobileInside(a,shape) &&
       abs(mobileData(address+4).x-ownerID)<0.5) return false;
    vec3 ray=b-a;
    float entry=0.0,exit=1.0;
    if(shape==2) {
        // Transforming by the three radii reduces the stretched ellipsoid to
        // a unit sphere. Solve the actual segment, including tilted ellipsoids.
        float quadratic=dot(ray,ray);
        if(quadratic<1e-12) return false;
        // Solve the same quadratic via closest approach. Subtracting b*b-a*c
        // loses thin pedestrian intersections when a far source is many radii
        // away; the closest point keeps the calculation near unit scale.
        float middle=-dot(a,ray)/quadratic;
        vec3 closest=a+ray*middle;
        float distanceLeft=1.0-dot(closest,closest);
        if(distanceLeft<=0.0) return false;
        float halfInterval=sqrt(distanceLeft/quadratic);
        entry=max(entry,middle-halfInterval);
        exit=min(exit,middle+halfInterval);
    } else {
        if(!mobileClipAxis(a.x,ray.x,-1.0,1.0,entry,exit) ||
           !mobileClipAxis(a.y,ray.y,-1.0,1.0,entry,exit) ||
           !mobileClipAxis(a.z,ray.z,-1.0,1.0,entry,exit)) return false;
    }
    // Exclude contact at the two endpoints, not a world-space clearance circle.
    // A neighboring pedestrian immediately beside a light still blocks its ray.
    float bias=min(0.001,0.01/max(length(receiver-source),0.01));
    return exit>max(entry,bias) && entry<1.0-bias;
}

float mobileVisibility(vec3 source,vec3 receiver,float ownerID)
{
    if(mobileShadowActive==0 || mobileShadowCount<=0 || mobileShadowSpan<=0.0) return 1.0;
    vec3 delta=receiver-source;
    if(dot(delta,delta)<1e-12) return 1.0;
    float entry=0.0,exit=1.0;
    // A high lamp's ray can travel above every proxy for most of its length.
    // Clip that empty height range before walking the x/z grid. Zero/default
    // bounds keep compatibility with callers without a height envelope.
    if(mobileShadowHeight.y>mobileShadowHeight.x &&
       !mobileClipAxis(source.y,delta.y,mobileShadowHeight.x,mobileShadowHeight.y,entry,exit)) return 1.0;
    if(!mobileClipAxis(source.x,delta.x,mobileShadowOrigin.x,mobileShadowOrigin.x+mobileShadowSpan,entry,exit) ||
       !mobileClipAxis(source.z,delta.z,mobileShadowOrigin.y,mobileShadowOrigin.y+mobileShadowSpan,entry,exit) ||
       exit<=entry) return 1.0;
    float cellSize=mobileShadowSpan/float(MOBILE_GRID_SIZE);
    vec2 gridPoint=(source.xz+delta.xz*entry-mobileShadowOrigin)/cellSize;
    ivec2 cell=clamp(ivec2(floor(gridPoint)),ivec2(0),ivec2(MOBILE_GRID_SIZE-1));
    ivec2 direction=ivec2(sign(delta.xz));
    vec2 nextBoundary=mobileShadowOrigin+(vec2(cell)+vec2(direction.x>0 ? 1.0 : 0.0,
                                                                         direction.y>0 ? 1.0 : 0.0))*cellSize;
    vec2 next=vec2(1e30),step=vec2(1e30);
    if(direction.x!=0) { next.x=(nextBoundary.x-source.x)/delta.x; step.x=cellSize/abs(delta.x); }
    if(direction.y!=0) { next.y=(nextBoundary.y-source.z)/delta.z; step.y=cellSize/abs(delta.z); }
    // A clipped segment crosses at most 32+32 cells. The CPU packs each cell's
    // indices contiguously, so an empty cell costs one fetch and a hit exits.
    for(int visit=0;visit<65;++visit) {
        int address=MOBILE_GRID_OFFSET+(cell.y*MOBILE_GRID_SIZE+cell.x)*MOBILE_GRID_TEXELS;
        for(int group=0;group<MOBILE_GRID_TEXELS;++group) {
            vec4 records=mobileData(address+group);
            if(records.x<0.5) break;
            for(int component=0;component<4;++component) {
                int record=int(records[component]+0.5)-1;
                if(record<0) break;
                if(record<mobileShadowCount &&
                   mobileProxyBlocks(record,source,receiver,ownerID)) return 0.0;
            }
        }
        float crossing=min(next.x,next.y);
        if(crossing>=exit) break;
        // At a grid corner both coordinates advance. Side cells touched only
        // at that point cannot introduce a finite segment intersection.
        if(next.x<=crossing) { cell.x+=direction.x; next.x+=step.x; }
        if(next.y<=crossing) { cell.y+=direction.y; next.y+=step.y; }
        if(any(lessThan(cell,ivec2(0))) || any(greaterThanEqual(cell,ivec2(MOBILE_GRID_SIZE)))) break;
    }
    return 1.0;
}
