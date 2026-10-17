import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chart_tick_store.dart';

class ChartMarketCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  const ChartMarketCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  bool get bullish => close >= open;
}

class ChartMarketSnapshot {
  final String symbol;
  final List<ChartMarketCandle> candles;
  final double price;

  const ChartMarketSnapshot({
    required this.symbol,
    required this.candles,
    required this.price,
  });

  double get changePercent {
    if (candles.length < 2 || candles.first.close == 0) return 0;

    return ((candles.last.close - candles.first.close) / candles.first.close) *
        100.0;
  }
}

class ChartMarketData {
  static final Map<String, List<ChartMarketCandle>> _historyCache = {};
  static final Map<String, DateTime> _historyLoadedAt = {};

  static String normalize(String symbol) {
    return symbol.toUpperCase().replaceAll('/', '').replaceAll(' ', '');
  }

  static Future<List<ChartMarketCandle>> history(
    String symbol, {
    int count = 160,
    bool force = false,
  }) async {
    final key = normalize(symbol);
    final loadedAt = _historyLoadedAt[key];

    if (!force &&
        _historyCache[key] != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(seconds: 20)) {
      return List<ChartMarketCandle>.from(_historyCache[key]!);
    }

    try {
      final uri = Uri.https(
        'bridge.sciool.net',
        '/history/$key',
        {'count': '$count'},
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return List<ChartMarketCandle>.from(
          _historyCache[key] ?? const [],
        );
      }

      final decoded = jsonDecode(response.body);

      final raw = decoded is Map && decoded['candles'] is List
          ? decoded['candles'] as List
          : const [];

      final result = <ChartMarketCandle>[];

      for (final item in raw) {
        if (item is! Map) continue;

        final timestamp = item['timestamp'];
        final open = item['open'];
        final high = item['high'];
        final low = item['low'];
        final close = item['close'];

        if (timestamp is num &&
            open is num &&
            high is num &&
            low is num &&
            close is num) {
          result.add(
            ChartMarketCandle(
              time: DateTime.fromMillisecondsSinceEpoch(
                timestamp.toInt() * 1000,
              ),
              open: open.toDouble(),
              high: high.toDouble(),
              low: low.toDouble(),
              close: close.toDouble(),
            ),
          );
        }
      }

      result.sort((a, b) => a.time.compareTo(b.time));

      _historyCache[key] = result;
      _historyLoadedAt[key] = DateTime.now();

      return List<ChartMarketCandle>.from(result);
    } catch (_) {
      return List<ChartMarketCandle>.from(
        _historyCache[key] ?? const [],
      );
    }
  }

  static Future<ChartMarketSnapshot> snapshot(
    String symbol, {
    int historyCount = 160,
  }) async {
    final key = normalize(symbol);

    await ChartTickStore.loadSymbol(key);

    final remote = await history(key, count: historyCount);

    final merged = <DateTime, ChartMarketCandle>{};

    for (final candle in remote) {
      merged[candle.time] = candle;
    }

    for (final candle in ChartTickStore.savedCandles(key)) {
      merged[candle.bucket] = ChartMarketCandle(
        time: candle.bucket,
        open: candle.open,
        high: candle.high,
        low: candle.low,
        close: candle.close,
      );
    }

    final ticks = ChartTickStore.forSymbol(key);
    final grouped = <DateTime, List<ChartTickPoint>>{};

    for (final tick in ticks) {
      final bucket = DateTime(
        tick.time.year,
        tick.time.month,
        tick.time.day,
        tick.time.hour,
        tick.time.minute,
      );

      grouped.putIfAbsent(bucket, () => <ChartTickPoint>[]).add(tick);
    }

    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) continue;

      double high = entry.value.first.price;
      double low = entry.value.first.price;

      for (final tick in entry.value) {
        if (tick.price > high) high = tick.price;
        if (tick.price < low) low = tick.price;
      }

      merged[entry.key] = ChartMarketCandle(
        time: entry.key,
        open: entry.value.first.price,
        high: high,
        low: low,
        close: entry.value.last.price,
      );
    }

    final candles = merged.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    final trimmed = candles.length > historyCount
        ? candles.sublist(candles.length - historyCount)
        : candles;

    double price = 0;

    if (ticks.isNotEmpty) {
      price = ticks.last.price;
    } else if (trimmed.isNotEmpty) {
      price = trimmed.last.close;
    }

    return ChartMarketSnapshot(
      symbol: key,
      candles: trimmed,
      price: price,
    );
  }
}
