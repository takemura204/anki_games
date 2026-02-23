#version 460 core
#include <flutter/runtime_effect.glsl>

// Glassmorphism: Fresnel edge glow + animated diagonal shimmer
// Replaces expensive MaskFilter.blur with analytical GPU glow

uniform vec2 uSize;     // [0,1]  cell dimensions
uniform vec2 uOrigin;   // [2,3]  cell top-left in canvas coords
uniform float uTime;    // [4]    animation time in seconds
uniform vec4 uBase;     // [5-8]  onSurface color
uniform vec4 uGlow;     // [9-12] glowColor
uniform float uOpacity; // [13]   overall opacity

out vec4 fragColor;

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;

  // --- Fresnel-like edge glow (replaces MaskFilter.blur) ---
  float edgeX = min(uv.x, 1.0 - uv.x);
  float edgeY = min(uv.y, 1.0 - uv.y);
  float edge = min(edgeX, edgeY);
  float rimGlow = 1.0 - smoothstep(0.0, 0.18, edge);

  // --- Animated diagonal shimmer (slowly drifts top-left → bottom-right) ---
  float speed = 0.25;
  float diag = uv.x * 0.6 + uv.y * 0.4;
  float phase = fract(diag - uTime * speed + 0.5) - 0.5;
  float shimmer = smoothstep(0.12, 0.0, abs(phase)) * 0.45;

  // --- Top-left specular highlight (static) ---
  float specDist = length(uv - vec2(0.28, 0.22));
  float spec = smoothstep(0.32, 0.0, specDist) * 0.55;

  // --- Compose layers ---
  // Base: semi-transparent glass
  vec4 base = vec4(uBase.rgb, uBase.a * 0.32 * uOpacity);
  // Rim glow from glowColor
  vec4 rim = vec4(uGlow.rgb, uGlow.a * rimGlow * 0.38 * uOpacity);
  // Highlights (white)
  float hlAlpha = (shimmer + spec) * uOpacity;
  vec4 highlight = vec4(1.0, 1.0, 1.0, hlAlpha);

  fragColor = base + rim + highlight;
}
