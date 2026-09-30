import 'dart:math' as math;

enum AngleMode { degrees, radians }

sealed class EvaluationResult {
  const EvaluationResult();
}

final class EvaluationSuccess extends EvaluationResult {
  const EvaluationSuccess(this.displayValue);

  final String displayValue;
}

final class EvaluationFailure extends EvaluationResult {
  const EvaluationFailure(this.message);

  final String message;
}

class ExpressionEvaluator {
  const ExpressionEvaluator();

  EvaluationResult evaluate(String expression, {required AngleMode angleMode}) {
    try {
      final normalized = expression
          .replaceAll('-', '−')
          .replaceAll('*', '×')
          .replaceAll('/', '÷');
      final parser = _ExpressionParser(normalized, angleMode);
      final value = parser.parse().regularValue;
      return EvaluationSuccess(_formatValue(value));
    } on Object {
      return const EvaluationFailure('错误');
    }
  }

  String _formatValue(_CalcValue value) {
    if (value.exact case final exact?) {
      return exact.toString();
    }

    var number = value.decimal;
    if (!number.isFinite) {
      throw const FormatException();
    }
    if (number.abs() < 1e-12) {
      number = 0;
    }

    var text = number.toStringAsPrecision(12);
    if (text.contains('e')) {
      final parts = text.split('e');
      final mantissa = _trimFraction(parts.first);
      final exponent = int.parse(parts.last).toString();
      return '${mantissa}e$exponent';
    }
    return _trimFraction(text);
  }

