import 'package:flutter/foundation.dart';
import 'package:magic_calculator/calculator/calculation_history.dart';
import 'package:magic_calculator/calculator/expression_evaluator.dart';

class CalculatorController extends ChangeNotifier {
  CalculatorController({ExpressionEvaluator? evaluator})
    : _evaluator = evaluator ?? const ExpressionEvaluator();

  final ExpressionEvaluator _evaluator;
  final CalculationHistory _calculationHistory = CalculationHistory();

  String _expression = '';
  String _display = '0';
  AngleMode _angleMode = AngleMode.degrees;
  String? _secretPhone;
  bool _isSecretVisible = false;
  bool _justEvaluated = false;
  bool _isDisposed = false;

  String get expression => _expression;
  String get display => _display;
  AngleMode get angleMode => _angleMode;
  List<HistoryEntry> get history => _calculationHistory.entries;
  String? get secretPhone => _secretPhone;
  bool get isSecretVisible => _isSecretVisible;

  void inputDigit(String digit) {
    if (!RegExp(r'^\d$').hasMatch(digit)) return;
    _prepareForFreshInput();
    _expression += digit;
    _display = _expression;
    notifyListeners();
  }

  void inputDecimalPoint() {
    _prepareForFreshInput();
    final currentNumber = _expression.split(RegExp(r'[^0-9.]')).last;
    if (currentNumber.contains('.')) return;
    _expression += currentNumber.isEmpty ? '0.' : '.';
    _display = _expression;
    notifyListeners();
  }

  void inputOperator(String operator) {
    if (!const ['+', '−', '×', '÷', '^'].contains(operator)) return;
    if (_expression.isEmpty || _display == '错误') return;

    if (_secretPhone == null &&
        operator != '^' &&
        RegExp(r'^\d{11}$').hasMatch(_expression)) {
      _secretPhone = _expression;
    }

    if (RegExp(r'[+−×÷^]$').hasMatch(_expression)) {
      _expression = _expression.substring(0, _expression.length - 1) + operator;
    } else {
      _expression += operator;
    }
    _display = _expression;
    _justEvaluated = false;
    notifyListeners();
  }

  void inputFunction(String function) {
    if (!const ['sin', 'cos', 'tan', 'ln', 'log', '√'].contains(function)) {
      return;
    }
    _prepareForFreshInput();
    _expression += '$function(';
    _display = _expression;
    notifyListeners();
  }

  void inputConstant(String constant) {
    if (!const ['π', 'e'].contains(constant)) return;
    _prepareForFreshInput();
    _expression += constant;
    _display = _expression;
    notifyListeners();
  }

  void inputParenthesis(String parenthesis) {
    if (!const ['(', ')'].contains(parenthesis)) return;
    _prepareForFreshInput();
    _expression += parenthesis;
    _display = _expression;
    notifyListeners();
  }

  void inputPercent() {
    if (_expression.isEmpty || _display == '错误') return;
    _expression += '%';
    _display = _expression;
    _justEvaluated = false;
    notifyListeners();
  }

  void square() {
    if (_expression.isEmpty || _display == '错误') return;
    _expression = '($_expression)^2';
    _display = _expression;
    _justEvaluated = false;
    notifyListeners();
  }

  void reciprocal() {
    if (_expression.isEmpty || _display == '错误') return;
    _expression = '1÷($_expression)';
    _display = _expression;
    _justEvaluated = false;
    notifyListeners();
  }

  void toggleSign() {
    if (_expression.isEmpty || _display == '错误') return;
    if (_expression.startsWith('−')) {
      _expression = _expression.substring(1);
    } else {
      _expression = '−$_expression';
    }
    _display = _expression;
    _justEvaluated = false;
    notifyListeners();
  }

  void backspace() {
    if (_expression.isEmpty || _display == '错误') return;
    _expression = _expression.substring(0, _expression.length - 1);
    _display = _expression.isEmpty ? '0' : _expression;
    _justEvaluated = false;
    notifyListeners();
  }

  void evaluate() {
    if (_expression.isEmpty) return;
    final originalExpression = _expression;
    final result = _evaluator.evaluate(_expression, angleMode: _angleMode);
    switch (result) {
      case EvaluationSuccess(:final displayValue):
        _display = displayValue;
        _expression = displayValue;
        _calculationHistory.add(originalExpression, displayValue);
        _justEvaluated = true;
      case EvaluationFailure(:final message):
        _display = message;
        _justEvaluated = false;
    }
    notifyListeners();
  }

  void clearCurrent() {
    _expression = '';
    _display = '0';
    _isSecretVisible = false;
    _justEvaluated = false;
    notifyListeners();
  }

  void clearAll() {
    _expression = '';
    _display = '0';
    _angleMode = AngleMode.degrees;
    _secretPhone = null;
    _isSecretVisible = false;
    _justEvaluated = false;
    _calculationHistory.clear();
    notifyListeners();
  }

  void toggleAngleMode() {
    _angleMode = _angleMode == AngleMode.degrees
        ? AngleMode.radians
        : AngleMode.degrees;
    notifyListeners();
  }

  void deleteHistory(int id) {
    _calculationHistory.delete(id);
    notifyListeners();
  }

  void clearHistory() {
    _calculationHistory.clear();
    notifyListeners();
  }

  void useHistoryResult(HistoryEntry entry) {
    _expression = entry.result;
    _display = entry.result;
    _justEvaluated = true;
    notifyListeners();
  }

  void setSecretVisible(bool visible) {
    if (_isDisposed) return;
    final nextValue = visible && _secretPhone != null;
    if (_isSecretVisible == nextValue) return;
    _isSecretVisible = nextValue;
    notifyListeners();
  }

  void _prepareForFreshInput() {
    if (_justEvaluated || _display == '错误') {
      _expression = '';
      _display = '0';
      _justEvaluated = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
