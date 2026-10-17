import 'intelligence_models.dart';

class IntelligenceStore {
  final List<SignalHistoryRecord> signalHistory = [];
  final List<TradeOutcomeRecord> tradeOutcomes = [];

  final List<AlertRule> alertRules = [
    const AlertRule(
      id: 'default',
      symbol: 'ALL',
      minConfidence: 70.0,
      buyAlerts: true,
      sellAlerts: true,
      dukeApprovedOnly: false,
      enabled: true,
    ),
  ];

  void addSignal(SignalHistoryRecord record) {
    final duplicate = signalHistory.any(
      (item) =>
          item.symbol == record.symbol &&
          item.direction == record.direction &&
          item.timestamp.difference(record.timestamp).abs().inSeconds < 30,
    );

    if (duplicate) return;

    signalHistory.insert(0, record);

    if (signalHistory.length > 500) {
      signalHistory.removeRange(500, signalHistory.length);
    }
  }

  void addOutcome(TradeOutcomeRecord record) {
    tradeOutcomes.insert(0, record);

    if (tradeOutcomes.length > 500) {
      tradeOutcomes.removeRange(500, tradeOutcomes.length);
    }
  }

  double get winRate {
    if (tradeOutcomes.isEmpty) return 0.0;

    final wins = tradeOutcomes.where((item) => item.win).length;
    return wins / tradeOutcomes.length * 100.0;
  }

  double get averageR {
    if (tradeOutcomes.isEmpty) return 0.0;

    final total = tradeOutcomes.fold<double>(
      0.0,
      (sum, item) => sum + item.resultR,
    );

    return total / tradeOutcomes.length;
  }
}
