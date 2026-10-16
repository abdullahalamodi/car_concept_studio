/// The engine-side brain of the Scene Lab demo.
///
/// Owns the flutter_scene [Scene], the loaded car, and every animated rig
/// (paint, wheels, lights, sky, camera). Widgets send intents and read state;
/// each animated quantity is eased here so every control on the page produces
/// smooth motion instead of a hard cut.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'scene_lab_math.dart';
import 'scene_lab_orbit.dart';
import 'scene_lab_presets.dart';

/// Break-in levels for the lamp materials, tuned against the showroom looks.
const double _headlightParkedStrength = .35;
const double _headlightLitStrength = 10;
const double _taillightRestStrength = 2;
const double _taillightBrakeStrength = 16;

/// How long a look crossfade takes, and how long the paint booth takes to
/// settle a changed finish.
const double _lookBlendSeconds = 1.7;
const double _paintSettleSeconds = .55;

/// Drives the live Scene Lab: model loading, per-frame animation, and the
/// showreel. One instance is shared by the viewer and the control panel.
class SceneLabController extends ChangeNotifier {
  SceneLabController();

  /// The scene rendered by [SceneView].
  final Scene scene = Scene();

  /// The orbit camera lens and aim, driven by [CameraControls].
  final LabOrbitController orbit = LabOrbitController(
    target: vm.Vector3(0, .74, 0),
    distance: 6.6,
    azimuth: math.pi + .68,
    polar: .24,
  );

  // ---------------------------------------------------------------------
  // Readiness
  // ---------------------------------------------------------------------

  bool _ready = false;
  bool get ready => _ready;

  Object? _error;
  Object? get error => _error;

  Future<void>? _init;

  /// Loads the engine, the scene dressing, and the car exactly once.
  Future<void> ensureInitialized() {
    return _init ??= _initialize().catchError((Object error) {
      _error = error;
      if (!_ready) notifyListeners();
    });
  }

  /// Retries a failed load; a no-op once the lab is live.
  void retry() {
    if (_ready) return;
    _error = null;
    _init = null;
    notifyListeners();
    ensureInitialized();
  }

  // ---------------------------------------------------------------------
  // User state (read by the controls panel)
  // ---------------------------------------------------------------------

  final Map<PaintZone, List<PaintSwatch>> _palettes =
      <PaintZone, List<PaintSwatch>>{
        for (final zone in PaintZone.values) zone: <PaintSwatch>[],
      };
  final Map<PaintZone, PaintSwatch> _zoneSwatches =
      <PaintZone, PaintSwatch>{};

  /// Swatches offered for [zone]: the factory finish, authored glTF variant
  /// finishes, then the curated palette.
  List<PaintSwatch> paletteOf(PaintZone zone) => _palettes[zone]!;

  /// The finish currently targeted for [zone].
  PaintSwatch swatchOf(PaintZone zone) => _zoneSwatches[zone]!;

  bool _paintDrift = false;
  bool get paintDrift => _paintDrift;

  int _lookIndex = 0;
  int get lookIndex => _lookIndex;
  LabLook get look => looks[_lookIndex];

  double keyAzimuth = 2.4;
  double keyElevation = .55;
  double keyIntensity = 3.4;
  double keyWarmth = .18;
  double rimIntensity = 26;
  double rimHue = .58;
  bool underGlowOn = true;
  bool headlightsOn = false;
  bool brakeOn = false;
  bool spinning = true;
  double rpm = 200;
  bool autoOrbit = true;
  double orbitSpeed = .22;
  bool autoSweep = false;
  int shotIndex = 0;
  bool showreelOn = false;

  String lastAction = 'Scene Lab ready';

  double speedKmh = 0;
  double fps = 60;

  /// Wheel speed in revolutions per minute, for the HUD readout.
  double get wheelRpm => _wheelSpeed.abs() * 60 / tau;

  /// The finish of the showreel step that is playing, when it runs.
  String reelStepName = 'Opening';

  // ---------------------------------------------------------------------
  // Animated internals
  // ---------------------------------------------------------------------

  final Map<PaintZone, List<_PaintChannel>> _channels =
      <PaintZone, List<_PaintChannel>>{
        for (final zone in PaintZone.values) zone: <_PaintChannel>[],
      };
  final Map<PaintZone, List<PaintSwatch>> _authored =
      <PaintZone, List<PaintSwatch>>{
        for (final zone in PaintZone.values) zone: <PaintSwatch>[],
      };
  final Map<PaintZone, List<PaintSpec>> _defaultSpecs =
      <PaintZone, List<PaintSpec>>{
        for (final zone in PaintZone.values) zone: <PaintSpec>[],
      };
  final Map<PaintZone, String> _defaultNames = <PaintZone, String>{};

  final List<_SpinNode> _spinners = <_SpinNode>[];

  Node? _frontWheel;
  Node? _rearWheel;

  late final GradientSkySource _sky;
  late final Skybox _skybox;
  late final SkyEnvironment _skyEnv;
  late final DirectionalLight _keyLight;
  late final Node _keyNode;
  late final PointLight _rimLight;
  late final Node _rimNode;
  late final PointLight _underLight;
  late final Node _underNode;
  late final Node _cameraNode;
  late final PerspectiveProjection _projection;
  PhysicallyBasedMaterial? _headlightMaterial;
  PhysicallyBasedMaterial? _taillightMaterial;

  EnvironmentSettings? _currentSettings;
  EnvironmentSettings? _lookFromSettings;

