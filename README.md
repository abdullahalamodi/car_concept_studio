# Car Concept Studio — web prototype

Throwaway Flutter web spike for testing a real glTF material-variant workflow.

## Run

```bash
cd /Users/alamodi/Documents/Codex/2026-08-13/we-have-an-app-to-show/deployments/flutter-projects/examples/car_concept_studio
flutter run -d chrome
```

The release build is generated at `build/web` with:

```bash
flutter build web --release
```

## What this tests

- `model_viewer_plus: ^1.10.0` on Flutter 3.44.8 web.
- The local `assets/CarConcept.glb` file from Khronos glTF Sample Assets.
- Switching the three authored `KHR_materials_variants` paint names without changing the model file.
- Exterior/interior camera presets, orbit/zoom controls, and AR handoff affordance.
- App-owned wheel information and headlight state controls.
- A visible capability summary: three paint variants, full interior, door pivots, and zero embedded animation clips.

The interior button is a camera presentation, not a second model. The CarConcept asset includes a modeled interior. It has door/hood hierarchy and authored pivots but no ready-made glTF animation clips, so door motion is intentionally called out rather than faked here.

## Asset attribution

CarConcept is from the Khronos glTF Sample Assets repository and is licensed CC BY 4.0. Keep the attribution when using it beyond local testing:

https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/CarConcept/README.md
