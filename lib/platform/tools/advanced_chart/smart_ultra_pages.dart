import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'smart_analysis_engine.dart';

const Color _uBg = Color(0xFF02060B);
const Color _uBg2 = Color(0xFF061019);
const Color _uPanel = Color(0xFF08151F);
const Color _uPanel2 = Color(0xFF0B1B28);
const Color _uGrid = Color(0xFF173140);

const Color _uCyan = Color(0xFF20F0E8);
const Color _uGreen = Color(0xFF62FF7C);
const Color _uRed = Color(0xFFFF5364);
const Color _uAmber = Color(0xFFFFC857);
const Color _uPurple = Color(0xFFE15AFF);
const Color _uBlue = Color(0xFF58AFFF);

enum _UltraKind {
  chart,
  patterns,
  liquidity,
  mtf,
  duke,
}

class UltraSmartChartAnalysisPage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const UltraSmartChartAnalysisPage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _UltraWorkspace(
      kind: _UltraKind.chart,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
      title: 'AI MARKET OPERATING COCKPIT',
      subtitle:
          'Autonomous technical intelligence, predictive geometry and market-state control',
      accent: _uCyan,
    );
  }
}

class UltraPatternIntelligencePage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const UltraPatternIntelligencePage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _UltraWorkspace(
      kind: _UltraKind.patterns,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
      title: 'AI PATTERN VISION LAB',
      subtitle:
          'Machine-vision pattern recognition, compression mapping and probability evolution',
      accent: _uGreen,
    );
  }
}

class UltraBreakoutLiquidityPage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const UltraBreakoutLiquidityPage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _UltraWorkspace(
      kind: _UltraKind.liquidity,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
      title: 'INSTITUTIONAL LIQUIDITY COMMAND CENTER',
      subtitle:
          'Liquidity pressure, sweep intelligence, breakout probability and smart-money mapping',
      accent: _uAmber,
    );
  }
}

class UltraMtfConfluencePage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const UltraMtfConfluencePage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _UltraWorkspace(
      kind: _UltraKind.mtf,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
      title: 'MULTI-TIMEFRAME SYNCHRONIZATION MATRIX',
      subtitle:
          'Cross-timeframe state fusion, conflict detection and weighted AI consensus',
      accent: _uPurple,
    );
  }
}

class UltraDukeTechnicalAiPage extends StatelessWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const UltraDukeTechnicalAiPage({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return _UltraWorkspace(
      kind: _UltraKind.duke,
      symbol: symbol,
      timeframe: timeframe,
      price: price,
      title: 'DUKE AUTONOMOUS TECHNICAL AI',
      subtitle:
          'Natural-language market operating system, reasoning stream and autonomous technical control',
      accent: _uBlue,
    );
  }
}

class _UltraWorkspace extends StatefulWidget {
  final _UltraKind kind;
  final String symbol;
  final String timeframe;
  final double price;
  final String title;
  final String subtitle;
  final Color accent;

