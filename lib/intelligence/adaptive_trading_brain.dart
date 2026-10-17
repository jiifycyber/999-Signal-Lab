class TradingBrainDecision {
  final double rawConfidence;
  final double adaptiveScore;
  final double conflictScore;
  final double performanceAdjustment;
  final String tier;
  final bool qualified;
  final String reason;

  const TradingBrainDecision({
    required this.rawConfidence,
    required this.adaptiveScore,
    required this.conflictScore,
    required this.performanceAdjustment,
    required this.tier,
    required this.qualified,
    required this.reason,
  });
}

class AdaptiveTradingBrain {
  static double _clamp(double value) => value.clamp(0.0, 100.0).toDouble();

  static TradingBrainDecision evaluate({
    required double confidence,
    double trend = 50.0,
    double momentum = 50.0,
    double structure = 50.0,
    double volatility = 50.0,
    double timeframeAlignment = 50.0,
    double historicalEdge = 50.0,
    double conflict = 0.0,
    double learningAdjustment = 0.0,
  }) {
    final weightedScore = (confidence * 0.24) +
        (trend * 0.18) +
        (momentum * 0.18) +
        (structure * 0.14) +
        (volatility * 0.08) +
        (timeframeAlignment * 0.10) +
        (historicalEdge * 0.08);

    final conflictPenalty = conflict.clamp(0.0, 100.0) * 0.18;

    final adaptiveScore = _clamp(
      weightedScore - conflictPenalty + learningAdjustment,
    );

    final qualified =
        adaptiveScore >= 68.0 && confidence >= 62.0 && conflict < 70.0;

    String tier;

    if (adaptiveScore >= 88.0 && conflict < 25.0) {
      tier = 'PRIME';
    } else if (adaptiveScore >= 78.0 && conflict < 40.0) {
      tier = 'STRONG';
    } else if (adaptiveScore >= 68.0 && conflict < 55.0) {
      tier = 'ACTIVE';
    } else if (adaptiveScore >= 58.0) {
      tier = 'WATCH';
    } else {
      tier = 'BLOCKED';
    }

    final reason = qualified
        ? 'Qualified by weighted market evidence'
        : 'Insufficient combined edge or excessive conflict';

    return TradingBrainDecision(
      rawConfidence: confidence,
      adaptiveScore: adaptiveScore,
      conflictScore: conflict,
      performanceAdjustment: learningAdjustment,
      tier: tier,
      qualified: qualified,
      reason: reason,
    );
  }
}
