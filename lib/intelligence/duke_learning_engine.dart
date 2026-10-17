import 'intelligence_models.dart';
import 'intelligence_store.dart';

class DukeLearningSnapshot {
  final double winRate;
  final double averageR;
  final int totalTrades;
  final Map<String, double> setupScores;

  const DukeLearningSnapshot({
    required this.winRate,
    required this.averageR,
    required this.totalTrades,
    required this.setupScores,
  });
}

class DukeLearningEngine {
  final IntelligenceStore store;

  DukeLearningEngine(this.store);

  DukeLearningSnapshot analyze() {
    final grouped = <String, List<TradeOutcomeRecord>>{};

    for (final outcome in store.tradeOutcomes) {
      grouped.putIfAbsent(outcome.setup, () => []).add(outcome);
    }

    final scores = <String, double>{};

    for (final entry in grouped.entries) {
      final records = entry.value;

      if (records.isEmpty) continue;

      final wins = records.where((item) => item.win).length;
      final winRate = wins / records.length * 100.0;

      final avgR = records.fold<double>(
            0.0,
            (sum, item) => sum + item.resultR,
          ) /
          records.length;

      final score = (winRate * 0.75) + ((avgR + 2.0) * 6.25);

      scores[entry.key] = score.clamp(0.0, 100.0).toDouble();
    }

    return DukeLearningSnapshot(
      winRate: store.winRate,
      averageR: store.averageR,
      totalTrades: store.tradeOutcomes.length,
      setupScores: scores,
    );
  }

  double confidenceAdjustment(String setup) {
    final snapshot = analyze();

    if (snapshot.totalTrades < 10) return 0.0;

    final score = snapshot.setupScores[setup];
    if (score == null) return 0.0;

    if (score >= 80.0) return 5.0;
    if (score >= 70.0) return 3.0;
    if (score <= 40.0) return -5.0;
    if (score <= 55.0) return -3.0;

    return 0.0;
  }
}
