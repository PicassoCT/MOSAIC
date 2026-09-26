// Decoded world normal: Y is up. Smooth masks keep terrain and unit roofs
// consistent without a material-dependent alpha flag or binary slope cutoff.
vec2 surfaceWaterWeights(float upwardness) {
    float wet = smoothstep(0.05, 0.65, upwardness);
    // Begin runoff on shallow roof/road inclines, keep truly flat roofs puddled.
    float puddle = smoothstep(0.975, 0.9995, upwardness);
    return vec2(wet,puddle);
}

// Fixed world charts avoid position*dNormal phase distortion on curved roofs.
// Height always increases uphill, so downward animation works for every azimuth.
// Choose the less foreshortened vertical projection; chart boundaries can seam.
vec3 runoffChartAcross(vec3 normal) {
    return abs(normal.x)>abs(normal.z) ? vec3(0,0,normal.x>=0.0 ? -1.0 : 1.0)
                                    : vec3(normal.z>=0.0 ? 1.0 : -1.0,0,0);
}
vec2 runoffChart(vec3 p, vec3 across) {
    return vec2(dot(p,across),-p.y*1.41421356);
}
float surfaceWetNoise(vec2 p);
vec4 roofWaterBeads(vec3 p, vec3 normal, bool building);
// Cached recursive split/rejoin network. RG are fixed bank/spill heights;
// BA is a complex phase so repeated borders and mip filtering remain continuous.
// Eight crests fit each 32-unit tile. Geometry and rain never move the banks.
vec4 terrainChannelFrame(vec2 at, float pixel) {
    vec4 data=texture2D(terrainRunoffTex,at/64.0);
    float head=0.010+0.990*pow(clamp(terrainWetness,0.0,1.0),1.85);
    float spill=2.0*data.g*data.g;
    float aa=max(fwidth(spill)*0.6,0.004);
    float wet=(1.0-smoothstep(head-aa,head+aa,spill))
        *smoothstep(0.0,0.025,terrainWetness);
    // Thresholding an averaged bank height would pop entire distant tiles.
    // Blend unresolved detail into the atlas's calibrated mean wet coverage.
    wet=mix(wet,0.76*pow(clamp(terrainWetness,0.0,1.0),1.65),
            smoothstep(1.5,8.0,pixel));
    return vec4(wet,max(head-2.0*data.r*data.r,0.0),data.ba*2.0-1.0);
}
float terrainCrest(vec2 phase) {
    float t=terrainFlowTime*5.3407075;
    // The vector shrinks under mip filtering, removing unresolved glitter.
    float wave=0.5+0.5*dot(phase,vec2(cos(t),sin(t)));
    return wave*wave*wave*min(dot(phase,phase),1.0);
}
float terrainChannelMask(vec2 at, float pixel) {
    return terrainChannelFrame(at,pixel).x;
}
float terrainWaterFilm(vec2 at, float pixel) {
    vec4 channel=terrainChannelFrame(at,pixel);
    return 0.36+channel.x*channel.x*(0.20+0.22*terrainCrest(channel.zw));
}
float getSurfaceRivulets(vec3 p, vec3 normal, bool building) {
    if(building) return roofWaterBeads(p,normal,true).w;
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float weight=smoothstep(0.2,0.8,normal.z*normal.z/max(dot(normal.xz,normal.xz),0.00001));
    float a=terrainWaterFilm(vec2(p.x,-p.y*1.41421356),pixel);
    float b=terrainWaterFilm(vec2(p.z,-p.y*1.41421356),pixel);
    return mix(b,a,weight)*smoothstep(0.0,1.5,p.y);
}
float getSurfaceRivulets(vec3 p, vec3 normal) {
    return getSurfaceRivulets(p,normal,false);
}
// x coverage, y rounded water relief/depth, z travelling crest, w local depth.
vec4 terrainChartWater(vec2 at, float pixel) {
    vec4 channel=terrainChannelFrame(at,pixel);
    float crest=terrainCrest(channel.zw);
    return vec4(channel.x,channel.x*(0.08+channel.y+0.14*crest),
                channel.x*crest,channel.y);
}
vec4 terrainSurfaceWater(vec3 p, vec3 n) {
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float weight=smoothstep(0.2,0.8,n.z*n.z/max(dot(n.xz,n.xz),0.00001));
    vec4 a=terrainChartWater(vec2(p.x,-p.y*1.41421356),pixel);
    vec4 b=terrainChartWater(vec2(p.z,-p.y*1.41421356),pixel);
    vec4 levelWater=terrainChartWater(p.xz,pixel);
    float puddle=surfaceWaterWeights(n.y).y;
    // Level ground fills fixed depressions without directional travelling waves.
    // Puddle surfaces are level: buried bank relief affects depth/coverage,
    // not the water's shading normal. Only the meniscus rounds the contact.
    levelWater.y=levelWater.x*0.08;
    levelWater.z=0.0;
    return mix(mix(b,a,weight),levelWater,puddle)
        *surfaceWaterWeights(n.y).x*smoothstep(0.0,1.5,p.y);
}