  double _keyIntensityGoal = 3.4;
  double _keyIntensityLevel = 0;
  double _rimIntensityGoal = 26;
  double _rimIntensityLevel = 0;
  double _underGlowGoal = 8;
  double _underGlowLevel = 0;

  double _wheelSpeed = 0;
  double _wheelAngle = 0;
  double _headlightLevel = 0;
  double _taillightLevel = 0;
  double _sweepLevel = 0;

  double _fov = 30 * math.pi / 180;
  double _fovGoal = 30 * math.pi / 180;

  vm.Vector3 _carCenter = vm.Vector3(0, .74, 0);
  final vm.Vector3 _sunDirection = vm.Vector3(0, 1, 0);
  final vm.Vector3 _scratchA = vm.Vector3(0, 0, 0);
  final vm.Vector3 _scratchB = vm.Vector3(0, 0, 0);

  final vm.Vector3 _skyFromZenith = vm.Vector3(.02, .03, .05);
  final vm.Vector3 _skyFromHorizon = vm.Vector3(.06, .07, .09);
  final vm.Vector3 _skyFromGround = vm.Vector3(.01, .01, .015);
  final vm.Vector3 _skyFromSun = vm.Vector3(2.2, 2.0, 1.8);

  double _elapsed = 0;
  double _driftTurns = 0;
  double _lookBlend = 1;
  double _skyBakeClock = 0;
  double _notifyClock = 0;
  double _fpsEma = 60;

  int _lookFromIndex = 0;

  final List<_ReelStep> _reel = <_ReelStep>[];
  int _reelStep = 0;
  double _reelClock = 0;

  final math.Random _random = math.Random();

  // ---------------------------------------------------------------------
  // Intents: paint
  // ---------------------------------------------------------------------

  /// Animates [zone] to [swatch].
  void selectZoneSwatch(PaintZone zone, PaintSwatch swatch) {
    _zoneSwatches[zone] = swatch;
    _retargetZone(zone, swatch, hueTurns: _paintDrift ? _driftTurns : 0);
    lastAction = '${zone.label} · ${swatch.name}';
    notifyListeners();
  }

  /// Animates every zone to the colors of [scheme].
  void applyScheme(LabScheme scheme) {
    for (final zone in PaintZone.values) {
      final swatch = scheme.swatch(zone);
      _zoneSwatches[zone] = swatch;
      _retargetZone(zone, swatch, hueTurns: _paintDrift ? _driftTurns : 0);
    }
    lastAction = 'Scheme · ${scheme.name}';
    notifyListeners();
  }

  /// Turns the slow hue drift on or off; drifting paint keeps every animated
  /// transition alive on its own.
  void setPaintDrift(bool value) => _setDrift(value);

  void _setDrift(bool value) {
    if (_paintDrift == value) return;
    _paintDrift = value;
    if (!value) {
      for (final zone in PaintZone.values) {
        _retargetZone(zone, _zoneSwatches[zone]!);
      }
    }
    lastAction = value ? 'Hue drift on' : 'Hue drift off';
    notifyListeners();
  }

