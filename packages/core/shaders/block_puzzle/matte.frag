#version 460 core
#include <flutter/runtime_effect.glsl>

// Soap Cut ASMR: matte chunky Voronoi + directional bevel + soft Lambertian diffuse
// Matte artisan soap cross-section — large chunks with directional bevel and boundary
// shadows for soap-cut depth, zero specular, pure Lambertian light, and organic rim glow

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;     // cyan #4DD0E1
uniform vec4 uGlow;     // light cyan #80DEEA
uniform float uOpacity;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
  p = fract(p * vec2(0.1031, 0.1030));
  p += dot(p, p.yx + 33.33);
  return fract((p.x + p.y) * p);
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

float fbm2(vec2 p) {
  float h = 0.0, a = 0.55;
  for (int i = 0; i < 2; i++) {
    h += a * vnoise(p);
    p = p * 2.4 + vec2(3.1, 7.4);
    a *= 0.45;
  }
  return h;
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;
  vec2 px = FlutterFragCoord().xy;

  // --- Single cyan base color ---
  vec3 baseColor = mix(uBase.rgb, uGlow.rgb, 0.15);

  // --- Chunky Voronoi (scale 6: ~10-16px per chunk — soap cut cross-section) ---
  vec2 cvUV = uv * 6.0 + vec2(1.3, 4.7);
  vec2 cvI  = floor(cvUV);
  vec2 cvF  = fract(cvUV);

  float minD  = 8.0;
  vec2  minR  = vec2(0.0);
  vec2  minId = vec2(0.0);
  for (int dy = -1; dy <= 1; dy++) {
    for (int dx = -1; dx <= 1; dx++) {
      vec2 nb   = vec2(float(dx), float(dy));
      vec2 site = hash2(cvI + nb) * 0.70 + 0.15;
      vec2 r    = cvF - (nb + site);
      float d   = length(r);
      if (d < minD) { minD = d; minR = r; minId = cvI + nb; }
    }
  }

  // Per-chunk tone (each soap chunk has slightly different surface density)
  float cellTone = (hash(minId) - 0.5) * 0.07;

  // Directional bevel per chunk (upper-left face catches light — no specular, pure Lambert)
  vec2 lightDir2D = normalize(vec2(-0.65, -0.70));
  float particleLight = max(
    0.0,
    dot(normalize(minR + vec2(0.0001)), lightDir2D)
  );
  float particleBevel = particleLight * 0.06;

  // Boundary shadow groove (matte soap cut fracture lines — moderate depth)
  float gapDark = smoothstep(0.10, 0.24, minD) * 0.13;

  // Subtle bright ridge at chunk boundary (compressed soap edge, no shiny glare)
  float edgeRing = smoothstep(0.09, 0.14, minD)
                 * (1.0 - smoothstep(0.14, 0.24, minD))
                 * 0.05;

  float chunkMod = cellTone + particleBevel - gapDark + edgeRing;

  // Fine surface micro-noise (matte soap micro-texture)
  float microGrain = (hash(floor(px)) - 0.5) * 0.050;
  float fineGrain  = (fbm2(px * 0.20 + vec2(0.5, 0.5)) - 0.5) * 0.045;

  // --- Soft ambient gradient (replaces hard bevel — top-left lighter) ---
  float ambientLight = 0.90 + 0.10 * (1.0 - uv.x * 0.30 - uv.y * 0.20);

  vec3 color = baseColor * ambientLight;
  color += vec3(chunkMod + microGrain + fineGrain);

  // --- Completely matte: Lambertian diffuse only, zero specular ---
  // High z=0.82 keeps surface gently bumpy without any specular hotspot
  vec2 nT  = vec2(uTime * 0.012, uTime * 0.008);
  vec2 nUV = uv * 3.5;
  float eps = 0.025;
  float hC = fbm2(nUV + nT);
  float hR = fbm2(nUV + vec2(eps * 3.5, 0.0) + nT);
  float hU = fbm2(nUV + vec2(0.0, eps * 3.5) + nT);
  float dnx = (hC - hR) * 2.5;
  float dny = (hC - hU) * 2.5;
  vec3 surfNorm = normalize(vec3(dnx, dny, 0.82));

  vec3 lightDir3D = normalize(vec3(-0.60, -0.70, 1.0));
  float ndotl     = max(0.0, dot(surfNorm, lightDir3D));

  // Pure Lambertian — matte soap absorbs all direct light, no reflection
  float diffuse = 0.86 + ndotl * 0.14;
  color *= diffuse;

  // Faint mica shimmer (artisan soap flecks catching ambient light — barely visible)
  float shimmerVal = fbm2(uv * 5.5 + vec2(uTime * 0.070, uTime * 0.050));
  float shimmer    = pow(max(0.0, shimmerVal - 0.48), 2.4) * 0.09;
  color += vec3(shimmer);

  // --- Organic FBM-warped edge rim (soft clay-like perimeter of cut soap bar) ---
  float edgeX    = min(uv.x, 1.0 - uv.x);
  float edgeY    = min(uv.y, 1.0 - uv.y);
  float edgeDist = min(edgeX, edgeY);
  float edgeWarpN = fbm2(uv * 5.0 + vec2(3.1, 1.9)) * 0.030;
  float organicEdge = smoothstep(0.14 + edgeWarpN, 0.0, edgeDist) * 0.22;
  vec3 edgeCol = mix(uGlow.rgb * 1.15, vec3(0.92, 0.98, 1.0), 0.52);
  color = mix(color, edgeCol, organicEdge);

  color = clamp(color, 0.0, 1.0);
  fragColor = vec4(color, uOpacity);
}
