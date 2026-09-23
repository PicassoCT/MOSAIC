#version 150 compatibility
uniform sampler2D sceneDepth;
uniform vec2 viewportSize, viewportOrigin;
uniform float effectTime, seed, density, emission, opacity, phase;
uniform vec3 smokeColor, hotColor, ambient;
uniform int shape, steps, volumeAxis;
uniform float gradientSign;
noperspective in vec4 nearH;
noperspective in vec4 farH;
out vec4 fragColor;
float hash(vec3 p) {
    p=fract(p*.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z);
}
float noise(vec3 p) {
    vec3 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),
                   mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),
                   mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float field(vec3 p, out float heat, out float light) {
    if(volumeAxis==0) p=p.yxz;
    if(volumeAxis==2) p=p.xzy;
    if(shape==1) p.y*=gradientSign;
    vec3 q=p*3.8+vec3(seed*.37,-effectTime,seed*.13);
    q.xz+=.35*vec2(sin(p.y*5.0+effectTime),cos(p.y*4.0-effectTime*.7));
    float n=noise(q)*.72+noise(q*2.07+7.3)*.28;
    float envelope;
    if(shape==1) { // elongated exhaust, hot toward the +Y nozzle end
        float y=clamp(p.y*.5+.5,0.0,1.0);
        float radius=mix(.65,.22,y);
        envelope=1.0-length(vec3(p.x/radius,p.y*.95,p.z/radius));
        heat=clamp(y*.85+.35-length(p.xz)*.5,0.0,1.0);
    } else if(shape==2) {
        envelope=1.0-length(vec2((length(p.xz)-.55)/.3,p.y/.6));
        heat=.35;
    } else if(shape==3) { // rising cap, stalk and expanding ground dust
        float cap=1.0-length((p-vec3(0,.38,0))/vec3(.78,.48,.78));
        float stalk=1.0-length((p-vec3(0,-.2,0))/vec3(.25,.65,.25));
        float ring=1.0-length(vec2((length(p.xz)-.62)/.26,(p.y+.78)/.14));
        float mushroom=max(max(cap,stalk),ring);
        float fireball=1.0-length((p-vec3(0,-.25,0))/vec3(.65,.6,.65));
        envelope=mix(fireball,mushroom,smoothstep(.015,.14,phase));
        heat=(1.0-smoothstep(.02,.5,phase))*clamp(.8+n*.6-p.y*.2,0.0,1.0);
    } else {
        envelope=1.0-length(p);
        heat=(1.0-smoothstep(.0,.7,phase))*(.5+n*.5);
    }
    // A single offset coarse-noise sample gives inexpensive directional relief.
    // This is a lighting approximation, not a secondary shadow ray march.
    float lightNoise=noise(q+vec3(.55,.7,.3));
    light=clamp(.55+(n-lightNoise)*2.4+p.y*.12,.16,1.0);
    heat*=smoothstep(.02,.65,envelope)*smoothstep(.32,.8,n);
    // Density is zero before reaching proxy edges: no visible box boundary.
    float edge=1.0-smoothstep(.87,1.0,max(max(abs(p.x),abs(p.y)),abs(p.z)));
    return max(envelope+(n-.55)*.65,0.0)*smoothstep(.24,.66,n)*edge;
}
void main() {
    vec3 ro=nearH.xyz/nearH.w;
    vec3 farPoint=farH.xyz/farH.w;
    vec3 rd=normalize(farPoint-ro);
    // Signed epsilon handles perfectly axial rays without division by zero.
    vec3 safeDir=mix(vec3(-1.0),vec3(1.0),greaterThanEqual(rd,vec3(0.0)))*max(abs(rd),vec3(1e-7));
    vec3 a=(-vec3(1.0)-ro)/safeDir,b=(vec3(1.0)-ro)/safeDir;
    vec3 lo=min(a,b),hi=max(a,b);
    float entry=max(max(lo.x,lo.y),max(lo.z,0.0));
    float exitT=min(min(hi.x,hi.y),hi.z);
    vec2 uv=(gl_FragCoord.xy-viewportOrigin)/viewportSize;
    float depth=texture(sceneDepth,uv).r;
    vec4 sceneH=mix(nearH,farH,depth);
    vec3 scenePoint=sceneH.xyz/sceneH.w;
    exitT=min(exitT,dot(scenePoint-ro,rd));
    if(exitT<=entry) discard;
    float stepSize=(exitT-entry)/float(steps);
    float jitter=hash(vec3(floor(gl_FragCoord.xy),seed));
    vec4 result=vec4(0.0);
    for(int i=0;i<32;i++) {
        if(i>=steps || result.a>.985) break;
        float t=entry+(float(i)+.25+.5*jitter)*stepSize;
        vec3 p=ro+rd*t;
        float heat,light;
        float d=field(p,heat,light)*density;
        // Soft intersection with scene depth, measured in normalized volume units.
        d*=smoothstep(0.0,.06,exitT-t);
        float alpha=1.0-exp(-d*stepSize*3.0);
        vec3 smoke=smokeColor*(ambient*.4+vec3(light*.8));
        vec3 color=mix(smoke,hotColor*emission,clamp(heat*min(emission,1.0),0.0,1.0));
        result.rgb+=(1.0-result.a)*alpha*color;
        result.a+=(1.0-result.a)*alpha;
    }
    fragColor=result*opacity; // premultiplied RGB; transparent smoke cannot leave a glow
}