  const _UltraWorkspace({
    required this.kind,
    required this.symbol,
    required this.timeframe,
    required this.price,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  State<_UltraWorkspace> createState() => _UltraWorkspaceState();
}

class _UltraWorkspaceState extends State<_UltraWorkspace> {
  SmartAnalysisSnapshot? snapshot;

  Timer? timer;

  bool loading = true;

  String? error;

  String mode = 'AI ASSIST';

  final TextEditingController command = TextEditingController();

  final List<String> eventStream = [];

  String dukeMessage =
      'Neural technical-analysis core online. Waiting for market synchronization.';

  final Map<String, bool> systems = {
    'Neural Trend Geometry': true,
    'Adaptive S/R': true,
    'Auto Fibonacci': true,
    'Structure Intelligence': true,
    'Pattern Vision': true,
    'Breakout Probability': true,
    'Liquidity Mapping': true,
    'FVG Detection': true,
    'Order Block Intelligence': true,
    'MTF Synchronization': true,
  };

  @override
  void initState() {
    super.initState();

    _load();

    timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    command.dispose();
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

  void _issueCommand(
    String text,
  ) {
    final value = text.trim();

    if (value.isEmpty) return;

    final s = snapshot;

    var answer = 'Waiting for market synchronization.';

    if (s != null) {
      final q = value.toLowerCase();

      if (q.contains('pattern')) {
        answer =
            'Pattern Vision detects ${s.pattern}. Direction ${s.patternDirection}. '
            'Recognition confidence ${s.patternConfidence.toStringAsFixed(0)} percent. '
            'Context is ${s.trend}, ${s.structure}, ${s.momentum}.';
      } else if (q.contains('breakout')) {
        answer = 'Breakout engine state: ${s.breakoutState}. '
            'Pressure score ${s.breakoutScore.toStringAsFixed(0)}. '
            'Resistance ${_px(s.resistance)} and support ${_px(s.support)}.';
      } else if (q.contains('liquidity')) {
        answer = '${s.liquidityState}. '
            'Buy-side reference ${_px(s.liquidityAbove)}. '
            'Sell-side reference ${_px(s.liquidityBelow)}. '
            'Liquidity intelligence ${s.liquidityScore.toStringAsFixed(0)} percent.';
      } else if (q.contains('timeframe') ||
          q.contains('mtf') ||
          q.contains('confluence')) {
        answer =
            'Multi-timeframe synchronization score ${s.mtfScore.toStringAsFixed(0)}. '
            'Global confluence ${s.confluence.toStringAsFixed(0)}. '
            'Machine consensus ${s.bias}.';
      } else if (q.contains('fib')) {
        answer = s.fibonacci.entries
            .map(
              (e) => '${e.key} ${_px(e.value)}',
            )
            .join('  |  ');
      } else if (q.contains('level') ||
          q.contains('support') ||
          q.contains('resistance')) {
        answer = 'Adaptive support ${_px(s.support)}. '
            'Adaptive resistance ${_px(s.resistance)}. '
            'ATR ${_px(s.atr)}.';
      } else {
        answer = 'Machine thesis: ${s.bias}. '
            'Trend ${s.trend}. '
            'Structure ${s.structure}. '
            'Momentum ${s.momentum}. '
            'Pattern ${s.pattern}. '
            'Breakout ${s.breakoutState}. '
            'Total confluence ${s.confluence.toStringAsFixed(0)} percent.';
      }
    }

    setState(() {
      dukeMessage = answer;

      eventStream.insert(
        0,
        '${DateTime.now().toLocal().toIso8601String().substring(11, 19)}  $value',
      );

      if (eventStream.length > 8) {
        eventStream.removeLast();
      }
    });

    command.clear();
  }

  String _px(
    double value,
  ) {
    return value >= 100 ? value.toStringAsFixed(2) : value.toStringAsFixed(5);
  }

  Color _biasColor(
    String? value,
  ) {
    final text = (value ?? '').toUpperCase();

    if (text.contains('BULL')) return _uGreen;

    if (text.contains('BEAR')) return _uRed;

    return _uAmber;
  }

  @override
  Widget build(BuildContext context) {
    final s = snapshot;

    return Scaffold(
      backgroundColor: _uBg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _quantStatusStrip(s),
            Expanded(
              child: LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  if (constraints.maxWidth < 1100) {
                    return ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        _leftNeuralRail(),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 720,
                          child: _centerCommandSpace(s),
                        ),
                        const SizedBox(height: 10),
                        _rightAiCore(s),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 248,
                        child: _leftNeuralRail(),
                      ),
                      Expanded(
                        child: _centerCommandSpace(s),
                      ),
                      SizedBox(
                        width: 310,
                        child: _rightAiCore(s),
                      ),
                    ],
                  );
                },
              ),
            ),
            _bottomTelemetry(s),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: _uBg2,
        border: Border(
          bottom: BorderSide(
            color: widget.accent.withValues(alpha: .35),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '999 TRADING STUDIO',
            style: TextStyle(
              color: widget.accent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            color: Colors.white12,
          ),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
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
          _chip(widget.symbol, _uCyan),
          const SizedBox(width: 6),
          _chip(widget.timeframe, _uAmber),
          const SizedBox(width: 6),
          _chip('LIVE', _uGreen),
          const SizedBox(width: 6),
          _chip(mode, widget.accent),
          IconButton(
            tooltip: 'Refresh intelligence',
            onPressed: _load,
            icon: Icon(
              Icons.sync,
              color: widget.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantStatusStrip(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        0,
      ),
      decoration: _neoBox(
        widget.accent,
        alpha: .18,
      ),
      child: Row(
        children: [
          _statusCell(
            'PRICE',
            s == null || s.candles.isEmpty
                ? _px(widget.price)
                : _px(s.candles.last.close),
            _uGreen,
          ),
          _statusCell(
            'MACHINE BIAS',
            s?.bias ?? 'SYNCING',
            _biasColor(s?.bias),
          ),
          _statusCell(
            'TREND',
            s?.trend ?? '--',
            _biasColor(s?.trend),
          ),
          _statusCell(
            'STRUCTURE',
            s?.structure ?? '--',
            _uCyan,
          ),
          _statusCell(
            'CONFLUENCE',
            s == null ? '--' : '${s.confluence.toStringAsFixed(0)} / 100',
            widget.accent,
          ),
        ],
      ),
    );
  }

  Widget _statusCell(
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftNeuralRail() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(11),
      decoration: _neoBox(
        widget.accent,
        alpha: .16,
      ),
      child: ListView(
        children: [
          _sectionTitle(
            _leftTitle(),
            widget.accent,
          ),
          const SizedBox(height: 8),
          for (final entry in systems.entries)
            _systemToggle(
              entry.key,
              entry.value,
            ),
          const SizedBox(height: 12),
          _sectionTitle(
            'ANALYSIS MODE',
            _uPurple,
          ),
          const SizedBox(height: 8),
          for (final option in [
            'MANUAL',
            'AI ASSIST',
            'FULL AUTO',
          ])
            Padding(
              padding: const EdgeInsets.only(
                bottom: 5,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    mode = option;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: mode == option
                        ? widget.accent.withValues(alpha: .15)
                        : Colors.black.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: mode == option ? widget.accent : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 14,
                        color: mode == option ? widget.accent : Colors.white30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: TextStyle(
                          color:
                              mode == option ? widget.accent : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _sectionTitle(
            'AUTONOMY STATE',
            _uBlue,
          ),
          const SizedBox(height: 8),
          _tinyState(
            'ENGINE',
            loading ? 'SYNCING' : 'ONLINE',
          ),
          _tinyState(
            'REFRESH',
            '6 SECOND',
          ),
          _tinyState(
            'DATA',
            'POCKET OPTION',
          ),
          _tinyState(
            'CONTROL',
            mode,
          ),
        ],
      ),
    );
  }

  String _leftTitle() {
    switch (widget.kind) {
      case _UltraKind.chart:
        return 'NEURAL CHART SYSTEMS';
      case _UltraKind.patterns:
        return 'PATTERN VISION SYSTEMS';
      case _UltraKind.liquidity:
        return 'LIQUIDITY SENSOR ARRAY';
      case _UltraKind.mtf:
        return 'CONFLUENCE SYSTEMS';
      case _UltraKind.duke:
        return 'DUKE AUTOMATION SYSTEMS';
    }
  }

  Widget _systemToggle(
    String label,
    bool value,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 3,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white10,
          ),
        ),
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        value: value,
        activeThumbColor: widget.accent,
        onChanged: (next) {
          setState(() {
            systems[label] = next;
          });
        },
      ),
    );
  }

