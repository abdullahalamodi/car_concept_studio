import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'car_lighting_contract.dart';

int _requestId = 0;

void syncCarHeadlights(String elementId, {required bool on}) {
  final requestId = ++_requestId;
  unawaited(_applyHeadlights(elementId, on, requestId));
}

Future<void> _applyHeadlights(String elementId, bool on, int requestId) async {
  for (var attempt = 0; attempt < 120; attempt++) {
    if (requestId != _requestId) return;

    final viewer = web.document.querySelector('#$elementId');
    if (viewer != null) {
      final jsViewer = viewer as JSObject;
      final model = jsViewer.getProperty<JSObject?>('model'.toJS);
      if (model != null) {
        try {
          final rawMaterial = model.callMethodVarArgs<JSAny?>(
            'getMaterialByName'.toJS,
            <JSAny?>[headlightMaterialName.toJS],
          );
          if (rawMaterial != null && rawMaterial.isA<JSObject>()) {
            final material = rawMaterial as JSObject;
            material.callMethodVarArgs<JSAny?>(
              'setEmissiveFactor'.toJS,
              <JSAny?>[(on ? '#ffffff' : '#000000').toJS],
            );
            material
                .callMethodVarArgs<JSAny?>('setEmissiveStrength'.toJS, <JSAny?>[
                  (on
                          ? headlightsOnEmissiveStrength
                          : headlightsOffEmissiveStrength)
                      .toJS,
                ]);
            return;
          }
        } catch (_) {
          // The material may still be lazy-loading. Retry on the next pass.
        }
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
