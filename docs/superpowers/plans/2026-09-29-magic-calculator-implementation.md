# Magic Calculator Android Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Android-first Flutter calculator with standard and scientific operations, normal deletable history, responsive portrait/landscape layouts, and a two-second hidden phone-number reveal gesture.

**Architecture:** A single `ChangeNotifier` controller owns the expression, result, history, angle mode, and memory-only secret. A focused recursive-descent evaluator handles standard precedence and scientific functions, while responsive widgets render portrait and landscape layouts without owning session state. The reveal timer stays in a reusable equals-button widget so short press and two-second hold behavior can be widget-tested with a fake clock.

**Tech Stack:** Flutter/Dart, Material 3 widgets, Dart `BigInt` and `double`, Flutter test framework, Android vector/adaptive icon resources.

**Spec:** `docs/superpowers/specs/2026-09-29-magic-calculator-design.md`

## Global Constraints

- Target Android only for the first release; do not add iOS-specific implementation work.
- Do not request network permission or persist the phone number or history to files, databases, logs, clipboard, analytics, or cloud services.
- Capture only the first 11-digit decimal operand followed by `+`, `−`, `×`, or `÷` in a performance session.
- Deleting visible history must not delete the independently held secret; long-pressing `AC` clears expression, history, and secret together.
- Short `=` evaluates normally; holding it for 2 seconds reveals the secret with one light haptic pulse, and releasing hides it immediately.
- Portrait exposes an expandable scientific panel; landscape shows basic and scientific keys together.
- Screen rotation must preserve expression, result, angle mode, history, and secret.
- Keep state management local to Flutter SDK APIs; add no routing, persistence, or general-purpose state-management package.

## Review Focus

- Very long integer input must remain responsive and exact rather than overflowing or crashing; Task 2 pins this with a 40-digit multiplication test.
- Incomplete or malformed expressions must show `错误`, create no history entry, and leave the secret unchanged; Tasks 2 and 3 pin this.
- Releasing near the two-second reveal threshold must produce exactly one outcome—evaluation or reveal, never both; Task 4 pins boundary timing.
- Deleting and clearing history while it is visible must update the panel immediately while preserving the secret; Tasks 3 and 6 pin this.
- Rotating while a reveal hold is in progress must cancel the pending reveal and keep the secret hidden while preserving all calculator state; Task 7 pins this.

---

### Task 1: Bootstrap the Android Flutter Application

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `lib/main.dart`
- Create: `lib/calculator/calculator_screen.dart`
- Create: `test/app_smoke_test.dart`
- Create: `android/` via Flutter project scaffolding
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: None.
- Produces: `MagicCalculatorApp extends StatelessWidget` and placeholder `CalculatorScreen extends StatefulWidget` used by all later widget tests.

- [ ] **Step 1: Scaffold the project and initialize source control**

Run `flutter create --platforms=android --org com.example --project-name magic_calculator .`, verify the existing `docs/` directory remains intact, then run `git init` because the starting directory is not a Git repository.

- [ ] **Step 2: Write the failing smoke test**

Create `test/app_smoke_test.dart` with `testWidgets('starts as a calculator without debug banner', ...)`; pump `MagicCalculatorApp`, then assert one `CalculatorScreen`, the display text `0`, and no debug banner.

- [ ] **Step 3: Run the smoke test to verify it fails**

Run: `flutter test test/app_smoke_test.dart`

Expected: FAIL because `MagicCalculatorApp` and the intended calculator screen do not exist yet.

- [ ] **Step 4: Implement the minimal app shell**

Create `MagicCalculatorApp` in `lib/main.dart` with Material 3, app title `计算器`, `debugShowCheckedModeBanner: false`, and `CalculatorScreen` as `home`. Create the temporary screen with a visible `0`. Confirm `AndroidManifest.xml` contains no `android.permission.INTERNET` entry and labels the app `计算器`.

