/// Preset data for the Scene Lab demo: paint finishes, lighting looks,
/// camera shots, and the showreel script's building blocks.
///
/// This file is pure data plus the math helpers; it does not import
/// flutter_scene so it can be exercised in plain unit tests.
library;

import 'dart:ui' show Color;

import 'package:vector_math/vector_math.dart' as vm;

import 'scene_lab_math.dart';

/// The car parts the paint booth can recolor.
enum PaintZone {
  body('Body'),
  accents('Accents'),
  interior('Interior'),
  rims('Rims');

  const PaintZone(this.label);

  /// Human-readable zone name.
  final String label;

  /// Matches a loaded glTF material to a recolorable zone by material name.
  static PaintZone? ofMaterial(String name) {
    if (name.startsWith('Paint 1')) return PaintZone.body;
    if (name.startsWith('Paint 2')) return PaintZone.accents;
    if (name.startsWith('Interior 3')) return PaintZone.interior;
    if (name.startsWith('Rim1') || name.startsWith('Rim2')) {
      return PaintZone.rims;
    }
    return null;
  }
}

/// One physically based paint finish.
///
/// Colors are linear RGB(A), the space glTF materials store. `null` numeric
/// fields mean "keep whatever the material already had" when the finish is
/// applied, which is how the authored glTF variants round-trip exactly.
class PaintSpec {
  const PaintSpec(
    this.color, {
    this.metallic,
    this.roughness,
    this.clearcoat,
    this.clearcoatRoughness,
    this.iridescence,
  });

  /// Linear RGB base color (`w` is alpha, usually 1).
  final vm.Vector4 color;
  final double? metallic;
  final double? roughness;
  final double? clearcoat;
  final double? clearcoatRoughness;
  final double? iridescence;

  /// This spec with its base color replaced by [color].
  PaintSpec withColor(vm.Vector4 color) => PaintSpec(
    color,
    metallic: metallic,
    roughness: roughness,
    clearcoat: clearcoat,
    clearcoatRoughness: clearcoatRoughness,
    iridescence: iridescence,
  );

  /// This spec with its hue rotated by [turns].
  PaintSpec hueShifted(double turns) =>
      withColor(rotateHue(color, turns));

  /// Whether this finish renders the same as [other].
  ///
  /// A `null` parameter is a wildcard: it means "keep whatever the material
  /// already had", so it can never make two finishes differ.
  bool matches(PaintSpec other, [double epsilon = 2e-3]) {
    bool near(double? a, double? b) =>
        a == null || b == null || (a - b).abs() <= epsilon;
    return (color.x - other.color.x).abs() <= epsilon &&
        (color.y - other.color.y).abs() <= epsilon &&
        (color.z - other.color.z).abs() <= epsilon &&
        near(metallic, other.metallic) &&
        near(roughness, other.roughness) &&
        near(clearcoat, other.clearcoat) &&
        near(clearcoatRoughness, other.clearcoatRoughness) &&
        near(iridescence, other.iridescence);
  }
}

/// A named finish shown as a swatch in the paint booth.
class PaintSwatch {
  const PaintSwatch(this.name, this.spec, {this.perMaterial});

  final String name;
  final PaintSpec spec;

  /// The exact finish for each material of a multi-material zone, when the
  /// zone's materials do not all share one finish (the factory rims, for
  /// example, mix a dark barrel with a polished face).
  ///
  /// Index-aligned with the controller's material list for the zone; when
  /// null (or shorter than the list) every material gets [spec].
  final List<PaintSpec>? perMaterial;

  Color get displayColor => colorOfLinearRgba(spec.color);

  /// Whether this swatch paints exactly what [other] does, including the
  /// per-material breakdown.
  bool sameSpecsAs(PaintSwatch other) {
    final a = perMaterial ?? <PaintSpec>[spec];
    final b = other.perMaterial ?? <PaintSpec>[other.spec];
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!a[i].matches(b[i])) return false;
    }
    return true;
  }
}

/// Builds a [PaintSpec] from an sRGB hex color and PBR parameters.
///
/// [argb] may be a bare `0xRRGGBB` literal (or `0xAARRGGBB`); paints are
/// opaque, so the alpha channel is always forced to 255. `Color(0xRRGGBB)`
/// alone would read as alpha 0 and make the material transparent.
PaintSpec finish(
  int argb, {
  double? metallic,
  double? roughness,
  double? clearcoat,
  double? clearcoatRoughness,
  double? iridescence,
}) => PaintSpec(
  linearRgba(Color(argb).withValues(alpha: 1)),
  metallic: metallic,
  roughness: roughness,
  clearcoat: clearcoat,
  clearcoatRoughness: clearcoatRoughness,
  iridescence: iridescence,
);

