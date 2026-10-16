/// A scriptable orbit camera for the Scene Lab demo.
library;

import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'scene_lab_math.dart';

/// Orbits a target with drag/scroll input like the engine's
/// `OrbitCameraController`, but exposes its azimuth/polar/distance state so
/// the demo can cut between authored shots and run a turntable.
///
/// The eye math mirrors the engine controller's convention exactly: view space
/// is left-handed (`+Z` into the screen), and the eye sits at
/// `pivot + (-sin(az), 0, -cos(az)) * horizontal + (0, sin(polar) * d, 0)`.
/// Copying that formula instead of deriving one keeps horizontal drag and
/// shot yaws consistent with the rest of the engine's cameras.
class LabOrbitController extends CameraController {
  LabOrbitController({
    required vm.Vector3 target,
    required double distance,
    required double azimuth,
    required double polar,
    this.minDistance = .5,
    this.maxDistance = 16,
    this.minPolar = -.05,
    this.maxPolar = 1.42,
    this.rotateSpeed = math.pi * 1.15,
    this.dollySpeed = .3,
    this.panSpeed = 1,
    this.scrollSensitivity = 1 / 120,
    super.smoothing = .3,
  }) : _target = target.clone(),
       _targetGoal = target.clone(),
       _distance = distance,
       _distanceGoal = distance,
       _azimuth = azimuth,
       _azimuthGoal = azimuth,
       _polar = polar.clamp(minPolar, maxPolar),
       _polarGoal = polar.clamp(minPolar, maxPolar);

  /// Closest and farthest the camera may dolly.
  double minDistance;
  double maxDistance;

  /// Elevation clamp (radians).
  double minPolar;
  double maxPolar;

  /// Radians of orbit per view-height of drag.
  double rotateSpeed;

  /// Proportional dolly rate.
  double dollySpeed;

  /// Pan distance as a multiple of the drag fraction times the orbit distance.
  double panSpeed;

  /// Dolly steps per unit of scroll delta.
  double scrollSensitivity;

  vm.Vector3 _target;
  vm.Vector3 _targetGoal;
  double _distance;
  double _distanceGoal;
  double _azimuth;
  double _azimuthGoal;
  double _polar;
  double _polarGoal;

  /// The point the camera orbits (its eased, current value).
  vm.Vector3 get target => _target.clone();

  set target(vm.Vector3 value) {
    _target = value.clone();
    _targetGoal = value.clone();
  }

  /// Distance from the target to the camera.
  double get distance => _distance;

  /// Current azimuth, in radians around world up.
  double get azimuth => _azimuth;

  /// Current elevation, in radians.
  double get polar => _polar;

  /// Rotates the orbit by [deltaAzimuth] and [deltaPolar] (radians).
  void orbitBy(double deltaAzimuth, double deltaPolar) {
    _azimuthGoal += deltaAzimuth;
    _polarGoal = (_polarGoal + deltaPolar).clamp(minPolar, maxPolar);
  }

  /// Dollies toward ([amount] > 0) or away from ([amount] < 0) the target.
  void dollyBy(double amount) {
    _distanceGoal = (_distanceGoal * math.exp(-amount * dollySpeed)).clamp(
      minDistance,
      maxDistance,
    );
  }

  /// Pans the target across the view by [fraction] of the viewport.
  void panBy(Offset fraction) {
    final forward = (_targetGoal - _eyeFor(_targetGoal, _distance))
        .normalized();
    final right = vm.Vector3(0, 1, 0).cross(forward)..normalize();
    final up = forward.cross(right)..normalize();
    final shift =
        (right * -fraction.dx + up * fraction.dy) * (_distance * panSpeed);
    _targetGoal += shift;
  }

  /// Adds a turntable rotation of [radiansPerSecond] for [deltaSeconds].
  void turntable(double deltaSeconds, double radiansPerSecond) =>
      orbitBy(radiansPerSecond * deltaSeconds, 0);

  /// Aims the camera at an authored shot, taking the shortest way around.
  ///
  /// [smoothingSeconds] temporarily overrides the settle time so showcase
  /// transitions can be quick cuts when a reel is running.
  void aimAt({
    vm.Vector3? target,
    double? azimuth,
    double? polar,
    double? distance,
    double? smoothingSeconds,
  }) {
    if (smoothingSeconds != null) smoothing = smoothingSeconds;
    if (azimuth != null) orbitBy(shortestTurn(_azimuthGoal, azimuth), 0);
    if (polar != null) orbitBy(0, polar - _polarGoal);
    if (distance != null && distance > 0) {
      dollyBy(-math.log(distance / _distanceGoal) / dollySpeed);
    }
    if (target != null) this.target = target;
  }

  @override
  void handleDragUpdate(Offset delta) {
    final k = rotateSpeed / viewportSize.height;
    orbitBy(-delta.dx * k, -delta.dy * k);
  }

  @override
  void handleSecondaryDragUpdate(Offset delta) =>
      panBy(Offset(delta.dx / viewportSize.height, delta.dy / viewportSize.height));

  @override
  void handleScaleUpdate(double scaleFactor, Offset focalDelta) {
    if (scaleFactor != 1.0) dollyBy(scaleFactor - 1.0);
    if (focalDelta != Offset.zero) {
      panBy(
        Offset(
          focalDelta.dx / viewportSize.height,
          focalDelta.dy / viewportSize.height,
        ),
      );
    }
  }

  @override
  void handleScroll(double scrollDelta) =>
      dollyBy(-scrollDelta * scrollSensitivity);

  @override
  void update(double deltaSeconds) {
    final r = smoothingResponse(clampDeltaSeconds(deltaSeconds));
    _azimuth += (_azimuthGoal - _azimuth) * r;
    _polar += (_polarGoal - _polar) * r;
    _distance += (_distanceGoal - _distance) * r;
    _target += (_targetGoal - _target) * r;
    node.lookAtFrom(_eyeFor(_target, _distance), _target);
  }

  // The camera eye for a pivot/azimuth/polar/distance, exactly as the
  // engine's OrbitCameraController computes it.
  vm.Vector3 _eyeFor(vm.Vector3 pivot, double distance) {
    final horizontal = math.cos(_polar) * distance;
    return pivot +
        vm.Vector3(-math.sin(_azimuth), 0, -math.cos(_azimuth)) * horizontal +
        vm.Vector3(0, math.sin(_polar) * distance, 0);
  }
}
