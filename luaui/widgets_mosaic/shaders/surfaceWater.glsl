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
float getSurfaceRivulets(vec3 p, vec3 normal, bool building) {
    vec3 across=runoffChartAcross(normal);
    vec2 at=runoffChart(p,across);
    // Independent world scales: fine building lanes, broad terrain channels.
    float scale=building ? 8.0 : 1.0;
    float along=at.y*scale;
    float crossSlope=at.x*scale;
    vec2 pixelX=runoffChart(dFdx(p),across)*scale;
    vec2 pixelY=runoffChart(dFdy(p),across)*scale;
    vec2 uvX=pixelX/vec2(5,18), uvY=pixelY/vec2(5,18);
    float footprint=max(length(uvX),length(uvY));
    // Independently timed channels, with only a gentle swell over a wet baseline.
    float laneID=floor(at.x/(building ? 1.0 : 5.0)+0.5);
    vec3 timing=hash3(vec2(laneID,building ? 31.0 : 59.0));
    float travel=along*(0.48+0.25*timing.y)-time*(2.5+2.0*timing.x)+timing.z*6.2831853;
    float beads=0.92+0.08*pow(0.5+0.5*sin(travel),3.0);
    if(building) return roofWaterBeads(p,normal,true).w;
    // A stationary, elongated UV Voronoi network supplies irregular channels,
    // forks and junctions. Only the water pulses move, monotonically downhill.
    vec2 flowUV=vec2(crossSlope/5.0,along/18.0);
    flowUV.x += 0.18*sin(flowUV.y*2.3)+0.09*sin(flowUV.y*5.1+1.7);
    vec2 cell=floor(flowUV), local=fract(flowUV);
    float nearest=100.0, second=100.0;
    vec2 nearOffset=vec2(0), secondOffset=vec2(0);
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,y);
        vec2 offset=vec2(x,y)+0.15+0.7*hash3(id).xy-local;
        float distance=dot(offset,offset);
        if(distance<nearest) {
            second=nearest; secondOffset=nearOffset;
            nearest=distance; nearOffset=offset;
        } else if(distance<second) { second=distance; secondOffset=offset; }
    }
    float edge=sqrt(second)-sqrt(nearest);

    float width=mix(0.018,0.09,surfaceWetNoise(flowUV*0.7+vec2(13,37)));
    float channel=1.0-smoothstep(width,width+max(footprint*0.65,0.018),edge);
    channel*=1.0-smoothstep(0.5,1.25,footprint);
    // Boundary tangent must have a downhill component: avoid a glowing wire mesh.
    vec2 edgeNormal=normalize(secondOffset-nearOffset+vec2(0.00001));
    float downhill=smoothstep(0.2,0.75,abs(edgeNormal.x));
    float surge=pow(0.5+0.5*sin(travel+surfaceWetNoise(flowUV)*2.0),3.0);
    return channel*downhill*(0.72+0.28*surge)*step(0.0,p.y);
}

// Terrain default for standalone surface probes.
float getSurfaceRivulets(vec3 p, vec3 normal) {
    return getSurfaceRivulets(p,normal,false);
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
vec4 roofChartWater(vec2 at, float pixel) {
    vec2 cell=floor(at/vec2(3,6));
    vec4 water=vec4(0);
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        vec2 id=cell+vec2(x,y);
        vec3 seed=hash3(id+vec2(71,19));
        float age=fract(time*(0.10+0.07*seed.x)+seed.z);
        float travel=roofTravel(age);
        float head=id.y*6.0+travel*5.5;
        float base=id.x*3.0+(seed.y-0.5)*1.3;
        float life=1.0-smoothstep(0.95,1.0,age);
        // Stationary beads are cleared as the head passes their position.
        for(int b=0;b<3;++b) {
            float by=id.y*6.0+0.8+float(b)*1.65
                     +0.45*(hash3(id+vec2(float(b)*17.0,93)).x-0.5);
            vec2 path=roofPath(by,seed);
            float collected=smoothstep(by-0.25,by+0.25,head);
            float grow=smoothstep(0.0,0.24+0.04*float(b),age);
            vec2 radius=vec2(0.35+0.18*seed.y,0.48+0.18*seed.x)*mix(0.4,1.0,grow);
            water+=roofCap(at-vec2(base+path.x,by),radius,pixel)*grow*(1.0-collected)*life;
        }
        vec2 headPath=roofPath(head,seed);
        float moving=smoothstep(0.37,0.42,age)*life;
        water+=roofCap(at-vec2(base+headPath.x,head),vec2(0.48,0.64)*(0.8+0.4*travel),pixel)*moving;
        // Temporary meandering wake, limited to the recently traversed path.
        vec2 path=roofPath(at.y,seed);
        float dx=at.x-base-path.x;
        float width=0.055+seed.y*0.045;
        float filtered=sqrt(width*width+pixel*pixel*0.16);
        float q=dx/filtered;
        float behind=head-at.y;
        float window=smoothstep(0.0,0.25,behind)*(1.0-smoothstep(0.5,1.8,behind));
        float h=exp(-q*q)*0.035*width/filtered*window*moving;
        float gx=-2.0*q/filtered*h;
        water+=vec4(gx,-gx*path.y,h,h/0.08);
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
    vec4 a=roofChartWater(vec2(p.x,-p.y*1.41421356),pixel);
    vec4 b=roofChartWater(vec2(p.z,-p.y*1.41421356),pixel);
    vec3 gradient=vec3(a.x*weight,-mix(b.y,a.y,weight)*1.41421356,b.x*(1.0-weight));
    gradient-=normal*dot(normal,gradient);
    return vec4(gradient,clamp(mix(b.w,a.w,weight),0.0,1.0))*eligible*resolved;
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
