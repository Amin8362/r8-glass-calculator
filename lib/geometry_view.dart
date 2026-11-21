import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'math_engine.dart';

enum _GeoShape {
  square,
  rectangle,
  circle,
  triangle,
  cube,
  box,
  sphere,
  cylinder,
}

class _ShapeMeta {
  final _GeoShape shape;
  final String title;
  final IconData icon;
  final bool is3D;
  final List<String> fields;
  final String formulaHint;

  const _ShapeMeta({
    required this.shape,
    required this.title,
    required this.icon,
    required this.is3D,
    required this.fields,
    required this.formulaHint,
  });
}

class _GeoOutput {
  final String primaryLabel;
  final String primaryFormatted;
  final String primaryRaw;
  final String secondaryLabel;
  final String secondaryFormatted;
  final String secondaryRaw;
  final String? error;

  const _GeoOutput({
    required this.primaryLabel,
    required this.primaryFormatted,
    required this.primaryRaw,
    required this.secondaryLabel,
    required this.secondaryFormatted,
    required this.secondaryRaw,
    this.error,
  });

  const _GeoOutput.error(String message)
      : primaryLabel = '',
        primaryFormatted = '',
        primaryRaw = '',
        secondaryLabel = '',
        secondaryFormatted = '',
        secondaryRaw = '',
        error = message;
}

class GeometryCalculatorView extends StatefulWidget {
  final ValueChanged<String> onSendToCalculator;
  final bool hapticsEnabled;

  const GeometryCalculatorView({
    super.key,
    required this.onSendToCalculator,
    required this.hapticsEnabled,
  });

  @override
  State<GeometryCalculatorView> createState() => _GeometryCalculatorViewState();
}

class _GeometryCalculatorViewState extends State<GeometryCalculatorView> {
  static const List<_ShapeMeta> _allShapes = [
    _ShapeMeta(
      shape: _GeoShape.square,
      title: 'مربع',
      icon: Icons.crop_square_rounded,
      is3D: false,
      fields: ['طول ضلع (a)'],
      formulaHint: 'مساحت: a²   •   محیط: 4a',
    ),
    _ShapeMeta(
      shape: _GeoShape.rectangle,
      title: 'مستطیل',
      icon: Icons.crop_16_9_rounded,
      is3D: false,
      fields: ['طول (l)', 'عرض (w)'],
      formulaHint: 'مساحت: l × w   •   محیط: 2(l + w)',
    ),
    _ShapeMeta(
      shape: _GeoShape.circle,
      title: 'دایره',
      icon: Icons.circle_outlined,
      is3D: false,
      fields: ['شعاع (r)'],
      formulaHint: 'مساحت: πr²   •   محیط: 2πr',
    ),
    _ShapeMeta(
      shape: _GeoShape.triangle,
      title: 'مثلث',
      icon: Icons.change_history_rounded,
      is3D: false,
      fields: ['ضلع اول (a)', 'ضلع دوم (b)', 'ضلع سوم (c)'],
      formulaHint: 'مساحت: فرمول هرون   •   محیط: a + b + c',
    ),
    _ShapeMeta(
      shape: _GeoShape.cube,
      title: 'مکعب',
      icon: Icons.view_in_ar_rounded,
      is3D: true,
      fields: ['طول یال (a)'],
      formulaHint: 'حجم: a³   •   مساحت کل: 6a²',
    ),
    _ShapeMeta(
      shape: _GeoShape.box,
      title: 'مکعب‌مستطیل',
      icon: Icons.inventory_2_outlined,
      is3D: true,
      fields: ['طول (l)', 'عرض (w)', 'ارتفاع (h)'],
      formulaHint: 'حجم: l × w × h   •   مساحت کل: 2(lw + lh + wh)',
    ),
    _ShapeMeta(
      shape: _GeoShape.sphere,
      title: 'کره',
      icon: Icons.public_rounded,
      is3D: true,
      fields: ['شعاع (r)'],
      formulaHint: 'حجم: (4/3)πr³   •   مساحت رویه: 4πr²',
    ),
    _ShapeMeta(
      shape: _GeoShape.cylinder,
      title: 'استوانه',
      icon: Icons.layers_rounded,
      is3D: true,
      fields: ['شعاع قاعده (r)', 'ارتفاع (h)'],
      formulaHint: 'حجم: πr²h   •   مساحت کل: 2πr(r + h)',
    ),
  ];

