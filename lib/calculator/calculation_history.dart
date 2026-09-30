class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
  });

  final int id;
  final String expression;
  final String result;
}

class CalculationHistory {
  final List<HistoryEntry> _entries = [];
  int _nextId = 0;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  HistoryEntry add(String expression, String result) {
    final entry = HistoryEntry(
      id: _nextId++,
      expression: expression,
      result: result,
    );
    _entries.add(entry);
    return entry;
  }

  void delete(int id) => _entries.removeWhere((entry) => entry.id == id);

  void clear() => _entries.clear();
}
