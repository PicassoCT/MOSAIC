#version 150
uniform sampler2D u_binaryTex;
uniform vec2 u_texSize;
in vec2 gl_TexCoord[1];
out vec2 outSeed;

void main() {
  vec2 uv = gl_TexCoord[0].st;
  float value = texture(u_binaryTex, uv).r;
  float dx = abs(texture(u_binaryTex, uv + vec2(1.0 / u_texSize.x, 0)).r - value);
  float dy = abs(texture(u_binaryTex, uv + vec2(0, 1.0 / u_texSize.y)).r - value);
  if (dx + dy > 0.01)
    outSeed = uv;
  else
    outSeed = vec2(-1.0);
}
