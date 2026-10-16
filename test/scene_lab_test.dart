/// Unit tests for the Scene Lab's pure logic: math helpers, paint specs, and
/// preset data invariants. These run without a rendering context.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:car_concept_studio/scene_lab/scene_lab_math.dart';
import 'package:car_concept_studio/scene_lab/scene_lab_presets.dart';

void main() {
  group('angle math', () {
    test('wrapPi folds angles into (-pi, pi]', () {
      expect(wrapPi(0), 0);
      expect(wrapPi(0.5), closeTo(0.5, 1e-12));
      expect(wrapPi(math.pi), closeTo(math.pi, 1e-12));
      expect(wrapPi(-math.pi), closeTo(math.pi, 1e-12));
      expect(wrapPi(math.pi * 3), closeTo(math.pi, 1e-12));
      expect(wrapPi(2.5 * tau + 0.5), closeTo(.5 - math.pi, 1e-9));
      expect(wrapPi(3 * tau + 0.5), closeTo(0.5, 1e-9));
      expect(wrapPi(-2.5 * tau - 0.5), closeTo(math.pi - .5, 1e-9));
    });

    test('shortestTurn picks the short way around the circle', () {
      expect(shortestTurn(0.1, 0.2), closeTo(0.1, 1e-12));
      // A +5.7 rad turn equals the short way back (-0.58 rad).
      expect(shortestTurn(0.1, 0.1 + 5.7), closeTo(5.7 - tau, 1e-9));
      expect(shortestTurn(-3.0, 3.0), closeTo(6 - tau, 1e-9));
    });

    test('smoothstep01 clamps and stays monotonic', () {
      expect(smoothstep01(-1), 0);
      expect(smoothstep01(0), 0);
      expect(smoothstep01(1), 1);
      expect(smoothstep01(2), 1);
      expect(smoothstep01(0.5), closeTo(0.5, 1e-12));
      expect(smoothstep01(0.25), closeTo(0.15625, 1e-12));
      expect(smoothstep01(0.3), lessThan(smoothstep01(0.6)));
    });

    test('settleResponse is frame-rate independent', () {
      expect(settleResponse(0, 1 / 60), 1);
      final r = settleResponse(0.55, 1 / 60);
      expect(r, greaterThan(0));
      expect(r, lessThan(1));
      // Splitting a frame into two halves must settle the same amount.
      final a = settleResponse(0.55, 0.01);
      final b = settleResponse(0.55, 0.02);
      final whole = settleResponse(0.55, 0.03);
      expect(a + b - a * b, closeTo(whole, 1e-9));
    });
  });

  group('color math', () {
    test('srgbToLinear and linearToSrgb round-trip', () {
      expect(srgbToLinear(0), 0);
      expect(srgbToLinear(1), closeTo(1, 1e-12));
      expect(srgbToLinear(0.5), closeTo(0.21404, 1e-4));
      for (final v in [0.0, 0.04045, 0.2, 0.5, 0.75, 1.0]) {
        expect(linearToSrgb(srgbToLinear(v)), closeTo(v, 1e-6));
      }
    });

    test('hsvToLinearRgb produces linear primaries without sRGB encoding', () {
      final red = hsvToLinearRgb(0, 1, 1);
      expect(red.x, 1);
      expect(red.y, 0);
      expect(red.z, 0);

      final green = hsvToLinearRgb(1 / 3, 1, 1);
      expect(green.x, 0);
      expect(green.y, 1);
      expect(green.z, 0);

      final blue = hsvToLinearRgb(2 / 3, 1, 1);
      expect(blue.x, 0);
      expect(blue.y, 0);
      expect(blue.z, 1);

      final grey = hsvToLinearRgb(0.4, 0, 0.5);
      expect(grey.x, 0.5);
      expect(grey.y, 0.5);
      expect(grey.z, 0.5);
    });

    test('rotateHue keeps the color and alpha for a full turn', () {
      final original = linearRgba(const Color(0xffc8202e));
      final same = rotateHue(original, 0);
      expect(same.x, closeTo(original.x, 1e-6));
      expect(same.y, closeTo(original.y, 1e-6));
      expect(same.z, closeTo(original.z, 1e-6));
      expect(same.w, original.w);

      final full = rotateHue(original, 1);
      expect(full.x, closeTo(original.x, 1e-6));
      expect(full.y, closeTo(original.y, 1e-6));
      expect(full.z, closeTo(original.z, 1e-6));
    });

    test('rotateHue turns red into green a third of the way around', () {
      final red = linearRgba(const Color(0xffff0000));
      final green = rotateHue(red, 1 / 3);
      expect(green.x, closeTo(0, 1e-4));
      expect(green.y, closeTo(1, 1e-4));
      expect(green.z, closeTo(0, 1e-4));
    });

    test('linearRgb / colorOfLinear round-trip sRGB bytes', () {
      for (final argb in [0xff000000, 0xffffffff, 0xffc8202e, 0xff1e6fe8]) {
        final color = Color(argb);
        expect(colorOfLinear(linearRgb(color)), color);
      }
      expect(hexOfLinearRgb(vm.Vector3(0, 0, 0)), '#000000');
      expect(hexOfLinearRgb(vm.Vector3(1, 1, 1)), '#FFFFFF');
      expect(hexOfLinearRgb(linearRgb(const Color(0xffc8202e))), '#C8202E');
    });
  });

  group('paint specs', () {
    test('finish() always produces an opaque paint', () {
      // Regression: a bare Color(0xRRGGBB) reads as alpha 0, which would
      // write a fully transparent baseColorFactor into the material.
      expect(finish(0xc8202e).color.w, 1);
      expect(finish(0xffffffff).color.w, 1);
      expect(colorOfLinearRgba(finish(0xc8202e).color), const Color(0xffc8202e));
    });

    test('matches() treats null parameters as wildcards', () {
      final base = finish(0x8040c0, metallic: 0.9, roughness: 0.2);
      final wildcard = finish(0x8040c0);
      expect(base.matches(wildcard), isTrue);
      expect(wildcard.matches(base), isTrue);
      expect(base.matches(base), isTrue);

      final tuned = finish(0x8040c0, metallic: 0.4, roughness: 0.2);
      expect(base.matches(tuned), isFalse);

      // A one-bit difference in linear space sits inside the default
      // epsilon, and outside an explicitly tighter one.
      final near1 = PaintSpec(
        vm.Vector4(.5, .5, .5, 1),
        metallic: .9,
        roughness: .2,
      );
      final near2 = PaintSpec(
        vm.Vector4(.501, .5, .5, 1),
        metallic: .9,
        roughness: .2,
      );
      expect(near1.matches(near2), isTrue);
      expect(near1.matches(near2, 5e-4), isFalse);
    });

    test('sameSpecsAs() compares per-material breakdowns index-wise', () {
      final a = PaintSwatch('a', finish(0x101010, metallic: 1));
      final b = PaintSwatch('b', finish(0x101010, metallic: 1));
      expect(a.sameSpecsAs(b), isTrue);

      final c = PaintSwatch('c', finish(0x202020, metallic: 1));
      expect(a.sameSpecsAs(c), isFalse);

      final split = PaintSwatch('d', finish(0x101010, metallic: 1), perMaterial: [
        finish(0x101010, metallic: 1),
        finish(0x303030, metallic: 1),
      ]);
      expect(a.sameSpecsAs(split), isFalse);
      expect(split.sameSpecsAs(split), isTrue);
      expect(split.sameSpecsAs(PaintSwatch('e', finish(0x999999), perMaterial: [
        finish(0x101010, metallic: 1),
        finish(0x303030, metallic: 1),
      ])), isTrue);
    });

    test('hueShifted keeps parameters and alpha while moving the hue', () {
      final spec = finish(0xff0000, metallic: 0.8, roughness: 0.3);
      final shifted = spec.hueShifted(1 / 3);
      expect(shifted.metallic, 0.8);
      expect(shifted.roughness, 0.3);
      expect(shifted.color.w, 1);
      expect(shifted.color.y, greaterThan(shifted.color.x));
      expect(shifted.color.y, greaterThan(shifted.color.z));
    });
  });

  group('zone + palette data', () {
    test('ofMaterial maps glTF material names onto paint zones', () {
      expect(PaintZone.ofMaterial('Paint 1'), PaintZone.body);
      expect(PaintZone.ofMaterial('Paint 1 - Copy'), PaintZone.body);
      expect(PaintZone.ofMaterial('Paint 2'), PaintZone.accents);
      expect(PaintZone.ofMaterial('Interior 3'), PaintZone.interior);
      expect(PaintZone.ofMaterial('Rim1 (Front)'), PaintZone.rims);
      expect(PaintZone.ofMaterial('Rim2'), PaintZone.rims);
      expect(PaintZone.ofMaterial('BodyUnderside'), isNull);
      expect(PaintZone.ofMaterial('Headlight'), isNull);
    });

    test('every zone palette is stocked and opaque', () {
      for (final zone in PaintZone.values) {
        final palette = paletteFor(zone);
        expect(palette.length, greaterThanOrEqualTo(6), reason: zone.label);
        for (final swatch in palette) {
          expect(swatch.name, isNotEmpty);
          expect(swatch.spec.color.w, 1, reason: '${zone.label} ${swatch.name}');
        }
      }
    });

    test('schemes dress every zone and only use palette swatches', () {
      expect(schemes.length, greaterThanOrEqualTo(4));
      expect(schemes.map((scheme) => scheme.name).toSet(), hasLength(schemes.length));
      for (final scheme in schemes) {
        for (final zone in PaintZone.values) {
          final swatch = scheme.swatch(zone);
          expect(paletteFor(zone).contains(swatch), isTrue, reason: scheme.name);
        }
      }
    });

    test('authored finishes mirror the glTF variant names', () {
      expect(authoredFinishes.map((swatch) => swatch.name), <String>[
        'Carmine Candy',
        'Pearly Swirly',
        'Torched Graphite',
      ]);
      expect(authoredFinishes[1].spec.iridescence, isNotNull);
    });
  });

  group('looks + shots data', () {
    test('looks are tame, positive, and distinctly named', () {
      expect(looks.map((look) => look.name), <String>[
        'Showcase',
        'Cinematic',
        'Neon',
        'Clean',
      ]);
      for (final look in looks) {
        expect(look.exposure, greaterThan(0));
        expect(look.bloom, inInclusiveRange(0, 1));
        expect(look.vignette, inInclusiveRange(0, 1));
        expect(look.keyIntensity, greaterThan(0));
        expect(look.rimIntensity, greaterThan(0));
        expect(look.underGlow, greaterThan(0));
        for (final sky in [
          look.skyZenith,
          look.skyHorizon,
          look.skyGround,
          look.skySun,
        ]) {
          expect(sky.x, greaterThan(0));
          expect(sky.y, greaterThan(0));
          expect(sky.z, greaterThan(0));
        }
      }
    });

    test('camera shots are well formed and aim at real parts', () {
      expect(cameraShots.length, greaterThanOrEqualTo(5));
      for (final shot in cameraShots) {
        expect(shot.yawDegrees.abs(), lessThanOrEqualTo(360));
        expect(shot.polar, greaterThan(0));
        expect(shot.polar, lessThanOrEqualTo(math.pi / 2));
        expect(shot.distance, greaterThan(0));
        expect(shot.fovDegrees, inExclusiveRange(10, 90));
      }
      final wheel = cameraShots.firstWhere((shot) => shot.name == 'Wheel');
      expect(wheel.target, ShotTarget.frontWheel);
      final cabin = cameraShots.firstWhere((shot) => shot.name == 'Cabin');
      expect(cabin.target, ShotTarget.cabin);
    });

    test('motion constants match the source model', () {
      expect(wheelRadiusMeters, closeTo(0.361, 1e-9));
      expect(maxWheelRpm, greaterThan(0));
      // 640 rpm on a 0.361 m tire is roughly 87 km/h.
      final kmh = maxWheelRpm / 60 * tau * wheelRadiusMeters * 3.6;
      expect(kmh, inInclusiveRange(80, 95));
    });
  });
}
