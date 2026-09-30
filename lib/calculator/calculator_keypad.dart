import 'package:flutter/material.dart';
import 'package:magic_calculator/calculator/calculator_button.dart';
import 'package:magic_calculator/calculator/calculator_controller.dart';
import 'package:magic_calculator/calculator/expression_evaluator.dart';
import 'package:magic_calculator/calculator/reveal_equals_button.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    super.key,
    required this.controller,
    required this.showScientific,
  });

  final CalculatorController controller;
  final bool showScientific;

  @override
  Widget build(BuildContext context) {
    final basic = _basicKeypad(context);
    if (!showScientific) return basic;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: _scientificKeypad(context)),
        Expanded(flex: 5, child: basic),
      ],
    );
  }

  Widget _basicKeypad(BuildContext context) {
    return GridView.count(
      key: const Key('basic-keypad'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      crossAxisCount: 4,
      childAspectRatio: 1.15,
      children: [
        _key('AC', controller.clearCurrent, onLongPress: controller.clearAll),
        _key('⌫', controller.backspace),
        _key('%', controller.inputPercent),
        _key('÷', () => controller.inputOperator('÷'), accent: true),
        _key('7', () => controller.inputDigit('7')),
        _key('8', () => controller.inputDigit('8')),
        _key('9', () => controller.inputDigit('9')),
        _key('×', () => controller.inputOperator('×'), accent: true),
        _key('4', () => controller.inputDigit('4')),
        _key('5', () => controller.inputDigit('5')),
        _key('6', () => controller.inputDigit('6')),
        _key('−', () => controller.inputOperator('−'), accent: true),
        _key('1', () => controller.inputDigit('1')),
        _key('2', () => controller.inputDigit('2')),
        _key('3', () => controller.inputDigit('3')),
        _key('+', () => controller.inputOperator('+'), accent: true),
        _key('±', controller.toggleSign),
        _key('0', () => controller.inputDigit('0')),
        _key('.', controller.inputDecimalPoint),
        Padding(
          padding: const EdgeInsets.all(3),
          child: RevealEqualsButton(
            onEquals: controller.evaluate,
            onRevealChanged: controller.setSecretVisible,
            canReveal: controller.secretPhone != null,
          ),
        ),
      ],
    );
  }

  Widget _scientificKeypad(BuildContext context) {
    final modeLabel = controller.angleMode == AngleMode.degrees ? 'DEG' : 'RAD';
    return GridView.count(
      key: const Key('scientific-keypad'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      crossAxisCount: 3,
      childAspectRatio: 1.1,
      children: [
        _key(modeLabel, controller.toggleAngleMode, accent: true),
        _key('(', () => controller.inputParenthesis('(')),
        _key(')', () => controller.inputParenthesis(')')),
        _key('sin', () => controller.inputFunction('sin')),
        _key('cos', () => controller.inputFunction('cos')),
        _key('tan', () => controller.inputFunction('tan')),
        _key('ln', () => controller.inputFunction('ln')),
        _key('log', () => controller.inputFunction('log')),
        _key('√', () => controller.inputFunction('√')),
        _key('x²', controller.square),
        _key('xʸ', () => controller.inputOperator('^')),
        _key('1/x', controller.reciprocal),
        _key('π', () => controller.inputConstant('π')),
        _key('e', () => controller.inputConstant('e')),
      ],
    );
  }

  Widget _key(
    String label,
    VoidCallback onPressed, {
    VoidCallback? onLongPress,
    bool accent = false,
  }) {
    return Builder(
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return CalculatorButton(
          label: label,
          onPressed: onPressed,
          onLongPress: onLongPress,
          foregroundColor: accent ? colors.primary : null,
        );
      },
    );
  }
}
