class DukeAdaptiveWeights {
  double trendWeight;
  double momentumWeight;
  double structureWeight;
  double volatilityWeight;

  DukeAdaptiveWeights({
    this.trendWeight = 0.35,
    this.momentumWeight = 0.30,
    this.structureWeight = 0.25,
    this.volatilityWeight = 0.10,
  });

  double score({
    required double trend,
    required double momentum,
    required double structure,
    required double volatility,
  }) {
    return (trend * trendWeight) +
        (momentum * momentumWeight) +
        (structure * structureWeight) +
        (volatility * volatilityWeight);
  }

  void learnFromOutcome({
    required bool won,
    required double trendContribution,
    required double momentumContribution,
    required double structureContribution,
    required double volatilityContribution,
  }) {
    const learningRate = 0.01;

    final direction = won ? 1.0 : -1.0;

    trendWeight +=
        direction * learningRate * _normalizedMagnitude(trendContribution);

    momentumWeight +=
        direction * learningRate * _normalizedMagnitude(momentumContribution);

    structureWeight +=
        direction * learningRate * _normalizedMagnitude(structureContribution);

    volatilityWeight +=
        direction * learningRate * _normalizedMagnitude(volatilityContribution);

    _clampWeights();
    _normalizeWeights();
  }

  double _normalizedMagnitude(double value) {
    return value.abs().clamp(0.0, 100.0) / 100.0;
  }

  void _clampWeights() {
    trendWeight = trendWeight.clamp(0.20, 0.50);
    momentumWeight = momentumWeight.clamp(0.15, 0.45);
    structureWeight = structureWeight.clamp(0.15, 0.40);
    volatilityWeight = volatilityWeight.clamp(0.05, 0.20);
  }

  void _normalizeWeights() {
    final total =
        trendWeight + momentumWeight + structureWeight + volatilityWeight;

    trendWeight /= total;
    momentumWeight /= total;
    structureWeight /= total;
    volatilityWeight /= total;
  }

  Map<String, double> snapshot() {
    return {
      'trend': trendWeight,
      'momentum': momentumWeight,
      'structure': structureWeight,
      'volatility': volatilityWeight,
    };
  }
}
