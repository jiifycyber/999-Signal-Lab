class ModuleContext {
  final String pair;
  final String timeframe;
  final double? price;

  final String direction;
  final double confidence;
  final double score;

  final String trend;
  final String momentum;
  final String setup;

  final double? entry;
  final double? stopLoss;
  final double? tp1;
  final double? tp2;
  final double? tp3;

  const ModuleContext({
    required this.pair,
    required this.timeframe,
    required this.price,
    required this.direction,
    required this.confidence,
    required this.score,
    required this.trend,
    required this.momentum,
    required this.setup,
    required this.entry,
    required this.stopLoss,
    required this.tp1,
    required this.tp2,
    required this.tp3,
  });

  bool get isBuy => direction.toUpperCase() == 'BUY';
  bool get isSell => direction.toUpperCase() == 'SELL';

  String get signalStrength {
    if (confidence >= 90) return 'EXTREME';
    if (confidence >= 80) return 'STRONG';
    if (confidence >= 65) return 'MODERATE';
    return 'WEAK';
  }

  String get regime {
    final t = trend.toLowerCase();
    final m = momentum.toLowerCase();

    if (t.contains('bull') && m.contains('bull')) {
      return 'BULLISH TREND';
    }

    if (t.contains('bear') && m.contains('bear')) {
      return 'BEARISH TREND';
    }

    if (confidence >= 80) {
      return isBuy
          ? 'BULLISH TREND'
          : isSell
              ? 'BEARISH TREND'
              : 'TRANSITION';
    }

    return 'RANGE / TRANSITION';
  }

  double get bullishProbability {
    if (isBuy) return confidence.clamp(0.0, 100.0);
    if (isSell) return (100.0 - confidence).clamp(0.0, 100.0);
    return 50.0;
  }

  double get bearishProbability {
    if (isSell) return confidence.clamp(0.0, 100.0);
    if (isBuy) return (100.0 - confidence).clamp(0.0, 100.0);
    return 50.0;
  }

  double? get riskDistance {
    if (entry == null || stopLoss == null) return null;
    return (entry! - stopLoss!).abs();
  }

  double? get rewardDistance {
    if (entry == null || tp1 == null) return null;
    return (tp1! - entry!).abs();
  }

  double? get riskReward {
    final risk = riskDistance;
    final reward = rewardDistance;

    if (risk == null || reward == null || risk == 0) return null;
    return reward / risk;
  }
}
