import 'dart:math';

/// ==============================================================
/// 999 SIGNAL INTELLIGENCE PRO
/// STAGE 51 — ADVANCED COMBINED FORMULA ENGINE
///
/// S(t) = SUM wiFi(t) + SUM gammaij Fi(t)Fj(t)
///
/// 12 normalized intelligence features + 66 pairwise interactions.
///
/// STAGE 51 MODE:
/// SHADOW INTELLIGENCE ONLY.
/// This engine does NOT control live BUY/SELL direction yet.
/// ===============================================================

class AdvancedCombinedFormulaInput {
  final double velocity;
  final double acceleration;
  final double jerk;
  final double volatility;
  final double probability;
  final double predictionErrorLearning;
  final double rectilinearNetwork;
  final double orthogonalPathEfficiency;
  final double junctionBranch;
  final double adaptiveGrid;
  final double transitionProbability;
  final double pathErrorLearning;

  const AdvancedCombinedFormulaInput({
    required this.velocity,
    required this.acceleration,
    required this.jerk,
    required this.volatility,
    required this.probability,
    required this.predictionErrorLearning,
    required this.rectilinearNetwork,
    required this.orthogonalPathEfficiency,
    required this.junctionBranch,
    required this.adaptiveGrid,
    required this.transitionProbability,
    required this.pathErrorLearning,
  });

  List<double> get rawFeatures => <double>[
        velocity,
        acceleration,
        jerk,
        volatility,
        probability,
        predictionErrorLearning,
        rectilinearNetwork,
        orthogonalPathEfficiency,
        junctionBranch,
        adaptiveGrid,
        transitionProbability,
        pathErrorLearning,
      ];
}

class AdvancedCombinedFormulaResult {
  final double score;
  final double bullishProbability;
  final double bearishProbability;
  final List<double> normalizedFeatures;
  final double linearContribution;
  final double interactionContribution;
  final int interactionCount;

  const AdvancedCombinedFormulaResult({
    required this.score,
    required this.bullishProbability,
    required this.bearishProbability,
    required this.normalizedFeatures,
    required this.linearContribution,
    required this.interactionContribution,
    required this.interactionCount,
  });

  bool get bullish => score > 0;
  bool get bearish => score < 0;
  bool get neutral => score == 0;
}

class AdvancedCombinedFormulaEngine {
  static const int featureCount = 12;

  static const List<double> _baseWeights = <double>[
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
    1.0 / 12.0,
  ];

  final List<List<double>> _gamma = List<List<double>>.generate(
    featureCount,
    (i) => List<double>.generate(
      featureCount,
      (j) => i < j ? 0.01 : 0.0,
    ),
  );

  final List<double> _weights = List<double>.from(_baseWeights);

  int _learningCount = 0;
  double _lastLearningError = 0.0;
  double _lastLearningTarget = 0.0;
  double _lastPredictedScore = 0.0;

  List<double> get weights => List<double>.unmodifiable(_weights);
  int get learningCount => _learningCount;
  double get lastLearningError => _lastLearningError;
  double get lastLearningTarget => _lastLearningTarget;
  double get lastPredictedScore => _lastPredictedScore;

  double get weightDrift {
    var total = 0.0;
    for (var i = 0; i < featureCount; i++) {
      total += (_weights[i] - _baseWeights[i]).abs();
    }
    return total;
  }

  MapEntry<String, double> get strongestInteraction {
    var bestI = 0;
    var bestJ = 1;
    var bestValue = _gamma[0][1];
    for (var i = 0; i < featureCount; i++) {
      for (var j = i + 1; j < featureCount; j++) {
        if (_gamma[i][j].abs() > bestValue.abs()) {
          bestI = i;
          bestJ = j;
          bestValue = _gamma[i][j];
        }
      }
    }
    return MapEntry("$bestI-$bestJ", bestValue);
  }

  int get interactionCount => (featureCount * (featureCount - 1)) ~/ 2;

  Map<String, dynamic> exportLearningState() {
    final interactions = <double>[];
    for (var i = 0; i < featureCount; i++) {
      for (var j = i + 1; j < featureCount; j++) {
        interactions.add(_gamma[i][j]);
      }
    }

    return <String, dynamic>{
      'version': 1,
      'featureCount': featureCount,
      'interactionCount': interactionCount,
      'weights': List<double>.from(_weights),
      'interactions': interactions,
      'learningCount': _learningCount,
      'lastLearningError': _lastLearningError,
      'lastLearningTarget': _lastLearningTarget,
      'lastPredictedScore': _lastPredictedScore,
    };
  }