final List<PaintSwatch> bodyPalette = <PaintSwatch>[
  PaintSwatch('Candy Red', finish(0xC8202E, metallic: .9, roughness: .24, clearcoat: 1, clearcoatRoughness: .06)),
  PaintSwatch('Pearl', finish(0xE9EDF2, metallic: .55, roughness: .3, clearcoat: 1, clearcoatRoughness: .08)),
  PaintSwatch('Graphite', finish(0x41454C, metallic: .9, roughness: .3, clearcoat: .5)),
  PaintSwatch('Azure', finish(0x1E6FE8, metallic: .85, roughness: .22, clearcoat: 1, clearcoatRoughness: .05)),
  PaintSwatch('Acid', finish(0xB9F53D, metallic: .7, roughness: .28, clearcoat: 1, clearcoatRoughness: .08)),
  PaintSwatch('Magenta', finish(0xE22BB6, metallic: .8, roughness: .24, clearcoat: 1, clearcoatRoughness: .07)),
  PaintSwatch('Copper', finish(0xC4703A, metallic: .95, roughness: .28, clearcoat: .8)),
  PaintSwatch('Midnight', finish(0x111A2E, metallic: .95, roughness: .3, clearcoat: 1, clearcoatRoughness: .05)),
];

final List<PaintSwatch> accentPalette = <PaintSwatch>[
  PaintSwatch('Shadow', finish(0x22262C, metallic: .9, roughness: .3, clearcoat: .6)),
  PaintSwatch('Pearl', finish(0xDCE0E6, metallic: .6, roughness: .3, clearcoat: 1, clearcoatRoughness: .08)),
  PaintSwatch('Candy Red', finish(0xA61F2D, metallic: .9, roughness: .3, clearcoat: .6)),
  PaintSwatch('Ink', finish(0x0C0F14, metallic: .9, roughness: .26, clearcoat: .6)),
  PaintSwatch('Gold Wax', finish(0xD8B24A, metallic: 1, roughness: .24, clearcoat: .5)),
  PaintSwatch('Azure', finish(0x14418A, metallic: .85, roughness: .26, clearcoat: .8)),
];

final List<PaintSwatch> interiorPalette = <PaintSwatch>[
  PaintSwatch('Oxblood', finish(0x7A1E22, metallic: 0, roughness: .82)),
  PaintSwatch('Sand', finish(0xE8E2D4, metallic: 0, roughness: .78)),
  PaintSwatch('Caviar', finish(0x16181C, metallic: 0, roughness: .7)),
  PaintSwatch('Navy', finish(0x1B2A4A, metallic: 0, roughness: .8)),
  PaintSwatch('Tan', finish(0x8A5B36, metallic: 0, roughness: .8)),
  PaintSwatch('Slate', finish(0x3A4149, metallic: 0, roughness: .75)),
];

final List<PaintSwatch> rimPalette = <PaintSwatch>[
  PaintSwatch('Graphite', finish(0x2A2D33, metallic: 1, roughness: .34)),
  PaintSwatch('Silver', finish(0xC9CDD3, metallic: 1, roughness: .18)),
  PaintSwatch('Gold', finish(0xD0A82C, metallic: 1, roughness: .22)),
  PaintSwatch('Bronze', finish(0x8C5A33, metallic: 1, roughness: .28)),
  PaintSwatch('Stealth', finish(0x101114, metallic: 1, roughness: .55)),
  PaintSwatch('Chrome', finish(0xEDF1F5, metallic: 1, roughness: .08)),
];

/// The swatches offered for a zone.
List<PaintSwatch> paletteFor(PaintZone zone) => switch (zone) {
  PaintZone.body => bodyPalette,
  PaintZone.accents => accentPalette,
  PaintZone.interior => interiorPalette,
  PaintZone.rims => rimPalette,
};

/// A complete car finish: one swatch per zone.
class LabScheme {
  const LabScheme(this.name, this.swatches);

  final String name;
  final Map<PaintZone, PaintSwatch> swatches;

  PaintSwatch swatch(PaintZone zone) => swatches[zone]!;
}

/// Swatch lookup by name, so schemes can name the shared palette entries.
PaintSwatch _pick(List<PaintSwatch> palette, String name) =>
    palette.firstWhere((swatch) => swatch.name == name);

