class ChartTickPoint {
  final DateTime time;
  final double price;

  const ChartTickPoint({
    required this.time,
    required this.price,
  });
}

class ChartTickStore {
  static final Map<String, List<ChartTickPoint>> _ticks = {};

  static String _normalize(String symbol) {
    return symbol.toUpperCase().replaceAll('/', '').replaceAll(' ', '');
  }

  static void add(
    String symbol,
    double price, {
    DateTime? time,
  }) {
    if (!price.isFinite || price <= 0) {
      return;
    }

    final key = _normalize(symbol);
    final now = time ?? DateTime.now();

    final list = _ticks.putIfAbsent(
      key,
      () => <ChartTickPoint>[],
    );

    list.add(
      ChartTickPoint(
        time: now,
        price: price,
      ),
    );

    // Keep up to 3 hours of chart ticks.
    final cutoff = now.subtract(
      const Duration(hours: 3),
    );

    list.removeWhere(
      (tick) => tick.time.isBefore(cutoff),
    );

    // Additional memory safety.
    if (list.length > 20000) {
      list.removeRange(
        0,
        list.length - 20000,
      );
    }
  }

  static List<ChartTickPoint> forSymbol(
    String symbol,
  ) {
    final key = _normalize(symbol);

    return List<ChartTickPoint>.unmodifiable(
      _ticks[key] ?? const <ChartTickPoint>[],
    );
  }

  static int count(String symbol) {
    return forSymbol(symbol).length;
  }

  static void clear(String symbol) {
    _ticks.remove(
      _normalize(symbol),
    );
  }

  static void clearAll() {
    _ticks.clear();
  }
}
