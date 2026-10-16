/// The live viewer half of the Scene Lab demo.
///
/// Shows the flutter_scene canvas with its HUD on top: the current look, the
/// live speed/fps readout, and the showreel badge. Widgets above the canvas
/// never block input, so dragging always reaches the camera controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import 'scene_lab_controller.dart';

/// Renders [controller]'s scene with the lab's loading, error, and HUD states.
class SceneLabView extends StatefulWidget {
  const SceneLabView({super.key, required this.controller});

  final SceneLabController controller;

  @override
  State<SceneLabView> createState() => _SceneLabViewState();
}

class _SceneLabViewState extends State<SceneLabView> {
  SceneLabController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 620,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xff13171c),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xff252b33)),
    ),
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.error != null) {
          return _statusPanel(error: controller.error);
        }
        if (!controller.ready) {
          return _statusPanel(
            title: 'Spinning up flutter_scene',
            message:
                'Compiling the physical-material shaders and decoding the '
                'car. The first run takes a moment.',
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: CameraControls(
                controller: controller.orbit,
                child: SceneView(
                  controller.scene,
                  onTick: controller.tick,
                  warmUp: true,
                  loadingBuilder: (context, _) =>
                      _statusPanel(title: 'Warming up shaders'),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(child: _Hud(controller: controller)),
            ),
          ],
        );
      },
    ),
  );

  Widget _statusPanel({Object? error, String? title, String? message}) {
    return Container(
      color: const Color(0xff0e1114),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error == null)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xffd8ff4f),
                  ),
                )
              else
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xffffb454),
                  size: 30,
                ),
              const SizedBox(height: 16),
              Text(
                title ?? 'flutter_scene could not start',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? message ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xff87909d),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: controller.retry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xffd8ff4f),
                    side: const BorderSide(color: Color(0xff303741)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The heads-up display drawn over the canvas.
class _Hud extends StatelessWidget {
  const _Hud({required this.controller});

  final SceneLabController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pill('FLUTTER SCENE'),
            const SizedBox(width: 8),
            _pill('LOOK · ${controller.look.name.toUpperCase()}'),
            const Spacer(),
            if (controller.showreelOn)
              _pill(
                '● REEL · ${controller.reelStepName.toUpperCase()}',
                accent: const Color(0xffd8ff4f),
              )
            else
              _pill('${controller.fps.round()} FPS'),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill(
                  '${controller.speedKmh.round()} KM/H  ·  '
                  '${controller.wheelRpm.round()} RPM',
                ),
                if (controller.brakeOn) ...[
                  const SizedBox(height: 6),
                  _pill('BRAKE', accent: const Color(0xffff5f5f)),
                ],
              ],
            ),
            const Spacer(),
            Text(
              'Drag to orbit  ·  Scroll to zoom  ·  Right-drag to pan',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: .5),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _pill(String text, {Color accent = const Color(0xffdce2e9)}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xcc11151a),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: .35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