final List<PaintSwatch> authoredFinishes = <PaintSwatch>[
  PaintSwatch('Carmine Candy', finish(0xCC2233, metallic: 1, roughness: .25, clearcoat: 1, clearcoatRoughness: .05)),
  PaintSwatch('Pearly Swirly', finish(0xBCBCBC, metallic: 1, roughness: .35, clearcoat: 1, clearcoatRoughness: .1, iridescence: 1)),
  PaintSwatch('Torched Graphite', finish(0x404040, metallic: 1, roughness: .3)),
];

/// Curated full-car schemes for the one-tap chips.
final List<LabScheme> schemes = <LabScheme>[
  LabScheme('Candy Dream', {
    PaintZone.body: _pick(bodyPalette, 'Candy Red'),
    PaintZone.accents: _pick(accentPalette, 'Ink'),
    PaintZone.interior: _pick(interiorPalette, 'Oxblood'),
    PaintZone.rims: _pick(rimPalette, 'Stealth'),
  }),
  LabScheme('Pearl White', {
    PaintZone.body: _pick(bodyPalette, 'Pearl'),
    PaintZone.accents: _pick(accentPalette, 'Pearl'),
    PaintZone.interior: _pick(interiorPalette, 'Sand'),
    PaintZone.rims: _pick(rimPalette, 'Silver'),
  }),
  LabScheme('Torched', {
    PaintZone.body: _pick(bodyPalette, 'Graphite'),
    PaintZone.accents: _pick(accentPalette, 'Shadow'),
    PaintZone.interior: _pick(interiorPalette, 'Caviar'),
    PaintZone.rims: _pick(rimPalette, 'Graphite'),
  }),
  LabScheme('Acid Volt', {
    PaintZone.body: _pick(bodyPalette, 'Acid'),
    PaintZone.accents: _pick(accentPalette, 'Ink'),
    PaintZone.interior: _pick(interiorPalette, 'Caviar'),
    PaintZone.rims: _pick(rimPalette, 'Stealth'),
  }),
  LabScheme('Neon Bloom', {
    PaintZone.body: _pick(bodyPalette, 'Magenta'),
    PaintZone.accents: _pick(accentPalette, 'Azure'),
    PaintZone.interior: _pick(interiorPalette, 'Navy'),
    PaintZone.rims: _pick(rimPalette, 'Chrome'),
  }),
  LabScheme('Sunset', {
    PaintZone.body: _pick(bodyPalette, 'Copper'),
    PaintZone.accents: _pick(accentPalette, 'Gold Wax'),
    PaintZone.interior: _pick(interiorPalette, 'Tan'),
    PaintZone.rims: _pick(rimPalette, 'Gold'),
  }),
];

/// Tone mapping choice for a look (mirrors the engine enum without importing
/// flutter_scene here).
enum LookToneMapping { pbrNeutral, aces, agx }

/// A coherent scene-wide look: post-processing, sky tint, and light levels.
///
/// The controller converts this into the engine's `EnvironmentSettings` and
/// crossfades between looks with `EnvironmentSettings.lerp`.
class LabLook {
  LabLook({
    required this.name,
    required this.tagline,
    this.toneMapping = LookToneMapping.aces,
    this.exposure = 1.0,
    this.bloom = 0.0,
    this.bloomThreshold = 1.1,
    this.bloomScatter = 0.7,
    this.grading = false,
    this.saturation = 1.0,
    this.contrast = 1.0,
    this.temperature = 0.0,
    this.ambientOcclusion = 0.9,
    this.reflections = false,
    this.vignette = 0.25,
    this.filmGrain = 0.0,
    this.chromaticAberration = 0.0,
    vm.Vector3? skyZenith,
    vm.Vector3? skyHorizon,
    vm.Vector3? skyGround,
    vm.Vector3? skySun,
    this.keyIntensity = 3.2,
    this.rimIntensity = 26,
    this.underGlow = 10,
  }) : skyZenith = skyZenith ?? vm.Vector3(.02, .03, .05),
       skyHorizon = skyHorizon ?? vm.Vector3(.06, .07, .09),
       skyGround = skyGround ?? vm.Vector3(.01, .01, .015),
       skySun = skySun ?? vm.Vector3(2.2, 2.0, 1.8);

  final String name;
  final String tagline;
  final LookToneMapping toneMapping;
  final double exposure;
  final double bloom;
  final double bloomThreshold;
  final double bloomScatter;
  final bool grading;
  final double saturation;
  final double contrast;
  final double temperature;
  final double ambientOcclusion;
  final bool reflections;
  final double vignette;
  final double filmGrain;
  final double chromaticAberration;
  final vm.Vector3 skyZenith;
  final vm.Vector3 skyHorizon;
  final vm.Vector3 skyGround;
  final vm.Vector3 skySun;
  final double keyIntensity;
  final double rimIntensity;
  final double underGlow;
}

