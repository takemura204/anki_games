#version 460 core
#include <flutter/runtime_effect.glsl>

// Bubble Wrap ASMR: realistic spherical depth + Phong lighting + thin-film iridescence
// Vinyl plastic bubble: proper 3D sphere illusion with satisfying depth

uniform vec2 uSize;
uniform vec2 uOrigin;
uniform float uTime;
uniform vec4 uBase;
uniform vec4 uGlow;
uniform float uOpacity;

out vec4 fragColor;

vec3 hue2rgb(float h) {
  float r = abs(h * 6.0 - 3.0) - 1.0;
  float g = 2.0 - abs(h * 6.0 - 2.0);
  float b = 2.0 - abs(h * 6.0 - 4.0);
  return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;
  vec2 centered = uv - 0.5;

  // --- Circular bubble mask ---
  float r = length(centered) * 2.0;
  float circleMask = 1.0 - smoothstep(0.80, 0.96, r);
  if (circleMask <= 0.001) {
    fragColor = vec4(0.0);
    return;
  }

  // --- Sphere surface normal (proper 3D sphere illusion) ---
  float sphereZ = sqrt(max(0.0, 1.0 - r * r * 0.85));
  vec3 normal = normalize(vec3(centered * 2.0, sphereZ));

  // --- Animated Phong lighting ---
  float lightAngle = uTime * 0.32;
  vec3 lightDir = normalize(vec3(
    0.55 + 0.25 * cos(lightAngle),
    -0.65 + 0.15 * sin(lightAngle),
    0.90
  ));

  vec3 viewDir = vec3(0.0, 0.0, 1.0);
  float diffuse = max(0.0, dot(normal, lightDir));

  // Specular: sharp lobe (plastic vinyl surface)
  vec3 reflectDir = reflect(-lightDir, normal);
  float spec = pow(max(0.0, dot(reflectDir, viewDir)), 32.0) * 0.82;

  // --- Fresnel: edge brightening (thin-film effect) ---
  float fresnel = 1.0 - max(0.0, dot(normal, viewDir));
  fresnel = pow(fresnel, 2.2);

  // --- Thin-film iridescence (rainbow at Fresnel edges) ---
  float hue = fract(atan(centered.y, centered.x) / 6.28318 + uTime * 0.065);
  vec3 rainbow = hue2rgb(hue);
  float iridStrength = fresnel * 0.58;

  // --- Base translucent color with sphere depth shading ---
  vec3 deepColor = uBase.rgb * (0.38 + diffuse * 0.48);
  vec3 color = mix(deepColor, rainbow, iridStrength);

  // Sharp specular (the satisfying bright "pop" highlight)
  color += vec3(spec);

  // Subtle center darkening (sphere depth illusion - convex center looks thicker)
  float centerDark = (1.0 - smoothstep(0.0, 0.28, r)) * 0.08;
  color -= vec3(centerDark);

  // Rim glow from glowColor
  color += uGlow.rgb * fresnel * 0.18;

  color = clamp(color, 0.0, 1.0);

  // --- Alpha: translucent plastic with Fresnel opacity boost at edges ---
  float alpha = uBase.a * (0.52 + fresnel * 0.22 + spec * 0.28) * circleMask * uOpacity;
  alpha = clamp(alpha, 0.0, 1.0);

  fragColor = vec4(color, alpha);
}
