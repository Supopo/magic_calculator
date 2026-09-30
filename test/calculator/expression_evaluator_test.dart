import 'package:flutter_test/flutter_test.dart';
import 'package:magic_calculator/calculator/expression_evaluator.dart';

void main() {
  const evaluator = ExpressionEvaluator();

  String value(String expression, {AngleMode mode = AngleMode.degrees}) {
    final result = evaluator.evaluate(expression, angleMode: mode);
    expect(result, isA<EvaluationSuccess>());
    return (result as EvaluationSuccess).displayValue;
  }

  group('basic expressions', () {
    test('respects precedence and parentheses', () {
      expect(value('2+3×4'), '14');
      expect(value('(2+3)×4'), '20');
      expect(value('10−3−2'), '5');
      expect(value('20÷4'), '5');
    });

    test('keeps large integer multiplication exact', () {
      expect(
        value('1234567890123456789012345678901234567890×9'),
        '11111111011111111101111111110111111111010',
      );
    });
  });

  group('scientific expressions', () {
    test('evaluates functions, powers, and constants', () {
      expect(value('√(9)'), '3');
      expect(value('2^10'), '1024');
      expect(value('sin(30)'), '0.5');
      expect(value('sin(π÷2)', mode: AngleMode.radians), '1');
      expect(value('ln(e)'), '1');
      expect(value('log(100)'), '2');
    });

    test('uses familiar contextual percent behavior', () {
      expect(value('100+10%'), '110');
      expect(value('100×10%'), '10');
    });
  });

  test('invalid expressions return a calculator error', () {
    for (final expression in [
      '',
      '2+',
      '1..2',
      '(2+3',
      '1÷0',
      '√(−1)',
      'ln(0)',
      'tan(90)',
    ]) {
      expect(
        evaluator.evaluate(expression, angleMode: AngleMode.degrees),
        isA<EvaluationFailure>().having(
          (result) => result.message,
          'message',
          '错误',
        ),
        reason: expression,
      );
    }
  });
}
