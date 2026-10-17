import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_market_data.dart';

class MultiChartScreen extends StatefulWidget {
  final String initialSymbol;
  final String initialTimeframe;

  const MultiChartScreen({
    super.key,
    required this.initialSymbol,
    required this.initialTimeframe,
  });

  @override
  State<MultiChartScreen> createState() => _MultiChartScreenState();
}

class _MultiChartScreenState extends State<MultiChartScreen> {
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF27FF88);
  static const red = Color(0xFFFF4057);
  static const purple = Color(0xFFB388FF);

  static const pairs = <String>[
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'USDCHF',
    'USDCAD',
    'AUDUSD',
    'NZDUSD',
    'EURGBP',
  ];

  late List<String> selected;
  final Map<String, ChartMarketSnapshot> snapshots = {};

  Timer? timer;
  int layout = 4;

  @override
  void initState() {
    super.initState();

    selected = [
      ChartMarketData.normalize(widget.initialSymbol),
      'GBPUSD',
      'USDJPY',
      'AUDUSD',
    ];

    _refresh();

    timer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    for (final symbol in selected.take(layout)) {
      snapshots[symbol] = await ChartMarketData.snapshot(
        symbol,
        historyCount: 100,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.grid_view_rounded, color: cyan),
            SizedBox(width: 9),
            Text(
              'MULTI-CHART VIEW',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          _layoutButton(1),
          _layoutButton(2),
          _layoutButton(4),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: layout == 1
            ? _chart(0)
            : GridView.builder(
                itemCount: layout,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (_, index) => _chart(index),
              ),
      ),
    );
  }

  Widget _layoutButton(int count) {
    return TextButton(
      onPressed: () {
        setState(() => layout = count);
        _refresh();
      },
      child: Text(
        '$count',
        style: TextStyle(
          color: layout == count ? cyan : Colors.white54,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _chart(int index) {
    final symbol = selected[index];
    final snap = snapshots[symbol];
    final change = snap?.changePercent ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF06121E),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: cyan.withValues(alpha: .24),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 47,
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(
                  Icons.candlestick_chart,
                  color: cyan,
                  size: 17,
                ),
                const SizedBox(width: 7),
                DropdownButton<String>(
                  value: symbol,
                  dropdownColor: const Color(0xFF06121E),
                  underline: const SizedBox(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  items: pairs
                      .map(
                        (pair) => DropdownMenuItem(
                          value: pair,
                          child: Text(pair),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selected[index] = value;
                    });

                    _refresh();
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  widget.initialTimeframe,
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      snap == null || snap.price <= 0
                          ? 'WAITING'
                          : snap.price.toStringAsFixed(5),
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(3)}%',
                      style: TextStyle(
                        color: change >= 0 ? green : red,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _LiveMiniChartPainter(
                snap?.candles ?? const [],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMiniChartPainter extends CustomPainter {
  final List<ChartMarketCandle> candles;

  const _LiveMiniChartPainter(this.candles);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;

    for (int i = 0; i <= 8; i++) {
      final x = size.width * i / 8;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        grid,
      );
    }

    for (int i = 0; i <= 6; i++) {
      final y = size.height * i / 6;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    if (candles.isEmpty) {
      return;
    }

    final visible =
        candles.length > 64 ? candles.sublist(candles.length - 64) : candles;

    double low = visible.first.low;
    double high = visible.first.high;

    for (final candle in visible) {
      low = math.min(low, candle.low);
      high = math.max(high, candle.high);
    }

    var range = high - low;

    if (range <= 0) {
      range = math.max(
        high.abs() * .001,
        0.0000001,
      );
    }

    low -= range * .08;
    high += range * .08;
    range = high - low;

    double yFor(double value) {
      return size.height * (1 - ((value - low) / range).clamp(0.0, 1.0));
    }

    final slot = size.width / math.max(64, visible.length);

    final start = math.max(
      0.0,
      size.width - slot * visible.length,
    );

    final bodyWidth = math.max(
      2.0,
      math.min(
        6.0,
        slot * .72,
      ),
    );

    for (int i = 0; i < visible.length; i++) {
      final candle = visible[i];

      final x = start + slot * i + slot / 2;

      final color =
          candle.bullish ? const Color(0xFF27FF88) : const Color(0xFFFF4057);

      canvas.drawLine(
        Offset(x, yFor(candle.high)),
        Offset(x, yFor(candle.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );

      final openY = yFor(candle.open);
      final closeY = yFor(candle.close);

      canvas.drawRect(
        Rect.fromLTWH(
          x - bodyWidth / 2,
          math.min(openY, closeY),
          bodyWidth,
          math.max(
            2.0,
            (openY - closeY).abs(),
          ),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _LiveMiniChartPainter oldDelegate,
  ) {
    return true;
  }
}
