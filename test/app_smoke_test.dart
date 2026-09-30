import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_calculator/calculator/calculator_screen.dart';
import 'package:magic_calculator/main.dart';

void main() {
  testWidgets('starts as a calculator without debug banner', (tester) async {
    await tester.pumpWidget(const MagicCalculatorApp());

    expect(find.byType(CalculatorScreen), findsOneWidget);
    final display = tester.widget<Text>(
      find.byKey(const Key('calculator-display')),
    );
    expect(display.data, '0');
    expect(find.byType(Banner), findsNothing);
  });
}