  bool _is3D = false;
  _GeoShape _selectedShape = _GeoShape.rectangle;

  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  _ShapeMeta get _currentMeta =>
      _allShapes.firstWhere((s) => s.shape == _selectedShape);

  List<_ShapeMeta> get _visibleShapes =>
      _allShapes.where((s) => s.is3D == _is3D).toList();

  void _triggerHaptic() {
    if (widget.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _clearInputs() {
    for (final TextEditingController c in _controllers) {
      c.clear();
    }
    setState(() {});
  }

  void _switchDimension(bool to3D) {
    if (_is3D == to3D) return;
    _triggerHaptic();
    setState(() {
      _is3D = to3D;
      _selectedShape = _visibleShapes.first.shape;
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
    });
  }

  void _selectShape(_GeoShape shape) {
    if (_selectedShape == shape) return;
    _triggerHaptic();
    setState(() {
      _selectedShape = shape;
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
    });
  }

  double? _parseInput(String raw) {
    String s = raw.trim();
    if (s.isEmpty) return null;

    const String persian = '۰۱۲۳۴۵۶۷۸۹';
    const String arabic = '٠١٢٣٤٥٦٧٨٩';
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(persian[i], '$i').replaceAll(arabic[i], '$i');
    }
    s = s.replaceAll('٫', '.').replaceAll('،', '.').replaceAll(',', '.');

    final double? val = double.tryParse(s);
    if (val == null || val.isNaN || val.isInfinite || val <= 0) {
      return null;
    }
    return val;
  }

  _GeoOutput? _compute() {
    final int count = _currentMeta.fields.length;
    final List<double> values = [];
    bool anyTyped = false;

    for (int i = 0; i < count; i++) {
      final String text = _controllers[i].text.trim();
      if (text.isNotEmpty) anyTyped = true;
      final double? v = _parseInput(text);
      if (v == null) {
        return anyTyped ? const _GeoOutput.error('مقادیر عددی مثبت وارد کنید') : null;
      }
      values.add(v);
    }

    double primary = 0;
    double secondary = 0;
    String pLabel = 'مساحت';
    String sLabel = 'محیط';

    switch (_selectedShape) {
      case _GeoShape.square:
        final double a = values[0];
        primary = a * a;
        secondary = 4 * a;
        break;
      case _GeoShape.rectangle:
        final double l = values[0];
        final double w = values[1];
        primary = l * w;
        secondary = 2 * (l + w);
        break;
      case _GeoShape.circle:
        final double r = values[0];
        primary = math.pi * r * r;
        secondary = 2 * math.pi * r;
        break;
      case _GeoShape.triangle:
        final double a = values[0];
        final double b = values[1];
        final double c = values[2];
        if (a + b <= c || a + c <= b || b + c <= a) {
          return const _GeoOutput.error('این سه ضلع مثلث تشکیل نمی‌دهند');
        }
        final double p = a + b + c;
        final double s = p / 2;
        primary = math.sqrt(s * (s - a) * (s - b) * (s - c));
        secondary = p;
        break;
      case _GeoShape.cube:
        final double a = values[0];
        pLabel = 'حجم';
        sLabel = 'مساحت کل';
        primary = a * a * a;
        secondary = 6 * a * a;
        break;
      case _GeoShape.box:
        final double l = values[0];
        final double w = values[1];
        final double h = values[2];
        pLabel = 'حجم';
        sLabel = 'مساحت کل';
        primary = l * w * h;
        secondary = 2 * (l * w + l * h + w * h);
        break;
      case _GeoShape.sphere:
        final double r = values[0];
        pLabel = 'حجم';
        sLabel = 'مساحت رویه';
        primary = (4 / 3) * math.pi * r * r * r;
        secondary = 4 * math.pi * r * r;
        break;
      case _GeoShape.cylinder:
        final double r = values[0];
        final double h = values[1];
        pLabel = 'حجم';
        sLabel = 'مساحت کل';
        primary = math.pi * r * r * h;
        secondary = 2 * math.pi * r * (r + h);
        break;
    }

    return _GeoOutput(
      primaryLabel: pLabel,
      primaryFormatted: LocalMathEngine.formatNumber(primary),
      primaryRaw: LocalMathEngine.toRawNumber(primary),
      secondaryLabel: sLabel,
      secondaryFormatted: LocalMathEngine.formatNumber(secondary),
      secondaryRaw: LocalMathEngine.toRawNumber(secondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _GeoOutput? output = _compute();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDimensionToggle(),
            const SizedBox(height: 14),
            _buildShapeSelector(),
            const SizedBox(height: 16),
            _buildInputGlassCard(),
            const SizedBox(height: 14),
            _buildResultGlassCard(output),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x20FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DimensionTab(
              label: 'دوبعدی (مساحت و محیط)',
              selected: !_is3D,
              onTap: () => _switchDimension(false),
            ),
          ),
          Expanded(
            child: _DimensionTab(
              label: 'سه‌بعدی (حجم و رویه)',
              selected: _is3D,
              onTap: () => _switchDimension(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeSelector() {
    return Row(
      children: _visibleShapes.map((_ShapeMeta meta) {
        final bool selected = meta.shape == _selectedShape;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _selectShape(meta.shape),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: selected
                      ? const Color(0x336366F1)
                      : const Color(0x12FFFFFF),
                  border: Border.all(
                    color: selected
                        ? const Color(0x8867E8F9)
                        : const Color(0x1FFFFFFF),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      meta.icon,
                      size: 22,
                      color: selected
                          ? const Color(0xFF67E8F9)
                          : const Color(0xAAFFFFFF),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? Colors.white
                            : const Color(0xBBE2E8F0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputGlassCard() {
    final List<String> fields = _currentMeta.fields;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1AFFFFFF),
                Color(0x0AFFFFFF),
              ],
            ),
            border: Border.all(color: const Color(0x24FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ابعاد ${_currentMeta.title}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _triggerHaptic();
                      _clearInputs();
                    },
                    child: const Text(
                      'پاک کردن',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF67E8F9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _currentMeta.formulaHint,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0x99A5B4FC),
                ),
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < fields.length; i++) ...[
                TextField(
                  controller: _controllers[i],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    labelText: fields[i],
                    labelStyle: const TextStyle(
                      color: Color(0xBBE2E8F0),
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: const Color(0x14FFFFFF),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0x24FFFFFF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0x9967E8F9)),
                    ),
                  ),
                ),
                if (i < fields.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultGlassCard(_GeoOutput? output) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x286366F1),
            Color(0x1E06B6D4),
          ],
        ),
        border: Border.all(color: const Color(0x44818CF8)),
      ),
      child: output == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'برای محاسبه لحظه‌ای، اندازه‌ها را وارد کنید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xBBE2E8F0),
                ),
              ),
            )
          : output.error != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    output.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFCA5A5),
                    ),
                  ),
                )
              : Column(
                  children: [
                    _ResultTile(
                      label: output.primaryLabel,
                      value: output.primaryFormatted,
                      onSend: () => widget.onSendToCalculator(output.primaryRaw),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0x26FFFFFF), height: 1),
                    ),
                    _ResultTile(
                      label: output.secondaryLabel,
                      value: output.secondaryFormatted,
                      onSend: () =>
                          widget.onSendToCalculator(output.secondaryRaw),
                    ),
                  ],
                ),
    );
  }
}

class _DimensionTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DimensionTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? const Color(0x3D6366F1) : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0x66818CF8) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : const Color(0x99E2E8F0),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onSend;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xBB67E8F9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: onSend,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x22FFFFFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.calculate_outlined, size: 16),
          label: const Text('ارسال', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
