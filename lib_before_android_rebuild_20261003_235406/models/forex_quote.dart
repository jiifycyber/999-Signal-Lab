class ForexQuote {
  final String symbol;
  final double price;
  final double open;
  final double high;
  final double low;
  final DateTime timestamp;

  const ForexQuote({
    required this.symbol,
    required this.price,
    required this.open,
    required this.high,
    required this.low,
    required this.timestamp,
  });

  double get change => price - open;

  double get changePercent => open == 0 ? 0 : ((price - open) / open) * 100;

  bool get bullish => price >= open;
}
