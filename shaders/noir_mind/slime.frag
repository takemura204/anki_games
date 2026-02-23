#version 460 core
#include <flutter/runtime_effect.glsl>

// Bubble Gel Slime ASMR: thick liquid with micro-bubbles and slow internal flow
// Like dense green slime slowly oozing — liquid wave pattern + ultra-fine bubble sparkle

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;     // green #43A047
uniform vec4 uGlow;     // mint #A5D6A7
uniform float uOpacity;

out vec4 fragColor;

vec2 hash2(vec2 p) {
  p = fract(p * vec2(0.1031, 0.1030));
  p += dot(p, p.yx + 33.33);
  return fract((p.x + p.y) * p);
}

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

float fbm3(vec2 p) {
  float h = 0.0, a = 0.5;
  for (int i = 0; i < 3; i++) {
    h += a * vnoise(p);
    p = p * 2.1 + vec2(1.7, 9.2);
    a *= 0.52;
  }
  return h;
}

// Voronoi: returns (dist_to_nearest_site, vector_from_site_to_pixel)
vec3 voronoiData(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float minD = 8.0;
  vec2 minR = vec2(0.0);
  for (int dy = -1; dy <= 1; dy++) {
    for (int dx = -1; dx <= 1; dx++) {
      vec2 nb = vec2(float(dx), float(dy));
      vec2 site = hash2(i + nb) * 0.72 + 0.14;
      vec2 r = f - (nb + site);
      float d = length(r);
      if (d < minD) {
        minD = d;
        minR = r;
      }
    }
  }
  return vec3(minD, minR);
}

// Micro-bubble sparkle at very small scale — returns highlight intensity only
float microBubble(vec2 uv, float scale, float speed, float seed) {
  vec2 dv = vec2(
    sin(uTime * speed * 0.4 + seed + uv.y * 4.0) * 0.010,
    -uTime * speed * 0.025
  );
  vec3 data = voronoiData((uv + dv) * scale);
  float d = data.x;
  vec2 r = data.yz;
  float rimR = 0.28;
  // Only highlights — rims are sub-pixel at this scale
  float inside = step(d, rimR);
  vec2 rn = r / (d + 0.001);
  float hlDir = clamp(-rn.x * 0.50 - rn.y * 0.85, 0.0, 1.0);
  float hlR   = smoothstep(rimR * 0.90, rimR * 0.20, d);
  return hlDir * hlDir * hlR * inside;
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;

  // --- Liquid flow: slow domain-warped fbm (thick liquid internal movement) ---
  vec2 t = vec2(uTime * 0.060, uTime * 0.045);
  vec2 q = vec2(
    fbm3(uv * 2.2 + t),
    fbm3(uv * 2.2 + t + vec2(5.2, 1.3))
  );
  float flow = fbm3(uv * 2.8 + 1.8 * q + t * 0.4);
  // Flow creates subtle bright/dark streaks (thick liquid internal pattern)
  float flowMod = (flow - 0.5) * 0.14; // ±0.07 luminance variation

  // --- SSS: bright glow from inside center (deep chewy slime feel) ---
  float dist = length(uv - 0.5) * 2.0;
  float sss = smoothstep(0.88, 0.0, dist);

  // Vivid lime-green base
  vec3 baseGreen = mix(uBase.rgb, vec3(0.52, 0.92, 0.12), 0.42);
  // Apply liquid flow (darker/lighter streaks)
  vec3 liquidColor = baseGreen * (1.0 + flowMod);
  // SSS: center illuminates brighter towards mint
  vec3 color = mix(liquidColor, uGlow.rgb * 1.32, sss * 0.45);

  // --- Micro-bubble sparkle (scale 22): ~1px dots, barely visible as bubbles ---
  float hl1 = microBubble(uv, 22.0, 0.06, 0.0);

  // --- Ultra-fine sparkle (scale 30): sub-pixel glistening ---
  float hl2 = microBubble(uv, 30.0, 0.09, 4.7);

  // Apply sparkle highlights (bright white micro-glistening)
  float hlMix = clamp(hl1 * 0.88 + hl2 * 0.72, 0.0, 1.0);
  color = mix(color, vec3(1.0, 1.0, 0.97), hlMix);

  // --- Surface sheen: one soft gloss highlight (mochi/gel surface) ---
  float sheenDist = length(uv - vec2(0.27, 0.21));
  float sheen = smoothstep(0.38, 0.0, sheenDist) * 0.16;
  color += vec3(sheen);

  color = clamp(color, 0.0, 1.0);

  float alpha = 0.93 * uOpacity;
  fragColor = vec4(color, alpha);
}
