import 'package:flutter_test/flutter_test.dart';
import 'package:magic_calculator/calculator/calculator_controller.dart';
import 'package:magic_calculator/calculator/expression_evaluator.dart';

void enter(CalculatorController controller, String digits) {
  for (final digit in digits.split('')) {
    controller.inputDigit(digit);
  }
}

void main() {
  group('calculator input and evaluation', () {
    test('builds and evaluates a standard expression', () {
      final controller = CalculatorController();
      enter(controller, '2');
      controller.inputOperator('+');
      enter(controller, '3');
      controller.inputOperator('×');
      enter(controller, '4');
      controller.evaluate();

      expect(controller.display, '14');
      expect(controller.history.single.expression, '2+3×4');
      expect(controller.history.single.result, '14');
    });

    test('empty equals is a no-op and malformed input adds no history', () {
      final controller = CalculatorController();
      controller.evaluate();
      expect(controller.display, '0');

      enter(controller, '2');
      controller.inputOperator('+');
      controller.evaluate();
      expect(controller.display, '错误');
      expect(controller.history, isEmpty);
    });

    test('toggles angle mode and replaces a repeated operator', () {
      final controller = CalculatorController();
      enter(controller, '2');
      controller.inputOperator('+');
      controller.inputOperator('×');
      enter(controller, '3');

      expect(controller.expression, '2×3');
      expect(controller.angleMode, AngleMode.degrees);
      controller.toggleAngleMode();
      expect(controller.angleMode, AngleMode.radians);
    });
  });

  group('secret capture', () {
    for (final operator in ['+', '−', '×', '÷']) {
      test('captures the first 11 digits before $operator', () {
        final controller = CalculatorController();
        enter(controller, '13800138000');
        controller.inputOperator(operator);
        expect(controller.secretPhone, '13800138000');
      });
    }

    test('rejects other lengths and never overwrites the first secret', () {
      final controller = CalculatorController();
      enter(controller, '1234567890');
      controller.inputOperator('+');
      expect(controller.secretPhone, isNull);

      controller.clearCurrent();
      enter(controller, '13800138000');
      controller.inputOperator('+');
      expect(controller.secretPhone, '13800138000');

      controller.clearCurrent();
      enter(controller, '13900139000');
      controller.inputOperator('×');
      expect(controller.secretPhone, '13800138000');
    });
  });

  test('normal history deletion preserves secret until full clear', () {
    final controller = CalculatorController();
    enter(controller, '13800138000');
    controller.inputOperator('+');
    enter(controller, '2');
    controller.evaluate();

    final entry = controller.history.single;
    expect(entry.expression, '13800138000+2');
    controller.deleteHistory(entry.id);
    expect(controller.history, isEmpty);
    expect(controller.secretPhone, '13800138000');

    controller.setSecretVisible(true);
    expect(controller.isSecretVisible, isTrue);
    controller.clearAll();
    expect(controller.secretPhone, isNull);
    expect(controller.history, isEmpty);
    expect(controller.display, '0');
  });
}