- [ ] **Step 5: Verify the shell**

Run: `flutter test test/app_smoke_test.dart && flutter analyze`

Expected: PASS and `No issues found!`.

- [ ] **Step 6: Commit**

Run: `git add . && git commit -m "chore: scaffold Android calculator app"`

### Task 2: Expression Evaluator

**Files:**
- Create: `lib/calculator/expression_evaluator.dart`
- Create: `test/calculator/expression_evaluator_test.dart`

**Interfaces:**
- Consumes: None.
- Produces: `enum AngleMode { degrees, radians }`, `sealed class EvaluationResult`, `EvaluationSuccess(displayValue: String)`, `EvaluationFailure(message: String)`, and `ExpressionEvaluator.evaluate(String expression, {required AngleMode angleMode}) -> EvaluationResult`.

- [ ] **Step 1: Write failing precedence and exact-integer tests**

Add tests asserting `2+3×4 -> 14`, `(2+3)×4 -> 20`, `10−3−2 -> 5`, `20÷4 -> 5`, and `1234567890123456789012345678901234567890×9 -> 11111111011111111101111111110111111111010`.

- [ ] **Step 2: Run the focused tests and confirm failure**

Run: `flutter test test/calculator/expression_evaluator_test.dart --plain-name "basic expressions"`

Expected: FAIL because the evaluator is absent.

- [ ] **Step 3: Implement tokenization and recursive-descent precedence**

Implement `ExpressionEvaluator.evaluate(...)` with private tokenizer/parser types in the same file. Preserve an exact `BigInt` path for integer `+`, `−`, and `×`; promote to `double` for non-exact division, decimals, constants, and scientific functions. Accept display glyphs `×`, `÷`, `−` directly.

- [ ] **Step 4: Verify precedence and exact integers**

Run: `flutter test test/calculator/expression_evaluator_test.dart --plain-name "basic expressions"`

Expected: PASS.

- [ ] **Step 5: Write failing scientific and percent tests**

Add assertions for `√(9) -> 3`, `2^10 -> 1024`, `1÷(4) -> 0.25`, `sin(30) -> 0.5` in degrees, `sin(π÷2) -> 1` in radians, `ln(e) -> 1`, `log(100) -> 2`, `100+10% -> 110`, and `100×10% -> 10`.

- [ ] **Step 6: Implement scientific evaluation and formatting**

Add postfix percent with common calculator semantics: for `+`/`−`, a percent right operand is relative to the left operand; for `×`/`÷`, it is divided by 100. Implement `sin`, `cos`, `tan`, `ln`, `log`, `√`, `^`, reciprocal syntax, π/e, and degree/radian conversion. Format up to 12 significant digits, collapse floating noise near zero, and use scientific notation when necessary.

- [ ] **Step 7: Write and satisfy failure-mode tests**

Assert empty input, `2+`, `1..2`, mismatched parentheses, `1÷0`, `√(−1)`, `ln(0)`, and `tan(90)` in degree mode return `EvaluationFailure(message: '错误')` without throwing. Task 3 separately ensures pressing equals on an empty controller is a UI no-op.

- [ ] **Step 8: Verify evaluator coverage**

Run: `flutter test test/calculator/expression_evaluator_test.dart`

Expected: all evaluator tests PASS.

- [ ] **Step 9: Commit**

Run: `git add lib/calculator/expression_evaluator.dart test/calculator/expression_evaluator_test.dart && git commit -m "feat: add scientific expression evaluator"`

### Task 3: Calculator Session, Secret Capture, and History State

**Files:**
- Create: `lib/calculator/calculator_controller.dart`
- Create: `lib/calculator/calculation_history.dart`
- Create: `test/calculator/calculator_controller_test.dart`

