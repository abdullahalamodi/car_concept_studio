import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() => runApp(const CarConceptStudioApp());

class PaintOption {
  const PaintOption(this.name, this.swatch, this.description);
  final String name;
  final Color swatch;
  final String description;
}

enum StudioModel { carConcept, commercialRefrigerator }

class ModelOption {
  const ModelOption(this.model, this.name, this.description, this.icon);
  final StudioModel model;
  final String name;
  final String description;
  final IconData icon;
}

const modelOptions = <ModelOption>[
  ModelOption(
    StudioModel.carConcept,
    'Car Concept',
    'Configuration demo',
    Icons.directions_car_filled_outlined,
  ),
  ModelOption(
    StudioModel.commercialRefrigerator,
    'Commercial Refrigerator',
    'Door animation demo',
    Icons.kitchen_outlined,
  ),
];

const paints = <PaintOption>[
  PaintOption('Carmine Candy', Color(0xffa61f2d), 'Deep red metallic'),
  PaintOption('Pearly Swirly', Color(0xffd7d9d7), 'White pearl finish'),
  PaintOption('Torched Graphite', Color(0xff34363b), 'Graphite metallic'),
];

class CarConceptStudioApp extends StatelessWidget {
  const CarConceptStudioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Car Concept Studio',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff0b0d10),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffd8ff4f),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const StudioPage(),
  );
}

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});
  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  PaintOption _paint = paints.first;
  StudioModel _model = StudioModel.carConcept;
  String _view = 'Exterior';
  String _lastAction = 'None';
  bool _headlightsOn = false;
  bool _doorsOpen = false;

  bool get _isRefrigerator => _model == StudioModel.commercialRefrigerator;

  ModelOption get _selectedModel => modelOptions.firstWhere(
    (option) => option.model == _model,
  );

  void _setPaint(PaintOption value) => setState(() {
    _paint = value;
    _lastAction = 'Paint changed';
  });

  void _setModel(StudioModel value) => setState(() {
    _model = value;
    _view = 'Exterior';
    _doorsOpen = false;
    _lastAction = value == StudioModel.commercialRefrigerator
        ? 'Commercial refrigerator selected'
        : 'Car concept selected';
  });

  void _setView(String value) => setState(() {
    _view = value;
    _lastAction = value == 'Interior' ? 'Interior reveal' : 'Exterior view';
  });

  void _toggleLights() => setState(() {
    _headlightsOn = !_headlightsOn;
    _lastAction = _headlightsOn
        ? 'Headlights turned on'
        : 'Headlights turned off';
  });

  void _toggleDoors() => setState(() {
    _doorsOpen = !_doorsOpen;
    _lastAction = _doorsOpen ? 'Doors opening' : 'Doors closing';
  });

  void _showWheels() {
    setState(() => _lastAction = 'Wheel information hotspot');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff171b20),
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Front wheel',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'This is an app-owned information hotspot; it does not replace the wheel mesh in the GLB.',
            ),
            SizedBox(height: 12),
            Text(
              '19” alloy · 245/40 R19 · performance road tire',
              style: TextStyle(color: Color(0xffaab2bd)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAr() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('AR handoff'),
      content: Text(
        'Selected configuration: ${_paint.name}. In production, resolve this backend paint ID to a prepared GLB/USDZ before opening native AR. AR is non-interactive in this spike.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 980;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 32,
                20,
                compact ? 16 : 32,
                32,
              ),
              sliver: SliverToBoxAdapter(
                child: compact
                    ? Column(
                        children: [
                          _viewer(),
                          const SizedBox(height: 18),
                          _controls(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _viewer()),
                          const SizedBox(width: 18),
                          Expanded(flex: 4, child: _controls()),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
      24,
      MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
      0,
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xffd8ff4f),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _selectedModel.icon,
                color: const Color(0xff12150d),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONCEPT STUDIO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                Text(
                  'MODEL INTERACTION LAB',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xff87909d),
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _badge('WEB SPIKE', const Color(0xffd8ff4f)),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showAr,
              tooltip: 'AR handoff',
              icon: const Icon(Icons.view_in_ar_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _modelSwitcher(),
      ],
    ),
  );

  Widget _modelSwitcher() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: const Color(0xff13171c),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xff252b33)),
    ),
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ACTIVE MODEL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Color(0xff65707d),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: modelOptions
                .map(
                  (option) => Expanded(
                    child: _modelButton(option),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );

  Widget _modelButton(ModelOption option) {
    final selected = option.model == _model;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => _setModel(option.model),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xffd8ff4f) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 17,
                color: selected
                    ? const Color(0xff11140d)
                    : const Color(0xffaab2bd),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? const Color(0xff11140d)
                            : const Color(0xffdce2e9),
                      ),
                    ),
                    Text(
                      option.description,
                      overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewer() {
    final interior = _view == 'Interior';
    return Container(
      height: 620,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xff13171c),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xff252b33)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey('${_paint.name}-$_view-$_headlightsOn'),
              id: 'car-concept-viewer',
              src: 'assets/CarConcept.glb',
              alt: 'Khronos Car Concept vehicle',
              variantName: _paint.name,
              cameraOrbit: interior ? '180deg 74deg 3.4m' : '25deg 75deg 5.6m',
              cameraTarget: interior ? '0m 1.05m 0m' : '0m 0.75m 0m',
              fieldOfView: '28deg',
              minCameraOrbit: 'auto auto 3m',
              maxCameraOrbit: 'auto auto 8m',
              cameraControls: true,
              autoRotate: !interior,
              autoRotateDelay: 1800,
              rotationPerSecond: '14deg',
              ar: true,
              arModes: const ['webxr', 'scene-viewer', 'quick-look'],
              backgroundColor: const Color(0xff13171c),
              shadowIntensity: 0.85,
              exposure: 0.92,
              innerModelViewerHtml: '''
              <div id="part-info" role="status">Wheel material picked · see wheel details</div>
            ''',
              relatedCss: '''
              #part-info {
                display: none;
                position: absolute;
                left: 16px;
                top: 52px;
                padding: 8px 10px;
                border-radius: 8px;
                color: #d8ff4f;
                background: rgba(17, 21, 26, .92);
                border: 1px solid #46522b;
                font: 700 11px Arial, sans-serif;
              }
              #part-info.visible { display: block; }
            ''',
              relatedJs:
                  '''
              const carViewer = document.querySelector('#car-concept-viewer');
              const partInfo = carViewer.querySelector('#part-info');
              carViewer.addEventListener('load', () => {
                const headlight = carViewer.model.getMaterialByName('Headlight');
                if (headlight) {
                  headlight.setEmissiveFactor('${_headlightsOn ? '#ffffff' : '#000000'}');
                  headlight.setEmissiveStrength(${_headlightsOn ? 3 : 0});
                }
              });
              carViewer.addEventListener('click', (event) => {
                const material = carViewer.materialFromPoint(event.clientX, event.clientY);
                if (material && /rim|tire|brake|disc/i.test(material.name)) {
                  partInfo.classList.add('visible');
                  window.setTimeout(() => partInfo.classList.remove('visible'), 2600);
                }
              });
            ''',
              debugLogging: false,
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: _label(
              interior ? 'INTERIOR REVEAL' : 'EXTERIOR CONFIGURATION',
            ),
          ),
          Positioned(
            bottom: 18,
            left: 18,
            right: 18,
            child: Row(
              children: [
                _label('LIVE  •  ${_paint.name.toUpperCase()}'),
                const Spacer(),
                Text(
                  'Drag to orbit  ·  Scroll to zoom',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() => Container(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
    decoration: BoxDecoration(
      color: const Color(0xff13171c),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xff252b33)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Configure your car',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
            _badge('DRAFT', const Color(0xff87909d)),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Every control maps to a capability exposed by the uploaded GLB.',
          style: TextStyle(color: Color(0xff87909d), fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 24),
        _section('01', 'PAINT VARIANTS', 'KHR_materials_variants'),
        const SizedBox(height: 12),
        ...paints.map(_paintTile),
        const SizedBox(height: 24),
        _section('02', 'VIEW & INTERACTION', 'App-owned actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            _viewChip('Exterior', Icons.directions_car_filled_outlined),
            const SizedBox(width: 8),
            _viewChip('Interior', Icons.airline_seat_recline_normal_outlined),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _action(
                Icons.lightbulb_outline,
                _headlightsOn ? 'Lights on' : 'Turn lights on',
                _toggleLights,
                active: _headlightsOn,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _action(
                Icons.tire_repair_outlined,
                'Wheel details',
                _showWheels,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xffd8ff4f),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last action  /  $_lastAction',
                style: const TextStyle(fontSize: 11, color: Color(0xffaab2bd)),
              ),
            ),
            const Icon(Icons.tune_rounded, size: 15, color: Color(0xff65707d)),
          ],
        ),
        const SizedBox(height: 22),
        _capabilities(),
        const SizedBox(height: 14),
        const Text(
          'Prototype note: CarConcept has door/hood hierarchy but no animation clips. An upload inspector should surface that distinction and ask the admin to add clips or bind a runtime interaction.',
          style: TextStyle(
            fontSize: 11,
            height: 1.45,
            color: Color(0xff87909d),
          ),
        ),
      ],
    ),
  );

  Widget _paintTile(PaintOption option) {
    final selected = option == _paint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _setPaint(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xff20262b) : const Color(0xff181c21),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xffd8ff4f)
                  : const Color(0xff252b33),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: option.swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .25),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff87909d),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xffd8ff4f),
                  size: 19,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewChip(String label, IconData icon) {
    final selected = _view == label;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _setView(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xffd8ff4f) : const Color(0xff181c21),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xffd8ff4f)
                  : const Color(0xff252b33),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? const Color(0xff11140d)
                    : const Color(0xffaab2bd),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xff11140d)
                      : const Color(0xffaab2bd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      foregroundColor: active
          ? const Color(0xffd8ff4f)
          : const Color(0xffaab2bd),
      side: BorderSide(
        color: active ? const Color(0xffd8ff4f) : const Color(0xff303741),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _capabilities() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xff0e1114),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 17,
              color: Color(0xffd8ff4f),
            ),
            const SizedBox(width: 8),
            const Text(
              'Detected model capabilities',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Text(
              'CarConcept.glb',
              style: TextStyle(fontSize: 10, color: Color(0xff65707d)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _tag('3 paint variants'),
            _tag('full interior'),
            _tag('door pivots'),
            _tag('0 clips'),
          ],
        ),
      ],
    ),
  );

  static Widget _section(String n, String title, String hint) => Row(
    children: [
      Text(
        n,
        style: const TextStyle(
          color: Color(0xffd8ff4f),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
      Text(
        hint,
        style: const TextStyle(fontSize: 10, color: Color(0xff65707d)),
      ),
    ],
  );
  static Widget _tag(String text) => Container(
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
  static Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: color,
      ),
    ),
  );
  static Widget _label(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xdd11151a),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xff303741)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: Color(0xffdce2e9),
      ),
    ),
  );
}
