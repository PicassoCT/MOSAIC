#version 150
uniform sampler2D u_sdf;
in vec2 gl_TexCoord[1];
out vec4 fragColor;

void main() {
  float d = texture(u_sdf, gl_TexCoord[0].st).r;
  float glow = smoothstep(32.0, 0.0, d); // adjust glow radius
  fragColor = vec4(glow, glow, glow, 1.0);
}
