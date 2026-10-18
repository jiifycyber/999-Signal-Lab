import '../models/forex_quote.dart';

class ScienceTickRecord {
  final String symbol;
  final double price;
  final DateTime timestamp;
  final bool isOtc;

  const ScienceTickRecord({
    required this.symbol,
    required this.price,
    required this.timestamp,
    required this.isOtc,
  });

  factory ScienceTickRecord.fromQuote(ForexQuote quote) {
    return ScienceTickRecord(
      symbol: quote.symbol,
      price: quote.price,
      timestamp: quote.timestamp,
      isOtc: quote.symbol.toUpperCase().endsWith('_OTC'),
    );
  }
}

class ScienceTickVault {
  static const Duration window = Duration(hours: 24);

  final Map<String, List<ScienceTickRecord>> _ticksBySymbol = {};

  void ingest(ForexQuote quote) {
    final tick = ScienceTickRecord.fromQuote(quote);
    final list =
        _ticksBySymbol.putIfAbsent(tick.symbol, () => <ScienceTickRecord>[]);
    list.add(tick);
    _pruneSymbol(tick.symbol, tick.timestamp);
  }

  void _pruneSymbol(String symbol, DateTime reference) {
    final list = _ticksBySymbol[symbol];
    if (list == null || list.isEmpty) return;
    final cutoff = reference.subtract(window);
    int firstKeep = 0;
    while (
        firstKeep < list.length && list[firstKeep].timestamp.isBefore(cutoff)) {
      firstKeep++;
    }
    if (firstKeep > 0) list.removeRange(0, firstKeep);
  }

  ScienceTickRecord? currentFor(String symbol) {
    final list = _ticksBySymbol[symbol];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  List<ScienceTickRecord> historicalFor(String symbol) {
    final list = _ticksBySymbol[symbol];
    if (list == null || list.length <= 1) return const [];
    return List<ScienceTickRecord>.unmodifiable(
        list.sublist(0, list.length - 1));
  }

  int tickCountFor(String symbol) => _ticksBySymbol[symbol]?.length ?? 0;

  int get totalTickCount =>
      _ticksBySymbol.values.fold(0, (sum, list) => sum + list.length);

  int get symbolCount => _ticksBySymbol.length;

  List<String> get symbols =>
      List<String>.unmodifiable(_ticksBySymbol.keys.toList()..sort());
}
