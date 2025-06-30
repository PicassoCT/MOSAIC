#version 150
uniform sampler2D u_finalSeed;
uniform vec2 u_texSize;
in vec2 gl_TexCoord[1];
out float outDist;

void main() {
  vec2 uv = gl_TexCoord[0].st;
  vec2 seed = texture(u_finalSeed, uv).xy;
  if (seed.x < 0.0)
    outDist = 1.0;
  else
    outDist = length((uv - seed) * u_texSize);
}
