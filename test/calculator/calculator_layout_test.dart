import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_calculator/main.dart';

Future<void> setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MagicCalculatorApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('portrait expands scientific keypad on demand', (tester) async {
    await setSurface(tester, const Size(400, 800));

    expect(find.byKey(const Key('basic-keypad')), findsOneWidget);
    expect(find.byKey(const Key('scientific-keypad')), findsNothing);
    expect(find.text('sin'), findsNothing);

    await tester.tap(find.byKey(const Key('scientific-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scientific-keypad')), findsOneWidget);
    for (final label in ['sin', 'cos', 'tan', 'ln', 'log', 'π', 'e', '√']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('landscape shows basic and scientific keypads together', (
    tester,
  ) async {
    await setSurface(tester, const Size(900, 500));

    expect(find.byKey(const Key('basic-keypad')), findsOneWidget);
    expect(find.byKey(const Key('scientific-keypad')), findsOneWidget);
    expect(find.text('sin'), findsOneWidget);
    expect(find.byKey(const Key('scientific-toggle')), findsNothing);
  });
}
