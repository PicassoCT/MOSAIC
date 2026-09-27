#version 150 compatibility
flat in vec3 patchPower;
flat in vec3 patchPosition;
flat in vec2 patchNormal;
flat in float patchRadius;
uniform sampler2D groundTex;
uniform sampler2D blockerTex;
uniform sampler2D wallTex;
uniform vec2 mapSize;
uniform vec2 fieldOrigin;
uniform float fieldSpan;
uniform float fieldResolution;
uniform float cutoff;
uniform vec2 maskOrigin;
uniform float maskSpan;
uniform vec2 buildingY;
float terrain(vec2 p){return texture2D(groundTex,p/mapSize).r;}
bool blocked(vec3 target){
    float cell=maskSpan/float(textureSize(wallTex,0).x);
    vec3 start=patchPosition+vec3(patchNormal.x,0,patchNormal.y)*cell*1.8;
    vec3 delta=target-start;
    // Stop self-wall traversal at the edge of this building's detailed mask.
    float finish=1.0;
    for(int axis=0;axis<2;++axis){
        float d=delta.xz[axis];
        if(abs(d)>0.001){
            float boundary=maskOrigin[axis]+(d>0.0?maskSpan:0.0);
            finish=min(finish,max(0.0,(boundary-start.xz[axis])/d));
        }
    }
    int ownSteps=min(192,max(1,int(ceil(length(delta.xz)*finish/(cell*0.5)))));
    for(int i=0;i<192;++i){
        if(i>=ownSteps)break;
        vec3 p=start+delta*((float(i)+0.5)/float(ownSteps)*finish);
        vec2 uv=(p.xz-maskOrigin)/maskSpan;
        if(p.y>=buildingY.x && p.y<buildingY.y && all(greaterThanEqual(uv,vec2(0))) && all(lessThan(uv,vec2(1)))){
            int band=clamp(int((p.y-buildingY.x)/(buildingY.y-buildingY.x)*4.0),0,3);
            if(texture2D(wallTex,uv)[band]>0.5)return true;
        }
    }
    float worldCell=min(mapSize.x,mapSize.y)/(float(textureSize(blockerTex,0).x)/4.0);
    // World rasterization expands this facade into coarse cells outside the
    // actual wall. Self-occlusion is already tested above at facade resolution.
    // Bias only that coarse test; retain nearby detailed walls and terrain.
    float sourceBias=1.5*max(mapSize.x,mapSize.y)/(float(textureSize(blockerTex,0).x)/4.0);
    int steps=min(192,max(1,int(ceil(length(delta.xz)/(worldCell*0.5)))));
    for(int i=0;i<192;++i){
        if(i>=steps)break;
        float t=(float(i)+0.5)/float(steps);vec3 p=start+delta*t;
        if(p.y<terrain(p.xz)-1.0)return true;
        if(p.y>=0.0 && p.y<2048.0 && length(p.xz-patchPosition.xz)>sourceBias){
            int band=int(p.y/128.0);vec2 tile=vec2(band%4,band/4);
            vec2 uv=(tile+clamp(p.xz/mapSize,vec2(0),vec2(0.999999)))/4.0;
            if(texture2D(blockerTex,uv).r>0.5)return true;
        }
    }
    return false;
}
void main(){
    vec2 xz=fieldOrigin+gl_FragCoord.xy/fieldResolution*fieldSpan;
    if(any(lessThan(xz,vec2(0))) || any(greaterThanEqual(xz,mapSize)))discard;
    float y=terrain(xz);if(y<0.0)discard;
    vec3 target=vec3(xz.x,y,xz.y),delta=target-patchPosition;
    float distance2=dot(delta,delta),horizontal=length(delta.xz);
    if(delta.y>=-1.0 || horizontal>=patchRadius)discard;
    float forward=max(dot(patchNormal,delta.xz),0.0);
    vec2 stepSize=mapSize/vec2(textureSize(groundTex,0));
    vec3 groundNormal=normalize(vec3((terrain(xz-vec2(stepSize.x,0))-terrain(xz+vec2(stepSize.x,0)))/(2.0*stepSize.x),
        1.0,(terrain(xz-vec2(0,stepSize.y))-terrain(xz+vec2(0,stepSize.y)))/(2.0*stepSize.y)));
    // Area-light geometry term: source cosine * receiver cosine / distance^2.
    // Finite patch softening bounds the near field; height is never discarded.
    float soften=max(1.0,max(patchPower.r,max(patchPower.g,patchPower.b))*0.05);
    vec3 light=patchPower*forward*max(dot(groundNormal,-delta),0.0)/pow(distance2+soften,2.0);
    float peak=max(light.r,max(light.g,light.b));
    if(peak<=cutoff)discard;
    light*=smoothstep(cutoff,cutoff*2.0,peak)*(1.0-smoothstep(patchRadius*0.8,patchRadius,horizontal));
    if(blocked(target))discard;
    gl_FragColor=vec4(light,0);
}