**Interfaces:**
- Consumes: `ExpressionEvaluator.evaluate(...)`, `AngleMode`, and evaluation result types from Task 2.
- Produces: `HistoryEntry(id: int, expression: String, result: String)`; `CalculatorController extends ChangeNotifier` with getters `expression`, `display`, `angleMode`, `history`, `secretPhone`, `isSecretVisible`; methods `inputDigit`, `inputDecimalPoint`, `inputOperator`, `inputFunction`, `inputConstant`, `inputParenthesis`, `toggleSign`, `backspace`, `evaluate`, `clearCurrent`, `clearAll`, `toggleAngleMode`, `deleteHistory`, `clearHistory`, `useHistoryResult`, and `setSecretVisible`.

- [ ] **Step 1: Write failing input and evaluation state tests**

Test digit/operator/function entry, replacement of repeated binary operators, backspace, parentheses, angle-mode toggling, successful evaluation display, and pressing equals on an empty controller as a no-op. For malformed non-empty expressions, assert display becomes `错误`, history remains empty, and existing secret state is unchanged.

- [ ] **Step 2: Run the controller tests to verify failure**

Run: `flutter test test/calculator/calculator_controller_test.dart`

Expected: FAIL because the controller and history types are absent.

- [ ] **Step 3: Implement input and evaluation state**

Implement the declared controller API, keeping the editable display expression separate from the evaluator result. `evaluate()` adds exactly one history entry only on success and prepares the result for continued calculation.

- [ ] **Step 4: Write failing secret-capture tests**

Assert `13800138000` followed by each binary operator captures the string once; 10- and 12-digit operands do not; later 11-digit operands cannot overwrite it; short `clearCurrent()` preserves it; and `clearAll()` removes it.

- [ ] **Step 5: Implement memory-only secret capture**

Capture the raw initial operand before appending the first qualifying binary operator. Keep `secretPhone` out of `HistoryEntry`; production widgets may render the getter only while `isSecretVisible` is true.

- [ ] **Step 6: Write failing normal-history tests**

Assert the first successful expression containing `13800138000` is stored verbatim; selecting an entry restores its result; deleting one entry and clearing all entries update history immediately; both operations preserve `secretPhone`; `clearAll()` removes history and secret together.

- [ ] **Step 7: Implement `CalculationHistory` and controller delegation**

Use an in-memory ordered list with monotonically increasing integer IDs. Return an unmodifiable history view so widgets cannot mutate state without controller notification.

- [ ] **Step 8: Verify state behavior**

Run: `flutter test test/calculator/calculator_controller_test.dart`

Expected: all controller tests PASS.

- [ ] **Step 9: Commit**

Run: `git add lib/calculator/calculator_controller.dart lib/calculator/calculation_history.dart test/calculator/calculator_controller_test.dart && git commit -m "feat: add calculator session and history state"`

### Task 4: Two-Second Secret Reveal Controls

**Files:**
- Create: `lib/calculator/reveal_equals_button.dart`
- Create: `lib/calculator/calculator_button.dart`
- Create: `test/calculator/reveal_equals_button_test.dart`

**Interfaces:**
- Consumes: callbacks `VoidCallback onEquals`, `ValueChanged<bool> onRevealChanged`, and `bool canReveal` supplied by `CalculatorScreen`.
- Produces: `RevealEqualsButton` with constant `revealDelay = Duration(seconds: 2)`; `CalculatorButton` for consistent tap targets and semantics.

- [ ] **Step 1: Write failing gesture timing tests**

Use `tester.startGesture`, `tester.pump`, and release to assert: release at 1999 ms calls `onEquals` once and never reveals; reaching 2000 ms calls `onRevealChanged(true)` once and never calls `onEquals`; release after reveal calls `onRevealChanged(false)` once; `canReveal: false` never reveals.

- [ ] **Step 2: Run the timing tests to verify failure**

Run: `flutter test test/calculator/reveal_equals_button_test.dart`

Expected: FAIL because the reveal button is absent.

- [ ] **Step 3: Implement mutually exclusive tap/hold behavior**

