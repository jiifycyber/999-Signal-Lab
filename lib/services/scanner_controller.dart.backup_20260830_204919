import 'dart:async';

import '../models/forex_quote.dart';
import '../models/scan_signal.dart';
import '../ai/agent_duke_scanner_bridge.dart';
import '../ai/agent_duke_master_engine.dart';
import '../ai/agent_duke_signal_memory.dart';
import 'market_data_service.dart';
import 'scanner_engine.dart';
import '../intelligence/intelligence_models.dart';
import '../intelligence/intelligence_store.dart';
import '../intelligence/duke_learning_engine.dart';
import '../intelligence/alert_engine.dart';

class ScannerController {
  final IntelligenceStore intelligenceStore = IntelligenceStore();
  late final DukeLearningEngine dukeLearningEngine =
      DukeLearningEngine(intelligenceStore);
  late final AlertEngine alertEngine = AlertEngine(intelligenceStore);

  final MarketDataService marketDataService;
  final ScannerEngine scannerEngine;
  final AgentDukeScannerBridge dukeBridge = AgentDukeScannerBridge();

  ScannerController({
    MarketDataService? marketDataService,
    ScannerEngine? scannerEngine,
  })  : marketDataService = marketDataService ?? MarketDataService(),
        scannerEngine = scannerEngine ?? ScannerEngine();

  final StreamController<List<ScanSignal>> _signalController =
      StreamController<List<ScanSignal>>.broadcast();

  final StreamController<List<ForexQuote>> _quoteController =
      StreamController<List<ForexQuote>>.broadcast();

  StreamSubscription<List<ForexQuote>>? _quoteSubscription;

  final Map<String, ForexQuote> _latestQuotes = {};
  final Map<String, ScanSignal> _latestSignals = {};
  final Map<String, DukeMasterResult> _latestDukeResults = {};

  Stream<List<ScanSignal>> get signalStream => _signalController.stream;

  int get pendingPredictions => dukeBridge.duke.signalMemory.records
      .where((record) => record.isOpen)
      .length;

  DukePerformanceSummary get dukePerformance => dukeBridge.duke.performance();

  DukeLearningSnapshot get learningSnapshot => dukeLearningEngine.analyze();

  Map<String, DukeMasterResult> get dukeResults =>
      Map.unmodifiable(_latestDukeResults);
  Stream<List<ForexQuote>> get quoteStream => _quoteController.stream;

  void start() {
    _quoteSubscription?.cancel();

    _quoteSubscription = marketDataService.quoteStream.listen(
      (quotes) {
        for (final quote in quotes) {
          _latestQuotes[quote.symbol] = quote;
        }

        if (!_quoteController.isClosed) {
          _quoteController.add(_latestQuotes.values.toList());
        }

        final updatedSignals = scannerEngine.analyze(quotes);

        for (final signal in updatedSignals) {
          final dukeResult = dukeBridge.analyzeSignal(signal);
          _latestDukeResults[signal.symbol] = dukeResult;

          final finalSignal = _applyDukeDecision(
            signal,
            dukeResult,
          );

          _latestSignals[finalSignal.symbol] = finalSignal;

          // Persist signal into intelligence memory.
          intelligenceStore.addSignal(
            SignalHistoryRecord(
              symbol: finalSignal.symbol,
              direction: _rawDirection(finalSignal.direction),
              confidence: finalSignal.confidence,
              entry: finalSignal.entry,
              stopLoss: finalSignal.stopLoss,
              tp1: finalSignal.takeProfit1,
              tp2: finalSignal.takeProfit2,
              tp3: finalSignal.takeProfit3,
              timestamp: finalSignal.timestamp,
              setup: finalSignal.setup,
              trend: finalSignal.trend,
              momentum: finalSignal.momentum,
            ),
          );

          // Evaluate all active alert rules.
          alertEngine.evaluate(
            symbol: finalSignal.symbol,
            direction: _rawDirection(finalSignal.direction),
            confidence: finalSignal.confidence,
            dukeApproved: dukeResult.tradeApproved,
          );

          // Keep Duke's learning model hot as new data arrives.
          dukeLearningEngine.analyze();
        }

        final mergedSignals = _latestSignals.values.toList()
          ..sort(
            (a, b) => b.confidence.compareTo(a.confidence),
          );

        if (!_signalController.isClosed) {
          _signalController.add(mergedSignals);
        }
      },
    );

    marketDataService.start();
  }

  ScanSignal _applyDukeDecision(
    ScanSignal signal,
    DukeMasterResult dukeResult,
  ) {
    TradeDirection finalDirection = TradeDirection.wait;

    if (dukeResult.tradeApproved) {
      if (dukeResult.decision == 'BUY') {
        finalDirection = TradeDirection.buy;
      } else if (dukeResult.decision == 'SELL') {
        finalDirection = TradeDirection.sell;
      }
    }

    final finalConfidence =
        ((signal.confidence * 0.40) + (dukeResult.qualityScore * 0.60))
            .clamp(0.0, 100.0)
            .toDouble();

    return ScanSignal(
      symbol: signal.symbol,
      direction: finalDirection,
      confidence: finalConfidence,
      score: dukeResult.qualityScore / 10.0,
      entry: signal.entry,
      stopLoss: signal.stopLoss,
      takeProfit1: signal.takeProfit1,
      takeProfit2: signal.takeProfit2,
      takeProfit3: signal.takeProfit3,
      trend: signal.trend,
      momentum: signal.momentum,
      setup: signal.setup,
      timestamp: signal.timestamp,
      support: signal.support,
      resistance: signal.resistance,
      minEntry: signal.minEntry,
      maxEntry: signal.maxEntry,
      m1Score: signal.m1Score,
      m5Score: signal.m5Score,
      m15Score: signal.m15Score,
      structureScore: signal.structureScore,
      volatilityScore: signal.volatilityScore,
      regime: signal.regime,
      analysis: signal.analysis,
    );
  }

  String _rawDirection(TradeDirection direction) {
    switch (direction) {
      case TradeDirection.buy:
        return 'BUY';
      case TradeDirection.sell:
        return 'SELL';
      case TradeDirection.wait:
        return 'WAIT';
    }
  }

  DukeMasterResult? deepScan(String symbol) {
    final signal = _latestSignals[symbol];

    if (signal == null) {
      return null;
    }

    final result = dukeBridge.analyzeSignal(signal);

    _latestDukeResults[symbol] = result;

    return result;
  }

  List<DukeMasterResult> deepScanAll() {
    final results = <DukeMasterResult>[];

    for (final signal in _latestSignals.values) {
      final result = dukeBridge.analyzeSignal(signal);

      _latestDukeResults[signal.symbol] = result;
      results.add(result);
    }

    results.sort(
      (a, b) => b.qualityScore.compareTo(a.qualityScore),
    );

    return results;
  }

  void setDemoMode() {
    marketDataService.setMode(MarketMode.demo);
  }

  void setLiveMode() {
    marketDataService.setMode(MarketMode.live);
  }

  void dispose() {
    _quoteSubscription?.cancel();
    marketDataService.dispose();
    _signalController.close();
    _quoteController.close();
  }
}
