import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_calculator/calculator/calculator_controller.dart';
import 'package:magic_calculator/calculator/calculator_screen.dart';
import 'package:magic_calculator/calculator/expression_evaluator.dart';
import 'package:magic_calculator/main.dart';

Future<void> tapText(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pump();
}

void main() {
  testWidgets('complete performance keeps a deleted phone available secretly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MagicCalculatorApp());

    for (final digit in '13800138000'.split('')) {
      await tapText(tester, digit);
    }
    await tapText(tester, '+');
    await tapText(tester, '2');
    await tapText(tester, '=');

    await tester.tap(find.byKey(const Key('history-button')));
    await tester.pumpAndSettle();
    expect(find.text('13800138000+2'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('close-history')));
    await tester.pumpAndSettle();
    expect(find.textContaining('13800138000'), findsNothing);

    final equals = find.text('=');
    final reveal = await tester.startGesture(tester.getCenter(equals));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('13800138000'), findsOneWidget);
    await reveal.up();
    await tester.pump();
    expect(find.text('13800138000'), findsNothing);

    await tester.longPress(find.text('AC'));
    await tester.pump();
    final secondReveal = await tester.startGesture(tester.getCenter(equals));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('13800138000'), findsNothing);
    await secondReveal.up();
  });

  testWidgets('rotation preserves session and cancels a pending reveal', (
    tester,
  ) async {
    final controller = CalculatorController();
    addTearDown(controller.dispose);
    for (final digit in '13800138000'.split('')) {
      controller.inputDigit(digit);
    }
    controller.inputOperator('+');
    controller.inputDigit('2');
    controller.evaluate();
    controller.toggleAngleMode();

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('=')));
    await tester.pump(const Duration(seconds: 1));
    await tester.binding.setSurfaceSize(const Size(900, 500));
    await tester.pumpAndSettle();

    expect(controller.display, '13800138002');
    expect(controller.history.single.expression, '13800138000+2');
    expect(controller.secretPhone, '13800138000');
    expect(controller.angleMode, AngleMode.radians);
    expect(controller.isSecretVisible, isFalse);
    expect(find.text('13800138000'), findsNothing);
    await gesture.up();
  });

  testWidgets('rotation while revealed hides the secret without an exception', (
    tester,
  ) async {
    final controller = CalculatorController();
    addTearDown(controller.dispose);
    for (final digit in '13800138000'.split('')) {
      controller.inputDigit(digit);
    }
    controller.inputOperator('+');

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('=')));
    await tester.pump(const Duration(seconds: 2));
    expect(controller.isSecretVisible, isTrue);

    await tester.binding.setSurfaceSize(const Size(900, 500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.isSecretVisible, isFalse);
    expect(find.text('13800138000'), findsNothing);
    await gesture.up();
  });
}
