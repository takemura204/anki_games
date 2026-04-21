#version 460 core
#include <flutter/runtime_effect.glsl>

// Wireframe: SDF-based neon border glow + animated pulse + chromatic aberration
// Analytical edge glow (no blur pass)

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;     // neon color (onSurface)
uniform vec4 uGlow;     // secondary neon / glow
uniform float uOpacity;

out vec4 fragColor;

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;

  // --- Box SDF: negative inside, positive outside ---
  vec2 d = abs(uv - 0.5) - 0.45;
  float sdf = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);

  // --- Animated neon pulse ---
  float pulse = 0.72 + 0.28 * sin(uTime * 2.8);

  // --- Exponential glow falloff (neon tube look) ---
  float glowBase = exp(-abs(sdf) * 22.0) * pulse;

  // --- Chromatic aberration: RGB channels at slightly different SDF thresholds ---
  float glowR = exp(-abs(sdf + 0.018) * 22.0) * pulse;
  float glowG = glowBase;
  float glowB = exp(-abs(sdf - 0.018) * 22.0) * pulse;

  // --- Very thin semi-transparent fill ---
  float fill = step(sdf, 0.0) * 0.06;

  // --- Horizontal scanline flicker ---
  float scanline = 0.96 + 0.04 * sin(uv.y * uSize.y * 2.2 - uTime * 6.0);

  // --- Color assembly ---
  vec3 neon = vec3(
    uBase.r * glowR + fill * uBase.r,
    uBase.g * glowG + fill * uBase.g,
    uBase.b * glowB + fill * uBase.b
  );

  float alpha = glowBase * scanline * uOpacity;
  fragColor = vec4(neon, alpha);
}
