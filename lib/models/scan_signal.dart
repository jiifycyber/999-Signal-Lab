enum TradeDirection {
  buy,
  sell,
  wait,
}

class ScanSignal {
  final String symbol;
  final TradeDirection direction;
  final double confidence;
  final double score;

  final double entry;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final double takeProfit3;

  final String trend;
  final String momentum;
  final String setup;
  final DateTime timestamp;

  // ============================================================
  // ADVANCED MARKET INTELLIGENCE
  // ============================================================

  /// Real calculated structural support.
  final double? support;

  /// Real calculated structural resistance.
  final double? resistance;

  /// Dynamic preferred entry zone.
  final double? minEntry;

  final double? maxEntry;

  /// Actual independently calculated timeframe scores.
  /// Range: approximately -100 to +100.
  final double m1Score;
  final double m5Score;
  final double m15Score;

  /// Signed market structure score.
  final double structureScore;

  /// Volatility intensity/quality score, 0-100.
  final double volatilityScore;

  /// Detected market environment.
  final String regime;

  /// Human-readable explanation of the quantitative analysis.
  final String analysis;

  const ScanSignal({
    required this.symbol,
    required this.direction,
    required this.confidence,
    required this.score,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.takeProfit3,
    required this.trend,
    required this.momentum,
    required this.setup,
    required this.timestamp,
    this.support,
    this.resistance,
    this.minEntry,
    this.maxEntry,
    this.m1Score = 0,
    this.m5Score = 0,
    this.m15Score = 0,
    this.structureScore = 0,
    this.volatilityScore = 50,
    this.regime = 'UNKNOWN',
    this.analysis = '',
  });

  Duration get age => DateTime.now().difference(timestamp);

  bool get isExpired => age.inSeconds >= 60;

  DateTime get entryTime => timestamp.toLocal();

  DateTime get expirationTime =>
      timestamp.add(const Duration(seconds: 60)).toLocal();

  int get countdownSeconds {
    final remaining = 60 - age.inSeconds;
    return remaining.clamp(0, 60);
  }

  String _clockText(DateTime value) {
    final local = value.toLocal();

    int hour = local.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second $suffix';
  }

  String get entryTimeText => _clockText(entryTime);

  String get expirationTimeText => _clockText(expirationTime);

  String get countdownText {
    final seconds = countdownSeconds;
    return '00:${seconds.toString().padLeft(2, '0')}';
  }

  String get entryTimingText {
    if (isExpired) return 'EXPIRED';

    switch (direction) {
      case TradeDirection.buy:
      case TradeDirection.sell:
        return 'ENTER NOW';
      case TradeDirection.wait:
        return 'NO LIVE DATA';
    }
  }

  bool get canEnterNow => !isExpired && direction != TradeDirection.wait;

  String get setupQuality {
    if (confidence >= 85) return 'ELITE';
    if (confidence >= 75) return 'STRONG';
    if (confidence >= 65) return 'GOOD';
    if (confidence >= 55) return 'AGGRESSIVE';
    return 'LOW EDGE';
  }

  String get executionState {
    if (direction == TradeDirection.wait) return 'NO LIVE DATA';
    if (isExpired) return 'EXPIRED';
    return 'ENTER NOW';
  }

  String get directionText {
    switch (direction) {
      case TradeDirection.buy:
        return 'BUY';
      case TradeDirection.sell:
        return 'SELL';
      case TradeDirection.wait:
        return 'WAIT';
    }
  }
}