/// The four studio looks, from clean product viz to neon night.
final List<LabLook> looks = <LabLook>[
  LabLook(
    name: 'Showcase',
    tagline: 'Bright product viz',
    exposure: 1.05,
    bloom: .22,
    ambientOcclusion: 1.0,
    reflections: true,
    vignette: .22,
    skyZenith: vm.Vector3(.055, .065, .085),
    skyHorizon: vm.Vector3(.13, .15, .18),
    skyGround: vm.Vector3(.012, .014, .018),
    skySun: vm.Vector3(2.6, 2.5, 2.4),
    keyIntensity: 3.4,
    rimIntensity: 24,
    underGlow: 8,
  ),
  LabLook(
    name: 'Cinematic',
    tagline: 'Dusk, graded',
    exposure: .86,
    bloom: .18,
    bloomThreshold: 1.05,
    grading: true,
    saturation: .92,
    contrast: 1.14,
    temperature: -.08,
    ambientOcclusion: 1.2,
    vignette: .52,
    filmGrain: .16,
    chromaticAberration: .1,
    skyZenith: vm.Vector3(.03, .04, .07),
    skyHorizon: vm.Vector3(.22, .13, .08),
    skyGround: vm.Vector3(.01, .01, .012),
    skySun: vm.Vector3(3.0, 1.6, .8),
    keyIntensity: 2.4,
    rimIntensity: 30,
    underGlow: 6,
  ),
  LabLook(
    name: 'Neon',
    tagline: 'Night showroom',
    exposure: .8,
    bloom: .5,
    bloomThreshold: .78,
    bloomScatter: .85,
    grading: true,
    saturation: 1.28,
    contrast: 1.08,
    temperature: -.14,
    ambientOcclusion: 1.1,
    reflections: true,
    vignette: .46,
    skyZenith: vm.Vector3(.03, .015, .07),
    skyHorizon: vm.Vector3(.12, .04, .2),
    skyGround: vm.Vector3(.008, .006, .015),
    skySun: vm.Vector3(1.0, .4, 2.2),
    keyIntensity: 2.8,
    rimIntensity: 42,
    underGlow: 26,
  ),
  LabLook(
    name: 'Clean',
    tagline: 'Honest materials',
    toneMapping: LookToneMapping.pbrNeutral,
    exposure: 1.0,
    ambientOcclusion: .85,
    vignette: .12,
    skyZenith: vm.Vector3(.05, .055, .065),
    skyHorizon: vm.Vector3(.11, .12, .135),
    skyGround: vm.Vector3(.014, .015, .017),
    skySun: vm.Vector3(2.4, 2.35, 2.3),
    keyIntensity: 3.6,
    rimIntensity: 18,
    underGlow: 6,
  ),
];

/// What a camera shot orbits.
enum ShotTarget { carCenter, frontWheel, rearWheel, cabin }

/// A authored camera shot: yaw is relative to the car's nose, so shots keep
/// their intent no matter how the asset is oriented.
class CameraShot {
  const CameraShot(
    this.name,
    this.yawDegrees, {
    required this.polar,
    required this.distance,
    this.fovDegrees = 32,
    this.target = ShotTarget.carCenter,
    this.targetHeightLift = 0,
  });

  final String name;
  final double yawDegrees;
  final double polar;
  final double distance;
  final double fovDegrees;
  final ShotTarget target;
  final double targetHeightLift;
}

/// The shot list in the camera section of the Motion tab.
const List<CameraShot> cameraShots = <CameraShot>[
  CameraShot('Hero', 38, polar: .24, distance: 6.6, fovDegrees: 30),
  CameraShot('Nose', 2, polar: .10, distance: 5.6, fovDegrees: 26),
  CameraShot('Profile', 90, polar: .15, distance: 6.2, fovDegrees: 26),
  CameraShot('Tail', 182, polar: .18, distance: 5.8, fovDegrees: 28),
  CameraShot('Wheel', 62, polar: .07, distance: 2.1, fovDegrees: 42, target: ShotTarget.frontWheel),
  CameraShot('Cabin', -132, polar: .04, distance: .95, fovDegrees: 58, target: ShotTarget.cabin, targetHeightLift: .12),
];

/// Motion defaults.
const double maxWheelRpm = 640;

/// Wheel radius in meters, used for the km/h readout.
const double wheelRadiusMeters = .361;
