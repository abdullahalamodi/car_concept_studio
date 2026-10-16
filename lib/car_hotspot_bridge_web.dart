import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Connects slotted DOM hotspot buttons to the Flutter details sheet.
class CarHotspotBridge {
  Timer? _retry;
  StreamSubscription<web.MouseEvent>? _clicks;

  void attach(String elementId, void Function(String) onSelected) {
    dispose();
    var attempts = 0;
    void connect() {
      final viewer = web.document.querySelector('#$elementId');
      if (viewer == null) {
        if (++attempts >= 120) _retry?.cancel();
        return;
      }
      _retry?.cancel();
      _clicks = viewer.onClick.listen((event) {
        final target = event.target;
        if (target == null || !target.isA<web.Element>()) return;
        final button = (target as web.Element).closest('.part-hotspot');
        final part = button?.getAttribute('data-part');
        if (part == null) return;
        event.stopPropagation();
        viewer.removeAttribute('auto-rotate');
        onSelected(part);
      });
    }

    _retry = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => connect(),
    );
    connect();
  }

  void dispose() {
    _retry?.cancel();
    _retry = null;
    unawaited(_clicks?.cancel());
    _clicks = null;
  }
}
