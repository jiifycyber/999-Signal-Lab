import '../models/scan_signal.dart';
import 'agent_duke_multitimeframe.dart';
import 'agent_duke_master_engine.dart';

class AgentDukeScannerBridge {
  final AgentDukeMasterEngine duke;

  AgentDukeScannerBridge({
    AgentDukeMasterEngine? duke,
  }) : duke = duke ?? AgentDukeMasterEngine();

  DukeMasterResult analyzeSignal(ScanSignal signal) {
    final directionBias = switch (signal.direction) {
      TradeDirection.buy => 1.0,
      TradeDirection.sell => -1.0,
      TradeDirection.wait => 0.0,
    };

    final confidence = signal.confidence.clamp(0.0, 100.0).toDouble();

    // -----------------------------------------------------------
    // IMPORTANT:
    //
    // OLD VERSION:
    // M1 / M5 / M15 were fabricated by multiplying one signal.
    //
    // NEW VERSION:
    // ScannerEngine supplies independently calculated timeframe
    // scores from actual M1, aggregated M5 and aggregated M15
    // Pocket Option candle data.
    // -----------------------------------------------------------

    double signedVolatility(double timeframeScore) {
      if (timeframeScore > 0) {
        return signal.volatilityScore;
      }

      if (timeframeScore < 0) {
        return -signal.volatilityScore;
      }

      return signal.volatilityScore * directionBias;
    }

    final oneMinute = DukeTimeframeInput(
      timeframe: '1M',
      trend: signal.m1Score,
      momentum: signal.m1Score,
      structure: signal.structureScore,
      volatility: signedVolatility(signal.m1Score),
    );

    final fiveMinute = DukeTimeframeInput(
      timeframe: '5M',
      trend: signal.m5Score,
      momentum: signal.m5Score,
      structure: signal.structureScore * 0.70,
      volatility: signedVolatility(signal.m5Score),
    );

    final fifteenMinute = DukeTimeframeInput(
      timeframe: '15M',
      trend: signal.m15Score,
      momentum: signal.m15Score,
      structure: signal.structureScore * 0.50,
      volatility: signedVolatility(signal.m15Score),
    );

    return duke.analyze(
      DukeMasterInput(
        symbol: signal.symbol,
        currentPrice: signal.entry,
        oneMinute: oneMinute,
        fiveMinute: fiveMinute,
        fifteenMinute: fifteenMinute,
        spreadQuality: confidence,
        structureQuality:
            signal.structureScore.abs().clamp(0.0, 100.0).toDouble(),
        trendStrength: signal.m1Score,
        volatility: signal.volatilityScore.clamp(0.0, 100.0).toDouble(),
      ),
    );
  }
}
