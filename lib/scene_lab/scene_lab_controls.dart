/// The control panel half of the Scene Lab demo.
///
/// Three tabs (PAINT, LIGHT, MOTION) send intents into the controller; every
/// value shown here is live state read back from the running scene.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene_lab_controller.dart';
import 'scene_lab_math.dart';
import 'scene_lab_presets.dart';

const _inkPanel = Color(0xff13171c);
const _inkDeep = Color(0xff0e1114);
const _inkLine = Color(0xff252b33);
const _inkMuted = Color(0xff87909d);
const _lime = Color(0xffd8ff4f);

/// The right-hand control panel for the Scene Lab module.
class SceneLabControls extends StatefulWidget {
  const SceneLabControls({super.key, required this.controller});

  final SceneLabController controller;

  @override
  State<SceneLabControls> createState() => _SceneLabControlsState();
}

class _SceneLabControlsState extends State<SceneLabControls> {
  static const _tabs = <String>['PAINT', 'LIGHT', 'MOTION'];
  int _tab = 0;

  SceneLabController get controller => widget.controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
    decoration: BoxDecoration(
      color: _inkPanel,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _inkLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Play the lab',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
            _badge('FLUTTER SCENE'),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'A retained scene with every dial live: per-part PBR paint, eased '
          'studio lights, and a choreographed showreel.',
          style: TextStyle(color: _inkMuted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 18),
        _tabBar(),
        const SizedBox(height: 18),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => switch (_tab) {
            0 => _paintTab(),
            1 => _lightTab(),
            _ => _motionTab(),
          },
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _lime,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Last action  /  ${controller.lastAction}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _inkMuted),
                ),
              ),
              const Icon(Icons.tune_rounded, size: 15, color: Color(0xff65707d)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _capabilities(),
      ],
    ),
  );

  // ---------------------------------------------------------------------
  // Tab chrome
  // ---------------------------------------------------------------------

  Widget _tabBar() => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: _inkDeep,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _inkLine),
    ),
    child: Row(
      children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _tab == i ? _lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _tab == i
                        ? const Color(0xff11140d)
                        : const Color(0xffaab2bd),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  // ---------------------------------------------------------------------
  // PAINT
  // ---------------------------------------------------------------------

  Widget _paintTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _section('01', 'SHOWROOM SCHEMES', 'Whole car in one tap'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final scheme in schemes)
            _chip(
              scheme.name,
              onTap: () => controller.applyScheme(scheme),
            ),
        ],
      ),
      const SizedBox(height: 20),
      _section('02', 'PER-PART PAINT', 'Animated PBR finishes'),
      const SizedBox(height: 6),
      for (final zone in PaintZone.values) _zoneRow(zone),
      const SizedBox(height: 10),
      _switchRow(
        'Hue drift',
        'Paint hue inches around the wheel forever',
        controller.paintDrift,
        controller.setPaintDrift,
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: _action(
          Icons.casino_outlined,
          'Surprise me',
          controller.randomize,
        ),
      ),
    ],
  );

  Widget _zoneRow(PaintZone zone) {
    final swatches = controller.paletteOf(zone);
    final selected = controller.swatchOf(zone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                zone.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                selected.name,
                style: const TextStyle(fontSize: 11, color: _inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: swatches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final swatch = swatches[index];
                final active = identical(swatch, selected);
                return Tooltip(
                  message: swatch.name,
                  waitDuration: const Duration(milliseconds: 350),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => controller.selectZoneSwatch(zone, swatch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            swatch.displayColor,
                            Color.lerp(swatch.displayColor, Colors.black, .45)!,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? _lime : const Color(0xff3a424d),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: active
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LIGHT
  // ---------------------------------------------------------------------

  Widget _lightTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _section('01', 'STUDIO LOOK', 'Crossfades post + sky'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < looks.length; i++)
            _chip(
              looks[i].name,
              sub: looks[i].tagline,
              selected: controller.lookIndex == i,
              onTap: () => controller.selectLook(i),
            ),
        ],
      ),
      const SizedBox(height: 20),
      _section('02', 'KEY LIGHT', 'The orbiting sun'),
      _sliderRow(
        'Azimuth',
        '${(controller.keyAzimuth / tau * 360).round() % 360}°',
        controller.keyAzimuth / tau,
        0,
        1,
        controller.setKeyAzimuth,
      ),
      _sliderRow(
        'Height',
        '${(controller.keyElevation / math.pi * 180).round()}°',
        (controller.keyElevation - .12) / (.98),
        0,
        1,
        controller.setKeyElevation,
      ),
      _sliderRow(
        'Intensity',
        controller.keyIntensity.toStringAsFixed(1),
        controller.keyIntensity.clamp(0.0, 6.0),
        0,
        6,
        controller.setKeyIntensity,
      ),
      _sliderRow(
        'Warmth',
        '${(controller.keyWarmth * 100).round()}%',
        controller.keyWarmth,
        0,
        1,
        controller.setKeyWarmth,
      ),
      const SizedBox(height: 14),
      _section('03', 'ACCENT RIG', 'Rim, ground glow, lamps'),
      _sliderRow(
        'Rim hue',
        '${(controller.rimHue * 360).round()}°',
        controller.rimHue,
        0,
        1,
        controller.setRimHue,
      ),
      _sliderRow(
        'Rim intensity',
        controller.rimIntensity.round().toString(),
        controller.rimIntensity.clamp(0.0, 90.0),
        0,
        90,
        controller.setRimIntensity,
      ),
      const SizedBox(height: 4),
      _switchRow(
        'Ground glow',
        'Colored pool under the car',
        controller.underGlowOn,
        (value) {
          if (value != controller.underGlowOn) controller.toggleUnderGlow();
        },
      ),
      _switchRow(
        'Headlights',
        'Lamp emissive with bloom flare',
        controller.headlightsOn,
        (value) {
          if (value != controller.headlightsOn) controller.toggleHeadlights();
        },
      ),
      _switchRow(
        'Light rig sweep',
        'Key and rim orbit the car',
        controller.autoSweep,
        (value) {
          if (value != controller.autoSweep) controller.toggleAutoSweep();
        },
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // MOTION
  // ---------------------------------------------------------------------

  Widget _motionTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _section('01', 'WHEELS', 'Tires spin on the axle'),
      const SizedBox(height: 4),
      _switchRow(
        'Wheel spin',
        'Tire, rim, and brake disc turn together',
        controller.spinning,
        (value) {
          if (value != controller.spinning) controller.toggleSpin();
        },
      ),
      _sliderRow(
        'Throttle',
        '${controller.rpm.round()} rpm',
        controller.rpm,
        0,
        maxWheelRpm,
        controller.setRpm,
      ),
      const SizedBox(height: 2),
      SizedBox(
        width: double.infinity,
        child: _action(
          Icons.dangerous_outlined,
          controller.brakeOn ? 'Release the brake' : 'Brake',
          () => controller.setBrake(!controller.brakeOn),
          active: controller.brakeOn,
        ),
      ),
      const SizedBox(height: 20),
      _section('02', 'TURNTABLE', 'Camera drift'),
      _switchRow(
        'Auto-orbit',
        'Camera circles the stage',
        controller.autoOrbit,
        (value) {
          if (value != controller.autoOrbit) controller.toggleAutoOrbit();
        },
      ),
      _sliderRow(
        'Speed',
        '${(controller.orbitSpeed * 57.3).round()}°/s',
        controller.orbitSpeed,
        .04,
        .8,
        controller.setOrbitSpeed,
      ),
      const SizedBox(height: 16),
      _section('03', 'CAMERA SHOTS', 'Authored angles'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < cameraShots.length; i++)
            _chip(
              cameraShots[i].name,
              selected: controller.shotIndex == i,
              onTap: () => controller.applyShot(i),
            ),
          _chip('Random', onTap: controller.randomShot),
        ],
      ),
      const SizedBox(height: 20),
      _section('04', 'SHOWREEL', 'Auto-choreographed tour'),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: _action(
          controller.showreelOn
              ? Icons.stop_circle_outlined
              : Icons.play_circle_outline,
          controller.showreelOn
              ? 'Stop · ${controller.reelStepName}'
              : 'Run the showreel',
          controller.toggleShowreel,
          active: controller.showreelOn,
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------

  Widget _section(String n, String title, String hint) => Row(
    children: [
      Text(
        n,
        style: const TextStyle(color: _lime, fontSize: 11, fontWeight: FontWeight.w800),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      const Spacer(),
      Text(hint, style: const TextStyle(fontSize: 10, color: Color(0xff65707d))),
    ],
  );

  Widget _switchRow(
    String label,
    String hint,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(hint, style: const TextStyle(fontSize: 10, color: _inkMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xff11140d),
          activeTrackColor: _lime,
        ),
      ],
    ),
  );

  Widget _sliderRow(
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color(0xffaab2bd),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: _lime,
            inactiveTrackColor: const Color(0xff2a313a),
            thumbColor: _lime,
            overlayColor: _lime.withValues(alpha: .12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
          ),
          child: Slider(
            value: current.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );

  Widget _chip(
    String label, {
    String? sub,
    bool selected = false,
    required VoidCallback onTap,
  }) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: sub == null ? 9 : 8),
      decoration: BoxDecoration(
        color: selected ? _lime : const Color(0xff181c21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? _lime : const Color(0xff252b33),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xff11140d) : const Color(0xffdce2e9),
            ),
          ),
          if (sub != null)
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? const Color(0xff3f4b1d)
                    : const Color(0xff65707d),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: active ? _lime : const Color(0xffaab2bd),
      side: BorderSide(color: active ? _lime : const Color(0xff303741)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _lime.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: _lime.withValues(alpha: .35)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: _lime,
      ),
    ),
  );

  Widget _capabilities() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _inkDeep,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fact_check_outlined, size: 17, color: _lime),
            const SizedBox(width: 8),
            const Text(
              'What the lab exercises',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Text(
              'live scene graph',
              style: TextStyle(fontSize: 10, color: Color(0xff65707d)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: const [
            _Tag('material variants'),
            _Tag('per-frame PBR easing'),
            _Tag('point + directional lights'),
            _Tag('shadow catcher stage'),
            _Tag('SMAA · bloom · SSR'),
            _Tag('gradient sky IBL'),
            _Tag('authored camera shots'),
          ],
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xff1c2328),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, color: Color(0xffaab2bd)),
    ),
  );
}
