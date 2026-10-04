#version 150 compatibility
uniform sampler2D heightTex;
uniform vec2 mapSize;
out vec2 worldXZ;
void main() {
    worldXZ=gl_Vertex.xz;
    vec2 size=vec2(textureSize(heightTex,0));
    vec2 uv=(clamp(worldXZ/mapSize,0.0,1.0)*(size-1.0)+0.5)/size;
    float h=texture2D(heightTex,uv).r;
    gl_Position=gl_ModelViewProjectionMatrix*vec4(worldXZ.x,max(h,0.0)+0.15,worldXZ.y,1);
    gl_TexCoord[0]=gl_MultiTexCoord0;
}
