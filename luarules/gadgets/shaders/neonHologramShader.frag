#version 150 compatibility
#line 20002
// Fragmentshader
//  Set the precision for data types used in this shader
#define RED vec4(1.0, 0.0, 0.0, 0.5)
#define GREEN vec4(0.0, 1.0, 0.0, 0.5)
#define BLUE vec4(0.0, 0.0, 1.0, 0.5)
#define WHITE vec4(1.0)
#define NONE vec4(0.)
#define PI 3.14159f
#define Y_NORMAL_CUTOFFVALUE 0.995

#define CASINO 1
#define BROTHEL 2
#define BUISNESS 3
#define ASIAN 4

//////////////////////    //////////////////////    //////////////////////
/////////////////////////
// declare uniforms
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D normaltex;
uniform sampler2D reflecttex;
uniform sampler2D screentex;
uniform sampler2D afterglowbuffertex;

uniform float time;
uniform float timepercent;
uniform float rainPercent;
uniform vec2 viewPortSize;

uniform vec3 unitCenterPosition;
// uniform vec3 vCamPositionWorld;
float rainPercentage;
uniform int typeDefID;
// Varyings passed from the vertex shader
in Data {
  vec2 vSphericalUVs;
  vec2 vCubicUVs;
  vec3 vPixelPositionWorld;
  vec3 normal;
  vec3 sphericalNormal;
  vec2 orgColUv;
  vec3 vVertexPos;
};

// GLOBAL VARIABLES/////    //////////////////////    //////////////////////
// //////////////////////

float radius = 16.0;
vec2 pixelCoord;

//////////////////////    //////////////////////    //////////////////////
/////////////////////////
bool isActive(vec2 colRowId) {
  float modulator = ceil((1 / rainPercentage) * 10.0);
  return floor(mod(colRowId.x + colRowId.y, modulator)) == 0;
}

float getLightPercentageFactorByTime() {
  return mix(0.35, 0.75, (1 + sin(timepercent * 2 * PI)) * 0.5);
}

float getSineWave(float posOffset,
                  float posOffsetScale,
                  float time,
                  float timeSpeedScale) {
  return sin((posOffset * posOffsetScale) + time * timeSpeedScale);
}

float getCosineWave(float posOffset,
                    float posOffsetScale,
                    float time,
                    float timeSpeedScale) {
  return cos((posOffset * posOffsetScale) + time * timeSpeedScale);
}

float cubicTransparency(vec2 position) {
  float cubeSize = 2.0;
  if (mod(position.x, cubeSize) < 0.5 || mod(position.y, cubeSize) < 0.5) {
    return abs(0.35 + abs(sin(time)) * 0.5) * getLightPercentageFactorByTime();
  }
  return getLightPercentageFactorByTime();
}

bool isCornerCase(vec2 uvCoord,
                  float effectStart,
                  float effectEnd,
                  float glowSize) {
  if (uvCoord.x > effectStart && uvCoord.x < effectStart + glowSize &&
      uvCoord.y > effectStart && uvCoord.y < effectStart + glowSize) {
    return true;
  }

  if (uvCoord.x > effectEnd - glowSize && uvCoord.x < effectEnd &&
      uvCoord.y > effectStart && uvCoord.y < effectStart + glowSize) {
    return true;
  }

  if (uvCoord.x > effectEnd - glowSize && uvCoord.x < effectEnd &&
      uvCoord.y > effectEnd - glowSize && uvCoord.y < effectEnd) {
    return true;
  }

  if (uvCoord.x > effectStart && uvCoord.x < effectStart + glowSize &&
      uvCoord.y > effectEnd - glowSize && uvCoord.y < effectEnd) {
    return true;
  }
  return false;
}

float GetHologramTransparency() {
  float sfactor = 4.0;  // scaling factor position
  float hologramTransparency = 0.0;
  float baseInterferenceRipples = max(
      min(0.35 + sin(time) * 0.1, 0.75),  // 0.25
      0.5 +
          abs(0.3 * getSineWave(vPixelPositionWorld.y * sfactor, 0.10,
                                time * 6.0, 0.10)) -
          abs(getSineWave(vPixelPositionWorld.y * sfactor, 1.0, time, 0.2)) +
          0.4 * abs(getSineWave(vPixelPositionWorld.y * sfactor, 0.5, time,
                                0.3)) -
          0.15 * abs(getCosineWave(vPixelPositionWorld.y * sfactor, 0.75, time,
                                   0.5)) +
          0.15 *
              getCosineWave(vPixelPositionWorld.y * sfactor, 0.5, time, 2.0));

  if (typeDefID == CASINO)  // casino
  {
    vec3 normedSphericalUvs = normalize(sphericalNormal);
    float sphericalUVsValue =
        (normedSphericalUvs.x + normedSphericalUvs.y) / 2.0;
    hologramTransparency =
        mix(mod(sphericalUVsValue + baseInterferenceRipples, 1.0),
            cubicTransparency(vSphericalUVs), 0.9);
  }
  if (typeDefID == BROTHEL || typeDefID == ASIAN)  // brothel || asian buisness
  {
    float averageShadow = (sphericalNormal.x * sphericalNormal.x +
                           sphericalNormal.y * sphericalNormal.y +
                           sphericalNormal.z + sphericalNormal.z) /
                          4.0;
    hologramTransparency =
        max(0.2, mix(baseInterferenceRipples, (2 + sin(time)) * 0.55, 0.5) +
                     averageShadow);
  }

  if (typeDefID == BUISNESS)  // buisness
  {
    hologramTransparency = baseInterferenceRipples;
  }
  return hologramTransparency;
}

