import 'dart:async';

import 'package:flutter/material.dart';

import 'smart_analysis_engine.dart';

const _bg0 = Color(0xFF04090F);
const _bg1 = Color(0xFF07111A);
const _panel = Color(0xFF0A1722);
const _panel2 = Color(0xFF0D1D2A);

const _cyan = Color(0xFF20F0E8);
const _green = Color(0xFF42F57B);
const _red = Color(0xFFFF5364);
const _amber = Color(0xFFFFC857);
const _purple = Color(0xFFD657FF);
const _blue = Color(0xFF56A8FF);

enum _FuturePageKind {
  smartChart,
  patterns,
  breakout,
  mtf,
  duke,
}

class FutureSmartChartAnalysisPage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const FutureSmartChartAnalysisPage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _FutureSmartWorkspace(
      kind: _FuturePageKind.smartChart,
      title: 'SMART CHART ANALYSIS',
      subtitle:
          'Autonomous market-structure and technical intelligence cockpit',
      accent: _cyan,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
    );
  }
}

class FuturePatternIntelligencePage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const FuturePatternIntelligencePage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _FutureSmartWorkspace(
      kind: _FuturePageKind.patterns,
      title: 'PATTERN INTELLIGENCE',
      subtitle:
          'AI visual pattern-recognition and compression-analysis laboratory',
      accent: _green,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
    );
  }
}

class FutureBreakoutLiquidityPage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const FutureBreakoutLiquidityPage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _FutureSmartWorkspace(
      kind: _FuturePageKind.breakout,
      title: 'BREAKOUT & LIQUIDITY',
      subtitle:
          'Institutional liquidity, breakout and market-pressure workstation',
      accent: _amber,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
    );
  }
}

class FutureMtfConfluencePage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const FutureMtfConfluencePage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _FutureSmartWorkspace(
      kind: _FuturePageKind.mtf,
      title: 'MTF & AI CONFLUENCE',
      subtitle:
          'Multi-timeframe synchronization and weighted confluence matrix',
      accent: _purple,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
    );
  }
}

class FutureDukeTechnicalAiPage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const FutureDukeTechnicalAiPage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _FutureSmartWorkspace(
      kind: _FuturePageKind.duke,
      title: 'DUKE TECHNICAL AI',
      subtitle:
          'Natural-language market intelligence and autonomous chart command center',
      accent: _blue,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
    );
  }
}

class _FutureSmartWorkspace extends StatefulWidget {
  final _FuturePageKind kind;
  final String title;
  final String subtitle;
  final Color accent;
  final String symbol;
  final String timeframe;
  final double price;

