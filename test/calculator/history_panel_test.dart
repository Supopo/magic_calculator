import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_calculator/calculator/calculator_controller.dart';
import 'package:magic_calculator/calculator/calculator_screen.dart';

void enter(CalculatorController controller, String value) {
  for (final digit in value.split('')) {
    controller.inputDigit(digit);
  }
}

void main() {
  testWidgets('history can be deleted without deleting the secret', (
    tester,
  ) async {
    final controller = CalculatorController();
    addTearDown(controller.dispose);
    enter(controller, '13800138000');
    controller.inputOperator('+');
    enter(controller, '2');
    controller.evaluate();
    final entry = controller.history.single;

    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );
    await tester.tap(find.byKey(const Key('history-button')));
    await tester.pumpAndSettle();

    expect(find.text('13800138000+2'), findsOneWidget);
    expect(find.text('13800138002'), findsWidgets);

    await tester.tap(find.byKey(Key('delete-history-${entry.id}')));
    await tester.pumpAndSettle();
    expect(find.text('13800138000+2'), findsNothing);
    expect(controller.secretPhone, '13800138000');
    expect(find.text('暂无历史记录'), findsOneWidget);
  });

  testWidgets('clear history updates the visible panel immediately', (
    tester,
  ) async {
    final controller = CalculatorController();
    addTearDown(controller.dispose);
    enter(controller, '2');
    controller.inputOperator('+');
    enter(controller, '3');
    controller.evaluate();

    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );
    await tester.tap(find.byKey(const Key('history-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear-history')));
    await tester.pumpAndSettle();

    expect(controller.history, isEmpty);
    expect(find.text('暂无历史记录'), findsOneWidget);
  });
}
