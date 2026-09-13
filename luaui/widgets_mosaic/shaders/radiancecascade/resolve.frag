#version 150 compatibility
uniform sampler2D cascadeTex;
uniform sampler2D occupancyTex;
uniform sampler2D emissionTex;
uniform float intensity;
vec3 visibleProbe(vec2 receiverUV, ivec2 probe, ivec2 tile, int probes)
{
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
    for(int d=0;d<4;++d) {
        ivec2 tile=ivec2(d%2,d/2)*probes;
        vec3 v00=visibleProbe(uv,a,tile,probes);
        vec3 v10=visibleProbe(uv,ivec2(c.x,a.y),tile,probes);
        vec3 v01=visibleProbe(uv,ivec2(a.x,c.y),tile,probes);
        vec3 v11=visibleProbe(uv,c,tile,probes);
        light+=mix(mix(v00,v10,w.x),mix(v01,v11,w.x),w.y)*0.25;
    }
    // Occupied receivers stay dark; retain emission at the source surface.
    if(texture2D(occupancyTex,uv).r>0.5) light=vec3(0.0);
    light=max(light,texture2D(emissionTex,uv).rgb);
    gl_FragColor=vec4(light*intensity,1.0);
}
