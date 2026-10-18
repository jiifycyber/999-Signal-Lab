import 'advanced_combined_formula_engine.dart';

class Stage53PendingPrediction {
  final String id;
  final String symbol;
  final String liveDirection;
  final double liveConfidence;
  final double entryPrice;
  final double stopLoss;
  final String setup;
  final DateTime openedAt;
  final DateTime expiresAt;
  final double formulaScore;
  final double bullishProbability;
  final double bearishProbability;
  final double linearContribution;
  final double interactionContribution;
  final int interactionCount;
  final List<double> formulaFeatures;

  const Stage53PendingPrediction({
    required this.id,
    required this.symbol,
    required this.liveDirection,
    required this.liveConfidence,
    required this.entryPrice,
    required this.stopLoss,
    required this.setup,
    required this.openedAt,
    required this.expiresAt,
    required this.formulaScore,
    required this.bullishProbability,
    required this.bearishProbability,
    required this.linearContribution,
    required this.interactionContribution,
    required this.interactionCount,
    required this.formulaFeatures,
  });

  String get formulaDirection {
    if (formulaScore > 0) return 'BUY';
    if (formulaScore < 0) return 'SELL';
    return 'NEUTRAL';
  }

  bool get agreesWithLive =>
      formulaDirection != 'NEUTRAL' && formulaDirection == liveDirection;
}

class Stage53FormulaOutcome {
  final String id;
  final String symbol;
  final String liveDirection;
  final String liveOutcome;
  final String formulaDirection;
  final String formulaOutcome;
  final double entryPrice;
  final double exitPrice;
  final double formulaScore;
  final double bullishProbability;
  final double bearishProbability;
  final double linearContribution;
  final double interactionContribution;
  final int interactionCount;
  final bool agreementAtEntry;
  final DateTime openedAt;
  final DateTime closedAt;
  final List<double> formulaFeatures;

  const Stage53FormulaOutcome({
    required this.id,
    required this.symbol,
    required this.liveDirection,
    required this.liveOutcome,
    required this.formulaDirection,
    required this.formulaOutcome,
    required this.entryPrice,
    required this.exitPrice,
    required this.formulaScore,
    required this.bullishProbability,
    required this.bearishProbability,
    required this.linearContribution,
    required this.interactionContribution,
    required this.interactionCount,
    required this.agreementAtEntry,
    required this.openedAt,
    required this.closedAt,
    required this.formulaFeatures,
  });

  bool get formulaWin => formulaOutcome == 'WIN';
  bool get formulaLoss => formulaOutcome == 'LOSS';
}

class Stage53OutcomeTracker {
  final Map<String, Stage53PendingPrediction> _pending = {};
  final List<Stage53FormulaOutcome> _outcomes = [];

  List<Stage53PendingPrediction> get pending =>
      List.unmodifiable(_pending.values);

  List<Stage53FormulaOutcome> get outcomes => List.unmodifiable(_outcomes);

  void track({
    required String id,
    required String symbol,
    required String liveDirection,
    required double liveConfidence,
    required double entryPrice,
    required double stopLoss,
    required String setup,
    required DateTime openedAt,
    required AdvancedCombinedFormulaResult formula,
  }) {
    if (_pending.containsKey(id)) return;

    _pending[id] = Stage53PendingPrediction(
      id: id,
      symbol: symbol,
      liveDirection: liveDirection,
      liveConfidence: liveConfidence,
      entryPrice: entryPrice,
      stopLoss: stopLoss,
      setup: setup,
      openedAt: openedAt,
      expiresAt: openedAt.add(const Duration(seconds: 60)),
      formulaScore: formula.score,
      bullishProbability: formula.bullishProbability,
      bearishProbability: formula.bearishProbability,
      linearContribution: formula.linearContribution,
      interactionContribution: formula.interactionContribution,
      interactionCount: formula.interactionCount,
      formulaFeatures: List.unmodifiable(formula.normalizedFeatures),
    );
  }

  Stage53PendingPrediction? pendingFor(String id) => _pending[id];