  const _FutureSmartWorkspace({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  State<_FutureSmartWorkspace> createState() => _FutureSmartWorkspaceState();
}

class _FutureSmartWorkspaceState extends State<_FutureSmartWorkspace> {
  SmartAnalysisSnapshot? snapshot;
  Timer? refreshTimer;

  bool loading = true;
  String? error;

  String analysisMode = 'AI ASSIST';

  final commandController = TextEditingController();
  final List<String> actionHistory = [];

  String dukeResponse =
      'Duke Technical AI is synchronized with the Smart Analysis engine.';

  final Map<String, bool> layers = {
    'Auto Trendlines': true,
    'Support / Resistance': true,
    'Auto Fibonacci': true,
    'Market Structure': true,
    'Pattern Recognition': true,
    'Breakout Detection': true,
    'Supply / Demand': true,
    'Liquidity Zones': true,
    'Fair Value Gaps': true,
    'Order Blocks': true,
    'Candlestick AI': true,
    'Multi-Timeframe': true,
  };

  @override
  void initState() {
    super.initState();

    _load();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    commandController.dispose();
    super.dispose();
  }

  Future<void> _load({
    bool silent = false,
  }) async {
    if (!silent && mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final next = await SmartAnalysisEngine.load(
        widget.symbol,
        count: 120,
      );

      if (!mounted) return;

      setState(() {
        snapshot = next;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  void _runCommand(String command) {
    final clean = command.trim();

    if (clean.isEmpty) return;

    final s = snapshot;

    String response;

    if (s == null) {
      response =
          'Duke is waiting for enough market history to complete this command.';
    } else {
      final lower = clean.toLowerCase();

      if (lower.contains('pattern')) {
        response = 'Pattern engine: ${s.pattern}. '
            'Direction ${s.patternDirection}. '
            'Pattern score ${s.patternConfidence.toStringAsFixed(0)}/100.';
      } else if (lower.contains('breakout')) {
        response = 'Breakout engine: ${s.breakoutState}. '
            'Breakout score ${s.breakoutScore.toStringAsFixed(0)}/100. '
            'Resistance ${_price(s.resistance)}. '
            'Support ${_price(s.support)}.';
      } else if (lower.contains('liquidity')) {
        response = '${s.liquidityState}. '
            'Buy-side reference ${_price(s.liquidityAbove)}. '
            'Sell-side reference ${_price(s.liquidityBelow)}. '
            'Liquidity score ${s.liquidityScore.toStringAsFixed(0)}/100.';
      } else if (lower.contains('fib')) {
        response = s.fibonacci.entries
            .map((e) => '${e.key}: ${_price(e.value)}')
            .join(' • ');
      } else if (lower.contains('timeframe') ||
          lower.contains('mtf') ||
          lower.contains('confluence')) {
        response = 'MTF score ${s.mtfScore.toStringAsFixed(0)}/100. '
            'Total confluence ${s.confluence.toStringAsFixed(0)}/100. '
            'Final market bias ${s.bias}.';
      } else if (lower.contains('support') ||
          lower.contains('resistance') ||
          lower.contains('level')) {
        response = 'Primary support ${_price(s.support)}. '
            'Primary resistance ${_price(s.resistance)}. '
            '${s.levels.map((e) => '${e.type} strength ${e.strength.toStringAsFixed(0)}').join(' • ')}.';
      } else {
        response = 'Market bias ${s.bias}. '
            'Trend ${s.trend}. '
            'Structure ${s.structure}. '
            'Momentum ${s.momentum}. '
            'Pattern ${s.pattern}. '
            'Breakout ${s.breakoutState}. '
            'Confluence ${s.confluence.toStringAsFixed(0)}/100.';
      }
    }

    setState(() {
      dukeResponse = response;
      actionHistory.insert(
        0,
        '${DateTime.now().toLocal().toIso8601String().substring(11, 19)}  $clean',
      );

      if (actionHistory.length > 8) {
        actionHistory.removeLast();
      }
    });

    commandController.clear();
  }

  String _price(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    return value.toStringAsFixed(5);
  }

  @override
  Widget build(BuildContext context) {
    final s = snapshot;

    return Scaffold(
      backgroundColor: _bg0,
      body: SafeArea(
        child: Column(
          children: [
            _topCommandBar(),
            _statusRail(s),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 1050) {
                    return ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        _leftControlDeck(),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 700,
                          child: _centerWorkspace(s),
                        ),
                        const SizedBox(height: 10),
                        _rightAiDeck(s),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 230,
                        child: _leftControlDeck(),
                      ),
                      Expanded(
                        child: _centerWorkspace(s),
                      ),
                      SizedBox(
                        width: 292,
                        child: _rightAiDeck(s),
                      ),
                    ],
                  );
                },
              ),
            ),
            _bottomStatus(s),
          ],
        ),
      ),
    );
  }

  Widget _topCommandBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: const BoxDecoration(
        color: _bg1,
        border: Border(
          bottom: BorderSide(
            color: Color(0x3320F0E8),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '999 TRADING STUDIO',
            style: TextStyle(
              color: widget.accent,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 30,
            width: 1,
            color: Colors.white12,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  widget.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          _topBadge(
            widget.symbol.replaceAll('_', ' '),
            widget.accent,
          ),
          const SizedBox(width: 6),
          _topBadge(
            widget.timeframe,
            _amber,
          ),
          const SizedBox(width: 6),
          _topBadge(
            loading ? 'SYNC' : 'LIVE',
            loading ? _amber : _green,
          ),
          const SizedBox(width: 6),
          _topBadge(
            'AI $analysisMode',
            widget.accent,
          ),
          IconButton(
            tooltip: 'Refresh analysis',
            onPressed: _load,
            icon: Icon(
              Icons.refresh,
              color: widget.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: .35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statusRail(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        2,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: _futureBox(widget.accent),
      child: Row(
        children: [
          Expanded(
            child: _railMetric(
              'PRICE',
              s == null
                  ? widget.price > 0
                      ? _price(widget.price)
                      : '--'
                  : _price(s.candles.last.close),
              _green,
            ),
          ),
          Expanded(
            child: _railMetric(
              'MARKET BIAS',
              s?.bias ?? '--',
              _biasColor(s?.bias),
            ),
          ),
          Expanded(
            child: _railMetric(
              'TREND',
              s?.trend ?? '--',
              _biasColor(s?.trend),
            ),
          ),
          Expanded(
            child: _railMetric(
              'STRUCTURE',
              s?.structure ?? '--',
              _cyan,
            ),
          ),
          Expanded(
            child: _railMetric(
              'CONFLUENCE',
              s == null ? '--' : '${s.confluence.toStringAsFixed(0)} / 100',
              widget.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _railMetric(
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _leftControlDeck() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: _futureBox(widget.accent),
      child: ListView(
        shrinkWrap: true,
        children: [
          _sectionTitle(
            _leftTitle(),
            widget.accent,
          ),
          const SizedBox(height: 8),
          for (final entry in layers.entries)
            _layerSwitch(
              entry.key,
              entry.value,
              (value) {
                setState(() {
                  layers[entry.key] = value;
                });
              },
            ),
          const SizedBox(height: 14),
          _sectionTitle(
            'ANALYSIS MODE',
            _purple,
          ),
          const SizedBox(height: 8),
          for (final mode in [
            'MANUAL',
            'AI ASSIST',
            'FULL AUTO',
          ])
            _modeButton(mode),
          const SizedBox(height: 14),
          _sectionTitle(
            'ENGINE CHANNELS',
            _cyan,
          ),
          const SizedBox(height: 8),
          _engineChannel('PRICE FEED', !loading),
          _engineChannel('STRUCTURE', snapshot != null),
          _engineChannel('PATTERN AI', snapshot != null),
          _engineChannel('MTF MATRIX', snapshot != null),
          _engineChannel('DUKE AI', true),
        ],
      ),
    );
  }

  String _leftTitle() {
    switch (widget.kind) {
      case _FuturePageKind.smartChart:
        return 'SMART ANALYSIS LAYERS';
      case _FuturePageKind.patterns:
        return 'PATTERN AI LAYERS';
      case _FuturePageKind.breakout:
        return 'LIQUIDITY ENGINE';
      case _FuturePageKind.mtf:
        return 'CONFLUENCE COMPONENTS';
      case _FuturePageKind.duke:
        return 'DUKE AUTOMATION LAYERS';
    }
  }

  Widget _layerSwitch(
    String label,
    bool value,
    ValueChanged<bool> changed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color:
            value ? widget.accent.withValues(alpha: .035) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value ? widget.accent : Colors.white24,
            size: 15,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? Colors.white70 : Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: changed,
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    String mode,
  ) {
    final selected = analysisMode == mode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: () {
          setState(() {
            analysisMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? widget.accent.withValues(alpha: .12)
                : Colors.black.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? widget.accent.withValues(alpha: .55)
                  : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 13,
                color: selected ? widget.accent : Colors.white24,
              ),
              const SizedBox(width: 8),
              Text(
                mode,
                style: TextStyle(
                  color: selected ? widget.accent : Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _engineChannel(
    String label,
    bool online,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: online ? _green : _amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ),
          Text(
            online ? 'ONLINE' : 'SYNC',
            style: TextStyle(
              color: online ? _green : _amber,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerWorkspace(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 2,
              ),
              decoration: _futureBox(widget.accent),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: s == null
                        ? _loadingChart()
                        : CustomPaint(
                            painter: _FutureAnalysisChartPainter(
                              snapshot: s,
                              kind: widget.kind,
                              accent: widget.accent,
                              layers: layers,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 12,
                    child: _chartLegend(s),
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: _scoreBubble(s),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 245,
            child: _deepIntelligencePanel(s),
          ),
        ],
      ),
    );
  }

  Widget _loadingChart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: widget.accent,
          ),
          const SizedBox(height: 12),
          Text(
            error == null
                ? 'SYNCHRONIZING MARKET INTELLIGENCE'
                : 'MARKET HISTORY TEMPORARILY UNAVAILABLE',
            style: TextStyle(
              color: error == null ? widget.accent : _amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _bg0.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: widget.accent.withValues(alpha: .25),
        ),
      ),
      child: Text(
        s == null
            ? '${widget.symbol} • ${widget.timeframe}'
            : '${widget.symbol} • ${widget.timeframe}   '
                'EMA9 ${_price(s.ema9)}   '
                'EMA21 ${_price(s.ema21)}   '
                'RSI ${s.rsi.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _scoreBubble(
    SmartAnalysisSnapshot? s,
  ) {
    final score = s?.confluence ?? 0;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: _bg0.withValues(alpha: .86),
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.accent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.toStringAsFixed(0),
            style: TextStyle(
              color: widget.accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'AI SCORE',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deepIntelligencePanel(
    SmartAnalysisSnapshot? s,
  ) {
    switch (widget.kind) {
      case _FuturePageKind.smartChart:
        return _smartDeepPanel(s);
      case _FuturePageKind.patterns:
        return _patternDeepPanel(s);
      case _FuturePageKind.breakout:
        return _breakoutDeepPanel(s);
      case _FuturePageKind.mtf:
        return _mtfDeepPanel(s);
      case _FuturePageKind.duke:
        return _dukeDeepPanel(s);
    }
  }

  Widget _smartDeepPanel(
    SmartAnalysisSnapshot? s,
  ) {
    return _panelShell(
      title: 'REAL-TIME TECHNICAL INTELLIGENCE',
      child: Row(
        children: [
          Expanded(
            child: _metricStack(
              'TREND ENGINE',
              [
                ['TREND', s?.trend ?? '--'],
                ['STRUCTURE', s?.structure ?? '--'],
                ['MOMENTUM', s?.momentum ?? '--'],
              ],
              _cyan,
            ),
          ),
          Expanded(
            child: _metricStack(
              'INSTITUTIONAL MAP',
              [
                ['ORDER BLOCK', s?.orderBlockBias ?? '--'],
                ['BULL FVG', '${s?.bullishFvgCount ?? 0}'],
                ['BEAR FVG', '${s?.bearishFvgCount ?? 0}'],
              ],
              _green,
            ),
          ),
          Expanded(
            child: _metricStack(
              'MARKET LEVELS',
              [
                ['RESISTANCE', s == null ? '--' : _price(s.resistance)],
                ['SUPPORT', s == null ? '--' : _price(s.support)],
                ['ATR', s == null ? '--' : _price(s.atr)],
              ],
              _amber,
            ),
          ),
          Expanded(
            child: _scorePanel(s),
          ),
        ],
      ),
    );
  }

  Widget _patternDeepPanel(
    SmartAnalysisSnapshot? s,
  ) {
    return _panelShell(
      title: 'PATTERN RECOGNITION LAB',
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _metricStack(
              'PRIMARY DETECTION',
              [
                ['PATTERN', s?.pattern ?? '--'],
                ['DIRECTION', s?.patternDirection ?? '--'],
                [
                  'PATTERN SCORE',
                  s == null
                      ? '--'
                      : '${s.patternConfidence.toStringAsFixed(0)} / 100',
                ],
              ],
              _green,
            ),
          ),
          Expanded(
            child: _metricStack(
              'CONTEXT FILTERS',
              [
                ['TREND', s?.trend ?? '--'],
                ['STRUCTURE', s?.structure ?? '--'],
                ['MOMENTUM', s?.momentum ?? '--'],
              ],
              _cyan,
            ),
          ),
          Expanded(
            child: _metricStack(
              'COMPRESSION / BREAKOUT',
              [
                ['BREAKOUT', s?.breakoutState ?? '--'],
                [
                  'BREAKOUT SCORE',
                  s == null ? '--' : '${s.breakoutScore.toStringAsFixed(0)}',
                ],
                ['LIQUIDITY', s?.liquidityState ?? '--'],
              ],
              _amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakoutDeepPanel(
    SmartAnalysisSnapshot? s,
  ) {
    return _panelShell(
      title: 'INSTITUTIONAL LIQUIDITY MAP',
      child: Row(
        children: [
          Expanded(
            child: _metricStack(
              'BREAKOUT ENGINE',
              [
                ['STATE', s?.breakoutState ?? '--'],
                [
                  'QUALITY',
                  s == null
                      ? '--'
                      : '${s.breakoutScore.toStringAsFixed(0)} / 100',
                ],
                ['BIAS', s?.bias ?? '--'],
              ],
              _amber,
            ),
          ),
          Expanded(
            child: _metricStack(
              'BUY-SIDE LIQUIDITY',
              [
                [
                  'REFERENCE',
                  s == null ? '--' : _price(s.liquidityAbove),
                ],
                ['RESISTANCE', s == null ? '--' : _price(s.resistance)],
                ['STATE', 'TRACKING'],
              ],
              _green,
            ),
          ),
          Expanded(
            child: _metricStack(
              'SELL-SIDE LIQUIDITY',
              [
                [
                  'REFERENCE',
                  s == null ? '--' : _price(s.liquidityBelow),
                ],
                ['SUPPORT', s == null ? '--' : _price(s.support)],
                ['STATE', 'TRACKING'],
              ],
              _red,
            ),
          ),
          Expanded(
            child: _metricStack(
              'SMART MONEY CONTEXT',
              [
                ['LIQUIDITY', s?.liquidityState ?? '--'],
                ['ORDER BLOCK', s?.orderBlockBias ?? '--'],
                [
                  'LIQ SCORE',
                  s == null ? '--' : '${s.liquidityScore.toStringAsFixed(0)}',
                ],
              ],
              _purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mtfDeepPanel(
    SmartAnalysisSnapshot? s,
  ) {
    final timeframes = s?.timeframes.values.toList() ?? [];

    return _panelShell(
      title: 'MULTI-TIMEFRAME SYNCHRONIZATION MATRIX',
      child: Row(
        children: [
          for (final tf in timeframes.take(4))
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _biasColor(tf.bias).withValues(alpha: .35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tf.timeframe,
                      style: TextStyle(
                        color: _biasColor(tf.bias),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _miniMetric('BIAS', tf.bias),
                    _miniMetric('TREND', tf.trend),
                    _miniMetric('STRUCTURE', tf.structure),
                    _miniMetric('MOMENTUM', tf.momentum),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: (tf.score / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      color: _biasColor(tf.bias),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tf.score.toStringAsFixed(0)} / 100',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dukeDeepPanel(
    SmartAnalysisSnapshot? s,
  ) {
    return _panelShell(
      title: 'DUKE AUTONOMOUS REASONING CONSOLE',
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _metricStack(
              'CURRENT MACHINE READ',
              [
                ['BIAS', s?.bias ?? '--'],
                ['TREND', s?.trend ?? '--'],
                ['STRUCTURE', s?.structure ?? '--'],
                ['MOMENTUM', s?.momentum ?? '--'],
              ],
              _blue,
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .17),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _blue.withValues(alpha: .3),
                ),
              ),
              child: Text(
                dukeResponse,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelShell({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(10),
      decoration: _futureBox(widget.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, widget.accent),
          const SizedBox(height: 5),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _metricStack(
    String title,
    List<List<String>> rows,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: .24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          for (final row in rows)
            Expanded(
              child: _miniMetric(row[0], row[1]),
            ),
        ],
      ),
    );
  }

  Widget _miniMetric(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _biasColor(value),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scorePanel(
    SmartAnalysisSnapshot? s,
  ) {
    final score = s?.confluence ?? 0;

    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: widget.accent.withValues(alpha: .35),
        ),
      ),
      child: Column(
        children: [
          Text(
            '999 AI CONFLUENCE',
            style: TextStyle(
              color: widget.accent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              color: widget.accent,
            ),
          ),
          const Spacer(),
          Text(
            '${score.toStringAsFixed(0)} / 100',
            style: TextStyle(
              color: widget.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightAiDeck(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: _futureBox(widget.accent),
      child: ListView(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.accent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.psychology_alt,
                  color: widget.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DUKE AGENT BOSS',
                      style: TextStyle(
                        color: widget.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'TECHNICAL AI ONLINE',
                      style: TextStyle(
                        color: _green,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('AI TECHNICAL READ', _cyan),
          const SizedBox(height: 6),
          _aiRead('MARKET BIAS', s?.bias ?? '--'),
          _aiRead('TREND', s?.trend ?? '--'),
          _aiRead('STRUCTURE', s?.structure ?? '--'),
          _aiRead('MOMENTUM', s?.momentum ?? '--'),
          _aiRead('PATTERN', s?.pattern ?? '--'),
          _aiRead('BREAKOUT', s?.breakoutState ?? '--'),
          _aiRead(
            'CONFLUENCE',
            s == null ? '--' : '${s.confluence.toStringAsFixed(0)} / 100',
          ),
          const SizedBox(height: 14),
          _sectionTitle('AI COMMAND CENTER', _purple),
          const SizedBox(height: 8),
          TextField(
            controller: commandController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            decoration: InputDecoration(
              hintText: 'Ask Duke about this chart...',
              hintStyle: const TextStyle(
                color: Colors.white24,
                fontSize: 9,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: .2),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  _runCommand(commandController.text);
                },
                icon: Icon(
                  Icons.send,
                  color: widget.accent,
                ),
              ),
            ),
            onSubmitted: _runCommand,
          ),
          const SizedBox(height: 8),
          _quickCommand('ANALYZE CHART'),
          _quickCommand('DRAW KEY LEVELS'),
          _quickCommand('FIND PATTERNS'),
          _quickCommand('FIND BREAKOUT SETUPS'),
          _quickCommand('SHOW LIQUIDITY'),
          _quickCommand('RUN MTF CONFLUENCE'),
          _quickCommand('SHOW FIBONACCI'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: widget.accent.withValues(alpha: .2),
              ),
            ),
            child: Text(
              dukeResponse,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiRead(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _biasColor(value),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCommand(
    String command,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: () => _runCommand(command),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.accent.withValues(alpha: .24),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: widget.accent,
                size: 13,
              ),
              const SizedBox(width: 7),
              Text(
                command,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomStatus(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: _bg1,
        border: Border(
          top: BorderSide(
            color: Colors.white10,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'DATA SOURCE: POCKET OPTION',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 8,
            ),
          ),
          const SizedBox(width: 18),
          Text(
            loading ? 'CONNECTION: SYNC' : 'CONNECTION: STABLE',
            style: TextStyle(
              color: loading ? _amber : _green,
              fontSize: 8,
            ),
          ),
          const Spacer(),
          Text(
            '999 TRADING STUDIO • SMART ANALYSIS MATRIX',
            style: TextStyle(
              color: widget.accent,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureAnalysisChartPainter extends CustomPainter {
  final SmartAnalysisSnapshot snapshot;
  final _FuturePageKind kind;
  final Color accent;
  final Map<String, bool> layers;

  const _FutureAnalysisChartPainter({
    required this.snapshot,
    required this.kind,
    required this.accent,
    required this.layers,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final source = snapshot.candles;

    if (source.isEmpty) return;

    final candles =
        source.length > 80 ? source.sublist(source.length - 80) : source;

    double low = candles.first.low;
    double high = candles.first.high;

    for (final candle in candles) {
      if (candle.low < low) low = candle.low;
      if (candle.high > high) high = candle.high;
    }

    final range = (high - low).abs();
    final safeRange = range <= 0 ? 1.0 : range;

    final paddedLow = low - safeRange * .08;
    final paddedHigh = high + safeRange * .08;
    final totalRange = paddedHigh - paddedLow;

    double y(double price) {
      return size.height - ((price - paddedLow) / totalRange) * size.height;
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..strokeWidth = 1;

    for (int i = 1; i < 8; i++) {
      final dx = size.width * i / 8;

      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, size.height),
        gridPaint,
      );
    }

    for (int i = 1; i < 6; i++) {
      final dy = size.height * i / 6;

      canvas.drawLine(
        Offset(0, dy),
        Offset(size.width, dy),
        gridPaint,
      );
    }

    if (layers['Support / Resistance'] == true) {
      _band(
        canvas,
        size,
        y(snapshot.resistance),
        _red,
        'RESISTANCE ${_formatPrice(snapshot.resistance)}',
      );

      _band(
        canvas,
        size,
        y(snapshot.support),
        _green,
        'SUPPORT ${_formatPrice(snapshot.support)}',
      );
    }

    if (layers['Auto Fibonacci'] == true &&
        kind == _FuturePageKind.smartChart) {
      for (final entry in snapshot.fibonacci.entries) {
        final fy = y(entry.value);

        canvas.drawLine(
          Offset(0, fy),
          Offset(size.width, fy),
          Paint()
            ..color = _amber.withValues(alpha: .43)
            ..strokeWidth = 1,
        );

        _text(
          canvas,
          '${entry.key} ${_formatPrice(entry.value)}',
          Offset(8, fy - 13),
          _amber,
          9,
        );
      }
    }

    final candleWidth = size.width / candles.length;
    final bodyWidth = (candleWidth * .58).clamp(2.0, 8.0);

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = candleWidth * i + candleWidth / 2;
      final color = candle.bullish ? _green : _red;

      canvas.drawLine(
        Offset(x, y(candle.high)),
        Offset(x, y(candle.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );

      final top = y(
        candle.open > candle.close ? candle.open : candle.close,
      );

      final bottom = y(
        candle.open < candle.close ? candle.open : candle.close,
      );

      canvas.drawRect(
        Rect.fromLTRB(
          x - bodyWidth / 2,
          top,
          x + bodyWidth / 2,
          bottom == top ? top + 1 : bottom,
        ),
        Paint()..color = color,
      );
    }
  }

  void _band(
    Canvas canvas,
    Size size,
    double yValue,
    Color color,
    String label,
  ) {
    canvas.drawLine(
      Offset(0, yValue),
      Offset(size.width, yValue),
      Paint()
        ..color = color.withValues(alpha: .62)
        ..strokeWidth = 1,
    );

    _text(
      canvas,
      label,
      Offset(
        size.width - 165,
        yValue - 18,
      ),
      color,
      9,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(
        maxWidth: 240,
      );

    painter.paint(
      canvas,
      offset,
    );
  }

  String _formatPrice(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    return value.toStringAsFixed(5);
  }

  @override
  bool shouldRepaint(
    covariant _FutureAnalysisChartPainter oldDelegate,
  ) {
    return true;
  }
}

Widget _sectionTitle(
  String title,
  Color color,
) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 15,
        color: color,
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

BoxDecoration _futureBox(
  Color color,
) {
  return BoxDecoration(
    color: _panel,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(
      color: color.withValues(alpha: .24),
    ),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _panel2,
        _panel,
      ],
    ),
  );
}

Color _biasColor(
  String? value,
) {
  final upper = (value ?? '').toUpperCase();

  if (upper.contains('BULL') ||
      upper.contains('STRONG') ||
      upper.contains('ONLINE') ||
      upper.contains('CONFIRMED')) {
    return _green;
  }

  if (upper.contains('BEAR') ||
      upper.contains('FAIL') ||
      upper.contains('LOSS')) {
    return _red;
  }

  if (upper.contains('WATCH') ||
      upper.contains('RANGE') ||
      upper.contains('NEUTRAL') ||
      upper.contains('SYNC')) {
    return _amber;
  }

  return _cyan;
}
