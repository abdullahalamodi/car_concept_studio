import 'package:flutter_test/flutter_test.dart';

import 'package:car_concept_studio/main.dart' as studio;

void main() {
  test('the model manifest exposes the car and refrigerator demos', () {
    expect(studio.modelOptions.map((model) => model.name), <String>[
      'Car Concept',
      'Commercial Refrigerator',
    ]);
  });

  test('the uploaded CarConcept capability manifest exposes three paints', () {
    expect(studio.paints.map((paint) => paint.name), <String>[
      'Carmine Candy',
      'Pearly Swirly',
      'Torched Graphite',
    ]);
  });

  test('the interior preset can enter the car cabin', () {
    expect(studio.interiorCameraPreset.radius, lessThan(2));
    expect(
      studio.interiorCameraPreset.minRadius,
      lessThan(studio.interiorCameraPreset.radius),
    );
    expect(studio.interiorCameraPreset.targetHeight, closeTo(0.65, 0.001));
    expect(studio.interiorCameraPreset.cameraOrbit, contains('1.2m'));
    expect(studio.interiorCameraPreset.minCameraOrbit, contains('0.65m'));
  });

  test('the car exposes a real emissive headlight material contract', () {
    expect(studio.headlightMaterialName, 'Headlight');
    expect(studio.headlightsOnEmissiveStrength, greaterThan(0));
    expect(studio.headlightsOffEmissiveStrength, 0);
  });
}
