import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

class SmartCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  const SmartCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  bool get bullish => close >= open;
}

class SmartLevel {
  final String type;
  final double price;
  final int touches;
  final double strength;

  const SmartLevel({
    required this.type,
    required this.price,
    required this.touches,
    required this.strength,
  });
}

class SmartTimeframeSummary {
  final String timeframe;
  final String trend;
  final String structure;
  final String momentum;
  final String bias;
  final double score;

  const SmartTimeframeSummary({
    required this.timeframe,
    required this.trend,
    required this.structure,
    required this.momentum,
    required this.bias,
    required this.score,
  });
}

class SmartAnalysisSnapshot {
  final String symbol;
  final List<SmartCandle> candles;

  final String trend;
  final String structure;
  final String momentum;
  final String bias;

  final double ema9;
  final double ema21;
  final double rsi;
  final double atr;

  final double support;
  final double resistance;

  final List<SmartLevel> levels;
  final Map<String, double> fibonacci;

  final String pattern;
  final String patternDirection;
  final double patternConfidence;

  final String breakoutState;
  final double breakoutScore;

  final double liquidityAbove;
  final double liquidityBelow;
  final String liquidityState;

  final int bullishFvgCount;
  final int bearishFvgCount;
  final String orderBlockBias;

  final double trendScore;
  final double structureScore;
  final double momentumScore;
  final double patternScore;
  final double liquidityScore;
  final double mtfScore;
  final double confluence;

  final Map<String, SmartTimeframeSummary> timeframes;

  const SmartAnalysisSnapshot({
    required this.symbol,
    required this.candles,
    required this.trend,
    required this.structure,
    required this.momentum,
    required this.bias,
    required this.ema9,
    required this.ema21,
    required this.rsi,
    required this.atr,
    required this.support,
    required this.resistance,
    required this.levels,
    required this.fibonacci,
    required this.pattern,
    required this.patternDirection,
    required this.patternConfidence,
    required this.breakoutState,
    required this.breakoutScore,
    required this.liquidityAbove,
    required this.liquidityBelow,
    required this.liquidityState,
    required this.bullishFvgCount,
    required this.bearishFvgCount,
    required this.orderBlockBias,
    required this.trendScore,
    required this.structureScore,
    required this.momentumScore,
    required this.patternScore,
    required this.liquidityScore,
    required this.mtfScore,
    required this.confluence,
    required this.timeframes,
  });
}