Use pointer-down/up/cancel handling and one cancellable `Timer`. Trigger `HapticFeedback.lightImpact()` only when entering reveal state. Dispose the timer and force hidden state when the widget is removed.

- [ ] **Step 4: Verify gesture boundaries**

Run: `flutter test test/calculator/reveal_equals_button_test.dart`

Expected: all timing tests PASS with no pending timers.

- [ ] **Step 5: Commit**

Run: `git add lib/calculator/reveal_equals_button.dart lib/calculator/calculator_button.dart test/calculator/reveal_equals_button_test.dart && git commit -m "feat: add hidden reveal gesture"`

### Task 5: Responsive Basic and Scientific Keypads

**Files:**
- Create: `lib/calculator/calculator_keypad.dart`
- Modify: `lib/calculator/calculator_screen.dart`
- Create: `test/calculator/calculator_layout_test.dart`

**Interfaces:**
- Consumes: `CalculatorController`, `CalculatorButton`, and `RevealEqualsButton` from Tasks 3-4.
- Produces: `CalculatorKeypad(controller: CalculatorController, scientificExpanded: bool, onToggleScientific: VoidCallback)` and responsive `CalculatorScreen` owning one controller for its lifetime.

- [ ] **Step 1: Write failing portrait-layout tests**

At `400×800`, assert the display, basic digits/operators, history button, and scientific-toggle button are visible; scientific keys are absent until toggled; after toggle, keys `sin`, `cos`, `tan`, `ln`, `log`, `π`, `e`, `√`, `x²`, `xʸ`, `1/x`, parentheses, and `DEG`/`RAD` are available without losing the expression.

- [ ] **Step 2: Write failing landscape-layout tests**

At `800×400`, assert keys with `Key('scientific-keypad')` and `Key('basic-keypad')` are simultaneously visible and no expand action is required.

- [ ] **Step 3: Run the layout tests to verify failure**

Run: `flutter test test/calculator/calculator_layout_test.dart`

Expected: FAIL because the responsive keypad is absent.

- [ ] **Step 4: Implement responsive calculator UI**

Use `LayoutBuilder`/`MediaQuery.orientation`. Build portrait as display-over-keypad and landscape as display-left/keypad-right. Keep the controller above orientation branches, give all keys at least a 48×48 logical-pixel tap target, use `FittedBox` for long display values, and show the secret only in the display's small top line while `isSecretVisible` is true.

- [ ] **Step 5: Wire all buttons and long-press `AC`**

Map buttons only to the Task 3 controller API. Short `AC` calls `clearCurrent`; a deliberate long press calls `clearAll`. Wire the equals reveal callbacks to `evaluate()` and `setSecretVisible(...)`.

- [ ] **Step 6: Verify layouts and interactions**

Run: `flutter test test/calculator/calculator_layout_test.dart && flutter analyze`

Expected: tests PASS and analyzer reports no issues.

- [ ] **Step 7: Commit**

Run: `git add lib/calculator/calculator_keypad.dart lib/calculator/calculator_screen.dart test/calculator/calculator_layout_test.dart && git commit -m "feat: add responsive scientific calculator UI"`

### Task 6: Normal Android-Style History Panel

**Files:**
- Create: `lib/calculator/history_panel.dart`
- Modify: `lib/calculator/calculator_screen.dart`
- Create: `test/calculator/history_panel_test.dart`

**Interfaces:**
- Consumes: `List<HistoryEntry>` and history methods on `CalculatorController`.
- Produces: `HistoryPanel(controller: CalculatorController, onClose: VoidCallback)` with select, per-entry delete, clear-all, scroll, and empty-state behavior.

- [ ] **Step 1: Write failing history-panel tests**

Seed two entries including `13800138000+2`; open history and assert both expressions/results appear. Tap an entry and assert its result becomes the active expression. Delete the phone entry and assert it disappears immediately while `controller.secretPhone == '13800138000'`; clear all and assert the empty state while the secret still exists.

