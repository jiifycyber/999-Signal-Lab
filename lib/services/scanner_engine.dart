import 'dart:math';

import '../models/forex_quote.dart';
import '../intelligence/price_dynamics_engine.dart';
import '../intelligence/market_geometry_engine.dart';
import '../intelligence/advanced_combined_formula_engine.dart';
import '../models/scan_signal.dart';

/// ===============================================================
/// 999 SIGNAL INTELLIGENCE PRO
/// ADVANCED 60-SECOND QUANTITATIVE MARKET ANALYSIS ENGINE
///
/// LIVE INPUT:
/// Pocket Option ticks delivered by the existing bridge.
///
/// ANALYTICAL STACK:
/// - Real M1 OHLC construction
/// - Real M5 aggregation
/// - Real M15 aggregation
/// - EMA trend analysis
/// - RSI momentum
/// - MACD momentum
/// - Bollinger location
/// - Stochastic
/// - Rate of change
/// - ATR volatility
/// - ADX-style directional strength
/// - Swing-high / swing-low market structure
/// - Support / resistance
/// - Breakout detection
/// - Candle body / wick price action
/// - Market regime classification
/// - Actual multi-timeframe ensemble
///
/// This engine does NOT modify the Pocket Option connection.
/// ===============================================================
class ScannerEngine {
  final Map<String, List<_MarketCandle>> _closedM1 = {};
  final Map<String, _MarketCandle> _activeM1 = {};
  final Map<String, List<double>> _tickHistory = {};
  final Map<String, List<PriceObservation>> _dynamicsHistory = {};
  final Map<String, PriceDynamicsResult> _dynamicsResults = {};
  final Map<String, List<MarketGeometryPoint>> _geometryHistory = {};
  final Map<String, MarketGeometryResult> _geometryResults = {};
  final AdvancedCombinedFormulaEngine _advancedFormulaEngine =
      AdvancedCombinedFormulaEngine();
  final Map<String, AdvancedCombinedFormulaResult> _advancedFormulaResults = {};

  PriceDynamicsResult? dynamicsFor(String symbol) => _dynamicsResults[symbol];
  MarketGeometryResult? geometryFor(String symbol) => _geometryResults[symbol];
  AdvancedCombinedFormulaResult? advancedFormulaFor(String symbol) =>
      _advancedFormulaResults[symbol];

  AdvancedCombinedFormulaEngine get advancedFormulaLearningEngine =>
      _advancedFormulaEngine;

  List<double> get advancedFormulaWeights => _advancedFormulaEngine.weights;
  int get advancedFormulaLearningCount => _advancedFormulaEngine.learningCount;
  double get advancedFormulaWeightDrift => _advancedFormulaEngine.weightDrift;
  double get advancedFormulaLastError =>
      _advancedFormulaEngine.lastLearningError;
  double get advancedFormulaLastTarget =>
      _advancedFormulaEngine.lastLearningTarget;
  double get advancedFormulaLastPredictedScore =>
      _advancedFormulaEngine.lastPredictedScore;
  MapEntry<String, double> get advancedFormulaStrongestInteraction =>
      _advancedFormulaEngine.strongestInteraction;

  void learnAdvancedFormula({
    required List<double> features,
    required double predictedScore,
    required double target,
    double learningRate = 0.0005,
  }) {
    _advancedFormulaEngine.learn(
      rawFeatures: features,
      predictedScore: predictedScore,
      target: target,
      learningRate: learningRate,
    );
  }

