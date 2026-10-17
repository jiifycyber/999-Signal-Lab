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
import '../intelligence/stage53_outcome_tracker.dart';
import '../intelligence/formula_learning_store.dart';
import '../intelligence/formula_outcome_history_store.dart';
import '../intelligence/duke_signal_history_store.dart';

class ScannerController {
  final IntelligenceStore intelligenceStore = IntelligenceStore();
  late final DukeLearningEngine dukeLearningEngine =
      DukeLearningEngine(intelligenceStore);
  late final AlertEngine alertEngine = AlertEngine(intelligenceStore);

  final MarketDataService marketDataService;
  final ScannerEngine scannerEngine;
  final AgentDukeScannerBridge dukeBridge = AgentDukeScannerBridge();
  final Stage53OutcomeTracker formulaOutcomeTracker = Stage53OutcomeTracker();
  final FormulaLearningStore formulaLearningStore = FormulaLearningStore();
  final FormulaOutcomeHistoryStore formulaOutcomeHistoryStore =
      FormulaOutcomeHistoryStore();
  final DukeSignalHistoryStore dukeSignalHistoryStore =
      DukeSignalHistoryStore();

  List<Stage53FormulaOutcome> get formulaOutcomes =>
      formulaOutcomeTracker.outcomes;

  double get formulaWinRate => formulaOutcomeTracker.winRate;

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

  bool _formulaLearningFrozen = false;
  bool _formulaRollbackEngaged = false;
  bool _dukeHistoryReady = false;

  bool get formulaLearningFrozen => _formulaLearningFrozen;
  bool get formulaRollbackEngaged => _formulaRollbackEngaged;

  String get formulaLearningMode {
    if (_formulaLearningFrozen && _formulaRollbackEngaged) {
      return 'ROLLBACK ACTIVE';
    }
    if (_formulaLearningFrozen) return 'FROZEN';
    if (formulaOutcomeTracker.validationStatus == 'CAUTION') {
      return 'CAUTION';
    }
    return 'ACTIVE';
  }

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

    unawaited(
      dukeSignalHistoryStore.restore(dukeBridge.duke.signalMemory).then<void>(
        (_) {
          _dukeHistoryReady = true;
          print(
              '[LEDGER-RESTORE] ready=true total=${dukeBridge.duke.signalMemory.records.length}');
        },
        onError: (_) {
          _dukeHistoryReady = true;
          print('[LEDGER-RESTORE-ERROR] ready=true');
        },
      ),
    );

