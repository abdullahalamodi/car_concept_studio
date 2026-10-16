import 'package:flutter/material.dart';

class CarPart {
  const CarPart(this.id, this.title, this.description, this.details);

  final String id;
  final String title;
  final String description;
  final List<String> details;
}

const carParts = <CarPart>[
  CarPart(
    'wheels',
    'Wheels & tires',
    'Explore the sculpted rims, tire tread and brake assembly.',
    [
      'Detailed rim and tire meshes',
      'Separate brake disc and caliper materials',
      'Tire size and performance specifications are not supplied with this concept',
    ],
  ),
  CarPart(
    'doors',
    'Doors',
    'Inspect the door panels, handles, mirrors and side windows.',
    [
      'Separate left and right door assemblies',
      'Paint follows the selected finish',
      'This concept has no authored door-opening animation',
    ],
  ),
];

// Model-space anchors derived from the GLB wheel centers and door panels.
// model-viewer projects these points as the user orbits and zooms.
const carHotspotHtml = '''
<button class="part-hotspot" slot="hotspot-wheel-left" data-part="wheels"
  data-position="1.10m 0.384m 1.486m" data-normal="1 0 0"
  data-visibility-attribute="visible" aria-label="Left front wheel details">+
  <span>Wheels &amp; tires</span></button>
<button class="part-hotspot" slot="hotspot-wheel-right" data-part="wheels"
  data-position="-1.10m 0.384m 1.484m" data-normal="-1 0 0"
  data-visibility-attribute="visible" aria-label="Right front wheel details">+
  <span>Wheels &amp; tires</span></button>
<button class="part-hotspot" slot="hotspot-door-left" data-part="doors"
  data-position="1.08m 0.65m 0.16m" data-normal="1 0 0"
  data-visibility-attribute="visible" aria-label="Left door details">+
  <span>Door</span></button>
<button class="part-hotspot" slot="hotspot-door-right" data-part="doors"
  data-position="-1.08m 0.65m 0.16m" data-normal="-1 0 0"
  data-visibility-attribute="visible" aria-label="Right door details">+
  <span>Door</span></button>
''';

const carHotspotCss = '''
.part-hotspot {
  width: 44px; height: 44px; padding: 0; border-radius: 50%;
  border: 1px solid #d8ff4f; background: rgba(17,21,26,.94);
  color: #d8ff4f; font: 24px Arial,sans-serif; cursor: pointer;
  box-shadow: 0 0 0 5px rgba(216,255,79,.12);
  --min-hotspot-opacity: 0;
}
.part-hotspot:not([data-visible]) { visibility: hidden; pointer-events: none; }
.part-hotspot:focus-visible { outline: 3px solid white; outline-offset: 5px; }
.part-hotspot span {
  position: absolute; top: 48px; left: 50%; transform: translateX(-50%);
  padding: 6px 9px; border-radius: 7px; white-space: nowrap;
  background: rgba(17,21,26,.94); color: #fff; font: 600 11px Arial,sans-serif;
  pointer-events: none;
}
''';

class CarPartInfo extends StatelessWidget {
  const CarPartInfo({super.key, this.part});

  final CarPart? part;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  part?.title ?? 'All part information',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close details',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Text(
            'Car Concept · Model information',
            style: TextStyle(color: Color(0xffaab2bd)),
          ),
          const SizedBox(height: 20),
          for (final item in part == null ? carParts : [part!]) ...[
            if (part == null)
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 8),
            Text(item.description),
            const SizedBox(height: 12),
            for (final detail in item.details)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '•  $detail',
                  style: const TextStyle(color: Color(0xffaab2bd), height: 1.5),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    ),
  );
}