class SmartAnalysisEngine {
  static Future<SmartAnalysisSnapshot> load(
    String symbol, {
    int count = 120,
  }) async {
    final normalized = symbol
        .toUpperCase()
        .replaceAll('/', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');

    final uri = Uri.https(
      'bridge.sciool.net',
      '/history/$normalized',
      {'count': '$count'},
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception(
        'History server returned ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid history response');
    }

    final raw = json['candles'];

    if (raw is! List) {
      throw Exception('No candle list returned');
    }

    final candles = <SmartCandle>[];

    for (final item in raw) {
      if (item is! Map) continue;

      final timestamp = _number(item['timestamp']);
      final open = _number(item['open']);
      final high = _number(item['high']);
      final low = _number(item['low']);
      final close = _number(item['close']);

      if (timestamp == null ||
          open == null ||
          high == null ||
          low == null ||
          close == null) {
        continue;
      }

      candles.add(
        SmartCandle(
          time: DateTime.fromMillisecondsSinceEpoch(
            (timestamp * 1000).round(),
          ),
          open: open,
          high: high,
          low: low,
          close: close,
        ),
      );
    }

    candles.sort(
      (a, b) => a.time.compareTo(b.time),
    );

    if (candles.length < 10) {
      throw Exception(
        'Only ${candles.length} candles available',
      );
    }

    return analyze(
      normalized,
      candles,
    );
  }

  static SmartAnalysisSnapshot analyze(
    String symbol,
    List<SmartCandle> candles,
  ) {
    final base = _analyze(candles);

    final timeframes = <String, SmartTimeframeSummary>{};

    void addTf(
      String label,
      List<SmartCandle> source,
    ) {
      if (source.length < 5) return;

      final result = _analyze(source);

      timeframes[label] = SmartTimeframeSummary(
        timeframe: label,
        trend: result.trend,
        structure: result.structure,
        momentum: result.momentum,
        bias: result.bias,
        score: result.directionScore.abs(),
      );
    }

    addTf('M1', candles);
    addTf('M5', _aggregate(candles, 5));
    addTf('M15', _aggregate(candles, 15));
    addTf('H1', _aggregate(candles, 60));

    double mtfTotal = 0;

    for (final tf in timeframes.values) {
      mtfTotal += tf.score;
    }

    final mtfScore = timeframes.isEmpty ? 0.0 : mtfTotal / timeframes.length;

    final confluence = (base.trendScore +
            base.structureScore +
            base.momentumScore +
            base.patternScore +
            base.liquidityScore +
            mtfScore) /
        6;

    var bull = 0;
    var bear = 0;

    void vote(String text) {
      final upper = text.toUpperCase();

      if (upper.contains('BULL')) bull++;
      if (upper.contains('BEAR')) bear++;
    }

    vote(base.trend);
    vote(base.structure);
    vote(base.momentum);
    vote(base.patternDirection);
    vote(base.breakoutState);

    for (final tf in timeframes.values) {
      vote(tf.bias);
    }

    final bias = bull > bear
        ? confluence >= 75
            ? 'STRONG BULLISH'
            : 'BULLISH'
        : bear > bull
            ? confluence >= 75
                ? 'STRONG BEARISH'
                : 'BEARISH'
            : 'NEUTRAL';

    return SmartAnalysisSnapshot(
      symbol: symbol,
      candles: List.unmodifiable(candles),
      trend: base.trend,
      structure: base.structure,
      momentum: base.momentum,
      bias: bias,
      ema9: base.ema9,
      ema21: base.ema21,
      rsi: base.rsi,
      atr: base.atr,
      support: base.support,
      resistance: base.resistance,
      levels: base.levels,
      fibonacci: base.fibonacci,
      pattern: base.pattern,
      patternDirection: base.patternDirection,
      patternConfidence: base.patternConfidence,
      breakoutState: base.breakoutState,
      breakoutScore: base.breakoutScore,
      liquidityAbove: base.resistance,
      liquidityBelow: base.support,
      liquidityState: base.liquidityState,
      bullishFvgCount: base.bullishFvgCount,
      bearishFvgCount: base.bearishFvgCount,
      orderBlockBias: base.orderBlockBias,
      trendScore: base.trendScore,
      structureScore: base.structureScore,
      momentumScore: base.momentumScore,
      patternScore: base.patternScore,
      liquidityScore: base.liquidityScore,
      mtfScore: mtfScore.clamp(0.0, 100.0).toDouble(),
      confluence: confluence.clamp(0.0, 100.0).toDouble(),
      timeframes: Map.unmodifiable(timeframes),
    );
  }

  static _Core _analyze(
    List<SmartCandle> candles,
  ) {
    final closes = candles.map((c) => c.close).toList();

    final ema9 = _ema(closes, 9);
    final ema21 = _ema(closes, 21);
    final rsi = _rsi(closes, 14);
    final atr = _atr(candles, 14);

    final latest = candles.last;

    final lookback =
        candles.length > 30 ? candles.sublist(candles.length - 30) : candles;

    final support = lookback.map((c) => c.low).reduce(math.min);

    final resistance = lookback.map((c) => c.high).reduce(math.max);

    final trend = ema9 > ema21
        ? 'BULLISH'
        : ema9 < ema21
            ? 'BEARISH'
            : 'NEUTRAL';

    final momentum = rsi >= 60
        ? 'BULLISH STRONG'
        : rsi >= 52
            ? 'BULLISH'
            : rsi <= 40
                ? 'BEARISH STRONG'
                : rsi <= 48
                    ? 'BEARISH'
                    : 'NEUTRAL';

    final swings = _swings(candles);

    var structure = 'RANGE';

    if (swings.highs.length >= 2 && swings.lows.length >= 2) {
      final h1 = swings.highs[swings.highs.length - 2];

      final h2 = swings.highs.last;

      final l1 = swings.lows[swings.lows.length - 2];

      final l2 = swings.lows.last;

      if (h2 > h1 && l2 > l1) {
        structure = 'BULLISH HH / HL';
      } else if (h2 < h1 && l2 < l1) {
        structure = 'BEARISH LH / LL';
      } else {
        structure = 'MIXED / RANGE';
      }
    }

    final tolerance = math.max(
      atr * .30,
      latest.close.abs() * .00025,
    );

    var supportTouches = 0;
    var resistanceTouches = 0;

    for (final candle in lookback) {
      if ((candle.low - support).abs() <= tolerance) {
        supportTouches++;
      }

      if ((candle.high - resistance).abs() <= tolerance) {
        resistanceTouches++;
      }
    }

    final levels = [
      SmartLevel(
        type: 'SUPPORT',
        price: support,
        touches: supportTouches,
        strength: math.min(100, 55 + supportTouches * 8).toDouble(),
      ),
      SmartLevel(
        type: 'RESISTANCE',
        price: resistance,
        touches: resistanceTouches,
        strength: math.min(100, 55 + resistanceTouches * 8).toDouble(),
      ),
    ];

    final swingHigh = lookback.map((c) => c.high).reduce(math.max);

    final swingLow = lookback.map((c) => c.low).reduce(math.min);

    final range = swingHigh - swingLow;

    final fibonacci = <String, double>{};

    if (trend == 'BULLISH') {
      fibonacci['23.6%'] = swingHigh - range * .236;
      fibonacci['38.2%'] = swingHigh - range * .382;
      fibonacci['50.0%'] = swingHigh - range * .500;
      fibonacci['61.8%'] = swingHigh - range * .618;
      fibonacci['78.6%'] = swingHigh - range * .786;
    } else {
      fibonacci['23.6%'] = swingLow + range * .236;
      fibonacci['38.2%'] = swingLow + range * .382;
      fibonacci['50.0%'] = swingLow + range * .500;
      fibonacci['61.8%'] = swingLow + range * .618;
      fibonacci['78.6%'] = swingLow + range * .786;
    }

    final pattern = _pattern(
      candles,
      atr,
    );

    var breakoutState = 'INSIDE RANGE';
    var breakoutScore = 50.0;

    if (latest.close >= resistance) {
      breakoutState = 'BULLISH BREAKOUT CONFIRMED';

      breakoutScore = 90;
    } else if (latest.close <= support) {
      breakoutState = 'BEARISH BREAKOUT CONFIRMED';

      breakoutScore = 90;
    } else if ((resistance - latest.close).abs() <= atr * .35) {
      breakoutState = 'BULLISH BREAKOUT WATCH';

      breakoutScore = 72;
    } else if ((latest.close - support).abs() <= atr * .35) {
      breakoutState = 'BEARISH BREAKOUT WATCH';

      breakoutScore = 72;
    }

    var bullishFvgCount = 0;
    var bearishFvgCount = 0;

    for (var i = 2; i < candles.length; i++) {
      if (candles[i].low > candles[i - 2].high) {
        bullishFvgCount++;
      }

      if (candles[i].high < candles[i - 2].low) {
        bearishFvgCount++;
      }
    }

    final liquidityState =
        (resistance - latest.close).abs() < (latest.close - support).abs()
            ? 'BUY-SIDE LIQUIDITY NEAREST'
            : 'SELL-SIDE LIQUIDITY NEAREST';

    final orderBlockBias = trend == 'BULLISH'
        ? 'BULLISH DEMAND / ORDER BLOCK'
        : trend == 'BEARISH'
            ? 'BEARISH SUPPLY / ORDER BLOCK'
            : 'NEUTRAL ORDER BLOCK';

    final trendScore = _trendScore(
      ema9,
      ema21,
      latest.close,
    );

    final structureScore =
        structure.contains('BULLISH') || structure.contains('BEARISH')
            ? 82.0
            : 55.0;

    final momentumScore = (50 + (rsi - 50).abs()).clamp(0.0, 100.0);

    final patternScore = pattern.confidence.clamp(0.0, 100.0);

    final liquidityScore = math.min(
      95.0,
      60 +
          math.max(
                supportTouches,
                resistanceTouches,
              ) *
              5,
    );

    var directionScore = 0.0;

    if (trend.contains('BULL')) {
      directionScore += trendScore;
    } else if (trend.contains('BEAR')) {
      directionScore -= trendScore;
    }

    if (structure.contains('BULL')) {
      directionScore += structureScore;
    } else if (structure.contains('BEAR')) {
      directionScore -= structureScore;
    }

    if (momentum.contains('BULL')) {
      directionScore += momentumScore;
    } else if (momentum.contains('BEAR')) {
      directionScore -= momentumScore;
    }

    directionScore /= 3;

    final bias = directionScore > 15
        ? 'BULLISH'
        : directionScore < -15
            ? 'BEARISH'
            : 'NEUTRAL';

    return _Core(
      trend: trend,
      structure: structure,
      momentum: momentum,
      bias: bias,
      ema9: ema9,
      ema21: ema21,
      rsi: rsi,
      atr: atr,
      support: support,
      resistance: resistance,
      levels: levels,
      fibonacci: fibonacci,
      pattern: pattern.name,
      patternDirection: pattern.direction,
      patternConfidence: pattern.confidence,
      breakoutState: breakoutState,
      breakoutScore: breakoutScore,
      liquidityState: liquidityState,
      bullishFvgCount: bullishFvgCount,
      bearishFvgCount: bearishFvgCount,
      orderBlockBias: orderBlockBias,
      trendScore: trendScore,
      structureScore: structureScore,
      momentumScore: momentumScore,
      patternScore: patternScore,
      liquidityScore: liquidityScore.toDouble(),
      directionScore: directionScore,
    );
  }

  static _Pattern _pattern(
    List<SmartCandle> candles,
    double atr,
  ) {
    final last = candles.last;

    final body = (last.close - last.open).abs();

    final range = math.max(
      0.0000001,
      last.high - last.low,
    );

    if (body / range < .12) {
      return const _Pattern(
        'DOJI',
        'NEUTRAL',
        82,
      );
    }

    if (candles.length >= 2) {
      final previous = candles[candles.length - 2];

      if (last.bullish &&
          !previous.bullish &&
          last.open <= previous.close &&
          last.close >= previous.open) {
        return const _Pattern(
          'BULLISH ENGULFING',
          'BULLISH',
          88,
        );
      }

      if (!last.bullish &&
          previous.bullish &&
          last.open >= previous.close &&
          last.close <= previous.open) {
        return const _Pattern(
          'BEARISH ENGULFING',
          'BEARISH',
          88,
        );
      }
    }

    final recent =
        candles.length > 20 ? candles.sublist(candles.length - 20) : candles;

    final half = recent.length ~/ 2;

    if (half >= 2) {
      final first = recent.sublist(0, half);
      final second = recent.sublist(half);

      final firstRange = first.map((c) => c.high).reduce(math.max) -
          first.map((c) => c.low).reduce(math.min);

      final secondRange = second.map((c) => c.high).reduce(math.max) -
          second.map((c) => c.low).reduce(math.min);

      if (secondRange < firstRange * .65) {
        return const _Pattern(
          'TRIANGLE / COMPRESSION',
          'BREAKOUT WATCH',
          78,
        );
      }
    }

    return const _Pattern(
      'NO HIGH-CONFIDENCE PATTERN',
      'NEUTRAL',
      52,
    );
  }

  static double _ema(
    List<double> values,
    int period,
  ) {
    if (values.isEmpty) return 0;

    final k = 2 / (period + 1);

    var result = values.first;

    for (var i = 1; i < values.length; i++) {
      result = (values[i] - result) * k + result;
    }

    return result;
  }

  static double _rsi(
    List<double> values,
    int period,
  ) {
    if (values.length < 2) return 50;

    final start = math.max(1, values.length - period);

    var gains = 0.0;
    var losses = 0.0;
    var count = 0;

    for (var i = start; i < values.length; i++) {
      final move = values[i] - values[i - 1];

      if (move > 0) {
        gains += move;
      } else {
        losses += move.abs();
      }

      count++;
    }

    if (count == 0) return 50;

    final averageGain = gains / count;
    final averageLoss = losses / count;

    if (averageLoss == 0) return 100;

    final rs = averageGain / averageLoss;

    return 100 - (100 / (1 + rs));
  }

  static double _atr(
    List<SmartCandle> candles,
    int period,
  ) {
    if (candles.length < 2) return 0;

    final start = math.max(1, candles.length - period);

    var total = 0.0;
    var count = 0;

    for (var i = start; i < candles.length; i++) {
      final candle = candles[i];
      final previousClose = candles[i - 1].close;

      final tr = math.max(
        candle.high - candle.low,
        math.max(
          (candle.high - previousClose).abs(),
          (candle.low - previousClose).abs(),
        ),
      );

      total += tr;
      count++;
    }

    return count == 0 ? 0 : total / count;
  }

  static double _trendScore(
    double fast,
    double slow,
    double price,
  ) {
    if (price == 0) return 50;

    final spread = ((fast - slow).abs() / price) * 10000;

    return (55 + spread * 8).clamp(0.0, 100.0);
  }

  static _Swings _swings(
    List<SmartCandle> candles,
  ) {
    final highs = <double>[];
    final lows = <double>[];

    for (var i = 2; i < candles.length - 2; i++) {
      final c = candles[i];

      if (c.high > candles[i - 1].high &&
          c.high > candles[i - 2].high &&
          c.high >= candles[i + 1].high &&
          c.high >= candles[i + 2].high) {
        highs.add(c.high);
      }

      if (c.low < candles[i - 1].low &&
          c.low < candles[i - 2].low &&
          c.low <= candles[i + 1].low &&
          c.low <= candles[i + 2].low) {
        lows.add(c.low);
      }
    }

    return _Swings(highs, lows);
  }

  static List<SmartCandle> _aggregate(
    List<SmartCandle> source,
    int minutes,
  ) {
    if (source.isEmpty) return const [];

    final result = <SmartCandle>[];

    SmartCandle? current;
    int? currentBucket;

    final bucketMs = minutes * 60 * 1000;

    for (final candle in source) {
      final millis = candle.time.millisecondsSinceEpoch;

      final bucket = (millis ~/ bucketMs) * bucketMs;

      if (current == null || currentBucket != bucket) {
        if (current != null) {
          result.add(current);
        }

        currentBucket = bucket;

        current = SmartCandle(
          time: DateTime.fromMillisecondsSinceEpoch(
            bucket,
          ),
          open: candle.open,
          high: candle.high,
          low: candle.low,
          close: candle.close,
        );
      } else {
        current = SmartCandle(
          time: current.time,
          open: current.open,
          high: math.max(
            current.high,
            candle.high,
          ),
          low: math.min(
            current.low,
            candle.low,
          ),
          close: candle.close,
        );
      }
    }

    if (current != null) {
      result.add(current);
    }

    return result;
  }

  static double? _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }
}

