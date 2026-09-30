import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_calculator/calculator/reveal_equals_button.dart';

Widget harness({
  required VoidCallback onEquals,
  required ValueChanged<bool> onRevealChanged,
  bool canReveal = true,
}) {
  return MaterialApp(
    home: Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: RevealEqualsButton(
          onEquals: onEquals,
          onRevealChanged: onRevealChanged,
          canReveal: canReveal,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('release before two seconds evaluates exactly once', (
    tester,
  ) async {
    var equalsCalls = 0;
    final reveals = <bool>[];
    await tester.pumpWidget(
      harness(onEquals: () => equalsCalls++, onRevealChanged: reveals.add),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('=')));
    await tester.pump(const Duration(milliseconds: 1999));
    await gesture.up();
    await tester.pump();

    expect(equalsCalls, 1);
    expect(reveals, isEmpty);
  });

  testWidgets('two-second hold reveals until release without evaluating', (
    tester,
  ) async {
    var equalsCalls = 0;
    final reveals = <bool>[];
    await tester.pumpWidget(
      harness(onEquals: () => equalsCalls++, onRevealChanged: reveals.add),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('=')));
    await tester.pump(const Duration(seconds: 2));
    expect(reveals, [true]);
    expect(equalsCalls, 0);

    await gesture.up();
    await tester.pump();
    expect(reveals, [true, false]);
    expect(equalsCalls, 0);
  });

  testWidgets('cannot reveal when no secret exists', (tester) async {
    final reveals = <bool>[];
    await tester.pumpWidget(
      harness(onEquals: () {}, onRevealChanged: reveals.add, canReveal: false),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('=')));
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    expect(reveals, isEmpty);
  });
}