  bool restoreLearningState(Map<String, dynamic> state) {
    try {
      final version = state['version'];
      final storedFeatureCount = state['featureCount'];
      final storedInteractionCount = state['interactionCount'];
      final storedWeights = state['weights'];
      final storedInteractions = state['interactions'];

      if (version != 1 ||
          storedFeatureCount != featureCount ||
          storedInteractionCount != interactionCount ||
          storedWeights is! List ||
          storedInteractions is! List ||
          storedWeights.length != featureCount ||
          storedInteractions.length != interactionCount) {
        return false;
      }

      final restoredWeights = storedWeights
          .map((value) => (value as num).toDouble())
          .toList(growable: false);
      final restoredInteractions = storedInteractions
          .map((value) => (value as num).toDouble())
          .toList(growable: false);

      if (restoredWeights.any((value) => !value.isFinite) ||
          restoredInteractions.any((value) => !value.isFinite)) {
        return false;
      }

      for (var i = 0; i < featureCount; i++) {
        _weights[i] = restoredWeights[i].clamp(-1.0, 1.0).toDouble();
      }

      var interactionIndex = 0;
      for (var i = 0; i < featureCount; i++) {
        for (var j = i + 1; j < featureCount; j++) {
          _gamma[i][j] = restoredInteractions[interactionIndex]
              .clamp(-0.25, 0.25)
              .toDouble();
          interactionIndex++;
        }
      }

      _learningCount = (state['learningCount'] as num?)?.toInt() ?? 0;
      _lastLearningError =
          (state['lastLearningError'] as num?)?.toDouble() ?? 0.0;
      _lastLearningTarget =
          (state['lastLearningTarget'] as num?)?.toDouble() ?? 0.0;
      _lastPredictedScore =
          (state['lastPredictedScore'] as num?)?.toDouble() ?? 0.0;

      return true;
    } catch (_) {
      return false;
    }
  }

  AdvancedCombinedFormulaResult analyze(
    AdvancedCombinedFormulaInput input,
  ) {
    final features = input.rawFeatures.map(_normalizeSigned).toList();

    if (features.length != featureCount) {
      throw StateError(
        'Advanced formula requires exactly $featureCount features.',
      );
    }

    var linear = 0.0;
    for (var i = 0; i < featureCount; i++) {
      linear += _weights[i] * features[i];
    }

    var interaction = 0.0;
    var pairs = 0;

    for (var i = 0; i < featureCount; i++) {
      for (var j = i + 1; j < featureCount; j++) {
        interaction += _gamma[i][j] * features[i] * features[j];
        pairs++;
      }
    }

    final combined = linear + interaction;
    final score = (tanh(combined) * 100.0).clamp(-100.0, 100.0).toDouble();

    final probabilityInput = combined.clamp(-20.0, 20.0).toDouble();
    final bullishProbability = 1.0 / (1.0 + exp(-probabilityInput));
    final bearishProbability = 1.0 - bullishProbability;

    return AdvancedCombinedFormulaResult(
      score: score,
      bullishProbability: bullishProbability,
      bearishProbability: bearishProbability,
      normalizedFeatures: List<double>.unmodifiable(features),
      linearContribution: linear,
      interactionContribution: interaction,
      interactionCount: pairs,
    );
  }

  void learn({
    required List<double> rawFeatures,
    required double predictedScore,
    required double target,
    double learningRate = 0.002,
  }) {
    if (rawFeatures.length != featureCount) return;

    final features = rawFeatures.map(_normalizeSigned).toList();
    final prediction = (predictedScore / 100.0).clamp(-1.0, 1.0).toDouble();
    final boundedTarget = target.clamp(-1.0, 1.0).toDouble();
    final error = boundedTarget - prediction;

    _learningCount++;
    _lastLearningError = error;
    _lastLearningTarget = boundedTarget;
    _lastPredictedScore = predictedScore;

    for (var i = 0; i < featureCount; i++) {
      _weights[i] += learningRate * error * features[i];
      _weights[i] = _weights[i].clamp(-1.0, 1.0).toDouble();
    }

    for (var i = 0; i < featureCount; i++) {
      for (var j = i + 1; j < featureCount; j++) {
        _gamma[i][j] += learningRate * error * features[i] * features[j];
        _gamma[i][j] = _gamma[i][j].clamp(-0.25, 0.25).toDouble();
      }
    }

    _normalizeWeights();
  }

  void _normalizeWeights() {
    final magnitude =
        _weights.fold<double>(0.0, (sum, value) => sum + value.abs());

    if (magnitude <= 1e-12) {
      for (var i = 0; i < featureCount; i++) {
        _weights[i] = _baseWeights[i];
      }
      return;
    }

    for (var i = 0; i < featureCount; i++) {
      _weights[i] /= magnitude;
    }
  }

  double _normalizeSigned(double value) {
    if (!value.isFinite) return 0.0;
    if (value.abs() > 1.0) {
      return tanh(value / 100.0);
    }
    return value.clamp(-1.0, 1.0).toDouble();
  }

  double tanh(double value) {
    final bounded = value.clamp(-20.0, 20.0).toDouble();
    final positive = exp(bounded);
    final negative = exp(-bounded);
    return (positive - negative) / (positive + negative);
  }
}