  List<ScanSignal> analyze(List<ForexQuote> quotes) {
    final results = <ScanSignal>[];

    for (final quote in quotes) {
      if (!quote.price.isFinite || quote.price <= 0) continue;

      _ingestTick(quote);

      final history = _dynamicsHistory.putIfAbsent(
          quote.symbol, () => <PriceObservation>[]);
      if (history.isEmpty || quote.timestamp.isAfter(history.last.timestamp)) {
        history.add(PriceObservation(quote.price, quote.timestamp));
        if (history.length > 100) history.removeAt(0);
        _dynamicsResults[quote.symbol] = PriceDynamicsEngine.analyze(history);
      }

      final geometryHistory = _geometryHistory.putIfAbsent(
        quote.symbol,
        () => <MarketGeometryPoint>[],
      );
      if (geometryHistory.isEmpty ||
          quote.timestamp.isAfter(geometryHistory.last.timestamp)) {
        geometryHistory.add(MarketGeometryPoint(quote.price, quote.timestamp));
        if (geometryHistory.length > 120) {
          geometryHistory.removeAt(0);
        }
        _geometryResults[quote.symbol] =
            MarketGeometryEngine.analyze(geometryHistory);
      }

      final m1 = _m1Series(quote.symbol);
      final m5 = _aggregateCandles(m1, 5);
      final m15 = _aggregateCandles(m1, 15);

      results.add(
        _analyzeMarket(
          quote: quote,
          m1: m1,
          m5: m5,
          m15: m15,
        ),
      );
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  // =============================================================
  // REAL CANDLE CONSTRUCTION
  // =============================================================

  void _ingestTick(ForexQuote quote) {
    final ticks = _tickHistory.putIfAbsent(
      quote.symbol,
      () => <double>[],
    );

    ticks.add(quote.price);

    if (ticks.length > 500) {
      ticks.removeRange(0, ticks.length - 500);
    }

    final bucket = DateTime.fromMillisecondsSinceEpoch(
      (quote.timestamp.millisecondsSinceEpoch ~/ 60000) * 60000,
    );

    final active = _activeM1[quote.symbol];

    if (active == null) {
      _activeM1[quote.symbol] = _MarketCandle(
        start: bucket,
        open: quote.price,
        high: quote.price,
        low: quote.price,
        close: quote.price,
      );

      return;
    }

    if (active.start == bucket) {
      active.update(quote.price);
      return;
    }

    final history = _closedM1.putIfAbsent(
      quote.symbol,
      () => <_MarketCandle>[],
    );

    history.add(active.copy());

    if (history.length > 1000) {
      history.removeRange(0, history.length - 1000);
    }

    _activeM1[quote.symbol] = _MarketCandle(
      start: bucket,
      open: quote.price,
      high: quote.price,
      low: quote.price,
      close: quote.price,
    );
  }

  List<_MarketCandle> _m1Series(String symbol) {
    final values = <_MarketCandle>[
      ...?_closedM1[symbol]?.map((e) => e.copy()),
    ];

    final active = _activeM1[symbol];

    if (active != null) {
      values.add(active.copy());
    }

    return values;
  }

  List<_MarketCandle> _aggregateCandles(
    List<_MarketCandle> source,
    int minutes,
  ) {
    if (source.isEmpty) return const [];

    final result = <_MarketCandle>[];
    _MarketCandle? current;
    int? currentBucket;

    final intervalMs = Duration(minutes: minutes).inMilliseconds;

    for (final candle in source) {
      final bucket = candle.start.millisecondsSinceEpoch ~/ intervalMs;

      if (current == null || currentBucket != bucket) {
        if (current != null) {
          result.add(current);
        }

        currentBucket = bucket;

        current = _MarketCandle(
          start: DateTime.fromMillisecondsSinceEpoch(
            bucket * intervalMs,
          ),
          open: candle.open,
          high: candle.high,
          low: candle.low,
          close: candle.close,
        );
      } else {
        current.high = max(current.high, candle.high);
        current.low = min(current.low, candle.low);
        current.close = candle.close;
      }
    }

    if (current != null) {
      result.add(current);
    }

    return result;
  }

  // =============================================================
  // MASTER ANALYSIS
  // =============================================================

  ScanSignal _analyzeMarket({
    required ForexQuote quote,
    required List<_MarketCandle> m1,
    required List<_MarketCandle> m5,
    required List<_MarketCandle> m15,
  }) {
    final m1Analysis = _analyzeTimeframe(m1);
    final m5Analysis = _analyzeTimeframe(m5);
    final m15Analysis = _analyzeTimeframe(m15);

    final ticks = _tickHistory[quote.symbol] ?? const <double>[];

    final tickScore = _tickMomentumScore(ticks);

    // =============================================================
    // ADVANCED FORMULA EVIDENCE LAYER
    //
    // M1 / M5 / M15 and tick momentum are evidence only.
    // They do not own final direction.
    // =============================================================
    final dynamics = _dynamicsResults[quote.symbol];
    final geometry = _geometryResults[quote.symbol];

    if (dynamics != null && geometry != null) {
      final fallbackScale = max(
        _fallbackDistance(quote.symbol, quote.price),
        quote.price.abs() * 0.000001,
      );

      final velocityFeature =
          (dynamics.velocity / fallbackScale).clamp(-1.0, 1.0).toDouble();

      final accelerationFeature =
          (dynamics.acceleration / fallbackScale).clamp(-1.0, 1.0).toDouble();

      final jerkFeature =
          (dynamics.jerk / fallbackScale).clamp(-1.0, 1.0).toDouble();

      // Intrinsic short-horizon orientation comes from measured motion.
      final motionComposite = ((velocityFeature * 0.50) +
              (accelerationFeature * 0.30) +
              (jerkFeature * 0.20))
          .clamp(-1.0, 1.0)
          .toDouble();

      final orientation = motionComposite > 0
          ? 1.0
          : motionComposite < 0
              ? -1.0
              : 0.0;

      final volatilityFeature = orientation *
          (dynamics.volatility * 1000.0).clamp(0.0, 1.0).toDouble();

      // Balanced market evidence enters the formula as one feature.
      // It is not a separate directional authority.
      final probabilityFeature = ((m1Analysis.score +
                  m5Analysis.score +
                  m15Analysis.score +
                  tickScore) /
              400.0)
          .clamp(-1.0, 1.0)
          .toDouble();

      // Formula feature #6 uses the most recent verified learning error.
      final predictionErrorLearningFeature =
          _advancedFormulaEngine.lastLearningError.clamp(-1.0, 1.0).toDouble();

      final rectilinearFeature = orientation *
          (geometry.rectilinearScore / 100.0).clamp(0.0, 1.0).toDouble();

      final orthogonalFeature = orientation *
          geometry.orthogonalEfficiency.clamp(0.0, 1.0).toDouble();

      final junctionBranchFeature = orientation *
          (((geometry.junctionCount + geometry.branchCount) / 10.0)
              .clamp(0.0, 1.0)
              .toDouble());

      final adaptiveGridFeature = orientation *
          (geometry.gridSize / fallbackScale).clamp(0.0, 1.0).toDouble();

      final transitionFeature = orientation *
          geometry.transitionProbability.clamp(0.0, 1.0).toDouble();

      final pathErrorFeature =
          -orientation * geometry.pathError.abs().clamp(0.0, 1.0).toDouble();

      _advancedFormulaResults[quote.symbol] = _advancedFormulaEngine.analyze(
        AdvancedCombinedFormulaInput(
          velocity: velocityFeature,
          acceleration: accelerationFeature,
          jerk: jerkFeature,
          volatility: volatilityFeature,
          probability: probabilityFeature,
          predictionErrorLearning: predictionErrorLearningFeature,
          rectilinearNetwork: rectilinearFeature,
          orthogonalPathEfficiency: orthogonalFeature,
          junctionBranch: junctionBranchFeature,
          adaptiveGrid: adaptiveGridFeature,
          transitionProbability: transitionFeature,
          pathErrorLearning: pathErrorFeature,
        ),
      );
    }

    TradeDirection direction = TradeDirection.wait;

    // FORMULA AUTHORITY — final BUY / SELL / WAIT decision.
    final formulaResult = _advancedFormulaResults[quote.symbol];
    final formulaScore = formulaResult?.score ?? 0.0;
    final bullishProbability = formulaResult?.bullishProbability ?? 0.5;
    final bearishProbability = formulaResult?.bearishProbability ?? 0.5;

    if (formulaResult != null) {
      if (formulaScore > 0.0 && bullishProbability >= 0.55) {
        direction = TradeDirection.buy;
      } else if (formulaScore < 0.0 && bearishProbability >= 0.55) {
        direction = TradeDirection.sell;
      }
    }

    final buy = direction == TradeDirection.buy;

    final atr = max(
      m1Analysis.atr,
      _fallbackDistance(quote.symbol, quote.price),
    );

    final levels = _findStructuralLevels(
      candles: m1,
      currentPrice: quote.price,
      atr: atr,
      buy: buy,
    );

    final regime = _detectRegime(
      m1Analysis,
      levels,
      quote.price,
    );

    // Do not pretend the system has mature confidence when only a
    // handful of candles exist.
    final maturity = (m1.length / 30.0).clamp(0.15, 1.0).toDouble();

    final directionalStrength = formulaScore.abs().clamp(0.0, 100.0).toDouble();
    final formulaConfidence = ((bullishProbability > bearishProbability
                ? bullishProbability
                : bearishProbability) *
            100.0)
        .clamp(50.0, 99.9)
        .toDouble();
    final confidence = (50.0 + ((formulaConfidence - 50.0) * maturity))
        .clamp(50.0, 99.9)
        .toDouble();

    final riskDistance = max(
      atr * 0.80,
      _fallbackDistance(quote.symbol, quote.price),
    );

    final stopLoss =
        buy ? quote.price - riskDistance : quote.price + riskDistance;

    final takeProfit1 =
        buy ? quote.price + riskDistance : quote.price - riskDistance;

    final takeProfit2 = buy
        ? quote.price + (riskDistance * 1.7)
        : quote.price - (riskDistance * 1.7);

    final takeProfit3 = buy
        ? quote.price + (riskDistance * 2.5)
        : quote.price - (riskDistance * 2.5);

    final trend = _trendLabel(
      m1Analysis.score,
      m5Analysis.score,
      m15Analysis.score,
    );

    final momentum = _momentumLabel(
      m1Analysis.rsi,
      m1Analysis.macdImpulse,
      tickScore,
    );

    final setup = 'ADVANCED $regime • ${m1Analysis.structureLabel}';

    final analysis = 'M1 ${m1Analysis.score.toStringAsFixed(1)} | '
        'M5 ${m5Analysis.score.toStringAsFixed(1)} | '
        'M15 ${m15Analysis.score.toStringAsFixed(1)} | '
        'RSI ${m1Analysis.rsi.toStringAsFixed(1)} | '
        'ADX ${m1Analysis.adx.toStringAsFixed(1)} | '
        'ATR ${m1Analysis.atr.toStringAsFixed(6)} | '
        'Structure ${m1Analysis.structureScore.toStringAsFixed(1)} | '
        '$regime';

    return ScanSignal(
      symbol: quote.symbol,
      direction: direction,
      confidence: confidence,
      score: directionalStrength / 10.0,
      entry: quote.price,
      stopLoss: stopLoss,
      takeProfit1: takeProfit1,
      takeProfit2: takeProfit2,
      takeProfit3: takeProfit3,
      trend: trend,
      momentum: momentum,
      setup: setup,
      timestamp: quote.timestamp,
      support: levels.support,
      resistance: levels.resistance,
      minEntry: levels.minEntry,
      maxEntry: levels.maxEntry,
      m1Score: m1Analysis.score,
      m5Score: m5Analysis.score,
      m15Score: m15Analysis.score,
      structureScore: m1Analysis.structureScore,
      volatilityScore: m1Analysis.volatilityScore,
      regime: regime,
      analysis: analysis,
    );
  }

  // =============================================================
  // TIMEFRAME ENGINE
  // =============================================================

  _TimeframeAnalysis _analyzeTimeframe(
    List<_MarketCandle> candles,
  ) {
    if (candles.isEmpty) {
      return const _TimeframeAnalysis.neutral();
    }

    final closes = candles.map((e) => e.close).toList();

    final ema9 = _ema(closes, 9);
    final ema21 = _ema(closes, 21);
    final ema50 = _ema(closes, 50);

    final rsi = _rsi(closes, 14);
    final atr = _atr(candles, 14);
    final adx = _adx(candles, 14);
    final stochastic = _stochastic(candles, 14);
    final roc = _roc(closes, 8);

    final macdNow = _macd(closes);

    double macdPrevious = 0;

    if (closes.length > 3) {
      macdPrevious = _macd(
        closes.sublist(0, closes.length - 1),
      );
    }

    final macdImpulse = macdNow - macdPrevious;

    final bollinger = _bollingerPosition(closes, 20);

    final structure = _marketStructure(candles);

    final priceAction = _priceActionScore(candles);

    double score = 0;

    // ---------------------------------------------------------
    // TREND
    // ---------------------------------------------------------

    if (ema9 > ema21) {
      score += 16;
    } else if (ema9 < ema21) {
      score -= 16;
    }

    if (ema21 > ema50) {
      score += 11;
    } else if (ema21 < ema50) {
      score -= 11;
    }

    if (closes.last > ema9) {
      score += 6;
    } else if (closes.last < ema9) {
      score -= 6;
    }

    // ---------------------------------------------------------
    // RSI
    // ---------------------------------------------------------

    if (rsi > 52) {
      score += min(10.0, (rsi - 50) * 0.45);
    } else if (rsi < 48) {
      score -= min(10.0, (50 - rsi) * 0.45);
    }

    // ---------------------------------------------------------
    // MACD IMPULSE
    // ---------------------------------------------------------

    if (macdImpulse > 0) {
      score += 8;
    } else if (macdImpulse < 0) {
      score -= 8;
    }

    // ---------------------------------------------------------
    // STOCHASTIC
    // ---------------------------------------------------------

    if (stochastic >= 55 && stochastic < 90) {
      score += 5;
    } else if (stochastic <= 45 && stochastic > 10) {
      score -= 5;
    }

    // ---------------------------------------------------------
    // RATE OF CHANGE
    // ---------------------------------------------------------

    if (roc > 0) {
      score += min(8.0, roc.abs() * 4000);
    } else if (roc < 0) {
      score -= min(8.0, roc.abs() * 4000);
    }

    // ---------------------------------------------------------
    // BOLLINGER LOCATION
    // ---------------------------------------------------------

    if (bollinger > 0.58 && bollinger < 1.10) {
      score += 5;
    } else if (bollinger < 0.42 && bollinger > -0.10) {
      score -= 5;
    }

    // ---------------------------------------------------------
    // REAL MARKET STRUCTURE
    // ---------------------------------------------------------

    score += structure.score * 0.22;

    // ---------------------------------------------------------
    // PRICE ACTION
    // ---------------------------------------------------------

    score += priceAction * 0.12;

    // Strong trend gets slightly more authority.
    if (adx >= 25) {
      score *= 1.08;
    }

    score = score.clamp(-100.0, 100.0).toDouble();

    final avgPrice = closes.fold<double>(0, (a, b) => a + b) / closes.length;

    final atrPercent = avgPrice == 0 ? 0 : (atr / avgPrice) * 100;

    final volatilityScore = (atrPercent * 8000).clamp(5.0, 100.0).toDouble();

    return _TimeframeAnalysis(
      score: score,
      rsi: rsi,
      atr: atr,
      adx: adx,
      macdImpulse: macdImpulse,
      structureScore: structure.score,
      structureLabel: structure.label,
      volatilityScore: volatilityScore,
    );
  }

  // =============================================================
  // MARKET STRUCTURE / SUPPORT / RESISTANCE
  // =============================================================

  _StructureResult _marketStructure(
    List<_MarketCandle> candles,
  ) {
    if (candles.length < 5) {
      return const _StructureResult(
        score: 0,
        label: 'STRUCTURE FORMING',
      );
    }

    final highs = <double>[];
    final lows = <double>[];

    for (int i = 2; i < candles.length - 2; i++) {
      final c = candles[i];

      if (c.high >= candles[i - 1].high &&
          c.high >= candles[i - 2].high &&
          c.high >= candles[i + 1].high &&
          c.high >= candles[i + 2].high) {
        highs.add(c.high);
      }

      if (c.low <= candles[i - 1].low &&
          c.low <= candles[i - 2].low &&
          c.low <= candles[i + 1].low &&
          c.low <= candles[i + 2].low) {
        lows.add(c.low);
      }
    }

    double score = 0;
    String label = 'RANGE / TRANSITION';

    if (highs.length >= 2 && lows.length >= 2) {
      final higherHigh = highs[highs.length - 1] > highs[highs.length - 2];

      final higherLow = lows[lows.length - 1] > lows[lows.length - 2];

      final lowerHigh = highs[highs.length - 1] < highs[highs.length - 2];

      final lowerLow = lows[lows.length - 1] < lows[lows.length - 2];

      if (higherHigh && higherLow) {
        score = 70;
        label = 'HH/HL BULLISH STRUCTURE';
      } else if (lowerHigh && lowerLow) {
        score = -70;
        label = 'LH/LL BEARISH STRUCTURE';
      } else if (higherHigh && !higherLow) {
        score = 25;
        label = 'BULLISH EXPANSION / TRANSITION';
      } else if (lowerLow && !lowerHigh) {
        score = -25;
        label = 'BEARISH EXPANSION / TRANSITION';
      }
    }

    final recent =
        candles.length > 25 ? candles.sublist(candles.length - 25) : candles;

    if (recent.length >= 4) {
      final prior = recent.sublist(0, recent.length - 1);

      final priorHigh = prior.map((e) => e.high).reduce(max);

      final priorLow = prior.map((e) => e.low).reduce(min);

      final last = recent.last;

      if (last.close > priorHigh) {
        score = max(score, 85);
        label = 'BULLISH BREAK OF STRUCTURE';
      } else if (last.close < priorLow) {
        score = min(score, -85);
        label = 'BEARISH BREAK OF STRUCTURE';
      }
    }

    return _StructureResult(
      score: score.clamp(-100.0, 100.0).toDouble(),
      label: label,
    );
  }

  _StructuralLevels _findStructuralLevels({
    required List<_MarketCandle> candles,
    required double currentPrice,
    required double atr,
    required bool buy,
  }) {
    final recent =
        candles.length > 80 ? candles.sublist(candles.length - 80) : candles;

    final swingHighs = <double>[];
    final swingLows = <double>[];

    for (int i = 2; i < recent.length - 2; i++) {
      final c = recent[i];

      if (c.high >= recent[i - 1].high &&
          c.high >= recent[i - 2].high &&
          c.high >= recent[i + 1].high &&
          c.high >= recent[i + 2].high) {
        swingHighs.add(c.high);
      }

      if (c.low <= recent[i - 1].low &&
          c.low <= recent[i - 2].low &&
          c.low <= recent[i + 1].low &&
          c.low <= recent[i + 2].low) {
        swingLows.add(c.low);
      }
    }

    double? support;
    double? resistance;

    final supportsBelow = swingLows.where((v) => v < currentPrice).toList();

    final resistanceAbove = swingHighs.where((v) => v > currentPrice).toList();

    if (supportsBelow.isNotEmpty) {
      support = supportsBelow.reduce(max);
    }

    if (resistanceAbove.isNotEmpty) {
      resistance = resistanceAbove.reduce(min);
    }

    if (recent.isNotEmpty) {
      support ??= recent.map((e) => e.low).reduce(min);
      resistance ??= recent.map((e) => e.high).reduce(max);
    }

    final minimumDistance = max(
      atr * 0.35,
      currentPrice.abs() * 0.00002,
    );

    if (support == null || support >= currentPrice) {
      support = currentPrice - minimumDistance;
    }

    if (resistance == null || resistance <= currentPrice) {
      resistance = currentPrice + minimumDistance;
    }

    final structuralRange = max(resistance - support, minimumDistance * 2);

    double minEntry;
    double maxEntry;

    if (buy) {
      final preferredCenter = max(
        support + (structuralRange * 0.60),
        currentPrice - (atr * 0.12),
      );

      final width = max(atr * 0.12, minimumDistance * 0.20);

      minEntry = preferredCenter - width;
      maxEntry = preferredCenter + width;
    } else {
      final preferredCenter = min(
        resistance - (structuralRange * 0.60),
        currentPrice + (atr * 0.12),
      );

      final width = max(atr * 0.12, minimumDistance * 0.20);

      minEntry = preferredCenter - width;
      maxEntry = preferredCenter + width;
    }

    minEntry = max(minEntry, support);
    maxEntry = min(maxEntry, resistance);

    // Do not manufacture an entry zone around currentPrice.
    // If market structure collapses to an invalid zone, return
    // no executable entry zone and let the execution gate HOLD.
    if (minEntry >= maxEntry) {
      return _StructuralLevels(
        support: support,
        resistance: resistance,
        minEntry: null,
        maxEntry: null,
      );
    }

    return _StructuralLevels(
      support: support,
      resistance: resistance,
      minEntry: minEntry,
      maxEntry: maxEntry,
    );
  }

  // =============================================================
  // MARKET REGIME
  // =============================================================

  String _detectRegime(
    _TimeframeAnalysis analysis,
    _StructuralLevels levels,
    double currentPrice,
  ) {
    final nearResistance = (levels.resistance - currentPrice).abs() <=
        max(analysis.atr * 0.30, currentPrice.abs() * 0.00002);

    final nearSupport = (currentPrice - levels.support).abs() <=
        max(analysis.atr * 0.30, currentPrice.abs() * 0.00002);

    if (analysis.adx >= 30 && analysis.score >= 25) {
      return 'BULLISH TREND';
    }

    if (analysis.adx >= 30 && analysis.score <= -25) {
      return 'BEARISH TREND';
    }

    if (analysis.structureLabel.contains('BREAK')) {
      return 'BREAKOUT';
    }

    if (analysis.volatilityScore >= 80) {
      return 'HIGH VOLATILITY';
    }

    if (analysis.adx < 18 && (nearResistance || nearSupport)) {
      return 'RANGE / REACTION ZONE';
    }

    if (analysis.adx < 18) {
      return 'RANGING / CHOP';
    }

    return 'TRANSITION';
  }

  // =============================================================
  // PRICE ACTION
  // =============================================================

  double _priceActionScore(
    List<_MarketCandle> candles,
  ) {
    if (candles.length < 2) return 0;

    final last = candles.last;
    final previous = candles[candles.length - 2];

    final range = max(last.high - last.low, 1e-12);
    final body = (last.close - last.open).abs();

    final bodyRatio = body / range;

    final upperWick = last.high - max(last.open, last.close);

    final lowerWick = min(last.open, last.close) - last.low;

    double score = 0;

    if (last.close > last.open) {
      score += bodyRatio * 45;

      if (lowerWick > body) {
        score += 18;
      }
    } else if (last.close < last.open) {
      score -= bodyRatio * 45;

      if (upperWick > body) {
        score -= 18;
      }
    }

    final bullishEngulf = last.close > last.open &&
        previous.close < previous.open &&
        last.close >= previous.open &&
        last.open <= previous.close;

    final bearishEngulf = last.close < last.open &&
        previous.close > previous.open &&
        last.open >= previous.close &&
        last.close <= previous.open;

    if (bullishEngulf) score += 30;
    if (bearishEngulf) score -= 30;

    return score.clamp(-100.0, 100.0).toDouble();
  }

  // =============================================================
  // TICK MICRO-MOMENTUM
  // =============================================================

  double _tickMomentumScore(List<double> ticks) {
    if (ticks.length < 2) return 0;

    double score = 0;

    final lastMove = ticks.last - ticks[ticks.length - 2];

    if (lastMove > 0) {
      score += 20;
    } else if (lastMove < 0) {
      score -= 20;
    }

    if (ticks.length >= 4) {
      final velocity = ticks.last - ticks[ticks.length - 4];

      if (velocity > 0) {
        score += 35;
      } else if (velocity < 0) {
        score -= 35;
      }
    }

    if (ticks.length >= 3) {
      final newest = ticks.last - ticks[ticks.length - 2];

      final previous = ticks[ticks.length - 2] - ticks[ticks.length - 3];

      if (newest > 0 && newest > previous) {
        score += 20;
      }

      if (newest < 0 && newest < previous) {
        score -= 20;
      }
    }

    return score.clamp(-100.0, 100.0).toDouble();
  }

  // =============================================================
  // INDICATORS
  // =============================================================

  double _ema(List<double> values, int period) {
    if (values.isEmpty) return 0;

    if (values.length == 1) return values.first;

    final actualPeriod = min(period, values.length);

    final start = values.length - actualPeriod;

    double value = values[start];

    final multiplier = 2.0 / (actualPeriod + 1.0);

    for (int i = start + 1; i < values.length; i++) {
      value = ((values[i] - value) * multiplier) + value;
    }

    return value;
  }

  double _rsi(List<double> values, int period) {
    if (values.length < 2) return 50;

    final start = max(1, values.length - period);

    double gains = 0;
    double losses = 0;

    for (int i = start; i < values.length; i++) {
      final change = values[i] - values[i - 1];

      if (change > 0) {
        gains += change;
      } else if (change < 0) {
        losses += change.abs();
      }
    }

    if (gains == 0 && losses == 0) return 50;
    if (losses == 0) return 100;

    final rs = gains / losses;

    return 100 - (100 / (1 + rs));
  }

  double _macd(List<double> closes) {
    if (closes.isEmpty) return 0;

    return _ema(closes, 12) - _ema(closes, 26);
  }

  double _atr(
    List<_MarketCandle> candles,
    int period,
  ) {
    if (candles.isEmpty) return 0;

    if (candles.length == 1) {
      return candles.first.high - candles.first.low;
    }

    final start = max(1, candles.length - period);

    double total = 0;
    int count = 0;

    for (int i = start; i < candles.length; i++) {
      final current = candles[i];
      final previousClose = candles[i - 1].close;

      final trueRange = max(
        current.high - current.low,
        max(
          (current.high - previousClose).abs(),
          (current.low - previousClose).abs(),
        ),
      );

      total += trueRange;
      count++;
    }

    return count == 0 ? 0 : total / count;
  }

  double _adx(
    List<_MarketCandle> candles,
    int period,
  ) {
    if (candles.length < 3) return 0;

    final start = max(1, candles.length - period);

    double plusDm = 0;
    double minusDm = 0;
    double tr = 0;

    for (int i = start; i < candles.length; i++) {
      final current = candles[i];
      final previous = candles[i - 1];

      final upMove = current.high - previous.high;

      final downMove = previous.low - current.low;

      if (upMove > downMove && upMove > 0) {
        plusDm += upMove;
      }

      if (downMove > upMove && downMove > 0) {
        minusDm += downMove;
      }

      tr += max(
        current.high - current.low,
        max(
          (current.high - previous.close).abs(),
          (current.low - previous.close).abs(),
        ),
      );
    }

    if (tr <= 0) return 0;

    final plusDi = 100 * plusDm / tr;
    final minusDi = 100 * minusDm / tr;

    final denominator = plusDi + minusDi;

    if (denominator <= 0) return 0;

    return (100 * (plusDi - minusDi).abs() / denominator)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _stochastic(
    List<_MarketCandle> candles,
    int period,
  ) {
    if (candles.isEmpty) return 50;

    final start = max(0, candles.length - period);

    final slice = candles.sublist(start);

    final highest = slice.map((e) => e.high).reduce(max);

    final lowest = slice.map((e) => e.low).reduce(min);

    final range = highest - lowest;

    if (range <= 0) return 50;

    return (((candles.last.close - lowest) / range) * 100)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _roc(List<double> values, int period) {
    if (values.length < 2) return 0;

    final index = max(0, values.length - 1 - period);

    final old = values[index];

    if (old == 0) return 0;

    return (values.last - old) / old;
  }

  double _bollingerPosition(
    List<double> values,
    int period,
  ) {
    if (values.length < 2) return 0.5;

    final start = max(0, values.length - period);

    final slice = values.sublist(start);

    final mean = slice.fold<double>(0, (a, b) => a + b) / slice.length;

    double variance = 0;

    for (final value in slice) {
      variance += pow(value - mean, 2).toDouble();
    }

    variance /= slice.length;

    final std = sqrt(variance);

    if (std == 0) return 0.5;

    final lower = mean - (std * 2);
    final upper = mean + (std * 2);

    return (values.last - lower) / (upper - lower);
  }

  double _fallbackDistance(
    String symbol,
    double price,
  ) {
    if (symbol.toUpperCase().contains('JPY')) {
      return 0.020;
    }

    if (price.abs() >= 1000) {
      return price.abs() * 0.00020;
    }

    if (price.abs() >= 100) {
      return price.abs() * 0.00010;
    }

    return 0.00020;
  }

  // =============================================================
  // LABELS
  // =============================================================

  String _trendLabel(
    double m1,
    double m5,
    double m15,
  ) {
    final weighted = (m1 * 0.70) + (m5 * 0.20) + (m15 * 0.10);

    if (weighted >= 55) return 'STRONG BULLISH';
    if (weighted >= 15) return 'BULLISH';
    if (weighted <= -55) return 'STRONG BEARISH';
    if (weighted <= -15) return 'BEARISH';

    return weighted >= 0 ? 'BULLISH TRANSITION' : 'BEARISH TRANSITION';
  }

  String _momentumLabel(
    double rsi,
    double macdImpulse,
    double tickScore,
  ) {
    final bullish = rsi >= 52 && macdImpulse >= 0 && tickScore >= 0;

    final bearish = rsi <= 48 && macdImpulse <= 0 && tickScore <= 0;

    if (bullish && rsi >= 60) {
      return 'BULLISH STRONG';
    }

    if (bullish) {
      return 'BULLISH';
    }

    if (bearish && rsi <= 40) {
      return 'BEARISH STRONG';
    }

    if (bearish) {
      return 'BEARISH';
    }

    return tickScore >= 0 ? 'MIXED / BULLISH EDGE' : 'MIXED / BEARISH EDGE';
  }
}

// =================================================================
// INTERNAL MODELS
// =================================================================

class _MarketCandle {
  final DateTime start;
  final double open;
  double high;
  double low;
  double close;

  _MarketCandle({
    required this.start,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  void update(double price) {
    high = max(high, price);
    low = min(low, price);
    close = price;
  }

  _MarketCandle copy() {
    return _MarketCandle(
      start: start,
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }
}

class _TimeframeAnalysis {
  final double score;
  final double rsi;
  final double atr;
  final double adx;
  final double macdImpulse;
  final double structureScore;
  final String structureLabel;
  final double volatilityScore;

  const _TimeframeAnalysis({
    required this.score,
    required this.rsi,
    required this.atr,
    required this.adx,
    required this.macdImpulse,
    required this.structureScore,
    required this.structureLabel,
    required this.volatilityScore,
  });

  const _TimeframeAnalysis.neutral()
      : score = 0,
        rsi = 50,
        atr = 0,
        adx = 0,
        macdImpulse = 0,
        structureScore = 0,
        structureLabel = 'STRUCTURE FORMING',
        volatilityScore = 5;
}

class _StructureResult {
  final double score;
  final String label;

  const _StructureResult({
    required this.score,
    required this.label,
  });
}

class _StructuralLevels {
  final double support;
  final double resistance;
  final double? minEntry;
  final double? maxEntry;

  const _StructuralLevels({
    required this.support,
    required this.resistance,
    required this.minEntry,
    required this.maxEntry,
  });
}