vec3 applyColorAberation(vec3 col) {
  if (typeDefID == CASINO || typeDefID == ASIAN)  // casino
  {
    return mix(col, sphericalNormal, max(sin(time), 0.0) / 10.0);
  }
  if (typeDefID == BROTHEL)  // brothel
  {
    float colHighLights =
        (-0.5 + ((abs(sphericalNormal.x) + abs(sphericalNormal.z)) / 2.0)) /
        10.0;
    return col + colHighLights;
  }

  if (typeDefID == BUISNESS) {
    if (timepercent < 0.25 && mod(time, 60) < 0.1) {
      return sphericalNormal;  // glitchy
    }
  }

  return col;
}

float random(float x) {
  return fract(sin(x * 12.9898) * 43758.5453);
}

float columnWidth = 0.5;  // max(0.1,abs(sin(time)));//0.05;
float halfSize = (columnWidth / 2.);
// const float pixelPillarSize = 100.0;

const float fallSpeed = 6.0;       // Controls vertical speed
const float shimmerFreq = 32.0;    // How fast it sparkles
const float trailFade = 512.0;     // How long the trail glows
const float recoverySpeed = 30.0;  // How fast it fades back
const float rainDropScale = 2.0;

bool isActive(float value) 
{
  float modolu = float(ceil(abs(rainPercentage) * 10.0));
  return floor(mod(value, modolu)) == 0.0;
}
float GetRainDropWaveAt(float heightValue, float colOffset) 
{
  return sin(time * fallSpeed - heightValue * rainDropScale +
             colOffset * 6.2831);
}

float GetDropCenterYPosition(float heightValue, float colOffset) 
{
  return time * fallSpeed - heightValue * rainDropScale + colOffset * 6.2831;
}

float debugGetCheckerBoardAlpha(vec2 uv, float alpha) 
{
  if (uv.x < 0.5 || uv.y < 0.5)
    return 1.0;
  return alpha;
}

float getGlow(float wave, float time, float height) 
{
  float glow = 0.0;
  if (wave > 0.0) {
    float dropGlow = exp(-wave * trailFade);
    float shimmer = sin((time + height * 5.0) * shimmerFreq) * 0.5 + 0.5;
    glow = dropGlow * shimmer;
  }
  return glow;
}

float getAlpha(float height, float wave) 
{
  // Sparkling glow when wave > 0
  float glow = getGlow(wave, time, height);

  // Recovery phase: when wave < 0
  float alphaRecovery = 0.0;
  if (wave < 0.0) {
    alphaRecovery = 1.0 - exp(wave * recoverySpeed);
  }

  // Final alpha: bright when glowing, then fades out, then fades back in
  return glow + alphaRecovery * 0.5;
}

vec2 getColRowIdentifier(vec3 vertexPos) 
{
  return vec2(floor(vertexPos.x / columnWidth),
              floor(vertexPos.z / columnWidth));
}

float getColOffset(vec3 vertexPos) 
{
  vec2 colRow = getColRowIdentifier(vertexPos);
  float v =
      dot(colRow * colRow.x, vec2(cos(colRow.y), sin(colRow.x))) * 43758.5453;
  return random(v);
}

vec4 applyAlphaMask(float sinVal, vec4 col) 
{
  return col;
  if (sinVal <= 0.)
    return col;
  col.a = col.a * sinVal;
  return col;
}

vec4 applyColorShift(float sinVal,
                     float glow,
                     vec4 col,
                     bool inDrop,
                     vec3 dropColor) 
{
  if (sinVal > 0.) 
  {
    if (inDrop)
      return vec4(dropColor, 1.0);

    col.rgb = mix(col.rgb * col.rgb, col.rgb, sinVal);
    return applyAlphaMask(sinVal, col);
  }

  col.rgb = mix(col.rgb, vec4(1.).rgb + col.rgb * glow, sinVal + 1.);

  return applyAlphaMask(sinVal, col);
}