  /// Picks a harmonized random scheme, look, and shot.
  void randomize() {
    final scheme = schemes[_random.nextInt(schemes.length)];
    applyScheme(scheme);
    selectLook(_random.nextInt(looks.length));
    applyShot(_random.nextInt(cameraShots.length));
    lastAction = 'Surprise · ${scheme.name}';
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Intents: lighting
  // ---------------------------------------------------------------------

  /// Crossfades to [looks]`[index]`.
  void selectLook(int index) {
    final clamped = index.clamp(0, looks.length - 1);
    if (clamped == _lookIndex && _lookBlend >= 1) return;
    _lookFromIndex = _lookBlend >= 1 ? _lookIndex : _lookFromIndex;
    _lookIndex = clamped;
    _lookBlend = 0;
    _lookFromSettings = _currentSettings;
    _skyFromZenith.setFrom(_sky.zenithColor);
    _skyFromHorizon.setFrom(_sky.horizonColor);
    _skyFromGround.setFrom(_sky.groundColor);
    _skyFromSun.setFrom(_sky.sunColor);
    final target = looks[clamped];
    keyIntensity = target.keyIntensity;
    rimIntensity = target.rimIntensity;
    _keyIntensityGoal = target.keyIntensity;
    _rimIntensityGoal = target.rimIntensity;
    _underGlowGoal = underGlowOn ? target.underGlow : 0;
    lastAction = 'Look · ${target.name}';
    notifyListeners();
  }

  /// Studio key azimuth, as a fraction of a full turn.
  void setKeyAzimuth(double turns) {
    keyAzimuth = turns * tau;
    lastAction = 'Key light moved';
    notifyListeners();
  }

  /// Studio key height, 0 (low and dramatic) to 1 (high noon).
  void setKeyElevation(double t) {
    keyElevation = lerpDouble(.12, 1.1, t.clamp(0.0, 1.0));
    lastAction = 'Key height ${(keyElevation * 57.296).round()}°';
    notifyListeners();
  }

  /// Studio key brightness, 0 to 6.
  void setKeyIntensity(double value) {
    keyIntensity = value;
    _keyIntensityGoal = value;
    lastAction = 'Key intensity ${value.toStringAsFixed(1)}';
    notifyListeners();
  }

  /// Color temperature, 0 (cool) to 1 (warm).
  void setKeyWarmth(double t) {
    keyWarmth = t.clamp(0.0, 1.0);
    lastAction = 'Key warmth ${(keyWarmth * 100).round()}%';
    notifyListeners();
  }

  /// Accent rim brightness in light units, 0 to 90.
  void setRimIntensity(double value) {
    rimIntensity = value;
    _rimIntensityGoal = value;
    lastAction = 'Rim intensity ${value.round()}';
    notifyListeners();
  }

  /// Accent rim hue, as a fraction of a full turn.
  void setRimHue(double turns) {
    rimHue = turns % 1;
    lastAction = 'Rim hue ${(rimHue * 360).round()}°';
    notifyListeners();
  }

  void toggleUnderGlow() => _setUnderGlow(!underGlowOn);

  void _setUnderGlow(bool value) {
    underGlowOn = value;
    _underGlowGoal = value ? look.underGlow : 0;
    lastAction = value ? 'Underglow on' : 'Underglow off';
    notifyListeners();
  }

  void toggleHeadlights() => _setHeadlights(!headlightsOn);

  void _setHeadlights(bool value) {
    headlightsOn = value;
    lastAction = value ? 'Headlights on' : 'Headlights off';
    notifyListeners();
  }

  void toggleAutoSweep() => _setAutoSweep(!autoSweep);

  void _setAutoSweep(bool value) {
    autoSweep = value;
    lastAction = value ? 'Light rig sweeping' : 'Light rig parked';
    notifyListeners();
  }

  /// Engages the brake: the wheels spin down and the tail lights flare.
  void setBrake(bool value) {
    if (brakeOn == value) return;
    brakeOn = value;
    lastAction = value ? 'Braking' : 'Brake released';
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Intents: motion
  // ---------------------------------------------------------------------

  void toggleSpin() => _setSpin(!spinning);

  void _setSpin(bool value, {double? targetRpm}) {
    spinning = value;
    if (targetRpm != null) rpm = targetRpm.clamp(0.0, maxWheelRpm);
    lastAction = value ? 'Wheels spinning' : 'Wheels stopped';
    notifyListeners();
  }

  void setRpm(double value) {
    rpm = value.clamp(0.0, maxWheelRpm);
    lastAction = 'Throttle ${rpm.round()} rpm';
    notifyListeners();
  }

  void toggleAutoOrbit() => _setAutoOrbit(!autoOrbit);

  void _setAutoOrbit(bool value) {
    autoOrbit = value;
    lastAction = value ? 'Turntable on' : 'Turntable off';
    notifyListeners();
  }

  void setOrbitSpeed(double value) {
    orbitSpeed = value.clamp(.04, .8);
    lastAction = 'Turntable ${(orbitSpeed * 57.3).round()}°/s';
    notifyListeners();
  }

  /// Cuts to the authored camera shot at [index].
  void applyShot(int index) {
    final clamped = index.clamp(0, cameraShots.length - 1);
    final shot = cameraShots[clamped];
    shotIndex = clamped;
    orbit.aimAt(
      target: _shotTarget(shot),
      azimuth: _noseAzimuth() + shot.yawDegrees * math.pi / 180,
      polar: shot.polar,
      distance: shot.distance,
      smoothingSeconds: showreelOn ? .18 : .32,
    );
    _fovGoal = shot.fovDegrees * math.pi / 180;
    lastAction = 'Camera · ${shot.name}';
    notifyListeners();
  }

  /// Cuts to a random authored shot.
  void randomShot() {
    var next = _random.nextInt(cameraShots.length);
    if (next == shotIndex) next = (next + 1) % cameraShots.length;
    applyShot(next);
  }

  /// Starts or stops the choreographed showreel.
  void toggleShowreel() {
    showreelOn = !showreelOn;
    if (showreelOn) {
      _reelStep = 0;
      _reelClock = 0;
      _reel.first.run();
      reelStepName = _reel.first.name;
      lastAction = 'Showreel · ${_reel.first.name}';
    } else {
      lastAction = 'Showreel stopped';
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Engine wiring
  // ---------------------------------------------------------------------

  Future<void> _initialize() async {
    // Rendering is gated on the engine's static resources; geometry and
    // materials must be built after this completes. The car's clearcoat,
    // transmission, and iridescence shaders load here too, so the first
    // visible frame does not stall on them.
    await Scene.preload(physicalMaterials: true, smaa: true);
    _configureScene();

    final model = await loadScene('assets/CarConcept.glb');
    scene.add(model);

    _buildRigs(model);
    _snapshotAuthoredFinishes(model);

    _applyLookNow(looks[_lookIndex]);
    applyShot(0);
    _paintLoadedStage();

    _ready = true;
    notifyListeners();
  }

  void _configureScene() {
    scene.antiAliasingMode = AntiAliasingMode.smaa;
    scene.renderQuality.adaptive = true;
    scene.renderQuality.targetFrameRate = 60;
    scene.renderQuality.minRenderScale = .6;
    // The car's windows are transmissive; one shared scene capture keeps the
    // glass affordable on the web's GLES-class backend.
    scene.sceneColorCaptureBatches = 1;

    _sky = GradientSkySource(sunSharpness: 900);
    _skybox = Skybox(_sky);
    scene.skybox = _skybox;
    // Image-based lighting baked from the same gradient the skybox shows, so
    // metallic paint reflects the room the car stands in. Manual refresh: the
    // look crossfade invalidates it while the sky colors move.
    _skyEnv = SkyEnvironment(
      _sky,
      refresh: SkyEnvironmentRefresh.manual,
      faceResolution: 128,
      equirectWidth: 512,
    );
    scene.skyEnvironment = _skyEnv;
    _applySky(looks[_lookIndex], looks[_lookIndex], 1);

    _keyLight = DirectionalLight(
      intensity: keyIntensity,
      castsShadow: true,
      contactShadows: true,
      contactShadowDistance: .05,
      shadowSoftness: .6,
    );
    _keyNode = Node(name: 'LabKeyLight')
      ..addComponent(DirectionalLightComponent(_keyLight));
    scene.root.add(_keyNode);

    _rimLight = PointLight(intensity: rimIntensity, range: 9, radius: .45);
    _rimNode = Node(name: 'LabRimLight')
      ..addComponent(PointLightComponent(_rimLight));
    scene.root.add(_rimNode);

    _underLight = PointLight(
      intensity: 8,
      range: 6,
      radius: 1.2,
      falloffExponent: 1.15,
      color: vm.Vector3(.2, .25, .4),
    );
    _underNode = Node(name: 'LabGroundGlow')
      ..addComponent(PointLightComponent(_underLight));
    _underNode.position = vm.Vector3(0, .32, 0);
    scene.root.add(_underNode);

    _projection = PerspectiveProjection(
      fovRadiansY: _fov,
      near: .05,
      far: 300,
    );
    _cameraNode = Node(name: 'LabCamera')
      ..addComponent(
        CameraComponent(projection: _projection, activateOnMount: true),
      )
      ..addComponent(orbit);
    scene.root.add(_cameraNode);

    final ground = Node(
      name: 'LabGround',
      mesh: Mesh(
        PlaneGeometry(width: 22, depth: 22),
        ShadowCatcherMaterial(
          shadowIntensity: .62,
          aoStrength: .9,
          fadeStart: 2.8,
          fadeEnd: 9.5,
        ),
      ),
    )..shadowCastingMode = ShadowCastingMode.off;
    scene.root.add(ground);

    _aimKeyLight();
  }

  // ---------------------------------------------------------------------
  // Rig construction
  // ---------------------------------------------------------------------

  void _buildRigs(Node model) {
    final seen = <PhysicallyBasedMaterial>{};
    _visit(model, (node) {
      final name = node.name;
      if (name == 'WheelFrontL') _frontWheel = node;
      if (name == 'WheelRearL') _rearWheel = node;
      if (name.startsWith('Wheel')) {
        // Everything on a wheel turns with it except the brake caliper.
        for (final child in node.children) {
          if (child.name.endsWith('BrakePad')) continue;
          _spinners.add(_SpinNode(child, child.localTransform.clone()));
        }
      }
      final mesh = node.mesh;
      if (mesh == null) return;
      for (final primitive in mesh.primitives) {
        final material = primitive.material;
        if (material is! PhysicallyBasedMaterial) continue;
        if (!seen.add(material)) continue;
        final materialName = material.name;
        if (materialName == 'Headlight') {
          _headlightMaterial = material;
          continue;
        }
        if (materialName == 'Brakelight') {
          _taillightMaterial = material;
          continue;
        }
        final zone = PaintZone.ofMaterial(materialName);
        if (zone == null) continue;
        final spec = _specOf(material);
        _defaultSpecs[zone]!.add(spec);
        _channels[zone]!.add(_PaintChannel(material, spec));
      }
    });

    for (final zone in PaintZone.values) {
      _defaultNames[zone] = _channels[zone]!
          .map((channel) => channel.material.name)
          .join('|');
    }

    final front = _frontWheel?.globalTransform.getTranslation();
    final rear = _rearWheel?.globalTransform.getTranslation();
    if (front != null && rear != null) {
      _carCenter = vm.Vector3(0, .74, (front.z + rear.z) * .5);
      orbit.target = _carCenter;
    }
  }

  /// Captures the finish each authored glTF variant paints a zone with.
  ///
  /// The variants component swaps primitives' materials in place, so the
  /// round trip is: select the variant, read the now-assigned materials,
  /// select null to restore the factory finish. A zone is only credited to
  /// the variant when the assigned materials actually change.
  void _snapshotAuthoredFinishes(Node model) {
    final component = MaterialsVariantsComponent.of(model);
    if (component != null) {
      for (final variant in component.variants) {
        component.select(variant);
        final zones = _assignedMaterials(model);
        for (final zone in PaintZone.values) {
          final materials = zones[zone]!;
          if (materials.isEmpty) continue;
          final names = materials.map((m) => m.name).join('|');
          if (names == _defaultNames[zone]) continue;
          _authored[zone]!.add(
            PaintSwatch(
              variant,
              _specOf(materials.first),
              perMaterial: [for (final m in materials) _specOf(m)],
            ),
          );
        }
      }
      component.select(null);
    } else {
      // No variants in the source: the curated authored list is the fallback
      // naming for the body zones.
      for (final zone in PaintZone.values) {
        if (zone == PaintZone.rims) continue;
        _authored[zone]!.addAll(
          authoredFinishes.map(
            (swatch) =>
                PaintSwatch(swatch.name, swatch.spec),
          ),
        );
      }
    }
    _fillPalettes();
  }

  /// Assigns every zone its palette and selects the factory finish.
  void _fillPalettes() {
    for (final zone in PaintZone.values) {
      final list = _palettes[zone]!..clear();
      final defaults = _defaultSpecs[zone]!;
      if (defaults.isEmpty) {
        // The asset does not carry this zone; offer the curated palette so
        // the panel still has something coherent to show.
        list.addAll(paletteFor(zone));
        _zoneSwatches[zone] = list.first;
        continue;
      }
      final initial = PaintSwatch(
        'Factory',
        defaults.first,
        perMaterial: List<PaintSpec>.of(defaults),
      );
      list.add(initial);
      for (final swatch in _authored[zone]!) {
        if (list.any((existing) => existing.sameSpecsAs(swatch))) continue;
        list.add(swatch);
      }
      for (final swatch in paletteFor(zone)) {
        if (list.any(
          (existing) =>
              existing.name == swatch.name ||
              existing.sameSpecsAs(swatch),
        )) {
          continue;
        }
        list.add(swatch);
      }
      _zoneSwatches[zone] = initial;
    }
  }

  /// The distinct materials currently assigned to each paint zone.
  Map<PaintZone, List<PhysicallyBasedMaterial>> _assignedMaterials(Node model) {
    final result = <PaintZone, List<PhysicallyBasedMaterial>>{
      for (final zone in PaintZone.values) zone: <PhysicallyBasedMaterial>[],
    };
    final seen = <PhysicallyBasedMaterial>{};
    _visit(model, (node) {
      final mesh = node.mesh;
      if (mesh == null) return;
      for (final primitive in mesh.primitives) {
        final material = primitive.material;
        if (material is! PhysicallyBasedMaterial || !seen.add(material)) {
          continue;
        }
        final zone = PaintZone.ofMaterial(material.name);
        if (zone == null) continue;
        result[zone]!.add(material);
      }
    });
    return result;
  }

  void _visit(Node node, void Function(Node) visit) {
    visit(node);
    for (final child in node.children) {
      _visit(child, visit);
    }
  }

  PaintSpec _specOf(PhysicallyBasedMaterial material) => PaintSpec(
    material.baseColorFactor.clone(),
    metallic: material.metallicFactor,
    roughness: material.roughnessFactor,
    clearcoat: material.clearcoat,
    clearcoatRoughness: material.clearcoatRoughness,
    iridescence: material.iridescence,
  );

  void _paintLoadedStage() {
    _headlightMaterial?.emissiveStrength = _headlightParkedStrength;
    _taillightMaterial?.emissiveStrength = _taillightRestStrength;
    _underLight.color.setFrom(hsvToLinearRgb(rimHue, .75, 1));
    _buildReel();
    lastAction = 'Scene Lab ready';
  }

  // ---------------------------------------------------------------------
  // Paint animation
  // ---------------------------------------------------------------------

  void _retargetZone(PaintZone zone, PaintSwatch swatch, {double hueTurns = 0}) {
    final channels = _channels[zone]!;
    final perMaterial = swatch.perMaterial;
    for (var i = 0; i < channels.length; i++) {
      PaintSpec spec = perMaterial != null && i < perMaterial.length
          ? perMaterial[i]
          : swatch.spec;
      if (hueTurns != 0) spec = spec.hueShifted(hueTurns);
      channels[i].setTarget(spec);
    }
  }

  void _tickPaint(double dt) {
    if (_paintDrift) {
      _driftTurns = (_driftTurns + dt * .045) % 1;
      for (final zone in PaintZone.values) {
        _retargetZone(zone, _zoneSwatches[zone]!, hueTurns: _driftTurns);
      }
    }
    final response = settleResponse(_paintSettleSeconds, dt);
    for (final zone in PaintZone.values) {
      for (final channel in _channels[zone]!) {
        channel.tick(response);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Light animation
  // ---------------------------------------------------------------------

  void _tickLights(double dt) {
    _sweepLevel +=
        ((autoSweep ? 1.0 : 0.0) - _sweepLevel) * settleResponse(.7, dt);
    if (!autoSweep && _sweepLevel < .001) _sweepLevel = 0;

    _keyIntensityLevel +=
        (_keyIntensityGoal - _keyIntensityLevel) * settleResponse(.55, dt);
    _keyLight.intensity = _keyIntensityLevel;

    _rimIntensityLevel +=
        (_rimIntensityGoal - _rimIntensityLevel) * settleResponse(.55, dt);
    _rimLight.intensity = _rimIntensityLevel;

    // The accent and ground lights share one hue knob, so the color story of
    // a night look stays coherent when either is dragged around.
    _scratchA.setFrom(hsvToLinearRgb(rimHue, .78, 1));
    _rimLight.color.setFrom(_scratchA);
    _underLight.color
      ..setFrom(_scratchA)
      ..scale(.92);

    _underGlowLevel +=
        (_underGlowGoal - _underGlowLevel) * settleResponse(.8, dt);
    _underLight.intensity =
        _underGlowLevel * (1 + .08 * math.sin(_elapsed * 1.9));

    _headlightLevel +=
        ((headlightsOn ? 1.0 : 0.0) - _headlightLevel) * settleResponse(.4, dt);
    final headlight = _headlightMaterial;
    if (headlight != null) {
      final strength = lerpDouble(
        _headlightParkedStrength,
        _headlightLitStrength,
        smoothstep01(_headlightLevel),
      );
      if ((headlight.emissiveStrength - strength).abs() > .01) {
        headlight.emissiveStrength = strength;
      }
    }

    _taillightLevel +=
        ((brakeOn ? 1.0 : 0.0) - _taillightLevel) * settleResponse(.16, dt);
    final taillight = _taillightMaterial;
    if (taillight != null) {
      final strength = lerpDouble(
        _taillightRestStrength,
        _taillightBrakeStrength,
        smoothstep01(_taillightLevel),
      );
      if ((taillight.emissiveStrength - strength).abs() > .01) {
        taillight.emissiveStrength = strength;
      }
    }

    // Key color rides the warmth slider: cool white to tungsten.
    _keyLight.color
      ..x = lerpDouble(.82, 1, keyWarmth)
      ..y = lerpDouble(.9, .82, keyWarmth)
      ..z = lerpDouble(1, .58, keyWarmth);

    _aimKeyLight();
  }

  void _aimKeyLight() {
    final azimuth = keyAzimuth + _sweepLevel * math.sin(_elapsed * tau / 13) * 1.25;
    final cosElevation = math.cos(keyElevation);
    _sunDirection
      ..x = math.sin(azimuth) * cosElevation
      ..y = math.sin(keyElevation)
      ..z = math.cos(azimuth) * cosElevation;
    _sky.sunDirection.setFrom(_sunDirection);
    // The light travels along the node's +Z, so the node sits on the sun side
    // and looks back at the car.
    _keyNode.lookAtFrom(_sunDirection * 24, vm.Vector3.zero());

    final rimAzimuth = math.pi + .52 + _sweepLevel * _elapsed * .3;
    _rimNode.position = vm.Vector3(
      _carCenter.x + math.sin(rimAzimuth) * 4.4,
      2.25,
      _carCenter.z + math.cos(rimAzimuth) * 4.4,
    );
    _underNode.position = vm.Vector3(_carCenter.x, .32, _carCenter.z);
  }

  // ---------------------------------------------------------------------
  // Wheel animation
  // ---------------------------------------------------------------------

  void _tickWheels(double dt) {
    final goalRpm = brakeOn ? 0.0 : (spinning ? rpm : 0.0);
    final goal = goalRpm * tau / 60;
    _wheelSpeed +=
        (goal - _wheelSpeed) * settleResponse(brakeOn ? .55 : .95, dt);
    if (goal == 0 && _wheelSpeed.abs() < .002) _wheelSpeed = 0;
    speedKmh = _wheelSpeed.abs() * wheelRadiusMeters * 3.6;
    if (_spinners.isEmpty) return;

    _wheelAngle += _wheelSpeed * dt;
    if (_wheelAngle > tau) _wheelAngle -= tau;
    if (_wheelAngle < -tau) _wheelAngle += tau;
    final spin = vm.Matrix4.rotationX(_wheelAngle);
    for (final spinner in _spinners) {
      spinner.node.localTransform = spinner.base * spin;
    }
  }

  // ---------------------------------------------------------------------
  // Camera animation
  // ---------------------------------------------------------------------

  void _tickCamera(double dt) {
    if (autoOrbit) orbit.turntable(dt, orbitSpeed);
    if ((_fov - _fovGoal).abs() > 1e-4) {
      _fov += (_fovGoal - _fov) * settleResponse(.4, dt);
      if ((_fov - _fovGoal).abs() < 1e-4) _fov = _fovGoal;
      _projection.fovRadiansY = _fov;
    }
  }

  double _noseAzimuth() {
    final front = _frontWheel?.globalTransform.getTranslation();
    final rear = _rearWheel?.globalTransform.getTranslation();
    if (front == null || rear == null) return math.pi;
    final forward = _scratchA
      ..setFrom(front)
      ..sub(rear);
    return math.atan2(-forward.x, -forward.z);
  }

  vm.Vector3 _shotTarget(CameraShot shot) {
    final lift = shot.targetHeightLift;
    return switch (shot.target) {
      ShotTarget.carCenter => _carCenter + vm.Vector3(0, lift, 0),
      ShotTarget.frontWheel => _wheelTarget(_frontWheel, lift),
      ShotTarget.rearWheel => _wheelTarget(_rearWheel, lift),
      ShotTarget.cabin => vm.Vector3(
        0,
        _carCenter.y + lift,
        _carCenter.z - .38,
      ),
    };
  }

  vm.Vector3 _wheelTarget(Node? wheel, double lift) {
    final translation = wheel?.globalTransform.getTranslation();
    if (translation == null) return _carCenter + vm.Vector3(0, lift, 0);
    return vm.Vector3(
      translation.x,
      translation.y + lift,
      translation.z,
    );
  }

  // ---------------------------------------------------------------------
  // Look crossfades
  // ---------------------------------------------------------------------

  EnvironmentSettings _settingsFor(LabLook look) => EnvironmentSettings(
    skybox: _skybox,
    skyEnvironment: _skyEnv,
    toneMapping: switch (look.toneMapping) {
      LookToneMapping.pbrNeutral => ToneMappingMode.pbrNeutral,
      LookToneMapping.aces => ToneMappingMode.aces,
      LookToneMapping.agx => ToneMappingMode.agx,
    },
    exposure: look.exposure,
    colorGradingEnabled: look.grading,
    saturation: look.saturation,
    contrast: look.contrast,
    temperature: look.temperature,
    bloomEnabled: look.bloom > 0,
    bloomThreshold: look.bloomThreshold,
    bloomIntensity: look.bloom,
    bloomScatter: look.bloomScatter,
    ambientOcclusionEnabled: look.ambientOcclusion > 0,
    ambientOcclusionIntensity: look.ambientOcclusion,
    screenSpaceReflectionsEnabled: look.reflections,
    vignetteEnabled: look.vignette > 0,
    vignetteIntensity: look.vignette,
    filmGrainEnabled: look.filmGrain > 0,
    filmGrainIntensity: look.filmGrain,
    chromaticAberrationEnabled: look.chromaticAberration > 0,
    chromaticAberrationIntensity: look.chromaticAberration,
  );

  /// Applies [look] with no crossfade, for the very first frame.
  void _applyLookNow(LabLook look) {
    _currentSettings = _settingsFor(look);
    scene.environmentSettings = _currentSettings!;
    _sky.zenithColor.setFrom(look.skyZenith);
    _sky.horizonColor.setFrom(look.skyHorizon);
    _sky.groundColor.setFrom(look.skyGround);
    _sky.sunColor.setFrom(look.skySun);
    _lookBlend = 1;
    _keyIntensityLevel = look.keyIntensity;
    _rimIntensityLevel = look.rimIntensity;
    _underGlowLevel = underGlowOn ? look.underGlow : 0;
    _skyEnv.invalidate();
  }

  /// The sky colors for a look blend at [t].
  void _applySky(LabLook from, LabLook to, double t) {
    _sky.zenithColor.setFrom(_mix(from.skyZenith, to.skyZenith, t, _scratchA));
    _sky.horizonColor.setFrom(
      _mix(from.skyHorizon, to.skyHorizon, t, _scratchB),
    );
    _sky.groundColor.setFrom(_mix(from.skyGround, to.skyGround, t, _scratchA));
    _sky.sunColor.setFrom(_mix(from.skySun, to.skySun, t, _scratchB));
  }

  vm.Vector3 _mix(
    vm.Vector3 a,
    vm.Vector3 b,
    double t,
    vm.Vector3 out,
  ) => out
    ..x = a.x + (b.x - a.x) * t
    ..y = a.y + (b.y - a.y) * t
    ..z = a.z + (b.z - a.z) * t;

  void _tickLook(double dt) {
    if (_lookBlend >= 1) return;
    _lookBlend = math.min(1, _lookBlend + dt / _lookBlendSeconds);
    final t = smoothstep01(_lookBlend);
    final target = looks[_lookIndex];
    final from = _lookFromSettings ?? _settingsFor(looks[_lookFromIndex]);
    _currentSettings = EnvironmentSettings.lerp(from, _settingsFor(target), t);
    scene.environmentSettings = _currentSettings!;
    _sky.zenithColor.setFrom(
      _mix(_skyFromZenith, target.skyZenith, t, _scratchA),
    );
    _sky.horizonColor.setFrom(
      _mix(_skyFromHorizon, target.skyHorizon, t, _scratchB),
    );
    _sky.groundColor.setFrom(
      _mix(_skyFromGround, target.skyGround, t, _scratchA),
    );
    _sky.sunColor.setFrom(_mix(_skyFromSun, target.skySun, t, _scratchB));
    _skyBakeClock += dt;
    if (_skyBakeClock > .22 || _lookBlend >= 1) {
      _skyBakeClock = 0;
      _skyEnv.invalidate();
    }
  }

  // ---------------------------------------------------------------------
  // Showreel
  // ---------------------------------------------------------------------

  void _buildReel() {
    _reel
      ..clear()
      ..addAll(<_ReelStep>[
        _ReelStep('Opening', 4.2, () {
          applyScheme(schemes[0]);
          selectLook(0);
          applyShot(0);
          _setHeadlights(true);
          setBrake(false);
          _setSpin(true, targetRpm: 220);
          _setAutoSweep(false);
          _setDrift(false);
          _setAutoOrbit(true);
          setOrbitSpeed(.2);
        }),
        _ReelStep('Acid cut', 3.8, () {
          applyScheme(schemes[3]);
          selectLook(1);
          applyShot(2);
        }),
        _ReelStep('Neon rims', 3.8, () {
          applyScheme(schemes[4]);
          selectLook(2);
          applyShot(4);
          setRimHue(.83);
          setRimIntensity(48);
          _setUnderGlow(true);
          _setAutoSweep(true);
        }),
        _ReelStep('Night tail', 3.8, () {
          selectLook(2);
          applyShot(3);
          _setHeadlights(false);
        }),
        _ReelStep('Launch', 3.6, () {
          applyScheme(schemes[5]);
          selectLook(0);
          applyShot(2);
          _setAutoSweep(false);
          _setSpin(true, targetRpm: 520);
        }),
        _ReelStep('Brake', 4.4, () {
          applyShot(3);
          setBrake(true);
        }),
        _ReelStep('Roll out', 2.8, () {
          setBrake(false);
          _setSpin(true, targetRpm: 240);
        }),
        _ReelStep('Hue drift', 5.2, () {
          applyScheme(schemes[1]);
          selectLook(1);
          applyShot(0);
          _setDrift(true);
        }),
        _ReelStep('Finale', 4.4, () {
          _setDrift(false);
          applyScheme(schemes[0]);
          selectLook(0);
          applyShot(5);
          _setHeadlights(true);
        }),
      ]);
  }

  void _tickReel(double dt) {
    if (!showreelOn || _reel.isEmpty) return;
    _reelClock += dt;
    if (_reelClock < _reel[_reelStep].duration) return;
    _reelClock = 0;
    _reelStep = (_reelStep + 1) % _reel.length;
    final step = _reel[_reelStep];
    reelStepName = step.name;
    step.run();
    lastAction = 'Showreel · ${step.name}';
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Frame
  // ---------------------------------------------------------------------

  /// Runs once per rendered frame from [SceneView.onTick].
  ///
  /// [deltaSeconds] is clamped so a stalled tab does not teleport the whole
  /// rig when it resumes.
  void tick(Duration elapsed, double deltaSeconds) {
    if (!_ready) return;
    final dt = deltaSeconds.clamp(0.0, .05);
    _elapsed += dt;
    if (deltaSeconds > 0) {
      _fpsEma += (1 / deltaSeconds - _fpsEma) * .06;
    }
    _tickReel(dt);
    _tickPaint(dt);
    _tickLights(dt);
    _tickWheels(dt);
    _tickCamera(dt);
    _tickLook(dt);
    _notifyClock += dt;
    if (_notifyClock >= .1) {
      _notifyClock = 0;
      fps = _fpsEma;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    scene.dispose();
    super.dispose();
  }
}

/// One material inside a paint zone, animated toward its target finish.
class _PaintChannel {
  _PaintChannel(this.material, PaintSpec spec)
    : _color = spec.color.clone(),
      _metallic = spec.metallic ?? material.metallicFactor,
      _roughness = spec.roughness ?? material.roughnessFactor,
      _clearcoat = spec.clearcoat ?? material.clearcoat,
      _clearcoatRoughness =
          spec.clearcoatRoughness ?? material.clearcoatRoughness,
      _iridescence = spec.iridescence ?? material.iridescence {
    _targetColor.setFrom(_color);
    _targetMetallic = _metallic;
    _targetRoughness = _roughness;
    _targetClearcoat = _clearcoat;
    _targetClearcoatRoughness = _clearcoatRoughness;
    _targetIridescence = _iridescence;
  }

  final PhysicallyBasedMaterial material;

  final vm.Vector4 _color;
  final vm.Vector4 _targetColor = vm.Vector4.zero();
  double _metallic = 1;
  double _roughness = 1;
  double _clearcoat = 0;
  double _clearcoatRoughness = 0;
  double _iridescence = 0;
  double _targetMetallic = 1;
  double _targetRoughness = 1;
  double _targetClearcoat = 0;
  double _targetClearcoatRoughness = 0;
  double _targetIridescence = 0;

  // The last value written to the material, so the channel can stop writing
  // once it settles instead of dirtying the material every frame.
  final vm.Vector4 _outColor = vm.Vector4.zero();
  double _outMetallic = -1;
  double _outRoughness = -1;
  double _outClearcoat = -1;
  double _outClearcoatRoughness = -1;
  double _outIridescence = -1;

  /// Points the channel at [spec]; `null` fields keep the current target.
  void setTarget(PaintSpec spec) {
    _targetColor.setFrom(spec.color);
    if (spec.metallic != null) _targetMetallic = spec.metallic!;
    if (spec.roughness != null) _targetRoughness = spec.roughness!;
    if (spec.clearcoat != null) _targetClearcoat = spec.clearcoat!;
    if (spec.clearcoatRoughness != null) {
      _targetClearcoatRoughness = spec.clearcoatRoughness!;
    }
    if (spec.iridescence != null) _targetIridescence = spec.iridescence!;
  }

  static bool _near(double a, double b) => (a - b).abs() < 2e-4;

  bool get _settled =>
      _near(_color.x, _targetColor.x) &&
      _near(_color.y, _targetColor.y) &&
      _near(_color.z, _targetColor.z) &&
      _near(_color.w, _targetColor.w) &&
      _near(_metallic, _targetMetallic) &&
      _near(_roughness, _targetRoughness) &&
      _near(_clearcoat, _targetClearcoat) &&
      _near(_clearcoatRoughness, _targetClearcoatRoughness) &&
      _near(_iridescence, _targetIridescence);

  /// Eases [response] of the remaining distance toward the target finish.
  void tick(double response) {
    if (_settled) return;
    _color
      ..x += (_targetColor.x - _color.x) * response
      ..y += (_targetColor.y - _color.y) * response
      ..z += (_targetColor.z - _color.z) * response
      ..w += (_targetColor.w - _color.w) * response;
    _metallic += (_targetMetallic - _metallic) * response;
    _roughness += (_targetRoughness - _roughness) * response;
    _clearcoat += (_targetClearcoat - _clearcoat) * response;
    _clearcoatRoughness +=
        (_targetClearcoatRoughness - _clearcoatRoughness) * response;
    _iridescence += (_targetIridescence - _iridescence) * response;
    _write();
  }

  void _write() {
    if (!_near(_outColor.x, _color.x) ||
        !_near(_outColor.y, _color.y) ||
        !_near(_outColor.z, _color.z) ||
        !_near(_outColor.w, _color.w)) {
      _outColor.setFrom(_color);
      material.baseColorFactor = _outColor;
    }
    if (!_near(_outMetallic, _metallic)) {
      _outMetallic = _metallic;
      material.metallicFactor = _metallic;
    }
    if (!_near(_outRoughness, _roughness)) {
      _outRoughness = _roughness;
      material.roughnessFactor = _roughness;
    }
    if (!_near(_outClearcoat, _clearcoat)) {
      _outClearcoat = _clearcoat;
      material.clearcoat = _clearcoat;
    }
    if (!_near(_outClearcoatRoughness, _clearcoatRoughness)) {
      _outClearcoatRoughness = _clearcoatRoughness;
      material.clearcoatRoughness = _clearcoatRoughness;
    }
    if (!_near(_outIridescence, _iridescence)) {
      _outIridescence = _iridescence;
      material.iridescence = _iridescence;
    }
  }
}

/// A wheel child node that spins about the wheel's axle (the node-local X).
class _SpinNode {
  _SpinNode(this.node, this.base);

  final Node node;

  /// The node's authored local transform, captured once; the spin is applied
  /// on top of this every frame.
  final vm.Matrix4 base;
}

/// One beat of the showreel script.
class _ReelStep {
  _ReelStep(this.name, this.duration, this.run);

  final String name;
  final double duration;
  final void Function() run;
}
