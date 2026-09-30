import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RevealEqualsButton extends StatefulWidget {
  const RevealEqualsButton({
    super.key,
    required this.onEquals,
    required this.onRevealChanged,
    required this.canReveal,
  });

  static const revealDelay = Duration(seconds: 2);

  final VoidCallback onEquals;
  final ValueChanged<bool> onRevealChanged;
  final bool canReveal;

  @override
  State<RevealEqualsButton> createState() => _RevealEqualsButtonState();
}

class _RevealEqualsButtonState extends State<RevealEqualsButton> {
  Timer? _timer;
  bool _pointerDown = false;
  bool _didReveal = false;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = true;
    _didReveal = false;
    _timer?.cancel();
    _timer = Timer(RevealEqualsButton.revealDelay, () {
      if (!mounted || !_pointerDown || !widget.canReveal) return;
      _didReveal = true;
      HapticFeedback.lightImpact();
      widget.onRevealChanged(true);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _finishPointer(evaluateShortPress: true);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _finishPointer(evaluateShortPress: false);
  }

  void _finishPointer({required bool evaluateShortPress}) {
    if (!_pointerDown) return;
    _pointerDown = false;
    _timer?.cancel();
    _timer = null;
    if (_didReveal) {
      _didReveal = false;
      widget.onRevealChanged(false);
    } else if (evaluateShortPress) {
      widget.onEquals();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_didReveal) {
      final onRevealChanged = widget.onRevealChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onRevealChanged(false);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '等于',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              '=',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