vec4 getPixelRainTopOfColumn(vec2 v_uv, vec4 originalColor)
{
  float colOffset = getColOffset(vertexPos);
  float wave = GetRainDropWaveAt(vertexPos.y, colOffset);
  float glow = exp(wave * trailFade);
  // determinate high effect
  vec2 colRow = getColRowIdentifier(vertexPos);
  float sum = float(colRow.x + colRow.y);
  if (isActive(sum)) 
  {
    return originalColor;
  }

  float col = colRow.x;
  float row = colRow.y;
  vec2 u_center =
      vec2(col * columnWidth + halfSize, row * columnWidth + halfSize);
  vec2 minEdge = u_center - halfSize * 0.95;
  vec2 maxEdge = u_center + halfSize * 0.95;

  // Create mask: 1 inside rect, 0 outside
  float u_radius = 0.1;  // Glow softness in UV units
  vec2 d = abs(v_uv - u_center);

  // Fade out edges using smoothstep
  float glowX = 1. - smoothstep(0.0, u_radius, d.x);
  float glowY = 1. - smoothstep(0.0, u_radius, d.y);
  float alpha = glowX * glowY;

  float inRect = step(minEdge.x, v_uv.x) * step(v_uv.x, maxEdge.x) *
                 step(minEdge.y, v_uv.y) * step(v_uv.y, maxEdge.y);

  return applyColorShift(wave, glow,
                         vec4(originalColor.rgb, mix(0., alpha, inRect)), false,
                         vec3(0.));
}

vec3 iridescentColor(float angleFactor) 
{
  // You can tweak this function for different rainbow styles
  float intensity = pow(1.0 - angleFactor, 2.0);
  float r = sin(2.0 * 3.1415 * intensity + 0.0) * 0.5 + 0.5;
  float g = sin(2.0 * 3.1415 * intensity + 2.0) * 0.5 + 0.5;
  float b = sin(2.0 * 3.1415 * intensity + 4.0) * 0.5 + 0.5;
  return vec3(r, g, b);
}

vec3 getDropColor(float wave, float dis, vec4 originalColor, vec3 normal) 
{
  return mix(iridescentColor(time + wave) / 3.0 + originalColor.rgb,
             WHITE.rgb,  // originalColor.rgb ,

             dis);
}

vec4 getPixelRainSideOfColumn(vec2 v_uv, vec4 originalColor) 
{
  v_uv.y = 1.0 - v_uv.y;

  // Which column we're in
  vec2 colRow = getColRowIdentifier(vertexPos);
  float col = colRow.x;
  float row = colRow.y;
  vec2 u_center =
      vec2(col * columnWidth + halfSize, row * columnWidth + halfSize);
  float colOffset = getColOffset(vertexPos);
  float sum = float(colRow.x + colRow.y);
  if (isActive(sum)) 
    {
        return originalColor;
    }

  // Drop "wave" — sine over time and vertical pos
  float wave = GetRainDropWaveAt(v_uv.y, colOffset);
  float glow = getGlow(wave, time, vertexPos.y);

  // Glow color
  vec3 color = originalColor.rgb * glow;
  vec2 dropCenter = u_center.xy;
  dropCenter.y +=
      colOffset;  // GetDropCenterYPosition(u_center.y, colOffset);// + time*;
  float disDropCenter = distance(
      u_center.xy, vertexPos.xy);  // mix(0., 1., sin((wave/0.1)*3.1415));
  bool inDrop = wave > -0.1 && wave < 0.1;  // disDropCenter < halfSize &&

  // Glow intensity
  return applyColorShift(
      wave, glow, originalColor, inDrop,
      getDropColor(wave, disDropCenter, originalColor, normal));
}

float interpolate(float value, float stepValue, float range)
{
  float position = value - (stepValue);
  if (position < -range)
    return 0.;
  if (position > range)
    return 1.;

  position += range;
  return position / (2. * range);
}

void main() 
{
  // our original texcoord for this fragment
  vec2 uv = gl_FragCoord.xy;
  rainPercentage = rainPercent;

  // the amount to blur, i.e. how far off center to sample from
  // 1.0 -> blur by one pixel
  // 2.0 -> blur by two pixels, etc.
  float blur = radius / 1024.0;

  // the direction of our blur
  //(1.0, 0.0) -> x-axis blur
  //(0.0, 1.0) -> y-axis blur
  float hstep = 0.1;
  float vstep = 1.0;

  // apply blurring, using a 9-tap filter with predefined gaussian weights
  pixelCoord = gl_FragCoord.xy / viewPortSize;

  // build hybrid normals
  vec3 hyNormal = normalize(mix(normalize(normal), sphericalNormal, 0.5));
  float averageShadow = (hyNormal.x * hyNormal.x + hyNormal.y * hyNormal.y +
                         hyNormal.z + hyNormal.z) /
                        PI;

  float hologramTransparency = GetHologramTransparency();

  vec4 orgCol = texture(tex1, orgColUv);
  vec4 colWithBorderGlow = vec4(orgCol.rgb + orgCol.rgb * (1.0 - averageShadow),
                                hologramTransparency);  //

  colWithBorderGlow.rgb *= getLightPercentageFactorByTime();

  colWithBorderGlow.rgb = applyColorAberation(colWithBorderGlow.rgb);
  gl_FragColor = colWithBorderGlow;

  // This gives the holograms a sort of "afterglow", leaving behind a trail of
  // fading previous pictures similar to a very bright lightsource shining on
  // retina leaving afterimages

  if (true)  //(rainPercent > 0.5)
  {
    gl_FragColor = mix(getPixelRainSideOfColumn(vCubicUVs, GREEN),
                       getPixelRainTopOfColumn(vCubicUVs, RED),
                       interpolate(normal.g, Y_NORMAL_CUTOFFVALUE, 0.1));
  }
}
