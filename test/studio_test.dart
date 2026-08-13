import 'package:flutter_test/flutter_test.dart';

import 'package:car_concept_studio/main.dart' as studio;

void main() {
  test('the uploaded CarConcept capability manifest exposes three paints', () {
    expect(studio.paints.map((paint) => paint.name), <String>[
      'Carmine Candy',
      'Pearly Swirly',
      'Torched Graphite',
    ]);
  });
}