class _Pattern {
  final String name;
  final String direction;
  final double confidence;

  const _Pattern(
    this.name,
    this.direction,
    this.confidence,
  );
}

class _Swings {
  final List<double> highs;
  final List<double> lows;

  const _Swings(
    this.highs,
    this.lows,
  );
}

class _Core {
  final String trend;
  final String structure;
  final String momentum;
  final String bias;

  final double ema9;
  final double ema21;
  final double rsi;
  final double atr;

  final double support;
  final double resistance;

  final List<SmartLevel> levels;
  final Map<String, double> fibonacci;

  final String pattern;
  final String patternDirection;
  final double patternConfidence;

  final String breakoutState;
  final double breakoutScore;

  final String liquidityState;

  final int bullishFvgCount;
  final int bearishFvgCount;

  final String orderBlockBias;

  final double trendScore;
  final double structureScore;
  final double momentumScore;
  final double patternScore;
  final double liquidityScore;

  final double directionScore;

  const _Core({
    required this.trend,
    required this.structure,
    required this.momentum,
    required this.bias,
    required this.ema9,
    required this.ema21,
    required this.rsi,
    required this.atr,
    required this.support,
    required this.resistance,
    required this.levels,
    required this.fibonacci,
    required this.pattern,
    required this.patternDirection,
    required this.patternConfidence,
    required this.breakoutState,
    required this.breakoutScore,
    required this.liquidityState,
    required this.bullishFvgCount,
    required this.bearishFvgCount,
    required this.orderBlockBias,
    required this.trendScore,
    required this.structureScore,
    required this.momentumScore,
    required this.patternScore,
    required this.liquidityScore,
    required this.directionScore,
  });
}