- [ ] **Step 2: Run the history tests to verify failure**

Run: `flutter test test/calculator/history_panel_test.dart`

Expected: FAIL because `HistoryPanel` is absent.

- [ ] **Step 3: Implement adaptive history presentation**

Use a modal/overlay panel in portrait and a side panel in landscape. Render newest entries first, provide explicit close, per-row delete, and clear-all controls, and call only controller history methods.

- [ ] **Step 4: Verify visible deletion and secret independence**

Run: `flutter test test/calculator/history_panel_test.dart`

Expected: all history-panel tests PASS.

- [ ] **Step 5: Commit**

Run: `git add lib/calculator/history_panel.dart lib/calculator/calculator_screen.dart test/calculator/history_panel_test.dart && git commit -m "feat: add deletable calculation history"`

### Task 7: Rotation Preservation and End-to-End Magic Flow

**Files:**
- Modify: `test/app_smoke_test.dart`
- Create: `test/magic_flow_test.dart`

**Interfaces:**
- Consumes: completed app UI and controller.
- Produces: regression coverage for the user-visible performance flow; no new production interface.

- [ ] **Step 1: Write the failing full-flow test**

Enter `13800138000+2=`, open history, delete the visible expression, close history, verify the number is absent from normal UI, hold `=` for 2 seconds, verify it appears only while held, release and verify it disappears, then long-press `AC` and verify a second reveal attempt shows nothing.

- [ ] **Step 2: Write the failing rotation test**

Create expression, history, degree/radian setting, and secret; begin holding `=` for less than 2 seconds; change the test surface from portrait to landscape. Assert expression, result, angle mode, history, and secret remain, but the pending reveal is canceled and the number is not displayed.

- [ ] **Step 3: Run end-to-end tests and fix only integration defects**

Run: `flutter test test/magic_flow_test.dart test/app_smoke_test.dart`

Expected: PASS. Make only the smallest production changes needed to satisfy these cross-component tests.

- [ ] **Step 4: Commit**

Run: `git add lib test && git commit -m "test: cover complete magic calculator flow"`

### Task 8: Calculator Launcher Icon and Release Verification

**Files:**
- Create: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Create: `android/app/src/main/res/mipmap-anydpi/ic_launcher.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- Modify: `android/app/src/main/res/values/colors.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Remove: generated placeholder launcher assets that conflict with the new `ic_launcher` resource

**Interfaces:**
- Consumes: Android project from Task 1.
- Produces: neutral calculator launcher icon and a verified Android debug APK.

- [ ] **Step 1: Add vector and adaptive icon resources**

Use a solid blue-gray background with a white rounded calculator body, display slot, and four simple button marks. Do not include magic, phone, text, wand, or sparkle imagery. Point manifest `android:icon` and `android:roundIcon` to the adaptive resource name with a legacy vector fallback.

- [ ] **Step 2: Verify Android resources and privacy constraints**

Run: `flutter build apk --debug`

Expected: build succeeds and creates `build/app/outputs/flutter-apk/app-debug.apk`.

Run: `rg -n "INTERNET|uses-permission|shared_preferences|sqflite|http:" android lib pubspec.yaml`

Expected: no network permission or persistence dependency; any unrelated Android template permission must be investigated and removed if unnecessary.

- [ ] **Step 3: Run the complete verification suite**

Run: `dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test`

Expected: formatting check succeeds, analyzer reports `No issues found!`, and all tests PASS.

- [ ] **Step 4: Perform Android manual acceptance**

Install the debug APK on an emulator or device. Verify portrait/landscape layouts, scientific panel, history deletion, haptic reveal, release-to-hide behavior, icon appearance, background/foreground session behavior, and long-press `AC` cleanup against the spec.

- [ ] **Step 5: Commit**

Run: `git add android lib test pubspec.yaml && git commit -m "feat: finish Android magic calculator"`
