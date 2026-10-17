class SignalHistoryRecord {
  final String symbol;
  final String direction;
  final double confidence;
  final double entry;
  final double stopLoss;
  final double tp1;
  final double tp2;
  final double tp3;
  final DateTime timestamp;
  final String setup;
  final String trend;
  final String momentum;

  const SignalHistoryRecord({
    required this.symbol,
    required this.direction,
    required this.confidence,
    required this.entry,
    required this.stopLoss,
    required this.tp1,
    required this.tp2,
    required this.tp3,
    required this.timestamp,
    required this.setup,
    required this.trend,
    required this.momentum,
  });
}

class TradeOutcomeRecord {
  final String symbol;
  final String direction;
  final bool win;
  final double resultR;
  final DateTime timestamp;
  final String setup;
  final double confidence;
  final String outcome;

  const TradeOutcomeRecord({
    required this.symbol,
    required this.direction,
    required this.win,
    required this.resultR,
    required this.timestamp,
    required this.setup,
    required this.confidence,
    this.outcome = '',
  });

  bool get isTie => outcome == 'TIE';

  bool get isWin => outcome == 'WIN' || (outcome.isEmpty && win);

  bool get isLoss => outcome == 'LOSS' || (outcome.isEmpty && !win);
}

class AlertRule {
  final String id;
  final String symbol;
  final double minConfidence;
  final bool buyAlerts;
  final bool sellAlerts;
  final bool dukeApprovedOnly;
  final bool enabled;

  const AlertRule({
    required this.id,
    required this.symbol,
    required this.minConfidence,
    required this.buyAlerts,
    required this.sellAlerts,
    required this.dukeApprovedOnly,
    required this.enabled,
  });
}
