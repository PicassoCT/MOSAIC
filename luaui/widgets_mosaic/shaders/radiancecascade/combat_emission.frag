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
    gl_FragColor=vec4(color*strength*fade*fade,0.0);
}
