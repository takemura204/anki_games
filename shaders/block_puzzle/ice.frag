#version 460 core
#include <flutter/runtime_effect.glsl>

// Liquid Ice ASMR: caustic light webs + swaying domain-warped normals
// Like looking through moving glacier water — flowing refracted light patterns
// with slow-swaying surface normals and glass-block edge glare

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;   // blue-grey #607D8B
uniform vec4 uGlow;   // light cyan #B2EBF2
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

float fbm3(vec2 p) {
  float h = 0.0, a = 0.5;
  for (int i = 0; i < 3; i++) {
    h += a * vnoise(p);
    p = p * 2.0 + vec2(1.7, 9.2);
    a *= 0.50;
  }
  return h;
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;

  // Moderate drift — liquid, not static like glass
  vec2 drift = vec2(uTime * 0.035, uTime * 0.022);

  // --- Swaying domain warp: slow sinusoidal sway layered on fbm drift ---
  vec2 sway = vec2(
    sin(uTime * 0.42 + uv.y * 4.1) * 0.028,
    cos(uTime * 0.35 + uv.x * 3.7) * 0.020
  );

  vec2 q = vec2(
    fbm3(uv * 2.1 + drift + sway),
    fbm3(uv * 2.1 + drift + sway + vec2(5.1, 1.7))
  );

  // --- Height field for surface normals (swaying liquid surface) ---
  float eps = 0.012;
  vec2 wp = uv * 2.5 + 2.2 * q + drift * 0.8;
  float hC = fbm3(wp);
  float hR = fbm3(wp + vec2(eps * 1.8, 0.0));
  float hU = fbm3(wp + vec2(0.0, eps * 1.8));

  // Surface normal from height differential (amplified for strong reflection)
  float nx = (hC - hR) * 6.5;
  float ny = (hC - hU) * 6.5;
  vec3 normal = normalize(vec3(nx, ny, 0.055));

  // --- Lighting: specular from main + fill light ---
  vec3 lightDir = normalize(vec3(-0.55, -0.65, 1.0));
  float ndotl = max(0.0, dot(normal, lightDir));
  float spec = pow(ndotl, 28.0) * 1.4;

  vec3 fillDir = normalize(vec3(0.4, -0.3, 1.0));
  float fillLight = max(0.0, dot(normal, fillDir)) * 0.25;

  // --- Caustic light: flowing interference pattern (refracted light webs) ---
  // Domain-warp the caustic UV with q for organic feel
  vec2 cauUV = uv * 4.2 + q * 1.0 + drift * 1.6;
  // Add secondary time offset so caustics flow independently of normals
  float wave = fbm3(cauUV + vec2(uTime * 0.060, uTime * 0.048));
  // cos pattern: bright bands where wave is near integer multiples
  // pow sharpens bright spots into caustic-like web intersections
  float caustic = pow(abs(cos(wave * 3.14159 * 3.2)), 6.0);

  // Fade caustic toward edges (caustics are interior phenomena)
  float edgeX = min(uv.x, 1.0 - uv.x);
  float edgeY = min(uv.y, 1.0 - uv.y);
  float edgeDist = min(edgeX, edgeY);
  float innerMask = smoothstep(0.0, 0.16, edgeDist);
  caustic *= innerMask;

  // --- Strong Fresnel edge glow (glass block feature) ---
  float edgeGlow = 1.0 - smoothstep(0.0, 0.13, edgeDist);
  edgeGlow = edgeGlow * edgeGlow * 1.3;

  // Corner accents
  float cornerTL = smoothstep(0.20, 0.0, length(uv - vec2(0.0, 0.0))) * 1.2;
  float cornerTR = smoothstep(0.12, 0.0, length(uv - vec2(1.0, 0.0))) * 0.7;

  // --- Color ---
  vec3 glassCool   = mix(uBase.rgb, vec3(0.78, 0.84, 0.88), 0.62);
  vec3 glassBright = mix(uGlow.rgb, vec3(0.92, 0.96, 1.00), 0.55);

  // Interior: sweeping reflection zones from swaying normal
  float reflBright = ndotl * 0.65 + fillLight + hC * 0.12;
  vec3 reflected = mix(glassCool * 0.60, glassBright, reflBright);

  // Caustic adds warm bright flare on top of reflections
  vec3 causticColor = mix(glassBright, vec3(1.0, 1.0, 0.95), 0.65);
  vec3 color = mix(reflected, causticColor, caustic * 0.58);

  // Sharp specular highlight
  color += vec3(spec);

  // Edge glow: bright white at glass perimeter
  color = mix(color, vec3(1.0), clamp(edgeGlow * 0.88, 0.0, 1.0));

  // Corner highlights
  color = mix(color, vec3(1.0), clamp(cornerTL * 0.92, 0.0, 1.0));
  color = mix(color, vec3(1.0), clamp(cornerTR * 0.72, 0.0, 1.0));

  // Subtle overall glass tint
  color = mix(color, glassCool, 0.10);

  color = clamp(color, 0.0, 1.0);

  // Alpha: caustic bright spots slightly increase apparent opacity
  float alpha = uOpacity * (0.72 + spec * 0.18 + edgeGlow * 0.10 + caustic * 0.08);
  alpha = clamp(alpha, 0.0, 1.0);

  fragColor = vec4(color, alpha);
}
