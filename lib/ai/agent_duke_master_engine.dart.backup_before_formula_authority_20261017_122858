import '../intelligence/adaptive_trading_brain.dart';
import 'agent_duke_adaptive_weights.dart';
import 'agent_duke_multitimeframe.dart';
import 'agent_duke_signal_memory.dart';
import 'agent_duke_trade_gate.dart';

class DukeMasterInput {
  final String symbol;
  final double currentPrice;
  final DukeTimeframeInput oneMinute;
  final DukeTimeframeInput fiveMinute;
  final DukeTimeframeInput fifteenMinute;
  final double spreadQuality;
  final double structureQuality;
  final double trendStrength;
  final double volatility;

  const DukeMasterInput({
    required this.symbol,
    required this.currentPrice,
    required this.oneMinute,
    required this.fiveMinute,
    required this.fifteenMinute,
    required this.spreadQuality,
    required this.structureQuality,
    required this.trendStrength,
    required this.volatility,
  });
}

class DukeMasterResult {
  final String symbol;
  final String decision;
  final double confidence;
  final double qualityScore;
  final bool tradeApproved;
  final String explanation;
  final DukeSignalRecord? signalRecord;

  const DukeMasterResult({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.qualityScore,
    required this.tradeApproved,
    required this.explanation,
    required this.signalRecord,
  });
}

/// 999 / DUKE 60-SECOND FORECAST MASTER ENGINE
///
/// Direction and qualification are separated.
///
/// Direction:
/// ALWAYS BUY or SELL when market analysis is available.
///
/// Quality:
/// Used to rank and learn from signals.
///
/// The adaptive brain no longer has permission to replace
/// Duke's directional answer with WAIT.
class AgentDukeMasterEngine {
  final AgentDukeMultiTimeframe multiTimeframe;
  final AgentDukeTradeGate tradeGate;
  final AgentDukeSignalMemory signalMemory;
  final DukeAdaptiveWeights adaptiveWeights;

  AgentDukeMasterEngine({
    AgentDukeMultiTimeframe? multiTimeframe,
    AgentDukeTradeGate? tradeGate,
    AgentDukeSignalMemory? signalMemory,
    DukeAdaptiveWeights? adaptiveWeights,
  })  : multiTimeframe = multiTimeframe ?? const AgentDukeMultiTimeframe(),
        tradeGate = tradeGate ?? const AgentDukeTradeGate(),
        signalMemory = signalMemory ?? AgentDukeSignalMemory(),
        adaptiveWeights = adaptiveWeights ?? DukeAdaptiveWeights();

  DukeMasterResult analyze(
    DukeMasterInput input,
  ) {
    final timeframeResult = multiTimeframe.analyze(
      symbol: input.symbol,
      oneMinute: input.oneMinute,
      fiveMinute: input.fiveMinute,
      fifteenMinute: input.fifteenMinute,
    );

    final aligned = timeframeResult.bullishTimeframes >= 2 ||
        timeframeResult.bearishTimeframes >= 2;

    final gateResult = tradeGate.evaluate(
      DukeTradeGateInput(
        symbol: input.symbol,
        proposedDecision: timeframeResult.decision,
        confidence: timeframeResult.confidence,
        trendStrength: input.trendStrength,
        volatility: input.volatility,
        spreadQuality: input.spreadQuality,
        structureQuality: input.structureQuality,
        multiTimeframeAligned: aligned,
      ),
    );

    double conflictScore;

    if (timeframeResult.bullishTimeframes == 3 ||
        timeframeResult.bearishTimeframes == 3) {
      conflictScore = 8;
    } else if (aligned) {
      conflictScore = 22;
    } else {
      conflictScore = 55;
    }

    final performance = signalMemory.performance();

    final historicalEdge = performance.closedSignals >= 10
        ? performance.winRate.clamp(25.0, 85.0).toDouble()
        : 50.0;

    final learningAdjustment = performance.closedSignals >= 10
        ? ((performance.winRate - 50.0) * 0.10).clamp(-5.0, 5.0).toDouble()
        : 0.0;

    final adaptiveDecision = AdaptiveTradingBrain.evaluate(
      confidence: timeframeResult.confidence,
      trend: input.trendStrength.abs(),
      momentum: input.oneMinute.momentum.abs(),
      structure: input.structureQuality,
      volatility: input.volatility,
      timeframeAlignment: aligned ? 92.0 : 58.0,
      historicalEdge: historicalEdge,
      conflict: conflictScore,
      learningAdjustment: learningAdjustment,
    );

    // ----------------------------------------------------------
    // THE IMPORTANT CHANGE
    //
    // OLD:
    // finalApproved ? BUY/SELL : WAIT
    //
    // NEW:
    // Duke's best directional forecast always survives.
    // ----------------------------------------------------------
    final finalDecision = timeframeResult.decision == 'SELL' ? 'SELL' : 'BUY';

    // Ranking/quality can still use the adaptive engine.
    final combinedQuality = ((adaptiveDecision.adaptiveScore * 0.60) +
            (gateResult.qualityScore * 0.20) +
            (timeframeResult.confidence * 0.20))
        .clamp(0.0, 100.0)
        .toDouble();

    // Avoid flooding signal memory with every weak tick.
    // This affects learning records ONLY.
    // It does NOT remove BUY/SELL from the live scanner.
    final recordForLearning =
        adaptiveDecision.qualified && gateResult.tradeApproved;

    DukeSignalRecord? record;

    if (recordForLearning) {
      record = signalMemory.recordSignal(
        symbol: input.symbol,
        decision: finalDecision,
        confidence: combinedQuality,
        entryPrice: input.currentPrice,
      );
    }

    final explanation = 'Duke 60-second forecast: '
        '$finalDecision ${input.symbol}. '
        'M1-first confidence '
        '${timeframeResult.confidence.toStringAsFixed(1)}%. '
        'Adaptive quality '
        '${combinedQuality.toStringAsFixed(1)}. '
        'Quality affects ranking, not direction.';

    return DukeMasterResult(
      symbol: input.symbol,
      decision: finalDecision,
      confidence: timeframeResult.confidence,
      qualityScore: combinedQuality,
      tradeApproved: true,
      explanation: explanation,
      signalRecord: record,
    );
  }

  DukeSignalRecord? closeSignal({
    required String id,
    required double exitPrice,
  }) {
    return signalMemory.closeSignal(
      id: id,
      exitPrice: exitPrice,
    );
  }

  DukePerformanceSummary performance() {
    return signalMemory.performance();
  }

  Map<String, double> learningWeights() {
    return adaptiveWeights.snapshot();
  }
}
