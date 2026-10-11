#version 150 compatibility
in vec3 lightWorld;
uniform sampler2D buildingOccupancy;
uniform vec2 mapSize;
uniform vec2 heightRange;
uniform vec3 lamp;
uniform float radius;
uniform vec3 color;
uniform float strength;
uniform float hasOccupancy;
uniform int sourceMetadata=0;
uniform float sourceOwner=-1.0;
void main() {
    vec2 delta=lightWorld.xz-lamp.xz;
    float distanceToLight=length(vec3(delta.x,lightWorld.y-lamp.y,delta.y));
    if(distanceToLight>=radius || lamp.y+radius<heightRange.x || lamp.y-radius>=heightRange.y)discard;
    if(hasOccupancy>0.5) {
        float cells=length(delta/mapSize*vec2(textureSize(buildingOccupancy,0)));
        int steps=min(96,max(1,int(ceil(cells*2.0))));
        for(int i=1;i<=96;++i) {
            if(i>steps)break;
            vec2 p=mix(lamp.xz,lightWorld.xz,float(i)/float(steps))/mapSize;
            if(any(lessThan(p,vec2(0))) || any(greaterThanEqual(p,vec2(1))))discard;
            if(texture2D(buildingOccupancy,p).r>0.5)discard;
        }
    }
    float fade=1.0-smoothstep(0.0,radius,distanceToLight);
    vec3 radiance=color*strength*fade*fade;
    float energy=dot(radiance,vec3(0.2126,0.7152,0.0722));
    if(sourceMetadata!=0) {
        if(energy<0.00001)discard;
        gl_FragColor=vec4(lamp,sourceOwner>=0.0 ? sourceOwner+1.0 : 0.5);
        gl_FragDepth=1.0/(1.0+energy);
    } else {
        // Alpha carries an additive source-height moment into the local RC.
        gl_FragColor=vec4(radiance,energy*lamp.y/2048.0);
        gl_FragDepth=gl_FragCoord.z;
    }
}
