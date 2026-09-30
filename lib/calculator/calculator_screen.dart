import 'package:flutter/material.dart';
import 'package:magic_calculator/calculator/calculator_controller.dart';
import 'package:magic_calculator/calculator/calculator_keypad.dart';
import 'package:magic_calculator/calculator/history_panel.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, this.controller});

  final CalculatorController? controller;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final CalculatorController _controller;
  late final bool _ownsController;
  bool _scientificExpanded = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CalculatorController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final landscape = constraints.maxWidth > constraints.maxHeight;
                return landscape
                    ? _landscapeLayout(context)
                    : _portraitLayout(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _portraitLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 3, child: _display(context, showToggle: true)),
        if (_scientificExpanded)
          Expanded(
            flex: 3,
            child: CalculatorKeypad(
              controller: _controller,
              showScientific: true,
            ),
          )
        else
          Expanded(
            flex: 7,
            child: CalculatorKeypad(
              controller: _controller,
              showScientific: false,
            ),
          ),
      ],
    );
  }

  Widget _landscapeLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _display(context)),
        Expanded(
          flex: 7,
          child: CalculatorKeypad(
            controller: _controller,
            showScientific: true,
          ),
        ),
      ],
    );
  }

  Widget _display(BuildContext context, {bool showToggle = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('history-button'),
                tooltip: '历史记录',
                onPressed: _openHistory,
                icon: const Icon(Icons.history),
              ),
              const Spacer(),
              if (showToggle)
                IconButton(
                  key: const Key('scientific-toggle'),
                  tooltip: '科学计算',
                  onPressed: () {
                    setState(() => _scientificExpanded = !_scientificExpanded);
                  },
                  icon: Icon(
                    _scientificExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.science_outlined,
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _controller.isSecretVisible
                    ? (_controller.secretPhone ?? '')
                    : '',
                key: const Key('secret-display'),
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: Text(
                  _controller.display,
                  key: const Key('calculator-display'),
                  maxLines: 1,
                  style: textTheme.displayMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHistory() {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    if (landscape) {
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '关闭历史记录',
        barrierColor: Colors.black54,
        pageBuilder: (dialogContext, _, _) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: SizedBox(
                width: 380,
                height: double.infinity,
                child: HistoryPanel(
                  controller: _controller,
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: HistoryPanel(
            controller: _controller,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        );
      },
    );
  }
}
