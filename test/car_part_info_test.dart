import 'package:car_concept_studio/car_hotspots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all info includes wheel and door details and can be closed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    const SizedBox(height: 400, child: CarPartInfo()),
              ),
              child: const Text('Show all info'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show all info'));
    await tester.pumpAndSettle();
    expect(find.text('All part information'), findsOneWidget);
    expect(find.text('Wheels & tires'), findsOneWidget);
    await tester.ensureVisible(find.text('Doors'));
    await tester.pumpAndSettle();
    expect(find.text('Doors'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byTooltip('Close details'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close details'));
    await tester.pumpAndSettle();
    expect(find.text('All part information'), findsNothing);
  });

  testWidgets('a door hotspot shows only the selected part', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CarPartInfo(part: carParts[1])),
      ),
    );
    expect(find.text('Doors'), findsOneWidget);
    expect(find.text('Wheels & tires'), findsNothing);
    expect(
      find.textContaining('no authored door-opening animation'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
