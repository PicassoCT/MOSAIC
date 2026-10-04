#version 150 compatibility
uniform sampler2D heightTex;
uniform sampler2D sandTex;
uniform vec2 mapSize;
in vec2 worldXZ;
float heightAt(vec2 p) {
    vec2 size=vec2(textureSize(heightTex,0));
    return texture2D(heightTex,(clamp(p/mapSize,0.0,1.0)*(size-1.0)+0.5)/size).r;
}
void main() {
    vec2 p=worldXZ;
    if(any(lessThan(p,vec2(0))) || any(greaterThan(p,mapSize))) {gl_FragColor=vec4(0);return;}
    float h=heightAt(p),side=h>=0.0 ? 1.0 : -1.0;
    if(h>12.0 || h< -24.0) {gl_FragColor=vec4(0);return;}
    float distance=97.0;vec2 coast=p,inland=vec2(0);
    // Only at initialization/rebuild: bounded radial shoreline search. It
    // rejects inland lowlands and uses real water crossings, not height alone.
    for(int ray=0;ray<16;++ray) {
        float a=float(ray)*0.3926990817;vec2 dir=vec2(cos(a),sin(a));
        float last=h,lastDistance=0.0;
        for(int j=1;j<=12;++j) {
            float d=float(j)*8.0;vec2 q=p+dir*d;
            if(any(lessThan(q,vec2(0))) || any(greaterThan(q,mapSize))) break;
            float sampleHeight=heightAt(q);
            if(sampleHeight*side<0.0) {
                float hit=mix(lastDistance,d,abs(last)/max(abs(last)+abs(sampleHeight),0.0001));
                if(hit<distance) {distance=hit;coast=p+dir*hit;inland=-dir*side;}
                break;
            }
            last=sampleHeight;lastDistance=d;
        }
    }
    float slope=length(vec2(heightAt(p+vec2(8,0))-heightAt(p-vec2(8,0)),
                            heightAt(p+vec2(0,8))-heightAt(p-vec2(0,8))))/16.0;
    // Water uses the adjoining beach material; land uses its own material.
    vec2 materialPoint=h>=0.0 ? p : coast+inland*8.0;
    float sand=texture2D(sandTex,clamp(materialPoint/mapSize,0.0,1.0)).r;
    float eligible=smoothstep(0.3,0.7,sand)*(1.0-smoothstep(0.25,0.65,slope))
        *(1.0-smoothstep(7.0,12.0,h))*smoothstep(-24.0,-12.0,h)
        *(1.0-smoothstep(64.0,88.0,distance));
    gl_FragColor=vec4(distance*side,eligible,h,distance<96.0 ? 1.0 : 0.0);
}
