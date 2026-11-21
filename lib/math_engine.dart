
class CalculationRecord {
  final String expression;
  final String result;
  final String rawResult;

  const CalculationRecord({
    required this.expression,
    required this.result,
    required this.rawResult,
  });
}

class MathResult {
  final double? value;
  final String formatted;
  final String raw;
  final String? error;

  const MathResult._({
    this.value,
    required this.formatted,
    required this.raw,
    this.error,
  });

  factory MathResult.success(double value) {
    final double normalized = value == 0 ? 0.0 : value;
    return MathResult._(
      value: normalized,
      formatted: LocalMathEngine.formatNumber(normalized),
      raw: LocalMathEngine.toRawNumber(normalized),
    );
  }

  factory MathResult.error(String message) {
    return MathResult._(
      formatted: message,
      raw: '',
      error: message,
    );
  }

  bool get isError => error != null;
}

class LocalMathEngine {
  static MathResult evaluate(String rawExpression) {
    final String cleaned = rawExpression
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-');

    if (cleaned.isEmpty) {
      return MathResult.success(0);
    }

    try {
      final _RecursiveParser parser = _RecursiveParser(cleaned);
      final double result = parser.parse();
      if (result.isNaN || result.isInfinite) {
        return MathResult.error('خارج از محدوده');
      }
      return MathResult.success(result);
    } on FormatException catch (e) {
      return MathResult.error(e.message);
    } catch (_) {
      return MathResult.error('عبارت نامعتبر');
    }
  }

  static String evaluatePreview(String rawExpression) {
    String trimmed = rawExpression.trim();
    while (trimmed.isNotEmpty &&
        '+−-×*÷/.'.contains(trimmed[trimmed.length - 1])) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.isEmpty) return '';

    final bool hasOperation = trimmed.contains('+') ||
        trimmed.contains('×') ||
        trimmed.contains('÷') ||
        trimmed.contains('%') ||
        trimmed.substring(1).contains('−');
    if (!hasOperation) return '';

    final MathResult result = evaluate(trimmed);
    return result.isError ? '' : result.formatted;
  }

  static String toRawNumber(double value) {
    if (value == 0) return '0';
    final double cleaned = double.parse(value.toStringAsPrecision(12));
    if (cleaned.abs() >= 1e12 || (cleaned.abs() > 0 && cleaned.abs() < 1e-6)) {
      return cleaned
          .toStringAsExponential(5)
          .replaceAll(RegExp(r'\.?0+(?=e)'), '')
          .replaceFirst('-', '−');
    }

    String str = cleaned.toStringAsFixed(10);
    if (str.contains('.')) {
      str = str.replaceFirst(RegExp(r'0+$'), '');
      if (str.endsWith('.')) {
        str = str.substring(0, str.length - 1);
      }
    }
    return str.replaceFirst('-', '−');
  }

  static String formatNumber(double value) {
    if (value == 0) return '0';
    final String raw = toRawNumber(value);
    if (raw.contains('e') || raw.contains('E')) return raw;

    final bool isNeg = raw.startsWith('−') || raw.startsWith('-');
    final String unsigned = isNeg ? raw.substring(1) : raw;
    final List<String> parts = unsigned.split('.');
    final String withCommas = _addThousandsSeparators(parts[0]);
    final String formatted =
        parts.length > 1 ? '$withCommas.${parts[1]}' : withCommas;
    return isNeg ? '−$formatted' : formatted;
  }

  static String formatExpression(String raw) {
    if (raw.isEmpty) return '0';
    final String withCommas = raw.replaceAllMapped(
      RegExp(r'\d+(?:\.\d*)?(?:[eE][+-]?\d+)?'),
      (Match m) {
        final String token = m.group(0)!;
        if (token.contains('e') || token.contains('E')) return token;
        final List<String> parts = token.split('.');
        final String intPart = _addThousandsSeparators(parts[0]);
        return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
      },
    );

    final StringBuffer out = StringBuffer();
    for (int i = 0; i < withCommas.length; i++) {
      final String ch = withCommas[i];
      final bool isBinaryMinus = ch == '−' &&
          i > 0 &&
          !'+−×÷eE'.contains(withCommas[i - 1]);
      final bool isExponentSign = (ch == '+' || ch == '-') &&
          i > 0 &&
          (withCommas[i - 1] == 'e' || withCommas[i - 1] == 'E');

      if (!isExponentSign && (ch == '+' || ch == '×' || ch == '÷' || isBinaryMinus)) {
        out.write(' $ch ');
      } else {
        out.write(ch);
      }
    }
    return out.toString();
  }

  static String _addThousandsSeparators(String digits) {
    if (digits.length <= 3) return digits;
    final StringBuffer buf = StringBuffer();
    final int mod = digits.length % 3;
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (i - mod) % 3 == 0) {
        buf.write(',');
      }
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