    _quoteSubscription = marketDataService.quoteStream.listen(
      (quotes) {
        for (final quote in quotes) {
          _latestQuotes[quote.symbol] = quote;
          print('[PO-4 CONTROLLER] ${quote.symbol} ${quote.price}');
        }

        if (!_quoteController.isClosed) {
          _quoteController.add(_latestQuotes.values.toList());
        }

        // STAGE 53 — resolve matured 60-second predictions against
        // the first real incoming market quote at or after expiration.
        if (_dukeHistoryReady) {
          _resolveExpiredPredictions();
        }

        final updatedSignals = scannerEngine.analyze(quotes);

        for (final signal in updatedSignals) {
          final dukeResult = dukeBridge.analyzeSignal(signal);
          _latestDukeResults[signal.symbol] = dukeResult;

          final formulaSnapshot =
              scannerEngine.advancedFormulaFor(signal.symbol);
          final finalSignal = _applyDukeDecision(
            signal,
            dukeResult,
          );

          // FORMULA AUTHORITY LEDGER
          // One official 60-second paper prediction per symbol.
          // WAIT never opens a prediction.
          if (_dukeHistoryReady &&
              formulaSnapshot != null &&
              finalSignal.direction != TradeDirection.wait) {
            final alreadyOpen = dukeBridge.duke.signalMemory.records.any(
              (record) => record.isOpen && record.symbol == finalSignal.symbol,
            );

            final liveQuote = _latestQuotes[finalSignal.symbol];

            if (!alreadyOpen &&
                liveQuote != null &&
                liveQuote.price.isFinite &&
                liveQuote.price > 0) {
              final decision = _rawDirection(finalSignal.direction);

              print(
                  '[LEDGER-OPEN-TRY] ${finalSignal.symbol} ${_rawDirection(finalSignal.direction)} price=${liveQuote.price}');

              final signalRecord = dukeBridge.duke.signalMemory.recordSignal(
                symbol: finalSignal.symbol,
                decision: decision,
                confidence: finalSignal.confidence,
                entryPrice: liveQuote.price,
              );

              unawaited(
                dukeSignalHistoryStore.save(dukeBridge.duke.signalMemory),
              );

              print(
                  '[LEDGER-OPENED] id=${signalRecord.id} pending=${pendingPredictions}');

              formulaOutcomeTracker.track(
                id: signalRecord.id,
                symbol: finalSignal.symbol,
                liveDirection: decision,
                liveConfidence: finalSignal.confidence,
                entryPrice: signalRecord.entryPrice,
                stopLoss: finalSignal.stopLoss,
                setup: finalSignal.setup,
                openedAt: signalRecord.openedAt,
                formula: formulaSnapshot,
              );

              unawaited(
                formulaOutcomeHistoryStore.save(formulaOutcomeTracker),
              );
            }
          }

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

    // Start live Pocket Option market data immediately.
    // Learning/history restoration must never block the price feed.
    marketDataService.start();

    unawaited(
      Future.wait<bool>([
        formulaLearningStore.restore(
          scannerEngine.advancedFormulaLearningEngine,
        ),
        formulaOutcomeHistoryStore.restore(
          formulaOutcomeTracker,
        ),
      ]).then<void>(
        (_) {},
        onError: (_) {},
      ),
    );
  }

  void _resolveExpiredPredictions() {
    final openRecords = dukeBridge.duke.signalMemory.records
        .where((record) => record.isOpen)
        .toList();

    if (openRecords.isNotEmpty) {
      print('[LEDGER-RESOLVE] open=${openRecords.length}');
    }

    for (final record in openRecords) {
      final quote = _latestQuotes[record.symbol];

      if (quote == null || !quote.price.isFinite || quote.price <= 0) {
        continue;
      }

      final expiresAt = record.openedAt.add(const Duration(seconds: 60));

      // The resolver is market-data driven. It waits until the feed itself
      // has reached or passed the 60-second expiration timestamp.
      if (quote.timestamp.isBefore(expiresAt)) {
        final remaining = expiresAt.difference(quote.timestamp).inSeconds;
        print(
            '[LEDGER-WAIT] ${record.symbol} remaining=$remaining quote=${quote.timestamp.toIso8601String()} expires=${expiresAt.toIso8601String()}');
        continue;
      }

      final pending = formulaOutcomeTracker.pendingFor(record.id);

      final closed = dukeBridge.duke.closeSignal(
        id: record.id,
        exitPrice: quote.price,
      );

      if (closed == null) {
        print('[LEDGER-CLOSE-FAILED] ${record.id}');
        continue;
      }

      print(
          '[LEDGER-CLOSED] ${closed.symbol} ${closed.outcome} entry=${closed.entryPrice} exit=${closed.exitPrice}');

      unawaited(
        dukeSignalHistoryStore.save(dukeBridge.duke.signalMemory),
      );

      if (pending != null) {
        final riskDistance = (pending.entryPrice - pending.stopLoss).abs();

        final signedMove = pending.liveDirection == 'SELL'
            ? pending.entryPrice - quote.price
            : quote.price - pending.entryPrice;

        final resultR = riskDistance <= 1e-12 ? 0.0 : signedMove / riskDistance;

        intelligenceStore.addOutcome(
          TradeOutcomeRecord(
            symbol: pending.symbol,
            direction: pending.liveDirection,
            win: closed.outcome == 'WIN',
            resultR: resultR,
            timestamp: quote.timestamp,
            setup: pending.setup,
            confidence: pending.liveConfidence,
            outcome: closed.outcome == 'BREAKEVEN' ? 'TIE' : closed.outcome,
          ),
        );

        final formulaOutcome = formulaOutcomeTracker.resolve(
          id: record.id,
          exitPrice: quote.price,
          liveOutcome: closed.outcome,
          closedAt: quote.timestamp,
        );

        if (formulaOutcome != null) {
          unawaited(
            formulaOutcomeHistoryStore.save(formulaOutcomeTracker),
          );
        }

        // STAGE 59 — VALIDATION-GATED CALIBRATION + ROLLBACK PROTECTION
        //
        // DEGRADED: freeze learning and restore the last HEALTHY checkpoint.
        // CAUTION: use a reduced learning rate unless recovering from DEGRADED.
        // HEALTHY: allow bounded learning and refresh the known-good checkpoint.
        if (formulaOutcome != null) {
          final validationStatus = formulaOutcomeTracker.validationStatus;

          if (validationStatus == 'DEGRADED') {
            if (!_formulaLearningFrozen) {
              _formulaLearningFrozen = true;
              unawaited(_rollbackFormulaToKnownGood());
            }
          } else {
            if (_formulaLearningFrozen) {
              if (validationStatus == 'HEALTHY') {
                _formulaLearningFrozen = false;
                _formulaRollbackEngaged = false;
              }
            }

            if (!_formulaLearningFrozen) {
              if (validationStatus == 'HEALTHY') {
                unawaited(
                  formulaLearningStore.saveKnownGood(
                    scannerEngine.advancedFormulaLearningEngine,
                  ),
                );
              }

              final marketMove =
                  formulaOutcome.exitPrice - formulaOutcome.entryPrice;
              final tieBand = formulaOutcome.entryPrice.abs() * 0.0001;

              if (marketMove.abs() > tieBand) {
                final target = marketMove > 0 ? 1.0 : -1.0;
                final learningRate =
                    validationStatus == 'CAUTION' ? 0.00025 : 0.0005;

                scannerEngine.learnAdvancedFormula(
                  features: formulaOutcome.formulaFeatures,
                  predictedScore: formulaOutcome.formulaScore,
                  target: target,
                  learningRate: learningRate,
                );

                unawaited(
                  formulaLearningStore.save(
                    scannerEngine.advancedFormulaLearningEngine,
                  ),
                );
              }
            }
          }
        }
      }

      // Refresh the existing learning summary only after a verified
      // 60-second outcome has actually been recorded.
      dukeLearningEngine.analyze();
    }
  }

  Future<void> _rollbackFormulaToKnownGood() async {
    final restored = await formulaLearningStore.restoreKnownGood(
      scannerEngine.advancedFormulaLearningEngine,
    );

    if (restored) {
      _formulaRollbackEngaged = true;
      await formulaLearningStore.save(
        scannerEngine.advancedFormulaLearningEngine,
      );
    }
  }

  ScanSignal _applyDukeDecision(
    ScanSignal signal,
    DukeMasterResult dukeResult,
  ) {
    // HARD TREND DIRECTION LOCK
    //
    // ScannerEngine owns market direction.
    // Duke evaluates quality and confidence, but cannot flip
    // a bullish market to SELL or a bearish market to BUY.
    //
    // This prevents short-term oscillator or M1 pullback noise
    // from creating counter-trend trades.
    final TradeDirection finalDirection = signal.direction;

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
