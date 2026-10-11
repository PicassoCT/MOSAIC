#version 150 compatibility
uniform sampler2D cascadeTex;
uniform sampler2D occupancyTex;
uniform sampler2D emissionTex;
uniform float intensity;
#ifdef HEIGHT_AWARE
uniform sampler2D cascadeSourceTex;
uniform vec2 mapSize;
uniform vec2 domainOrigin;
float sourceWeight(vec3 color) { return dot(max(color,vec3(0.0)),vec3(0.2126,0.7152,0.0722)); }
void chooseSource(vec4 candidate,vec3 color,float weight,inout vec4 selected,inout float strongest)
{
    float energy=sourceWeight(color)*weight;
    if(candidate.w>0.0 && energy>strongest) { selected=candidate; strongest=energy; }
}
#endif
vec3 visibleProbe(vec2 receiverUV, ivec2 probe, ivec2 tile, int probes, out vec4 source)
{
    source=vec4(0.0);
    vec3 value=texelFetch(cascadeTex,tile+probe,0).rgb;
    if(max(value.r,max(value.g,value.b))<=0.0) return value;
    vec2 targetUV=(vec2(probe)+0.5)/float(probes);
    float texels=length((targetUV-receiverUV)*vec2(textureSize(occupancyTex,0)));
    int steps=min(64,max(1,int(ceil(texels*2.0))));
    for(int i=0;i<64;++i) {
        if(i>=steps) break;
        vec2 uv=mix(receiverUV,targetUV,(float(i)+0.5)/float(steps));
        if(texture2D(occupancyTex,uv).r>0.5) return vec3(0.0);
    }
#ifdef HEIGHT_AWARE
    source=texelFetch(cascadeSourceTex,tile+probe,0);
#endif
    return value;
}
void main()
{
    vec2 uv=gl_TexCoord[0].st;
    int probes=textureSize(cascadeTex,0).x/2;
    // Resolve the four direction tiles independently, preventing tile bleed.
    vec2 p=uv*float(probes)-0.5;
    ivec2 b=ivec2(floor(p)); vec2 w=fract(p);
    ivec2 a=clamp(b,ivec2(0),ivec2(probes-1));
    ivec2 c=clamp(b+ivec2(1),ivec2(0),ivec2(probes-1));
    vec3 light=vec3(0.0);
    vec4 representative=vec4(0.0);
    float strongest=0.0;
    for(int d=0;d<4;++d) {
        ivec2 tile=ivec2(d%2,d/2)*probes;
        vec4 s00,s10,s01,s11;
        vec3 v00=visibleProbe(uv,a,tile,probes,s00);
        vec3 v10=visibleProbe(uv,ivec2(c.x,a.y),tile,probes,s10);
        vec3 v01=visibleProbe(uv,ivec2(a.x,c.y),tile,probes,s01);
        vec3 v11=visibleProbe(uv,c,tile,probes,s11);
        light+=mix(mix(v00,v10,w.x),mix(v01,v11,w.x),w.y)*0.25;
#ifdef HEIGHT_AWARE
        chooseSource(s00,v00,(1.0-w.x)*(1.0-w.y)*0.25,representative,strongest);
        chooseSource(s10,v10,w.x*(1.0-w.y)*0.25,representative,strongest);
        chooseSource(s01,v01,(1.0-w.x)*w.y*0.25,representative,strongest);
        chooseSource(s11,v11,w.x*w.y*0.25,representative,strongest);
#endif
    }
    // Occupied receivers stay dark; retain emission at the source surface.
    if(texture2D(occupancyTex,uv).r>0.5) {
        light=vec3(0.0); representative=vec4(0.0); strongest=0.0;
    }
    vec4 emitted=texture2D(emissionTex,uv);
    light=max(light,emitted.rgb);
#ifdef HEIGHT_AWARE
    float sourceEnergy=sourceWeight(emitted.rgb);
    if(sourceEnergy>0.000001) {
        vec2 position=domainOrigin+uv*mapSize;
        vec4 source=vec4(position.x,emitted.a*2048.0/sourceEnergy,position.y,1.0);
        chooseSource(source,emitted.rgb,1.0,representative,strongest);
    }
    gl_FragData[0]=vec4(light*intensity,1.0);
    gl_FragData[1]=representative;
#else
    gl_FragColor=vec4(light*intensity,1.0);
#endif
}
