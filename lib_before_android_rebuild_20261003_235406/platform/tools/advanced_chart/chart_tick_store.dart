import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChartTickPoint {
  final DateTime time;
  final double price;

  const ChartTickPoint({
    required this.time,
    required this.price,
  });
}

class ChartCandleRecord {
  final DateTime bucket;
  final double open;
  final double high;
  final double low;
  final double close;

  const ChartCandleRecord({
    required this.bucket,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  Map<String, dynamic> toJson() {
    return {
      'bucket': bucket.millisecondsSinceEpoch,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
    };
  }

  static ChartCandleRecord? fromJson(
    Map<String, dynamic> json,
  ) {
    final bucket = json['bucket'];
    final open = json['open'];
    final high = json['high'];
    final low = json['low'];
    final close = json['close'];

    if (bucket is! num ||
        open is! num ||
        high is! num ||
        low is! num ||
        close is! num) {
      return null;
    }

    return ChartCandleRecord(
      bucket: DateTime.fromMillisecondsSinceEpoch(
        bucket.toInt(),
      ),
      open: open.toDouble(),
      high: high.toDouble(),
      low: low.toDouble(),
      close: close.toDouble(),
    );
  }
}

class ChartTickStore {
  static const String _storagePrefix = '999_chart_candles_v1_';

  static final Map<String, List<ChartTickPoint>> _ticks = {};

  static final Map<String, List<ChartCandleRecord>> _savedCandles = {};

  static final Set<String> _loadedSymbols = {};

  static SharedPreferences? _prefs;

  static String _normalize(String symbol) {
    return symbol.toUpperCase().replaceAll('/', '').replaceAll(' ', '');
  }

  static String _storageKey(String symbol) {
    return '$_storagePrefix${_normalize(symbol)}';
  }

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> loadSymbol(
    String symbol,
  ) async {
    await initialize();

    final key = _normalize(symbol);

    if (_loadedSymbols.contains(key)) {
      return;
    }

    _loadedSymbols.add(key);

    final raw = _prefs?.getString(
      _storageKey(key),
    );

    print(
      'CHART LOAD key=${_storageKey(key)} '
      'rawLength=${raw?.length ?? 0}',
    );

    if (raw == null || raw.isEmpty) {
      _savedCandles[key] = <ChartCandleRecord>[];
      return;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        _savedCandles[key] = <ChartCandleRecord>[];
        return;
      }

      final records = <ChartCandleRecord>[];

      for (final item in decoded) {
        if (item is Map) {
          final record = ChartCandleRecord.fromJson(
            Map<String, dynamic>.from(item),
          );

          if (record != null) {
            records.add(record);
          }
        }
      }

      records.sort(
        (a, b) => a.bucket.compareTo(b.bucket),
      );

      if (records.length > 120) {
        _savedCandles[key] = records.sublist(
          records.length - 120,
        );
      } else {
        _savedCandles[key] = records;
      }
    } catch (_) {
      _savedCandles[key] = <ChartCandleRecord>[];
    }
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

    final cutoff = now.subtract(
      const Duration(hours: 3),
    );

    list.removeWhere(
      (tick) => tick.time.isBefore(cutoff),
    );

    if (list.length > 20000) {
      list.removeRange(
        0,
        list.length - 20000,
      );
    }

    _updateCompletedCandles(
      key,
      now,
    );
  }

  static void _updateCompletedCandles(
    String key,
    DateTime now,
  ) {
    final ticks = _ticks[key];

    if (ticks == null || ticks.isEmpty) {
      return;
    }

    final currentBucket = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    final grouped = <DateTime, List<ChartTickPoint>>{};

    for (final tick in ticks) {
      final bucket = DateTime(
        tick.time.year,
        tick.time.month,
        tick.time.day,
        tick.time.hour,
        tick.time.minute,
      );

      if (!bucket.isBefore(currentBucket)) {
        continue;
      }

      grouped
          .putIfAbsent(
            bucket,
            () => <ChartTickPoint>[],
          )
          .add(tick);
    }

    if (grouped.isEmpty) {
      return;
    }

    final saved = _savedCandles.putIfAbsent(
      key,
      () => <ChartCandleRecord>[],
    );

    bool changed = false;

    for (final entry in grouped.entries) {
      if (saved.any(
        (candle) => candle.bucket == entry.key,
      )) {
        continue;
      }

      final minuteTicks = entry.value;

      if (minuteTicks.isEmpty) {
        continue;
      }

      double high = minuteTicks.first.price;
      double low = minuteTicks.first.price;

      for (final tick in minuteTicks) {
        if (tick.price > high) {
          high = tick.price;
        }

        if (tick.price < low) {
          low = tick.price;
        }
      }

      saved.add(
        ChartCandleRecord(
          bucket: entry.key,
          open: minuteTicks.first.price,
          high: high,
          low: low,
          close: minuteTicks.last.price,
        ),
      );

      changed = true;
    }

    if (!changed) {
      return;
    }

    saved.sort(
      (a, b) => a.bucket.compareTo(b.bucket),
    );

    if (saved.length > 120) {
      saved.removeRange(
        0,
        saved.length - 120,
      );
    }

    _persistCandles(key);
  }

  static Future<void> _persistCandles(
    String key,
  ) async {
    await initialize();

    final candles = _savedCandles[key] ?? const <ChartCandleRecord>[];

    final json = jsonEncode(
      candles
          .map(
            (candle) => candle.toJson(),
          )
          .toList(),
    );

    final savedOk = await _prefs?.setString(
      _storageKey(key),
      json,
    );

    print(
      'CHART SAVE key=${_storageKey(key)} '
      'candles=${candles.length} '
      'bytes=${json.length} '
      'ok=$savedOk',
    );
  }

  static Future<void> mergeCandles(
    String symbol,
    Iterable<ChartCandleRecord> incoming,
  ) async {
    await loadSymbol(symbol);

    final key = _normalize(symbol);
    final merged = <DateTime, ChartCandleRecord>{};

    for (final candle in _savedCandles[key] ?? const <ChartCandleRecord>[]) {
      merged[candle.bucket] = candle;
    }

    for (final candle in incoming) {
      if (!candle.open.isFinite ||
          !candle.high.isFinite ||
          !candle.low.isFinite ||
          !candle.close.isFinite ||
          candle.open <= 0 ||
          candle.high <= 0 ||
          candle.low <= 0 ||
          candle.close <= 0) {
        continue;
      }

      final bucket = DateTime(
        candle.bucket.year,
        candle.bucket.month,
        candle.bucket.day,
        candle.bucket.hour,
        candle.bucket.minute,
      );

      merged[bucket] = ChartCandleRecord(
        bucket: bucket,
        open: candle.open,
        high: candle.high,
        low: candle.low,
        close: candle.close,
      );
    }

    final result = merged.values.toList()
      ..sort(
        (a, b) => a.bucket.compareTo(b.bucket),
      );

    _savedCandles[key] =
        result.length > 120 ? result.sublist(result.length - 120) : result;

    await _persistCandles(key);
  }

  static List<ChartTickPoint> forSymbol(
    String symbol,
  ) {
    final key = _normalize(symbol);

    return List<ChartTickPoint>.unmodifiable(
      _ticks[key] ?? const <ChartTickPoint>[],
    );
  }

  static List<ChartCandleRecord> savedCandles(
    String symbol,
  ) {
    final key = _normalize(symbol);

    return List<ChartCandleRecord>.unmodifiable(
      _savedCandles[key] ?? const <ChartCandleRecord>[],
    );
  }

  static int count(String symbol) {
    return forSymbol(symbol).length;
  }

  static Future<void> clear(
    String symbol,
  ) async {
    await initialize();

    final key = _normalize(symbol);

    _ticks.remove(key);
    _savedCandles.remove(key);
    _loadedSymbols.remove(key);

    await _prefs?.remove(
      _storageKey(key),
    );
  }

  static Future<void> clearAll() async {
    await initialize();

    final keys = _prefs
            ?.getKeys()
            .where(
              (key) => key.startsWith(_storagePrefix),
            )
            .toList() ??
        <String>[];

    for (final key in keys) {
      await _prefs?.remove(key);
    }

    _ticks.clear();
    _savedCandles.clear();
    _loadedSymbols.clear();
  }
}
