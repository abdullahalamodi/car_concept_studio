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
- Switching between the Car Concept and Commercial Refrigerator models from the top model bar.
- Exterior/interior camera presets, orbit/zoom controls, and AR handoff affordance.
- App-owned wheel information and a web bridge for the CarConcept `Headlight` emissive material.
- Seeking the refrigerator's authored door animation between closed and open endpoints with the Open doors / Close doors control.
- A visible capability summary for each selected model.

The interior button is a camera presentation, not a second model. The CarConcept asset includes a modeled interior. It has door/hood hierarchy and authored pivots but no ready-made glTF animation clips; its headlight interaction is material-based rather than animation-based.

## Asset attribution

CarConcept is from the Khronos glTF Sample Assets repository and is licensed CC BY 4.0. Keep the attribution when using it beyond local testing:

https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/CarConcept/README.md

Commercial Refrigerator is from the Khronos glTF Sample Assets repository and is licensed CC BY 4.0. Its source model credits Eric Chadwick and Sean Thomas:

https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/CommercialRefrigerator/README.md
