/// Pure math helpers for the Scene Lab demo.
///
/// This file stays free of Flutter and flutter_scene types where practical so
/// the color and angle logic can be unit tested without a rendering context.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:vector_math/vector_math.dart' as vm;

const double tau = 2 * math.pi;

/// Wraps [angle] (radians) into `(-pi, pi]`.
double wrapPi(double angle) {
  var a = angle % tau;
  if (a <= -math.pi) {
    a += tau;
  } else if (a > math.pi) {
    a -= tau;
  }
  return a;
}

/// The shortest signed rotation that takes [from] to [to], in `(-pi, pi]`.
double shortestTurn(double from, double to) => wrapPi(to - from);

/// The classic smoothstep on the clamped unit interval.
double smoothstep01(double t) {
  final x = t.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// Fraction of a remaining offset to consume this frame for a frame-rate
/// independent exponential settle, matching the engine's camera controllers.
double settleResponse(double smoothingSeconds, double deltaSeconds) {
  if (smoothingSeconds <= 0) return 1;
  return 1 - math.exp(-4.605170185988091 * deltaSeconds / smoothingSeconds);
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// sRGB transfer function, decoding to linear light.
double srgbToLinear(double c) {
  if (c <= 0.04045) return c / 12.92;
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// Inverse of [srgbToLinear].
double linearToSrgb(double c) {
  if (c <= 0.0031308) return c * 12.92;
  return 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;
}

/// Linear RGB for an HSV triple ([hue] in turns).
///
/// Lights read color in linear space, so unlike [rotateHue] this skips the
/// sRGB encode: the HSV mix is treated as the linear result directly.
vm.Vector3 hsvToLinearRgb(double hue, double saturation, double value) {
  final h = (hue % 1.0) * 6;
  final i = h.floor();
  final f = h - i;
  final p = value * (1 - saturation);
  final q = value * (1 - saturation * f);
  final t = value * (1 - saturation * (1 - f));
  return switch (i % 6) {
    0 => vm.Vector3(value, t, p),
    1 => vm.Vector3(q, value, p),
    2 => vm.Vector3(p, value, t),
    3 => vm.Vector3(p, q, value),
    4 => vm.Vector3(t, p, value),
    _ => vm.Vector3(value, p, q),
  };
}

/// Linear RGB (values above 1 allowed for HDR) from an sRGB [Color].
vm.Vector3 linearRgb(Color color) => vm.Vector3(
  srgbToLinear(color.r),
  srgbToLinear(color.g),
  srgbToLinear(color.b),
);

/// Linear RGBA from an sRGB [Color].
vm.Vector4 linearRgba(Color color) => vm.Vector4(
  srgbToLinear(color.r),
  srgbToLinear(color.g),
  srgbToLinear(color.b),
  color.a,
);

/// The sRGB [Color] that displays the linear RGB triple [linear].
Color colorOfLinear(vm.Vector3 linear) => Color.fromARGB(
  255,
  (linearToSrgb(linear.x).clamp(0.0, 1.0) * 255).round(),
  (linearToSrgb(linear.y).clamp(0.0, 1.0) * 255).round(),
  (linearToSrgb(linear.z).clamp(0.0, 1.0) * 255).round(),
);

/// The display (sRGB) [Color] for a linear RGBA factor.
Color colorOfLinearRgba(vm.Vector4 linear) =>
    colorOfLinear(vm.Vector3(linear.x, linear.y, linear.z));

/// Rotates the hue of a linear RGB color by [turns] (1.0 is a full turn).
///
/// Hue is a display-space property, so the color is encoded to sRGB first,
/// rotated in HSV, and decoded back to linear light.
vm.Vector4 rotateHue(vm.Vector4 linear, double turns) {
  final r = linearToSrgb(linear.x).clamp(0.0, 1.0);
  final g = linearToSrgb(linear.y).clamp(0.0, 1.0);
  final b = linearToSrgb(linear.z).clamp(0.0, 1.0);
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  final delta = maxC - minC;

  double hue;
  if (delta == 0) {
    hue = 0;
  } else if (maxC == r) {
    hue = ((g - b) / delta) % 6;
  } else if (maxC == g) {
    hue = (b - r) / delta + 2;
  } else {
    hue = (r - g) / delta + 4;
  }
  hue = hue / 6 + turns;
  hue = hue % 1.0;
  if (hue < 0) hue += 1.0;

  final s = maxC == 0 ? 0.0 : delta / maxC;
  final v = maxC;
  final h = hue * 6;
  final i = h.floor();
  final f = h - i;
  final p = v * (1 - s);
  final q = v * (1 - s * f);
  final t = v * (1 - s * (1 - f));

  final (rr, gg, bb) = switch (i % 6) {
    0 => (v, t, p),
    1 => (q, v, p),
    2 => (p, v, t),
    3 => (p, q, v),
    4 => (t, p, v),
    _ => (v, p, q),
  };

  return vm.Vector4(srgbToLinear(rr), srgbToLinear(gg), srgbToLinear(bb), linear.w);
}

/// Formats a linear RGB color as an uppercase `#RRGGBB` string.
String hexOfLinearRgb(vm.Vector3 linear) {
  final color = colorOfLinear(linear);
  String two(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${two((color.r * 255).round())}${two((color.g * 255).round())}${two((color.b * 255).round())}'.toUpperCase();
}