  String _trimFraction(String value) {
    if (!value.contains('.')) {
      return value;
    }
    return value.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _ExpressionParser {
  _ExpressionParser(this.source, this.angleMode);

  final String source;
  final AngleMode angleMode;
  int position = 0;

  _CalcValue parse() {
    _skipSpaces();
    if (_isAtEnd) {
      throw const FormatException();
    }
    final result = _parseExpression();
    _skipSpaces();
    if (!_isAtEnd) {
      throw const FormatException();
    }
    return result;
  }

  _CalcValue _parseExpression() {
    var left = _parseTerm();
    while (true) {
      if (_consume('+')) {
        left = _add(left, _parseTerm());
      } else if (_consume('−')) {
        left = _subtract(left, _parseTerm());
      } else {
        return left;
      }
    }
  }

  _CalcValue _parseTerm() {
    var left = _parsePower();
    while (true) {
      if (_consume('×')) {
        left = _multiply(left, _parsePower());
      } else if (_consume('÷')) {
        left = _divide(left, _parsePower());
      } else {
        return left;
      }
    }
  }

  _CalcValue _parsePower() {
    final left = _parseUnary();
    if (_consume('^')) {
      return _power(left, _parsePower());
    }
    return left;
  }

  _CalcValue _parseUnary() {
    if (_consume('+')) {
      return _parseUnary();
    }
    if (_consume('−')) {
      return _parseUnary().negated;
    }
    if (_consume('√')) {
      return _applyFunction('sqrt', _parseFunctionArgument());
    }
    return _parsePostfix();
  }

  _CalcValue _parsePostfix() {
    var value = _parsePrimary();
    while (_consume('%')) {
      value = value.asPercent;
    }
    return value;
  }

  _CalcValue _parsePrimary() {
    _skipSpaces();
    if (_consume('(')) {
      final value = _parseExpression();
      _expect(')');
      return value;
    }
    if (_consume('π')) {
      return _CalcValue.decimal(math.pi);
    }

    final current = _current;
    if (current != null && (_isDigit(current) || current == '.')) {
      return _parseNumber();
    }
    if (current != null && _isLetter(current)) {
      final name = _parseIdentifier();
      if (name == 'e') {
        return _CalcValue.decimal(math.e);
      }
      return _applyFunction(name, _parseFunctionArgument());
    }
    throw const FormatException();
  }

  _CalcValue _parseFunctionArgument() {
    _expect('(');
    final value = _parseExpression();
    _expect(')');
    return value;
  }

  _CalcValue _parseNumber() {
    final start = position;
    var decimalPoints = 0;
    while (!_isAtEnd) {
      final character = source[position];
      if (_isDigit(character)) {
        position++;
      } else if (character == '.') {
        decimalPoints++;
        position++;
      } else {
        break;
      }
    }
    final token = source.substring(start, position);
    if (token == '.' || decimalPoints > 1) {
      throw const FormatException();
    }
    if (decimalPoints == 0) {
      return _CalcValue.exact(BigInt.parse(token));
    }
    return _CalcValue.decimal(double.parse(token));
  }

  String _parseIdentifier() {
    final start = position;
    while (!_isAtEnd && _isLetter(source[position])) {
      position++;
    }
    return source.substring(start, position);
  }

  _CalcValue _applyFunction(String name, _CalcValue argument) {
    final number = argument.regularValue.asDouble;
    switch (name) {
      case 'sin':
        return _CalcValue.decimal(math.sin(_toRadians(number)));
      case 'cos':
        return _CalcValue.decimal(math.cos(_toRadians(number)));
      case 'tan':
        final radians = _toRadians(number);
        if (math.cos(radians).abs() < 1e-12) {
          throw const FormatException();
        }
        return _CalcValue.decimal(math.tan(radians));
      case 'ln':
        if (number <= 0) throw const FormatException();
        return _CalcValue.decimal(math.log(number));
      case 'log':
        if (number <= 0) throw const FormatException();
        return _CalcValue.decimal(math.log(number) / math.ln10);
      case 'sqrt':
        if (number < 0) throw const FormatException();
        return _CalcValue.decimal(math.sqrt(number));
      default:
        throw const FormatException();
    }
  }

  double _toRadians(double value) {
    return angleMode == AngleMode.degrees ? value * math.pi / 180 : value;
  }

  _CalcValue _add(_CalcValue left, _CalcValue right) {
    if (right.isPercent) {
      return _CalcValue.decimal(
        left.regularValue.asDouble * (1 + right.asDouble / 100),
      );
    }
    final a = left.regularValue;
    final b = right.regularValue;
    if (a.exact != null && b.exact != null) {
      return _CalcValue.exact(a.exact! + b.exact!);
    }
    return _CalcValue.decimal(a.asDouble + b.asDouble);
  }

  _CalcValue _subtract(_CalcValue left, _CalcValue right) {
    if (right.isPercent) {
      return _CalcValue.decimal(
        left.regularValue.asDouble * (1 - right.asDouble / 100),
      );
    }
    final a = left.regularValue;
    final b = right.regularValue;
    if (a.exact != null && b.exact != null) {
      return _CalcValue.exact(a.exact! - b.exact!);
    }
    return _CalcValue.decimal(a.asDouble - b.asDouble);
  }

  _CalcValue _multiply(_CalcValue left, _CalcValue right) {
    final a = left.regularValue;
    final b = right.regularValue;
    if (a.exact != null && b.exact != null) {
      return _CalcValue.exact(a.exact! * b.exact!);
    }
    return _CalcValue.decimal(a.asDouble * b.asDouble);
  }

  _CalcValue _divide(_CalcValue left, _CalcValue right) {
    final a = left.regularValue;
    final b = right.regularValue;
    if (b.asDouble == 0) {
      throw const FormatException();
    }
    if (a.exact != null &&
        b.exact != null &&
        a.exact! % b.exact! == BigInt.zero) {
      return _CalcValue.exact(a.exact! ~/ b.exact!);
    }
    return _CalcValue.decimal(a.asDouble / b.asDouble);
  }

  _CalcValue _power(_CalcValue left, _CalcValue right) {
    final a = left.regularValue;
    final b = right.regularValue;
    if (a.exact != null && b.exact != null && b.exact! >= BigInt.zero) {
      final exponent = b.exact!.toInt();
      if (exponent <= 10000) {
        return _CalcValue.exact(a.exact!.pow(exponent));
      }
    }
    final result = math.pow(a.asDouble, b.asDouble).toDouble();
    if (!result.isFinite) throw const FormatException();
    return _CalcValue.decimal(result);
  }

  void _expect(String token) {
    if (!_consume(token)) {
      throw const FormatException();
    }
  }

  bool _consume(String token) {
    _skipSpaces();
    if (source.startsWith(token, position)) {
      position += token.length;
      return true;
    }
    return false;
  }

  void _skipSpaces() {
    while (!_isAtEnd && source[position].trim().isEmpty) {
      position++;
    }
  }

  bool _isDigit(String value) => RegExp(r'[0-9]').hasMatch(value);
  bool _isLetter(String value) => RegExp(r'[A-Za-z]').hasMatch(value);
  bool get _isAtEnd => position >= source.length;
  String? get _current => _isAtEnd ? null : source[position];
}

class _CalcValue {
  const _CalcValue._(this.exact, this.decimal, this.isPercent);

  factory _CalcValue.exact(BigInt value) =>
      _CalcValue._(value, value.toDouble(), false);
  factory _CalcValue.decimal(double value) => _CalcValue._(null, value, false);

  final BigInt? exact;
  final double decimal;
  final bool isPercent;

  double get asDouble => exact?.toDouble() ?? decimal;

  _CalcValue get asPercent => _CalcValue._(exact, decimal, true);

  _CalcValue get regularValue {
    if (!isPercent) return this;
    return _CalcValue.decimal(asDouble / 100);
  }

  _CalcValue get negated {
    if (exact case final value?) {
      return _CalcValue._(-value, -decimal, isPercent);
    }
    return _CalcValue._(null, -decimal, isPercent);
  }
}