  Stage53FormulaOutcome? resolve({
    required String id,
    required double exitPrice,
    required String liveOutcome,
    required DateTime closedAt,
  }) {
    final pending = _pending.remove(id);
    if (pending == null) return null;

    final direction = pending.formulaDirection;
    String formulaOutcome;

    if (direction == 'NEUTRAL') {
      formulaOutcome = 'NEUTRAL';
    } else {
      final delta = exitPrice - pending.entryPrice;
      final tieBand = pending.entryPrice.abs() * 0.0001;

      if (delta.abs() <= tieBand) {
        formulaOutcome = 'BREAKEVEN';
      } else if ((direction == 'BUY' && delta > 0) ||
          (direction == 'SELL' && delta < 0)) {
        formulaOutcome = 'WIN';
      } else {
        formulaOutcome = 'LOSS';
      }
    }

    final outcome = Stage53FormulaOutcome(
      id: pending.id,
      symbol: pending.symbol,
      liveDirection: pending.liveDirection,
      liveOutcome: liveOutcome,
      formulaDirection: direction,
      formulaOutcome: formulaOutcome,
      entryPrice: pending.entryPrice,
      exitPrice: exitPrice,
      formulaScore: pending.formulaScore,
      bullishProbability: pending.bullishProbability,
      bearishProbability: pending.bearishProbability,
      linearContribution: pending.linearContribution,
      interactionContribution: pending.interactionContribution,
      interactionCount: pending.interactionCount,
      agreementAtEntry: pending.agreesWithLive,
      openedAt: pending.openedAt,
      closedAt: closedAt,
      formulaFeatures: pending.formulaFeatures,
    );

    _outcomes.insert(0, outcome);
    if (_outcomes.length > 500) {
      _outcomes.removeRange(500, _outcomes.length);
    }

    return outcome;
  }

  Map<String, dynamic> exportState() {
    return <String, dynamic>{
      'version': 1,
      'pending': _pending.values
          .map((item) => <String, dynamic>{
                'id': item.id,
                'symbol': item.symbol,
                'liveDirection': item.liveDirection,
                'liveConfidence': item.liveConfidence,
                'entryPrice': item.entryPrice,
                'stopLoss': item.stopLoss,
                'setup': item.setup,
                'openedAt': item.openedAt.toIso8601String(),
                'expiresAt': item.expiresAt.toIso8601String(),
                'formulaScore': item.formulaScore,
                'bullishProbability': item.bullishProbability,
                'bearishProbability': item.bearishProbability,
                'linearContribution': item.linearContribution,
                'interactionContribution': item.interactionContribution,
                'interactionCount': item.interactionCount,
                'formulaFeatures': item.formulaFeatures,
              })
          .toList(),
      'outcomes': _outcomes
          .map((item) => <String, dynamic>{
                'id': item.id,
                'symbol': item.symbol,
                'liveDirection': item.liveDirection,
                'liveOutcome': item.liveOutcome,
                'formulaDirection': item.formulaDirection,
                'formulaOutcome': item.formulaOutcome,
                'entryPrice': item.entryPrice,
                'exitPrice': item.exitPrice,
                'formulaScore': item.formulaScore,
                'bullishProbability': item.bullishProbability,
                'bearishProbability': item.bearishProbability,
                'linearContribution': item.linearContribution,
                'interactionContribution': item.interactionContribution,
                'interactionCount': item.interactionCount,
                'agreementAtEntry': item.agreementAtEntry,
                'openedAt': item.openedAt.toIso8601String(),
                'closedAt': item.closedAt.toIso8601String(),
                'formulaFeatures': item.formulaFeatures,
              })
          .toList(),
    };
  }