  Widget _centerCommandSpace(
    SmartAnalysisSnapshot? s,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: _neoBox(
                widget.accent,
                alpha: .18,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: s == null
                        ? _syncingPanel()
                        : CustomPaint(
                            painter: _UltraMarketPainter(
                              snapshot: s,
                              accent: widget.accent,
                              kind: widget.kind,
                              systems: systems,
                            ),
                          ),
                  ),
                  Positioned(
                    left: 12,
                    top: 10,
                    child: _marketLegend(s),
                  ),
                  Positioned(
                    right: 14,
                    top: 12,
                    child: _aiOrb(s),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: _liveModelBadge(s),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _advancedModule(s),
          ),
        ],
      ),
    );
  }

  Widget _syncingPanel() {
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
                ? 'SYNCHRONIZING LIVE MARKET MATRIX'
                : 'MARKET HISTORY TEMPORARILY UNAVAILABLE',
            style: TextStyle(
              color: error == null ? widget.accent : _uAmber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketLegend(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _uBg.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: widget.accent.withValues(alpha: .28),
        ),
      ),
      child: Text(
        s == null
            ? '${widget.symbol} ${widget.timeframe}'
            : '${widget.symbol} ${widget.timeframe}   '
                'EMA9 ${_px(s.ema9)}   EMA21 ${_px(s.ema21)}   '
                'RSI ${s.rsi.toStringAsFixed(1)}   ATR ${_px(s.atr)}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _aiOrb(
    SmartAnalysisSnapshot? s,
  ) {
    final score = s?.confluence ?? 0;

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _uBg.withValues(alpha: .87),
        border: Border.all(
          color: widget.accent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: .24),
            blurRadius: 18,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                color: widget.accent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'AI SCORE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveModelBadge(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _uGreen.withValues(alpha: .35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.circle,
            size: 7,
            color: _uGreen,
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE SMART MODEL  |  ${s?.bias ?? "SYNCING"}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _advancedModule(
    SmartAnalysisSnapshot? s,
  ) {
    switch (widget.kind) {
      case _UltraKind.chart:
        return _chartIntelligence(s);
      case _UltraKind.patterns:
        return _patternVision(s);
      case _UltraKind.liquidity:
        return _liquidityCommand(s);
      case _UltraKind.mtf:
        return _mtfMatrix(s);
      case _UltraKind.duke:
        return _dukeReasoning(s);
    }
  }

  Widget _chartIntelligence(
    SmartAnalysisSnapshot? s,
  ) {
    final scenario = s == null
        ? '--'
        : s.bias.contains('BULL')
            ? 'UPSIDE EXPANSION'
            : s.bias.contains('BEAR')
                ? 'DOWNSIDE EXPANSION'
                : 'RANGE / TRANSITION';

    final regime = s == null
        ? '--'
        : s.atr > 0 && s.rsi >= 60
            ? 'HIGH MOMENTUM'
            : s.rsi >= 52
                ? 'TRENDING'
                : 'BALANCED';

    return _panelShell(
      'PREDICTIVE MARKET INTELLIGENCE',
      Row(
        children: [
          Expanded(
            child: _metricBlock(
              'MARKET STATE VECTOR',
              [
                ['REGIME', regime],
                ['BIAS', s?.bias ?? '--'],
                ['STRUCTURE', s?.structure ?? '--'],
                ['MOMENTUM', s?.momentum ?? '--'],
              ],
              _uCyan,
            ),
          ),
          Expanded(
            child: _metricBlock(
              'PROBABILITY PATH',
              [
                ['PRIMARY', scenario],
                [
                  'CONFLUENCE',
                  s == null ? '--' : '${s.confluence.toStringAsFixed(0)} / 100',
                ],
                [
                  'TREND QUALITY',
                  s == null ? '--' : '${s.trendScore.toStringAsFixed(0)} / 100',
                ],
                [
                  'MTF SCORE',
                  s == null ? '--' : '${s.mtfScore.toStringAsFixed(0)} / 100',
                ],
              ],
              _uGreen,
            ),
          ),
          Expanded(
            child: _metricBlock(
              'RANKED PRICE GEOMETRY',
              [
                [
                  'RESISTANCE',
                  s == null ? '--' : _px(s.resistance),
                ],
                [
                  'SUPPORT',
                  s == null ? '--' : _px(s.support),
                ],
                [
                  'ATR',
                  s == null ? '--' : _px(s.atr),
                ],
                [
                  'ORDER FLOW BIAS',
                  s?.orderBlockBias ?? '--',
                ],
              ],
              _uAmber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patternVision(
    SmartAnalysisSnapshot? s,
  ) {
    final continuation =
        s == null ? 0.0 : math.max(s.patternConfidence, s.trendScore);

    final failure = s == null
        ? 0.0
        : (100 - s.patternConfidence).clamp(
            0.0,
            100.0,
          );

    final evolution = s == null
        ? '--'
        : s.breakoutState.contains('WATCH')
            ? 'COMPRESSION -> RELEASE WATCH'
            : s.breakoutState.contains('CONFIRMED')
                ? 'PATTERN -> EXPANSION'
                : 'FORMATION -> VALIDATION';

    return _panelShell(
      'MACHINE VISION PATTERN LAB',
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _metricBlock(
              'PRIMARY VISUAL SIGNATURE',
              [
                ['DETECTION', s?.pattern ?? '--'],
                ['VECTOR', s?.patternDirection ?? '--'],
                [
                  'VISION CONFIDENCE',
                  s == null
                      ? '--'
                      : '${s.patternConfidence.toStringAsFixed(0)}%',
                ],
                ['EVOLUTION', evolution],
              ],
              _uGreen,
            ),
          ),
          Expanded(
            child: _metricBlock(
              'OUTCOME PROBABILITY',
              [
                [
                  'CONTINUATION',
                  '${continuation.toStringAsFixed(0)}%',
                ],
                [
                  'FAILURE',
                  '${failure.toStringAsFixed(0)}%',
                ],
                ['TREND FILTER', s?.trend ?? '--'],
                ['STRUCTURE FILTER', s?.structure ?? '--'],
              ],
              _uCyan,
            ),
          ),
          Expanded(
            child: _metricBlock(
              'COMPRESSION ENGINE',
              [
                ['BREAKOUT STATE', s?.breakoutState ?? '--'],
                [
                  'BREAKOUT PRESSURE',
                  s == null ? '--' : '${s.breakoutScore.toStringAsFixed(0)}%',
                ],
                ['LIQUIDITY CONTEXT', s?.liquidityState ?? '--'],
                [
                  'HISTORICAL MATCH',
                  s == null
                      ? '--'
                      : '${((s.patternConfidence + s.structureScore) / 2).toStringAsFixed(0)}%',
                ],
              ],
              _uPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liquidityCommand(
    SmartAnalysisSnapshot? s,
  ) {
    final fakeout = s == null
        ? 0.0
        : (100 - s.breakoutScore).clamp(
            0.0,
            100.0,
          );

    return _panelShell(
      'INSTITUTIONAL LIQUIDITY PRESSURE MATRIX',
      Row(
        children: [
          Expanded(
            child: _metricBlock(
              'BREAKOUT PRESSURE',
              [
                ['STATE', s?.breakoutState ?? '--'],
                [
                  'PRESSURE',
                  s == null ? '--' : '${s.breakoutScore.toStringAsFixed(0)}%',
                ],
                [
                  'FAKEOUT RISK',
                  '${fakeout.toStringAsFixed(0)}%',
                ],
                ['BIAS', s?.bias ?? '--'],
              ],
              _uAmber,
            ),
          ),
          Expanded(
            child: _metricBlock(
              'BUY-SIDE CLUSTER',
              [
                [
                  'LIQUIDITY',
                  s == null ? '--' : _px(s.liquidityAbove),
                ],
                [
                  'RESISTANCE',
                  s == null ? '--' : _px(s.resistance),
                ],
                ['STATUS', 'TRACKING'],
                ['SWEEP SENSOR', s?.liquidityState ?? '--'],
              ],
              _uGreen,
            ),
          ),
          Expanded(
            child: _metricBlock(
              'SELL-SIDE CLUSTER',
              [
                [
                  'LIQUIDITY',
                  s == null ? '--' : _px(s.liquidityBelow),
                ],
                [
                  'SUPPORT',
                  s == null ? '--' : _px(s.support),
                ],
                ['STATUS', 'TRACKING'],
                [
                  'LIQ SCORE',
                  s == null ? '--' : '${s.liquidityScore.toStringAsFixed(0)}',
                ],
              ],
              _uRed,
            ),
          ),
          Expanded(
            child: _metricBlock(
              'SMART MONEY MAP',
              [
                ['ORDER BLOCK', s?.orderBlockBias ?? '--'],
                ['BULL FVG', '${s?.bullishFvgCount ?? 0}'],
                ['BEAR FVG', '${s?.bearishFvgCount ?? 0}'],
                [
                  'RETEST ZONE',
                  s == null ? '--' : _px((s.support + s.resistance) / 2),
                ],
              ],
              _uPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mtfMatrix(
    SmartAnalysisSnapshot? s,
  ) {
    final values = s?.timeframes.values.toList() ?? <SmartTimeframeSummary>[];

    return _panelShell(
      'TIMEFRAME CONSENSUS NETWORK',
      Row(
        children: [
          for (final tf in values.take(4))
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _biasColor(tf.bias).withValues(alpha: .45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tf.timeframe,
                      style: TextStyle(
                        color: _biasColor(tf.bias),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _miniMetric(
                      'BIAS',
                      tf.bias,
                    ),
                    _miniMetric(
                      'TREND',
                      tf.trend,
                    ),
                    _miniMetric(
                      'STRUCTURE',
                      tf.structure,
                    ),
                    _miniMetric(
                      'MOMENTUM',
                      tf.momentum,
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: (tf.score / 100).clamp(
                        0.0,
                        1.0,
                      ),
                      color: _biasColor(tf.bias),
                      backgroundColor: Colors.white10,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${tf.score.toStringAsFixed(0)} / 100',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (values.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'SYNCHRONIZING MULTI-TIMEFRAME NETWORK',
                  style: TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dukeReasoning(
    SmartAnalysisSnapshot? s,
  ) {
    final thesis = s == null
        ? 'Synchronizing market state.'
        : 'Current machine thesis is ${s.bias}. '
            'Trend ${s.trend}, structure ${s.structure}, momentum ${s.momentum}. '
            'Primary pattern ${s.pattern}. '
            'Breakout engine reports ${s.breakoutState}. '
            'Global confluence is ${s.confluence.toStringAsFixed(0)} percent.';

    return _panelShell(
      'AUTONOMOUS REASONING STREAM',
      Row(
        children: [
          Expanded(
            flex: 4,
            child: _metricBlock(
              'LIVE MACHINE THESIS',
              [
                ['BIAS', s?.bias ?? '--'],
                ['TREND', s?.trend ?? '--'],
                ['STRUCTURE', s?.structure ?? '--'],
                ['MOMENTUM', s?.momentum ?? '--'],
              ],
              _uBlue,
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _uBlue.withValues(alpha: .3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DUKE AI REASONING',
                    style: TextStyle(
                      color: _uBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    thesis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dukeMessage,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _uGreen,
                      fontSize: 9,
                      height: 1.35,
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

  Widget _rightAiCore(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(11),
      decoration: _neoBox(
        widget.accent,
        alpha: .17,
      ),
      child: ListView(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.accent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: .25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology_alt,
                  color: widget.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DUKE AGENT BOSS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'AUTONOMOUS TECHNICAL AI ONLINE',
                      style: TextStyle(
                        color: _uGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _sectionTitle(
            'AI TECHNICAL READ',
            widget.accent,
          ),
          const SizedBox(height: 8),
          _tinyState(
            'MARKET BIAS',
            s?.bias ?? '--',
          ),
          _tinyState(
            'TREND',
            s?.trend ?? '--',
          ),
          _tinyState(
            'STRUCTURE',
            s?.structure ?? '--',
          ),
          _tinyState(
            'MOMENTUM',
            s?.momentum ?? '--',
          ),
          _tinyState(
            'PATTERN',
            s?.pattern ?? '--',
          ),
          _tinyState(
            'BREAKOUT',
            s?.breakoutState ?? '--',
          ),
          _tinyState(
            'CONFLUENCE',
            s == null ? '--' : '${s.confluence.toStringAsFixed(0)} / 100',
          ),
          const SizedBox(height: 16),
          _sectionTitle(
            'AI COMMAND CENTER',
            _uPurple,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: command,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            onSubmitted: _issueCommand,
            decoration: InputDecoration(
              hintText: 'Command Duke...',
              hintStyle: const TextStyle(
                color: Colors.white30,
                fontSize: 9,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  _issueCommand(command.text);
                },
                icon: Icon(
                  Icons.send,
                  color: widget.accent,
                  size: 17,
                ),
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: .22),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.accent.withValues(alpha: .35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _aiCommandButton(
            'FULL MARKET READ',
            'Analyze the entire chart and give me the machine thesis.',
          ),
          _aiCommandButton(
            'PROJECT NEXT MOVE',
            'Analyze trend structure momentum and project the next move.',
          ),
          _aiCommandButton(
            'MAP KEY LEVELS',
            'Show support resistance and Fibonacci levels.',
          ),
          _aiCommandButton(
            'SCAN PATTERN FIELD',
            'Find patterns and pattern probability.',
          ),
          _aiCommandButton(
            'LIQUIDITY X-RAY',
            'Show liquidity and smart money context.',
          ),
          _aiCommandButton(
            'BREAKOUT PROBABILITY',
            'Analyze breakout probability and fakeout risk.',
          ),
          _aiCommandButton(
            'RUN MTF CONSENSUS',
            'Run multi timeframe confluence analysis.',
          ),
          const SizedBox(height: 12),
          _sectionTitle(
            'LIVE AI EVENT STREAM',
            _uBlue,
          ),
          const SizedBox(height: 6),
          if (eventStream.isEmpty)
            const Text(
              'No AI commands issued yet.',
              style: TextStyle(
                color: Colors.white30,
                fontSize: 9,
              ),
            ),
          for (final item in eventStream.take(5))
            Container(
              margin: const EdgeInsets.only(
                bottom: 4,
              ),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _aiCommandButton(
    String label,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
      ),
      child: InkWell(
        onTap: () => _issueCommand(text),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.accent.withValues(alpha: .28),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: widget.accent,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
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

  Widget _bottomTelemetry(
    SmartAnalysisSnapshot? s,
  ) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: const BoxDecoration(
        color: _uBg2,
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
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 24),
          const Text(
            'CONNECTION: STABLE',
            style: TextStyle(
              color: _uGreen,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'CANDLES: ${s?.candles.length ?? 0}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'MODE: $mode',
            style: TextStyle(
              color: widget.accent,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            '999 SMART ANALYSIS MATRIX  |  ${widget.title}',
            style: TextStyle(
              color: widget.accent,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(
    String title,
    List<List<String>> rows,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: .33),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          for (final row in rows)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row[0],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row[1],
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _biasColor(row[1]),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _panelShell(
    String title,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _neoBox(
        widget.accent,
        alpha: .14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: widget.accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: child,
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
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
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

  Widget _tinyState(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
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
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: .4),
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

  BoxDecoration _neoBox(
    Color color, {
    double alpha = .2,
  }) {
    return BoxDecoration(
      color: _uPanel,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: color.withValues(alpha: alpha),
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .035),
          blurRadius: 18,
        ),
      ],
    );
  }
}

class _UltraMarketPainter extends CustomPainter {
  final SmartAnalysisSnapshot snapshot;
  final Color accent;
  final _UltraKind kind;
  final Map<String, bool> systems;

  const _UltraMarketPainter({
    required this.snapshot,
    required this.accent,
    required this.kind,
    required this.systems,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final source = snapshot.candles;

    if (source.isEmpty) return;

    final candles = source.length > 70
        ? source.sublist(
            source.length - 70,
          )
        : source;

    double high = candles.first.high;
    double low = candles.first.low;

    for (final candle in candles) {
      high = math.max(
        high,
        candle.high,
      );

      low = math.min(
        low,
        candle.low,
      );
    }

    high = math.max(
      high,
      snapshot.resistance,
    );

    low = math.min(
      low,
      snapshot.support,
    );

    final range = math.max(
      .0000001,
      high - low,
    );

    final chartLeft = 12.0;
    final chartRight = size.width - 52;
    final chartTop = 36.0;
    final chartBottom = size.height - 24;

    double y(
      double price,
    ) {
      return chartTop + ((high - price) / range) * (chartBottom - chartTop);
    }

    final gridPaint = Paint()
      ..color = _uGrid.withValues(alpha: .42)
      ..strokeWidth = .7;

    for (int i = 0; i <= 8; i++) {
      final yy = chartTop + ((chartBottom - chartTop) / 8) * i;

      canvas.drawLine(
        Offset(chartLeft, yy),
        Offset(chartRight, yy),
        gridPaint,
      );
    }

    for (int i = 0; i <= 10; i++) {
      final xx = chartLeft + ((chartRight - chartLeft) / 10) * i;

      canvas.drawLine(
        Offset(xx, chartTop),
        Offset(xx, chartBottom),
        gridPaint,
      );
    }

    final candleStep = (chartRight - chartLeft) / candles.length;

    final candleWidth = math.max(2.0, candleStep * .52);

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];

      final x = chartLeft + candleStep * i + candleStep / 2;

      final bullish = candle.close >= candle.open;

      final color = bullish ? _uGreen : _uRed;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(
          x,
          y(candle.high),
        ),
        Offset(
          x,
          y(candle.low),
        ),
        paint,
      );

      final top = y(
        math.max(
          candle.open,
          candle.close,
        ),
      );

      final bottom = y(
        math.min(
          candle.open,
          candle.close,
        ),
      );

      canvas.drawRect(
        Rect.fromLTRB(
          x - candleWidth / 2,
          top,
          x + candleWidth / 2,
          math.max(
            top + 1.5,
            bottom,
          ),
        ),
        paint,
      );
    }

    void horizontal(
      double value,
      Color color,
      String label,
    ) {
      final yy = y(value);

      final paint = Paint()
        ..color = color.withValues(alpha: .78)
        ..strokeWidth = 1.2;

      canvas.drawLine(
        Offset(chartLeft, yy),
        Offset(chartRight, yy),
        paint,
      );

      final span = TextSpan(
        text: '$label ${_format(value)}',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      );

      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          chartRight - tp.width,
          yy - 13,
        ),
      );
    }

    if (systems['Adaptive S/R'] ?? true) {
      horizontal(
        snapshot.resistance,
        _uRed,
        'RESISTANCE',
      );

      horizontal(
        snapshot.support,
        _uGreen,
        'SUPPORT',
      );
    }

    if (systems['Auto Fibonacci'] ?? true) {
      for (final entry in snapshot.fibonacci.entries) {
        final yy = y(entry.value);

        final paint = Paint()
          ..color = _uAmber.withValues(alpha: .48)
          ..strokeWidth = .8;

        canvas.drawLine(
          Offset(chartLeft, yy),
          Offset(chartRight, yy),
          paint,
        );

        final span = TextSpan(
          text: '${entry.key} ${_format(entry.value)}',
          style: const TextStyle(
            color: _uAmber,
            fontSize: 8,
          ),
        );

        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(
            chartLeft + 5,
            yy - 10,
          ),
        );
      }
    }

    if (systems['Neural Trend Geometry'] ?? true) {
      final first = candles.first;
      final last = candles.last;

      final paint = Paint()
        ..color = accent.withValues(alpha: .62)
        ..strokeWidth = 1.3;

      canvas.drawLine(
        Offset(
          chartLeft,
          y(first.low),
        ),
        Offset(
          chartRight,
          y(last.close),
        ),
        paint,
      );
    }

    if (kind == _UltraKind.liquidity || kind == _UltraKind.patterns) {
      final liqPaint = Paint()..color = _uPurple.withValues(alpha: .75);

      final lookback = candles.length > 24 ? candles.length - 24 : 0;

      for (int i = lookback; i < candles.length; i += 4) {
        final candle = candles[i];

        final x = chartLeft + candleStep * i + candleStep / 2;

        canvas.drawCircle(
          Offset(
            x,
            y(candle.high),
          ),
          3,
          liqPaint,
        );
      }
    }

    if (kind == _UltraKind.chart || kind == _UltraKind.duke) {
      final last = candles.last;

      final startX = chartRight - 50;
      final startY = y(last.close);

      final bullish = snapshot.bias.toUpperCase().contains('BULL');

      final bearish = snapshot.bias.toUpperCase().contains('BEAR');

      final projection = Path()
        ..moveTo(
          startX,
          startY,
        )
        ..cubicTo(
          startX + 25,
          startY +
              (bullish
                  ? -18
                  : bearish
                      ? 18
                      : 0),
          startX + 48,
          startY +
              (bullish
                  ? -30
                  : bearish
                      ? 30
                      : 0),
          chartRight,
          startY +
              (bullish
                  ? -42
                  : bearish
                      ? 42
                      : 0),
        );

      final projectionPaint = Paint()
        ..color = accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawPath(
        projection,
        projectionPaint,
      );
    }
  }

  static String _format(
    double value,
  ) {
    return value >= 100 ? value.toStringAsFixed(2) : value.toStringAsFixed(5);
  }

  @override
  bool shouldRepaint(
    covariant _UltraMarketPainter oldDelegate,
  ) {
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.kind != kind ||
        oldDelegate.systems != systems;
  }
}
