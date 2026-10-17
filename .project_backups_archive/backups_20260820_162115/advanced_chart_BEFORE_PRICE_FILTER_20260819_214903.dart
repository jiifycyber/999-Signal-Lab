import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AdvancedChartScreen extends StatefulWidget {
  final String Function() symbolProvider;
  final String Function() timeframeProvider;
  final double Function() priceProvider;
  final List<double> Function() historyProvider;

  const AdvancedChartScreen({
    super.key,
    required this.symbolProvider,
    required this.timeframeProvider,
    required this.priceProvider,
    required this.historyProvider,
  });

  @override
  State<AdvancedChartScreen> createState() => _AdvancedChartScreenState();
}

class _AdvancedChartScreenState extends State<AdvancedChartScreen> {
  static const bg = Color(0xFF020811);
  static const panel = Color(0xFF06121E);
  static const panel2 = Color(0xFF081A29);

  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF27FF88);
  static const red = Color(0xFFFF4057);
  static const amber = Color(0xFFFFD23F);
  static const purple = Color(0xFF9A5CFF);

  Timer? refreshTimer;

  int selectedBottomTab = 0;
  bool showGrid = true;
  bool showCrosshair = true;

  @override
  void initState() {
    super.initState();

    refreshTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  String get symbol => widget.symbolProvider();

  String get timeframe => widget.timeframeProvider();

  double get currentPrice => widget.priceProvider();

  List<double> get priceHistory {
    final values = widget.historyProvider();

    if (values.length <= 180) {
      return values;
    }

    return values.sublist(values.length - 180);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _topToolbar(),
            Expanded(
              child: Row(
                children: [
                  _drawingToolbar(),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _chartPanel(),
                        ),
                        _bottomPanel(),
                      ],
                    ),
                  ),
                  _aiPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topToolbar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: panel,
        border: Border(
          bottom: BorderSide(
            color: cyan.withValues(alpha: .22),
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
          const Icon(
            Icons.candlestick_chart,
            color: cyan,
            size: 19,
          ),
          const SizedBox(width: 7),
          const Text(
            'ADVANCED CHART',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(width: 18),
          _statusBox(
            symbol,
            Icons.currency_exchange,
            cyan,
          ),
          const SizedBox(width: 6),
          _statusBox(
            currentPrice > 0 ? currentPrice.toStringAsFixed(5) : 'WAITING',
            Icons.show_chart,
            currentPrice > 0 ? green : amber,
          ),
          const SizedBox(width: 6),
          _statusBox(
            timeframe,
            Icons.timer_outlined,
            purple,
          ),
          const Spacer(),
          _toggleButton(
            Icons.grid_4x4,
            'GRID',
            showGrid,
            () {
              setState(() {
                showGrid = !showGrid;
              });
            },
          ),
          _toggleButton(
            Icons.control_camera,
            'CROSSHAIR',
            showCrosshair,
            () {
              setState(() {
                showCrosshair = !showCrosshair;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _statusBox(
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: .30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        margin: const EdgeInsets.only(left: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? cyan.withValues(alpha: .08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? cyan.withValues(alpha: .35) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? cyan : Colors.white38,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? cyan : Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawingToolbar() {
    const tools = [
      (Icons.mouse, 'Cursor'),
      (Icons.control_camera, 'Crosshair'),
      (Icons.trending_up, 'Trendline'),
      (Icons.horizontal_rule, 'Horizontal Line'),
      (Icons.vertical_align_center, 'Vertical Line'),
      (Icons.crop_square, 'Zone'),
      (Icons.stacked_line_chart, 'Fibonacci'),
      (Icons.text_fields, 'Text'),
      (Icons.straighten, 'Measure'),
      (Icons.delete_outline, 'Delete'),
    ];

    return Container(
      width: 58,
      color: const Color(0xFF04101A),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 7),
        children: [
          for (final tool in tools)
            Tooltip(
              message: tool.$2,
              child: SizedBox(
                height: 46,
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 700),
                        content: Text(
                          '${tool.$2} selected',
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    tool.$1,
                    color: Colors.white54,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chartPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 6, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF030B13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cyan.withValues(alpha: .22),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PriceTracePainter(
                values: priceHistory,
                showGrid: showGrid,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$symbol • $timeframe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'LIVE MARKET CHART',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: Text(
              currentPrice > 0
                  ? currentPrice.toStringAsFixed(5)
                  : 'WAITING FOR PRICE',
              style: TextStyle(
                color: currentPrice > 0 ? green : amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (priceHistory.length < 2)
            const Center(
              child: Text(
                'WAITING FOR LIVE PRICE HISTORY',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (showCrosshair)
            const Center(
              child: Icon(
                Icons.add,
                color: Colors.white24,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _aiPanel() {
    final values = priceHistory;

    double change = 0;

    if (values.length > 1 && values.first != 0) {
      change = ((values.last - values.first) / values.first) * 100;
    }

    final bullish = change >= 0;

    return Container(
      width: 255,
      margin: const EdgeInsets.fromLTRB(0, 8, 8, 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: purple.withValues(alpha: .30),
        ),
      ),
      child: ListView(
        children: [
          const Row(
            children: [
              Icon(
                Icons.psychology,
                color: purple,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'AI CHART INTELLIGENCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _intelRow('PAIR', symbol, cyan),
          _intelRow('TIMEFRAME', timeframe, cyan),
          _intelRow(
            'PRICE',
            currentPrice > 0 ? currentPrice.toStringAsFixed(5) : '--',
            green,
          ),
          _intelRow(
            'TRACE TREND',
            bullish ? 'BULLISH' : 'BEARISH',
            bullish ? green : red,
          ),
          _intelRow(
            'CHANGE',
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(3)}%',
            bullish ? green : red,
          ),
          _intelRow(
            'LIVE POINTS',
            '${values.length}',
            amber,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: purple.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: purple.withValues(alpha: .25),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DUKE ANALYSIS',
                  style: TextStyle(
                    color: purple,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Live chart connected to the existing market state. '
                  'Scanner intelligence will be layered into this panel '
                  'after the chart foundation is confirmed.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _intelRow(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    const tabs = [
      'OVERVIEW',
      'INDICATORS',
      'SCANNER',
      'MARKET STRUCTURE',
      'SIGNAL HISTORY',
    ];

    return Container(
      height: 145,
      margin: const EdgeInsets.fromLTRB(8, 0, 6, 8),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cyan.withValues(alpha: .18),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedBottomTab = i;
                        });
                      },
                      child: Center(
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            color:
                                selectedBottomTab == i ? cyan : Colors.white38,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _bottomBody(),
          ),
        ],
      ),
    );
  }

  Widget _bottomBody() {
    if (selectedBottomTab == 1) {
      return _centerMessage(
        'INDICATORS',
        'Indicator engine connects here.',
      );
    }

    if (selectedBottomTab == 2) {
      return _centerMessage(
        'SCANNER',
        'Direction • Confidence • Setup • Momentum',
      );
    }

    if (selectedBottomTab == 3) {
      return _centerMessage(
        'MARKET STRUCTURE',
        'Trend • Support • Resistance • Break of Structure',
      );
    }

    if (selectedBottomTab == 4) {
      return _centerMessage(
        'SIGNAL HISTORY',
        'Resolved $symbol signals will appear here.',
      );
    }

    final values = priceHistory;

    final high = values.isEmpty ? 0.0 : values.reduce(math.max);

    final low = values.isEmpty ? 0.0 : values.reduce(math.min);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _metric(
          'CURRENT',
          currentPrice > 0 ? currentPrice.toStringAsFixed(5) : '--',
          green,
        ),
        _metric(
          'TRACE HIGH',
          high > 0 ? high.toStringAsFixed(5) : '--',
          cyan,
        ),
        _metric(
          'TRACE LOW',
          low > 0 ? low.toStringAsFixed(5) : '--',
          red,
        ),
        _metric(
          'POINTS',
          '${values.length}',
          amber,
        ),
        _metric(
          'TIMEFRAME',
          timeframe,
          purple,
        ),
      ],
    );
  }

  Widget _centerMessage(
    String title,
    String text,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: cyan,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String label,
    String value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PriceTracePainter extends CustomPainter {
  final List<double> values;
  final bool showGrid;

  const _PriceTracePainter({
    required this.values,
    required this.showGrid,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: .045)
        ..strokeWidth = 1;

      for (int i = 1; i < 10; i++) {
        final x = size.width * i / 10;

        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          gridPaint,
        );
      }

      for (int i = 1; i < 8; i++) {
        final y = size.height * i / 8;

        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint,
        );
      }
    }

    if (values.length < 2) {
      return;
    }

    final low = values.reduce(math.min);
    final high = values.reduce(math.max);

    var range = high - low;

    if (range.abs() < .0000001) {
      range = math.max(
        high.abs() * .0001,
        .00001,
      );
    }

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);

      final normalized = (values[i] - low) / range;

      final y = size.height - 25 - normalized * (size.height - 50);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: .16)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      path,
      glowPaint,
    );

    canvas.drawPath(
      path,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PriceTracePainter oldDelegate,
  ) {
    return true;
  }
}
