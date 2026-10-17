class DukeTimeframeInput {
  final String timeframe;
  final double trend;
  final double momentum;
  final double structure;
  final double volatility;

  const DukeTimeframeInput({
    required this.timeframe,
    required this.trend,
    required this.momentum,
    required this.structure,
    required this.volatility,
  });

  double get score =>
      (trend * 0.38) +
      (momentum * 0.34) +
      (structure * 0.20) +
      (volatility * 0.08);
}

class DukeMultiTimeframeResult {
  final String symbol;
  final String decision;
  final double confidence;
  final double oneMinuteScore;
  final double fiveMinuteScore;
  final double fifteenMinuteScore;
  final int bullishTimeframes;
  final int bearishTimeframes;
  final String explanation;

  const DukeMultiTimeframeResult({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.oneMinuteScore,
    required this.fiveMinuteScore,
    required this.fifteenMinuteScore,
    required this.bullishTimeframes,
    required this.bearishTimeframes,
    required this.explanation,
  });
}

/// 999 aggressive M1-first forecast.
///
/// M1 carries 70% of the directional decision.
/// M5 and M15 provide context instead of permission.
///
/// There is no ±38 qualification threshold.
class AgentDukeMultiTimeframe {
  const AgentDukeMultiTimeframe();

  DukeMultiTimeframeResult analyze({
    required String symbol,
    required DukeTimeframeInput oneMinute,
    required DukeTimeframeInput fiveMinute,
    required DukeTimeframeInput fifteenMinute,
  }) {
    final s1 = oneMinute.score;
    final s5 = fiveMinute.score;
    final s15 = fifteenMinute.score;

    final scores = [s1, s5, s15];

    final bullish = scores.where((score) => score > 0).length;

    final bearish = scores.where((score) => score < 0).length;

    // M1 dominates because this system forecasts 60 seconds.
    final weightedScore = (s1 * 0.70) + (s5 * 0.20) + (s15 * 0.10);

    String decision;

    if (weightedScore > 0) {
      decision = 'BUY';
    } else if (weightedScore < 0) {
      decision = 'SELL';
    } else {
      // Exact tie: M1 gets final vote.
      decision = s1 >= 0 ? 'BUY' : 'SELL';
    }

    double alignmentBonus = 0;

    if (bullish == 3 || bearish == 3) {
      alignmentBonus = 7;
    } else if (bullish == 2 || bearish == 2) {
      alignmentBonus = 3;
    }

    final confidence = (50.0 + (weightedScore.abs() * 0.40) + alignmentBonus)
        .clamp(50.0, 95.0)
        .toDouble();

    return DukeMultiTimeframeResult(
      symbol: symbol,
      decision: decision,
      confidence: confidence,
      oneMinuteScore: s1,
      fiveMinuteScore: s5,
      fifteenMinuteScore: s15,
      bullishTimeframes: bullish,
      bearishTimeframes: bearish,
      explanation: 'Aggressive M1-first 60-second forecast: '
          '1M ${s1.toStringAsFixed(1)}, '
          '5M ${s5.toStringAsFixed(1)}, '
          '15M ${s15.toStringAsFixed(1)}. '
          'Weighted direction ${weightedScore.toStringAsFixed(1)}. '
          'Forecast: $decision.',
    );
  }
}