// Stop-and-go motion is monotone: each smooth burst is separated by a rest.
float roofTravel(float age) {
    return 0.30*smoothstep(0.40,0.52,age)
         + 0.35*smoothstep(0.61,0.72,age)
         + 0.35*smoothstep(0.80,0.94,age);
}
vec2 roofPath(float y, vec3 seed) {
    float phase=seed.z*6.2831853;
    return vec2(0.28*sin(y*0.85+phase)+0.12*sin(y*1.9+phase),
                0.238*cos(y*0.85+phase)+0.228*cos(y*1.9+phase));
}
// Analytic cap: xyz is the chart-space gradient and height; w is coverage.
vec4 roofCap(vec2 delta, vec2 radius, float pixel) {
    vec2 filtered=sqrt(radius*radius+vec2(pixel*pixel*0.16));
    vec2 q=delta/filtered;
    float cap=max(1.0-dot(q,q),0.0);
    float energy=radius.x*radius.y/(filtered.x*filtered.y);
    return vec4(-4.0*q/filtered*cap*0.08*energy,
                cap*cap*0.08*energy,cap*cap*energy);
}
// Stable cluster conversion: light rain beads, full rain ~80% rivulet clusters.
// This is a population ratio, not a claim that 80% of roof pixels are wet.
float roofRivuletShare(float rain) {
    return 0.8*smoothstep(0.1,1.0,clamp(rain,0.0,1.0));
}
float roofClusterRivulet(vec2 id, float rain) {
    float threshold=hash3(id+vec2(113,29)).z;
    float share=roofRivuletShare(rain);
    return smoothstep(threshold-0.02,threshold+0.02,share)*smoothstep(0.0,0.02,share);
}
vec4 roofChartWater(vec2 at, float pixel) {
    vec2 cell=floor(at/vec2(3,6));
    vec4 water=vec4(0);
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,y);
        vec3 seed=hash3(id+vec2(71,19));
        float age=fract(time*(0.10+0.07*seed.x)+seed.z);
        float activeRunoff=roofClusterRivulet(id,rainPercent);
        float travel=roofTravel(age)*activeRunoff;
        float originY=id.y*6.0+(seed.x-0.5)*1.4;
        float head=originY+travel*5.5;
        float base=id.x*3.0+(seed.y-0.5)*2.2;
        float life=1.0-smoothstep(0.95,1.0,age);
        // Stationary beads are cleared as the head passes their position.
        for(int b=0;b<3;++b) {
            vec3 beadSeed=hash3(id+vec2(float(b)*17.0,93));
            float by=originY+0.8+float(b)*1.65+1.2*(beadSeed.x-0.5);
            float side=(beadSeed.y-0.5)*0.9;
            vec2 path=roofPath(by,seed);
            float collected=smoothstep(by-0.25,by+0.25,head);
            float grow=smoothstep(0.0,0.24+0.04*float(b),age);
            vec2 radius=0.5*vec2(0.35+0.18*seed.y,0.48+0.18*seed.x)*mix(0.4,1.0,grow);
            water+=roofCap(at-vec2(base+path.x+side,by),radius,pixel)*grow*(1.0-collected)*life*(1.0-activeRunoff);
        }
        vec2 headPath=roofPath(head,seed);
        float moving=smoothstep(0.37,0.42,age)*life*activeRunoff;
        water+=roofCap(at-vec2(base+headPath.x,head),vec2(0.24,0.32)*(0.8+0.4*travel),pixel)*moving;
        // Meandering rivulet with a steady body and a small travelling swell.
        vec2 path=roofPath(at.y,seed);
        float dx=at.x-base-path.x;
        // Independent stable sizes: mostly fine threads, occasional broader runs.
        vec3 sizeSeed=hash3(id+vec2(197,53));
        float width=mix(0.12,0.38,sizeSeed.x*sizeSeed.x);
        float length=mix(1.4,4.8,sizeSeed.y);
        float start=originY+0.3+sizeSeed.z*(5.4-length);
        // Finite channels stay wet between moving swells, without pulsing off.
        float channelWindow=smoothstep(start,start+0.3,at.y)
            *(1.0-smoothstep(start+length-0.35,start+length,at.y));
        float filtered=sqrt(width*width+pixel*pixel*0.16);
        float q=dx/filtered;
        float behind=head-at.y;
        float window=smoothstep(0.0,0.25,behind)*(1.0-smoothstep(0.5,1.8,behind));
        float relief=channelWindow*activeRunoff*(0.8+0.2*window*moving);
        float h=exp(-q*q)*(0.035+width*0.08)*width/filtered*relief;
        float gx=-2.0*q/filtered*h;
        water+=vec4(gx,-gx*path.y,h,h/0.08);
    }
    return water;
}
// Art calibration: one visual metre is four engine units (one debug square).
const float RAIN_UNITS_PER_METRE=4.0;
const float ROOF_STREAM_SPACING=2.5; // Art-directed spacing, independent of metre calibration.
float permanentStreamEnabled(float lane, float rain) {
    float density=pow(clamp(rain,0.0,1.0),1.35);
    return smoothstep(hash3(vec2(lane,163)).x-0.035,hash3(vec2(lane,163)).x+0.035,density)*smoothstep(0.0,0.05,rain);
}
vec4 permanentRoofStreams(vec2 at, float pixel) {
    float lane=floor(at.x/ROOF_STREAM_SPACING);
    vec4 water=vec4(0);
    for(int i=-1;i<=1;++i) {
        float id=lane+float(i);
        vec3 seed=hash3(vec2(id,163));
        float enabled=permanentStreamEnabled(id,rainPercent);
        // Stable paths and nested rain thresholds: no time-dependent motion.
        vec2 path=roofPath(at.y*0.35,seed);
        float centre=(id+0.2+0.6*seed.y)*ROOF_STREAM_SPACING+path.x*0.4;
        float width=0.065+0.10*seed.z*seed.z;
        float filtered=sqrt(width*width+pixel*pixel*0.16);
        float q=(at.x-centre)/filtered;
        float h=exp(-q*q)*0.016*width/filtered*enabled;
        float gx=-2.0*q/filtered*h;
        water+=vec4(gx,-gx*path.y*0.14,h,h/0.08);
    }
    return water;
}

