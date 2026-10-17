class DukeAnalysis {
  final String symbol;
  final String decision;
  final double confidence;
  final double trendScore;
  final double momentumScore;
  final double volatilityScore;
  final double structureScore;
  final String explanation;

  const DukeAnalysis({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.trendScore,
    required this.momentumScore,
    required this.volatilityScore,
    required this.structureScore,
    required this.explanation,
  });
}

/// Aggressive directional intelligence.
///
/// Duke must choose BUY or SELL.
/// Confidence measures how decisive the choice is.
class AgentDukeIntelligence {
  const AgentDukeIntelligence();

  DukeAnalysis analyze({
    required String symbol,
    required double trend,
    required double momentum,
    required double volatility,
    required double structure,
  }) {
    final score = (trend * 0.38) +
        (momentum * 0.34) +
        (structure * 0.20) +
        (volatility * 0.08);

    final decision = score >= 0 ? 'BUY' : 'SELL';

    final confidence =
        (50.0 + (score.abs() * 0.45)).clamp(50.0, 95.0).toDouble();

    return DukeAnalysis(
      symbol: symbol,
      decision: decision,
      confidence: confidence,
      trendScore: trend,
      momentumScore: momentum,
      volatilityScore: volatility,
      structureScore: structure,
      explanation: 'Agent Duke 60-second directional forecast: '
          '$decision. Composite directional score '
          '${score.toStringAsFixed(1)}. '
          'Confidence measures relative forecast strength.',
    );
  }
}
