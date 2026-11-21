
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF070A12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ModernCalculatorApp());
}

class ModernCalculatorApp extends StatelessWidget {
  const ModernCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF070A12),
      ),
      home: const CalculatorUiScreen(),
    );
  }
}

class CalculatorUiScreen extends StatefulWidget {
  const CalculatorUiScreen({super.key});

  @override
  State<CalculatorUiScreen> createState() => _CalculatorUiScreenState();
}

class _CalculatorUiScreenState extends State<CalculatorUiScreen> {
  // فقط برای نمایش تغییر ظاهری تب‌ها در پیش‌نمایش UI
  int _selectedMode = 0; // 0: عادی، 1: حل مسئله

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // پس‌زمینه تیره با گرادیان عمق‌دار
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1020),
                  Color(0xFF070A12),
                  Color(0xFF0D1426),
                ],
              ),
            ),
          ),

          // هاله نوری بالا راست (بسیار سبک بدون افت فریم)
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x556366F1),
                    Color(0x006366F1),
                  ],
                ),
              ),
            ),
          ),

          // هاله نوری پایین چپ
          Positioned(
            bottom: -110,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x4406B6D4),
                    Color(0x0006B6D4),
                  ],
                ),
              ),
            ),
          ),

          // محتوای اصلی صفحه
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 18),
                  Expanded(
                    flex: 4,
                    child: _buildDisplayCard(),
                  ),
                  const SizedBox(height: 14),
                  _buildVoiceActionPill(),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 7,
                    child: _buildGlassKeypad(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // دکمه تاریخچه (جایگاه آماده برای آینده)
        _GlassIconChip(
          icon: Icons.history_rounded,
          onTap: () => HapticFeedback.lightImpact(),
        ),

        // سوییچ حالت عادی و حل مسئله (فاز ۳)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModePill(
                label: 'عادی',
                icon: Icons.calculate_rounded,
                selected: _selectedMode == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMode = 0);
                },
              ),
              _ModePill(
                label: 'حل مسئله',
                icon: Icons.auto_awesome_rounded,
                selected: _selectedMode == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMode = 1);
                },
              ),
            ],
          ),
        ),

        // دکمه تنظیمات ظاهری
        _GlassIconChip(
          icon: Icons.tune_rounded,
          onTap: () => HapticFeedback.lightImpact(),
        ),
      ],
    );
  }

  Widget _buildDisplayCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1AFFFFFF),
                Color(0x0AFFFFFF),
              ],
            ),
            border: Border.all(color: const Color(0x24FFFFFF), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // برچسب وضعیت بالا
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1F06B6D4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4406B6D4)),
                    ),
                    child: Text(
                      _selectedMode == 0 ? 'STANDARD' : 'AI SOLVER',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF67E8F9),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: Color(0x66FFFFFF),
                  ),
                ],
              ),

              // ناحیه نمایش عبارت و نتیجه نمونه
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _selectedMode == 0
                        ? '12,450 + 380 × 2'
                        : '15% of 480,000',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color(0x99E2E8F0),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _selectedMode == 0 ? '13,210' : '72,000',
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.5,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // نوار آماده برای فاز ۲ (ورودی صوتی طبیعی)
  Widget _buildVoiceActionPill() {
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [
              Color(0x286366F1),
              Color(0x2206B6D4),
            ],
          ),
          border: Border.all(color: const Color(0x44818CF8), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFF67E8F9),
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'برای محاسبه صوتی نگه دارید...',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xCCE2E8F0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.auto_awesome_outlined,
              color: Color(0x99A5B4FC),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // صفحه کلید شیشه‌ای با یک لایه Blur واحد برای حفظ ۶۰/۱۲۰ فریم
  Widget _buildGlassKeypad() {
    final List<List<_KeySpec>> rows = [
      const [
        _KeySpec('AC', _KeyType.utility),
        _KeySpec('⌫', _KeyType.utility),
        _KeySpec('%', _KeyType.utility),
        _KeySpec('÷', _KeyType.operator),
      ],
      const [
        _KeySpec('7', _KeyType.number),
        _KeySpec('8', _KeyType.number),
        _KeySpec('9', _KeyType.number),
        _KeySpec('×', _KeyType.operator),
      ],
      const [
        _KeySpec('4', _KeyType.number),
        _KeySpec('5', _KeyType.number),
        _KeySpec('6', _KeyType.number),
        _KeySpec('−', _KeyType.operator),
      ],
      const [
        _KeySpec('1', _KeyType.number),
        _KeySpec('2', _KeyType.number),
        _KeySpec('3', _KeyType.number),
        _KeySpec('+', _KeyType.operator),
      ],
      const [
        _KeySpec('±', _KeyType.utility),
        _KeySpec('0', _KeyType.number),
        _KeySpec('.', _KeyType.number),
        _KeySpec('=', _KeyType.equals),
      ],
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x16FFFFFF),
                Color(0x09FFFFFF),
              ],
            ),
            border: Border.all(color: const Color(0x20FFFFFF), width: 1),
          ),
          child: Column(
            children: rows.map((row) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: row.map((spec) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _CalcGlassButton(spec: spec),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

enum _KeyType { number, utility, operator, equals }

class _KeySpec {
  final String label;
  final _KeyType type;

  const _KeySpec(this.label, this.type);
}

class _CalcGlassButton extends StatefulWidget {
  final _KeySpec spec;

  const _CalcGlassButton({required this.spec});

  @override
  State<_CalcGlassButton> createState() => _CalcGlassButtonState();
}

class _CalcGlassButtonState extends State<_CalcGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEquals = widget.spec.type == _KeyType.equals;
    final bool isOperator = widget.spec.type == _KeyType.operator;
    final bool isUtility = widget.spec.type == _KeyType.utility;

    final Color bgColor = isOperator
        ? const Color(0x2E6366F1)
        : isUtility
            ? const Color(0x1A94A3B8)
            : const Color(0x12FFFFFF);

    final Color borderColor = isEquals
        ? const Color(0x66A5F3FC)
        : isOperator
            ? const Color(0x55818CF8)
            : const Color(0x1FFFFFFF);

    final Color textColor = isEquals
        ? Colors.white
        : isOperator
            ? const Color(0xFFA5B4FC)
            : isUtility
                ? const Color(0xFF67E8F9)
                : const Color(0xFFF8FAFC);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isEquals ? null : bgColor,
            gradient: isEquals
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF06B6D4),
                    ],
                  )
                : null,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isEquals
                ? const [
                    BoxShadow(
                      color: Color(0x5506B6D4),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.spec.label,
            style: TextStyle(
              fontSize: isOperator || isEquals ? 28 : 23,
              fontWeight: isEquals ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? const Color(0x386366F1) : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0x66818CF8) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? const Color(0xFFA5B4FC) : const Color(0x88FFFFFF),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : const Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconChip({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x14FFFFFF),
          border: Border.all(color: const Color(0x20FFFFFF)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xCCE2E8F0)),
      ),
    );
  }
}
