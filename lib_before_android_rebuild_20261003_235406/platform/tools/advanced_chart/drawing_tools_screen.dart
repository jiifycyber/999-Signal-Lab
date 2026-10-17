import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_market_data.dart';

enum _DrawingTool {
  cursor,
  trendline,
  horizontal,
  vertical,
  ray,
  fibonacci,
  rectangle,
  arrow,
  text,
  measure,
  erase,
}

class DrawingToolsScreen extends StatefulWidget {
  final String initialSymbol;
  final String initialTimeframe;

  const DrawingToolsScreen({
    super.key,
    this.initialSymbol = 'EURUSD',
    this.initialTimeframe = 'M1',
  });

  @override
  State<DrawingToolsScreen> createState() => _DrawingToolsScreenState();
}

class _DrawingObject {
  final _DrawingTool tool;
  final Offset start;
  final Offset end;

  const _DrawingObject({
    required this.tool,
    required this.start,
    required this.end,
  });
}

class _DrawingToolsScreenState extends State<DrawingToolsScreen> {
  static const bg = Color(0xFF020811);
  static const panel = Color(0xFF06121E);
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF27FF88);
  static const red = Color(0xFFFF4057);
  static const amber = Color(0xFFFFD23F);
  static const purple = Color(0xFFB388FF);

  late String symbol;
  late String timeframe;

  ChartMarketSnapshot? snapshot;

  final List<_DrawingObject> drawings = [];

  _DrawingTool selected = _DrawingTool.cursor;

  Offset? dragStart;
  Offset? dragCurrent;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    symbol = ChartMarketData.normalize(widget.initialSymbol);
    timeframe = widget.initialTimeframe;

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
    final next = await ChartMarketData.snapshot(
      symbol,
      historyCount: 120,
    );

    if (!mounted) return;

    setState(() {
      snapshot = next;
    });
  }

  void _start(DragStartDetails details) {
    if (selected == _DrawingTool.cursor) return;

    setState(() {
      dragStart = details.localPosition;
      dragCurrent = details.localPosition;
    });
  }

  void _update(DragUpdateDetails details) {
    if (dragStart == null) return;

    setState(() {
      dragCurrent = details.localPosition;
    });
  }

  void _finish(DragEndDetails details) {
    final start = dragStart;
    final end = dragCurrent;

    if (start == null || end == null) return;

    if (selected == _DrawingTool.erase) {
      setState(() {
        if (drawings.isNotEmpty) {
          drawings.removeLast();
        }

        dragStart = null;
        dragCurrent = null;
      });

      return;
    }

    setState(() {
      drawings.add(
        _DrawingObject(
          tool: selected,
          start: start,
          end: end,
        ),
      );

      dragStart = null;
      dragCurrent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final price = snapshot?.price ?? 0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(
              Icons.edit_note,
              color: cyan,
            ),
            const SizedBox(width: 8),
            const Text(
              'DRAWING TOOLS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$symbol • $timeframe',
              style: const TextStyle(
                color: purple,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          if (price > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(
                  price.toStringAsFixed(5),
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Undo drawing',
            onPressed: drawings.isEmpty
                ? null
                : () {
                    setState(() {
                      drawings.removeLast();
                    });
                  },
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Clear drawings',
            onPressed: () {
              setState(drawings.clear);
            },
            icon: const Icon(Icons.delete_sweep),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 220,
            color: panel,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _tool(
                  _DrawingTool.cursor,
                  Icons.mouse,
                  'Cursor',
                ),
                _tool(
                  _DrawingTool.trendline,
                  Icons.show_chart,
                  'Trendline',
                ),
                _tool(
                  _DrawingTool.horizontal,
                  Icons.horizontal_rule,
                  'Horizontal Line',
                ),
                _tool(
                  _DrawingTool.vertical,
                  Icons.more_vert,
                  'Vertical Line',
                ),
                _tool(
                  _DrawingTool.ray,
                  Icons.trending_flat,
                  'Ray',
                ),
                _tool(
                  _DrawingTool.fibonacci,
                  Icons.stacked_line_chart,
                  'Fibonacci',
                ),
                _tool(
                  _DrawingTool.rectangle,
                  Icons.crop_square,
                  'Rectangle / Zone',
                ),
                _tool(
                  _DrawingTool.arrow,
                  Icons.arrow_forward,
                  'Arrow',
                ),
                _tool(
                  _DrawingTool.text,
                  Icons.text_fields,
                  'Annotation',
                ),
                _tool(
                  _DrawingTool.measure,
                  Icons.straighten,
                  'Measure',
                ),
                _tool(
                  _DrawingTool.erase,
                  Icons.cleaning_services,
                  'Erase Last',
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF030B13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cyan.withValues(alpha: .25),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _start,
                onPanUpdate: _update,
                onPanEnd: _finish,
                child: CustomPaint(
                  painter: _DrawingChartPainter(
                    candles: snapshot?.candles ?? const [],
                    drawings: drawings,
                    previewTool: selected,
                    previewStart: dragStart,
                    previewEnd: dragCurrent,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tool(
    _DrawingTool tool,
    IconData icon,
    String label,
  ) {
    final active = selected == tool;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? cyan.withValues(alpha: .08) : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: active ? cyan.withValues(alpha: .30) : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: active ? cyan : Colors.white54,
          size: 19,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        onTap: () {
          setState(() {
            selected = tool;
          });
        },
      ),
    );
  }
}

class _DrawingChartPainter extends CustomPainter {
  final List<ChartMarketCandle> candles;
  final List<_DrawingObject> drawings;

  final _DrawingTool previewTool;
  final Offset? previewStart;
  final Offset? previewEnd;

  const _DrawingChartPainter({
    required this.candles,
    required this.drawings,
    required this.previewTool,
    required this.previewStart,
    required this.previewEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawCandles(canvas, size);

    for (final drawing in drawings) {
      _drawObject(
        canvas,
        size,
        drawing.tool,
        drawing.start,
        drawing.end,
        preview: false,
      );
    }

    if (previewStart != null && previewEnd != null) {
      _drawObject(
        canvas,
        size,
        previewTool,
        previewStart!,
        previewEnd!,
        preview: true,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (int i = 0; i <= 8; i++) {
      final y = size.height * i / 8;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawCandles(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final visible =
        candles.length > 70 ? candles.sublist(candles.length - 70) : candles;

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

    final slots = math.max(70, visible.length);
    final slot = size.width / slots;

    final used = slot * visible.length;

    final startX = math.max(
      0.0,
      size.width - used,
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

      final x = startX + slot * i + slot / 2;

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

  void _drawObject(
    Canvas canvas,
    Size size,
    _DrawingTool tool,
    Offset start,
    Offset end, {
    required bool preview,
  }) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(
        alpha: preview ? .55 : .95,
      )
      ..strokeWidth = preview ? 1.2 : 1.6
      ..style = PaintingStyle.stroke;

    switch (tool) {
      case _DrawingTool.horizontal:
        canvas.drawLine(
          Offset(0, start.dy),
          Offset(size.width, start.dy),
          paint,
        );
        return;

      case _DrawingTool.vertical:
        canvas.drawLine(
          Offset(start.dx, 0),
          Offset(start.dx, size.height),
          paint,
        );
        return;

      case _DrawingTool.rectangle:
        canvas.drawRect(
          Rect.fromPoints(start, end),
          paint,
        );
        return;

      case _DrawingTool.ray:
        final delta = end - start;

        if (delta.distance <= 0) return;

        final scale = math.max(size.width, size.height) * 3 / delta.distance;

        canvas.drawLine(
          start,
          start + delta * scale,
          paint,
        );
        return;

      case _DrawingTool.fibonacci:
        const levels = <double>[
          0,
          .236,
          .382,
          .5,
          .618,
          .786,
          1,
        ];

        for (final level in levels) {
          final y = start.dy + (end.dy - start.dy) * level;

          canvas.drawLine(
            Offset(
              math.min(start.dx, end.dx),
              y,
            ),
            Offset(
              math.max(start.dx, end.dx),
              y,
            ),
            paint,
          );

          final label = TextPainter(
            text: TextSpan(
              text: level.toStringAsFixed(3),
              style: const TextStyle(
                color: Color(0xFFFFD23F),
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          label.paint(
            canvas,
            Offset(
              math.min(start.dx, end.dx) + 4,
              y - label.height - 2,
            ),
          );
        }

        return;

      case _DrawingTool.arrow:
        canvas.drawLine(start, end, paint);

        final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

        const arrowLength = 10.0;

        final p1 = Offset(
          end.dx - arrowLength * math.cos(angle - math.pi / 6),
          end.dy - arrowLength * math.sin(angle - math.pi / 6),
        );

        final p2 = Offset(
          end.dx - arrowLength * math.cos(angle + math.pi / 6),
          end.dy - arrowLength * math.sin(angle + math.pi / 6),
        );

        canvas.drawLine(end, p1, paint);
        canvas.drawLine(end, p2, paint);
        return;

      case _DrawingTool.measure:
        canvas.drawLine(start, end, paint);

        final distance = (end - start).distance;

        final label = TextPainter(
          text: TextSpan(
            text: '${distance.toStringAsFixed(0)} px',
            style: const TextStyle(
              color: Color(0xFFFFD23F),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        label.paint(
          canvas,
          Offset(
            (start.dx + end.dx) / 2,
            (start.dy + end.dy) / 2,
          ),
        );
        return;

      case _DrawingTool.text:
        final label = TextPainter(
          text: const TextSpan(
            text: 'NOTE',
            style: TextStyle(
              color: Color(0xFFFFD23F),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        label.paint(canvas, end);
        return;

      case _DrawingTool.cursor:
      case _DrawingTool.erase:
        return;

      case _DrawingTool.trendline:
        canvas.drawLine(start, end, paint);
        return;
    }
  }

  @override
  bool shouldRepaint(
    covariant _DrawingChartPainter oldDelegate,
  ) {
    return true;
  }
}
