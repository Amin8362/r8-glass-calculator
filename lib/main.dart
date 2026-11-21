import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'math_engine.dart';

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
  int _selectedMode = 0; // 0: عادی، 1: حل مسئله

  String _expression = '';
  String _lastEvaluatedExpression = '';
  String _preview = '';
  String? _errorText;
  bool _justEvaluated = false;

  final List<CalculationRecord> _history = [];

  bool _isOperator(String ch) =>
      ch == '+' || ch == '−' || ch == '×' || ch == '÷';

  void _onKeyPressed(String key) {
    setState(() {
      _errorText = null;

      if (key == 'AC') {
        _expression = '';
        _lastEvaluatedExpression = '';
        _preview = '';
        _justEvaluated = false;
        return;
      }

      if (key == '⌫') {
        if (_justEvaluated) {
          _lastEvaluatedExpression = '';
          _justEvaluated = false;
        }
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        _preview = LocalMathEngine.evaluatePreview(_expression);
        return;
      }

      if (key == '=') {
        _evaluateCurrent();
        return;
      }

      if (key == '±') {
        _toggleSign();
        _preview = LocalMathEngine.evaluatePreview(_expression);
        return;
      }

      if (key == '%') {
        if (_expression.isEmpty) return;
        final String last = _expression[_expression.length - 1];
        if (RegExp(r'[0-9]').hasMatch(last)) {
          _expression += '%';
          _justEvaluated = false;
          _preview = LocalMathEngine.evaluatePreview(_expression);
        }
        return;
      }

      if (_isOperator(key)) {
        _handleOperator(key);
        _preview = LocalMathEngine.evaluatePreview(_expression);
        return;
      }

      if (key == '.') {
        _handleDecimal();
        _preview = LocalMathEngine.evaluatePreview(_expression);
        return;
      }

      // اعداد ۰ تا ۹
      _handleDigit(key);
      _preview = LocalMathEngine.evaluatePreview(_expression);
    });
  }

  void _handleDigit(String digit) {
    if (_justEvaluated) {
      _expression = digit;
      _lastEvaluatedExpression = '';
      _justEvaluated = false;
      return;
    }

    final int tokenStart = _lastNumberTokenStart();
    final String currentToken = _expression.substring(tokenStart);
    if (currentToken == '0') {
      _expression = _expression.substring(0, tokenStart) + digit;
      return;
    }

    if (_expression.isNotEmpty &&
        _expression[_expression.length - 1] == '%') {
      _expression += '×$digit';
      return;
    }

    _expression += digit;
  }

  void _handleDecimal() {
    if (_justEvaluated) {
      _expression = '0.';
      _lastEvaluatedExpression = '';
      _justEvaluated = false;
      return;
    }

    if (_expression.isEmpty ||
        _isOperator(_expression[_expression.length - 1])) {
      _expression += '0.';
      return;
    }

    final String currentToken = _expression.substring(_lastNumberTokenStart());
    if (currentToken.contains('.') ||
        currentToken.contains('e') ||
        currentToken.contains('%')) {
      return;
    }

    _expression += '.';
  }

  void _handleOperator(String op) {
    if (_expression.isEmpty) {
      if (op == '−') {
        _expression = '−';
      }
      return;
    }

    _justEvaluated = false;
    _lastEvaluatedExpression = '';

    final String last = _expression[_expression.length - 1];
    if (_isOperator(last)) {
      if (_expression.length == 1 && last == '−' && op != '−') {
        return;
      }
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else if (last == '.') {
      _expression = '${_expression}0$op';
    } else {
      _expression += op;
    }
  }

  void _toggleSign() {
    if (_expression.isEmpty) return;
    _justEvaluated = false;
    _lastEvaluatedExpression = '';

    final int start = _lastNumberTokenStart();
    if (start >= _expression.length) return;

    if (start == 0) {
      _expression = '−$_expression';
      return;
    }

    final String prev = _expression[start - 1];
    if (prev == '−') {
      final bool isUnary =
          start - 1 == 0 || _isOperator(_expression[start - 2]);
      if (isUnary) {
        _expression =
            _expression.substring(0, start - 1) + _expression.substring(start);
      } else {
        _expression =
            '${_expression.substring(0, start - 1)}+${_expression.substring(start)}';
      }
    } else if (prev == '+') {
      _expression =
          '${_expression.substring(0, start - 1)}−${_expression.substring(start)}';
    } else {
      _expression =
          '${_expression.substring(0, start)}−${_expression.substring(start)}';
    }
  }

  int _lastNumberTokenStart() {
    int i = _expression.length - 1;
    while (i >= 0) {
      final String ch = _expression[i];
      if (RegExp(r'[0-9.%eE]').hasMatch(ch)) {
        i--;
      } else if ((ch == '+' || ch == '-') &&
          i > 0 &&
          (_expression[i - 1] == 'e' || _expression[i - 1] == 'E')) {
        i--;
      } else {
        break;
      }
    }
    return i + 1;
  }

  void _evaluateCurrent() {
    if (_expression.isEmpty) return;
    String toEval = _expression;
    while (toEval.isNotEmpty && _isOperator(toEval[toEval.length - 1])) {
      toEval = toEval.substring(0, toEval.length - 1);
    }
    if (toEval.isEmpty) return;

    final MathResult result = LocalMathEngine.evaluate(toEval);
    if (result.isError) {
      _errorText = result.error;
      _preview = '';
      return;
    }

    final String formattedExpr = LocalMathEngine.formatExpression(toEval);
    _lastEvaluatedExpression = formattedExpr;
    _history.insert(
      0,
      CalculationRecord(
        expression: formattedExpr,
        result: result.formatted,
        rawResult: result.raw,
      ),
    );
    if (_history.length > 50) {
      _history.removeLast();
    }

    _expression = result.raw;
    _preview = '';
    _justEvaluated = true;
  }

  void _showHistorySheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E1426),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x44FFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_history.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _history.clear());
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'پاک کردن',
                          style: TextStyle(color: Color(0xFFFCA5A5)),
                        ),
                      )
                    else
                      const SizedBox(width: 64),
                    const Text(
                      'تاریخچه محاسبات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'هنوز محاسبه‌ای ثبت نشده است',
                      style: TextStyle(color: Color(0x88E2E8F0)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Color(0x18FFFFFF),
                        height: 1,
                      ),
                      itemBuilder: (_, int index) {
                        final CalculationRecord item = _history[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          onTap: () {
                            setState(() {
                              _expression = item.rawResult;
                              _lastEvaluatedExpression = item.expression;
                              _preview = '';
                              _errorText = null;
                              _justEvaluated = true;
                            });
                            Navigator.pop(ctx);
                          },
                          title: Text(
                            item.expression,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0x99E2E8F0),
                            ),
                          ),
                          subtitle: Text(
                            '= ${item.result}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
        _GlassIconChip(
          icon: Icons.history_rounded,
          onTap: _showHistorySheet,
        ),
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
        _GlassIconChip(
          icon: Icons.tune_rounded,
          onTap: () => HapticFeedback.lightImpact(),
        ),
      ],
    );
  }

  Widget _buildDisplayCard() {
    final String formattedCurrent = LocalMathEngine.formatExpression(_expression);
    final String secondaryText = _justEvaluated
        ? _lastEvaluatedExpression
        : (_preview.isNotEmpty ? '= $_preview' : '');
    final String primaryText = _errorText ?? formattedCurrent;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_justEvaluated && secondaryText.isNotEmpty)
                    Text(
                      secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w400,
                        color: Color(0x99E2E8F0),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      primaryText,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: _errorText != null ? 28 : 50,
                        fontWeight: FontWeight.w600,
                        letterSpacing: _errorText != null ? 0 : -1.2,
                        color: _errorText != null
                            ? const Color(0xFFFCA5A5)
                            : Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (!_justEvaluated && secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xAA67E8F9),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                          child: _CalcGlassButton(
                            spec: spec,
                            onTap: () => _onKeyPressed(spec.label),
                          ),
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
  final VoidCallback onTap;

  const _CalcGlassButton({
    required this.spec,
    required this.onTap,
  });

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
      onTap: widget.onTap,
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