  bool restoreState(Map<String, dynamic> state) {
    try {
      if (state['version'] != 1) return false;

      final pendingList = state['pending'];
      final outcomeList = state['outcomes'];
      if (pendingList is! List || outcomeList is! List) return false;

      final restoredPending = <String, Stage53PendingPrediction>{};
      final restoredOutcomes = <Stage53FormulaOutcome>[];

      for (final raw in pendingList) {
        final item = Map<String, dynamic>.from(raw as Map);
        final features = (item['formulaFeatures'] as List)
            .map((value) => (value as num).toDouble())
            .toList(growable: false);
        if (features.length != AdvancedCombinedFormulaEngine.featureCount) {
          return false;
        }

        final prediction = Stage53PendingPrediction(
          id: item['id'] as String,
          symbol: item['symbol'] as String,
          liveDirection: item['liveDirection'] as String,
          liveConfidence: (item['liveConfidence'] as num).toDouble(),
          entryPrice: (item['entryPrice'] as num).toDouble(),
          stopLoss: (item['stopLoss'] as num).toDouble(),
          setup: item['setup'] as String,
          openedAt: DateTime.parse(item['openedAt'] as String),
          expiresAt: DateTime.parse(item['expiresAt'] as String),
          formulaScore: (item['formulaScore'] as num).toDouble(),
          bullishProbability: (item['bullishProbability'] as num).toDouble(),
          bearishProbability: (item['bearishProbability'] as num).toDouble(),
          linearContribution: (item['linearContribution'] as num).toDouble(),
          interactionContribution:
              (item['interactionContribution'] as num).toDouble(),
          interactionCount: (item['interactionCount'] as num).toInt(),
          formulaFeatures: List<double>.unmodifiable(features),
        );
        restoredPending[prediction.id] = prediction;
      }

      for (final raw in outcomeList) {
        final item = Map<String, dynamic>.from(raw as Map);
        final features = (item['formulaFeatures'] as List)
            .map((value) => (value as num).toDouble())
            .toList(growable: false);
        if (features.length != AdvancedCombinedFormulaEngine.featureCount) {
          return false;
        }

        restoredOutcomes.add(
          Stage53FormulaOutcome(
            id: item['id'] as String,
            symbol: item['symbol'] as String,
            liveDirection: item['liveDirection'] as String,
            liveOutcome: item['liveOutcome'] as String,
            formulaDirection: item['formulaDirection'] as String,
            formulaOutcome: item['formulaOutcome'] as String,
            entryPrice: (item['entryPrice'] as num).toDouble(),
            exitPrice: (item['exitPrice'] as num).toDouble(),
            formulaScore: (item['formulaScore'] as num).toDouble(),
            bullishProbability: (item['bullishProbability'] as num).toDouble(),
            bearishProbability: (item['bearishProbability'] as num).toDouble(),
            linearContribution: (item['linearContribution'] as num).toDouble(),
            interactionContribution:
                (item['interactionContribution'] as num).toDouble(),
            interactionCount: (item['interactionCount'] as num).toInt(),
            agreementAtEntry: item['agreementAtEntry'] as bool,
            openedAt: DateTime.parse(item['openedAt'] as String),
            closedAt: DateTime.parse(item['closedAt'] as String),
            formulaFeatures: List<double>.unmodifiable(features),
          ),
        );
      }

      _pending
        ..clear()
        ..addAll(restoredPending);
      _outcomes
        ..clear()
        ..addAll(restoredOutcomes.take(500));

      return true;
    } catch (_) {
      return false;
    }
  }

  int get wins => _outcomes.where((o) => o.formulaWin).length;
  int get losses => _outcomes.where((o) => o.formulaLoss).length;

  double get winRate {
    final graded = wins + losses;
    if (graded == 0) return 0.0;
    return wins / graded * 100.0;
  }

  int get gradedCount => wins + losses;

  double rollingWinRate([int window = 25]) {
    final graded = _outcomes
        .where((item) => item.formulaWin || item.formulaLoss)
        .take(window)
        .toList();

    if (graded.isEmpty) return 0.0;

    final rollingWins = graded.where((item) => item.formulaWin).length;
    return rollingWins / graded.length * 100.0;
  }

  double get recentWinRate => rollingWinRate(25);
  double get longTermWinRate => rollingWinRate(100);

  int get agreementGradedCount => _outcomes
      .where((item) =>
          item.agreementAtEntry && (item.formulaWin || item.formulaLoss))
      .length;

  int get disagreementGradedCount => _outcomes
      .where((item) =>
          !item.agreementAtEntry && (item.formulaWin || item.formulaLoss))
      .length;

  double get agreementWinRate {
    final graded = _outcomes
        .where((item) =>
            item.agreementAtEntry && (item.formulaWin || item.formulaLoss))
        .toList();

    if (graded.isEmpty) return 0.0;
    return graded.where((item) => item.formulaWin).length /
        graded.length *
        100.0;
  }

  double get disagreementWinRate {
    final graded = _outcomes
        .where((item) =>
            !item.agreementAtEntry && (item.formulaWin || item.formulaLoss))
        .toList();

    if (graded.isEmpty) return 0.0;
    return graded.where((item) => item.formulaWin).length /
        graded.length *
        100.0;
  }

  String get validationStatus {
    if (gradedCount < 20) return "WARMING UP";

    final recent = recentWinRate;
    final longTerm = longTermWinRate;

    if (recent < 45.0 && longTerm < 50.0) {
      return "DEGRADED";
    }

    if (recent < 50.0 || (gradedCount >= 50 && recent + 5.0 < longTerm)) {
      return "CAUTION";
    }

    return "HEALTHY";
  }
}
