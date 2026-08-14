import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

int _requestId = 0;

void syncRefrigeratorDoors(String elementId, {required bool open}) {
  final requestId = ++_requestId;
  unawaited(_seekAndPlay(elementId, open, requestId));
}

Future<void> _seekAndPlay(String elementId, bool open, int requestId) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (requestId != _requestId) return;

    final viewer = web.document.querySelector('#$elementId');
    if (viewer != null) {
      final jsViewer = viewer as JSObject;
      final rawAnimations = jsViewer.getProperty<JSAny?>(
        'availableAnimations'.toJS,
      );
      final animations = rawAnimations == null
          ? const <JSString>[]
          : (rawAnimations as JSArray<JSString>).toDart;
      if (animations.isNotEmpty) {
        jsViewer.setProperty('animationName'.toJS, animations.first);

        final updateComplete = jsViewer
            .getProperty<JSPromise<JSAny?>>('updateComplete'.toJS)
            .toDart;
        await updateComplete;
        if (requestId != _requestId) return;

        final duration = jsViewer
            .getProperty<JSNumber>('duration'.toJS)
            .toDartDouble;
        if (duration <= 0) return;

        final midpoint = duration / 2;
        final startTime = open ? 0 : midpoint;
        final endTime = open ? midpoint : duration;

        jsViewer.callMethodVarArgs<JSAny?>('pause'.toJS, const []);
        jsViewer.setProperty('currentTime'.toJS, startTime.toJS);
        jsViewer.setProperty('timeScale'.toJS, (1).toJS);
        jsViewer.callMethodVarArgs<JSAny?>('play'.toJS, <JSAny?>[
          <String, Object>{'repetitions': 1}.jsify(),
        ]);

        // model-viewer plays a clip to its next loop boundary. Pause at the
        // midpoint ourselves so each button controls exactly one half of the
        // authored closed -> open -> closed cycle.
        for (var frame = 0; frame < 600; frame++) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
          if (requestId != _requestId) return;

          final currentTime = jsViewer
              .getProperty<JSNumber>('currentTime'.toJS)
              .toDartDouble;
          if (currentTime >= endTime) {
            jsViewer.callMethodVarArgs<JSAny?>('pause'.toJS, const []);
            jsViewer.setProperty('currentTime'.toJS, endTime.toJS);
            break;
          }
        }
        return;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
