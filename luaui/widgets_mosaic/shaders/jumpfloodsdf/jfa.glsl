#version 150
uniform sampler2D u_prevSeed;
uniform vec2 u_texSize;
uniform float u_jump;
in vec2 gl_TexCoord[1];
out vec2 outSeed;

float dist(vec2 a, vec2 b) {
  return length(a - b);
}

void main() {
  vec2 uv = gl_TexCoord[0].st;
  vec2 best = texture(u_prevSeed, uv).xy;
  float bestD = 1e20;

  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      vec2 offset = vec2(float(dx), float(dy)) * u_jump / u_texSize;
      vec2 nUV = uv + offset;
      vec2 candidate = texture(u_prevSeed, nUV).xy;
      if (candidate.x < 0.0) continue;
      float d = dist(uv, candidate);
      if (d < bestD) {
        bestD = d;
        best = candidate;
      }
    }
  }

  outSeed = best;
}
