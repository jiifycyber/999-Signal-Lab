import 'intelligence_store.dart';

class AlertDecision {
  final bool shouldAlert;
  final String reason;

  const AlertDecision({
    required this.shouldAlert,
    required this.reason,
  });
}

class AlertEngine {
  final IntelligenceStore store;

  AlertEngine(this.store);

  AlertDecision evaluate({
    required String symbol,
    required String direction,
    required double confidence,
    required bool dukeApproved,
  }) {
    for (final rule in store.alertRules) {
      if (!rule.enabled) continue;

      if (rule.symbol != 'ALL' && rule.symbol != symbol) {
        continue;
      }

      if (confidence < rule.minConfidence) {
        continue;
      }

      if (rule.dukeApprovedOnly && !dukeApproved) {
        continue;
      }

      if (direction == 'BUY' && !rule.buyAlerts) {
        continue;
      }

      if (direction == 'SELL' && !rule.sellAlerts) {
        continue;
      }

      if (direction != 'BUY' && direction != 'SELL') {
        continue;
      }

      return AlertDecision(
        shouldAlert: true,
        reason:
            '$symbol $direction ${confidence.toStringAsFixed(1)}% qualifies',
      );
    }

    return const AlertDecision(
      shouldAlert: false,
      reason: 'No alert rule matched',
    );
  }
}
