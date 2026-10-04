#version 150 compatibility

uniform sampler2D screencopy;
uniform sampler2D depthcopy;
uniform vec2 resolution;
uniform float realTime;
uniform float slowAmount;
uniform float temporalPrivilege;
uniform float clipZeroToOne;
uniform mat4 viewProjectionInv;
uniform int sourceCount;
// xyz: visible source position; w: locally animated age, frozen on pause.
uniform vec4 rippleSources[4];

float luminance(vec3 c) { return dot(c,vec3(.299,.587,.114)); }

// A droplet's crest and weaker trailing meniscus, not a filled energy disc.
vec3 waterRipples(vec2 uv, vec2 px)
{
    float depth=texture2D(depthcopy,uv).r;
    if (depth>=.999999 || sourceCount==0 || slowAmount<=0.0) return vec3(0.0);
    float ndcDepth=mix(depth*2.0-1.0,depth,clipZeroToOne);
    vec4 homogeneous=viewProjectionInv*vec4(uv*2.0-1.0,ndcDepth,1.0);
    if (abs(homogeneous.w)<.00001) return vec3(0.0);
    vec3 world=homogeneous.xyz/homogeneous.w;
    vec2 displacement=vec2(0.0);
    float highlight=0.0;
    for (int i=0;i<4;++i) {
        if (i>=sourceCount) break;
        vec4 source=rippleSources[i];
        float radial=length(world.xz-source.xz);
        // Fade up tall buildings; depth reconstruction keeps the ring behind occluders.
        float heightFade=1.0-smoothstep(75.0,230.0,abs(world.y-source.y));
        vec2 gradient=vec2(dFdx(radial),dFdy(radial));
        float footprint=length(gradient);
        float width=max(1.6,min(8.0,footprint*1.1));
        vec2 direction=gradient/max(.001,footprint);
        float distanceFade=1.0-smoothstep(700.0,1156.0,radial);
        float detailFade=1.0-smoothstep(12.0,45.0,footprint);
        if (heightFade*distanceFade*detailFade<.001) continue;
        for (int j=0;j<3;++j) {
            float elapsed=source.w-float(j)*6.0;
            float age=mod(max(0.0,elapsed),18.0);
            float radius=40.0+62.0*age;
            float envelope=step(0.0,elapsed)*smoothstep(0.0,.8,age)
                *(1.0-smoothstep(15.0,18.0,age))*heightFade*distanceFade*detailFade;
            float d=radial-radius;
            if (d>width*4.0 || d< -8.0-width*5.4) continue;
            float crest=exp(-pow(d/width,2.0));
            float trailing=exp(-pow((d+8.0)/(width*1.35),2.0))*.38;
            displacement+=direction*px*(crest-trailing)*envelope*1.8;
            highlight+=(crest+trailing)*envelope;
        }
    }
    if (highlight<.00001) return vec3(0.0);
    // Under two pixels even where several temporal fields overlap.
    displacement=clamp(displacement,-px*2.0,px*2.0)*slowAmount;
    vec3 bent=texture2D(screencopy,clamp(uv+displacement,px,1.0-px)).rgb;
    vec3 original=texture2D(screencopy,uv).rgb;
    return bent-original+vec3(.18,.105,.045)*min(highlight,1.3)*slowAmount;
}

void main()
{
    vec2 uv=gl_TexCoord[0].st;
    vec2 safeResolution=max(resolution,vec2(1.0));
    vec2 px=1.0/safeResolution;
    vec3 color=texture2D(screencopy,uv).rgb;
    float slow=clamp(slowAmount,0.0,1.0);
    float outsider=1.0-clamp(temporalPrivilege,0.0,1.0);
    // Preserve orange cognition while retaining the existing temporal grade.
    color=mix(color,vec3(luminance(color)),.16*slow);
    color=mix(color,color*vec3(.96,.99,1.035),.45*slow);
    color+=waterRipples(uv,px);
    float aspect=safeResolution.x/safeResolution.y;
    vec2 centered=(uv-.5)*vec2(aspect,1.0);
    color*=1.0-outsider*slow*.24*smoothstep(.30,.90,length(centered));
    float scan=.5+.5*sin(gl_FragCoord.y*1.10+realTime*2.0);
    color-=vec3(.012,.016,.020)*scan*outsider*slow;
    gl_FragColor=vec4(clamp(color,0.0,1.0),1.0);
}