// Two fixed world projections crossfade instead of abruptly switching axes.
// Both use -worldY: a travelling head can only move down in world height.
vec4 roofWaterBeads(vec3 p, vec3 normal, bool building) {
    vec2 wet=surfaceWaterWeights(normal.y);
    float eligible=building ? wet.x*(1.0-wet.y)*step(0.0,p.y) : 0.0;
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float resolved=1.0-smoothstep(2.0,5.0,pixel);
    if(eligible*resolved<0.0001) return vec4(0);
    float weight=smoothstep(0.2,0.8,normal.z*normal.z/max(dot(normal.xz,normal.xz),0.00001));
    vec2 uvA=vec2(p.x,-p.y*1.41421356),uvB=vec2(p.z,-p.y*1.41421356);
    // 40% of the previous diameter, 6.25x the cluster density.
    vec4 a=roofChartWater(uvA*2.5,pixel*2.5)+permanentRoofStreams(uvA,pixel);
    vec4 b=roofChartWater(uvB*2.5,pixel*2.5)+permanentRoofStreams(uvB,pixel);
    vec3 gradient=vec3(a.x*weight,-mix(b.y,a.y,weight)*1.41421356,b.x*(1.0-weight));
    gradient-=normal*dot(normal,gradient);
    return vec4(gradient,clamp(mix(b.w,a.w,weight),0.0,1.0))*eligible*resolved;
}