class _ParsedVal {
  final double value;
  final bool isPercent;

  const _ParsedVal(this.value, this.isPercent);
}

class _RecursiveParser {
  final String _src;
  int _pos = 0;

  _RecursiveParser(this._src);

  bool get _isAtEnd => _pos >= _src.length;
  String get _peek => _src[_pos];
  String _advance() => _src[_pos++];

  bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  double parse() {
    final _ParsedVal result = _parseExpression();
    if (!_isAtEnd) {
      throw const FormatException('عبارت نامعتبر');
    }
    return result.value;
  }

  _ParsedVal _parseExpression() {
    _ParsedVal left = _parseTerm();
    while (!_isAtEnd && (_peek == '+' || _peek == '-')) {
      final String op = _advance();
      final _ParsedVal right = _parseTerm();
      final double rhs =
          right.isPercent ? (left.value * right.value) : right.value;
      final double next =
          op == '+' ? (left.value + rhs) : (left.value - rhs);
      left = _ParsedVal(next, false);
    }
    return left;
  }

  _ParsedVal _parseTerm() {
    _ParsedVal left = _parseUnary();
    while (!_isAtEnd && (_peek == '*' || _peek == '/')) {
      final String op = _advance();
      final _ParsedVal right = _parseUnary();
      if (op == '/') {
        if (right.value == 0) {
          throw const FormatException('تقسیم بر صفر مجاز نیست');
        }
        left = _ParsedVal(left.value / right.value, false);
      } else {
        left = _ParsedVal(left.value * right.value, false);
      }
    }
    return left;
  }

  _ParsedVal _parseUnary() {
    if (!_isAtEnd && _peek == '+') {
      _advance();
      return _parseUnary();
    }
    if (!_isAtEnd && _peek == '-') {
      _advance();
      final _ParsedVal val = _parseUnary();
      return _ParsedVal(-val.value, val.isPercent);
    }
    return _parsePrimary();
  }

  _ParsedVal _parsePrimary() {
    double val;
    if (!_isAtEnd && _peek == '(') {
      _advance();
      val = _parseExpression().value;
      if (_isAtEnd || _peek != ')') {
        throw const FormatException('پرانتز بسته نشده');
      }
      _advance();
    } else {
      val = _parseNumber();
    }

    bool isPercent = false;
    while (!_isAtEnd && _peek == '%') {
      _advance();
      val /= 100.0;
      isPercent = true;
    }
    return _ParsedVal(val, isPercent);
  }

  double _parseNumber() {
    final int start = _pos;
    bool hasDot = false;
    while (!_isAtEnd && (_isDigit(_peek) || (_peek == '.' && !hasDot))) {
      if (_peek == '.') hasDot = true;
      _advance();
    }

    if (!_isAtEnd && (_peek == 'e' || _peek == 'E')) {
      final int expStart = _pos;
      _advance();
      if (!_isAtEnd && (_peek == '+' || _peek == '-')) {
        _advance();
      }
      final int digitStart = _pos;
      while (!_isAtEnd && _isDigit(_peek)) {
        _advance();
      }
      if (_pos == digitStart) {
        _pos = expStart;
      }
    }

    if (_pos == start) {
      throw const FormatException('عدد نامعتبر');
    }
    return double.parse(_src.substring(start, _pos));
  }
}
