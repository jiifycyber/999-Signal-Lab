class DukeTradeGateInput {
  final String symbol;
  final String proposedDecision;
  final double confidence;
  final double trendStrength;
  final double volatility;
  final double spreadQuality;
  final double structureQuality;
  final bool multiTimeframeAligned;

  const DukeTradeGateInput({
    required this.symbol,
    required this.proposedDecision,
    required this.confidence,
    required this.trendStrength,
    required this.volatility,
    required this.spreadQuality,
    required this.structureQuality,
    required this.multiTimeframeAligned,
  });
}

class DukeTradeGateResult {
  final String symbol;
  final String finalDecision;
  final bool tradeApproved;
  final double qualityScore;
  final List<String> reasons;

  const DukeTradeGateResult({
    required this.symbol,
    required this.finalDecision,
    required this.tradeApproved,
    required this.qualityScore,
    required this.reasons,
  });
}

/// The trade gate no longer has authority to erase Duke's direction.
///
/// It can report quality warnings.
/// It cannot convert BUY/SELL into WAIT.
class AgentDukeTradeGate {
  const AgentDukeTradeGate();

  DukeTradeGateResult evaluate(
    DukeTradeGateInput input,
  ) {
    final reasons = <String>[];

    final volatilityQuality =
        (100.0 - (input.volatility - 65.0).abs()).clamp(0.0, 100.0).toDouble();

    final qualityScore = ((input.confidence * 0.35) +
            (input.trendStrength.abs() * 0.20) +
            (input.spreadQuality * 0.10) +
            (input.structureQuality * 0.15) +
            (volatilityQuality * 0.10) +
            ((input.multiTimeframeAligned ? 100.0 : 60.0) * 0.10))
        .clamp(0.0, 100.0)
        .toDouble();

    if (!input.multiTimeframeAligned) {
      reasons.add(
        'Timeframes disagree; M1 forecast remains active.',
      );
    }

    if (input.trendStrength.abs() < 25) {
      reasons.add(
        'Trend edge is weak; confidence reduced.',
      );
    }

    if (input.structureQuality < 45) {
      reasons.add(
        'Structure edge is weak; confidence reduced.',
      );
    }

    if (input.spreadQuality < 35) {
      reasons.add(
        'Spread/execution quality is weak.',
      );
    }

    if (input.volatility > 95) {
      reasons.add(
        'Volatility is unusually high.',
      );
    }

    final validDecision =
        input.proposedDecision == 'BUY' || input.proposedDecision == 'SELL';

    return DukeTradeGateResult(
      symbol: input.symbol,

      // Never replace a valid directional forecast with WAIT.
      finalDecision: validDecision ? input.proposedDecision : 'BUY',

      tradeApproved: validDecision,
      qualityScore: qualityScore,
      reasons: reasons,
    );
  }
}
