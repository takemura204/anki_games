#version 460 core
#include <flutter/runtime_effect.glsl>

// Kinetic Sand ASMR: dense visible grain + normal-map lighting + slow avalanche flow
// Real kinetic sand: cohesive grains that hold shape then slowly slump

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;
uniform vec4 uGlow;
uniform float uOpacity;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * vnoise(p);
    p = p * 2.1 + vec2(1.7, 9.2);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;
  vec2 fragPx = FlutterFragCoord().xy;

  // --- Mounding shape (center elevated, like freshly poured sand pile) ---
  float mound = 1.0 - pow(length((uv - 0.5) * 1.85), 1.6);
  mound = clamp(mound, 0.0, 1.0);

  // --- Slow avalanche flow: sand slides gently downward with slight sway ---
  vec2 flowDir = vec2(0.038 * sin(uTime * 0.28), 0.08);
  vec2 sandUV = uv * 7.0 + flowDir * uTime;

  float surface    = fbm(sandUV);
  float fineSurf   = fbm(uv * 19.0 + flowDir * uTime * 1.4);

  // --- Normal map from height gradient (raking light reveals grain relief) ---
  float eps = 0.012;
  float hL = fbm(sandUV - vec2(eps * 7.0, 0.0));
  float hR = fbm(sandUV + vec2(eps * 7.0, 0.0));
  float hU = fbm(sandUV - vec2(0.0, eps * 7.0));
  float hD = fbm(sandUV + vec2(0.0, eps * 7.0));
  vec3 normal = normalize(vec3((hL - hR) * 4.5, (hU - hD) * 4.5, 1.0));

  // Raking light from upper-left (classic ASMR lighting for texture)
  vec3 lightDir = normalize(vec3(0.55, -0.75, 1.0));
  float ndotl = max(0.0, dot(normal, lightDir));

  // --- Individual visible grain dots ---
  float grainRaw = hash(floor(fragPx * 0.88));
  float grainVis = step(0.60, grainRaw) * (0.38 + hash(fragPx * 1.25) * 0.62);

  // --- Height field ---
  float height = mound * 0.72 + surface * 0.20 + fineSurf * 0.08;
  height = clamp(height, 0.0, 1.0);

  // --- Color: dark valley → bright sunlit peak ---
  vec3 valley = uBase.rgb * 0.52;
  vec3 peak = mix(uBase.rgb, uGlow.rgb, 0.58);
  vec3 color = mix(valley, peak, height);

  // Normal-map lighting (makes individual grains pop with shadow/highlight)
  color *= 0.58 + 0.42 * ndotl;

  // Grain dot brightening (micro-highlights on individual grains)
  color += grainVis * 0.05 * peak;

  color = clamp(color, 0.0, 1.0);
  fragColor = vec4(color, uOpacity);
}