// Low-amplitude connected wet film under building runoff; world-anchored and
// rain-scaled. It changes the material response without filling every channel.
float roofWetFilm(vec3 p, vec3 n, bool building) {
    vec2 wet=surfaceWaterWeights(n.y);
    float pattern=surfaceWetNoise(p.xz/9.0+vec2(p.y*0.07));
    return (building ? 1.0 : 0.0)*wet.x*(1.0-wet.y)*smoothstep(0.0,1.5,p.y)
        *clamp(rainPercent,0.0,1.0)*(0.08+0.14*pattern);
}

// Convert a sampled height field into a world tangent gradient. Clamp silhouette
// discontinuities; the channel mask itself is never used as emitted colour.
vec3 runoffHeightGradient(float height, vec3 p, vec3 n) {
    vec3 dx=dFdx(p),dy=dFdy(p);
    vec3 a=cross(dy,n),b=cross(n,dx);
    float det=dot(dx,a);
    vec3 gradient=(a*dFdx(height)+b*dFdy(height))/(abs(det)>0.00001 ? det : 1.0);
    return gradient/max(1.0,length(gradient)/0.25);
}

// Stable broad puddles, separate from the fine impact pattern.
float surfaceWetNoise(vec2 p) {
    vec2 cell=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(hash3(cell).z,hash3(cell+vec2(1,0)).z,f.x),
               mix(hash3(cell+vec2(0,1)).z,hash3(cell+vec2(1,1)).z,f.x),f.y);
}
float surfacePuddleMask(vec2 p) {
    float patch=surfaceWetNoise(p/24.0)*0.7+surfaceWetNoise(p/7.0)*0.3;
    return smoothstep(0.28,0.7,patch);
}

// Analytic gradient of a small Gaussian water ridge. Keep the existing impact
// seeds, expanding radii and lifetime, but light its curved surface instead of
// painting a uniformly bright circle. Broader pixel filters conserve amplitude.
vec2 surfaceRippleProfile(vec2 position) {
    vec2 p=position*RAIN_RIPPLE_SCALE;
    vec2 cell=floor(p);
    float pixel=max(length(dFdx(p)),length(dFdy(p)));
    float width=sqrt(0.075*0.075+pixel*pixel*0.25);
    float resolved=1.0-smoothstep(0.75,2.0,pixel);
    vec2 gradient=vec2(0);
    for(int z=-1;z<=1;++z) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,z);
        vec3 seed=hash3(id);
        float age=mod(time*RAIN_RIPPLE_SPEED*2.0-(seed.x+seed.y)*5.0,2.0*PI)
                  /(RAIN_RIPPLE_SPEED*2.0);
        float radius=age*0.95;
        vec2 radial=p-id-seed.xy;
        float distance=length(radial);
        float life=smoothstep(0.0,0.06,age)*(1.0-smoothstep(0.45,0.85,age));
        float t=(distance-radius)/width;
        float slope=-2.0*t*exp(-t*t)*0.032/width;
        gradient+=radial/max(distance,0.001)*slope*life*(0.075/width);
    }
    return gradient*resolved;
}
