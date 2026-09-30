import 'package:flutter/material.dart';
import 'package:magic_calculator/calculator/calculator_controller.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final CalculatorController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries = controller.history.reversed.toList(growable: false);
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Text('历史记录', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      key: const Key('clear-history'),
                      tooltip: '清空历史',
                      onPressed: entries.isEmpty
                          ? null
                          : controller.clearHistory,
                      icon: const Icon(Icons.delete_sweep_outlined),
                    ),
                    IconButton(
                      key: const Key('close-history'),
                      tooltip: '关闭',
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('暂无历史记录'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            onTap: () {
                              controller.useHistoryResult(entry);
                              onClose();
                            },
                            title: Text(
                              entry.expression,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              entry.result,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            trailing: IconButton(
                              key: Key('delete-history-${entry.id}'),
                              tooltip: '删除',
                              onPressed: () =>
                                  controller.deleteHistory(entry.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
